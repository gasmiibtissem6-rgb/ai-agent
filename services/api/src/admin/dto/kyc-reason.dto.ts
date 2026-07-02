import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

/** Mandatory justification recorded in the audit log for a state-changing KYC decision. */
export class KycReasonDto {
  @ApiProperty({ description: 'Reason for the decision (required, non-empty).', maxLength: 1000 })
  @IsString()
  @IsNotEmpty({ message: 'A reason is required for this action.' })
  @MaxLength(1000)
  reason!: string;
}
