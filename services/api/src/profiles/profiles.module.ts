// services/api/src/profiles/profiles.module.ts
import { Module } from '@nestjs/common';
import { ProfilesController } from './profiles.controller';
import { ProfilesService } from './profiles.service';
import { PrismaModule } from '../prisma/prisma.module'; // Import Prisma to use the service database hooks
import { AuthModule } from '../auth/auth.module'; // Provides JwtAuthGuard

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [ProfilesController],
  providers: [ProfilesService],
  exports: [ProfilesService],
})
export class ProfilesModule {}
