import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class InitiateKycDto {
  @ApiPropertyOptional({
    description: 'Optional external KYC provider reference / session id.',
    example: 'prov_ref_8f3a2c',
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  providerReference?: string;
}
