import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { PageHeader } from "../components/common/PageHeader";
import { Panel } from "../components/common/Panel";
import { LeadStatusBadge } from "../components/leads/LeadStatusBadge";
import { fetchAppUsers, fetchLeads } from "../lib/dashboardApi";
import { useDashboardStore } from "../store/useDashboardStore";
import type { AppUserRecord, LeadRecord } from "../types";

export function LeadsPage() {
  const {
    leadSearch,
    leadStatusFilter,
    setLeadSearch,
    setLeadStatusFilter,
    setSelectedLeadId,
  } = useDashboardStore();
  const [leads, setLeads] = useState<LeadRecord[]>([]);
  const [users, setUsers] = useState<AppUserRecord[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      setLoading(true);
      try {
        const [leadRows, userRows] = await Promise.all([
          fetchLeads(leadSearch, leadStatusFilter),
          fetchAppUsers(),
        ]);

        if (!cancelled) {
          setLeads(leadRows);
          setUsers(userRows);
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
    </div>
  );
}
