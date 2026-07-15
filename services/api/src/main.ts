// main.ts
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { json, urlencoded } from 'express';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';
import cookieParser from 'cookie-parser';
import { isExplicitDevelopment, isOriginAllowed } from './common/cors';

const defaultDevOrigins = ['http://localhost:3000', 'http://localhost:3001'];
const isLocalDevelopment = () =>
  !process.env.NODE_ENV || process.env.NODE_ENV === 'development';

function validateEnv(): void {
  // Variables strictement requises — le serveur refuse de démarrer sans elles.
  const required = ['JWT_SECRET', 'DATABASE_URL'];
  // Optionnel : SUPABASE_* et SUPABASE_JWT_SECRET.

  const missing = required.filter((key) => !process.env[key]);

  if (missing.length > 0) {
    console.error(
      `Variables d'environnement requises manquantes : ${missing.join(', ')}`,
    );
    process.exit(1); // Le serveur ne démarre pas
  }

  if (!process.env.ALLOWED_ORIGINS && !isLocalDevelopment()) {
    console.error(
      "Variables d'environnement requises manquantes : ALLOWED_ORIGINS",
    );
    process.exit(1);
  }

  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
  const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const hasAnySupabaseEnv = Boolean(
    supabaseUrl || supabaseAnonKey || supabaseServiceRoleKey,
  );
  const hasAllSupabaseEnv = Boolean(
    supabaseUrl && supabaseAnonKey && supabaseServiceRoleKey,
  );

  if (hasAnySupabaseEnv && !hasAllSupabaseEnv) {
    const missingSupabase = [
      !supabaseUrl ? 'SUPABASE_URL' : null,
      !supabaseAnonKey ? 'SUPABASE_ANON_KEY' : null,
      !supabaseServiceRoleKey ? 'SUPABASE_SERVICE_ROLE_KEY' : null,
    ].filter((key): key is string => key !== null);

    console.error(
      `Configuration Supabase incomplète : ${missingSupabase.join(', ')}`,
    );
    process.exit(1);
  }
}

function getAllowedOrigins(): string[] {
  const configuredOrigins = (process.env.ALLOWED_ORIGINS ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter((origin) => origin.length > 0);

  if (configuredOrigins.length > 0) {
    return configuredOrigins;
  }

  if (isLocalDevelopment()) {
    return defaultDevOrigins;
  }

  return [];
}

async function bootstrap() {
  // Vérification en tout premier
  validateEnv();

  const app = await NestFactory.create(AppModule);

  // Enable cookie parsing middleware
  app.use(cookieParser());

  // Préfixe global — une seule fois, au bon endroit
  app.setGlobalPrefix('api/v1');

  //  Body parsers — une seule fois
  app.use(json({ limit: '50mb' }));
  app.use(urlencoded({ limit: '50mb', extended: true }));

  //  CORS — une seule fois, allowlist stricte depuis ALLOWED_ORIGINS.
  //  En local, une fallback explicite autorise seulement les origines connues.
  const allowedOrigins = getAllowedOrigins();
  const allowAnyLoopback = isExplicitDevelopment();

  if (allowAnyLoopback) {
    console.warn(
      '[CORS] NODE_ENV=development : toute origine loopback (http://localhost:<port>) ' +
        'est acceptée, en plus de ALLOWED_ORIGINS. Ne jamais activer en production.',
    );
  }

  app.enableCors({
    origin: (
      origin: string | undefined,
      callback: (err: Error | null, allow?: boolean) => void,
    ) => {
      // Autoriser les appels sans origin (mobile, Postman, curl)
      if (!origin) return callback(null, true);

      // `flutter run -d chrome` tire un port aléatoire à chaque lancement, donc
      // aucune allowlist fixe ne peut le couvrir. La tolérance est restreinte au
      // loopback ET au mode développement explicite : la production reste sur
      // l'allowlist seule.
      if (isOriginAllowed(origin, allowedOrigins, allowAnyLoopback)) {
        return callback(null, true);
      }

      return callback(new Error(`Origin non autorisée : ${origin}`), false);
    },

    methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization','X-Requested-With', 'Accept'],
    credentials: true,
  });

  //  ValidationPipe — une seule fois, bien configuré
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true, // Convertit les types automatiquement
      whitelist: true, // Supprime les champs non déclarés dans le DTO
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
