import { useEffect, useMemo, useState } from "react";
import {
  createCampaignWithRecipients,
  fetchCampaignRecipients,
  fetchCampaignTemplates,
  fetchCampaigns,
  sendCampaign,
} from "../lib/dashboardApi";
import type {
  CampaignRecord,
  CampaignRecipientRecord,
  CampaignTemplateRecord,
} from "../types";

type ParsedRecipient = {
  phone: string;
  customer_name: string | null;
  variables: Record<string, unknown> | null;
};

function parseManualRecipients(text: string): ParsedRecipient[] {
  return text
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => {
      const [phone, name] = line.split(",").map((s) => s.trim());
      return { phone: phone ?? "", customer_name: name ?? null, variables: null };
    })
    .filter((r) => r.phone.length >= 10);
}

function parseCsvRecipients(csv: string): ParsedRecipient[] {
  const lines = csv.split("\n").map((l) => l.trim()).filter(Boolean);
  const [header, ...rows] = lines;
  if (!header) return [];
  const cols = header.split(",").map((c) => c.trim().toLowerCase());
  const phoneIdx = cols.indexOf("phone");
  const nameIdx = cols.indexOf("customer_name");
  if (phoneIdx === -1) return [];
  return rows.map((row) => {
    const cells = row.split(",");
    return {
      phone: cells[phoneIdx]?.trim() ?? "",
      customer_name: nameIdx !== -1 ? cells[nameIdx]?.trim() ?? null : null,
      variables: null,
    };
  }).filter((r) => r.phone.length >= 10);
}

function statusBadge(status: string) {
  const map: Record<string, string> = {
    sent: "chip chip-sold",
    draft: "chip chip-lost",
    sending: "chip chip-warm",
    failed: "chip chip-hot",
    pending: "chip chip-new",
  };
  return map[status] ?? "chip chip-lost";
}

function recipientBadge(status: string) {
  if (status === "sent") return "chip chip-sold";
  if (status === "failed") return "chip chip-hot";
  if (status === "pending") return "chip chip-new";
  return "chip chip-lost";
}

