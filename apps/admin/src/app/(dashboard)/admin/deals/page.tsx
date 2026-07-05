'use client';

import React, { useEffect, useState, useCallback } from 'react';
import { getApiBaseUrl } from '@/lib/api-base';

interface DealItem {
  id: string;
  title: string;
  company: string;
  creator: string;
  status: string;
  participantsCount: number;
  attachmentsCount: number;
  createdAt: string;
}

const API_BASE_URL = getApiBaseUrl(
  process.env.NEXT_PUBLIC_API_BASE_URL ?? process.env.NEXT_PUBLIC_API_URL,
);

export default function AdminDealsLedgerPage() {
  const [deals, setDeals] = useState<DealItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');

  const loadLedgerData = useCallback(async (searchQuery = '') => {
    try {
      setLoading(true);
      setError('');

      const token = localStorage.getItem('admin_token');
      if (!token || token === 'undefined' || token === 'null') {
        throw new Error('Authentication required. Please sign in again.');
      }

      const res = await fetch(`${API_BASE_URL}/admin/deals?search=${encodeURIComponent(searchQuery)}`, {
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
    } catch (err: any) {
      setError(err.message || 'An error occurred loading the deal ledger.');
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

  return (
    <div className="rounded-sm border border-stroke bg-white px-5 pt-6 pb-2.5 shadow-default dark:border-strokedark dark:bg-boxdark sm:px-7.5 xl:pb-1">
      <div className="mb-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h4 className="text-xl font-bold text-black dark:text-white">Global Deals Ledger</h4>
          <p className="text-sm font-medium mt-1 text-gray-500">
            Supervise, audit, and inspect active legal pipeline drafts across all system companies.
          </p>
        </div>
        <div>
          <input
            type="text"
            placeholder="Search title..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full max-w-xs rounded-lg border border-stroke bg-transparent px-4 py-2 text-black outline-none transition focus:border-primary dark:border-strokedark dark:bg-meta-4 dark:text-white"
          />
        </div>
      </div>

      {error && (
        <div className="mb-6 rounded-lg bg-rose-50 p-4 text-sm text-rose-600 dark:bg-rose-950/20 dark:text-rose-400">
          Error: {error}
        </div>
      )}

      {loading && deals.length === 0 ? (
        <div className="p-6 text-center text-black dark:text-white">Loading system deal records...</div>
      ) : (
        <div className="max-w-full overflow-x-auto">
          <table className="w-full table-auto">
            <thead>
              <tr className="bg-gray-2 text-left dark:bg-meta-4">
                <th className="py-4 px-4 font-medium text-black dark:text-white pl-6">Deal Details</th>
                <th className="py-4 px-4 font-medium text-black dark:text-white">Company Scope</th>
                <th className="py-4 px-4 font-medium text-black dark:text-white">Owner</th>
                <th className="py-4 px-4 font-medium text-black dark:text-white">Parties / Files</th>
                <th className="py-4 px-4 font-medium text-black dark:text-white">Status</th>
              </tr>
            </thead>
            <tbody>
              {deals.length === 0 ? (
                <tr>
                  <td colSpan={5} className="py-10 text-center text-gray-500">
                    No active transaction structures found inside the pipeline matrix.
                  </td>
                </tr>
              ) : (
                deals.map((deal) => (
                  <tr key={deal.id} className="border-b border-[#eee] dark:border-strokedark">
                    <td className="py-5 px-4 pl-6">
                      <h5 className="font-medium text-black dark:text-white">{deal.title}</h5>
                      <p className="text-xs text-gray-400 font-mono">{deal.id}</p>
                    </td>
                    <td className="py-5 px-4 text-sm text-black dark:text-white">{deal.company}</td>
                    <td className="py-5 px-4 text-sm text-black dark:text-white">{deal.creator}</td>
                    <td className="py-5 px-4 text-sm text-gray-500">
                      👥 {deal.participantsCount} Parties | 📂 {deal.attachmentsCount} Files
                    </td>
                    <td className="py-5 px-4">
                      <span className="inline-flex rounded-full bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300 py-1 px-3 text-xs font-semibold">
                        {deal.status}
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}