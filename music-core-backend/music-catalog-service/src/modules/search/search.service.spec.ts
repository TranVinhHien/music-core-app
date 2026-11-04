import { jest } from '@jest/globals';
import { Test, TestingModule } from '@nestjs/testing';
import { SearchService } from './search.service';
import {
  type ISearchRepository,
  SEARCH_REPOSITORY_TOKEN,
} from './repositories/search.repository.interface';
import {
  AlbumSearchResultDto,
  ArtistSearchResultDto,
  SearchCatalogQueryDto,
  SearchSectionDto,
  SearchTargetType,
  TrackSearchResultDto,
} from './dto/search-catalog.dto';

describe('SearchService', () => {
  let service: SearchService;
  let repository: jest.Mocked<ISearchRepository>;

  const mockTrack: TrackSearchResultDto = {
    id: 'track-uuid-1',
    title: 'Shape of You',
    slug: 'shape-of-you',
    albumId: 'album-uuid-1',
    durationMs: 233712,
    trackNumber: 4,
    discNumber: 1,
    releaseDate: '2017-03-03',
    coverImageUrl: 'https://example.com/cover.jpg',
    fileUrl: 'https://example.com/track.mp3',
    status: 'ACTIVE',
    album: {
      id: 'album-uuid-1',
      title: 'Divide',
      coverImageUrl: 'https://example.com/album.jpg',
    },
    artists: [
      {
        id: 'artist-uuid-1',
        name: 'Ed Sheeran',
        role: 'PRIMARY',
        position: 1,
        imageUrl: 'https://example.com/ed.jpg',
      },
    ],
    relevanceScore: 9.5,
  };

  const mockAlbum: AlbumSearchResultDto = {
    id: 'album-uuid-1',
    title: 'Divide',
    releaseDate: '2017-03-03',
    coverImageUrl: 'https://example.com/album.jpg',
    status: 'ACTIVE',
    artists: [
      {
        id: 'artist-uuid-1',
        name: 'Ed Sheeran',
        position: 1,
        imageUrl: 'https://example.com/ed.jpg',
      },
    ],
    totalTracks: 16,
    relevanceScore: 8.2,
  };

  const mockArtist: ArtistSearchResultDto = {
    id: 'artist-uuid-1',
    name: 'Ed Sheeran',
    normalizedName: 'ed sheeran',
    bio: 'English singer-songwriter',
    imageUrl: 'https://example.com/ed.jpg',
    relevanceScore: 10.0,
  };

  beforeEach(async () => {
    repository = {
      searchTracks: jest
        .fn()
        .mockResolvedValue(new SearchSectionDto([mockTrack], 1)),
      searchAlbums: jest
        .fn()
        .mockResolvedValue(new SearchSectionDto([mockAlbum], 1)),
      searchArtists: jest
        .fn()
        .mockResolvedValue(new SearchSectionDto([mockArtist], 1)),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SearchService,
        {
          provide: SEARCH_REPOSITORY_TOKEN,
          useValue: repository,
        },
      ],
    }).compile();

    service = module.get<SearchService>(SearchService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('searchCatalog', () => {
    it('should query all 3 entities using 3 separate queries when type is ALL', async () => {
      const dto = new SearchCatalogQueryDto();
      dto.query = 'Ed Sheeran';
      dto.limit = 10;
      dto.page = 1;
      dto.type = SearchTargetType.ALL;

      const result = await service.searchCatalog(dto);

      expect(repository.searchTracks).toHaveBeenCalledTimes(1);
      expect(repository.searchTracks).toHaveBeenCalledWith('Ed Sheeran', 10, 0);

      expect(repository.searchAlbums).toHaveBeenCalledTimes(1);
      expect(repository.searchAlbums).toHaveBeenCalledWith('Ed Sheeran', 10, 0);

      expect(repository.searchArtists).toHaveBeenCalledTimes(1);
      expect(repository.searchArtists).toHaveBeenCalledWith('Ed Sheeran', 10, 0);

      expect(result).toHaveProperty('tracks');
      expect(result).toHaveProperty('albums');
      expect(result).toHaveProperty('artists');

      expect(result.tracks.total).toBe(1);
      expect(result.tracks.items).toHaveLength(1);
      expect(result.tracks.items[0].title).toBe('Shape of You');

      expect(result.albums.total).toBe(1);
      expect(result.albums.items).toHaveLength(1);
      expect(result.albums.items[0].title).toBe('Divide');

      expect(result.artists.total).toBe(1);
      expect(result.artists.items).toHaveLength(1);
      expect(result.artists.items[0].name).toBe('Ed Sheeran');
    });

    it('should only query tracks when type is TRACKS', async () => {
      const dto = new SearchCatalogQueryDto();
      dto.query = 'Shape';
      dto.type = SearchTargetType.TRACKS;

      const result = await service.searchCatalog(dto);

      expect(repository.searchTracks).toHaveBeenCalledTimes(1);
      expect(repository.searchAlbums).not.toHaveBeenCalled();
      expect(repository.searchArtists).not.toHaveBeenCalled();

      expect(result.tracks.items).toHaveLength(1);
      expect(result.albums.items).toHaveLength(0);
      expect(result.albums.total).toBe(0);
      expect(result.artists.items).toHaveLength(0);
      expect(result.artists.total).toBe(0);
    });

    it('should only query albums when type is ALBUMS', async () => {
      const dto = new SearchCatalogQueryDto();
      dto.query = 'Divide';
      dto.type = SearchTargetType.ALBUMS;

      const result = await service.searchCatalog(dto);

      expect(repository.searchTracks).not.toHaveBeenCalled();
      expect(repository.searchAlbums).toHaveBeenCalledTimes(1);
      expect(repository.searchArtists).not.toHaveBeenCalled();

      expect(result.tracks.items).toHaveLength(0);
      expect(result.albums.items).toHaveLength(1);
      expect(result.artists.items).toHaveLength(0);
    });

    it('should only query artists when type is ARTISTS', async () => {
      const dto = new SearchCatalogQueryDto();
      dto.query = 'Ed';
      dto.type = SearchTargetType.ARTISTS;

      const result = await service.searchCatalog(dto);

      expect(repository.searchTracks).not.toHaveBeenCalled();
      expect(repository.searchAlbums).not.toHaveBeenCalled();
      expect(repository.searchArtists).toHaveBeenCalledTimes(1);

      expect(result.tracks.items).toHaveLength(0);
      expect(result.albums.items).toHaveLength(0);
      expect(result.artists.items).toHaveLength(1);
    });

    it('should support alias q parameter when query is not provided', async () => {
      const dto = new SearchCatalogQueryDto();
      dto.q = 'Perfect';

      await service.searchCatalog(dto);

      expect(repository.searchTracks).toHaveBeenCalledWith('Perfect', 10, 0);
      expect(repository.searchAlbums).toHaveBeenCalledWith('Perfect', 10, 0);
      expect(repository.searchArtists).toHaveBeenCalledWith('Perfect', 10, 0);
    });

    it('should calculate correct offset from page and limit', async () => {
      const dto = new SearchCatalogQueryDto();
      dto.query = 'Love';
      dto.page = 3;
      dto.limit = 15;

      await service.searchCatalog(dto);

      // (3 - 1) * 15 = 30
      expect(repository.searchTracks).toHaveBeenCalledWith('Love', 15, 30);
    });
  });
});
