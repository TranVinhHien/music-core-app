import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export enum SearchTargetType {
  ALL = 'all',
  TRACKS = 'tracks',
  ALBUMS = 'albums',
  ARTISTS = 'artists',
}

export class SearchCatalogQueryDto {
  @ApiPropertyOptional({
    description: 'Search keyword term across tracks, albums, and artists',
    example: 'shape of you',
  })
  @IsOptional()
  @IsString()
  query?: string;

  @ApiPropertyOptional({
    description: 'Alias for query parameter',
    example: 'shape of you',
  })
  @IsOptional()
  @IsString()
  q?: string;

  @ApiPropertyOptional({ default: 1, minimum: 1, description: 'Page number' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page: number = 1;

  @ApiPropertyOptional({
    default: 10,
    minimum: 1,
    maximum: 100,
    description: 'Number of items returned per object category',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit: number = 10;

  @ApiPropertyOptional({
    enum: SearchTargetType,
    default: SearchTargetType.ALL,
    description: 'Filter targets to search (all, tracks, albums, artists)',
  })
  @IsOptional()
  @IsEnum(SearchTargetType)
  type: SearchTargetType = SearchTargetType.ALL;

  get searchTerm(): string {
    return (this.query || this.q || '').trim();
  }

  get offset(): number {
    return (this.page - 1) * this.limit;
  }
}

export class SearchTrackArtistDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  name: string;

  @ApiProperty()
  role: string;

  @ApiProperty()
  position: number;

  @ApiPropertyOptional()
  imageUrl?: string | null;
}

export class SearchTrackAlbumDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  title: string;

  @ApiPropertyOptional()
  coverImageUrl?: string | null;
}

export class TrackSearchResultDto {
  @ApiProperty({ example: '87042a96-65dc-424a-9e19-07593fcbc891' })
  id: string;

  @ApiProperty({ example: 'Shape of You' })
  title: string;

  @ApiPropertyOptional({ example: 'shape-of-you' })
  slug?: string | null;

  @ApiPropertyOptional()
  albumId?: string | null;

  @ApiPropertyOptional({ example: 233712 })
  durationMs?: number | null;

  @ApiPropertyOptional({ example: 4 })
  trackNumber?: number | null;

  @ApiPropertyOptional({ example: 1 })
  discNumber?: number | null;

  @ApiPropertyOptional()
  releaseDate?: string | Date | null;

  @ApiPropertyOptional()
  coverImageUrl?: string | null;

  @ApiPropertyOptional()
  fileUrl?: string | null;

  @ApiProperty({ example: 'ACTIVE' })
  status: string;

  @ApiPropertyOptional({ type: () => SearchTrackAlbumDto })
  album?: SearchTrackAlbumDto | null;

  @ApiProperty({ type: [SearchTrackArtistDto] })
  artists: SearchTrackArtistDto[];

  @ApiPropertyOptional({ example: 8.5 })
  relevanceScore?: number;
}

export class SearchAlbumArtistDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  name: string;

  @ApiProperty()
  position: number;

  @ApiPropertyOptional()
  imageUrl?: string | null;
}

export class AlbumSearchResultDto {
  @ApiProperty({ example: '69f8c148-ee5f-4a6c-b3b4-4ecde1e523db' })
  id: string;

  @ApiProperty({ example: 'Divide (÷)' })
  title: string;

  @ApiPropertyOptional()
  releaseDate?: string | Date | null;

  @ApiPropertyOptional()
  coverImageUrl?: string | null;

  @ApiProperty({ example: 'ACTIVE' })
  status: string;

  @ApiProperty({ type: [SearchAlbumArtistDto] })
  artists: SearchAlbumArtistDto[];

  @ApiPropertyOptional({ example: 16 })
  totalTracks?: number;

  @ApiPropertyOptional({ example: 7.2 })
  relevanceScore?: number;
}

export class ArtistSearchResultDto {
  @ApiProperty({ example: 'a0f96894-3a21-4f10-9112-c2e4347ec05e' })
  id: string;

  @ApiProperty({ example: 'Ed Sheeran' })
  name: string;

  @ApiProperty({ example: 'ed sheeran' })
  normalizedName: string;

  @ApiPropertyOptional()
  bio?: string | null;

  @ApiPropertyOptional()
  imageUrl?: string | null;

  @ApiPropertyOptional({ example: 9.8 })
  relevanceScore?: number;
}

export class SearchSectionDto<T> {
  @ApiProperty({ description: 'List of matching items' })
  items: T[];

  @ApiProperty({ example: 42, description: 'Total number of matching records' })
  total: number;

  constructor(items: T[] = [], total: number = 0) {
    this.items = items;
    this.total = total;
  }

  // Alias for clients expecting .data
  get data(): T[] {
    return this.items;
  }
}

export class CatalogSearchResponseDto {
  @ApiProperty({ type: () => SearchSectionDto<TrackSearchResultDto> })
  tracks: SearchSectionDto<TrackSearchResultDto>;

  @ApiProperty({ type: () => SearchSectionDto<AlbumSearchResultDto> })
  albums: SearchSectionDto<AlbumSearchResultDto>;

  @ApiProperty({ type: () => SearchSectionDto<ArtistSearchResultDto> })
  artists: SearchSectionDto<ArtistSearchResultDto>;

  constructor(
    tracks: SearchSectionDto<TrackSearchResultDto>,
    albums: SearchSectionDto<AlbumSearchResultDto>,
    artists: SearchSectionDto<ArtistSearchResultDto>,
  ) {
    this.tracks = tracks;
    this.albums = albums;
    this.artists = artists;
  }
}

