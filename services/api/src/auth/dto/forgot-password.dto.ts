import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, MaxLength } from 'class-validator';

/** Payload to trigger a password-reset email (Supabase-backed). */
export class ForgotPasswordDto {
  @ApiProperty({ example: 'user@example.com', format: 'email', maxLength: 320 })
  @IsEmail()
  @MaxLength(320)
  email!: string;
}
