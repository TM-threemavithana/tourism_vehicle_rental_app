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
import { MigrationModule } from './migrations/migration.module';

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
      useFactory: async (configService: ConfigService) => {
        const redisUrl = configService.get<string>('REDIS_URL');
        
        if (redisUrl) {
          try {
            // Use Redis/Valkey for caching
            const { redisStore } = await import('cache-manager-ioredis');
            return {
              store: redisStore,
              url: redisUrl,
              ttl: 300, // 5 minutes default TTL
              max: 1000, // Maximum number of items in cache
              retryAttempts: 3,
              retryDelay: 1000,
            };
          } catch (error) {
            console.warn('Failed to load Redis store, falling back to memory cache:', error);
            return {
              ttl: 300,
              max: 1000,
            };
          }
        } else {
          // Fallback to memory cache for development
          console.warn('REDIS_URL not found, using memory cache');
          return {
            ttl: 300,
            max: 1000,
          };
        }
      },
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

    // Migration module for Firebase to PostgreSQL migration
    MigrationModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
