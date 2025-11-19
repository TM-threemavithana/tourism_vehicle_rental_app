import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CacheService } from '../../cache/cache.service';

@Injectable()
export class TokenBlacklistService {
  private readonly logger = new Logger(TokenBlacklistService.name);
  private readonly BLACKLIST_PREFIX = 'token:blacklist:';
  private readonly USER_TOKENS_PREFIX = 'user:tokens:';

  constructor(
    private readonly cacheService: CacheService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * Add token to blacklist
   * @param token - JWT token to blacklist
   * @param userId - User ID associated with the token
   * @param expiresIn - Seconds until token naturally expires
   */
  async blacklistToken(
    token: string,
    userId: string,
    expiresIn: number,
  ): Promise<void> {
    try {
      const key = `${this.BLACKLIST_PREFIX}${token}`;
      const data = {
        userId,
        blacklistedAt: new Date().toISOString(),
      };

      // Store in cache until token would naturally expire
      await this.cacheService.set(key, data, expiresIn);

      // Remove from user's active tokens
      await this.removeUserToken(userId, token);

      this.logger.log(`Token blacklisted for user ${userId}`);
    } catch (error) {
      this.logger.error('Error blacklisting token:', error);
      throw error;
    }
  }

  /**
   * Check if token is blacklisted
   * @param token - JWT token to check
   * @returns true if blacklisted, false otherwise
   */
  async isTokenBlacklisted(token: string): Promise<boolean> {
    try {
      const key = `${this.BLACKLIST_PREFIX}${token}`;
      const result = await this.cacheService.exists(key);
      return result;
    } catch (error) {
      this.logger.error('Error checking token blacklist:', error);
      // Fail open - if cache is down, allow the token
      return false;
    }
  }

  /**
   * Add token to user's active tokens list
   * @param userId - User ID
   * @param token - JWT token
   * @param expiresIn - Seconds until token expires
   */
  async addUserToken(
    userId: string,
    token: string,
    expiresIn: number,
  ): Promise<void> {
    try {
      const key = `${this.USER_TOKENS_PREFIX}${userId}`;
      await this.cacheService.sadd(key, token);
      // Set expiry on the set itself
      await this.cacheService.set(key, { updated: Date.now() }, expiresIn);
    } catch (error) {
      this.logger.error('Error adding user token:', error);
    }
  }

  /**
   * Remove token from user's active tokens list
   * @param userId - User ID
   * @param token - JWT token
   */
  async removeUserToken(userId: string, token: string): Promise<void> {
    try {
      const key = `${this.USER_TOKENS_PREFIX}${userId}`;
      await this.cacheService.srem(key, token);
    } catch (error) {
      this.logger.error('Error removing user token:', error);
    }
  }

  /**
   * Check if token is in user's active tokens
   * @param userId - User ID
   * @param token - JWT token
   * @returns true if token is active, false otherwise
   */
  async isUserTokenActive(userId: string, token: string): Promise<boolean> {
    try {
      const key = `${this.USER_TOKENS_PREFIX}${userId}`;
      return await this.cacheService.sismember(key, token);
    } catch (error) {
      this.logger.error('Error checking user token:', error);
      return true; // Fail open
    }
  }

  /**
   * Blacklist all tokens for a user (useful for logout all devices)
   * @param userId - User ID
   */
  async blacklistAllUserTokens(userId: string): Promise<void> {
    try {
      const key = `${this.USER_TOKENS_PREFIX}${userId}`;
      // Delete the user's token set
      await this.cacheService.del(key);
      this.logger.log(`All tokens blacklisted for user ${userId}`);
    } catch (error) {
      this.logger.error('Error blacklisting all user tokens:', error);
      throw error;
    }
  }

  /**
   * Get total number of blacklisted tokens (for monitoring)
   */
  async getBlacklistStats(): Promise<{
    blacklistedTokens: number;
  }> {
    try {
      // This is an approximation - in production you'd want better tracking
      return {
        blacklistedTokens: 0, // Would need to scan keys to get exact count
      };
    } catch (error) {
      this.logger.error('Error getting blacklist stats:', error);
      return { blacklistedTokens: 0 };
    }
  }
}
