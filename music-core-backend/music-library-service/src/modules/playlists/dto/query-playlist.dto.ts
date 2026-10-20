import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsUUID } from 'class-validator';
import { PaginationQueryDto } from '../../../common/dto/pagination.dto';
import { PlaylistVisibility } from './create-playlist.dto';

export class QueryPlaylistDto extends PaginationQueryDto {
  @ApiPropertyOptional({ enum: PlaylistVisibility })
  @IsOptional()
  @IsEnum(PlaylistVisibility)
  visibility?: PlaylistVisibility;

  @ApiPropertyOptional({ description: 'Filter by specific user UUID' })
  @IsOptional()
  @IsUUID()
  userId?: string;
}
