import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam } from '@nestjs/swagger';
import { VehicleCategoriesService } from './vehicle-categories.service';
import {
  CreateVehicleCategoryDto,
  UpdateVehicleCategoryDto,
  VehicleCategoryResponseDto,
} from '../dto/vehicle-category.dto';

@ApiTags('Vehicle Categories')
@Controller('vehicle-categories')
export class VehicleCategoriesController {
  constructor(private readonly categoriesService: VehicleCategoriesService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new vehicle category' })
  @ApiResponse({
    status: 201,
    description: 'Category created successfully',
    type: VehicleCategoryResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Bad request - validation errors' })
  async create(@Body() createCategoryDto: CreateVehicleCategoryDto) {
    return this.categoriesService.create(createCategoryDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all vehicle categories' })
  @ApiResponse({
    status: 200,
    description: 'Categories retrieved successfully',
    type: [VehicleCategoryResponseDto],
  })
  async findAll() {
    return this.categoriesService.findAll();
  }

  @Get('with-stats')
  @ApiOperation({ summary: 'Get all categories with vehicle counts' })
  @ApiResponse({
    status: 200,
    description: 'Categories with statistics retrieved successfully',
  })
  async getCategoriesWithStats() {
    return this.categoriesService.getCategoriesWithStats();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a category by ID' })
  @ApiParam({ name: 'id', description: 'Category ID' })
  @ApiResponse({
    status: 200,
    description: 'Category retrieved successfully',
    type: VehicleCategoryResponseDto,
  })
  @ApiResponse({ status: 404, description: 'Category not found' })
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.categoriesService.findOne(id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a category' })
  @ApiParam({ name: 'id', description: 'Category ID' })
  @ApiResponse({
    status: 200,
    description: 'Category updated successfully',
    type: VehicleCategoryResponseDto,
  })
  @ApiResponse({ status: 404, description: 'Category not found' })
  @ApiResponse({ status: 400, description: 'Bad request - validation errors' })
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateCategoryDto: UpdateVehicleCategoryDto,
  ) {
    return this.categoriesService.update(id, updateCategoryDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a category' })
  @ApiParam({ name: 'id', description: 'Category ID' })
  @ApiResponse({ status: 200, description: 'Category deleted successfully' })
  @ApiResponse({ status: 404, description: 'Category not found' })
  async remove(@Param('id', ParseUUIDPipe) id: string) {
    await this.categoriesService.remove(id);
    return { message: 'Category deleted successfully' };
  }
}
