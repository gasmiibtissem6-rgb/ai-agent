import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

/**
 * Partial update of a DRAFT deal. Any provided `terms` object replaces the terms
 * of the current draft version (locked/approved versions are never modifiable).
 */
export class UpdateDealDto {
  @ApiPropertyOptional({ maxLength: 200 })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  title?: string;

  @ApiPropertyOptional({ maxLength: 2000 })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @ApiPropertyOptional({ example: 'nda', maxLength: 64 })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  dealType?: string;

  @ApiPropertyOptional({ type: Object })
  @IsOptional()
  @IsObject()
  terms?: Record<string, unknown>;
}
