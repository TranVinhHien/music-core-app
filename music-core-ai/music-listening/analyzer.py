import math
from typing import Dict, List, Optional, Tuple
import numpy as np
import scipy.signal
import librosa

from audio_loader import load_audio
from models import AudioTransitionProfile

# Pitch classes standard (12 semitones)
PITCH_CLASSES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

# Krumhansl-Schmuckler Key Profiles
MAJOR_PROFILE = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88])
MINOR_PROFILE = np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17])

# Camelot Wheel Mapping (Key, Scale) -> Camelot Code
CAMELOT_MAPPING: Dict[Tuple[str, str], str] = {
    ("B", "Major"): "1B", ("G#", "Minor"): "1A", ("Ab", "Minor"): "1A",
    ("F#", "Major"): "2B", ("Gb", "Major"): "2B", ("D#", "Minor"): "2A", ("Eb", "Minor"): "2A",
    ("C#", "Major"): "3B", ("Db", "Major"): "3B", ("A#", "Minor"): "3A", ("Bb", "Minor"): "3A",
    ("G#", "Major"): "4B", ("Ab", "Major"): "4B", ("F", "Minor"): "4A",
    ("D#", "Major"): "5B", ("Eb", "Major"): "5B", ("C", "Minor"): "5A",
    ("A#", "Major"): "6B", ("Bb", "Major"): "6B", ("G", "Minor"): "6A",
    ("F", "Major"): "7B", ("D", "Minor"): "7A",
    ("C", "Major"): "8B", ("A", "Minor"): "8A",
    ("G", "Major"): "9B", ("E", "Minor"): "9A",
    ("D", "Major"): "10B", ("B", "Minor"): "10A",
    ("A", "Major"): "11B", ("F#", "Minor"): "11A",
    ("E", "Major"): "12B", ("C#", "Minor"): "12A"
}


def calculate_k_weighted_lufs(y: np.ndarray, sr: int) -> float:
    """
    Compute integrated loudness (LUFS) according to ITU-R BS.1770 / EBU R128.
    Applies high-shelf pre-filter (stage 1) and RLB high-pass filter (stage 2).
    """
    if len(y) == 0 or np.all(y == 0):
        return -70.0

    # Stage 1: High-shelf filter (gain +4dB around 1.5kHz)
    b_shelf = [1.53512485958697, -2.69169618940638, 1.19839281085285]
    a_shelf = [1.0, -1.69065929318241, 0.73248077421585]
    y_shelf = scipy.signal.lfilter(b_shelf, a_shelf, y)

    # Stage 2: High-pass RLB filter (cutoff ~100Hz)
    b_hp = [1.0, -2.0, 1.0]
    a_hp = [1.0, -1.99004745483398, 0.99007225035372]
    y_k = scipy.signal.lfilter(b_hp, a_hp, y_shelf)

    mean_square = np.mean(y_k ** 2)
    if mean_square <= 1e-10:
        return -70.0
    
    lufs = -0.691 + 10.0 * np.log10(mean_square)
    return round(float(lufs), 1)


