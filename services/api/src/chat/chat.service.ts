import { Injectable } from '@nestjs/common';
import { AiProvider } from './providers/ai-provider.interface';
import { MockAiProvider } from './providers/mock-ai.provider';
import { ClaudeAiProvider } from './providers/claude-ai.provider';
import { GeminiAiProvider } from './providers/gemini-ai.provider';
import { ChatMessageDto } from './dto/chat-message.dto';
import { detectChatMode, FAQ_SYSTEM_PROMPT, CONTRACT_SYSTEM_PROMPT } from './chat.types';

@Injectable()
export class ChatService {
  private readonly provider: AiProvider;

  constructor(
    private readonly mockProvider: MockAiProvider,
    private readonly claudeProvider: ClaudeAiProvider,
    private readonly geminiProvider: GeminiAiProvider,
  ) {
    if (process.env.ANTHROPIC_API_KEY) {
      this.provider = this.claudeProvider;
    } else if (process.env.OPENROUTER_API_KEY) {
      this.provider = this.geminiProvider;
    } else {
      this.provider = this.mockProvider;
    }
  }

  async sendMessage(dto: ChatMessageDto, userId: string) {
    const mode = detectChatMode(dto.message, dto.history);
    const systemPrompt = mode === 'contract' ? CONTRACT_SYSTEM_PROMPT : FAQ_SYSTEM_PROMPT;
    const response = await this.provider.chat({
      message: dto.message,
      history: dto.history as any,
      systemPrompt,
    });
    return { reply: response.reply, provider: response.provider, mode, userId };
  }
}
