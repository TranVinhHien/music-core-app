import { Module } from '@nestjs/common';
import { AlbumsController } from './albums.controller';
import { AlbumsService } from './albums.service';
import { ALBUM_REPOSITORY_TOKEN } from './repositories/album.repository.interface';
import { PrismaAlbumRepository } from './repositories/prisma-album.repository';

@Module({
  controllers: [AlbumsController],
  providers: [
    AlbumsService,
    {
      provide: ALBUM_REPOSITORY_TOKEN,
      useClass: PrismaAlbumRepository,
    },
  ],
  exports: [AlbumsService, ALBUM_REPOSITORY_TOKEN],
})
export class AlbumsModule {}
