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
import { Vehicle } from './vehicle.entity';

@Entity('favorites')
export class Favorite {
  @ApiProperty({ description: 'Favorite ID' })
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ApiProperty({ description: 'User ID' })
  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ApiProperty({ description: 'Vehicle ID' })
  @Column({ name: 'vehicle_id', type: 'uuid' })
  vehicleId: string;

  @ApiProperty({ description: 'Creation timestamp' })
  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  // Relationships
  @ManyToOne(() => User, (user) => user.favorites)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @ManyToOne(() => Vehicle, (vehicle) => vehicle.favorites)
  @JoinColumn({ name: 'vehicle_id' })
  vehicle: Vehicle;
}
