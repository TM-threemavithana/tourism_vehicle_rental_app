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
import { Vehicle } from './vehicle.entity';
import { PaymentTransaction } from './payment-transaction.entity';

export enum BookingStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
  REFUNDED = 'refunded',
}

export enum PaymentStatus {
  PENDING = 'pending',
  PAID = 'paid',
  FAILED = 'failed',
  REFUNDED = 'refunded',
  PARTIAL = 'partial',
}

@Entity('bookings')
export class Booking {
  @ApiProperty({ description: 'Booking ID' })
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

  @ApiProperty({ description: 'Booking start date' })
  @Column({ name: 'start_date', type: 'timestamptz' })
  startDate: Date;

  @ApiProperty({ description: 'Booking end date' })
  @Column({ name: 'end_date', type: 'timestamptz' })
  endDate: Date;

  @ApiProperty({ description: 'Daily rate at time of booking', example: 75 })
  @Column({
    name: 'daily_rate',
    type: 'decimal',
    precision: 10,
    scale: 2,
  })
  dailyRate: number;

  @ApiProperty({ description: 'Total days', example: 3 })
  @Column({ name: 'total_days', type: 'integer' })
  totalDays: number;

  @ApiProperty({ description: 'Subtotal amount', example: 225 })
  @Column({
    type: 'decimal',
    precision: 10,
    scale: 2,
  })
  subtotal: number;

  @ApiProperty({ description: 'Tax amount', example: 22.5 })
  @Column({
    name: 'tax_amount',
    type: 'decimal',
    precision: 10,
    scale: 2,
    default: 0,
  })
  taxAmount: number;

  @ApiProperty({ description: 'Discount amount', example: 0 })
  @Column({
    name: 'discount_amount',
    type: 'decimal',
    precision: 10,
    scale: 2,
    default: 0,
  })
  discountAmount: number;

  @ApiProperty({ description: 'Total amount', example: 247.5 })
  @Column({
    name: 'total_amount',
    type: 'decimal',
    precision: 10,
    scale: 2,
  })
  totalAmount: number;

  @ApiProperty({ description: 'Security deposit', example: 200 })
  @Column({
    name: 'security_deposit',
    type: 'decimal',
    precision: 10,
    scale: 2,
    nullable: true,
  })
  securityDeposit?: number;

  @ApiProperty({
    description: 'Booking status',
    enum: BookingStatus,
    example: BookingStatus.CONFIRMED,
  })
  @Column({
    type: 'enum',
    enum: BookingStatus,
    default: BookingStatus.PENDING,
  })
  status: BookingStatus;

  @ApiProperty({
    description: 'Payment status',
    enum: PaymentStatus,
    example: PaymentStatus.PAID,
  })
  @Column({
    name: 'payment_status',
    type: 'enum',
    enum: PaymentStatus,
    default: PaymentStatus.PENDING,
  })
  paymentStatus: PaymentStatus;

  @ApiProperty({ description: 'Pickup location' })
  @Column({ name: 'pickup_location', type: 'text', nullable: true })
  pickupLocation?: string;

  @ApiProperty({ description: 'Dropoff location' })
  @Column({ name: 'dropoff_location', type: 'text', nullable: true })
  dropoffLocation?: string;

  @ApiProperty({ description: 'Special requests' })
  @Column({ name: 'special_requests', type: 'text', nullable: true })
  specialRequests?: string;

  @ApiProperty({ description: 'Booking date' })
  @Column({
    name: 'booking_date',
    type: 'timestamptz',
    default: () => 'CURRENT_TIMESTAMP',
  })
  bookingDate: Date;

  @ApiProperty({ description: 'Creation timestamp' })
  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @ApiProperty({ description: 'Update timestamp' })
  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  // Relationships
  @ManyToOne(() => User, (user) => user.bookings)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @ManyToOne(() => Vehicle, (vehicle) => vehicle.bookings)
  @JoinColumn({ name: 'vehicle_id' })
  vehicle: Vehicle;

  @OneToMany(() => PaymentTransaction, (transaction) => transaction.booking)
  paymentTransactions: PaymentTransaction[];
}
