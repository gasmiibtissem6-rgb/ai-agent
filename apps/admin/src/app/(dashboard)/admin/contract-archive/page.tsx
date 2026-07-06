'use client';

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

const API_BASE_URL = getApiBaseUrl(
  process.env.NEXT_PUBLIC_API_BASE_URL ?? process.env.NEXT_PUBLIC_API_URL,
);

export default function ContractArchivePage() {
  const [contracts, setContracts] = useState<ArchivedContract[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [selectedContract, setSelectedContract] = useState<string | null>(null);
  const [contractHistory, setContractHistory] = useState<any>(null);

  const loadContracts = useCallback(async (searchQuery = '') => {
    try {
      setLoading(true);
      setError('');

      const token = localStorage.getItem('admin_token');
      if (!token || token === 'undefined' || token === 'null') {
        throw new Error('Authentication required. Please sign in again.');
      }

      const res = await fetch(`${API_BASE_URL}/admin/contract-archive?search=${encodeURIComponent(searchQuery.trim())}`, {
        method: "GET",
        headers: {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        cache: 'no-store',
      });

      if (!res.ok) {
        throw new Error(`Server responded with status ${res.status}`);
      }

      const data = await res.json();
      const targetData = data?.data ? data.data : data;
      if (targetData && Array.isArray(targetData.items)) {
        setContracts(targetData.items);
      } else if (Array.isArray(targetData)) {
        setContracts(targetData);
      } else {
        setContracts([]);
      }
    } catch (err: any) {
      setError(err.message || 'An error occurred loading contract archive.');
    } finally {
      setLoading(false);
    }
  }, []);

  const loadVersionHistory = useCallback(async (contractId: string) => {
    try {
      const token = localStorage.getItem('admin_token');
      const res = await fetch(`${API_BASE_URL}/admin/contract-archive/${contractId}/version-history`, {
        method: "GET",
        headers: {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });

      if (!res.ok) {
        throw new Error('Failed to load version history');
      }

      const data = await res.json();
      setContractHistory(data.data);
      setSelectedContract(contractId);
    } catch (err: any) {
      setError(err.message || 'Failed to load version history');
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

  return (
    <div className="rounded-sm border border-stroke bg-gray-1 px-5 pt-6 pb-2.5 shadow-default dark:border-strokedark dark:bg-boxdark sm:px-7.5 xl:pb-1">
      <div className="mb-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h4 className="text-xl font-bold text-black dark:text-white">Contract Archive & Audit Log</h4>
          <p className="text-sm font-medium mt-1 text-gray-500">
            Read-only historical repository of all approved and locked contracts
          </p>
        </div>
        <div>
          <input
            type="text"
            placeholder="Search contracts..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full max-w-xs rounded-lg border border-stroke bg-transparent px-4 py-2 text-black outline-none transition focus:border-primary dark:border-strokedark dark:bg-meta-4 dark:text-white"
          />
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
            <tr className="bg-gray-2 text-left dark:bg-meta-4">
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
            ) : contracts.length === 0 ? (
              <tr>
                <td colSpan={6} className="py-10 text-center text-gray-500">
                  No archived contracts found
                </td>
              </tr>
            ) : (
              contracts.map((contract) => (
                <tr key={contract.id} className="border-b border-[#eee] dark:border-strokedark">
                  <td className="py-5 px-4 pl-6">
                    <h5 className="font-medium text-black dark:text-white">{contract.title}</h5>
                    <p className="text-xs text-gray-400 font-mono">{contract.id}</p>
                  </td>
                  <td className="py-5 px-4 text-sm text-black dark:text-white">
                    {contract.company || 'Individual'}
                  </td>
                  <td className="py-5 px-4 text-sm text-black dark:text-white">
                    {contract.creator || 'System'}
                  </td>
                  <td className="py-5 px-4 text-sm text-gray-500">
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
        <div className="mt-8 border-t border-stroke pt-6">
          <h5 className="text-lg font-bold text-black dark:text-white mb-4">
            Version History: {contractHistory.contract.title}
          </h5>
          <div className="space-y-4">
            {contractHistory.versionHistory.map((version: any) => (
              <div
                key={version.id}
                className={`rounded-lg border p-4 ${
                  version.isLockedVersion
                    ? 'border-emerald-500 bg-emerald-50 dark:bg-emerald-950/20'
                    : 'border-stroke'
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
                      <p className="text-sm text-gray-600 dark:text-gray-400 mt-2">
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
  );
}
