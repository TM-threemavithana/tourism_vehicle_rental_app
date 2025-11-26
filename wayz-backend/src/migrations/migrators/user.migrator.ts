import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../entities/user.entity';
import * as bcrypt from 'bcrypt';

interface FirebaseUserData {
  email: string;
  displayName?: string;
  firstName?: string;
  lastName?: string;
  phoneNumber?: string;
  photoURL?: string;
  role?: string;
  createdAt?: any;
  updatedAt?: any;
  emailVerified?: boolean;
  isActive?: boolean;
  address?: string;
  dateOfBirth?: any;
  licenseNumber?: string;
  [key: string]: any;
}

@Injectable()
export class UserMigrator {
  private readonly logger = new Logger(UserMigrator.name);

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async migrate(firebaseUid: string, data: FirebaseUserData): Promise<User> {
    try {
      // Check if user already exists by Firebase UID or email
      const existingUser = await this.userRepository.findOne({
        where: [
          { firebaseUid },
          { email: data.email },
        ],
      });

      if (existingUser) {
        this.logger.debug(`User already exists: ${data.email}, updating...`);
        return await this.updateUser(existingUser, firebaseUid, data);
      }

      return await this.createUser(firebaseUid, data);
    } catch (error) {
      this.logger.error(
        `Failed to migrate user ${firebaseUid}:`,
        error.message,
      );
      throw error;
    }
  }

  private async createUser(
    firebaseUid: string,
    data: FirebaseUserData,
  ): Promise<User> {
    // Parse names
    const { firstName, lastName } = this.parseDisplayName(data);

    // Generate a random password hash for migrated users
    // Users will need to reset their password or use Firebase login
    const tempPassword = Math.random().toString(36).slice(-12);
    const passwordHash = await bcrypt.hash(tempPassword, 10);

    const user = this.userRepository.create({
      firebaseUid,
      email: data.email,
      passwordHash,
      firstName: data.firstName || firstName,
      lastName: data.lastName || lastName,
      phoneNumber: data.phoneNumber,
      profileImageUrl: data.photoURL,
      role: this.mapRole(data.role),
      emailVerified: data.emailVerified || false,
      isEmailVerified: data.emailVerified || false,
      isActive: data.isActive !== false,
      address: data.address,
      dateOfBirth: this.parseDate(data.dateOfBirth),
      licenseNumber: data.licenseNumber,
      createdAt: this.parseDate(data.createdAt) || new Date(),
      updatedAt: this.parseDate(data.updatedAt) || new Date(),
    });

    const savedUser = await this.userRepository.save(user);
    this.logger.debug(`✅ Created user: ${savedUser.email}`);
    return savedUser;
  }

  private async updateUser(
    existingUser: User,
    firebaseUid: string,
    data: FirebaseUserData,
  ): Promise<User> {
    const { firstName, lastName } = this.parseDisplayName(data);

    // Update user with Firebase data if not already set
    existingUser.firebaseUid = firebaseUid;
    existingUser.firstName = existingUser.firstName || data.firstName || firstName;
    existingUser.lastName = existingUser.lastName || data.lastName || lastName;
    existingUser.phoneNumber = existingUser.phoneNumber || data.phoneNumber;
    existingUser.profileImageUrl = existingUser.profileImageUrl || data.photoURL;
    existingUser.emailVerified = existingUser.emailVerified || data.emailVerified || false;
    existingUser.isEmailVerified = existingUser.isEmailVerified || data.emailVerified || false;
    existingUser.address = existingUser.address || data.address;
    existingUser.dateOfBirth = existingUser.dateOfBirth || this.parseDate(data.dateOfBirth);
    existingUser.licenseNumber = existingUser.licenseNumber || data.licenseNumber;

    const savedUser = await this.userRepository.save(existingUser);
    this.logger.debug(`✅ Updated user: ${savedUser.email}`);
    return savedUser;
  }

  private parseDisplayName(data: FirebaseUserData): {
    firstName: string;
    lastName: string;
  } {
    if (data.firstName && data.lastName) {
      return { firstName: data.firstName, lastName: data.lastName };
    }

    if (data.displayName) {
      const parts = data.displayName.trim().split(' ');
      return {
        firstName: parts[0] || '',
        lastName: parts.slice(1).join(' ') || '',
      };
    }

    return { firstName: '', lastName: '' };
  }

  private mapRole(role?: string): 'customer' | 'owner' | 'admin' {
    if (!role) return 'customer';

    const normalized = role.toLowerCase();
    if (normalized === 'owner' || normalized === 'vehicle_owner') {
      return 'owner';
    }
    if (normalized === 'admin') {
      return 'admin';
    }
    return 'customer';
  }

  private parseDate(timestamp: any): Date | undefined {
    if (!timestamp) return undefined;

    // Handle Firebase Timestamp
    if (timestamp._seconds !== undefined) {
      return new Date(timestamp._seconds * 1000);
    }

    // Handle Firestore Timestamp object
    if (timestamp.toDate && typeof timestamp.toDate === 'function') {
      return timestamp.toDate();
    }

    // Handle ISO string or number
    if (typeof timestamp === 'string' || typeof timestamp === 'number') {
      const date = new Date(timestamp);
      return isNaN(date.getTime()) ? undefined : date;
    }

    return undefined;
  }

  /**
   * Find PostgreSQL user by Firebase UID
   */
  async findByFirebaseUid(firebaseUid: string): Promise<User | null> {
    return await this.userRepository.findOne({
      where: { firebaseUid },
    });
  }

  /**
   * Find PostgreSQL user by email
   */
  async findByEmail(email: string): Promise<User | null> {
    return await this.userRepository.findOne({
      where: { email },
    });
  }
}
