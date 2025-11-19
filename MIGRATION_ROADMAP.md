# 🚀 Migration Roadmap: Firebase → Node.js + NestJS + PostgreSQL

## 📋 Migration Overview

This document provides a **step-by-step, gradual migration plan** to transition your Flutter tourism vehicle rental app from Firebase to Node.js with NestJS and PostgreSQL, ensuring **zero downtime** and **minimal risk**.

---

## 🎯 Migration Strategy

### Phase-Based Approach
- **Phase 1**: Setup & Dual Writing (Weeks 1-2)
- **Phase 2**: Backend API Implementation (Weeks 3-5)
- **Phase 3**: Gradual Data Migration (Weeks 6-7)
- **Phase 4**: Flutter App Updates (Weeks 8-9)
- **Phase 5**: Testing & Optimization (Weeks 10-11)
- **Phase 6**: Final Cutover (Week 12)

### Core Principles
1. **Zero Downtime**: App continues working throughout migration
2. **Gradual**: One feature at a time, not everything at once
3. **Rollback Ready**: Can revert at any step
4. **User Transparent**: Users won't notice the migration

---

## 📅 Detailed Migration Timeline

### 🔸 **Phase 1: Infrastructure Setup & Dual Writing (Weeks 1-2)**

#### Week 1: Backend Setup

**Day 1-2: Project Initialization**
```bash
# 1. Create new NestJS project
npx @nestjs/cli new wayz-backend
cd wayz-backend

# 2. Install core dependencies
npm install @nestjs/typeorm typeorm pg
npm install @nestjs/passport @nestjs/jwt passport passport-jwt
npm install @nestjs/config
npm install redis ioredis
npm install class-validator class-transformer

# 3. Install dev dependencies
npm install -D @types/node @types/pg
```

**Day 3: Database Setup**
- Set up PostgreSQL (local + cloud)
- Install Redis (local + cloud)
- Create initial database schema
- Set up connection configurations

**Day 4-5: Basic Project Structure**
- Configure TypeORM
- Set up environment configurations
- Create basic auth module
- Set up JWT configuration

#### Week 2: Dual Writing Implementation

**Day 1-3: Firebase Integration in Backend**
```bash
# Install Firebase Admin SDK
npm install firebase-admin
```
- Set up Firebase Admin in NestJS
- Create services that write to both Firebase AND PostgreSQL
- Implement dual-write pattern for critical data

**Day 4-5: Initial API Endpoints**
- Create user management endpoints
- Create vehicle listing endpoints
- Implement dual-write for user actions
- Set up basic error handling and logging

### 🔸 **Phase 2: Core Backend Implementation (Weeks 3-5)**

#### Week 3: Authentication & User Management

**Day 1-2: Auth System**
- Implement JWT-based authentication
- Create user registration/login endpoints
- Set up password hashing (bcrypt)
- Implement Firebase token verification (for gradual migration)

**Day 3-4: User Services**
- User profile management
- Password reset functionality
- Email verification system
- User preferences handling

**Day 5: Testing & Validation**
- Unit tests for auth services
- Integration tests for user APIs
- Postman collection creation

#### Week 4: Vehicle & Booking Management

**Day 1-2: Vehicle Services**
- Vehicle CRUD operations
- Image upload handling (Cloudinary integration)
- Vehicle search and filtering
- Geospatial queries setup

**Day 3-4: Booking System**
- Booking creation and management
- Availability checking logic
- Payment integration preparation
- Booking status management

**Day 5: Real-time Features**
- WebSocket setup for real-time notifications
- Event-driven booking updates
- Real-time vehicle availability

#### Week 5: Advanced Features

**Day 1-2: Favorites & Reviews**
- Favorites management system
- Review and rating system
- User feedback handling

**Day 3-4: Notifications & Communication**
- Push notification service
- Email notification system
- SMS integration setup

**Day 5: Performance & Caching**
- Redis caching implementation
- Database query optimization
- API response caching

### 🔸 **Phase 3: Data Migration Strategy (Weeks 6-7)**

#### Week 6: Migration Tools & Scripts

**Day 1-2: Migration Scripts**
```javascript
// Example migration script structure
async function migrateUsers() {
  const firebaseUsers = await admin.auth().listUsers();
  
  for (const user of firebaseUsers.users) {
    // Transform Firebase user to PostgreSQL format
    const pgUser = transformUserData(user);
    
    // Insert into PostgreSQL
    await userRepository.save(pgUser);
    
    // Verify data integrity
    await verifyUserMigration(user.uid, pgUser.id);
  }
}
```

**Day 3-4: Data Validation**
- Create data comparison tools
- Implement data integrity checks
- Set up rollback mechanisms

**Day 5: Testing Migration**
- Test migration scripts on sample data
- Verify data consistency
- Performance testing of migration process

#### Week 7: Gradual Data Migration

**Day 1-2: User Data Migration**
- Migrate user accounts (keeping Firebase Auth active)
- Migrate user profiles and preferences
- Update user-related associations

**Day 3-4: Vehicle & Booking Data**
- Migrate vehicle listings
- Migrate booking history
- Migrate reviews and ratings

