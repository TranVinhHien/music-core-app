CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Artists: Stores information about music artists.
CREATE TABLE artists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Unique artist identifier
    name VARCHAR(255) NOT NULL, -- Artist display name
    normalized_name VARCHAR(255) NOT NULL, -- Normalized name for searching and duplicate detection
    bio TEXT, -- Artist biography or description
    image_url TEXT, -- URL of the artist profile image
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- Record creation timestamp
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW() -- Last update timestamp
);

CREATE INDEX idx_artists_normalized_name
    ON artists (normalized_name);


-- 2. Albums: Stores information about music albums.
CREATE TABLE albums (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Unique album identifier
    title VARCHAR(255) NOT NULL, -- Album title
    release_date DATE, -- Official album release date
    cover_image_url TEXT, -- URL of the album cover image
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- Album status, e.g. ACTIVE or INACTIVE
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- Record creation timestamp
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW() -- Last update timestamp
);

CREATE INDEX idx_albums_title ON albums (title);


-- 3. Tracks: Stores metadata for individual music tracks.
CREATE TABLE tracks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Unique track identifier
    title VARCHAR(255) NOT NULL, -- Track title
    slug VARCHAR(255), -- URL-friendly identifier for the track
    album_id UUID REFERENCES albums(id) ON DELETE SET NULL, -- Associated album; NULL if no album is assigned
    duration_ms INTEGER CHECK (duration_ms IS NULL OR duration_ms >= 0), -- Track duration in milliseconds
    track_number INTEGER CHECK (track_number IS NULL OR track_number > 0), -- Track position within the album
    disc_number INTEGER CHECK (disc_number IS NULL OR disc_number > 0), -- Disc number for multi-disc albums
    release_date DATE, -- Track release date, which may differ from the album release date
    cover_image_url TEXT, -- URL of the track cover / background image
    file_url TEXT, -- URL or storage path of the audio track file
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- Track status, e.g. ACTIVE or INACTIVE
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- Record creation timestamp
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW() -- Last update timestamp
);

CREATE INDEX idx_tracks_title ON tracks (title);
CREATE INDEX idx_tracks_album_id ON tracks (album_id);
CREATE INDEX idx_tracks_status ON tracks (status);


-- 4. Genres: Stores music genres and supports parent-child classification.
CREATE TABLE genres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Unique genre identifier
    name VARCHAR(100) NOT NULL, -- Genre display name, e.g. Pop or Rock
    slug VARCHAR(100) NOT NULL UNIQUE, -- Unique URL-friendly genre identifier
    parent_id UUID REFERENCES genres(id) ON DELETE SET NULL, -- Parent genre for hierarchical classification
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW() -- Record creation timestamp
);


-- 5. Track Artists: Maps tracks to artists and defines their roles.
CREATE TABLE track_artists (
    track_id UUID NOT NULL REFERENCES tracks(id) ON DELETE CASCADE, -- Associated track ID
    artist_id UUID NOT NULL REFERENCES artists(id) ON DELETE CASCADE, -- Associated artist ID
    role VARCHAR(30) NOT NULL DEFAULT 'PRIMARY', -- Artist contribution role, e.g. PRIMARY or FEAT
    position SMALLINT NOT NULL DEFAULT 1 CHECK (position > 0), -- Display order of the artist on the track
    PRIMARY KEY (track_id, artist_id, role) -- Prevents duplicate artist-role assignments for the same track
);

CREATE INDEX idx_track_artists_artist_id
    ON track_artists (artist_id);


-- 6. Album Artists: Maps albums to their credited artists.
CREATE TABLE album_artists (
    album_id UUID NOT NULL REFERENCES albums(id) ON DELETE CASCADE, -- Associated album ID
    artist_id UUID NOT NULL REFERENCES artists(id) ON DELETE CASCADE, -- Associated artist ID
    position SMALLINT NOT NULL DEFAULT 1 CHECK (position > 0), -- Display order of the artist on the album
    PRIMARY KEY (album_id, artist_id) -- Prevents assigning the same artist to an album more than once
);

CREATE INDEX idx_album_artists_artist_id
    ON album_artists (artist_id);


-- 7. Track Genres: Maps tracks to genres (many-to-many relationship).
CREATE TABLE track_genres (
    track_id UUID NOT NULL REFERENCES tracks(id) ON DELETE CASCADE, -- Associated track ID
    genre_id UUID NOT NULL REFERENCES genres(id) ON DELETE CASCADE, -- Associated genre ID
    PRIMARY KEY (track_id, genre_id) -- Prevents assigning the same genre to a track more than once
);

CREATE INDEX idx_track_genres_genre_id
    ON track_genres (genre_id);


-- 8. Track Sources: Stores external identifiers and links from music platforms.
CREATE TABLE track_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Unique source record identifier
    track_id UUID NOT NULL REFERENCES tracks(id) ON DELETE CASCADE, -- Internal track associated with this source
    source VARCHAR(50) NOT NULL, -- External platform or data source, e.g. YouTube or Facebook
    external_id VARCHAR(255) NOT NULL, -- Track identifier on the external platform
    external_url TEXT, -- Direct URL to the track on the external platform
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- Record creation timestamp
    UNIQUE (source, external_id) -- Prevents duplicate external identifiers within the same platform
);

CREATE INDEX idx_track_sources_track_id
    ON track_sources (track_id);