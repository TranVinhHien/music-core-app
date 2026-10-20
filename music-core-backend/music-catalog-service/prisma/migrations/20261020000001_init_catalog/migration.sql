CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Artists: Stores information about music artists.
CREATE TABLE "artists" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "name" VARCHAR(255) NOT NULL,
    "normalized_name" VARCHAR(255) NOT NULL,
    "bio" TEXT,
    "image_url" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX "idx_artists_normalized_name" ON "artists" ("normalized_name");

-- 2. Albums: Stores information about music albums.
CREATE TABLE "albums" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "title" VARCHAR(255) NOT NULL,
    "release_date" DATE,
    "cover_image_url" TEXT,
    "status" VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX "idx_albums_title" ON "albums" ("title");

-- 3. Tracks: Stores metadata for individual music tracks.
CREATE TABLE "tracks" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "title" VARCHAR(255) NOT NULL,
    "slug" VARCHAR(255),
    "album_id" UUID REFERENCES "albums"("id") ON DELETE SET NULL,
    "duration_ms" INTEGER CHECK ("duration_ms" IS NULL OR "duration_ms" >= 0),
    "track_number" INTEGER CHECK ("track_number" IS NULL OR "track_number" > 0),
    "disc_number" INTEGER CHECK ("disc_number" IS NULL OR "disc_number" > 0),
    "release_date" DATE,
    "status" VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX "idx_tracks_title" ON "tracks" ("title");
CREATE INDEX "idx_tracks_album_id" ON "tracks" ("album_id");
CREATE INDEX "idx_tracks_status" ON "tracks" ("status");

-- 4. Genres: Stores music genres and supports parent-child classification.
CREATE TABLE "genres" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "name" VARCHAR(100) NOT NULL,
    "slug" VARCHAR(100) NOT NULL UNIQUE,
    "parent_id" UUID REFERENCES "genres"("id") ON DELETE SET NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Track Artists: Maps tracks to artists and defines their roles.
CREATE TABLE "track_artists" (
    "track_id" UUID NOT NULL REFERENCES "tracks"("id") ON DELETE CASCADE,
    "artist_id" UUID NOT NULL REFERENCES "artists"("id") ON DELETE CASCADE,
    "role" VARCHAR(30) NOT NULL DEFAULT 'PRIMARY',
    "position" SMALLINT NOT NULL DEFAULT 1 CHECK ("position" > 0),
    PRIMARY KEY ("track_id", "artist_id", "role")
);

CREATE INDEX "idx_track_artists_artist_id" ON "track_artists" ("artist_id");

-- 6. Album Artists: Maps albums to their credited artists.
CREATE TABLE "album_artists" (
    "album_id" UUID NOT NULL REFERENCES "albums"("id") ON DELETE CASCADE,
    "artist_id" UUID NOT NULL REFERENCES "artists"("id") ON DELETE CASCADE,
    "position" SMALLINT NOT NULL DEFAULT 1 CHECK ("position" > 0),
    PRIMARY KEY ("album_id", "artist_id")
);

CREATE INDEX "idx_album_artists_artist_id" ON "album_artists" ("artist_id");

-- 7. Track Genres: Maps tracks to genres (many-to-many relationship).
CREATE TABLE "track_genres" (
    "track_id" UUID NOT NULL REFERENCES "tracks"("id") ON DELETE CASCADE,
    "genre_id" UUID NOT NULL REFERENCES "genres"("id") ON DELETE CASCADE,
    PRIMARY KEY ("track_id", "genre_id")
);

CREATE INDEX "idx_track_genres_genre_id" ON "track_genres" ("genre_id");

-- 8. Track Sources: Stores external identifiers and links from music platforms.
CREATE TABLE "track_sources" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "track_id" UUID NOT NULL REFERENCES "tracks"("id") ON DELETE CASCADE,
    "source" VARCHAR(50) NOT NULL,
    "external_id" VARCHAR(255) NOT NULL,
    "external_url" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE ("source", "external_id")
);

CREATE INDEX "idx_track_sources_track_id" ON "track_sources" ("track_id");
