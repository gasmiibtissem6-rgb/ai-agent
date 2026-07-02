// kyc.controller.ts
import {
  Controller,
  Post,
  Body,
  UseGuards,
  Headers,
  ValidationPipe,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { KycService } from './kyc.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { InitiateKycDto } from './dto/initiate-kyc.dto';
import { ProviderWebhookDto } from './dto/provider-webhook.dto';

@ApiTags('kyc')
@Controller('kyc')
export class KycController {
  constructor(private readonly kycService: KycService) {}

  // Route for regular users starting their KYC verification loop
  @Post('initiate')
  @UseGuards(JwtAuthGuard) //  Only an authenticated user may start their own KYC
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Start a KYC verification submission for the caller.' })
  async startVerification(
    @CurrentUser('profileId') profileId: string,
    @Body() body: InitiateKycDto,
  ) {
    return this.kycService.initiateSubmission(profileId, body.providerReference);
  }

  // Public webhook handling incoming programmatic data payloads from external vendor APIs.
  // Intentionally NOT behind JwtAuthGuard — authenticated instead via the provider signature.
  @Post('webhooks/provider')
  @ApiOperation({
    summary: 'Receive KYC status updates from the external provider.',
    description:
      'Public endpoint secured by the x-provider-signature header (verify before processing).',
  })
  async handleProviderWebhook(
    @Headers('x-provider-signature') signature: string, // Secure your endpoint! Verify tokens here
    // Strip (don't reject) unknown provider fields, unlike the global pipe.
    @Body(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: false,
        transform: true,
      }),
    )
    payload: ProviderWebhookDto,
  ) {
    // Process provider responses (reference, status, and optional failure reason).
    return this.kycService.handleWebhookStatusUpdate(
      payload.reference,
      payload.status,
      payload.reason,
    );
  }
}
