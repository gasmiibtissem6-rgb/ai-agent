import { Controller, Post, Body, Res } from '@nestjs/common';
import { PdfService } from './pdf.service';

@Controller('chat')
export class PdfController {
  constructor(private readonly pdfService: PdfService) {}

  @Post('generate-pdf')
  async generatePdf(
    @Body() body: {
      content: string;
      title?: string;
      signatureImage?: string;
      mediaItems?: Array<{ type: 'image' | 'video'; data: string; caption?: string; date?: string; thumbnail?: string }>;
    },
    @Res() res: any,
  ) {
    const pdf = await this.pdfService.generateContractPdf(
      body.content,
      body.title ?? 'Contrat',
      body.signatureImage,
      body.mediaItems,
    );
    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': 'attachment; filename="contrat.pdf"',
      'Content-Length': pdf.length,
    });
    res.end(pdf);
  }
}
