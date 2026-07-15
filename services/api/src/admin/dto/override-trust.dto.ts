// services/api/src/admin/dto/override-trust.dto.ts
import { IsInt, Min, IsString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class OverrideTrustDto {
  @ApiProperty({ description: 'Number of successful deals', minimum: 0 })
  @IsInt()
  @Min(0)
  successfulDeals: number;

  @ApiProperty({ description: 'Number of ongoing deals', minimum: 0 })
  @IsInt()
  @Min(0)
  ongoingDeals: number;

  @ApiProperty({ description: 'Number of breached deals', minimum: 0 })
  @IsInt()
  @Min(0)
  breachedDeals: number;

  @ApiProperty({
    description: 'Reason for manual override (required for audit trail)',
  })
  @IsString()
  @MinLength(10, {
    message: 'Reason must be at least 10 characters for audit compliance',
  })
  reason: string;
}
