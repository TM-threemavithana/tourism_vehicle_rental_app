import {
  IsEmail,
  IsString,
  MinLength,
  MaxLength,
  IsOptional,
  IsEnum,
  IsUUID,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export enum UserRole {
  CUSTOMER = 'customer',
  OWNER = 'owner',
  ADMIN = 'admin',
}

export class RegisterDto {
  @ApiProperty({
    description: 'User email address',
    example: 'john.doe@example.com',
  })
  @IsEmail()
  email: string;

  @ApiProperty({
    description: 'User password',
    example: 'SecurePassword123!',
    minLength: 8,
  })
  @IsString()
  @MinLength(8, { message: 'Password must be at least 8 characters long' })
  password: string;

  @ApiProperty({
    description: 'First name',
    example: 'John',
  })
  @IsString()
  @MaxLength(50)
  firstName: string;

  @ApiProperty({
    description: 'Last name',
    example: 'Doe',
  })
  @IsString()
  @MaxLength(50)
  lastName: string;

  @ApiProperty({
    description: 'Phone number',
    example: '+94771234567',
    required: false,
  })
  @IsOptional()
  @IsString()
  phoneNumber?: string;

  @ApiProperty({
    description: 'User role',
    enum: UserRole,
    example: UserRole.CUSTOMER,
    required: false,
  })
  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;
}

export class LoginDto {
  @ApiProperty({
    description: 'User email address',
    example: 'john.doe@example.com',
  })
  @IsEmail()
  email: string;

  @ApiProperty({
    description: 'User password',
    example: 'SecurePassword123!',
  })
  @IsString()
  password: string;
}

export class ChangePasswordDto {
  @ApiProperty({
    description: 'Current password',
    example: 'CurrentPassword123!',
  })
  @IsString()
  currentPassword: string;

  @ApiProperty({
    description: 'New password',
    example: 'NewSecurePassword123!',
    minLength: 8,
  })
  @IsString()
  @MinLength(8, { message: 'Password must be at least 8 characters long' })
  newPassword: string;
}

export class ForgotPasswordDto {
  @ApiProperty({
    description: 'User email address',
    example: 'john.doe@example.com',
  })
  @IsEmail()
  email: string;
}

export class ResetPasswordDto {
  @ApiProperty({
    description: 'Reset token',
    example: 'reset-token-here',
  })
  @IsString()
  token: string;

  @ApiProperty({
    description: 'New password',
    example: 'NewSecurePassword123!',
    minLength: 8,
  })
  @IsString()
  @MinLength(8, { message: 'Password must be at least 8 characters long' })
  newPassword: string;
}

export class ConfirmResetPasswordDto {
  @ApiProperty({
    description: 'Reset token',
    example: 'reset-token-here',
  })
  @IsString()
  token: string;

  @ApiProperty({
    description: 'New password',
    example: 'NewSecurePassword123!',
    minLength: 8,
  })
  @IsString()
  @MinLength(8, { message: 'Password must be at least 8 characters long' })
  newPassword: string;
}

export class FirebaseTokenDto {
  @ApiProperty({
    description: 'Firebase ID token',
    example: 'firebase.jwt.token.here',
  })
  @IsString()
  firebaseToken: string;
}

export class AuthResponseDto {
  @ApiProperty({ description: 'JWT access token' })
  accessToken: string;

  @ApiProperty({ description: 'Token type', example: 'Bearer' })
  tokenType: string;

  @ApiProperty({ description: 'Token expiration in seconds', example: 3600 })
  expiresIn: number;

  @ApiProperty({ description: 'User information' })
  user: {
    id: string;
    email: string;
    firstName?: string;
    lastName?: string;
    role: 'customer' | 'owner' | 'admin';
    isEmailVerified: boolean;
  };
}

export class RefreshTokenDto {
  @ApiProperty({
    description: 'Refresh token',
    example: 'refresh-token-here',
  })
  @IsString()
  refreshToken: string;
}
