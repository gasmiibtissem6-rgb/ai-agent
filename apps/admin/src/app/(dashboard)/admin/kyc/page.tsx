"use client";

import { AdminPageHeader } from "@/components/Layouts/admin-page-header";
import { adminService } from "@/services/adminService";
import { useCallback, useEffect, useState } from "react";

interface KycSubmission {
  id: string;
  idNumber: string;
  idType: string;
  documentUrl: string;
  status: "PENDING" | "APPROVED" | "REJECTED";
  createdAt: string;
  profile: {
    id: string;
    email: string;
    displayName: string | null;
  };
}

function getErrorMessage(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback;
}

export default function KycQueuePage() {
  const [submissions, setSubmissions] = useState<KycSubmission[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [reviewingId, setReviewingId] = useState<string | null>(null);
  const [rejectionReasons, setRejectionReasons] = useState<Record<string, string>>({});
  const [actionError, setActionError] = useState<string | null>(null);
  const [documentFilter, setDocumentFilter] = useState("ALL");
  const [searchTerm, setSearchTerm] = useState("");

  const loadQueue = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const responsePayload = await adminService.getPendingKycQueue();
      const targetData = responsePayload?.data ? responsePayload.data : responsePayload;

      if (Array.isArray(targetData)) {
        setSubmissions(targetData);
      } else if (targetData && Array.isArray(targetData.submissions)) {
        setSubmissions(targetData.submissions);
      } else {
        setSubmissions([]);
      }
    } catch (err: unknown) {
      setError(getErrorMessage(err, "Failed to load the identity review queue."));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const timeout = window.setTimeout(() => {
      void loadQueue();
    }, 0);

    return () => window.clearTimeout(timeout);
  }, [loadQueue]);

  const handleReview = async (id: string, status: "APPROVED" | "REJECTED") => {
    const currentReason = rejectionReasons[id] || "";

    if (status === "REJECTED" && !currentReason.trim()) {
      setActionError("Add a rejection reason before rejecting this submission.");
      return;
    }

    try {
      setActionError(null);
      setReviewingId(id);
      await adminService.reviewKycSubmission(id, status, currentReason);
      setRejectionReasons((prev) => {
        const copy = { ...prev };
        delete copy[id];
        return copy;
      });
      await loadQueue();
    } catch (err: unknown) {
      setActionError(getErrorMessage(err, "Failed to submit verification action."));
    } finally {
      setReviewingId(null);
    }
  };

  const pendingCount = submissions.filter((sub) => sub.status === "PENDING").length;
  const activeReviewCount = reviewingId ? 1 : 0;
  const rejectionDraftCount = Object.values(rejectionReasons).filter((reason) =>
    reason.trim(),
  ).length;
  const documentTypeCount = new Set(submissions.map((sub) => sub.idType)).size;
  const documentTypes = Array.from(new Set(submissions.map((sub) => sub.idType))).sort();
  const filteredSubmissions = submissions.filter((sub) => {
    const query = searchTerm.trim().toLowerCase();
    const matchesSearch =
      !query ||
      (sub.profile?.displayName || "").toLowerCase().includes(query) ||
      (sub.profile?.email || "").toLowerCase().includes(query) ||
      sub.idNumber.toLowerCase().includes(query);
    const matchesDocument = documentFilter === "ALL" || sub.idType === documentFilter;

    return matchesSearch && matchesDocument;
  });

  return (
    <div className="space-y-7">
      <AdminPageHeader
        eyebrow="VERIFICATION DESK"
        title="KYC Review Queue"
        description="Process identity submissions, inspect document types, and keep verification decisions moving without losing audit context."
        panelLabel="Queue Load"
        panelValue={loading ? "..." : submissions.length}
        panelNote="Pending files"
        panelSubtext={`${documentTypeCount} document type${documentTypeCount === 1 ? "" : "s"} represented in the current queue.`}
        panelBarValue={submissions.length ? Math.min((pendingCount / submissions.length) * 100, 100) : 12}
        metrics={[
          {
            label: "Pending",
            value: loading ? "..." : pendingCount,
            note: "Awaiting decision",
            accent: "from-amber-600 to-amber-500",
          },
          {
            label: "Reviewing",
            value: activeReviewCount,
            note: "Action in progress",
            accent: "from-blue-700 to-indigo-600",
          },
          {
            label: "Doc Types",
            value: loading ? "..." : documentTypeCount,
            note: "Identity formats",
            accent: "from-slate-900 to-slate-700",
          },
          {
            label: "Draft Reasons",
            value: rejectionDraftCount,
            note: "Prepared rejection notes",
            accent: "from-rose-700 to-rose-500",
          },
        ]}
        tone="amber"
        compact
      />

      <div className="rounded-[20px] border border-stroke bg-white px-5 pb-3 pt-6 shadow-card-2 dark:border-dark-3 dark:bg-dark-2 sm:px-7.5">
      <div className="mb-6 flex flex-col gap-4 xl:flex-row xl:items-end xl:justify-between">
        <div>
          <h4 className="text-xl font-bold text-black dark:text-white">
            KYC Review Queue
          </h4>
          <p className="mt-1 text-sm font-medium text-gray-500 dark:text-dark-6">
            Review pending identity documents and submit verification decisions.
          </p>
        </div>
        <div className="grid gap-2 sm:grid-cols-2 xl:flex xl:items-center">
        <input
          type="search"
          placeholder="Search applicant or ID"
          value={searchTerm}
          onChange={(event) => setSearchTerm(event.target.value)}
          className="rounded-xl border border-stroke bg-gray-1 px-4 py-2.5 text-sm text-black outline-none transition focus:border-primary dark:border-dark-3 dark:bg-dark dark:text-white"
        />
        <select
          value={documentFilter}
          onChange={(event) => setDocumentFilter(event.target.value)}
          className="rounded-xl border border-stroke bg-gray-1 px-4 py-2.5 text-sm text-black outline-none transition focus:border-primary dark:border-dark-3 dark:bg-dark dark:text-white"
        >
          <option value="ALL">All documents</option>
          {documentTypes.map((type) => (
            <option key={type} value={type}>
              {type}
            </option>
          ))}
        </select>
        <button
          type="button"
          onClick={() => {
            setSearchTerm("");
            setDocumentFilter("ALL");
          }}
          className="rounded-xl border border-stroke px-4 py-2.5 text-sm font-semibold text-black transition hover:bg-gray-100 dark:border-dark-3 dark:text-white dark:hover:bg-dark"
        >
          Reset
        </button>
          <button
          type="button"
          onClick={() => void loadQueue()}
          disabled={loading}
          className="inline-flex items-center justify-center rounded-lg border border-stroke px-4 py-2 text-sm font-medium text-black transition hover:bg-gray-100 disabled:opacity-50 dark:border-dark-3 dark:text-white dark:hover:bg-dark"
        >
          Refresh
        </button>
        </div>
      </div>

      {(error || actionError) && (
        <div className="mb-6 rounded-lg bg-rose-50 p-4 text-sm text-rose-600 dark:bg-rose-950/20 dark:text-rose-400">
          {error || actionError}
        </div>
      )}

      <div className="max-w-full overflow-x-auto">
        <table className="w-full table-auto">
          <thead>
            <tr className="bg-gray-2 text-left dark:bg-dark">
              <th className="py-4 px-4 font-medium text-black dark:text-white pl-6">Applicant</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">Document Type</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">ID Number</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white">File</th>
              <th className="py-4 px-4 font-medium text-black dark:text-white text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading && submissions.length === 0 ? (
              <tr>
                <td colSpan={5} className="py-10 text-center text-gray-500 dark:text-dark-6">
                  Loading verification queue...
                </td>
              </tr>
            ) : filteredSubmissions.length === 0 ? (
              <tr>
                <td colSpan={5} className="py-10 text-center text-gray-500 dark:text-dark-6">
                  No verification files match the selected filters.
                </td>
              </tr>
            ) : (
              filteredSubmissions.map((sub) => (
                <tr key={sub.id} className="border-b border-stroke/80 dark:border-dark-3">
                  <td className="py-5 px-4 pl-6">
                    <h5 className="font-medium text-black dark:text-white">
                      {sub.profile?.displayName || "Anonymous User"}
                    </h5>
                    <p className="text-sm text-gray-500 dark:text-dark-6">{sub.profile?.email}</p>
                  </td>
                  <td className="py-5 px-4 text-sm text-black dark:text-white">
                    <span className="rounded bg-gray-100 px-2.5 py-1 text-xs font-semibold uppercase dark:bg-dark dark:text-dark-7">
                      {sub.idType}
                    </span>
                  </td>
                  <td className="py-5 px-4 font-mono text-sm text-black dark:text-white">
                    {sub.idNumber}
                  </td>
                  <td className="py-5 px-4 text-sm">
                    <a
                      href={sub.documentUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="font-medium text-primary hover:underline"
                    >
                      View file
                    </a>
                  </td>
                  <td className="py-5 px-4">
                    <div className="ml-auto flex max-w-[360px] flex-col items-end gap-2">
                      <div className="flex gap-2">
                        <button
                          disabled={reviewingId !== null}
                          onClick={() => void handleReview(sub.id, "APPROVED")}
                          className="rounded-lg bg-emerald-600 px-3 py-2 text-xs font-semibold text-white transition hover:bg-emerald-700 disabled:opacity-50"
                        >
                          {reviewingId === sub.id ? "Processing" : "Approve"}
                        </button>
                        <button
                          disabled={reviewingId !== null}
                          onClick={() => void handleReview(sub.id, "REJECTED")}
                          className="rounded-lg bg-rose-600 px-3 py-2 text-xs font-semibold text-white transition hover:bg-rose-700 disabled:opacity-50"
                        >
                          Reject
                        </button>
                      </div>
                      <input
                        type="text"
                        placeholder="Rejection reason"
                        value={rejectionReasons[sub.id] || ""}
                        onChange={(e) =>
                          setRejectionReasons((prev) => ({
                            ...prev,
                            [sub.id]: e.target.value,
                          }))
                        }
                        className="w-full rounded-lg border border-stroke bg-gray-1 px-3 py-2 text-xs text-black outline-none transition focus:border-primary dark:border-dark-3 dark:bg-dark dark:text-white"
                      />
                    </div>
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
