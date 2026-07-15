// services/api/src/prisma/prisma.module.ts
import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Global() // Makes Prisma available everywhere without importing it in every single module file
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
