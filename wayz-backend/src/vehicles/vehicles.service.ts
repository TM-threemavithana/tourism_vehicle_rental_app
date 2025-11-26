import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Vehicle } from '../entities/vehicle.entity';
import { CreateVehicleDto, UpdateVehicleDto } from '../dto/vehicle.dto';
import { CacheService } from '../cache/cache.service';

@Injectable()
export class VehiclesService {
  private readonly logger = new Logger(VehiclesService.name);
  private readonly CACHE_TTL = 300; // 5 minutes
  private readonly LIST_CACHE_TTL = 180; // 3 minutes for lists

  constructor(
    @InjectRepository(Vehicle)
    private readonly vehicleRepository: Repository<Vehicle>,
    private readonly cacheService: CacheService,
  ) {}

  async create(
    createVehicleDto: CreateVehicleDto,
    ownerId: string,
  ): Promise<Vehicle> {
    const vehicle = this.vehicleRepository.create({
      ...createVehicleDto,
      ownerId,
    });
    const savedVehicle = await this.vehicleRepository.save(vehicle);

    // Invalidate related caches
    await this.invalidateVehicleCaches(ownerId);

    return savedVehicle;
  }

  async findAll(): Promise<Vehicle[]> {
    const cacheKey = 'vehicles:all';

    const cached = await this.cacheService.get<Vehicle[]>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const vehicles = await this.vehicleRepository.find({
      where: { isActive: true },
      relations: ['owner', 'category'],
      order: { createdAt: 'DESC' },
    });

    await this.cacheService.set(cacheKey, vehicles, this.LIST_CACHE_TTL);
    return vehicles;
  }

  async findAvailable(): Promise<Vehicle[]> {
    const cacheKey = 'vehicles:available';

    const cached = await this.cacheService.get<Vehicle[]>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const vehicles = await this.vehicleRepository.find({
      where: { isActive: true, isAvailable: true },
      relations: ['owner', 'category'],
      order: { createdAt: 'DESC' },
    });

    await this.cacheService.set(cacheKey, vehicles, this.LIST_CACHE_TTL);
    return vehicles;
  }

  async findOne(id: string): Promise<Vehicle> {
    const cacheKey = `vehicle:${id}`;

    const cached = await this.cacheService.get<Vehicle>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const vehicle = await this.vehicleRepository.findOne({
      where: { id, isActive: true },
      relations: ['owner', 'category', 'reviews'],
    });

    if (!vehicle) {
      throw new NotFoundException(`Vehicle with ID "${id}" not found`);
    }

    await this.cacheService.set(cacheKey, vehicle, this.CACHE_TTL);
    return vehicle;
  }

  async findByOwner(ownerId: string): Promise<Vehicle[]> {
    const cacheKey = `vehicles:owner:${ownerId}`;

    const cached = await this.cacheService.get<Vehicle[]>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const vehicles = await this.vehicleRepository.find({
      where: { ownerId, isActive: true },
      relations: ['category'],
      order: { createdAt: 'DESC' },
    });

    await this.cacheService.set(cacheKey, vehicles, this.CACHE_TTL);
    return vehicles;
  }

  async update(
    id: string,
    updateVehicleDto: UpdateVehicleDto,
  ): Promise<Vehicle> {
    const vehicle = await this.findOne(id);
    Object.assign(vehicle, updateVehicleDto);
    const updatedVehicle = await this.vehicleRepository.save(vehicle);

    // Invalidate related caches
    if (vehicle.ownerId) {
      await this.invalidateVehicleCaches(vehicle.ownerId, id);
    }

    return updatedVehicle;
  }

  async remove(id: string): Promise<void> {
    const vehicle = await this.findOne(id);
    vehicle.isActive = false;
    await this.vehicleRepository.save(vehicle);

    // Invalidate related caches
    if (vehicle.ownerId) {
      await this.invalidateVehicleCaches(vehicle.ownerId, id);
    }
  }

  async setAvailability(id: string, isAvailable: boolean): Promise<Vehicle> {
    const vehicle = await this.findOne(id);
    vehicle.isAvailable = isAvailable;
    const updatedVehicle = await this.vehicleRepository.save(vehicle);

    // Invalidate related caches
    if (vehicle.ownerId) {
      await this.invalidateVehicleCaches(vehicle.ownerId, id);
    }

    return updatedVehicle;
  }

