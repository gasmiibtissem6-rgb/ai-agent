import {
  Controller,
  Get,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  BadRequestException,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { DealsService } from './deals.service';
import { DealStatus } from '@prisma/client';

@Controller('admin/deals')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('SUPER_ADMIN', 'ADMIN') // Ensure administrative access restrictions
export class DealsController {
  constructor(private readonly dealsService: DealsService) {}

  // 1. Fetch all system deals with pagination and multi-status filtering
  @Get()
  async getAllDeals(
    @Query('status') status?: DealStatus,
    @Query('search') search?: string,
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '10',
  ) {
    return this.dealsService.getGlobalDealsDashboard({
      status,
      search,
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
    });
  }

  // 2. Fetch specific deal details alongside metadata metrics for sub-views
  @Get(':id')
  async getDealDetails(@Param('id') id: string) {
    return this.dealsService.getAdminDealById(id);
  }

  // 3. Force-override state adjustment if a deal gets stuck in legal deadlock
  @Patch(':id/override-status')
  async forceOverrideStatus(
    @Param('id') id: string,
    @Body('status') status: DealStatus,
    @Body('reason') reason: string,
  ) {
    if (!status)
      throw new BadRequestException('Target status override state missing.');
    if (!reason?.trim())
      throw new BadRequestException(
        'An audit justification reason is required.',
      );

    return this.dealsService.overrideDealStatus(id, status, reason);
  }
}
