# 🔗 Integrating Upload Service with Vehicles Module

## Overview

This guide shows how to integrate the upload service with the vehicles module so vehicle owners can upload images when creating or updating vehicles.

---

## Step 1: Update Vehicle DTOs

First, let's update the vehicle DTOs to handle image uploads properly.

### Update `create-vehicle.dto.ts`

```typescript
// wayz-backend/src/dtos/vehicle.dto.ts

import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNumber, IsOptional, IsArray, IsBoolean, IsUUID, Min, Max } from 'class-validator';

export class CreateVehicleDto {
  // ...existing fields...

  @ApiPropertyOptional({ 
    description: 'Vehicle images (URLs from upload service)',
    type: [String],
    example: ['http://localhost:3000/uploads/abc123-vehicle.jpg']
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  images?: string[];

  // ...rest of fields...
}
```

---

## Step 2: Update Vehicles Controller

Add image upload methods to the vehicles controller:

```typescript
// wayz-backend/src/vehicles/vehicles.controller.ts

import { 
  Controller, 
  Post, 
  Put, 
  Delete, 
  Body, 
  Param, 
  UseGuards,
  UseInterceptors,
  UploadedFiles,
  BadRequestException
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { VehiclesService } from './vehicles.service';
import { UploadService } from '../upload/upload.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiConsumes } from '@nestjs/swagger';

@ApiTags('Vehicles')
@Controller('vehicles')
export class VehiclesController {
  constructor(
    private readonly vehiclesService: VehiclesService,
    private readonly uploadService: UploadService,
  ) {}

  // ...existing methods...

  /**
   * Upload images for a vehicle
   */
  @Post(':id/images')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Upload images for a vehicle' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FilesInterceptor('files', 10))
  async uploadVehicleImages(
    @Param('id') vehicleId: string,
    @UploadedFiles() files: Express.Multer.File[],
    @CurrentUser() user: any,
  ) {
    if (!files || files.length === 0) {
      throw new BadRequestException('No files uploaded');
    }

    // Get vehicle and verify ownership
    const vehicle = await this.vehiclesService.findOne(vehicleId);
    if (vehicle.ownerId !== user.userId && user.role !== 'admin') {
      throw new BadRequestException('You can only upload images for your own vehicles');
    }

    // Upload images
    const uploadResults = await this.uploadService.uploadImages(files);
    const imageUrls = uploadResults.map(result => result.url);

    // Update vehicle with new image URLs
    const updatedVehicle = await this.vehiclesService.addImages(vehicleId, imageUrls);

    return {
      success: true,
      message: `${imageUrls.length} images uploaded successfully`,
      vehicle: updatedVehicle,
      images: uploadResults,
    };
  }

  /**
   * Delete an image from a vehicle
   */
  @Delete(':id/images/:filename')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete an image from a vehicle' })
  async deleteVehicleImage(
    @Param('id') vehicleId: string,
    @Param('filename') filename: string,
    @CurrentUser() user: any,
  ) {
    // Get vehicle and verify ownership
    const vehicle = await this.vehiclesService.findOne(vehicleId);
    if (vehicle.ownerId !== user.userId && user.role !== 'admin') {
      throw new BadRequestException('You can only delete images from your own vehicles');
    }

    // Delete from storage
    await this.uploadService.deleteFile(filename);

    // Remove from vehicle images array
    const imageUrl = `http://localhost:3000/uploads/${filename}`;
    const updatedVehicle = await this.vehiclesService.removeImage(vehicleId, imageUrl);

    return {
      success: true,
      message: 'Image deleted successfully',
      vehicle: updatedVehicle,
    };
  }

  /**
   * Create vehicle with images (combined endpoint)
   */
  @Post('with-images')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create vehicle with images in one request' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FilesInterceptor('images', 10))
  async createVehicleWithImages(
    @Body() createVehicleDto: CreateVehicleDto,
    @UploadedFiles() files: Express.Multer.File[],
    @CurrentUser() user: any,
  ) {
    // Upload images first if provided
    let imageUrls: string[] = [];
    if (files && files.length > 0) {
      const uploadResults = await this.uploadService.uploadImages(files);
      imageUrls = uploadResults.map(result => result.url);
    }

    // Create vehicle with image URLs
    const vehicleData = {
      ...createVehicleDto,
      images: imageUrls,
      ownerId: user.userId,
    };

    const vehicle = await this.vehiclesService.create(vehicleData);

    return {
      success: true,
      message: 'Vehicle created successfully',
      vehicle,
      uploadedImages: imageUrls.length,
    };
  }
}
```

---

## Step 3: Update Vehicles Service

Add methods to manage vehicle images:

```typescript
// wayz-backend/src/vehicles/vehicles.service.ts

