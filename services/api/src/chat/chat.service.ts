import { Injectable } from '@nestjs/common';
import { MockAiProvider } from './providers/mock-ai.provider';
import { ClaudeAiProvider } from './providers/claude-ai.provider';
import { GeminiAiProvider } from './providers/gemini-ai.provider';
import { AiProvider } from './providers/ai-provider.interface';
import {
  detectChatMode,
  FAQ_SYSTEM_PROMPT,
  CONTRACT_SYSTEM_PROMPT,
  ANALYZE_SYSTEM_PROMPT,
} from './chat.types';

@Injectable()
export class ChatService {
  private provider: AiProvider;

  constructor(
    private readonly mockProvider: MockAiProvider,
    private readonly claudeProvider: ClaudeAiProvider,
    private readonly geminiProvider: GeminiAiProvider,
  ) {
    this.provider = this.claudeProvider;
  }

  async sendMessage(dto: {
    message: string;
    history?: any[];
    userId?: string;
    image?: string;
  }) {
    const mode = detectChatMode(dto.message, dto.history);
    const systemPrompt =
      mode === 'contract'
        ? CONTRACT_SYSTEM_PROMPT
        : mode === 'analyze'
          ? ANALYZE_SYSTEM_PROMPT
          : FAQ_SYSTEM_PROMPT;
    const result = await this.provider.chat({
      message: dto.message,
      history: dto.history ?? [],
      systemPrompt,
      image: dto.image,
    });
    return { ...result, mode, userId: dto.userId ?? 'test-user' };
  }
}
