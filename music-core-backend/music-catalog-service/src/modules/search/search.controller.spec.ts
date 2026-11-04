import { jest } from '@jest/globals';
import { Test, TestingModule } from '@nestjs/testing';
import { SearchController } from './search.controller';
import { SearchService } from './search.service';
import {
  CatalogSearchResponseDto,
  SearchCatalogQueryDto,
  SearchSectionDto,
} from './dto/search-catalog.dto';

describe('SearchController', () => {
  let controller: SearchController;
  let service: jest.Mocked<SearchService>;

  beforeEach(async () => {
    service = {
      searchCatalog: jest.fn().mockResolvedValue(
        new CatalogSearchResponseDto(
          new SearchSectionDto([], 0),
          new SearchSectionDto([], 0),
          new SearchSectionDto([], 0),
        ),
      ),
    } as any;

    const module: TestingModule = await Test.createTestingModule({
      controllers: [SearchController],
      providers: [
        {
          provide: SearchService,
          useValue: service,
        },
      ],
    }).compile();

    controller = module.get<SearchController>(SearchController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('should call searchCatalog on service', async () => {
    const query = new SearchCatalogQueryDto();
    query.query = 'test';

    const result = await controller.search(query);

    expect(service.searchCatalog).toHaveBeenCalledWith(query);
    expect(result).toHaveProperty('tracks');
    expect(result).toHaveProperty('albums');
    expect(result).toHaveProperty('artists');
  });
});
