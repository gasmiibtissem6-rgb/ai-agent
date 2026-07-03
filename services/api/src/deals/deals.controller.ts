// services/api/src/deals/deals.controller.ts
import { Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { KycVerifiedGuard } from '../common/guards/kyc-verified.guard'; // 👈 Import the KYC guard
import { DealsService } from './deals.service';
import type { FoundationModuleSummary } from '../common/foundation.types';
import { lifecycleStatuses } from '../common/foundation.types';

@ApiTags('deals')
@Controller('deals')
export class DealsController {
  constructor(private readonly dealsService: DealsService) {}

  /**
   * Production Endpoint: Fetch authenticated user's deals
   * Route: GET /deals
   * Permissive: Accessible by any logged-in user so they can track historical info or incoming invites.
   */
  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async getMyDeals(@CurrentUser('sub') sub: string) {
    return this.dealsService.getDealsByUserId(sub);
  }

  /**
   * Planned Production Endpoint Example: Create a draft deal
   * Route: POST /deals
   * Restrictive: Enforces sequential gates: Is logged in? -> Is identity approved?
   */
  @Post()
  @UseGuards(JwtAuthGuard, KycVerifiedGuard) // 🔒 Stacking gates blocks unauthorized creation natively
  @ApiBearerAuth()
  async createDraftDeal() {
    // Business logic intentionally left as-is (planned endpoint).
    // return this.dealsService.createDeal(user.sub, body);
  }

  /**
   * Boilerplate Foundation Info Route
   * Route: GET /deals/foundation
   */
  @Get('foundation')
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
      plannedEndpoints: [
        {
          method: 'POST',
          path: '/api/v1/deals',
          purpose:
            'Create a draft deal. Requires full KYC validation confirmation.',
          authenticated: true,
          auditRequired: true,
        },
        {
          method: 'GET',
          path: '/api/v1/deals',
          purpose: 'List deals where the user is creator or participant.',
          authenticated: true,
          auditRequired: false,
        },
        {
          method: 'GET',
          path: '/api/v1/deals/:dealId',
          purpose: 'Read one authorized deal with current version and parties.',
          authenticated: true,
          auditRequired: false,
        },
      ],
      lifecycleStatuses,
    };
  }
}
