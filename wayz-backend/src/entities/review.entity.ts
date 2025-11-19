import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { User } from './user.entity';
import { Vehicle } from './vehicle.entity';
import { Booking } from './booking.entity';

@Entity('reviews')
export class Review {
  @ApiProperty({ description: 'Review ID' })
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

  @ApiProperty({ description: 'User ID' })
  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ApiProperty({ description: 'Vehicle ID' })
  @Column({ name: 'vehicle_id', type: 'uuid' })
  vehicleId: string;

  @ApiProperty({ description: 'Booking ID', required: false })
  @Column({ name: 'booking_id', type: 'uuid', nullable: true })
  bookingId?: string;

  @ApiProperty({ description: 'Rating (1-5)', example: 4 })
  @Column({ type: 'integer' })
  rating: number;

  @ApiProperty({ description: 'Review title', example: 'Great car!' })
  @Column({ type: 'varchar', length: 200, nullable: true })
  title?: string;

  @ApiProperty({ description: 'Review comment' })
  @Column({ type: 'text', nullable: true })
  comment?: string;

  @ApiProperty({ description: 'Owner response' })
  @Column({ name: 'owner_response', type: 'text', nullable: true })
  ownerResponse?: string;

  @ApiProperty({ description: 'Owner response date' })
  @Column({ name: 'owner_response_date', type: 'timestamptz', nullable: true })
  ownerResponseDate?: Date;

  @ApiProperty({ description: 'Review verified status', default: false })
  @Column({ name: 'is_verified', type: 'boolean', default: false })
  isVerified: boolean;

  @ApiProperty({ description: 'Featured review status', default: false })
  @Column({ name: 'is_featured', type: 'boolean', default: false })
  isFeatured: boolean;

  @ApiProperty({ description: 'Creation timestamp' })
  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @ApiProperty({ description: 'Update timestamp' })
  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  // Relationships
  @ManyToOne(() => User, (user) => user.reviews)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @ManyToOne(() => Vehicle, (vehicle) => vehicle.reviews)
  @JoinColumn({ name: 'vehicle_id' })
  vehicle: Vehicle;

  @ManyToOne(() => Booking, { nullable: true })
  @JoinColumn({ name: 'booking_id' })
  booking?: Booking;
}
