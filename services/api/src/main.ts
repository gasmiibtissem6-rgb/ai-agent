// services/api/src/main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { ValidationPipe } from '@nestjs/common';

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

  // Register your structural response formatting layers globally
  app.useGlobalInterceptors(new TransformInterceptor());
  app.useGlobalFilters(new HttpExceptionFilter());

  const port = process.env.API_PORT || 3001;
  await app.listen(port);
  console.log(
    `🚀 IDEAL API Foundation is live on: http://localhost:${port}/${apiPrefix}`,
  );
}
bootstrap();
