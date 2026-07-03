// kyc.module.ts
import { Module } from '@nestjs/common';
import { KycController } from './kyc.controller';
import { KycService } from './kyc.service';
import { PrismaModule } from '../prisma/prisma.module'; // Adjust relative path
import { AuthModule } from '../auth/auth.module'; // Provides JwtAuthGuard

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [KycController],
  providers: [KycService],
  exports: [KycService], // Exporting allows AdminModule to access shared verification steps
})
export class KycModule {}
