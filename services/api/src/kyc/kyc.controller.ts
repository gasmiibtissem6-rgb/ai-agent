<<<<<<< HEAD
// kyc.controller.ts
import {
  Controller,
  Post,
  Body,
  UseGuards,
  Headers,
  ValidationPipe,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
=======
import { Controller, Get, Patch, Body, Param, UseGuards, Req, BadRequestException } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard'; // Adjust path to match your file structure
import { RolesGuard } from '../auth/guards/roles.guard';       // Adjust path to match your file structure
import { Roles } from '../auth/decorators/roles.decorator';       // Adjust to match your existing decorator file
>>>>>>> 8f5ce2b850dbacc959ab0a4bdd5aebbb96355f60
import { KycService } from './kyc.service';
import { KycStatus } from '@prisma/client';

@Controller('admin/kyc')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('SUPER_ADMIN', 'ADMIN') // Match your application's admin roles
export class KycController {
  constructor(private readonly kycService: KycService) {}

<<<<<<< HEAD
  // Route for regular users starting their KYC verification loop
  @Post('initiate')
  @UseGuards(JwtAuthGuard) //  Only an authenticated user may start their own KYC
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Start a KYC verification submission for the caller.',
  })
  async startVerification(
    @CurrentUser('profileId') profileId: string,
    @Body() body: InitiateKycDto,
  ) {
    return this.kycService.initiateSubmission(
      profileId,
      body.providerReference,
    );
=======
  // 1. Fetch all pending queues to match your Next.js Table view
  @Get('pending')
  async getPendingQueue() {
    return this.kycService.getPendingSubmissions();
>>>>>>> 8f5ce2b850dbacc959ab0a4bdd5aebbb96355f60
  }

  // 2. Process action route (Approve or Reject)
  @Patch(':id/review')
  async reviewSubmission(
    @Param('id') id: string,
    @Req() req: any, // Extract active admin context
    @Body() dto: { status: KycStatus; rejectionReason?: string }
  ) {
    const adminProfileId = req.user.profileId; // Target the active admin's profile ID

    if (dto.status === KycStatus.REJECTED && !dto.rejectionReason?.trim()) {
      throw new BadRequestException('A clear rejection reason must be provided.');
    }

    if (dto.status !== KycStatus.APPROVED && dto.status !== KycStatus.REJECTED) {
      throw new BadRequestException('Invalid target review status.');
    }

    return this.kycService.processReview(id, adminProfileId, dto.status, dto.rejectionReason);
  }
}