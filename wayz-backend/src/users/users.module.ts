import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { User } from '../entities/user.entity';
import { CacheServiceModule } from '../cache/cache.module';

@Module({
  imports: [TypeOrmModule.forFeature([User]), CacheServiceModule],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService], // Export for use in other modules (auth, etc.)
})
export class UsersModule {}
