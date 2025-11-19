import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayInit,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger, Inject, forwardRef } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { NotificationsService } from './notifications.service';
import { TokenBlacklistService } from '../auth/services/token-blacklist.service';

interface AuthenticatedSocket extends Socket {
  data: {
    userId?: string;
    email?: string;
    role?: string;
  };
}

/**
 * WebSocket Gateway for Real-Time Notifications
 *
 * Features:
 * - JWT authentication for WebSocket connections
 * - Real-time notification delivery to connected clients
 * - Room-based broadcasting (user-specific rooms)
 * - Connection lifecycle management
 * - Token blacklist validation
 *
 * Connection URL: ws://localhost:3000/notifications
 * Auth: Include JWT token in handshake query parameter or auth header
 */
@WebSocketGateway({
  namespace: '/notifications',
  cors: {
    origin: '*', // Configure this based on your frontend URL in production
    credentials: true,
  },
})
export class NotificationsGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(NotificationsGateway.name);
  private userSocketMap = new Map<string, Set<string>>(); // userId -> Set of socket IDs

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    @Inject(forwardRef(() => NotificationsService))
    private readonly notificationsService: NotificationsService,
    private readonly tokenBlacklistService: TokenBlacklistService,
  ) {}

  /**
   * Gateway initialization
   */
  afterInit() {
    this.logger.log('🚀 WebSocket Gateway initialized for notifications');
    this.logger.log(
      `📡 WebSocket server listening on namespace: /notifications`,
    );
  }

  /**
   * Handle new client connections with JWT authentication
   */
  async handleConnection(client: AuthenticatedSocket) {
    try {
      this.logger.log(`🔌 Client attempting to connect: ${client.id}`);

      // Extract token from handshake (query or auth header)
      const token =
        client.handshake.query.token ||
        client.handshake.headers.authorization?.split(' ')[1];

      if (!token) {
        this.logger.warn(
          `❌ Connection rejected for ${client.id}: No token provided`,
        );
        client.emit('error', { message: 'Authentication token required' });
        client.disconnect();
        return;
      }

      // Check if token is blacklisted
      const isBlacklisted = await this.tokenBlacklistService.isTokenBlacklisted(
        token as string,
      );

      if (isBlacklisted) {
        this.logger.warn(
          `❌ Connection rejected for ${client.id}: Token is blacklisted`,
        );
        client.emit('error', { message: 'Token has been revoked' });
        client.disconnect();
        return;
      }

      // Verify JWT token
      const payload: {
        sub: string;
        email: string;
        role: string;
      } = await this.jwtService.verifyAsync(token as string, {
        secret: this.configService.get<string>('JWT_SECRET'),
      });

      const userId: string = payload.sub;

      // Store user ID in socket data for later use
      client.data.userId = userId;
      client.data.email = payload.email;

      // Add socket to user's room
      await client.join(`user:${userId}`);

      // Track user's socket connections
      if (!this.userSocketMap.has(userId)) {
        this.userSocketMap.set(userId, new Set());
      }
      this.userSocketMap.get(userId)!.add(client.id);

      this.logger.log(
        `✅ Client connected: ${client.id} | User: ${userId} (${payload.email})`,
      );
      this.logger.log(
        `👥 Active connections for user ${userId}: ${this.userSocketMap.get(userId)!.size}`,
      );

      // Send connection success message
      client.emit('connected', {
        message: 'Successfully connected to notifications',
        userId,
        timestamp: new Date().toISOString(),
      });

      // Send unread notification count
      const unreadCount =
        await this.notificationsService.getUnreadCount(userId);
      client.emit('unreadCount', { count: unreadCount });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`❌ Connection error for ${client.id}: ${message}`);
      client.emit('error', { message: 'Authentication failed' });
      client.disconnect();
    }
  }

  /**
   * Handle client disconnections
   */
  handleDisconnect(client: AuthenticatedSocket) {
    const userId = client.data.userId;

    if (userId && this.userSocketMap.has(userId)) {
      const userSockets = this.userSocketMap.get(userId)!;
      userSockets.delete(client.id);

      if (userSockets.size === 0) {
        this.userSocketMap.delete(userId);
        this.logger.log(
          `👤 User ${userId} fully disconnected (no more sockets)`,
        );
      } else {
        this.logger.log(
          `🔌 Socket ${client.id} disconnected | User ${userId} still has ${userSockets.size} connection(s)`,
        );
      }
    }

    this.logger.log(`🔌 Client disconnected: ${client.id}`);
  }

  /**
   * Subscribe to notification updates
   */
  @SubscribeMessage('subscribe')
  handleSubscribe(@ConnectedSocket() client: AuthenticatedSocket) {
    const userId = client.data.userId as string;
    this.logger.log(`📬 User ${userId} subscribed to notifications`);
    return { event: 'subscribed', data: { userId } };
  }

  /**
   * Get unread notification count
   */
  @SubscribeMessage('getUnreadCount')
  async handleGetUnreadCount(@ConnectedSocket() client: AuthenticatedSocket) {
    const userId = client.data.userId as string;
    const count = await this.notificationsService.getUnreadCount(userId);
    return { event: 'unreadCount', data: { count } };
  }

  /**
   * Mark notification as read (via WebSocket)
   */
  @SubscribeMessage('markAsRead')
  async handleMarkAsRead(
    @MessageBody() data: { notificationId: string },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    const userId = client.data.userId as string;
    try {
      await this.notificationsService.markAsRead(data.notificationId);
      const unreadCount =
        await this.notificationsService.getUnreadCount(userId);

      // Send updated unread count to all user's connected sockets
      this.server
        .to(`user:${userId}`)
        .emit('unreadCount', { count: unreadCount });

      return {
        event: 'markedAsRead',
        data: { notificationId: data.notificationId },
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to mark notification as read: ${message}`);
      return { event: 'error', data: { message } };
    }
  }

  /**
   * Mark all notifications as read (via WebSocket)
   */
  @SubscribeMessage('markAllAsRead')
  async handleMarkAllAsRead(@ConnectedSocket() client: AuthenticatedSocket) {
    const userId = client.data.userId as string;
    try {
      await this.notificationsService.markAllAsRead(userId);

      // Send updated unread count (should be 0)
      this.server.to(`user:${userId}`).emit('unreadCount', { count: 0 });

      return { event: 'allMarkedAsRead', data: { userId } };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to mark all notifications as read: ${message}`);
      return { event: 'error', data: { message } };
    }
  }

  /**
   * Send notification to a specific user (called by NotificationsService)
   */
  sendNotificationToUser(userId: string, notification: unknown) {
    const room = `user:${userId}`;
    this.logger.log(
      `📨 Sending notification to user ${userId} in room ${room}`,
    );

    this.server.to(room).emit('newNotification', {
      notification,
      timestamp: new Date().toISOString(),
    });

    this.logger.log(
      `✅ Notification sent to ${this.userSocketMap.get(userId)?.size || 0} socket(s)`,
    );
  }

  /**
   * Broadcast notification to multiple users
   */
  broadcastToUsers(userIds: string[], notification: unknown) {
    userIds.forEach((userId) => {
      this.sendNotificationToUser(userId, notification);
    });
  }

  /**
   * Get connection stats (useful for monitoring)
   */
  getConnectionStats() {
    return {
      totalConnections: Array.from(this.userSocketMap.values()).reduce(
        (sum, sockets) => sum + sockets.size,
        0,
      ),
      uniqueUsers: this.userSocketMap.size,
      userConnections: Array.from(this.userSocketMap.entries()).map(
        ([userId, sockets]) => ({
          userId,
          socketCount: sockets.size,
        }),
      ),
    };
  }

  /**
   * Check if a user is currently connected
   */
  isUserConnected(userId: string): boolean {
    return (
      this.userSocketMap.has(userId) && this.userSocketMap.get(userId)!.size > 0
    );
  }
}
