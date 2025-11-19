import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { User } from './user.entity';

@Entity('notifications')
export class Notification {
  @ApiProperty({ description: 'Notification ID' })
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ApiProperty({ description: 'User ID' })
  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ApiProperty({
    description: 'Notification title',
    example: 'Booking Confirmed',
  })
  @Column({ type: 'varchar', length: 200 })
  title: string;

  @ApiProperty({ description: 'Notification message' })
  @Column({ type: 'text' })
  message: string;

  @ApiProperty({ description: 'Notification type', example: 'booking' })
  @Column({ type: 'varchar', length: 50, nullable: true })
  type?: string;

  @ApiProperty({ description: 'Reference ID for related entity' })
  @Column({ name: 'reference_id', type: 'uuid', nullable: true })
  referenceId?: string;

  @ApiProperty({ description: 'Read status', default: false })
  @Column({ name: 'is_read', type: 'boolean', default: false })
  isRead: boolean;

  @ApiProperty({ description: 'Push notification sent status', default: false })
  @Column({ name: 'is_push_sent', type: 'boolean', default: false })
  isPushSent: boolean;

  @ApiProperty({ description: 'Creation timestamp' })
  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  // Relationships
  @ManyToOne(() => User, (user) => user.notifications)
  @JoinColumn({ name: 'user_id' })
  user: User;
}
