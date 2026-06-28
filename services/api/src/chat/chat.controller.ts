import { Controller, Post, Body, Req } from '@nestjs/common';
import { ChatService } from './chat.service';
import { ChatMessageDto } from './dto/chat-message.dto';

@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post('message')
  async sendMessage(@Body() dto: ChatMessageDto, @Req() req: any) {
    return this.chatService.sendMessage(dto);
  }
}
