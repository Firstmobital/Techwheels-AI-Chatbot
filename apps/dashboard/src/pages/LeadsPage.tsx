import { useEffect, useRef, useState } from "react";
import clsx from "clsx";
import {
  fetchAppUsers,
  fetchConversationByLeadId,
  fetchLeads,
  fetchMessages,
  updateLeadNotes,
  updateLeadOwner,
} from "../lib/dashboardApi";
import { supabase } from "../lib/supabase";
import { useDashboardStore } from "../store/useDashboardStore";
import type { ConversationRecord, LeadRecord, MessageRecord } from "../types";

/* ─── helpers ─────────────────────────────────────────────── */

function statusChipClass(status: string) {
  const map: Record<string, string> = {
    hot: "chip chip-hot",
    warm: "chip chip-warm",
    new: "chip chip-new",
    qualified: "chip chip-qualified",
    sold: "chip chip-sold",
    lost: "chip chip-lost",
  };
  return map[status] ?? "chip chip-lost";
}

function avatarColors(name: string) {
  const palettes = [
    { bg: "bg-indigo-50", text: "text-indigo-600" },
    { bg: "bg-rose-50",   text: "text-rose-600" },
    { bg: "bg-emerald-50",text: "text-emerald-700" },
    { bg: "bg-amber-50",  text: "text-amber-700" },
    { bg: "bg-violet-50", text: "text-violet-700" },
    { bg: "bg-sky-50",    text: "text-sky-700" },
  ];
  const idx = (name.charCodeAt(0) ?? 0) % palettes.length;
  return palettes[idx];
}

function initials(name: string | null, phone: string) {
  if (!name) return phone.slice(-2);
  const parts = name.trim().split(" ");
  return parts.length >= 2
    ? `${parts[0][0]}${parts[1][0]}`.toUpperCase()
    : name.slice(0, 2).toUpperCase();
}

function relativeTime(iso: string | null | undefined) {
  if (!iso) return "";
  const diff = Date.now() - new Date(iso).getTime();
  const m = Math.floor(diff / 60000);
  if (m < 1) return "just now";
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  return `${Math.floor(h / 24)}d ago`;
}

function formatMsgTime(iso: string) {
  return new Date(iso).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
}

function formatMsgDate(iso: string) {
  const d = new Date(iso);
  const today = new Date();
  const yesterday = new Date(today);
  yesterday.setDate(today.getDate() - 1);
  if (d.toDateString() === today.toDateString()) return "Today";
  if (d.toDateString() === yesterday.toDateString()) return "Yesterday";
  return d.toLocaleDateString("en-IN", { day: "numeric", month: "short" });
}

/* ─── sub-components ──────────────────────────────────────── */

function LeadRow({
  lead,
  lastMsgAt,
  selected,
  onClick,
}: {
  lead: LeadRecord;
  lastMsgAt: string | null;
  selected: boolean;
  onClick: () => void;
}) {
  const name = lead.customer_name ?? lead.phone;
  const av = avatarColors(name);

  return (
    <button
      type="button"
      onClick={onClick}
      className={clsx(
        "flex w-full items-center gap-3 px-4 py-3 text-left transition-colors",
        "border-b border-slate-100 hover:bg-slate-50",
        selected && "bg-indigo-50/70 border-l-[3px] border-l-accent"
      )}
    >
      {/* Avatar */}
      <div
        className={clsx(
          "flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-xs font-bold",
          av.bg, av.text
        )}
      >
        {initials(lead.customer_name, lead.phone)}
      </div>

      {/* Info */}
      <div className="min-w-0 flex-1">
        <div className="flex items-center justify-between gap-1">
          <span className="truncate text-[13px] font-semibold text-ink">{name}</span>
          <span className="shrink-0 text-[10px] text-slate-400">{relativeTime(lastMsgAt)}</span>
        </div>
        <div className="mt-0.5 flex items-center gap-2">
          <span className={statusChipClass(lead.lead_status)}>{lead.lead_status}</span>
          {lead.interested_model && (
            <span className="truncate text-[11px] text-slate-400">{lead.interested_model}</span>
          )}
        </div>
      </div>
    </button>
  );
}

