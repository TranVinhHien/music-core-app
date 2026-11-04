import { Injectable, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../database/prisma.service';
import type { ISearchRepository } from './search.repository.interface';
import {
  AlbumSearchResultDto,
  ArtistSearchResultDto,
  SearchSectionDto,
  TrackSearchResultDto,
} from '../dto/search-catalog.dto';
import { normalizeString } from '../../../common/utils/text.util';

interface RawQueryResult<T> {
  total: number;
  items: T[] | string;
}

@Injectable()
export class PrismaSearchRepository implements ISearchRepository {
  private readonly logger = new Logger(PrismaSearchRepository.name);

  constructor(private readonly prisma: PrismaService) {}

  private parseItems<T>(rawItems: T[] | string | undefined | null): T[] {
    if (!rawItems) return [];
    if (Array.isArray(rawItems)) return rawItems;
    if (typeof rawItems === 'string') {
      try {
        return JSON.parse(rawItems) as T[];
      } catch {
        return [];
      }
    }
    return [];
  }

  async searchTracks(
    term: string,
    limit: number,
    offset: number,
  ): Promise<SearchSectionDto<TrackSearchResultDto>> {
    const trimmed = (term || '').trim();

    if (!trimmed) {
      const query = Prisma.sql`
        SELECT
          (SELECT COUNT(*)::int FROM tracks WHERE status = 'ACTIVE') AS total,
          COALESCE(
            (
              SELECT json_agg(row_to_json(p))
              FROM (
                SELECT
                  t.id,
                  t.title,
                  t.slug,
                  t.album_id AS "albumId",
                  t.duration_ms AS "durationMs",
                  t.track_number AS "trackNumber",
                  t.disc_number AS "discNumber",
                  t.release_date AS "releaseDate",
                  t.cover_image_url AS "coverImageUrl",
                  t.file_url AS "fileUrl",
                  t.status,
                  CASE WHEN al.id IS NOT NULL THEN
                    json_build_object(
                      'id', al.id,
                      'title', al.title,
                      'coverImageUrl', al.cover_image_url
                    )
                  ELSE NULL END AS album,
                  COALESCE(
                    (
                      SELECT json_agg(
                        json_build_object(
                          'id', ar.id,
                          'name', ar.name,
                          'role', ta.role,
                          'position', ta.position,
                          'imageUrl', ar.image_url
                        ) ORDER BY ta.position ASC
                      )
                      FROM track_artists ta
                      JOIN artists ar ON ar.id = ta.artist_id
                      WHERE ta.track_id = t.id
                    ),
                    '[]'::json
                  ) AS artists,
                  0.0::float AS "relevanceScore"
                FROM tracks t
                LEFT JOIN albums al ON al.id = t.album_id
                WHERE t.status = 'ACTIVE'
                ORDER BY t.created_at DESC
                LIMIT ${limit} OFFSET ${offset}
              ) p
            ),
            '[]'::json
          ) AS items;
      `;
      const result = await this.prisma.$queryRaw<RawQueryResult<TrackSearchResultDto>[]>(query);
      const total = Number(result[0]?.total ?? 0);
      const items = this.parseItems<TrackSearchResultDto>(result[0]?.items);
      return new SearchSectionDto<TrackSearchResultDto>(items, total);
    }

    const rawLower = trimmed.toLowerCase();
    const prefixLike = `${rawLower}%`;
    const substringLike = `%${rawLower}%`;

    const query = Prisma.sql`
      WITH matched AS (
        SELECT
          t.id,
          t.title,
          t.slug,
          t.album_id AS "albumId",
          t.duration_ms AS "durationMs",
          t.track_number AS "trackNumber",
          t.disc_number AS "discNumber",
          t.release_date AS "releaseDate",
          t.cover_image_url AS "coverImageUrl",
          t.file_url AS "fileUrl",
          t.status,
          t.created_at,
          (
            (CASE WHEN LOWER(t.title) = ${rawLower} THEN 10.0 ELSE 0.0 END) +
            (CASE WHEN t.title ILIKE ${prefixLike} THEN 5.0 ELSE 0.0 END) +
            (CASE WHEN t.title ILIKE ${substringLike} THEN 2.0 ELSE 0.0 END) +
            (CASE WHEN to_tsvector('simple', t.title) @@ plainto_tsquery('simple', ${trimmed})
                  THEN 3.0 * ts_rank(to_tsvector('simple', t.title), plainto_tsquery('simple', ${trimmed}))
                  ELSE 0.0 END) +
            (similarity(t.title, ${trimmed}) * 4.0)
          ) AS "relevanceScore",
          CASE WHEN al.id IS NOT NULL THEN
            json_build_object(
              'id', al.id,
              'title', al.title,
              'coverImageUrl', al.cover_image_url
            )
          ELSE NULL END AS album,
          COALESCE(
            (
              SELECT json_agg(
                json_build_object(
                  'id', ar.id,
                  'name', ar.name,
                  'role', ta.role,
                  'position', ta.position,
                  'imageUrl', ar.image_url
                ) ORDER BY ta.position ASC
              )
              FROM track_artists ta
              JOIN artists ar ON ar.id = ta.artist_id
              WHERE ta.track_id = t.id
            ),
            '[]'::json
          ) AS artists
        FROM tracks t
        LEFT JOIN albums al ON al.id = t.album_id
        WHERE t.status = 'ACTIVE'
          AND (
            t.title ILIKE ${prefixLike}
            OR t.title ILIKE ${substringLike}
            OR to_tsvector('simple', t.title) @@ plainto_tsquery('simple', ${trimmed})
            OR similarity(t.title, ${trimmed}) > 0.25
          )
      )
      SELECT
        (SELECT COUNT(*)::int FROM matched) AS total,
        COALESCE(
          (
            SELECT json_agg(row_to_json(p))
            FROM (
              SELECT
                id,
                title,
                slug,
                "albumId",
                "durationMs",
                "trackNumber",
                "discNumber",
                "releaseDate",
                "coverImageUrl",
                "fileUrl",
                status,
                album,
                artists,
                ROUND("relevanceScore"::numeric, 2)::float AS "relevanceScore"
              FROM matched
              ORDER BY "relevanceScore" DESC, created_at DESC
              LIMIT ${limit} OFFSET ${offset}
            ) p
          ),
          '[]'::json
        ) AS items;
    `;

    try {
      const result = await this.prisma.$queryRaw<RawQueryResult<TrackSearchResultDto>[]>(query);
      const total = Number(result[0]?.total ?? 0);
      const items = this.parseItems<TrackSearchResultDto>(result[0]?.items);
      return new SearchSectionDto<TrackSearchResultDto>(items, total);
    } catch (e: any) {
      this.logger.warn(`searchTracks raw query error (${e.message}), executing Prisma fallback`);
      return this.searchTracksFallback(trimmed, limit, offset);
    }
  }

  async searchAlbums(
    term: string,
    limit: number,
    offset: number,
  ): Promise<SearchSectionDto<AlbumSearchResultDto>> {
    const trimmed = (term || '').trim();

    if (!trimmed) {
      const query = Prisma.sql`
        SELECT
          (SELECT COUNT(*)::int FROM albums WHERE status = 'ACTIVE') AS total,
          COALESCE(
            (
              SELECT json_agg(row_to_json(p))
              FROM (
                SELECT
                  a.id,
                  a.title,
                  a.release_date AS "releaseDate",
                  a.cover_image_url AS "coverImageUrl",
                  a.status,
                  COALESCE(
                    (
                      SELECT json_agg(
                        json_build_object(
                          'id', ar.id,
                          'name', ar.name,
                          'position', aa.position,
                          'imageUrl', ar.image_url
                        ) ORDER BY aa.position ASC
                      )
                      FROM album_artists aa
                      JOIN artists ar ON ar.id = aa.artist_id
                      WHERE aa.album_id = a.id
                    ),
                    '[]'::json
                  ) AS artists,
                  (
                    SELECT COUNT(*)::int
                    FROM tracks tr
                    WHERE tr.album_id = a.id AND tr.status = 'ACTIVE'
                  ) AS "totalTracks",
                  0.0::float AS "relevanceScore"
                FROM albums a
                WHERE a.status = 'ACTIVE'
                ORDER BY a.created_at DESC
                LIMIT ${limit} OFFSET ${offset}
              ) p
            ),
            '[]'::json
          ) AS items;
      `;
      const result = await this.prisma.$queryRaw<RawQueryResult<AlbumSearchResultDto>[]>(query);
      const total = Number(result[0]?.total ?? 0);
      const items = this.parseItems<AlbumSearchResultDto>(result[0]?.items);
      return new SearchSectionDto<AlbumSearchResultDto>(items, total);
    }

    const rawLower = trimmed.toLowerCase();
    const prefixLike = `${rawLower}%`;
    const substringLike = `%${rawLower}%`;

    const query = Prisma.sql`
      WITH matched AS (
        SELECT
          a.id,
          a.title,
          a.release_date AS "releaseDate",
          a.cover_image_url AS "coverImageUrl",
          a.status,
          a.created_at,
          (
            (CASE WHEN LOWER(a.title) = ${rawLower} THEN 10.0 ELSE 0.0 END) +
            (CASE WHEN a.title ILIKE ${prefixLike} THEN 5.0 ELSE 0.0 END) +
            (CASE WHEN a.title ILIKE ${substringLike} THEN 2.0 ELSE 0.0 END) +
            (CASE WHEN to_tsvector('simple', a.title) @@ plainto_tsquery('simple', ${trimmed})
                  THEN 3.0 * ts_rank(to_tsvector('simple', a.title), plainto_tsquery('simple', ${trimmed}))
                  ELSE 0.0 END) +
            (similarity(a.title, ${trimmed}) * 4.0)
          ) AS "relevanceScore",
          COALESCE(
            (
              SELECT json_agg(
                json_build_object(
                  'id', ar.id,
                  'name', ar.name,
                  'position', aa.position,
                  'imageUrl', ar.image_url
                ) ORDER BY aa.position ASC
              )
              FROM album_artists aa
              JOIN artists ar ON ar.id = aa.artist_id
              WHERE aa.album_id = a.id
            ),
            '[]'::json
          ) AS artists,
          (
            SELECT COUNT(*)::int
            FROM tracks tr
            WHERE tr.album_id = a.id AND tr.status = 'ACTIVE'
          ) AS "totalTracks"
        FROM albums a
        WHERE a.status = 'ACTIVE'
          AND (
            a.title ILIKE ${prefixLike}
            OR a.title ILIKE ${substringLike}
            OR to_tsvector('simple', a.title) @@ plainto_tsquery('simple', ${trimmed})
            OR similarity(a.title, ${trimmed}) > 0.25
          )
      )
      SELECT
        (SELECT COUNT(*)::int FROM matched) AS total,
        COALESCE(
          (
            SELECT json_agg(row_to_json(p))
            FROM (
              SELECT
                id,
                title,
                "releaseDate",
                "coverImageUrl",
                status,
                artists,
                "totalTracks",
                ROUND("relevanceScore"::numeric, 2)::float AS "relevanceScore"
              FROM matched
              ORDER BY "relevanceScore" DESC, created_at DESC
              LIMIT ${limit} OFFSET ${offset}
            ) p
          ),
          '[]'::json
        ) AS items;
    `;

    try {
      const result = await this.prisma.$queryRaw<RawQueryResult<AlbumSearchResultDto>[]>(query);
      const total = Number(result[0]?.total ?? 0);
      const items = this.parseItems<AlbumSearchResultDto>(result[0]?.items);
      return new SearchSectionDto<AlbumSearchResultDto>(items, total);
    } catch (e: any) {
      this.logger.warn(`searchAlbums raw query error (${e.message}), executing Prisma fallback`);
      return this.searchAlbumsFallback(trimmed, limit, offset);
    }
  }

  async searchArtists(
    term: string,
    limit: number,
    offset: number,
  ): Promise<SearchSectionDto<ArtistSearchResultDto>> {
    const trimmed = (term || '').trim();

    if (!trimmed) {
      const query = Prisma.sql`
        SELECT
          (SELECT COUNT(*)::int FROM artists) AS total,
          COALESCE(
            (
              SELECT json_agg(row_to_json(p))
              FROM (
                SELECT
                  ar.id,
                  ar.name,
                  ar.normalized_name AS "normalizedName",
                  ar.bio,
                  ar.image_url AS "imageUrl",
                  0.0::float AS "relevanceScore"
                FROM artists ar
                ORDER BY ar.created_at DESC
                LIMIT ${limit} OFFSET ${offset}
              ) p
            ),
            '[]'::json
          ) AS items;
      `;
      const result = await this.prisma.$queryRaw<RawQueryResult<ArtistSearchResultDto>[]>(query);
      const total = Number(result[0]?.total ?? 0);
      const items = this.parseItems<ArtistSearchResultDto>(result[0]?.items);
      return new SearchSectionDto<ArtistSearchResultDto>(items, total);
    }

    const rawLower = trimmed.toLowerCase();
    const rawNorm = normalizeString(trimmed);
    const prefixLike = `${rawLower}%`;
    const substringLike = `%${rawLower}%`;
    const prefixLikeNorm = `${rawNorm}%`;
    const substringLikeNorm = `%${rawNorm}%`;

    const query = Prisma.sql`
      WITH matched AS (
        SELECT
          ar.id,
          ar.name,
          ar.normalized_name AS "normalizedName",
          ar.bio,
          ar.image_url AS "imageUrl",
          ar.created_at,
          (
            (CASE WHEN LOWER(ar.name) = ${rawLower} OR ar.normalized_name = ${rawNorm} THEN 10.0 ELSE 0.0 END) +
            (CASE WHEN ar.name ILIKE ${prefixLike} OR ar.normalized_name ILIKE ${prefixLikeNorm} THEN 5.0 ELSE 0.0 END) +
            (CASE WHEN ar.name ILIKE ${substringLike} OR ar.normalized_name ILIKE ${substringLikeNorm} THEN 2.0 ELSE 0.0 END) +
            (CASE WHEN to_tsvector('simple', ar.name) @@ plainto_tsquery('simple', ${trimmed})
                  THEN 3.0 * ts_rank(to_tsvector('simple', ar.name), plainto_tsquery('simple', ${trimmed}))
                  ELSE 0.0 END) +
            (similarity(ar.name, ${trimmed}) * 4.0)
          ) AS "relevanceScore"
        FROM artists ar
        WHERE (
          ar.name ILIKE ${prefixLike}
          OR ar.name ILIKE ${substringLike}
          OR ar.normalized_name ILIKE ${prefixLikeNorm}
          OR ar.normalized_name ILIKE ${substringLikeNorm}
          OR to_tsvector('simple', ar.name) @@ plainto_tsquery('simple', ${trimmed})
          OR similarity(ar.name, ${trimmed}) > 0.25
          OR similarity(ar.normalized_name, ${rawNorm}) > 0.25
        )
      )
      SELECT
        (SELECT COUNT(*)::int FROM matched) AS total,
        COALESCE(
          (
            SELECT json_agg(row_to_json(p))
            FROM (
              SELECT
                id,
                name,
                "normalizedName",
                bio,
                "imageUrl",
                ROUND("relevanceScore"::numeric, 2)::float AS "relevanceScore"
              FROM matched
              ORDER BY "relevanceScore" DESC, created_at DESC
              LIMIT ${limit} OFFSET ${offset}
            ) p
          ),
          '[]'::json
        ) AS items;
    `;

    try {
      const result = await this.prisma.$queryRaw<RawQueryResult<ArtistSearchResultDto>[]>(query);
      const total = Number(result[0]?.total ?? 0);
      const items = this.parseItems<ArtistSearchResultDto>(result[0]?.items);
      return new SearchSectionDto<ArtistSearchResultDto>(items, total);
    } catch (e: any) {
      this.logger.warn(`searchArtists raw query error (${e.message}), executing Prisma fallback`);
      return this.searchArtistsFallback(trimmed, limit, offset);
    }
  }

  private async searchTracksFallback(
    trimmed: string,
    limit: number,
    offset: number,
  ): Promise<SearchSectionDto<TrackSearchResultDto>> {
    const where: Prisma.TrackWhereInput = {
      status: 'ACTIVE',
      ...(trimmed
        ? {
            OR: [
              { title: { contains: trimmed, mode: 'insensitive' } },
              { slug: { contains: trimmed, mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const [tracks, total] = await Promise.all([
      this.prisma.track.findMany({
        where,
        take: limit,
        skip: offset,
        include: {
          album: true,
          trackArtists: {
            include: { artist: true },
            orderBy: { position: 'asc' },
          },
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.track.count({ where }),
    ]);

    const items: TrackSearchResultDto[] = tracks.map((t) => ({
      id: t.id,
      title: t.title,
      slug: t.slug,
      albumId: t.albumId,
      durationMs: t.durationMs,
      trackNumber: t.trackNumber,
      discNumber: t.discNumber,
      releaseDate: t.releaseDate,
      coverImageUrl: t.coverImageUrl,
      fileUrl: t.fileUrl,
      status: t.status,
      album: t.album
        ? {
            id: t.album.id,
            title: t.album.title,
            coverImageUrl: t.album.coverImageUrl,
          }
        : null,
      artists: t.trackArtists.map((ta) => ({
        id: ta.artist.id,
        name: ta.artist.name,
        role: ta.role,
        position: ta.position,
        imageUrl: ta.artist.imageUrl,
      })),
      relevanceScore: 1.0,
    }));

    return new SearchSectionDto<TrackSearchResultDto>(items, total);
  }

  private async searchAlbumsFallback(
    trimmed: string,
    limit: number,
    offset: number,
  ): Promise<SearchSectionDto<AlbumSearchResultDto>> {
    const where: Prisma.AlbumWhereInput = {
      status: 'ACTIVE',
      ...(trimmed
        ? {
            title: { contains: trimmed, mode: 'insensitive' },
          }
        : {}),
    };

    const [albums, total] = await Promise.all([
      this.prisma.album.findMany({
        where,
        take: limit,
        skip: offset,
        include: {
          albumArtists: {
            include: { artist: true },
            orderBy: { position: 'asc' },
          },
          tracks: {
            where: { status: 'ACTIVE' },
          },
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.album.count({ where }),
    ]);

    const items: AlbumSearchResultDto[] = albums.map((a) => ({
      id: a.id,
      title: a.title,
      releaseDate: a.releaseDate,
      coverImageUrl: a.coverImageUrl,
      status: a.status,
      artists: a.albumArtists.map((aa) => ({
        id: aa.artist.id,
        name: aa.artist.name,
        position: aa.position,
        imageUrl: aa.artist.imageUrl,
      })),
      totalTracks: a.tracks.length,
      relevanceScore: 1.0,
    }));

    return new SearchSectionDto<AlbumSearchResultDto>(items, total);
  }

  private async searchArtistsFallback(
    trimmed: string,
    limit: number,
    offset: number,
  ): Promise<SearchSectionDto<ArtistSearchResultDto>> {
    const rawNorm = normalizeString(trimmed);
    const where: Prisma.ArtistWhereInput = trimmed
      ? {
          OR: [
            { name: { contains: trimmed, mode: 'insensitive' } },
            { normalizedName: { contains: rawNorm, mode: 'insensitive' } },
          ],
        }
      : {};

    const [artists, total] = await Promise.all([
      this.prisma.artist.findMany({
        where,
        take: limit,
        skip: offset,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.artist.count({ where }),
    ]);

    const items: ArtistSearchResultDto[] = artists.map((ar) => ({
      id: ar.id,
      name: ar.name,
      normalizedName: ar.normalizedName,
      bio: ar.bio,
      imageUrl: ar.imageUrl,
      relevanceScore: 1.0,
    }));

    return new SearchSectionDto<ArtistSearchResultDto>(items, total);
  }
}
