import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsNotEmpty, IsOptional, IsUUID, Min } from 'class-validator';

export class AddTrackToPlaylistDto {
  @ApiProperty({ description: 'Track UUID from catalog service' })
  @IsUUID()
  @IsNotEmpty()
  trackId: string;

  @ApiPropertyOptional({ description: 'Display position in playlist (auto-assigned if omitted)' })
  @IsOptional()
  @IsInt()
  @Min(1)
  position?: number;
}
