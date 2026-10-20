import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { ApiResponseDto } from '../dto/response.dto';
import { PaginatedResult } from '../dto/pagination.dto';

@Injectable()
export class ResponseTransformInterceptor<T>
  implements NestInterceptor<T, ApiResponseDto<T>>
{
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<ApiResponseDto<T>> {
    const http = context.switchToHttp();
    const response = http.getResponse();
    const statusCode = response.statusCode || 200;

    return next.handle().pipe(
      map((res) => {
        if (res instanceof ApiResponseDto) {
          return res;
        }

        if (res instanceof PaginatedResult || (res && res.list !== undefined && res.pagination !== undefined)) {
          return new ApiResponseDto(
            String(statusCode),
            'ok',
            res.list,
            res.pagination,
          );
        }

        return new ApiResponseDto(
          String(statusCode),
          'ok',
          res !== undefined ? res : null,
          null,
        );
      }),
    );
  }
}
