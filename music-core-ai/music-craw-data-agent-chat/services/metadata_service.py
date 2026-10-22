import requests
from typing import Optional, Dict, Any, List

class MetadataService:
    """
    Dịch vụ tìm kiếm metadata chuẩn (Title, Artist, Album, Cover Art, Year, Genre).
    Kết hợp iTunes API và Deezer API miễn phí, không cần token.
    """

    @staticmethod
    def search_itunes(query: str, limit: int = 1) -> List[Dict[str, Any]]:
        results = []
        try:
            url = "https://itunes.apple.com/search"
            params = {
                "term": query,
                "entity": "song",
                "limit": limit
            }
            resp = requests.get(url, params=params, timeout=10)
            if resp.status_code == 200:
                data = resp.json()
                for item in data.get("results", []):
                    cover_url = item.get("artworkUrl100", "")
                    if cover_url:
                        cover_url = cover_url.replace("100x100bb", "1400x1400bb")

                    release_date = item.get("releaseDate", "")
                    year = release_date[:4] if release_date else ""

                    results.append({
                        "source": "itunes",
                        "title": item.get("trackName"),
                        "artist": item.get("artistName"),
                        "album": item.get("collectionName"),
                        "genre": item.get("primaryGenreName"),
                        "year": year,
                        "release_date": release_date,
                        "duration_ms": item.get("trackTimeMillis"),
                        "track_number": item.get("trackNumber"),
                        "cover_url": cover_url
                    })
        except Exception as e:
            print(f"[MetadataService] Lỗi gọi iTunes API: {e}")
        return results

    @staticmethod
    def search_deezer(query: str, limit: int = 1) -> List[Dict[str, Any]]:
        results = []
        try:
            url = "https://api.deezer.com/search"
            params = {"q": query, "limit": limit}
            resp = requests.get(url, params=params, timeout=10)
            if resp.status_code == 200:
                data = resp.json()
                for item in data.get("data", []):
                    album = item.get("album", {})
                    artist = item.get("artist", {})
                    results.append({
                        "source": "deezer",
                        "title": item.get("title"),
                        "artist": artist.get("name"),
                        "album": album.get("title"),
                        "genre": "",
                        "year": "",
                        "release_date": "",
                        "duration_ms": item.get("duration", 0) * 1000,
                        "track_number": 1,
                        "cover_url": album.get("cover_xl") or album.get("cover_big") or album.get("cover_medium")
                    })
        except Exception as e:
            print(f"[MetadataService] Lỗi gọi Deezer API: {e}")
        return results

    @classmethod
    def get_metadata(cls, query: str) -> Optional[Dict[str, Any]]:
        """Lấy 1 bài hát khớp nhất"""
        res = cls.search_itunes(query, limit=1)
        if res:
            return res[0]
        res_dz = cls.search_deezer(query, limit=1)
        return res_dz[0] if res_dz else None

    @classmethod
    def search_candidates(cls, query: str, limit: int = 5) -> List[Dict[str, Any]]:
        """Tìm danh sách bài hát gợi ý cho Agent lên kế hoạch"""
        res = cls.search_itunes(query, limit=limit)
        if len(res) < limit:
            dz_items = cls.search_deezer(query, limit=limit - len(res))
            res.extend(dz_items)
        return res
