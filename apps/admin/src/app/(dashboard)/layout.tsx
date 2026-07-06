"use client";

import { useEffect, useState, ReactNode } from "react";
import { useRouter } from "next/navigation";
import { Header } from "@/components/Layouts/header";
import { Sidebar } from "@/components/Layouts/sidebar";
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
        if (!token || token === "undefined" || token === "null") {
          router.replace("/login");
          return;
        }

        const profileResponse = await apiRequest<{ data?: AdminUser }>(
          "/auth/profile",
        );
        const profile = profileResponse?.data;
        const validRoles = [
          "super_admin",
          "admin",
          "support_reviewer",
          "finance_reviewer",
          "SUPER_ADMIN",
          "ADMIN",
          "SUPPORT_REVIEWER",
          "FINANCE_REVIEWER",
        ];

        if (
          !profile ||
          !profile.adminRole ||
          !validRoles.includes(profile.adminRole)
        ) {
          localStorage.removeItem("admin_token");
          router.replace("/login");
          return;
        }

        setAdmin(profile);
      } catch (err) {
        console.error("Session verification failed:", err);
        localStorage.removeItem("admin_token");
        router.replace("/login");
      } finally {
        setLoading(false);
      }
    }

    verifyAdminSession();
  }, [router]);

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center bg-gray-50 dark:bg-gray-dark">
        <div className="h-10 w-10 animate-spin rounded-full border-4 border-slate-950 border-t-transparent dark:border-white dark:border-t-transparent"></div>
      </div>
    );
  }

  if (!admin) return null;

  return (
    <div className="flex h-screen overflow-hidden">
      <Sidebar />
      <div className="relative flex flex-1 flex-col overflow-y-auto overflow-x-hidden bg-gray-50 text-gray-900 dark:bg-gray-dark dark:text-white">
        <Header />
        <main>
          <div className="mx-auto max-w-screen-2xl p-4 md:p-6 2xl:p-10">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
