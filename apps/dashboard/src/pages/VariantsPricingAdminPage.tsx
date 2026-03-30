import { useEffect, useState } from "react";
import { fetchVariants, saveVariant } from "../lib/dashboardApi";
import type { VariantRecord } from "../types";

const SCHEME_KEYS: { key: keyof VariantRecord; label: string }[] = [
  { key: "scheme_consumer", label: "Consumer" },
  { key: "scheme_exchange_scrap", label: "Exchange" },
  { key: "scheme_corporate", label: "Corporate" },
  { key: "scheme_intervention", label: "Intervention" },
  { key: "scheme_solar", label: "Solar" },
  { key: "scheme_msme", label: "MSME" },
  { key: "scheme_green_bonus", label: "Green Bonus" },
];

const MODEL_COLORS: Record<string, string> = {
  "Nexon EV": "#3b4fe0",
  "Harrier": "#22a06b",
  "Punch EV": "#f59e0b",
  "Safari": "#e84393",
  "Tiago EV": "#8b5cf6",
  "Altroz": "#06b6d4",
};

function modelColor(model: string) {
  for (const [key, color] of Object.entries(MODEL_COLORS)) {
    if (model.includes(key)) return color;
  }
  return "#6b7280";
}

function lakhFormat(n: number | null) {
  if (n === null || n === undefined) return "—";
  return `₹${(n / 100000).toFixed(2)}L`;
}

function schemeChips(variant: VariantRecord) {
  return SCHEME_KEYS.filter((s) => (variant[s.key] as number | null) != null && (variant[s.key] as number) > 0).map((s) => s.label);
}

/* ── Edit modal ── */
function EditModal({ variant, onClose, onSave }: {
  variant: Partial<VariantRecord>;
  onClose: () => void;
  onSave: (v: Partial<VariantRecord>) => Promise<void>;
}) {
  const [form, setForm] = useState<Partial<VariantRecord>>({ ...variant });
  const [saving, setSaving] = useState(false);

  function set(key: keyof VariantRecord, val: string) {
    setForm((prev) => ({ ...prev, [key]: val === "" ? null : isNaN(Number(val)) ? val : Number(val) }));
  }

  async function handleSave() {
    setSaving(true);
    try { await onSave(form); onClose(); }
    finally { setSaving(false); }
  }

  const fields: { key: keyof VariantRecord; label: string; type?: string }[] = [
    { key: "model", label: "Model" },
    { key: "variant_name", label: "Variant name" },
    { key: "fuel_type", label: "Fuel type" },
    { key: "transmission", label: "Transmission" },
    { key: "ex_showroom_price", label: "Ex-showroom price (₹)", type: "number" },
    { key: "insurance", label: "Insurance (₹)", type: "number" },
    { key: "rto_standard", label: "RTO standard (₹)", type: "number" },
    ...SCHEME_KEYS.map((s) => ({ key: s.key, label: `${s.label} discount (₹)`, type: "number" })),
    { key: "brochure_url", label: "Brochure URL" },
  ];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30">
      <div className="flex max-h-[80vh] w-[520px] flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-slate-100 px-6 py-4">
          <p className="text-[14px] font-semibold text-ink">
            {form.id ? "Edit variant" : "Add new variant"}
          </p>
          <button type="button" onClick={onClose} className="text-slate-400 hover:text-slate-600">✕</button>
        </div>
        <div className="flex-1 overflow-y-auto px-6 py-4">
          <div className="grid grid-cols-2 gap-3">
            {fields.map(({ key, label, type }) => (
              <div key={String(key)} className={key === "brochure_url" ? "col-span-2" : ""}>
                <label className="field-label">{label}</label>
                <input
                  type={type ?? "text"}
                  className="field-input text-[12px]"
                  value={String(form[key] ?? "")}
                  onChange={(e) => set(key, e.target.value)}
                />
              </div>
            ))}
          </div>
        </div>
        <div className="flex justify-end gap-2 border-t border-slate-100 px-6 py-4">
          <button type="button" className="secondary-button text-[12px]" onClick={onClose}>Cancel</button>
          <button type="button" className="action-button text-[12px]" disabled={saving} onClick={() => void handleSave()}>
            {saving ? "Saving…" : "Save variant"}
          </button>
        </div>
      </div>
    </div>
  );
}

