import { Controller, Post, Body } from '@nestjs/common';
import { createWorker } from 'tesseract.js';

@Controller('chat')
export class OcrController {
  @Post('scan-contract')
  async scanContract(@Body() body: { image: string; lang?: string }) {
    try {
      const base64Data = body.image.replace(/^data:image\/\w+;base64,/, '');
      const buffer = Buffer.from(base64Data, 'base64');

      const worker = await createWorker('fra+eng');
      const { data } = await worker.recognize(buffer);
      await worker.terminate();

      const text = data.text.trim();
      if (!text) return { success: false, text: '', message: 'Aucun texte détecté' };

      return { success: true, text, confidence: data.confidence };
    } catch (err: any) {
      console.error('[OCR] Error:', err.message);
      return { success: false, text: '', message: err.message };
    }
  }
}
