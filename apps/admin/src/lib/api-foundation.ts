import { getApiBaseUrl } from './api-base';

export const apiBasePath = getApiBaseUrl(process.env.NEXT_PUBLIC_API_BASE_URL);

export const configurationStatusUrl = `${apiBasePath}/configuration/status`;

export const apiUrl = (endpoint: string) =>
  `${apiBasePath}${endpoint.startsWith('/') ? endpoint : `/${endpoint}`}`;

export type ConfigurationCheck = {
  name: string;
  status: 'configured' | 'missing' | 'pending';
  detail: string;
};

export type ConfigurationStatus = {
  projectName: 'IDEAL';
  serviceName: 'api';
  apiVersion: 'v1';
  environment: string;
  status: 'operational' | 'configuration_pending';
  checkedAt: string;
  message: string;
  checks: ConfigurationCheck[];
  employeeGuidance: string[];
};

export type AdminArea = {
  title: string;
  endpoint: string;
  responsibility: string;
};

export type ApiProbe = {
  label: string;
  endpoint: string;
  description: string;
};

export const apiProbes: ApiProbe[] = [
  {
    label: 'Health',
    endpoint: '/health',
    description: 'Confirms that the NestJS API process is running.',
  },
  {
    label: 'Configuration',
    endpoint: '/configuration/status',
    description: 'Confirms environment and integration readiness reporting.',
  },
  {
    label: 'Deals',
    endpoint: '/deals/foundation',
    description: 'Confirms the deal lifecycle API boundary is registered.',
  },
  {
    label: 'Approvals',
    endpoint: '/approvals/foundation',
    description: 'Confirms approval workflow endpoints are reachable.',
  },
  {
    label: 'Files',
    endpoint: '/files/foundation',
    description: 'Confirms file access endpoints are routed through the API.',
  },
  {
    label: 'Versions',
    endpoint: '/deal-versions/foundation',
    description: 'Confirms deal version workflow endpoints are reachable.',
  },
  {
    label: 'Admin',
    endpoint: '/admin/foundation',
    description: 'Confirms admin API boundaries are reachable.',
  },
];

export const adminApiAreas: AdminArea[] = [
  {
    title: 'KYC queue',
    endpoint: '/admin/foundation',
    responsibility: 'Review identity submissions through audited backend APIs.',
  },
  {
    title: 'Deal monitoring',
    endpoint: '/deals/foundation',
    responsibility: 'Observe deal lifecycle state without bypassing API rules.',
  },
  {
    title: 'File access',
    endpoint: '/files/foundation',
    responsibility: 'Request signed URLs only through backend authorization.',
  },
  {
    title: 'Audit logs',
    endpoint: '/admin/audit-logs',
    responsibility: 'Inspect sensitive platform actions and admin decisions.',
  },
];
