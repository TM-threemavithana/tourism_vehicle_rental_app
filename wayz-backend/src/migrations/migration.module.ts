import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { MigrationService } from './migration.service';
import { MigrationController } from './migration.controller';
import { UserMigrator } from './migrators/user.migrator';
import { VehicleMigrator } from './migrators/vehicle.migrator';
import { BookingMigrator } from './migrators/booking.migrator';
import { FavoriteMigrator } from './migrators/favorite.migrator';
import { ReviewMigrator } from './migrators/review.migrator';
import { User } from '../entities/user.entity';
import { Vehicle } from '../entities/vehicle.entity';
import { Booking } from '../entities/booking.entity';
import { Favorite } from '../entities/favorite.entity';
import { Review } from '../entities/review.entity';
import { VehicleCategory } from '../entities/vehicle-category.entity';
import { Notification } from '../entities/notification.entity';
import { PaymentTransaction } from '../entities/payment-transaction.entity';

@Module({
  imports: [
    ConfigModule,
    TypeOrmModule.forFeature([
      User,
      Vehicle,
      Booking,
      Favorite,
      Review,
      VehicleCategory,
      Notification,
      PaymentTransaction,
    ]),
  ],
  controllers: [MigrationController],
  providers: [
    MigrationService,
    UserMigrator,
    VehicleMigrator,
    BookingMigrator,
    FavoriteMigrator,
    ReviewMigrator,
  ],
  exports: [MigrationService],
})
export class MigrationModule {}
