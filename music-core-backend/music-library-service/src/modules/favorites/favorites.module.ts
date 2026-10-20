import { Module } from '@nestjs/common';
import { FavoritesController } from './favorites.controller';
import { FavoritesService } from './favorites.service';
import { FAVORITE_REPOSITORY_TOKEN } from './repositories/favorite.repository.interface';
import { PrismaFavoriteRepository } from './repositories/prisma-favorite.repository';
import { CatalogModule } from '../../integrations/catalog/catalog.module';

@Module({
  imports: [CatalogModule],
  controllers: [FavoritesController],
  providers: [
    FavoritesService,
    {
      provide: FAVORITE_REPOSITORY_TOKEN,
      useClass: PrismaFavoriteRepository,
    },
  ],
  exports: [FavoritesService, FAVORITE_REPOSITORY_TOKEN],
})
export class FavoritesModule {}