import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Vehicle } from '../entities/vehicle.entity';

@Injectable()
export class VehiclesService {
  constructor(
    @InjectRepository(Vehicle)
    private readonly vehicleRepository: Repository<Vehicle>,
  ) {}

  // ...existing methods...

  /**
   * Add images to a vehicle
   */
  async addImages(vehicleId: string, imageUrls: string[]): Promise<Vehicle> {
    const vehicle = await this.findOne(vehicleId);
    
    // Add new images to existing ones
    vehicle.images = vehicle.images || [];
    vehicle.images = [...vehicle.images, ...imageUrls];
    
    const updatedVehicle = await this.vehicleRepository.save(vehicle);

    // Invalidate cache
    await this.invalidateVehicleCache(vehicleId, vehicle.ownerId);

    return updatedVehicle;
  }

  /**
   * Remove an image from a vehicle
   */
  async removeImage(vehicleId: string, imageUrl: string): Promise<Vehicle> {
    const vehicle = await this.findOne(vehicleId);
    
    // Remove the image URL from array
    vehicle.images = (vehicle.images || []).filter(url => url !== imageUrl);
    
    const updatedVehicle = await this.vehicleRepository.save(vehicle);

    // Invalidate cache
    await this.invalidateVehicleCache(vehicleId, vehicle.ownerId);

    return updatedVehicle;
  }

  /**
   * Update vehicle images (replace all)
   */
  async updateImages(vehicleId: string, imageUrls: string[]): Promise<Vehicle> {
    const vehicle = await this.findOne(vehicleId);
    
    vehicle.images = imageUrls;
    
    const updatedVehicle = await this.vehicleRepository.save(vehicle);

    // Invalidate cache
    await this.invalidateVehicleCache(vehicleId, vehicle.ownerId);

    return updatedVehicle;
  }

  private async invalidateVehicleCache(vehicleId: string, ownerId?: string) {
    // Invalidate relevant caches
    await this.cacheService.del(`vehicle:${vehicleId}`);
    await this.cacheService.del('vehicles:all');
    if (ownerId) {
      await this.cacheService.del(`vehicles:owner:${ownerId}`);
    }
  }
}
```

---

## Step 4: Update Vehicles Module

Import the UploadService in the vehicles module:

```typescript
// wayz-backend/src/vehicles/vehicles.module.ts

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { VehiclesController } from './vehicles.controller';
import { VehiclesService } from './vehicles.service';
import { Vehicle } from '../entities/vehicle.entity';
import { CacheServiceModule } from '../cache/cache.module';
import { UploadModule } from '../upload/upload.module'; // Add this

@Module({
  imports: [
    TypeOrmModule.forFeature([Vehicle]),
    CacheServiceModule,
    UploadModule, // Add this
  ],
  controllers: [VehiclesController],
  providers: [VehiclesService],
  exports: [VehiclesService],
})
export class VehiclesModule {}
```

---

## Step 5: Usage Examples

### Example 1: Create Vehicle with Images

```bash
# Upload images and create vehicle in one request
curl -X POST http://localhost:3000/vehicles/with-images \
  -H "Authorization: Bearer $TOKEN" \
  -F "make=Toyota" \
  -F "model=Camry" \
  -F "year=2023" \
  -F "dailyRate=75" \
  -F "images=@vehicle-front.jpg" \
  -F "images=@vehicle-side.jpg" \
  -F "images=@vehicle-interior.jpg"
```

### Example 2: Add Images to Existing Vehicle

```bash
# Upload additional images to vehicle
curl -X POST http://localhost:3000/vehicles/abc-123-uuid/images \
  -H "Authorization: Bearer $TOKEN" \
  -F "files=@new-photo-1.jpg" \
  -F "files=@new-photo-2.jpg"
```

### Example 3: Delete Image from Vehicle

```bash
# Delete specific image
curl -X DELETE http://localhost:3000/vehicles/abc-123-uuid/images/abc123-vehicle.jpg \
  -H "Authorization: Bearer $TOKEN"
```

### Example 4: Using JavaScript/TypeScript Client

```typescript
// Frontend code example
async function createVehicleWithImages(vehicleData: any, imageFiles: File[]) {
  const formData = new FormData();
  
  // Add vehicle data
  Object.keys(vehicleData).forEach(key => {
    formData.append(key, vehicleData[key]);
  });
  
  // Add image files
  imageFiles.forEach(file => {
    formData.append('images', file);
  });
  
  const response = await fetch('http://localhost:3000/vehicles/with-images', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
    },
    body: formData,
  });
  
  return await response.json();
}

