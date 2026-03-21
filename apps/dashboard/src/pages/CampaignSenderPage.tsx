import { useEffect, useMemo, useState } from "react";
import { PageHeader } from "../components/common/PageHeader";
import { Panel } from "../components/common/Panel";
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

export function CampaignSenderPage() {
  const [templates, setTemplates] = useState<CampaignTemplateRecord[]>([]);
  const [campaigns, setCampaigns] = useState<CampaignRecord[]>([]);
  const [selectedCampaignId, setSelectedCampaignId] = useState<string>("");
  const [campaignRecipients, setCampaignRecipients] = useState<CampaignRecipientRecord[]>([]);
  const [campaignName, setCampaignName] = useState("");
  const [templateId, setTemplateId] = useState("");
  const [recipientSource, setRecipientSource] = useState<"manual" | "csv">("manual");
  const [manualRecipients, setManualRecipients] = useState("");
  const [csvText, setCsvText] = useState("");
  const [saving, setSaving] = useState(false);
  const [sending, setSending] = useState(false);

  async function loadCampaignData() {
    const [templateRows, campaignRows] = await Promise.all([
      fetchCampaignTemplates(),
      fetchCampaigns(),
    ]);
    setTemplates(templateRows);
    setCampaigns(campaignRows);
  }

  useEffect(() => {
    void loadCampaignData();
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function loadRecipients() {
      if (!selectedCampaignId) {
        setCampaignRecipients([]);
        return;
      }

      const recipientRows = await fetchCampaignRecipients(selectedCampaignId);
      if (!cancelled) {
        setCampaignRecipients(recipientRows);
      }
    }

    void loadRecipients();
    return () => {
      cancelled = true;
    };
  }, [selectedCampaignId]);

  const parsedRecipients = useMemo(
    () =>
      recipientSource === "manual"
        ? parseManualRecipients(manualRecipients)
        : parseCsvRecipients(csvText),
    [recipientSource, manualRecipients, csvText],
  );

  async function handleCreateCampaign() {
    if (!campaignName || !templateId || parsedRecipients.length === 0) {
      return;
    }

    setSaving(true);
    try {
      const createdCampaign = await createCampaignWithRecipients({
        name: campaignName,
        template_id: templateId,
        recipient_source: recipientSource,
        payload: {
          upload_mode: recipientSource,
        },
        recipients: parsedRecipients,
      });

      setCampaignName("");
      setTemplateId("");
      setManualRecipients("");
      setCsvText("");
      setSelectedCampaignId(createdCampaign.id);
      await loadCampaignData();
    } finally {
      setSaving(false);
    }
  }

  async function handleSendCampaign() {
    if (!selectedCampaignId) {
      return;
    }

    setSending(true);
    try {
      await sendCampaign(selectedCampaignId);
      await loadCampaignData();
      const recipientRows = await fetchCampaignRecipients(selectedCampaignId);
      setCampaignRecipients(recipientRows);
    } finally {
      setSending(false);
    }
  }

  return (
    <div>
      <PageHeader
        title="Campaign Sender"
        description="Create a simple campaign, attach recipients, and send an approved WhatsApp template."
      />

      <div className="grid gap-6 xl:grid-cols-[1.1fr_0.9fr]">
        <Panel
          title="Campaign Setup"
          description="Phase 1 campaign form with manual list or CSV-style text input."
        >
          <div className="grid gap-4 md:grid-cols-2">
            <div>
              <label className="field-label">Campaign name</label>
              <input
                className="field-input"
                value={campaignName}
                onChange={(event) => setCampaignName(event.target.value)}
                placeholder="Weekend exchange push"
              />
            </div>
            <div>
              <label className="field-label">Template selection</label>
              <select
                className="field-input"
                value={templateId}
                onChange={(event) => setTemplateId(event.target.value)}
              >
                <option value="">Select template</option>
                {templates.map((template) => (
                  <option key={template.id} value={template.id}>
                    {template.template_name}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="field-label">Recipient input mode</label>
              <select
                className="field-input"
                value={recipientSource}
                onChange={(event) =>
                  setRecipientSource(event.target.value as "manual" | "csv")}
              >
                <option value="manual">Manual list</option>
                <option value="csv">CSV text</option>
              </select>
            </div>
            <div className="md:col-span-2">
              <label className="field-label">
                {recipientSource === "manual"
                  ? "Manual recipients"
                  : "CSV upload text"}
              </label>
              <textarea
                className="field-input min-h-40"
                value={recipientSource === "manual" ? manualRecipients : csvText}
                onChange={(event) =>
                  recipientSource === "manual"
                    ? setManualRecipients(event.target.value)
                    : setCsvText(event.target.value)}
                placeholder={
                  recipientSource === "manual"
                    ? "919876543210,Rahul Sharma,Hyundai Creta\n919812345678,Neha Singh,Kia Seltos"
                    : "phone,customer_name,var1,var2\n919876543210,Rahul Sharma,Hyundai Creta,SX"
                }
              />
            </div>
          </div>

          <div className="mt-4 rounded-xl border border-slate-200 bg-slate-50 p-4">
            <div className="text-sm font-medium text-ink">Recipient preview</div>
            <div className="mt-2 text-sm text-slate-600">
              {parsedRecipients.length} recipient(s) parsed
            </div>
            <div className="mt-3 space-y-2 text-sm text-slate-600">
              {parsedRecipients.slice(0, 5).map((recipient) => (
                <div key={`${recipient.phone}-${recipient.customer_name}`}>
                  {recipient.phone} • {recipient.customer_name ?? "No name"}
                </div>
              ))}
            </div>
          </div>

          <div className="mt-4 flex flex-wrap gap-3">
            <button
              className="action-button"
              disabled={saving || !campaignName || !templateId || parsedRecipients.length === 0}
              onClick={() => void handleCreateCampaign()}
            >
              {saving ? "Saving..." : "Create Campaign"}
            </button>
            <button
              className="secondary-button"
              disabled={sending || !selectedCampaignId}
              onClick={() => void handleSendCampaign()}
            >
              {sending ? "Sending..." : "Send Campaign"}
            </button>
          </div>
        </Panel>

        <Panel title="Approved Templates">
          <div className="space-y-3">
            {templates.length === 0 ? (
              <div className="text-sm text-slate-500">
                No active campaign templates found.
              </div>
            ) : (
              templates.map((template) => (
                <div key={template.id} className="rounded-xl border border-slate-200 p-4">
                  <div className="font-medium text-ink">{template.template_name}</div>
                  <div className="mt-1 text-xs uppercase tracking-wide text-slate-500">
                    {template.category} • {template.language_code}
                  </div>
                  <p className="mt-2 text-sm text-slate-600">
                    {template.body_example ?? "No example body saved."}
                  </p>
                </div>
              ))
            )}
          </div>
        </Panel>
      </div>

      <div className="mt-6 grid gap-6 xl:grid-cols-[0.95fr_1.05fr]">
        <Panel title="Recent Campaigns">
          <div className="space-y-3">
            {campaigns.length === 0 ? (
              <div className="text-sm text-slate-500">No campaigns created yet.</div>
            ) : (
              campaigns.map((campaign) => (
                <button
                  key={campaign.id}
                  className={`w-full rounded-xl border p-4 text-left ${
                    selectedCampaignId === campaign.id
                      ? "border-accent bg-accentSoft"
                      : "border-slate-200 bg-white"
                  }`}
                  onClick={() => setSelectedCampaignId(campaign.id)}
                >
                  <div className="font-medium text-ink">{campaign.name}</div>
                  <div className="mt-1 text-xs uppercase tracking-wide text-slate-500">
                    {campaign.status} • {campaign.recipient_source}
                  </div>
                  <div className="mt-2 text-sm text-slate-600">
                    Created {new Date(campaign.created_at).toLocaleString()}
                  </div>
                </button>
              ))
            )}
          </div>
        </Panel>

        <Panel title="Campaign Recipients">
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead>
                <tr className="border-b border-slate-200 text-left text-slate-500">
                  <th className="px-3 py-2 font-medium">Phone</th>
                  <th className="px-3 py-2 font-medium">Name</th>
                  <th className="px-3 py-2 font-medium">Status</th>
                  <th className="px-3 py-2 font-medium">Error</th>
                </tr>
              </thead>
              <tbody>
                {campaignRecipients.map((recipient) => (
                  <tr key={recipient.id} className="border-b border-slate-100">
                    <td className="px-3 py-2">{recipient.phone}</td>
                    <td className="px-3 py-2">{recipient.customer_name ?? "No name"}</td>
                    <td className="px-3 py-2 capitalize">{recipient.send_status}</td>
                    <td className="px-3 py-2 text-rose-600">
                      {recipient.error_message ?? "-"}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Panel>
      </div>
    </div>
  );
}

function parseManualRecipients(input: string): ParsedRecipient[] {
  return input
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => {
      const [phone, customerName, var1, var2] = line.split(",").map((value) =>
        value.trim()
      );

      return {
        phone,
        customer_name: customerName || null,
        variables: buildRecipientVariables([var1, var2]),
      };
    })
    .filter((recipient) => recipient.phone.length > 0);
}

function parseCsvRecipients(input: string): ParsedRecipient[] {
  const lines = input
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean);

  if (lines.length <= 1) {
    return [];
  }

  return lines.slice(1).map((line) => {
    const [phone, customerName, ...variables] = line.split(",").map((value) =>
      value.trim()
    );

    return {
      phone,
      customer_name: customerName || null,
      variables: buildRecipientVariables(variables),
    };
  }).filter((recipient) => recipient.phone.length > 0);
}

function buildRecipientVariables(values: string[]): Record<string, unknown> | null {
  const filteredValues = values.filter((value) => value.length > 0);

  if (filteredValues.length === 0) {
    return null;
  }

  return Object.fromEntries(
    filteredValues.map((value, index) => [`var${index + 1}`, value]),
  );
}
