// admin.controller.ts
/*
 * TODO FOR OUSSEMA
 * This controller has been restored to its pre-KYC-session state. It keeps the
 * basic KYC review routes you owned before:
 *   - GET   /admin/kyc/pending
 *   - PATCH /admin/kyc/:submissionId/review   (body: ReviewKycDto)
 *
 * The KYC session had removed these from here and replaced them with a richer,
 * dedicated surface. That richer surface is NOT wired anymore. If you want it,
 * implement it in admin-kyc.controller.ts (see the placeholder there):
 *   - GET   /admin/kyc                         (paginated queue + status filter)
 *   - GET   /admin/kyc/:id                     (detail + signed document URLs + audit)
 *   - PATCH /admin/kyc/:id/approve
 *   - PATCH /admin/kyc/:id/reject
 *   - PATCH /admin/kyc/:id/request-resubmission
 *   - PATCH /admin/kyc/:id/revoke              (APPROVED only)
 *   - POST  /admin/kyc/:id/recheck            (SUPER_ADMIN, ADMIN only)
 * Then register AdminKycController in admin.module.ts.
 */
import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AdminRole } from '@prisma/client';
import { AdminService } from './admin.service';
import { OverrideTrustDto } from './dto/override-trust.dto';
import { ReviewKycDto } from './dto/review-kyc.dto';
import { PaginationQueryDto } from './dto/pagination-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin')
// 🔒 Every admin route requires a valid token AND administrator privileges.
@UseGuards(JwtAuthGuard, RolesGuard)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  // 1. Fetch Users Directory (with basic pagination parameters)
  @Get('users')
  @Roles() // any authenticated admin
  @ApiOperation({ summary: 'List user profiles (paginated).' })
  async getUsersDirectory(@Query() query: PaginationQueryDto) {
    return this.adminService.getUsersDirectory(query.page, query.limit);
  }

  // 2. Fetch Identity Verification Queue
  @Get('kyc/pending')
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.ADMIN, AdminRole.SUPPORT_REVIEWER)
  @ApiOperation({ summary: 'List pending KYC submissions for review.' })
  async getKycQueue() {
    return this.adminService.getPendingKycQueue();
  }

  // 3. Process KYC Approvals / Rejections
  @Patch('kyc/:submissionId/review')
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.ADMIN, AdminRole.SUPPORT_REVIEWER)
  @ApiOperation({ summary: 'Approve or reject a KYC submission.' })
  async reviewKyc(
    @Param('submissionId') submissionId: string,
    @Body() body: ReviewKycDto,
    @CurrentUser('profileId') adminId: string,
  ) {
    return this.adminService.reviewKycSubmission(
      submissionId,
      adminId,
      body.status,
      body.reason,
    );
  }

  // 4. Override trust metrics (high-privilege action)
  @Post('users/:profileId/trust-override')
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.ADMIN)
  @ApiOperation({ summary: 'Override a user trust counter (audited).' })
  async overrideTrust(
    @Param('profileId') profileId: string,
    @Body() body: OverrideTrustDto,
    @CurrentUser('profileId') adminId: string,
  ) {
    const { reason, ...metrics } = body;
    return this.adminService.overrideTrustCounters(
      profileId,
      adminId,
      metrics,
      reason,
    );
  }
}
