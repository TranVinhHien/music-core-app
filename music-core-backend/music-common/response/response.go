package response

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-common/pagination"
	"github.com/gin-gonic/gin"
)

// Response represents the single standardized API envelope across all microservices.
type Response[T any] struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Meta    any    `json:"meta,omitempty"`
	Data    T      `json:"data"`
}

// AnyResponse is a non-generic response envelope for backward compatibility and dynamic payloads.
type AnyResponse struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Meta    any    `json:"meta,omitempty"`
	Data    any    `json:"data"`
}

// Send sends a custom JSON response.
func Send(c *gin.Context, status int, code string, message string, meta any, data any) {
	c.JSON(status, AnyResponse{
		Code:    code,
		Message: message,
		Meta:    meta,
		Data:    data,
	})
}

// Success sends a 200 OK response with data and default "ok" message.
func Success(c *gin.Context, data any) {
	Send(c, http.StatusOK, "200", "ok", nil, data)
}

// OK sends a 200 OK response with a custom message and data.
func OK(c *gin.Context, message string, data any) {
	Send(c, http.StatusOK, "200", message, nil, data)
}

// Created sends a 201 Created response with data.
func Created(c *gin.Context, message string, data any) {
	Send(c, http.StatusCreated, "201", message, nil, data)
}

// Paginated sends a 200 OK response for a paginated collection.
func Paginated[T any](c *gin.Context, list []T, meta pagination.PaginationMeta) {
	if list == nil {
		list = []T{}
	}
	Send(c, http.StatusOK, "200", "ok", meta, list)
}

// Error responds with a structured error.
func Error(c *gin.Context, status int, err error) {
	if err == nil {
		Send(c, status, strconv.Itoa(status), http.StatusText(status), nil, nil)
		return
	}

	var appErr *AppError
	if errors.As(err, &appErr) {
		Send(c, appErr.StatusCode, appErr.ErrorCode, appErr.Message, appErr.Details, nil)
		return
	}

	Send(c, status, strconv.Itoa(status), err.Error(), nil, nil)
}

// BadRequest sends a 400 Bad Request error.
func BadRequest(c *gin.Context, err error) {
	Error(c, http.StatusBadRequest, err)
}

// Unauthorized sends a 401 Unauthorized error.
func Unauthorized(c *gin.Context, message ...string) {
	msg := "Unauthorized"
	if len(message) > 0 && message[0] != "" {
		msg = message[0]
	}
	Send(c, http.StatusUnauthorized, "401", msg, nil, nil)
}

// Forbidden sends a 403 Forbidden error.
func Forbidden(c *gin.Context, message ...string) {
	msg := "Forbidden: access denied"
	if len(message) > 0 && message[0] != "" {
		msg = message[0]
	}
	Send(c, http.StatusForbidden, "403", msg, nil, nil)
}

// NotFound sends a 404 Not Found error.
func NotFound(c *gin.Context, message ...string) {
	msg := "Resource not found"
	if len(message) > 0 && message[0] != "" {
		msg = message[0]
	}
	Send(c, http.StatusNotFound, "404", msg, nil, nil)
}

// InternalServerError sends a 500 Internal Server Error.
func InternalServerError(c *gin.Context, err error) {
	Error(c, http.StatusInternalServerError, err)
}
