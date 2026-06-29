import { Controller, Post, Body, Res } from '@nestjs/common';
import type { Response } from 'express';
import { PdfService } from './pdf.service';

@Controller('chat')
export class PdfController {
  constructor(private readonly pdfService: PdfService) {}

  @Post('generate-pdf')
  async generatePdf(@Body() body: { content: string; title?: string; signatureImage?: string }, @Res() res: Response) {
    const pdf = await this.pdfService.generateContractPdf(body.content, body.title ?? 'Contract', body.signatureImage);
    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': 'attachment; filename="contract.pdf"',
      'Content-Length': pdf.length,
    });
    res.end(pdf);
  }
}
