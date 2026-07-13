'use client';

import { AdminPageHeader } from '@/components/Layouts/admin-page-header';
import React, { useEffect, useState, useCallback } from 'react';
import { getApiBaseUrl } from '@/lib/api-base';
import { Button } from '@/components/ui-elements/button';
import { EyeIcon } from '@/assets/icons';

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

function getErrorMessage(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback;
}

const API_BASE_URL = getApiBaseUrl(
  process.env.NEXT_PUBLIC_API_BASE_URL ?? process.env.NEXT_PUBLIC_API_URL,
);

export default function DisputeCenterPage() {
  const [tickets, setTickets] = useState<DisputeTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('ACTIVE');
  const [resourceFilter, setResourceFilter] = useState('ALL');
  const [selectedTicket, setSelectedTicket] = useState<DisputeTicket | null>(null);
  const [resolution, setResolution] = useState('');
  const [newStatus, setNewStatus] = useState<'RESOLVED' | 'DISMISSED' | 'UNDER_REVIEW'>('UNDER_REVIEW');

  const loadTickets = useCallback(async (searchQuery = '') => {
    try {
      setLoading(true);
      setError('');

      const data = await (await import("@/lib/api-client")).apiRequest<any>(
        `/admin/dispute-center?search=${encodeURIComponent(searchQuery.trim())}`,
      );
      const targetData = data?.data ? data.data : data;
      if (targetData && Array.isArray(targetData.items)) {
        setTickets(targetData.items);
      } else if (Array.isArray(targetData)) {
        setTickets(targetData);
      } else {
        setTickets([]);
      }
    } catch (err: unknown) {
      setError(getErrorMessage(err, 'An error occurred loading dispute tickets.'));
    } finally {
      setLoading(false);
    }
  }, []);

  const updateTicket = useCallback(async () => {
    if (!selectedTicket) return;
    try {
      await (await import("@/lib/api-client")).apiRequest<any>(
        `/admin/dispute-center/${selectedTicket.id}/resolve`,
        { method: 'PATCH', body: JSON.stringify({ status: newStatus, resolution: resolution || undefined }) },
      );

      setSelectedTicket(null);
      setResolution('');
      loadTickets(search);
    } catch (err: unknown) {
      setError(getErrorMessage(err, 'Failed to update ticket'));
    }
  }, [selectedTicket, newStatus, resolution, search, loadTickets]);

  const pauseDeal = useCallback(async (dealId: string, reason: string) => {
    try {
      await (await import("@/lib/api-client")).apiRequest<any>(
        `/admin/dispute-center/deal/${dealId}/pause`,
        { method: 'POST', body: JSON.stringify({ reason }) },
      );

      loadTickets(search);
    } catch (err: unknown) {
      setError(getErrorMessage(err, 'Failed to pause deal'));
    }
  }, [search, loadTickets]);

  const suspendUser = useCallback(async (profileId: string, reason: string) => {
    try {
      await (await import("@/lib/api-client")).apiRequest<any>(
        `/admin/dispute-center/profile/${profileId}/suspend`,
        { method: 'POST', body: JSON.stringify({ reason }) },
      );

      loadTickets(search);
    } catch (err: unknown) {
      setError(getErrorMessage(err, 'Failed to suspend user'));
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

  const openCount = tickets.filter((ticket) => ticket.status?.toUpperCase() === 'OPEN').length;
  const reviewCount = tickets.filter(
    (ticket) => ticket.status?.toUpperCase() === 'UNDER_REVIEW',
  ).length;
  const resolvedCount = tickets.filter(
    (ticket) => ['RESOLVED', 'DISMISSED'].includes(ticket.status?.toUpperCase()),
  ).length;
  const actionLoad = openCount + reviewCount;
  const resourceTypes = Array.from(new Set(tickets.map((ticket) => ticket.resourceType))).sort();
  const filteredTickets = tickets.filter((ticket) => {
    const normalizedStatus = ticket.status?.toUpperCase();
    const matchesStatus =
      statusFilter === 'ALL' ||
      (statusFilter === 'ACTIVE' && !['RESOLVED', 'DISMISSED'].includes(normalizedStatus)) ||
      normalizedStatus === statusFilter;
    const matchesResource = resourceFilter === 'ALL' || ticket.resourceType === resourceFilter;

    return matchesStatus && matchesResource;
  });

  return (
    <div className="space-y-7">
      <AdminPageHeader
        eyebrow="RISK RESPONSE"
        title="Dispute Center"
        description="Track fraud reports and contract disputes, review context quickly, and apply platform actions with clear operational priority."
        panelLabel="Response Load"
        panelValue={loading ? '...' : actionLoad}
        panelNote="Needs handling"
        panelSubtext={`${resolvedCount} ticket${resolvedCount === 1 ? '' : 's'} already resolved or dismissed in this view.`}
        panelBarValue={tickets.length ? Math.min((actionLoad / tickets.length) * 100, 100) : 12}
        metrics={[
          {
            label: 'Tickets',
            value: loading ? '...' : tickets.length,
            note: 'Loaded reports',
            accent: 'from-slate-900 to-slate-700',
          },
          {
            label: 'Open',
            value: loading ? '...' : openCount,
            note: 'New reports',
            accent: 'from-rose-700 to-rose-500',
          },
          {
            label: 'Review',
            value: loading ? '...' : reviewCount,
            note: 'Under investigation',
            accent: 'from-amber-600 to-amber-500',
          },
          {
            label: 'Closed',
            value: loading ? '...' : resolvedCount,
            note: 'Resolved or dismissed',
            accent: 'from-emerald-600 to-teal-500',
          },
        ]}
        tone="rose"
        compact
      />

      <div className="rounded-[20px] border border-stroke bg-white px-5 pb-3 pt-6 shadow-card-2 dark:border-dark-3 dark:bg-dark-2 sm:px-7.5">
      <div className="mb-6 flex flex-col gap-4 xl:flex-row xl:items-end xl:justify-between">
        <div>
          <h4 className="text-xl font-bold text-black dark:text-white">Platform Dispute Center</h4>
          <p className="mt-1 text-sm font-medium text-gray-500 dark:text-dark-6">
            Centralized ticketing area for fraud reports and contract disputes
          </p>
        </div>
        <div className="grid gap-2 sm:grid-cols-2 xl:flex xl:items-center">
          <input
            type="text"
            placeholder="Search tickets..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full max-w-xs rounded-xl border border-stroke bg-gray-1 px-4 py-2.5 text-black outline-none transition focus:border-primary dark:border-dark-3 dark:bg-dark dark:text-white"
          />
          <select
            value={statusFilter}
            onChange={(event) => setStatusFilter(event.target.value)}
            className="rounded-xl border border-stroke bg-gray-1 px-4 py-2.5 text-sm text-black outline-none transition focus:border-primary dark:border-dark-3 dark:bg-dark dark:text-white"
          >
            <option value="ACTIVE">Active tickets</option>
            <option value="ALL">All statuses</option>
            <option value="OPEN">Open</option>
            <option value="UNDER_REVIEW">Under review</option>
            <option value="RESOLVED">Resolved</option>
            <option value="DISMISSED">Dismissed</option>
          </select>
          <select
            value={resourceFilter}
            onChange={(event) => setResourceFilter(event.target.value)}
            className="rounded-xl border border-stroke bg-gray-1 px-4 py-2.5 text-sm text-black outline-none transition focus:border-primary dark:border-dark-3 dark:bg-dark dark:text-white"
          >
            <option value="ALL">All resources</option>
            {resourceTypes.map((type) => (
              <option key={type} value={type}>
                {type}
              </option>
            ))}
          </select>
          <button
            type="button"
            onClick={() => {
              setSearch('');
              setStatusFilter('ACTIVE');
              setResourceFilter('ALL');
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
            ) : filteredTickets.length === 0 ? (
              <tr>
                <td colSpan={5} className="py-10 text-center text-gray-500">
                  No dispute tickets match the selected filters.
                </td>
              </tr>
            ) : (
              filteredTickets.map((ticket) => (
                <tr key={ticket.id} className="border-b border-stroke/80 dark:border-dark-3">
                  <td className="py-5 px-4 pl-6">
                    <h5 className="font-medium text-black dark:text-white">
                      Report #{ticket.id.slice(0, 8)}
                    </h5>
                    <p className="mt-1 line-clamp-2 text-sm text-gray-500 dark:text-dark-6">
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
                      <Button
                        label="Review"
                        variant="outlinePrimary"
                        size="small"
                        icon={<EyeIcon />}
                        onClick={() => setSelectedTicket(ticket)}
                      />
                      {ticket.resourceType === 'DEAL' && (
                        <Button
                          label="Pause Deal"
                          variant="outlinePrimary"
                          size="small"
                          onClick={() => pauseDeal(ticket.resourceId, 'Dispute review')}
                        />
                      )}
                      {ticket.resourceType === 'PROFILE' && (
                        <Button
                          label="Suspend"
                          variant="outlinePrimary"
                          size="small"
                          onClick={() => suspendUser(ticket.resourceId, ticket.reason)}
                        />
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
        <div className="mt-8 border-t border-stroke pt-6 dark:border-dark-3">
          <h5 className="mb-4 text-lg font-bold text-black dark:text-white">
            Reviewing Ticket #{selectedTicket.id.slice(0, 8)}
          </h5>
          <div className="space-y-4">
            <div>
              <p className="text-sm font-medium text-gray-700 dark:text-gray-300">Reason</p>
              <p className="mt-1 text-gray-600 dark:text-dark-6">{selectedTicket.reason}</p>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium text-gray-700 dark:text-gray-300 block mb-2">
                  New Status
                </label>
                <select
                  value={newStatus}
                  onChange={(e) =>
                    setNewStatus(
                      e.target.value as 'RESOLVED' | 'DISMISSED' | 'UNDER_REVIEW',
                    )
                  }
                  className="w-full rounded-lg border border-stroke bg-gray-1 px-4 py-2 text-black outline-none transition focus:border-primary dark:border-dark-3 dark:bg-dark dark:text-white"
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
                className="w-full rounded-lg border border-stroke bg-gray-1 px-4 py-2 text-black outline-none transition focus:border-primary dark:border-dark-3 dark:bg-dark dark:text-white"
                rows={4}
                placeholder="Add resolution notes..."
              />
            </div>
            <div className="flex gap-3">
              <Button
                label="Update Ticket"
                variant="primary"
                size="small"
                onClick={updateTicket}
              />
              <Button
                label="Cancel"
                variant="outlinePrimary"
                size="small"
                onClick={() => {
                  setSelectedTicket(null);
                  setResolution('');
                }}
              />
            </div>
          </div>
        </div>
      )}
    </div>
    </div>
  );
}
