import {
  IsUUID,
  IsNumber,
  IsOptional,
  IsString,
  Length,
  Min,
  Max,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateReviewDto {
  @ApiProperty({
    description: 'ID of the vehicle being reviewed',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsUUID()
  vehicleId: string;

  @ApiProperty({
    description: 'ID of the booking (optional)',
    example: '550e8400-e29b-41d4-a716-446655440001',
    required: false,
  })
  @IsOptional()
  @IsUUID()
  bookingId?: string;

  @ApiProperty({
    description: 'Rating from 1 to 5',
    example: 4.5,
    minimum: 1,
    maximum: 5,
  })
  @IsNumber({ maxDecimalPlaces: 1 })
  @Min(1)
  @Max(5)
  rating: number;

  @ApiProperty({
    description: 'Review comment',
    example:
      'Great vehicle! Very clean and comfortable. The owner was very responsive and helpful.',
    minLength: 10,
    maxLength: 1000,
  })
  @IsString()
  @Length(10, 1000)
  comment: string;
}

export class UpdateReviewDto {
  @ApiProperty({
    description: 'Rating from 1 to 5',
    example: 4.5,
    minimum: 1,
    maximum: 5,
    required: false,
  })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 1 })
  @Min(1)
  @Max(5)
  rating?: number;

  @ApiProperty({
    description: 'Review comment',
    example: 'Updated review: Great vehicle! Very clean and comfortable.',
    minLength: 10,
    maxLength: 1000,
    required: false,
  })
  @IsOptional()
  @IsString()
  @Length(10, 1000)
  comment?: string;
}

export class ReviewResponseDto {
  @ApiProperty({ description: 'Review ID' })
  id: string;

  @ApiProperty({ description: 'Vehicle information' })
  vehicle: {
    id: string;
    name: string;
    brand: string;
    model: string;
    imageUrl: string;
  };

  @ApiProperty({ description: 'User information' })
  user: {
    id: string;
    firstName: string;
    lastName: string;
  };

  @ApiProperty({ description: 'Booking information', required: false })
  booking?: {
    id: string;
    startDate: Date;
    endDate: Date;
  };

  @ApiProperty({ description: 'Review rating' })
  rating: number;

  @ApiProperty({ description: 'Review comment' })
  comment: string;

  @ApiProperty({ description: 'Creation timestamp' })
  createdAt: Date;

  @ApiProperty({ description: 'Last update timestamp' })
  updatedAt: Date;
}
