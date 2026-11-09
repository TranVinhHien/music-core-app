import re
from typing import List, Dict, Tuple, Any

class ArtistParser:
    """
    Parser specialized in handling track titles and artist strings:
    - Identifies primary artists (PRIMARY) and featured / collaborating artists (FEAT).
    - Supports delimiters: 'A & B', 'A x B', 'A vs B', 'A, B & C', 'A feat. B', 'A ft. B', 'A featuring B'.
    - Handles embedded featured artists in track titles (e.g. 'Baby (feat. marzuz)', 'Huh (feat. RPT Orijinn & Thanh Draw)').
    """

    FEAT_PATTERNS = [
        re.compile(r'[\(\[\{]\s*(?:feat\.?|ft\.?|featuring)\s+([^()]+)[\)\]\}]', re.IGNORECASE),
        re.compile(r'\s+(?:feat\.?|ft\.?|featuring)\s+(.+)$', re.IGNORECASE)
    ]

    DELIMITERS = [',', '&', ' x ', ' X ', ' vs ', ' VS ', ' with ', ' WITH ', ' and ', ' AND ']

    @classmethod
    def _split_names(cls, text: str) -> List[str]:
        """Splits multi-artist string by common delimiter tokens."""
        names = [text]
        for delim in cls.DELIMITERS:
            new_names = []
            for n in names:
                for sub in n.split(delim):
                    sub_clean = sub.strip()
                    if sub_clean:
                        new_names.append(sub_clean)
            names = new_names
        # Deduplicate while preserving order
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
        Parses artist_str and track_title.
        Returns:
        - List of dicts: [{"name": "...", "role": "PRIMARY" | "FEAT", "position": 1, ...}]
        - Clean track title (normalized, removing embedded feat clauses)
        """
        primary_artists: List[str] = []
        feat_artists: List[str] = []
        clean_title = track_title.strip()

        # 1. Extract featured artists from track title if present
        for pat in cls.FEAT_PATTERNS:
            match = pat.search(clean_title)
            if match:
                feat_str = match.group(1).strip()
                feat_artists.extend(cls._split_names(feat_str))
                # Remove (feat. ...) from title to obtain clean title
                clean_title = pat.sub('', clean_title).strip()
                break

        # 2. Extract from artist_str
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

        # Extract remaining primary artists
        primary_artists.extend(cls._split_names(art_clean))

        # 3. Build standardized structure for Catalog Microservice
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
