package services

import (
	"context"
	"fmt"
	"time"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/config"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/handlers/dto"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/logging"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/models"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/repository"
	"github.com/google/uuid"
)

type IEventService interface {
	IngestBatch(ctx context.Context, userID uuid.UUID, req *dto.IngestBatchRequest) (*dto.IngestBatchResponse, error)
}

type EventService struct {
	repo repository.IEventRepository
}

func NewEventService(repo repository.IEventRepository) IEventService {
	return &EventService{repo: repo}
}

func (s *EventService) IngestBatch(ctx context.Context, userID uuid.UUID, req *dto.IngestBatchRequest) (*dto.IngestBatchResponse, error) {
	if len(req.Events) == 0 {
		return nil, dto.ErrEmptyBatch
	}

	maxBatchSize := 100
	if config.App != nil && config.App.Batch.MaxBatchSize > 0 {
		maxBatchSize = config.App.Batch.MaxBatchSize
	}
	if len(req.Events) > maxBatchSize {
		return nil, fmt.Errorf("%w: received %d, limit is %d", dto.ErrBatchTooLarge, len(req.Events), maxBatchSize)
	}

	now := time.Now().UTC()
	entities := make([]models.ListeningEvent, 0, len(req.Events))

	for i := range req.Events {
		eventItem := &req.Events[i]

		// 1. Validate against schema
		if err := ValidateEvent(eventItem); err != nil {
			logging.Error(ctx, "EventService.IngestBatch.ValidateEvent", err)
			return nil, fmt.Errorf("event at index %d invalid: %w", i, err)
		}

		var source *models.EventSource
		if eventItem.Source != nil {
			source = &models.EventSource{
				Type: eventItem.Source.Type,
				ID:   eventItem.Source.ID,
			}
		}

		// 2. Map to database entity
		entities = append(entities, models.ListeningEvent{
			EventID:       eventItem.EventID,
			UserID:        userID,
			EventType:     eventItem.EventType,
			OccurredAt:    eventItem.OccurredAt.UTC(),
			ReceivedAt:    now,
			SessionID:     eventItem.SessionID,
			TrackID:       eventItem.TrackID,
			Source:        source,
			Properties:    eventItem.Properties,
			SchemaVersion: eventItem.SchemaVersion,
		})
	}

	// 3. Persist to MongoDB
	res, err := s.repo.BulkInsertEvents(ctx, entities)
	if err != nil {
		logging.Error(ctx, "EventService.IngestBatch.BulkInsertEvents", err)
		return nil, fmt.Errorf("failed to persist events: %w", err)
	}

	return &dto.IngestBatchResponse{
		TotalCount:        res.TotalCount,
		IngestedCount:     res.InsertedCount,
		DuplicateCount:    res.DuplicateCount,
		ProcessedEventIDs: res.EventIDs,
	}, nil
}
