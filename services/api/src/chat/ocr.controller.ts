import { Controller, Post, Body } from '@nestjs/common';
import Tesseract from 'tesseract.js';

@Controller('chat')
export class OcrController {
  @Post('scan-contract')
  async scanContract(@Body() body: { image: string; lang?: string }) {
    try {
      const base64Data = body.image.replace(/^data:image\/\w+;base64,/, '');
      const buffer = Buffer.from(base64Data, 'base64');
      
      const result = await Tesseract.recognize(buffer, body.lang ?? 'fra+ara+eng', {
        logger: () => {},
      });

      const text = result.data.text.trim();
      if (!text) return { success: false, text: '', message: 'Aucun texte détecté' };

      return { success: true, text, confidence: result.data.confidence };
    } catch (err: any) {
      return { success: false, text: '', message: err.message };
    }
  }
}
