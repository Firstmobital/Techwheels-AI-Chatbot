import { useEffect, useState } from "react";
import { Panel } from "../components/common/Panel";
import { PageHeader } from "../components/common/PageHeader";
import { supabase } from "../lib/supabase";

type LeadStatusMetric = {
  status: string;
  count: number;
};

type ConversationStateMetric = {
  state: string;
  count: number;
};

type MessageDayMetric = {
  date: string;
  inbound: number;
  outbound: number;
};

type CampaignMetric = {
  id: string;
  name: string;
  status: string;
  sent_at: string | null;
  total: number;
  sent: number;
  failed: number;
};

type LeadRow = {
  lead_status: string | null;
};

type ConversationRow = {
  current_state: string | null;
};

type MessageRow = {
  created_at: string;
  direction: string;
};

type CampaignRow = {
  id: string;
  name: string;
  status: string;
  sent_at: string | null;
  created_at: string;
};

type CampaignRecipientRow = {
  campaign_id: string;
  send_status: string;
};

export function AnalyticsPage() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [leadStatusMetrics, setLeadStatusMetrics] = useState<LeadStatusMetric[]>(
    [],
  );
  const [conversationStateMetrics, setConversationStateMetrics] = useState<
    ConversationStateMetric[]
  >([]);
  const [messageMetrics, setMessageMetrics] = useState<MessageDayMetric[]>([]);
  const [campaignMetrics, setCampaignMetrics] = useState<CampaignMetric[]>([]);

  useEffect(() => {
    async function loadAnalytics() {
      setLoading(true);
      setError(null);

      try {
        const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
          .toISOString();

        const [
          leadsResult,
          conversationsResult,
          messagesResult,
          campaignsResult,
          recipientsResult,
        ] = await Promise.all([
          supabase.from("leads").select("lead_status"),
          supabase.from("conversations").select("current_state"),
          supabase
            .from("messages")
            .select("created_at, direction")
            .gt("created_at", sevenDaysAgo)
            .order("created_at", { ascending: false }),
          supabase
            .from("campaigns")
            .select("id, name, status, sent_at, created_at")
            .order("created_at", { ascending: false })
            .limit(10),
          supabase.from("campaign_recipients").select("campaign_id, send_status"),
        ]);

        if (leadsResult.error) {
          throw new Error(leadsResult.error.message);
        }

        if (conversationsResult.error) {
          throw new Error(conversationsResult.error.message);
        }

        if (messagesResult.error) {
          throw new Error(messagesResult.error.message);
        }

        if (campaignsResult.error) {
          throw new Error(campaignsResult.error.message);
        }

        if (recipientsResult.error) {
          throw new Error(recipientsResult.error.message);
        }

        const leadCounts = new Map<string, number>();
        for (const lead of (leadsResult.data ?? []) as LeadRow[]) {
          const status = lead.lead_status ?? "unknown";
          leadCounts.set(status, (leadCounts.get(status) ?? 0) + 1);
        }
        setLeadStatusMetrics(
          [...leadCounts.entries()]
            .map(([status, count]) => ({ status, count }))
            .sort((a, b) => a.status.localeCompare(b.status)),
        );

        const conversationCounts = new Map<string, number>();
        for (
          const conversation of (conversationsResult.data ?? []) as ConversationRow[]
        ) {
          const state = conversation.current_state ?? "unknown";
          conversationCounts.set(
            state,
            (conversationCounts.get(state) ?? 0) + 1,
          );
        }
        setConversationStateMetrics(
          [...conversationCounts.entries()]
            .map(([state, count]) => ({ state, count }))
            .sort((a, b) => a.state.localeCompare(b.state)),
        );

        const messageCounts = new Map<string, MessageDayMetric>();
        for (const message of (messagesResult.data ?? []) as MessageRow[]) {
          const date = message.created_at.slice(0, 10);
          const existing = messageCounts.get(date) ?? {
            date,
            inbound: 0,
            outbound: 0,
          };

          if (message.direction === "inbound") {
            existing.inbound += 1;
          } else if (message.direction === "outbound") {
            existing.outbound += 1;
          }

          messageCounts.set(date, existing);
        }
        setMessageMetrics(
          [...messageCounts.values()].sort((a, b) => b.date.localeCompare(a.date)),
        );

        const recipientsByCampaign = new Map<
          string,
          { total: number; sent: number; failed: number }
        >();
        for (
          const recipient of (recipientsResult.data ?? []) as CampaignRecipientRow[]
        ) {
          const current = recipientsByCampaign.get(recipient.campaign_id) ?? {
            total: 0,
            sent: 0,
            failed: 0,
          };

          current.total += 1;
          if (recipient.send_status === "sent") {
            current.sent += 1;
          } else if (recipient.send_status === "failed") {
            current.failed += 1;
          }

          recipientsByCampaign.set(recipient.campaign_id, current);
        }

        setCampaignMetrics(
          ((campaignsResult.data ?? []) as CampaignRow[]).map((campaign) => {
            const counts = recipientsByCampaign.get(campaign.id) ?? {
              total: 0,
              sent: 0,
              failed: 0,
            };

            return {
              id: campaign.id,
              name: campaign.name,
              status: campaign.status,
              sent_at: campaign.sent_at,
              total: counts.total,
              sent: counts.sent,
              failed: counts.failed,
            };
          }),
        );
      } catch (loadError) {
        setError(
          loadError instanceof Error
            ? loadError.message
            : "Failed to load analytics.",
        );
      } finally {
        setLoading(false);
      }
    }

    void loadAnalytics();
  }, []);

  if (loading) {
    return (
      <div>
        <PageHeader title="Analytics" description="View dashboard metrics and summaries." />
        <Panel>
          <p className="text-sm text-slate-600">Loading...</p>
        </Panel>
      </div>
    );
  }

  return (
    <div>
      <PageHeader
        title="Analytics"
        description="View dashboard metrics and summaries."
      />

      {error ? (
        <Panel>
          <p className="text-sm text-red-600">{error}</p>
        </Panel>
      ) : null}

      <div className="grid gap-6">
        <Panel title="Total Leads by Status">
          <AnalyticsTable
            columns={["Status", "Count"]}
            rows={leadStatusMetrics.map((metric) => [
              metric.status,
              String(metric.count),
            ])}
          />
        </Panel>

        <Panel title="Conversations by State">
          <AnalyticsTable
            columns={["State", "Count"]}
            rows={conversationStateMetrics.map((metric) => [
              metric.state,
              String(metric.count),
            ])}
          />
        </Panel>

        <Panel title="Messages Last 7 Days">
          <AnalyticsTable
            columns={["Date", "Inbound", "Outbound"]}
            rows={messageMetrics.map((metric) => [
              metric.date,
              String(metric.inbound),
              String(metric.outbound),
            ])}
          />
        </Panel>

        <Panel title="Campaign Performance">
          <AnalyticsTable
            columns={["Campaign", "Status", "Sent At", "Total", "Sent", "Failed"]}
            rows={campaignMetrics.map((metric) => [
              metric.name,
              metric.status,
              metric.sent_at ? formatDateTime(metric.sent_at) : "-",
              String(metric.total),
              String(metric.sent),
              String(metric.failed),
            ])}
          />
        </Panel>
      </div>
    </div>
  );
}

function AnalyticsTable({
  columns,
  rows,
}: {
  columns: string[];
  rows: string[][];
}) {
  return (
    <div className="overflow-x-auto">
      <table className="min-w-full text-sm">
        <thead>
          <tr className="border-b border-slate-200 text-left text-slate-500">
            {columns.map((column) => (
              <th key={column} className="px-3 py-2 font-medium">
                {column}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.length === 0 ? (
            <tr>
              <td
                colSpan={columns.length}
                className="px-3 py-4 text-sm text-slate-500"
              >
                No data available.
              </td>
            </tr>
          ) : (
            rows.map((row, index) => (
              <tr key={`${row[0]}-${index}`} className="border-b border-slate-100">
                {row.map((cell, cellIndex) => (
                  <td key={`${index}-${cellIndex}`} className="px-3 py-2 text-slate-700">
                    {cell}
                  </td>
                ))}
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
}

function formatDateTime(value: string): string {
  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return new Intl.DateTimeFormat("en-IN", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(date);
}
