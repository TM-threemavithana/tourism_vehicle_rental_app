import { Injectable, Logger } from '@nestjs/common';
import { CacheService } from '../../cache/cache.service';

/**
 * Rate limiting service for authentication operations
 * Provides fine-grained control over rate limits per operation
 */
@Injectable()
export class RateLimitService {
  private readonly logger = new Logger(RateLimitService.name);
  private readonly RATE_LIMIT_PREFIX = 'ratelimit:';

  // Rate limit configurations
  private readonly limits = {
    login: { maxAttempts: 5, windowSeconds: 900 }, // 5 attempts per 15 minutes
    register: { maxAttempts: 3, windowSeconds: 3600 }, // 3 attempts per hour
    forgotPassword: { maxAttempts: 3, windowSeconds: 3600 }, // 3 attempts per hour
    changePassword: { maxAttempts: 5, windowSeconds: 900 }, // 5 attempts per 15 minutes
    refresh: { maxAttempts: 10, windowSeconds: 600 }, // 10 attempts per 10 minutes
  };

  constructor(private readonly cacheService: CacheService) {}

  /**
   * Check if operation is rate limited for the given identifier
   * @param operation - Operation type (login, register, etc.)
   * @param identifier - Unique identifier (IP, email, userId)
   * @returns true if rate limited, false otherwise
   */
  async isRateLimited(
    operation: keyof typeof this.limits,
    identifier: string,
  ): Promise<boolean> {
    const key = `${this.RATE_LIMIT_PREFIX}${operation}:${identifier}`;
    const limit = this.limits[operation];

    try {
      const attempts = await this.cacheService.incr(key, limit.windowSeconds);

      if (attempts > limit.maxAttempts) {
        this.logger.warn(
          `Rate limit exceeded for ${operation} by ${identifier}`,
        );
        return true;
      }

      return false;
    } catch (error) {
      this.logger.error('Error checking rate limit:', error);
      // Fail open - if cache is down, don't block requests
      return false;
    }
  }

  /**
   * Record a failed attempt for the given operation
   * @param operation - Operation type
   * @param identifier - Unique identifier
   */
  async recordAttempt(
    operation: keyof typeof this.limits,
    identifier: string,
  ): Promise<void> {
    const key = `${this.RATE_LIMIT_PREFIX}${operation}:${identifier}`;
    const limit = this.limits[operation];

    try {
      await this.cacheService.incr(key, limit.windowSeconds);
    } catch (error) {
      this.logger.error('Error recording attempt:', error);
    }
  }

  /**
   * Reset rate limit for an operation
   * Useful after successful operations
   */
  async resetLimit(
    operation: keyof typeof this.limits,
    identifier: string,
  ): Promise<void> {
    const key = `${this.RATE_LIMIT_PREFIX}${operation}:${identifier}`;

    try {
      await this.cacheService.del(key);
    } catch (error) {
      this.logger.error('Error resetting rate limit:', error);
    }
  }

  /**
   * Get remaining attempts for an operation
   */
  async getRemainingAttempts(
    operation: keyof typeof this.limits,
    identifier: string,
  ): Promise<number> {
    const key = `${this.RATE_LIMIT_PREFIX}${operation}:${identifier}`;
    const limit = this.limits[operation];

    try {
      const attempts = (await this.cacheService.get<number>(key)) || 0;
      return Math.max(0, limit.maxAttempts - attempts);
    } catch (error) {
      this.logger.error('Error getting remaining attempts:', error);
      return limit.maxAttempts;
    }
  }

  /**
   * Get rate limit window information
   */
  getLimitInfo(operation: keyof typeof this.limits) {
    const limit = this.limits[operation];
    return {
      maxAttempts: limit.maxAttempts,
      windowSeconds: limit.windowSeconds,
      windowMinutes: Math.floor(limit.windowSeconds / 60),
    };
  }
}
