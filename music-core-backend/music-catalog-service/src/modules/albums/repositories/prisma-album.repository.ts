import { Injectable } from '@nestjs/common';
import { Album, Prisma } from '@prisma/client';
import { PrismaService } from '../../../database/prisma.service';
import {
  FindAlbumsResult,
  IAlbumRepository,
} from './album.repository.interface';
import { QueryAlbumDto } from '../dto/query-album.dto';

@Injectable()
export class PrismaAlbumRepository implements IAlbumRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createWithArtists(
    data: Prisma.AlbumCreateInput,
    artists?: { artistId: string; position?: number }[],
  ): Promise<Album> {
    return this.prisma.$transaction(async (tx) => {
      const album = await tx.album.create({ data });

      if (artists && artists.length > 0) {
        await tx.albumArtist.createMany({
          data: artists.map((a, idx) => ({
            albumId: album.id,
            artistId: a.artistId,
            position: a.position ?? idx + 1,
          })),
        });
      }

      return album;
    });
  }

  async findById(id: string): Promise<Album | null> {
    return this.prisma.album.findUnique({
      where: { id },
    });
  }

  async findWithDetails(id: string): Promise<any | null> {
    return this.prisma.album.findUnique({
      where: { id },
      include: {
        albumArtists: {
          include: {
            artist: true,
          },
          orderBy: { position: 'asc' },
        },
        tracks: {
          orderBy: [
            { discNumber: 'asc' },
            { trackNumber: 'asc' },
            { createdAt: 'asc' },
          ],
        },
      },
    });
  }

  async findAll(query: QueryAlbumDto): Promise<FindAlbumsResult> {
    const { page, limit, order, query: search, status } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.AlbumWhereInput = {};
    if (status) {
      where.status = status;
    }
    if (search) {
      where.title = { contains: search, mode: 'insensitive' };
    }

    const [items, total] = await Promise.all([
      this.prisma.album.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: order },
        include: {
          albumArtists: {
            include: { artist: true },
            orderBy: { position: 'asc' },
          },
        },
      }),
      this.prisma.album.count({ where }),
    ]);

    return { items, total };
  }

  async updateWithArtists(
    id: string,
    data: Prisma.AlbumUpdateInput,
    artists?: { artistId: string; position?: number }[],
  ): Promise<Album> {
    return this.prisma.$transaction(async (tx) => {
      const album = await tx.album.update({
        where: { id },
        data,
      });

      if (artists !== undefined) {
        // Replace album artists
        await tx.albumArtist.deleteMany({
          where: { albumId: id },
        });

        if (artists.length > 0) {
          await tx.albumArtist.createMany({
            data: artists.map((a, idx) => ({
              albumId: id,
              artistId: a.artistId,
              position: a.position ?? idx + 1,
            })),
          });
        }
      }

      return album;
    });
  }

  async delete(id: string): Promise<Album> {
    return this.prisma.album.delete({
      where: { id },
    });
  }
}
