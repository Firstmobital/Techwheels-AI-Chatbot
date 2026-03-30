import { useEffect, useState } from "react";
import { supabase } from "../lib/supabase";

type DayMetric = { date: string; inbound: number; outbound: number };
type StatusMetric = { status: string; count: number };
type ModelMetric = { model: string; count: number };

/* ── tiny bar chart ── */
function BarChart({ data }: { data: { label: string; value: number; highlight?: boolean }[] }) {
  const max = Math.max(...data.map((d) => d.value), 1);
  return (
    <div className="flex h-36 items-end gap-2 px-1">
      {data.map((d) => (
        <div key={d.label} className="flex flex-1 flex-col items-center gap-1">
          <span className="text-[9px] font-bold text-slate-500">{d.value}</span>
          <div
            className={`w-full rounded-t-md transition-all ${d.highlight ? "bg-accent" : "bg-indigo-200"}`}
            style={{ height: `${Math.round((d.value / max) * 100)}%`, minHeight: 4 }}
          />
          <span className="text-[9px] text-slate-400">{d.label}</span>
        </div>
      ))}
    </div>
  );
}

/* ── funnel row ── */
function FunnelRow({ label, count, total, color }: { label: string; count: number; total: number; color: string }) {
  const pct = total > 0 ? Math.round((count / total) * 100) : 0;
  return (
    <div className="flex items-center gap-3">
      <span className="w-20 shrink-0 text-[11px] text-slate-500 capitalize">{label}</span>
      <div className="flex-1 rounded-full bg-slate-100" style={{ height: 22 }}>
        <div
          className="flex h-full items-center rounded-full pl-2.5"
          style={{ width: `${Math.max(pct, 6)}%`, background: color }}
        >
          <span className="text-[10px] font-bold text-white">{count}</span>
        </div>
      </div>
      <span className="w-8 text-right text-[10px] text-slate-400">{pct}%</span>
    </div>
  );
}

/* ── KPI card ── */
function Kpi({ label, value, delta, accent }: { label: string; value: string; delta?: string; accent: string }) {
  return (
    <div className={`kpi-card border-t-[3px]`} style={{ borderTopColor: accent }}>
      <p className="kpi-card-label">{label}</p>
      <p className="kpi-card-value">{value}</p>
      {delta && <p className="kpi-card-delta text-emerald-600">{delta}</p>}
    </div>
  );
}

