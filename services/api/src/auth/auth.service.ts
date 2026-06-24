import { Injectable, UnauthorizedException } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AuthService {
  private supabase: SupabaseClient;

  constructor(
    private prisma: PrismaService,
    private configService: ConfigService 
  ) {
    const supabaseUrl = this.configService.get<string>('SUPABASE_URL');
    const supabaseKey = this.configService.get<string>('SUPABASE_ANON_KEY');

    if (!supabaseUrl || !supabaseKey) {
      throw new Error('Supabase environment variables are missing!');
    }

    this.supabase = createClient(supabaseUrl, supabaseKey);
  }

  // --- 1. THE LOGIN METHOD ---
  async login(email: string, pass: string) {
    const { data: authData, error } = await this.supabase.auth.signInWithPassword({
      email: email,
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

  // --- 2. THE NEW GET PROFILE METHOD ---
  async getProfile(authHeader: string) {
    if (!authHeader) {
      throw new UnauthorizedException('Missing authorization header');
    }

    // Extract the raw token string (remove the "Bearer " part)
    const token = authHeader.replace('Bearer ', '').trim();

    // Ask Supabase to verify if this token is real and hasn't expired
    const { data: authData, error } = await this.supabase.auth.getUser(token);

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

    // Return it in the exact wrapper format your Next.js frontend expects!
    return profile;
  }
}