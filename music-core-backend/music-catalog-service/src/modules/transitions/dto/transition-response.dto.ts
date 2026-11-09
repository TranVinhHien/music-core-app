import { ApiProperty } from '@nestjs/swagger';

export class CurrentTrackTransitionDto {
  @ApiProperty({ example: '2d4e9b6b-4885-4586-a8e8-b2a5f1b880ed' })
  id: string;

  @ApiProperty({ example: 'Trái Tim Bên Lề' })
  title: string;

  @ApiProperty({ example: 313862 })
  durationMs: number;

  @ApiProperty({ example: 136 })
  bpm: number;

  @ApiProperty({ example: '9A' })
  camelotKey: string;

  @ApiProperty({ example: -23.1 })
  loudnessLufs: number;

  @ApiProperty({
    description: 'Timestamp in current track to trigger crossfade transition (cueOutMs)',
    example: 303624,
  })
  triggerTransitionAtMs: number;

  @ApiProperty({
    description: 'Timestamp in current track to stop playback completely',
    example: 313862,
  })
  stopPlaybackAtMs: number;
}

export class NextTrackTransitionDto {
  @ApiProperty({ example: 'cbda8cd0-45ad-4b49-9f22-32767f002302' })
  id: string;

  @ApiProperty({ example: 'Không' })
  title: string;

  @ApiProperty({
    nullable: true,
    example: 'https://cdn.example.com/audio/khong.m4a',
  })
  fileUrl: string | null;

  @ApiProperty({
    nullable: true,
    example: 'https://cdn.example.com/cover/khong.jpg',
  })
  coverImageUrl: string | null;

  @ApiProperty({ type: [String], example: ['Elvis Phương'] })
  artists: string[];

  @ApiProperty({ example: 245000 })
  durationMs: number;

  @ApiProperty({ example: 136 })
  bpm: number;

  @ApiProperty({ example: '9A' })
  camelotKey: string;

  @ApiProperty({
    description: 'Playback offset in next track to start playback from (cueInMs or firstDownbeatMs)',
    example: 1200,
  })
  startPlaybackAtMs: number;

  @ApiProperty({
    description: 'First downbeat position in next track for beat-matching alignment',
    example: 2400,
  })
  targetDownbeatMs: number;
}

export class TransitionPlanDto {
  @ApiProperty({
    description: 'Recommended transition strategy (e.g. SMOOTH_FADE, BEAT_SYNC_CUT)',
    example: 'SMOOTH_FADE',
  })
  transitionType: string;

  @ApiProperty({
    description: 'Crossfade duration in milliseconds',
    example: 8000,
  })
  crossfadeDurationMs: number;

  @ApiProperty({
    description: 'Timestamp in current track to begin pre-buffering next track',
    example: 293624,
  })
  preBufferAtMs: number;

  @ApiProperty({
    description: 'Volume gain compensation in dB to balance perceived loudness between tracks',
    example: 0.5,
  })
  volumeBalanceGainDb: number;

  @ApiProperty({
    description: 'Ratio of next track BPM to current track BPM',
    example: 1.0,
  })
  tempoRatio: number;

  @ApiProperty({
    description: 'Overall compatibility score combining Camelot, BPM, and energy (0 to 100)',
    example: 95.5,
  })
  compatibilityScore: number;
}

export class TransitionResponseDto {
  @ApiProperty({ type: CurrentTrackTransitionDto })
  currentTrack: CurrentTrackTransitionDto;

  @ApiProperty({ type: NextTrackTransitionDto })
  nextTrack: NextTrackTransitionDto;

  @ApiProperty({ type: TransitionPlanDto })
  transitionPlan: TransitionPlanDto;
}
