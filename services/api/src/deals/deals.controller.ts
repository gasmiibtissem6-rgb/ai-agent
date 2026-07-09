// services/api/src/deals/deals.controller.ts
import {
  BadRequestException,
  Body,
  Controller,
  Delete,
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
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { KycVerifiedGuard } from '../common/guards/kyc-verified.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Public } from '../auth/decorators/public.decorator';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { DealStatus } from '@prisma/client';
import type { FoundationModuleSummary } from '../common/foundation.types';
import { lifecycleStatuses } from '../common/foundation.types';
import { AuditContext, DealsService } from './deals.service';
import { CreateDealDto } from './dto/create-deal.dto';
import { UpdateDealDto } from './dto/update-deal.dto';
import { UpdateDealStatusDto } from './dto/update-deal-status.dto';
import { ListDealsQueryDto } from './dto/list-deals-query.dto';
import { CreateDealVersionDto } from './dto/create-deal-version.dto';
import { ShareDealDto } from './dto/share-deal.dto';

@ApiTags('deals')
@Controller('deals')
export class DealsController {
  constructor(private readonly dealsService: DealsService) {}

  // --- Deal CRUD -------------------------------------------------------------

  @Post()
  @UseGuards(JwtAuthGuard, KycVerifiedGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Create a draft deal with its initial version (KYC approved only).',
  })
  @ApiResponse({ status: 201, description: 'Deal and first version created.' })
  @ApiResponse({
    status: 403,
    description: 'KYC not approved, or deal quota reached.',
  })
  async createDeal(
    @CurrentUser('profileId') profileId: string,
    @Body() body: CreateDealDto,
    @Ip() ipAddress: string,
    @Headers('user-agent') userAgent: string,
  ) {
    return this.dealsService.createDeal(
      profileId,
      body,
      this.audit(ipAddress, userAgent),
    );
  }

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'List deals where the caller is creator or participant.',
  })
  @ApiResponse({ status: 200, description: 'Paginated deals returned.' })
  async listDeals(
    @CurrentUser('profileId') profileId: string,
    @Query() query: ListDealsQueryDto,
  ) {
    return this.dealsService.listDeals(profileId, query);
  }

  @Get('foundation')
  @ApiOperation({ summary: 'Deals module capability summary (boilerplate).' })
  getFoundation(): FoundationModuleSummary & {
    lifecycleStatuses: readonly string[];
  } {
    return {
      area: 'deals',
      status: 'ready-for-implementation',
      owner: 'api',
      responsibilities: [
        'Own deal creation, status transitions, and participant access checks.',
        'Ensure locked approved versions are immutable.',
        'Coordinate versions, approvals, files, notifications, trust, and audit events.',
      ],
      plannedEndpoints: [],
      lifecycleStatuses,
    };
  }

  // --- Invitation links (public view + authenticated accept) -----------------

  @Get('invite/:token')
  @Public()
  @ApiOperation({
    summary: 'View public metadata for an invitation link (no auth).',
  })
  @ApiResponse({ status: 200, description: 'Invitation metadata returned.' })
  @ApiResponse({
    status: 403,
    description: 'Link expired, revoked, or exhausted.',
  })
  async getInvite(@Param('token') token: string) {
    return this.dealsService.getInviteByToken(token);
  }

  @Post('invite/:token/accept')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Accept an invitation and join the deal as a participant.',
  })
  @ApiResponse({
    status: 201,
    description: 'Caller added as participant; deal returned.',
  })
  @ApiResponse({
    status: 403,
    description: 'Link expired, revoked, or exhausted.',
  })
  async acceptInvite(
    @CurrentUser('profileId') profileId: string,
    @CurrentUser('email') email: string,
    @Param('token') token: string,
    @Ip() ipAddress: string,
    @Headers('user-agent') userAgent: string,
  ) {
    return this.dealsService.acceptInvite(
      profileId,
      email,
      token,
      this.audit(ipAddress, userAgent),
    );
  }

  // --- Sharing management (creator only) -------------------------------------

  @Post(':id/share')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Generate a secure invitation link / QR payload (creator only).',
  })
  @ApiResponse({ status: 201, description: 'Invitation link created.' })
  async shareDeal(
    @CurrentUser('profileId') profileId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: ShareDealDto,
    @Ip() ipAddress: string,
    @Headers('user-agent') userAgent: string,
  ) {
    return this.dealsService.createShareLink(
      profileId,
      id,
      body,
      this.audit(ipAddress, userAgent),
    );
  }

  @Get(':id/shares')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List invitation links for a deal (creator only).' })
  @ApiResponse({
    status: 200,
    description: 'Invitation links returned (tokens masked).',
  })
  async listShares(
    @CurrentUser('profileId') profileId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.dealsService.listShareLinks(profileId, id);
  }

  @Delete(':id/share/:token')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Revoke an invitation link (creator only).' })
  @ApiResponse({ status: 200, description: 'Invitation link revoked.' })
  async revokeShare(
    @CurrentUser('profileId') profileId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('token') token: string,
    @Ip() ipAddress: string,
    @Headers('user-agent') userAgent: string,
  ) {
    return this.dealsService.revokeShareLink(
      profileId,
      id,
      token,
      this.audit(ipAddress, userAgent),
    );
  }

  // --- Versions --------------------------------------------------------------

  @Post(':id/versions')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Create a new deal version (creator only, not approved/locked).',
  })
  @ApiResponse({ status: 201, description: 'New version created.' })
  @ApiResponse({
    status: 403,
    description: 'Not the creator, or deal is approved/locked.',
  })
  async createVersion(
    @CurrentUser('profileId') profileId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: CreateDealVersionDto,
    @Ip() ipAddress: string,
    @Headers('user-agent') userAgent: string,
  ) {
    return this.dealsService.createVersion(
      profileId,
      id,
      body,
      this.audit(ipAddress, userAgent),
    );
  }

  // --- Single deal read/update/delete ----------------------------------------

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Get full deal detail (creator or participant only).',
  })
  @ApiResponse({ status: 200, description: 'Deal detail returned.' })
  @ApiResponse({
    status: 403,
    description: 'Caller has no relation to this deal.',
  })
  async getDeal(
    @CurrentUser('profileId') profileId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.dealsService.getDealById(profileId, id);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update a DRAFT deal (creator only).' })
  @ApiResponse({ status: 200, description: 'Deal updated.' })
  @ApiResponse({
    status: 403,
    description: 'Not the creator, or deal is not DRAFT.',
  })
  async updateDeal(
    @CurrentUser('profileId') profileId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: UpdateDealDto,
    @Ip() ipAddress: string,
    @Headers('user-agent') userAgent: string,
  ) {
    return this.dealsService.updateDeal(
      profileId,
      id,
      body,
      this.audit(ipAddress, userAgent),
    );
  }

  @Patch(':id/status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Set the deal status to APPROVED, NEGOTIATION ("Bridged") or CANCELLED (creator only).',
  })
  @ApiResponse({ status: 200, description: 'Deal status updated.' })
  @ApiResponse({
    status: 403,
    description: 'Not the creator, or the deal is LOCKED/ARCHIVED.',
  })
  async updateDealStatus(
    @CurrentUser('profileId') profileId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: UpdateDealStatusDto,
    @Ip() ipAddress: string,
    @Headers('user-agent') userAgent: string,
  ) {
    return this.dealsService.updateDealStatus(
      profileId,
      id,
      body,
      this.audit(ipAddress, userAgent),
    );
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Delete a DRAFT deal with no confirmed parties (creator only).',
  })
  @ApiResponse({ status: 200, description: 'Deal deleted.' })
  @ApiResponse({
    status: 403,
    description: 'Not the creator, not DRAFT, or has confirmed parties.',
  })
  async deleteDeal(
    @CurrentUser('profileId') profileId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Ip() ipAddress: string,
    @Headers('user-agent') userAgent: string,
  ) {
    return this.dealsService.deleteDeal(
      profileId,
      id,
      this.audit(ipAddress, userAgent),
    );
  }

  private audit(ipAddress?: string, userAgent?: string): AuditContext {
    return { ipAddress, userAgent };
  }
}
@ApiTags('admin-deals')
@Controller('admin/deals')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('SUPER_ADMIN', 'ADMIN')
export class DealsAdminController {
  constructor(private readonly dealsService: DealsService) {}

  // Global deals table (pagination + status/search filter).
  @Get()
  async getAllDeals(
    @Query('status') status?: DealStatus,
    @Query('search') search?: string,
    @Query('page') page = '1',
    @Query('limit') limit = '10',
  ) {
    return this.dealsService.getGlobalDealsDashboard({
      status,
      search,
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
    });
  }

  // Deep deal detail for the admin inspector.
  @Get(':id')
  async getDealDetails(@Param('id') id: string) {
    return this.dealsService.getAdminDealById(id);
  }

  // Force-override a stuck deal's status (audited).
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
