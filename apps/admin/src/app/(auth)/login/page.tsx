"use client";

import { useActionState } from "react";
import { useRouter } from "next/navigation";
import { getApiBaseUrl } from "@/lib/api-base";

const API_BASE_URL = getApiBaseUrl(process.env.NEXT_PUBLIC_API_BASE_URL);

export default function LoginPage() {
  const router = useRouter();

  const [errorMessage, submitAction, isPending] = useActionState(
    async (previousState: string | null, formData: FormData) => {
      const email = formData.get("email") as string;
      const password = formData.get("password") as string;

      // 🔍 DEBUG STEP 1: Check your terminal/browser console when you click submit.
      // If this prints "admin@api.com" but you typed something else, your browser's
      // password manager/autofill is hijacking the form submission at the last millisecond.
      console.log("SUBMITTING -> Email:", email, "Password:", password);

      try {
        const res = await fetch(`${API_BASE_URL}/auth/login/admin`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email, password }),
          // Ensure the server can set an HttpOnly cookie on successful login
          credentials: 'include',
          cache: "no-store",
        });

        if (!res.ok) {
          const errorData = await res.json().catch(() => ({}));
          return errorData.message || "Invalid administrative credentials.";
        }

        // Inside your LoginPage try block:
        // Inside LoginPage try block...
        // Inside your LoginPage try block...
        const resData = await res.json();

        const token =
          resData.data?.data?.token || resData.data?.token || resData.token;

        if (!token) {
          return "Login failed: No token received from server.";
        }

        // Server should set HttpOnly cookie; client should NOT store the token in localStorage.
        // Force a hard navigation to refresh server-protected routes.
        window.location.href = "/";

        return null;
      } catch {
        return "System network error. Check API configuration.";
      }
    },
    null,
  );

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 px-4 py-12 sm:px-6 lg:px-8">
      <div className="w-full max-w-md space-y-8 rounded-xl border border-gray-200 bg-white p-8 shadow-sm">
        <div className="text-center">
          <h2 className="text-3xl font-extrabold tracking-tight text-gray-900">
            IDEAL Console
          </h2>
          <p className="mt-2 text-sm text-gray-500">
            Sign in with your admin privileges
          </p>
        </div>

        {/* Added autoComplete="off" to stop aggressive browser autofills from hijacking */}
        <form
          action={submitAction}
          className="mt-8 space-y-6"
          autoComplete="off"
        >
          {errorMessage && (
            <div className="rounded-md bg-red-50 p-3 text-sm text-red-600 border border-red-200">
              {errorMessage}
            </div>
          )}

          <div className="space-y-4 rounded-md shadow-sm">
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase">
                Email address
              </label>
              <input
                name="email"
                type="email"
                required
                autoComplete="new-password" // Hack to stop Chrome from autofilling emails
                className="relative block w-full rounded-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
              />
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-500 uppercase">
                Password
              </label>
              <input
                name="password"
                type="password"
                required
                autoComplete="new-password"
                className="relative block w-full rounded-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
              />
            </div>
          </div>

          <div>
            <button
              type="submit"
              disabled={isPending}
              className="group relative flex w-full justify-center rounded-md border border-transparent bg-slate-900 px-4 py-2 text-sm font-medium text-white hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-slate-500 focus:ring-offset-2 disabled:opacity-50"
            >
              {isPending ? "Authenticating..." : "Sign in"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
