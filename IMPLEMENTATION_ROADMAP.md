# 🛠️ Implementation Roadmap: Code Examples & Project Structure

## 📁 Project Structure Overview

### Backend Project Structure (NestJS)
```
wayz-backend/
├── src/
│   ├── app.module.ts
│   ├── main.ts
│   ├── auth/
│   │   ├── auth.module.ts
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   ├── dto/
│   │   │   ├── login.dto.ts
│   │   │   └── register.dto.ts
│   │   ├── guards/
│   │   │   ├── jwt-auth.guard.ts
│   │   │   └── firebase-auth.guard.ts
│   │   └── strategies/
│   │       ├── jwt.strategy.ts
│   │       └── firebase.strategy.ts
│   ├── users/
│   │   ├── users.module.ts
│   │   ├── users.controller.ts
│   │   ├── users.service.ts
│   │   ├── entities/
│   │   │   └── user.entity.ts
│   │   └── dto/
│   │       ├── create-user.dto.ts
│   │       └── update-user.dto.ts
│   ├── vehicles/
│   │   ├── vehicles.module.ts
│   │   ├── vehicles.controller.ts
│   │   ├── vehicles.service.ts
│   │   ├── entities/
│   │   │   └── vehicle.entity.ts
│   │   └── dto/
│   ├── bookings/
│   ├── favorites/
│   ├── reviews/
│   ├── notifications/
│   ├── common/
│   │   ├── decorators/
│   │   ├── filters/
│   │   ├── guards/
│   │   ├── interceptors/
│   │   └── pipes/
│   ├── config/
│   │   ├── database.config.ts
│   │   ├── jwt.config.ts
│   │   ├── redis.config.ts
│   │   └── firebase.config.ts
│   └── migrations/
│       ├── firebase-to-postgres/
│       └── data-validation/
├── test/
├── package.json
├── docker-compose.yml
├── .env.example
└── README.md
```

### Flutter App Structure Updates
```
lib/
├── main.dart
├── services/
│   ├── api_service.dart          # New: REST API calls
│   ├── auth_service.dart         # Updated: Hybrid auth
│   ├── migration_service.dart    # New: Migration logic
│   ├── websocket_service.dart    # New: Real-time features
│   ├── favorites_service.dart    # Updated: API integration
│   └── legacy/
│       ├── firebase_auth_service.dart
│       └── firestore_service.dart
├── models/
│   ├── api_models/              # New: API response models
│   └── firebase_models/         # Existing: Firebase models
├── config/
│   ├── api_config.dart          # New: API endpoints
│   └── migration_config.dart    # New: Feature flags
└── utils/
    ├── api_client.dart          # New: HTTP client
    └── migration_helper.dart    # New: Migration utilities
```

---

## 🔧 Phase 1: Backend Setup Implementation

### 1. Initial NestJS Setup

**package.json**
```json
{
  "name": "wayz-backend",
  "version": "1.0.0",
  "scripts": {
    "start": "nest start",
    "start:dev": "nest start --watch",
    "start:prod": "node dist/main",
    "build": "nest build",
    "migration:generate": "typeorm migration:generate",
    "migration:run": "typeorm migration:run"
  },
  "dependencies": {
    "@nestjs/common": "^10.0.0",
    "@nestjs/core": "^10.0.0",
    "@nestjs/platform-express": "^10.0.0",
    "@nestjs/typeorm": "^10.0.0",
    "@nestjs/config": "^3.0.0",
    "@nestjs/jwt": "^10.0.0",
    "@nestjs/passport": "^10.0.0",
    "@nestjs/websockets": "^10.0.0",
    "@nestjs/platform-socket.io": "^10.0.0",
    "typeorm": "^0.3.17",
    "pg": "^8.11.0",
    "redis": "^4.6.0",
    "ioredis": "^5.3.0",
    "passport": "^0.6.0",
    "passport-jwt": "^4.0.1",
    "passport-local": "^1.0.0",
    "bcrypt": "^5.1.0",
    "class-validator": "^0.14.0",
    "class-transformer": "^0.5.1",
    "firebase-admin": "^11.10.0",
    "socket.io": "^4.7.0"
  }
}
```

### 2. Environment Configuration

