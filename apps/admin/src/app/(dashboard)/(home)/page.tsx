import Link from "next/link";

const adminAreas = [
  {
    href: "/admin/users",
    title: "User Directory",
    description: "Review profiles, admin roles, and trust counters.",
  },
  {
    href: "/admin/kyc",
    title: "KYC Queue",
    description: "Process submitted verification records and reviewer actions.",
  },
  {
    href: "/pages/settings",
    title: "Settings",
    description: "Update the dashboard account presentation and local preferences.",
  },
];

export default function Home() {

  return (
    <div className="space-y-8">
      <section className="rounded-3xl border border-slate-200 bg-white p-8 shadow-sm">
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-slate-500">
          IDEAL Admin
        </p>
        <h1 className="mt-3 text-4xl font-bold tracking-tight text-slate-950">
          Control panel for trusted digital deals
        </h1>
        <p className="mt-4 max-w-3xl text-lg leading-8 text-slate-600">
          Manage user access, review KYC submissions, and monitor the internal
          operations that support the IDEAL platform.
        </p>
      </section>

      <section className="grid gap-4 md:grid-cols-3">
        {adminAreas.map((area) => (
          <Link
            key={area.href}
            href={area.href}
            className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:border-slate-300 hover:shadow-md"
          >
            <h2 className="text-xl font-semibold text-slate-950">
              {area.title}
            </h2>
            <p className="mt-3 text-sm leading-7 text-slate-600">
              {area.description}
            </p>
          </Link>
        ))}
      </section>

      <section className="rounded-3xl border border-dashed border-slate-300 bg-slate-50 p-8">
        <h2 className="text-xl font-semibold text-slate-950">
          First-run checklist
        </h2>
        <div className="mt-4 grid gap-3 text-sm text-slate-700">
          <p>1. Create at least one admin user in Supabase Auth and `profiles`.</p>
          <p>2. Sign in through `/login` with that admin account.</p>
          <p>3. Start wiring live admin metrics into the dashboard routes.</p>
        </div>
      </section>
    </div>
  );
}