  // Search and filter methods
  async searchVehicles(params: {
    city?: string;
    make?: string;
    minPrice?: number;
    maxPrice?: number;
    seats?: number;
  }): Promise<Vehicle[]> {
    // Generate cache key based on search params
    const cacheKey = `vehicles:search:${JSON.stringify(params)}`;

    const cached = await this.cacheService.get<Vehicle[]>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const query = this.vehicleRepository
      .createQueryBuilder('vehicle')
      .leftJoinAndSelect('vehicle.owner', 'owner')
      .leftJoinAndSelect('vehicle.category', 'category')
      .where('vehicle.isActive = :isActive', { isActive: true })
      .andWhere('vehicle.isAvailable = :isAvailable', { isAvailable: true });

    if (params.city) {
      query.andWhere('LOWER(vehicle.locationCity) LIKE LOWER(:city)', {
        city: `%${params.city}%`,
      });
    }

    if (params.make) {
      query.andWhere('LOWER(vehicle.make) LIKE LOWER(:make)', {
        make: `%${params.make}%`,
      });
    }

    if (params.minPrice) {
      query.andWhere('vehicle.dailyRate >= :minPrice', {
        minPrice: params.minPrice,
      });
    }

    if (params.maxPrice) {
      query.andWhere('vehicle.dailyRate <= :maxPrice', {
        maxPrice: params.maxPrice,
      });
    }

    if (params.seats) {
      query.andWhere('vehicle.seats >= :seats', { seats: params.seats });
    }

    const vehicles = await query.orderBy('vehicle.createdAt', 'DESC').getMany();

    // Cache search results
    await this.cacheService.set(cacheKey, vehicles, this.LIST_CACHE_TTL);

    return vehicles;
  }

  /**
   * Helper method to invalidate all related vehicle caches
   */
  private async invalidateVehicleCaches(
    ownerId: string,
    vehicleId?: string,
  ): Promise<void> {
    try {
      // Invalidate list caches
      await this.cacheService.delByPattern('vehicles:all');
      await this.cacheService.delByPattern('vehicles:available');
      await this.cacheService.delByPattern('vehicles:search:*');

      // Invalidate owner vehicles
      await this.cacheService.del(`vehicles:owner:${ownerId}`);

      // Invalidate specific vehicle if provided
      if (vehicleId) {
        await this.cacheService.del(`vehicle:${vehicleId}`);
      }

      this.logger.debug('Vehicle caches invalidated');
    } catch (error) {
      this.logger.error('Error invalidating vehicle caches:', error);
    }
  }

  /**
   * Add images to a vehicle
   */
  async addImages(id: string, imageUrls: string[]): Promise<Vehicle> {
    const vehicle = await this.findOne(id);

    // Get existing images or initialize empty array
    const existingImages = (vehicle.images as string[]) || [];

    // Add new images
    vehicle.images = [...existingImages, ...imageUrls];

    const updatedVehicle = await this.vehicleRepository.save(vehicle);

    // Invalidate caches
    if (vehicle.ownerId) {
      await this.invalidateVehicleCaches(vehicle.ownerId, id);
    }

    return updatedVehicle;
  }

  /**
   * Update vehicle images (replace all)
   */
  async updateImages(id: string, imageUrls: string[]): Promise<Vehicle> {
    const vehicle = await this.findOne(id);

    vehicle.images = imageUrls;

    const updatedVehicle = await this.vehicleRepository.save(vehicle);

    // Invalidate caches
    if (vehicle.ownerId) {
      await this.invalidateVehicleCaches(vehicle.ownerId, id);
    }

    return updatedVehicle;
  }

  /**
   * Delete all images from a vehicle
   */
  async deleteImages(id: string): Promise<Vehicle> {
    const vehicle = await this.findOne(id);

    vehicle.images = [];

    const updatedVehicle = await this.vehicleRepository.save(vehicle);

    // Invalidate caches
    if (vehicle.ownerId) {
      await this.invalidateVehicleCaches(vehicle.ownerId, id);
    }

    return updatedVehicle;
  }
}
