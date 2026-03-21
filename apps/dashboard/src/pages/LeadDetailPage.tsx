import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { PageHeader } from "../components/common/PageHeader";
import { Panel } from "../components/common/Panel";
import {
  fetchAppUsers,
  fetchConversationByLeadId,
  fetchLeadById,
  updateLeadNotes,
  updateLeadOwner,
} from "../lib/dashboardApi";
import type { AppUserRecord, ConversationRecord, LeadRecord } from "../types";

export function LeadDetailPage() {
  const { leadId = "" } = useParams();
  const [lead, setLead] = useState<LeadRecord | null>(null);
  const [conversation, setConversation] = useState<ConversationRecord | null>(null);
  const [users, setUsers] = useState<AppUserRecord[]>([]);
  const [notes, setNotes] = useState("");
  const [ownerId, setOwnerId] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      const [leadRow, conversationRow, userRows] = await Promise.all([
        fetchLeadById(leadId),
        fetchConversationByLeadId(leadId),
        fetchAppUsers(),
      ]);

      if (!cancelled) {
        setLead(leadRow);
        setConversation(conversationRow);
        setUsers(userRows);
        setNotes(leadRow?.notes ?? "");
        setOwnerId(leadRow?.assigned_to ?? "");
      }
    }

    void load();
    return () => {
      cancelled = true;
    };
  }, [leadId]);

  async function handleSave() {
    if (!lead) return;
    setSaving(true);
    try {
      await Promise.all([
        updateLeadNotes(lead.id, notes),
        updateLeadOwner(lead.id, ownerId || null),
      ]);
      setLead({
        ...lead,
        notes,
        assigned_to: ownerId || null,
      });
    } finally {
      setSaving(false);
    }
  }

  if (!lead) {
    return (
      <div>
        <PageHeader
          title="Lead Detail"
          description="Lead record could not be loaded."
        />
      </div>
    );
  }

  return (
    <div>
      <PageHeader
        title={lead.customer_name ?? "Lead Detail"}
        description={`Lead qualification and ownership for ${lead.phone}.`}
        actions={
          conversation ? (
            <Link className="secondary-button" to={`/conversations/${conversation.id}`}>
              Open Conversation
            </Link>
          ) : null
        }
      />

      <div className="grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
        <Panel title="Qualification Fields">
          <div className="grid gap-4 md:grid-cols-2">
            <Info label="Phone" value={lead.phone} />
            <Info label="Status" value={lead.lead_status} />
            <Info label="Interested Model" value={lead.interested_model} />
            <Info label="Fuel Type" value={lead.fuel_type} />
            <Info label="Transmission" value={lead.transmission} />
            <Info
              label="Exchange Required"
              value={
                lead.exchange_required === null
                  ? "Not captured"
                  : lead.exchange_required
                  ? "Yes"
                  : "No"
              }
            />
            <Info label="Source" value={lead.source} />
            <Info label="City" value={lead.city} />
          </div>
        </Panel>

        <Panel title="Lead Management">
          <div className="space-y-4">
            <div>
              <label className="field-label">Assign owner</label>
              <select
                className="field-input"
                value={ownerId}
                onChange={(event) => setOwnerId(event.target.value)}
              >
                <option value="">Unassigned</option>
                {users.map((user) => (
                  <option key={user.id} value={user.id}>
                    {user.full_name ?? user.id}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="field-label">Notes</label>
              <textarea
                className="field-input min-h-36"
                value={notes}
                onChange={(event) => setNotes(event.target.value)}
                placeholder="Add notes for the sales team"
              />
            </div>

            <button className="action-button" disabled={saving} onClick={() => void handleSave()}>
              {saving ? "Saving..." : "Save Updates"}
            </button>
          </div>
        </Panel>
      </div>
    </div>
  );
}

function Info({ label, value }: { label: string; value: string | null }) {
  return (
    <div className="rounded-xl border border-slate-100 bg-slate-50 px-4 py-3">
      <div className="text-xs font-medium uppercase tracking-wide text-slate-500">
        {label}
      </div>
      <div className="mt-1 text-sm text-ink">{value ?? "Not available"}</div>
    </div>
  );
}
