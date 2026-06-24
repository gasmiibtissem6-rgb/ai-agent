"use client";

import { useEffect, useState, ReactNode } from "react";
import { useRouter } from "next/navigation";
import { apiRequest } from "@/lib/api-client";

interface AdminUser {
  id: string;
  email: string;
  adminRole: string;
  role: "super_admin" | "admin" | "support_reviewer" | "finance_reviewer" | "authenticated";
}

export default function AdminLayout({ children }: { children: ReactNode }) {
  const [admin, setAdmin] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    async function verifyAdminSession() {
      try {
        const token = localStorage.getItem("admin_token");
        if (!token) {
          router.replace("/login");
          return;
        }

        // Fetch profile details from NestJS to check role clearance
const profileResponse = await apiRequest<any>("/auth/profile");

// Grab the nested data object
const profile = profileResponse?.data; 

const validRoles = ["super_admin", "admin", "support_reviewer", "finance_reviewer", "SUPER_ADMIN", "ADMIN", "SUPPORT_REVIEWER", "FINANCE_REVIEWER"];

// 2. Use profile.adminRole instead of profile.role
if (!profile || !profile.adminRole || !validRoles.includes(profile.adminRole)) {
  console.log("Role validation failed for:", profile); 
  localStorage.removeItem("admin_token");
  router.replace("/login");
  return;
}

// 3. Set your state using the nested profile data
setAdmin(profile);
      } catch (err) {
        console.error("Session verification failed:", err);
        router.replace("/login");
      } finally {
        setLoading(false);
      }
    }

    verifyAdminSession();
  }, [router]);

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center bg-gray-50">
        <div className="h-10 w-10 animate-spin rounded-full border-4 border-slate-950 border-t-transparent"></div>
      </div>
    );
  }

  if (!admin) return null;

  return (
    <div className="flex h-screen w-full bg-gray-50 overflow-hidden text-gray-900">
      <div className="flex flex-col flex-1 min-w-0">
        <main className="flex-1 overflow-y-auto p-6">
          {children}
        </main>
      </div>
    </div>
  );
}