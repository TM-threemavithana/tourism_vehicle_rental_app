import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Request } from 'express';
import { User } from '../../entities/user.entity';
import { TokenBlacklistService } from '../services/token-blacklist.service';

export interface JwtPayload {
  sub: string;
  email: string;
  role: string;
  iat?: number;
  exp?: number;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly configService: ConfigService,
    private readonly tokenBlacklistService: TokenBlacklistService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET') || 'fallback-secret',
      passReqToCallback: true, // Enable request callback to access token
    });
  }

  async validate(req: Request, payload: JwtPayload): Promise<User> {
    // Extract token from Authorization header
    const token = ExtractJwt.fromAuthHeaderAsBearerToken()(req);

    if (!token) {
      throw new UnauthorizedException('Token not found');
    }

    // Check if token is blacklisted
    const isBlacklisted = await this.tokenBlacklistService.isTokenBlacklisted(
      token,
    );

    if (isBlacklisted) {
      throw new UnauthorizedException('Token has been revoked');
    }

    // Check if token is in user's active tokens
    const isActive = await this.tokenBlacklistService.isUserTokenActive(
      payload.sub,
      token,
    );

    if (!isActive) {
      throw new UnauthorizedException('Token is not active');
    }

    // Find user
    const user = await this.userRepository.findOne({
      where: { id: payload.sub },
    });

    if (!user || !user.isActive) {
      throw new UnauthorizedException('User not found or inactive');
    }

    return user;
  }
}
