// admin.controller.ts
import { Controller, Get, Post, Patch, Body, Param, Query, UseGuards, Req } from '@nestjs/common';
import { AdminService } from './admin.service';
import { ValidationPipe } from '@nestjs/common';
import { OverrideTrustDto } from './dto/override-trust.dto';
// Import your custom decorators & guards here (e.g., JwtAuthGuard, AdminGuard, Roles)

@Controller('admin')
// @UseGuards(JwtAuthGuard, AdminGuard) <- Apply your security gatekeepers here
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  // 1. Fetch Users Directory (with basic pagination parameters)
  @Get('users')
  // @Roles(AdminRole.SUPER_ADMIN, AdminRole.ADMIN)
  async getUsersDirectory(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const p = page ? parseInt(page, 10) : 1;
    const l = limit ? parseInt(limit, 10) : 10;
    return this.adminService.getUsersDirectory(p, l);
  }

  // 2. Fetch Identity Verification Queue
  @Get('kyc/pending')
  // @Roles(AdminRole.SUPER_ADMIN, AdminRole.ADMIN, AdminRole.SUPPORT_REVIEWER)
  async getKycQueue() {
    return this.adminService.getPendingKycQueue();
  }

  // 3. Process KYC Approvals / Rejections
  @Patch('kyc/:submissionId/review')
  // @Roles(AdminRole.SUPER_ADMIN, AdminRole.ADMIN, AdminRole.SUPPORT_REVIEWER)
  async reviewKyc(
    @Param('submissionId') submissionId: string,
    @Body() body: { status: 'APPROVED' | 'REJECTED'; reason?: string },
    @Req() req: any, // Extract active admin profile from user token
  ) {
    const adminId = req.user.id; // Adjust based on where your passport/jwt guard populates profile data
    return this.adminService.reviewKycSubmission(submissionId, adminId, body.status, body.reason);
  }

 @Post('users/:profileId/trust-override')
async overrideTrust(
  @Param('profileId') profileId: string,
  @Body(new ValidationPipe({ whitelist: true })) body: OverrideTrustDto, // 👈 Automatic payload scanning
  @Req() req: any,
) {
  const adminId = req.user.id;
  const { reason, ...metrics } = body;
  return this.adminService.overrideTrustCounters(profileId, adminId, metrics, reason);
}
  
}