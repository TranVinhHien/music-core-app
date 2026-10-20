import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  PLAYLIST_REPOSITORY_TOKEN,
  type IPlaylistRepository,
} from './repositories/playlist.repository.interface';
import { CatalogClient } from '../../integrations/catalog/catalog.client';
import { CreatePlaylistDto } from './dto/create-playlist.dto';
import { UpdatePlaylistDto } from './dto/update-playlist.dto';
import { AddTrackToPlaylistDto } from './dto/add-track-to-playlist.dto';
import { QueryPlaylistDto } from './dto/query-playlist.dto';
import { PaginatedResult } from '../../common/dto/pagination.dto';

@Injectable()
export class PlaylistsService {
  constructor(
    @Inject(PLAYLIST_REPOSITORY_TOKEN)
    private readonly playlistRepository: IPlaylistRepository,
    private readonly catalogClient: CatalogClient,
  ) {}

  async create(userId: string, dto: CreatePlaylistDto) {
    return this.playlistRepository.create({
      userId,
      name: dto.name,
      description: dto.description,
      coverImageUrl: dto.coverImageUrl,
      visibility: dto.visibility || 'PRIVATE',
    });
  }

  async findAll(currentUserId: string, query: QueryPlaylistDto) {
    const { items, total } = await this.playlistRepository.findAll(
      currentUserId,
      query,
    );
    return new PaginatedResult(items, total, query.page, query.limit);
  }

  async findOne(id: string, currentUserId?: string) {
    const playlist = await this.playlistRepository.findById(id);
    if (!playlist) {
      throw new NotFoundException(`Playlist with ID "${id}" not found`);
    }

    if (playlist.visibility === 'PRIVATE' && playlist.userId !== currentUserId) {
      throw new ForbiddenException('You do not have access to this private playlist');
    }

    // Enrich tracks information from Catalog Service
    const trackIds = playlist.tracks.map((pt: any) => pt.trackId);
    const trackMap = await this.catalogClient.getTracksByIds(trackIds);

    const enrichedTracks = playlist.tracks.map((pt: any) => ({
      playlistId: pt.playlistId,
      trackId: pt.trackId,
      position: pt.position,
      addedAt: pt.addedAt,
      track: trackMap.get(pt.trackId) || null,
    }));

    return {
      ...playlist,
      tracks: enrichedTracks,
    };
  }

  async update(id: string, userId: string, dto: UpdatePlaylistDto) {
    const playlist = await this.playlistRepository.findById(id);
    if (!playlist) {
      throw new NotFoundException(`Playlist with ID "${id}" not found`);
    }
    if (playlist.userId !== userId) {
      throw new ForbiddenException('You are not allowed to update this playlist');
    }

    return this.playlistRepository.update(id, dto);
  }

  async remove(id: string, userId: string) {
    const playlist = await this.playlistRepository.findById(id);
    if (!playlist) {
      throw new NotFoundException(`Playlist with ID "${id}" not found`);
    }
    if (playlist.userId !== userId) {
      throw new ForbiddenException('You are not allowed to delete this playlist');
    }

    return this.playlistRepository.delete(id);
  }

  async addTrack(id: string, userId: string, dto: AddTrackToPlaylistDto) {
    const playlist = await this.playlistRepository.findById(id);
    if (!playlist) {
      throw new NotFoundException(`Playlist with ID "${id}" not found`);
    }
    if (playlist.userId !== userId) {
      throw new ForbiddenException('You are not allowed to modify this playlist');
    }

    // Verify track exists in catalog
    const track = await this.catalogClient.getTrackById(dto.trackId);
    if (!track) {
      throw new NotFoundException(`Track with ID "${dto.trackId}" not found in catalog`);
    }

    const hasTrack = await this.playlistRepository.hasTrack(id, dto.trackId);
    if (hasTrack) {
      throw new ConflictException('This track is already in the playlist');
    }

    let position = dto.position;
    if (position === undefined) {
      const maxPos = await this.playlistRepository.getMaxPosition(id);
      position = maxPos + 1;
    }

    const playlistTrack = await this.playlistRepository.addTrack(
      id,
      dto.trackId,
      position,
    );

    return {
      ...playlistTrack,
      track,
    };
  }

  async removeTrack(id: string, trackId: string, userId: string) {
    const playlist = await this.playlistRepository.findById(id);
    if (!playlist) {
      throw new NotFoundException(`Playlist with ID "${id}" not found`);
    }
    if (playlist.userId !== userId) {
      throw new ForbiddenException('You are not allowed to modify this playlist');
    }

    const hasTrack = await this.playlistRepository.hasTrack(id, trackId);
    if (!hasTrack) {
      throw new NotFoundException('Track not found in this playlist');
    }

    return this.playlistRepository.removeTrack(id, trackId);
  }
}
