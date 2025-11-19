import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Booking, BookingStatus } from '../entities/booking.entity';
import { CreateBookingDto, UpdateBookingDto } from '../dto/booking.dto';
import { CacheService } from '../cache/cache.service';

@Injectable()
export class BookingsService {
  private readonly logger = new Logger(BookingsService.name);
  private readonly CACHE_TTL = 300; // 5 minutes for most queries
  private readonly STATS_CACHE_TTL = 600; // 10 minutes for stats

  constructor(
    @InjectRepository(Booking)
    private readonly bookingsRepository: Repository<Booking>,
    private readonly cacheService: CacheService,
  ) {}

  async create(createBookingDto: CreateBookingDto): Promise<Booking> {
    // Check for date conflicts
    const existingBooking = await this.bookingsRepository
      .createQueryBuilder('booking')
      .where('booking.vehicleId = :vehicleId', {
        vehicleId: createBookingDto.vehicleId,
      })
      .andWhere('booking.status IN (:...statuses)', {
        statuses: [BookingStatus.CONFIRMED, BookingStatus.IN_PROGRESS],
      })
      .andWhere(
        '(booking.startDate <= :endDate AND booking.endDate >= :startDate)',
        {
          startDate: createBookingDto.startDate,
          endDate: createBookingDto.endDate,
        },
      )
      .getOne();

    if (existingBooking) {
      throw new BadRequestException(
        'Vehicle is not available for the selected dates',
      );
    }

    // Validate dates
    const startDate = new Date(createBookingDto.startDate);
    const endDate = new Date(createBookingDto.endDate);

    if (startDate >= endDate) {
      throw new BadRequestException('End date must be after start date');
    }

    if (startDate < new Date()) {
      throw new BadRequestException('Start date cannot be in the past');
    }

    const booking = this.bookingsRepository.create({
      ...createBookingDto,
      startDate,
      endDate,
    });

    const savedBooking = await this.bookingsRepository.save(booking);

    // Invalidate related caches after creating
    await this.invalidateBookingCaches(
      savedBooking.userId,
      savedBooking.vehicleId,
    );

    return savedBooking;
  }

  async findAll(userId?: string, vehicleId?: string): Promise<Booking[]> {
    // Generate cache key based on filters
    const cacheKey = `bookings:list:${userId || 'all'}:${vehicleId || 'all'}`;

    // Try to get from cache
    const cached = await this.cacheService.get<Booking[]>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const queryBuilder = this.bookingsRepository
      .createQueryBuilder('booking')
      .leftJoinAndSelect('booking.user', 'user')
      .leftJoinAndSelect('booking.vehicle', 'vehicle')
      .leftJoinAndSelect('vehicle.category', 'category')
      .orderBy('booking.createdAt', 'DESC');

    if (userId) {
      queryBuilder.andWhere('booking.userId = :userId', { userId });
    }

    if (vehicleId) {
      queryBuilder.andWhere('booking.vehicleId = :vehicleId', { vehicleId });
    }

    const bookings = await queryBuilder.getMany();

    // Store in cache
    await this.cacheService.set(cacheKey, bookings, this.CACHE_TTL);

    return bookings;
  }

  async findOne(id: string): Promise<Booking> {
    const cacheKey = `booking:${id}`;

    // Try to get from cache
    const cached = await this.cacheService.get<Booking>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const booking = await this.bookingsRepository
      .createQueryBuilder('booking')
      .leftJoinAndSelect('booking.user', 'user')
      .leftJoinAndSelect('booking.vehicle', 'vehicle')
      .leftJoinAndSelect('vehicle.category', 'category')
      .leftJoinAndSelect('booking.paymentTransactions', 'payments')
      .where('booking.id = :id', { id })
      .getOne();

    if (!booking) {
      throw new NotFoundException(`Booking with ID ${id} not found`);
    }

    // Store in cache
    await this.cacheService.set(cacheKey, booking, this.CACHE_TTL);

    return booking;
  }

