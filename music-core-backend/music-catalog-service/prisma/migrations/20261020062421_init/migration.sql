-- DropForeignKey
ALTER TABLE "album_artists" DROP CONSTRAINT "album_artists_album_id_fkey";

-- DropForeignKey
ALTER TABLE "album_artists" DROP CONSTRAINT "album_artists_artist_id_fkey";

-- DropForeignKey
ALTER TABLE "genres" DROP CONSTRAINT "genres_parent_id_fkey";

-- DropForeignKey
ALTER TABLE "track_artists" DROP CONSTRAINT "track_artists_artist_id_fkey";

-- DropForeignKey
ALTER TABLE "track_artists" DROP CONSTRAINT "track_artists_track_id_fkey";

-- DropForeignKey
ALTER TABLE "track_genres" DROP CONSTRAINT "track_genres_genre_id_fkey";

-- DropForeignKey
ALTER TABLE "track_genres" DROP CONSTRAINT "track_genres_track_id_fkey";

-- DropForeignKey
ALTER TABLE "track_sources" DROP CONSTRAINT "track_sources_track_id_fkey";

-- DropForeignKey
ALTER TABLE "tracks" DROP CONSTRAINT "tracks_album_id_fkey";

-- AddForeignKey
ALTER TABLE "tracks" ADD CONSTRAINT "tracks_album_id_fkey" FOREIGN KEY ("album_id") REFERENCES "albums"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "genres" ADD CONSTRAINT "genres_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "genres"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "track_artists" ADD CONSTRAINT "track_artists_track_id_fkey" FOREIGN KEY ("track_id") REFERENCES "tracks"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "track_artists" ADD CONSTRAINT "track_artists_artist_id_fkey" FOREIGN KEY ("artist_id") REFERENCES "artists"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "album_artists" ADD CONSTRAINT "album_artists_album_id_fkey" FOREIGN KEY ("album_id") REFERENCES "albums"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "album_artists" ADD CONSTRAINT "album_artists_artist_id_fkey" FOREIGN KEY ("artist_id") REFERENCES "artists"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "track_genres" ADD CONSTRAINT "track_genres_track_id_fkey" FOREIGN KEY ("track_id") REFERENCES "tracks"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "track_genres" ADD CONSTRAINT "track_genres_genre_id_fkey" FOREIGN KEY ("genre_id") REFERENCES "genres"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "track_sources" ADD CONSTRAINT "track_sources_track_id_fkey" FOREIGN KEY ("track_id") REFERENCES "tracks"("id") ON DELETE CASCADE ON UPDATE CASCADE;
