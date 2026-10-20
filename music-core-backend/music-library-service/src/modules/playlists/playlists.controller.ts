import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Put,
  Query,
  UnauthorizedException,
} from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { PlaylistsService } from './playlists.service';
import { CreatePlaylistDto } from './dto/create-playlist.dto';
import { UpdatePlaylistDto } from './dto/update-playlist.dto';
import { AddTrackToPlaylistDto } from './dto/add-track-to-playlist.dto';
import { QueryPlaylistDto } from './dto/query-playlist.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Playlists')
@Controller('playlists')
export class PlaylistsController {
  constructor(private readonly playlistsService: PlaylistsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new user playlist' })
  @ApiResponse({ status: 201, description: 'Playlist successfully created.' })
  create(
    @CurrentUser('id') userId: string | undefined,
    @Body() dto: CreatePlaylistDto,
  ) {
    if (!userId) {
      throw new UnauthorizedException('User identification header (X-User-ID) is missing');
    }
    return this.playlistsService.create(userId, dto);
  }

  @Get()
  @ApiOperation({ summary: 'Get paginated list of playlists' })
  findAll(
    @CurrentUser('id') userId: string | undefined,
    @Query() query: QueryPlaylistDto,
  ) {
    return this.playlistsService.findAll(userId || '', query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get playlist details with enriched track metadata from catalog' })
  findOne(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser('id') userId: string | undefined,
  ) {
    return this.playlistsService.findOne(id, userId);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update playlist metadata' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser('id') userId: string | undefined,
    @Body() dto: UpdatePlaylistDto,
  ) {
    if (!userId) {
      throw new UnauthorizedException('User identification header (X-User-ID) is missing');
    }
    return this.playlistsService.update(id, userId, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete playlist' })
  remove(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser('id') userId: string | undefined,
  ) {
    if (!userId) {
      throw new UnauthorizedException('User identification header (X-User-ID) is missing');
    }
    return this.playlistsService.remove(id, userId);
  }

  @Post(':id/tracks')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Add a track to playlist' })
  addTrack(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser('id') userId: string | undefined,
    @Body() dto: AddTrackToPlaylistDto,
  ) {
    if (!userId) {
      throw new UnauthorizedException('User identification header (X-User-ID) is missing');
    }
    return this.playlistsService.addTrack(id, userId, dto);
  }

  @Delete(':id/tracks/:trackId')
  @ApiOperation({ summary: 'Remove a track from playlist' })
  removeTrack(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('trackId', ParseUUIDPipe) trackId: string,
    @CurrentUser('id') userId: string | undefined,
  ) {
    if (!userId) {
      throw new UnauthorizedException('User identification header (X-User-ID) is missing');
    }
    return this.playlistsService.removeTrack(id, trackId, userId);
  }
}
