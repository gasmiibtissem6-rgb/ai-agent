import { Injectable } from '@nestjs/common';
import PDFDocument = require('pdfkit');

interface MediaItem {
  type: 'image' | 'video';
  data: string; // base64
  caption?: string;
  date?: string;
  thumbnail?: string; // base64 thumbnail pour les vidéos
}

@Injectable()
export class PdfService {
  generateContractPdf(
    content: string,
    title: string = 'Contrat',
    signatureImage?: string,
    mediaItems?: MediaItem[],
  ): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ margin: 50, size: 'A4' });
      const chunks: Buffer[] = [];
      doc.on('data', (chunk: Buffer) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      // ── Entête ──
      doc.fontSize(20).font('Helvetica-Bold').text(title, { align: 'center' });
      doc.moveDown(0.5);
      doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke();
      doc.moveDown(0.5);
      doc
        .fontSize(9)
        .font('Helvetica')
        .fillColor('#888888')
        .text(`Généré le ${new Date().toLocaleDateString('fr-FR')}`, {
          align: 'right',
        });
      doc.fillColor('#000000').moveDown();

      // ── Contenu texte ──
      const clean = content
        .replace(/\*\*(.*?)\*\*/g, '$1')
        .replace(/\*(.*?)\*/g, '$1')
        .replace(/#{1,6}\s/g, '')
        .replace(/---/g, '')
        .replace(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/gu, '')
        .trim();
      doc.fontSize(11).font('Helvetica').text(clean, { lineGap: 5 });

      // ── Photos et vidéos ──
      if (mediaItems && mediaItems.length > 0) {
        doc.addPage();
        doc
          .fontSize(16)
          .font('Helvetica-Bold')
          .text('Pièces jointes', { align: 'center' });
        doc.moveDown();
        doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke();
        doc.moveDown();

        let col = 0;
        const imgW = 220;
        const imgH = 160;
        const colGap = 25;
        const startX = 50;

        for (const item of mediaItems) {
          const x = startX + col * (imgW + colGap);
          const y = doc.y;

          if (y + imgH + 40 > 780) {
            doc.addPage();
            col = 0;
          }

          try {
            const rawData = (item.thumbnail || item.data).replace(
              /^data:image\/\w+;base64,/,
              '',
            );
            const buffer = Buffer.from(rawData, 'base64');
            doc.image(buffer, x, doc.y, {
              width: imgW,
              height: imgH,
              fit: [imgW, imgH],
            });

            // Icône vidéo
            if (item.type === 'video') {
              doc
                .save()
                .fillColor('#000000')
                .opacity(0.45)
                .rect(x, doc.y - imgH, imgW, imgH)
                .fill()
                .restore();
              doc
                .fontSize(28)
                .fillColor('white')
                .text('▶', x + imgW / 2 - 14, doc.y - imgH / 2 - 20);
              doc.fillColor('#000000');
            }

            doc.moveDown(0.3);
            const currentY = doc.y;

            // Légende
            if (item.caption) {
              doc
                .fontSize(9)
                .font('Helvetica-Bold')
                .fillColor('#333333')
                .text(item.caption, x, currentY, { width: imgW });
            }
            if (item.date) {
              doc
                .fontSize(8)
                .font('Helvetica')
                .fillColor('#888888')
                .text(item.date, x, doc.y, { width: imgW });
            }
            doc.fillColor('#000000');

            if (col === 0) {
              col = 1;
            } else {
              col = 0;
              doc.moveDown(imgH / 72 + 1.5);
            }
          } catch (e) {
            col = 0;
          }
        }
      }

      // ── Signature ──
      if (signatureImage) {
        try {
          if (doc.y > 650) doc.addPage();
          doc.moveDown(2);
          doc
            .fontSize(11)
            .font('Helvetica-Bold')
            .text('Signature :', { continued: false });
          doc.moveDown(0.5);
          const sigData = signatureImage.replace(
            /^data:image\/\w+;base64,/,
            '',
          );
          doc.image(Buffer.from(sigData, 'base64'), {
            width: 180,
            height: 80,
            fit: [180, 80],
          });
        } catch (e) {}
      }

      doc.end();
    });
  }
}
