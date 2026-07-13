import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUrl,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

/**
 * Self-service profile edit. Only presentation fields are exposed: `kycStatus`,
 * `isAdmin` and `adminRole` are privilege-bearing and must never be settable by
 * the profile owner.
 */
export class UpdateProfileDto {
  @ApiPropertyOptional({ maxLength: 120 })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  displayName?: string;

  @ApiPropertyOptional({
    description: 'Public handle: 3-30 chars, letters/digits/underscore.',
    example: 'jane_doe',
  })
  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(30)
  @Matches(/^[a-zA-Z0-9_]+$/, {
    message: 'username may only contain letters, digits and underscores.',
  })
  username?: string;

  @ApiPropertyOptional({ maxLength: 2048 })
  @IsOptional()
  @IsString()
  @MaxLength(2048)
  @IsUrl({ require_protocol: true }, { message: 'avatarUrl must be a URL.' })
  avatarUrl?: string;

  @ApiPropertyOptional({
    description: 'Whether the profile is discoverable by QR scan.',
  })
  @IsOptional()
  @IsBoolean()
  isPublic?: boolean;
}
