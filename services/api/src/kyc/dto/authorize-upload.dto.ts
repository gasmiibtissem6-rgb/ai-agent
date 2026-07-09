import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsIn, IsInt, IsString, Max, MaxLength, Min } from 'class-validator';

/** MIME types accepted for KYC documents. */
export const ALLOWED_KYC_MIME_TYPES = [
  'image/jpeg',
  'image/png',
  'application/pdf',
] as const;

/** Hard cap on a single KYC document (10 MB). */
export const MAX_KYC_FILE_BYTES = 10 * 1024 * 1024;

export enum DocumentSideDto {
  FRONT = 'front',
  BACK = 'back',
  SELFIE = 'selfie',
}

export class AuthorizeUploadDto {
  @ApiProperty({ example: 'passport-front.jpg', maxLength: 255 })
  @IsString()
  @MaxLength(255)
  fileName!: string;

  @ApiProperty({ enum: ALLOWED_KYC_MIME_TYPES })
  @IsIn([...ALLOWED_KYC_MIME_TYPES])
  mimeType!: string;

  @ApiProperty({ minimum: 1, maximum: MAX_KYC_FILE_BYTES, example: 1048576 })
  @IsInt()
  @Min(1)
  @Max(MAX_KYC_FILE_BYTES)
  sizeBytes!: number;

  @ApiProperty({ enum: DocumentSideDto })
  @IsEnum(DocumentSideDto)
  documentSide!: DocumentSideDto;
}
