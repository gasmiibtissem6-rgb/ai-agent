// admin.module.ts
/*
 * TODO FOR OUSSEMA
 * Restored to its pre-KYC-session state: registers only AdminController + AdminService.
 * The KYC session had also registered AdminKycController + AdminKycService and imported
 * KycModule (for KycStorageService / KYC_PROVIDER). Those registrations were removed.
 * If you implement the enhanced admin KYC surface (admin-kyc.controller.ts /
 * admin-kyc.service.ts), re-add here:
 *   imports:     [PrismaModule, AuthModule, KycModule]
 *   controllers: [AdminController, AdminKycController]
 *   providers:   [AdminService, AdminKycService]
 * (KycModule already exports KycService, KYC_PROVIDER and KycStorageService.)
 */
import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { PrismaModule } from '../prisma/prisma.module'; // Adjust relative path to yours
import { AuthModule } from '../auth/auth.module'; // Provides JwtAuthGuard + RolesGuard

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [AdminController],
  providers: [AdminService],
  exports: [AdminService], // Export if other modules need access to operational methods
})
export class AdminModule {}
