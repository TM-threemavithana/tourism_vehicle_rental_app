import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam } from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import { NotificationsGateway } from './notifications.gateway';
import {
  CreateNotificationDto,
  NotificationResponseDto,
} from '../dto/notification.dto';

@ApiTags('Notifications')
@Controller('notifications')
export class NotificationsController {
  constructor(
    private readonly notificationsService: NotificationsService,
    private readonly notificationsGateway: NotificationsGateway,
  ) {}

  @Post()
  @ApiOperation({ summary: 'Create a new notification' })
  @ApiResponse({
    status: 201,
    description: 'Notification created successfully',
    type: NotificationResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Bad request - validation errors' })
  async create(@Body() createNotificationDto: CreateNotificationDto) {
    return this.notificationsService.create(createNotificationDto);
  }

  @Get('user/:userId')
  @ApiOperation({ summary: 'Get user notifications' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({
    status: 200,
    description: 'User notifications retrieved successfully',
    type: [NotificationResponseDto],
  })
  async getUserNotifications(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.notificationsService.findUserNotifications(userId);
  }

  @Get('user/:userId/unread-count')
  @ApiOperation({ summary: 'Get unread notification count' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({
    status: 200,
    description: 'Unread count retrieved successfully',
  })
  async getUnreadCount(@Param('userId', ParseUUIDPipe) userId: string) {
    const count = await this.notificationsService.getUnreadCount(userId);
    return { unreadCount: count };
  }

  @Patch(':id/read')
  @ApiOperation({ summary: 'Mark notification as read' })
  @ApiParam({ name: 'id', description: 'Notification ID' })
  @ApiResponse({
    status: 200,
    description: 'Notification marked as read',
    type: NotificationResponseDto,
  })
  @ApiResponse({ status: 404, description: 'Notification not found' })
  async markAsRead(@Param('id', ParseUUIDPipe) id: string) {
    return this.notificationsService.markAsRead(id);
  }

  @Patch('user/:userId/read-all')
  @ApiOperation({ summary: 'Mark all notifications as read for user' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({ status: 200, description: 'All notifications marked as read' })
  async markAllAsRead(@Param('userId', ParseUUIDPipe) userId: string) {
    await this.notificationsService.markAllAsRead(userId);
    return { message: 'All notifications marked as read' };
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a notification' })
  @ApiParam({ name: 'id', description: 'Notification ID' })
  @ApiResponse({
    status: 200,
    description: 'Notification deleted successfully',
  })
  @ApiResponse({ status: 404, description: 'Notification not found' })
  async remove(@Param('id', ParseUUIDPipe) id: string) {
    await this.notificationsService.remove(id);
    return { message: 'Notification deleted successfully' };
  }

  @Get('ws-stats')
  @ApiOperation({ summary: 'Get WebSocket connection statistics' })
  @ApiResponse({
    status: 200,
    description: 'WebSocket connection stats retrieved successfully',
  })
  getWebSocketStats() {
    return this.notificationsGateway.getConnectionStats();
  }
}
