import { Inject, Injectable } from '@nestjs/common';
import {
  type ISearchRepository,
  SEARCH_REPOSITORY_TOKEN,
} from './repositories/search.repository.interface';
import {
  AlbumSearchResultDto,
  ArtistSearchResultDto,
  CatalogSearchResponseDto,
  SearchCatalogQueryDto,
  SearchSectionDto,
  SearchTargetType,
  TrackSearchResultDto,
} from './dto/search-catalog.dto';

@Injectable()
export class SearchService {
  constructor(
    @Inject(SEARCH_REPOSITORY_TOKEN)
    private readonly searchRepository: ISearchRepository,
  ) {}

  /**
   * Performs unified catalog search across tracks, albums, and artists
   * using PostgreSQL Full-Text Search, pg_trgm similarity, and SQL ILIKE.
   * Executes 3 independent queries across the 3 entities in parallel.
   */
  async searchCatalog(dto: SearchCatalogQueryDto): Promise<CatalogSearchResponseDto> {
    const term = dto.searchTerm;
    const limit = dto.limit || 10;
    const offset = dto.offset || 0;
    const type = dto.type || SearchTargetType.ALL;

    const shouldSearchTracks =
      type === SearchTargetType.ALL || type === SearchTargetType.TRACKS;
    const shouldSearchAlbums =
      type === SearchTargetType.ALL || type === SearchTargetType.ALBUMS;
    const shouldSearchArtists =
      type === SearchTargetType.ALL || type === SearchTargetType.ARTISTS;

    const [tracksSection, albumsSection, artistsSection] = await Promise.all([
      shouldSearchTracks
        ? this.searchRepository.searchTracks(term, limit, offset)
        : Promise.resolve(new SearchSectionDto<TrackSearchResultDto>([], 0)),
      shouldSearchAlbums
        ? this.searchRepository.searchAlbums(term, limit, offset)
        : Promise.resolve(new SearchSectionDto<AlbumSearchResultDto>([], 0)),
      shouldSearchArtists
        ? this.searchRepository.searchArtists(term, limit, offset)
        : Promise.resolve(new SearchSectionDto<ArtistSearchResultDto>([], 0)),
    ]);

    return new CatalogSearchResponseDto(tracksSection, albumsSection, artistsSection);
  }
}
