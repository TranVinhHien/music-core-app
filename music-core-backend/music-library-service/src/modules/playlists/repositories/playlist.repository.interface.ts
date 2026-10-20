import { Playlist, PlaylistTrack, Prisma } from '@prisma/client';
import { QueryPlaylistDto } from '../dto/query-playlist.dto';

export interface FindPlaylistsResult {
  items: Playlist[];
  total: number;
}

export const PLAYLIST_REPOSITORY_TOKEN = Symbol('IPlaylistRepository');

export interface IPlaylistRepository {
  create(data: Prisma.PlaylistCreateInput): Promise<Playlist>;
  findById(id: string): Promise<any | null>;
  findAll(currentUserId: string, query: QueryPlaylistDto): Promise<FindPlaylistsResult>;
  update(id: string, data: Prisma.PlaylistUpdateInput): Promise<Playlist>;
  delete(id: string): Promise<Playlist>;
  addTrack(playlistId: string, trackId: string, position: number): Promise<PlaylistTrack>;
  removeTrack(playlistId: string, trackId: string): Promise<PlaylistTrack>;
  getMaxPosition(playlistId: string): Promise<number>;
  hasTrack(playlistId: string, trackId: string): Promise<boolean>;
}
