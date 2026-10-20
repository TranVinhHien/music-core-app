import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHealth(): { status: string; service: string; timestamp: string } {
    return {
      status: 'UP',
      service: 'music-library-service',
      timestamp: new Date().toISOString(),
    };
  }
}
