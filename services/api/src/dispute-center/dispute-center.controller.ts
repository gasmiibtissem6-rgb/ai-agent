import { Controller, Get, Post, Patch, Body, Param, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { DisputeCenterService } from './dispute-center.service';
import { ReportStatus } from '@prisma/client';

@Controller('admin/dispute-center')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('SUPER_ADMIN', 'ADMIN')
export class DisputeCenterController {
  constructor(private readonly disputeCenterService: DisputeCenterService) {}

  /**
   * Fetch all dispute tickets with filtering and pagination
   */
  @Get()
  async getDisputeTickets(
    @Query('status') status?: ReportStatus,
    @Query('resourceType') resourceType?: string,
    @Query('search') search?: string,
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '10'
  ) {
    return this.disputeCenterService.getDisputeTickets({
      status,
      resourceType,
      search,
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
    });
  }

  /**
   * Fetch specific dispute ticket details
   */
  @Get(':id')
  async getDisputeTicketById(@Param('id') id: string) {
    return this.disputeCenterService.getDisputeTicketById(id);
  }

  /**
   * Update dispute ticket status and resolution
   */
  @Patch(':id/resolve')
  async updateDisputeTicket(
    @Param('id') id: string,
    @CurrentUser('profileId') adminProfileId: string,
    @Body('status') status: ReportStatus,
    @Body('resolution') resolution?: string
  ) {
    if (!status) throw new Error('Status is required');
    
    return this.disputeCenterService.updateDisputeTicket(id, adminProfileId, { status, resolution });
  }

  /**
   * Pause deal progression for disputed contracts
   */
  @Post('deal/:dealId/pause')
  async pauseDealForDispute(
    @Param('dealId') dealId: string,
    @CurrentUser('profileId') adminProfileId: string,
    @Body('reason') reason: string
  ) {
    if (!reason?.trim()) throw new Error('Reason is required');
    
    return this.disputeCenterService.pauseDealForDispute(dealId, adminProfileId, reason);
  }

  /**
   * Suspend user account due to fraud reports
   */
  @Post('profile/:profileId/suspend')
  async suspendProfileForFraud(
    @Param('profileId') profileId: string,
    @CurrentUser('profileId') adminProfileId: string,
    @Body('reason') reason: string
  ) {
    if (!reason?.trim()) throw new Error('Reason is required');
    
    return this.disputeCenterService.suspendProfileForFraud(profileId, adminProfileId, reason);
  }
}

/**
 * Public endpoint for users to create dispute tickets
 */
@Controller('dispute-center')
@UseGuards(JwtAuthGuard)
export class DisputeCenterUserController {
  constructor(private readonly disputeCenterService: DisputeCenterService) {}

  @Post()
  async createDisputeTicket(
    @CurrentUser('profileId') reporterProfileId: string,
    @Body() data: { resourceType: string; resourceId: string; reason: string }
  ) {
    if (!data.resourceType || !data.resourceId || !data.reason?.trim()) {
      throw new Error('resourceType, resourceId, and reason are required');
    }
    
    return this.disputeCenterService.createDisputeTicket({
      reporterProfileId,
      resourceType: data.resourceType,
      resourceId: data.resourceId,
      reason: data.reason,
    });
  }
}
