import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { DealPartyInputDto } from './deal-party.dto';

export class CreateDealDto {
  @ApiProperty({ maxLength: 200 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  title!: string;

  @ApiPropertyOptional({ maxLength: 2000 })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @ApiPropertyOptional({ example: 'nda', maxLength: 64 })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  dealType?: string;

  @ApiPropertyOptional({
    type: [DealPartyInputDto],
    description: 'Participants invited to the deal (creator is implicit).',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => DealPartyInputDto)
  parties?: DealPartyInputDto[];

  @ApiProperty({
    type: Object,
    description:
      'Structured deal terms persisted on the initial draft version.',
  })
  @IsObject()
  terms!: Record<string, unknown>;
}
