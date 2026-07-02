// admin.controller.ts
import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AdminRole } from '@prisma/client';
import { AdminService } from './admin.service';
import { OverrideTrustDto } from './dto/override-trust.dto';
import { PaginationQueryDto } from './dto/pagination-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin')
// 🔒 Every admin route requires a valid token AND administrator privileges.
// KYC review routes now live in AdminKycController (@Controller('admin/kyc')).
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

  // 2. Override trust metrics (high-privilege action)
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
