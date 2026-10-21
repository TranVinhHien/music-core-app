package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-common/constants"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/handlers/dto"
	eventMW "github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/middleware"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/models"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type mockEventService struct {
	ingestFn func(ctx context.Context, userID uuid.UUID, req *dto.IngestBatchRequest) (*dto.IngestBatchResponse, error)
}

func (m *mockEventService) IngestBatch(ctx context.Context, userID uuid.UUID, req *dto.IngestBatchRequest) (*dto.IngestBatchResponse, error) {
	if m.ingestFn != nil {
		return m.ingestFn(ctx, userID, req)
	}
	return &dto.IngestBatchResponse{
		TotalCount:     len(req.Events),
		IngestedCount:  len(req.Events),
		DuplicateCount: 0,
	}, nil
}

func stringPtr(s string) *string {
	return &s
}

func TestEventHandler_IngestBatch(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mockService := &mockEventService{}
	handler := NewEventHandler(mockService)

	r := gin.New()
	r.Use(eventMW.AuthMiddleware())
	r.POST("/api/v1/listening-events/batch", handler.IngestBatch)

	testUserID := uuid.New()

	t.Run("successful batch ingestion with gateway headers", func(t *testing.T) {
		reqBody := dto.IngestBatchRequest{
			Events: []dto.EventItemDTO{
				{
					EventID:       uuid.New().String(),
					EventType:     models.EventTypeTrackStarted,
					OccurredAt:    time.Now(),
					SessionID:     stringPtr("session-abc"),
					TrackID:       stringPtr("track-xyz"),
					SchemaVersion: 1,
					Properties: map[string]interface{}{
						"duration_ms": 200000,
						"position_ms": 0,
					},
				},
			},
		}

		bodyBytes, _ := json.Marshal(reqBody)
		req, _ := http.NewRequest(http.MethodPost, "/api/v1/listening-events/batch", bytes.NewBuffer(bodyBytes))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set(constants.HeaderUserID, testUserID.String())
		req.Header.Set(constants.HeaderUserRoles, "user")

		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		if w.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d: %s", w.Code, w.Body.String())
		}
	})

	t.Run("missing user identity returns 401", func(t *testing.T) {
		reqBody := dto.IngestBatchRequest{
			Events: []dto.EventItemDTO{},
		}
		bodyBytes, _ := json.Marshal(reqBody)
		req, _ := http.NewRequest(http.MethodPost, "/api/v1/listening-events/batch", bytes.NewBuffer(bodyBytes))
		req.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		if w.Code != http.StatusUnauthorized {
			t.Fatalf("expected 401 Unauthorized, got %d", w.Code)
		}
	})

	t.Run("empty batch returns 400 Bad Request", func(t *testing.T) {
		reqBody := dto.IngestBatchRequest{
			Events: []dto.EventItemDTO{},
		}
		bodyBytes, _ := json.Marshal(reqBody)
		req, _ := http.NewRequest(http.MethodPost, "/api/v1/listening-events/batch", bytes.NewBuffer(bodyBytes))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set(constants.HeaderUserID, testUserID.String())

		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		if w.Code != http.StatusBadRequest {
			t.Fatalf("expected 400 Bad Request, got %d", w.Code)
		}
	})
}
