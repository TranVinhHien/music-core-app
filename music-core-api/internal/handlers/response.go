package handlers

import (
	"net/http"
	"strconv"

	"github.com/TranVinhHien/music-core-app/music-core-api/internal/handlers/dto"
	"github.com/gin-gonic/gin"
)

func respond(c *gin.Context, status int, message string, data interface{}) {
	c.JSON(status, dto.Response{
		Code:    strconv.Itoa(status),
		Message: message,
		Meta:    nil,
		Data:    data,
	})
}

func respondError(c *gin.Context, status int, err error) {
	message := http.StatusText(status)
	if err != nil {
		message = err.Error()
	}
	respond(c, status, message, nil)
}
