// services/api/src/common/guards/auth.guard.ts
import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { Request } from 'express';
import * as jwt from 'jsonwebtoken';


export interface AuthenticatedUser {
  sub: string;      // This is the unique Supabase User ID (UUID)
  email: string;
  role: string;
  [key: string]: any;
}

@Injectable()
export class AuthGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const token = this.extractTokenFromHeader(request);

    if (!token) {
      throw new UnauthorizedException('Authentication token is missing');
    }

    try {
      const jwtSecret = process.env.JWT_SECRET;
      if (!jwtSecret) {
        throw new Error('JWT_SECRET configuration is missing on the server');
      }

      // Verify and decode the Supabase JWT token using the secret signature key
      const payload = jwt.verify(token, jwtSecret) as AuthenticatedUser;
      
      // Assign the payload to the request object so controllers can access user info
      (request as any).user = payload;
    } catch (error) {
      throw new UnauthorizedException('Invalid or expired authentication token');
    }

    return true;
  }

  private extractTokenFromHeader(request: Request): string | undefined {
    const [type, token] = request.headers.authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }
}