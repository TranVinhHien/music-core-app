import { jest } from '@jest/globals';
import { Test, TestingModule } from '@nestjs/testing';
import { FavoritesService } from './favorites.service';
import { FAVORITE_REPOSITORY_TOKEN } from './repositories/favorite.repository.interface';
import { CatalogClient } from '../../integrations/catalog/catalog.client';
import { NotFoundException, ConflictException } from '@nestjs/common';

describe('FavoritesService', () => {
  let service: FavoritesService;
  let mockFavRepo: any;
  let mockCatalogClient: any;

  beforeEach(async () => {
    mockFavRepo = {
      add: jest.fn(),
      remove: jest.fn(),
      findAll: jest.fn(),
      isFavorite: jest.fn(),
    };

    mockCatalogClient = {
      getTrackById: jest.fn(),
      getTracksByIds: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FavoritesService,
        {
          provide: FAVORITE_REPOSITORY_TOKEN,
          useValue: mockFavRepo,
        },
        {
          provide: CatalogClient,
          useValue: mockCatalogClient,
        },
      ],
    }).compile();

    service = module.get<FavoritesService>(FavoritesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('add', () => {
    it('should add track to favorites when track exists in catalog and is not favorited yet', async () => {
      const userId = 'user-1';
      const trackId = 'track-1';
      const trackData = { id: trackId, title: 'Hit Song' };

      mockCatalogClient.getTrackById.mockResolvedValue(trackData);
      mockFavRepo.isFavorite.mockResolvedValue(false);
      mockFavRepo.add.mockResolvedValue({ userId, trackId, createdAt: new Date() });

      const result = await service.add(userId, { trackId });
      expect(result.track).toEqual(trackData);
      expect(mockFavRepo.add).toHaveBeenCalledWith(userId, trackId);
    });

    it('should throw NotFoundException if track does not exist in catalog', async () => {
      mockCatalogClient.getTrackById.mockResolvedValue(null);

      await expect(service.add('user-1', { trackId: 'invalid-id' })).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw ConflictException if track is already in favorites', async () => {
      mockCatalogClient.getTrackById.mockResolvedValue({ id: 't-1' });
      mockFavRepo.isFavorite.mockResolvedValue(true);

      await expect(service.add('user-1', { trackId: 't-1' })).rejects.toThrow(
        ConflictException,
      );
    });
  });

  describe('findAll', () => {
    it('should return enriched favorite tracks with metadata from catalog', async () => {
      const userId = 'user-1';
      const favList = [{ userId, trackId: 't-1', createdAt: new Date() }];
      const trackDetail = { id: 't-1', title: 'Song 1' };
      const trackMap = new Map();
      trackMap.set('t-1', trackDetail);

      mockFavRepo.findAll.mockResolvedValue({ items: favList, total: 1 });
      mockCatalogClient.getTracksByIds.mockResolvedValue(trackMap);

      const result = await service.findAll(userId, { page: 1, limit: 10 } as any);
      expect(result.list[0].track).toEqual(trackDetail);
      expect(result.pagination.total_items).toBe(1);
    });
  });
});
