import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { CacheService } from '../../cache/cache.service';

@Injectable()
export class RateLimitInterceptor implements NestInterceptor {
  private readonly logger = new Logger(RateLimitInterceptor.name);
  private readonly RATE_LIMIT_PREFIX = 'rate:limit:';

  constructor(private readonly cacheService: CacheService) {}

  async intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Promise<Observable<any>> {
    const request = context.switchToHttp().getRequest();
    const identifier = this.getIdentifier(request);
    const endpoint = `${request.method}:${request.route?.path || request.url}`;

    // Get rate limit rules for this endpoint
    const limits = this.getRateLimits(endpoint);

    // Check all rate limit windows
    for (const limit of limits) {
      const allowed = await this.checkRateLimit(
        identifier,
        endpoint,
        limit.window,
        limit.max,
      );

      if (!allowed) {
        this.logger.warn(
          `Rate limit exceeded for ${identifier} on ${endpoint}`,
        );
        throw new HttpException(
          {
            statusCode: HttpStatus.TOO_MANY_REQUESTS,
            message: `Too many requests. Please try again in ${limit.window} seconds.`,
            error: 'Too Many Requests',
          },
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
    }

    return next.handle();
  }

  /**
   * Get identifier for rate limiting (user ID or IP address)
   */
  private getIdentifier(request: any): string {
    // Use user ID if authenticated, otherwise use IP
    const userId = request.user?.sub || request.user?.id;
    if (userId) {
      return `user:${userId}`;
    }

    // Get IP address
    const ip =
      request.ip ||
      request.headers['x-forwarded-for'] ||
      request.connection.remoteAddress;
    return `ip:${ip}`;
  }

  /**
   * Get rate limit configuration for endpoint
   */
  private getRateLimits(
    endpoint: string,
  ): Array<{ window: number; max: number }> {
    // Default rate limits
    const defaults = [
      { window: 60, max: 60 }, // 60 requests per minute
      { window: 3600, max: 1000 }, // 1000 requests per hour
    ];

    // Custom rate limits for specific endpoints
    const customLimits: Record<string, Array<{ window: number; max: number }>> =
      {
        'POST:/auth/login': [
          { window: 60, max: 5 }, // 5 login attempts per minute
          { window: 3600, max: 20 }, // 20 login attempts per hour
        ],
        'POST:/auth/register': [
          { window: 60, max: 3 }, // 3 registrations per minute
          { window: 3600, max: 10 }, // 10 registrations per hour
        ],
        'POST:/auth/forgot-password': [
          { window: 60, max: 2 }, // 2 requests per minute
          { window: 3600, max: 5 }, // 5 requests per hour
        ],
        'POST:/auth/refresh': [
          { window: 60, max: 10 }, // 10 refresh requests per minute
          { window: 3600, max: 100 }, // 100 refresh requests per hour
        ],
      };

    return customLimits[endpoint] || defaults;
  }

  /**
   * Check if request is within rate limit
   */
  private async checkRateLimit(
    identifier: string,
    endpoint: string,
    windowSeconds: number,
    maxRequests: number,
  ): Promise<boolean> {
    try {
      const key = `${this.RATE_LIMIT_PREFIX}${identifier}:${endpoint}:${windowSeconds}`;
      const current = await this.cacheService.incr(key, windowSeconds);

      if (current === 1) {
        // First request in this window, set expiry
        // Already set by incr method
      }

      return current <= maxRequests;
    } catch (error) {
      this.logger.error('Rate limit check error:', error);
      // Fail open - if cache is down, allow the request
      return true;
    }
  }
}

/**
 * Decorator to apply rate limiting to specific routes
 */
export function RateLimit(options: { window: number; max: number }) {
  return function (
    target: any,
    propertyKey: string,
    descriptor: PropertyDescriptor,
  ) {
    // Store rate limit options in metadata
    Reflect.defineMetadata('rateLimit', options, target, propertyKey);
    return descriptor;
  };
}