export function VariantsPricingAdminPage() {
  const [variants, setVariants] = useState<VariantRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [modelFilter, setModelFilter] = useState("all");
  const [editing, setEditing] = useState<Partial<VariantRecord> | null>(null);

  async function load() {
    setLoading(true);
    try { setVariants(await fetchVariants()); }
    finally { setLoading(false); }
  }

  useEffect(() => { void load(); }, []);

  const models = Array.from(new Set(variants.map((v) => v.model))).sort();

  const filtered = variants.filter((v) => {
    const q = search.toLowerCase();
    const matchSearch = !q || v.model.toLowerCase().includes(q) || v.variant_name.toLowerCase().includes(q);
    const matchModel = modelFilter === "all" || v.model === modelFilter;
    return matchSearch && matchModel;
  });

  async function handleSave(v: Partial<VariantRecord>) {
    await saveVariant(v);
    await load();
  }

  return (
    <div className="flex flex-col">
      {editing && (
        <EditModal
          variant={editing}
          onClose={() => setEditing(null)}
          onSave={handleSave}
        />
      )}

      {/* Top bar */}
      <header className="flex items-center justify-between border-b border-slate-200 bg-white px-6 py-3.5">
        <div>
          <h2 className="text-[16px] font-semibold text-ink">Variants & Pricing</h2>
          <p className="text-[11px] text-slate-400">{variants.length} variants · 8 scheme types</p>
        </div>
      </header>

      <div className="p-5">
        {/* KPI row */}
        <div className="mb-4 grid grid-cols-4 gap-3">
          {[
            { label: "Total variants", value: String(variants.length), accent: "#3b4fe0" },
            { label: "Active models", value: String(models.length), accent: "#22a06b" },
            { label: "Scheme types", value: "8", accent: "#f59e0b" },
            { label: "Brochures live", value: String(variants.filter((v) => v.brochure_url).length), accent: "#e84393" },
          ].map(({ label, value, accent }) => (
            <div key={label} className="kpi-card" style={{ borderTop: `3px solid ${accent}` }}>
              <p className="kpi-card-label">{label}</p>
              <p className="kpi-card-value">{value}</p>
            </div>
          ))}
        </div>

        {/* Toolbar */}
        <div className="mb-3 flex items-center gap-2">
          <div className="flex flex-1 items-center gap-2 rounded-xl border border-slate-200 bg-white px-3 py-2">
            <svg width="13" height="13" viewBox="0 0 13 13" fill="none" stroke="#aab0be" strokeWidth="1.5">
              <circle cx="5.5" cy="5.5" r="4" />
              <path d="M9 9l2.5 2.5" />
            </svg>
            <input
              className="w-full bg-transparent text-[12px] text-ink outline-none placeholder:text-slate-400"
              placeholder="Search variant or model…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
          <select
            className="field-input w-44 text-[12px]"
            value={modelFilter}
            onChange={(e) => setModelFilter(e.target.value)}
          >
            <option value="all">All models</option>
            {models.map((m) => <option key={m} value={m}>{m}</option>)}
          </select>
          <button
            type="button"
            className="action-button shrink-0 text-[12px]"
            onClick={() => setEditing({})}
          >
            + Add variant
          </button>
        </div>

        {/* Table */}
        <div className="panel overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full border-collapse text-[12px]">
              <thead>
                <tr className="bg-slate-50 text-left">
                  <th className="px-4 py-3 text-[10px] font-bold uppercase tracking-wide text-slate-400">Model / Variant</th>
                  <th className="px-4 py-3 text-[10px] font-bold uppercase tracking-wide text-slate-400">Ex-showroom</th>
                  <th className="px-4 py-3 text-[10px] font-bold uppercase tracking-wide text-slate-400">On-road (Jaipur est.)</th>
                  <th className="px-4 py-3 text-[10px] font-bold uppercase tracking-wide text-slate-400">Fuel / Trans</th>
                  <th className="px-4 py-3 text-[10px] font-bold uppercase tracking-wide text-slate-400">Schemes</th>
                  <th className="px-4 py-3 text-[10px] font-bold uppercase tracking-wide text-slate-400">Brochure</th>
                  <th className="px-4 py-3 text-[10px] font-bold uppercase tracking-wide text-slate-400"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {loading ? (
                  <tr><td colSpan={7} className="px-4 py-6 text-slate-400">Loading variants…</td></tr>
                ) : filtered.length === 0 ? (
                  <tr><td colSpan={7} className="px-4 py-6 text-slate-400">No variants match the filter.</td></tr>
                ) : (
                  filtered.map((v) => {
                    const onRoad = v.ex_showroom_price + (v.insurance ?? 0) + (v.rto_standard ?? 0);
                    const chips = schemeChips(v);
                    return (
                      <tr key={v.id} className="hover:bg-slate-50/80 transition-colors">
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-2">
                            <div className="h-2 w-2 shrink-0 rounded-full" style={{ background: modelColor(v.model) }} />
                            <div>
                              <p className="font-semibold text-ink">{v.model}</p>
                              <p className="text-[11px] text-slate-400">{v.variant_name}</p>
                            </div>
                          </div>
                        </td>
                        <td className="px-4 py-3 font-semibold text-ink">{lakhFormat(v.ex_showroom_price)}</td>
                        <td className="px-4 py-3 text-slate-600">{onRoad > 0 ? lakhFormat(onRoad) : "—"}</td>
                        <td className="px-4 py-3 text-slate-500">{[v.fuel_type, v.transmission].filter(Boolean).join(" · ")}</td>
                        <td className="px-4 py-3">
                          <div className="flex flex-wrap gap-1">
                            {chips.length === 0 ? (
                              <span className="text-slate-300">—</span>
                            ) : chips.map((c) => (
                              <span key={c} className="rounded px-1.5 py-0.5 text-[9px] font-bold bg-indigo-50 text-indigo-600">{c}</span>
                            ))}
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          {v.brochure_url ? (
                            <a
                              href={v.brochure_url}
                              target="_blank"
                              rel="noreferrer"
                              className="text-[11px] font-medium text-accent hover:underline"
                            >
                              View PDF
                            </a>
                          ) : (
                            <span className="text-slate-300">—</span>
                          )}
                        </td>
                        <td className="px-4 py-3">
                          <button
                            type="button"
                            className="secondary-button text-[11px]"
                            onClick={() => setEditing(v)}
                          >
                            Edit
                          </button>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
