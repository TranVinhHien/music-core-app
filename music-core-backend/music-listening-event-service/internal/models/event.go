package models

import (
	"time"

	"github.com/google/uuid"
)

// Supported Event Types
const (
	// Playback
	EventTypeTrackStarted   = "TRACK_STARTED"
	EventTypeTrackCompleted = "TRACK_COMPLETED"
	EventTypeTrackSkipped   = "TRACK_SKIPPED"
	EventTypeTrackPaused    = "TRACK_PAUSED"
	EventTypeTrackSeeked    = "TRACK_SEEKED"
	EventTypeTrackReplayed  = "TRACK_REPLAYED"

	// Discovery
	EventTypeSearchPerformed = "SEARCH_PERFORMED"

	// Library
	EventTypeTrackFavorited         = "TRACK_FAVORITED"
	EventTypeTrackUnfavorited       = "TRACK_UNFAVORITED"
	EventTypeTrackAddedToPlaylist   = "TRACK_ADDED_TO_PLAYLIST"
	EventTypeTrackRemovedFromPlaylist = "TRACK_REMOVED_FROM_PLAYLIST"

	// Playlist
	EventTypePlaylistPlayed = "PLAYLIST_PLAYED"
)

// ReplayType enum
const (
	ReplayTypeManual = "MANUAL_REPLAY"
)

// SearchType enums
const (
	SearchTypeTrack  = "track"
	SearchTypeArtist = "artist"
	SearchTypeAlbum  = "album"
	SearchTypeAll    = "all"
)

// PlaybackMode enums
const (
	PlaybackModeSequential = "SEQUENTIAL"
	PlaybackModeShuffle    = "SHUFFLE"
)

// EventSource captures where the action occurred (e.g. playlist, album, search, favorite, queue)
type EventSource struct {
	Type string  `json:"type" bson:"type"`
	ID   *string `json:"id,omitempty" bson:"id,omitempty"`
}

// ListeningEvent represents an ingested listening activity document in MongoDB
type ListeningEvent struct {
	EventID       string                 `json:"event_id" bson:"event_id"`
	UserID        uuid.UUID              `json:"user_id" bson:"user_id"`
	EventType     string                 `json:"event_type" bson:"event_type"`
	OccurredAt    time.Time              `json:"occurred_at" bson:"occurred_at"`
	ReceivedAt    time.Time              `json:"received_at" bson:"received_at"`
	SessionID     *string                `json:"session_id,omitempty" bson:"session_id,omitempty"`
	TrackID       *string                `json:"track_id,omitempty" bson:"track_id,omitempty"`
	Source        *EventSource           `json:"source,omitempty" bson:"source,omitempty"`
	Properties    map[string]interface{} `json:"properties" bson:"properties"`
	SchemaVersion int                    `json:"schema_version" bson:"schema_version"`
}
