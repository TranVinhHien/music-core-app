import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsDateString,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

export class TrackArtistInputDto {
  @ApiProperty({ description: 'Artist UUID' })
  @IsUUID()
  @IsNotEmpty()
  artistId: string;

  @ApiPropertyOptional({ description: 'Role (e.g. PRIMARY, FEAT)', default: 'PRIMARY' })
  @IsOptional()
  @IsString()
  role?: string = 'PRIMARY';

  @ApiPropertyOptional({ description: 'Display position', default: 1 })
  @IsOptional()
  @IsInt()
  @Min(1)
  position?: number = 1;
}

export class TrackSourceInputDto {
  @ApiProperty({ description: 'Platform source (e.g. YOUTUBE, SPOTIFY, SOUNDCLOUD)' })
  @IsString()
  @IsNotEmpty()
  source: string;

  @ApiProperty({ description: 'External ID on platform' })
  @IsString()
  @IsNotEmpty()
  externalId: string;

  @ApiPropertyOptional({ description: 'Direct URL on platform' })
  @IsOptional()
  @IsString()
  externalUrl?: string;
}

export class CreateTrackDto {
  @ApiProperty({ description: 'Track title', example: 'Chung Ta Cua Tuong Lai' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  title: string;

  @ApiPropertyOptional({ description: 'URL-friendly slug (auto-generated if omitted)' })
  @IsOptional()
  @IsString()
  slug?: string;

  @ApiPropertyOptional({ description: 'Associated album UUID' })
  @IsOptional()
  @IsUUID()
  albumId?: string;

  @ApiPropertyOptional({ description: 'Duration in milliseconds', example: 215000 })
  @IsOptional()
  @IsInt()
  @Min(0)
  durationMs?: number;

  @ApiPropertyOptional({ description: 'Track position within album', example: 1 })
  @IsOptional()
  @IsInt()
  @Min(1)
  trackNumber?: number;

  @ApiPropertyOptional({ description: 'Disc number for multi-disc album', default: 1 })
  @IsOptional()
  @IsInt()
  @Min(1)
  discNumber?: number;

  @ApiPropertyOptional({ description: 'Release date (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  releaseDate?: string;

  @ApiPropertyOptional({ description: 'Audio file URL or storage path', example: 'https://example.com/audio/song.mp3' })
  @IsOptional()
  @IsString()
  fileUrl?: string;

  @ApiPropertyOptional({ description: 'Track status', default: 'ACTIVE' })
  @IsOptional()
  @IsString()
  status?: string = 'ACTIVE';

  @ApiPropertyOptional({
    description: 'Artists credited on this track',
    type: [TrackArtistInputDto],
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => TrackArtistInputDto)
  artists?: TrackArtistInputDto[];

  @ApiPropertyOptional({
    description: 'Genre UUIDs associated with this track',
    type: [String],
  })
  @IsOptional()
  @IsArray()
  @IsUUID('all', { each: true })
  genreIds?: string[];

  @ApiPropertyOptional({
    description: 'External sources for this track',
    type: [TrackSourceInputDto],
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => TrackSourceInputDto)
  sources?: TrackSourceInputDto[];
}
