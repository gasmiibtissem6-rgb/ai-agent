import Link from "next/link";

type AdminPageMetric = {
  label: string;
  value: string | number;
  note: string;
  accent: string;
  href?: string;
};

type AdminPageHeaderProps = {
  eyebrow: string;
  title: string;
  description: string;
  panelLabel: string;
  panelValue: string | number;
  panelNote: string;
  panelSubtext: string;
  panelBarValue?: number;
  metrics?: AdminPageMetric[];
  tone?: "blue" | "amber" | "rose" | "emerald" | "slate";
  compact?: boolean;
};

const toneClasses = {
  blue: "from-sky-100/60 via-transparent to-indigo-100/40 dark:from-sky-900/25 dark:to-indigo-900/20",
  amber:
    "from-amber-100/70 via-transparent to-orange-100/40 dark:from-amber-900/25 dark:to-orange-900/20",
  rose: "from-rose-100/60 via-transparent to-pink-100/40 dark:from-rose-900/25 dark:to-pink-900/20",
  emerald:
    "from-emerald-100/60 via-transparent to-teal-100/40 dark:from-emerald-900/25 dark:to-teal-900/20",
  slate:
    "from-slate-100/60 via-transparent to-indigo-100/40 dark:from-slate-900/25 dark:to-indigo-900/20",
};

export function AdminPageHeader({
  eyebrow,
  title,
  description,
  panelLabel,
  panelValue,
  panelNote,
  panelSubtext,
  panelBarValue = 70,
  metrics = [],
  tone = "slate",
  compact = false,
}: AdminPageHeaderProps) {
  if (compact) {
    return (
      <section className="relative overflow-hidden rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-dark-3 dark:bg-dark-2">
        <div
          className={`pointer-events-none absolute inset-0 bg-gradient-to-br ${toneClasses[tone]}`}
        />

        <div className="relative flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
          <div className="max-w-3xl">
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-slate-500 dark:text-dark-6">
              {eyebrow}
            </p>
            <h1 className="mt-2 text-2xl font-bold text-slate-950 dark:text-white">
              {title}
            </h1>
            <p className="mt-2 text-sm leading-6 text-slate-600 dark:text-dark-7">
              {description}
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2 xl:justify-end">
            <div className="rounded-full border border-slate-200 bg-slate-950 px-4 py-2 text-white shadow-sm dark:border-slate-800 dark:bg-slate-900">
              <span className="mr-2 text-[11px] uppercase tracking-[0.18em] text-slate-300">
                {panelLabel}
              </span>
              <span className="text-sm font-semibold">{panelValue}</span>
              <span className="ml-2 text-xs text-slate-300">{panelNote}</span>
            </div>

            {metrics.map((metric) => (
              <div
                key={metric.label}
                className="rounded-full border border-slate-200 bg-white/80 px-3 py-2 text-sm shadow-sm dark:border-dark-3 dark:bg-dark/80"
              >
                <span className="font-semibold text-slate-950 dark:text-white">
                  {metric.value}
                </span>
                <span className="ml-1 text-xs text-slate-500 dark:text-dark-6">
                  {metric.label}
                </span>
              </div>
            ))}
          </div>
        </div>
      </section>
    );
  }

  return (
    <div className="space-y-7">
      <section className="relative overflow-hidden rounded-3xl border border-slate-200 bg-white p-7 shadow-sm dark:border-dark-3 dark:bg-dark-2 md:p-9">
        <div
          className={`pointer-events-none absolute inset-0 bg-gradient-to-br ${toneClasses[tone]}`}
        />

        <div className="relative grid gap-6 lg:grid-cols-[1.4fr_1fr] lg:items-end">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.24em] text-slate-500 dark:text-dark-6">
              {eyebrow}
            </p>
            <h1 className="mt-3 text-3xl font-bold text-slate-950 dark:text-white md:text-4xl">
              {title}
            </h1>
            <p className="mt-4 max-w-2xl text-sm leading-7 text-slate-600 dark:text-dark-7 md:text-base">
              {description}
            </p>
          </div>

          <div className="rounded-2xl border border-slate-200 bg-slate-950 p-5 text-white shadow-md dark:border-slate-800 dark:bg-slate-900">
            <p className="text-xs uppercase tracking-[0.2em] text-slate-300 dark:text-slate-400">
              {panelLabel}
            </p>
            <div className="mt-3 flex items-end justify-between gap-4">
              <p className="text-4xl font-semibold">{panelValue}</p>
              <p className="text-right text-xs text-slate-300 dark:text-slate-400">
                {panelNote}
              </p>
            </div>
            <div className="mt-4 h-2 rounded-full bg-white/15">
              <div
                className="h-2 rounded-full bg-gradient-to-r from-emerald-300 to-sky-300 transition-all duration-500"
                style={{ width: `${Math.max(8, Math.min(panelBarValue, 100))}%` }}
              />
            </div>
            <p className="mt-3 text-xs text-slate-300 dark:text-slate-400">
              {panelSubtext}
            </p>
          </div>
        </div>
      </section>

      {metrics.length > 0 && (
        <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          {metrics.map((metric) => {
            const content = (
              <>
                <div
                  className={`inline-flex rounded-full bg-gradient-to-r px-3 py-1 text-xs font-medium text-white ${metric.accent}`}
                >
                  {metric.label}
                </div>
                <p className="mt-4 text-3xl font-semibold text-slate-950 dark:text-white">
                  {metric.value}
                </p>
                <p className="mt-1 text-sm text-slate-500 dark:text-dark-6">
                  {metric.note}
                </p>
                <p className="mt-4 text-xs font-medium uppercase tracking-[0.16em] text-slate-400 transition group-hover:text-slate-600 dark:text-dark-6 dark:group-hover:text-dark-7">
                  {metric.href ? "Open section" : "Live metric"}
                </p>
              </>
            );

            if (metric.href) {
              return (
                <Link
                  key={metric.label}
                  href={metric.href}
                  className="group rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition duration-200 hover:-translate-y-0.5 hover:border-slate-300 hover:shadow-md dark:border-dark-3 dark:bg-dark-2 dark:hover:border-dark-4"
                >
                  {content}
                </Link>
              );
            }

            return (
              <div
                key={metric.label}
                className="group rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-dark-3 dark:bg-dark-2"
              >
                {content}
              </div>
            );
          })}
        </section>
      )}
    </div>
  );
}
