// apps/admin/src/services/adminService.ts

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ||
  process.env.NEXT_PUBLIC_API_URL ||
  'http://localhost:3001/api/v1';

async function getAdminHeaders(supabaseToken: string) {
  return {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${supabaseToken}`,
  };
}

export const adminService = {
  // 1. Fetch Users Directory
  async getUsersDirectory(supabaseToken: string, page = 1, limit = 10) {
    // ⚡ Append a dynamic timestamp tag so the browser is forced to bypass its local memory cache
    const cacheBusterUrl = `${API_BASE_URL}/admin/users?page=${page}&limit=${limit}&_t=${Date.now()}`;
    
    const response = await fetch(cacheBusterUrl, {
      method: 'GET',
      headers: await getAdminHeaders(supabaseToken),
    });
    
    if (!response.ok) {
      throw new Error('Failed to fetch the administrative user directory.');
    }
    return response.json();
  },

  // 2. Fetch Pending KYC Submissions Queue
  async getPendingKycQueue(supabaseToken: string) {
    const cacheBusterUrl = `${API_BASE_URL}/admin/kyc/pending?_t=${Date.now()}`;

    const response = await fetch(cacheBusterUrl, {
      method: 'GET',
      headers: await getAdminHeaders(supabaseToken),
    });

    if (!response.ok) {
      throw new Error('Failed to load pending KYC validation queues.');
    }
    return response.json();
  },

  // 3. Approve or Reject a KYC Submission
  async reviewKycSubmission(supabaseToken: string, submissionId: string, status: 'APPROVED' | 'REJECTED', reason?: string) {
    const response = await fetch(`${API_BASE_URL}/admin/kyc/${submissionId}/review`, {
      method: 'PATCH',
      headers: await getAdminHeaders(supabaseToken),
      body: JSON.stringify({ status, reason }),
    });

    if (!response.ok) {
      throw new Error('Failed to submit administrative verification decision.');
    }
    return response.json();
  },

  // 4. Override User Trust Metric Parameter Overrides
  async overrideTrustMetrics(supabaseToken: string, profileId: string, payload: { successfulDeals: number; ongoingDeals: number; breachedDeals: number; reason: string }) {
    const response = await fetch(`${API_BASE_URL}/admin/users/${profileId}/trust-override`, {
      method: 'POST',
      headers: await getAdminHeaders(supabaseToken),
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      throw new Error('Failed to process trust parameter metrics override.');
    }
    return response.json();
  }
};
