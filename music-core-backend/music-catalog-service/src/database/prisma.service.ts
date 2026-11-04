import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(PrismaService.name);

  async onModuleInit() {
    await this.$connect();
    try {
      await this.$executeRawUnsafe(`CREATE EXTENSION IF NOT EXISTS pg_trgm;`);
    } catch (e: any) {
      this.logger.warn(`Could not enable pg_trgm extension: ${e.message}`);
    }
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
