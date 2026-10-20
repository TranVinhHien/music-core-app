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

export class AlbumArtistInputDto {
  @ApiProperty({ description: 'Artist UUID' })
  @IsUUID()
  @IsNotEmpty()
  artistId: string;

  @ApiPropertyOptional({ description: 'Display position', default: 1 })
  @IsOptional()
  @IsInt()
  @Min(1)
  position?: number = 1;
}

export class CreateAlbumDto {
  @ApiProperty({ description: 'Album title', example: 'Chung Ta Cua Hien Tai' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  title: string;

  @ApiPropertyOptional({ description: 'Album release date (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  releaseDate?: string;

  @ApiPropertyOptional({ description: 'Cover image URL' })
  @IsOptional()
  @IsString()
  coverImageUrl?: string;

  @ApiPropertyOptional({ description: 'Album status', default: 'ACTIVE' })
  @IsOptional()
  @IsString()
  status?: string = 'ACTIVE';

  @ApiPropertyOptional({
    description: 'Artists credited on this album',
    type: [AlbumArtistInputDto],
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => AlbumArtistInputDto)
  artists?: AlbumArtistInputDto[];
}
