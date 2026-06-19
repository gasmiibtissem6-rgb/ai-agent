import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AdminModule } from './admin/admin.module';
import { ApprovalsModule } from './approvals/approvals.module';
import { AuditModule } from './audit/audit.module';
import { ChatModule } from './chat/chat.module';
import { ConfigurationModule } from './configuration/configuration.module';
import { DealPartiesModule } from './deal-parties/deal-parties.module';
import { DealVersionsModule } from './deal-versions/deal-versions.module';
import { DealsModule } from './deals/deals.module';
import { FilesModule } from './files/files.module';
import { HealthModule } from './health/health.module';
import { KycModule } from './kyc/kyc.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ProfilesModule } from './profiles/profiles.module';
import { SubscriptionsModule } from './subscriptions/subscriptions.module';
import { TrustModule } from './trust/trust.module';

@Module({
  imports: [
    AdminModule,
    ApprovalsModule,
    AuditModule,
    ChatModule,
    ConfigurationModule,
    DealPartiesModule,
    DealVersionsModule,
    DealsModule,
    FilesModule,
    HealthModule,
    KycModule,
    NotificationsModule,
    ProfilesModule,
    SubscriptionsModule,
    TrustModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
