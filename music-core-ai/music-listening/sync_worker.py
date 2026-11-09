import argparse
import os
import sys
import time
from analyzer import AudioAnalyzer
from audio_resolver import resolve_audio_file
from catalog_client import CatalogClient


def process_batch(client: CatalogClient, analyzer: AudioAnalyzer, limit: int = 5) -> int:
    """Process a batch of unanalyzed tracks. Returns the number of successfully processed tracks."""
    print(f"\n[AI Worker] Fetching up to {limit} unanalyzed tracks from Catalog Service...")
    tracks = client.get_pending_tracks(limit=limit)
    if not tracks:
        print("[AI Worker] No pending tracks to analyze.")
        return 0

    print(f"[AI Worker] Found {len(tracks)} pending tracks. Starting analysis pipeline...")
    success_count = 0

    for idx, track in enumerate(tracks, 1):
        track_id = track.get("id")
        title = track.get("title", "Unknown Title")
        file_url = track.get("fileUrl")

        print(f"\n--- [{idx}/{len(tracks)}] Track ID: {track_id} | Title: '{title}' ---")
        if not file_url:
            print(f"Skipping track '{title}' ({track_id}): fileUrl is missing.")
            continue

        temp_path = None
        is_temp = False
        try:
            print(f"Resolving audio file for: {file_url[:80]}...")
            file_path, is_temp = resolve_audio_file(file_url, track_title=title)
            if is_temp:
                temp_path = file_path
            print(f"Loaded audio from: {file_path}")

            print("Analyzing audio features (BPM, Cues, Key, Camelot, Energy, LUFS)...")
            start_t = time.time()
            profile = analyzer.analyze(file_path=file_path, track_id=track_id)
            elapsed = time.time() - start_t

            print(
                f"Analysis completed in {elapsed:.1f}s: "
                f"BPM={profile.bpm}, Key={profile.camelot_key} ({profile.key} {profile.scale}), "
                f"LUFS={profile.loudness_lufs}, Cues=[{profile.cue_in_ms}ms -> {profile.cue_out_ms}ms]"
            )

            # Build payload matching SaveTrackAudioAnalysisDto (camelCase)
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

            print("Syncing analysis result to Catalog Service...")
            client.update_audio_analysis(track_id, payload)
            print(f"Successfully updated track '{title}' ({track_id}) in Catalog Service.")
            success_count += 1

        except Exception as e:
            print(f"Error analyzing track '{title}' ({track_id}): {e}", file=sys.stderr)
            try:
                # Mark as FAILED so it won't be retried indefinitely
                client.update_audio_analysis(track_id, {
                    "cueInMs": 0,
                    "cueOutMs": 0,
                    "durationMs": track.get("durationMs") or 0,
                    "analysisStatus": "FAILED",
                    "errorMessage": str(e),
                })
            except Exception as update_err:
                print(f"Failed to record error status in catalog: {update_err}", file=sys.stderr)

        finally:
            if is_temp and temp_path and os.path.exists(temp_path):
                try:
                    os.remove(temp_path)
                except OSError:
                    pass

    return success_count


def main():
    parser = argparse.ArgumentParser(description="AI Worker for analyzing and syncing track audio profiles.")
    parser.add_argument("--limit", type=int, default=5, help="Number of tracks to process per batch.")
    parser.add_argument("--loop", action="store_true", help="Run continuously in a polling loop.")
    parser.add_argument("--interval", type=int, default=15, help="Sleep interval (seconds) between loops.")
    args = parser.parse_args()

    client = CatalogClient()
    analyzer = AudioAnalyzer()

    print("==================================================")
    print("🚀 Music Listening AI Worker Initialized")
    print(f"Target Catalog Service: {client.base_url}")
    print("==================================================")

    if args.loop:
        while True:
            processed = process_batch(client, analyzer, limit=args.limit)
            if processed == 0:
                print(f"Waiting {args.interval}s before checking for new tracks...")
            time.sleep(args.interval)
    else:
        processed = process_batch(client, analyzer, limit=args.limit)
        print(f"\n[AI Worker] Batch complete. Successfully processed: {processed} tracks.")


if __name__ == "__main__":
    main()