**Day 5: Validation & Cleanup**
- Complete data validation
- Fix any migration issues
- Prepare for Flutter app updates

### 🔸 **Phase 4: Flutter App Updates (Weeks 8-9)**

#### Week 8: Service Layer Updates

**Day 1-2: HTTP Service Setup**
```dart
// Create new API service
class ApiService {
  static const String baseUrl = 'https://your-backend-url.com';
  
  // Keep Firebase services as backup during migration
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      // Try new backend first
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        body: {'email': email, 'password': password},
      );
      
      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      }
    } catch (e) {
      // Fallback to Firebase if backend fails
      return await _firebaseLogin(email, password);
    }
  }
}
```

**Day 3-4: Feature-by-Feature Updates**
- Update authentication flows
- Update user profile management
- Implement gradual rollout mechanism

**Day 5: Testing & Validation**
- Test new API integrations
- Verify fallback mechanisms work
- Performance testing

#### Week 9: Complete Feature Migration

**Day 1-2: Vehicle Management**
- Update vehicle listing/searching
- Update vehicle detail views
- Update favorite management

**Day 3-4: Booking System**
- Update booking creation flow
- Update booking management
- Update real-time notifications

**Day 5: Final Testing**
- End-to-end testing
- User acceptance testing
- Performance optimization

### 🔸 **Phase 5: Testing & Optimization (Weeks 10-11)**

#### Week 10: Comprehensive Testing

**Day 1-2: Load Testing**
- Stress test the new backend
- Test concurrent user scenarios
- Database performance testing

**Day 3-4: Security Testing**
- Authentication security audit
- API endpoint security testing
- Data encryption verification

**Day 5: Bug Fixes**
- Fix identified issues
- Performance optimizations
- Security improvements

#### Week 11: Pre-Production

**Day 1-2: Staging Environment**
- Set up production-like staging
- Complete end-to-end testing
- Data migration dress rehearsal

**Day 3-4: Monitoring Setup**
- Application monitoring setup
- Database monitoring setup
- Error tracking and alerting

**Day 5: Final Preparations**
- Documentation updates
- Team training on new system
- Rollback plan finalization

### 🔸 **Phase 6: Final Cutover (Week 12)**

#### Week 12: Production Migration

**Day 1: Pre-Migration**
- Final data sync
- System health checks
- Team coordination

**Day 2-3: Gradual Cutover**
- Route 10% of traffic to new backend
- Monitor system performance
- Gradually increase traffic (25%, 50%, 75%)

**Day 4: Complete Migration**
- Route 100% traffic to new backend
- Monitor system stability
- Keep Firebase as read-only backup

**Day 5: Post-Migration**
- System optimization
- Performance tuning
- Documentation completion

---

## 🛠️ Technical Implementation Details

### Database Schema Design

```sql
-- Users table (migrated from Firebase Auth)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid VARCHAR(128) UNIQUE, -- For transition period
  email VARCHAR(255) UNIQUE NOT NULL,
  email_verified BOOLEAN DEFAULT FALSE,
  password_hash VARCHAR(255), -- For new auth system
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  phone VARCHAR(20),
  profile_image_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Vehicles table
CREATE TABLE vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES users(id),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  brand VARCHAR(100),
  model VARCHAR(100),
  year INTEGER,
  license_plate VARCHAR(20),
  color VARCHAR(50),
  transmission VARCHAR(20),
  fuel_type VARCHAR(20),
  seats INTEGER,
  price_per_day DECIMAL(10,2),
  location_lat DECIMAL(10,8),
  location_lng DECIMAL(11,8),
  location_address TEXT,
  images JSONB, -- Store image URLs as JSON
  features JSONB, -- Vehicle features as JSON
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bookings table
CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id UUID REFERENCES vehicles(id),
  user_id UUID REFERENCES users(id),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_price DECIMAL(10,2),
  status VARCHAR(20) DEFAULT 'pending',
  payment_status VARCHAR(20) DEFAULT 'pending',
  payment_intent_id VARCHAR(255), -- Stripe payment intent
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Favorites table
CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  vehicle_id UUID REFERENCES vehicles(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, vehicle_id)
);

-- Reviews table
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID REFERENCES bookings(id),
  reviewer_id UUID REFERENCES users(id),
  reviewed_user_id UUID REFERENCES users(id),
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_vehicles_location ON vehicles USING GIST (ST_Point(location_lng, location_lat));
CREATE INDEX idx_vehicles_status ON vehicles(status);
CREATE INDEX idx_bookings_dates ON bookings(start_date, end_date);
CREATE INDEX idx_bookings_user ON bookings(user_id);
CREATE INDEX idx_bookings_vehicle ON bookings(vehicle_id);
```

### Dual Writing Service Example

