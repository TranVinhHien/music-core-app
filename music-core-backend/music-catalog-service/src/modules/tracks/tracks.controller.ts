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
} from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { TracksService } from './tracks.service';
import { CreateTrackDto } from './dto/create-track.dto';
import { UpdateTrackDto } from './dto/update-track.dto';
import { QueryTrackDto } from './dto/query-track.dto';
import { SaveTrackAudioAnalysisDto } from './dto/save-track-audio-analysis.dto';

@ApiTags('Tracks')
@Controller('tracks')
export class TracksController {
  constructor(private readonly tracksService: TracksService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new track with artists, genres, and sources' })
  @ApiResponse({ status: 201, description: 'Track successfully created.' })
  create(@Body() dto: CreateTrackDto) {
    return this.tracksService.create(dto);
  }

  @Get()
  @ApiOperation({ summary: 'Get paginated list of tracks with filters' })
  findAll(@Query() query: QueryTrackDto) {
    return this.tracksService.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get track details with artists, genres, and sources' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.tracksService.findOne(id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update track by ID' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateTrackDto,
  ) {
    return this.tracksService.update(id, dto);
  }

  @Put(':id/audio-analysis')
  @ApiOperation({ summary: 'Save or update track audio transition analysis' })
  @ApiResponse({ status: 200, description: 'Track audio analysis saved successfully.' })
  saveAudioAnalysis(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveTrackAudioAnalysisDto,
  ) {
    return this.tracksService.saveAudioAnalysis(id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete track by ID' })
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.tracksService.remove(id);
  }
}
