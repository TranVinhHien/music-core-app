import { Module } from '@nestjs/common';
import { ArtistsController } from './artists.controller';
import { ArtistsService } from './artists.service';
import { ARTIST_REPOSITORY_TOKEN } from './repositories/artist.repository.interface';
import { PrismaArtistRepository } from './repositories/prisma-artist.repository';

@Module({
  controllers: [ArtistsController],
  providers: [
    ArtistsService,
    {
      provide: ARTIST_REPOSITORY_TOKEN,
      useClass: PrismaArtistRepository,
    },
  ],
  exports: [ArtistsService, ARTIST_REPOSITORY_TOKEN],
})
export class ArtistsModule {}
