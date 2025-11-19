import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities/user.entity';
import { CreateUserDto, UpdateUserDto } from '../dtos/user.dto';

@Injectable()
export class UserRepository {
  constructor(
    @InjectRepository(User)
    private readonly repository: Repository<User>,
  ) {}

  async create(createUserDto: CreateUserDto): Promise<User> {
    const user = this.repository.create(createUserDto);
    return await this.repository.save(user);
  }

  async findAll(): Promise<User[]> {
    return await this.repository.find({
      where: { isActive: true },
      order: { createdAt: 'DESC' },
    });
  }

  async findById(id: string): Promise<User | null> {
    return await this.repository.findOne({
      where: { id, isActive: true },
      relations: ['vehicles', 'bookings', 'favorites'],
    });
  }

  async findByEmail(email: string): Promise<User | null> {
    return await this.repository.findOne({
      where: { email, isActive: true },
    });
  }

  async findByFirebaseUid(firebaseUid: string): Promise<User | null> {
    return await this.repository.findOne({
      where: { firebaseUid, isActive: true },
    });
  }

  async update(id: string, updateUserDto: UpdateUserDto): Promise<User | null> {
    await this.repository.update(id, updateUserDto);
    return await this.findById(id);
  }

  async softDelete(id: string): Promise<void> {
    await this.repository.update(id, { isActive: false });
  }

  async delete(id: string): Promise<void> {
    await this.repository.delete(id);
  }

  async count(): Promise<number> {
    return await this.repository.count({ where: { isActive: true } });
  }
}
