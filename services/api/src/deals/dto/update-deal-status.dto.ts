import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DealStatus } from '@prisma/client';
import { IsEnum, IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

/**
 * Statuses a deal creator may set on their own deal.
 *
 * `NEGOTIATION` is surfaced to end users as "Bridged"; the label lives in the
 * client, the enum value is the canonical `deal_status` stored in Postgres.
 * Terminal states (LOCKED, ARCHIVED) and reviewer-driven states
 * (PENDING_APPROVAL, CHANGES_REQUESTED, REJECTED) are deliberately excluded —
 * they belong to the approval flow, not to a creator-initiated override.
 */
export const CREATOR_SETTABLE_STATUSES = [
  DealStatus.APPROVED,
  DealStatus.NEGOTIATION,
  DealStatus.CANCELLED,
] as const;

export class UpdateDealStatusDto {
  @ApiProperty({
    enum: CREATOR_SETTABLE_STATUSES,
    description:
      'Target status. NEGOTIATION is displayed as "Bridged" in the user app.',
  })
  @IsEnum(DealStatus)
  @IsIn(CREATOR_SETTABLE_STATUSES as readonly DealStatus[], {
    message: 'Status must be one of APPROVED, NEGOTIATION or CANCELLED.',
  })
  status!: DealStatus;

  @ApiPropertyOptional({
    maxLength: 500,
    description: 'Optional note recorded on the audit entry.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
