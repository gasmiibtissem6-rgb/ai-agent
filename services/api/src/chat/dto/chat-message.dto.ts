import {
  IsArray,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class ChatMessageDto {
  @IsString()
  @MaxLength(10000)
  message!: string;

  @IsOptional()
  @IsArray()
  history?: Array<{
    role: string;
    content: string;
  }>;

  @IsOptional()
  @IsString()
  sessionId?: string;

  @IsOptional()
  @IsString()
  image?: string;
  
}
