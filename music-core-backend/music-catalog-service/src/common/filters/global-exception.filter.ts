import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Response } from 'express';
import { ApiResponseDto } from '../dto/response.dto';

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Internal server error';
    let meta: any = null;

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const res = exception.getResponse();

      if (typeof res === 'string') {
        message = res;
      } else if (typeof res === 'object' && res !== null) {
        const resObj = res as Record<string, any>;
        message = Array.isArray(resObj.message)
          ? resObj.message.join(', ')
          : resObj.message || exception.message;
        meta = resObj.error || null;
      }
    } else if (typeof exception === 'object' && exception !== null) {
      const err = exception as any;
      // Handle Prisma errors gracefully
      if (err.code === 'P2002') {
        status = HttpStatus.CONFLICT;
        message = `Unique constraint violation on field(s): ${err.meta?.target || 'unknown'}`;
        meta = err.meta;
      } else if (err.code === 'P2025') {
        status = HttpStatus.NOT_FOUND;
        message = 'Requested record not found';
        meta = err.meta;
      } else if (err.code === 'P2003') {
        status = HttpStatus.BAD_REQUEST;
        message = 'Foreign key constraint failed';
        meta = err.meta;
      } else {
        message = err.message || message;
      }
    }

    if (status >= 500) {
      this.logger.error(
        `[${status}] ${message}`,
        exception instanceof Error ? exception.stack : undefined,
      );
    } else {
      this.logger.warn(`[${status}] ${message}`);
    }

    const errorResponse = new ApiResponseDto(String(status), message, null, meta);

    response.status(status).json(errorResponse);
  }
}
