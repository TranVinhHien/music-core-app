import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios, { AxiosInstance } from 'axios';

export interface CatalogTrackDto {
  id: string;
  title: string;
  slug?: string;
  albumId?: string;
  durationMs?: number;
  trackNumber?: number;
  discNumber?: number;
  releaseDate?: string;
  fileUrl?: string;
  status: string;
  album?: any;
  trackArtists?: any[];
  trackGenres?: any[];
  trackSources?: any[];
}

@Injectable()
export class CatalogClient {
  private readonly logger = new Logger(CatalogClient.name);
  private readonly axiosInstance: AxiosInstance;

  constructor(private readonly configService: ConfigService) {
    const baseURL = this.configService.get<string>(
      'CATALOG_SERVICE_URL',
      'http://localhost:3002/api/v1/catalog',
    );
    this.axiosInstance = axios.create({
      baseURL,
      timeout: 5000,
    });
  }

  async getTrackById(trackId: string): Promise<CatalogTrackDto | null> {
    try {
      const response = await this.axiosInstance.get(`/tracks/${trackId}`);
      if (response.data && response.data.data) {
        return response.data.data;
      }
      return null;
    } catch (error: any) {
      this.logger.warn(`Failed to fetch track ${trackId} from catalog: ${error.message}`);
      return null;
    }
  }

  async getTracksByIds(trackIds: string[]): Promise<Map<string, CatalogTrackDto>> {
    const trackMap = new Map<string, CatalogTrackDto>();
    const uniqueIds = Array.from(new Set(trackIds));

    if (uniqueIds.length === 0) {
      return trackMap;
    }

    const promises = uniqueIds.map(async (id) => {
      const track = await this.getTrackById(id);
      if (track) {
        trackMap.set(id, track);
      }
    });

    await Promise.all(promises);
    return trackMap;
  }
}
