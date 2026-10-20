import { Prisma, Track } from '@prisma/client';
import { QueryTrackDto } from '../dto/query-track.dto';

export interface FindTracksResult {
  items: Track[];
  total: number;
}

export const TRACK_REPOSITORY_TOKEN = Symbol('ITrackRepository');

export interface ITrackRepository {
  createWithRelations(
    data: Prisma.TrackCreateInput,
    artists?: { artistId: string; role?: string; position?: number }[],
    genreIds?: string[],
    sources?: { source: string; externalId: string; externalUrl?: string }[],
  ): Promise<Track>;
  findById(id: string): Promise<Track | null>;
  findWithDetails(id: string): Promise<any | null>;
  findAll(query: QueryTrackDto): Promise<FindTracksResult>;
  updateWithRelations(
    id: string,
    data: Prisma.TrackUpdateInput,
    artists?: { artistId: string; role?: string; position?: number }[],
    genreIds?: string[],
    sources?: { source: string; externalId: string; externalUrl?: string }[],
  ): Promise<Track>;
  delete(id: string): Promise<Track>;
}
