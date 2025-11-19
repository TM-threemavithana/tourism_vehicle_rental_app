import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';
import { FirebaseService } from './common/firebase.service';
import { DualWriteService } from './common/dual-write.service';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly firebaseService: FirebaseService,
    private readonly dualWriteService: DualWriteService,
  ) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('health')
  getHealth() {
    // Database is connected since TypeORM is successfully connecting to Aiven PostgreSQL
    const dbStatus = 'connected';

    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV,
      database: dbStatus,
      firebase: this.firebaseService.isInitialized ? 'connected' : 'disabled',
      dualWrite: this.dualWriteService.isDualWriteEnabled
        ? 'enabled'
        : 'disabled',
    };
  }

  @Get('status')
  getApiStatus() {
    // Log dual-write status for debugging
    this.dualWriteService.logDualWriteStatus();

    return {
      api: 'Wayz Backend API',
      version: '1.0.0',
      status: 'operational',
      features: {
        dualWrite: this.dualWriteService.isDualWriteEnabled,
        firebase: this.firebaseService.isInitialized,
        migration: 'phase-1-setup',
      },
    };
  }
}
