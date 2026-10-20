import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsUUID } from 'class-validator';

export class AddFavoriteTrackDto {
  @ApiProperty({ description: 'Track UUID from catalog service' })
  @IsUUID()
  @IsNotEmpty()
  trackId: string;
}
