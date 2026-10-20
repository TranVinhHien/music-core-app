import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import {
  ALBUM_REPOSITORY_TOKEN,
  type IAlbumRepository,
} from './repositories/album.repository.interface';
import { CreateAlbumDto } from './dto/create-album.dto';
import { UpdateAlbumDto } from './dto/update-album.dto';
import { QueryAlbumDto } from './dto/query-album.dto';
import { PaginatedResult } from '../../common/dto/pagination.dto';

@Injectable()
export class AlbumsService {
  constructor(
    @Inject(ALBUM_REPOSITORY_TOKEN)
    private readonly albumRepository: IAlbumRepository,
  ) {}

  async create(dto: CreateAlbumDto) {
    const { artists, releaseDate, ...rest } = dto;
    return this.albumRepository.createWithArtists(
      {
        ...rest,
        releaseDate: releaseDate ? new Date(releaseDate) : undefined,
      },
      artists,
    );
  }

  async findAll(query: QueryAlbumDto) {
    const { items, total } = await this.albumRepository.findAll(query);
    return new PaginatedResult(items, total, query.page, query.limit);
  }

  async findOne(id: string) {
    const album = await this.albumRepository.findWithDetails(id);
    if (!album) {
      throw new NotFoundException(`Album with ID "${id}" not found`);
    }
    return album;
  }

  async update(id: string, dto: UpdateAlbumDto) {
    await this.findOne(id);
    const { artists, releaseDate, ...rest } = dto;
    const updateData: any = { ...rest };
    if (releaseDate !== undefined) {
      updateData.releaseDate = releaseDate ? new Date(releaseDate) : null;
    }
    return this.albumRepository.updateWithArtists(id, updateData, artists);
  }

  async remove(id: string) {
    await this.findOne(id);
    return this.albumRepository.delete(id);
  }
}
