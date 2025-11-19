import {
  IsString,
  IsNumber,
  IsOptional,
  IsBoolean,
  IsUUID,
  IsArray,
  Min,
  Max,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export class CreateVehicleDto {
  @ApiProperty({ example: 'Toyota', description: 'Vehicle make' })
  @IsString()
  make: string;

  @ApiProperty({ example: 'Camry', description: 'Vehicle model' })
  @IsString()
  model: string;

  @ApiProperty({ example: 2022, description: 'Vehicle year' })
  @IsNumber()
  @Min(1900)
  @Max(new Date().getFullYear() + 1)
  year: number;

  @ApiPropertyOptional({ example: 'White', description: 'Vehicle color' })
  @IsOptional()
  @IsString()
  color?: string;

  @ApiPropertyOptional({ example: 'ABC-1234', description: 'License plate' })
  @IsOptional()
  @IsString()
  licensePlate?: string;

  @ApiPropertyOptional({ description: 'Vehicle VIN' })
  @IsOptional()
  @IsString()
  vin?: string;

  @ApiProperty({ example: 75.0, description: 'Daily rental rate' })
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Type(() => Number)
  dailyRate: number;

  @ApiPropertyOptional({ example: 200.0, description: 'Security deposit' })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Type(() => Number)
  securityDeposit?: number;

  @ApiPropertyOptional({ example: 'petrol', description: 'Fuel type' })
  @IsOptional()
  @IsString()
  fuelType?: string;

  @ApiPropertyOptional({
    example: 'automatic',
    description: 'Transmission type',
  })
  @IsOptional()
  @IsString()
  transmission?: string;

  @ApiPropertyOptional({ example: 5, description: 'Number of seats' })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(50)
  seats?: number;

  @ApiPropertyOptional({ example: 37.7749, description: 'Location latitude' })
  @IsOptional()
  @IsNumber()
  @Min(-90)
  @Max(90)
  locationLat?: number;

  @ApiPropertyOptional({
    example: -122.4194,
    description: 'Location longitude',
  })
  @IsOptional()
  @IsNumber()
  @Min(-180)
  @Max(180)
  locationLng?: number;

  @ApiPropertyOptional({ description: 'Location address' })
  @IsOptional()
  @IsString()
  locationAddress?: string;

  @ApiPropertyOptional({
    example: 'San Francisco',
    description: 'Location city',
  })
  @IsOptional()
  @IsString()
  locationCity?: string;

  @ApiPropertyOptional({ description: 'Vehicle features array' })
  @IsOptional()
  @IsArray()
  features?: string[];

  @ApiPropertyOptional({ description: 'Vehicle description' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ description: 'Rental rules' })
  @IsOptional()
  @IsString()
  rules?: string;

  @ApiPropertyOptional({ description: 'Vehicle images array' })
  @IsOptional()
  @IsArray()
  images?: string[];

  @ApiPropertyOptional({ description: 'Vehicle category ID' })
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @ApiPropertyOptional({ description: 'Vehicle owner ID' })
  @IsOptional()
  @IsUUID()
  ownerId?: string;

  @ApiPropertyOptional({ description: 'Firebase document ID for migration' })
  @IsOptional()
  @IsString()
  firebaseDocId?: string;
}

export class UpdateVehicleDto {
  @ApiPropertyOptional({ example: 'Toyota', description: 'Vehicle make' })
  @IsOptional()
  @IsString()
  make?: string;

  @ApiPropertyOptional({ example: 'Camry', description: 'Vehicle model' })
  @IsOptional()
  @IsString()
  model?: string;

  @ApiPropertyOptional({ example: 2022, description: 'Vehicle year' })
  @IsOptional()
  @IsNumber()
  @Min(1900)
  @Max(new Date().getFullYear() + 1)
  year?: number;

  @ApiPropertyOptional({ example: 'White', description: 'Vehicle color' })
  @IsOptional()
  @IsString()
  color?: string;

  @ApiPropertyOptional({ example: 'ABC-1234', description: 'License plate' })
  @IsOptional()
  @IsString()
  licensePlate?: string;

  @ApiPropertyOptional({ description: 'Vehicle VIN' })
  @IsOptional()
  @IsString()
  vin?: string;

  @ApiPropertyOptional({ example: 75.0, description: 'Daily rental rate' })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Type(() => Number)
  dailyRate?: number;

  @ApiPropertyOptional({ example: 200.0, description: 'Security deposit' })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Type(() => Number)
  securityDeposit?: number;

  @ApiPropertyOptional({ example: 'petrol', description: 'Fuel type' })
  @IsOptional()
  @IsString()
  fuelType?: string;

  @ApiPropertyOptional({
    example: 'automatic',
    description: 'Transmission type',
  })
  @IsOptional()
  @IsString()
  transmission?: string;

  @ApiPropertyOptional({ example: 5, description: 'Number of seats' })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(50)
  seats?: number;

  @ApiPropertyOptional({ example: 37.7749, description: 'Location latitude' })
  @IsOptional()
  @IsNumber()
  @Min(-90)
  @Max(90)
  locationLat?: number;

  @ApiPropertyOptional({
    example: -122.4194,
    description: 'Location longitude',
  })
  @IsOptional()
  @IsNumber()
  @Min(-180)
  @Max(180)
  locationLng?: number;

  @ApiPropertyOptional({ description: 'Location address' })
  @IsOptional()
  @IsString()
  locationAddress?: string;

  @ApiPropertyOptional({
    example: 'San Francisco',
    description: 'Location city',
  })
  @IsOptional()
  @IsString()
  locationCity?: string;

  @ApiPropertyOptional({ description: 'Vehicle features array' })
  @IsOptional()
  @IsArray()
  features?: string[];

  @ApiPropertyOptional({ description: 'Vehicle description' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ description: 'Rental rules' })
  @IsOptional()
  @IsString()
  rules?: string;

  @ApiPropertyOptional({ description: 'Vehicle images array' })
  @IsOptional()
  @IsArray()
  images?: string[];

  @ApiPropertyOptional({ default: true, description: 'Vehicle availability' })
  @IsOptional()
  @IsBoolean()
  isAvailable?: boolean;

  @ApiPropertyOptional({ default: true, description: 'Vehicle active status' })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @ApiPropertyOptional({ description: 'Vehicle category ID' })
  @IsOptional()
  @IsUUID()
  categoryId?: string;
}
