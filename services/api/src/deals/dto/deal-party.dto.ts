import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

/** A single participant supplied when creating a deal. */
export class DealPartyInputDto {
  @ApiProperty({ example: 'counterparty@example.com', maxLength: 320 })
  @IsEmail()
  @MaxLength(320)
  email!: string;

  @ApiProperty({ example: 'buyer', maxLength: 64 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  role!: string;

  @ApiPropertyOptional({
    default: true,
    description: 'Whether this party must approve versions before locking.',
  })
  @IsOptional()
  @IsBoolean()
  requiredApproval?: boolean;
}
