import { Module } from '@nestjs/common';
import { TracksController } from './tracks.controller';
import { TracksService } from './tracks.service';
import { TRACK_REPOSITORY_TOKEN } from './repositories/track.repository.interface';
import { PrismaTrackRepository } from './repositories/prisma-track.repository';

@Module({
  controllers: [TracksController],
  providers: [
    TracksService,
    {
      provide: TRACK_REPOSITORY_TOKEN,
      useClass: PrismaTrackRepository,
    },
  ],
  exports: [TracksService, TRACK_REPOSITORY_TOKEN],
})
export class TracksModule {}
