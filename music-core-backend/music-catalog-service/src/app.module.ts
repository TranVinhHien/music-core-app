import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { validate } from './config/env.validation';
import { PrismaModule } from './database/prisma.module';
import { ArtistsModule } from './modules/artists/artists.module';
import { AlbumsModule } from './modules/albums/albums.module';
import { TracksModule } from './modules/tracks/tracks.module';
import { GenresModule } from './modules/genres/genres.module';
import { TransitionsModule } from './modules/transitions/transitions.module';
import { AppController } from './app.controller';
import { AppService } from './app.service';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validate,
    }),
    PrismaModule,
    ArtistsModule,
    AlbumsModule,
    TracksModule,
    GenresModule,
    TransitionsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
