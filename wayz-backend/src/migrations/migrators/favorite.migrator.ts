import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Favorite } from '../../entities/favorite.entity';
import { User } from '../../entities/user.entity';
import { Vehicle } from '../../entities/vehicle.entity';

interface FirebaseFavoriteData {
  userId?: string;
  userEmail?: string;
  vehicleId?: string;
  createdAt?: any;
  [key: string]: any;
}

@Injectable()
export class FavoriteMigrator {
  private readonly logger = new Logger(FavoriteMigrator.name);

  constructor(
    @InjectRepository(Favorite)
    private readonly favoriteRepository: Repository<Favorite>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Vehicle)
    private readonly vehicleRepository: Repository<Vehicle>,
  ) {}

  async migrate(
    firebaseDocId: string,
    data: FirebaseFavoriteData,
  ): Promise<Favorite> {
    try {
      // Resolve user and vehicle IDs
      const userId = await this.resolveUserId(data);
      const vehicleId = await this.resolveVehicleId(data);

      if (!userId || !vehicleId) {
        throw new Error(
          `Cannot create favorite: user or vehicle not found (userId: ${data.userId}, vehicleId: ${data.vehicleId})`,
        );
      }

      // Check if favorite already exists
      const existingFavorite = await this.favoriteRepository.findOne({
        where: { userId, vehicleId },
      });

      if (existingFavorite) {
        this.logger.debug(
          `Favorite already exists for user ${userId} and vehicle ${vehicleId}`,
        );
        return existingFavorite;
      }

      const favorite = this.favoriteRepository.create({
        userId,
        vehicleId,
        createdAt: this.parseDate(data.createdAt) || new Date(),
      });

      const savedFavorite = await this.favoriteRepository.save(favorite);
      this.logger.debug(`✅ Created favorite: ${savedFavorite.id}`);
      return savedFavorite;
    } catch (error) {
      this.logger.error(
        `Failed to migrate favorite ${firebaseDocId}:`,
        error.message,
      );
      throw error;
    }
  }

  private async resolveUserId(
    data: FirebaseFavoriteData,
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
    data: FirebaseFavoriteData,
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
