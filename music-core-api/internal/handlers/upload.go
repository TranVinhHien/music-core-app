package handlers

import (
	"fmt"
	"net/http"
	"path/filepath"
	"time"

	"github.com/TranVinhHien/music-core-app/music-core-api/internal/handlers/dto"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/services"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type UploadHandler struct {
	uploadService *services.UploadService
}

func NewUploadHandler(uploadService *services.UploadService) *UploadHandler {
	return &UploadHandler{uploadService: uploadService}
}

func (h *UploadHandler) UploadImage(c *gin.Context) {
	fileHeader, err := c.FormFile("file")
	if err != nil {
		respondError(c, http.StatusBadRequest, fmt.Errorf("file field is required: %w", err))
		return
	}
	file, err := fileHeader.Open()
	if err != nil {
		respondError(c, http.StatusInternalServerError, fmt.Errorf("open upload file: %w", err))
		return
	}
	defer file.Close()

	objectKey := fmt.Sprintf("media-dev/%d_%s%s", time.Now().UnixNano(), uuid.New().String(), filepath.Ext(fileHeader.Filename))
	response, err := h.uploadService.UploadImage(c.Request.Context(), dto.UploadImageInput{
		File: file, ObjectKey: objectKey,
	})
	if err != nil {
		respondError(c, http.StatusInternalServerError, fmt.Errorf("upload image: %w", err))
		return
	}
	respond(c, http.StatusOK, "image uploaded successfully", response)
}
