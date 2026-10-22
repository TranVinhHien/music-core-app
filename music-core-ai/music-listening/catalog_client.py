import os
from typing import Any, Dict, List, Optional
import requests


class CatalogClient:
    """HTTP Client for communicating with music-catalog-service."""

    def __init__(self, base_url: Optional[str] = None):
        self.base_url = (base_url or os.getenv("CATALOG_SERVICE_URL", "http://localhost:3002/api/v1/catalog")).rstrip("/")

    def get_pending_tracks(self, page: int = 1, limit: int = 20) -> List[Dict[str, Any]]:
        """
        Fetch a page of tracks that do not have completed audio analysis.
        """
        url = f"{self.base_url}/tracks"
        params = {
            "page": page,
            "limit": limit,
            "analysisStatus": "PENDING",
        }
        resp = requests.get(url, params=params, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        return data.get("data", [])

    def get_track_by_id(self, track_id: str) -> Dict[str, Any]:
        """
        Fetch single track with details and audio analysis.
        """
        url = f"{self.base_url}/tracks/{track_id}"
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        return resp.json().get("data", {})

    def update_audio_analysis(self, track_id: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        """
        Update or upsert track audio analysis results.
        """
        url = f"{self.base_url}/tracks/{track_id}/audio-analysis"
        resp = requests.put(url, json=payload, timeout=15)
        resp.raise_for_status()
        return resp.json().get("data", {})
