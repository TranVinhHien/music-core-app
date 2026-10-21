package handlers

import (
	"strconv"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-common/response"
	"github.com/gin-gonic/gin"
)

func respond(c *gin.Context, status int, message string, data interface{}) {
	response.Send(c, status, strconv.Itoa(status), message, nil, data)
}

func respondError(c *gin.Context, status int, err error) {
	response.Error(c, status, err)
}
