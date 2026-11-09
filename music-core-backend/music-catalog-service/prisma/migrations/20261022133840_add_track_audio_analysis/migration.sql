-- CreateTable
CREATE TABLE "track_audio_analyses" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "track_id" UUID NOT NULL,
    "cue_in_ms" INTEGER NOT NULL DEFAULT 0,
    "cue_out_ms" INTEGER NOT NULL,
    "duration_ms" INTEGER NOT NULL,
    "bpm" REAL,
    "first_downbeat_ms" INTEGER,
    "downbeats" JSONB,
    "key" VARCHAR(10),
    "scale" VARCHAR(10),
    "camelot_key" VARCHAR(10),
    "energy" REAL,
    "loudness_lufs" REAL,
    "recommended_transition" VARCHAR(50),
    "recommended_crossfade_ms" INTEGER,
    "analysis_status" VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    "error_message" TEXT,
    "analyzed_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "track_audio_analyses_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "track_audio_analyses_track_id_key" ON "track_audio_analyses"("track_id");

-- CreateIndex
CREATE INDEX "idx_track_audio_analysis_status" ON "track_audio_analyses"("analysis_status");

-- AddForeignKey
ALTER TABLE "track_audio_analyses" ADD CONSTRAINT "track_audio_analyses_track_id_fkey" FOREIGN KEY ("track_id") REFERENCES "tracks"("id") ON DELETE CASCADE ON UPDATE CASCADE;