  async update(
    id: string,
    updateBookingDto: UpdateBookingDto,
  ): Promise<Booking> {
    const booking = await this.findOne(id);

    // If dates are being updated, check for conflicts
    if (updateBookingDto.startDate || updateBookingDto.endDate) {
      const startDate = updateBookingDto.startDate
        ? new Date(updateBookingDto.startDate)
        : booking.startDate;
      const endDate = updateBookingDto.endDate
        ? new Date(updateBookingDto.endDate)
        : booking.endDate;

      const conflictingBooking = await this.bookingsRepository
        .createQueryBuilder('booking')
        .where('booking.vehicleId = :vehicleId', {
          vehicleId: booking.vehicle.id,
        })
        .andWhere('booking.id != :currentId', { currentId: id })
        .andWhere('booking.status IN (:...statuses)', {
          statuses: [BookingStatus.CONFIRMED, BookingStatus.IN_PROGRESS],
        })
        .andWhere(
          '(booking.startDate <= :endDate AND booking.endDate >= :startDate)',
          { startDate, endDate },
        )
        .getOne();

      if (conflictingBooking) {
        throw new BadRequestException(
          'Vehicle is not available for the updated dates',
        );
      }
    }

    Object.assign(booking, updateBookingDto);
    const updatedBooking = await this.bookingsRepository.save(booking);

    // Invalidate related caches
    await this.invalidateBookingCaches(booking.userId, booking.vehicle.id, id);

    return updatedBooking;
  }

  async remove(id: string): Promise<void> {
    const booking = await this.findOne(id);

    // Only allow cancellation if booking is not in progress or completed
    if (
      booking.status === BookingStatus.IN_PROGRESS ||
      booking.status === BookingStatus.COMPLETED
    ) {
      throw new BadRequestException(
        'Cannot cancel booking that is in progress or completed',
      );
    }

    booking.status = BookingStatus.CANCELLED;
    await this.bookingsRepository.save(booking);

    // Invalidate related caches
    await this.invalidateBookingCaches(booking.userId, booking.vehicle.id, id);
  }

  async getBookingStats(): Promise<any> {
    const cacheKey = 'bookings:stats';

    // Try to get from cache
    const cached = await this.cacheService.get(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const totalBookings = await this.bookingsRepository.count();

    const statusCounts = await this.bookingsRepository
      .createQueryBuilder('booking')
      .select('booking.status, COUNT(booking.id) as count')
      .groupBy('booking.status')
      .getRawMany();

    const recentBookings = await this.bookingsRepository
      .createQueryBuilder('booking')
      .where('booking.createdAt >= :date', {
        date: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // Last 30 days
      })
      .getCount();

    const stats = {
      totalBookings,
      statusCounts,
      recentBookings,
    };

    // Store in cache with longer TTL for stats
    await this.cacheService.set(cacheKey, stats, this.STATS_CACHE_TTL);

    return stats;
  }

  async getUserBookings(userId: string): Promise<Booking[]> {
    const cacheKey = `bookings:user:${userId}`;

    // Try to get from cache
    const cached = await this.cacheService.get<Booking[]>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const bookings = await this.bookingsRepository
      .createQueryBuilder('booking')
      .leftJoinAndSelect('booking.vehicle', 'vehicle')
      .leftJoinAndSelect('vehicle.category', 'category')
      .where('booking.userId = :userId', { userId })
      .orderBy('booking.createdAt', 'DESC')
      .getMany();

    // Store in cache
    await this.cacheService.set(cacheKey, bookings, this.CACHE_TTL);

    return bookings;
  }

  async getVehicleBookings(vehicleId: string): Promise<Booking[]> {
    const cacheKey = `bookings:vehicle:${vehicleId}`;

    // Try to get from cache
    const cached = await this.cacheService.get<Booking[]>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const bookings = await this.bookingsRepository
      .createQueryBuilder('booking')
      .leftJoinAndSelect('booking.user', 'user')
      .where('booking.vehicleId = :vehicleId', { vehicleId })
      .orderBy('booking.startDate', 'ASC')
      .getMany();

    // Store in cache
    await this.cacheService.set(cacheKey, bookings, this.CACHE_TTL);

    return bookings;
  }

  /**
   * Helper method to invalidate all related booking caches
   */
  private async invalidateBookingCaches(
    userId: string,
    vehicleId: string,
    bookingId?: string,
  ): Promise<void> {
    try {
      // Invalidate list caches
      await this.cacheService.delByPattern('bookings:list:*');
      await this.cacheService.delByPattern('bookings:stats');
      
      // Invalidate user bookings
      await this.cacheService.del(`bookings:user:${userId}`);
      
      // Invalidate vehicle bookings
      await this.cacheService.del(`bookings:vehicle:${vehicleId}`);
      
      // Invalidate specific booking if provided
      if (bookingId) {
        await this.cacheService.del(`booking:${bookingId}`);
      }

      this.logger.debug('Booking caches invalidated');
    } catch (error) {
      this.logger.error('Error invalidating booking caches:', error);
    }
  }
}
