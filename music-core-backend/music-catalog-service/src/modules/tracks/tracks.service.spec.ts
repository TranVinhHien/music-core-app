import { jest } from '@jest/globals';
import { NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { TracksService } from './tracks.service';
import {
  ITrackRepository,
  TRACK_REPOSITORY_TOKEN,
} from './repositories/track.repository.interface';
import { QueryRandomTrackDto } from './dto/query-random-track.dto';

describe('TracksService', () => {
  let service: TracksService;
  let trackRepository: jest.Mocked<ITrackRepository>;

  const mockTrack = {
    id: 'tr-random-1',
    title: 'Random Track',
    artistName: 'Random Artist',
    durationMs: 180000,
  } as any;

  beforeEach(async () => {
    trackRepository = {
      createWithRelations: jest.fn(),
      findById: jest.fn(),
      findWithDetails: jest.fn(),
      findAll: jest.fn(),
      findRandom: jest.fn(),
      updateWithRelations: jest.fn(),
      delete: jest.fn(),
      upsertAudioAnalysis: jest.fn(),
    } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TracksService,
        {
          provide: TRACK_REPOSITORY_TOKEN,
          useValue: trackRepository,
        },
      ],
    }).compile();

    service = module.get<TracksService>(TracksService);
  });

  describe('findRandom', () => {
    it('should return a single random track when limit is 1', async () => {
      trackRepository.findRandom.mockResolvedValue([mockTrack]);

      const dto = new QueryRandomTrackDto();
      dto.limit = 1;
      dto.excludeTrackId = 'tr-excluded-1';

      const result = await service.findRandom(dto);

      expect(trackRepository.findRandom).toHaveBeenCalledWith(dto);
      expect(result).toEqual(mockTrack);
    });

    it('should return a list of random tracks when limit > 1', async () => {
      const mockTrack2 = { id: 'tr-random-2', title: 'Random Track 2' } as any;
      trackRepository.findRandom.mockResolvedValue([mockTrack, mockTrack2]);

      const dto = new QueryRandomTrackDto();
      dto.limit = 2;

      const result = await service.findRandom(dto);

      expect(trackRepository.findRandom).toHaveBeenCalledWith(dto);
      expect(Array.isArray(result)).toBe(true);
      expect(result).toHaveLength(2);
    });

    it('should throw NotFoundException when no tracks are found', async () => {
      trackRepository.findRandom.mockResolvedValue([]);

      const dto = new QueryRandomTrackDto();

      await expect(service.findRandom(dto)).rejects.toThrow(NotFoundException);
    });
  });
});

