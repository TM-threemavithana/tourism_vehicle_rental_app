import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Review } from '../../entities/review.entity';
import { User } from '../../entities/user.entity';
import { Vehicle } from '../../entities/vehicle.entity';
import { Booking } from '../../entities/booking.entity';

interface FirebaseReviewData {
  // User info
  userId?: string;
  userEmail?: string;
  userName?: string;

  // Vehicle info
  vehicleId?: string;

  // Booking info (optional)
  bookingId?: string;

  // Rating
  rating?: number | string;
  overallRating?: number | string;

  // Review content
  review?: string;
  comment?: string;
  feedback?: string;

  // Specific ratings (optional)
  cleanliness?: number | string;
  communication?: number | string;
  valueForMoney?: number | string;
  accuracy?: number | string;

  // Timestamps
  createdAt?: any;
  updatedAt?: any;

  [key: string]: any;
}

@Injectable()
export class ReviewMigrator {
  private readonly logger = new Logger(ReviewMigrator.name);

  constructor(
    @InjectRepository(Review)
    private readonly reviewRepository: Repository<Review>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Vehicle)
    private readonly vehicleRepository: Repository<Vehicle>,
    @InjectRepository(Booking)
    private readonly bookingRepository: Repository<Booking>,
  ) {}

  async migrate(
    firebaseDocId: string,
    data: FirebaseReviewData,
  ): Promise<Review> {
    try {
      // Check if review already exists
      const existingReview = await this.reviewRepository.findOne({
        where: { firebaseDocId },
      });

      if (existingReview) {
        this.logger.debug(
          `Review already exists: ${firebaseDocId}, updating...`,
        );
        return await this.updateReview(existingReview, data);
      }

      return await this.createReview(firebaseDocId, data);
    } catch (error) {
      this.logger.error(
        `Failed to migrate review ${firebaseDocId}:`,
        error.message,
      );
      throw error;
    }
  }

  private async createReview(
    firebaseDocId: string,
    data: FirebaseReviewData,
  ): Promise<Review> {
    // Resolve IDs
    const userId = await this.resolveUserId(data);
    const vehicleId = await this.resolveVehicleId(data);
    const bookingId = await this.resolveBookingId(data);

    if (!userId) {
      throw new Error(
        `Cannot create review: user not found (userId: ${data.userId}, email: ${data.userEmail})`,
      );
    }

    if (!vehicleId) {
      throw new Error(
        `Cannot create review: vehicle not found (vehicleId: ${data.vehicleId})`,
      );
    }

    // Parse rating
    const rating = this.parseRating(data.rating || data.overallRating);

    if (!rating || rating < 1 || rating > 5) {
      throw new Error(`Invalid rating: ${rating}`);
    }

    // Get review content
    const comment = data.review || data.comment || data.feedback || '';

    const review = this.reviewRepository.create({
      firebaseDocId,
      userId,
      vehicleId,
      bookingId,
      rating,
      comment,
      createdAt: this.parseDate(data.createdAt) || new Date(),
      updatedAt: this.parseDate(data.updatedAt) || new Date(),
    });

    const savedReview = await this.reviewRepository.save(review);
    this.logger.debug(`✅ Created review: ${savedReview.id} (rating: ${rating})`);
    return savedReview;
  }

  private async updateReview(
    existingReview: Review,
    data: FirebaseReviewData,
  ): Promise<Review> {
    // Update rating if changed
    const rating = this.parseRating(data.rating || data.overallRating);
    if (rating && rating >= 1 && rating <= 5) {
      existingReview.rating = rating;
    }

    // Update comment if changed
    const comment = data.review || data.comment || data.feedback;
    if (comment) {
      existingReview.comment = comment;
    }

    const savedReview = await this.reviewRepository.save(existingReview);
    this.logger.debug(`✅ Updated review: ${savedReview.id}`);
    return savedReview;
  }

  private async resolveUserId(
    data: FirebaseReviewData,
  ): Promise<string | undefined> {
    if (!data.userId && !data.userEmail) {
      return undefined;
    }

    try {
      if (data.userId) {
        const user = await this.userRepository.findOne({
          where: { firebaseUid: data.userId },
        });
        if (user) return user.id;
      }

      if (data.userEmail) {
        const user = await this.userRepository.findOne({
          where: { email: data.userEmail },
        });
        if (user) return user.id;
      }

      return undefined;
    } catch (error) {
      this.logger.error('Error resolving user ID:', error);
      return undefined;
    }
  }

  private async resolveVehicleId(
    data: FirebaseReviewData,
  ): Promise<string | undefined> {
    if (!data.vehicleId) {
      return undefined;
    }

    try {
      const vehicle = await this.vehicleRepository.findOne({
        where: { firebaseDocId: data.vehicleId },
      });

      return vehicle?.id;
    } catch (error) {
      this.logger.error('Error resolving vehicle ID:', error);
      return undefined;
    }
  }

  private async resolveBookingId(
    data: FirebaseReviewData,
  ): Promise<string | undefined> {
    if (!data.bookingId) {
      return undefined;
    }

    try {
      const booking = await this.bookingRepository.findOne({
        where: { firebaseDocId: data.bookingId },
      });

      return booking?.id;
    } catch (error) {
      this.logger.error('Error resolving booking ID:', error);
      return undefined;
    }
  }

  private parseRating(rating: any): number {
    if (typeof rating === 'number') return rating;
    if (typeof rating === 'string') {
      const parsed = parseFloat(rating);
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
