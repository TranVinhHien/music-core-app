import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsArray, IsNumber, IsOptional, IsUUID, Max, Min } from 'class-validator';

export class GetNextTransitionDto {
  @ApiProperty({
    description: 'Current playing track UUID',
    example: '2d4e9b6b-4885-4586-a8e8-b2a5f1b880ed',
  })
  @IsUUID('all', { message: 'currentTrackId must be a valid UUID' })
  currentTrackId: string;

  @ApiPropertyOptional({
    description: 'Track IDs to exclude from candidate selection (array of UUIDs or comma-separated string)',
    type: [String],
    example: ['db121517-80fe-4cc9-bef1-c3c057ef8ab3'],
  })
  @IsOptional()
  @Transform(({ value }) => {
    if (value === undefined || value === null || value === '') {
      return [];
    }
    if (Array.isArray(value)) {
      return value;
    }
    if (typeof value === 'string') {
      return value
        .split(',')
        .map((id: string) => id.trim())
        .filter((id: string) => id.length > 0);
    }
    return [value];
  })
  @IsArray()
  @IsUUID('all', { each: true, message: 'Each excludeTrackId must be a valid UUID' })
  excludeTrackIds?: string[] = [];

  @ApiPropertyOptional({
    description: 'Softmax temperature parameter for controlled randomness (0.01 = deterministic, higher = more exploratory)',
    default: 0.7,
    minimum: 0.01,
    maximum: 5.0,
    example: 0.7,
  })
  @IsOptional()
  @Transform(({ value }) => {
    if (value === undefined || value === null || value === '') {
      return 0.7;
    }
    const parsed = Number(value);
    return isNaN(parsed) ? 0.7 : parsed;
  })
  @IsNumber({}, { message: 'temperature must be a number' })
  @Min(0.01, { message: 'temperature must be at least 0.01' })
  @Max(5.0, { message: 'temperature must not exceed 5.0' })
  temperature?: number = 0.7;
}
