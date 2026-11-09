import re
from typing import List, Dict, Tuple, Any

class ArtistParser:
    """
    Parser chuyên xử lý tên bài hát và danh sách ca sĩ:
    - Nhận diện nghệ sĩ chính (PRIMARY) và nghệ sĩ kết hợp / hợp tác (FEAT).
    - Hỗ trợ các định dạng: 'A & B', 'A x B', 'A vs B', 'A, B & C', 'A feat. B', 'A ft. B', 'A featuring B'.
    - Xử lý feat nằm trong tên bài hát (VD: 'Baby (feat. marzuz)', 'Huh (feat. RPT Orijinn & Thành Draw)').
    """

    FEAT_PATTERNS = [
        re.compile(r'[\(\[\{]\s*(?:feat\.?|ft\.?|featuring)\s+([^()]+)[\)\]\}]', re.IGNORECASE),
        re.compile(r'\s+(?:feat\.?|ft\.?|featuring)\s+(.+)$', re.IGNORECASE)
    ]

    DELIMITERS = [',', '&', ' x ', ' X ', ' vs ', ' VS ', ' with ', ' WITH ', ' and ', ' AND ']

    @classmethod
    def _split_names(cls, text: str) -> List[str]:
        """Tách chuỗi nhiều nghệ sĩ theo các dấu phân tách thông dụng"""
        names = [text]
        for delim in cls.DELIMITERS:
            new_names = []
            for n in names:
                for sub in n.split(delim):
                    sub_clean = sub.strip()
                    if sub_clean:
                        new_names.append(sub_clean)
            names = new_names
        # Lọc trùng giữ thứ tự
        seen = set()
        unique = []
        for n in names:
            norm = n.lower()
            if norm not in seen and n:
                seen.add(norm)
                unique.append(n)
        return unique

    @classmethod
    def parse(cls, artist_str: str, track_title: str) -> Tuple[List[Dict[str, Any]], str]:
        """
        Phân tích artist_str và track_title.
        Trả về:
        - List các dict: [{"name": "...", "role": "PRIMARY" | "FEAT", "position": 1, ...}]
        - Clean track title (đã chuẩn hóa, có thể giữ hoặc lược bỏ feat)
        """
        primary_artists: List[str] = []
        feat_artists: List[str] = []
        clean_title = track_title.strip()

        # 1. Trích xuất featured artists từ trong tên bài hát (nếu có)
        for pat in cls.FEAT_PATTERNS:
            match = pat.search(clean_title)
            if match:
                feat_str = match.group(1).strip()
                feat_artists.extend(cls._split_names(feat_str))
                # Xóa phần (feat. ...) khỏi title để lấy title sạch
                clean_title = pat.sub('', clean_title).strip()
                break

        # 2. Trích xuất từ artist_str
        art_clean = artist_str.strip()
        has_feat_in_artist = False
        for pat in cls.FEAT_PATTERNS:
            match = pat.search(art_clean)
            if match:
                has_feat_in_artist = True
                feat_str = match.group(1).strip()
                feat_artists.extend(cls._split_names(feat_str))
                art_clean = pat.sub('', art_clean).strip()
                break

        # Tách các nghệ sĩ chính còn lại
        primary_artists.extend(cls._split_names(art_clean))

        # 3. Tạo cấu trúc chuẩn cho Catalog Microservice
        results: List[Dict[str, Any]] = []
        seen_names = set()
        pos = 1

        for name in primary_artists:
            if name.lower() not in seen_names:
                seen_names.add(name.lower())
                results.append({
                    "name": name,
                    "role": "PRIMARY",
                    "position": pos
                })
                pos += 1

        for name in feat_artists:
            if name.lower() not in seen_names:
                seen_names.add(name.lower())
                results.append({
                    "name": name,
                    "role": "FEAT",
                    "position": pos
                })
                pos += 1

        if not results:
            results.append({
                "name": artist_str or "Unknown Artist",
                "role": "PRIMARY",
                "position": 1
            })

        return results, clean_title
