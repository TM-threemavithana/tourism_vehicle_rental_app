import { Global, Module } from '@nestjs/common';
import { FirebaseService } from './firebase.service';
import { DualWriteService } from './dual-write.service';

@Global()
@Module({
  providers: [FirebaseService, DualWriteService],
  exports: [FirebaseService, DualWriteService],
})
export class CommonModule {}
