import { Module } from '@nestjs/common';
import { ContractsController } from './contracts.controller';
import { ContractsService } from './contracts.service';
import { EmailService } from './email.service';

@Module({
  controllers: [ContractsController],
  providers: [ContractsService, EmailService],
})
export class ContractsModule {}
