"use client";

import { notificationList } from "@/components/Layouts/header/notification";
import Image from "next/image";
import { useMemo, useState } from "react";

const filters = ["All", "Unread", "KYC", "Risk", "Contracts", "Audit", "Account"];

export default function NotificationsPage() {
  const [activeFilter, setActiveFilter] = useState("All");
  const [readItems, setReadItems] = useState<string[]>([]);

  const filteredNotifications = useMemo(() => {
    return notificationList.filter((item) => {
      const isRead = readItems.includes(item.title);

      if (activeFilter === "All") return true;
      if (activeFilter === "Unread") return !isRead;
      return item.category === activeFilter;
    });
  }, [activeFilter, readItems]);

  const unreadCount = notificationList.filter(
    (item) => !readItems.includes(item.title),
  ).length;

  return (
    <div className="space-y-6">
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-dark-3 dark:bg-dark-2">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.22em] text-slate-500 dark:text-dark-6">
              ADMIN NOTIFICATIONS
            </p>
            <h1 className="mt-2 text-3xl font-bold text-slate-950 dark:text-white">
              Notification Center
            </h1>
            <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-600 dark:text-dark-7">
              Review account, KYC, contract, audit, and risk events from the admin workspace.
            </p>
          </div>

          <button
            type="button"
            onClick={() => setReadItems(notificationList.map((item) => item.title))}
            className="rounded-xl bg-slate-950 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-slate-800 dark:bg-primary dark:hover:bg-primary/90"
          >
            Mark all as read
          </button>
        </div>

        <div className="mt-5 flex flex-wrap gap-2">
          {filters.map((filter) => (
            <button
              key={filter}
              type="button"
              onClick={() => setActiveFilter(filter)}
              className={`rounded-full border px-3 py-1.5 text-sm font-semibold transition ${
                activeFilter === filter
                  ? "border-primary bg-primary text-white"
                  : "border-slate-200 bg-slate-50 text-slate-600 hover:border-slate-300 hover:bg-white dark:border-dark-3 dark:bg-dark dark:text-dark-7 dark:hover:border-dark-4"
              }`}
            >
              {filter}
              {filter === "Unread" && (
                <span className="ml-1 opacity-80">({unreadCount})</span>
              )}
            </button>
          ))}
        </div>
      </section>

      <section className="rounded-2xl border border-slate-200 bg-white p-3 shadow-sm dark:border-dark-3 dark:bg-dark-2">
        {filteredNotifications.length === 0 ? (
          <div className="px-4 py-12 text-center text-sm text-slate-500 dark:text-dark-6">
            No notifications match this filter.
          </div>
        ) : (
          <div className="divide-y divide-slate-200 dark:divide-dark-3">
            {filteredNotifications.map((item) => {
              const isRead = readItems.includes(item.title);

              return (
                <article
                  key={item.title}
                  className="flex flex-col gap-4 rounded-xl px-4 py-4 transition hover:bg-slate-50 dark:hover:bg-dark md:flex-row md:items-center"
                >
                  <Image
                    src={item.image}
                    alt=""
                    width={56}
                    height={56}
                    className="size-12 rounded-full object-cover ring-1 ring-stroke dark:ring-dark-3"
                  />

                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <h2 className="text-base font-semibold text-slate-950 dark:text-white">
                        {item.title}
                      </h2>
                      {!isRead && (
                        <span className="rounded-full bg-primary px-2 py-0.5 text-[11px] font-semibold text-white">
                          New
                        </span>
                      )}
                      <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-semibold text-slate-500 dark:bg-dark dark:text-dark-6">
                        {item.category}
                      </span>
                    </div>
                    <p className="mt-1 text-sm text-slate-600 dark:text-dark-7">
                      {item.subTitle}
                    </p>
                  </div>

                  <div className="flex shrink-0 items-center gap-3">
                    <span className="text-xs font-medium text-slate-500 dark:text-dark-6">
                      {item.time}
                    </span>
                    <button
                      type="button"
                      onClick={() =>
                        setReadItems((current) =>
                          current.includes(item.title)
                            ? current.filter((title) => title !== item.title)
                            : [...current, item.title],
                        )
                      }
                      className="rounded-lg border border-slate-200 px-3 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-100 dark:border-dark-3 dark:text-dark-7 dark:hover:bg-dark"
                    >
                      {isRead ? "Mark unread" : "Mark read"}
                    </button>
                  </div>
                </article>
              );
            })}
          </div>
        )}
      </section>
    </div>
  );
}
