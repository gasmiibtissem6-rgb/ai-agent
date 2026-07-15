import { getApiBaseUrl } from "./api-base";

const BASE_URL = getApiBaseUrl(process.env.NEXT_PUBLIC_API_BASE_URL);

function clearAdminSession() {
  if (typeof window === "undefined") {
    return;
  }
  // Clear any local state, UI layout config, or caches here if needed
}

// 🚀 EXPORTED LOGOUT UTILITY: Call this from any UI component button
export async function logoutAdmin(): Promise<void> {
  try {
    await apiRequest("/auth/logout/admin", { method: "POST" });
  } catch (err) {
    console.error("Failed to cleanly notify server of logout:", err);
  } finally {
    clearAdminSession();
    if (typeof window !== "undefined") {
      window.location.href = "/login";
    }
  }
}

export async function apiRequest<T>(
  endpoint: string,
  options: RequestInit = {},
): Promise<T> {
  const headers = new Headers(options.headers);
  headers.set("Content-Type", "application/json");

  const fetchOptions: RequestInit = {
    ...options,
    headers,
    cache: "no-store",
    credentials: "include", // Retained for secure cookie handling
  };

  let response: Response;

  try {
    response = await fetch(`${BASE_URL}${endpoint}`, fetchOptions);
  } catch {
    return Promise.reject({
      message:
        "API unreachable. Check that the backend is running and ALLOWED_ORIGINS includes the admin origin.",
      status: 0,
      requestId: null,
    });
  }

  // Handle Session Expirations / Bad Roles
  if (response.status === 401) {
    if (
      typeof window !== "undefined" &&
      window.location.pathname !== "/login" &&
      !endpoint.includes("login")
    ) {
      clearAdminSession();
      window.location.href = "/login";
      return new Promise(() => {}) as Promise<T>;
    }

    clearAdminSession();
    return Promise.reject(new Error("FORBIDDEN_ROLE"));
  }

  if (response.status === 403) {
    return Promise.reject(new Error("FORBIDDEN_ROUTE"));
  }

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    return Promise.reject({
      message: data.message || "API Error",
      status: response.status,
      requestId: response.headers.get("x-request-id"),
    });
  }

  return data as T;
}