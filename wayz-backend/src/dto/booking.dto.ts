import {
  IsUUID,
  IsEnum,
  IsDateString,
  IsOptional,
  IsNumber,
  IsPositive,
  IsString,
  Length,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { BookingStatus } from '../entities/booking.entity';

export class CreateBookingDto {
  @ApiProperty({
    description: 'ID of the vehicle being booked',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsUUID()
  vehicleId: string;

  @ApiProperty({
    description: 'ID of the user making the booking',
    example: '550e8400-e29b-41d4-a716-446655440001',
  })
  @IsUUID()
  userId: string;

  @ApiProperty({
    description: 'Start date and time of the rental',
    example: '2024-01-15T09:00:00.000Z',
  })
  @IsDateString()
  startDate: string;

  @ApiProperty({
    description: 'End date and time of the rental',
    example: '2024-01-17T18:00:00.000Z',
  })
  @IsDateString()
  endDate: string;

  @ApiProperty({
    description: 'Total rental cost',
    example: 299.99,
  })
  @IsNumber({ maxDecimalPlaces: 2 })
  @IsPositive()
  totalCost: number;

  @ApiProperty({
    description: 'Pickup location address',
    example: 'Hotel Paradise, Bentota Beach, Sri Lanka',
    required: false,
  })
  @IsOptional()
  @IsString()
  @Length(1, 500)
  pickupLocation?: string;

  @ApiProperty({
    description: 'Drop-off location address',
    example: 'Bandaranaike International Airport, Katunayake, Sri Lanka',
    required: false,
  })
  @IsOptional()
  @IsString()
  @Length(1, 500)
  dropoffLocation?: string;

  @ApiProperty({
    description: 'Special requests or notes',
    example: 'Need child seat for 5-year-old',
    required: false,
  })
  @IsOptional()
  @IsString()
  @Length(1, 1000)
  specialRequests?: string;
}

export class UpdateBookingDto {
  @ApiProperty({
    description: 'Booking status',
    enum: BookingStatus,
    example: BookingStatus.CONFIRMED,
    required: false,
  })
  @IsOptional()
  @IsEnum(BookingStatus)
  status?: BookingStatus;

  @ApiProperty({
    description: 'Start date and time of the rental',
    example: '2024-01-15T09:00:00.000Z',
    required: false,
  })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiProperty({
    description: 'End date and time of the rental',
    example: '2024-01-17T18:00:00.000Z',
    required: false,
  })
  @IsOptional()
  @IsDateString()
  endDate?: string;

  @ApiProperty({
    description: 'Total rental cost',
    example: 299.99,
    required: false,
  })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @IsPositive()
  totalCost?: number;

  @ApiProperty({
    description: 'Pickup location address',
    example: 'Hotel Paradise, Bentota Beach, Sri Lanka',
    required: false,
  })
  @IsOptional()
  @IsString()
  @Length(1, 500)
  pickupLocation?: string;

  @ApiProperty({
    description: 'Drop-off location address',
    example: 'Bandaranaike International Airport, Katunayake, Sri Lanka',
    required: false,
  })
  @IsOptional()
  @IsString()
  @Length(1, 500)
  dropoffLocation?: string;

  @ApiProperty({
    description: 'Special requests or notes',
    example: 'Need child seat for 5-year-old',
    required: false,
  })
  @IsOptional()
  @IsString()
  @Length(1, 1000)
  specialRequests?: string;
}

export class BookingResponseDto {
  @ApiProperty({ description: 'Booking ID' })
  id: string;

  @ApiProperty({ description: 'Vehicle information' })
  vehicle: {
    id: string;
    name: string;
    brand: string;
    model: string;
    year: number;
    pricePerDay: number;
    imageUrl: string;
  };

  @ApiProperty({ description: 'User information' })
  user: {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
  };

  @ApiProperty({ description: 'Booking status', enum: BookingStatus })
  status: BookingStatus;

  @ApiProperty({ description: 'Start date and time' })
  startDate: Date;

  @ApiProperty({ description: 'End date and time' })
  endDate: Date;

  @ApiProperty({ description: 'Total cost' })
  totalCost: number;

  @ApiProperty({ description: 'Pickup location', required: false })
  pickupLocation?: string;

  @ApiProperty({ description: 'Drop-off location', required: false })
  dropoffLocation?: string;

  @ApiProperty({ description: 'Special requests', required: false })
  specialRequests?: string;

  @ApiProperty({ description: 'Creation timestamp' })
  createdAt: Date;

  @ApiProperty({ description: 'Last update timestamp' })
  updatedAt: Date;
}
