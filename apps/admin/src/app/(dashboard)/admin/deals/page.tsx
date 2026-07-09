'use client';

import { AdminPageHeader } from '@/components/Layouts/admin-page-header';
import React, { useEffect, useState, useCallback } from 'react';
import { getApiBaseUrl } from '@/lib/api-base';

interface DealItem {
  id: string;
  title: string;
  company?: { legalName: string } | string;
  creator?: { displayName: string | null; email: string } | string;
  status: string;
  participantsCount: number;
  attachmentsCount: number;
  createdAt: string;
}

function getErrorMessage(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback;
}

const API_BASE_URL = getApiBaseUrl(
  process.env.NEXT_PUBLIC_API_BASE_URL ?? process.env.NEXT_PUBLIC_API_URL,
);

export default function AdminDealsLedgerPage() {
  const [deals, setDeals] = useState<DealItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');

  const loadLedgerData = useCallback(async (searchQuery = '') => {
    try {
      setLoading(true);
      setError('');

      const token = localStorage.getItem('admin_token');
      if (!token || token === 'undefined' || token === 'null') {
        throw new Error('Authentication required. Please sign in again.');
      }

      const res = await fetch(`${API_BASE_URL}/admin/deals?search=${encodeURIComponent(searchQuery.trim())}`, {
        method: "GET",
        headers: {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        cache: 'no-store',
      });

      if (!res.ok) {
        const apiError = await res.json().catch(() => ({}));
        const apiMessage = Array.isArray(apiError?.message)
          ? apiError.message[0]
          : apiError?.message;
        throw new Error(apiMessage || `Server responded with status ${res.status}`);
      }

      const data = await res.json();
      const targetData = data?.data ? data.data : data;

      if (targetData && Array.isArray(targetData.items)) {
        setDeals(targetData.items);
      } else if (Array.isArray(targetData)) {
        setDeals(targetData);
      } else {
        setDeals([]);
      }
    } catch (err: unknown) {
      setError(getErrorMessage(err, 'An error occurred loading the deal ledger.'));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const delayDebounce = setTimeout(() => {
      loadLedgerData(search);
    }, 300);

    return () => clearTimeout(delayDebounce);
  }, [search, loadLedgerData]);

  const getStatusBadgeClass = (status: string) => {
    switch (status?.toUpperCase()) {
      case 'APPROVED':
      case 'LOCKED':
        return 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300';
      case 'REJECTED':
      case 'CANCELLED':
        return 'bg-rose-100 text-rose-800 dark:bg-rose-950 dark:text-rose-300';
      case 'PENDING_APPROVAL':
        return 'bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300';
      case 'NEGOTIATION':
      default:
        return 'bg-purple-100 text-purple-800 dark:bg-purple-950 dark:text-purple-300';
    }
  };

  const renderCompany = (company: DealItem["company"]) =>
    typeof company === 'object' ? company?.legalName : company;
  const renderCreator = (creator: DealItem["creator"]) =>
    typeof creator === 'object' ? (creator?.displayName || creator?.email) : creator;

  const approvedCount = deals.filter((deal) =>
    ['APPROVED', 'LOCKED'].includes(deal.status?.toUpperCase()),
  ).length;
  const participantCount = deals.reduce(
    (total, deal) => total + (deal.participantsCount || 0),
    0,
  );
  const fileCount = deals.reduce(
    (total, deal) => total + (deal.attachmentsCount || 0),
    0,
  );
  const dealStatuses = Array.from(new Set(deals.map((deal) => deal.status))).sort();
  const filteredDeals = deals.filter(
    (deal) => statusFilter === 'ALL' || deal.status === statusFilter,
  );

  return (
    <div className="space-y-7">
      <AdminPageHeader
        eyebrow="DEAL OPERATIONS"
        title="Deals Ledger"
        description="Supervise active transaction drafts, company scope, ownership, parties, and attached files across the platform."
        panelLabel="Active Pipeline"
        panelValue={loading ? "..." : deals.length}
        panelNote="Visible records"
        panelSubtext={`${approvedCount} approved or locked deals currently visible.`}
        panelBarValue={deals.length ? Math.min((approvedCount / deals.length) * 100, 100) : 12}
        metrics={[
          {
            label: "Deals",
            value: loading ? "..." : deals.length,
            note: "Loaded records",
            accent: "from-blue-700 to-indigo-600",
          },
          {
            label: "Approved",
            value: loading ? "..." : approvedCount,
            note: "Approved or locked",
            accent: "from-emerald-600 to-teal-500",
          },
          {
            label: "Parties",
            value: loading ? "..." : participantCount,
            note: "Linked participants",
            accent: "from-slate-900 to-slate-700",
          },
          {
            label: "Files",
            value: loading ? "..." : fileCount,
            note: "Attached documents",
            accent: "from-amber-600 to-amber-500",
          },
        ]}
        tone="blue"
        compact
      />

      <div className="rounded-[20px] border border-stroke bg-white px-5 pb-3 pt-6 shadow-card-2 dark:border-dark-3 dark:bg-dark-2 sm:px-7.5">
      <div className="mb-6 flex flex-col gap-4 xl:flex-row xl:items-end xl:justify-between">
        <div>
          <h4 className="text-xl font-bold text-black dark:text-white">Global Deals Ledger</h4>
          <p className="mt-1 text-sm font-medium text-gray-500 dark:text-dark-6">
            Supervise, audit, and inspect active legal pipeline drafts across all system companies.
          </p>
        </div>
        <div className="grid gap-2 sm:grid-cols-2 xl:flex xl:items-center">
          <input
            type="text"
            placeholder="Search title..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full max-w-xs rounded-xl border border-stroke bg-gray-1 px-4 py-2.5 text-black outline-none transition focus:border-primary dark:border-dark-3 dark:bg-dark dark:text-white"
          />
          <select
            value={statusFilter}
            onChange={(event) => setStatusFilter(event.target.value)}
            className="rounded-xl border border-stroke bg-gray-1 px-4 py-2.5 text-sm text-black outline-none transition focus:border-primary dark:border-dark-3 dark:bg-dark dark:text-white"
          >
            <option value="ALL">All statuses</option>
            {dealStatuses.map((status) => (
              <option key={status} value={status}>
                {status}
              </option>
            ))}
          </select>
          <button
            type="button"
            onClick={() => {
              setSearch('');
              setStatusFilter('ALL');
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
              <th className="py-4 px-4 font-medium text-black dark:text-white pl-6">Deal Details</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">Company Scope</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">Owner</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">Parties / Files</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">Status</th>
            </tr>
          </thead>
          <tbody>
            {loading && deals.length === 0 ? (
              <tr>
                <td colSpan={5} className="py-10 text-center text-gray-500 animate-pulse">
                  Loading system deal records...
                </td>
              </tr>
            ) : filteredDeals.length === 0 ? (
              <tr>
                <td colSpan={5} className="py-10 text-center text-gray-500">
                  No deals match the selected filters.
                </td>
              </tr>
            ) : (
              filteredDeals.map((deal) => (
                <tr key={deal.id} className="border-b border-stroke/80 dark:border-dark-3">
                  <td className="py-5 px-4 pl-6">
                    <h5 className="font-medium text-black dark:text-white">{deal.title}</h5>
                    <p className="font-mono text-xs text-gray-400 dark:text-dark-5">{deal.id}</p>
                  </td>
                  <td className="py-5 px-4 text-sm text-black dark:text-white">
                    {renderCompany(deal.company) || 'Individual'}
                  </td>
                  <td className="py-5 px-4 text-sm text-black dark:text-white">
                    {renderCreator(deal.creator) || 'System Profile'}
                  </td>
                  <td className="py-5 px-4 text-sm text-gray-500 dark:text-dark-6">
                    Parties: {deal.participantsCount || 0} | Files: {deal.attachmentsCount || 0}
                  </td>
                  <td className="py-5 px-4">
                    <span className={`inline-flex rounded-full py-1 px-3 text-xs font-semibold ${getStatusBadgeClass(deal.status)}`}>
                      {deal.status}
                    </span>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
    </div>
  );
}
