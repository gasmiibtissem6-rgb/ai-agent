// main.ts
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { json, urlencoded } from 'express';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';

function validateEnv(): void {
  const required = [
    //'JWT_SECRET',
    'DATABASE_URL',
    //'SUPABASE_URL',
    //'SUPABASE_SERVICE_KEY',
  ];

  const missing = required.filter((key) => !process.env[key]);

  if (missing.length > 0) {
    console.error(
      ` Variables d'environnement manquantes : ${missing.join(', ')}`,
    );
    process.exit(1); // Le serveur ne démarre pas
  }
}

async function bootstrap() {
  // Vérification en tout premier
  validateEnv();

  const app = await NestFactory.create(AppModule);

  // Préfixe global — une seule fois, au bon endroit
  app.setGlobalPrefix('api/v1');

  //  Body parsers — une seule fois
  app.use(json({ limit: '50mb' }));
  app.use(urlencoded({ limit: '50mb', extended: true }));

  //  CORS — une seule fois, domaines depuis .env
  const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') ?? [];
  app.enableCors({
    origin: (
      origin: string | undefined,
      callback: (err: Error | null, allow?: boolean) => void,
    ) => {
      // Autoriser les appels sans origin (mobile, Postman, curl)
      if (!origin) return callback(null, true);

      if (allowedOrigins.includes(origin)) {
        return callback(null, true);
      }

      return callback(new Error(`Origin non autorisée : ${origin}`), false);
    },
    methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  });

  //  ValidationPipe — une seule fois, bien configuré
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,           // Convertit les types automatiquement
      whitelist: true,           // Supprime les champs non déclarés dans le DTO
      forbidNonWhitelisted: true, // Retourne une erreur si champ inconnu
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  //  Intercepteurs et filtres globaux
  app.useGlobalInterceptors(new TransformInterceptor());
  app.useGlobalFilters(new HttpExceptionFilter());

  //  Swagger / OpenAPI — exposé sous le préfixe global
  const swaggerConfig = new DocumentBuilder()
    .setTitle('IDEAL API')
    .setDescription('Authentication & authorization-protected API surface.')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const swaggerDocument = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/v1/docs', app, swaggerDocument);

  const port = process.env.API_PORT ?? '3001';

  try {
    await app.listen(port);
    console.log(` API live → http://localhost:${port}/api/v1`);
  } catch (error: unknown) {
    if (
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      (error as NodeJS.ErrnoException).code === 'EADDRINUSE'
    ) {
      console.error(` Port ${port} déjà utilisé.`);
      process.exit(1);
    }
    throw error;
  }
}

bootstrap();