**.env.example**
```env
# Database
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=wayz_user
DATABASE_PASSWORD=wayz_password
DATABASE_NAME=wayz_db

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRATION=3600

# Firebase
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n..."
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-...@your-project.iam.gserviceaccount.com

# App
APP_PORT=3000
APP_ENV=development
API_PREFIX=api/v1

# External Services
CLOUDINARY_CLOUD_NAME=your-cloudinary-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
```

### 3. Database Configuration

**src/config/database.config.ts**
```typescript
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';

export const getDatabaseConfig = (configService: ConfigService): TypeOrmModuleOptions => ({
  type: 'postgres',
  host: configService.get('DATABASE_HOST'),
  port: +configService.get('DATABASE_PORT'),
  username: configService.get('DATABASE_USERNAME'),
  password: configService.get('DATABASE_PASSWORD'),
  database: configService.get('DATABASE_NAME'),
  entities: [__dirname + '/../**/*.entity{.ts,.js}'],
  migrations: [__dirname + '/../migrations/*{.ts,.js}'],
  synchronize: configService.get('APP_ENV') === 'development',
  logging: configService.get('APP_ENV') === 'development',
  ssl: configService.get('APP_ENV') === 'production' ? { rejectUnauthorized: false } : false,
});
```

### 4. Main Application Module

**src/app.module.ts**
```typescript
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { getDatabaseConfig } from './config/database.config';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { VehiclesModule } from './vehicles/vehicles.module';
import { BookingsModule } from './bookings/bookings.module';
import { FavoritesModule } from './favorites/favorites.module';
import { NotificationsModule } from './notifications/notifications.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: getDatabaseConfig,
      inject: [ConfigService],
    }),
    AuthModule,
    UsersModule,
    VehiclesModule,
    BookingsModule,
    FavoritesModule,
    NotificationsModule,
  ],
})
export class AppModule {}
```

---

## 🔐 Phase 2: Authentication Implementation

### 1. User Entity

**src/users/entities/user.entity.ts**
```typescript
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany } from 'typeorm';
import { Exclude } from 'class-transformer';
import { Vehicle } from '../../vehicles/entities/vehicle.entity';
import { Booking } from '../../bookings/entities/booking.entity';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'firebase_uid', nullable: true, unique: true })
  firebaseUid?: string;

  @Column({ unique: true })
  email: string;

  @Column({ name: 'email_verified', default: false })
  emailVerified: boolean;

  @Column({ name: 'password_hash', nullable: true })
  @Exclude()
  passwordHash?: string;

  @Column({ name: 'first_name', length: 100 })
  firstName: string;

  @Column({ name: 'last_name', length: 100 })
  lastName: string;

  @Column({ nullable: true, length: 20 })
  phone?: string;

  @Column({ name: 'profile_image_url', nullable: true })
  profileImageUrl?: string;

  @Column({ name: 'date_of_birth', nullable: true, type: 'date' })
  dateOfBirth?: Date;

  @Column({ nullable: true })
  address?: string;

  @Column({ name: 'driver_license', nullable: true })
  driverLicense?: string;

  @Column({ default: true })
  active: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // Relations
  @OneToMany(() => Vehicle, vehicle => vehicle.owner)
  vehicles: Vehicle[];

  @OneToMany(() => Booking, booking => booking.user)
  bookings: Booking[];

  // Virtual fields
  get fullName(): string {
    return `${this.firstName} ${this.lastName}`;
  }
}
```

### 2. Auth Service with Dual Support

