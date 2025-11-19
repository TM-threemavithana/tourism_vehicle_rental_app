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
import { BookingsService } from './bookings.service';
import {
  CreateBookingDto,
  UpdateBookingDto,
  BookingResponseDto,
} from '../dto/booking.dto';

@ApiTags('Bookings')
@Controller('bookings')
export class BookingsController {
  constructor(private readonly bookingsService: BookingsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new booking' })
  @ApiResponse({
    status: 201,
    description: 'Booking created successfully',
    type: BookingResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Bad request - validation errors' })
  async create(@Body() createBookingDto: CreateBookingDto) {
    return this.bookingsService.create(createBookingDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all bookings with optional filters' })
  @ApiQuery({
    name: 'userId',
    required: false,
    description: 'Filter bookings by user ID',
  })
  @ApiQuery({
    name: 'vehicleId',
    required: false,
    description: 'Filter bookings by vehicle ID',
  })
  @ApiResponse({
    status: 200,
    description: 'Bookings retrieved successfully',
    type: [BookingResponseDto],
  })
  async findAll(
    @Query('userId') userId?: string,
    @Query('vehicleId') vehicleId?: string,
  ) {
    return this.bookingsService.findAll(userId, vehicleId);
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get booking statistics' })
  @ApiResponse({
    status: 200,
    description: 'Statistics retrieved successfully',
  })
  async getStats() {
    return this.bookingsService.getBookingStats();
  }

  @Get('user/:userId')
  @ApiOperation({ summary: 'Get bookings for a specific user' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  @ApiResponse({
    status: 200,
    description: 'User bookings retrieved successfully',
    type: [BookingResponseDto],
  })
  async getUserBookings(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.bookingsService.getUserBookings(userId);
  }

  @Get('vehicle/:vehicleId')
  @ApiOperation({ summary: 'Get bookings for a specific vehicle' })
  @ApiParam({ name: 'vehicleId', description: 'Vehicle ID' })
  @ApiResponse({
    status: 200,
    description: 'Vehicle bookings retrieved successfully',
    type: [BookingResponseDto],
  })
  async getVehicleBookings(
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
  ) {
    return this.bookingsService.getVehicleBookings(vehicleId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a booking by ID' })
  @ApiParam({ name: 'id', description: 'Booking ID' })
  @ApiResponse({
    status: 200,
    description: 'Booking retrieved successfully',
    type: BookingResponseDto,
  })
  @ApiResponse({ status: 404, description: 'Booking not found' })
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.bookingsService.findOne(id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a booking' })
  @ApiParam({ name: 'id', description: 'Booking ID' })
  @ApiResponse({
    status: 200,
    description: 'Booking updated successfully',
    type: BookingResponseDto,
  })
  @ApiResponse({ status: 404, description: 'Booking not found' })
  @ApiResponse({ status: 400, description: 'Bad request - validation errors' })
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateBookingDto: UpdateBookingDto,
  ) {
    return this.bookingsService.update(id, updateBookingDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Cancel a booking' })
  @ApiParam({ name: 'id', description: 'Booking ID' })
  @ApiResponse({ status: 200, description: 'Booking cancelled successfully' })
  @ApiResponse({ status: 404, description: 'Booking not found' })
  @ApiResponse({ status: 400, description: 'Cannot cancel this booking' })
  async remove(@Param('id', ParseUUIDPipe) id: string) {
    await this.bookingsService.remove(id);
    return { message: 'Booking cancelled successfully' };
  }
}
