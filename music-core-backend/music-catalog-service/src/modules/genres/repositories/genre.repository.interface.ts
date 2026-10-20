import { Genre, Prisma } from '@prisma/client';
import { QueryGenreDto } from '../dto/query-genre.dto';

export interface FindGenresResult {
  items: Genre[];
  total: number;
}

export const GENRE_REPOSITORY_TOKEN = Symbol('IGenreRepository');

export interface IGenreRepository {
  create(data: Prisma.GenreCreateInput): Promise<Genre>;
  findById(id: string): Promise<Genre | null>;
  findBySlug(slug: string): Promise<Genre | null>;
  findWithDetails(id: string): Promise<any | null>;
  findAll(query: QueryGenreDto): Promise<FindGenresResult>;
  update(id: string, data: Prisma.GenreUpdateInput): Promise<Genre>;
  delete(id: string): Promise<Genre>;
}
