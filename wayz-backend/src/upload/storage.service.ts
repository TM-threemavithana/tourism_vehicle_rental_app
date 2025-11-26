import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs/promises';
import * as path from 'path';
import { existsSync } from 'fs';

export interface StorageStats {
  totalFiles: number;
  totalSize: number;
  avgFileSize: number;
}

@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);
  private readonly uploadDir: string;
  private readonly publicUrlBase: string;

  constructor(private readonly configService: ConfigService) {
    this.uploadDir = this.configService.get<string>(
      'UPLOAD_DIR',
      './uploads/vehicles',
    );
    this.publicUrlBase = this.configService.get<string>(
      'PUBLIC_URL_BASE',
      'http://localhost:3000/uploads/vehicles',
    );

    // Ensure upload directory exists
    this.ensureUploadDir();
  }

  /**
   * Ensure upload directory exists
   */
  private async ensureUploadDir(): Promise<void> {
    try {
      if (!existsSync(this.uploadDir)) {
        await fs.mkdir(this.uploadDir, { recursive: true });
        this.logger.log(`Created upload directory: ${this.uploadDir}`);
      }
    } catch (error) {
      this.logger.error(
        `Failed to create upload directory: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
    }
  }

  /**
   * Get the public URL for a file
   */
  getPublicUrl(filename: string): string {
    return `${this.publicUrlBase}/${filename}`;
  }

  /**
   * Get the full file path
   */
  getFilePath(filename: string): string {
    return path.join(this.uploadDir, filename);
  }

  /**
   * Check if file exists
   */
  async fileExists(filename: string): Promise<boolean> {
    try {
      await fs.access(this.getFilePath(filename));
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Delete a file
   */
  async deleteFile(filename: string): Promise<void> {
    const filePath = this.getFilePath(filename);

    try {
      if (await this.fileExists(filename)) {
        await fs.unlink(filePath);
        this.logger.log(`Deleted file: ${filename}`);
      } else {
        this.logger.warn(`File not found: ${filename}`);
      }
    } catch (error) {
      this.logger.error(
        `Failed to delete file ${filename}: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
      throw error;
    }
  }

  /**
   * Delete multiple files
   */
  async deleteFiles(filenames: string[]): Promise<void> {
    await Promise.all(filenames.map((filename) => this.deleteFile(filename)));
  }

  /**
   * Get file size
   */
  async getFileSize(filename: string): Promise<number> {
    try {
      const stats = await fs.stat(this.getFilePath(filename));
      return stats.size;
    } catch (error) {
      this.logger.error(
        `Failed to get file size: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
      throw error;
    }
  }

  /**
   * Get storage statistics
   */
  async getStorageStats(): Promise<StorageStats> {
    try {
      const files = await fs.readdir(this.uploadDir);
      let totalSize = 0;

      for (const file of files) {
        const filePath = path.join(this.uploadDir, file);
        const stats = await fs.stat(filePath);
        if (stats.isFile()) {
          totalSize += stats.size;
        }
      }

      return {
        totalFiles: files.length,
        totalSize,
        avgFileSize: files.length > 0 ? totalSize / files.length : 0,
      };
    } catch (error) {
      this.logger.error(
        `Failed to get storage stats: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
      throw error;
    }
  }

  /**
   * Clean up old files (older than specified days)
   */
  async cleanupOldFiles(daysOld: number): Promise<number> {
    try {
      const files = await fs.readdir(this.uploadDir);
      const now = Date.now();
      const maxAge = daysOld * 24 * 60 * 60 * 1000;
      let deletedCount = 0;

      for (const file of files) {
        const filePath = path.join(this.uploadDir, file);
        const stats = await fs.stat(filePath);

        if (stats.isFile() && now - stats.mtimeMs > maxAge) {
          await fs.unlink(filePath);
          deletedCount++;
        }
      }

      this.logger.log(`Cleaned up ${deletedCount} old files`);
      return deletedCount;
    } catch (error) {
      this.logger.error(
        `Failed to cleanup old files: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
      throw error;
    }
  }
}
