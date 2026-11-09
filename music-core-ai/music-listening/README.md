# Music Listening - Audio Transition Analyzer (AI Engine)

Acoustic and cue-point transition analyzer module powering the intelligent listening system (Auto DJ / Smart Crossfade) in Level 3 of Personal Music App.

## Features
- **Silence Trimming & Cue Points**: Automatically detects and trims leading/trailing silence, calculating `cue_in_ms` (audio start cue) and `cue_out_ms` (transition cue to next track).
- **Rhythm & Beat Matching**: Measures `bpm`, the first downbeat marker (`first_downbeat_ms`), and a list of all beat positions (`downbeats`) for rhythm-aligned track transitions.
- **Harmonic Mixing**: Detects musical key (`key`, `scale`) and maps to the Camelot Wheel (`camelot_key`, e.g., `8A`, `3A`) for harmonious transitions without dissonance.
- **Dynamic Normalization**: Estimates musical energy (`energy` from 0.0 to 1.0) and loudness according to EBU R128 standards (`loudness_lufs`).
- **Transition Strategy**: Suggests transition style (`recommended_transition`) and optimal crossfade duration (`recommended_crossfade_ms`).
- **Multi-Format Audio Compatibility**: Broad support for `.mp3`, `.m4a`, `.aac`, `.wav`, and `.flac` with intelligent fallback mechanisms (using macOS CoreAudio `afconvert` or `ffmpeg`).

## Environment Setup

```bash
cd music-core-ai/music-listening
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## CLI Usage

### 1. Analyze a track and output JSON to console:
```bash
python main.py --file "/path/to/song.m4a" --track-id "111"
```

### 2. Omit downbeats list (core metrics only):
```bash
python main.py --file "/path/to/song.m4a" --track-id "111" --omit-downbeats
```

### 3. Save analysis output to JSON file:
```bash
python main.py --file "/path/to/song.m4a" --track-id "111" --output "/path/to/result.json"
```

### 4. Automated Catalog Service Synchronization (Sync Worker):
Worker periodically queries `GET /api/v1/catalog/tracks?analysisStatus=PENDING` for unanalyzed tracks, downloads the audio, executes acoustic feature extraction, and calls `PUT /api/v1/catalog/tracks/:id/audio-analysis` to update catalog records:

```bash
# Analyze a single batch of 5 tracks:
python sync_worker.py --limit 5

# Run as a continuous daemon polling periodically:
python sync_worker.py --loop --interval 15
```

## Output JSON Schema

```json
{
  "track_id": "111",
  "file_path": "/path/to/song.m4a",
  "duration_ms": 204519,
  "cue_in_ms": 812,
  "cue_out_ms": 198623,
  "bpm": 172.3,
  "first_downbeat_ms": 812,
  "key": "A#",
  "scale": "Minor",
  "camelot_key": "3A",
  "energy": 0.41,
  "loudness_lufs": -14.4,
  "recommended_transition": "SMOOTH_FADE",
  "recommended_crossfade_ms": 5896,
  "analyzed_at": "2026-10-22T13:10:36.041709+00:00"
}
```
