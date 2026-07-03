import { IsString, IsOptional, IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class ContractPartyDto {
  @IsString()
  role: string; // "CLIENT" ou "PRESTATAIRE"
  @IsString()
  fullName: string;
  @IsOptional()
  @IsString()
  functionRole?: string;
  @IsOptional()
  @IsString()
  address?: string;
  @IsOptional()
  @IsString()
  email?: string;
}

export class CreateContractDto {
  @IsString()
  title: string;
  @IsOptional()
  @IsString()
  description?: string;
  @IsOptional()
  @IsString()
  contractType?: string;
  @IsOptional()
  @IsString()
  content?: string;
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ContractPartyDto)
  parties?: ContractPartyDto[] = [];
}
