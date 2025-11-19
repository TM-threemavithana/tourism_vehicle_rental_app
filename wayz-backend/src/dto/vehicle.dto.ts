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
}
