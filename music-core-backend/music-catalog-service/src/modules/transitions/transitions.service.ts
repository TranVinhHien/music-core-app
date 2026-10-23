import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { GetNextTransitionDto } from './dto/get-next-transition.dto';
import {
  CurrentTrackTransitionDto,
  NextTrackTransitionDto,
  TransitionPlanDto,
  TransitionResponseDto,
} from './dto/transition-response.dto';

interface CandidateEvaluation {
  track: any;
  camelotScore: number;
  bpmScore: number;
  energyScore: number;
  totalScore: number;
}

@Injectable()
export class TransitionsService {
  private readonly logger = new Logger(TransitionsService.name);

  constructor(private readonly prisma: PrismaService) {}

  async getNextTransition(dto: GetNextTransitionDto): Promise<TransitionResponseDto> {
    const { currentTrackId, excludeTrackIds = [], temperature = 0.7 } = dto;

    // 1. Fetch current track with its audioAnalysis
    const currentTrack = await this.prisma.track.findUnique({
      where: { id: currentTrackId },
      include: {
        audioAnalysis: true,
        trackArtists: {
          include: { artist: true },
          orderBy: { position: 'asc' },
        },
      },
    });

    if (!currentTrack) {
      throw new NotFoundException(`Current track with ID "${currentTrackId}" not found`);
    }

    const currentAnalysis = currentTrack.audioAnalysis;
    if (!currentAnalysis || currentAnalysis.analysisStatus !== 'COMPLETED') {
      throw new BadRequestException(
        `Current track "${currentTrack.title}" (${currentTrackId}) audio analysis is missing or not completed`,
      );
    }

    // 2. Fetch candidate tracks from DB
    const excludedIds = [currentTrackId, ...(excludeTrackIds || [])];

    let candidates = await this.prisma.track.findMany({
      where: {
        status: 'ACTIVE',
        id: {
          notIn: excludedIds,
        },
        audioAnalysis: {
          analysisStatus: 'COMPLETED',
        },
      },
      include: {
        audioAnalysis: true,
        trackArtists: {
          include: { artist: true },
          orderBy: { position: 'asc' },
        },
      },
    });

    if (!candidates || candidates.length === 0) {
      this.logger.warn(
        `All candidates were excluded by excludeTrackIds (${excludedIds.length} tracks). Falling back to active tracks excluding currentTrackId.`,
      );
      candidates = await this.prisma.track.findMany({
        where: {
          status: 'ACTIVE',
          id: {
            not: currentTrackId,
          },
          audioAnalysis: {
            analysisStatus: 'COMPLETED',
          },
        },
        include: {
          audioAnalysis: true,
          trackArtists: {
            include: { artist: true },
            orderBy: { position: 'asc' },
          },
        },
      });
    }

    if (!candidates || candidates.length === 0) {
      throw new NotFoundException('No eligible transition candidate tracks found');
    }

    // 3. Calculate compatibility scores for all candidates
    const evaluatedCandidates: CandidateEvaluation[] = candidates.map((candidate) => {
      const nextAnalysis = candidate.audioAnalysis!;
      const camelotScore = this.calculateCamelotScore(
        currentAnalysis.camelotKey,
        nextAnalysis.camelotKey,
      );
      const bpmScore = this.calculateBpmScore(
        currentAnalysis.bpm,
        nextAnalysis.bpm,
      );
      const energyScore = this.calculateEnergyScore(
        currentAnalysis.energy,
        nextAnalysis.energy,
      );

      const totalScore = Math.round((camelotScore + bpmScore + energyScore) * 10) / 10;

      return {
        track: candidate,
        camelotScore,
        bpmScore,
        energyScore,
        totalScore,
      };
    });

    // 4. Softmax probability selection with temperature
    const selectedEvaluation = this.selectCandidateBySoftmax(
      evaluatedCandidates,
      temperature,
    );

    const selectedTrack = selectedEvaluation.track;
    const selectedAnalysis = selectedTrack.audioAnalysis!;

    // 5. Calculate transition timing & parameters
    const currentDurationMs =
      currentTrack.durationMs ?? currentAnalysis.durationMs ?? 0;
    const triggerTransitionAtMs =
      currentAnalysis.cueOutMs ??
      (currentDurationMs > 10000 ? currentDurationMs - 10000 : 0);
    const crossfadeDurationMs = currentAnalysis.recommendedCrossfadeMs || 8000;
    const stopPlaybackAtMs = Math.min(
      triggerTransitionAtMs + crossfadeDurationMs,
      currentDurationMs > 0 ? currentDurationMs : triggerTransitionAtMs + crossfadeDurationMs,
    );
    const preBufferAtMs = Math.max(0, triggerTransitionAtMs - 10000);

    const startPlaybackAtMs =
      selectedAnalysis.cueInMs ?? selectedAnalysis.firstDownbeatMs ?? 0;
    const targetDownbeatMs =
      selectedAnalysis.firstDownbeatMs ?? selectedAnalysis.cueInMs ?? 0;

    const currentLufs = currentAnalysis.loudnessLufs ?? -14;
    const nextLufs = selectedAnalysis.loudnessLufs ?? -14;
    const volumeBalanceGainDb = Math.round((currentLufs - nextLufs) * 10) / 10;

    const currentBpm = currentAnalysis.bpm;
    const nextBpm = selectedAnalysis.bpm;
    const tempoRatio =
      currentBpm && nextBpm && currentBpm > 0
        ? Math.round((nextBpm / currentBpm) * 1000) / 1000
        : 1.0;

    const transitionType =
      currentAnalysis.recommendedTransition || 'SMOOTH_FADE';

    const currentTrackDto: CurrentTrackTransitionDto = {
      id: currentTrack.id,
      title: currentTrack.title,
      durationMs: currentDurationMs,
      bpm: currentAnalysis.bpm ?? 0,
      camelotKey: currentAnalysis.camelotKey ?? '',
      loudnessLufs: currentAnalysis.loudnessLufs ?? -14.0,
      triggerTransitionAtMs,
      stopPlaybackAtMs,
    };

    const nextTrackArtists =
      selectedTrack.trackArtists?.map(
        (ta: { artist: { name: string } }) => ta.artist.name,
      ) ?? [];

    const nextTrackDto: NextTrackTransitionDto = {
      id: selectedTrack.id,
      title: selectedTrack.title,
      fileUrl: selectedTrack.fileUrl,
      coverImageUrl: selectedTrack.coverImageUrl,
      artists: nextTrackArtists,
      durationMs: selectedTrack.durationMs ?? selectedAnalysis.durationMs ?? 0,
      bpm: selectedAnalysis.bpm ?? 0,
      camelotKey: selectedAnalysis.camelotKey ?? '',
      startPlaybackAtMs,
      targetDownbeatMs,
    };

    const transitionPlanDto: TransitionPlanDto = {
      transitionType,
      crossfadeDurationMs,
      preBufferAtMs,
      volumeBalanceGainDb,
      tempoRatio,
      compatibilityScore: selectedEvaluation.totalScore,
    };

    return {
      currentTrack: currentTrackDto,
      nextTrack: nextTrackDto,
      transitionPlan: transitionPlanDto,
    };
  }

