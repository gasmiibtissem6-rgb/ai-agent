// kyc.controller.ts
import {
  Body,
  Controller,
  Get,
  Headers,
  Ip,
  Post,
  UseGuards,
  ValidationPipe,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { KycService, AuditContext } from './kyc.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { InitiateKycDto } from './dto/initiate-kyc.dto';
import { ProviderWebhookDto } from './dto/provider-webhook.dto';
import { AuthorizeUploadDto } from './dto/authorize-upload.dto';
import { SubmitKycDto } from './dto/submit-kyc.dto';
import { ResubmitKycDto } from './dto/resubmit-kyc.dto';

@ApiTags('kyc')
@Controller('kyc')
export class KycController {
  constructor(private readonly kycService: KycService) {}

  // --- Document upload authorization -----------------------------------------

  @Post('storage/authorize')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Authorize a single KYC document upload and return a signed upload URL.',
  })
  @ApiResponse({ status: 201, description: 'Signed upload URL issued.' })
  async authorizeUpload(
    @CurrentUser('profileId') profileId: string,
    @Body() body: AuthorizeUploadDto,
  ) {
    return this.kycService.authorizeUpload(profileId, body);
  }

  // --- User submission flow --------------------------------------------------

  @Post('submit')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Submit KYC documents for review (own profile only).' })
  @ApiResponse({ status: 201, description: 'Submission created.' })
  @ApiResponse({ status: 409, description: 'A submission is already under review.' })
  async submit(
    @CurrentUser('profileId') profileId: string,
    @Body() body: SubmitKycDto,
    @Ip() ipAddress: string,
    @Headers('user-agent') userAgent: string,
  ) {
    return this.kycService.submit(profileId, body, this.audit(ipAddress, userAgent));
  }

  @Get('me/status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get the current KYC status of the caller.' })
  @ApiResponse({ status: 200, description: 'Current KYC status returned.' })
  async myStatus(@CurrentUser('profileId') profileId: string) {
    return this.kycService.getMyStatus(profileId);
  }

  @Post('me/resubmit')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Resubmit KYC documents after a rejection or resubmission request.',
  })
  @ApiResponse({ status: 201, description: 'Submission updated and re-queued.' })
  @ApiResponse({ status: 400, description: 'Current status does not allow resubmission.' })
  async resubmit(
    @CurrentUser('profileId') profileId: string,
    @Body() body: ResubmitKycDto,
    @Ip() ipAddress: string,
    @Headers('user-agent') userAgent: string,
  ) {
    return this.kycService.resubmit(profileId, body, this.audit(ipAddress, userAgent));
  }

  // --- Legacy manual + external-provider flow (unchanged) --------------------

  @Post('initiate')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Start a KYC verification submission for the caller.' })
  async startVerification(
    @CurrentUser('profileId') profileId: string,
    @Body() body: InitiateKycDto,
  ) {
    return this.kycService.initiateSubmission(profileId, body.providerReference);
  }

  @Post('webhooks/provider')
  @ApiOperation({
    summary: 'Receive KYC status updates from the external provider.',
    description:
      'Public endpoint secured by the x-provider-signature header (verify before processing).',
  })
  async handleProviderWebhook(
    @Headers('x-provider-signature') signature: string,
    @Body(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: false,
        transform: true,
      }),
    )
    payload: ProviderWebhookDto,
  ) {
    return this.kycService.handleWebhookStatusUpdate(
      payload.reference,
      payload.status,
      payload.reason,
    );
  }

  private audit(ipAddress?: string, userAgent?: string): AuditContext {
    return { ipAddress, userAgent };
  }
}
