import { jest } from '@jest/globals';
import { Test, TestingModule } from '@nestjs/testing';
import { ArtistsService } from './artists.service';
import { ARTIST_REPOSITORY_TOKEN } from './repositories/artist.repository.interface';
import { NotFoundException } from '@nestjs/common';

describe('ArtistsService', () => {
  let service: ArtistsService;
  let mockRepo: any;

  beforeEach(async () => {
    mockRepo = {
      create: jest.fn(),
      findById: jest.fn(),
      findWithDetails: jest.fn(),
      findAll: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ArtistsService,
        {
          provide: ARTIST_REPOSITORY_TOKEN,
          useValue: mockRepo,
        },
      ],
    }).compile();

    service = module.get<ArtistsService>(ArtistsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should create an artist with normalized name', async () => {
      const dto = { name: 'Sơn Tùng M-TP', bio: 'Vietnamese Singer' };
      const createdArtist = {
        id: '123e4567-e89b-12d3-a456-426614174000',
        name: 'Sơn Tùng M-TP',
        normalizedName: 'son tung m-tp',
        bio: 'Vietnamese Singer',
        imageUrl: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      mockRepo.create.mockResolvedValue(createdArtist);

      const result = await service.create(dto);
      expect(result).toEqual(createdArtist);
      expect(mockRepo.create).toHaveBeenCalledWith({
        name: 'Sơn Tùng M-TP',
        normalizedName: 'son tung m-tp',
        bio: 'Vietnamese Singer',
        imageUrl: undefined,
      });
    });
  });

  describe('findOne', () => {
    it('should return artist details if found', async () => {
      const artist = { id: 'uuid-1', name: 'Artist 1' };
      mockRepo.findWithDetails.mockResolvedValue(artist);

      const result = await service.findOne('uuid-1');
      expect(result).toEqual(artist);
    });

    it('should throw NotFoundException if artist not found', async () => {
      mockRepo.findWithDetails.mockResolvedValue(null);

      await expect(service.findOne('uuid-non-existent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
