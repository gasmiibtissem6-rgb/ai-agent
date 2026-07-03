// services/api/src/deals/deals.module.ts
import { Module } from '@nestjs/common';
import { DealsController } from './deals.controller';
import { DealsService } from './deals.service';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module'; // Provides JwtAuthGuard

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [DealsController],
  providers: [DealsService],
})
export class DealsModule {}