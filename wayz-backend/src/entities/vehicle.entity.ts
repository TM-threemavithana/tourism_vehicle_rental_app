import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
} from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { User } from './user.entity';
import { VehicleCategory } from './vehicle-category.entity';
import { Booking } from './booking.entity';
import { Review } from './review.entity';
import { Favorite } from './favorite.entity';

@Entity('vehicles')
export class Vehicle {
  @ApiProperty({ description: 'Vehicle ID' })
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ApiProperty({
    description: 'Firebase document ID for migration',
    required: false,
  })
  @Column({
    name: 'firebase_doc_id',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  firebaseDocId?: string;

  @ApiProperty({ description: 'Vehicle category ID' })
  @Column({ name: 'category_id', type: 'uuid', nullable: true })
  categoryId?: string;

  @ApiProperty({ description: 'Vehicle owner ID' })
  @Column({ name: 'owner_id', type: 'uuid', nullable: true })
  ownerId?: string;

  @ApiProperty({ description: 'Vehicle make', example: 'Toyota' })
  @Column({ type: 'varchar', length: 50 })
  make: string;

  @ApiProperty({ description: 'Vehicle model', example: 'Camry' })
  @Column({ type: 'varchar', length: 100 })
  model: string;

  @ApiProperty({ description: 'Vehicle year', example: 2022 })
  @Column({ type: 'integer' })
  year: number;

  @ApiProperty({ description: 'Vehicle color', example: 'White' })
  @Column({ type: 'varchar', length: 50, nullable: true })
  color?: string;

  @ApiProperty({ description: 'License plate', example: 'ABC-1234' })
  @Column({
    name: 'license_plate',
    type: 'varchar',
    length: 20,
    nullable: true,
  })
  licensePlate?: string;

  @ApiProperty({ description: 'Vehicle VIN' })
  @Column({ type: 'varchar', length: 50, nullable: true })
  vin?: string;

  @ApiProperty({ description: 'Daily rental rate', example: 75.0 })
  @Column({ name: 'daily_rate', type: 'decimal', precision: 10, scale: 2 })
  dailyRate: number;

  @ApiProperty({ description: 'Security deposit', example: 200.0 })
  @Column({
    name: 'security_deposit',
    type: 'decimal',
    precision: 10,
    scale: 2,
    nullable: true,
  })
  securityDeposit?: number;

  @ApiProperty({ description: 'Fuel type', example: 'petrol' })
  @Column({ name: 'fuel_type', type: 'varchar', length: 20, nullable: true })
  fuelType?: string;

  @ApiProperty({ description: 'Transmission type', example: 'automatic' })
  @Column({ type: 'varchar', length: 20, nullable: true })
  transmission?: string;

  @ApiProperty({ description: 'Number of seats', example: 5 })
  @Column({ type: 'integer', nullable: true })
  seats?: number;

  @ApiProperty({ description: 'Location latitude', example: 37.7749 })
  @Column({
    name: 'location_lat',
    type: 'decimal',
    precision: 10,
    scale: 8,
    nullable: true,
  })
  locationLat?: number;

  @ApiProperty({ description: 'Location longitude', example: -122.4194 })
  @Column({
    name: 'location_lng',
    type: 'decimal',
    precision: 11,
    scale: 8,
    nullable: true,
  })
  locationLng?: number;

  @ApiProperty({ description: 'Location address' })
  @Column({ name: 'location_address', type: 'text', nullable: true })
  locationAddress?: string;

  @ApiProperty({ description: 'Location city' })
  @Column({
    name: 'location_city',
    type: 'varchar',
    length: 100,
    nullable: true,
  })
  locationCity?: string;

  @ApiProperty({
    description: 'Vehicle features',
    example: '["AC", "GPS", "Bluetooth"]',
  })
  @Column({ type: 'jsonb', nullable: true })
  features?: any;

  @ApiProperty({ description: 'Vehicle description' })
  @Column({ type: 'text', nullable: true })
  description?: string;

  @ApiProperty({ description: 'Rental rules' })
  @Column({ type: 'text', nullable: true })
  rules?: string;

  @ApiProperty({ description: 'Vehicle images', example: '["url1", "url2"]' })
  @Column({ type: 'jsonb', nullable: true })
  images?: any;

  @ApiProperty({ description: 'Vehicle availability status', default: true })
  @Column({ name: 'is_available', type: 'boolean', default: true })
  isAvailable: boolean;

  @ApiProperty({ description: 'Vehicle active status', default: true })
  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;

  @ApiProperty({ description: 'Vehicle creation timestamp' })
  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @ApiProperty({ description: 'Last update timestamp' })
  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  // Relationships
  @ManyToOne(() => VehicleCategory, { nullable: true })
  @JoinColumn({ name: 'category_id' })
  category?: VehicleCategory;

  @ManyToOne(() => User, (user) => user.vehicles, { nullable: true })
  @JoinColumn({ name: 'owner_id' })
  owner?: User;

  @OneToMany(() => Booking, (booking) => booking.vehicle)
  bookings: Booking[];

  @OneToMany(() => Review, (review) => review.vehicle)
  reviews: Review[];

  @OneToMany(() => Favorite, (favorite) => favorite.vehicle)
  favorites: Favorite[];
}
