import requests
from typing import Dict, Any, Optional, List
from services.artist_parser import ArtistParser

class CatalogService:
    """
    Client giao tiếp với Backend music-catalog-service (NestJS) qua REST API.
    Tự động phân tách và liên kết nhiều nghệ sĩ (PRIMARY, FEAT), Album và Track.
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
        Tìm Artist theo tên; nếu chưa có thì tự động tạo mới.
        """
        clean_name = artist_name.strip()
        if not clean_name:
            return None

        # 1. Tìm trong danh sách hiện tại
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
            print(f"[CatalogService] Lỗi kết nối danh sách Artist: {e}")

        # 2. Tạo mới Artist nếu chưa có
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
                print(f"[CatalogService] ✓ Đã tạo Artist mới: {clean_name} (ID: {artist.get('id')})")
                return artist
            else:
                print(f"[CatalogService] Lỗi tạo Artist '{clean_name}': {post_resp.status_code} - {post_resp.text}")
        except Exception as e:
            print(f"[CatalogService] Ngoại lệ tạo Artist: {e}")

        return None

    def find_or_create_album(self, album_title: str, artist_id: Optional[str] = None, release_date: Optional[str] = None, cover_image_url: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """
        Tìm Album theo tên; nếu chưa có thì tự động tạo mới.
        """
        clean_title = album_title.strip()
        if not clean_title:
            return None

        # 1. Tìm album
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
            print(f"[CatalogService] Lỗi kết nối danh sách Album: {e}")

        # 2. Tạo mới Album
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
                print(f"[CatalogService] ✓ Đã tạo Album mới: {clean_title} (ID: {album.get('id')})")
                return album
            else:
                print(f"[CatalogService] Lỗi tạo Album '{clean_title}': {post_resp.status_code} - {post_resp.text}")
        except Exception as e:
            print(f"[CatalogService] Ngoại lệ tạo Album: {e}")

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
        Đăng ký Track hoàn chỉnh:
        - Tự động phân tách đa nghệ sĩ (PRIMARY, FEAT) từ raw_artist và raw_title.
        - Tạo Artist records nếu chưa tồn tại.
        - Tạo Album record nếu có.
        - Đăng ký Track với liên kết đa nghệ sĩ.
        """
        # 1. Phân tách danh sách nghệ sĩ và chuẩn hóa tiêu đề bài hát
        parsed_artists, clean_title = ArtistParser.parse(raw_artist, raw_title)
        
        # 2. Tạo hoặc lấy artist records cho từng nghệ sĩ
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

        # 3. Tạo hoặc lấy album record
        album_id = None
        if album_title:
            album_rec = self.find_or_create_album(
                album_title=album_title,
                artist_id=primary_artist_id,
                release_date=release_date,
                cover_image_url=cover_image_url
            )
            album_id = album_rec.get("id") if album_rec else None

        # 4. Tạo Track payload
        payload: Dict[str, Any] = {
            "title": raw_title,  # Giữ tên gốc hoặc clean_title
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
                print(f"[CatalogService] ✓ Đã đăng ký Track: '{raw_title}' - Nghệ sĩ: [{artist_summary}]")
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
                "error": f"Ngoại lệ kết nối Catalog Service: {str(e)}",
                "payload_sent": payload
            }
