// services/api/src/admin/dto/review-kyc.dto.ts
import { IsEnum, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum KycReviewDecision {
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
}

export class ReviewKycDto {
  @ApiProperty({ enum: KycReviewDecision, description: 'KYC review decision' })
  @IsEnum(KycReviewDecision)
  status: KycReviewDecision;

  @ApiPropertyOptional({
    description: 'Reason for rejection (required if rejected)',
  })
  @IsOptional()
  @IsString()
  reason?: string;
}