**src/auth/auth.service.ts**
```typescript
import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import * as bcrypt from 'bcrypt';
import * as admin from 'firebase-admin';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) {}

  async register(registerDto: RegisterDto) {
    // Check if user already exists
    const existingUser = await this.usersService.findByEmail(registerDto.email);
    if (existingUser) {
      throw new ConflictException('User already exists');
    }

    // Hash password
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(registerDto.password, saltRounds);

    // Create user in PostgreSQL
    const user = await this.usersService.create({
      ...registerDto,
      passwordHash,
    });

    // During migration period, also create in Firebase
    try {
      const firebaseUser = await admin.auth().createUser({
        uid: user.id,
        email: user.email,
        displayName: user.fullName,
        emailVerified: false,
      });

      // Update user with Firebase UID
      await this.usersService.update(user.id, {
        firebaseUid: firebaseUser.uid,
      });
    } catch (error) {
      console.warn('Firebase user creation failed:', error);
      // Continue with PostgreSQL-only user during migration
    }

    // Generate JWT token
    const payload = { sub: user.id, email: user.email };
    const accessToken = this.jwtService.sign(payload);

    return {
      user: user,
      accessToken,
      tokenType: 'Bearer',
    };
  }

  async login(loginDto: LoginDto) {
    // Validate user credentials
    const user = await this.validateUser(loginDto.email, loginDto.password);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Generate JWT token
    const payload = { sub: user.id, email: user.email };
    const accessToken = this.jwtService.sign(payload);

    return {
      user,
      accessToken,
      tokenType: 'Bearer',
    };
  }

  async validateUser(email: string, password: string) {
    const user = await this.usersService.findByEmail(email);
    if (!user || !user.passwordHash) {
      return null;
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      return null;
    }

    return user;
  }

  async validateFirebaseToken(token: string) {
    try {
      const decodedToken = await admin.auth().verifyIdToken(token);
      const user = await this.usersService.findByFirebaseUid(decodedToken.uid);
      return user;
    } catch (error) {
      return null;
    }
  }

  async findUserById(id: string) {
    return this.usersService.findById(id);
  }
}
```

### 3. JWT Strategy

**src/auth/strategies/jwt.strategy.ts**
```typescript
import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { AuthService } from '../auth.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private readonly configService: ConfigService,
    private readonly authService: AuthService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get('JWT_SECRET'),
    });
  }

  async validate(payload: any) {
    const user = await this.authService.findUserById(payload.sub);
    return user;
  }
}
```

---

## 🚗 Phase 3: Vehicles & Bookings Implementation

### 1. Vehicle Entity

**src/vehicles/entities/vehicle.entity.ts**
```typescript
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToMany, CreateDateColumn, UpdateDateColumn, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Booking } from '../../bookings/entities/booking.entity';

@Entity('vehicles')
export class Vehicle {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'owner_id' })
  ownerId: string;

  @Column()
  title: string;

  @Column('text', { nullable: true })
  description?: string;

  @Column({ length: 100 })
  brand: string;

  @Column({ length: 100 })
  model: string;

  @Column()
  year: number;

  @Column({ name: 'license_plate', length: 20 })
  licensePlate: string;

  @Column({ length: 50, nullable: true })
  color?: string;

  @Column({ length: 20 })
  transmission: string;

  @Column({ name: 'fuel_type', length: 20 })
  fuelType: string;

  @Column()
  seats: number;

  @Column({ name: 'price_per_day', type: 'decimal', precision: 10, scale: 2 })
  pricePerDay: number;

  @Column({ name: 'location_lat', type: 'decimal', precision: 10, scale: 8, nullable: true })
  locationLat?: number;

  @Column({ name: 'location_lng', type: 'decimal', precision: 11, scale: 8, nullable: true })
  locationLng?: number;

  @Column({ name: 'location_address', nullable: true })
  locationAddress?: string;

  @Column('jsonb', { nullable: true })
  images?: string[];

  @Column('jsonb', { nullable: true })
  features?: Record<string, any>;

  @Column({ default: 'active' })
  status: 'active' | 'inactive' | 'maintenance';

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // Relations
  @ManyToOne(() => User, user => user.vehicles)
  @JoinColumn({ name: 'owner_id' })
  owner: User;

  @OneToMany(() => Booking, booking => booking.vehicle)
  bookings: Booking[];
}
```

### 2. Vehicle Service

