from datetime import datetime, timezone
from typing import List, Optional
from pydantic import BaseModel, Field


class AudioTransitionProfile(BaseModel):
    """Data model representing the analyzed audio transition parameters for a music track."""
    track_id: Optional[str] = Field(default=None, description="Unique track identifier (UUID or external ID)")
    file_path: str = Field(..., description="File path of the analyzed audio track")
    duration_ms: int = Field(..., description="Total track duration in milliseconds")
    
    # 1. Primary Transition Cue Points
    cue_in_ms: int = Field(..., description="Point where audio/music actually starts after initial silence (ms)")
    cue_out_ms: int = Field(..., description="Point where outro / crossfade transition should initiate (ms)")
    
    # 2. Rhythm & Phrasing
    bpm: float = Field(..., description="Tempo in Beats Per Minute")
    first_downbeat_ms: int = Field(..., description="Timestamp of the first downbeat (Bar 1, Beat 1) in ms")
    downbeats: List[int] = Field(default_factory=list, description="List of downbeat timestamps in ms")
    
    # 3. Harmonic & Key Information
    key: str = Field(..., description="Detected musical key root (e.g., 'C', 'A#')")
    scale: str = Field(..., description="Key scale ('Major' or 'Minor')")
    camelot_key: str = Field(..., description="Camelot harmonic mixing code (e.g., '8B', '3A')")
    
    # 4. Energy & Loudness
    energy: float = Field(..., description="Normalized track energy from 0.0 (very calm) to 1.0 (very energetic)")
    loudness_lufs: float = Field(..., description="Estimated integrated loudness in LUFS (EBU R128)")
    
    # 5. Playback Transition Recommendation
    recommended_transition: str = Field(
        ...,
        description="Transition style recommendation ('BEAT_CROSSFADE', 'SMOOTH_FADE', 'DROP_SWAP')"
    )
    recommended_crossfade_ms: int = Field(
        default=6000,
        description="Recommended duration for crossfading into the next track in milliseconds"
    )
    
    analyzed_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat(),
        description="UTC timestamp when the analysis was performed"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "track_id": "111",
                "file_path": "/path/to/song.m4a",
                "duration_ms": 204520,
                "cue_in_ms": 740,
                "cue_out_ms": 196500,
                "bpm": 86.2,
                "first_downbeat_ms": 810,
                "key": "A#",
                "scale": "Minor",
                "camelot_key": "3A",
                "energy": 0.65,
                "loudness_lufs": -12.4,
                "recommended_transition": "SMOOTH_FADE",
                "recommended_crossfade_ms": 6000
            }
        }
