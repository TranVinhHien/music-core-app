import requests
from typing import Dict, Any, Optional, List
from services.artist_parser import ArtistParser

class CatalogService:
    """
    Client communicating with the NestJS music-catalog-service over REST API.
    Handles artist parsing (PRIMARY, FEAT), Album, and Track registration.
    """

    def __init__(self, base_url: str = "http://localhost:3002/api/v1/catalog"):
        self.base_url = base_url.rstrip("/")

    def _headers(self) -> Dict[str, str]:
        return {
            "Content-Type": "application/json",
            "X-User-Roles": "admin"
        }

    def find_or_create_artist(self, artist_name: str, image_url: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """
        Finds an artist by name; automatically creates a new record if not found.
        """
        clean_name = artist_name.strip()
        if not clean_name:
            return None

        # 1. Look up in existing artists
        try:
            get_resp = requests.get(
                f"{self.base_url}/artists",
                headers=self._headers(),
                params={"limit": 100},
                timeout=5
            )
            if get_resp.status_code == 200:
                result = get_resp.json()
                items = result.get("data", {}).get("items", []) if isinstance(result.get("data"), dict) else result.get("data", [])
                for item in items:
                    if item.get("name", "").strip().lower() == clean_name.lower():
                        return item
        except Exception as e:
            print(f"[CatalogService] Error connecting to Artists list: {e}")

        # 2. Create new artist if not found
        try:
            payload = {
                "name": clean_name,
                "bio": f"Artist catalog entry",
                "imageUrl": image_url or ""
            }
            post_resp = requests.post(
                f"{self.base_url}/artists",
                headers=self._headers(),
                json=payload,
                timeout=5
            )
            if post_resp.status_code in [200, 201]:
                res_data = post_resp.json()
                artist = res_data.get("data", res_data)
                print(f"[CatalogService] ✓ Created new Artist: {clean_name} (ID: {artist.get('id')})")
                return artist
            else:
                print(f"[CatalogService] Failed to create Artist '{clean_name}': {post_resp.status_code} - {post_resp.text}")
        except Exception as e:
            print(f"[CatalogService] Exception creating Artist: {e}")

        return None

    def find_or_create_album(self, album_title: str, artist_id: Optional[str] = None, release_date: Optional[str] = None, cover_image_url: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """
        Finds an album by title; automatically creates a new record if not found.
        """
        clean_title = album_title.strip()
        if not clean_title:
            return None

        # 1. Search for existing album
        try:
            get_resp = requests.get(
                f"{self.base_url}/albums",
                headers=self._headers(),
                params={"limit": 100},
                timeout=5
            )
            if get_resp.status_code == 200:
                result = get_resp.json()
                items = result.get("data", {}).get("items", []) if isinstance(result.get("data"), dict) else result.get("data", [])
                for item in items:
                    if item.get("title", "").strip().lower() == clean_title.lower():
                        return item
        except Exception as e:
            print(f"[CatalogService] Error connecting to Albums list: {e}")

        # 2. Create new album
        try:
            payload: Dict[str, Any] = {
                "title": clean_title,
                "coverImageUrl": cover_image_url or "",
            }
            if release_date and len(release_date) >= 10:
                payload["releaseDate"] = release_date[:10]
            if artist_id:
                payload["artists"] = [{"artistId": artist_id, "position": 1}]

            post_resp = requests.post(
                f"{self.base_url}/albums",
                headers=self._headers(),
                json=payload,
                timeout=5
            )
            if post_resp.status_code in [200, 201]:
                res_data = post_resp.json()
                album = res_data.get("data", res_data)
                print(f"[CatalogService] ✓ Created new Album: {clean_title} (ID: {album.get('id')})")
                return album
            else:
                print(f"[CatalogService] Failed to create Album '{clean_title}': {post_resp.status_code} - {post_resp.text}")
        except Exception as e:
            print(f"[CatalogService] Exception creating Album: {e}")

        return None

    def register_track_full(self,
                            raw_title: str,
                            raw_artist: str,
                            file_url: str,
                            album_title: Optional[str] = None,
                            cover_image_url: Optional[str] = None,
                            duration_ms: Optional[int] = None,
                            release_date: Optional[str] = None,
                            track_number: Optional[int] = None,
                            disc_number: Optional[int] = None,
                            sources: Optional[List[Dict[str, str]]] = None) -> Dict[str, Any]:
        """
        Registers a complete Track:
        - Separates multiple artists (PRIMARY, FEAT) from raw_artist and raw_title.
        - Creates Artist records if they do not exist.
        - Creates Album record if present.
        - Registers Track with relational artist mappings.
        """
        # 1. Parse artist list and normalize track title
        parsed_artists, clean_title = ArtistParser.parse(raw_artist, raw_title)
        
        # 2. Fetch or create artist records
        track_artists_dto = []
        primary_artist_id = None

        for art in parsed_artists:
            artist_rec = self.find_or_create_artist(art["name"], image_url=cover_image_url)
            if artist_rec and artist_rec.get("id"):
                art_id = artist_rec["id"]
                track_artists_dto.append({
                    "artistId": art_id,
                    "role": art["role"],
                    "position": art["position"]
                })
                if art["role"] == "PRIMARY" and not primary_artist_id:
                    primary_artist_id = art_id

        # 3. Fetch or create album record
        album_id = None
        if album_title:
            album_rec = self.find_or_create_album(
                album_title=album_title,
                artist_id=primary_artist_id,
                release_date=release_date,
                cover_image_url=cover_image_url
            )
            album_id = album_rec.get("id") if album_rec else None

        # 4. Construct Track payload
        payload: Dict[str, Any] = {
            "title": raw_title,  # Preserve original title or clean_title
            "fileUrl": file_url,
            "status": "ACTIVE"
        }
        if cover_image_url:
            payload["coverImageUrl"] = cover_image_url
        if duration_ms:
            payload["durationMs"] = int(duration_ms)
        if release_date and len(release_date) >= 10:
            payload["releaseDate"] = release_date[:10]
        if track_number:
            payload["trackNumber"] = int(track_number)
        if disc_number:
            payload["discNumber"] = int(disc_number)
        if album_id:
            payload["albumId"] = album_id
        if track_artists_dto:
            payload["artists"] = track_artists_dto
        if sources:
            payload["sources"] = sources

        try:
            resp = requests.post(
                f"{self.base_url}/tracks",
                headers=self._headers(),
                json=payload,
                timeout=8
            )
            if resp.status_code in [200, 201]:
                data = resp.json()
                artist_summary = ", ".join([f"{a['name']} ({a['role']})" for a in parsed_artists])
                print(f"[CatalogService] ✓ Registered Track: '{raw_title}' - Artists: [{artist_summary}]")
                return {
                    "success": True,
                    "catalog_id": data.get("data", {}).get("id") or data.get("id"),
                    "track": data.get("data", data),
                    "parsed_artists": parsed_artists
                }
            else:
                return {
                    "success": False,
                    "error": f"API {resp.status_code}: {resp.text}",
                    "payload_sent": payload
                }
        except Exception as e:
            return {
                "success": False,
                "error": f"Exception connecting to Catalog Service: {str(e)}",
                "payload_sent": payload
            }

    def update_audio_analysis(self, track_id: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        """
        Updates acoustic analysis metrics (BPM, key, camelot, cues, energy, lufs...) to Catalog Service.
        Endpoint: PUT /api/v1/catalog/tracks/{track_id}/audio-analysis
        """
        clean_track_id = str(track_id).strip()
        url = f"{self.base_url}/tracks/{clean_track_id}/audio-analysis"
        try:
            resp = requests.put(
                url,
                headers=self._headers(),
                json=payload,
                timeout=15
            )
            if resp.status_code in [200, 201]:
                data = resp.json()
                return {
                    "success": True,
                    "data": data.get("data", data)
                }
            else:
                return {
                    "success": False,
                    "error": f"API {resp.status_code}: {resp.text}"
                }
        except Exception as e:
            return {
                "success": False,
                "error": f"Exception updating Audio Analysis: {str(e)}"
            }

