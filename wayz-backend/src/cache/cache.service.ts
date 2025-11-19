import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class CacheService {
  private readonly logger = new Logger(CacheService.name);
  private readonly redis: Redis;
  private readonly defaultTtl = 300; // 5 minutes

  constructor(private readonly configService: ConfigService) {
    // Initialize Redis/Valkey connection
    this.redis = new Redis({
      host: this.configService.get<string>('REDIS_HOST'),
      port: this.configService.get<number>('REDIS_PORT'),
      password: this.configService.get<string>('REDIS_PASSWORD'),
      keyPrefix: 'wayz:',
      lazyConnect: true,
    });

    // Event handlers
    this.redis.on('connect', () => {
      this.logger.log('✅ Connected to Valkey/Redis cache');
    });

    this.redis.on('error', (error: Error) => {
      this.logger.error('❌ Valkey/Redis connection error:', error.message);
    });
  }

  /**
   * Get a value from cache
   */
  async get<T = any>(key: string): Promise<T | null> {
    try {
      const value = await this.redis.get(key);
      if (value) {
        return JSON.parse(value) as T;
      }
      return null;
    } catch (error) {
      this.logger.error(`Cache get error for key ${key}:`, error);
      return null;
    }
  }

  /**
   * Set a value in cache
   */
  async set(
    key: string,
    value: any,
    ttlSeconds: number = this.defaultTtl,
  ): Promise<void> {
    try {
      await this.redis.setex(key, ttlSeconds, JSON.stringify(value));
    } catch (error) {
      this.logger.error(`Cache set error for key ${key}:`, error);
    }
  }

  /**
   * Delete a value from cache
   */
  async del(key: string): Promise<void> {
    try {
      await this.redis.del(key);
    } catch (error) {
      this.logger.error(`Cache delete error for key ${key}:`, error);
    }
  }

  /**
   * Delete multiple keys by pattern
   */
  async delByPattern(pattern: string): Promise<void> {
    try {
      const keys = await this.redis.keys(`wayz:${pattern}`);
      if (keys.length > 0) {
        await this.redis.del(...keys);
        this.logger.log(`Deleted ${keys.length} cache entries matching: ${pattern}`);
      }
    } catch (error) {
      this.logger.error(`Cache delete by pattern error for ${pattern}:`, error);
    }
  }

  /**
   * Check if key exists in cache
   */
  async exists(key: string): Promise<boolean> {
    try {
      const exists = await this.redis.exists(key);
      return exists === 1;
    } catch (error) {
      this.logger.error(`Cache exists check error for key ${key}:`, error);
      return false;
    }
  }

  /**
   * Increment a counter in cache
   */
  async incr(key: string, ttlSeconds: number = this.defaultTtl): Promise<number> {
    try {
      const value = await this.redis.incr(key);
      if (value === 1) {
        // Set TTL only on first increment
        await this.redis.expire(key, ttlSeconds);
      }
      return value;
    } catch (error) {
      this.logger.error(`Cache increment error for key ${key}:`, error);
      return 0;
    }
  }

  /**
   * Add to a set in cache
   */
  async sadd(key: string, value: string): Promise<void> {
    try {
      await this.redis.sadd(key, value);
    } catch (error) {
      this.logger.error(`Cache set add error for key ${key}:`, error);
    }
  }

  /**
   * Remove from a set in cache
   */
  async srem(key: string, value: string): Promise<void> {
    try {
      await this.redis.srem(key, value);
    } catch (error) {
      this.logger.error(`Cache set remove error for key ${key}:`, error);
    }
  }

  /**
   * Check if value exists in set
   */
  async sismember(key: string, value: string): Promise<boolean> {
    try {
      const exists = await this.redis.sismember(key, value);
      return exists === 1;
    } catch (error) {
      this.logger.error(`Cache set member check error for key ${key}:`, error);
      return false;
    }
  }

  /**
   * Cache with automatic JSON serialization and error handling
   */
  async cached<T>(
    key: string,
    factory: () => Promise<T>,
    ttlSeconds: number = this.defaultTtl,
  ): Promise<T> {
    // Try to get from cache first
    const cached = await this.get<T>(key);
    if (cached !== null) {
      this.logger.debug(`Cache HIT: ${key}`);
      return cached;
    }

    // Not in cache, get from factory function
    this.logger.debug(`Cache MISS: ${key}`);
    const result = await factory();
    
    // Store in cache for next time
    await this.set(key, result, ttlSeconds);
    
    return result;
  }

  /**
   * Warm cache with popular data
   */
  async warmCache(): Promise<void> {
    this.logger.log('🔥 Starting cache warming...');
    
    try {
      // Warm popular vehicle categories
      await this.set('vehicle:categories', [], 3600); // 1 hour
      
      // Warm system status
      await this.set('system:status', { status: 'operational', timestamp: new Date() }, 60);
      
      this.logger.log('✅ Cache warming completed');
    } catch (error) {
      this.logger.error('❌ Cache warming failed:', error);
    }
  }

  /**
   * Get cache statistics
   */
  async getStats(): Promise<{ connected: boolean; keys: number; memory: string }> {
    try {
      const info = await this.redis.info('memory');
      const keyCount = await this.redis.dbsize();
      
      // Parse memory usage from info
      const memoryMatch = info.match(/used_memory_human:(.+)/);
      const memoryUsage = memoryMatch ? memoryMatch[1].trim() : 'unknown';
      
      return {
        connected: true,
        keys: keyCount,
        memory: memoryUsage,
      };
    } catch (error) {
      this.logger.error('Cache stats error:', error);
      return {
        connected: false,
        keys: 0,
        memory: 'unavailable',
      };
    }
  }

  /**
   * Health check for cache
   */
  async healthCheck(): Promise<boolean> {
    try {
      await this.redis.ping();
      return true;
    } catch (error) {
      this.logger.error('Cache health check failed:', error);
      return false;
    }
  }

  /**
   * Cleanup on module destroy
   */
  onModuleDestroy(): void {
    this.redis.disconnect();
    this.logger.log('🔌 Disconnected from Valkey/Redis cache');
  }
}
