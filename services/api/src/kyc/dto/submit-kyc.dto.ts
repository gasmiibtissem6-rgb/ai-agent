import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';

/**
 * Optional applicant identity fields.
 *
 * FLAGGED (see summary): there is no confirmed Prisma column/table to persist these, so
 * they are validated but NOT stored yet. Ranine must confirm a home before persistence.
 */
export class KycPersonalInfoDto {
  @ApiPropertyOptional({ maxLength: 120 })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  firstName?: string;

  @ApiPropertyOptional({ maxLength: 120 })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  lastName?: string;

  @ApiPropertyOptional({ example: '1990-01-31', maxLength: 32 })
  @IsOptional()
  @IsString()
  @MaxLength(32)
  dateOfBirth?: string;

  @ApiPropertyOptional({ maxLength: 80 })
  @IsOptional()
  @IsString()
  @MaxLength(80)
  nationality?: string;

  @ApiPropertyOptional({ maxLength: 128 })
  @IsOptional()
  @IsString()
  @MaxLength(128)
  documentNumber?: string;
}

export class SubmitKycDto {
  @ApiProperty({ example: 'passport', maxLength: 64 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  documentType!: string;

  @ApiProperty({
    description:
      'Storage path pre-authorized via /kyc/storage/authorize (front).',
    maxLength: 1024,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(1024)
  storagePathFront!: string;

  @ApiPropertyOptional({
    description:
      'Storage path pre-authorized via /kyc/storage/authorize (back).',
    maxLength: 1024,
  })
  @IsOptional()
  @IsString()
  @MaxLength(1024)
  storagePathBack?: string;

  @ApiProperty({
    description:
      'Storage path pre-authorized via /kyc/storage/authorize (selfie).',
    maxLength: 1024,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(1024)
  storagePathSelfie!: string;

  @ApiPropertyOptional({ type: KycPersonalInfoDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => KycPersonalInfoDto)
  personalInfo?: KycPersonalInfoDto;
}
