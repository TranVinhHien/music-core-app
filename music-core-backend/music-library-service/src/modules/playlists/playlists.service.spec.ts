import { jest } from '@jest/globals';
import { Test, TestingModule } from '@nestjs/testing';
import { PlaylistsService } from './playlists.service';
import { PLAYLIST_REPOSITORY_TOKEN } from './repositories/playlist.repository.interface';
import { CatalogClient } from '../../integrations/catalog/catalog.client';
import { NotFoundException, ConflictException } from '@nestjs/common';

describe('PlaylistsService', () => {
  let service: PlaylistsService;
  let mockPlaylistRepo: any;
  let mockCatalogClient: any;

  beforeEach(async () => {
    mockPlaylistRepo = {
      create: jest.fn(),
      findById: jest.fn(),
      findAll: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      addTrack: jest.fn(),
      removeTrack: jest.fn(),
      getMaxPosition: jest.fn(),
      hasTrack: jest.fn(),
    };

    mockCatalogClient = {
      getTrackById: jest.fn(),
      getTracksByIds: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PlaylistsService,
        {
          provide: PLAYLIST_REPOSITORY_TOKEN,
          useValue: mockPlaylistRepo,
        },
        {
          provide: CatalogClient,
          useValue: mockCatalogClient,
        },
      ],
    }).compile();

    service = module.get<PlaylistsService>(PlaylistsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should create a playlist for user', async () => {
      const userId = 'user-uuid-1';
      const dto = { name: 'My Playlist', description: 'Test' };
      const created = { id: 'playlist-1', userId, ...dto, visibility: 'PRIVATE' };

      mockPlaylistRepo.create.mockResolvedValue(created);

      const result = await service.create(userId, dto);
      expect(result).toEqual(created);
      expect(mockPlaylistRepo.create).toHaveBeenCalledWith({
        userId,
        name: 'My Playlist',
        description: 'Test',
        coverImageUrl: undefined,
        visibility: 'PRIVATE',
      });
    });
  });

  describe('findOne with catalog enrichment', () => {
    it('should enrich playlist tracks with metadata from catalog', async () => {
      const playlist = {
        id: 'p-1',
        userId: 'u-1',
        name: 'Hits',
        visibility: 'PUBLIC',
        tracks: [
          { playlistId: 'p-1', trackId: 't-1', position: 1, addedAt: new Date() },
        ],
      };

      const trackDetail = { id: 't-1', title: 'Song 1', fileUrl: 'https://example.com/song1.mp3' };
      const trackMap = new Map();
      trackMap.set('t-1', trackDetail);

      mockPlaylistRepo.findById.mockResolvedValue(playlist);
      mockCatalogClient.getTracksByIds.mockResolvedValue(trackMap);

      const result = await service.findOne('p-1', 'u-1');
      expect(result.tracks[0].track).toEqual(trackDetail);
      expect(mockCatalogClient.getTracksByIds).toHaveBeenCalledWith(['t-1']);
    });
  });

  describe('addTrack', () => {
    it('should throw NotFoundException if track does not exist in catalog', async () => {
      mockPlaylistRepo.findById.mockResolvedValue({ id: 'p-1', userId: 'u-1' });
      mockCatalogClient.getTrackById.mockResolvedValue(null);

      await expect(
        service.addTrack('p-1', 'u-1', { trackId: 'non-existent' }),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw ConflictException if track is already in playlist', async () => {
      mockPlaylistRepo.findById.mockResolvedValue({ id: 'p-1', userId: 'u-1' });
      mockCatalogClient.getTrackById.mockResolvedValue({ id: 't-1', title: 'Track 1' });
      mockPlaylistRepo.hasTrack.mockResolvedValue(true);

      await expect(
        service.addTrack('p-1', 'u-1', { trackId: 't-1' }),
      ).rejects.toThrow(ConflictException);
    });
  });
});
