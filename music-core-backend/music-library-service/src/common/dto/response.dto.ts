import { ApiProperty } from '@nestjs/swagger';

export class ApiResponseDto<T = any> {
  @ApiProperty({ example: '200', description: 'HTTP Status Code as string' })
  code: string;

  @ApiProperty({ example: 'ok', description: 'Response message' })
  message: string;

  @ApiProperty({ required: false, description: 'Metadata, e.g. pagination' })
  meta?: any;

  @ApiProperty({ description: 'Response payload' })
  data: T;

  constructor(code: string, message: string, data: T, meta?: any) {
    this.code = code;
    this.message = message;
    this.data = data;
    this.meta = meta;
  }
}
