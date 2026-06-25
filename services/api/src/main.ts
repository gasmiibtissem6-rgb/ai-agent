import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const apiPrefix = 'api/v1';

  app.setGlobalPrefix(apiPrefix);
  app.enableCors({
    origin: true,
    credentials: true,
  });

  // Enable global validations (very useful for incoming post data)
  app.useGlobalPipes(new ValidationPipe({ transform: true }));

  app.enableCors({
    origin: 'http://localhost:3000', // Allow your Next.js admin frontend
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true, // Allow cookies / authorization headers if needed
  });

  app.enableCors({
    origin: '*', // For production, replace with your exact frontend domain URL
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });
  // Register your structural response formatting layers globally
  app.useGlobalInterceptors(new TransformInterceptor());
  app.useGlobalFilters(new HttpExceptionFilter());
  app.setGlobalPrefix('api');

  const port = process.env.API_PORT || 3001;
  try {
    await app.listen(port);
    console.log(
      `🚀 IDEAL API Foundation is live on: http://localhost:${port}/${apiPrefix}`,
    );
  } catch (error: unknown) {
    if (
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      error.code === 'EADDRINUSE'
    ) {
      console.error(
        `Port ${port} is already in use. Stop the existing API process or run with API_PORT=<port> npm run dev:api.`,
      );
      process.exit(1);
    }

    throw error;
  }
}
bootstrap();
