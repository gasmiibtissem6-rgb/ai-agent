'use client';

import { AdminPageHeader } from '@/components/Layouts/admin-page-header';
import React, { useEffect, useState, useCallback } from 'react';
import { getApiBaseUrl } from '@/lib/api-base';

interface ArchivedContract {
  id: string;
  title: string;
  company?: string;
  creator?: string;
  status: string;
  participantsCount: number;
  versionsCount: number;
  lockedAt?: string;
  createdAt: string;
}

interface VersionHistoryEntry {
  id: string;
  versionNumber: number;
  isLockedVersion: boolean;
  createdAt: string;
  summary?: string | null;
  status: string;
}

interface ContractHistoryResponse {
  contract: {
    title: string;
  };
  versionHistory: VersionHistoryEntry[];
}

function getErrorMessage(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback;
}

const API_BASE_URL = getApiBaseUrl(
  process.env.NEXT_PUBLIC_API_BASE_URL ?? process.env.NEXT_PUBLIC_API_URL,
);

export default function ContractArchivePage() {
  const [contracts, setContracts] = useState<ArchivedContract[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [selectedContract, setSelectedContract] = useState<string | null>(null);
  const [contractHistory, setContractHistory] = useState<ContractHistoryResponse | null>(null);

  const loadContracts = useCallback(async (searchQuery = '') => {
    try {
      setLoading(true);
      setError('');

      // Use centralized apiRequest which forwards HttpOnly cookies automatically
      const data = await (await import("@/lib/api-client")).apiRequest<any>(
        `/admin/contract-archive?search=${encodeURIComponent(searchQuery.trim())}`,
      );
      const targetData = data?.data ? data.data : data;
      if (targetData && Array.isArray(targetData.items)) {
        setContracts(targetData.items);
      } else if (Array.isArray(targetData)) {
        setContracts(targetData);
      } else {
        setContracts([]);
      }
    } catch (err: unknown) {
      setError(getErrorMessage(err, 'An error occurred loading contract archive.'));
    } finally {
      setLoading(false);
    }
  }, []);

  const loadVersionHistory = useCallback(async (contractId: string) => {
    try {
      const data = await (await import("@/lib/api-client")).apiRequest<any>(
        `/admin/contract-archive/${contractId}/version-history`,
      );
      setContractHistory(data.data);
      setSelectedContract(contractId);
    } catch (err: unknown) {
      setError(getErrorMessage(err, 'Failed to load version history'));
    }
  }, []);

  useEffect(() => {
    const delayDebounce = setTimeout(() => {
      loadContracts(search);
    }, 300);

    return () => clearTimeout(delayDebounce);
  }, [search, loadContracts]);

  const getStatusBadgeClass = (status: string) => {
    switch (status?.toUpperCase()) {
      case 'APPROVED':
      case 'LOCKED':
        return 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300';
      case 'ARCHIVED':
        return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300';
      default:
        return 'bg-purple-100 text-purple-800 dark:bg-purple-950 dark:text-purple-300';
    }
  };

  const lockedCount = contracts.filter((contract) =>
    ['APPROVED', 'LOCKED', 'ARCHIVED'].includes(contract.status?.toUpperCase()),
  ).length;
  const versionCount = contracts.reduce(
    (total, contract) => total + (contract.versionsCount || 0),
    0,
  );
  const participantCount = contracts.reduce(
    (total, contract) => total + (contract.participantsCount || 0),
    0,
  );
  const contractStatuses = Array.from(new Set(contracts.map((contract) => contract.status))).sort();
  const filteredContracts = contracts.filter(
    (contract) => statusFilter === 'ALL' || contract.status === statusFilter,
  );

  return (
    <div className="space-y-7">
      <AdminPageHeader
        eyebrow="AUDIT ARCHIVE"
        title="Contract Archive"
        description="Inspect locked contracts, historical versions, ownership context, and audit records without changing the source documents."
        panelLabel="Archive Depth"
        panelValue={loading ? '...' : contracts.length}
        panelNote="Archived records"
        panelSubtext={`${versionCount} saved version${versionCount === 1 ? '' : 's'} available for review.`}
        panelBarValue={contracts.length ? Math.min((lockedCount / contracts.length) * 100, 100) : 12}
        metrics={[
          {
            label: 'Contracts',
            value: loading ? '...' : contracts.length,
            note: 'Archive entries',
            accent: 'from-slate-900 to-slate-700',
          },
          {
            label: 'Locked',
            value: loading ? '...' : lockedCount,
            note: 'Immutable records',
            accent: 'from-emerald-600 to-teal-500',
          },
          {
            label: 'Versions',
            value: loading ? '...' : versionCount,
            note: 'Historical snapshots',
            accent: 'from-blue-700 to-indigo-600',
          },
          {
            label: 'Parties',
            value: loading ? '...' : participantCount,
            note: 'Linked participants',
            accent: 'from-amber-600 to-amber-500',
          },
        ]}
        tone="slate"
        compact
      />

      <div className="rounded-[20px] border border-stroke bg-white px-5 pb-3 pt-6 shadow-card-2 dark:border-dark-3 dark:bg-dark-2 sm:px-7.5">
      <div className="mb-6 flex flex-col gap-4 xl:flex-row xl:items-end xl:justify-between">
        <div>
          <h4 className="text-xl font-bold text-black dark:text-white">Contract Archive & Audit Log</h4>
          <p className="mt-1 text-sm font-medium text-gray-500 dark:text-dark-6">
            Read-only historical repository of all approved and locked contracts
          </p>
        </div>
        <div className="grid gap-2 sm:grid-cols-2 xl:flex xl:items-center">
          <input
            type="text"
            placeholder="Search contracts..."
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
            {contractStatuses.map((status) => (
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
              <th className="py-4 px-4 font-medium text-black dark:text-white pl-6">Contract</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">Company</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">Created By</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">Versions</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">Status</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading && contracts.length === 0 ? (
              <tr>
                <td colSpan={6} className="py-10 text-center text-gray-500 animate-pulse">
                  Loading archived contracts...
                </td>
              </tr>
            ) : filteredContracts.length === 0 ? (
              <tr>
                <td colSpan={6} className="py-10 text-center text-gray-500">
                  No archived contracts match the selected filters.
                </td>
              </tr>
            ) : (
              filteredContracts.map((contract) => (
                <tr key={contract.id} className="border-b border-stroke/80 dark:border-dark-3">
                  <td className="py-5 px-4 pl-6">
                    <h5 className="font-medium text-black dark:text-white">{contract.title}</h5>
                    <p className="font-mono text-xs text-gray-400 dark:text-dark-5">{contract.id}</p>
                  </td>
                  <td className="py-5 px-4 text-sm text-black dark:text-white">
                    {contract.company || 'Individual'}
                  </td>
                  <td className="py-5 px-4 text-sm text-black dark:text-white">
                    {contract.creator || 'System'}
                  </td>
                  <td className="py-5 px-4 text-sm text-gray-500 dark:text-dark-6">
                    {contract.versionsCount} versions
                  </td>
                  <td className="py-5 px-4">
                    <span className={`inline-flex rounded-full py-1 px-3 text-xs font-semibold ${getStatusBadgeClass(contract.status)}`}>
                      {contract.status}
                    </span>
                  </td>
                  <td className="py-5 px-4">
                    <button
                      onClick={() => loadVersionHistory(contract.id)}
                      className="text-primary hover:text-opacity-80 text-sm font-medium"
                    >
                      View History
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {selectedContract && contractHistory && (
        <div className="mt-8 border-t border-stroke pt-6 dark:border-dark-3">
          <h5 className="mb-4 text-lg font-bold text-black dark:text-white">
            Version History: {contractHistory.contract.title}
          </h5>
          <div className="space-y-4">
            {contractHistory.versionHistory.map((version) => (
              <div
                key={version.id}
                className={`rounded-lg border p-4 ${
                  version.isLockedVersion
                    ? 'border-emerald-500 bg-emerald-50 dark:bg-emerald-950/20'
                    : 'border-stroke dark:border-dark-3 dark:bg-dark'
                }`}
              >
                <div className="flex justify-between items-start">
                  <div>
                    <h6 className="font-semibold text-black dark:text-white">
                      Version {version.versionNumber}
                      {version.isLockedVersion && (
                        <span className="ml-2 text-emerald-600 text-xs font-medium">(Locked)</span>
                      )}
                    </h6>
                    <p className="text-sm text-gray-500">
                      {new Date(version.createdAt).toLocaleString()}
                    </p>
                    {version.summary && (
                      <p className="mt-2 text-sm text-gray-600 dark:text-dark-6">
                        {version.summary}
                      </p>
                    )}
                  </div>
                  <span
                    className={`inline-flex rounded-full py-1 px-3 text-xs font-semibold ${getStatusBadgeClass(
                      version.status
                    )}`}
                  >
                    {version.status}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
    </div>
  );
}
