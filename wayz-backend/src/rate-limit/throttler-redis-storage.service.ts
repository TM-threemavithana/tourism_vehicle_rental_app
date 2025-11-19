import { Injectable, Logger } from '@nestjs/common';
import { CacheService } from '../cache/cache.service';

export interface ThrottlerStorageRecord {
  totalHits: number;
  timeToExpire: number;
  isBlocked: boolean;
  timeToBlockExpire: number;
}

export interface ThrottlerStorage {
  increment(
    key: string,
    ttl: number,
    limit: number,
    blockDuration: number,
    throttlerName: string,
  ): Promise<ThrottlerStorageRecord>;
}

/**
 * Redis-backed storage service for NestJS Throttler
 * Provides distributed rate limiting across multiple server instances
 */
@Injectable()
export class ThrottlerRedisStorage implements ThrottlerStorage {
  private readonly logger = new Logger(ThrottlerRedisStorage.name);
  private readonly keyPrefix = 'throttle:';

  constructor(private readonly cacheService: CacheService) {}

  /**
   * Increment the request count for the given key
   * @param key - Unique identifier for the rate limit (e.g., IP address)
   * @param ttl - Time-to-live in milliseconds
   * @param limit - Maximum number of requests allowed
   * @param blockDuration - Duration to block if limit exceeded
   * @param throttlerName - Name of the throttler configuration
   * @returns The storage record with hits and blocking information
   */
  async increment(
    key: string,
    ttl: number,
    limit: number,
    blockDuration: number,
    throttlerName: string,
  ): Promise<ThrottlerStorageRecord> {
    try {
      const fullKey = `${this.keyPrefix}${throttlerName}:${key}`;
      const ttlSeconds = Math.ceil(ttl / 1000);

      // Increment counter with TTL
      const totalHits = await this.cacheService.incr(fullKey, ttlSeconds);

      // Check if blocked
      const isBlocked = totalHits > limit;
      const timeToBlockExpire = isBlocked ? blockDuration : 0;

      return {
        totalHits,
        timeToExpire: ttl,
        isBlocked,
        timeToBlockExpire,
      };
    } catch (error) {
      this.logger.error(`Error incrementing throttle key ${key}:`, error);
      // Fail open - return zero hits if cache is unavailable
      return {
        totalHits: 0,
        timeToExpire: ttl,
        isBlocked: false,
        timeToBlockExpire: 0,
      };
    }
  }
}

