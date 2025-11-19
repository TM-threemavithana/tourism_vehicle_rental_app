import { IsUUID, IsOptional, IsString, Length, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export enum NotificationType {
  BOOKING_CONFIRMED = 'booking_confirmed',
  BOOKING_CANCELLED = 'booking_cancelled',
  PAYMENT_SUCCESS = 'payment_success',
  PAYMENT_FAILED = 'payment_failed',
  VEHICLE_AVAILABLE = 'vehicle_available',
  REMINDER = 'reminder',
  PROMOTION = 'promotion',
  SYSTEM = 'system',
}

export class CreateNotificationDto {
  @ApiProperty({
    description: 'ID of the user to send notification to',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsUUID()
  userId: string;

  @ApiProperty({
    description: 'Type of notification',
    enum: NotificationType,
    example: NotificationType.BOOKING_CONFIRMED,
  })
  @IsEnum(NotificationType)
  type: NotificationType;

  @ApiProperty({
    description: 'Notification title',
    example: 'Booking Confirmed!',
    maxLength: 200,
  })
  @IsString()
  @Length(1, 200)
  title: string;

  @ApiProperty({
    description: 'Notification message',
    example:
      'Your booking for Toyota Camry has been confirmed. Pickup date: Jan 15, 2024.',
    maxLength: 1000,
  })
  @IsString()
  @Length(1, 1000)
  message: string;

  @ApiProperty({
    description: 'Related booking ID (optional)',
    example: '550e8400-e29b-41d4-a716-446655440001',
    required: false,
  })
  @IsOptional()
  @IsUUID()
  bookingId?: string;

  @ApiProperty({
    description: 'Additional data in JSON format (optional)',
    example: '{"vehicleId": "123", "pickupDate": "2024-01-15"}',
    required: false,
  })
  @IsOptional()
  @IsString()
  data?: string;
}

export class NotificationResponseDto {
  @ApiProperty({ description: 'Notification ID' })
  id: string;

  @ApiProperty({ description: 'User information' })
  user: {
    id: string;
    firstName: string;
    lastName: string;
  };

  @ApiProperty({ description: 'Notification type', enum: NotificationType })
  type: NotificationType;

  @ApiProperty({ description: 'Notification title' })
  title: string;

  @ApiProperty({ description: 'Notification message' })
  message: string;

  @ApiProperty({ description: 'Read status' })
  isRead: boolean;

  @ApiProperty({ description: 'Booking information', required: false })
  booking?: {
    id: string;
    vehicleName: string;
    startDate: Date;
  };

  @ApiProperty({ description: 'Additional data', required: false })
  data?: string;

  @ApiProperty({ description: 'Creation timestamp' })
  createdAt: Date;
}
