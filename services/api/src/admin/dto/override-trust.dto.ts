// services/api/src/admin/dto/override-trust.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsString, Min, IsNotEmpty } from 'class-validator';

export class OverrideTrustDto {
  @ApiProperty({ minimum: 0, example: 3 })
  @IsNumber()
  @Min(0)
  successfulDeals!: number;

  @ApiProperty({ minimum: 0, example: 1 })
  @IsNumber()
  @Min(0)
  ongoingDeals!: number;

  @ApiProperty({ minimum: 0, example: 0 })
  @IsNumber()
  @Min(0)
  breachedDeals!: number;

  @ApiProperty({
    description: 'Mandatory justification recorded in the admin audit log.',
  })
  @IsString()
  @IsNotEmpty({ message: 'A precise explanation is mandatory to override structural system trust metrics.' })
  reason!: string;
}