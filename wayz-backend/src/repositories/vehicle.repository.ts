import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Vehicle } from '../entities/vehicle.entity';
import { CreateVehicleDto, UpdateVehicleDto } from '../dtos/vehicle.dto';

@Injectable()
export class VehicleRepository {
  constructor(
    @InjectRepository(Vehicle)
    private readonly repository: Repository<Vehicle>,
  ) {}

  async create(createVehicleDto: CreateVehicleDto): Promise<Vehicle> {
    const vehicle = this.repository.create(createVehicleDto);
    return await this.repository.save(vehicle);
  }

  async findAll(): Promise<Vehicle[]> {
    return await this.repository.find({
      where: { isActive: true, isAvailable: true },
      relations: ['category', 'owner', 'reviews'],
      order: { createdAt: 'DESC' },
    });
  }

  async findById(id: string): Promise<Vehicle | null> {
    return await this.repository.findOne({
      where: { id, isActive: true },
      relations: ['category', 'owner', 'bookings', 'reviews', 'favorites'],
    });
  }

  async findByOwner(ownerId: string): Promise<Vehicle[]> {
    return await this.repository.find({
      where: { ownerId, isActive: true },
      relations: ['category', 'bookings'],
      order: { createdAt: 'DESC' },
    });
  }

  async findAvailable(startDate: Date, endDate: Date): Promise<Vehicle[]> {
    // This is a simplified availability check
    // In production, you'd want more complex logic to check for booking conflicts
    return await this.repository.find({
      where: { isActive: true, isAvailable: true },
      relations: ['category', 'reviews'],
    });
  }

  async findByLocation(
    lat: number,
    lng: number,
    radiusKm: number = 50,
  ): Promise<Vehicle[]> {
    // Simplified location search - in production use PostGIS functions
    return await this.repository
      .createQueryBuilder('vehicle')
      .leftJoinAndSelect('vehicle.category', 'category')
      .leftJoinAndSelect('vehicle.reviews', 'reviews')
      .where('vehicle.isActive = :isActive', { isActive: true })
      .andWhere('vehicle.isAvailable = :isAvailable', { isAvailable: true })
      .andWhere(
        'vehicle.locationLat IS NOT NULL AND vehicle.locationLng IS NOT NULL',
      )
      .orderBy('vehicle.createdAt', 'DESC')
      .getMany();
  }

  async findByPriceRange(
    minPrice: number,
    maxPrice: number,
  ): Promise<Vehicle[]> {
    return await this.repository.find({
      where: {
        isActive: true,
        isAvailable: true,
        dailyRate: Between(minPrice, maxPrice),
      },
      relations: ['category', 'reviews'],
      order: { dailyRate: 'ASC' },
    });
  }

  async findByCategory(categoryId: string): Promise<Vehicle[]> {
    return await this.repository.find({
      where: { categoryId, isActive: true, isAvailable: true },
      relations: ['category', 'reviews'],
      order: { createdAt: 'DESC' },
    });
  }

  async update(
    id: string,
    updateVehicleDto: UpdateVehicleDto,
  ): Promise<Vehicle | null> {
    await this.repository.update(id, updateVehicleDto);
    return await this.findById(id);
  }

  async updateAvailability(id: string, isAvailable: boolean): Promise<void> {
    await this.repository.update(id, { isAvailable });
  }

  async softDelete(id: string): Promise<void> {
    await this.repository.update(id, { isActive: false });
  }

  async delete(id: string): Promise<void> {
    await this.repository.delete(id);
  }

  async count(): Promise<number> {
    return await this.repository.count({
      where: { isActive: true, isAvailable: true },
    });
  }

  async getPopularVehicles(limit: number = 10): Promise<Vehicle[]> {
    return await this.repository
      .createQueryBuilder('vehicle')
      .leftJoinAndSelect('vehicle.category', 'category')
      .leftJoinAndSelect('vehicle.reviews', 'reviews')
      .leftJoinAndSelect('vehicle.bookings', 'bookings')
      .where('vehicle.isActive = :isActive', { isActive: true })
      .andWhere('vehicle.isAvailable = :isAvailable', { isAvailable: true })
      .groupBy('vehicle.id')
      .addGroupBy('category.id')
      .orderBy('COUNT(bookings.id)', 'DESC')
      .addOrderBy('AVG(reviews.rating)', 'DESC')
      .limit(limit)
      .getMany();
  }
}
