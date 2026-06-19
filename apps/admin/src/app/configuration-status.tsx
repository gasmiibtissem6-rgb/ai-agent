"use client";

import { useEffect, useState } from "react";
import {
  apiProbes,
  apiUrl,
  configurationStatusUrl,
  type ConfigurationStatus,
} from "@/lib/api-foundation";

type ConnectionState =
  | { state: "loading" }
  | { state: "connected"; data: ConfigurationStatus }
  | { state: "unreachable"; error: string };

type ProbeResult = {
  state: "idle" | "loading" | "success" | "error";
  message?: string;
  checkedAt?: string;
};

export function ConfigurationStatusPanel() {
  const [connection, setConnection] = useState<ConnectionState>({
    state: "loading",
  });
  const [probeResults, setProbeResults] = useState<Record<string, ProbeResult>>(
    {},
  );

  const checkConfiguration = () => {
    const controller = new AbortController();
    setConnection({ state: "loading" });

    fetch(configurationStatusUrl, {
      cache: "no-store",
      signal: controller.signal,
    })
      .then(async (response) => {
        if (!response.ok) {
          throw new Error(`API returned HTTP ${response.status}`);
        }

        return (await response.json()) as ConfigurationStatus;
      })
      .then((data) => setConnection({ state: "connected", data }))
      .catch((error: unknown) => {
        if (controller.signal.aborted) {
          return;
        }

        setConnection({
          state: "unreachable",
          error:
            error instanceof Error
              ? error.message
              : "The API did not return a readable response.",
        });
      });

    return controller;
  };

  useEffect(() => {
    const controller = checkConfiguration();

    return () => controller.abort();
  }, []);

  const runProbe = async (endpoint: string) => {
    setProbeResults((current) => ({
      ...current,
      [endpoint]: { state: "loading" },
    }));

    try {
      const response = await fetch(apiUrl(endpoint), { cache: "no-store" });
      const payload = (await response.json().catch(() => null)) as unknown;

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      setProbeResults((current) => ({
        ...current,
        [endpoint]: {
          state: "success",
          message:
            payload && typeof payload === "object"
              ? "Response received and parsed"
              : "Response received",
          checkedAt: new Date().toLocaleTimeString(),
        },
      }));
    } catch (error: unknown) {
      setProbeResults((current) => ({
        ...current,
        [endpoint]: {
          state: "error",
          message:
            error instanceof Error
              ? error.message
              : "No readable API response received.",
          checkedAt: new Date().toLocaleTimeString(),
        },
      }));
    }
  };

  if (connection.state === "loading") {
    return (
      <div className="rounded-lg border border-slate-200 bg-white p-5">
        <StatusHeader
          actionLabel="Checking..."
          disabled
          onAction={() => undefined}
          tone="slate"
        />
        <p className="mt-3 text-lg font-semibold">Waiting for backend...</p>
      </div>
    );
  }

  if (connection.state === "unreachable") {
    return (
      <div className="rounded-lg border border-amber-300 bg-amber-50 p-5">
        <StatusHeader
          actionLabel="Retry check"
          onAction={checkConfiguration}
          title="Backend unreachable"
          tone="amber"
        />
        <h3 className="mt-3 text-xl font-semibold text-amber-950">
          No API response received
        </h3>
        <p className="mt-2 leading-7 text-amber-900">{connection.error}</p>
        <p className="mt-3 text-sm text-amber-900">
          Start the NestJS API and confirm this URL responds:{" "}
          <code>{configurationStatusUrl}</code>
        </p>
      </div>
    );
  }

  return (
    <div className="rounded-lg border border-emerald-300 bg-emerald-50 p-5">
      <p className="text-sm font-semibold uppercase tracking-wide text-emerald-700">
        Backend connected
      </p>
      <h3 className="mt-3 text-xl font-semibold text-emerald-950">
        API response received
      </h3>
      <button
        className="mt-4 rounded-md bg-emerald-700 px-4 py-2 text-sm font-semibold text-white transition hover:bg-emerald-800"
        onClick={checkConfiguration}
        type="button"
      >
        Refresh configuration check
      </button>
      <p className="mt-2 leading-7 text-emerald-900">
        {connection.data.message}
      </p>
      <dl className="mt-4 grid gap-3 sm:grid-cols-3">
        <div>
          <dt className="text-xs font-semibold uppercase text-emerald-700">
            Service
          </dt>
          <dd className="mt-1 font-medium">{connection.data.serviceName}</dd>
        </div>
        <div>
          <dt className="text-xs font-semibold uppercase text-emerald-700">
            Version
          </dt>
          <dd className="mt-1 font-medium">{connection.data.apiVersion}</dd>
        </div>
        <div>
          <dt className="text-xs font-semibold uppercase text-emerald-700">
            Environment
          </dt>
          <dd className="mt-1 font-medium">{connection.data.environment}</dd>
        </div>
      </dl>
      <div className="mt-5 grid gap-3">
        {connection.data.checks.map((check) => (
          <div
            className="rounded-md border border-emerald-200 bg-white/70 p-3"
            key={check.name}
          >
            <div className="flex items-center justify-between gap-3">
              <p className="font-medium text-slate-950">{check.name}</p>
              <span className="rounded-full bg-slate-900 px-2.5 py-1 text-xs font-semibold uppercase text-white">
                {check.status}
              </span>
            </div>
            <p className="mt-1 text-sm leading-6 text-slate-700">
              {check.detail}
            </p>
          </div>
        ))}
      </div>
      <div className="mt-6 border-t border-emerald-200 pt-5">
        <h4 className="text-lg font-semibold text-emerald-950">
          Functional API probes
        </h4>
        <p className="mt-1 text-sm leading-6 text-emerald-900">
          Use these buttons to confirm that the admin dashboard can reach each
          prepared backend boundary.
        </p>
        <div className="mt-4 grid gap-3 md:grid-cols-2">
          {apiProbes.map((probe) => {
            const result = probeResults[probe.endpoint] ?? { state: "idle" };
            const isLoading = result.state === "loading";
            const isSuccess = result.state === "success";
            const isError = result.state === "error";

            return (
              <div
                className="rounded-md border border-emerald-200 bg-white p-4"
                key={probe.endpoint}
              >
                <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                  <div>
                    <p className="font-semibold text-slate-950">
                      {probe.label}
                    </p>
                    <p className="mt-1 text-sm text-blue-700">
                      {probe.endpoint}
                    </p>
                    <p className="mt-2 text-sm leading-6 text-slate-600">
                      {probe.description}
                    </p>
                  </div>
                  <button
                    className="rounded-md bg-slate-950 px-3 py-2 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:cursor-wait disabled:bg-slate-400"
                    disabled={isLoading}
                    onClick={() => void runProbe(probe.endpoint)}
                    type="button"
                  >
                    {isLoading ? "Testing..." : "Test"}
                  </button>
                </div>
                {result.state !== "idle" ? (
                  <p
                    className={`mt-3 rounded-md px-3 py-2 text-sm font-medium ${
                      isSuccess
                        ? "bg-emerald-100 text-emerald-900"
                        : isError
                          ? "bg-amber-100 text-amber-950"
                          : "bg-slate-100 text-slate-700"
                    }`}
                  >
                    {isSuccess ? "Connected" : isError ? "Failed" : "Running"}{" "}
                    {result.message ? `- ${result.message}` : ""}
                    {result.checkedAt ? ` at ${result.checkedAt}` : ""}
                  </p>
                ) : null}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

function StatusHeader({
  actionLabel,
  disabled = false,
  onAction,
  title = "Checking API response",
  tone,
}: {
  actionLabel: string;
  disabled?: boolean;
  onAction: () => void;
  title?: string;
  tone: "amber" | "slate";
}) {
  const buttonClass =
    tone === "amber"
      ? "bg-amber-700 hover:bg-amber-800 disabled:bg-amber-300"
      : "bg-slate-700 hover:bg-slate-800 disabled:bg-slate-300";

  return (
    <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <p
        className={`text-sm font-semibold uppercase tracking-wide ${
          tone === "amber" ? "text-amber-700" : "text-slate-500"
        }`}
      >
        {title}
      </p>
      <button
        className={`rounded-md px-4 py-2 text-sm font-semibold text-white transition ${buttonClass}`}
        disabled={disabled}
        onClick={onAction}
        type="button"
      >
        {actionLabel}
      </button>
    </div>
  );
}
