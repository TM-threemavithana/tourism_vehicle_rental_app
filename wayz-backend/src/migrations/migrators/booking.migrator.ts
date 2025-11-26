import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Booking, BookingStatus, PaymentStatus } from '../../entities/booking.entity';
import { User } from '../../entities/user.entity';
import { Vehicle } from '../../entities/vehicle.entity';

interface FirebaseBookingData {
  // User info
  userId?: string;
  userEmail?: string;
  userName?: string;

  // Vehicle info
  vehicleId?: string;
  vehicleDetails?: {
    make?: string;
    model?: string;
    year?: string | number;
    vehicleNo?: string;
  };

  // Booking dates
  startDate?: any;
  endDate?: any;
  pickupDate?: any;
  returnDate?: any;

  // Pricing
  dailyRate?: string | number;
  totalDays?: string | number;
  subtotal?: string | number;
  totalAmount?: string | number;
  totalCost?: string | number;
  taxAmount?: string | number;
  discountAmount?: string | number;

  // Status
  status?: string;
  bookingStatus?: string;
  paymentStatus?: string;

  // Payment info
  paymentMethod?: string;
  transactionId?: string;

  // Additional info
  pickupLocation?: string;
  dropoffLocation?: string;
  notes?: string;
  specialRequests?: string;

  // Timestamps
  createdAt?: any;
  updatedAt?: any;
  approvedAt?: any;
  confirmedAt?: any;
  cancelledAt?: any;

  [key: string]: any;
}

@Injectable()
export class BookingMigrator {
  private readonly logger = new Logger(BookingMigrator.name);

