import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { CreateUserDto } from '../src/dto/user.dto';
import { RegisterDto, UserRole } from '../src/dto/auth.dto';
import * as path from 'path';
import * as fs from 'fs';

describe('Authentication and Upload Integration Tests', () => {
  let app: INestApplication<App>;
  let authToken: string;
  let ownerToken: string;
  let testUserId: string;

  const testUser: RegisterDto = {
    email: 'testuser@example.com',
    password: 'SecurePassword123!',
    firstName: 'Test',
    lastName: 'User',
    phoneNumber: '+1234567890',
    role: UserRole.CUSTOMER,
  };

  const testOwner: RegisterDto = {
    email: 'testowner@example.com',
    password: 'SecurePassword123!',
    firstName: 'Test',
    lastName: 'Owner',
    phoneNumber: '+1234567891',
    role: UserRole.OWNER,
  };

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Register test users
    const userResponse = await request(app.getHttpServer())
      .post('/auth/register')
      .send(testUser)
      .expect(201);

    authToken = userResponse.body.accessToken;
    testUserId = userResponse.body.user.id;

    const ownerResponse = await request(app.getHttpServer())
      .post('/auth/register')
      .send(testOwner)
      .expect(201);

    ownerToken = ownerResponse.body.accessToken;
  });

  afterAll(async () => {
    await app.close();
  });

  describe('Authentication Flow', () => {
    it('should register a new user', async () => {
      const newUser: RegisterDto = {
        email: 'newuser@example.com',
        password: 'SecurePassword123!',
        firstName: 'New',
        lastName: 'User',
        phoneNumber: '+1234567892',
        role: UserRole.CUSTOMER,
      };

      const response = await request(app.getHttpServer())
        .post('/auth/register')
        .send(newUser)
        .expect(201);

      expect(response.body).toHaveProperty('accessToken');
      expect(response.body).toHaveProperty('refreshToken');
      expect(response.body.user.email).toBe(newUser.email);
      expect(response.body.user.role).toBe(newUser.role);
    });

    it('should login with valid credentials', async () => {
      const response = await request(app.getHttpServer())
        .post('/auth/login')
        .send({
          email: testUser.email,
          password: testUser.password,
        })
        .expect(200);

      expect(response.body).toHaveProperty('accessToken');
      expect(response.body).toHaveProperty('refreshToken');
      expect(response.body.user.email).toBe(testUser.email);
    });

    it('should reject invalid credentials', async () => {
      await request(app.getHttpServer())
        .post('/auth/login')
        .send({
          email: testUser.email,
          password: 'wrongpassword',
        })
        .expect(401);
    });

    it('should refresh token successfully', async () => {
      const loginResponse = await request(app.getHttpServer())
        .post('/auth/login')
        .send({
          email: testUser.email,
          password: testUser.password,
        });

      const refreshToken = loginResponse.body.refreshToken;

      const response = await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken })
        .expect(200);

      expect(response.body).toHaveProperty('accessToken');
      expect(response.body).toHaveProperty('refreshToken');
    });

    it('should handle forgot password request', async () => {
      const response = await request(app.getHttpServer())
        .post('/auth/forgot-password')
        .send({ email: testUser.email })
        .expect(200);

      expect(response.body.message).toContain('reset link has been sent');
    });
  });

  describe('Protected Routes', () => {
    it('should reject requests without auth token', async () => {
      await request(app.getHttpServer())
        .get('/auth/profile')
        .expect(401);
    });

    it('should allow access with valid auth token', async () => {
      const response = await request(app.getHttpServer())
        .get('/auth/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.email).toBe(testUser.email);
    });
  });

  describe('Upload Endpoints with Authentication', () => {
    let testImagePath: string;
    let uploadedFileName: string;

    beforeAll(() => {
      // Create a simple test image buffer
      testImagePath = path.join(__dirname, 'test-image.jpg');
      const testImageBuffer = Buffer.from([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        // Minimal JPEG header
      ]);
      fs.writeFileSync(testImagePath, testImageBuffer);
    });

    afterAll(() => {
      // Clean up test files
      if (fs.existsSync(testImagePath)) {
        fs.unlinkSync(testImagePath);
      }
    });

    it('should reject upload without authentication', async () => {
      await request(app.getHttpServer())
        .post('/upload/single')
        .attach('file', testImagePath)
        .expect(401);
    });

    it('should reject upload from non-owner/admin user', async () => {
      await request(app.getHttpServer())
        .post('/upload/single')
        .set('Authorization', `Bearer ${authToken}`)
        .attach('file', testImagePath)
        .expect(403);
    });

    it('should allow upload from owner user', async () => {
      const response = await request(app.getHttpServer())
        .post('/upload/single')
        .set('Authorization', `Bearer ${ownerToken}`)
        .attach('file', testImagePath)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body).toHaveProperty('filename');
      expect(response.body).toHaveProperty('url');
      uploadedFileName = response.body.filename;
    });

    it('should allow multiple file uploads from owner', async () => {
      const response = await request(app.getHttpServer())
        .post('/upload/multiple')
        .set('Authorization', `Bearer ${ownerToken}`)
        .attach('files', testImagePath)
        .attach('files', testImagePath)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.files).toHaveLength(2);
      expect(response.body.count).toBe(2);
    });

    it('should allow file deletion from owner', async () => {
      if (uploadedFileName) {
        const response = await request(app.getHttpServer())
          .delete(`/upload/${uploadedFileName}`)
          .set('Authorization', `Bearer ${ownerToken}`)
          .expect(200);

        expect(response.body.success).toBe(true);
        expect(response.body.message).toContain('deleted successfully');
      }
    });

    it('should reject file deletion without authentication', async () => {
      await request(app.getHttpServer())
        .delete('/upload/somefile.jpg')
        .expect(401);
    });
  });

  describe('Vehicle Endpoints with Authentication', () => {
    it('should reject vehicle creation without authentication', async () => {
      const vehicleData = {
        name: 'Test Vehicle',
        type: 'car',
        price: 100,
        description: 'Test vehicle description',
      };

      await request(app.getHttpServer())
        .post('/vehicles')
        .send(vehicleData)
        .expect(401);
    });

    it('should allow vehicle creation from owner', async () => {
      const vehicleData = {
        name: 'Test Vehicle',
        type: 'car',
        price: 100,
        description: 'Test vehicle description',
        location: 'Test Location',
        availability: true,
      };

      const response = await request(app.getHttpServer())
        .post('/vehicles')
        .set('Authorization', `Bearer ${ownerToken}`)
        .send(vehicleData)
        .expect(201);

      expect(response.body.name).toBe(vehicleData.name);
      expect(response.body.ownerId).toBeDefined();
    });

    it('should reject vehicle creation from customer', async () => {
      const vehicleData = {
        name: 'Test Vehicle',
        type: 'car',
        price: 100,
        description: 'Test vehicle description',
        location: 'Test Location',
        availability: true,
      };

      await request(app.getHttpServer())
        .post('/vehicles')
        .set('Authorization', `Bearer ${authToken}`)
        .send(vehicleData)
        .expect(403);
    });
  });

  describe('Error Handling', () => {
    it('should handle malformed JWT token', async () => {
      await request(app.getHttpServer())
        .get('/auth/profile')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });

    it('should handle expired token gracefully', async () => {
      // This would require a token with short expiry time
      // For now, we'll test with an obviously invalid token
      const expiredToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
      
      await request(app.getHttpServer())
        .get('/auth/profile')
        .set('Authorization', `Bearer ${expiredToken}`)
        .expect(401);
    });

    it('should handle large file uploads', async () => {
      // Create a large test file (this would normally be rejected)
      const largeBuffer = Buffer.alloc(50 * 1024 * 1024); // 50MB
      const largeFilePath = path.join(__dirname, 'large-test-file.bin');
      fs.writeFileSync(largeFilePath, largeBuffer);

      try {
        await request(app.getHttpServer())
          .post('/upload/single')
          .set('Authorization', `Bearer ${ownerToken}`)
          .attach('file', largeFilePath)
          .expect(413); // Payload too large
      } finally {
        if (fs.existsSync(largeFilePath)) {
          fs.unlinkSync(largeFilePath);
        }
      }
    });
  });
});
