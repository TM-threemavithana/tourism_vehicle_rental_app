import { Injectable, Logger } from '@nestjs/common';
import { StorageService } from './storage.service';
import { ImageProcessingService } from './image-processing.service';

export interface ProcessedImage {
  filename: string;
  path: string;
  url: string;
  thumbnailUrl: string;
  size: number;
  width: number;
  height: number;
}

export interface ImageProcessingOptions {
  maxWidth?: number;
  maxHeight?: number;
  quality?: number;
  generateThumbnail?: boolean;
  thumbnailWidth?: number;
  thumbnailHeight?: number;
}

@Injectable()
export class UploadService {
  private readonly logger = new Logger(UploadService.name);

  constructor(
    private readonly storageService: StorageService,
    private readonly imageProcessingService: ImageProcessingService,
  ) {}

  /**
   * Process and store a vehicle image
   */
  async processVehicleImage(
    file: Express.Multer.File,
    options?: ImageProcessingOptions,
  ): Promise<ProcessedImage> {
    this.logger.log(`Processing vehicle image: ${file.filename}`);

    try {
      // Default options
      const processingOptions = {
        maxWidth: options?.maxWidth || 1920,
        maxHeight: options?.maxHeight || 1080,
        quality: options?.quality || 85,
        generateThumbnail: options?.generateThumbnail ?? true,
        thumbnailWidth: options?.thumbnailWidth || 300,
        thumbnailHeight: options?.thumbnailHeight || 200,
      };

      // Optimize main image
      const optimized = await this.imageProcessingService.optimizeImage(
        file.path,
        {
          maxWidth: processingOptions.maxWidth,
          maxHeight: processingOptions.maxHeight,
          quality: processingOptions.quality,
        },
      );

      // Generate thumbnail if requested
      let thumbnailUrl = '';
      if (processingOptions.generateThumbnail) {
        const thumbnailPath = await this.imageProcessingService.createThumbnail(
          file.path,
          {
            width: processingOptions.thumbnailWidth,
            height: processingOptions.thumbnailHeight,
          },
        );
        thumbnailUrl = this.storageService.getPublicUrl(
          thumbnailPath.split('/').pop() || '',
        );
      }

      const imageUrl = this.storageService.getPublicUrl(file.filename);

      return {
        filename: file.filename,
        path: file.path,
        url: imageUrl,
        thumbnailUrl,
        size: optimized.size,
        width: optimized.width,
        height: optimized.height,
      };
    } catch (error) {
      this.logger.error(
        `Failed to process vehicle image: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
      throw error;
    }
  }

  /**
   * Process multiple vehicle images
   */
  async processVehicleImages(
    files: Express.Multer.File[],
    options?: ImageProcessingOptions,
  ): Promise<ProcessedImage[]> {
    this.logger.log(`Processing ${files.length} vehicle images`);

    const processed: ProcessedImage[] = [];

    for (const file of files) {
      try {
        const result = await this.processVehicleImage(file, options);
        processed.push(result);
      } catch (error) {
        this.logger.error(
          `Failed to process ${file.filename}: ${error instanceof Error ? error.message : 'Unknown error'}`,
        );
        // Clean up on error
        await this.storageService.deleteFile(file.filename);
      }
    }

    return processed;
  }

  /**
   * Delete vehicle image and its thumbnail
   */
  async deleteVehicleImage(filename: string): Promise<void> {
    this.logger.log(`Deleting vehicle image: ${filename}`);

    try {
      await this.storageService.deleteFile(filename);

      // Also delete thumbnail
      const thumbnailFilename = `thumb-${filename}`;
      try {
        await this.storageService.deleteFile(thumbnailFilename);
      } catch {
        // Thumbnail might not exist
      }
    } catch (error) {
      this.logger.error(
        `Failed to delete vehicle image: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
      throw error;
    }
  }

  /**
   * Delete multiple vehicle images
   */
  async deleteVehicleImages(filenames: string[]): Promise<{
    deleted: string[];
    failed: string[];
  }> {
    this.logger.log(`Deleting ${filenames.length} vehicle images`);

    const deleted: string[] = [];
    const failed: string[] = [];

    for (const filename of filenames) {
      try {
        await this.deleteVehicleImage(filename);
        deleted.push(filename);
      } catch {
        failed.push(filename);
      }
    }

    return { deleted, failed };
  }

  /**
   * Get storage statistics
   */
  async getStorageStats(): Promise<{
    totalFiles: number;
    totalSize: number;
    avgFileSize: number;
  }> {
    return this.storageService.getStorageStats();
  }

  /**
   * Upload multiple files and return their URLs (convenience method for vehicles)
   */
  async uploadFiles(files: Express.Multer.File[]): Promise<string[]> {
    this.logger.log(`Uploading ${files.length} files`);

    const processed = await this.processVehicleImages(files);
    return processed.map((img) => img.url);
  }
}
