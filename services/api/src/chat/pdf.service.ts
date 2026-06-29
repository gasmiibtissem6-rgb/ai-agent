import { Injectable } from '@nestjs/common';
import PDFDocument = require('pdfkit');

@Injectable()
export class PdfService {
  generateContractPdf(content: string, title: string = 'Contrat', signatureImage?: string): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ margin: 50 });
      const chunks: Buffer[] = [];

      doc.on('data', (chunk: Buffer) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      doc.fontSize(20).font('Helvetica-Bold').text(title, { align: 'center' });
      doc.moveDown();
      doc.moveTo(50, doc.y).lineTo(550, doc.y).stroke();
      doc.moveDown();
      doc.fontSize(10).font('Helvetica').text(`Generated: ${new Date().toLocaleDateString()}`, { align: 'right' });
      doc.moveDown();

      const clean = content
        .replace(/\*\*(.*?)\*\*/g, '$1')
        .replace(/\*(.*?)\*/g, '$1')
        .replace(/#{1,6}\s/g, '')
        .replace(/---/g, '')
        .replace(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/gu, '')
        .trim();

      doc.fontSize(12).font('Helvetica').text(clean, { lineGap: 4 });

      if (signatureImage) {
        try {
          const base64Data = signatureImage.replace(/^data:image\/\w+;base64,/, '');
          const buffer = Buffer.from(base64Data, 'base64');

          if (doc.y > 650) doc.addPage();
          doc.moveDown(2);
          doc.fontSize(11).font('Helvetica-Bold').text('Signature :', { continued: false });
          doc.moveDown(0.5);
          doc.image(buffer, { width: 200, height: 100, fit: [200, 100] });
        } catch (err) {
          doc.fontSize(10).fillColor('red').text('(Erreur: signature non lisible)');
        }
      }

      doc.end();
    });
  }
}
