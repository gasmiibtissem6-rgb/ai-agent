import { Injectable } from '@nestjs/common';
import * as path from 'path';
import * as fs from 'fs';
import PDFDocument = require('pdfkit');

interface MediaItem {
  type: 'image' | 'video';
  data: string;
  caption?: string;
  date?: string;
  thumbnail?: string;
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
      const doc = new PDFDocument({
        margin: 50,
        size: 'A4',
      });

      const chunks: Buffer[] = [];

      doc.on('data', (chunk: Buffer) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      // ─────────────────────────────────────────────
      // En-tête
      // ─────────────────────────────────────────────

      doc
        .fontSize(20)
        .font('Helvetica-Bold')
        .text(title, {
          align: 'center',
        });

      doc.moveDown(0.5);

      doc
        .moveTo(50, doc.y)
        .lineTo(545, doc.y)
        .stroke();

      doc.moveDown(0.5);

      doc
        .fontSize(9)
        .font('Helvetica')
        .fillColor('#888888')
        .text(
          `Généré le ${new Date().toLocaleDateString('fr-FR')}`,
          {
            align: 'right',
          },
        );

      doc.fillColor('#000000');
      doc.moveDown();

      // ─────────────────────────────────────────────
      // Police arabe
      // ─────────────────────────────────────────────

      const arabicFontPath = path.join(
        process.cwd(),
        'src',
        'chat',
        'fonts',
        'NotoNaskhArabic-Regular.ttf',
      );

      let arabicAvailable = false;

      try {
        if (fs.existsSync(arabicFontPath)) {
          doc.registerFont('Arabic', arabicFontPath);
          arabicAvailable = true;
          console.log('✅ Police arabe chargée');
        } else {
          console.warn(
            '⚠️ Police arabe introuvable :',
            arabicFontPath,
          );
        }
      } catch (error) {
        console.error(
          'Erreur pendant le chargement de la police arabe :',
          error,
        );
      }

      const isArabicLine = (text: string): boolean =>
        /[\u0600-\u06FF]/.test(text);

      const getRegularFont = (isArabic: boolean): string => {
        if (isArabic && arabicAvailable) {
          return 'Arabic';
        }

        return 'Helvetica';
      };

      const getBoldFont = (isArabic: boolean): string => {
        if (isArabic && arabicAvailable) {
          return 'Arabic';
        }

        return 'Helvetica-Bold';
      };

      // ─────────────────────────────────────────────
      // Contenu du contrat
      // ─────────────────────────────────────────────

      const lines = content.split('\n');

      for (const rawLine of lines) {
        const line = rawLine
          .replace(/\*\*(.*?)\*\*/g, '$1')
          .replace(/\*(.*?)\*/g, '$1')
          .replace(
            /[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/gu,
            '',
          )
          .trimEnd();

        // Ligne vide
        if (line.trim() === '') {
          doc.moveDown(0.4);
          continue;
        }

        // Séparateur horizontal
        if (line.trim() === '---') {
          doc.moveDown(0.3);

          doc
            .moveTo(50, doc.y)
            .lineTo(545, doc.y)
            .strokeColor('#cccccc')
            .stroke();

          doc
            .strokeColor('#000000')
            .moveDown(0.5);

          continue;
        }

        // Titres Markdown
        const headerMatch = line.match(/^#{1,6}\s+(.*)/);

        if (headerMatch) {
          const headerText = headerMatch[1].trim();
          const rtl = isArabicLine(headerText);

          doc.moveDown(0.7);

          doc
            .fontSize(13)
            .font(getBoldFont(rtl))
            .fillColor('#1a1a1a')
            .text(headerText, {
              align: rtl ? 'right' : 'left',
            });

          doc.moveDown(0.15);

          doc
            .moveTo(50, doc.y)
            .lineTo(545, doc.y)
            .strokeColor('#dddddd')
            .stroke();

          doc
            .strokeColor('#000000')
            .fillColor('#000000')
            .moveDown(0.35);

          continue;
        }

        // Listes à puces
        const bulletMatch = line.match(/^[-•]\s+(.*)/);

        if (bulletMatch) {
          const bulletText = bulletMatch[1].trim();
          const rtl = isArabicLine(bulletText);

          doc
            .font(getRegularFont(rtl))
            .fontSize(11)
            .text(
              rtl
                ? `${bulletText}  •`
                : `•  ${bulletText}`,
              {
                indent: rtl ? 0 : 10,
                lineGap: 3,
                align: rtl ? 'right' : 'left',
              },
            );

          continue;
        }

        // Texte normal
        const cleanLine = line.trim();
        const rtlLine = isArabicLine(cleanLine);

        doc
          .font(getRegularFont(rtlLine))
          .fontSize(11)
          .fillColor('#000000')
          .text(cleanLine, {
            lineGap: 4,
            align: rtlLine ? 'right' : 'left',
          });
      }

      // ─────────────────────────────────────────────
      // Photos et vidéos
      // ─────────────────────────────────────────────

      if (mediaItems && mediaItems.length > 0) {
        doc.addPage();

        doc
          .fontSize(16)
          .font('Helvetica-Bold')
          .fillColor('#000000')
          .text('Pièces jointes', {
            align: 'center',
          });

        doc.moveDown();

        doc
          .moveTo(50, doc.y)
          .lineTo(545, doc.y)
          .stroke();

        doc.moveDown();

        const imgW = 220;
        const imgH = 160;
        const colGap = 25;
        const startX = 50;
        const bottomLimit = 760;

        let column = 0;
        let rowTop = doc.y;

        for (const item of mediaItems) {
          // Nouvelle page si la prochaine ligne ne rentre pas
          if (rowTop + imgH + 80 > bottomLimit) {
            doc.addPage();
            rowTop = 50;
            column = 0;
          }

          const x =
            startX + column * (imgW + colGap);

          const boxTop = rowTop;

          try {
            const imageSource =
              item.thumbnail || item.data;

            const rawData = imageSource.replace(
              /^data:image\/[a-zA-Z0-9.+-]+;base64,/,
              '',
            );

            const buffer = Buffer.from(
              rawData,
              'base64',
            );

            // Image proportionnelle, centrée et non coupée
            doc.image(buffer, x, boxTop, {
              fit: [imgW, imgH],
              align: 'center',
              valign: 'center',
            });

            // Superposition pour les vidéos
            if (item.type === 'video') {
              doc
                .save()
                .fillColor('#000000')
                .opacity(0.45)
                .rect(x, boxTop, imgW, imgH)
                .fill()
                .restore();

              doc
                .fontSize(28)
                .font('Helvetica')
                .fillColor('#ffffff')
                .text(
                  '▶',
                  x + imgW / 2 - 14,
                  boxTop + imgH / 2 - 20,
                  {
                    lineBreak: false,
                  },
                );
            }

            doc.fillColor('#000000');

            let captionY = boxTop + imgH + 8;

            // Légende
            if (item.caption) {
              doc
                .fontSize(9)
                .font('Helvetica-Bold')
                .fillColor('#333333')
                .text(
                  item.caption,
                  x,
                  captionY,
                  {
                    width: imgW,
                    align: 'left',
                  },
                );

              captionY = doc.y + 3;
            }

            // Date
            if (item.date) {
              doc
                .fontSize(8)
                .font('Helvetica')
                .fillColor('#888888')
                .text(
                  item.date,
                  x,
                  captionY,
                  {
                    width: imgW,
                    align: 'left',
                  },
                );
            }

            doc.fillColor('#000000');

            if (column === 0) {
              column = 1;
            } else {
              column = 0;
              rowTop += imgH + 70;
            }
          } catch (error) {
            console.error(
              'Erreur pendant l’ajout d’un média dans le PDF :',
              error,
            );

            if (column === 0) {
              column = 1;
            } else {
              column = 0;
              rowTop += imgH + 70;
            }
          }
        }

        // Positionner la suite sous la dernière ligne d’images
        if (column === 1) {
          rowTop += imgH + 70;
        }

        doc.y = rowTop;
      }

      // ─────────────────────────────────────────────
      // Signature
      // ─────────────────────────────────────────────

      if (signatureImage) {
        try {
          if (doc.y > 650) {
            doc.addPage();
          }

          doc.moveDown(2);

          doc
            .fontSize(11)
            .font('Helvetica-Bold')
            .fillColor('#000000')
            .text('Signature :');

          doc.moveDown(0.5);

          const signatureData =
            signatureImage.replace(
              /^data:image\/[a-zA-Z0-9.+-]+;base64,/,
              '',
            );

          const signatureBuffer = Buffer.from(
            signatureData,
            'base64',
          );

          doc.image(signatureBuffer, {
            fit: [180, 80],
            align: 'left',
            valign: 'center',
          });
        } catch (error) {
          console.error(
            'Erreur pendant l’ajout de la signature :',
            error,
          );
        }
      }

      doc.end();
    });
  }
}