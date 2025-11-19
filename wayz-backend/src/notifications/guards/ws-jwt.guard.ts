import {
  CanActivate,
  ExecutionContext,
  Injectable,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { WsException } from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { TokenBlacklistService } from '../../auth/services/token-blacklist.service';

interface AuthenticatedSocket extends Socket {
  data: {
    userId?: string;
    email?: string;
    role?: string;
  };
}

/**
 * WebSocket JWT Authentication Guard
 *
 * Validates JWT tokens for WebSocket connections and protects
 * WebSocket message handlers from unauthorized access.
 */
@Injectable()
export class WsJwtGuard implements CanActivate {
  private readonly logger = new Logger(WsJwtGuard.name);

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly tokenBlacklistService: TokenBlacklistService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    try {
      const client = context.switchToWs().getClient<AuthenticatedSocket>();

      // If user data is already attached during connection, allow
      if (client.data.userId) {
        return true;
      }

      // Extract token from handshake
      const token =
        client.handshake.query.token ||
        client.handshake.headers.authorization?.split(' ')[1];

      if (!token) {
        throw new WsException('Authentication token required');
      }

      // Check if token is blacklisted
      const isBlacklisted = await this.tokenBlacklistService.isTokenBlacklisted(
        token as string,
      );

      if (isBlacklisted) {
        throw new WsException('Token has been revoked');
      }

      // Verify JWT token
      const payload: {
        sub: string;
        email: string;
        role: string;
      } = await this.jwtService.verifyAsync(token as string, {
        secret: this.configService.get<string>('JWT_SECRET'),
      });

      // Attach user data to socket
      client.data.userId = payload.sub;
      client.data.email = payload.email;
      client.data.role = payload.role;

      return true;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`WebSocket authentication failed: ${message}`);
      throw new WsException('Authentication failed');
    }
  }
}
