'use client';

import React, { useEffect, useState, useCallback } from 'react';
import { getApiBaseUrl } from '@/lib/api-base';

interface DisputeTicket {
  id: string;
  resourceType: string;
  resourceId: string;
  status: string;
  reason: string;
  resolution?: string;
  reporter: string;
  reviewedBy?: string;
  createdAt: string;
  reviewedAt?: string;
}

const API_BASE_URL = getApiBaseUrl(
  process.env.NEXT_PUBLIC_API_BASE_URL ?? process.env.NEXT_PUBLIC_API_URL,
);

export default function DisputeCenterPage() {
  const [tickets, setTickets] = useState<DisputeTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [selectedTicket, setSelectedTicket] = useState<DisputeTicket | null>(null);
  const [resolution, setResolution] = useState('');
  const [newStatus, setNewStatus] = useState<'RESOLVED' | 'DISMISSED' | 'UNDER_REVIEW'>('UNDER_REVIEW');

  const loadTickets = useCallback(async (searchQuery = '') => {
    try {
      setLoading(true);
      setError('');

      const token = localStorage.getItem('admin_token');
      if (!token || token === 'undefined' || token === 'null') {
        throw new Error('Authentication required. Please sign in again.');
      }

      const res = await fetch(`${API_BASE_URL}/admin/dispute-center?search=${encodeURIComponent(searchQuery.trim())}`, {
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
        setTickets(targetData.items);
      } else if (Array.isArray(targetData)) {
        setTickets(targetData);
      } else {
        setTickets([]);
      }
    } catch (err: any) {
      setError(err.message || 'An error occurred loading dispute tickets.');
    } finally {
      setLoading(false);
    }
  }, []);

  const updateTicket = useCallback(async () => {
    if (!selectedTicket) return;
    try {
      const token = localStorage.getItem('admin_token');
      const res = await fetch(`${API_BASE_URL}/admin/dispute-center/${selectedTicket.id}/resolve`, {
        method: "PATCH",
        headers: {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          status: newStatus,
          resolution: resolution || undefined,
        }),
      });

      if (!res.ok) {
        throw new Error('Failed to update ticket');
      }

      setSelectedTicket(null);
      setResolution('');
      loadTickets(search);
    } catch (err: any) {
      setError(err.message || 'Failed to update ticket');
    }
  }, [selectedTicket, newStatus, resolution, search, loadTickets]);

  const pauseDeal = useCallback(async (dealId: string, reason: string) => {
    try {
      const token = localStorage.getItem('admin_token');
      const res = await fetch(`${API_BASE_URL}/admin/dispute-center/deal/${dealId}/pause`, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ reason }),
      });

      if (!res.ok) {
        throw new Error('Failed to pause deal');
      }

      loadTickets(search);
    } catch (err: any) {
      setError(err.message || 'Failed to pause deal');
    }
  }, [search, loadTickets]);

  const suspendUser = useCallback(async (profileId: string, reason: string) => {
    try {
      const token = localStorage.getItem('admin_token');
      const res = await fetch(`${API_BASE_URL}/admin/dispute-center/profile/${profileId}/suspend`, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ reason }),
      });

      if (!res.ok) {
        throw new Error('Failed to suspend user');
      }

      loadTickets(search);
    } catch (err: any) {
      setError(err.message || 'Failed to suspend user');
    }
  }, [search, loadTickets]);

  useEffect(() => {
    const delayDebounce = setTimeout(() => {
      loadTickets(search);
    }, 300);

    return () => clearTimeout(delayDebounce);
  }, [search, loadTickets]);

  const getStatusBadgeClass = (status: string) => {
    switch (status?.toUpperCase()) {
      case 'OPEN':
        return 'bg-red-100 text-red-800 dark:bg-red-950 dark:text-red-300';
      case 'UNDER_REVIEW':
        return 'bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300';
      case 'RESOLVED':
        return 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300';
      case 'DISMISSED':
        return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300';
      default:
        return 'bg-purple-100 text-purple-800 dark:bg-purple-950 dark:text-purple-300';
    }
  };

  return (
    <div className="rounded-sm border border-stroke bg-white px-5 pt-6 pb-2.5 shadow-default dark:border-strokedark dark:bg-boxdark sm:px-7.5 xl:pb-1">
      <div className="mb-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h4 className="text-xl font-bold text-black dark:text-white">Platform Dispute Center</h4>
          <p className="text-sm font-medium mt-1 text-gray-500">
            Centralized ticketing area for fraud reports and contract disputes
          </p>
        </div>
        <div>
          <input
            type="text"
            placeholder="Search tickets..."
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
              <th className="py-4 px-4 font-medium text-black dark:text-white pl-6">Ticket</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">Resource Type</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">Reporter</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">Status</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading && tickets.length === 0 ? (
              <tr>
                <td colSpan={5} className="py-10 text-center text-gray-500 animate-pulse">
                  Loading dispute tickets...
                </td>
              </tr>
            ) : tickets.length === 0 ? (
              <tr>
                <td colSpan={5} className="py-10 text-center text-gray-500">
                  No dispute tickets found
                </td>
              </tr>
            ) : (
              tickets.map((ticket) => (
                <tr key={ticket.id} className="border-b border-[#eee] dark:border-strokedark">
                  <td className="py-5 px-4 pl-6">
                    <h5 className="font-medium text-black dark:text-white">
                      Report #{ticket.id.slice(0, 8)}
                    </h5>
                    <p className="text-sm text-gray-500 mt-1 line-clamp-2">
                      {ticket.reason}
                    </p>
                  </td>
                  <td className="py-5 px-4 text-sm text-black dark:text-white">
                    {ticket.resourceType}
                  </td>
                  <td className="py-5 px-4 text-sm text-black dark:text-white">
                    {ticket.reporter}
                  </td>
                  <td className="py-5 px-4">
                    <span className={`inline-flex rounded-full py-1 px-3 text-xs font-semibold ${getStatusBadgeClass(ticket.status)}`}>
                      {ticket.status}
                    </span>
                  </td>
                  <td className="py-5 px-4">
                    <div className="flex gap-2">
                      <button
                        onClick={() => setSelectedTicket(ticket)}
                        className="text-primary hover:text-opacity-80 text-sm font-medium"
                      >
                        Review
                      </button>
                      {ticket.resourceType === 'DEAL' && (
                        <button
                          onClick={() => pauseDeal(ticket.resourceId, 'Dispute review')}
                          className="text-amber-600 hover:text-opacity-80 text-sm font-medium"
                        >
                          Pause Deal
                        </button>
                      )}
                      {ticket.resourceType === 'PROFILE' && (
                        <button
                          onClick={() => suspendUser(ticket.resourceId, ticket.reason)}
                          className="text-red-600 hover:text-opacity-80 text-sm font-medium"
                        >
                          Suspend
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {selectedTicket && (
        <div className="mt-8 border-t border-stroke pt-6">
          <h5 className="text-lg font-bold text-black dark:text-white mb-4">
            Reviewing Ticket #{selectedTicket.id.slice(0, 8)}
          </h5>
          <div className="space-y-4">
            <div>
              <p className="text-sm font-medium text-gray-700 dark:text-gray-300">Reason</p>
              <p className="text-gray-600 dark:text-gray-400 mt-1">{selectedTicket.reason}</p>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium text-gray-700 dark:text-gray-300 block mb-2">
                  New Status
                </label>
                <select
                  value={newStatus}
                  onChange={(e) => setNewStatus(e.target.value as any)}
                  className="w-full rounded-lg border border-stroke bg-transparent px-4 py-2 text-black outline-none transition focus:border-primary dark:border-strokedark dark:bg-meta-4 dark:text-white"
                >
                  <option value="UNDER_REVIEW">Under Review</option>
                  <option value="RESOLVED">Resolved</option>
                  <option value="DISMISSED">Dismissed</option>
                </select>
              </div>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 dark:text-gray-300 block mb-2">
                Resolution Notes
              </label>
              <textarea
                value={resolution}
                onChange={(e) => setResolution(e.target.value)}
                className="w-full rounded-lg border border-stroke bg-transparent px-4 py-2 text-black outline-none transition focus:border-primary dark:border-strokedark dark:bg-meta-4 dark:text-white"
                rows={4}
                placeholder="Add resolution notes..."
              />
            </div>
            <div className="flex gap-3">
              <button
                onClick={updateTicket}
                className="rounded-lg bg-primary px-4 py-2 text-white font-medium hover:bg-opacity-90"
              >
                Update Ticket
              </button>
              <button
                onClick={() => {
                  setSelectedTicket(null);
                  setResolution('');
                }}
                className="rounded-lg border border-stroke px-4 py-2 text-gray-700 dark:text-gray-300 font-medium"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
