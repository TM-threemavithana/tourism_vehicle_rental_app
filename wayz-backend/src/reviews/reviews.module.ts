import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ReviewsService } from './reviews.service';
import { ReviewsController } from './reviews.controller';
import { Review } from '../entities/review.entity';
import { CacheServiceModule } from '../cache/cache.module';

@Module({
  imports: [TypeOrmModule.forFeature([Review]), CacheServiceModule],
  controllers: [ReviewsController],
  providers: [ReviewsService],
  exports: [ReviewsService],
})
export class ReviewsModule {}
