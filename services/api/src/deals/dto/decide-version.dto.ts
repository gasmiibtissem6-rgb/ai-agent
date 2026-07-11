import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';

/** A required party's decision on a submitted version: approve or reject. */
export class DecideVersionDto {
  @ApiProperty({ description: 'true to approve the version, false to reject.' })
  @IsBoolean()
  approve!: boolean;

  @ApiPropertyOptional({
    description: 'Reason, recommended when rejecting / requesting changes.',
    maxLength: 500,
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
