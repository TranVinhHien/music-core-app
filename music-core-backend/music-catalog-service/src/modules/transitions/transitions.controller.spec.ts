import { jest } from '@jest/globals';
import { Test, TestingModule } from '@nestjs/testing';
import { TransitionsController } from './transitions.controller';
import { TransitionsService } from './transitions.service';
import { GetNextTransitionDto } from './dto/get-next-transition.dto';
import { TransitionResponseDto } from './dto/transition-response.dto';

describe('TransitionsController', () => {
  let controller: TransitionsController;
  let service: TransitionsService;

  const mockResponse: TransitionResponseDto = {
    currentTrack: {
      id: '2d4e9b6b-4885-4586-a8e8-b2a5f1b880ed',
      title: 'Current Track',
      durationMs: 300000,
      bpm: 128,
      camelotKey: '8A',
      loudnessLufs: -14.0,
      triggerTransitionAtMs: 290000,
      stopPlaybackAtMs: 298000,
    },
    nextTrack: {
      id: 'candidate-track-uuid',
      title: 'Candidate Track',
      fileUrl: 'https://example.com/audio.mp3',
      coverImageUrl: 'https://example.com/cover.jpg',
      artists: ['Artist B'],
      durationMs: 240000,
      bpm: 128,
      camelotKey: '8A',
      startPlaybackAtMs: 1000,
      targetDownbeatMs: 2500,
    },
    transitionPlan: {
      transitionType: 'SMOOTH_FADE',
      crossfadeDurationMs: 8000,
      preBufferAtMs: 280000,
      volumeBalanceGainDb: 0,
      tempoRatio: 1.0,
      compatibilityScore: 100,
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [TransitionsController],
      providers: [
        {
          provide: TransitionsService,
          useValue: {
            getNextTransition: jest.fn().mockResolvedValue(mockResponse),
          },
        },
      ],
    }).compile();

    controller = module.get<TransitionsController>(TransitionsController);
    service = module.get<TransitionsService>(TransitionsService);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('should call service.getNextTransition and return result', async () => {
    const dto: GetNextTransitionDto = {
      currentTrackId: '2d4e9b6b-4885-4586-a8e8-b2a5f1b880ed',
      temperature: 0.7,
      excludeTrackIds: [],
    };

    const result = await controller.getNextTransition(dto);
    expect(result).toEqual(mockResponse);
    expect(service.getNextTransition).toHaveBeenCalledWith(dto);
  });
});
