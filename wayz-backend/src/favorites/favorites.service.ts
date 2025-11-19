import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Favorite } from '../entities/favorite.entity';
import { CreateFavoriteDto } from '../dto/favorite.dto';
import { CacheService } from '../cache/cache.service';

@Injectable()
export class FavoritesService {
  private readonly logger = new Logger(FavoritesService.name);
  private readonly CACHE_TTL = 300; // 5 minutes

  constructor(
    @InjectRepository(Favorite)
    private readonly favoritesRepository: Repository<Favorite>,
    private readonly cacheService: CacheService,
  ) {}

  async create(
    userId: string,
    createFavoriteDto: CreateFavoriteDto,
  ): Promise<Favorite> {
    // Check if already favorited
    const existing = await this.favoritesRepository
      .createQueryBuilder('favorite')
      .where('favorite.userId = :userId', { userId })
      .andWhere('favorite.vehicleId = :vehicleId', {
        vehicleId: createFavoriteDto.vehicleId,
      })
      .getOne();

    if (existing) {
      throw new BadRequestException('Vehicle already in favorites');
    }

    const favorite = this.favoritesRepository.create({
      ...createFavoriteDto,
      userId,
    });

    const savedFavorite = await this.favoritesRepository.save(favorite);

    // Invalidate user favorites cache
    await this.invalidateFavoritesCaches(userId);

    return savedFavorite;
  }

  async findUserFavorites(userId: string): Promise<Favorite[]> {
    const cacheKey = `favorites:user:${userId}`;

    const cached = await this.cacheService.get<Favorite[]>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const favorites = await this.favoritesRepository
      .createQueryBuilder('favorite')
      .leftJoinAndSelect('favorite.vehicle', 'vehicle')
      .leftJoinAndSelect('vehicle.category', 'category')
      .where('favorite.userId = :userId', { userId })
      .orderBy('favorite.createdAt', 'DESC')
      .getMany();

    await this.cacheService.set(cacheKey, favorites, this.CACHE_TTL);
    return favorites;
  }

  async remove(userId: string, vehicleId: string): Promise<void> {
    const favorite = await this.favoritesRepository
      .createQueryBuilder('favorite')
      .where('favorite.userId = :userId', { userId })
      .andWhere('favorite.vehicleId = :vehicleId', { vehicleId })
      .getOne();

    if (!favorite) {
      throw new NotFoundException('Favorite not found');
    }

    await this.favoritesRepository.remove(favorite);

    // Invalidate user favorites cache
    await this.invalidateFavoritesCaches(userId, vehicleId);
  }

  async checkIfFavorite(userId: string, vehicleId: string): Promise<boolean> {
    const cacheKey = `favorite:check:${userId}:${vehicleId}`;

    const cached = await this.cacheService.get<boolean>(cacheKey);
    if (cached !== null && cached !== undefined) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const favorite = await this.favoritesRepository
      .createQueryBuilder('favorite')
      .where('favorite.userId = :userId', { userId })
      .andWhere('favorite.vehicleId = :vehicleId', { vehicleId })
      .getOne();

    const isFavorite = !!favorite;
    await this.cacheService.set(cacheKey, isFavorite, this.CACHE_TTL);

    return isFavorite;
  }

  // Cache invalidation helper
  private async invalidateFavoritesCaches(
    userId: string,
    vehicleId?: string,
  ): Promise<void> {
    const keysToDelete = [`favorites:user:${userId}`];

    if (vehicleId) {
      keysToDelete.push(`favorite:check:${userId}:${vehicleId}`);
    }

    await Promise.all(keysToDelete.map((key) => this.cacheService.del(key)));
    this.logger.debug(`Invalidated caches: ${keysToDelete.join(', ')}`);
  }
}
