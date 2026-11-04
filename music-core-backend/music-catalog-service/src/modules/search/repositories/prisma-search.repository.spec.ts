import { jest } from '@jest/globals';
import { Test, TestingModule } from '@nestjs/testing';
import { PrismaSearchRepository } from './prisma-search.repository';
import { PrismaService } from '../../../database/prisma.service';

describe('PrismaSearchRepository', () => {
  let repository: PrismaSearchRepository;
  let prismaService: jest.Mocked<PrismaService>;

  beforeEach(async () => {
    prismaService = {
      $queryRaw: jest.fn(),
    } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PrismaSearchRepository,
        {
          provide: PrismaService,
          useValue: prismaService,
        },
      ],
    }).compile();

    repository = module.get<PrismaSearchRepository>(PrismaSearchRepository);
  });

  it('should be defined', () => {
    expect(repository).toBeDefined();
  });

  describe('searchTracks', () => {
    it('should query tracks with FTS, trigram, ILIKE and return items and total', async () => {
      const mockResult = [
        {
          total: 1,
          items: [
            {
              id: 'track-1',
              title: 'Shape of You',
              relevanceScore: 10.0,
            },
          ],
        },
      ];
      (prismaService.$queryRaw as jest.Mock).mockResolvedValue(mockResult);

      const res = await repository.searchTracks('Shape of You', 10, 0);

      expect(prismaService.$queryRaw).toHaveBeenCalledTimes(1);
      expect(res.total).toBe(1);
      expect(res.items).toHaveLength(1);
      expect(res.items[0].id).toBe('track-1');
    });

    it('should handle empty term gracefully', async () => {
      (prismaService.$queryRaw as jest.Mock).mockResolvedValue([
        {
          total: 0,
          items: [],
        },
      ]);

      const res = await repository.searchTracks('', 10, 0);

      expect(prismaService.$queryRaw).toHaveBeenCalledTimes(1);
      expect(res.total).toBe(0);
      expect(res.items).toEqual([]);
    });

    it('should handle json string formatted items', async () => {
      (prismaService.$queryRaw as jest.Mock).mockResolvedValue([
        {
          total: 1,
          items: JSON.stringify([{ id: 'track-2', title: 'Perfect' }]),
        },
      ]);

      const res = await repository.searchTracks('Perfect', 10, 0);

      expect(res.total).toBe(1);
      expect(res.items).toHaveLength(1);
      expect(res.items[0].title).toBe('Perfect');
    });
  });

  describe('searchAlbums', () => {
    it('should query albums and return items and total', async () => {
      const mockResult = [
        {
          total: 2,
          items: [
            { id: 'album-1', title: 'Divide' },
            { id: 'album-2', title: 'Multiply' },
          ],
        },
      ];
      (prismaService.$queryRaw as jest.Mock).mockResolvedValue(mockResult);

      const res = await repository.searchAlbums('Divide', 10, 0);

      expect(prismaService.$queryRaw).toHaveBeenCalledTimes(1);
      expect(res.total).toBe(2);
      expect(res.items).toHaveLength(2);
    });
  });

  describe('searchArtists', () => {
    it('should query artists using name and normalized_name', async () => {
      const mockResult = [
        {
          total: 1,
          items: [{ id: 'artist-1', name: 'Ed Sheeran', normalizedName: 'ed sheeran' }],
        },
      ];
      (prismaService.$queryRaw as jest.Mock).mockResolvedValue(mockResult);

      const res = await repository.searchArtists('ed sheeran', 10, 0);

      expect(prismaService.$queryRaw).toHaveBeenCalledTimes(1);
      expect(res.total).toBe(1);
      expect(res.items).toHaveLength(1);
      expect(res.items[0].name).toBe('Ed Sheeran');
    });
  });
});
