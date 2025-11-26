import { Controller, Post, Get, Body, Query, Logger } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiQuery } from '@nestjs/swagger';
import { MigrationService } from './migration.service';

@ApiTags('Migration')
@Controller('migration')
export class MigrationController {
  private readonly logger = new Logger(MigrationController.name);

  constructor(private readonly migrationService: MigrationService) {}

  @Post('migrate-all')
  @ApiOperation({ summary: 'Migrate all data from Firebase to PostgreSQL' })
  @ApiResponse({
    status: 200,
    description: 'Migration completed successfully',
  })
  @ApiResponse({ status: 500, description: 'Migration failed' })
  async migrateAll(
    @Body()
    options: {
      batchSize?: number;
      dryRun?: boolean;
      collections?: string[];
    } = {},
  ) {
    this.logger.log('Migration request received');
    return await this.migrationService.migrateAll(options);
  }

  @Post('migrate-document')
  @ApiOperation({ summary: 'Migrate a single document from Firebase' })
  @ApiResponse({ status: 200, description: 'Document migrated successfully' })
  @ApiResponse({ status: 404, description: 'Document not found' })
  @ApiResponse({ status: 500, description: 'Migration failed' })
  async migrateSingleDocument(
    @Body() body: { collection: string; documentId: string },
  ) {
    await this.migrationService.migrateSingleDocument(
      body.collection,
      body.documentId,
    );
    return {
      success: true,
      message: `Document ${body.collection}/${body.documentId} migrated successfully`,
    };
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get migration statistics' })
  @ApiResponse({ status: 200, description: 'Statistics retrieved successfully' })
  async getStats() {
    return await this.migrationService.getMigrationStats();
  }

  @Get('validate')
  @ApiOperation({ summary: 'Validate migrated data integrity' })
  @ApiResponse({ status: 200, description: 'Validation completed' })
  async validateMigration() {
    return await this.migrationService.validateMigration();
  }

  @Post('export-firestore')
  @ApiOperation({ summary: 'Export Firestore data to JSON backup' })
  @ApiResponse({ status: 200, description: 'Export completed successfully' })
  @ApiQuery({ name: 'outputPath', required: false })
  async exportFirestore(
    @Query('outputPath') outputPath?: string,
    @Body() body?: { collections?: string[] },
  ) {
    const path = outputPath || './firestore-backup.json';
    await this.migrationService.exportFirestoreToJson(
      path,
      body?.collections,
    );
    return {
      success: true,
      message: `Firestore data exported to ${path}`,
    };
  }
}
