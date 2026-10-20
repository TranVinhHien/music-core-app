import { Artist, Prisma } from '@prisma/client';
import { QueryArtistDto } from '../dto/query-artist.dto';

export interface FindArtistsResult {
  items: Artist[];
  total: number;
}

export const ARTIST_REPOSITORY_TOKEN = Symbol('IArtistRepository');

export interface IArtistRepository {
  create(data: Prisma.ArtistCreateInput): Promise<Artist>;
  findById(id: string): Promise<Artist | null>;
  findWithDetails(id: string): Promise<any | null>;
  findAll(query: QueryArtistDto): Promise<FindArtistsResult>;
  update(id: string, data: Prisma.ArtistUpdateInput): Promise<Artist>;
  delete(id: string): Promise<Artist>;
}
