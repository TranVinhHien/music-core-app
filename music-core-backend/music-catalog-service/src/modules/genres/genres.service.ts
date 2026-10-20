import {
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  GENRE_REPOSITORY_TOKEN,
  type IGenreRepository,
} from './repositories/genre.repository.interface';
import { CreateGenreDto } from './dto/create-genre.dto';
import { UpdateGenreDto } from './dto/update-genre.dto';
import { QueryGenreDto } from './dto/query-genre.dto';
import { PaginatedResult } from '../../common/dto/pagination.dto';
import { slugify } from '../../common/utils/text.util';

@Injectable()
export class GenresService {
  constructor(
    @Inject(GENRE_REPOSITORY_TOKEN)
    private readonly genreRepository: IGenreRepository,
  ) {}

  async create(dto: CreateGenreDto) {
    const finalSlug = dto.slug || slugify(dto.name);

    const existing = await this.genreRepository.findBySlug(finalSlug);
    if (existing) {
      throw new ConflictException(
        `Genre with slug "${finalSlug}" already exists`,
      );
    }

    if (dto.parentId) {
      const parent = await this.genreRepository.findById(dto.parentId);
      if (!parent) {
        throw new NotFoundException(
          `Parent genre with ID "${dto.parentId}" not found`,
        );
      }
    }

    return this.genreRepository.create({
      name: dto.name,
      slug: finalSlug,
      parent: dto.parentId ? { connect: { id: dto.parentId } } : undefined,
    });
  }

  async findAll(query: QueryGenreDto) {
    const { items, total } = await this.genreRepository.findAll(query);
    return new PaginatedResult(items, total, query.page, query.limit);
  }

  async findOne(id: string) {
    const genre = await this.genreRepository.findWithDetails(id);
    if (!genre) {
      throw new NotFoundException(`Genre with ID "${id}" not found`);
    }
    return genre;
  }

  async update(id: string, dto: UpdateGenreDto) {
    await this.findOne(id);

    const updateData: any = {};
    if (dto.name) {
      updateData.name = dto.name;
    }
    if (dto.slug || dto.name) {
      const newSlug = dto.slug || slugify(dto.name!);
      const existing = await this.genreRepository.findBySlug(newSlug);
      if (existing && existing.id !== id) {
        throw new ConflictException(
          `Genre with slug "${newSlug}" already exists`,
        );
      }
      updateData.slug = newSlug;
    }

    if (dto.parentId !== undefined) {
      if (dto.parentId === id) {
        throw new ConflictException('A genre cannot be its own parent');
      }
      if (dto.parentId) {
        const parent = await this.genreRepository.findById(dto.parentId);
        if (!parent) {
          throw new NotFoundException(
            `Parent genre with ID "${dto.parentId}" not found`,
          );
        }
        updateData.parent = { connect: { id: dto.parentId } };
      } else {
        updateData.parent = { disconnect: true };
      }
    }

    return this.genreRepository.update(id, updateData);
  }

  async remove(id: string) {
    await this.findOne(id);
    return this.genreRepository.delete(id);
  }
}
