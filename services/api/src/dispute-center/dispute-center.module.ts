import { Module } from '@nestjs/common';
import { DisputeCenterService } from './dispute-center.service';
import {
  DisputeCenterController,
  DisputeCenterUserController,
} from './dispute-center.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [DisputeCenterController, DisputeCenterUserController],
  providers: [DisputeCenterService],
  exports: [DisputeCenterService],
})
export class DisputeCenterModule {}
