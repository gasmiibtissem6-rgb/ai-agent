// services/api/src/prisma/prisma.service.ts
import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(PrismaService.name);

  async onModuleInit() {
    if (!process.env.DATABASE_URL) {
      this.logger.warn(
        'DATABASE_URL is not set. Prisma startup connection was skipped.',
      );
      return;
    }

    // Connects to your PostgreSQL instance on startup when configured
    await this.$connect();

    // Setup auth trigger and enable realtime on profiles
    try {
      await this.$executeRawUnsafe(`
        CREATE OR REPLACE FUNCTION public.handle_new_user()
        RETURNS trigger AS $$
        BEGIN
          INSERT INTO public.profiles (id, auth_user_id, email, display_name, kyc_status, is_admin, updated_at)
          VALUES (
            gen_random_uuid(),
            new.id,
            new.email,
            COALESCE(new.raw_user_meta_data->>'display_name', new.raw_user_meta_data->>'full_name', 'Anonymous User'),
            'NOT_STARTED'::kyc_status,
            FALSE,
            NOW()
          )
          ON CONFLICT (auth_user_id) DO UPDATE
          SET email = EXCLUDED.email,
              display_name = COALESCE(EXCLUDED.display_name, public.profiles.display_name),
              updated_at = NOW();
          RETURN new;
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
      `);

      await this.$executeRawUnsafe(`
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created') THEN
            CREATE TRIGGER on_auth_user_created
              AFTER INSERT ON auth.users
              FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
          END IF;
        END $$;
      `);

      // Backfill existing users from auth.users to public.profiles
      await this.$executeRawUnsafe(`
        INSERT INTO public.profiles (id, auth_user_id, email, display_name, kyc_status, is_admin, updated_at)
        SELECT 
          gen_random_uuid(),
          id,
          email,
          COALESCE(raw_user_meta_data->>'display_name', raw_user_meta_data->>'full_name', 'Anonymous User'),
          'NOT_STARTED'::kyc_status,
          FALSE,
          NOW()
        FROM auth.users
        ON CONFLICT (auth_user_id) DO UPDATE
        SET email = EXCLUDED.email,
            updated_at = NOW();
      `);

      await this.$executeRawUnsafe(`
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
            CREATE PUBLICATION supabase_realtime;
          END IF;
          
          IF NOT EXISTS (
            SELECT 1 
            FROM pg_publication_rel pr
            JOIN pg_class c ON pr.prrelid = c.oid
            JOIN pg_publication p ON pr.prpubid = p.oid
            WHERE p.pubname = 'supabase_realtime' AND c.relname = 'profiles'
          ) THEN
            ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
          END IF;
        END $$;
      `);
      this.logger.log(
        'PrismaService: Supabase sync trigger and realtime publication verified/created successfully.',
      );
    } catch (err) {
      this.logger.error(
        'PrismaService: Failed to setup Supabase sync trigger or realtime:',
        err,
      );
    }
  }

  async onModuleDestroy() {
    if (!process.env.DATABASE_URL) {
      return;
    }

    // Safely tears down the connection pool if the server shuts down
    await this.$disconnect();
  }
}
