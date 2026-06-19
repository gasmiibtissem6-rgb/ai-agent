export type FoundationStatus = 'planned' | 'ready-for-implementation';

export type FoundationEndpoint = {
  method: 'GET' | 'POST' | 'PATCH' | 'DELETE';
  path: string;
  purpose: string;
  authenticated: boolean;
  auditRequired: boolean;
};

export type FoundationModuleSummary = {
  area: string;
  status: FoundationStatus;
  owner: 'api' | 'admin' | 'mobile' | 'database' | 'integration';
  responsibilities: string[];
  plannedEndpoints: FoundationEndpoint[];
};

export const lifecycleStatuses = [
  'draft',
  'negotiation',
  'pending_approval',
  'approved',
  'locked',
  'changes_requested',
  'rejected',
  'cancelled',
  'archived',
] as const;

export type DealLifecycleStatus = (typeof lifecycleStatuses)[number];
