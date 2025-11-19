import { Injectable, Logger } from '@nestjs/common';
import { CacheService } from '../cache/cache.service';

interface PerformanceMetrics {
  apiCalls: number;
  cacheHits: number;
  cacheMisses: number;
  averageResponseTime: number;
  dbQueries: number;
  timestamp: Date;
}

@Injectable()
export class PerformanceService {
  private readonly logger = new Logger(PerformanceService.name);
  private metrics: PerformanceMetrics = {
    apiCalls: 0,
    cacheHits: 0,
    cacheMisses: 0,
    averageResponseTime: 0,
    dbQueries: 0,
    timestamp: new Date(),
  };

  constructor(private readonly cacheService: CacheService) {}

  /**
   * Track API call performance
   */
  async trackApiCall(endpoint: string, responseTime: number): Promise<void> {
    this.metrics.apiCalls++;
    this.updateAverageResponseTime(responseTime);
    
    // Store in cache for dashboard
    const key = `performance:api:${endpoint}:${this.getHourKey()}`;
    await this.cacheService.incr(key, 3600); // Store for 1 hour
    
    this.logger.debug(`API call tracked: ${endpoint} (${responseTime}ms)`);
  }

  /**
   * Track cache hit
   */
  async trackCacheHit(key: string): Promise<void> {
    this.metrics.cacheHits++;
    
    const cacheKey = `performance:cache:hits:${this.getHourKey()}`;
    await this.cacheService.incr(cacheKey, 3600);
  }

  /**
   * Track cache miss
   */
  async trackCacheMiss(key: string): Promise<void> {
    this.metrics.cacheMisses++;
    
    const cacheKey = `performance:cache:misses:${this.getHourKey()}`;
    await this.cacheService.incr(cacheKey, 3600);
  }

  /**
   * Track database query
   */
  async trackDbQuery(query: string, executionTime: number): Promise<void> {
    this.metrics.dbQueries++;
    
    const key = `performance:db:queries:${this.getHourKey()}`;
    await this.cacheService.incr(key, 3600);
    
    // Track slow queries separately
    if (executionTime > 1000) { // Queries over 1 second
      const slowKey = `performance:db:slow:${this.getHourKey()}`;
      await this.cacheService.incr(slowKey, 3600);
      this.logger.warn(`Slow query detected: ${executionTime}ms - ${query.substring(0, 100)}`);
    }
  }

  /**
   * Get current performance metrics
   */
  getCurrentMetrics(): PerformanceMetrics {
    return {
      ...this.metrics,
      timestamp: new Date(),
    };
  }

  /**
   * Get cache hit ratio
   */
  getCacheHitRatio(): number {
    const total = this.metrics.cacheHits + this.metrics.cacheMisses;
    if (total === 0) return 0;
    return (this.metrics.cacheHits / total) * 100;
  }

  /**
   * Get performance statistics from cache
   */
  async getPerformanceStats(): Promise<{
    apiCalls: number;
    cacheHits: number;
    cacheMisses: number;
    dbQueries: number;
    cacheHitRatio: number;
    redisStats: any;
  }> {
    const hourKey = this.getHourKey();
    
    const [apiCalls, cacheHits, cacheMisses, dbQueries, redisStats] = await Promise.all([
      this.getHourlyMetric('api', hourKey),
      this.getHourlyMetric('cache:hits', hourKey),
      this.getHourlyMetric('cache:misses', hourKey),
      this.getHourlyMetric('db:queries', hourKey),
      this.cacheService.getStats(),
    ]);

    const totalCache = cacheHits + cacheMisses;
    const cacheHitRatio = totalCache > 0 ? (cacheHits / totalCache) * 100 : 0;

    return {
      apiCalls,
      cacheHits,
      cacheMisses,
      dbQueries,
      cacheHitRatio,
      redisStats,
    };
  }

  /**
   * Reset performance metrics
   */
  resetMetrics(): void {
    this.metrics = {
      apiCalls: 0,
      cacheHits: 0,
      cacheMisses: 0,
      averageResponseTime: 0,
      dbQueries: 0,
      timestamp: new Date(),
    };
    this.logger.log('Performance metrics reset');
  }

  /**
   * Get top performing endpoints
   */
  async getTopEndpoints(limit = 10): Promise<Array<{ endpoint: string; calls: number }>> {
    try {
      const pattern = 'performance:api:*';
      const keys = await this.cacheService.get<string[]>(`top:endpoints:${this.getHourKey()}`);
      
      if (keys) {
        return keys.slice(0, limit).map((key, index) => ({
          endpoint: key.replace('performance:api:', '').replace(`:${this.getHourKey()}`, ''),
          calls: index + 1, // Placeholder - would need proper Redis operations
        }));
      }
      
      return [];
    } catch (error) {
      this.logger.error('Error getting top endpoints:', error);
      return [];
    }
  }

  /**
   * Health check for performance monitoring
   */
  async healthCheck(): Promise<{
    status: 'healthy' | 'degraded' | 'unhealthy';
    metrics: PerformanceMetrics;
    cacheHealth: boolean;
  }> {
    const cacheHealth = await this.cacheService.healthCheck();
    const metrics = this.getCurrentMetrics();
    
    let status: 'healthy' | 'degraded' | 'unhealthy' = 'healthy';
    
    // Determine health status based on metrics
    if (!cacheHealth || metrics.averageResponseTime > 5000) {
      status = 'unhealthy';
    } else if (metrics.averageResponseTime > 2000 || this.getCacheHitRatio() < 50) {
      status = 'degraded';
    }
    
    return {
      status,
      metrics,
      cacheHealth,
    };
  }

  private updateAverageResponseTime(responseTime: number): void {
    if (this.metrics.apiCalls === 1) {
      this.metrics.averageResponseTime = responseTime;
    } else {
      // Calculate rolling average
      this.metrics.averageResponseTime = 
        (this.metrics.averageResponseTime * (this.metrics.apiCalls - 1) + responseTime) / 
        this.metrics.apiCalls;
    }
  }

  private getHourKey(): string {
    const now = new Date();
    return `${now.getFullYear()}-${now.getMonth() + 1}-${now.getDate()}-${now.getHours()}`;
  }

  private async getHourlyMetric(type: string, hourKey: string): Promise<number> {
    const key = `performance:${type}:${hourKey}`;
    const value = await this.cacheService.get<number>(key);
    return value || 0;
  }
}
