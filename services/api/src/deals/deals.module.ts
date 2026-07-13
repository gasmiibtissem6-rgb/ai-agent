// services/api/src/deals/deals.module.ts
import { Module } from '@nestjs/common';
import { DealsController, DealsAdminController } from './deals.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module'; // Provides JwtAuthGuard
import { DealsService } from './deals.service';


@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [DealsController, DealsAdminController],
  providers: [DealsService],
  exports: [DealsService],
})
export class DealsModule {}
