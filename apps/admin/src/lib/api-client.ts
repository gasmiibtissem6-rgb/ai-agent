// src/lib/api-client.ts
import { getApiBaseUrl } from "./api-base";

const BASE_URL = getApiBaseUrl(process.env.NEXT_PUBLIC_API_BASE_URL);

function clearAdminSession() {
  if (typeof window === "undefined") {
    return;
  }

  localStorage.removeItem("admin_token");
  document.cookie =
    "admin_token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT";
  document.cookie = "token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT";
}

export async function apiRequest<T>(
  endpoint: string,
  options: RequestInit = {},
): Promise<T> {
  const token =
    typeof window !== "undefined" ? localStorage.getItem("admin_token") : null;

  const headers = new Headers(options.headers);
  headers.set("Content-Type", "application/json");

  // Safeguard against the literal string "undefined"
  if (token && token !== "undefined" && token !== "null") {
    headers.set("Authorization", `Bearer ${token}`);
  }

  const fetchOptions: RequestInit = {
    ...options,
    headers,
    cache: "no-store",
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

  if (response.status === 401) {
    const currentToken =
      typeof window !== "undefined"
        ? localStorage.getItem("admin_token")
        : null;
    const isSessionVerification =
      endpoint === "/auth/profile" || endpoint === "/auth/me";

    if (
      !currentToken ||
      currentToken === "undefined" ||
      currentToken === "null" ||
      isSessionVerification
    ) {
      if (
        typeof window !== "undefined" &&
        window.location.pathname !== "/login" &&
        !endpoint.includes("login")
      ) {
        clearAdminSession();
        window.location.href = "/login";
        return new Promise(() => {}) as Promise<T>;
      }
    }

    clearAdminSession();
    return Promise.reject(new Error("FORBIDDEN_ROLE"));
  }

  if (response.status === 403) {
    // 🚨 Changed to Promise.reject
    return Promise.reject(new Error("FORBIDDEN_ROUTE"));
  }

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    // 🚨 Changed to Promise.reject
    return Promise.reject({
      message: data.message || "API Error",
      status: response.status,
      requestId: response.headers.get("x-request-id"),
    });
  }

  return data as T;
}
