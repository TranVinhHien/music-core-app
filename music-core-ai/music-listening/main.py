import argparse
import json
import os
import sys
from analyzer import AudioAnalyzer


def parse_args():
    parser = argparse.ArgumentParser(
        description="Music Audio Transition Analyzer - Extracts cue points, BPM, key, and transition profile."
    )
    parser.add_argument(
        "-f", "--file",
        required=True,
        help="Path to the audio file (supported: .mp3, .m4a, .wav, .flac, .aac)"
    )
    parser.add_argument(
        "-t", "--track-id",
        default=None,
        help="Custom track identifier (e.g., 111, UUID). Defaults to filename without extension."
    )
    parser.add_argument(
        "-o", "--output",
        default=None,
        help="Path to save output JSON. If not specified, prints to stdout."
    )
    parser.add_argument(
        "--omit-downbeats",
        action="store_true",
        help="Omit the full downbeat array in the output JSON for a more concise response."
    )
    return parser.parse_args()


def main():
    args = parse_args()

    if not os.path.exists(args.file):
        print(f"Error: File not found: {args.file}", file=sys.stderr)
        sys.exit(1)

    track_id = args.track_id
    if not track_id:
        track_id = os.path.splitext(os.path.basename(args.file))[0]

    analyzer = AudioAnalyzer()
    try:
        profile = analyzer.analyze(file_path=args.file, track_id=track_id)
        
        # Convert Pydantic model to dict
        result_dict = profile.model_dump()
        
        if args.omit_downbeats:
            result_dict.pop("downbeats", None)

        json_output = json.dumps(result_dict, indent=2, ensure_ascii=False)

        if args.output:
            with open(args.output, "w", encoding="utf-8") as f:
                f.write(json_output)
            print(f"Successfully saved transition profile to: {args.output}")
        else:
            print(json_output)

    except Exception as e:
        print(f"Analysis failed: {str(e)}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
