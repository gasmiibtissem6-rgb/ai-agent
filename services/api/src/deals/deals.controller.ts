import { Controller, Get } from '@nestjs/common';
import type { FoundationModuleSummary } from '../common/foundation.types';
import { lifecycleStatuses } from '../common/foundation.types';

@Controller('deals')
export class DealsController {
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
          purpose: 'Create a draft deal.',
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