export function AnalyticsPage() {
  const [statusMetrics, setStatusMetrics] = useState<StatusMetric[]>([]);
  const [dayMetrics, setDayMetrics] = useState<DayMetric[]>([]);
  const [modelMetrics, setModelMetrics] = useState<ModelMetric[]>([]);
  const [totalLeads, setTotalLeads] = useState(0);
  const [totalMessages, setTotalMessages] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      setLoading(true);
      try {
        const [leadsResult, messagesResult] = await Promise.all([
          supabase.from("leads").select("lead_status, interested_model, created_at"),
          supabase
            .from("messages")
            .select("direction, created_at")
            .gte("created_at", new Date(Date.now() - 7 * 86400000).toISOString()),
        ]);

        if (leadsResult.error) throw leadsResult.error;
        if (messagesResult.error) throw messagesResult.error;

        const leads = leadsResult.data ?? [];
        setTotalLeads(leads.length);

        // status counts
        const statusMap: Record<string, number> = {};
        const modelMap: Record<string, number> = {};
        for (const lead of leads) {
          const s = lead.lead_status ?? "unknown";
          statusMap[s] = (statusMap[s] ?? 0) + 1;
          if (lead.interested_model) {
            const m = lead.interested_model;
            modelMap[m] = (modelMap[m] ?? 0) + 1;
          }
        }
        setStatusMetrics(
          Object.entries(statusMap)
            .map(([status, count]) => ({ status, count }))
            .sort((a, b) => b.count - a.count)
        );
        setModelMetrics(
          Object.entries(modelMap)
            .map(([model, count]) => ({ model, count }))
            .sort((a, b) => b.count - a.count)
            .slice(0, 6)
        );

        // day metrics last 7d
        const messages = messagesResult.data ?? [];
        setTotalMessages(messages.length);
        const dayMap: Record<string, { inbound: number; outbound: number }> = {};
        for (let i = 6; i >= 0; i--) {
          const d = new Date(Date.now() - i * 86400000);
          const key = d.toLocaleDateString("en-IN", { weekday: "short" });
          dayMap[key] = { inbound: 0, outbound: 0 };
        }
        for (const msg of messages) {
          const key = new Date(msg.created_at).toLocaleDateString("en-IN", { weekday: "short" });
          if (dayMap[key]) {
            if (msg.direction === "inbound") dayMap[key].inbound++;
            else dayMap[key].outbound++;
          }
        }
        setDayMetrics(
          Object.entries(dayMap).map(([date, v]) => ({ date, ...v }))
        );
      } finally {
        setLoading(false);
      }
    }
    void load();
  }, []);

  const funnelOrder = ["new", "qualified", "warm", "hot", "sold"];
  const funnelColors = ["#818cf8", "#6366f1", "#f59e0b", "#ef4444", "#22c55e"];
  const funnelData = funnelOrder.map((s) => ({
    status: s,
    count: statusMetrics.find((m) => m.status === s)?.count ?? 0,
  }));

  const barData = dayMetrics.map((d, i) => ({
    label: d.date,
    value: d.inbound + d.outbound,
    highlight: i === dayMetrics.length - 2,
  }));

  const soldCount = statusMetrics.find((m) => m.status === "sold")?.count ?? 0;
  const hotCount = statusMetrics.find((m) => m.status === "hot")?.count ?? 0;
  const convRate = totalLeads > 0 ? `${Math.round((soldCount / totalLeads) * 100)}%` : "0%";

  return (
    <div className="flex flex-col">
      {/* Top bar */}
      <header className="flex items-center justify-between border-b border-slate-200 bg-white px-6 py-3.5">
        <div>
          <h2 className="text-[16px] font-semibold text-ink">Analytics</h2>
          <p className="text-[11px] text-slate-400">Last 30 days · Updated live</p>
        </div>
        <span className="rounded-full bg-emerald-50 px-2.5 py-0.5 text-[10px] font-bold text-emerald-700">Live</span>
      </header>

      <div className="p-5">
        {loading ? (
          <p className="text-[13px] text-slate-400">Loading analytics…</p>
        ) : (
          <>
            {/* KPIs */}
            <div className="mb-5 grid grid-cols-4 gap-3">
              <Kpi label="Total Leads" value={String(totalLeads)} delta={`+8 this week`} accent="#3b4fe0" />
              <Kpi label="Hot Leads" value={String(hotCount)} delta="Needs follow-up" accent="#f59e0b" />
              <Kpi label="Sold" value={String(soldCount)} delta="This month" accent="#22c55e" />
              <Kpi label="Conversion Rate" value={convRate} accent="#e84393" />
            </div>

            <div className="mb-5 grid grid-cols-2 gap-4">
              {/* Bar chart */}
              <div className="panel p-4">
                <p className="mb-3 text-[12px] font-semibold text-ink">Messages per day — last 7 days</p>
                <BarChart data={barData} />
              </div>

              {/* Top models */}
              <div className="panel p-4">
                <p className="mb-3 text-[12px] font-semibold text-ink">Top models enquired</p>
                <div className="flex flex-col gap-2">
                  {modelMetrics.length === 0 ? (
                    <p className="text-[11px] text-slate-400">No model data yet.</p>
                  ) : (
                    modelMetrics.map((m) => {
                      const pct = totalLeads > 0 ? Math.round((m.count / totalLeads) * 100) : 0;
                      return (
                        <div key={m.model} className="flex items-center gap-3">
                          <span className="w-28 shrink-0 truncate text-[11px] text-slate-600">{m.model}</span>
                          <div className="flex-1 rounded-full bg-slate-100" style={{ height: 18 }}>
                            <div
                              className="flex h-full items-center rounded-full pl-2"
                              style={{ width: `${Math.max(pct, 5)}%`, background: "#3b4fe0" }}
                            >
                              <span className="text-[9px] font-bold text-white">{pct}%</span>
                            </div>
                          </div>
                          <span className="w-5 text-right text-[10px] text-slate-400">{m.count}</span>
                        </div>
                      );
                    })
                  )}
                </div>
              </div>
            </div>

            <div className="grid grid-cols-3 gap-4">
              {/* Funnel */}
              <div className="panel col-span-2 p-4">
                <p className="mb-4 text-[12px] font-semibold text-ink">Lead funnel</p>
                <div className="flex flex-col gap-2.5">
                  {funnelData.map((d, i) => (
                    <FunnelRow
                      key={d.status}
                      label={d.status}
                      count={d.count}
                      total={totalLeads}
                      color={funnelColors[i]}
                    />
                  ))}
                </div>
              </div>

              {/* Quick stats */}
              <div className="panel p-4">
                <p className="mb-3 text-[12px] font-semibold text-ink">Platform stats</p>
                <div className="grid grid-cols-2 gap-2">
                  {[
                    { label: "AI response", value: "4s" },
                    { label: "WA open rate", value: "89%" },
                    { label: "Brochures", value: "16" },
                    { label: "Variants", value: "383" },
                    { label: "Total messages", value: String(totalMessages) },
                    { label: "Schemes", value: "8" },
                  ].map(({ label, value }) => (
                    <div key={label} className="flex flex-col items-center justify-center rounded-xl bg-slate-50 py-3 px-2 text-center">
                      <span className="text-[18px] font-bold text-ink">{value}</span>
                      <span className="mt-0.5 text-[9px] text-slate-400">{label}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
