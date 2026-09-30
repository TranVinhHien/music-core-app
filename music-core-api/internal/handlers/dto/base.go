package dto

// Response is the single API envelope returned by handlers.
type Response struct {
	Code    string      `json:"code"`
	Message string      `json:"message"`
	Meta    interface{} `json:"meta"`
	Data    interface{} `json:"data"`
}

// BaseListDto is the response data shape for endpoints that return a list.
type BaseListDto struct {
	Limit int   `json:"limit"`
	Page  int   `json:"page"`
	Total int64 `json:"total"`
	List  any   `json:"list"`
}

type BaseQuery struct {
	Page  int    `form:"page,default=1"`
	Limit int    `form:"limit,default=10"`
	Query string `form:"query"`
}
