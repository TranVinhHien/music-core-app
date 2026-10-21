package handlers

import (
	"errors"
	"net/http"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/handlers/dto"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/middleware"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/services"
	"github.com/gin-gonic/gin"
)

type EventHandler struct {
	eventService services.IEventService
}

func NewEventHandler(eventService services.IEventService) *EventHandler {
	return &EventHandler{
		eventService: eventService,
	}
}

// IngestBatch handles batch event ingestion from clients (1 - 100 events)
func (h *EventHandler) IngestBatch(c *gin.Context) {
	var req dto.IngestBatchRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, err)
		return
	}

	userID, ok := middleware.RequestUserID(c)
	if !ok {
		respondError(c, http.StatusUnauthorized, errors.New("unauthorized: missing user identity"))
		return
	}

	result, err := h.eventService.IngestBatch(c.Request.Context(), userID, &req)
	if err != nil {
		status := http.StatusInternalServerError
		if errors.Is(err, dto.ErrEmptyBatch) ||
			errors.Is(err, dto.ErrBatchTooLarge) ||
			errors.Is(err, dto.ErrUnsupportedEventType) ||
			errors.Is(err, dto.ErrMissingTrackID) ||
			errors.Is(err, dto.ErrMissingSessionID) ||
			errors.Is(err, dto.ErrInvalidProperty) ||
			errors.Is(err, dto.ErrMissingRequiredProperty) {
			status = http.StatusBadRequest
		}
		respondError(c, status, err)
		return
	}

	respond(c, http.StatusOK, "events ingested successfully", result)
}

func (h *EventHandler) Health(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status": "UP",
		"time":   c.GetTime("request_time"),
	})
}
