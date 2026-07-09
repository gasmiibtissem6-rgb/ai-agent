import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  Max,
  Min,
} from 'class-validator';
import {
  DEAL_INVITE_PERMISSIONS,
  DealInvitePermission,
} from '../deal-quota.constants';

export class ShareDealDto {
  @ApiPropertyOptional({
    default: 48,
    minimum: 1,
    maximum: 720,
    description: 'Link lifetime in hours (max 30 days).',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(720)
  expiresInHours: number = 48;

  @ApiProperty({
    isArray: true,
    enum: DEAL_INVITE_PERMISSIONS,
    example: ['VIEW'],
    description: 'Permissions granted to whoever accepts the link.',
  })
  @IsArray()
  @ArrayNotEmpty()
  @IsIn(DEAL_INVITE_PERMISSIONS, { each: true })
  permissions!: DealInvitePermission[];

  @ApiPropertyOptional({
    minimum: 1,
    description: 'Maximum number of accepts allowed (omit for unlimited).',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  maxUses?: number;
}
