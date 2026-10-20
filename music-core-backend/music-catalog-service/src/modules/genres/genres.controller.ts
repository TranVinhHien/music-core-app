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
import { GenresService } from './genres.service';
import { CreateGenreDto } from './dto/create-genre.dto';
import { UpdateGenreDto } from './dto/update-genre.dto';
import { QueryGenreDto } from './dto/query-genre.dto';

@ApiTags('Genres')
@Controller('genres')
export class GenresController {
  constructor(private readonly genresService: GenresService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new genre' })
  @ApiResponse({ status: 201, description: 'Genre successfully created.' })
  create(@Body() dto: CreateGenreDto) {
    return this.genresService.create(dto);
  }

  @Get()
  @ApiOperation({ summary: 'Get paginated list of genres' })
  findAll(@Query() query: QueryGenreDto) {
    return this.genresService.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get genre details with sub-genres' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.genresService.findOne(id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update genre by ID' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateGenreDto,
  ) {
    return this.genresService.update(id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete genre by ID' })
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.genresService.remove(id);
  }
}
