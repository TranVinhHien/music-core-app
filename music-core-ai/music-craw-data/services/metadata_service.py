import requests
from typing import Optional, Dict, Any, List

class MetadataService:
    """
    Standardized metadata resolution service (Title, Artist, Album, Cover Art, Year, Genre).
    Combines iTunes API and Deezer API, supporting full album tracklist resolution.
    """

    @staticmethod
    def _format_track(item: Dict[str, Any], source: str = "itunes") -> Dict[str, Any]:
        if source == "itunes":
            cover_url = item.get("artworkUrl100", "")
            if cover_url:
                cover_url = cover_url.replace("100x100bb", "1400x1400bb")

            release_date = item.get("releaseDate", "")
            year = release_date[:4] if release_date else ""

            return {
                "source": "itunes",
                "title": item.get("trackName"),
                "artist": item.get("artistName"),
                "album": item.get("collectionName"),
                "album_id": item.get("collectionId"),
                "genre": item.get("primaryGenreName"),
                "year": year,
                "release_date": release_date,
                "duration_ms": item.get("trackTimeMillis"),
                "track_number": item.get("trackNumber", 1),
                "disc_number": item.get("discNumber", 1),
                "cover_url": cover_url
            }
        else:  # deezer
            album = item.get("album", {})
            artist = item.get("artist", {})
            return {
                "source": "deezer",
                "title": item.get("title"),
                "artist": artist.get("name"),
                "album": album.get("title"),
                "album_id": album.get("id"),
                "genre": "",
                "year": "",
                "release_date": "",
                "duration_ms": item.get("duration", 0) * 1000,
                "track_number": item.get("track_position", 1),
                "disc_number": item.get("disk_number", 1),
                "cover_url": album.get("cover_xl") or album.get("cover_big") or album.get("cover_medium")
            }

    @classmethod
    def get_album_tracks(cls, album_name: str, artist_name: str = "") -> List[Dict[str, Any]]:
        """
        Retrieves the complete tracklist for an album.
        Queries iTunes Lookup API first, falling back to Deezer.
        """
        search_query = f"{album_name} {artist_name}".strip()
        print(f"[MetadataService] Querying complete tracklist for Album: '{search_query}'...")

        collection_id = None
        album_meta = None

        # 1. Search album via entity=album
        try:
            resp = requests.get(
                "https://itunes.apple.com/search",
                params={"term": search_query, "entity": "album", "limit": 5},
                timeout=10
            )
            if resp.status_code == 200:
                results = resp.json().get("results", [])
                # Prioritize album with most tracks if multiple matches exist
                for r in results:
                    if r.get("trackCount", 0) > 1 or not collection_id:
                        collection_id = r.get("collectionId")
                        album_meta = r
                        if r.get("trackCount", 0) > 1:
                            break
        except Exception as e:
            print(f"[MetadataService] Error searching iTunes album: {e}")

        # 2. If single-track result or missing, search via entity=song
        if not collection_id or (album_meta and album_meta.get("trackCount", 0) <= 1):
            try:
                song_resp = requests.get(
                    "https://itunes.apple.com/search",
                    params={"term": search_query, "entity": "song", "limit": 10},
                    timeout=10
                )
                if song_resp.status_code == 200:
                    for s in song_resp.json().get("results", []):
                        col_name = s.get("collectionName", "").lower()
                        if album_name.lower() in col_name and not "single" in col_name:
                            collection_id = s.get("collectionId")
                            break
            except Exception as e:
                print(f"[MetadataService] Error finding collection via iTunes song: {e}")

        # 3. Fetch full tracklist via iTunes Lookup API
        if collection_id:
            try:
                lookup_resp = requests.get(
                    "https://itunes.apple.com/lookup",
                    params={"id": collection_id, "entity": "song"},
                    timeout=10
                )
                if lookup_resp.status_code == 200:
                    items = lookup_resp.json().get("results", [])
                    tracks = [
                        cls._format_track(item, source="itunes")
                        for item in items if item.get("wrapperType") == "track"
                    ]
                    if tracks:
                        # Sort by discNumber and trackNumber
                        tracks.sort(key=lambda t: (t.get("disc_number", 1), t.get("track_number", 1)))
                        print(f"[MetadataService] ✓ Found {len(tracks)} tracks in Album '{album_name}' from iTunes!")
                        return tracks
            except Exception as e:
                print(f"[MetadataService] Error in iTunes album lookup: {e}")

        # 4. Fallback to Deezer if not found on iTunes
        try:
            dz_album_resp = requests.get(
                "https://api.deezer.com/search/album",
                params={"q": search_query, "limit": 1},
                timeout=10
            )
            if dz_album_resp.status_code == 200:
                dz_data = dz_album_resp.json().get("data", [])
                if dz_data:
                    dz_alb = dz_data[0]
                    dz_alb_id = dz_alb.get("id")
                    tracks_resp = requests.get(
                        f"https://api.deezer.com/album/{dz_alb_id}/tracks",
                        params={"limit": 100},
                        timeout=10
                    )
                    if tracks_resp.status_code == 200:
                        tr_items = tracks_resp.json().get("data", [])
                        tracks = []
                        for t in tr_items:
                            t["album"] = dz_alb
                            tracks.append(cls._format_track(t, source="deezer"))
                        if tracks:
                            print(f"[MetadataService] ✓ Found {len(tracks)} tracks in Album '{album_name}' from Deezer!")
                            return tracks
        except Exception as e:
            print(f"[MetadataService] Error searching Deezer album: {e}")

        return []

    @classmethod
    def search_candidates(cls, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Searches track candidates matching the query."""
        results = []
        try:
            resp = requests.get(
                "https://itunes.apple.com/search",
                params={"term": query, "entity": "song", "limit": limit},
                timeout=10
            )
            if resp.status_code == 200:
                for item in resp.json().get("results", []):
                    results.append(cls._format_track(item, source="itunes"))
        except Exception as e:
            print(f"[MetadataService] Error searching iTunes: {e}")

        if len(results) < limit:
            try:
                dz_resp = requests.get(
                    "https://api.deezer.com/search",
                    params={"q": query, "limit": limit - len(results)},
                    timeout=10
                )
                if dz_resp.status_code == 200:
                    for item in dz_resp.json().get("data", []):
                        results.append(cls._format_track(item, source="deezer"))
            except Exception as e:
                print(f"[MetadataService] Error searching Deezer: {e}")

        return results

    @classmethod
    def get_metadata(cls, query: str) -> Optional[Dict[str, Any]]:
        """Retrieves best matching metadata for a single track."""
        cands = cls.search_candidates(query, limit=1)
        return cands[0] if cands else None
