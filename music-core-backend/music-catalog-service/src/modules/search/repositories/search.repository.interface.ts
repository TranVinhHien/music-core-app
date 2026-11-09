import {
  AlbumSearchResultDto,
  ArtistSearchResultDto,
  SearchSectionDto,
  TrackSearchResultDto,
} from '../dto/search-catalog.dto';

export const SEARCH_REPOSITORY_TOKEN = Symbol('SEARCH_REPOSITORY_TOKEN');

export interface ISearchRepository {
  /**
   * Search tracks using Full-Text Search (to_tsvector/to_tsquery),
   * pg_trgm similarity fuzzy search, and SQL ILIKE prefix/substring matching.
   * Returns matching tracks with credited artists and album, plus total count in a single query.
   */
  searchTracks(
    term: string,
    limit: number,
    offset: number,
  ): Promise<SearchSectionDto<TrackSearchResultDto>>;

  /**
   * Search albums using Full-Text Search, pg_trgm similarity fuzzy search,
   * and SQL ILIKE prefix/substring matching.
   * Returns matching albums with credited artists and track count, plus total count in a single query.
   */
  searchAlbums(
    term: string,
    limit: number,
    offset: number,
  ): Promise<SearchSectionDto<AlbumSearchResultDto>>;

  /**
   * Search artists using Full-Text Search, pg_trgm similarity fuzzy search,
   * and SQL ILIKE prefix/substring matching against name and normalized_name.
   * Returns matching artists, plus total count in a single query.
   */
  searchArtists(
    term: string,
    limit: number,
    offset: number,
  ): Promise<SearchSectionDto<ArtistSearchResultDto>>;
}

