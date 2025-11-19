import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam } from '@nestjs/swagger';
import { FavoritesService } from './favorites.service';
import { CreateFavoriteDto, FavoriteResponseDto } from '../dto/favorite.dto';

@ApiTags('Favorites')
@Controller('favorites')
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  @Post(':userId')
  @ApiOperation({ summary: 'Add vehicle to favorites' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({
    status: 201,
    description: 'Vehicle added to favorites successfully',
    type: FavoriteResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Bad request - validation errors' })
  async create(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Body() createFavoriteDto: CreateFavoriteDto,
  ) {
    return this.favoritesService.create(userId, createFavoriteDto);
  }

  @Get('user/:userId')
  @ApiOperation({ summary: 'Get user favorites' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({
    status: 200,
    description: 'User favorites retrieved successfully',
    type: [FavoriteResponseDto],
  })
  async getUserFavorites(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.favoritesService.findUserFavorites(userId);
  }

  @Get(':userId/check/:vehicleId')
  @ApiOperation({ summary: 'Check if vehicle is in favorites' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiParam({ name: 'vehicleId', description: 'Vehicle ID' })
  @ApiResponse({
    status: 200,
    description: 'Check result retrieved successfully',
  })
  async checkFavorite(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
  ) {
    const isFavorite = await this.favoritesService.checkIfFavorite(
      userId,
      vehicleId,
    );
    return { isFavorite };
  }

  @Delete(':userId/:vehicleId')
  @ApiOperation({ summary: 'Remove vehicle from favorites' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiParam({ name: 'vehicleId', description: 'Vehicle ID' })
  @ApiResponse({
    status: 200,
    description: 'Vehicle removed from favorites successfully',
  })
  @ApiResponse({ status: 404, description: 'Favorite not found' })
  async remove(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
  ) {
    await this.favoritesService.remove(userId, vehicleId);
    return { message: 'Vehicle removed from favorites successfully' };
  }
}
