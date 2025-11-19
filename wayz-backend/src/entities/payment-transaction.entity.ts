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
import { Booking } from './booking.entity';

@Entity('payment_transactions')
export class PaymentTransaction {
  @ApiProperty({ description: 'Payment transaction ID' })
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ApiProperty({ description: 'Booking ID' })
  @Column({ name: 'booking_id', type: 'uuid' })
  bookingId: string;

  @ApiProperty({ description: 'User ID' })
  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ApiProperty({ description: 'Transaction amount', example: 247.5 })
  @Column({
    type: 'decimal',
    precision: 10,
    scale: 2,
  })
  amount: number;

  @ApiProperty({ description: 'Currency code', example: 'USD' })
  @Column({ type: 'varchar', length: 3, default: 'USD' })
  currency: string;

  @ApiProperty({ description: 'Transaction type', example: 'payment' })
  @Column({
    name: 'transaction_type',
    type: 'varchar',
    length: 20,
    nullable: true,
  })
  transactionType?: string;

  @ApiProperty({ description: 'Payment gateway name', example: 'stripe' })
  @Column({ name: 'gateway_name', type: 'varchar', length: 50, nullable: true })
  gatewayName?: string;

  @ApiProperty({ description: 'Gateway transaction ID' })
  @Column({
    name: 'gateway_transaction_id',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  gatewayTransactionId?: string;

  @ApiProperty({ description: 'Gateway response data' })
  @Column({ name: 'gateway_response', type: 'jsonb', nullable: true })
  gatewayResponse?: any;

  @ApiProperty({ description: 'Transaction status', example: 'pending' })
  @Column({
    type: 'varchar',
    length: 20,
    default: 'pending',
  })
  status: string;

  @ApiProperty({ description: 'Creation timestamp' })
  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @ApiProperty({ description: 'Update timestamp' })
  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  // Relationships
  @ManyToOne(() => Booking, (booking) => booking.paymentTransactions)
  @JoinColumn({ name: 'booking_id' })
  booking: Booking;

  @ManyToOne(() => User, (user) => user.paymentTransactions)
  @JoinColumn({ name: 'user_id' })
  user: User;
}
