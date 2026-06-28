import { Injectable } from '@nestjs/common';
import { AiProvider, AiChatRequest, AiChatResponse } from './ai-provider.interface';

@Injectable()
export class GeminiAiProvider implements AiProvider {
  async chat(request: AiChatRequest): Promise<AiChatResponse> {
    try {
      const response = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'x-api-key': process.env.ANTHROPIC_API_KEY ?? '',
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'claude-haiku-4-5',
          max_tokens: 2048,
          system: request.systemPrompt,
          messages: [
            ...(request.history ?? []),
            { role: 'user', content: request.message },
          ],
        }),
      });

      const data = await response.json();
      const reply = data.content?.[0]?.text;
      if (!reply) throw new Error(JSON.stringify(data));
      console.log('[AI] Success: claude-haiku-4-5');
      return { reply, provider: 'anthropic:claude-haiku-4-5' };
    } catch (err: any) {
      console.error('[AI] Anthropic error:', err.message);
      return { reply: 'Service IA indisponible. Réessayez dans un moment.', provider: 'none' };
    }
  }
}
