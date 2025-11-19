import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { VehicleCategory } from '../entities/vehicle-category.entity';
import {
  CreateVehicleCategoryDto,
  UpdateVehicleCategoryDto,
} from '../dto/vehicle-category.dto';
import { CacheService } from '../cache/cache.service';

@Injectable()
export class VehicleCategoriesService {
  private readonly logger = new Logger(VehicleCategoriesService.name);
  private readonly CACHE_TTL = 900; // 15 minutes - categories rarely change

  constructor(
    @InjectRepository(VehicleCategory)
    private readonly categoriesRepository: Repository<VehicleCategory>,
    private readonly cacheService: CacheService,
  ) {}

  async create(
    createCategoryDto: CreateVehicleCategoryDto,
  ): Promise<VehicleCategory> {
    const category = this.categoriesRepository.create(createCategoryDto);
    const savedCategory = await this.categoriesRepository.save(category);

    // Invalidate list caches
    await this.invalidateCategoryCaches();

    return savedCategory;
  }

  async findAll(): Promise<VehicleCategory[]> {
    const cacheKey = 'categories:all';

    const cached = await this.cacheService.get<VehicleCategory[]>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const categories = await this.categoriesRepository
      .createQueryBuilder('category')
      .leftJoinAndSelect('category.vehicles', 'vehicle')
      .orderBy('category.displayOrder', 'ASC')
      .addOrderBy('category.name', 'ASC')
      .getMany();

    await this.cacheService.set(cacheKey, categories, this.CACHE_TTL);
    return categories;
  }

  async findOne(id: string): Promise<VehicleCategory> {
    const cacheKey = `category:${id}`;

    const cached = await this.cacheService.get<VehicleCategory>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const category = await this.categoriesRepository
      .createQueryBuilder('category')
      .leftJoinAndSelect('category.vehicles', 'vehicle')
      .where('category.id = :id', { id })
      .getOne();

    if (!category) {
      throw new NotFoundException(`Vehicle category with ID ${id} not found`);
    }

    await this.cacheService.set(cacheKey, category, this.CACHE_TTL);
    return category;
  }

  async update(
    id: string,
    updateCategoryDto: UpdateVehicleCategoryDto,
  ): Promise<VehicleCategory> {
    const category = await this.findOne(id);
    Object.assign(category, updateCategoryDto);
    const updatedCategory = await this.categoriesRepository.save(category);

    // Invalidate caches
    await this.invalidateCategoryCaches(id);

    return updatedCategory;
  }

  async remove(id: string): Promise<void> {
    const category = await this.findOne(id);
    await this.categoriesRepository.remove(category);

    // Invalidate caches
    await this.invalidateCategoryCaches(id);
  }

  async getCategoriesWithStats(): Promise<any[]> {
    const cacheKey = 'categories:stats';

    const cached = await this.cacheService.get<any[]>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const categories = await this.categoriesRepository
      .createQueryBuilder('category')
      .leftJoinAndSelect('category.vehicles', 'vehicle')
      .loadRelationCountAndMap('category.vehicleCount', 'category.vehicles')
      .orderBy('category.displayOrder', 'ASC')
      .addOrderBy('category.name', 'ASC')
      .getMany();

    await this.cacheService.set(cacheKey, categories, this.CACHE_TTL);
    return categories;
  }

  // Cache invalidation helper
  private async invalidateCategoryCaches(id?: string): Promise<void> {
    const keysToDelete = ['categories:all', 'categories:stats'];

    if (id) {
      keysToDelete.push(`category:${id}`);
    }

    await Promise.all(keysToDelete.map((key) => this.cacheService.del(key)));
    this.logger.debug(`Invalidated caches: ${keysToDelete.join(', ')}`);
  }
}
