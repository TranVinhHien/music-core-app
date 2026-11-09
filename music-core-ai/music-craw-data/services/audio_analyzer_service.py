import os
import sys
import time
from typing import Dict, Any, Optional

# Ensure music-listening module can be imported
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
LISTENING_DIR = os.path.abspath(os.path.join(CURRENT_DIR, "..", "..", "music-listening"))
if LISTENING_DIR not in sys.path and os.path.exists(LISTENING_DIR):
    sys.path.insert(0, LISTENING_DIR)

try:
    from analyzer import AudioAnalyzer
except ImportError:
    AudioAnalyzer = None


class AudioAnalyzerService:
    """
    Acoustic feature extraction service (BPM, Key, Camelot, Cue points, Downbeats, Energy, LUFS)
    using the AudioAnalyzer engine from music-listening.
    """

    def __init__(self, sample_rate: int = 22050):
        if AudioAnalyzer is None:
            raise ImportError(
                f"Cannot import AudioAnalyzer from {LISTENING_DIR}. Please check the music-listening directory and dependencies."
            )
        self.analyzer = AudioAnalyzer(sample_rate=sample_rate)

    def analyze_audio(self, file_path: str, track_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Analyzes a local audio file and returns standard SaveTrackAudioAnalysisDto payload for the Catalog API.
        """
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Audio file not found: {file_path}")

        start_time = time.time()
        profile = self.analyzer.analyze(file_path=file_path, track_id=track_id)
        elapsed = time.time() - start_time

        payload = {
            "cueInMs": profile.cue_in_ms,
            "cueOutMs": profile.cue_out_ms,
            "durationMs": profile.duration_ms,
            "bpm": profile.bpm,
            "firstDownbeatMs": profile.first_downbeat_ms,
            "downbeats": profile.downbeats,
            "key": profile.key,
            "scale": profile.scale,
            "camelotKey": profile.camelot_key,
            "energy": profile.energy,
            "loudnessLufs": profile.loudness_lufs,
            "recommendedTransition": profile.recommended_transition,
            "recommendedCrossfadeMs": profile.recommended_crossfade_ms,
            "analysisStatus": "COMPLETED",
        }

        return {
            "payload": payload,
            "elapsed_seconds": round(elapsed, 2),
            "summary": {
                "bpm": profile.bpm,
                "camelot": profile.camelot_key,
                "key_scale": f"{profile.key} {profile.scale}",
                "energy": profile.energy,
                "lufs": profile.loudness_lufs,
                "cues": f"{profile.cue_in_ms}ms -> {profile.cue_out_ms}ms",
                "recommended_transition": profile.recommended_transition
            }
        }

    def build_failed_payload(self, duration_ms: int = 0, error_message: str = "") -> Dict[str, Any]:
        """Builds error payload if acoustic feature extraction fails."""
        return {
            "cueInMs": 0,
            "cueOutMs": 0,
            "durationMs": duration_ms or 0,
            "analysisStatus": "FAILED",
            "errorMessage": error_message[:255] if error_message else "Analysis failed",
        }
