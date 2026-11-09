import requests
from typing import Dict, Any, Optional, List

class CatalogService:
    """
    Client giao tiếp với Backend music-catalog-service (NestJS) qua REST API.
    Đảm bảo tự động tìm kiếm hoặc tạo Artist, Album trước khi gắn vào Track.
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
        if not artist_name:
            return None

        # 1. Tìm trong danh sách hiện tại
        try:
            get_resp = requests.get(
                f"{self.base_url}/artists",
                headers=self._headers(),
                params={"limit": 50},
                timeout=5
            )
            if get_resp.status_code == 200:
                result = get_resp.json()
                items = result.get("data", {}).get("items", []) if isinstance(result.get("data"), dict) else result.get("data", [])
                for item in items:
                    if item.get("name", "").strip().lower() == artist_name.strip().lower():
                        print(f"[CatalogService] Đã tìm thấy Artist tồn tại: {item.get('name')} (ID: {item.get('id')})")
                        return item
        except Exception as e:
            print(f"[CatalogService] Không thể kết nối danh sách Artist: {e}")

        # 2. Tạo mới Artist nếu chưa có
        try:
            payload = {
                "name": artist_name,
                "bio": f"Artist imported by AI Music Crawler Agent",
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
                print(f"[CatalogService] Đã tạo mới Artist: {artist_name} (ID: {artist.get('id')})")
                return artist
            else:
                print(f"[CatalogService] Lỗi tạo Artist: {post_resp.status_code} - {post_resp.text}")
        except Exception as e:
            print(f"[CatalogService] Ngoại lệ tạo Artist: {e}")

        return None

    def find_or_create_album(self, album_title: str, artist_id: Optional[str] = None, release_date: Optional[str] = None, cover_image_url: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """
        Tìm Album theo tên; nếu chưa có thì tự động tạo mới.
        """
        if not album_title:
            return None

        # 1. Tìm album
        try:
            get_resp = requests.get(
                f"{self.base_url}/albums",
                headers=self._headers(),
                params={"limit": 50},
                timeout=5
            )
            if get_resp.status_code == 200:
                result = get_resp.json()
                items = result.get("data", {}).get("items", []) if isinstance(result.get("data"), dict) else result.get("data", [])
                for item in items:
                    if item.get("title", "").strip().lower() == album_title.strip().lower():
                        print(f"[CatalogService] Đã tìm thấy Album tồn tại: {item.get('title')} (ID: {item.get('id')})")
                        return item
        except Exception as e:
            print(f"[CatalogService] Không thể kết nối danh sách Album: {e}")

        # 2. Tạo mới Album
        try:
            payload: Dict[str, Any] = {
                "title": album_title,
                "coverImageUrl": cover_image_url or "",
            }
            if release_date and len(release_date) >= 10:
                payload["releaseDate"] = release_date[:10]  # Format YYYY-MM-DD
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
                print(f"[CatalogService] Đã tạo mới Album: {album_title} (ID: {album.get('id')})")
                return album
            else:
                print(f"[CatalogService] Lỗi tạo Album: {post_resp.status_code} - {post_resp.text}")
        except Exception as e:
            print(f"[CatalogService] Ngoại lệ tạo Album: {e}")

        return None

    def create_track(self, 
                     title: str, 
                     file_url: str, 
                     cover_image_url: Optional[str] = None, 
                     duration_ms: Optional[int] = None,
                     release_date: Optional[str] = None,
                     artist_id: Optional[str] = None,
                     album_id: Optional[str] = None,
                     sources: Optional[List[Dict[str, str]]] = None) -> Dict[str, Any]:
        """
        Đăng ký bản ghi Track vào Catalog Microservice.
        """
        payload: Dict[str, Any] = {
            "title": title,
            "fileUrl": file_url,
            "status": "ACTIVE"
        }
        if cover_image_url:
            payload["coverImageUrl"] = cover_image_url
        if duration_ms:
            payload["durationMs"] = int(duration_ms)
        if release_date and len(release_date) >= 10:
            payload["releaseDate"] = release_date[:10]
        if album_id:
            payload["albumId"] = album_id
        if artist_id:
            payload["artists"] = [{
                "artistId": artist_id,
                "role": "PRIMARY",
                "position": 1
            }]
        if sources:
            payload["sources"] = sources

        try:
            print(f"[CatalogService] Đang đẩy thông tin Track '{title}' lên Catalog API...")
            resp = requests.post(
                f"{self.base_url}/tracks",
                headers=self._headers(),
                json=payload,
                timeout=8
            )
            if resp.status_code in [200, 201]:
                data = resp.json()
                print(f"[CatalogService] Thành công tạo Track trên hệ thống!")
                return {
                    "success": True,
                    "catalog_id": data.get("data", {}).get("id") or data.get("id"),
                    "track": data.get("data", data)
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
