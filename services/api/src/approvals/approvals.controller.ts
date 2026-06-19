import { Controller, Get } from '@nestjs/common';
import type { FoundationModuleSummary } from '../common/foundation.types';

@Controller('approvals')
export class ApprovalsController {
  @Get('foundation')
  getFoundation(): FoundationModuleSummary {
    return {
      area: 'approvals',
      status: 'ready-for-implementation',
      owner: 'api',
      responsibilities: [
        'Enforce that each required party approves only for themselves.',
        'Lock the official version only after all required parties approve the same version.',
        'Record rejection and change-request reasons.',
      ],
      plannedEndpoints: [
        {
          method: 'POST',
          path: '/api/v1/deal-versions/:versionId/approve',
          purpose: 'Approve a submitted version for the authenticated party.',
          authenticated: true,
          auditRequired: true,
        },
        {
          method: 'POST',
          path: '/api/v1/deal-versions/:versionId/reject',
          purpose: 'Reject a submitted version.',
          authenticated: true,
          auditRequired: true,
        },
        {
          method: 'POST',
          path: '/api/v1/deal-versions/:versionId/request-changes',
          purpose: 'Request changes before approval.',
          authenticated: true,
          auditRequired: true,
        },
      ],
    };
  }
}
