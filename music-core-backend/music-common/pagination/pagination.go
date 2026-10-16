package pagination

import (
	"math"
	"strings"
)

// PaginationQuery defines the standard query parameters for paginated endpoints.
type PaginationQuery struct {
	Page  int    `form:"page,default=1" json:"page"`
	Limit int    `form:"limit,default=10" json:"limit"`
	Sort  string `form:"sort" json:"sort"`
	Order string `form:"order,default=desc" json:"order"`
	Query string `form:"query" json:"query"`
}

// GetPage returns the valid 1-indexed page number (default: 1).
func (p *PaginationQuery) GetPage() int {
	if p.Page <= 0 {
		return 1
	}
	return p.Page
}

// GetLimit returns the valid limit per page (default: 10, max: 100).
func (p *PaginationQuery) GetLimit() int {
	if p.Limit <= 0 {
		return 10
	}
	if p.Limit > 100 {
		return 100
	}
	return p.Limit
}

// GetOffset calculates the SQL offset.
func (p *PaginationQuery) GetOffset() int {
	return (p.GetPage() - 1) * p.GetLimit()
}

// GetOrder returns sanitized sort order (asc or desc).
func (p *PaginationQuery) GetOrder() string {
	order := strings.ToLower(strings.TrimSpace(p.Order))
	if order == "asc" {
		return "ASC"
	}
	return "DESC"
}

// PaginationMeta contains metadata about the paginated list.
type PaginationMeta struct {
	CurrentPage int   `json:"current_page"`
	PageSize    int   `json:"page_size"`
	TotalItems  int64 `json:"total_items"`
	TotalPages  int   `json:"total_pages"`
	HasNext     bool  `json:"has_next"`
	HasPrevious bool  `json:"has_previous"`
}

// NewPaginationMeta creates a PaginationMeta struct based on total items, page, and limit.
func NewPaginationMeta(totalItems int64, page, limit int) PaginationMeta {
	if page <= 0 {
		page = 1
	}
	if limit <= 0 {
		limit = 10
	}

	totalPages := 0
	if totalItems > 0 {
		totalPages = int(math.Ceil(float64(totalItems) / float64(limit)))
	}

	return PaginationMeta{
		CurrentPage: page,
		PageSize:    limit,
		TotalItems:  totalItems,
		TotalPages:  totalPages,
		HasNext:     page < totalPages,
		HasPrevious: page > 1,
	}
}

// PageResult represents the standard envelope for paginated collections.
type PageResult[T any] struct {
	List       []T            `json:"list"`
	Pagination PaginationMeta `json:"pagination"`
}

// NewPageResult constructs a PageResult wrapper.
func NewPageResult[T any](list []T, totalItems int64, page, limit int) PageResult[T] {
	if list == nil {
		list = []T{}
	}
	return PageResult[T]{
		List:       list,
		Pagination: NewPaginationMeta(totalItems, page, limit),
	}
}
