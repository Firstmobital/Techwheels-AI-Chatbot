import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { PageHeader } from "../components/common/PageHeader";
import { Panel } from "../components/common/Panel";
import { LeadStatusBadge } from "../components/leads/LeadStatusBadge";
import { fetchAppUsers, fetchLeads } from "../lib/dashboardApi";
import { supabase } from "../lib/supabase";
import { useDashboardStore } from "../store/useDashboardStore";
import type { AppUserRecord, LeadRecord } from "../types";

type ConversationSummaryRow = {
  lead_id: string | null;
  last_message_at: string | null;
};

const kanbanColumns = [
  { key: "new", label: "New" },
  { key: "qualified", label: "Qualified" },
  { key: "warm", label: "Interested" },
  { key: "hot", label: "Hot" },
  { key: "sold", label: "Sold" },
  { key: "lost", label: "Lost" },
] as const;

export function LeadsPage() {
  const {
    leadSearch,
    leadStatusFilter,
    setLeadSearch,
    setLeadStatusFilter,
    setSelectedLeadId,
  } = useDashboardStore();
  const [leads, setLeads] = useState<LeadRecord[]>([]);
  const [kanbanLeads, setKanbanLeads] = useState<LeadRecord[]>([]);
  const [users, setUsers] = useState<AppUserRecord[]>([]);
  const [lastMessageByLeadId, setLastMessageByLeadId] = useState<
    Record<string, string | null>
  >({});
  const [loading, setLoading] = useState(true);
  const [isKanban, setIsKanban] = useState(false);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      setLoading(true);
      try {
        const [leadRows, userRows, allLeadRows, conversationRowsResult] = await Promise.all([
          fetchLeads(leadSearch, leadStatusFilter),
          fetchAppUsers(),
          fetchLeads("", "all"),
          supabase
            .from("conversations")
            .select("lead_id, last_message_at")
            .not("lead_id", "is", null)
            .order("last_message_at", { ascending: false }),
        ]);

        if (conversationRowsResult.error) {
          throw conversationRowsResult.error;
        }

        const nextLastMessageByLeadId: Record<string, string | null> = {};
        for (const conversation of (conversationRowsResult.data ?? []) as ConversationSummaryRow[]) {
          if (!conversation.lead_id || nextLastMessageByLeadId[conversation.lead_id]) {
            continue;
          }

          nextLastMessageByLeadId[conversation.lead_id] = conversation.last_message_at;
        }

        if (!cancelled) {
          setLeads(leadRows);
          setUsers(userRows);
          setKanbanLeads(allLeadRows);
          setLastMessageByLeadId(nextLastMessageByLeadId);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void load();
    return () => {
      cancelled = true;
    };
  }, [leadSearch, leadStatusFilter]);

  const userNameById = new Map(users.map((user) => [user.id, user.full_name ?? "Unassigned"]));

  return (
    <div>
      <PageHeader
        title="Leads List"
        description="Search, filter, and review customer leads from WhatsApp conversations."
      />

      <Panel>
        <div className="flex flex-wrap gap-2">
          <button
            className={`rounded-full px-4 py-2 text-sm font-medium ${
              !isKanban
                ? "bg-ink text-white"
                : "bg-slate-100 text-slate-700"
            }`}
            onClick={() => setIsKanban(false)}
            type="button"
          >
            List View
          </button>
          <button
            className={`rounded-full px-4 py-2 text-sm font-medium ${
              isKanban
                ? "bg-ink text-white"
                : "bg-slate-100 text-slate-700"
            }`}
            onClick={() => setIsKanban(true)}
            type="button"
          >
            Kanban View
          </button>
        </div>
      </Panel>

      {isKanban ? (
        <div className="mt-6 overflow-x-auto pb-2">
          {/* TODO Phase 2: add drag-and-drop to move leads between stages */}
          <div className="grid min-w-[1200px] grid-cols-6 gap-4">
            {kanbanColumns.map((column) => {
              const columnLeads = kanbanLeads.filter((lead) =>
                lead.lead_status === column.key
              );

              return (
                <div
                  key={column.key}
                  className="rounded-2xl border border-slate-200 bg-slate-50 p-4"
                >
                  <div className="mb-4 flex items-center justify-between">
                    <h3 className="text-sm font-semibold text-ink">{column.label}</h3>
                    <span className="rounded-full bg-white px-2.5 py-1 text-xs font-medium text-slate-500">
                      {columnLeads.length}
                    </span>
                  </div>
                  <div className="space-y-3">
                    {loading ? (
                      <div className="rounded-2xl border border-slate-200 bg-white p-4 text-sm text-slate-500">
                        Loading leads...
                      </div>
                    ) : columnLeads.length === 0 ? (
                      <div className="rounded-2xl border border-dashed border-slate-200 bg-white/70 p-4 text-sm text-slate-400">
                        No leads
                      </div>
                    ) : (
                      columnLeads.map((lead) => (
                        <Link
                          key={lead.id}
                          className="block rounded-2xl border border-slate-200 bg-white p-4 shadow-sm transition hover:-translate-y-0.5 hover:border-slate-300 hover:shadow-md"
                          to={`/leads/${lead.id}`}
                          onClick={() => setSelectedLeadId(lead.id)}
                        >
                          <div className="flex items-start justify-between gap-3">
                            <div>
                              <div className="text-sm font-semibold text-ink">
                                {lead.customer_name || lead.phone}
                              </div>
                              <div className="mt-1 text-xs text-slate-500">
                                {[lead.interested_model, lead.fuel_type].filter(Boolean).join(" | ") || "Model not captured"}
                              </div>
                            </div>
                            <span className={getKanbanStatusBadgeClass(lead.lead_status)}>
                              {lead.lead_status}
                            </span>
                          </div>
                          <div className="mt-3 text-xs text-slate-500">
                            {formatRelativeTime(lastMessageByLeadId[lead.id])}
                          </div>
                        </Link>
                      ))
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      ) : (
        <>
          <Panel>
            <div className="grid gap-4 md:grid-cols-[1fr_220px]">
              <div>
                <label className="field-label">Search by phone or customer name</label>
                <input
                  className="field-input"
                  value={leadSearch}
                  onChange={(event) => setLeadSearch(event.target.value)}
                  placeholder="Search leads"
                />
              </div>
              <div>
                <label className="field-label">Lead status</label>
                <select
                  className="field-input"
                  value={leadStatusFilter}
                  onChange={(event) => setLeadStatusFilter(event.target.value)}
                >
                  <option value="all">All</option>
                  <option value="new">New</option>
                  <option value="qualified">Qualified</option>
                  <option value="closed">Closed</option>
                </select>
              </div>
            </div>
          </Panel>

          <div className="mt-6 overflow-hidden rounded-2xl border border-slate-200 bg-white">
            <table className="min-w-full divide-y divide-slate-200 text-sm">
              <thead className="bg-slate-50 text-left text-slate-500">
                <tr>
                  <th className="px-4 py-3 font-medium">Customer</th>
                  <th className="px-4 py-3 font-medium">Phone</th>
                  <th className="px-4 py-3 font-medium">Status</th>
                  <th className="px-4 py-3 font-medium">Assigned To</th>
                  <th className="px-4 py-3 font-medium">Created At</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {loading ? (
                  <tr>
                    <td className="px-4 py-6 text-slate-500" colSpan={5}>
                      Loading leads...
                    </td>
                  </tr>
                ) : leads.length === 0 ? (
                  <tr>
                    <td className="px-4 py-6 text-slate-500" colSpan={5}>
                      No leads found for the current filters.
                    </td>
                  </tr>
                ) : (
                  leads.map((lead) => (
                    <tr key={lead.id} className="hover:bg-slate-50">
                      <td className="px-4 py-4">
                        <Link
                          className="font-medium text-ink hover:text-accent"
                          to={`/leads/${lead.id}`}
                          onClick={() => setSelectedLeadId(lead.id)}
                        >
                          {lead.customer_name ?? "Unnamed lead"}
                        </Link>
                      </td>
                      <td className="px-4 py-4 text-slate-600">{lead.phone}</td>
                      <td className="px-4 py-4">
                        <LeadStatusBadge status={lead.lead_status} />
                      </td>
                      <td className="px-4 py-4 text-slate-600">
                        {lead.assigned_to ? userNameById.get(lead.assigned_to) ?? "Unknown" : "Unassigned"}
                      </td>
                      <td className="px-4 py-4 text-slate-600">
                        {new Date(lead.created_at).toLocaleString()}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </>
      )}
    </div>
  );
}

function formatRelativeTime(value: string | null | undefined): string {
  if (!value) {
    return "No messages yet";
  }

  const timestamp = new Date(value).getTime();

  if (Number.isNaN(timestamp)) {
    return "Unknown";
  }

  const diffMs = Date.now() - timestamp;
  const diffMinutes = Math.max(1, Math.floor(diffMs / (1000 * 60)));

  if (diffMinutes < 60) {
    return `${diffMinutes}m ago`;
  }

  const diffHours = Math.floor(diffMinutes / 60);
  if (diffHours < 24) {
    return `${diffHours}h ago`;
  }

  const diffDays = Math.floor(diffHours / 24);
  if (diffDays < 7) {
    return `${diffDays}d ago`;
  }

  return new Date(value).toLocaleDateString();
}

function getKanbanStatusBadgeClass(status: string): string {
  const baseClass =
    "inline-flex rounded-full px-2.5 py-1 text-xs font-semibold capitalize";

  if (status === "hot") {
    return `${baseClass} bg-red-100 text-red-700`;
  }

  if (status === "warm") {
    return `${baseClass} bg-orange-100 text-orange-700`;
  }

  if (status === "qualified") {
    return `${baseClass} bg-blue-100 text-blue-700`;
  }

  if (status === "new") {
    return `${baseClass} bg-slate-200 text-slate-700`;
  }

  return `${baseClass} bg-slate-100 text-slate-600`;
}
