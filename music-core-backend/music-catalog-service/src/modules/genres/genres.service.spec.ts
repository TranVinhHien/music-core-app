import { jest } from '@jest/globals';
import { Test, TestingModule } from '@nestjs/testing';
import { GenresService } from './genres.service';
import { GENRE_REPOSITORY_TOKEN } from './repositories/genre.repository.interface';
import { ConflictException } from '@nestjs/common';

describe('GenresService', () => {
  let service: GenresService;
  let mockRepo: any;

  beforeEach(async () => {
    mockRepo = {
      create: jest.fn(),
      findById: jest.fn(),
      findBySlug: jest.fn(),
      findWithDetails: jest.fn(),
      findAll: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GenresService,
        {
          provide: GENRE_REPOSITORY_TOKEN,
          useValue: mockRepo,
        },
      ],
    }).compile();

    service = module.get<GenresService>(GenresService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should create genre and generate slug automatically', async () => {
      mockRepo.findBySlug.mockResolvedValue(null);
      const createdGenre = {
        id: 'genre-1',
        name: 'Pop Music',
        slug: 'pop-music',
        parentId: null,
        createdAt: new Date(),
      };
      mockRepo.create.mockResolvedValue(createdGenre);

      const result = await service.create({ name: 'Pop Music' });
      expect(result).toEqual(createdGenre);
      expect(mockRepo.create).toHaveBeenCalledWith({
        name: 'Pop Music',
        slug: 'pop-music',
        parent: undefined,
      });
    });

    it('should throw ConflictException if slug already exists', async () => {
      mockRepo.findBySlug.mockResolvedValue({ id: 'existing', slug: 'rock' });

      await expect(service.create({ name: 'Rock', slug: 'rock' })).rejects.toThrow(
        ConflictException,
      );
    });
  });
});
