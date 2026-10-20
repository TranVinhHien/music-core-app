-- Down migration for 20261020000001_init_library
DROP TABLE IF EXISTS "user_favorite_tracks" CASCADE;
DROP TABLE IF EXISTS "playlist_tracks" CASCADE;
DROP TABLE IF EXISTS "playlists" CASCADE;
