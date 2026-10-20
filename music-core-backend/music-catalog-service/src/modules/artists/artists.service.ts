import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import {
  ARTIST_REPOSITORY_TOKEN,
  type IArtistRepository,
} from './repositories/artist.repository.interface';
import { CreateArtistDto } from './dto/create-artist.dto';
import { UpdateArtistDto } from './dto/update-artist.dto';
import { QueryArtistDto } from './dto/query-artist.dto';
import { PaginatedResult } from '../../common/dto/pagination.dto';
import { normalizeString } from '../../common/utils/text.util';

@Injectable()
export class ArtistsService {
  constructor(
    @Inject(ARTIST_REPOSITORY_TOKEN)
    private readonly artistRepository: IArtistRepository,
  ) {}

  async create(dto: CreateArtistDto) {
    const normalizedName = normalizeString(dto.name);
    return this.artistRepository.create({
      name: dto.name,
      normalizedName,
      bio: dto.bio,
      imageUrl: dto.imageUrl,
    });
  }

  async findAll(query: QueryArtistDto) {
    const { items, total } = await this.artistRepository.findAll(query);
    return new PaginatedResult(items, total, query.page, query.limit);
  }

  async findOne(id: string) {
    const artist = await this.artistRepository.findWithDetails(id);
    if (!artist) {
      throw new NotFoundException(`Artist with ID "${id}" not found`);
    }
    return artist;
  }

  async update(id: string, dto: UpdateArtistDto) {
    await this.findOne(id);
    const data: any = { ...dto };
    if (dto.name) {
      data.normalizedName = normalizeString(dto.name);
    }
    return this.artistRepository.update(id, data);
  }

  async remove(id: string) {
    await this.findOne(id);
    return this.artistRepository.delete(id);
  }
}
