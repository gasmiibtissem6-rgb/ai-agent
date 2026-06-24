"use client";

import { ChevronUpIcon } from "@/assets/icons";
import {
  Dropdown,
  DropdownContent,
  DropdownTrigger,
} from "@/components/ui/dropdown";
import { cn } from "@/lib/utils";
import Image from "next/image";
import Link from "next/link";
import { useState, useEffect } from "react";
import { LogOutIcon, SettingsIcon, UserIcon } from "./icons";
import { apiRequest } from "@/lib/api-client"; 
import { useRouter } from "next/navigation";

// Define the User structure expected from your NestJS backend
interface UserData {
  name: string;
  email: string;
  img?: string | null;
}

export function UserInfo() {
  const [isOpen, setIsOpen] = useState(false);
  const router = useRouter();
  
  const [user, setUser] = useState<UserData | null>(null);
  const [loading, setLoading] = useState(true);

useEffect(() => {
  // Ensure we are on the client and actually have a token before bothering the backend
  const token = typeof window !== "undefined" ? localStorage.getItem("admin_token") : null;
  if (!token || token === "undefined") {
    setLoading(false);
    return;
  }

  // 💡 FIXED: Changed from "/profile" to "/auth/profile"
  apiRequest<any>("/auth/profile")
    .then((response) => {
      if (!response) return;
      
      // Extract the nested 'data' object from NestJS
      const userData = response?.data; 

      if (userData) {
        setUser({
          // 💡 FIXED: Fallback to adminRole and check displayName from your logs
          name: userData.displayName || userData.name || userData.adminRole || "Admin", 
          email: userData.email,
          img: userData.avatarUrl || userData.img || null,
        });
      }
    })
    .catch((err) => {
      console.error("Failed to load user info:", err);
    })
    .finally(() => {
      setLoading(false);
    });
}, []);

  const handleLogout = () => {
    localStorage.removeItem("admin_token"); // Ensure this matches your login token key
    setIsOpen(false);
    router.replace("/login"); 
  };

  if (loading) {
    return <UserAvatarPlaceholder />;
  }

  const activeUser = user || { name: "Admin User", email: "admin@api.com", img: null };

  return (
    <Dropdown isOpen={isOpen} setIsOpen={setIsOpen}>
      <DropdownTrigger className="cursor-pointer rounded align-middle ring-primary ring-offset-2 outline-none focus-visible:ring-1 dark:ring-offset-gray-dark">
        <span className="sr-only">My Account</span>

        <figure className="flex items-center gap-3">
          {activeUser?.img ? (
            <Image
              src={activeUser.img}
              className="size-12 overflow-hidden rounded-full object-cover"
              alt={`Avatar of ${activeUser.name}`}
              role="presentation"
              width={200}
              height={200}
            />
          ) : (
            <UserAvatar />
          )}
          <figcaption className="flex items-center gap-1 font-medium text-dark max-[1024px]:sr-only dark:text-dark-6">
            <span className="max-w-24 truncate">{activeUser.name}</span>

            <ChevronUpIcon
              aria-hidden
              className={cn(
                "rotate-180 transition-transform",
                isOpen && "rotate-0",
              )}
              strokeWidth={1.5}
            />
          </figcaption>
        </figure>
      </DropdownTrigger>

      <DropdownContent
        className="border border-stroke bg-white shadow-md min-[230px]:min-w-70 dark:border-dark-3 dark:bg-gray-dark"
        align="end"
      >
        <h2 className="sr-only">User information</h2>

        <figure className="flex items-center gap-2.5 px-5 py-3.5">
          {activeUser?.img ? (
            <Image
              src={activeUser.img}
              className="size-12 shrink-0 overflow-hidden rounded-full object-cover object-center"
              alt={`Avatar of ${activeUser.name}`}
              role="presentation"
              width={48}
              height={48}
            />
          ) : (
            <UserAvatar />
          )}

          <figcaption className="space-y-1 text-base font-medium">
            <div className="mb-2 leading-none text-dark dark:text-white">
              {activeUser.name}
            </div>

            <div className="w-full max-w-47.5 truncate leading-none text-gray-6">
              {activeUser.email}
            </div>
          </figcaption>
        </figure>

        <hr className="border-[#E8E8E8] dark:border-dark-3" />

        <div className="p-2 text-base text-[#4B5563] *:cursor-pointer dark:text-dark-6">
          <Link
            href={"/profile"}
            onClick={() => setIsOpen(false)}
            className="flex w-full items-center gap-2.5 rounded-lg px-2.5 py-2.25 ring-primary outline-0 hover:bg-gray-2 hover:text-dark focus-visible:ring-1 dark:hover:bg-dark-3 dark:hover:text-white"
          >
            <UserIcon />

            <span className="mr-auto text-base font-medium">View profile</span>
          </Link>

          <Link
            href={"/pages/settings"}
            onClick={() => setIsOpen(false)}
            className="flex w-full items-center gap-2.5 rounded-lg px-2.5 py-2.25 ring-primary outline-0 hover:bg-gray-2 hover:text-dark focus-visible:ring-1 dark:hover:bg-dark-3 dark:hover:text-white"
          >
            <SettingsIcon />

            <span className="mr-auto text-base font-medium">
              Account Settings
            </span>
          </Link>
        </div>

        <hr className="border-[#E8E8E8] dark:border-dark-3" />

        <div className="p-2 text-base text-[#4B5563] dark:text-dark-6">
          <button
            className="flex w-full cursor-pointer items-center gap-2.5 rounded-lg px-2.5 py-2.25 ring-primary outline-0 hover:bg-gray-2 hover:text-dark focus-visible:ring-1 dark:hover:bg-dark-3 dark:hover:text-white"
            onClick={handleLogout}
          >
            <LogOutIcon />

            <span className="text-base font-medium">Log out</span>
          </button>
        </div>
      </DropdownContent>
    </Dropdown>
  );
}

function UserAvatar() {
  return (
    <span className="flex size-12 items-center justify-center rounded-full border bg-gray-2 text-dark outline-none dark:border-dark-4 dark:bg-dark-2 dark:text-white">
      <UserIcon />
    </span>
  );
}

function UserAvatarPlaceholder() {
  return (
    <div className="flex items-center gap-3 animate-pulse">
      <div className="size-12 rounded-full bg-gray-3 dark:bg-dark-3" />
      <div className="h-4 w-20 bg-gray-3 dark:bg-dark-3 rounded max-[1024px]:hidden" />
    </div>
  );
}