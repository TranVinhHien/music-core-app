import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsUUID } from 'class-validator';
import { PaginationQueryDto } from '../../../common/dto/pagination.dto';

export class QueryTrackDto extends PaginationQueryDto {
  @ApiPropertyOptional({ description: 'Filter by album UUID' })
  @IsOptional()
  @IsUUID()
  albumId?: string;

  @ApiPropertyOptional({ description: 'Filter by artist UUID' })
  @IsOptional()
  @IsUUID()
  artistId?: string;

  @ApiPropertyOptional({ description: 'Filter by genre UUID' })
  @IsOptional()
  @IsUUID()
  genreId?: string;

  @ApiPropertyOptional({ description: 'Filter by track status (e.g. ACTIVE, INACTIVE)' })
  @IsOptional()
  @IsString()
  status?: string;
}
