import { Injectable } from '@nestjs/common';
import { Playlist, PlaylistTrack, Prisma } from '@prisma/client';
import { PrismaService } from '../../../database/prisma.service';
import {
  FindPlaylistsResult,
  IPlaylistRepository,
} from './playlist.repository.interface';
import { QueryPlaylistDto } from '../dto/query-playlist.dto';

@Injectable()
export class PrismaPlaylistRepository implements IPlaylistRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(data: Prisma.PlaylistCreateInput): Promise<Playlist> {
    return this.prisma.playlist.create({ data });
  }

  async findById(id: string): Promise<any | null> {
    return this.prisma.playlist.findUnique({
      where: { id },
      include: {
        tracks: {
          orderBy: { position: 'asc' },
        },
      },
    });
  }

  async findAll(
    currentUserId: string,
    query: QueryPlaylistDto,
  ): Promise<FindPlaylistsResult> {
    const { page, limit, order, query: search, visibility, userId } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.PlaylistWhereInput = {};

    if (userId) {
      where.userId = userId;
      if (userId !== currentUserId) {
        where.visibility = 'PUBLIC';
      }
    } else {
      // By default show user's own playlists OR public playlists
      where.OR = [
        { userId: currentUserId },
        { visibility: 'PUBLIC' },
      ];
    }

    if (visibility) {
      where.visibility = visibility;
    }

    if (search) {
      where.name = { contains: search, mode: 'insensitive' };
    }

    const [items, total] = await Promise.all([
      this.prisma.playlist.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: order },
        include: {
          _count: {
            select: { tracks: true },
          },
        },
      }),
      this.prisma.playlist.count({ where }),
    ]);

    return { items, total };
  }

  async update(id: string, data: Prisma.PlaylistUpdateInput): Promise<Playlist> {
    return this.prisma.playlist.update({
      where: { id },
      data,
    });
  }

  async delete(id: string): Promise<Playlist> {
    return this.prisma.playlist.delete({
      where: { id },
    });
  }

  async addTrack(
    playlistId: string,
    trackId: string,
    position: number,
  ): Promise<PlaylistTrack> {
    return this.prisma.playlistTrack.create({
      data: {
        playlistId,
        trackId,
        position,
      },
    });
  }

  async removeTrack(playlistId: string, trackId: string): Promise<PlaylistTrack> {
    return this.prisma.playlistTrack.delete({
      where: {
        playlistId_trackId: {
          playlistId,
          trackId,
        },
      },
    });
  }

  async getMaxPosition(playlistId: string): Promise<number> {
    const aggregate = await this.prisma.playlistTrack.aggregate({
      where: { playlistId },
      _max: { position: true },
    });
    return aggregate._max.position ?? 0;
  }

  async hasTrack(playlistId: string, trackId: string): Promise<boolean> {
    const count = await this.prisma.playlistTrack.count({
      where: { playlistId, trackId },
    });
    return count > 0;
  }
}
