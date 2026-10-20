import {
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  FAVORITE_REPOSITORY_TOKEN,
  type IFavoriteRepository,
} from './repositories/favorite.repository.interface';
import { CatalogClient } from '../../integrations/catalog/catalog.client';
import { AddFavoriteTrackDto } from './dto/add-favorite-track.dto';
import { QueryFavoriteTrackDto } from './dto/query-favorite.dto';
import { PaginatedResult } from '../../common/dto/pagination.dto';

@Injectable()
export class FavoritesService {
  constructor(
    @Inject(FAVORITE_REPOSITORY_TOKEN)
    private readonly favoriteRepository: IFavoriteRepository,
    private readonly catalogClient: CatalogClient,
  ) {}

  async add(userId: string, dto: AddFavoriteTrackDto) {
    // 1. Verify track exists in catalog service
    const track = await this.catalogClient.getTrackById(dto.trackId);
    if (!track) {
      throw new NotFoundException(`Track with ID "${dto.trackId}" not found in catalog`);
    }

    // 2. Check if already favorited
    const isFav = await this.favoriteRepository.isFavorite(userId, dto.trackId);
    if (isFav) {
      throw new ConflictException('This track is already in your favorites');
    }

    const favorite = await this.favoriteRepository.add(userId, dto.trackId);
    return {
      ...favorite,
      track,
    };
  }

  async remove(userId: string, trackId: string) {
    const isFav = await this.favoriteRepository.isFavorite(userId, trackId);
    if (!isFav) {
      throw new NotFoundException('Track not found in your favorites');
    }

    return this.favoriteRepository.remove(userId, trackId);
  }

  async findAll(userId: string, query: QueryFavoriteTrackDto) {
    const { items, total } = await this.favoriteRepository.findAll(userId, query);

    // Enrich tracks information from Catalog Service
    const trackIds = items.map((f) => f.trackId);
    const trackMap = await this.catalogClient.getTracksByIds(trackIds);

    const enrichedItems = items.map((f) => ({
      userId: f.userId,
      trackId: f.trackId,
      createdAt: f.createdAt,
      track: trackMap.get(f.trackId) || null,
    }));

    return new PaginatedResult(enrichedItems, total, query.page, query.limit);
  }
}
