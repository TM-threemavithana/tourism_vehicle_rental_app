import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { VehicleCategoriesService } from './vehicle-categories.service';
import { VehicleCategoriesController } from './vehicle-categories.controller';
import { VehicleCategory } from '../entities/vehicle-category.entity';
import { CacheServiceModule } from '../cache/cache.module';

@Module({
  imports: [TypeOrmModule.forFeature([VehicleCategory]), CacheServiceModule],
  controllers: [VehicleCategoriesController],
  providers: [VehicleCategoriesService],
  exports: [VehicleCategoriesService],
})
export class VehicleCategoriesModule {}
