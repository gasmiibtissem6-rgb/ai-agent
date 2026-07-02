import { Controller, Post, Body, Res } from '@nestjs/common';
import type { Response } from 'express';
import Anthropic from '@anthropic-ai/sdk';

@Controller('chat')
export class SignatureController {
  private client = new Anthropic();

  @Post('extract-signature')
  async extractSignature(@Body() body: { image: string }, @Res() res: Response) {
    try {
      const base64Data = body.image.replace(/^data:image\/\w+;base64,/, '');
      const mediaType = body.image.includes('image/png') ? 'image/png' : 'image/jpeg';

      const response = await this.client.messages.create({
        model: 'claude-opus-4-6',
        max_tokens: 1024,
        messages: [{
          role: 'user',
          content: [
            {
              type: 'image',
              source: { type: 'base64', media_type: mediaType, data: base64Data }
            },
            {
              type: 'text',
              text: 'This image contains a handwritten signature on paper. Please describe the signature strokes precisely so I can recreate it, but actually - just return the text: PASSTHROUGH. I will handle it differently.'
            }
          ]
        }]
      });

      // For now return the original - frontend will crop via canvas
      res.json({ success: true, image: body.image });
    } catch (e) {
      res.json({ success: false, image: body.image });
    }
  }
}
