// admin.module.ts
import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AdminKycController } from './admin-kyc.controller';
import { AdminKycService } from './admin-kyc.service';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module'; // Provides JwtAuthGuard + RolesGuard
import { KycModule } from '../kyc/kyc.module'; // Provides KYC_PROVIDER + KycStorageService

@Module({
  imports: [PrismaModule, AuthModule, KycModule],
  controllers: [AdminController, AdminKycController],
  providers: [AdminService, AdminKycService],
  exports: [AdminService],
})
export class AdminModule {}
