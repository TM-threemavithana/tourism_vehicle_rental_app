import { Injectable, Logger } from '@nestjs/common';
import sharp from 'sharp';
import * as path from 'path';

export interface ImageDimensions {
  width: number;
  height: number;
  size: number;
}

export interface OptimizeOptions {
  maxWidth?: number;
  maxHeight?: number;
  quality?: number;
  format?: 'jpeg' | 'png' | 'webp';
}

export interface ThumbnailOptions {
  width: number;
  height: number;
  fit?: 'cover' | 'contain' | 'fill' | 'inside' | 'outside';
}

@Injectable()
export class ImageProcessingService {
  private readonly logger = new Logger(ImageProcessingService.name);

  /**
   * Optimize an image (resize, compress, convert format)
   */
  async optimizeImage(
    imagePath: string,
    options: OptimizeOptions = {},
  ): Promise<ImageDimensions> {
    try {
      const {
        maxWidth = 1920,
        maxHeight = 1080,
        quality = 85,
        format = 'jpeg',
      } = options;

      // Read image metadata
      const metadata = await sharp(imagePath).metadata();

      // Calculate new dimensions if needed
      let resizeOptions: { width?: number; height?: number } | undefined;
      if (
        metadata.width &&
        metadata.height &&
        (metadata.width > maxWidth || metadata.height > maxHeight)
      ) {
        resizeOptions = {
          width: maxWidth,
          height: maxHeight,
        };
      }

      // Process image
      const pipeline = sharp(imagePath);

      if (resizeOptions) {
        pipeline.resize({
          ...resizeOptions,
          fit: 'inside',
          withoutEnlargement: true,
        });
      }

      // Apply format-specific optimizations
      if (format === 'jpeg') {
        pipeline.jpeg({
          quality,
          progressive: true,
          mozjpeg: true,
        });
      } else if (format === 'webp') {
        pipeline.webp({
          quality,
        });
      } else if (format === 'png') {
        pipeline.png({
          quality,
          compressionLevel: 9,
        });
      }

      // Save optimized image (overwrite original)
      await pipeline.toFile(imagePath + '.tmp');

      // Replace original file
      const fs = await import('fs/promises');
      await fs.rename(imagePath + '.tmp', imagePath);

      // Get final metadata
      const finalMetadata = await sharp(imagePath).metadata();
      const stats = await fs.stat(imagePath);

      this.logger.log(`Optimized image: ${imagePath}`);

      return {
        width: finalMetadata.width || 0,
        height: finalMetadata.height || 0,
        size: stats.size,
      };
    } catch (error) {
      this.logger.error(
        `Failed to optimize image: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
      throw error;
    }
  }

  /**
   * Create a thumbnail from an image
   */
  async createThumbnail(
    imagePath: string,
    options: ThumbnailOptions,
  ): Promise<string> {
    try {
      const { width, height, fit = 'cover' } = options;

      // Generate thumbnail filename
      const dir = path.dirname(imagePath);
      const ext = path.extname(imagePath);
      const basename = path.basename(imagePath, ext);
      const thumbnailPath = path.join(dir, `thumb-${basename}${ext}`);

      // Create thumbnail
      await sharp(imagePath)
        .resize({
          width,
          height,
          fit,
          position: 'centre',
        })
        .jpeg({
          quality: 80,
          progressive: true,
        })
        .toFile(thumbnailPath);

      this.logger.log(`Created thumbnail: ${thumbnailPath}`);

      return thumbnailPath;
    } catch (error) {
      this.logger.error(
        `Failed to create thumbnail: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
      throw error;
    }
  }

  /**
   * Get image dimensions and metadata
   */
  async getImageMetadata(imagePath: string): Promise<sharp.Metadata> {
    try {
      return await sharp(imagePath).metadata();
    } catch (error) {
      this.logger.error(
        `Failed to get image metadata: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
      throw error;
    }
  }

  /**
   * Convert image format
   */
  async convertFormat(
    imagePath: string,
    targetFormat: 'jpeg' | 'png' | 'webp',
    quality = 85,
  ): Promise<string> {
    try {
      const dir = path.dirname(imagePath);
      const basename = path.basename(imagePath, path.extname(imagePath));
      const outputPath = path.join(dir, `${basename}.${targetFormat}`);

      const pipeline = sharp(imagePath);

      if (targetFormat === 'jpeg') {
        pipeline.jpeg({ quality });
      } else if (targetFormat === 'webp') {
        pipeline.webp({ quality });
      } else if (targetFormat === 'png') {
        pipeline.png({ quality });
      }

      await pipeline.toFile(outputPath);

      this.logger.log(`Converted image to ${targetFormat}: ${outputPath}`);

      return outputPath;
    } catch (error) {
      this.logger.error(
        `Failed to convert image format: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
      throw error;
    }
  }

  /**
   * Create multiple thumbnail sizes
   */
  async createMultipleThumbnails(
    imagePath: string,
    sizes: Array<{ width: number; height: number; suffix: string }>,
  ): Promise<string[]> {
    const thumbnails: string[] = [];

    for (const size of sizes) {
      try {
        const dir = path.dirname(imagePath);
        const ext = path.extname(imagePath);
        const basename = path.basename(imagePath, ext);
        const thumbnailPath = path.join(
          dir,
          `${basename}-${size.suffix}${ext}`,
        );

        await sharp(imagePath)
          .resize({
            width: size.width,
            height: size.height,
            fit: 'cover',
            position: 'centre',
          })
          .jpeg({
            quality: 80,
            progressive: true,
          })
          .toFile(thumbnailPath);

        thumbnails.push(thumbnailPath);
      } catch (error) {
        this.logger.error(
          `Failed to create ${size.suffix} thumbnail: ${error instanceof Error ? error.message : 'Unknown error'}`,
        );
      }
    }

    return thumbnails;
  }
}