  /**
   * Calculate Camelot harmonic wheel compatibility score (0 - 40 pts).
   *
   * Wheel properties:
   * - Identical key (e.g. 9A -> 9A): 40 pts
   * - Relative Major/Minor (e.g. 9A -> 9B): 36 pts
   * - Adjacent step (±1, same mode, e.g. 9A -> 8A, 10A): 35 pts
   * - Adjacent step with mode switch (±1, opposite mode, e.g. 9A -> 8B, 10B): 26 pts
   * - 2 steps (±2, same mode, e.g. 9A -> 7A, 11A): 22 pts
   * - 2 steps with mode switch: 14 pts
   * - 3 steps: 12 pts (same mode) / 6 pts (opposite mode)
   * - 4+ steps: decaying to 0
   */
  calculateCamelotScore(
    key1?: string | null,
    key2?: string | null,
  ): number {
    if (!key1 || !key2) {
      return 15; // Neutral fallback when key is not detected
    }

    const regex = /^(\d{1,2})([AB])$/i;
    const match1 = key1.trim().match(regex);
    const match2 = key2.trim().match(regex);

    if (!match1 || !match2) {
      return 15;
    }

    const num1 = parseInt(match1[1], 10);
    const mode1 = match1[2].toUpperCase();
    const num2 = parseInt(match2[1], 10);
    const mode2 = match2[2].toUpperCase();

    // Modular distance on 1-12 wheel
    const diff = Math.abs(num1 - num2);
    const wheelDist = Math.min(diff, 12 - diff);

    if (mode1 === mode2) {
      switch (wheelDist) {
        case 0:
          return 40; // Exact match
        case 1:
          return 35; // Harmonic neighbor (Circle of Fifths)
        case 2:
          return 22; // Two steps away
        case 3:
          return 12; // Energy boost / drop modulation
        case 4:
          return 5;
        default:
          return 0; // Clashing harmonic distance
      }
    } else {
      switch (wheelDist) {
        case 0:
          return 36; // Relative Major / Minor
        case 1:
          return 26; // Diagonal mixing
        case 2:
          return 14;
        case 3:
          return 6;
        default:
          return 0;
      }
    }
  }

