import { Injectable } from '@nestjs/common';
import { Artist, Prisma } from '@prisma/client';
import { PrismaService } from '../../../database/prisma.service';
import {
  FindArtistsResult,
  IArtistRepository,
} from './artist.repository.interface';
import { QueryArtistDto } from '../dto/query-artist.dto';
import { normalizeString } from '../../../common/utils/text.util';

@Injectable()
export class PrismaArtistRepository implements IArtistRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(data: Prisma.ArtistCreateInput): Promise<Artist> {
    return this.prisma.artist.create({ data });
  }

  async findById(id: string): Promise<Artist | null> {
    return this.prisma.artist.findUnique({
      where: { id },
    });
  }

  async findWithDetails(id: string): Promise<any | null> {
    return this.prisma.artist.findUnique({
      where: { id },
      include: {
        albumArtists: {
          include: {
            album: true,
          },
          orderBy: { position: 'asc' },
        },
        trackArtists: {
          include: {
            track: true,
          },
          orderBy: { position: 'asc' },
        },
      },
    });
  }

  async findAll(query: QueryArtistDto): Promise<FindArtistsResult> {
    const { page, limit, order, query: search } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.ArtistWhereInput = {};
    if (search) {
      const normalized = normalizeString(search);
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { normalizedName: { contains: normalized } },
      ];
    }

    const [items, total] = await Promise.all([
      this.prisma.artist.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: order },
      }),
      this.prisma.artist.count({ where }),
    ]);

    return { items, total };
  }

  async update(id: string, data: Prisma.ArtistUpdateInput): Promise<Artist> {
    return this.prisma.artist.update({
      where: { id },
      data,
    });
  }

  async delete(id: string): Promise<Artist> {
    return this.prisma.artist.delete({
      where: { id },
    });
  }
}
