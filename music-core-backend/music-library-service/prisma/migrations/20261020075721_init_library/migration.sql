-- DropForeignKey
ALTER TABLE "playlist_tracks" DROP CONSTRAINT "playlist_tracks_playlist_id_fkey";

-- AddForeignKey
ALTER TABLE "playlist_tracks" ADD CONSTRAINT "playlist_tracks_playlist_id_fkey" FOREIGN KEY ("playlist_id") REFERENCES "playlists"("id") ON DELETE CASCADE ON UPDATE CASCADE;
