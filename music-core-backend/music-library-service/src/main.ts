import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { ResponseTransformInterceptor } from './common/interceptors/response-transform.interceptor';
import { GlobalExceptionFilter } from './common/filters/global-exception.filter';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  const port = process.env.PORT ? parseInt(process.env.PORT, 10) : 3003;
  const globalPrefix = process.env.GLOBAL_PREFIX || 'api/v1/library';
  const corsOrigin = process.env.CORS_ORIGIN || '*';

  // Enable CORS
  app.enableCors({
    origin: corsOrigin === '*' ? true : corsOrigin.split(','),
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  // Global Prefix
  app.setGlobalPrefix(globalPrefix);

  // Global Validation Pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Global Interceptor and Filter
  app.useGlobalInterceptors(new ResponseTransformInterceptor());
  app.useGlobalFilters(new GlobalExceptionFilter());

  // Swagger Documentation Setup
  const config = new DocumentBuilder()
    .setTitle('Music Library Service API')
    .setDescription('User playlists and favorite tracks microservice.')
    .setVersion('1.0.0')
    .addApiKey(
      { type: 'apiKey', name: 'X-User-ID', in: 'header' },
      'X-User-ID',
    )
    .addApiKey(
      { type: 'apiKey', name: 'X-User-Roles', in: 'header' },
      'X-User-Roles',
    )
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup(`${globalPrefix}/docs`, app, document);

  await app.listen(port);
  logger.log(`Music Library Service is running on http://localhost:${port}/${globalPrefix}`);
  logger.log(`Swagger documentation available at http://localhost:${port}/${globalPrefix}/docs`);
}
bootstrap();
