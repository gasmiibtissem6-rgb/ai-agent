"use client";

import {
  Dropdown,
  DropdownContent,
  DropdownTrigger,
} from "@/components/ui/dropdown";
import { useIsMobile } from "@/hooks/use-mobile";
import { cn } from "@/lib/utils";
import Image from "next/image";
import Link from "next/link";
import { useState } from "react";
import { BellIcon } from "./icons";
import user03 from "../../../../../images/user/user-03.png";
import user15 from "../../../../../images/user/user-15.png";
import user26 from "../../../../../images/user/user-26.png";
import user27 from "../../../../../images/user/user-27.png";
import user28 from "../../../../../images/user/user-28.png";

export const notificationList = [
  {
    image: user15,
    title: "New admin profile created",
    subTitle: "Piter was added to the operations team",
    category: "Account",
    time: "8 min ago",
    unread: true,
  },
  {
    image: user03,
    title: "KYC queue requires review",
    subTitle: "3 identity files are waiting for approval",
    category: "KYC",
    time: "22 min ago",
    unread: true,
  },
  {
    image: user26,
    title: "Contract version locked",
    subTitle: "A deal moved into archive history",
    category: "Contracts",
    time: "1 hr ago",
    unread: true,
  },
  {
    image: user28,
    title: "Dispute status updated",
    subTitle: "A ticket was marked under review",
    category: "Risk",
    time: "2 hrs ago",
    unread: true,
  },
  {
    image: user27,
    title: "Trust metrics adjusted",
    subTitle: "Manual override recorded in audit log",
    category: "Audit",
    time: "Today",
    unread: true,
  },
];

export function Notification() {
  const [isOpen, setIsOpen] = useState(false);
  const [isDotVisible, setIsDotVisible] = useState(true);
  const isMobile = useIsMobile();

  return (
    <Dropdown
      isOpen={isOpen}
      setIsOpen={(open) => {
        setIsOpen(open);

        if (setIsDotVisible) setIsDotVisible(false);
      }}
    >
      <DropdownTrigger
        className="grid size-12 cursor-pointer place-items-center rounded-full border bg-gray-2 text-dark outline-none hover:text-primary focus-visible:border-primary focus-visible:text-primary dark:border-dark-4 dark:bg-dark-2 dark:text-white dark:hover:bg-dark-3 dark:focus-visible:border-primary"
        aria-label="View Notifications"
      >
        <span className="relative">
          <BellIcon />

          {isDotVisible && (
            <span
              className={cn(
                "absolute top-0 right-0 z-1 size-2 rounded-full bg-red-light ring-2 ring-gray-2 dark:ring-dark-3",
              )}
            >
              <span className="absolute inset-0 -z-1 animate-ping rounded-full bg-red-light opacity-75" />
            </span>
          )}
        </span>
      </DropdownTrigger>

      <DropdownContent
        align={isMobile ? "end" : "center"}
        className="border border-stroke bg-white p-3 shadow-xl min-[350px]:min-w-[24rem] dark:border-dark-3 dark:bg-gray-dark"
      >
        <div className="mb-2 flex items-start justify-between gap-4 px-2 py-1.5">
          <div>
          <span className="text-lg font-semibold text-dark dark:text-white">
            Notifications
          </span>
            <p className="mt-1 text-xs text-dark-5 dark:text-dark-6">
              Operational alerts from the admin workspace
            </p>
          </div>
          <span className="rounded-full bg-primary px-2.5 py-1 text-xs font-semibold text-white">
            5 new
          </span>
        </div>

        <ul className="mb-3 max-h-92 space-y-1.5 overflow-y-auto">
          {notificationList.map((item, index) => (
            <li key={index} role="menuitem">
              <Link
                href="/notifications"
                onClick={() => setIsOpen(false)}
                className="group flex items-start gap-3 rounded-xl px-2 py-2.5 outline-none transition hover:bg-gray-2 focus-visible:bg-gray-2 dark:hover:bg-dark-3 dark:focus-visible:bg-dark-3"
              >
                <Image
                  src={item.image}
                  className="size-11 rounded-full object-cover ring-1 ring-stroke dark:ring-dark-3"
                  width={200}
                  height={200}
                  alt="User"
                />

                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-3">
                  <strong className="block truncate text-sm font-semibold text-dark dark:text-white">
                    {item.title}
                  </strong>
                    <span className="shrink-0 text-[11px] font-medium text-dark-5 dark:text-dark-6">
                      {item.time}
                    </span>
                  </div>

                  <span className="mt-0.5 block truncate text-sm text-dark-5 dark:text-dark-6">
                    {item.subTitle}
                  </span>
                  <span className="mt-2 inline-flex rounded-full bg-gray-2 px-2 py-0.5 text-[11px] font-semibold text-dark-5 dark:bg-dark dark:text-dark-6">
                    {item.category}
                  </span>
                </div>
              </Link>
            </li>
          ))}
        </ul>

        <Link
          href="/notifications"
          onClick={() => setIsOpen(false)}
          className="block rounded-xl border border-primary/30 bg-primary/5 p-2.5 text-center text-sm font-semibold tracking-wide text-primary transition-colors outline-none hover:bg-primary hover:text-white focus:bg-primary focus:text-white focus-visible:border-primary dark:border-primary/40 dark:bg-primary/10"
        >
          See all notifications
        </Link>
      </DropdownContent>
    </Dropdown>
  );
}
