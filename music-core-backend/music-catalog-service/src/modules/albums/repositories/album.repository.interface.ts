import { Album, Prisma } from '@prisma/client';
import { QueryAlbumDto } from '../dto/query-album.dto';

export interface FindAlbumsResult {
  items: Album[];
  total: number;
}

export const ALBUM_REPOSITORY_TOKEN = Symbol('IAlbumRepository');

export interface IAlbumRepository {
  createWithArtists(
    data: Prisma.AlbumCreateInput,
    artists?: { artistId: string; position?: number }[],
  ): Promise<Album>;
  findById(id: string): Promise<Album | null>;
  findWithDetails(id: string): Promise<any | null>;
  findAll(query: QueryAlbumDto): Promise<FindAlbumsResult>;
  updateWithArtists(
    id: string,
    data: Prisma.AlbumUpdateInput,
    artists?: { artistId: string; position?: number }[],
  ): Promise<Album>;
  delete(id: string): Promise<Album>;
}
