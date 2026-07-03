import { IsString } from 'class-validator';

export class GenerateContractDto {
  @IsString()
  prompt: string;
}
