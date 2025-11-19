import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  ParseUUIDPipe,
  Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiQuery } from '@nestjs/swagger';
import { VehiclesService } from './vehicles.service';
import { CreateVehicleDto, UpdateVehicleDto } from '../dto/vehicle.dto';
import { Vehicle } from '../entities/vehicle.entity';

@ApiTags('Vehicles')
@Controller('vehicles')
export class VehiclesController {
  constructor(private readonly vehiclesService: VehiclesService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new vehicle' })
  @ApiResponse({ status: 201, description: 'Vehicle created successfully' })
  async create(
    @Body() createVehicleDto: CreateVehicleDto,
    // TODO: Get owner ID from JWT token after auth implementation
    @Query('ownerId') ownerId: string = 'temp-owner-id',
  ): Promise<Vehicle> {
    return await this.vehiclesService.create(createVehicleDto, ownerId);
  }

  @Get()
  @ApiOperation({ summary: 'Get all vehicles' })
  @ApiResponse({ status: 200, type: [Vehicle] })
  async findAll(): Promise<Vehicle[]> {
    return await this.vehiclesService.findAll();
  }

  @Get('available')
  @ApiOperation({ summary: 'Get available vehicles' })
  @ApiResponse({ status: 200, type: [Vehicle] })
  async findAvailable(): Promise<Vehicle[]> {
    return await this.vehiclesService.findAvailable();
  }

  @Get('search')
  @ApiOperation({ summary: 'Search vehicles with filters' })
  @ApiQuery({ name: 'city', required: false })
  @ApiQuery({ name: 'make', required: false })
  @ApiQuery({ name: 'minPrice', required: false, type: Number })
  @ApiQuery({ name: 'maxPrice', required: false, type: Number })
  @ApiQuery({ name: 'seats', required: false, type: Number })
  async searchVehicles(
    @Query('city') city?: string,
    @Query('make') make?: string,
    @Query('minPrice') minPrice?: number,
    @Query('maxPrice') maxPrice?: number,
    @Query('seats') seats?: number,
  ): Promise<Vehicle[]> {
    return await this.vehiclesService.searchVehicles({
      city,
      make,
      minPrice,
      maxPrice,
      seats,
    });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get vehicle by ID' })
  @ApiResponse({ status: 200, type: Vehicle })
  async findOne(@Param('id', ParseUUIDPipe) id: string): Promise<Vehicle> {
    return await this.vehiclesService.findOne(id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update vehicle' })
  @ApiResponse({ status: 200, type: Vehicle })
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateVehicleDto: UpdateVehicleDto,
  ): Promise<Vehicle> {
    return await this.vehiclesService.update(id, updateVehicleDto);
  }

  @Patch(':id/availability')
  @ApiOperation({ summary: 'Update vehicle availability' })
  async setAvailability(
    @Param('id', ParseUUIDPipe) id: string,
    @Body('isAvailable') isAvailable: boolean,
  ): Promise<Vehicle> {
    return await this.vehiclesService.setAvailability(id, isAvailable);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete vehicle (soft delete)' })
  @ApiResponse({ status: 204, description: 'Vehicle deleted successfully' })
  async remove(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    await this.vehiclesService.remove(id);
  }
}
