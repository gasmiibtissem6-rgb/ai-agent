// kyc.controller.ts
import { Controller, Post, Body, Req, UseGuards, Headers, BadRequestException } from '@nestjs/common';
import { KycService } from './kyc.service';
// Import your custom JwtAuthGuard or strategy here

@Controller('kyc')
export class KycController {
  constructor(private readonly kycService: KycService) {}

  // Route for regular users starting their KYC verification loop
  @Post('initiate')
  // @UseGuards(JwtAuthGuard) <- Protect this route so only authenticated users can trigger it
  async startVerification(
    @Req() req: any, 
    @Body() body: { providerReference?: string }
  ) {
    const profileId = req.user.id; // Adjust based on your passport setup
    return this.kycService.initiateSubmission(profileId, body.providerReference);
  }

  // Public webhook handling incoming programmatic data payloads from external vendor APIs
  @Post('webhooks/provider')
  async handleProviderWebhook(
    @Headers('x-provider-signature') signature: string, // Secure your endpoint! Verify tokens here
    @Body() payload: any
  ) {
    if (!payload || !payload.reference) {
      throw new BadRequestException('Malformed webhook data packet payload.');
    }

    // Process provider responses (assuming standard webhook format: reference, status, and failures)
    return this.kycService.handleWebhookStatusUpdate(
      payload.reference,
      payload.status,
      payload.reason
    );
  }
}