  /**
   * Calculate BPM tempo match score (0 - 35 pts).
   * Supports standard matching, half-time, and double-time relationships.
   */
  calculateBpmScore(bpm1?: number | null, bpm2?: number | null): number {
    if (!bpm1 || !bpm2 || bpm1 <= 0 || bpm2 <= 0) {
      return 15; // Neutral fallback
    }

    const directRatio = Math.abs(bpm1 - bpm2) / bpm1;
    const halfRatio = Math.abs(bpm1 - bpm2 * 2) / bpm1;
    const doubleRatio = Math.abs(bpm1 * 2 - bpm2) / (bpm1 * 2);

    const minRatio = Math.min(directRatio, halfRatio, doubleRatio);

    // If tempo difference exceeds 20%, score decays to 0
    const maxAllowedDrift = 0.2;
    if (minRatio >= maxAllowedDrift) {
      return 0;
    }

    const score = 35 * (1 - minRatio / maxAllowedDrift);
    return Math.round(score * 10) / 10;
  }

  /**
   * Calculate Energy level compatibility score (0 - 25 pts).
   * Energy is typically in [0.0, 1.0].
   */
  calculateEnergyScore(
    energy1?: number | null,
    energy2?: number | null,
  ): number {
    if (energy1 === null || energy1 === undefined || energy2 === null || energy2 === undefined) {
      return 12.5; // Neutral fallback
    }

    const diff = Math.abs(energy1 - energy2);
    const score = Math.max(0, 25 * (1 - Math.min(diff, 1.0)));
    return Math.round(score * 10) / 10;
  }

  /**
   * Softmax probability selection with temperature.
   * Lower temperature (e.g. 0.1) -> almost deterministic (highest score wins).
   * Medium temperature (0.7) -> balanced quality and variety.
   * High temperature (2.0+) -> high exploration.
   */
  selectCandidateBySoftmax(
    evaluations: CandidateEvaluation[],
    temperature: number,
  ): CandidateEvaluation {
    if (evaluations.length === 1) {
      return evaluations[0];
    }

    const temp = Math.max(0.01, temperature);
    const maxScore = Math.max(...evaluations.map((e) => e.totalScore));

    // Normalize scores: scaling score/10 with temperature for well-calibrated distribution
    const weights = evaluations.map((e) =>
      Math.exp((e.totalScore - maxScore) / (10 * temp)),
    );
    const totalWeight = weights.reduce((sum, w) => sum + w, 0);

    const probabilities = weights.map((w) => w / totalWeight);

    let random = Math.random();
    for (let i = 0; i < evaluations.length; i++) {
      random -= probabilities[i];
      if (random <= 0 || i === evaluations.length - 1) {
        return evaluations[i];
      }
    }

    return evaluations[0];
  }
}
