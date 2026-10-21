package dto

import (
	"errors"
	"time"
)

var (
	ErrEmptyBatch             = errors.New("batch must contain at least 1 event")
	ErrBatchTooLarge          = errors.New("batch exceeds maximum of 100 events")
	ErrUnsupportedEventType   = errors.New("unsupported event_type")
	ErrMissingTrackID         = errors.New("track_id is required for track-specific events")
	ErrMissingSessionID       = errors.New("session_id is required for playback events")
	ErrInvalidProperty        = errors.New("invalid event property")
	ErrMissingRequiredProperty = errors.New("missing required property")
)

type EventSourceDTO struct {
	Type string  `json:"type" binding:"required"`
	ID   *string `json:"id,omitempty"`
}

type EventItemDTO struct {
	EventID       string                 `json:"event_id" binding:"required"`
	EventType     string                 `json:"event_type" binding:"required"`
	OccurredAt    time.Time              `json:"occurred_at" binding:"required"`
	SessionID     *string                `json:"session_id,omitempty"`
	TrackID       *string                `json:"track_id,omitempty"`
	Source        *EventSourceDTO        `json:"source,omitempty"`
	Properties    map[string]interface{} `json:"properties"`
	SchemaVersion int                    `json:"schema_version" binding:"required"`
}

type IngestBatchRequest struct {
	Events []EventItemDTO `json:"events" binding:"required,min=1,max=100"`
}

type IngestBatchResponse struct {
	TotalCount        int      `json:"total_count"`
	IngestedCount     int      `json:"ingested_count"`
	DuplicateCount    int      `json:"duplicate_count"`
	ProcessedEventIDs []string `json:"processed_event_ids"`
}
