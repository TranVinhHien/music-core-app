import { Module } from '@nestjs/common';
import { SearchController } from './search.controller';
import { SearchService } from './search.service';
import { SEARCH_REPOSITORY_TOKEN } from './repositories/search.repository.interface';
import { PrismaSearchRepository } from './repositories/prisma-search.repository';

@Module({
  controllers: [SearchController],
  providers: [
    SearchService,
    {
      provide: SEARCH_REPOSITORY_TOKEN,
      useClass: PrismaSearchRepository,
    },
  ],
  exports: [SearchService, SEARCH_REPOSITORY_TOKEN],
})
export class SearchModule {}

