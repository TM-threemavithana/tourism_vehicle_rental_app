import { IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateFavoriteDto {
  @ApiProperty({
    description: 'ID of the vehicle to add to favorites',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsUUID()
  vehicleId: string;
}

export class FavoriteResponseDto {
  @ApiProperty({ description: 'Favorite ID' })
  id: string;

  @ApiProperty({ description: 'User information' })
  user: {
    id: string;
    firstName: string;
    lastName: string;
  };

  @ApiProperty({ description: 'Vehicle information' })
  vehicle: {
    id: string;
    name: string;
    brand: string;
    model: string;
    year: number;
    pricePerDay: number;
    imageUrl: string;
    category: {
      name: string;
    };
  };

  @ApiProperty({ description: 'Creation timestamp' })
  createdAt: Date;
}
