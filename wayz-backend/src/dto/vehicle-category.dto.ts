import {
  IsString,
  Length,
  IsOptional,
  IsNumber,
  IsPositive,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateVehicleCategoryDto {
  @ApiProperty({
    description: 'Category name',
    example: 'Luxury Sedan',
    maxLength: 100,
  })
  @IsString()
  @Length(1, 100)
  name: string;

  @ApiProperty({
    description: 'Category description',
    example:
      'Premium luxury vehicles for special occasions and business travel',
    maxLength: 500,
    required: false,
  })
  @IsOptional()
  @IsString()
  @Length(1, 500)
  description?: string;

  @ApiProperty({
    description: 'Category icon URL',
    example: 'https://example.com/icons/luxury-sedan.png',
    required: false,
  })
  @IsOptional()
  @IsString()
  iconUrl?: string;

  @ApiProperty({
    description: 'Display order for sorting',
    example: 1,
    required: false,
  })
  @IsOptional()
  @IsNumber()
  @IsPositive()
  displayOrder?: number;
}

export class UpdateVehicleCategoryDto {
  @ApiProperty({
    description: 'Category name',
    example: 'Luxury Sedan',
    maxLength: 100,
    required: false,
  })
  @IsOptional()
  @IsString()
  @Length(1, 100)
  name?: string;

  @ApiProperty({
    description: 'Category description',
    example:
      'Premium luxury vehicles for special occasions and business travel',
    maxLength: 500,
    required: false,
  })
  @IsOptional()
  @IsString()
  @Length(1, 500)
  description?: string;

  @ApiProperty({
    description: 'Category icon URL',
    example: 'https://example.com/icons/luxury-sedan.png',
    required: false,
  })
  @IsOptional()
  @IsString()
  iconUrl?: string;

  @ApiProperty({
    description: 'Display order for sorting',
    example: 1,
    required: false,
  })
  @IsOptional()
  @IsNumber()
  @IsPositive()
  displayOrder?: number;
}

export class VehicleCategoryResponseDto {
  @ApiProperty({ description: 'Category ID' })
  id: string;

  @ApiProperty({ description: 'Category name' })
  name: string;

  @ApiProperty({ description: 'Category description' })
  description?: string;

  @ApiProperty({ description: 'Category icon URL' })
  iconUrl?: string;

  @ApiProperty({ description: 'Display order' })
  displayOrder: number;

  @ApiProperty({ description: 'Number of vehicles in this category' })
  vehicleCount?: number;

  @ApiProperty({ description: 'Creation timestamp' })
  createdAt: Date;

  @ApiProperty({ description: 'Last update timestamp' })
  updatedAt: Date;
}