```typescript
// dual-write.service.ts
@Injectable()
export class DualWriteService {
  constructor(
    private readonly userRepository: Repository<User>,
    private readonly firebaseAdmin: FirebaseAdmin,
  ) {}

  async createUser(userData: CreateUserDto): Promise<User> {
    // Start transaction
    const queryRunner = this.connection.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // 1. Create in PostgreSQL
      const pgUser = await queryRunner.manager.save(User, {
        email: userData.email,
        firstName: userData.firstName,
        lastName: userData.lastName,
      });

      // 2. Create in Firebase (as backup during migration)
      const firebaseUser = await this.firebaseAdmin.auth().createUser({
        email: userData.email,
        displayName: `${userData.firstName} ${userData.lastName}`,
        uid: pgUser.id, // Use PostgreSQL ID as Firebase UID
      });

      // 3. Update PostgreSQL with Firebase UID
      await queryRunner.manager.update(User, pgUser.id, {
        firebaseUid: firebaseUser.uid,
      });

      await queryRunner.commitTransaction();
      return pgUser;
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }
}
```

### Flutter Migration Service

```dart
// migration_service.dart
class MigrationService {
  static const String backendUrl = 'https://your-backend-url.com';
  static bool useNewBackend = false; // Feature flag

  static Future<void> initializeMigration() async {
    // Check if new backend is available
    try {
      final response = await http.get(Uri.parse('$backendUrl/health'));
      useNewBackend = response.statusCode == 200;
    } catch (e) {
      useNewBackend = false;
    }
  }

  static Future<T> executeWithFallback<T>(
    Future<T> Function() newBackendCall,
    Future<T> Function() firebaseCall,
  ) async {
    if (useNewBackend) {
      try {
        return await newBackendCall();
      } catch (e) {
        // Log error and fallback to Firebase
        print('New backend failed, falling back to Firebase: $e');
        return await firebaseCall();
      }
    } else {
      return await firebaseCall();
    }
  }
}

// Updated service example
class UserService {
  Future<User?> getCurrentUser() async {
    return await MigrationService.executeWithFallback(
      () => ApiService.getCurrentUser(), // New backend
      () => FirebaseAuth.instance.currentUser, // Firebase fallback
    );
  }
}
```

---

## 🔄 Rollback Strategy

### Immediate Rollback Plan
1. **Feature Flag Rollback**: Disable new backend via feature flags
2. **Traffic Routing**: Route all traffic back to Firebase
3. **Data Sync**: Ensure Firebase has latest data
4. **App Update**: Push emergency update if needed

### Data Rollback Considerations
- **Dual Writing Period**: Data exists in both systems
- **Migration Window**: Only data created during migration needs special handling
- **User Impact**: Minimal impact due to gradual migration approach

---

## 📊 Migration Checklist

### Pre-Migration
- [ ] Backend development complete
- [ ] Database schema created and tested
- [ ] Migration scripts tested
- [ ] Staging environment ready
- [ ] Monitoring systems in place
- [ ] Team trained on new system
- [ ] Rollback plan documented

### During Migration
- [ ] Feature flags configured
- [ ] Dual writing implemented
- [ ] Data migration executed
- [ ] Flutter app updated
- [ ] Traffic gradually routed
- [ ] System performance monitored
- [ ] User experience validated

### Post-Migration
- [ ] All traffic on new system
- [ ] Performance optimized
- [ ] Firebase read-only mode
- [ ] Monitoring alerts configured
- [ ] Documentation updated
- [ ] Team debriefing completed

---

## 🎯 Success Metrics

### Technical Metrics
- **Zero Downtime**: App availability = 100%
- **Data Integrity**: All data successfully migrated
- **Performance**: Response times < Firebase baseline
- **Error Rate**: < 0.1% error rate during migration

### Business Metrics
- **User Experience**: No user complaints related to migration
- **Booking Continuity**: All bookings processed normally
- **System Reliability**: 99.9% uptime maintained

---

## 📞 Support & Communication

### Communication Plan
- **Daily Standups**: During migration weeks
- **Progress Updates**: Weekly stakeholder updates
- **Issue Escalation**: 24/7 support during cutover
- **User Communication**: In-app notifications if needed

### Team Responsibilities
- **Backend Team**: API development and deployment
- **Mobile Team**: Flutter app updates
- **DevOps Team**: Infrastructure and monitoring
- **QA Team**: Testing and validation
- **Product Team**: User communication and rollback decisions

---

## 🚨 Risk Mitigation

### High-Risk Areas
1. **Data Loss**: Mitigated by dual writing and validation
2. **Service Downtime**: Mitigated by gradual migration
3. **Performance Issues**: Mitigated by load testing
4. **User Experience**: Mitigated by feature flags and rollback plan

### Contingency Plans
- **Immediate Rollback**: Feature flag disable
- **Partial Rollback**: Route specific features back to Firebase
- **Emergency Response**: 24/7 team availability during cutover
- **Communication Plan**: User notifications and status updates

---

## 📚 Next Steps

1. **Review and Approve**: Stakeholder review of migration plan
2. **Resource Allocation**: Assign team members to migration tasks
3. **Timeline Confirmation**: Confirm migration timeline fits business needs
4. **Environment Setup**: Begin Phase 1 infrastructure setup
5. **Progress Tracking**: Set up project management and tracking tools

---

*This migration plan ensures a smooth, gradual transition with minimal risk and zero downtime. Each phase builds upon the previous one, allowing for course correction and rollback at any point.*
