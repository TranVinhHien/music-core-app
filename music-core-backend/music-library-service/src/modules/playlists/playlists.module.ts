import { Module } from '@nestjs/common';
import { PlaylistsController } from './playlists.controller';
import { PlaylistsService } from './playlists.service';
import { PLAYLIST_REPOSITORY_TOKEN } from './repositories/playlist.repository.interface';
import { PrismaPlaylistRepository } from './repositories/prisma-playlist.repository';
import { CatalogModule } from '../../integrations/catalog/catalog.module';

@Module({
  imports: [CatalogModule],
  controllers: [PlaylistsController],
  providers: [
    PlaylistsService,
    {
      provide: PLAYLIST_REPOSITORY_TOKEN,
      useClass: PrismaPlaylistRepository,
    },
  ],
  exports: [PlaylistsService, PLAYLIST_REPOSITORY_TOKEN],
})
export class PlaylistsModule {}
