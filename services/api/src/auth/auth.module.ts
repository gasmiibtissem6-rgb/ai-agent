import { Module } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { ConfigModule } from '@nestjs/config'; 
import { JwtModule, JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  controllers: [AuthController],
  providers: [AuthService, PrismaService, JwtService],
  imports: [
    ConfigModule,
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'default_secret', // Use a secure secret in production
      signOptions: { expiresIn: '1h' }, // Token expiration time
    }),
  ],  
})
export class AuthModule {}