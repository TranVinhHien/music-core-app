package repository

import (
	"context"
	"errors"
	"fmt"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/logging"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/models"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

type BatchInsertResult struct {
	TotalCount     int
	InsertedCount  int
	DuplicateCount int
	EventIDs       []string
}

type IEventRepository interface {
	BulkInsertEvents(ctx context.Context, events []models.ListeningEvent) (*BatchInsertResult, error)
}

type EventRepository struct {
	collection *mongo.Collection
}

func NewEventRepository(db *mongo.Database, collectionName string) IEventRepository {
	return &EventRepository{
		collection: db.Collection(collectionName),
	}
}

func (r *EventRepository) BulkInsertEvents(ctx context.Context, events []models.ListeningEvent) (*BatchInsertResult, error) {
	if len(events) == 0 {
		return &BatchInsertResult{}, nil
	}

	eventIDs := make([]string, 0, len(events))
	writeModels := make([]mongo.WriteModel, 0, len(events))

	for _, ev := range events {
		eventIDs = append(eventIDs, ev.EventID)
		writeModels = append(writeModels, mongo.NewInsertOneModel().SetDocument(ev))
	}

	// Unordered bulk write: allow non-duplicate inserts even if some IDs are duplicated
	opts := options.BulkWrite().SetOrdered(false)
	res, err := r.collection.BulkWrite(ctx, writeModels, opts)

	if err != nil {
		var bwe mongo.BulkWriteException
		if errors.As(err, &bwe) {
			duplicateCount := 0
			var fatalErr error

			for _, writeErr := range bwe.WriteErrors {
				// MongoDB code 11000 is DuplicateKey error
				if writeErr.Code == 11000 {
					duplicateCount++
				} else {
					fatalErr = fmt.Errorf("mongo bulk write error (code %d): %s", writeErr.Code, writeErr.Message)
					break
				}
			}

			if fatalErr != nil {
				logging.Error(ctx, "EventRepository.BulkInsertEvents.Fatal", fatalErr)
				return nil, fatalErr
			}

			inserted := 0
			if res != nil {
				inserted = int(res.InsertedCount)
			} else {
				inserted = len(events) - duplicateCount
			}

			return &BatchInsertResult{
				TotalCount:     len(events),
				InsertedCount:  inserted,
				DuplicateCount: duplicateCount,
				EventIDs:       eventIDs,
			}, nil
		}

		logging.Error(ctx, "EventRepository.BulkInsertEvents", err)
		return nil, fmt.Errorf("failed to bulk insert events: %w", err)
	}

	inserted := 0
	if res != nil {
		inserted = int(res.InsertedCount)
	}

	return &BatchInsertResult{
		TotalCount:     len(events),
		InsertedCount:  inserted,
		DuplicateCount: len(events) - inserted,
		EventIDs:       eventIDs,
	}, nil
}
