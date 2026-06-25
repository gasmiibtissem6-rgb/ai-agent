// services/api/src/main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

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
  await app.listen(port);
  console.log(`🚀 IDEAL API Foundation is live on: http://localhost:${port}`);
}
bootstrap();