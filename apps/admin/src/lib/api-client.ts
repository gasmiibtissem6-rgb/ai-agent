// src/lib/api-client.ts
const BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:3000";

export async function apiRequest<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const token = typeof window !== "undefined" ? localStorage.getItem("admin_token") : null;
  
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

  const response = await fetch(`${BASE_URL}${endpoint}`, fetchOptions);

  if (response.status === 401) {
  // 💡 ONLY nuke the session if the user explicitly has no token or an invalid structural token.
  // If a valid token is present, let the specific page or layout handle the restriction inline instead of crashing out.
  const currentToken = typeof window !== "undefined" ? localStorage.getItem("admin_token") : null;
  
  if (!currentToken || currentToken === "undefined") {
    if (typeof window !== "undefined" && window.location.pathname !== "/login" && !endpoint.includes("login")) {
      localStorage.removeItem("admin_token");
      document.cookie = "admin_token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT";
      window.location.href = "/login";
      return new Promise(() => {}) as Promise<T>;
    }
  }

  // If there IS a token but the backend still sent back 401, treat it like a 403 (Forbidden Route/Role issue)
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
      requestId: response.headers.get("x-request-id")
    });
  }

  return data as T;
}