**src/vehicles/vehicles.service.ts**
```typescript
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Vehicle } from './entities/vehicle.entity';
import { CreateVehicleDto } from './dto/create-vehicle.dto';
import { UpdateVehicleDto } from './dto/update-vehicle.dto';
import { SearchVehiclesDto } from './dto/search-vehicles.dto';

@Injectable()
export class VehiclesService {
  constructor(
    @InjectRepository(Vehicle)
    private readonly vehicleRepository: Repository<Vehicle>,
  ) {}

  async create(createVehicleDto: CreateVehicleDto, ownerId: string) {
    const vehicle = this.vehicleRepository.create({
      ...createVehicleDto,
      ownerId,
    });
    return this.vehicleRepository.save(vehicle);
  }

  async findAll(searchDto: SearchVehiclesDto) {
    const queryBuilder = this.vehicleRepository
      .createQueryBuilder('vehicle')
      .leftJoinAndSelect('vehicle.owner', 'owner')
      .where('vehicle.status = :status', { status: 'active' });

    // Location-based search
    if (searchDto.lat && searchDto.lng && searchDto.radius) {
      queryBuilder.andWhere(
        `ST_DWithin(
          ST_SetSRID(ST_MakePoint(vehicle.location_lng, vehicle.location_lat), 4326),
          ST_SetSRID(ST_MakePoint(:lng, :lat), 4326),
          :radius
        )`,
        { lat: searchDto.lat, lng: searchDto.lng, radius: searchDto.radius }
      );
    }

    // Date availability check
    if (searchDto.startDate && searchDto.endDate) {
      queryBuilder.andWhere(
        `vehicle.id NOT IN (
          SELECT booking.vehicle_id FROM bookings booking
          WHERE booking.status IN ('confirmed', 'active')
          AND (
            (booking.start_date <= :startDate AND booking.end_date >= :startDate)
            OR (booking.start_date <= :endDate AND booking.end_date >= :endDate)
            OR (booking.start_date >= :startDate AND booking.end_date <= :endDate)
          )
        )`,
        { startDate: searchDto.startDate, endDate: searchDto.endDate }
      );
    }

    // Price range filter
    if (searchDto.minPrice !== undefined) {
      queryBuilder.andWhere('vehicle.price_per_day >= :minPrice', { minPrice: searchDto.minPrice });
    }
    if (searchDto.maxPrice !== undefined) {
      queryBuilder.andWhere('vehicle.price_per_day <= :maxPrice', { maxPrice: searchDto.maxPrice });
    }

    // Vehicle type filters
    if (searchDto.brand) {
      queryBuilder.andWhere('LOWER(vehicle.brand) = LOWER(:brand)', { brand: searchDto.brand });
    }
    if (searchDto.fuelType) {
      queryBuilder.andWhere('vehicle.fuel_type = :fuelType', { fuelType: searchDto.fuelType });
    }
    if (searchDto.transmission) {
      queryBuilder.andWhere('vehicle.transmission = :transmission', { transmission: searchDto.transmission });
    }
    if (searchDto.minSeats) {
      queryBuilder.andWhere('vehicle.seats >= :minSeats', { minSeats: searchDto.minSeats });
    }

    // Pagination
    const page = searchDto.page || 1;
    const limit = searchDto.limit || 10;
    queryBuilder.skip((page - 1) * limit).take(limit);

    // Sorting
    const sortBy = searchDto.sortBy || 'created_at';
    const sortOrder = searchDto.sortOrder || 'DESC';
    queryBuilder.orderBy(`vehicle.${sortBy}`, sortOrder);

    const [vehicles, total] = await queryBuilder.getManyAndCount();

    return {
      vehicles,
      total,
      page,
      limit,
      pages: Math.ceil(total / limit),
    };
  }

  async findOne(id: string) {
    const vehicle = await this.vehicleRepository.findOne({
      where: { id },
      relations: ['owner'],
    });

    if (!vehicle) {
      throw new NotFoundException('Vehicle not found');
    }

    return vehicle;
  }

  async update(id: string, updateVehicleDto: UpdateVehicleDto, userId: string) {
    const vehicle = await this.findOne(id);
    
    // Check if user owns the vehicle
    if (vehicle.ownerId !== userId) {
      throw new NotFoundException('Vehicle not found');
    }

    await this.vehicleRepository.update(id, updateVehicleDto);
    return this.findOne(id);
  }

  async remove(id: string, userId: string) {
    const vehicle = await this.findOne(id);
    
    // Check if user owns the vehicle
    if (vehicle.ownerId !== userId) {
      throw new NotFoundException('Vehicle not found');
    }

    await this.vehicleRepository.update(id, { status: 'inactive' });
    return { message: 'Vehicle deleted successfully' };
  }

  async findByOwner(ownerId: string) {
    return this.vehicleRepository.find({
      where: { ownerId },
      relations: ['bookings'],
      order: { createdAt: 'DESC' },
    });
  }
}
```

