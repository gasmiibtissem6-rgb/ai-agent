import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

/** Payload for exchanging a Supabase refresh token for a fresh session. */
export class RefreshTokenDto {
  @ApiProperty({
    description: 'The Supabase refresh token issued at login/register.',
    maxLength: 2048,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(2048)
  refresh_token!: string;
}
