import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class SaveTrackAudioAnalysisDto {
  @ApiProperty({ description: 'Start time of actual music in milliseconds (silence trimmed)', example: 812 })
  @IsInt()
  @Min(0)
  @IsNotEmpty()
  cueInMs: number;

  @ApiProperty({ description: 'End time / outro cue point to start transition in milliseconds', example: 198623 })
  @IsInt()
  @Min(0)
  @IsNotEmpty()
  cueOutMs: number;

  @ApiProperty({ description: 'Total audio duration in milliseconds', example: 204519 })
  @IsInt()
  @Min(0)
  @IsNotEmpty()
  durationMs: number;

  @ApiPropertyOptional({ description: 'Beats per minute', example: 172.3 })
  @IsOptional()
  @IsNumber()
  bpm?: number;

  @ApiPropertyOptional({ description: 'Timestamp of the first downbeat in milliseconds', example: 812 })
  @IsOptional()
  @IsInt()
  @Min(0)
  firstDownbeatMs?: number;

  @ApiPropertyOptional({ description: 'List of downbeat timestamps in milliseconds', example: [812, 2136, 3552] })
  @IsOptional()
  @IsArray()
  downbeats?: number[];

  @ApiPropertyOptional({ description: 'Musical key root', example: 'A#' })
  @IsOptional()
  @IsString()
  key?: string;

  @ApiPropertyOptional({ description: 'Musical scale (Major/Minor)', example: 'Minor' })
  @IsOptional()
  @IsString()
  scale?: string;

  @ApiPropertyOptional({ description: 'Harmonic Camelot wheel code', example: '3A' })
  @IsOptional()
  @IsString()
  camelotKey?: string;

  @ApiPropertyOptional({ description: 'Energy level (0.0 to 1.0)', example: 0.41 })
  @IsOptional()
  @IsNumber()
  energy?: number;

  @ApiPropertyOptional({ description: 'Loudness in LUFS (EBU R128)', example: -14.4 })
  @IsOptional()
  @IsNumber()
  loudnessLufs?: number;

  @ApiPropertyOptional({ description: 'Recommended transition strategy', example: 'SMOOTH_FADE' })
  @IsOptional()
  @IsString()
  recommendedTransition?: string;

  @ApiPropertyOptional({ description: 'Recommended crossfade duration in milliseconds', example: 5896 })
  @IsOptional()
  @IsInt()
  @Min(0)
  recommendedCrossfadeMs?: number;

  @ApiPropertyOptional({ description: 'Analysis status', default: 'COMPLETED' })
  @IsOptional()
  @IsString()
  analysisStatus?: string;

  @ApiPropertyOptional({ description: 'Error message if analysis failed' })
  @IsOptional()
  @IsString()
  errorMessage?: string;
}
