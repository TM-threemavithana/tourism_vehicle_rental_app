import {
  IsUUID,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsDateString,
  IsEnum,
  IsNumber,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum BookingStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  ACTIVE = 'active',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
  REJECTED = 'rejected',
}

export enum PaymentStatus {
  PENDING = 'pending',
  PAID = 'paid',
  FAILED = 'failed',
  REFUNDED = 'refunded',
  PARTIAL_REFUND = 'partial_refund',
}

export class CreateBookingDto {
  @ApiProperty({ description: 'User ID who is making the booking' })
  @IsUUID()
  @IsNotEmpty()
  user_id: string;

  @ApiProperty({ description: 'Vehicle ID being booked' })
  @IsUUID()
  @IsNotEmpty()
  vehicle_id: string;

  @ApiProperty({
    description: 'Booking start date',
    example: '2024-01-15T10:00:00Z',
  })
  @IsDateString()
  @IsNotEmpty()
  start_date: string;

  @ApiProperty({
    description: 'Booking end date',
    example: '2024-01-20T18:00:00Z',
  })
  @IsDateString()
  @IsNotEmpty()
  end_date: string;

  @ApiProperty({
    description: 'Total price for the booking',
    example: '250.00',
  })
  @IsNumber({ maxDecimalPlaces: 2 })
  @Transform(({ value }) => parseFloat(value))
  total_price: number;

  @ApiPropertyOptional({
    description: 'Special requests or notes from the customer',
  })
  @IsOptional()
  @IsString()
  special_requests?: string;

  @ApiPropertyOptional({ description: 'Pickup location' })
  @IsOptional()
  @IsString()
  pickup_location?: string;

  @ApiPropertyOptional({ description: 'Drop-off location' })
  @IsOptional()
  @IsString()
  dropoff_location?: string;
}

export class UpdateBookingDto {
  @ApiPropertyOptional({ description: 'Booking status', enum: BookingStatus })
  @IsOptional()
  @IsEnum(BookingStatus)
  status?: BookingStatus;

  @ApiPropertyOptional({ description: 'Payment status', enum: PaymentStatus })
  @IsOptional()
  @IsEnum(PaymentStatus)
  payment_status?: PaymentStatus;

  @ApiPropertyOptional({
    description: 'Booking start date',
    example: '2024-01-15T10:00:00Z',
  })
  @IsOptional()
  @IsDateString()
  start_date?: string;

  @ApiPropertyOptional({
    description: 'Booking end date',
    example: '2024-01-20T18:00:00Z',
  })
  @IsOptional()
  @IsDateString()
  end_date?: string;

  @ApiPropertyOptional({
    description: 'Total price for the booking',
    example: '250.00',
  })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Transform(({ value }) => parseFloat(value))
  total_price?: number;

  @ApiPropertyOptional({
    description: 'Special requests or notes from the customer',
  })
  @IsOptional()
  @IsString()
  special_requests?: string;

  @ApiPropertyOptional({ description: 'Pickup location' })
  @IsOptional()
  @IsString()
  pickup_location?: string;

  @ApiPropertyOptional({ description: 'Drop-off location' })
  @IsOptional()
  @IsString()
  dropoff_location?: string;

  @ApiPropertyOptional({ description: 'Cancellation reason' })
  @IsOptional()
  @IsString()
  cancellation_reason?: string;

  @ApiPropertyOptional({ description: 'Admin notes' })
  @IsOptional()
  @IsString()
  admin_notes?: string;
}

export class BookingResponseDto {
  @ApiProperty({ description: 'Booking ID' })
  id: string;

  @ApiProperty({ description: 'User ID' })
  user_id: string;

  @ApiProperty({ description: 'Vehicle ID' })
  vehicle_id: string;

  @ApiProperty({ description: 'Booking status', enum: BookingStatus })
  status: BookingStatus;

  @ApiProperty({ description: 'Payment status', enum: PaymentStatus })
  payment_status: PaymentStatus;

  @ApiProperty({ description: 'Start date' })
  start_date: Date;

  @ApiProperty({ description: 'End date' })
  end_date: Date;

  @ApiProperty({ description: 'Total price' })
  total_price: number;

  @ApiPropertyOptional({ description: 'Special requests' })
  special_requests?: string;

  @ApiPropertyOptional({ description: 'Pickup location' })
  pickup_location?: string;

  @ApiPropertyOptional({ description: 'Drop-off location' })
  dropoff_location?: string;

  @ApiPropertyOptional({ description: 'Cancellation reason' })
  cancellation_reason?: string;

  @ApiPropertyOptional({ description: 'Admin notes' })
  admin_notes?: string;

  @ApiProperty({ description: 'Created at timestamp' })
  created_at: Date;

  @ApiProperty({ description: 'Updated at timestamp' })
  updated_at: Date;

  // Relations
  @ApiPropertyOptional({ description: 'User details' })
  user?: any;

  @ApiPropertyOptional({ description: 'Vehicle details' })
  vehicle?: any;
}

export class BookingQueryDto {
  @ApiPropertyOptional({ description: 'Filter by status', enum: BookingStatus })
  @IsOptional()
  @IsEnum(BookingStatus)
  status?: BookingStatus;

  @ApiPropertyOptional({
    description: 'Filter by payment status',
    enum: PaymentStatus,
  })
  @IsOptional()
  @IsEnum(PaymentStatus)
  payment_status?: PaymentStatus;

  @ApiPropertyOptional({ description: 'Filter by user ID' })
  @IsOptional()
  @IsUUID()
  user_id?: string;

  @ApiPropertyOptional({ description: 'Filter by vehicle ID' })
  @IsOptional()
  @IsUUID()
  vehicle_id?: string;

  @ApiPropertyOptional({
    description: 'Start date range filter (from)',
    example: '2024-01-01',
  })
  @IsOptional()
  @IsDateString()
  start_date_from?: string;

  @ApiPropertyOptional({
    description: 'Start date range filter (to)',
    example: '2024-12-31',
  })
  @IsOptional()
  @IsDateString()
  start_date_to?: string;

  @ApiPropertyOptional({
    description: 'Page number for pagination',
    example: 1,
  })
  @IsOptional()
  @Transform(({ value }) => parseInt(value))
  @IsNumber()
  page?: number;

  @ApiPropertyOptional({ description: 'Items per page', example: 10 })
  @IsOptional()
  @Transform(({ value }) => parseInt(value))
  @IsNumber()
  limit?: number;
}
