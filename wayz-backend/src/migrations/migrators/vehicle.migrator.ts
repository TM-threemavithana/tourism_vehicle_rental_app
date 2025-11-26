import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Vehicle } from '../../entities/vehicle.entity';
import { User } from '../../entities/user.entity';
import { VehicleCategory } from '../../entities/vehicle-category.entity';

interface FirebaseVehicleData {
  // Basic info
  type?: string;
  make?: string;
  model?: string;
  category?: string;
  grade?: string;
  year?: string | number;
  vehicleNo?: string;
  engineCapacity?: string;
  transmission?: string;
  fuelType?: string;
  seatingCapacity?: string | number;
  color?: string;

  // Collection point / Location
  collectionPoint?: {
    district?: string;
    city?: string;
    address?: string;
  };
  location?: {
    lat?: number;
    lng?: number;
  };

  // Owner info
  ownerId?: string;
  ownerEmail?: string;

  // Rental conditions
  rentalConditions?: {
    minRentalPeriod?: { value: string; unit: string };
    maxRentalPeriod?: { value: string; unit: string };
    advanceRentalPeriod?: { value: string; unit: string };
    rentMode?: string;
  };

  // Driver details
  driverDetails?: {
    name?: string;
    licenseNo?: string;
  };

  // Pricing
  vehicleValue?: string | number;
  rentalPeriods?: Record<string, boolean>;
  hourlyPricing?: any;
  dailyPricing?: any;
  weeklyPricing?: any;
  monthlyPricing?: any;

  // Images
  images?: string[];
  coverImage?: string;

  // Status
  status?: string;
  isActive?: boolean;
  isAvailable?: boolean;

  // Timestamps
  createdAt?: any;
  updatedAt?: any;

  // Description
  description?: string;
  features?: string[] | Record<string, any>;

  [key: string]: any;
}

@Injectable()
export class VehicleMigrator {
  private readonly logger = new Logger(VehicleMigrator.name);

  constructor(
    @InjectRepository(Vehicle)
    private readonly vehicleRepository: Repository<Vehicle>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(VehicleCategory)
    private readonly categoryRepository: Repository<VehicleCategory>,
  ) {}

  async migrate(
    firebaseDocId: string,
    data: FirebaseVehicleData,
  ): Promise<Vehicle> {
    try {
      // Check if vehicle already exists
      const existingVehicle = await this.vehicleRepository.findOne({
        where: { firebaseDocId },
      });

      if (existingVehicle) {
        this.logger.debug(
          `Vehicle already exists: ${firebaseDocId}, updating...`,
        );
        return await this.updateVehicle(existingVehicle, data);
      }

      return await this.createVehicle(firebaseDocId, data);
    } catch (error) {
      this.logger.error(
        `Failed to migrate vehicle ${firebaseDocId}:`,
        error.message,
      );
      throw error;
    }
  }

  private async createVehicle(
    firebaseDocId: string,
    data: FirebaseVehicleData,
  ): Promise<Vehicle> {
    // Find or create owner
    const ownerId = await this.resolveOwnerId(data);

    // Find or create category
    const categoryId = await this.resolveCategoryId(data.category);

    // Parse daily rate from pricing data
    const dailyRate = this.parseDailyRate(data);

    // Parse year
    const year = typeof data.year === 'string' ? parseInt(data.year, 10) : data.year;

    // Parse seating capacity
    const seats =
      typeof data.seatingCapacity === 'string'
        ? parseInt(data.seatingCapacity, 10)
        : data.seatingCapacity;

    const vehicle = this.vehicleRepository.create({
      firebaseDocId,
      categoryId,
      ownerId,
      make: data.make || 'Unknown',
      model: data.model || 'Unknown',
      year: year || new Date().getFullYear(),
      color: data.color,
      licensePlate: data.vehicleNo,
      dailyRate: dailyRate || 0,
      fuelType: data.fuelType,
      transmission: data.transmission,
      seats,
      locationLat: data.location?.lat,
      locationLng: data.location?.lng,
      locationAddress:
        data.collectionPoint?.address || data.collectionPoint?.city,
      locationCity: data.collectionPoint?.city,
      features: this.parseFeatures(data.features),
      description: this.buildDescription(data),
      rules: this.buildRules(data),
      images: data.images || [],
      isActive: data.status !== 'inactive' && data.status !== 'maintenance',
      isAvailable: data.isAvailable !== false,
      createdAt: this.parseDate(data.createdAt) || new Date(),
      updatedAt: this.parseDate(data.updatedAt) || new Date(),
    } as any);

    const savedVehicle = await this.vehicleRepository.save(vehicle);
    const vehicleResult = Array.isArray(savedVehicle) ? savedVehicle[0] : savedVehicle;
    this.logger.debug(
      `✅ Created vehicle: ${vehicleResult.make} ${vehicleResult.model}`,
    );
    return vehicleResult;
  }

