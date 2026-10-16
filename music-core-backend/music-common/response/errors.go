package response

import (
	"fmt"
	"net/http"
)

// AppError represents a structured application error with HTTP code and message.
type AppError struct {
	StatusCode int    `json:"status_code"`
	ErrorCode  string `json:"error_code"`
	Message    string `json:"message"`
	Details    any    `json:"details,omitempty"`
}

func (e *AppError) Error() string {
	return fmt.Sprintf("[%s] %s", e.ErrorCode, e.Message)
}

// NewAppError creates a new AppError.
func NewAppError(status int, code string, message string, details ...any) *AppError {
	var d any
	if len(details) > 0 {
		d = details[0]
	}
	return &AppError{
		StatusCode: status,
		ErrorCode:  code,
		Message:    message,
		Details:    d,
	}
}

// Common error constructors.
func ErrBadRequest(message string, details ...any) *AppError {
	return NewAppError(http.StatusBadRequest, "BAD_REQUEST", message, details...)
}

func ErrUnauthorized(message string) *AppError {
	return NewAppError(http.StatusUnauthorized, "UNAUTHORIZED", message)
}

func ErrForbidden(message string) *AppError {
	return NewAppError(http.StatusForbidden, "FORBIDDEN", message)
}

func ErrNotFound(message string) *AppError {
	return NewAppError(http.StatusNotFound, "NOT_FOUND", message)
}

func ErrConflict(message string) *AppError {
	return NewAppError(http.StatusConflict, "CONFLICT", message)
}

func ErrInternal(message string) *AppError {
	return NewAppError(http.StatusInternalServerError, "INTERNAL_SERVER_ERROR", message)
}