// Usage
const vehicle = {
  make: 'Toyota',
  model: 'Camry',
  year: 2023,
  dailyRate: 75,
};

const imageFiles = [file1, file2, file3]; // From file input
const result = await createVehicleWithImages(vehicle, imageFiles);
console.log(result.vehicle); // Created vehicle with images
```

---

## Step 6: Flutter Integration

Update your Flutter app to use the new endpoints:

```dart
// lib/services/vehicle_service.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class VehicleService {
  final String baseUrl = 'http://localhost:3000';
  final String? authToken;
  
  VehicleService({this.authToken});
  
  /// Create vehicle with images
  Future<Map<String, dynamic>> createVehicleWithImages({
    required Map<String, dynamic> vehicleData,
    required List<File> imageFiles,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/vehicles/with-images'),
    );
    
    // Add headers
    request.headers['Authorization'] = 'Bearer $authToken';
    
    // Add vehicle data
    vehicleData.forEach((key, value) {
      request.fields[key] = value.toString();
    });
    
    // Add image files
    for (var imageFile in imageFiles) {
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'images',
        stream,
        length,
        filename: imageFile.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
    }
    
    // Send request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create vehicle: ${response.body}');
    }
  }
  
  /// Add images to existing vehicle
  Future<Map<String, dynamic>> addVehicleImages({
    required String vehicleId,
    required List<File> imageFiles,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/vehicles/$vehicleId/images'),
    );
    
    request.headers['Authorization'] = 'Bearer $authToken';
    
    for (var imageFile in imageFiles) {
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'files',
        stream,
        length,
        filename: imageFile.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
    }
    
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to add images: ${response.body}');
    }
  }
  
  /// Delete vehicle image
  Future<void> deleteVehicleImage({
    required String vehicleId,
    required String filename,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/vehicles/$vehicleId/images/$filename'),
      headers: {
        'Authorization': 'Bearer $authToken',
      },
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete image: ${response.body}');
    }
  }
}
```

---

## Step 7: Testing Integration

### Test Script

```bash
#!/bin/bash

echo "🧪 Testing Vehicle-Upload Integration..."

# Get auth token
TOKEN=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@example.com","password":"SecurePass123!"}' \
  | jq -r '.accessToken')

echo "✓ Got auth token"

# Test 1: Create vehicle with images
echo "Test 1: Create vehicle with images..."
VEHICLE_RESPONSE=$(curl -s -X POST http://localhost:3000/vehicles/with-images \
  -H "Authorization: Bearer $TOKEN" \
  -F "make=Toyota" \
  -F "model=Camry" \
  -F "year=2023" \
  -F "dailyRate=75" \
  -F "images=@test-image1.jpg" \
  -F "images=@test-image2.jpg")

VEHICLE_ID=$(echo $VEHICLE_RESPONSE | jq -r '.vehicle.id')
echo "✓ Created vehicle: $VEHICLE_ID"

# Test 2: Add more images
echo "Test 2: Add more images to vehicle..."
curl -s -X POST http://localhost:3000/vehicles/$VEHICLE_ID/images \
  -H "Authorization: Bearer $TOKEN" \
  -F "files=@test-image3.jpg" \
  > /dev/null

echo "✓ Added more images"

# Test 3: Get vehicle and verify images
echo "Test 3: Verify vehicle images..."
IMAGES_COUNT=$(curl -s http://localhost:3000/vehicles/$VEHICLE_ID \
  | jq '.images | length')

echo "✓ Vehicle has $IMAGES_COUNT images"

# Test 4: Delete an image
echo "Test 4: Delete an image..."
FIRST_IMAGE=$(curl -s http://localhost:3000/vehicles/$VEHICLE_ID \
  | jq -r '.images[0]' | sed 's/.*\///')

curl -s -X DELETE http://localhost:3000/vehicles/$VEHICLE_ID/images/$FIRST_IMAGE \
  -H "Authorization: Bearer $TOKEN" \
  > /dev/null

echo "✓ Deleted image"

echo "🎉 All integration tests passed!"
```

---

## Success Criteria

✅ **Integration is complete when:**
- Vehicle can be created with images in one request
- Images can be added to existing vehicles
- Images can be deleted from vehicles
- Vehicle images array is properly updated
- Only vehicle owners can manage their vehicle images
- Cache is properly invalidated on changes

---

## Next Steps

1. ✅ Test the integration endpoints
2. ✅ Update Flutter app to use new endpoints
3. ✅ Run Firebase migration
4. 🚀 Deploy to production

**Ready for migration!** 🎉
