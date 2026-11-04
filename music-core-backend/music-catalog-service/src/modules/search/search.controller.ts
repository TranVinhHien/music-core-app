import { Controller, Get, Query } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { SearchService } from './search.service';
import {
  CatalogSearchResponseDto,
  SearchCatalogQueryDto,
} from './dto/search-catalog.dto';

@ApiTags('Search')
@Controller('search')
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  @Get()
  @ApiOperation({
    summary: 'Search catalog across tracks, albums, and artists',
    description:
      'Multi-entity search utilizing PostgreSQL Full-Text Search (to_tsvector/to_tsquery), ' +
      'pg_trgm extension for fuzzy matching (similarity), SQL ILIKE prefix/substring matching, ' +
      'and GIN indexes. Dispatches 3 parallel queries to retrieve tracks, albums, and artists with individual totals.',
  })
  @ApiResponse({
    status: 200,
    description: 'Catalog search results grouped by tracks, albums, and artists with individual totals.',
    type: CatalogSearchResponseDto,
  })
  search(@Query() query: SearchCatalogQueryDto) {
    return this.searchService.searchCatalog(query);
  }
}

