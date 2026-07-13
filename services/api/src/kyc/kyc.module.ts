// kyc.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { KycController, KycAdminController } from './kyc.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module'; // Provides JwtAuthGuard
import { PendingUploadRegistry } from './storage/pending-upload.registry';
import { KycStorageService } from './storage/kyc-storage.service';
import { ManualKycProvider } from './providers/manual-kyc.provider';
import { KYC_PROVIDER } from './providers/kyc-provider.interface';
import { KycService } from './kyc.service';

@Module({
  imports: [PrismaModule, AuthModule, ConfigModule],
  controllers: [KycController, KycAdminController],
  providers: [
    KycService,
    PendingUploadRegistry,
    KycStorageService,
    ManualKycProvider,
    // Bind the provider-neutral token to the manual implementation. Swap this single
    // line to integrate a third-party provider — no business logic changes required.
    { provide: KYC_PROVIDER, useExisting: ManualKycProvider },
  ],
  // Exported so AdminModule can reuse the provider abstraction and signed-URL service.
  exports: [KycService, KYC_PROVIDER, KycStorageService],
})
export class KycModule {}
