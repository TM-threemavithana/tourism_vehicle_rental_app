import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  ParseUUIDPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiQuery,
  ApiParam,
} from '@nestjs/swagger';
import { ReviewsService } from './reviews.service';
import {
  CreateReviewDto,
  UpdateReviewDto,
  ReviewResponseDto,
} from '../dto/review.dto';

@ApiTags('Reviews')
@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Post(':userId')
  @ApiOperation({ summary: 'Create a new review' })
  @ApiParam({ name: 'userId', description: 'User ID creating the review' })
  @ApiResponse({
    status: 201,
    description: 'Review created successfully',
    type: ReviewResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Bad request - validation errors' })
  async create(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Body() createReviewDto: CreateReviewDto,
  ) {
    return this.reviewsService.create(userId, createReviewDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all reviews with optional vehicle filter' })
  @ApiQuery({
    name: 'vehicleId',
    required: false,
    description: 'Filter reviews by vehicle ID',
  })
  @ApiResponse({
    status: 200,
    description: 'Reviews retrieved successfully',
    type: [ReviewResponseDto],
  })
  async findAll(@Query('vehicleId') vehicleId?: string) {
    return this.reviewsService.findAll(vehicleId);
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get review statistics' })
  @ApiResponse({
    status: 200,
    description: 'Statistics retrieved successfully',
  })
  async getStats() {
    return this.reviewsService.getReviewStats();
  }

  @Get('user/:userId')
  @ApiOperation({ summary: 'Get reviews by a specific user' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({
    status: 200,
    description: 'User reviews retrieved successfully',
    type: [ReviewResponseDto],
  })
  async getUserReviews(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.reviewsService.getUserReviews(userId);
  }

  @Get('vehicle/:vehicleId')
  @ApiOperation({ summary: 'Get reviews for a specific vehicle' })
  @ApiParam({ name: 'vehicleId', description: 'Vehicle ID' })
  @ApiResponse({
    status: 200,
    description: 'Vehicle reviews retrieved successfully',
    type: [ReviewResponseDto],
  })
  async getVehicleReviews(
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
  ) {
    return this.reviewsService.getVehicleReviews(vehicleId);
  }

  @Get('vehicle/:vehicleId/rating')
  @ApiOperation({ summary: 'Get average rating for a vehicle' })
  @ApiParam({ name: 'vehicleId', description: 'Vehicle ID' })
  @ApiResponse({
    status: 200,
    description: 'Vehicle rating retrieved successfully',
  })
  async getVehicleRating(@Param('vehicleId', ParseUUIDPipe) vehicleId: string) {
    return this.reviewsService.getVehicleAverageRating(vehicleId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a review by ID' })
  @ApiParam({ name: 'id', description: 'Review ID' })
  @ApiResponse({
    status: 200,
    description: 'Review retrieved successfully',
    type: ReviewResponseDto,
  })
  @ApiResponse({ status: 404, description: 'Review not found' })
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.reviewsService.findOne(id);
  }

  @Patch(':id/user/:userId')
  @ApiOperation({ summary: 'Update a review' })
  @ApiParam({ name: 'id', description: 'Review ID' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({
    status: 200,
    description: 'Review updated successfully',
    type: ReviewResponseDto,
  })
  @ApiResponse({ status: 404, description: 'Review not found' })
  @ApiResponse({ status: 400, description: 'Bad request - validation errors' })
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('userId', ParseUUIDPipe) userId: string,
    @Body() updateReviewDto: UpdateReviewDto,
  ) {
    return this.reviewsService.update(id, userId, updateReviewDto);
  }

  @Delete(':id/user/:userId')
  @ApiOperation({ summary: 'Delete a review' })
  @ApiParam({ name: 'id', description: 'Review ID' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({ status: 200, description: 'Review deleted successfully' })
  @ApiResponse({ status: 404, description: 'Review not found' })
  @ApiResponse({ status: 400, description: 'Cannot delete this review' })
  async remove(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('userId', ParseUUIDPipe) userId: string,
  ) {
    await this.reviewsService.remove(id, userId);
    return { message: 'Review deleted successfully' };
  }
}
