import { Injectable } from '@nestjs/common';
import { Prisma, Track, TrackAudioAnalysis } from '@prisma/client';
import { PrismaService } from '../../../database/prisma.service';
import {
  FindTracksResult,
  ITrackRepository,
} from './track.repository.interface';
import { QueryTrackDto } from '../dto/query-track.dto';
import { SaveTrackAudioAnalysisDto } from '../dto/save-track-audio-analysis.dto';

@Injectable()
export class PrismaTrackRepository implements ITrackRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createWithRelations(
    data: Prisma.TrackCreateInput,
    artists?: { artistId: string; role?: string; position?: number }[],
    genreIds?: string[],
    sources?: { source: string; externalId: string; externalUrl?: string }[],
  ): Promise<Track> {
    return this.prisma.$transaction(async (tx) => {
      const track = await tx.track.create({ data });

      if (artists && artists.length > 0) {
        await tx.trackArtist.createMany({
          data: artists.map((a, idx) => ({
            trackId: track.id,
            artistId: a.artistId,
            role: a.role || 'PRIMARY',
            position: a.position ?? idx + 1,
          })),
        });
      }

      if (genreIds && genreIds.length > 0) {
        await tx.trackGenre.createMany({
          data: genreIds.map((genreId) => ({
            trackId: track.id,
            genreId,
          })),
        });
      }

      if (sources && sources.length > 0) {
        await tx.trackSource.createMany({
          data: sources.map((s) => ({
            trackId: track.id,
            source: s.source,
            externalId: s.externalId,
            externalUrl: s.externalUrl,
          })),
        });
      }

      return track;
    });
  }

  async findById(id: string): Promise<Track | null> {
    return this.prisma.track.findUnique({
      where: { id },
    });
  }

  async findWithDetails(id: string): Promise<any | null> {
    return this.prisma.track.findUnique({
      where: { id },
      include: {
        album: true,
        trackArtists: {
          include: { artist: true },
          orderBy: { position: 'asc' },
        },
        trackGenres: {
          include: { genre: true },
        },
        trackSources: true,
        audioAnalysis: true,
      },
    });
  }

  async findAll(query: QueryTrackDto): Promise<FindTracksResult> {
    const {
      page,
      limit,
      order,
      query: search,
      albumId,
      artistId,
      genreId,
      status,
      analysisStatus,
    } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.TrackWhereInput = {};
    if (status) {
      where.status = status;
    }
    if (albumId) {
      where.albumId = albumId;
    }
    if (artistId) {
      where.trackArtists = { some: { artistId } };
    }
    if (genreId) {
      where.trackGenres = { some: { genreId } };
    }
    if (search) {
      where.title = { contains: search, mode: 'insensitive' };
    }
    if (analysisStatus) {
      if (analysisStatus === 'PENDING') {
        where.OR = [
          { audioAnalysis: null },
          { audioAnalysis: { analysisStatus: 'PENDING' } },
        ];
      } else {
        where.audioAnalysis = { analysisStatus };
      }
    }

    const [items, total] = await Promise.all([
      this.prisma.track.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: order },
        include: {
          album: true,
          trackArtists: {
            include: { artist: true },
            orderBy: { position: 'asc' },
          },
          audioAnalysis: true,
        },
      }),
      this.prisma.track.count({ where }),
    ]);

    return { items, total };
  }

  async updateWithRelations(
    id: string,
    data: Prisma.TrackUpdateInput,
    artists?: { artistId: string; role?: string; position?: number }[],
    genreIds?: string[],
    sources?: { source: string; externalId: string; externalUrl?: string }[],
  ): Promise<Track> {
    return this.prisma.$transaction(async (tx) => {
      const track = await tx.track.update({
        where: { id },
        data,
      });

      if (artists !== undefined) {
        await tx.trackArtist.deleteMany({ where: { trackId: id } });
        if (artists.length > 0) {
          await tx.trackArtist.createMany({
            data: artists.map((a, idx) => ({
              trackId: id,
              artistId: a.artistId,
              role: a.role || 'PRIMARY',
              position: a.position ?? idx + 1,
            })),
          });
        }
      }

      if (genreIds !== undefined) {
        await tx.trackGenre.deleteMany({ where: { trackId: id } });
        if (genreIds.length > 0) {
          await tx.trackGenre.createMany({
            data: genreIds.map((genreId) => ({
              trackId: id,
              genreId,
            })),
          });
        }
      }

      if (sources !== undefined) {
        await tx.trackSource.deleteMany({ where: { trackId: id } });
        if (sources.length > 0) {
          await tx.trackSource.createMany({
            data: sources.map((s) => ({
              trackId: id,
              source: s.source,
              externalId: s.externalId,
              externalUrl: s.externalUrl,
            })),
          });
        }
      }

      return track;
    });
  }

  async delete(id: string): Promise<Track> {
    return this.prisma.track.delete({
      where: { id },
    });
  }

  async upsertAudioAnalysis(
    trackId: string,
    data: SaveTrackAudioAnalysisDto,
  ): Promise<TrackAudioAnalysis> {
    const {
      cueInMs,
      cueOutMs,
      durationMs,
      bpm,
      firstDownbeatMs,
      downbeats,
      key,
      scale,
      camelotKey,
      energy,
      loudnessLufs,
      recommendedTransition,
      recommendedCrossfadeMs,
      analysisStatus,
      errorMessage,
    } = data;

    return this.prisma.$transaction(async (tx) => {
      const analysis = await tx.trackAudioAnalysis.upsert({
        where: { trackId },
        create: {
          trackId,
          cueInMs,
          cueOutMs,
          durationMs,
          bpm,
          firstDownbeatMs,
          downbeats: downbeats ?? undefined,
          key,
          scale,
          camelotKey,
          energy,
          loudnessLufs,
          recommendedTransition,
          recommendedCrossfadeMs,
          analysisStatus: analysisStatus || 'COMPLETED',
          errorMessage,
          analyzedAt: new Date(),
        },
        update: {
          cueInMs,
          cueOutMs,
          durationMs,
          bpm,
          firstDownbeatMs,
          downbeats: downbeats ?? undefined,
          key,
          scale,
          camelotKey,
          energy,
          loudnessLufs,
          recommendedTransition,
          recommendedCrossfadeMs,
          analysisStatus: analysisStatus || 'COMPLETED',
          errorMessage,
          analyzedAt: new Date(),
        },
      });

      // Update track durationMs if available
      if (durationMs) {
        await tx.track.update({
          where: { id: trackId },
          data: { durationMs },
        });
      }

      return analysis;
    });
  }
}
