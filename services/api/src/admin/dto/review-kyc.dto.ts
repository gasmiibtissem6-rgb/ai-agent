import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

/** Admin decision applied to a KYC submission under review. */
export enum KycReviewDecision {
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
}

export class ReviewKycDto {
  @ApiProperty({ enum: KycReviewDecision })
  @IsEnum(KycReviewDecision)
  status!: KycReviewDecision;

  @ApiPropertyOptional({
    description: 'Required when rejecting; explains the decision.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  reason?: string;
}
