"use client";

import { ThemeToggleSwitch } from "@/components/Layouts/header/theme-toggle";
import { getApiBaseUrl } from "@/lib/api-base";
import { useActionState } from "react";

const API_BASE_URL = getApiBaseUrl(process.env.NEXT_PUBLIC_API_BASE_URL);

export default function LoginPage() {
  const [errorMessage, submitAction, isPending] = useActionState(
    async (_previousState: string | null, formData: FormData) => {
      const email = String(formData.get("email") ?? "");
      const password = String(formData.get("password") ?? "");

      try {
        const res = await fetch(`${API_BASE_URL}/auth/login/admin`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email, password }),
          cache: "no-store",
        });

        if (!res.ok) {
          const errorData = await res.json().catch(() => ({}));
          return errorData.message || "Invalid administrative credentials.";
        }

        const resData = await res.json();
        const token =
          resData.data?.data?.token || resData.data?.token || resData.token;

        if (!token) {
          return "Login failed: No token received from server.";
        }

        localStorage.setItem("admin_token", token);
        document.cookie = `admin_token=${token}; path=/; max-age=86400; SameSite=Lax`;
        document.cookie = `token=${token}; path=/; max-age=86400; SameSite=Lax`;
        window.location.href = "/";

        return null;
      } catch {
        return "System network error. Check API configuration.";
      }
    },
    null,
  );

  return (
    <div className="min-h-screen bg-slate-100 px-4 py-6 text-slate-950 dark:bg-gray-dark dark:text-white sm:px-6">
      <div className="mx-auto flex max-w-6xl justify-end">
        <ThemeToggleSwitch />
      </div>

      <div className="mx-auto flex min-h-[calc(100vh-5rem)] max-w-6xl items-center justify-center">
        <section className="w-full max-w-[560px] rounded-[28px] border border-slate-200 bg-white p-8 shadow-lg dark:border-dark-3 dark:bg-dark-2 sm:p-10">
          <div className="mb-8">
            <h1 className="text-3xl font-bold tracking-tight text-slate-950 dark:text-white">
              Sign in
            </h1>
            <p className="mt-3 text-sm leading-6 text-slate-600 dark:text-dark-6">
              Enter your administrative credentials to continue.
            </p>
          </div>

          <form action={submitAction} className="space-y-5" autoComplete="off">
            {errorMessage && (
              <div className="rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700 dark:border-rose-900 dark:bg-rose-950/30 dark:text-rose-300">
                {errorMessage}
              </div>
            )}

            <div>
              <label
                htmlFor="email"
                className="mb-2 block text-xs font-semibold uppercase tracking-[0.18em] text-slate-500 dark:text-dark-6"
              >
                Email Address
              </label>
              <input
                id="email"
                name="email"
                type="email"
                required
                autoComplete="new-password"
                placeholder="admin@ideal.local"
                className="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3.5 text-slate-950 outline-none transition focus:border-primary focus:bg-white dark:border-dark-3 dark:bg-dark dark:text-white dark:focus:bg-dark"
              />
            </div>

            <div>
              <label
                htmlFor="password"
                className="mb-2 block text-xs font-semibold uppercase tracking-[0.18em] text-slate-500 dark:text-dark-6"
              >
                Password
              </label>
              <input
                id="password"
                name="password"
                type="password"
                required
                autoComplete="new-password"
                placeholder="Enter your password"
                className="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3.5 text-slate-950 outline-none transition focus:border-primary focus:bg-white dark:border-dark-3 dark:bg-dark dark:text-white dark:focus:bg-dark"
              />
            </div>

            <button
              type="submit"
              disabled={isPending}
              className="flex w-full items-center justify-center rounded-xl bg-slate-950 px-4 py-3.5 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60 dark:bg-primary dark:hover:bg-primary/90"
            >
              {isPending ? "Authenticating..." : "Sign in"}
            </button>
          </form>
        </section>
      </div>
    </div>
  );
}