  constructor(
    @InjectRepository(Booking)
    private readonly bookingRepository: Repository<Booking>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Vehicle)
    private readonly vehicleRepository: Repository<Vehicle>,
  ) {}

  async migrate(
    firebaseDocId: string,
    data: FirebaseBookingData,
  ): Promise<Booking> {
    try {
      // Check if booking already exists
      const existingBooking = await this.bookingRepository.findOne({
        where: { firebaseDocId },
      });

      if (existingBooking) {
        this.logger.debug(
          `Booking already exists: ${firebaseDocId}, updating...`,
        );
        return await this.updateBooking(existingBooking, data);
      }

      return await this.createBooking(firebaseDocId, data);
    } catch (error) {
      this.logger.error(
        `Failed to migrate booking ${firebaseDocId}:`,
        error.message,
      );
      throw error;
    }
  }

  private async createBooking(
    firebaseDocId: string,
    data: FirebaseBookingData,
  ): Promise<Booking> {
    // Resolve user and vehicle IDs
    const userId = await this.resolveUserId(data);
    const vehicleId = await this.resolveVehicleId(data);

    if (!userId) {
      throw new Error(
        `Cannot create booking: user not found (userId: ${data.userId}, email: ${data.userEmail})`,
      );
    }

    if (!vehicleId) {
      throw new Error(
        `Cannot create booking: vehicle not found (vehicleId: ${data.vehicleId})`,
      );
    }

    // Parse dates
    const startDate = this.parseDate(data.startDate || data.pickupDate);
    const endDate = this.parseDate(data.endDate || data.returnDate);

    if (!startDate || !endDate) {
      throw new Error('Invalid booking dates');
    }

    // Calculate total days
    const totalDays = this.calculateTotalDays(startDate, endDate, data);

    // Parse pricing
    const dailyRate = this.parseNumber(data.dailyRate);
    const subtotal = this.parseNumber(data.subtotal || data.totalCost);
    const taxAmount = this.parseNumber(data.taxAmount);
    const discountAmount = this.parseNumber(data.discountAmount);
    const totalAmount = this.parseNumber(
      data.totalAmount || data.totalCost || data.subtotal,
    );

    const booking = this.bookingRepository.create({
      firebaseDocId,
      userId,
      vehicleId,
      startDate,
      endDate,
      dailyRate: dailyRate || 0,
      totalDays,
      subtotal: subtotal || dailyRate * totalDays || 0,
      taxAmount: taxAmount || 0,
      discountAmount: discountAmount || 0,
      totalAmount: totalAmount || subtotal || dailyRate * totalDays || 0,
      status: this.mapBookingStatus(data.status || data.bookingStatus),
      paymentStatus: this.mapPaymentStatus(data.paymentStatus),
      pickupLocation: data.pickupLocation,
      dropoffLocation: data.dropoffLocation,
      specialRequests: data.notes || data.specialRequests,
      createdAt: this.parseDate(data.createdAt) || new Date(),
      updatedAt: this.parseDate(data.updatedAt) || new Date(),
    } as any);

    const savedBooking = await this.bookingRepository.save(booking);
    const bookingResult = Array.isArray(savedBooking) ? savedBooking[0] : savedBooking;
    this.logger.debug(`✅ Created booking: ${bookingResult.id}`);
    return bookingResult;
  }

  private async updateBooking(
    existingBooking: Booking,
    data: FirebaseBookingData,
  ): Promise<Booking> {
    // Update status if changed
    if (data.status || data.bookingStatus) {
      existingBooking.status = this.mapBookingStatus(
        data.status || data.bookingStatus,
      );
    }

    if (data.paymentStatus) {
      existingBooking.paymentStatus = this.mapPaymentStatus(
        data.paymentStatus,
      );
    }

    // Update special requests if provided
    if (data.notes || data.specialRequests) {
      existingBooking.specialRequests = data.notes || data.specialRequests;
    }

    const savedBooking = await this.bookingRepository.save(existingBooking);
    this.logger.debug(`✅ Updated booking: ${savedBooking.id}`);
    return savedBooking;
  }

  private async resolveUserId(
    data: FirebaseBookingData,
  ): Promise<string | undefined> {
    if (!data.userId && !data.userEmail) {
      return undefined;
    }

    try {
      // Try Firebase UID first
      if (data.userId) {
        const user = await this.userRepository.findOne({
          where: { firebaseUid: data.userId },
        });
        if (user) return user.id;
      }

      // Try email
      if (data.userEmail) {
        const user = await this.userRepository.findOne({
          where: { email: data.userEmail },
        });
        if (user) return user.id;
      }

      this.logger.warn(
        `User not found for booking: userId=${data.userId}, email=${data.userEmail}`,
      );
      return undefined;
    } catch (error) {
      this.logger.error('Error resolving user ID:', error);
      return undefined;
    }
  }

  private async resolveVehicleId(
    data: FirebaseBookingData,
  ): Promise<string | undefined> {
    if (!data.vehicleId) {
      return undefined;
    }

    try {
      // Try Firebase doc ID first
      const vehicle = await this.vehicleRepository.findOne({
        where: { firebaseDocId: data.vehicleId },
      });

      if (vehicle) return vehicle.id;

      this.logger.warn(`Vehicle not found for booking: vehicleId=${data.vehicleId}`);
      return undefined;
    } catch (error) {
      this.logger.error('Error resolving vehicle ID:', error);
      return undefined;
    }
  }

  private calculateTotalDays(
    startDate: Date,
    endDate: Date,
    data: FirebaseBookingData,
  ): number {
    // Use provided total days if available
    if (data.totalDays) {
      const days = this.parseNumber(data.totalDays);
      if (days > 0) return days;
    }

    // Calculate from dates
    const diffTime = Math.abs(endDate.getTime() - startDate.getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays || 1;
  }

  private mapBookingStatus(status?: string): BookingStatus {
    if (!status) return BookingStatus.PENDING;

    const normalized = status.toLowerCase().replace(/[_\s-]/g, '');

    switch (normalized) {
      case 'confirmed':
      case 'approved':
        return BookingStatus.CONFIRMED;
      case 'inprogress':
      case 'active':
      case 'ongoing':
        return BookingStatus.IN_PROGRESS;
      case 'completed':
      case 'finished':
        return BookingStatus.COMPLETED;
      case 'cancelled':
      case 'canceled':
        return BookingStatus.CANCELLED;
      case 'refunded':
        return BookingStatus.REFUNDED;
      case 'pending':
      default:
        return BookingStatus.PENDING;
    }
  }

  private mapPaymentStatus(status?: string): PaymentStatus {
    if (!status) return PaymentStatus.PENDING;

    const normalized = status.toLowerCase().replace(/[_\s-]/g, '');

    switch (normalized) {
      case 'paid':
      case 'completed':
      case 'success':
        return PaymentStatus.PAID;
      case 'failed':
      case 'error':
        return PaymentStatus.FAILED;
      case 'refunded':
        return PaymentStatus.REFUNDED;
      case 'partial':
      case 'partialpayment':
        return PaymentStatus.PARTIAL;
      case 'pending':
      default:
        return PaymentStatus.PENDING;
    }
  }

  private parseNumber(value: any): number {
    if (typeof value === 'number') return value;
    if (typeof value === 'string') {
      const parsed = parseFloat(value);
      return isNaN(parsed) ? 0 : parsed;
    }
    return 0;
  }

  private parseDate(timestamp: any): Date | undefined {
    if (!timestamp) return undefined;

    if (timestamp._seconds !== undefined) {
      return new Date(timestamp._seconds * 1000);
    }

    if (timestamp.toDate && typeof timestamp.toDate === 'function') {
      return timestamp.toDate();
    }

    if (typeof timestamp === 'string' || typeof timestamp === 'number') {
      const date = new Date(timestamp);
      return isNaN(date.getTime()) ? undefined : date;
    }

    return undefined;
  }
}
