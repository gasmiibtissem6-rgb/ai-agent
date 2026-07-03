"use client";

import { useEffect, useState } from "react";
import { adminService } from "@/services/adminService";

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

export default function KycQueuePage() {
  const [submissions, setSubmissions] = useState<KycSubmission[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [reviewingId, setReviewingId] = useState<string | null>(null);
  
  // 🚀 FIXED: Store typing state independently for each row via submission ID
  const [rejectionReasons, setRejectionReasons] = useState<Record<string, string>>({});

  const loadQueue = async () => {
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
    } catch (err: any) {
      setError(err.message || "Failed to load the identity validation queue.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadQueue();
  }, []);

  const handleReview = async (id: string, status: "APPROVED" | "REJECTED") => {
    // 🚀 FIXED: Retrieve the reason explicitly from our dictionary mapping state
    const currentReason = rejectionReasons[id] || "";

    if (status === "REJECTED" && !currentReason.trim()) {
      alert("Please provide an administrative reason for rejecting this document verification.");
      return;
    }

    try {
      setReviewingId(id);
      await adminService.reviewKycSubmission(id, status, currentReason);
      
      // Clear out the reason string for this row upon completion
      setRejectionReasons(prev => {
        const copy = { ...prev };
        delete copy[id];
        return copy;
      });
      
      await loadQueue();
    } catch (err: any) {
      alert(err.message || "Failed to submit verification action.");
    } finally {
      setReviewingId(null);
    }
  };

  if (loading) {
    return (
      <div className="flex h-48 items-center justify-center font-medium text-black dark:text-white">
        Loading Verification Queue Metrics...
      </div>
    );
  }

  return (
    <div className="rounded-[10px] bg-white p-4 shadow-1 dark:bg-gray-dark dark:shadow-card sm:p-7.5">
      <div className="mb-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h4 className="text-xl font-bold text-black dark:text-white">
            KYC Identity Review Queue
          </h4>
          <p className="text-sm font-medium mt-1">
            Validate incoming user authentication documents to manage safety metrics.
          </p>
        </div>
      </div>

      {error && (
        <div className="mb-6 rounded-lg bg-red-50 p-4 text-sm text-red-600 dark:bg-red-950/20 dark:text-red-400">
          {error}
        </div>
      )}

      {submissions.length === 0 ? (
        <div className="text-center py-12 text-gray-500 dark:text-gray-400 border border-dashed border-gray-200 dark:border-gray-800 rounded-xl">
          🎉 Operational Queue Clear! No pending verification files require review.
        </div>
      ) : (
        <div className="max-w-full overflow-x-auto">
          <table className="w-full table-auto">
            <thead>
              <tr className="bg-gray-2 text-left dark:bg-meta-4">
                <th className="py-4 px-4 font-medium text-black dark:text-white pl-6">Applicant</th>
                <th className="py-4 px-4 font-medium text-black dark:text-white">Doc Type</th>
                <th className="py-4 px-4 font-medium text-black dark:text-white">ID Number</th>
                <th className="py-4 px-4 font-medium text-black dark:text-white">File Link</th>
                <th className="py-4 px-4 font-medium text-black dark:text-white text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              {submissions.map((sub) => (
                <tr key={sub.id} className="border-b border-[#eee] dark:border-strokedark">
                  <td className="py-5 px-4 pl-6">
                    <h5 className="font-medium text-black dark:text-white">
                      {sub.profile?.displayName || "Anonymous User"}
                    </h5>
                    <p className="text-xs text-gray-500">{sub.profile?.email}</p>
                  </td>
                  <td className="py-5 px-4 text-black dark:text-white text-sm">
                    <span className="rounded bg-gray-100 px-2.5 py-1 text-xs font-semibold uppercase dark:bg-gray-800">
                      {sub.idType}
                    </span>
                  </td>
                  <td className="py-5 px-4 text-black dark:text-white text-sm font-mono">
                    {sub.idNumber}
                  </td>
                  <td className="py-5 px-4 text-sm">
                    <a
                      href={sub.documentUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-primary hover:underline font-medium inline-flex items-center gap-1"
                    >
                      View File ↗
                    </a>
                  </td>
                  <td className="py-5 px-4">
                    <div className="flex flex-col gap-2 items-center justify-center">
                      <div className="flex gap-2">
                        <button
                          disabled={reviewingId !== null}
                          onClick={() => handleReview(sub.id, "APPROVED")}
                          className="rounded bg-green-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-green-700 transition disabled:opacity-50"
                        >
                          {reviewingId === sub.id ? "Processing..." : "Approve"}
                        </button>
                        <button
                          disabled={reviewingId !== null}
                          onClick={() => handleReview(sub.id, "REJECTED")}
                          className="rounded bg-red px-3 py-1.5 text-xs font-medium text-white hover:bg-red-hover transition disabled:opacity-50"
                        >
                          Reject
                        </button>
                      </div>
                      
                      {/* 🚀 FIXED: Value maps to individual key dictionary dynamically */}
                      <input
                        type="text"
                        placeholder="Reason if rejecting..."
                        value={rejectionReasons[sub.id] || ""}
                        onChange={(e) => 
                          setRejectionReasons((prev) => ({
                            ...prev,
                            [sub.id]: e.target.value,
                          }))
                        }
                        className="w-full max-w-[180px] rounded border-[1.5px] border-stroke bg-transparent px-2 py-1 text-xs outline-none transition focus:border-primary active:border-primary dark:border-form-strokedark dark:bg-form-input dark:focus:border-primary"
                      />
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}