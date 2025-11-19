import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { CacheServiceModule } from '../cache/cache.module';
import { ThrottlerRedisStorage } from './throttler-redis-storage.service';

@Module({
  imports: [
    // Global throttler configuration with Redis storage
    // eslint-disable-next-line @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access
    ThrottlerModule.forRootAsync({
      imports: [CacheServiceModule],
      inject: [ThrottlerRedisStorage],
      useFactory: (storage: ThrottlerRedisStorage) => ({
        throttlers: [
          {
            name: 'default',
            ttl: 60000, // 1 minute window
            limit: 100, // 100 requests per minute for general endpoints
          },
          {
            name: 'strict',
            ttl: 60000, // 1 minute window
            limit: 20, // 20 requests per minute for sensitive endpoints
          },
        ],
        storage,
      }),
    }),
    CacheServiceModule,
  ],
  providers: [
    ThrottlerRedisStorage,
    {
      provide: APP_GUARD,
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      useClass: ThrottlerGuard,
    },
  ],
  exports: [ThrottlerRedisStorage],
})
export class ThrottlerConfigModule {}

