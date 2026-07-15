import { Injectable } from '@nestjs/common';
import {
  AiProvider,
  AiChatRequest,
  AiChatResponse,
} from './ai-provider.interface';

const MODELS = [
  'gemini-2.0-flash-lite',
  'gemini-1.5-flash-8b',
  'gemini-2.0-flash',
];

@Injectable()
export class ClaudeAiProvider implements AiProvider {
  async chat(request: AiChatRequest): Promise<AiChatResponse> {
    for (const model of MODELS) {
      try {
        const response = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${process.env.GEMINI_API_KEY}`,
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              system_instruction: { parts: [{ text: request.systemPrompt }] },
              contents: [
                ...(request.history ?? []).map((m: any) => ({
                  role: m.role === 'assistant' ? 'model' : 'user',
                  parts: [{ text: m.content }],
                })),
                {
                  role: 'user',
                  parts: [
                    { text: request.message },
                    ...(request.image
                      ? [
                          {
                            inline_data: {
                              mime_type: (request.image.match(
                                /^data:(image\/\w+);base64,/,
                              ) || [, 'image/png'])[1],
                              data: request.image.replace(
                                /^data:image\/\w+;base64,/,
                                '',
                              ),
                            },
                          },
                        ]
                      : []),
                  ],
                },
              ],
            }),
          },
        );
        const data = await response.json();
        if (data.error) {
          console.log(`[AI] ${model} failed: ${data.error.message}`);
          continue;
        }
        const reply = data.candidates?.[0]?.content?.parts?.[0]?.text;
        if (!reply) continue;
        console.log(`[AI] Success: ${model}`);
        return { reply, provider: `google:${model}` };
      } catch (err: any) {
        console.error(`[AI] ${model} error:`, err.message);
      }
    }
    return {
      reply: 'Service IA indisponible. Réessayez dans 1 minute.',
      provider: 'none',
    };
  }
}
