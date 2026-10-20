import { Injectable } from '@nestjs/common';
import { Genre, Prisma } from '@prisma/client';
import { PrismaService } from '../../../database/prisma.service';
import {
  FindGenresResult,
  IGenreRepository,
} from './genre.repository.interface';
import { QueryGenreDto } from '../dto/query-genre.dto';

@Injectable()
export class PrismaGenreRepository implements IGenreRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(data: Prisma.GenreCreateInput): Promise<Genre> {
    return this.prisma.genre.create({ data });
  }

  async findById(id: string): Promise<Genre | null> {
    return this.prisma.genre.findUnique({
      where: { id },
    });
  }

  async findBySlug(slug: string): Promise<Genre | null> {
    return this.prisma.genre.findUnique({
      where: { slug },
    });
  }

  async findWithDetails(id: string): Promise<any | null> {
    return this.prisma.genre.findUnique({
      where: { id },
      include: {
        parent: true,
        children: true,
      },
    });
  }

  async findAll(query: QueryGenreDto): Promise<FindGenresResult> {
    const { page, limit, order, query: search, parentId, rootOnly } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.GenreWhereInput = {};
    if (rootOnly) {
      where.parentId = null;
    } else if (parentId) {
      where.parentId = parentId;
    }
    if (search) {
      where.name = { contains: search, mode: 'insensitive' };
    }

    const [items, total] = await Promise.all([
      this.prisma.genre.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: order },
        include: {
          children: true,
        },
      }),
      this.prisma.genre.count({ where }),
    ]);

    return { items, total };
  }

  async update(id: string, data: Prisma.GenreUpdateInput): Promise<Genre> {
    return this.prisma.genre.update({
      where: { id },
      data,
    });
  }

  async delete(id: string): Promise<Genre> {
    return this.prisma.genre.delete({
      where: { id },
    });
  }
}
