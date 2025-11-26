import {
  Controller,
  Post,
  Delete,
  UseInterceptors,
  UploadedFile,
  UploadedFiles,
  Body,
  Param,
  UseGuards,
  HttpStatus,
  HttpException,
  BadRequestException,
} from '@nestjs/common';
import {
  FileInterceptor,
  FilesInterceptor,
} from '@nestjs/platform-express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../dto/auth.dto';
import { UploadService } from './upload.service';
import { StorageService } from './storage.service';
import { ImageProcessingService } from './image-processing.service';

interface UploadResponse {
  success: boolean;
  filename: string;
  path: string;
  url: string;
  size: number;
  mimetype: string;
  thumbnailUrl?: string;
}

interface MultiUploadResponse {
  success: boolean;
  files: UploadResponse[];
  totalSize: number;
  count: number;
}

interface DeleteResponse {
  success: boolean;
  message: string;
  filename: string;
}

@Controller('upload')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UploadController {
  constructor(
    private readonly uploadService: UploadService,
    private readonly storageService: StorageService,
    private readonly imageProcessingService: ImageProcessingService,
  ) {}

  /**
   * Upload a single vehicle image
   */
  @Post('vehicle-image')
  @Roles(UserRole.OWNER, UserRole.ADMIN)
  @UseInterceptors(FileInterceptor('image'))
  async uploadVehicleImage(
    @UploadedFile() file: Express.Multer.File,
  ): Promise<UploadResponse> {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }

    try {
      // Process and optimize image
      const optimizedFile = await this.imageProcessingService.optimizeImage(
        file.path,
        {
          maxWidth: 1920,
          maxHeight: 1080,
          quality: 85,
        },
      );

      // Generate thumbnail
      const thumbnailPath = await this.imageProcessingService.createThumbnail(
        file.path,
        {
          width: 300,
          height: 200,
        },
      );

      // Get public URLs
      const imageUrl = this.storageService.getPublicUrl(file.filename);
      const thumbnailUrl = this.storageService.getPublicUrl(
        thumbnailPath.split('/').pop() || '',
      );

      return {
        success: true,
        filename: file.filename,
        path: file.path,
        url: imageUrl,
        size: optimizedFile.size,
        mimetype: file.mimetype,
        thumbnailUrl,
      };
    } catch (error) {
      // Clean up uploaded file on error
      await this.storageService.deleteFile(file.filename);
      throw new HttpException(
        `Failed to process image: ${error instanceof Error ? error.message : 'Unknown error'}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Upload multiple vehicle images (max 10)
   */
  @Post('vehicle-images')
  @Roles(UserRole.OWNER, UserRole.ADMIN)
  @UseInterceptors(FilesInterceptor('images', 10))
  async uploadMultipleVehicleImages(
    @UploadedFiles() files: Express.Multer.File[],
  ): Promise<MultiUploadResponse> {
    if (!files || files.length === 0) {
      throw new BadRequestException('No files uploaded');
    }

    const uploadedFiles: UploadResponse[] = [];
    let totalSize = 0;
    const errors: string[] = [];

    for (const file of files) {
      try {
        // Process each image
        const optimizedFile = await this.imageProcessingService.optimizeImage(
          file.path,
          {
            maxWidth: 1920,
            maxHeight: 1080,
            quality: 85,
          },
        );

        // Generate thumbnail
        const thumbnailPath = await this.imageProcessingService.createThumbnail(
          file.path,
          {
            width: 300,
            height: 200,
          },
        );

        const imageUrl = this.storageService.getPublicUrl(file.filename);
        const thumbnailUrl = this.storageService.getPublicUrl(
          thumbnailPath.split('/').pop() || '',
        );

        uploadedFiles.push({
          success: true,
          filename: file.filename,
          path: file.path,
          url: imageUrl,
          size: optimizedFile.size,
          mimetype: file.mimetype,
          thumbnailUrl,
        });

        totalSize += optimizedFile.size;
      } catch (error) {
        errors.push(
          `Failed to process ${file.originalname}: ${error instanceof Error ? error.message : 'Unknown error'}`,
        );
        // Clean up failed upload
        await this.storageService.deleteFile(file.filename);
      }
    }

    if (errors.length > 0 && uploadedFiles.length === 0) {
      throw new HttpException(
        `All uploads failed: ${errors.join(', ')}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }

    return {
      success: true,
      files: uploadedFiles,
      totalSize,
      count: uploadedFiles.length,
    };
  }

  /**
   * Delete a vehicle image
   */
  @Delete('vehicle-image/:filename')
  @Roles(UserRole.OWNER, UserRole.ADMIN)
  async deleteVehicleImage(
    @Param('filename') filename: string,
  ): Promise<DeleteResponse> {
    if (!filename) {
      throw new BadRequestException('Filename is required');
    }

    try {
      await this.storageService.deleteFile(filename);

      // Also delete thumbnail if exists
      const thumbnailFilename = `thumb-${filename}`;
      try {
        await this.storageService.deleteFile(thumbnailFilename);
      } catch {
        // Thumbnail might not exist, ignore error
      }

      return {
        success: true,
        message: 'File deleted successfully',
        filename,
      };
    } catch (error) {
      throw new HttpException(
        `Failed to delete file: ${error instanceof Error ? error.message : 'Unknown error'}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Delete multiple vehicle images
   */
  @Delete('vehicle-images')
  @Roles(UserRole.OWNER, UserRole.ADMIN)
  async deleteMultipleVehicleImages(
    @Body() body: { filenames: string[] },
  ): Promise<{ success: boolean; deleted: string[]; failed: string[] }> {
    if (!body.filenames || body.filenames.length === 0) {
      throw new BadRequestException('Filenames array is required');
    }

    const deleted: string[] = [];
    const failed: string[] = [];

    for (const filename of body.filenames) {
      try {
        await this.storageService.deleteFile(filename);
        deleted.push(filename);

        // Also delete thumbnail
        const thumbnailFilename = `thumb-${filename}`;
        try {
          await this.storageService.deleteFile(thumbnailFilename);
        } catch {
          // Thumbnail might not exist, ignore error
        }
      } catch (error) {
        failed.push(filename);
      }
    }

    return {
      success: failed.length === 0,
      deleted,
      failed,
    };
  }
}
