import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import {
  type ITrackRepository,
  TRACK_REPOSITORY_TOKEN,
} from './repositories/track.repository.interface';
import { CreateTrackDto } from './dto/create-track.dto';
import { UpdateTrackDto } from './dto/update-track.dto';
import { QueryTrackDto } from './dto/query-track.dto';
import { SaveTrackAudioAnalysisDto } from './dto/save-track-audio-analysis.dto';
import { PaginatedResult } from '../../common/dto/pagination.dto';
import { slugify } from '../../common/utils/text.util';

@Injectable()
export class TracksService {
  constructor(
    @Inject(TRACK_REPOSITORY_TOKEN)
    private readonly trackRepository: ITrackRepository,
  ) {}

  async create(dto: CreateTrackDto) {
    const { artists, genreIds, sources, releaseDate, slug, ...rest } = dto;
    const finalSlug = slug || slugify(dto.title);

    return this.trackRepository.createWithRelations(
      {
        ...rest,
        slug: finalSlug,
        releaseDate: releaseDate ? new Date(releaseDate) : undefined,
      },
      artists,
      genreIds,
      sources,
    );
  }

  async findAll(query: QueryTrackDto) {
    const { items, total } = await this.trackRepository.findAll(query);
    return new PaginatedResult(items, total, query.page, query.limit);
  }

  async findOne(id: string) {
    const track = await this.trackRepository.findWithDetails(id);
    if (!track) {
      throw new NotFoundException(`Track with ID "${id}" not found`);
    }
    return track;
  }

  async update(id: string, dto: UpdateTrackDto) {
    await this.findOne(id);
    const { artists, genreIds, sources, releaseDate, slug, title, ...rest } =
      dto;

    const updateData: any = { ...rest };
    if (title) {
      updateData.title = title;
      if (!slug) {
        updateData.slug = slugify(title);
      }
    }
    if (slug) {
      updateData.slug = slug;
    }
    if (releaseDate !== undefined) {
      updateData.releaseDate = releaseDate ? new Date(releaseDate) : null;
    }

    return this.trackRepository.updateWithRelations(
      id,
      updateData,
      artists,
      genreIds,
      sources,
    );
  }

  async remove(id: string) {
    await this.findOne(id);
    return this.trackRepository.delete(id);
  }

  async saveAudioAnalysis(id: string, dto: SaveTrackAudioAnalysisDto) {
    await this.findOne(id);
    return this.trackRepository.upsertAudioAnalysis(id, dto);
  }
}
