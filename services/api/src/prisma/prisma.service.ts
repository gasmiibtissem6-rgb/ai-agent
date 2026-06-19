// services/api/src/prisma/prisma.service.ts
import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  async onModuleInit() {
    // Connects to your Supabase PostgreSQL instance on startup
    await this.$connect();
  }

  async onModuleDestroy() {
    // Safely tears down the connection pool if the server shuts down
    await this.$disconnect();
  }
}