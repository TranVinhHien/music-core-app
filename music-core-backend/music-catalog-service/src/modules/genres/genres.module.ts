import { Module } from '@nestjs/common';
import { GenresController } from './genres.controller';
import { GenresService } from './genres.service';
import { GENRE_REPOSITORY_TOKEN } from './repositories/genre.repository.interface';
import { PrismaGenreRepository } from './repositories/prisma-genre.repository';

@Module({
  controllers: [GenresController],
  providers: [
    GenresService,
    {
      provide: GENRE_REPOSITORY_TOKEN,
      useClass: PrismaGenreRepository,
    },
  ],
  exports: [GenresService, GENRE_REPOSITORY_TOKEN],
})
export class GenresModule {}