---

## 📱 Phase 4: Flutter Integration

### 1. API Service

**lib/services/api_service.dart**
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_models/user_model.dart';
import '../models/api_models/vehicle_model.dart';
import '../models/api_models/auth_response_model.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;
  static String? _accessToken;

  // Set authentication token
  static void setToken(String token) {
    _accessToken = token;
  }

  // Get headers with authentication
  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    
    return headers;
  }

  // Authentication
  static Future<AuthResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(json.decode(response.body));
      setToken(authResponse.accessToken);
      return authResponse;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  static Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: json.encode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
      }),
    );

    if (response.statusCode == 201) {
      final authResponse = AuthResponse.fromJson(json.decode(response.body));
      setToken(authResponse.accessToken);
      return authResponse;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  // User Management
  static Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get user profile');
    }
  }

  static Future<User> updateProfile(Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/profile'),
      headers: _headers,
      body: json.encode(userData),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update profile');
    }
  }

  // Vehicle Management
  static Future<List<Vehicle>> searchVehicles({
    double? lat,
    double? lng,
    double? radius,
    DateTime? startDate,
    DateTime? endDate,
    double? minPrice,
    double? maxPrice,
    String? brand,
    String? fuelType,
    int? page = 1,
    int? limit = 10,
  }) async {
    final queryParams = <String, String>{};
    
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lng != null) queryParams['lng'] = lng.toString();
    if (radius != null) queryParams['radius'] = radius.toString();
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
    if (brand != null) queryParams['brand'] = brand;
    if (fuelType != null) queryParams['fuelType'] = fuelType;
    queryParams['page'] = page.toString();
    queryParams['limit'] = limit.toString();

    final uri = Uri.parse('$baseUrl/vehicles').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['vehicles'] as List)
          .map((vehicleJson) => Vehicle.fromJson(vehicleJson))
          .toList();
    } else {
      throw Exception('Failed to search vehicles');
    }
  }

  static Future<Vehicle> getVehicle(String vehicleId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/vehicles/$vehicleId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Vehicle.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get vehicle details');
    }
  }

  // Bookings
  static Future<Booking> createBooking({
    required String vehicleId,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: _headers,
      body: json.encode({
        'vehicleId': vehicleId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'notes': notes,
      }),
    );

    if (response.statusCode == 201) {
      return Booking.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create booking');
    }
  }

  static Future<List<Booking>> getUserBookings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/user'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return (json.decode(response.body) as List)
          .map((bookingJson) => Booking.fromJson(bookingJson))
          .toList();
    } else {
      throw Exception('Failed to get user bookings');
    }
  }

  // Favorites
  static Future<void> addToFavorites(String vehicleId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/favorites'),
      headers: _headers,
      body: json.encode({'vehicleId': vehicleId}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add to favorites');
    }
  }

  static Future<void> removeFromFavorites(String vehicleId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/favorites/$vehicleId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove from favorites');
    }
  }

  static Future<List<Vehicle>> getFavorites() async {
    final response = await http.get(
      Uri.parse('$baseUrl/favorites'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return (json.decode(response.body) as List)
          .map((vehicleJson) => Vehicle.fromJson(vehicleJson))
          .toList();
    } else {
      throw Exception('Failed to get favorites');
    }
  }
}
```

### 2. Migration Service

**lib/services/migration_service.dart**
```dart
import 'package:flutter/foundation.dart';
import '../config/migration_config.dart';
import 'api_service.dart';
import 'legacy/firebase_auth_service.dart';

class MigrationService {
  static bool _isNewBackendAvailable = false;
  static bool _useLegacyFallback = true;

  static bool get isNewBackendAvailable => _isNewBackendAvailable;
  static bool get useLegacyFallback => _useLegacyFallback;

  // Initialize migration service
  static Future<void> initialize() async {
    await _checkBackendAvailability();
    _configureMigrationSettings();
  }

