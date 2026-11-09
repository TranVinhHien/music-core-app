-- Down migration for 20261028151000_add_search_gin_indexes
DROP INDEX IF EXISTS "idx_artists_name_fts";
DROP INDEX IF EXISTS "idx_artists_normalized_name_trgm";
DROP INDEX IF EXISTS "idx_artists_name_trgm";

DROP INDEX IF EXISTS "idx_albums_title_fts";
DROP INDEX IF EXISTS "idx_albums_title_trgm";

DROP INDEX IF EXISTS "idx_tracks_title_fts";
DROP INDEX IF EXISTS "idx_tracks_title_trgm";

