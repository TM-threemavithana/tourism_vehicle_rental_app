import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CacheModule } from '@nestjs/cache-manager';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { CommonModule } from './common/common.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { VehiclesModule } from './vehicles/vehicles.module';
import { BookingsModule } from './bookings/bookings.module';
import { ReviewsModule } from './reviews/reviews.module';
import { FavoritesModule } from './favorites/favorites.module';
import { NotificationsModule } from './notifications/notifications.module';
import { VehicleCategoriesModule } from './vehicle-categories/vehicle-categories.module';
import { CacheServiceModule } from './cache/cache.module';

@Module({
  imports: [
    // Configuration module
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    // Database module
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get('DATABASE_HOST'),
        port: configService.get('DATABASE_PORT'),
        username: configService.get('DATABASE_USERNAME'),
        password: configService.get('DATABASE_PASSWORD'),
        database: configService.get('DATABASE_NAME'),
        // SSL configuration for cloud databases (Aiven.io requires SSL)
        ssl: {
          rejectUnauthorized: false, // Accept self-signed certificates for managed services
        },
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        autoLoadEntities: true,
        synchronize: false, // Never use in production - we have SQL schema
        logging: configService.get('NODE_ENV') === 'development',
      }),
    }),

    // Cache module with Valkey (Redis-compatible) integration
    CacheModule.registerAsync({
      isGlobal: true,
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        ttl: 300, // 5 minutes default TTL
        max: 1000, // Maximum number of items in cache
        // For now using memory cache, will upgrade to Redis in production
        // TODO: Implement proper Redis store configuration
        host: configService.get('REDIS_HOST'),
        port: configService.get('REDIS_PORT'),
      }),
    }),

    // Common module with Firebase and dual-write services
    CommonModule,

    // Cache service module
    CacheServiceModule,

    // Authentication module
    AuthModule,

    // Feature modules
    UsersModule,
    VehiclesModule,
    BookingsModule,
    ReviewsModule,
    FavoritesModule,
    NotificationsModule,
    VehicleCategoriesModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
