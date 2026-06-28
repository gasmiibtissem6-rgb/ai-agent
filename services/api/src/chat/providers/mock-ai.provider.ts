import { Injectable } from '@nestjs/common';
import { AiProvider, AiChatRequest, AiChatResponse } from './ai-provider.interface';

@Injectable()
export class MockAiProvider implements AiProvider {
  async chat(request: AiChatRequest): Promise<AiChatResponse> {
    const isArabic = /[\u0600-\u06FF]/.test(request.message);
    const isFrench = /\b(bonjour|bonsoir|salut|merci|comment|je|tu|nous|contrat|aide|veux|pour|avec|est)\b/i.test(request.message);
    let reply: string;
    if (isArabic) reply = `مرحباً! كيف يمكنني مساعدتك اليوم؟`;
    else if (isFrench) reply = `Bonjour ! Comment puis-je vous aider aujourd'hui ?`;
    else reply = `Hello! How can I help you today?`;
    return { reply, provider: 'mock' };
  }
}
