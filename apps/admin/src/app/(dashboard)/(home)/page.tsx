"use client";

import { getApiBaseUrl } from "@/lib/api-base";
import Link from "next/link";
import { useEffect, useState } from "react";

type DashboardSnapshot = {
  usersTotal: number | null;
  pendingKyc: number | null;
  dealsCount: number | null;
  openDisputes: number | null;
};

const API_BASE_URL = getApiBaseUrl(
  process.env.NEXT_PUBLIC_API_BASE_URL ?? process.env.NEXT_PUBLIC_API_URL,
);

const quickLinks = [
  {
    href: "/admin/users",
    title: "User Directory",
    description: "Search users, inspect trust counters, and manage admin roles.",
  },
  {
    href: "/admin/kyc",
    title: "KYC Queue",
    description: "Process pending identity submissions and track review throughput.",
  },
  {
    href: "/admin/deals",
    title: "Deals Ledger",
    description: "Monitor active deal states, owners, and attached records.",
  },
  {
    href: "/admin/dispute-center",
    title: "Dispute Center",
    description: "Review reports and enforce platform actions quickly.",
  },
];

function asObject(value: unknown): Record<string, unknown> | null {
  if (!value || typeof value !== "object") {
    return null;
  }

  return value as Record<string, unknown>;
}

function readItemsCount(payload: unknown): number {
  const payloadObj = asObject(payload);
  const data = payloadObj && "data" in payloadObj ? payloadObj.data : payload;
  const dataObj = asObject(data);

  if (Array.isArray(data)) {
    return data.length;
  }

  if (Array.isArray(dataObj?.items)) {
    return dataObj.items.length;
  }

  if (Array.isArray(dataObj?.submissions)) {
    return dataObj.submissions.length;
  }

  if (typeof dataObj?.total === "number") {
    return dataObj.total;
  }

  if (typeof payloadObj?.total === "number") {
    return payloadObj.total;
  }

  return 0;
}

function formatMetric(value: number | null, loading: boolean) {
  if (loading) {
    return "...";
  }

  if (value === null) {
    return "--";
  }

  return value.toLocaleString();
}

function getReliabilityScore(snapshot: DashboardSnapshot) {
  const users = snapshot.usersTotal ?? 0;
  const kyc = snapshot.pendingKyc ?? 0;
  const disputes = snapshot.openDisputes ?? 0;

  const score = Math.max(58, 94 - Math.min(kyc * 2 + disputes * 3, 35));
  const exposure = Math.max(0, Math.min(100, Math.round((disputes / Math.max(users, 1)) * 100)));

  return {
    score,
    exposure,
  };
}

function buildPriorityItems(snapshot: DashboardSnapshot) {
  const kyc = snapshot.pendingKyc ?? 0;
  const disputes = snapshot.openDisputes ?? 0;

  return [
    {
      title: "KYC Throughput",
      value: kyc,
      tone:
        kyc >= 15
          ? "bg-rose-50 text-rose-700 border-rose-200"
          : kyc >= 6
            ? "bg-amber-50 text-amber-700 border-amber-200"
            : "bg-emerald-50 text-emerald-700 border-emerald-200",
      summary:
        kyc >= 15
          ? "High backlog detected. Assign additional reviewers today."
          : kyc >= 6
            ? "Moderate queue. Maintain two-pass daily review."
            : "Queue healthy. Current SLA is stable.",
    },
    {
      title: "Dispute Response",
      value: disputes,
      tone:
        disputes >= 8
          ? "bg-rose-50 text-rose-700 border-rose-200"
          : disputes >= 4
            ? "bg-amber-50 text-amber-700 border-amber-200"
            : "bg-emerald-50 text-emerald-700 border-emerald-200",
      summary:
        disputes >= 8
          ? "Escalation volume is elevated. Prioritize top-risk tickets."
          : disputes >= 4
            ? "Activity is moderate. Keep 24h response target."
            : "Response load is low. Maintain proactive monitoring.",
    },
  ];
}

