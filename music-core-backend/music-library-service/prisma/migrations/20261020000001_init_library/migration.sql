CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE "playlists" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "description" TEXT,
    "cover_image_url" TEXT,
    "visibility" VARCHAR(20) NOT NULL DEFAULT 'PRIVATE'
        CHECK ("visibility" IN ('PRIVATE', 'PUBLIC')),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX "idx_playlists_user_created"
    ON "playlists" ("user_id", "created_at" DESC);

CREATE TABLE "playlist_tracks" (
    "playlist_id" UUID NOT NULL
        REFERENCES "playlists"("id") ON DELETE CASCADE,
    "track_id" UUID NOT NULL,
    "position" INTEGER NOT NULL CHECK ("position" > 0),
    "added_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY ("playlist_id", "track_id")
);

CREATE INDEX "idx_playlist_tracks_order"
    ON "playlist_tracks" ("playlist_id", "position");

CREATE INDEX "idx_playlist_tracks_track_id"
    ON "playlist_tracks" ("track_id");

CREATE TABLE "user_favorite_tracks" (
    "user_id" UUID NOT NULL,
    "track_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY ("user_id", "track_id")
);

CREATE INDEX "idx_user_favorite_tracks_track_id"
    ON "user_favorite_tracks" ("track_id");
