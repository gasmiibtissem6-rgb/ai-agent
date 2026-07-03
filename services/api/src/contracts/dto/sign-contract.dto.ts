import { IsString } from 'class-validator';

export class SignContractDto {
  @IsString()
  signature: string;
}
