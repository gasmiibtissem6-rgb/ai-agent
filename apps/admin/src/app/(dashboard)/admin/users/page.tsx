'use client';

import { AdminPageHeader } from '@/components/Layouts/admin-page-header';
import React, { useEffect, useState, useCallback, useRef } from 'react';
import { adminService } from '@/services/adminService';
import { getApiBaseUrl } from '@/lib/api-base';
import type { RealtimeChannel } from '@supabase/supabase-js';

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

interface SupabaseConfig {
  supabaseUrl?: string;
  supabaseAnonKey?: string;
}

function getErrorMessage(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback;
}

const API_BASE_URL = getApiBaseUrl(
  process.env.NEXT_PUBLIC_API_BASE_URL ?? process.env.NEXT_PUBLIC_API_URL,
);

const fetchSupabaseConfig = async (): Promise<SupabaseConfig | null> => {
  try {
    const res = await fetch(`${API_BASE_URL}/configuration/supabase`);
    if (res.ok) {
      const payload = await res.json() as { data?: SupabaseConfig } & SupabaseConfig;
      return payload?.data || payload;
    }
  } catch (err) {
    console.error('Failed to fetch Supabase config:', err);
  }
  return null;
};

export default function UsersDirectoryPage() {
  const [users, setUsers] = useState<UserProfileRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState('ALL');
  const [kycFilter, setKycFilter] = useState('ALL');

  const [page, setPage] = useState(1);
  const [limit] = useState(10);
  const [totalPages, setTotalPages] = useState(1);
  const [totalUsers, setTotalUsers] = useState(0);

  const [selectedUser, setSelectedUser] = useState<UserProfileRow | null>(null);
  const [successCount, setSuccessCount] = useState(0);
  const [ongoingCount, setOngoingCount] = useState(0);
  const [breachCount, setBreachCount] = useState(0);
  const [reason, setReason] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');
  const [modalSuccess, setModalSuccess] = useState('');

  const loadDirectoryData = useCallback(async (currentPage = page, currentLimit = limit) => {
    try {
      setLoading(true);
      const responsePayload = await adminService.getUsersDirectory(currentPage, currentLimit);
      const targetData = responsePayload?.data ? responsePayload.data : responsePayload;

      if (targetData && Array.isArray(targetData.users)) {
        setUsers(targetData.users);
        setTotalPages(targetData.totalPages || 1);
        setTotalUsers(targetData.total || 0);
      } else if (Array.isArray(targetData)) {
        setUsers(targetData);
        setTotalPages(1);
        setTotalUsers(targetData.length);
      } else {
        setUsers([]);
      }
    } catch (err: unknown) {
      setError(getErrorMessage(err, 'An error occurred loading users.'));
    } finally {
      setLoading(false);
    }
  }, [page, limit]);

  useEffect(() => {
    const timeout = window.setTimeout(() => {
      void loadDirectoryData(page, limit);
    }, 0);

    return () => window.clearTimeout(timeout);
  }, [page, limit, loadDirectoryData]);

  const loadRef = useRef(loadDirectoryData);
  const pageRef = useRef(page);
  const limitRef = useRef(limit);

  useEffect(() => {
    loadRef.current = loadDirectoryData;
    pageRef.current = page;
    limitRef.current = limit;
  }, [loadDirectoryData, page, limit]);

  useEffect(() => {
    let supabaseChannel: RealtimeChannel | null = null;

    async function initRealtime() {
      const config = await fetchSupabaseConfig();
      if (config && config.supabaseUrl && config.supabaseAnonKey) {
        try {
          const { createClient } = await import('@supabase/supabase-js');
          const supabase = createClient(config.supabaseUrl, config.supabaseAnonKey);
          supabaseChannel = supabase
            .channel('live-profiles-updates')
            .on('postgres_changes', { event: '*', schema: 'public', table: 'profiles' }, () => {
              void loadRef.current(pageRef.current, limitRef.current);
            })
            .subscribe();
        } catch (err) {
          console.error('Failed to initialize Supabase realtime:', err);
        }
      }
    }

    void initRealtime();
    return () => { if (supabaseChannel) supabaseChannel.unsubscribe(); };
  }, []);

  const openOverrideModal = (user: UserProfileRow) => {
    setSelectedUser(user);
    setSuccessCount(user.trustCounter?.successfulDeals ?? 0);
    setOngoingCount(user.trustCounter?.ongoingDeals ?? 0);
    setBreachCount(user.trustCounter?.breachedDeals ?? 0);
    setReason('');
    setModalError('');
    setModalSuccess('');
  };

  const closeModal = () => {
    if (submitting) return;
    setSelectedUser(null);
    setModalError('');
    setModalSuccess('');
  };

  const handleOverrideSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedUser) return;
    setModalError('');
    setModalSuccess('');

    if (reason.trim().length < 10) {
      setModalError('Audit reason must be at least 10 characters.');
      return;
    }

    try {
      setSubmitting(true);
      await adminService.overrideTrustMetrics(selectedUser.id, {
        successfulDeals: successCount,
        ongoingDeals: ongoingCount,
        breachedDeals: breachCount,
        reason: reason.trim(),
      });
      setModalSuccess('Trust metrics updated. Action logged to audit trail.');
      await loadDirectoryData(page, limit);
      setTimeout(() => closeModal(), 1800);
    } catch (err: unknown) {
      setModalError(getErrorMessage(err, 'Failed to update trust metrics. Please try again.'));
    } finally {
      setSubmitting(false);
    }
  };

  const getKycBadgeClass = (status: string) => {
    switch (status) {
      case 'APPROVED': return 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300';
      case 'REJECTED': return 'bg-rose-100 text-rose-800 dark:bg-rose-950 dark:text-rose-300';
      case 'UNDER_REVIEW': return 'bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300';
      case 'SUBMITTED': return 'bg-purple-100 text-purple-800 dark:bg-purple-950 dark:text-purple-300';
      default: return 'bg-blue-100 text-blue-800 dark:bg-blue-950 dark:text-blue-300';
    }
  };

  const getRoleBadgeClass = (role: string) => {
    switch (role) {
      case 'SUPER_ADMIN': return 'bg-red-100 text-red-800 dark:bg-red-950 dark:text-red-300';
      case 'ADMIN': return 'bg-orange-100 text-orange-800 dark:bg-orange-950 dark:text-orange-300';
      default: return 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300';
    }
  };

  const visibleTotal = totalUsers || users.length;
  const adminCount = users.filter((user) => user.isAdmin).length;
  const approvedKycCount = users.filter((user) => user.kycStatus === 'APPROVED').length;
  const trustEventCount = users.reduce(
    (total, user) =>
      total +
      (user.trustCounter?.successfulDeals || 0) +
      (user.trustCounter?.ongoingDeals || 0) +
      (user.trustCounter?.breachedDeals || 0),
    0,
  );
  const filteredUsers = users.filter((user) => {
    const query = searchTerm.trim().toLowerCase();
    const matchesSearch =
      !query ||
      (user.displayName || '').toLowerCase().includes(query) ||
      user.email.toLowerCase().includes(query);
    const matchesRole =
      roleFilter === 'ALL' ||
      (roleFilter === 'ADMIN' && user.isAdmin) ||
      (roleFilter === 'MEMBER' && !user.isAdmin);
    const matchesKyc = kycFilter === 'ALL' || user.kycStatus === kycFilter;

    return matchesSearch && matchesRole && matchesKyc;
  });

  return (
    <div className="space-y-7">
      <AdminPageHeader
        eyebrow="IDENTITY COMMAND"
        title="User Directory"
        description="Review platform accounts, administrative access, KYC posture, and trust counters from one controlled directory."
        panelLabel="Directory Coverage"
        panelValue={loading ? '...' : visibleTotal}
        panelNote="Known accounts"
        panelSubtext={`${approvedKycCount} approved identities visible on this page.`}
        panelBarValue={visibleTotal ? Math.min((approvedKycCount / visibleTotal) * 100, 100) : 12}
        metrics={[
          {
            label: 'Users',
            value: loading ? '...' : visibleTotal,
            note: 'Platform accounts',
            accent: 'from-slate-900 to-slate-700',
          },
          {
            label: 'Admins',
            value: loading ? '...' : adminCount,
            note: 'Privileged profiles',
            accent: 'from-blue-700 to-indigo-600',
          },
          {
            label: 'Approved KYC',
            value: loading ? '...' : approvedKycCount,
            note: 'Verified identities',
            accent: 'from-emerald-600 to-teal-500',
          },
          {
            label: 'Trust Events',
            value: loading ? '...' : trustEventCount,
            note: 'Recorded deal counters',
            accent: 'from-amber-600 to-amber-500',
          },
        ]}
        tone="emerald"
        compact
      />

      <div className="rounded-[20px] border border-stroke bg-white px-5 pb-3 pt-6 shadow-card-2 dark:border-dark-3 dark:bg-dark-2 sm:px-7.5">
      <div className="mb-6 flex flex-col gap-4 xl:flex-row xl:items-end xl:justify-between">
        <div>
        <h4 className="text-xl font-bold text-black dark:text-white">User Directory</h4>
        <p className="mt-1 text-sm font-medium text-gray-500 dark:text-dark-6">
          Administrative overview of platform users and trust metrics.
        </p>
        </div>

        <div className="grid gap-2 sm:grid-cols-2 xl:flex xl:items-center">
          <input
            type="search"
            placeholder="Search name or email"
            value={searchTerm}
            onChange={(event) => setSearchTerm(event.target.value)}
            className="rounded-xl border border-stroke bg-gray-1 px-4 py-2.5 text-sm text-black outline-none transition focus:border-primary dark:border-dark-3 dark:bg-dark dark:text-white"
          />
          <select
            value={roleFilter}
            onChange={(event) => setRoleFilter(event.target.value)}
            className="rounded-xl border border-stroke bg-gray-1 px-4 py-2.5 text-sm text-black outline-none transition focus:border-primary dark:border-dark-3 dark:bg-dark dark:text-white"
          >
            <option value="ALL">All roles</option>
            <option value="ADMIN">Admins</option>
            <option value="MEMBER">Members</option>
          </select>
          <select
            value={kycFilter}
            onChange={(event) => setKycFilter(event.target.value)}
            className="rounded-xl border border-stroke bg-gray-1 px-4 py-2.5 text-sm text-black outline-none transition focus:border-primary dark:border-dark-3 dark:bg-dark dark:text-white"
          >
            <option value="ALL">All KYC</option>
            <option value="APPROVED">Approved</option>
            <option value="UNDER_REVIEW">Under review</option>
            <option value="SUBMITTED">Submitted</option>
            <option value="REJECTED">Rejected</option>
            <option value="NOT_STARTED">Not started</option>
          </select>
          <button
            type="button"
            onClick={() => {
              setSearchTerm('');
              setRoleFilter('ALL');
              setKycFilter('ALL');
            }}
            className="rounded-xl border border-stroke px-4 py-2.5 text-sm font-semibold text-black transition hover:bg-gray-100 dark:border-dark-3 dark:text-white dark:hover:bg-dark"
          >
            Reset
          </button>
        </div>
      </div>

      {error && (
        <div className="mb-6 rounded-lg bg-rose-50 p-4 text-sm text-rose-600 dark:bg-rose-950/20 dark:text-rose-400">
          {error}
        </div>
      )}

      <div className="max-w-full overflow-x-auto">
        <table className="w-full table-auto">
          <thead>
            <tr className="bg-gray-2 text-left dark:bg-dark">
              <th className="min-w-[220px] py-4 px-4 font-medium text-black dark:text-white xl:pl-11">User Profile</th>
              <th className="min-w-[150px] py-4 px-4 font-medium text-black dark:text-white">Security Access</th>
              <th className="min-w-[120px] py-4 px-4 font-medium text-black dark:text-white">KYC Status</th>
              <th className="min-w-[150px] py-4 px-4 font-medium text-black dark:text-white">Trust Matrix Index</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading && users.length === 0 ? (
              <tr>
                <td colSpan={5} className="py-10 text-center text-gray-500 dark:text-dark-6">
                  Loading administrative user directory...
                </td>
              </tr>
            ) : filteredUsers.length === 0 ? (
              <tr>
                <td colSpan={5} className="py-10 text-center text-gray-500">
                  No users match the selected filters.
                </td>
              </tr>
            ) : (
              filteredUsers.map((user) => (
                <tr key={user.id} className="border-b border-stroke/80 dark:border-dark-3">
                  <td className="py-5 px-4 pl-9 xl:pl-11">
                    <h5 className="font-medium text-black dark:text-white">{user.displayName || 'Anonymous User'}</h5>
                    <p className="text-sm text-gray-500 dark:text-dark-6">{user.email}</p>
                  </td>
                  <td className="py-5 px-4">
                    {user.isAdmin ? (
                      <span className={`inline-flex rounded-full py-1 px-3 text-sm font-semibold ${getRoleBadgeClass(user.adminRole || 'ADMIN')}`}>
                        {user.adminRole || 'ADMIN'}
                      </span>
                    ) : (
                      <span className="inline-flex rounded-full bg-gray-100 py-1 px-3 text-sm font-semibold text-gray-800 dark:bg-gray-800 dark:text-gray-300">
                        Standard Member
                      </span>
                    )}
                  </td>
                  <td className="py-5 px-4">
                    <span className={`inline-flex rounded-full py-1 px-3 text-sm font-semibold ${getKycBadgeClass(user.kycStatus)}`}>
                      {user.kycStatus}
                    </span>
                  </td>
                  <td className="py-5 px-4 text-sm">
                    <div className="flex items-center space-x-3.5">
                      <span className="inline-flex items-center text-emerald-600 font-semibold" title="Successful Deals">
                        <span className="mr-1">S</span> {user.trustCounter?.successfulDeals || 0}
                      </span>
                      <span className="inline-flex items-center text-blue-600 font-semibold" title="Ongoing Deals">
                        <span className="mr-1">O</span> {user.trustCounter?.ongoingDeals || 0}
                      </span>
                      <span className="inline-flex items-center text-amber-600 font-semibold" title="Breached Deals">
                        <span className="mr-1">B</span> {user.trustCounter?.breachedDeals || 0}
                      </span>
                    </div>
                  </td>
                  <td className="py-5 px-4">
                    <button
                      onClick={() => openOverrideModal(user)}
                      className="inline-flex items-center justify-center rounded-lg border border-stroke px-4 py-2 text-center text-sm font-medium text-black transition hover:bg-gray-100 dark:border-dark-3 dark:text-white dark:hover:bg-dark"
                    >
                      Adjust Metrics
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex flex-col items-center justify-between border-t border-stroke px-4 py-4 dark:border-dark-3 sm:flex-row">
          <p className="text-sm text-gray-500 dark:text-dark-6">
            Showing {(page - 1) * limit + 1} to {Math.min(page * limit, totalUsers)} of {totalUsers} accounts
          </p>
          <div className="flex items-center space-x-2 mt-4 sm:mt-0">
            <button onClick={() => setPage((p) => Math.max(p - 1, 1))} disabled={page === 1}
              className="inline-flex items-center justify-center rounded border border-stroke py-1 px-3 text-sm font-medium text-black hover:bg-gray-100 disabled:opacity-50 dark:border-dark-3 dark:text-white dark:hover:bg-dark">
              Previous
            </button>
            {Array.from({ length: totalPages }, (_, i) => i + 1).map((p) => (
              <button key={p} onClick={() => setPage(p)}
                className={`inline-flex items-center justify-center rounded border py-1 px-3 text-sm font-medium transition ${page === p ? 'bg-primary border-primary text-white' : 'border-stroke text-black hover:bg-gray-100 dark:border-dark-3 dark:text-white dark:hover:bg-dark'}`}>
                {p}
              </button>
            ))}
            <button onClick={() => setPage((p) => Math.min(p + 1, totalPages))} disabled={page === totalPages}
              className="inline-flex items-center justify-center rounded border border-stroke py-1 px-3 text-sm font-medium text-black hover:bg-gray-100 disabled:opacity-50 dark:border-dark-3 dark:text-white dark:hover:bg-dark">
              Next
            </button>
          </div>
        </div>
      )}

      {selectedUser && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center p-4"
          style={{ backgroundColor: 'rgba(0,0,0,0.55)', backdropFilter: 'blur(4px)' }}
          onClick={(e) => { if (e.target === e.currentTarget) closeModal(); }}
        >
          <div className="w-full max-w-lg overflow-hidden rounded-xl bg-white shadow-2xl dark:bg-dark-2">

            <div className="flex items-start justify-between border-b border-stroke px-6 py-5 dark:border-dark-3">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-amber-100 text-amber-600 dark:bg-amber-900/40">
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v4m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/>
                  </svg>
                </div>
                <div>
                  <h3 className="text-lg font-bold text-black dark:text-white">Adjust Trust Metrics</h3>
                  <p className="text-xs text-gray-500 mt-0.5">This action is audited and irreversible.</p>
                </div>
              </div>
              <button onClick={closeModal} disabled={submitting}
                className="rounded-lg p-1.5 text-gray-400 transition hover:bg-gray-100 hover:text-gray-600 disabled:opacity-40 dark:hover:bg-dark">
                <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12"/>
                </svg>
              </button>
            </div>

            <div className="mx-6 mt-5 flex items-center gap-3 rounded-lg border border-stroke bg-gray-1 px-4 py-3 dark:border-dark-3 dark:bg-dark">
              <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary font-bold text-sm">
                {(selectedUser.displayName || selectedUser.email).charAt(0).toUpperCase()}
              </div>
              <div className="min-w-0">
                <p className="text-sm font-semibold text-black dark:text-white truncate">
                  {selectedUser.displayName || 'Anonymous User'}
                </p>
                <p className="text-xs text-gray-500 truncate">{selectedUser.email}</p>
              </div>
              <span className={`ml-auto shrink-0 inline-flex rounded-full py-0.5 px-2.5 text-xs font-semibold ${getKycBadgeClass(selectedUser.kycStatus)}`}>
                {selectedUser.kycStatus}
              </span>
            </div>

            <form onSubmit={handleOverrideSubmit}>
              <div className="px-6 pt-5 pb-3">
                <p className="mb-3 text-xs font-semibold uppercase tracking-wider text-gray-400">Trust Counters</p>
                <div className="grid grid-cols-3 gap-3">

                  <div className="rounded-lg border border-emerald-200 bg-emerald-50 p-3 dark:border-emerald-800 dark:bg-emerald-900/20">
                    <p className="mb-2 text-xs font-medium text-emerald-700 dark:text-emerald-400 flex items-center gap-1">
                      <span>S</span> Successful
                    </p>
                    <div className="flex items-center justify-between gap-1">
                      <button type="button" onClick={() => setSuccessCount((v) => Math.max(0, v - 1))}
                        className="flex h-7 w-7 items-center justify-center rounded-md border border-emerald-300 bg-white text-lg font-bold text-emerald-700 transition hover:bg-emerald-100 dark:border-emerald-700 dark:bg-dark dark:text-emerald-300 dark:hover:bg-emerald-900/40">
                        -
                      </button>
                      <input type="number" min="0" value={successCount}
                        onChange={(e) => setSuccessCount(Math.max(0, parseInt(e.target.value) || 0))}
                        className="w-12 rounded-md border border-emerald-300 bg-white py-1 text-center text-base font-bold text-emerald-800 outline-none focus:border-emerald-500 dark:border-emerald-700 dark:bg-dark dark:text-emerald-200"
                      />
                      <button type="button" onClick={() => setSuccessCount((v) => v + 1)}
                        className="flex h-7 w-7 items-center justify-center rounded-md border border-emerald-300 bg-white text-lg font-bold text-emerald-700 transition hover:bg-emerald-100 dark:border-emerald-700 dark:bg-dark dark:text-emerald-300 dark:hover:bg-emerald-900/40">
                        +
                      </button>
                    </div>
                  </div>

                  <div className="rounded-lg border border-blue-200 bg-blue-50 p-3 dark:border-blue-800 dark:bg-blue-900/20">
                    <p className="mb-2 text-xs font-medium text-blue-700 dark:text-blue-400 flex items-center gap-1">
                      <span>O</span> Ongoing
                    </p>
                    <div className="flex items-center justify-between gap-1">
                      <button type="button" onClick={() => setOngoingCount((v) => Math.max(0, v - 1))}
                        className="flex h-7 w-7 items-center justify-center rounded-md border border-blue-300 bg-white text-lg font-bold text-blue-700 transition hover:bg-blue-100 dark:border-blue-700 dark:bg-dark dark:text-blue-300 dark:hover:bg-blue-900/40">
                        -
                      </button>
                      <input type="number" min="0" value={ongoingCount}
                        onChange={(e) => setOngoingCount(Math.max(0, parseInt(e.target.value) || 0))}
                        className="w-12 rounded-md border border-blue-300 bg-white py-1 text-center text-base font-bold text-blue-800 outline-none focus:border-blue-500 dark:border-blue-700 dark:bg-dark dark:text-blue-200"
                      />
                      <button type="button" onClick={() => setOngoingCount((v) => v + 1)}
                        className="flex h-7 w-7 items-center justify-center rounded-md border border-blue-300 bg-white text-lg font-bold text-blue-700 transition hover:bg-blue-100 dark:border-blue-700 dark:bg-dark dark:text-blue-300 dark:hover:bg-blue-900/40">
                        +
                      </button>
                    </div>
                  </div>

                  <div className="rounded-lg border border-rose-200 bg-rose-50 p-3 dark:border-rose-800 dark:bg-rose-900/20">
                    <p className="mb-2 text-xs font-medium text-rose-700 dark:text-rose-400 flex items-center gap-1">
                      <span>B</span> Breached
                    </p>
                    <div className="flex items-center justify-between gap-1">
                      <button type="button" onClick={() => setBreachCount((v) => Math.max(0, v - 1))}
                        className="flex h-7 w-7 items-center justify-center rounded-md border border-rose-300 bg-white text-lg font-bold text-rose-700 transition hover:bg-rose-100 dark:border-rose-700 dark:bg-dark dark:text-rose-300 dark:hover:bg-rose-900/40">
                        -
                      </button>
                      <input type="number" min="0" value={breachCount}
                        onChange={(e) => setBreachCount(Math.max(0, parseInt(e.target.value) || 0))}
                        className="w-12 rounded-md border border-rose-300 bg-white py-1 text-center text-base font-bold text-rose-800 outline-none focus:border-rose-500 dark:border-rose-700 dark:bg-dark dark:text-rose-200"
                      />
                      <button type="button" onClick={() => setBreachCount((v) => v + 1)}
                        className="flex h-7 w-7 items-center justify-center rounded-md border border-rose-300 bg-white text-lg font-bold text-rose-700 transition hover:bg-rose-100 dark:border-rose-700 dark:bg-dark dark:text-rose-300 dark:hover:bg-rose-900/40">
                        +
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              <div className="px-6 pb-4">
                <p className="mb-2 text-xs font-semibold uppercase tracking-wider text-gray-400">
                  Audit Justification <span className="text-rose-500 normal-case font-normal">*</span>
                </p>
                <textarea
                  required
                  rows={3}
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  placeholder="Describe the reason for this adjustment (min. 10 characters)..."
                  className="w-full resize-none rounded-lg border border-stroke bg-gray-1 px-4 py-3 text-sm text-black outline-none transition focus:border-primary dark:border-dark-3 dark:bg-dark dark:text-white dark:placeholder-gray-500"
                />
                <p className={`mt-1 text-right text-xs transition-colors ${reason.length > 0 && reason.length < 10 ? 'text-rose-500' : 'text-gray-400'}`}>
                  {reason.length} chars {reason.length >= 10 ? 'ready' : `${10 - reason.length} more needed`}
                </p>
              </div>

              {modalError && (
                <div className="mx-6 mb-4 flex items-start gap-2.5 rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 dark:border-rose-800 dark:bg-rose-900/20">
                  <svg xmlns="http://www.w3.org/2000/svg" className="mt-0.5 h-4 w-4 shrink-0 text-rose-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                  </svg>
                  <p className="text-sm text-rose-700 dark:text-rose-400">{modalError}</p>
                </div>
              )}
              {modalSuccess && (
                <div className="mx-6 mb-4 flex items-start gap-2.5 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 dark:border-emerald-800 dark:bg-emerald-900/20">
                  <svg xmlns="http://www.w3.org/2000/svg" className="mt-0.5 h-4 w-4 shrink-0 text-emerald-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M20 6L9 17l-5-5"/>
                  </svg>
                  <p className="text-sm text-emerald-700 dark:text-emerald-400">{modalSuccess}</p>
                </div>
              )}

              <div className="flex items-center justify-end gap-3 border-t border-stroke px-6 py-4 dark:border-dark-3">
                <button type="button" onClick={closeModal} disabled={submitting}
                  className="rounded-lg border border-stroke px-5 py-2.5 text-sm font-medium text-black transition hover:bg-gray-100 disabled:opacity-50 dark:border-dark-3 dark:text-white dark:hover:bg-dark">
                  Cancel
                </button>
                <button type="submit" disabled={submitting || reason.trim().length < 10}
                  className="flex items-center gap-2 rounded-lg bg-primary px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-opacity-90 disabled:opacity-50 disabled:cursor-not-allowed">
                  {submitting ? (
                    <>
                      <svg className="h-4 w-4 animate-spin" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
                      </svg>
                      Saving...
                    </>
                  ) : (
                    <>
                      <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7"/>
                      </svg>
                      Save Adjustments
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
    </div>
  );
}
