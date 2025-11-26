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
  UseInterceptors,
  UploadedFiles,
  BadRequestException,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiQuery, ApiConsumes } from '@nestjs/swagger';
import { FilesInterceptor } from '@nestjs/platform-express';
import { VehiclesService } from './vehicles.service';
import { CreateVehicleDto, UpdateVehicleDto } from '../dto/vehicle.dto';
import { Vehicle } from '../entities/vehicle.entity';
import { User } from '../entities/user.entity';
import { UploadService } from '../upload/upload.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserRole } from '../dto/auth.dto';

@ApiTags('Vehicles')
@Controller('vehicles')
export class VehiclesController {
  constructor(
    private readonly vehiclesService: VehiclesService,
    private readonly uploadService: UploadService,
  ) {}

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.OWNER, UserRole.ADMIN)
  @ApiOperation({ summary: 'Create a new vehicle' })
  @ApiResponse({ status: 201, description: 'Vehicle created successfully' })
  async create(
    @Body() createVehicleDto: CreateVehicleDto,
    @CurrentUser() user: User,
  ): Promise<Vehicle> {
    return await this.vehiclesService.create(createVehicleDto, user.id);
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

  @Post(':id/images')
  @ApiOperation({ summary: 'Upload vehicle images' })
  @ApiResponse({ status: 201, description: 'Images uploaded successfully' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FilesInterceptor('files'))
  async uploadImages(
    @Param('id', ParseUUIDPipe) id: string,
    @UploadedFiles() files: Express.Multer.File[],
  ) {
    if (!files || files.length === 0) {
      throw new BadRequestException('No files uploaded');
    }
    const imageUrls = await this.uploadService.uploadFiles(files);
    return await this.vehiclesService.addImages(id, imageUrls);
  }

  @Patch(':id/images')
  @ApiOperation({ summary: 'Update vehicle images' })
  @ApiResponse({ status: 200, description: 'Images updated successfully' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FilesInterceptor('files'))
  async updateImages(
    @Param('id', ParseUUIDPipe) id: string,
    @UploadedFiles() files: Express.Multer.File[],
  ) {
    if (!files || files.length === 0) {
      throw new BadRequestException('No files uploaded');
    }
    const imageUrls = await this.uploadService.uploadFiles(files);
    return await this.vehiclesService.updateImages(id, imageUrls);
  }

  @Delete(':id/images')
  @ApiOperation({ summary: 'Delete vehicle images' })
  @ApiResponse({ status: 204, description: 'Images deleted successfully' })
  async deleteImages(@Param('id', ParseUUIDPipe) id: string) {
    await this.vehiclesService.deleteImages(id);
  }
}
