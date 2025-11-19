import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Review } from '../entities/review.entity';
import { CreateReviewDto, UpdateReviewDto } from '../dto/review.dto';
import { CacheService } from '../cache/cache.service';

@Injectable()
export class ReviewsService {
  private readonly logger = new Logger(ReviewsService.name);
  private readonly CACHE_TTL = 300; // 5 minutes
  private readonly RATING_CACHE_TTL = 600; // 10 minutes for ratings

  constructor(
    @InjectRepository(Review)
    private readonly reviewsRepository: Repository<Review>,
    private readonly cacheService: CacheService,
  ) {}

  async create(
    userId: string,
    createReviewDto: CreateReviewDto,
  ): Promise<Review> {
    // Check if user already reviewed this vehicle
    const existingReview = await this.reviewsRepository
      .createQueryBuilder('review')
      .where('review.userId = :userId', { userId })
      .andWhere('review.vehicleId = :vehicleId', {
        vehicleId: createReviewDto.vehicleId,
      })
      .getOne();

    if (existingReview) {
      throw new BadRequestException('User has already reviewed this vehicle');
    }

    const review = this.reviewsRepository.create({
      ...createReviewDto,
      userId,
    });

    const savedReview = await this.reviewsRepository.save(review);

    // Invalidate related caches
    await this.invalidateReviewCaches(userId, createReviewDto.vehicleId);

    return savedReview;
  }

  async findAll(vehicleId?: string): Promise<Review[]> {
    const cacheKey = vehicleId
      ? `reviews:vehicle:${vehicleId}:all`
      : 'reviews:all';

    const cached = await this.cacheService.get<Review[]>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const queryBuilder = this.reviewsRepository
      .createQueryBuilder('review')
      .leftJoinAndSelect('review.user', 'user')
      .leftJoinAndSelect('review.vehicle', 'vehicle')
      .leftJoinAndSelect('review.booking', 'booking')
      .orderBy('review.createdAt', 'DESC');

    if (vehicleId) {
      queryBuilder.andWhere('review.vehicleId = :vehicleId', { vehicleId });
    }

    const reviews = await queryBuilder.getMany();
    await this.cacheService.set(cacheKey, reviews, this.CACHE_TTL);

    return reviews;
  }

  async findOne(id: string): Promise<Review> {
    const cacheKey = `review:${id}`;

    const cached = await this.cacheService.get<Review>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const review = await this.reviewsRepository
      .createQueryBuilder('review')
      .leftJoinAndSelect('review.user', 'user')
      .leftJoinAndSelect('review.vehicle', 'vehicle')
      .leftJoinAndSelect('review.booking', 'booking')
      .where('review.id = :id', { id })
      .getOne();

    if (!review) {
      throw new NotFoundException(`Review with ID ${id} not found`);
    }

    await this.cacheService.set(cacheKey, review, this.CACHE_TTL);
    return review;
  }

  async update(
    id: string,
    userId: string,
    updateReviewDto: UpdateReviewDto,
  ): Promise<Review> {
    const review = await this.findOne(id);

    if (review.user.id !== userId) {
      throw new BadRequestException('You can only update your own reviews');
    }

    Object.assign(review, updateReviewDto);
    const updatedReview = await this.reviewsRepository.save(review);

    // Invalidate related caches
    await this.invalidateReviewCaches(userId, review.vehicle.id, id);

    return updatedReview;
  }

  async remove(id: string, userId: string): Promise<void> {
    const review = await this.findOne(id);

    if (review.user.id !== userId) {
      throw new BadRequestException('You can only delete your own reviews');
    }

    await this.reviewsRepository.remove(review);

    // Invalidate related caches
    await this.invalidateReviewCaches(userId, review.vehicle.id, id);
  }

