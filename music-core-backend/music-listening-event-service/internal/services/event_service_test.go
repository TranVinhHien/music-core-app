package services

import (
	"context"
	"testing"
	"time"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/handlers/dto"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/models"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/repository"
	"github.com/google/uuid"
)

type fakeEventRepo struct {
	insertedEvents []models.ListeningEvent
	duplicateIDs   map[string]bool
}

func newFakeRepo() *fakeEventRepo {
	return &fakeEventRepo{
		insertedEvents: make([]models.ListeningEvent, 0),
		duplicateIDs:   make(map[string]bool),
	}
}

func (r *fakeEventRepo) BulkInsertEvents(ctx context.Context, events []models.ListeningEvent) (*repository.BatchInsertResult, error) {
	newlyInserted := 0
	duplicateCount := 0
	eventIDs := make([]string, 0, len(events))

	for _, ev := range events {
		eventIDs = append(eventIDs, ev.EventID)
		if r.duplicateIDs[ev.EventID] {
			duplicateCount++
		} else {
			newlyInserted++
			r.duplicateIDs[ev.EventID] = true
			r.insertedEvents = append(r.insertedEvents, ev)
		}
	}

	return &repository.BatchInsertResult{
		TotalCount:     len(events),
		InsertedCount:  newlyInserted,
		DuplicateCount: duplicateCount,
		EventIDs:       eventIDs,
	}, nil
}

func TestEventService_IngestBatch(t *testing.T) {
	repo := newFakeRepo()
	service := NewEventService(repo)
	userID := uuid.New()
	ctx := context.Background()

	t.Run("empty batch returns error", func(t *testing.T) {
		req := &dto.IngestBatchRequest{
			Events: []dto.EventItemDTO{},
		}
		_, err := service.IngestBatch(ctx, userID, req)
		if err != dto.ErrEmptyBatch {
			t.Fatalf("expected ErrEmptyBatch, got %v", err)
		}
	})

	t.Run("batch over 100 returns error", func(t *testing.T) {
		events := make([]dto.EventItemDTO, 101)
		for i := 0; i < 101; i++ {
			events[i] = dto.EventItemDTO{
				EventID:       uuid.New().String(),
				EventType:     models.EventTypeTrackStarted,
				OccurredAt:    time.Now(),
				SessionID:     stringPtr("session-1"),
				TrackID:       stringPtr("track-1"),
				SchemaVersion: 1,
				Properties:    map[string]interface{}{"duration_ms": 1000},
			}
		}
		req := &dto.IngestBatchRequest{Events: events}
		_, err := service.IngestBatch(ctx, userID, req)
		if err == nil {
			t.Fatal("expected batch limit error, got nil")
		}
	})

	t.Run("valid batch inserts successfully and marks duplicates", func(t *testing.T) {
		evID1 := uuid.New().String()
		evID2 := uuid.New().String()

		req := &dto.IngestBatchRequest{
			Events: []dto.EventItemDTO{
				{
					EventID:       evID1,
					EventType:     models.EventTypeTrackStarted,
					OccurredAt:    time.Now(),
					SessionID:     stringPtr("session-1"),
					TrackID:       stringPtr("track-1"),
					SchemaVersion: 1,
					Properties:    map[string]interface{}{"duration_ms": 180000},
				},
				{
					EventID:       evID2,
					EventType:     models.EventTypeTrackCompleted,
					OccurredAt:    time.Now(),
					SessionID:     stringPtr("session-1"),
					TrackID:       stringPtr("track-1"),
					SchemaVersion: 1,
					Properties:    map[string]interface{}{"duration_ms": 180000, "listened_ms": 180000},
				},
			},
		}

		res, err := service.IngestBatch(ctx, userID, req)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if res.TotalCount != 2 || res.IngestedCount != 2 || res.DuplicateCount != 0 {
			t.Fatalf("unexpected result: %+v", res)
		}

		// Re-sending same batch simulates network retry (idempotent)
		retryRes, err := service.IngestBatch(ctx, userID, req)
		if err != nil {
			t.Fatalf("retry failed: %v", err)
		}
		if retryRes.TotalCount != 2 || retryRes.IngestedCount != 0 || retryRes.DuplicateCount != 2 {
			t.Fatalf("expected 2 duplicates on retry, got: %+v", retryRes)
		}
	})
}
