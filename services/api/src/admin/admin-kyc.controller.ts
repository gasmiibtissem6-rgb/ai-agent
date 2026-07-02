// admin-kyc.controller.ts
import {
  Body,
  Controller,
  Get,
  Headers,
  Ip,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { AdminRole } from '@prisma/client';
import { AdminKycService, AuditContext } from './admin-kyc.service';
import { KycQueueQueryDto } from './dto/kyc-queue-query.dto';
import { KycReasonDto } from './dto/kyc-reason.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

/** Reviewer roles allowed to read and decide on KYC submissions. */
const REVIEW_ROLES = [
  AdminRole.SUPER_ADMIN,
  AdminRole.ADMIN,
  AdminRole.SUPPORT_REVIEWER,
] as const;

@ApiTags('admin-kyc')
@ApiBearerAuth()
@Controller('admin/kyc')
// Every route requires a valid token AND an administrator role. Normal users and
// FINANCE_REVIEWER are rejected by RolesGuard.
@UseGuards(JwtAuthGuard, RolesGuard)
export class AdminKycController {
  constructor(private readonly adminKycService: AdminKycService) {}

  @Get()
  @Roles(...REVIEW_ROLES)
  @ApiOperation({ summary: 'List KYC submissions (paginated, optional status filter).' })
  @ApiResponse({ status: 200, description: 'Paginated KYC queue.' })
  async getQueue(@Query() query: KycQueueQueryDto) {
    return this.adminKycService.getQueue(query);
  }

  @Get(':id')
  @Roles(...REVIEW_ROLES)
  @ApiOperation({
    summary: 'Get full submission detail with temporary signed document URLs and audit history.',
  })
  @ApiResponse({ status: 200, description: 'Submission detail.' })
  @ApiResponse({ status: 404, description: 'Submission not found.' })
  async getById(@Param('id', ParseUUIDPipe) id: string) {
    return this.adminKycService.getById(id);
  }

  @Patch(':id/approve')
  @Roles(...REVIEW_ROLES)
  @ApiOperation({ summary: 'Approve a KYC submission.' })
  @ApiResponse({ status: 200, description: 'Submission approved.' })
  async approve(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser('profileId') reviewerId: string,
    @Ip() ipAddress: string,
    @Headers('user-agent') userAgent: string,
  ) {
    return this.adminKycService.approve(id, reviewerId, this.audit(ipAddress, userAgent));
  }

  @Patch(':id/reject')
  @Roles(...REVIEW_ROLES)
  @ApiOperation({ summary: 'Reject a KYC submission (reason required).' })
  @ApiResponse({ status: 200, description: 'Submission rejected.' })
  async reject(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: KycReasonDto,
    @CurrentUser('profileId') reviewerId: string,
    @Ip() ipAddress: string,
    @Headers('user-agent') userAgent: string,
  ) {
    return this.adminKycService.reject(
      id,
      reviewerId,
      body.reason,
      this.audit(ipAddress, userAgent),
    );
  }

  @Patch(':id/request-resubmission')
  @Roles(...REVIEW_ROLES)
  @ApiOperation({ summary: 'Request that the applicant resubmit (reason required).' })
  @ApiResponse({ status: 200, description: 'Resubmission requested.' })
  async requestResubmission(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: KycReasonDto,
    @CurrentUser('profileId') reviewerId: string,
    @Ip() ipAddress: string,
    @Headers('user-agent') userAgent: string,
  ) {
    return this.adminKycService.requestResubmission(
      id,
      reviewerId,
      body.reason,
      this.audit(ipAddress, userAgent),
    );
  }

  @Patch(':id/revoke')
  @Roles(...REVIEW_ROLES)
  @ApiOperation({ summary: 'Revoke an approved KYC verification (reason required).' })
  @ApiResponse({ status: 200, description: 'Verification revoked.' })
  @ApiResponse({ status: 400, description: 'Submission is not currently approved.' })
  async revoke(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: KycReasonDto,
    @CurrentUser('profileId') reviewerId: string,
    @Ip() ipAddress: string,
    @Headers('user-agent') userAgent: string,
  ) {
    return this.adminKycService.revoke(
      id,
      reviewerId,
      body.reason,
      this.audit(ipAddress, userAgent),
    );
  }

  @Post(':id/recheck')
  // Elevated action: SUPPORT_REVIEWER is intentionally excluded.
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.ADMIN)
  @ApiOperation({ summary: 'Send a submission back under review (reason required).' })
  @ApiResponse({ status: 201, description: 'Submission moved to UNDER_REVIEW.' })
  async recheck(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: KycReasonDto,
    @CurrentUser('profileId') reviewerId: string,
    @Ip() ipAddress: string,
    @Headers('user-agent') userAgent: string,
  ) {
    return this.adminKycService.recheck(
      id,
      reviewerId,
      body.reason,
      this.audit(ipAddress, userAgent),
    );
  }

  private audit(ipAddress?: string, userAgent?: string): AuditContext {
    return { ipAddress, userAgent };
  }
}
