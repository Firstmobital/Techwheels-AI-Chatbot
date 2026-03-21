import { NavLink } from "react-router-dom";
import type { PropsWithChildren } from "react";
import clsx from "clsx";

const navItems = [
  { to: "/leads", label: "Leads" },
  { to: "/admin/variants-pricing", label: "Variants & Pricing" },
  { to: "/campaigns", label: "Campaigns" },
];

export function AppLayout({ children }: PropsWithChildren) {
  return (
    <div className="min-h-screen bg-paper text-ink">
      <div className="mx-auto grid min-h-screen max-w-[1440px] grid-cols-1 lg:grid-cols-[260px_1fr]">
        <aside className="border-b border-slate-200 bg-ink px-6 py-8 text-white lg:border-b-0 lg:border-r">
          <div className="mb-8">
            <p className="text-xs uppercase tracking-[0.24em] text-white/60">
              Techwheels
            </p>
            <h1 className="mt-2 text-2xl font-semibold">Phase 1 Dashboard</h1>
            <p className="mt-2 text-sm text-white/70">
              Leads, conversations, pricing inputs, and campaign operations.
            </p>
          </div>

          <nav className="space-y-2">
            {navItems.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                className={({ isActive }) =>
                  clsx(
                    "block rounded-xl px-4 py-3 text-sm font-medium transition",
                    isActive
                      ? "bg-white text-ink"
                      : "text-white/80 hover:bg-white/10 hover:text-white",
                  )}
              >
                {item.label}
              </NavLink>
            ))}
          </nav>
        </aside>

        <main className="px-4 py-6 sm:px-6 lg:px-8">{children}</main>
      </div>
    </div>
  );
}
