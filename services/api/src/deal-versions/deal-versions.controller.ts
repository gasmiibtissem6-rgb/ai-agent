import { Controller, Get } from '@nestjs/common';
import type { FoundationModuleSummary } from '../common/foundation.types';

@Controller('deal-versions')
export class DealVersionsController {
  @Get('foundation')
  getFoundation(): FoundationModuleSummary {
    return {
      area: 'deal-versions',
      status: 'ready-for-implementation',
      owner: 'api',
      responsibilities: [
        'Create new versions when draft terms change after approval.',
        'Prevent edits to locked versions.',
        'Track the current active version for each deal.',
      ],
      plannedEndpoints: [
        {
          method: 'POST',
          path: '/api/v1/deals/:dealId/versions',
          purpose: 'Create a new deal version.',
          authenticated: true,
          auditRequired: true,
        },
        {
          method: 'POST',
          path: '/api/v1/deal-versions/:versionId/submit',
          purpose: 'Submit a version for required-party approval.',
          authenticated: true,
          auditRequired: true,
        },
      ],
    };
  }
}
