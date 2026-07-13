// services/api/src/deals/deals.module.ts
import { Module } from '@nestjs/common';
import { DealsController, DealsAdminController } from './deals.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module'; // Provides JwtAuthGuard
import { NotificationsModule } from '../notifications/notifications.module';
import { DealsService } from './deals.service';


@Module({
  imports: [PrismaModule, AuthModule, NotificationsModule],
  controllers: [DealsController, DealsAdminController],
  providers: [DealsService],
  exports: [DealsService],
})
export class DealsModule {}
