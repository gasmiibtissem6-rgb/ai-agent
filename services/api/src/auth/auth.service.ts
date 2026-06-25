import {
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AuthService {
  private supabase: SupabaseClient | null = null;

  constructor(
    private prisma: PrismaService,
    private configService: ConfigService,
  ) {
    const supabaseUrl = this.configService.get<string>('SUPABASE_URL');
    const supabaseKey = this.configService.get<string>('SUPABASE_ANON_KEY');

    if (supabaseUrl && supabaseKey) {
      this.supabase = createClient(supabaseUrl, supabaseKey);
    }
  }

  private getSupabaseClient(): SupabaseClient {
    if (!this.supabase) {
      throw new ServiceUnavailableException(
        'Supabase authentication is not configured yet. Add SUPABASE_URL and SUPABASE_ANON_KEY to enable auth endpoints.',
      );
    }

    return this.supabase;
  }

  async login(email: string, pass: string) {
    const supabase = this.getSupabaseClient();
    const { data: authData, error } =
      await supabase.auth.signInWithPassword({
        email,
        password: pass,
      });

    if (error || !authData.user) {
      throw new UnauthorizedException('Invalid administrative credentials.');
    }

    // FIX: Using this.prisma.profile instead of this.prisma.user!
    const profile = await this.prisma.profile.findUnique({
      where: { authUserId: authData.user.id },
    });

    if (!profile || !profile.isAdmin) {
      throw new UnauthorizedException('Access denied. Admin privileges required.');
    }

    return {
      token: authData.session.access_token,
    };
  }

  async getProfile(authHeader: string) {
    if (!authHeader) {
      throw new UnauthorizedException('Missing authorization header');
    }

    const supabase = this.getSupabaseClient();
    const token = authHeader.replace('Bearer ', '').trim();

    const { data: authData, error } = await supabase.auth.getUser(token);

    if (error || !authData.user) {
      throw new UnauthorizedException('Invalid or expired token.');
    }

    // Fetch the actual user details from Prisma using the verified ID
    const profile = await this.prisma.profile.findUnique({
      where: { authUserId: authData.user.id },
    });

    if (!profile) {
      throw new UnauthorizedException('Profile not found.');
    }

    return profile;
  }
}
