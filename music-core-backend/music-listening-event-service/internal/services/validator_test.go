package services

import (
	"testing"
	"time"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/handlers/dto"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/models"
)

func stringPtr(s string) *string {
	return &s
}

func TestValidateEvent_PlaybackEvents(t *testing.T) {
	now := time.Now()
	sessionID := "session-123"
	trackID := "track-456"

	tests := []struct {
		name    string
		item    dto.EventItemDTO
		wantErr bool
	}{
		{
			name: "TRACK_STARTED - valid",
			item: dto.EventItemDTO{
				EventID:       "ev-1",
				EventType:     models.EventTypeTrackStarted,
				OccurredAt:    now,
				SessionID:     stringPtr(sessionID),
				TrackID:       stringPtr(trackID),
				SchemaVersion: 1,
				Properties: map[string]interface{}{
					"duration_ms": 180000,
					"position_ms": 0,
				},
			},
			wantErr: false,
		},
		{
			name: "TRACK_STARTED - missing session_id",
			item: dto.EventItemDTO{
				EventID:       "ev-2",
				EventType:     models.EventTypeTrackStarted,
				OccurredAt:    now,
				TrackID:       stringPtr(trackID),
				SchemaVersion: 1,
				Properties: map[string]interface{}{
					"duration_ms": 180000,
				},
			},
			wantErr: true,
		},
		{
			name: "TRACK_STARTED - negative duration_ms",
			item: dto.EventItemDTO{
				EventID:       "ev-3",
				EventType:     models.EventTypeTrackStarted,
				OccurredAt:    now,
				SessionID:     stringPtr(sessionID),
				TrackID:       stringPtr(trackID),
				SchemaVersion: 1,
				Properties: map[string]interface{}{
					"duration_ms": -100,
				},
			},
			wantErr: true,
		},
		{
			name: "TRACK_COMPLETED - valid",
			item: dto.EventItemDTO{
				EventID:       "ev-4",
				EventType:     models.EventTypeTrackCompleted,
				OccurredAt:    now,
				SessionID:     stringPtr(sessionID),
				TrackID:       stringPtr(trackID),
				SchemaVersion: 1,
				Properties: map[string]interface{}{
					"duration_ms": 200000,
					"listened_ms": 200000,
				},
			},
			wantErr: false,
		},
		{
			name: "TRACK_SKIPPED - valid with next_track_id",
			item: dto.EventItemDTO{
				EventID:       "ev-5",
				EventType:     models.EventTypeTrackSkipped,
				OccurredAt:    now,
				SessionID:     stringPtr(sessionID),
				TrackID:       stringPtr(trackID),
				SchemaVersion: 1,
				Properties: map[string]interface{}{
					"duration_ms":   200000,
					"position_ms":   45000,
					"listened_ms":   45000,
					"next_track_id": "track-789",
				},
			},
			wantErr: false,
		},
		{
			name: "TRACK_PAUSED - valid",
			item: dto.EventItemDTO{
				EventID:       "ev-6",
				EventType:     models.EventTypeTrackPaused,
				OccurredAt:    now,
				SessionID:     stringPtr(sessionID),
				TrackID:       stringPtr(trackID),
				SchemaVersion: 1,
				Properties: map[string]interface{}{
					"position_ms": 30000,
					"listened_ms": 30000,
				},
			},
			wantErr: false,
		},
		{
			name: "TRACK_SEEKED - valid",
			item: dto.EventItemDTO{
				EventID:       "ev-7",
				EventType:     models.EventTypeTrackSeeked,
				OccurredAt:    now,
				SessionID:     stringPtr(sessionID),
				TrackID:       stringPtr(trackID),
				SchemaVersion: 1,
				Properties: map[string]interface{}{
					"from_position_ms": 10000,
					"to_position_ms":   50000,
				},
			},
			wantErr: false,
		},
		{
			name: "TRACK_REPLAYED - valid manual replay",
			item: dto.EventItemDTO{
				EventID:       "ev-8",
				EventType:     models.EventTypeTrackReplayed,
				OccurredAt:    now,
				SessionID:     stringPtr(sessionID),
				TrackID:       stringPtr(trackID),
				SchemaVersion: 1,
				Properties: map[string]interface{}{
					"position_ms": 0,
					"replay_type": "MANUAL_REPLAY",
				},
			},
			wantErr: false,
		},
		{
			name: "TRACK_REPLAYED - invalid replay_type",
			item: dto.EventItemDTO{
				EventID:       "ev-9",
				EventType:     models.EventTypeTrackReplayed,
				OccurredAt:    now,
				SessionID:     stringPtr(sessionID),
				TrackID:       stringPtr(trackID),
				SchemaVersion: 1,
				Properties: map[string]interface{}{
					"position_ms": 0,
					"replay_type": "AUTO_REPEAT",
				},
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateEvent(&tt.item)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateEvent() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestValidateEvent_DiscoveryLibraryAndPlaylist(t *testing.T) {
	now := time.Now()
	trackID := "track-456"

	tests := []struct {
		name    string
		item    dto.EventItemDTO
		wantErr bool
	}{
		{
			name: "SEARCH_PERFORMED - valid",
			item: dto.EventItemDTO{
				EventID:       "ev-10",
				EventType:     models.EventTypeSearchPerformed,
				OccurredAt:    now,
				SchemaVersion: 1,
				Properties: map[string]interface{}{
					"query":         "lofi beats",
					"search_type":   "track",
					"results_count": 25,
				},
			},
			wantErr: false,
		},
		{
			name: "SEARCH_PERFORMED - empty query",
			item: dto.EventItemDTO{
				EventID:       "ev-11",
				EventType:     models.EventTypeSearchPerformed,
				OccurredAt:    now,
				SchemaVersion: 1,
				Properties: map[string]interface{}{
					"query":       "   ",
					"search_type": "all",
				},
			},
			wantErr: true,
		},
		{
			name: "TRACK_FAVORITED - valid",
			item: dto.EventItemDTO{
				EventID:       "ev-12",
				EventType:     models.EventTypeTrackFavorited,
				OccurredAt:    now,
				TrackID:       stringPtr(trackID),
				SchemaVersion: 1,
				Properties:    map[string]interface{}{},
			},
			wantErr: false,
		},
		{
			name: "TRACK_FAVORITED - missing track_id",
			item: dto.EventItemDTO{
				EventID:       "ev-13",
				EventType:     models.EventTypeTrackFavorited,
				OccurredAt:    now,
				SchemaVersion: 1,
			},
			wantErr: true,
		},
		{
			name: "TRACK_ADDED_TO_PLAYLIST - valid",
			item: dto.EventItemDTO{
				EventID:       "ev-14",
				EventType:     models.EventTypeTrackAddedToPlaylist,
				OccurredAt:    now,
				TrackID:       stringPtr(trackID),
				SchemaVersion: 1,
				Properties: map[string]interface{}{
					"playlist_id": "pl-999",
					"position":    2,
				},
			},
			wantErr: false,
		},
		{
			name: "TRACK_REMOVED_FROM_PLAYLIST - missing playlist_id",
			item: dto.EventItemDTO{
				EventID:       "ev-15",
				EventType:     models.EventTypeTrackRemovedFromPlaylist,
				OccurredAt:    now,
				TrackID:       stringPtr(trackID),
				SchemaVersion: 1,
				Properties:    map[string]interface{}{},
			},
			wantErr: true,
		},
		{
			name: "PLAYLIST_PLAYED - valid sequential",
			item: dto.EventItemDTO{
				EventID:       "ev-16",
				EventType:     models.EventTypePlaylistPlayed,
				OccurredAt:    now,
				SchemaVersion: 1,
				Properties: map[string]interface{}{
					"playlist_id":   "pl-999",
					"track_count":   50,
					"playback_mode": "SEQUENTIAL",
				},
			},
			wantErr: false,
		},
		{
			name: "PLAYLIST_PLAYED - invalid playback_mode",
			item: dto.EventItemDTO{
				EventID:       "ev-17",
				EventType:     models.EventTypePlaylistPlayed,
				OccurredAt:    now,
				SchemaVersion: 1,
				Properties: map[string]interface{}{
					"playlist_id":   "pl-999",
					"playback_mode": "RANDOM",
				},
			},
			wantErr: true,
		},
		{
			name: "UNKNOWN_EVENT_TYPE - error",
			item: dto.EventItemDTO{
				EventID:       "ev-18",
				EventType:     "TRACK_DELETED",
				OccurredAt:    now,
				SchemaVersion: 1,
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateEvent(&tt.item)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateEvent() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
