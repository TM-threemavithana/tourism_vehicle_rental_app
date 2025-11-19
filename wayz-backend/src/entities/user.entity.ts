import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { Vehicle } from './vehicle.entity';
import { Booking } from './booking.entity';
import { Review } from './review.entity';
import { Favorite } from './favorite.entity';
import { Notification } from './notification.entity';
import { PaymentTransaction } from './payment-transaction.entity';

@Entity('users')
export class User {
  @ApiProperty({ description: 'User ID', example: 'uuid' })
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ApiProperty({ description: 'Firebase UID for migration', required: false })
  @Column({
    name: 'firebase_uid',
    type: 'varchar',
    length: 255,
    nullable: true,
    unique: true,
  })
  firebaseUid?: string;

  @ApiProperty({ description: 'User email', example: 'user@example.com' })
  @Column({ type: 'varchar', length: 255, unique: true })
  email: string;

  @ApiProperty({ description: 'Password hash for authentication' })
  @Column({
    name: 'password_hash',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  passwordHash?: string;

  @ApiProperty({
    description: 'User role',
    enum: ['customer', 'owner', 'admin'],
    default: 'customer',
  })
  @Column({
    type: 'enum',
    enum: ['customer', 'owner', 'admin'],
    default: 'customer',
  })
  role: 'customer' | 'owner' | 'admin';

  @ApiProperty({ description: 'Email verification status', default: false })
  @Column({ name: 'email_verified', type: 'boolean', default: false })
  emailVerified: boolean;

  @ApiProperty({
    description: 'Email verification status (alias for auth service)',
    default: false,
  })
  @Column({ name: 'is_email_verified', type: 'boolean', default: false })
  isEmailVerified: boolean;

  @ApiProperty({ description: 'Password reset token' })
  @Column({
    name: 'password_reset_token',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  passwordResetToken?: string;

  @ApiProperty({ description: 'Password reset token expiry' })
  @Column({
    name: 'password_reset_expires',
    type: 'timestamptz',
    nullable: true,
  })
  passwordResetExpires?: Date;

  @ApiProperty({ description: 'User first name', example: 'John' })
  @Column({ name: 'first_name', type: 'varchar', length: 100, nullable: true })
  firstName?: string;

  @ApiProperty({ description: 'User last name', example: 'Doe' })
  @Column({ name: 'last_name', type: 'varchar', length: 100, nullable: true })
  lastName?: string;

  @ApiProperty({ description: 'Phone number', example: '+1234567890' })
  @Column({ name: 'phone_number', type: 'varchar', length: 20, nullable: true })
  phoneNumber?: string;

  @ApiProperty({ description: 'Profile image URL' })
  @Column({ name: 'profile_image_url', type: 'text', nullable: true })
  profileImageUrl?: string;

  @ApiProperty({ description: 'Date of birth' })
  @Column({ name: 'date_of_birth', type: 'date', nullable: true })
  dateOfBirth?: Date;

  @ApiProperty({ description: 'Driver license number' })
  @Column({
    name: 'license_number',
    type: 'varchar',
    length: 50,
    nullable: true,
  })
  licenseNumber?: string;

  @ApiProperty({ description: 'License expiry date' })
  @Column({ name: 'license_expiry', type: 'date', nullable: true })
  licenseExpiry?: Date;

  @ApiProperty({ description: 'User address' })
  @Column({ type: 'text', nullable: true })
  address?: string;

  @ApiProperty({ description: 'City' })
  @Column({ type: 'varchar', length: 100, nullable: true })
  city?: string;

  @ApiProperty({ description: 'Country' })
  @Column({ type: 'varchar', length: 100, nullable: true })
  country?: string;

  @ApiProperty({ description: 'Account active status', default: true })
  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;

  @ApiProperty({ description: 'Last login timestamp' })
  @Column({ name: 'last_login_at', type: 'timestamptz', nullable: true })
  lastLoginAt?: Date;

  @ApiProperty({ description: 'Account creation timestamp' })
  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @ApiProperty({ description: 'Last update timestamp' })
  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  // Relationships
  @OneToMany(() => Vehicle, (vehicle) => vehicle.owner)
  vehicles: Vehicle[];

  @OneToMany(() => Booking, (booking) => booking.user)
  bookings: Booking[];

  @OneToMany(() => Review, (review) => review.user)
  reviews: Review[];

  @OneToMany(() => Favorite, (favorite) => favorite.user)
  favorites: Favorite[];

  @OneToMany(() => Notification, (notification) => notification.user)
  notifications: Notification[];

  @OneToMany(() => PaymentTransaction, (transaction) => transaction.user)
  paymentTransactions: PaymentTransaction[];
}
