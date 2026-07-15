import { getApiBaseUrl } from '../lib/api-base';

const API_BASE_URL = getApiBaseUrl(
  process.env.NEXT_PUBLIC_API_BASE_URL ?? process.env.NEXT_PUBLIC_API_URL,
);

// 1. UPDATED: No longer checking localStorage. Content-Type is our only manual header.
function getAdminHeaders() {
  return {
    'Content-Type': 'application/json',
  };
}

// 2. SHARED UTILITY: Common fetch configuration for cookie forwarding
const getFetchOptions = (method: 'GET' | 'POST' | 'PATCH', body?: unknown): RequestInit => {
  const options: RequestInit = {
    method,
    headers: getAdminHeaders(),
    cache: 'no-store',
    // CRITICAL: Instructs fetch to automatically attach the secure HttpOnly session cookie 
    credentials: 'include', 
  };

  // Safe validation instead of the tricky conditional shortcut spread
  if (body !== undefined && body !== null) {
    options.body = JSON.stringify(body);
  }

  return options;
};

async function parseApiError(response: Response, fallbackMessage: string) {
  const data = await response.json().catch(() => ({}));
  const message =
    (typeof data?.message === 'string' && data.message) || fallbackMessage;
  
  // Clean fallback context handling if the browser encounters a session expiration
  if (response.status === 401 && typeof window !== 'undefined') {
    window.location.href = '/login';
  }

  throw new Error(`${message} (HTTP ${response.status})`);
}

export const adminService = {
  // 1. Fetch Users Directory
  async getUsersDirectory(page = 1, limit = 10) {
    const usersDirectoryUrl = `${API_BASE_URL}/admin/users?page=${page}&limit=${limit}`;
    
    const response = await fetch(
      usersDirectoryUrl, 
      getFetchOptions('GET')
    );
    
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

    const response = await fetch(
      kycQueueUrl, 
      getFetchOptions('GET')
    );

    if (!response.ok) {
      await parseApiError(response, 'Failed to load pending KYC validation queues.');
    }
    return response.json();
  },

  // 3. Approve or Reject a KYC Submission
  async reviewKycSubmission(submissionId: string, status: 'APPROVED' | 'REJECTED', reason?: string) {
    const response = await fetch(
      `${API_BASE_URL}/admin/kyc/${submissionId}/review`, 
      getFetchOptions('PATCH', { status, reason })
    );

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
    const response = await fetch(
      `${API_BASE_URL}/admin/users/${profileId}/trust-override`, 
      getFetchOptions('POST', payload)
    );

    if (!response.ok) {
      await parseApiError(
        response,
        'Failed to process trust parameter metrics override.',
      );
    }
    return response.json();
  }
};