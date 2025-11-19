import {
  Injectable,
  NotFoundException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification } from '../entities/notification.entity';
import { CreateNotificationDto } from '../dto/notification.dto';
import { NotificationsGateway } from './notifications.gateway';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private readonly notificationsRepository: Repository<Notification>,
    @Inject(forwardRef(() => NotificationsGateway))
    private readonly notificationsGateway: NotificationsGateway,
  ) {}

  async create(
    createNotificationDto: CreateNotificationDto,
  ): Promise<Notification> {
    const notification = this.notificationsRepository.create(
      createNotificationDto,
    );
    const savedNotification =
      await this.notificationsRepository.save(notification);

    // Send real-time notification via WebSocket if user is connected
    this.notificationsGateway.sendNotificationToUser(
      savedNotification.userId,
      savedNotification,
    );

    return savedNotification;
  }

  async findUserNotifications(userId: string): Promise<Notification[]> {
    return this.notificationsRepository
      .createQueryBuilder('notification')
      .leftJoinAndSelect('notification.booking', 'booking')
      .leftJoinAndSelect('booking.vehicle', 'vehicle')
      .where('notification.userId = :userId', { userId })
      .orderBy('notification.createdAt', 'DESC')
      .getMany();
  }

  async markAsRead(id: string): Promise<Notification> {
    const notification = await this.notificationsRepository.findOne({
      where: { id },
    });

    if (!notification) {
      throw new NotFoundException(`Notification with ID ${id} not found`);
    }

    notification.isRead = true;
    return this.notificationsRepository.save(notification);
  }

  async markAllAsRead(userId: string): Promise<void> {
    await this.notificationsRepository
      .createQueryBuilder()
      .update(Notification)
      .set({ isRead: true })
      .where('userId = :userId', { userId })
      .execute();
  }

  async getUnreadCount(userId: string): Promise<number> {
    return this.notificationsRepository
      .createQueryBuilder('notification')
      .where('notification.userId = :userId', { userId })
      .andWhere('notification.isRead = false')
      .getCount();
  }

  async remove(id: string): Promise<void> {
    const notification = await this.notificationsRepository.findOne({
      where: { id },
    });

    if (!notification) {
      throw new NotFoundException(`Notification with ID ${id} not found`);
    }

    await this.notificationsRepository.remove(notification);
  }
}