function ChatBubble({ msg }: { msg: MessageRecord }) {
  const isOut = msg.direction === "outbound";
  return (
    <div className={clsx("flex flex-col gap-0.5", isOut ? "items-end" : "items-start")}>
      {isOut && <span className="ai-tag">AI reply</span>}
      <div className={isOut ? "bubble-out" : "bubble-in"}>
        {msg.content ?? "(no content)"}
        <div className={isOut ? "bubble-time-out" : "bubble-time-in"}>
          {formatMsgTime(msg.created_at)}
        </div>
      </div>
    </div>
  );
}

/* ─── main page ───────────────────────────────────────────── */

export function LeadsPage() {
  const { leadSearch, leadStatusFilter, setLeadSearch, setLeadStatusFilter } =
    useDashboardStore();

  const [leads, setLeads] = useState<LeadRecord[]>([]);
  const [lastMsgMap, setLastMsgMap] = useState<Record<string, string | null>>({});
  const [loading, setLoading] = useState(true);

  // selected lead + its conversation/messages
  const [selectedLead, setSelectedLead] = useState<LeadRecord | null>(null);
  const [conversation, setConversation] = useState<ConversationRecord | null>(null);
  const [messages, setMessages] = useState<MessageRecord[]>([]);
  const [chatLoading, setChatLoading] = useState(false);

  // lead detail panel (notes / assign)
  const [notes, setNotes] = useState("");
  const [ownerId, setOwnerId] = useState("");
  const [users, setUsers] = useState<{ id: string; full_name: string | null }[]>([]);
  const [saving, setSaving] = useState(false);
  const [showDetail, setShowDetail] = useState(false);

  const chatEndRef = useRef<HTMLDivElement>(null);

  /* load leads list */
  useEffect(() => {
    let cancelled = false;
    async function load() {
      setLoading(true);
      try {
        const [leadRows, convRows] = await Promise.all([
          fetchLeads(leadSearch, leadStatusFilter),
          supabase
            .from("conversations")
            .select("lead_id, last_message_at")
            .not("lead_id", "is", null)
            .order("last_message_at", { ascending: false }),
        ]);

        if (convRows.error) throw convRows.error;

        const map: Record<string, string | null> = {};
        for (const row of (convRows.data ?? []) as { lead_id: string; last_message_at: string | null }[]) {
          if (row.lead_id && !map[row.lead_id]) map[row.lead_id] = row.last_message_at;
        }

        if (!cancelled) {
          setLeads(leadRows);
          setLastMsgMap(map);
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    }
    void load();
    return () => { cancelled = true; };
  }, [leadSearch, leadStatusFilter]);

  /* load users once */
  useEffect(() => {
    fetchAppUsers().then(setUsers).catch(console.error);
  }, []);

  /* load chat when lead is selected */
  async function selectLead(lead: LeadRecord) {
    setSelectedLead(lead);
    setShowDetail(false);
    setNotes(lead.notes ?? "");
    setOwnerId(lead.assigned_to ?? "");
    setChatLoading(true);
    setMessages([]);
    setConversation(null);
    try {
      const conv = await fetchConversationByLeadId(lead.id);
      setConversation(conv);
      if (conv) {
        const msgs = await fetchMessages(conv.id);
        setMessages(msgs);
      }
    } finally {
      setChatLoading(false);
    }
  }

  /* auto-scroll chat */
  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  /* save lead edits */
  async function handleSave() {
    if (!selectedLead) return;
    setSaving(true);
    try {
      await Promise.all([
        updateLeadNotes(selectedLead.id, notes),
        updateLeadOwner(selectedLead.id, ownerId || null),
      ]);
    } finally {
      setSaving(false);
    }
  }

  /* group messages by date */
  const groupedMessages: { date: string; msgs: MessageRecord[] }[] = [];
  for (const msg of messages) {
    const label = formatMsgDate(msg.created_at);
    const last = groupedMessages[groupedMessages.length - 1];
    if (last?.date === label) last.msgs.push(msg);
    else groupedMessages.push({ date: label, msgs: [msg] });
  }

  const statusFilters = ["all", "new", "qualified", "warm", "hot", "sold", "lost"];

  return (
    <div className="flex h-screen flex-col overflow-hidden">
      {/* ── Top bar ── */}
      <header className="flex items-center justify-between border-b border-slate-200 bg-white px-6 py-3.5">
        <div>
          <h2 className="text-[16px] font-semibold text-ink">Leads</h2>
          <p className="text-[11px] text-slate-400">
            {loading ? "Loading…" : `${leads.length} leads`}
            {leadStatusFilter !== "all" && ` · filtered by ${leadStatusFilter}`}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="rounded-full bg-emerald-50 px-2.5 py-0.5 text-[10px] font-bold text-emerald-700">
            Live
          </span>
          <div className="flex h-7 w-7 items-center justify-center rounded-full bg-[#152033] text-[10px] font-semibold text-white">
            TW
          </div>
        </div>
      </header>

      {/* ── Body: 3-column split ── */}
      <div className="flex flex-1 overflow-hidden">

        {/* Col 1 — Leads list */}
        <div className="flex w-[260px] shrink-0 flex-col border-r border-slate-200 bg-white">
          {/* Search */}
          <div className="p-3">
            <div className="flex items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-3 py-2">
              <svg width="13" height="13" viewBox="0 0 13 13" fill="none" stroke="#aab0be" strokeWidth="1.5">
                <circle cx="5.5" cy="5.5" r="4" />
                <path d="M9 9l2.5 2.5" />
              </svg>
              <input
                className="w-full bg-transparent text-[12px] text-ink outline-none placeholder:text-slate-400"
                placeholder="Search name or phone…"
                value={leadSearch}
                onChange={(e) => setLeadSearch(e.target.value)}
              />
            </div>
          </div>

          {/* Status filter pills */}
          <div className="flex gap-1.5 overflow-x-auto px-3 pb-2 scrollbar-none">
            {statusFilters.map((f) => (
              <button
                key={f}
                type="button"
                onClick={() => setLeadStatusFilter(f)}
                className={clsx(
                  "shrink-0 rounded-full px-3 py-1 text-[11px] font-semibold capitalize transition",
                  leadStatusFilter === f
                    ? "bg-[#152033] text-white"
                    : "bg-slate-100 text-slate-500 hover:bg-slate-200"
                )}
              >
                {f}
              </button>
            ))}
          </div>

          {/* Lead rows */}
          <div className="flex-1 overflow-y-auto">
            {loading ? (
              <p className="p-4 text-[12px] text-slate-400">Loading leads…</p>
            ) : leads.length === 0 ? (
              <p className="p-4 text-[12px] text-slate-400">No leads found.</p>
            ) : (
              leads.map((lead) => (
                <LeadRow
                  key={lead.id}
                  lead={lead}
                  lastMsgAt={lastMsgMap[lead.id] ?? null}
                  selected={selectedLead?.id === lead.id}
                  onClick={() => void selectLead(lead)}
                />
              ))
            )}
          </div>
        </div>

        {/* Col 2 — WhatsApp chat */}
        <div className="flex flex-1 flex-col bg-[#f9f9fc]">
          {!selectedLead ? (
            <div className="flex flex-1 flex-col items-center justify-center gap-3 text-slate-400">
              <svg width="40" height="40" viewBox="0 0 40 40" fill="none" stroke="#cbd5e1" strokeWidth="1.5">
                <path d="M20 4C11.2 4 4 11.2 4 20c0 2.8.7 5.4 2 7.7L4 36l8.5-2c2.2 1.2 4.7 1.9 7.5 1.9 8.8 0 16-7.2 16-16S28.8 4 20 4z"/>
              </svg>
              <p className="text-[13px]">Select a lead to view conversation</p>
            </div>
          ) : (
            <>
              {/* Chat header */}
              <div className="flex items-center gap-3 border-b border-slate-200 bg-white px-5 py-3">
                {(() => {
                  const name = selectedLead.customer_name ?? selectedLead.phone;
                  const av = avatarColors(name);
                  return (
                    <div className={clsx("flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-xs font-bold", av.bg, av.text)}>
                      {initials(selectedLead.customer_name, selectedLead.phone)}
                    </div>
                  );
                })()}
                <div className="flex-1 min-w-0">
                  <p className="text-[13px] font-semibold text-ink truncate">
                    {selectedLead.customer_name ?? selectedLead.phone}
                  </p>
                  <p className="text-[11px] text-slate-400">
                    {selectedLead.phone}
                    {selectedLead.interested_model && ` · ${selectedLead.interested_model}`}
                  </p>
                </div>
                <span className={statusChipClass(selectedLead.lead_status)}>
                  {selectedLead.lead_status}
                </span>
                <button
                  type="button"
                  onClick={() => setShowDetail(!showDetail)}
                  className="secondary-button text-[11px]"
                >
                  {showDetail ? "Hide profile" : "Profile"}
                </button>
              </div>

              {/* Messages */}
              <div className="flex-1 overflow-y-auto px-5 py-4">
                {chatLoading ? (
                  <p className="text-center text-[12px] text-slate-400">Loading messages…</p>
                ) : messages.length === 0 ? (
                  <p className="text-center text-[12px] text-slate-400">No messages yet in this conversation.</p>
                ) : (
                  <div className="flex flex-col gap-4">
                    {groupedMessages.map(({ date, msgs }) => (
                      <div key={date}>
                        <div className="mb-3 text-center text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                          {date}
                        </div>
                        <div className="flex flex-col gap-2">
                          {msgs.map((msg) => (
                            <ChatBubble key={msg.id} msg={msg} />
                          ))}
                        </div>
                      </div>
                    ))}
                    <div ref={chatEndRef} />
                  </div>
                )}
              </div>

              {/* Reply bar */}
              <div className="flex items-center gap-3 border-t border-slate-200 bg-white px-5 py-3">
                <input
                  className="field-input flex-1 text-[12px]"
                  placeholder="Reply manually (AI handles most messages)…"
                  readOnly
                />
                <button type="button" className="action-button text-[12px]">Send</button>
              </div>
            </>
          )}
        </div>

        {/* Col 3 — Lead profile (slide in) */}
        {showDetail && selectedLead && (
          <div className="flex w-[240px] shrink-0 flex-col gap-4 overflow-y-auto border-l border-slate-200 bg-white p-4">
            <p className="text-[11px] font-bold uppercase tracking-wide text-slate-400">Lead profile</p>

            {/* Quick info */}
            <div className="flex flex-col gap-2">
              {[
                { label: "Phone", value: selectedLead.phone },
                { label: "Status", value: selectedLead.lead_status },
                { label: "Model", value: selectedLead.interested_model },
                { label: "Fuel", value: selectedLead.fuel_type },
                { label: "Transmission", value: selectedLead.transmission },
                { label: "Exchange", value: selectedLead.exchange_required === null ? null : selectedLead.exchange_required ? "Yes" : "No" },
                { label: "City", value: selectedLead.city },
                { label: "Source", value: selectedLead.source },
              ].map(({ label, value }) => (
                <div key={label} className="rounded-xl border border-slate-100 bg-slate-50 px-3 py-2">
                  <p className="text-[9px] font-bold uppercase tracking-wide text-slate-400">{label}</p>
                  <p className="mt-0.5 text-[12px] text-ink">{value ?? "—"}</p>
                </div>
              ))}
            </div>

            <div className="h-px bg-slate-100" />

            {/* Assign */}
            <div>
              <label className="field-label">Assign to</label>
              <select
                className="field-input text-[12px]"
                value={ownerId}
                onChange={(e) => setOwnerId(e.target.value)}
              >
                <option value="">Unassigned</option>
                {users.map((u) => (
                  <option key={u.id} value={u.id}>{u.full_name ?? u.id}</option>
                ))}
              </select>
            </div>

            {/* Notes */}
            <div>
              <label className="field-label">Notes</label>
              <textarea
                className="field-input min-h-[80px] text-[12px]"
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Sales team notes…"
              />
            </div>

            <button
              type="button"
              className="action-button w-full text-[12px]"
              disabled={saving}
              onClick={() => void handleSave()}
            >
              {saving ? "Saving…" : "Save updates"}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
