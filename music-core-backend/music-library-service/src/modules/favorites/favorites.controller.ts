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
  Query,
  UnauthorizedException,
} from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { FavoritesService } from './favorites.service';
import { AddFavoriteTrackDto } from './dto/add-favorite-track.dto';
import { QueryFavoriteTrackDto } from './dto/query-favorite.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Favorites')
@Controller('favorites')
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  @Post('tracks')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Add a track to user favorites' })
  @ApiResponse({ status: 201, description: 'Track added to favorites.' })
  addFavorite(
    @CurrentUser('id') userId: string | undefined,
    @Body() dto: AddFavoriteTrackDto,
  ) {
    if (!userId) {
      throw new UnauthorizedException('User identification header (X-User-ID) is missing');
    }
    return this.favoritesService.add(userId, dto);
  }

  @Post('tracks/:trackId')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Add a track to user favorites by path param' })
  addFavoriteByParam(
    @CurrentUser('id') userId: string | undefined,
    @Param('trackId', ParseUUIDPipe) trackId: string,
  ) {
    if (!userId) {
      throw new UnauthorizedException('User identification header (X-User-ID) is missing');
    }
    return this.favoritesService.add(userId, { trackId });
  }

  @Delete('tracks/:trackId')
  @ApiOperation({ summary: 'Remove a track from user favorites' })
  removeFavorite(
    @CurrentUser('id') userId: string | undefined,
    @Param('trackId', ParseUUIDPipe) trackId: string,
  ) {
    if (!userId) {
      throw new UnauthorizedException('User identification header (X-User-ID) is missing');
    }
    return this.favoritesService.remove(userId, trackId);
  }

  @Get('tracks')
  @ApiOperation({ summary: 'Get paginated list of user favorite tracks with full catalog metadata' })
  findAll(
    @CurrentUser('id') userId: string | undefined,
    @Query() query: QueryFavoriteTrackDto,
  ) {
    if (!userId) {
      throw new UnauthorizedException('User identification header (X-User-ID) is missing');
    }
    return this.favoritesService.findAll(userId, query);
  }
}
