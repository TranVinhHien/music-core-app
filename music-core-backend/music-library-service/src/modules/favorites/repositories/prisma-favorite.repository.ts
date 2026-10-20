import { Injectable } from '@nestjs/common';
import { UserFavoriteTrack } from '@prisma/client';
import { PrismaService } from '../../../database/prisma.service';
import {
  FindFavoritesResult,
  IFavoriteRepository,
} from './favorite.repository.interface';
import { QueryFavoriteTrackDto } from '../dto/query-favorite.dto';

@Injectable()
export class PrismaFavoriteRepository implements IFavoriteRepository {
  constructor(private readonly prisma: PrismaService) {}

  async add(userId: string, trackId: string): Promise<UserFavoriteTrack> {
    return this.prisma.userFavoriteTrack.create({
      data: {
        userId,
        trackId,
      },
    });
  }

  async remove(userId: string, trackId: string): Promise<UserFavoriteTrack> {
    return this.prisma.userFavoriteTrack.delete({
      where: {
        userId_trackId: {
          userId,
          trackId,
        },
      },
    });
  }

  async findAll(
    userId: string,
    query: QueryFavoriteTrackDto,
  ): Promise<FindFavoritesResult> {
    const { page, limit, order } = query;
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      this.prisma.userFavoriteTrack.findMany({
        where: { userId },
        skip,
        take: limit,
        orderBy: { createdAt: order },
      }),
      this.prisma.userFavoriteTrack.count({ where: { userId } }),
    ]);

    return { items, total };
  }

  async isFavorite(userId: string, trackId: string): Promise<boolean> {
    const count = await this.prisma.userFavoriteTrack.count({
      where: { userId, trackId },
    });
    return count > 0;
  }
}
