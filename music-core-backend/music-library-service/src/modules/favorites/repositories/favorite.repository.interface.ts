import { UserFavoriteTrack } from '@prisma/client';
import { QueryFavoriteTrackDto } from '../dto/query-favorite.dto';

export interface FindFavoritesResult {
  items: UserFavoriteTrack[];
  total: number;
}

export const FAVORITE_REPOSITORY_TOKEN = Symbol('IFavoriteRepository');

export interface IFavoriteRepository {
  add(userId: string, trackId: string): Promise<UserFavoriteTrack>;
  remove(userId: string, trackId: string): Promise<UserFavoriteTrack>;
  findAll(userId: string, query: QueryFavoriteTrackDto): Promise<FindFavoritesResult>;
  isFavorite(userId: string, trackId: string): Promise<boolean>;
}
