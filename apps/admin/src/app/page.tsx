import Image from "next/image";

const adminAreas = [
  {
    title: "User review",
    description: "Review accounts, profiles, roles, and platform access.",
  },
  {
    title: "Deal review",
    description: "Monitor agreements, parties, approvals, and version status.",
  },
  {
    title: "Reports",
    description: "Handle reports and moderation tasks from the platform.",
  },
  {
    title: "System monitoring",
    description: "Track service health, audit logs, and operational activity.",
  },
];

export default function Home() {
  return (
    <main className="min-h-screen bg-slate-50 text-slate-950">
      <section className="mx-auto flex w-full max-w-6xl flex-col gap-10 px-6 py-10 sm:px-8 lg:px-10">
        <header className="flex flex-col gap-6 border-b border-slate-200 pb-8 sm:flex-row sm:items-center">
          <Image
            src="/ideal-logo.png"
            alt="IDEAL logo"
            width={88}
            height={88}
            priority
            className="rounded-lg"
          />
          <div>
            <p className="text-sm font-semibold uppercase tracking-wide text-blue-700">
              Admin dashboard
            </p>
            <h1 className="mt-2 text-4xl font-bold">IDEAL</h1>
            <p className="mt-3 max-w-3xl text-lg leading-8 text-slate-700">
              Internal management, moderation, user review, deal review, system
              monitoring, and operational control for trusted digital deals.
            </p>
          </div>
        </header>

        <section>
          <h2 className="text-2xl font-semibold">Main admin areas</h2>
          <div className="mt-5 grid gap-4 sm:grid-cols-2">
            {adminAreas.map((area) => (
              <article
                className="rounded-lg border border-slate-200 bg-white p-5"
                key={area.title}
              >
                <h3 className="text-lg font-semibold">{area.title}</h3>
                <p className="mt-2 leading-7 text-slate-600">
                  {area.description}
                </p>
              </article>
            ))}
          </div>
        </section>
      </section>
    </main>
  );
}
