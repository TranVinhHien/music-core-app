-- Enable pg_trgm extension for trigram similarity and fuzzy matching
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 1. Tracks GIN indexes
-- GIN Trigram index on title for fast ILIKE and similarity() fuzzy matching
CREATE INDEX IF NOT EXISTS "idx_tracks_title_trgm"
    ON "tracks" USING gin ("title" gin_trgm_ops);

-- GIN Full-Text Search index on title
CREATE INDEX IF NOT EXISTS "idx_tracks_title_fts"
    ON "tracks" USING gin (to_tsvector('simple', "title"));


-- 2. Albums GIN indexes
-- GIN Trigram index on title for fast ILIKE and similarity() fuzzy matching
CREATE INDEX IF NOT EXISTS "idx_albums_title_trgm"
    ON "albums" USING gin ("title" gin_trgm_ops);

-- GIN Full-Text Search index on title
CREATE INDEX IF NOT EXISTS "idx_albums_title_fts"
    ON "albums" USING gin (to_tsvector('simple', "title"));


-- 3. Artists GIN indexes
-- GIN Trigram index on name and normalized_name for fast ILIKE and similarity()
CREATE INDEX IF NOT EXISTS "idx_artists_name_trgm"
    ON "artists" USING gin ("name" gin_trgm_ops);

CREATE INDEX IF NOT EXISTS "idx_artists_normalized_name_trgm"
    ON "artists" USING gin ("normalized_name" gin_trgm_ops);

-- GIN Full-Text Search index on name
CREATE INDEX IF NOT EXISTS "idx_artists_name_fts"
    ON "artists" USING gin (to_tsvector('simple', "name"));

