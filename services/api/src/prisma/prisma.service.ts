// services/api/src/prisma/prisma.service.ts
import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(PrismaService.name);

  async onModuleInit() {
    if (!process.env.DATABASE_URL) {
      this.logger.warn(
        'DATABASE_URL is not set. Prisma startup connection was skipped.',
      );
      return;
    }

    // Connects to your PostgreSQL instance on startup when configured
    await this.$connect();
  }

  async onModuleDestroy() {
    if (!process.env.DATABASE_URL) {
      return;
    }

    // Safely tears down the connection pool if the server shuts down
    await this.$disconnect();
  }
}
