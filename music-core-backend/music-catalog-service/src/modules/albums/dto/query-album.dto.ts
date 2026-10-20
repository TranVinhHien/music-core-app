import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';
import { PaginationQueryDto } from '../../../common/dto/pagination.dto';

export class QueryAlbumDto extends PaginationQueryDto {
  @ApiPropertyOptional({ description: 'Filter by album status (e.g. ACTIVE, INACTIVE)' })
  @IsOptional()
  @IsString()
  status?: string;
}
