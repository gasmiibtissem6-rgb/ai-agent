import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsObject, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateDealVersionDto {
  @ApiProperty({
    type: Object,
    description: 'Updated deal terms for the new version.',
  })
  @IsObject()
  terms!: Record<string, unknown>;

  @ApiPropertyOptional({
    maxLength: 200,
    description: 'Optional title override (defaults to the deal title).',
  })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  title?: string;

  @ApiPropertyOptional({
    maxLength: 1000,
    description: 'Human-readable summary of what changed in this version.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  summary?: string;
}
