import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { VehiclesService } from './vehicles.service';
import { VehiclesController } from './vehicles.controller';
import { Vehicle } from '../entities/vehicle.entity';
import { VehicleCategory } from '../entities/vehicle-category.entity';
import { CacheServiceModule } from '../cache/cache.module';
import { UploadModule } from '../upload/upload.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Vehicle, VehicleCategory]),
    CacheServiceModule,
    UploadModule,
  ],
  controllers: [VehiclesController],
  providers: [VehiclesService],
  exports: [VehiclesService],
})
export class VehiclesModule {}
