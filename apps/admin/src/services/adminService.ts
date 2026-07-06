// apps/admin/src/services/adminService.ts
import { getApiBaseUrl } from '../lib/api-base';

const API_BASE_URL = getApiBaseUrl(
  process.env.NEXT_PUBLIC_API_BASE_URL ?? process.env.NEXT_PUBLIC_API_URL,
);

function getStoredAdminToken(): string {
  if (typeof window === 'undefined') {
    throw new Error('Admin session is unavailable in server context.');
  }

  const token = localStorage.getItem('admin_token');
  if (!token || token === 'undefined' || token === 'null') {
    throw new Error('Authentication required. Please sign in again.');
  }

  return token;
}

async function getAdminHeaders() {
  const token = getStoredAdminToken();
  return {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
  };
}

async function parseApiError(response: Response, fallbackMessage: string) {
  const data = await response.json().catch(() => ({}));
  const message =
    (typeof data?.message === 'string' && data.message) || fallbackMessage;
  throw new Error(`${message} (HTTP ${response.status})`);
}

export const adminService = {
  // 1. Fetch Users Directory
  async getUsersDirectory(page = 1, limit = 10) {
    const usersDirectoryUrl = `${API_BASE_URL}/admin/users?page=${page}&limit=${limit}`;
    
    const response = await fetch(usersDirectoryUrl, {
      method: 'GET',
      headers: await getAdminHeaders(),
      cache: 'no-store',
    });
    
    if (!response.ok) {
      await parseApiError(
        response,
        'Failed to fetch the administrative user directory.',
      );
    }
    return response.json();
  },

  // 2. Fetch Pending KYC Submissions Queue
  async getPendingKycQueue() {
    const kycQueueUrl = `${API_BASE_URL}/admin/kyc/pending`;

    const response = await fetch(kycQueueUrl, {
      method: 'GET',
      headers: await getAdminHeaders(),
      cache: 'no-store',
    });

    if (!response.ok) {
      await parseApiError(response, 'Failed to load pending KYC validation queues.');
    }
    return response.json();
  },

  // 3. Approve or Reject a KYC Submission
  async reviewKycSubmission(submissionId: string, status: 'APPROVED' | 'REJECTED', reason?: string) {
    const response = await fetch(`${API_BASE_URL}/admin/kyc/${submissionId}/review`, {
      method: 'PATCH',
      headers: await getAdminHeaders(),
      body: JSON.stringify({ status, reason }),
    });

    if (!response.ok) {
      await parseApiError(
        response,
        'Failed to submit administrative verification decision.',
      );
    }
    return response.json();
  },

  // 4. Override User Trust Metric Parameter Overrides
  async overrideTrustMetrics(profileId: string, payload: { successfulDeals: number; ongoingDeals: number; breachedDeals: number; reason: string }) {
    const response = await fetch(`${API_BASE_URL}/admin/users/${profileId}/trust-override`, {
      method: 'POST',
      headers: await getAdminHeaders(),
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      await parseApiError(
        response,
        'Failed to process trust parameter metrics override.',
      );
    }
    return response.json();
  }
};
