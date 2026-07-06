import { Module } from '@nestjs/common';
import { KycController } from './kyc.controller'; // Adjust filename to match your controller file
import { KycService } from './kyc.service';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module'; // 1. Import your AuthModule (adjust the path if needed)

@Module({
  imports: [
    PrismaModule, 
    AuthModule // 2. Add AuthModule here to provide AuthService to your JwtAuthGuard
  ],
  controllers: [KycController],
  providers: [KycService],
})
export class KycModule {}