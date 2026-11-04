import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, IsUUID, Max, Min } from 'class-validator';

export class QueryRandomTrackDto {
  @ApiPropertyOptional({
    description: 'Track ID to exclude (e.g. currently playing song)',
    example: '87042a96-65dc-424a-9e19-07593fcbc891',
  })
  @IsOptional()
  @IsUUID()
  excludeTrackId?: string;

  @ApiPropertyOptional({
    description: 'Comma-separated list of track IDs to exclude (e.g. recently played history)',
    example: '87042a96-65dc-424a-9e19-07593fcbc891,e1f60b2a-aeba-4cad-8dc7-20bc1a25ff2f',
  })
  @IsOptional()
  @IsString()
  excludeTrackIds?: string;

  @ApiPropertyOptional({
    description: 'Filter random track by specific genre UUID',
  })
  @IsOptional()
  @IsUUID()
  genreId?: string;

  @ApiPropertyOptional({
    default: 1,
    minimum: 1,
    maximum: 10,
    description: 'Number of random tracks to return (default 1)',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(10)
  limit: number = 1;

  get excludedIds(): string[] {
    const ids = new Set<string>();
    if (this.excludeTrackId) {
      ids.add(this.excludeTrackId.trim());
    }
    if (this.excludeTrackIds) {
      this.excludeTrackIds
        .split(',')
        .map((s) => s.trim())
        .filter((s) => s.length > 0)
        .forEach((id) => ids.add(id));
    }
    return Array.from(ids);
  }
}

