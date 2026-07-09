import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
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

  @ApiPropertyOptional({ maxLength: 2048 })
  @IsOptional()
  @IsString()
  @MaxLength(2048)
  @IsUrl({ require_protocol: true }, { message: 'avatarUrl must be a URL.' })
  avatarUrl?: string;
}
