import { IsString, IsArray, IsOptional } from 'class-validator';

export class ChatMessageDto {
  @IsString()
  message: string;

  @IsArray()
  @IsOptional()
  history?: { role: string; content: string }[];
}
