import { Module } from '@nestjs/common';
import { ContractArchiveService } from './contract-archive.service';
import { ContractArchiveController } from './contract-archive.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [ContractArchiveController],
  providers: [ContractArchiveService],
  exports: [ContractArchiveService],
})
export class ContractArchiveModule {}
