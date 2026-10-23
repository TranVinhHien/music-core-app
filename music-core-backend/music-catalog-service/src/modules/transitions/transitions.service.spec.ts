import { jest } from '@jest/globals';
import { Test, TestingModule } from '@nestjs/testing';
import { TransitionsService } from './transitions.service';
import { PrismaService } from '../../database/prisma.service';
import { BadRequestException, NotFoundException } from '@nestjs/common';

describe('TransitionsService', () => {
  let service: TransitionsService;
  let mockPrisma: any;

  beforeEach(async () => {
    mockPrisma = {
      track: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TransitionsService,
        {
          provide: PrismaService,
          useValue: mockPrisma,
        },
      ],
    }).compile();

    service = module.get<TransitionsService>(TransitionsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('calculateCamelotScore', () => {
    it('should return 40 for identical Camelot keys', () => {
      expect(service.calculateCamelotScore('9A', '9A')).toBe(40);
      expect(service.calculateCamelotScore('12B', '12B')).toBe(40);
    });

    it('should return 36 for relative Major/Minor keys (same number, different mode)', () => {
      expect(service.calculateCamelotScore('9A', '9B')).toBe(36);
      expect(service.calculateCamelotScore('4B', '4A')).toBe(36);
    });

    it('should return 35 for adjacent keys with same mode (Circle of Fifths)', () => {
      expect(service.calculateCamelotScore('9A', '8A')).toBe(35);
      expect(service.calculateCamelotScore('9A', '10A')).toBe(35);
      // Wrap-around on 12-hour wheel
      expect(service.calculateCamelotScore('12A', '1A')).toBe(35);
      expect(service.calculateCamelotScore('1B', '12B')).toBe(35);
    });

    it('should return 26 for diagonal keys (adjacent number, different mode)', () => {
      expect(service.calculateCamelotScore('9A', '8B')).toBe(26);
      expect(service.calculateCamelotScore('9A', '10B')).toBe(26);
    });

    it('should return 22 for two steps distance with same mode', () => {
      expect(service.calculateCamelotScore('9A', '7A')).toBe(22);
      expect(service.calculateCamelotScore('9A', '11A')).toBe(22);
    });

    it('should return 0 for clashing distant keys', () => {
      expect(service.calculateCamelotScore('1A', '7A')).toBe(0);
      expect(service.calculateCamelotScore('2A', '8B')).toBe(0);
    });

    it('should return 15 fallback for null/empty/invalid keys', () => {
      expect(service.calculateCamelotScore(null, '9A')).toBe(15);
      expect(service.calculateCamelotScore('9A', undefined)).toBe(15);
      expect(service.calculateCamelotScore('invalid', '9A')).toBe(15);
    });
  });

  describe('calculateBpmScore', () => {
    it('should return 35 for identical BPM', () => {
      expect(service.calculateBpmScore(128, 128)).toBe(35);
    });

    it('should return 35 for half-time / double-time matching BPM', () => {
      expect(service.calculateBpmScore(70, 140)).toBe(35);
      expect(service.calculateBpmScore(160, 80)).toBe(35);
    });

    it('should decay smoothly for small tempo differences', () => {
      // 5% difference: 120 vs 126
      const score = service.calculateBpmScore(120, 126);
      expect(score).toBeGreaterThan(20);
      expect(score).toBeLessThan(35);
    });

    it('should return 0 when drift exceeds 20%', () => {
      expect(service.calculateBpmScore(100, 125)).toBe(0);
    });

    it('should return 15 fallback when BPM is missing or non-positive', () => {
      expect(service.calculateBpmScore(null, 128)).toBe(15);
      expect(service.calculateBpmScore(128, 0)).toBe(15);
    });
  });

  describe('calculateEnergyScore', () => {
    it('should return 25 for identical energy levels', () => {
      expect(service.calculateEnergyScore(0.8, 0.8)).toBe(25);
    });

    it('should calculate linearly based on difference', () => {
      expect(service.calculateEnergyScore(0.8, 0.6)).toBe(20);
      expect(service.calculateEnergyScore(0.3, 0.7)).toBe(15);
    });

    it('should return 12.5 fallback when energy is missing', () => {
      expect(service.calculateEnergyScore(null, 0.8)).toBe(12.5);
    });
  });

  describe('getNextTransition', () => {
    const currentTrackId = '2d4e9b6b-4885-4586-a8e8-b2a5f1b880ed';
    const mockCurrentTrack = {
      id: currentTrackId,
      title: 'Current Track',
      durationMs: 300000,
      audioAnalysis: {
        id: 'analysis-1',
        trackId: currentTrackId,
        analysisStatus: 'COMPLETED',
        bpm: 128,
        camelotKey: '8A',
        energy: 0.7,
        loudnessLufs: -14.0,
        cueInMs: 1500,
        cueOutMs: 290000,
        recommendedCrossfadeMs: 8000,
        recommendedTransition: 'SMOOTH_FADE',
        firstDownbeatMs: 2000,
      },
      trackArtists: [{ artist: { name: 'Artist A' } }],
    };

    const mockCandidateTrack = {
      id: 'candidate-track-uuid',
      title: 'Candidate Track',
      durationMs: 240000,
      fileUrl: 'https://example.com/audio.mp3',
      coverImageUrl: 'https://example.com/cover.jpg',
      audioAnalysis: {
        id: 'analysis-2',
        trackId: 'candidate-track-uuid',
        analysisStatus: 'COMPLETED',
        bpm: 128,
        camelotKey: '8A',
        energy: 0.7,
        loudnessLufs: -13.5,
        cueInMs: 1000,
        cueOutMs: 235000,
        recommendedCrossfadeMs: 6000,
        recommendedTransition: 'SMOOTH_FADE',
        firstDownbeatMs: 2500,
      },
      trackArtists: [{ artist: { name: 'Artist B' } }],
    };

    it('should throw NotFoundException if current track is not found', async () => {
      mockPrisma.track.findUnique.mockResolvedValue(null);

      await expect(
        service.getNextTransition({ currentTrackId: 'non-existent' }),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw BadRequestException if audioAnalysis is missing or not COMPLETED', async () => {
      mockPrisma.track.findUnique.mockResolvedValue({
        id: currentTrackId,
        title: 'Track Without Analysis',
        audioAnalysis: { analysisStatus: 'PENDING' },
      });

      await expect(
        service.getNextTransition({ currentTrackId }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw NotFoundException if no candidates match criteria', async () => {
      mockPrisma.track.findUnique.mockResolvedValue(mockCurrentTrack);
      mockPrisma.track.findMany.mockResolvedValue([]);

      await expect(
        service.getNextTransition({ currentTrackId }),
      ).rejects.toThrow(NotFoundException);
    });

    it('should return valid transition response with correct timing and plan', async () => {
      mockPrisma.track.findUnique.mockResolvedValue(mockCurrentTrack);
      mockPrisma.track.findMany.mockResolvedValue([mockCandidateTrack]);

      const result = await service.getNextTransition({
        currentTrackId,
        temperature: 0.1,
      });

      expect(result).toBeDefined();
      // Current track verification
      expect(result.currentTrack.id).toBe(currentTrackId);
      expect(result.currentTrack.triggerTransitionAtMs).toBe(290000);
      expect(result.currentTrack.stopPlaybackAtMs).toBe(298000); // 290000 + 8000 <= 300000
      expect(result.currentTrack.bpm).toBe(128);
      expect(result.currentTrack.camelotKey).toBe('8A');

      // Next track verification
      expect(result.nextTrack.id).toBe('candidate-track-uuid');
      expect(result.nextTrack.title).toBe('Candidate Track');
      expect(result.nextTrack.artists).toEqual(['Artist B']);
      expect(result.nextTrack.startPlaybackAtMs).toBe(1000);
      expect(result.nextTrack.targetDownbeatMs).toBe(2500);

      // Transition plan verification
      expect(result.transitionPlan.crossfadeDurationMs).toBe(8000);
      expect(result.transitionPlan.preBufferAtMs).toBe(280000); // 290000 - 10000
      expect(result.transitionPlan.volumeBalanceGainDb).toBe(-0.5); // -14 - (-13.5) = -0.5
      expect(result.transitionPlan.tempoRatio).toBe(1); // 128 / 128
      expect(result.transitionPlan.compatibilityScore).toBe(100); // 40 + 35 + 25
    });

    it('should exclude specified track IDs in findMany query', async () => {
      mockPrisma.track.findUnique.mockResolvedValue(mockCurrentTrack);
      mockPrisma.track.findMany.mockResolvedValue([mockCandidateTrack]);

      const excludeTrackIds = ['excluded-1', 'excluded-2'];
      await service.getNextTransition({
        currentTrackId,
        excludeTrackIds,
      });

      expect(mockPrisma.track.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            id: {
              notIn: [currentTrackId, ...excludeTrackIds],
            },
          }),
        }),
      );
    });
  });
});
