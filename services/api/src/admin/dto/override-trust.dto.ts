// services/api/src/admin/dto/override-trust.dto.ts
import { IsNumber, IsString, Min, IsNotEmpty } from 'class-validator';

export class OverrideTrustDto {
  @IsNumber()
  @Min(0)
  successfulDeals!: number; // 👈 Notice the '!' here

  @IsNumber()
  @Min(0)
  ongoingDeals!: number;

  @IsNumber()
  @Min(0)
  breachedDeals!: number;

  @IsString()
  @IsNotEmpty({ message: 'A precise explanation is mandatory to override structural system trust metrics.' })
  reason!: string;
}