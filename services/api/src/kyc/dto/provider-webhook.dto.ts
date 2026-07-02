import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class ProviderWebhookDto {
  @ApiProperty({
    description: 'Provider reference correlating the webhook to a submission.',
    example: 'prov_ref_8f3a2c',
  })
  @IsString()
  @IsNotEmpty()
  reference!: string;

  @ApiProperty({
    description: 'External vendor status string (e.g. verified, rejected).',
    example: 'verified',
  })
  @IsString()
  @IsNotEmpty()
  status!: string;

  @ApiPropertyOptional({ description: 'Reason supplied on rejection.' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  reason?: string;
}
