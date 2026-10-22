import os
import shutil
import subprocess
import tempfile
from typing import Tuple
import numpy as np
import librosa


def convert_to_wav(input_path: str) -> str:
    """
    Convert an unsupported audio format (like .m4a, .aac) to a temporary 16-bit PCM WAV file.
    Uses macOS native 'afconvert' if available, otherwise falls back to 'ffmpeg'.
    """
    temp_wav = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
    temp_wav_path = temp_wav.name
    temp_wav.close()

    # Strategy 1: Check for macOS built-in afconvert
    if shutil.which("afconvert"):
        cmd = ["afconvert", "-f", "WAVE", "-d", "LEI16", input_path, temp_wav_path]
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if res.returncode == 0 and os.path.exists(temp_wav_path) and os.path.getsize(temp_wav_path) > 0:
            return temp_wav_path

    # Strategy 2: Check for ffmpeg
    if shutil.which("ffmpeg"):
        cmd = ["ffmpeg", "-y", "-i", input_path, "-ac", "1", "-ar", "22050", temp_wav_path]
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if res.returncode == 0 and os.path.exists(temp_wav_path) and os.path.getsize(temp_wav_path) > 0:
            return temp_wav_path

    # If both fail, clean up and raise error
    if os.path.exists(temp_wav_path):
        os.remove(temp_wav_path)
    raise RuntimeError(
        f"Unable to decode audio file '{input_path}'. Neither 'afconvert' (macOS) nor 'ffmpeg' is installed or functional."
    )


def load_audio(file_path: str, target_sr: int = 22050) -> Tuple[np.ndarray, int]:
    """
    Load an audio file into a mono float numpy array normalized between -1.0 and 1.0.
    Automatically handles .m4a, .aac, .mp3, .wav, .flac via librosa and conversion fallbacks.
    """
    if not os.path.isfile(file_path):
        raise FileNotFoundError(f"Audio file not found: {file_path}")

    # First attempt: standard librosa/soundfile loading
    try:
        y, sr = librosa.load(file_path, sr=target_sr, mono=True)
        return y, sr
    except Exception:
        # Second attempt: convert to temporary WAV (e.g. for Apple M4A/AAC)
        temp_wav = convert_to_wav(file_path)
        try:
            y, sr = librosa.load(temp_wav, sr=target_sr, mono=True)
            return y, sr
        finally:
            if os.path.exists(temp_wav):
                os.remove(temp_wav)
