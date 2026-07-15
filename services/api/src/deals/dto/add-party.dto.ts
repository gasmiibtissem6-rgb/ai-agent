import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

/**
 * Attach a counterparty to a deal by their username OR email. The creator uses
 * this after creating the deal to pick who they want to deal with.
 */
export class AddPartyDto {
  @ApiProperty({
    description: 'The other party, given as a username or an email address.',
    example: 'jane_doe',
  })
  @IsString()
  @MinLength(3)
  @MaxLength(320)
  identifier!: string;

  @ApiPropertyOptional({ example: 'Partner', maxLength: 64 })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  role?: string;
}
