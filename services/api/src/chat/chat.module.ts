import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';

import { ChatController } from './chat.controller';
import { ChatService } from './chat.service';
import { MockAiProvider } from './providers/mock-ai.provider';
import { ClaudeAiProvider } from './providers/claude-ai.provider';
import { GeminiAiProvider } from './providers/gemini-ai.provider';
import { PdfService } from './pdf.service';
import { PdfController } from './pdf.controller';
import { OcrController } from './ocr.controller';

@Module({
  imports: [
    HttpModule.register({
      timeout: 120000,
      maxRedirects: 3,
    }),
  ],

  controllers: [
    ChatController,
    PdfController,
    OcrController,
  ],

  providers: [
    ChatService,
    MockAiProvider,
    ClaudeAiProvider,
    GeminiAiProvider,
    PdfService,
  ],
})
export class ChatModule {}
