import { NavLink, useNavigate } from "react-router-dom";
import type { PropsWithChildren } from "react";
import clsx from "clsx";
import { supabase } from "../../lib/supabase";

const navItems = [
  {
    to: "/leads",
    label: "Leads",
    icon: (
      <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5">
        <circle cx="6" cy="5" r="2.5" />
        <path d="M1 13c0-2.8 2.2-5 5-5h0c2.8 0 5 2.2 5 5" />
        <circle cx="12" cy="5" r="2" />
        <path d="M12 10c1.7 0 3 1.3 3 3" />
      </svg>
    ),
  },
  {
    to: "/analytics",
    label: "Analytics",
    icon: (
      <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5">
        <rect x="2" y="9" width="3" height="5" rx="1" />
        <rect x="6.5" y="6" width="3" height="8" rx="1" />
        <rect x="11" y="3" width="3" height="11" rx="1" />
      </svg>
    ),
  },
  {
    to: "/admin/variants-pricing",
    label: "Variants & Pricing",
    icon: (
      <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5">
        <path d="M13 2H8L2 8l6 6 6-6V2z" />
        <circle cx="10" cy="5" r="1" />
      </svg>
    ),
  },
  {
    to: "/campaigns",
    label: "Campaigns",
    icon: (
      <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5">
        <path d="M2 4h12v9H2z" />
        <path d="M2 4l6 5 6-5" />
      </svg>
    ),
  },
];

export function AppLayout({ children }: PropsWithChildren) {
  const navigate = useNavigate();

  async function handleLogout() {
    const { error } = await supabase.auth.signOut();
    if (error) {
      console.error("[dashboard-auth] Failed to sign out", error);
      return;
    }
    navigate("/login");
  }

  return (
    <div className="flex min-h-screen bg-paper">
      {/* ── Sidebar ── */}
      <aside className="flex w-[210px] shrink-0 flex-col bg-[#152033] px-3.5 py-6">
        {/* Brand */}
        <div className="mb-6 px-2">
          <p className="text-[10px] font-semibold uppercase tracking-[0.18em] text-white/30">
            Techwheels
          </p>
          <h1 className="mt-1 text-[15px] font-semibold text-white">
            Phase 1 Dashboard
          </h1>
          <p className="mt-1 text-[11px] leading-relaxed text-white/30">
            AI Sales Platform · Jaipur
          </p>
        </div>

        <p className="mb-2 px-2 text-[9px] font-bold uppercase tracking-[0.14em] text-white/25">
          Main
        </p>

        {/* Nav */}
        <nav className="flex flex-col gap-0.5">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                clsx(
                  "flex items-center gap-2.5 rounded-xl px-3 py-2.5 text-[12px] font-medium transition-all",
                  isActive
                    ? "bg-white text-[#152033]"
                    : "text-white/50 hover:bg-white/8 hover:text-white/90"
                )
              }
            >
              {item.icon}
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="my-4 h-px bg-white/10" />

        {/* Logout */}
        <button
          className="mt-auto rounded-xl border border-white/10 px-3 py-2.5 text-left text-[11px] font-medium text-white/35 transition hover:bg-white/6 hover:text-white/70"
          onClick={() => void handleLogout()}
          type="button"
        >
          Logout
        </button>
      </aside>

      {/* ── Main area ── */}
      <div className="flex flex-1 flex-col min-w-0">
        <main className="flex-1 overflow-auto">
          {children}
        </main>
      </div>
    </div>
  );
}
