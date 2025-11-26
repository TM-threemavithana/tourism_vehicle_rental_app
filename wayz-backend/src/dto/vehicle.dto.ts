import {
  IsString,
  IsNumber,
  IsOptional,
  IsDecimal,
  IsBoolean,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export class CreateVehicleDto {
  @ApiProperty({ example: 'Toyota' })
  @IsString()
  make: string;

  @ApiProperty({ example: 'Camry' })
  @IsString()
  model: string;

  @ApiProperty({ example: 2022 })
  @IsNumber()
  year: number;

  @ApiPropertyOptional({ example: 'White' })
  @IsOptional()
  @IsString()
  color?: string;

  @ApiPropertyOptional({ example: 'ABC123' })
  @IsOptional()
  @IsString()
  licensePlate?: string;

  @ApiProperty({ example: 50.0 })
  @IsNumber({ maxDecimalPlaces: 2 })
  @Type(() => Number)
  dailyRate: number;

  @ApiPropertyOptional({ example: 4 })
  @IsOptional()
  @IsNumber()
  seats?: number;

  @ApiPropertyOptional({ example: 'gasoline' })
  @IsOptional()
  @IsString()
  fuelType?: string;

  @ApiPropertyOptional({ example: 'automatic' })
  @IsOptional()
  @IsString()
  transmission?: string;

  @ApiPropertyOptional({ example: 'Air conditioning, GPS, Bluetooth' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ example: 40.7128 })
  @IsOptional()
  @IsNumber()
  locationLat?: number;

  @ApiPropertyOptional({ example: -74.006 })
  @IsOptional()
  @IsNumber()
  locationLng?: number;

  @ApiPropertyOptional({ example: 'New York, NY' })
  @IsOptional()
  @IsString()
  locationCity?: string;

  @ApiPropertyOptional({
    example: [
      'https://example.com/vehicles/image1.jpg',
      'https://example.com/vehicles/image2.jpg',
    ],
    description: 'Array of vehicle image URLs',
  })
  @IsOptional()
  images?: string[];

  @ApiPropertyOptional({
    example: ['AC', 'GPS', 'Bluetooth', 'USB'],
    description: 'Array of vehicle features',
  })
  @IsOptional()
  features?: string[];

  @ApiPropertyOptional({ example: 'category-uuid-here' })
  @IsOptional()
  @IsString()
  categoryId?: string;

  @ApiPropertyOptional({ example: 200.0 })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Type(() => Number)
  securityDeposit?: number;

  @ApiPropertyOptional({ example: 'No smoking, No pets' })
  @IsOptional()
  @IsString()
  rules?: string;

  @ApiPropertyOptional({ example: '1HGBH41JXMN109186' })
  @IsOptional()
  @IsString()
  vin?: string;

  @ApiPropertyOptional({ example: '123 Main St, New York, NY 10001' })
  @IsOptional()
  @IsString()
  locationAddress?: string;
}

export class UpdateVehicleDto {
  @ApiPropertyOptional({ example: 'Toyota' })
  @IsOptional()
  @IsString()
  make?: string;

  @ApiPropertyOptional({ example: 'Camry' })
  @IsOptional()
  @IsString()
  model?: string;

  @ApiPropertyOptional({ example: 50.0 })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Type(() => Number)
  dailyRate?: number;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  isAvailable?: boolean;

  @ApiPropertyOptional({ example: 'Updated description' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    example: [
      'https://example.com/vehicles/image1.jpg',
      'https://example.com/vehicles/image2.jpg',
    ],
    description: 'Array of vehicle image URLs',
  })
  @IsOptional()
  images?: string[];

  @ApiPropertyOptional({
    example: ['AC', 'GPS', 'Bluetooth', 'USB'],
    description: 'Array of vehicle features',
  })
  @IsOptional()
  features?: string[];

  @ApiPropertyOptional({ example: 200.0 })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Type(() => Number)
  securityDeposit?: number;

  @ApiPropertyOptional({ example: 40.7128 })
  @IsOptional()
  @IsNumber()
  locationLat?: number;

  @ApiPropertyOptional({ example: -74.006 })
  @IsOptional()
  @IsNumber()
  locationLng?: number;

  @ApiPropertyOptional({ example: 'New York, NY' })
  @IsOptional()
  @IsString()
  locationCity?: string;

  @ApiPropertyOptional({ example: '123 Main St, New York, NY 10001' })
  @IsOptional()
  @IsString()
  locationAddress?: string;
}
