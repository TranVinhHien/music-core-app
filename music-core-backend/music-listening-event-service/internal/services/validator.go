package services

import (
	"fmt"
	"strings"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/handlers/dto"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/models"
)

// ValidateEvent validates a single event item against the 12 supported event schemas.
func ValidateEvent(item *dto.EventItemDTO) error {
	if item.EventID == "" {
		return fmt.Errorf("event_id cannot be empty")
	}
	if item.OccurredAt.IsZero() {
		return fmt.Errorf("occurred_at cannot be zero")
	}
	if item.SchemaVersion != 1 {
		return fmt.Errorf("unsupported schema_version: %d, expected 1", item.SchemaVersion)
	}

	props := item.Properties
	if props == nil {
		props = make(map[string]interface{})
		item.Properties = props
	}

	switch item.EventType {
	// ----------------------------------------------------
	// 1. Playback Events
	// ----------------------------------------------------
	case models.EventTypeTrackStarted:
		if err := requirePlaybackFields(item); err != nil {
			return err
		}
		if _, err := getNonNegativeNumber(props, "duration_ms", true); err != nil {
			return err
		}
		// position_ms may default to 0 if not provided
		if _, exists := props["position_ms"]; exists {
			if _, err := getNonNegativeNumber(props, "position_ms", true); err != nil {
				return err
			}
		} else {
			props["position_ms"] = float64(0)
		}

	case models.EventTypeTrackCompleted:
		if err := requirePlaybackFields(item); err != nil {
			return err
		}
		if _, err := getNonNegativeNumber(props, "duration_ms", true); err != nil {
			return err
		}
		if _, err := getNonNegativeNumber(props, "listened_ms", true); err != nil {
			return err
		}

	case models.EventTypeTrackSkipped:
		if err := requirePlaybackFields(item); err != nil {
			return err
		}
		if _, err := getNonNegativeNumber(props, "position_ms", true); err != nil {
			return err
		}
		if _, err := getNonNegativeNumber(props, "duration_ms", true); err != nil {
			return err
		}
		if _, err := getNonNegativeNumber(props, "listened_ms", true); err != nil {
			return err
		}
		// next_track_id is optional

	case models.EventTypeTrackPaused:
		if err := requirePlaybackFields(item); err != nil {
			return err
		}
		if _, err := getNonNegativeNumber(props, "position_ms", true); err != nil {
			return err
		}
		if _, err := getNonNegativeNumber(props, "listened_ms", true); err != nil {
			return err
		}

	case models.EventTypeTrackSeeked:
		if err := requirePlaybackFields(item); err != nil {
			return err
		}
		if _, err := getNonNegativeNumber(props, "from_position_ms", true); err != nil {
			return err
		}
		if _, err := getNonNegativeNumber(props, "to_position_ms", true); err != nil {
			return err
		}

	case models.EventTypeTrackReplayed:
		if err := requirePlaybackFields(item); err != nil {
			return err
		}
		if _, err := getNonNegativeNumber(props, "position_ms", true); err != nil {
			return err
		}
		replayType, err := getString(props, "replay_type", true)
		if err != nil {
			return err
		}
		if replayType != models.ReplayTypeManual {
			return fmt.Errorf("invalid replay_type '%s', expected '%s'", replayType, models.ReplayTypeManual)
		}

	// ----------------------------------------------------
	// 2. Discovery Events
	// ----------------------------------------------------
	case models.EventTypeSearchPerformed:
		query, err := getString(props, "query", true)
		if err != nil {
			return err
		}
		trimmedQuery := strings.TrimSpace(query)
		if trimmedQuery == "" {
			return fmt.Errorf("query cannot be empty")
		}
		props["query"] = trimmedQuery

		searchType, err := getString(props, "search_type", true)
		if err != nil {
			return err
		}
		switch searchType {
		case models.SearchTypeTrack, models.SearchTypeArtist, models.SearchTypeAlbum, models.SearchTypeAll:
		default:
			return fmt.Errorf("invalid search_type '%s', expected track, artist, album, or all", searchType)
		}

		if _, exists := props["results_count"]; exists {
			if _, err := getNonNegativeNumber(props, "results_count", true); err != nil {
				return err
			}
		}

	// ----------------------------------------------------
	// 3. Library Events
	// ----------------------------------------------------
	case models.EventTypeTrackFavorited, models.EventTypeTrackUnfavorited:
		if item.TrackID == nil || strings.TrimSpace(*item.TrackID) == "" {
			return dto.ErrMissingTrackID
		}

	case models.EventTypeTrackAddedToPlaylist, models.EventTypeTrackRemovedFromPlaylist:
		if item.TrackID == nil || strings.TrimSpace(*item.TrackID) == "" {
			return dto.ErrMissingTrackID
		}
		playlistID, err := getString(props, "playlist_id", true)
		if err != nil || strings.TrimSpace(playlistID) == "" {
			return fmt.Errorf("playlist_id is required in properties")
		}
		if _, exists := props["position"]; exists {
			if _, err := getNonNegativeNumber(props, "position", true); err != nil {
				return err
			}
		}

	// ----------------------------------------------------
	// 4. Playlist Events
	// ----------------------------------------------------
	case models.EventTypePlaylistPlayed:
		playlistID, err := getString(props, "playlist_id", true)
		if err != nil || strings.TrimSpace(playlistID) == "" {
			return fmt.Errorf("playlist_id is required in properties")
		}
		if _, exists := props["track_count"]; exists {
			if _, err := getNonNegativeNumber(props, "track_count", true); err != nil {
				return err
			}
		}
		if _, exists := props["playback_mode"]; exists {
			mode, err := getString(props, "playback_mode", true)
			if err != nil {
				return err
			}
			if mode != models.PlaybackModeSequential && mode != models.PlaybackModeShuffle {
				return fmt.Errorf("invalid playback_mode '%s', expected SEQUENTIAL or SHUFFLE", mode)
			}
		}

	default:
		return fmt.Errorf("%w: '%s'", dto.ErrUnsupportedEventType, item.EventType)
	}

	return nil
}

func requirePlaybackFields(item *dto.EventItemDTO) error {
	if item.SessionID == nil || strings.TrimSpace(*item.SessionID) == "" {
		return dto.ErrMissingSessionID
	}
	if item.TrackID == nil || strings.TrimSpace(*item.TrackID) == "" {
		return dto.ErrMissingTrackID
	}
	return nil
}

func getNonNegativeNumber(props map[string]interface{}, key string, required bool) (float64, error) {
	val, exists := props[key]
	if !exists {
		if required {
			return 0, fmt.Errorf("missing required property '%s'", key)
		}
		return 0, nil
	}

	var num float64
	switch v := val.(type) {
	case float64:
		num = v
	case float32:
		num = float64(v)
	case int:
		num = float64(v)
	case int32:
		num = float64(v)
	case int64:
		num = float64(v)
	default:
		return 0, fmt.Errorf("property '%s' must be a numeric value, got %T", key, val)
	}

	if num < 0 {
		return 0, fmt.Errorf("property '%s' must be non-negative, got %v", key, num)
	}

	return num, nil
}

func getString(props map[string]interface{}, key string, required bool) (string, error) {
	val, exists := props[key]
	if !exists {
		if required {
			return "", fmt.Errorf("missing required property '%s'", key)
		}
		return "", nil
	}

	str, ok := val.(string)
	if !ok {
		return "", fmt.Errorf("property '%s' must be a string", key)
	}

	if required && strings.TrimSpace(str) == "" {
		return "", fmt.Errorf("property '%s' cannot be empty", key)
	}

	return str, nil
}
