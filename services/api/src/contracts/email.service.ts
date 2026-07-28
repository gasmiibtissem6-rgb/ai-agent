import { Injectable, Logger } from '@nestjs/common';
import { Resend } from 'resend';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private readonly resend: Resend | null;

  constructor() {
    const apiKey = process.env.RESEND_API_KEY;

    if (apiKey) {
      this.resend = new Resend(apiKey);
    } else {
      this.resend = null;

      this.logger.warn(
        'RESEND_API_KEY absente : envoi d’e-mails désactivé.',
      );
    }
  }

  async sendEmail(
    to: string,
    subject: string,
    html: string,
  ) {
    if (!this.resend) {
      return {
        success: false,
        skipped: true,
        message:
          'Envoi d’e-mails désactivé : RESEND_API_KEY absente.',
      };
    }

    return this.resend.emails.send({
      from: 'IDEAL <onboarding@resend.dev>',
      to,
      subject,
      html,
    });
  }

  async sendContractEmail(
    to: string,
    subject: string,
    html: string,
  ) {
    return this.sendEmail(
      to,
      subject,
      html,
    );
  }
}
