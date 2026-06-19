import { Module } from '@nestjs/common';
import { DealVersionsController } from './deal-versions.controller';

@Module({
  controllers: [DealVersionsController],
})
export class DealVersionsModule {}
