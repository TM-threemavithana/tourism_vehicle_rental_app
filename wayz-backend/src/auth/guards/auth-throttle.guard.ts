import { Injectable } from '@nestjs/common';
import { ThrottlerGuard } from '@nestjs/throttler';
import { Request } from 'express';

/**
 * Custom throttle guard for authentication endpoints
 * Provides stricter rate limiting for sensitive auth operations
 */
@Injectable()
export class AuthThrottleGuard extends ThrottlerGuard {
  /**
   * Override to customize rate limit key generation
   * Uses IP address + endpoint for granular control
   */
  protected getTracker(req: Request): Promise<string> {
    const ip = this.getRequestIP(req);
    const route = req.route as { path?: string } | undefined;
    const endpoint = route?.path || req.url;
    return Promise.resolve(`${ip}:${endpoint}`);
  }

  /**
   * Extract real IP address from request
   * Handles proxy headers for accurate tracking
   */
  private getRequestIP(req: Request): string {
    // Check for X-Forwarded-For header (common in reverse proxy setups)
    const forwardedFor = req.headers['x-forwarded-for'];
    if (forwardedFor) {
      const ips = Array.isArray(forwardedFor)
        ? forwardedFor[0]
        : forwardedFor.split(',')[0];
      return ips.trim();
    }

    // Check for X-Real-IP header
    const realIp = req.headers['x-real-ip'];
    if (realIp) {
      return Array.isArray(realIp) ? realIp[0] : realIp;
    }

    // Fall back to connection remote address
    return req.ip || req.connection.remoteAddress || 'unknown';
  }
}


