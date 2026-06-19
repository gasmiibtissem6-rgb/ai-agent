import { Controller, Get } from '@nestjs/common';
import type { FoundationModuleSummary } from '../common/foundation.types';

@Controller('files')
export class FilesController {
  @Get('foundation')
  getFoundation(): FoundationModuleSummary {
    return {
      area: 'files',
      status: 'ready-for-implementation',
      owner: 'api',
      responsibilities: [
        'Keep all deal and KYC files private by default.',
        'Issue signed upload and download URLs only after authorization checks.',
        'Persist file metadata and write audit events for uploads and access.',
      ],
      plannedEndpoints: [
        {
          method: 'POST',
          path: '/api/v1/files/signed-upload-url',
          purpose: 'Create an authorized signed upload URL.',
          authenticated: true,
          auditRequired: true,
        },
        {
          method: 'GET',
          path: '/api/v1/files/:fileId/signed-download-url',
          purpose: 'Create an authorized signed download URL.',
          authenticated: true,
          auditRequired: true,
        },
      ],
    };
  }
}
