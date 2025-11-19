import { Module, Global } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { RateLimitInterceptor } from '../auth/interceptors/rate-limit.interceptor';
import { CacheServiceModule } from '../cache/cache.module';

@Global()
@Module({
  imports: [CacheServiceModule],
  providers: [
    {
      provide: APP_INTERCEPTOR,
      useClass: RateLimitInterceptor,
    },
  ],
})
export class RateLimitModule {}
