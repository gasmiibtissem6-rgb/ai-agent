// src/app/admin/users/page.tsx
'use client';

import React, { useEffect, useState } from 'react';
import { adminService } from '@/services/adminService';

interface UserProfileRow {
  id: string;
  displayName: string | null;
  email: string;
  kycStatus: 'NOT_STARTED' | 'SUBMITTED' | 'UNDER_REVIEW' | 'APPROVED' | 'REJECTED' | 'RESUBMISSION_REQUIRED';
  isAdmin: boolean;
  adminRole: string | null;
  createdAt: string;
  trustCounter: {
    successfulDeals: number;
    ongoingDeals: number;
    breachedDeals: number;
  } | null;
}

export default function UsersDirectoryPage() {
  const [users, setUsers] = useState<UserProfileRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  // Modal tracking state
  const [selectedUser, setSelectedUser] = useState<UserProfileRow | null>(null);
  const [successCount, setSuccessCount] = useState(0);
  const [ongoingCount, setOngoingCount] = useState(0);
  const [breachCount, setBreachCount] = useState(0);
  const [reason, setReason] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const loadDirectoryData = async () => {
  try {
    setLoading(true);
    const responsePayload = await adminService.getUsersDirectory(1, 10);
    
    // 🔍 Trace logs to verify structure parsing visually
    console.log("Raw Payload Checked:", responsePayload);

    // 1. Check if the backend wraps responses in a global 'data' interceptor envelope
    const targetData = responsePayload?.data ? responsePayload.data : responsePayload;

    // 2. Safe Extraction matching your exact runtime log output
    if (targetData && Array.isArray(targetData.users)) {
      setUsers(targetData.users);
    } else if (Array.isArray(targetData)) {
      setUsers(targetData);
    } else {
      console.error("Unexpected backend payload format structure:", responsePayload);
      setUsers([]);
    }
  } catch (err: any) {
    setError(err.message || 'An error occurred loading users.');
  } finally {
    setLoading(false);
  }
};

  useEffect(() => {
    loadDirectoryData();
  }, []);

  const openOverrideModal = (user: UserProfileRow) => {
    setSelectedUser(user);
    setSuccessCount(user.trustCounter?.successfulDeals || 0);
    setOngoingCount(user.trustCounter?.ongoingDeals || 0);
    setBreachCount(user.trustCounter?.breachedDeals || 0);
    setReason('');
  };

  const handleOverrideSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedUser) return;
    if (!reason.trim()) {
      alert("An audit justification reason is strictly required by the backend module configuration.");
      return;
    }

    try {
      setSubmitting(true);
      await adminService.overrideTrustMetrics(selectedUser.id, {
        successfulDeals: successCount,
        ongoingDeals: ongoingCount,
        breachedDeals: breachCount,
        reason: reason
      });
      
      setSelectedUser(null);
      await loadDirectoryData(); // Refresh list to view real-time changes
    } catch (err: any) {
      alert(err.message || "Failed to alter metric overrides.");
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return <div className="p-6 text-center">Loading administrative user directory...</div>;
  if (error) return <div className="p-6 text-red-500 text-center">Error: {error}</div>;

  return (
    <div className="rounded-sm border border-stroke bg-white px-5 pt-6 pb-2.5 shadow-default dark:border-strokedark dark:bg-boxdark sm:px-7.5 xl:pb-1">
      <div className="max-w-full overflow-x-auto">
        <table className="w-full table-auto">
          <thead>
            <tr className="bg-gray-2 text-left dark:bg-meta-4">
              <th className="min-w-[220px] py-4 px-4 font-medium text-black dark:text-white xl:pl-11">User Profile</th>
              <th className="min-w-[150px] py-4 px-4 font-medium text-black dark:text-white">Security Access</th>
              <th className="min-w-[120px] py-4 px-4 font-medium text-black dark:text-white">KYC Status</th>
              <th className="min-w-[150px] py-4 px-4 font-medium text-black dark:text-white">Trust Matrix Index</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.id} className="border-b border-[#eee] dark:border-strokedark">
                <td className="py-5 px-4 pl-9 xl:pl-11">
                  <h5 className="font-medium text-black dark:text-white">{user.displayName || 'Anonymous User'}</h5>
                  <p className="text-sm text-gray-500">{user.email}</p>
                </td>
                <td className="py-5 px-4">
                  {user.isAdmin ? (
                    <span className="inline-flex rounded-full bg-red-100 py-1 px-3 text-sm font-medium text-red-800">
                      {user.adminRole || 'ADMIN'}
                    </span>
                  ) : (
                    <span className="text-sm text-black dark:text-white">Standard Member</span>
                  )}
                </td>
                <td className="py-5 px-4">
                  <p className="inline-flex rounded-full py-1 px-3 text-sm font-medium bg-blue-100 text-blue-800">
                    {user.kycStatus}
                  </p>
                </td>
                <td className="py-5 px-4 text-sm">
                  <div className="flex space-x-3">
                    <span className="text-green-600">✓ {user.trustCounter?.successfulDeals || 0}</span>
                    <span className="text-blue-500">⟳ {user.trustCounter?.ongoingDeals || 0}</span>
                    <span className="text-red-500">⚠ {user.trustCounter?.breachedDeals || 0}</span>
                  </div>
                </td>
                <td className="py-5 px-4">
                  <button 
                    onClick={() => openOverrideModal(user)}
                    className="hover:text-primary text-sm font-medium border border-gray-300 rounded py-1 px-3 dark:border-strokedark"
                  >
                    Adjust Metrics
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Trust Metrics Override Modal popup view context */}
      {selectedUser && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-sm border border-stroke bg-white p-6 shadow-default dark:border-strokedark dark:bg-boxdark">
            <h3 className="mb-4 text-xl font-bold text-black dark:text-white">Override System Trust Parameters</h3>
            <p className="text-sm text-gray-500 mb-4">Target Account: {selectedUser.email}</p>
            
            <form onSubmit={handleOverrideSubmit} className="space-y-4">
              <div>
                <label className="mb-1.5 block text-sm font-medium text-black dark:text-white">Successful Deals Count</label>
                <input type="number" value={successCount} onChange={(e) => setSuccessCount(parseInt(e.target.value) || 0)} className="w-full rounded border-[1.5px] border-stroke bg-transparent py-2 px-3 text-black outline-none focus:border-primary dark:border-form-strokedark dark:bg-form-input dark:text-white" />
              </div>
              <div>
                <label className="mb-1.5 block text-sm font-medium text-black dark:text-white">Breached Deals Count</label>
                <input type="number" value={breachCount} onChange={(e) => setBreachCount(parseInt(e.target.value) || 0)} className="w-full rounded border-[1.5px] border-stroke bg-transparent py-2 px-3 text-black outline-none focus:border-primary dark:border-form-strokedark dark:bg-form-input dark:text-white" />
              </div>
              <div>
                <label className="mb-1.5 block text-sm font-medium text-black dark:text-white">Audit Trail Justification Reason</label>
                <textarea required rows={3} value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Type the explicit reason for changing system metrics..." className="w-full rounded border-[1.5px] border-stroke bg-transparent py-2 px-3 text-black outline-none focus:border-primary dark:border-form-strokedark dark:bg-form-input dark:text-white" />
              </div>

              <div className="flex justify-end space-x-3 pt-2">
                <button type="button" onClick={() => setSelectedUser(null)} className="rounded border border-stroke py-2 px-6 font-medium text-black hover:shadow-1 dark:border-strokedark dark:text-white">Cancel</button>
                <button type="submit" disabled={submitting} className="flex justify-center rounded bg-primary py-2 px-6 font-medium text-white hover:bg-opacity-95">{submitting ? 'Saving changes...' : 'Save Adjustments'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}