  private async updateVehicle(
    existingVehicle: Vehicle,
    data: FirebaseVehicleData,
  ): Promise<Vehicle> {
    const ownerId = await this.resolveOwnerId(data);
    const categoryId = await this.resolveCategoryId(data.category);
    const dailyRate = this.parseDailyRate(data);

    // Update fields that might have changed
    existingVehicle.ownerId = ownerId || existingVehicle.ownerId;
    existingVehicle.categoryId = categoryId || existingVehicle.categoryId;
    existingVehicle.make = data.make || existingVehicle.make;
    existingVehicle.model = data.model || existingVehicle.model;
    existingVehicle.licensePlate = data.vehicleNo || existingVehicle.licensePlate;
    existingVehicle.dailyRate = dailyRate || existingVehicle.dailyRate;
    existingVehicle.locationAddress =
      data.collectionPoint?.address || existingVehicle.locationAddress;
    existingVehicle.locationCity =
      data.collectionPoint?.city || existingVehicle.locationCity;
    existingVehicle.images = data.images || existingVehicle.images;
    existingVehicle.isAvailable =
      data.isAvailable !== undefined
        ? data.isAvailable
        : existingVehicle.isAvailable;

    const savedVehicle = await this.vehicleRepository.save(existingVehicle);
    this.logger.debug(
      `✅ Updated vehicle: ${savedVehicle.make} ${savedVehicle.model}`,
    );
    return savedVehicle;
  }

  private async resolveOwnerId(
    data: FirebaseVehicleData,
  ): Promise<string | undefined> {
    if (!data.ownerId && !data.ownerEmail) {
      return undefined;
    }

    try {
      // Try to find by Firebase UID first
      if (data.ownerId) {
        const owner = await this.userRepository.findOne({
          where: { firebaseUid: data.ownerId },
        });
        if (owner) return owner.id;
      }

      // Try to find by email
      if (data.ownerEmail) {
        const owner = await this.userRepository.findOne({
          where: { email: data.ownerEmail },
        });
        if (owner) return owner.id;
      }

      this.logger.warn(
        `Owner not found for vehicle: ownerId=${data.ownerId}, ownerEmail=${data.ownerEmail}`,
      );
      return undefined;
    } catch (error) {
      this.logger.error('Error resolving owner ID:', error);
      return undefined;
    }
  }

  private async resolveCategoryId(
    categoryName?: string,
  ): Promise<string | undefined> {
    if (!categoryName) return undefined;

    try {
      let category = await this.categoryRepository.findOne({
        where: { name: categoryName },
      });

      if (!category) {
        // Create category if it doesn't exist
        category = this.categoryRepository.create({
          name: categoryName,
          description: `Auto-created category during migration: ${categoryName}`,
          isActive: true,
        });
        category = await this.categoryRepository.save(category);
        this.logger.debug(`✅ Created category: ${categoryName}`);
      }

      return category.id;
    } catch (error) {
      this.logger.error('Error resolving category ID:', error);
      return undefined;
    }
  }

  private parseDailyRate(data: FirebaseVehicleData): number {
    // Try to extract from dailyPricing
    if (data.dailyPricing?.baseRate) {
      return parseFloat(data.dailyPricing.baseRate);
    }

    // Try vehicleValue as fallback
    if (data.vehicleValue) {
      const value =
        typeof data.vehicleValue === 'string'
          ? parseFloat(data.vehicleValue)
          : data.vehicleValue;
      // Assume daily rate is a fraction of vehicle value (rough estimate)
      return value / 100;
    }

    return 0;
  }

  private parseFeatures(
    features?: string[] | Record<string, any>,
  ): Record<string, any> {
    if (!features) return {};

    if (Array.isArray(features)) {
      return { features };
    }

    return features;
  }

  private buildDescription(data: FirebaseVehicleData): string {
    let desc = data.description || '';

    if (!desc) {
      desc = `${data.make || ''} ${data.model || ''} ${data.year || ''}`.trim();
    }

    // Add additional details
    const details = [];
    if (data.fuelType) details.push(`Fuel: ${data.fuelType}`);
    if (data.transmission) details.push(`Transmission: ${data.transmission}`);
    if (data.seatingCapacity)
      details.push(`Seats: ${data.seatingCapacity}`);
    if (data.engineCapacity)
      details.push(`Engine: ${data.engineCapacity}`);

    if (details.length > 0) {
      desc += '\n\n' + details.join(' • ');
    }

    return desc;
  }

  private buildRules(data: FirebaseVehicleData): string | undefined {
    const rules = [];

    if (data.rentalConditions?.minRentalPeriod) {
      rules.push(
        `Minimum rental: ${data.rentalConditions.minRentalPeriod.value} ${data.rentalConditions.minRentalPeriod.unit}`,
      );
    }

    if (data.rentalConditions?.maxRentalPeriod) {
      rules.push(
        `Maximum rental: ${data.rentalConditions.maxRentalPeriod.value} ${data.rentalConditions.maxRentalPeriod.unit}`,
      );
    }

    if (data.rentalConditions?.advanceRentalPeriod) {
      rules.push(
        `Book in advance: ${data.rentalConditions.advanceRentalPeriod.value} ${data.rentalConditions.advanceRentalPeriod.unit}`,
      );
    }

    if (data.rentalConditions?.rentMode) {
      rules.push(`Rent mode: ${data.rentalConditions.rentMode}`);
    }

    return rules.length > 0 ? rules.join('\n') : undefined;
  }

  private mapStatus(
    status?: string,
    isAvailable?: boolean,
  ): 'active' | 'inactive' | 'maintenance' {
    if (status) {
      const normalized = status.toLowerCase();
      if (normalized === 'inactive' || normalized === 'disabled') {
        return 'inactive';
      }
      if (normalized === 'maintenance') {
        return 'maintenance';
      }
    }

    return isAvailable !== false ? 'active' : 'inactive';
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