class AudioAnalyzer:
    """
    Analyzes an audio file to extract seamless transition profiles:
    cue points, tempo, downbeats, key, camelot code, loudness, and transition recommendations.
    """

    def __init__(self, sample_rate: int = 22050, silence_top_db: float = 40.0):
        self.sample_rate = sample_rate
        self.silence_top_db = silence_top_db

    def _detect_key_and_camelot(self, y: np.ndarray, sr: int) -> Tuple[str, str, str]:
        """Determine key, scale, and Camelot code using chromagram correlation."""
        chroma = librosa.feature.chroma_cqt(y=y, sr=sr)
        chroma_avg = np.mean(chroma, axis=1)

        best_score = -float("inf")
        detected_key = "C"
        detected_scale = "Major"

        for i in range(12):
            maj_rotated = np.roll(MAJOR_PROFILE, i)
            corr_maj = np.corrcoef(chroma_avg, maj_rotated)[0, 1]
            if corr_maj > best_score:
                best_score = corr_maj
                detected_key = PITCH_CLASSES[i]
                detected_scale = "Major"

            min_rotated = np.roll(MINOR_PROFILE, i)
            corr_min = np.corrcoef(chroma_avg, min_rotated)[0, 1]
            if corr_min > best_score:
                best_score = corr_min
                detected_key = PITCH_CLASSES[i]
                detected_scale = "Minor"

        camelot_code = CAMELOT_MAPPING.get((detected_key, detected_scale), "8B")
        return detected_key, detected_scale, camelot_code

    def _estimate_energy(self, y: np.ndarray) -> float:
        """Estimate normalized energy score between 0.0 and 1.0 based on RMS distribution."""
        rms = librosa.feature.rms(y=y)[0]
        mean_rms = float(np.mean(rms))
        peak_rms = float(np.percentile(rms, 95))
        score = (mean_rms * 2.5 + peak_rms * 1.5) / 2.0
        clamped = max(0.05, min(0.99, score))
        return round(clamped, 2)

    def analyze(self, file_path: str, track_id: Optional[str] = None) -> AudioTransitionProfile:
        """
        Run full transition analysis on a local audio file.
        """
        # 1. Load audio data
        y, sr = load_audio(file_path, target_sr=self.sample_rate)
        total_duration_sec = len(y) / sr
        duration_ms = int(total_duration_sec * 1000)

        # 2. Trim silence (start & end)
        _, trim_indices = librosa.effects.trim(y, top_db=self.silence_top_db)
        raw_start_sec = librosa.samples_to_time(trim_indices[0], sr=sr)
        raw_end_sec = librosa.samples_to_time(trim_indices[1], sr=sr)

        # 3. Beat and tempo tracking
        tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
        bpm = float(tempo[0] if hasattr(tempo, "__iter__") else tempo)
        bpm = round(bpm, 1)

        beat_times = librosa.frames_to_time(beat_frames, sr=sr)

        # 4. Extract downbeats (Bar boundaries in 4/4 meter)
        downbeats_ms: List[int] = []
        first_downbeat_ms = int(raw_start_sec * 1000)

        if len(beat_times) > 0:
            # Find the first beat occurring after or near the audible start
            first_idx = 0
            for i, bt in enumerate(beat_times):
                if bt >= raw_start_sec - 0.05:
                    first_idx = i
                    break

            # Collect downbeats every 4 beats
            downbeats_sec = [beat_times[i] for i in range(first_idx, len(beat_times), 4)]
            downbeats_ms = [int(t * 1000) for t in downbeats_sec]
            if downbeats_ms:
                first_downbeat_ms = downbeats_ms[0]

        # 5. Calculate Cue-In (start playback on audible start or aligned downbeat)
        cue_in_ms = int(raw_start_sec * 1000)
        # If the first downbeat is within 500ms of raw start, align to downbeat
        if 0 <= (first_downbeat_ms - cue_in_ms) <= 500:
            cue_in_ms = first_downbeat_ms

        # 6. Calculate Cue-Out (outro transition initiation point)
        # Standard DJ transition window: 16 beats (or ~8-12 seconds before audible end)
        beat_duration_sec = 60.0 / bpm if bpm > 20 else 0.5
        outro_window_sec = min(16.0, max(6.0, 16 * beat_duration_sec))
        target_cue_out_sec = max(raw_start_sec + 15.0, raw_end_sec - outro_window_sec)

        # Align cue_out to the nearest downbeat before audible end
        cue_out_ms = int(target_cue_out_sec * 1000)
        if downbeats_ms:
            # Find downbeat closest to target_cue_out_sec
            valid_downbeats = [db for db in downbeats_ms if db < (raw_end_sec * 1000 - 2000)]
            if valid_downbeats:
                cue_out_ms = min(valid_downbeats, key=lambda db: abs(db - int(target_cue_out_sec * 1000)))

        # Ensure cue_out does not exceed duration
        cue_out_ms = min(cue_out_ms, duration_ms - 2000)
        cue_out_ms = max(cue_out_ms, cue_in_ms + 10000)

        # 7. Key and Camelot wheel analysis
        key, scale, camelot = self._detect_key_and_camelot(y, sr)

        # 8. Energy and loudness
        energy = self._estimate_energy(y)
        lufs = calculate_k_weighted_lufs(y, sr)

        # 9. Recommendations
        recommended_crossfade_ms = max(4000, min(12000, duration_ms - cue_out_ms))
        if bpm >= 115 and energy >= 0.55:
            transition_style = "BEAT_CROSSFADE"
        elif energy <= 0.35:
            transition_style = "SMOOTH_FADE"
        else:
            transition_style = "SMOOTH_FADE"

        return AudioTransitionProfile(
            track_id=track_id,
            file_path=file_path,
            duration_ms=duration_ms,
            cue_in_ms=cue_in_ms,
            cue_out_ms=cue_out_ms,
            bpm=bpm,
            first_downbeat_ms=first_downbeat_ms,
            downbeats=downbeats_ms,
            key=key,
            scale=scale,
            camelot_key=camelot,
            energy=energy,
            loudness_lufs=lufs,
            recommended_transition=transition_style,
            recommended_crossfade_ms=recommended_crossfade_ms
        )
