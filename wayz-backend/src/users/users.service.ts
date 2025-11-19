import {
  Injectable,
  NotFoundException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities/user.entity';
import { CreateUserDto, UpdateUserDto } from '../dto/user.dto';
import { CacheService } from '../cache/cache.service';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);
  private readonly CACHE_TTL = 600; // 10 minutes for user profiles
  private readonly STATS_CACHE_TTL = 300; // 5 minutes for stats

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly cacheService: CacheService,
  ) {}

  async create(createUserDto: CreateUserDto): Promise<User> {
    // Check if user with email already exists
    const existingUser = await this.userRepository.findOne({
      where: { email: createUserDto.email },
    });

    if (existingUser) {
      throw new ConflictException('User with this email already exists');
    }

    // Check if Firebase UID already exists (for migration)
    if (createUserDto.firebaseUid) {
      const existingFirebaseUser = await this.userRepository.findOne({
        where: { firebaseUid: createUserDto.firebaseUid },
      });

      if (existingFirebaseUser) {
        throw new ConflictException(
          'User with this Firebase UID already exists',
        );
      }
    }

    const user = this.userRepository.create(createUserDto);
    const savedUser = await this.userRepository.save(user);

    // Cache the newly created user
    await this.cacheService.set(
      `user:${savedUser.id}`,
      savedUser,
      this.CACHE_TTL,
    );
    await this.cacheService.set(
      `user:email:${savedUser.email}`,
      savedUser,
      this.CACHE_TTL,
    );

    // Invalidate list cache
    await this.cacheService.del('users:all');

    return savedUser;
  }

  async findAll(): Promise<User[]> {
    const cacheKey = 'users:all';

    const cached = await this.cacheService.get<User[]>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const users = await this.userRepository.find({
      where: { isActive: true },
      order: { createdAt: 'DESC' },
    });

    await this.cacheService.set(cacheKey, users, this.CACHE_TTL);
    return users;
  }

  async findOne(id: string): Promise<User> {
    const cacheKey = `user:${id}`;

    const cached = await this.cacheService.get<User>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const user = await this.userRepository.findOne({
      where: { id, isActive: true },
    });

    if (!user) {
      throw new NotFoundException(`User with ID "${id}" not found`);
    }

    await this.cacheService.set(cacheKey, user, this.CACHE_TTL);
    return user;
  }

  async findByEmail(email: string): Promise<User | null> {
    const cacheKey = `user:email:${email}`;

    const cached = await this.cacheService.get<User>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const user = await this.userRepository.findOne({
      where: { email, isActive: true },
    });

    if (user) {
      await this.cacheService.set(cacheKey, user, this.CACHE_TTL);
    }

    return user;
  }

  async findByFirebaseUid(firebaseUid: string): Promise<User | null> {
    const cacheKey = `user:firebase:${firebaseUid}`;

    const cached = await this.cacheService.get<User>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const user = await this.userRepository.findOne({
      where: { firebaseUid, isActive: true },
    });

    if (user) {
      await this.cacheService.set(cacheKey, user, this.CACHE_TTL);
    }

    return user;
  }

  async update(id: string, updateUserDto: UpdateUserDto): Promise<User> {
    const user = await this.findOne(id);

    // Update the user properties
    Object.assign(user, updateUserDto);

    const updatedUser = await this.userRepository.save(user);

    // Invalidate all related caches
    await this.invalidateUserCache(id, user.email, user.firebaseUid);

    return updatedUser;
  }

  async remove(id: string): Promise<void> {
    const user = await this.findOne(id);

    // Soft delete - set isActive to false
    user.isActive = false;
    await this.userRepository.save(user);

    // Invalidate all related caches
    await this.invalidateUserCache(id, user.email, user.firebaseUid);
  }

  async updateLastLogin(id: string): Promise<void> {
    await this.userRepository.update(id, {
      lastLoginAt: new Date(),
    });

    // Invalidate user cache to reflect updated lastLoginAt
    const user = await this.userRepository.findOne({ where: { id } });
    if (user) {
      await this.invalidateUserCache(id, user.email, user.firebaseUid);
    }
  }

  async verifyEmail(id: string): Promise<User> {
    const user = await this.findOne(id);
    user.emailVerified = true;
    const verifiedUser = await this.userRepository.save(user);

    // Invalidate user cache
    await this.invalidateUserCache(id, user.email, user.firebaseUid);

    return verifiedUser;
  }

  // Statistics methods
  async getUserStats(): Promise<{
    total: number;
    verified: number;
    active: number;
    newThisMonth: number;
  }> {
    const cacheKey = 'users:stats';

    const cached = await this.cacheService.get<{
      total: number;
      verified: number;
      active: number;
      newThisMonth: number;
    }>(cacheKey);

    if (cached) {
      this.logger.debug(`Cache HIT: ${cacheKey}`);
      return cached;
    }

    this.logger.debug(`Cache MISS: ${cacheKey}`);
    const [total, verified, active, newThisMonth] = await Promise.all([
      this.userRepository.count(),
      this.userRepository.count({ where: { emailVerified: true } }),
      this.userRepository.count({ where: { isActive: true } }),
      this.userRepository.count({
        where: {
          createdAt: new Date(
            new Date().getFullYear(),
            new Date().getMonth(),
            1,
          ),
        },
      }),
    ]);

    const stats = { total, verified, active, newThisMonth };
    await this.cacheService.set(cacheKey, stats, this.STATS_CACHE_TTL);

    return stats;
  }

  // Cache invalidation helper
  private async invalidateUserCache(
    id: string,
    email?: string,
    firebaseUid?: string | null,
  ): Promise<void> {
    const keysToDelete = [`user:${id}`, 'users:all', 'users:stats'];

    if (email) {
      keysToDelete.push(`user:email:${email}`);
    }

    if (firebaseUid) {
      keysToDelete.push(`user:firebase:${firebaseUid}`);
    }

    await Promise.all(keysToDelete.map((key) => this.cacheService.del(key)));
    this.logger.debug(`Invalidated caches: ${keysToDelete.join(', ')}`);
  }
}
