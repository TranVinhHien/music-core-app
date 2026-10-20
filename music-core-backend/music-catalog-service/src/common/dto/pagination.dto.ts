import { ApiPropertyOptional, ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export enum SortOrder {
  ASC = 'asc',
  DESC = 'desc',
}

export class PaginationQueryDto {
  @ApiPropertyOptional({ default: 1, minimum: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page: number = 1;

  @ApiPropertyOptional({ default: 10, minimum: 1, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit: number = 10;

  @ApiPropertyOptional({ description: 'Field to sort by' })
  @IsOptional()
  @IsString()
  sort?: string;

  @ApiPropertyOptional({ enum: SortOrder, default: SortOrder.DESC })
  @IsOptional()
  @IsEnum(SortOrder)
  order: SortOrder = SortOrder.DESC;

  @ApiPropertyOptional({ description: 'Search term' })
  @IsOptional()
  @IsString()
  query?: string;

  get offset(): number {
    return (this.page - 1) * this.limit;
  }
}

export class PaginationMetaDto {
  @ApiProperty({ example: 1 })
  current_page: number;

  @ApiProperty({ example: 10 })
  page_size: number;

  @ApiProperty({ example: 42 })
  total_items: number;

  @ApiProperty({ example: 5 })
  total_pages: number;

  @ApiProperty({ example: true })
  has_next: boolean;

  @ApiProperty({ example: false })
  has_previous: boolean;

  constructor(totalItems: number, page: number, limit: number) {
    this.current_page = page;
    this.page_size = limit;
    this.total_items = totalItems;
    this.total_pages = totalItems > 0 ? Math.ceil(totalItems / limit) : 0;
    this.has_next = this.current_page < this.total_pages;
    this.has_previous = this.current_page > 1;
  }
}

export class PaginatedResult<T> {
  list: T[];
  pagination: PaginationMetaDto;

  constructor(list: T[], totalItems: number, page: number, limit: number) {
    this.list = list;
    this.pagination = new PaginationMetaDto(totalItems, page, limit);
  }
}
