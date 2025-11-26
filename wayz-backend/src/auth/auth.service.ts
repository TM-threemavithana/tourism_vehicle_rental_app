import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from '../entities/user.entity';
import {
  RegisterDto,
  LoginDto,
  AuthResponseDto,
  ChangePasswordDto,
  UserRole,
} from '../dto/auth.dto';
import { TokenBlacklistService } from './services/token-blacklist.service';
import { EmailService } from '../email/email.service';

interface RefreshPayload {
  sub: string;
  email: string;
  role: string;
  type: string;
  iat?: number;
  exp?: number;
}

@Injectable()
export class AuthService {
  private readonly saltRounds = 12;

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly tokenBlacklistService: TokenBlacklistService,
    private readonly emailService: EmailService,
  ) {}

  async register(registerDto: RegisterDto): Promise<AuthResponseDto> {
    const { email, password, firstName, lastName, phoneNumber, role } =
      registerDto;

    // Check if user already exists
    const existingUser = await this.userRepository.findOne({
      where: { email },
    });

    if (existingUser) {
      throw new ConflictException('User with this email already exists');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, this.saltRounds);

    // Create new user
    const user = this.userRepository.create({
      email,
      passwordHash: hashedPassword,
      firstName,
      lastName,
      phoneNumber,
      role: role || UserRole.CUSTOMER,
      isActive: true,
      isEmailVerified: false,
    });

    const savedUser = await this.userRepository.save(user);

    // Generate JWT token
    const payload = {
      sub: savedUser.id,
      email: savedUser.email,
      role: savedUser.role,
    };
    const accessToken = this.jwtService.sign(payload);

    // Add token to user's active tokens
    const expiresIn = 3600; // 1 hour
    await this.tokenBlacklistService.addUserToken(
      savedUser.id,
      accessToken,
      expiresIn,
    );

    return {
      accessToken,
      tokenType: 'Bearer',
      expiresIn,
      user: {
        id: savedUser.id,
        email: savedUser.email,
        firstName: savedUser.firstName,
        lastName: savedUser.lastName,
        role: savedUser.role,
        isEmailVerified: savedUser.isEmailVerified,
      },
    };
  }

  async login(loginDto: LoginDto): Promise<AuthResponseDto> {
    const { email, password } = loginDto;

    // Find user by email
    const user = await this.userRepository.findOne({
      where: { email },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Account has been deactivated');
    }

    // Verify password
    if (!user.passwordHash) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid email or password');
    }

    // Update last login
    user.lastLoginAt = new Date();
    await this.userRepository.save(user);

    // Generate JWT token
    const payload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };
    const accessToken = this.jwtService.sign(payload);

    // Add token to user's active tokens
    const expiresIn = 3600; // 1 hour
    await this.tokenBlacklistService.addUserToken(
      user.id,
      accessToken,
      expiresIn,
    );

    return {
      accessToken,
      tokenType: 'Bearer',
      expiresIn,
      user: {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role,
        isEmailVerified: user.isEmailVerified,
      },
    };
  }

  async validateUser(userId: string): Promise<User | null>;
  async validateUser(email: string, password: string): Promise<User | null>;
  async validateUser(
    emailOrId: string,
    password?: string,
  ): Promise<User | null> {
    if (password) {
      // Email/password validation for LocalStrategy
      const user = await this.userRepository.findOne({
        where: { email: emailOrId, isActive: true },
      });

      if (!user || !user.passwordHash) {
        return null;
      }

      const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
      return isPasswordValid ? user : null;
    } else {
      // User ID validation for JWT
      const user = await this.userRepository.findOne({
        where: { id: emailOrId, isActive: true },
      });

      return user || null;
    }
  }

  async changePassword(
    userId: string,
    changePasswordDto: ChangePasswordDto,
  ): Promise<{ message: string }> {
    const { currentPassword, newPassword } = changePasswordDto;

    const user = await this.userRepository.findOne({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (!user.passwordHash) {
      throw new BadRequestException('User has no password set');
    }

    // Verify current password
    const isCurrentPasswordValid = await bcrypt.compare(
      currentPassword,
      user.passwordHash,
    );

    if (!isCurrentPasswordValid) {
      throw new BadRequestException('Current password is incorrect');
    }

    // Hash new password
    const hashedNewPassword = await bcrypt.hash(newPassword, this.saltRounds);

    // Update password
    user.passwordHash = hashedNewPassword;
    await this.userRepository.save(user);

    // Invalidate all existing tokens after password change
    await this.tokenBlacklistService.blacklistAllUserTokens(userId);

    return { message: 'Password changed successfully. Please login again.' };
  }

  async forgotPassword(email: string): Promise<{ message: string }> {
    const user = await this.userRepository.findOne({
      where: { email },
    });

    if (!user) {
      // Don't reveal if email exists for security
      return { message: 'If the email exists, a reset link has been sent' };
    }

    // Generate reset token (in production, implement proper token generation)
    const resetToken =
      Math.random().toString(36).substring(2, 15) +
      Math.random().toString(36).substring(2, 15);

    // Store reset token and expiry (you might want to create a separate table for this)
    user.passwordResetToken = resetToken;
    user.passwordResetExpires = new Date(Date.now() + 3600000); // 1 hour
    await this.userRepository.save(user);

    // Send email with reset link
    try {
      await this.emailService.sendPasswordResetEmail(email, resetToken);
    } catch (error) {
      console.error(`Failed to send password reset email to ${email}:`, error);
      // Don't throw error to prevent revealing if email exists
    }

    return { message: 'If the email exists, a reset link has been sent' };
  }

  async resetPassword(
    token: string,
    newPassword: string,
  ): Promise<{ message: string }> {
    const user = await this.userRepository.findOne({
      where: {
        passwordResetToken: token,
      },
    });

    if (
      !user ||
      !user.passwordResetExpires ||
      user.passwordResetExpires < new Date()
    ) {
      throw new BadRequestException('Invalid or expired reset token');
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, this.saltRounds);

    // Update user
    user.passwordHash = hashedPassword;
    user.passwordResetToken = undefined;
    user.passwordResetExpires = undefined;
    await this.userRepository.save(user);

    return { message: 'Password reset successfully' };
  }

  async verifyEmail(userId: string): Promise<{ message: string }> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    user.isEmailVerified = true;
    await this.userRepository.save(user);

    return { message: 'Email verified successfully' };
  }

  // Firebase integration for migration
  async validateFirebaseToken(firebaseToken: string): Promise<User | null> {
    try {
      const admin = await import('firebase-admin');

      // Verify Firebase token
      const decodedToken = await admin.auth().verifyIdToken(firebaseToken);
      const { uid, email, name, phone_number, email_verified } = decodedToken;

      if (!email) {
        throw new UnauthorizedException(
          'Email is required from Firebase token',
        );
      }

      // Find existing user by Firebase UID or email
      let user = await this.userRepository.findOne({
        where: [{ firebaseUid: uid }, { email: email }],
      });

      if (!user) {
        // Create new user from Firebase data during migration
        const displayName = (name as string) || email.split('@')[0];
        const [firstName, ...lastNameParts] = displayName.split(' ');

        user = this.userRepository.create({
          firebaseUid: uid,
          email,
          firstName: firstName || 'User',
          lastName: lastNameParts.join(' ') || '',
          phoneNumber: phone_number as string,
          emailVerified: email_verified || false,
          role: UserRole.CUSTOMER,
          isActive: true,
          // No password hash - Firebase handles authentication during migration
        });

        user = await this.userRepository.save(user);
        console.log(`✅ Created new user from Firebase: ${email}`);
      } else {
        // Update existing user with Firebase UID if not set
        if (!user.firebaseUid) {
          user.firebaseUid = uid;
          await this.userRepository.save(user);
          console.log(`✅ Linked existing user to Firebase: ${email}`);
        }

        // Update last login
        await this.userRepository.update(user.id, {
          lastLoginAt: new Date(),
        });
      }

      return user;
    } catch (error) {
      console.error(
        'Firebase token validation error:',
        (error as Error).message,
      );
      throw new UnauthorizedException('Invalid Firebase token');
    }
  }

  async loginWithFirebase(firebaseToken: string): Promise<AuthResponseDto> {
    const user = await this.validateFirebaseToken(firebaseToken);

    if (!user) {
      throw new UnauthorizedException('Failed to authenticate with Firebase');
    }

    // Generate JWT access token for our backend
    const payload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };
    const accessToken = this.jwtService.sign(payload);

    return {
      accessToken,
      tokenType: 'Bearer',
      expiresIn: 3600, // 1 hour
      user: {
        id: user.id,
        email: user.email,
        firstName: user.firstName || 'User',
        lastName: user.lastName || '',
        role: user.role,
        isEmailVerified: user.emailVerified || false,
      },
    };
  }

  private generateTokens(user: User): {
    accessToken: string;
    refreshToken: string;
  } {
    const payload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };

    // Generate access token
    const accessToken = this.jwtService.sign(payload);

    // Generate refresh token with longer expiration
    const refreshToken = this.jwtService.sign(
      { ...payload, type: 'refresh' },
      {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
        expiresIn: '7d',
      },
    );

    return { accessToken, refreshToken };
  }

  async getProfile(userId: string): Promise<Partial<User>> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return this.sanitizeUser(user);
  }

  async refreshToken(refreshToken: string): Promise<AuthResponseDto> {
    try {
      const payload = await this.jwtService.verifyAsync<RefreshPayload>(
        refreshToken,
        {
          secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
        },
      );

      if (!payload.type || payload.type !== 'refresh') {
        throw new UnauthorizedException('Invalid refresh token');
      }

      const user = await this.userRepository.findOne({
        where: { id: payload.sub },
      });

      if (!user) {
        throw new UnauthorizedException('User not found');
      }

      const tokens = this.generateTokens(user);

      return {
        accessToken: tokens.accessToken,
        tokenType: 'Bearer',
        expiresIn: 3600, // 1 hour
        user: {
          id: user.id,
          email: user.email,
          firstName: user.firstName || '',
          lastName: user.lastName || '',
          role: user.role,
          isEmailVerified: user.emailVerified || false,
        },
      };
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  /**
   * Logout user by blacklisting their current token
   */
  async logout(userId: string, token: string): Promise<{ message: string }> {
    try {
      // Decode token to get expiration
      interface DecodedToken {
        exp?: number;
        [key: string]: any;
      }
      const decoded = this.jwtService.decode(token) as DecodedToken | null;
      const expiresIn = decoded?.exp
        ? decoded.exp - Math.floor(Date.now() / 1000)
        : 3600;

      // Blacklist the token
      await this.tokenBlacklistService.blacklistToken(
        token,
        userId,
        Math.max(expiresIn, 0),
      );

      return { message: 'Logged out successfully' };
    } catch {
      throw new BadRequestException('Invalid token');
    }
  }

  /**
   * Logout user from all devices by blacklisting all their tokens
   */
  async logoutAll(userId: string): Promise<{ message: string }> {
    await this.tokenBlacklistService.blacklistAllUserTokens(userId);
    return { message: 'Logged out from all devices successfully' };
  }

  private sanitizeUser(user: User): Partial<User> {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { passwordHash, ...sanitizedUser } = user;
    return sanitizedUser;
  }
}
