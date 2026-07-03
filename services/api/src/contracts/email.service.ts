import { Injectable, Logger } from '@nestjs/common';
import { Resend } from 'resend';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private readonly resend: Resend;

  constructor() {
    this.resend = new Resend(process.env.RESEND_API_KEY);
  }

  async sendContractEmail(
    toEmail: string,
    contractTitle: string,
    contractId: string,
  ) {
    try {
      const result = await this.resend.emails.send({
        from: 'onboarding@resend.dev',
        to: toEmail,
        subject: `Contrat à consulter : ${contractTitle}`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto;">
            <h2>IDEAL - Nouveau contrat</h2>
            <p>Bonjour,</p>
            <p>Un contrat intitulé <strong>${contractTitle}</strong> vous a été envoyé pour consultation et signature.</p>
            <p>
              <a href="http://localhost:63993/#/contracts/${contractId}"
                 style="background:#2563eb;color:white;padding:10px 20px;text-decoration:none;border-radius:6px;">
                Consulter le contrat
              </a>
            </p>
            <p>Cordialement,<br/>L'équipe IDEAL</p>
          </div>
        `,
      });
      this.logger.log(`Email envoyé à ${toEmail}: ${JSON.stringify(result)}`);
      return result;
    } catch (error) {
      this.logger.error(`Erreur envoi email à ${toEmail}`, error);
      throw error;
    }
  }
}
