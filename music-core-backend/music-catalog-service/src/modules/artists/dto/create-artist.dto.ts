import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateArtistDto {
  @ApiProperty({ description: 'Artist display name', example: 'Son Tung M-TP' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  name: string;

  @ApiPropertyOptional({ description: 'Artist biography' })
  @IsOptional()
  @IsString()
  bio?: string;

  @ApiPropertyOptional({ description: 'Artist profile image URL' })
  @IsOptional()
  @IsString()
  imageUrl?: string;
}