export default function Home() {
  const [loading, setLoading] = useState(true);
  const [fetchError, setFetchError] = useState<string | null>(null);
  const [snapshot, setSnapshot] = useState<DashboardSnapshot>({
    usersTotal: null,
    pendingKyc: null,
    dealsCount: null,
    openDisputes: null,
  });

  useEffect(() => {
    const token = localStorage.getItem("admin_token");

    const headers: HeadersInit = {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token ?? ""}`,
    };

    async function loadDashboardSnapshot() {
      try {
        setLoading(true);
        setFetchError(null);

        if (!token || token === "undefined" || token === "null") {
          throw new Error("MISSING_TOKEN");
        }

        const [usersRes, kycRes, dealsRes, disputesRes] = await Promise.all([
          fetch(`${API_BASE_URL}/admin/users?page=1&limit=1`, {
            headers,
            cache: "no-store",
          }),
          fetch(`${API_BASE_URL}/admin/kyc/pending`, {
            headers,
            cache: "no-store",
          }),
          fetch(`${API_BASE_URL}/admin/deals`, {
            headers,
            cache: "no-store",
          }),
          fetch(`${API_BASE_URL}/admin/dispute-center`, {
            headers,
            cache: "no-store",
          }),
        ]);

        const [usersData, kycData, dealsData, disputesData] = await Promise.all([
          usersRes.ok ? usersRes.json() : null,
          kycRes.ok ? kycRes.json() : null,
          dealsRes.ok ? dealsRes.json() : null,
          disputesRes.ok ? disputesRes.json() : null,
        ]);

        const disputeItems = (disputesData?.data?.items ??
          disputesData?.items ??
          disputesData?.data ??
          disputesData ?? []) as Array<{ status?: string }>;

        const openDisputes = Array.isArray(disputeItems)
          ? disputeItems.filter((ticket) => ticket?.status !== "RESOLVED").length
          : readItemsCount(disputesData);

        setSnapshot({
          usersTotal: usersData ? readItemsCount(usersData) : null,
          pendingKyc: kycData ? readItemsCount(kycData) : null,
          dealsCount: dealsData ? readItemsCount(dealsData) : null,
          openDisputes,
        });

        if (!usersRes.ok || !kycRes.ok || !dealsRes.ok || !disputesRes.ok) {
          setFetchError(
            "Some dashboard metrics could not be loaded. Core pages are still available.",
          );
        }
      } catch {
        setFetchError(
          !token || token === "undefined" || token === "null"
            ? "Admin session is missing. Please sign in again."
            : "Unable to load dashboard metrics. Check backend connectivity and admin token.",
        );
      } finally {
        setLoading(false);
      }
    }

    loadDashboardSnapshot();
  }, []);

  const reliability = getReliabilityScore(snapshot);
  const priorityItems = buildPriorityItems(snapshot);

  const metrics = [
    {
      title: "Total Users",
      value: snapshot.usersTotal,
      accent: "from-slate-900 to-slate-700",
      note: "Platform accounts",
      href: "/admin/users",
    },
    {
      title: "Pending KYC",
      value: snapshot.pendingKyc,
      accent: "from-amber-600 to-amber-500",
      note: "Verification queue",
      href: "/admin/kyc",
    },
    {
      title: "Deals",
      value: snapshot.dealsCount,
      accent: "from-blue-700 to-indigo-600",
      note: "Visible in ledger",
      href: "/admin/deals",
    },
    {
      title: "Open Disputes",
      value: snapshot.openDisputes,
      accent: "from-rose-700 to-rose-500",
      note: "Needs active handling",
      href: "/admin/dispute-center",
    },
  ];

  return (
    <div className="space-y-7">
      <section className="relative overflow-hidden rounded-3xl border border-slate-200 bg-white p-7 shadow-sm dark:border-dark-3 dark:bg-dark-2 md:p-9">
        <div className="pointer-events-none absolute -left-16 -top-20 h-56 w-56 rounded-full bg-sky-100/60 blur-3xl dark:bg-sky-900/30" />
        <div className="pointer-events-none absolute -right-16 -bottom-24 h-64 w-64 rounded-full bg-indigo-100/60 blur-3xl dark:bg-indigo-900/30" />

        <div className="relative grid gap-6 lg:grid-cols-[1.4fr_1fr] lg:items-end">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.24em] text-slate-500 dark:text-dark-6">
              IDEAL OPERATIONS HUB
            </p>
            <h1 className="mt-3 text-3xl font-bold tracking-tight text-slate-950 dark:text-white md:text-4xl">
              Executive Overview
            </h1>
            <p className="mt-4 max-w-2xl text-sm leading-7 text-slate-600 dark:text-dark-7 md:text-base">
              Consolidated command surface for moderation, verification, deal flow,
              and dispute resolution across the IDEAL platform.
            </p>
          </div>

          <div className="rounded-2xl border border-slate-200 bg-slate-950 p-5 text-white shadow-md dark:border-slate-800 dark:bg-slate-900">
            <p className="text-xs uppercase tracking-[0.2em] text-slate-300 dark:text-slate-400">
              Reliability Index
            </p>
            <div className="mt-3 flex items-end justify-between">
              <p className="text-4xl font-semibold">
                {loading ? "..." : `${reliability.score}%`}
              </p>
              <p className="text-xs text-slate-300 dark:text-slate-400">Daily health estimate</p>
            </div>
            <div className="mt-4 h-2 rounded-full bg-white/15">
              <div
                className="h-2 rounded-full bg-gradient-to-r from-emerald-300 to-sky-300 transition-all duration-500"
                style={{ width: `${loading ? 25 : reliability.score}%` }}
              />
            </div>
            <p className="mt-3 text-xs text-slate-300 dark:text-slate-400">
              Dispute exposure: {loading ? "..." : `${reliability.exposure}%`} of active users.
            </p>
          </div>
        </div>
      </section>

      {fetchError && (
        <section className="rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800 dark:border-amber-900 dark:bg-amber-950/30 dark:text-amber-300">
          {fetchError}
        </section>
      )}

      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {metrics.map((metric) => (
          <Link
            key={metric.title}
            href={metric.href}
            className="group rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition duration-200 hover:-translate-y-0.5 hover:border-slate-300 hover:shadow-md dark:border-dark-3 dark:bg-dark-2 dark:hover:border-dark-4"
          >
            <div className={`inline-flex rounded-full bg-gradient-to-r px-3 py-1 text-xs font-medium text-white ${metric.accent}`}>
              {metric.title}
            </div>
            <p className="mt-4 text-3xl font-semibold tracking-tight text-slate-950 dark:text-white">
              {formatMetric(metric.value, loading)}
            </p>
            <p className="mt-1 text-sm text-slate-500 dark:text-dark-6">{metric.note}</p>
            <p className="mt-4 text-xs font-medium uppercase tracking-[0.16em] text-slate-400 transition group-hover:text-slate-600 dark:text-dark-6 dark:group-hover:text-dark-7">
              Open section
            </p>
          </Link>
        ))}
      </section>

      <section className="grid gap-4 xl:grid-cols-[1.25fr_1fr]">
        <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm dark:border-dark-3 dark:bg-dark-2 md:p-7">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-semibold text-slate-950 dark:text-white">
              Priority Watchlist
            </h2>
            <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-medium text-slate-600 dark:bg-dark-3 dark:text-dark-7">
              Today
            </span>
          </div>

          <div className="mt-5 space-y-4">
            {priorityItems.map((item) => (
              <div
                key={item.title}
                className="rounded-2xl border border-slate-200 bg-slate-50/70 p-4 dark:border-dark-3 dark:bg-dark"
              >
                <div className="flex items-center justify-between gap-3">
                  <p className="text-sm font-semibold text-slate-900 dark:text-white">{item.title}</p>
                  <span className={`rounded-full border px-2.5 py-1 text-xs font-semibold ${item.tone}`}>
                    {loading ? "..." : `${item.value} open`}
                  </span>
                </div>
                <p className="mt-2 text-sm leading-6 text-slate-600 dark:text-dark-7">{item.summary}</p>
              </div>
            ))}
          </div>
        </div>

        <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm dark:border-dark-3 dark:bg-dark-2 md:p-7">
          <h2 className="text-xl font-semibold text-slate-950 dark:text-white">Quick Actions</h2>
          <p className="mt-2 text-sm text-slate-500 dark:text-dark-6">
            Jump directly to high-frequency workflows.
          </p>

          <div className="mt-5 grid gap-3">
            {quickLinks.map((area) => (
              <Link
                key={area.href}
                href={area.href}
                className="rounded-2xl border border-slate-200 bg-slate-50 p-4 transition hover:border-slate-300 hover:bg-white dark:border-dark-3 dark:bg-dark dark:hover:border-dark-4 dark:hover:bg-dark-3"
              >
                <h3 className="text-base font-semibold text-slate-900 dark:text-white">{area.title}</h3>
                <p className="mt-1 text-sm leading-6 text-slate-600 dark:text-dark-7">
                  {area.description}
                </p>
              </Link>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
}