export function CampaignSenderPage() {
  const [templates, setTemplates] = useState<CampaignTemplateRecord[]>([]);
  const [campaigns, setCampaigns] = useState<CampaignRecord[]>([]);
  const [selectedCampaignId, setSelectedCampaignId] = useState("");
  const [campaignRecipients, setCampaignRecipients] = useState<CampaignRecipientRecord[]>([]);
  const [campaignName, setCampaignName] = useState("");
  const [templateId, setTemplateId] = useState("");
  const [recipientSource, setRecipientSource] = useState<"manual" | "csv">("manual");
  const [manualRecipients, setManualRecipients] = useState("");
  const [csvText, setCsvText] = useState("");
  const [saving, setSaving] = useState(false);
  const [sending, setSending] = useState(false);
  const [sendError, setSendError] = useState<string | null>(null);

  async function loadCampaignData() {
    const [tRows, cRows] = await Promise.all([fetchCampaignTemplates(), fetchCampaigns()]);
    setTemplates(tRows);
    setCampaigns(cRows);
  }

  useEffect(() => { void loadCampaignData(); }, []);

  useEffect(() => {
    let cancelled = false;
    async function loadRecipients() {
      if (!selectedCampaignId) { setCampaignRecipients([]); return; }
      const rows = await fetchCampaignRecipients(selectedCampaignId);
      if (!cancelled) setCampaignRecipients(rows);
    }
    void loadRecipients();
    return () => { cancelled = true; };
  }, [selectedCampaignId]);

  const parsedRecipients = useMemo(
    () => recipientSource === "manual" ? parseManualRecipients(manualRecipients) : parseCsvRecipients(csvText),
    [recipientSource, manualRecipients, csvText]
  );

  async function handleCreate() {
    if (!campaignName || !templateId || parsedRecipients.length === 0) return;
    setSaving(true);
    try {
      const created = await createCampaignWithRecipients({
        name: campaignName, template_id: templateId, recipient_source: recipientSource,
        payload: { upload_mode: recipientSource }, recipients: parsedRecipients,
      });
      setCampaignName(""); setTemplateId(""); setManualRecipients(""); setCsvText("");
      setSelectedCampaignId(created.id);
      await loadCampaignData();
    } finally { setSaving(false); }
  }

  async function handleSend() {
    if (!selectedCampaignId) return;
    setSending(true);
    setSendError(null);
    try {
      await sendCampaign(selectedCampaignId);
      await loadCampaignData();
      setCampaignRecipients(await fetchCampaignRecipients(selectedCampaignId));
    } catch (error) {
      console.error("[CampaignSenderPage] Failed to send campaign", error);
      if (error instanceof Error) {
        setSendError(error.message);
      } else {
        setSendError("Failed to send campaign. Please try again.");
      }
    } finally { setSending(false); }
  }

  const selectedCampaign = campaigns.find((c) => c.id === selectedCampaignId);

  const sentCount = campaignRecipients.filter((r) => r.send_status === "sent").length;
  const failedCount = campaignRecipients.filter((r) => r.send_status === "failed").length;
  const pendingCount = campaignRecipients.filter((r) => r.send_status === "pending").length;

  return (
    <div className="flex flex-col">
      {/* Top bar */}
      <header className="flex items-center justify-between border-b border-slate-200 bg-white px-6 py-3.5">
        <div>
          <h2 className="text-[16px] font-semibold text-ink">Campaigns</h2>
          <p className="text-[11px] text-slate-400">{campaigns.length} campaigns · {templates.length} approved templates</p>
        </div>
      </header>

      <div className="p-5">
        <div className="grid grid-cols-2 gap-5">

          {/* ── Left: Create ── */}
          <div className="flex flex-col gap-4">
            <div className="panel p-5">
              <p className="mb-4 text-[13px] font-semibold text-ink">Create new campaign</p>

              <div className="flex flex-col gap-3">
                <div>
                  <label className="field-label">Campaign name</label>
                  <input className="field-input text-[12px]" placeholder="e.g. Nexon EV March Offer" value={campaignName} onChange={(e) => setCampaignName(e.target.value)} />
                </div>

                <div>
                  <label className="field-label">WhatsApp template</label>
                  <select className="field-input text-[12px]" value={templateId} onChange={(e) => setTemplateId(e.target.value)}>
                    <option value="">Select a template…</option>
                    {templates.map((t) => (
                      <option key={t.id} value={t.id}>{t.template_name}</option>
                    ))}
                  </select>
                </div>

                {templateId && templates.find((t) => t.id === templateId)?.body_example && (
                  <div className="rounded-xl bg-emerald-50 p-3">
                    <p className="mb-1 text-[9px] font-bold uppercase tracking-wide text-emerald-600">Message preview</p>
                    <p className="whitespace-pre-wrap text-[12px] leading-relaxed text-slate-700">
                      {templates.find((t) => t.id === templateId)?.body_example}
                    </p>
                  </div>
                )}

                <div>
                  <label className="field-label">Recipients</label>
                  <div className="mb-2 flex gap-2">
                    {(["manual", "csv"] as const).map((mode) => (
                      <button
                        key={mode}
                        type="button"
                        onClick={() => setRecipientSource(mode)}
                        className={`rounded-lg px-3 py-1.5 text-[11px] font-semibold capitalize transition ${
                          recipientSource === mode ? "bg-[#152033] text-white" : "bg-slate-100 text-slate-500 hover:bg-slate-200"
                        }`}
                      >
                        {mode === "manual" ? "Manual entry" : "CSV paste"}
                      </button>
                    ))}
                  </div>

                  {recipientSource === "manual" ? (
                    <>
                      <textarea
                        className="field-input min-h-[100px] font-mono text-[12px]"
                        placeholder={"One per line: phone, name\n+919829000001, Ravi Sharma\n+919929000002, Priya Singh"}
                        value={manualRecipients}
                        onChange={(e) => setManualRecipients(e.target.value)}
                      />
                      {parsedRecipients.length > 0 && (
                        <p className="mt-1 text-[11px] text-emerald-600">{parsedRecipients.length} recipients parsed</p>
                      )}
                    </>
                  ) : (
                    <>
                      <textarea
                        className="field-input min-h-[100px] font-mono text-[12px]"
                        placeholder={"phone,customer_name\n+919829000001,Ravi Sharma"}
                        value={csvText}
                        onChange={(e) => setCsvText(e.target.value)}
                      />
                      {parsedRecipients.length > 0 && (
                        <p className="mt-1 text-[11px] text-emerald-600">{parsedRecipients.length} recipients parsed</p>
                      )}
                    </>
                  )}
                </div>

                <button
                  type="button"
                  className="action-button w-full text-[12px]"
                  disabled={saving || !campaignName || !templateId || parsedRecipients.length === 0}
                  onClick={() => void handleCreate()}
                >
                  {saving ? "Creating…" : `Create campaign (${parsedRecipients.length} recipients)`}
                </button>
              </div>
            </div>
          </div>

          {/* ── Right: View & Send ── */}
          <div className="flex flex-col gap-4">
            <div className="panel p-5">
              <p className="mb-3 text-[13px] font-semibold text-ink">Campaign history</p>

              {campaigns.length === 0 ? (
                <p className="text-[12px] text-slate-400">No campaigns yet.</p>
              ) : (
                <div className="flex flex-col divide-y divide-slate-100">
                  {campaigns.map((c) => (
                    <button
                      key={c.id}
                      type="button"
                      onClick={() => setSelectedCampaignId(c.id)}
                      className={`flex items-center justify-between gap-3 py-3 text-left transition-colors hover:bg-slate-50 px-2 -mx-2 rounded-xl ${
                        selectedCampaignId === c.id ? "bg-indigo-50/60" : ""
                      }`}
                    >
                      <div className="min-w-0">
                        <p className="truncate text-[12px] font-semibold text-ink">{c.name}</p>
                        <p className="text-[10px] text-slate-400">
                          {new Date(c.created_at).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" })}
                        </p>
                      </div>
                      <span className={statusBadge(c.status)}>{c.status}</span>
                    </button>
                  ))}
                </div>
              )}
            </div>

            {selectedCampaign && (
              <div className="panel p-5">
                <div className="mb-4 flex items-start justify-between">
                  <div>
                    <p className="text-[13px] font-semibold text-ink">{selectedCampaign.name}</p>
                    <span className={`mt-1 ${statusBadge(selectedCampaign.status)}`}>{selectedCampaign.status}</span>
                  </div>
                  {selectedCampaign.status === "draft" && (
                    <button
                      type="button"
                      className="action-button text-[12px]"
                      disabled={sending}
                      onClick={() => void handleSend()}
                    >
                      {sending ? "Sending…" : `Send to ${campaignRecipients.length} recipients`}
                    </button>
                  )}
                </div>

                {sendError && (
                  <div className="mb-3 rounded-xl border border-red-100 bg-red-50 px-3 py-2 text-[11px] text-red-700">
                    {sendError}
                  </div>
                )}

                {/* Stats */}
                {campaignRecipients.length > 0 && (
                  <>
                    <div className="mb-3 grid grid-cols-3 gap-2">
                      {[
                        { label: "Sent", value: sentCount, color: "text-emerald-600" },
                        { label: "Pending", value: pendingCount, color: "text-indigo-600" },
                        { label: "Failed", value: failedCount, color: "text-red-600" },
                      ].map(({ label, value, color }) => (
                        <div key={label} className="flex flex-col items-center rounded-xl bg-slate-50 py-3">
                          <span className={`text-[20px] font-bold ${color}`}>{value}</span>
                          <span className="text-[10px] text-slate-400">{label}</span>
                        </div>
                      ))}
                    </div>

                    <div className="max-h-[200px] overflow-y-auto rounded-xl border border-slate-100">
                      <table className="w-full text-[11px]">
                        <thead className="sticky top-0 bg-slate-50">
                          <tr>
                            <th className="px-3 py-2 text-left font-semibold text-slate-400">Phone</th>
                            <th className="px-3 py-2 text-left font-semibold text-slate-400">Name</th>
                            <th className="px-3 py-2 text-left font-semibold text-slate-400">Status</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-50">
                          {campaignRecipients.map((r) => (
                            <tr key={r.id}>
                              <td className="px-3 py-2 font-mono text-slate-600">{r.phone}</td>
                              <td className="px-3 py-2 text-slate-600">{r.customer_name ?? "—"}</td>
                              <td className="px-3 py-2"><span className={recipientBadge(r.send_status)}>{r.send_status}</span></td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
