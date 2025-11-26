import { Module } from '@nestjs/common';
import { MulterModule } from '@nestjs/platform-express';
import { UploadController } from './upload.controller';
import { UploadService } from './upload.service';
import { StorageService } from './storage.service';
import { ImageProcessingService } from './image-processing.service';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { v4 as uuidv4 } from 'uuid';
import { Request } from 'express';

@Module({
  imports: [
    MulterModule.register({
      storage: diskStorage({
        destination: (
          req: Request,
          file: Express.Multer.File,
          cb: (error: Error | null, destination: string) => void,
        ) => {
          // Store in uploads directory
          cb(null, './uploads/vehicles');
        },
        filename: (
          req: Request,
          file: Express.Multer.File,
          cb: (error: Error | null, filename: string) => void,
        ) => {
          // Generate unique filename with UUID
          const uniqueSuffix = uuidv4();
          const ext = extname(file.originalname);
          cb(null, `vehicle-${uniqueSuffix}${ext}`);
        },
      }),
      limits: {
        fileSize: 5 * 1024 * 1024, // 5MB limit
        files: 10, // Max 10 files per upload
      },
      fileFilter: (
        req: Request,
        file: Express.Multer.File,
        cb: (error: Error | null, acceptFile: boolean) => void,
      ) => {
        // Only allow images
        if (file.mimetype.match(/\/(jpg|jpeg|png|webp)$/)) {
          cb(null, true);
        } else {
          cb(
            new Error(
              'Invalid file type. Only JPG, JPEG, PNG, and WebP are allowed.',
            ),
            false,
          );
        }
      },
    }),
  ],
  controllers: [UploadController],
  providers: [UploadService, StorageService, ImageProcessingService],
  exports: [UploadService, StorageService],
})
export class UploadModule {}