  async getVehicleReviews(vehicleId: string): Promise<Review[]> {
    const cacheKey = `reviews:vehicle:${vehicleId}`;

    const cached = await this.cacheService.get<Review[]>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const reviews = await this.reviewsRepository
      .createQueryBuilder('review')
      .leftJoinAndSelect('review.user', 'user')
      .leftJoinAndSelect('review.booking', 'booking')
      .where('review.vehicleId = :vehicleId', { vehicleId })
      .orderBy('review.createdAt', 'DESC')
      .getMany();

    await this.cacheService.set(cacheKey, reviews, this.CACHE_TTL);
    return reviews;
  }

  async getUserReviews(userId: string): Promise<Review[]> {
    const cacheKey = `reviews:user:${userId}`;

    const cached = await this.cacheService.get<Review[]>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const reviews = await this.reviewsRepository
      .createQueryBuilder('review')
      .leftJoinAndSelect('review.vehicle', 'vehicle')
      .leftJoinAndSelect('review.booking', 'booking')
      .where('review.userId = :userId', { userId })
      .orderBy('review.createdAt', 'DESC')
      .getMany();

    await this.cacheService.set(cacheKey, reviews, this.CACHE_TTL);
    return reviews;
  }

  async getVehicleAverageRating(
    vehicleId: string,
  ): Promise<{ averageRating: number; reviewCount: number }> {
    const cacheKey = `reviews:vehicle:${vehicleId}:rating`;

    const cached = await this.cacheService.get<{
      averageRating: number;
      reviewCount: number;
    }>(cacheKey);

    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const result = (await this.reviewsRepository
      .createQueryBuilder('review')
      .select('AVG(review.rating)', 'averageRating')
      .addSelect('COUNT(review.id)', 'reviewCount')
      .where('review.vehicleId = :vehicleId', { vehicleId })
      .getRawOne()) as { averageRating: string; reviewCount: string };

    const rating = {
      averageRating: parseFloat(result.averageRating) || 0,
      reviewCount: parseInt(result.reviewCount, 10) || 0,
    };

    await this.cacheService.set(cacheKey, rating, this.RATING_CACHE_TTL);
    return rating;
  }

  async getReviewStats(): Promise<{
    totalReviews: number;
    averageRating: number;
    ratingDistribution: any[];
  }> {
    const cacheKey = 'reviews:stats';

    const cached = await this.cacheService.get<{
      totalReviews: number;
      averageRating: number;
      ratingDistribution: any[];
    }>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const totalReviews = await this.reviewsRepository.count();

    const ratingDistribution = await this.reviewsRepository
      .createQueryBuilder('review')
      .select('FLOOR(review.rating)', 'rating')
      .addSelect('COUNT(review.id)', 'count')
      .groupBy('FLOOR(review.rating)')
      .orderBy('rating', 'DESC')
      .getRawMany();

    const averageRatingResult = (await this.reviewsRepository
      .createQueryBuilder('review')
      .select('AVG(review.rating)', 'averageRating')
      .getRawOne()) as { averageRating: string };

    const stats = {
      totalReviews,
      averageRating: parseFloat(averageRatingResult.averageRating) || 0,
      ratingDistribution,
    };

    await this.cacheService.set(cacheKey, stats, this.RATING_CACHE_TTL);
    return stats;
  }

  // Cache invalidation helper
  private async invalidateReviewCaches(
    userId: string,
    vehicleId: string,
    reviewId?: string,
  ): Promise<void> {
    const keysToDelete = [
      'reviews:all',
      `reviews:user:${userId}`,
      `reviews:vehicle:${vehicleId}`,
      `reviews:vehicle:${vehicleId}:all`,
      `reviews:vehicle:${vehicleId}:rating`,
      'reviews:stats',
    ];

    if (reviewId) {
      keysToDelete.push(`review:${reviewId}`);
    }

    await Promise.all(keysToDelete.map((key) => this.cacheService.del(key)));
    this.logger.debug(`Invalidated caches: ${keysToDelete.join(', ')}`);
  }
}