  // Check if new backend is available and responsive
  static Future<void> _checkBackendAvailability() async {
    try {
      // Try to reach the health endpoint
      final response = await http.get(
        Uri.parse('${MigrationConfig.backendUrl}/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      _isNewBackendAvailable = response.statusCode == 200;
      
      if (kDebugMode) {
        print('Backend availability check: $_isNewBackendAvailable');
      }
    } catch (e) {
      _isNewBackendAvailable = false;
      if (kDebugMode) {
        print('Backend availability check failed: $e');
      }
    }
  }

  // Configure migration settings based on feature flags
  static void _configureMigrationSettings() {
    // Check feature flags from remote config or local config
    _useLegacyFallback = MigrationConfig.enableLegacyFallback;
    
    if (kDebugMode) {
      print('Migration settings:');
      print('  - New backend available: $_isNewBackendAvailable');
      print('  - Legacy fallback enabled: $_useLegacyFallback');
    }
  }

  // Execute operation with fallback logic
  static Future<T> executeWithFallback<T>({
    required Future<T> Function() newBackendOperation,
    required Future<T> Function() legacyOperation,
    String? operationName,
  }) async {
    // If new backend is not available, use legacy
    if (!_isNewBackendAvailable) {
      if (kDebugMode && operationName != null) {
        print('Using legacy for $operationName (backend unavailable)');
      }
      return await legacyOperation();
    }

    // Try new backend first
    try {
      final result = await newBackendOperation().timeout(
        const Duration(seconds: 10),
      );
      
      if (kDebugMode && operationName != null) {
        print('Successfully used new backend for $operationName');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode && operationName != null) {
        print('New backend failed for $operationName: $e');
      }

      // Fallback to legacy if enabled
      if (_useLegacyFallback) {
        if (kDebugMode && operationName != null) {
          print('Falling back to legacy for $operationName');
        }
        return await legacyOperation();
      } else {
        // Re-throw the error if fallback is disabled
        rethrow;
      }
    }
  }

  // Gradually migrate user sessions
  static Future<void> migrateUserSession() async {
    try {
      // Check if user has active Firebase session
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;

      // Try to get corresponding user from new backend
      final token = await firebaseUser.getIdToken();
      
      // Call backend endpoint to verify/migrate user
      final response = await http.post(
        Uri.parse('${MigrationConfig.backendUrl}/auth/migrate-firebase'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ApiService.setToken(data['accessToken']);
        
        if (kDebugMode) {
          print('User session migrated successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('User session migration failed: $e');
      }
    }
  }

  // Update migration status based on backend health
  static Future<void> updateBackendStatus() async {
    await _checkBackendAvailability();
  }

  // Force refresh migration settings
  static Future<void> refreshMigrationSettings() async {
    await initialize();
  }
}
```

### 3. Hybrid Auth Service

**lib/services/auth_service.dart**
```dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/api_models/user_model.dart';
import '../models/api_models/auth_response_model.dart';
import 'api_service.dart';
import 'migration_service.dart';
import 'legacy/firebase_auth_service.dart';

class AuthService {
  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user_data';

  static User? _currentUser;
  static String? _accessToken;

  static User? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;
  static String? get accessToken => _accessToken;

  // Initialize auth service
  static Future<void> initialize() async {
    await MigrationService.initialize();
    await _loadStoredSession();
    
    // Try to migrate existing Firebase session
    if (firebase_auth.FirebaseAuth.instance.currentUser != null && _currentUser == null) {
      await MigrationService.migrateUserSession();
    }
  }

  // Login with email and password
  static Future<AuthResponse> login(String email, String password) async {
    return await MigrationService.executeWithFallback(
      newBackendOperation: () async {
        final authResponse = await ApiService.login(email, password);
        await _storeSession(authResponse);
        return authResponse;
      },
      legacyOperation: () async {
        final firebaseUser = await FirebaseAuthService.signInWithEmail(email, password);
        final authResponse = AuthResponse(
          user: User.fromFirebaseUser(firebaseUser),
          accessToken: await firebaseUser.getIdToken(),
          tokenType: 'Bearer',
        );
        await _storeSession(authResponse);
        return authResponse;
      },
      operationName: 'login',
    );
  }

  // Register new user
  static Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    return await MigrationService.executeWithFallback(
      newBackendOperation: () async {
        final authResponse = await ApiService.register(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
        );
        await _storeSession(authResponse);
        return authResponse;
      },
      legacyOperation: () async {
        final firebaseUser = await FirebaseAuthService.createUserWithEmail(
          email, 
          password,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
        );
        final authResponse = AuthResponse(
          user: User.fromFirebaseUser(firebaseUser),
          accessToken: await firebaseUser.getIdToken(),
          tokenType: 'Bearer',
        );
        await _storeSession(authResponse);
        return authResponse;
      },
      operationName: 'register',
    );
  }

  // Get current user profile
  static Future<User> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser!;
    }

    return await MigrationService.executeWithFallback(
      newBackendOperation: () async {
        final user = await ApiService.getCurrentUser();
        _currentUser = user;
        await _storeUserData(user);
        return user;
      },
      legacyOperation: () async {
        final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
        if (firebaseUser == null) {
          throw Exception('No user logged in');
        }
        final user = User.fromFirebaseUser(firebaseUser);
        _currentUser = user;
        await _storeUserData(user);
        return user;
      },
      operationName: 'getCurrentUser',
    );
  }

  // Update user profile
  static Future<User> updateProfile(Map<String, dynamic> userData) async {
    return await MigrationService.executeWithFallback(
      newBackendOperation: () async {
        final user = await ApiService.updateProfile(userData);
        _currentUser = user;
        await _storeUserData(user);
        return user;
      },
      legacyOperation: () async {
        final updatedUser = await FirebaseAuthService.updateProfile(userData);
        _currentUser = User.fromFirebaseUser(updatedUser);
        await _storeUserData(_currentUser!);
        return _currentUser!;
      },
      operationName: 'updateProfile',
    );
  }

  // Logout
  static Future<void> logout() async {
    await MigrationService.executeWithFallback(
      newBackendOperation: () async {
        // Clear local session
        await _clearSession();
        
        // If we also have Firebase session, sign out from there too
        if (firebase_auth.FirebaseAuth.instance.currentUser != null) {
          await firebase_auth.FirebaseAuth.instance.signOut();
        }
      },
      legacyOperation: () async {
        await firebase_auth.FirebaseAuth.instance.signOut();
        await _clearSession();
      },
      operationName: 'logout',
    );
  }

  // Store authentication session
  static Future<void> _storeSession(AuthResponse authResponse) async {
    _currentUser = authResponse.user;
    _accessToken = authResponse.accessToken;
    
    ApiService.setToken(authResponse.accessToken);
    
    // Store in secure storage
    await SecureStorage.write(_tokenKey, authResponse.accessToken);
    await SecureStorage.write(_userKey, json.encode(authResponse.user.toJson()));
  }

  // Store user data
  static Future<void> _storeUserData(User user) async {
    _currentUser = user;
    await SecureStorage.write(_userKey, json.encode(user.toJson()));
  }

  // Load stored session
  static Future<void> _loadStoredSession() async {
    try {
      final token = await SecureStorage.read(_tokenKey);
      final userData = await SecureStorage.read(_userKey);
      
      if (token != null && userData != null) {
        _accessToken = token;
        _currentUser = User.fromJson(json.decode(userData));
        ApiService.setToken(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load stored session: $e');
      }
    }
  }

  // Clear session
  static Future<void> _clearSession() async {
    _currentUser = null;
    _accessToken = null;
    
    await SecureStorage.delete(_tokenKey);
    await SecureStorage.delete(_userKey);
    
    ApiService.setToken('');
  }
}
```

---

## 🎯 Conclusion

This implementation roadmap provides:

1. **Complete backend setup** with NestJS, PostgreSQL, and Redis
2. **Gradual migration strategy** with dual writing and fallback mechanisms
3. **Flutter integration** with hybrid auth and API services
4. **Database schema** optimized for the vehicle rental business
5. **Real-time features** with WebSockets and notifications
6. **Security best practices** with JWT authentication and data validation

The migration can be executed phase by phase, ensuring zero downtime and minimal risk throughout the process.

---

**Next Steps:**
1. Set up development environment with the provided configurations
2. Begin Phase 1 implementation
3. Test each phase thoroughly before proceeding
4. Monitor system performance and user experience throughout migration
