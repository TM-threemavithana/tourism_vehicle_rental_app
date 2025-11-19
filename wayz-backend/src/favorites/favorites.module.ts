import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FavoritesService } from './favorites.service';
import { FavoritesController } from './favorites.controller';
import { Favorite } from '../entities/favorite.entity';
import { CacheServiceModule } from '../cache/cache.module';

@Module({
  imports: [TypeOrmModule.forFeature([Favorite]), CacheServiceModule],
  controllers: [FavoritesController],
  providers: [FavoritesService],
  exports: [FavoritesService],
})
export class FavoritesModule {}
