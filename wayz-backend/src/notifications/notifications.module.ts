import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { NotificationsGateway } from './notifications.gateway';
import { WsJwtGuard } from './guards/ws-jwt.guard';
import { Notification } from '../entities/notification.entity';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Notification]),
    forwardRef(() => AuthModule),
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService, NotificationsGateway, WsJwtGuard],
  exports: [NotificationsService, NotificationsGateway],
})
export class NotificationsModule {}
