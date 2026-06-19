import { Controller, Get } from '@nestjs/common';
import type { FoundationModuleSummary } from '../common/foundation.types';

@Controller('admin')
export class AdminController {
  @Get('foundation')
  getFoundation(): FoundationModuleSummary {
    return {
      area: 'admin',
      status: 'ready-for-implementation',
      owner: 'api',
      responsibilities: [
        'Expose audited internal operations for the Next.js dashboard.',
        'Enforce admin authorization through backend guards.',
        'Prevent direct admin writes that bypass API business rules.',
      ],
      plannedEndpoints: [
        {
          method: 'POST',
          path: '/api/v1/admin/kyc/:submissionId/approve',
          purpose: 'Approve a KYC submission after admin review.',
          authenticated: true,
          auditRequired: true,
        },
        {
          method: 'GET',
          path: '/api/v1/admin/audit-logs',
          purpose: 'Inspect platform audit activity.',
          authenticated: true,
          auditRequired: true,
        },
      ],
    };
  }
}
