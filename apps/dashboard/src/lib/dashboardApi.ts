import { supabase } from "./supabase";
import type {
  AppUserRecord,
  CampaignRecord,
  CampaignRecipientRecord,
  CampaignTemplateRecord,
  ConversationRecord,
  LeadRecord,
  MessageRecord,
  PricingRuleRecord,
  VariantRecord,
} from "../types";

export async function fetchLeads(
  search: string,
  leadStatus: string,
): Promise<LeadRecord[]> {
  let query = supabase
    .from("leads")
    .select("*")
    .order("created_at", { ascending: false });

  if (leadStatus !== "all") {
    query = query.eq("lead_status", leadStatus);
  }

  if (search.trim()) {
    const term = `%${search.trim()}%`;
    query = query.or(`phone.ilike.${term},customer_name.ilike.${term}`);
  }

  const { data, error } = await query;

  if (error) {
    console.error("[dashboardApi] Failed to fetch leads", error);
    throw error;
  }

  return (data ?? []) as LeadRecord[];
}

export async function fetchLeadById(leadId: string): Promise<LeadRecord | null> {
  const { data, error } = await supabase
    .from("leads")
    .select("*")
    .eq("id", leadId)
    .maybeSingle();

  if (error) {
    console.error("[dashboardApi] Failed to fetch lead", error);
    throw error;
  }

  return data as LeadRecord | null;
}

export async function fetchConversationByLeadId(
  leadId: string,
): Promise<ConversationRecord | null> {
  const { data, error } = await supabase
    .from("conversations")
    .select("*")
    .eq("lead_id", leadId)
    .order("last_message_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) {
    console.error("[dashboardApi] Failed to fetch conversation by lead id", error);
    throw error;
  }

  return data as ConversationRecord | null;
}

export async function fetchConversationById(
  conversationId: string,
): Promise<ConversationRecord | null> {
  const { data, error } = await supabase
    .from("conversations")
    .select("*")
    .eq("id", conversationId)
    .maybeSingle();

  if (error) {
    console.error("[dashboardApi] Failed to fetch conversation", error);
    throw error;
  }

  return data as ConversationRecord | null;
}

export async function fetchMessages(
  conversationId: string,
): Promise<MessageRecord[]> {
  const { data, error } = await supabase
    .from("messages")
    .select("*")
    .eq("conversation_id", conversationId)
    .order("created_at", { ascending: true });

  if (error) {
    console.error("[dashboardApi] Failed to fetch messages", error);
    throw error;
  }

  return (data ?? []) as MessageRecord[];
}

export async function fetchAppUsers(): Promise<AppUserRecord[]> {
  const { data, error } = await supabase
    .from("app_users")
    .select("*")
    .eq("is_active", true)
    .order("full_name", { ascending: true });

  if (error) {
    console.error("[dashboardApi] Failed to fetch app users", error);
    throw error;
  }

  return (data ?? []) as AppUserRecord[];
}

export async function updateLeadNotes(leadId: string, notes: string) {
  const { error } = await supabase
    .from("leads")
    .update({ notes })
    .eq("id", leadId);

  if (error) {
    console.error("[dashboardApi] Failed to update lead notes", error);
    throw error;
  }
}

export async function updateLeadOwner(
  leadId: string,
  ownerId: string | null,
) {
  const { error } = await supabase
    .from("leads")
    .update({ assigned_to: ownerId })
    .eq("id", leadId);

  if (error) {
    console.error("[dashboardApi] Failed to update lead owner", error);
    throw error;
  }
}

export async function fetchVariants(): Promise<VariantRecord[]> {
  const { data, error } = await supabase
    .from("variants")
    .select("*")
    .order("created_at", { ascending: false });

  if (error) {
    console.error("[dashboardApi] Failed to fetch variants", error);
    throw error;
  }

  return ((data ?? []) as Array<Omit<VariantRecord, "ex_showroom_price"> & { ex_showroom_price: number | string }>).map(
    (variant) => ({
      ...variant,
      ex_showroom_price: Number(variant.ex_showroom_price),
    }),
  );
}

export async function saveVariant(
  variant: Partial<VariantRecord>,
): Promise<void> {
  const payload = {
    ...variant,
    ex_showroom_price: variant.ex_showroom_price ?? 0,
  };

  const { error } = variant.id
    ? await supabase.from("variants").update(payload).eq("id", variant.id)
    : await supabase.from("variants").insert(payload);

  if (error) {
    console.error("[dashboardApi] Failed to save variant", error);
    throw error;
  }
}

export async function fetchPricingRules(): Promise<PricingRuleRecord[]> {
  const { data, error } = await supabase
    .from("pricing_rules")
    .select("*")
    .order("created_at", { ascending: false });

  if (error) {
    console.error("[dashboardApi] Failed to fetch pricing rules", error);
    throw error;
  }

  return ((data ?? []) as Array<Omit<PricingRuleRecord, "value"> & { value: number | string }>).map(
    (rule) => ({
      ...rule,
      value: Number(rule.value),
    }),
  );
}

export async function savePricingRule(
  rule: Partial<PricingRuleRecord>,
): Promise<void> {
  const payload = {
    ...rule,
    value: rule.value ?? 0,
  };

  const { error } = rule.id
    ? await supabase.from("pricing_rules").update(payload).eq("id", rule.id)
    : await supabase.from("pricing_rules").insert(payload);

  if (error) {
    console.error("[dashboardApi] Failed to save pricing rule", error);
    throw error;
  }
}

export async function fetchCampaignTemplates(): Promise<CampaignTemplateRecord[]> {
  const { data, error } = await supabase
    .from("campaign_templates")
    .select("*")
    .eq("is_active", true)
    .order("template_name", { ascending: true });

  if (error) {
    console.error("[dashboardApi] Failed to fetch campaign templates", error);
    throw error;
  }

  return (data ?? []) as CampaignTemplateRecord[];
}

export async function fetchCampaigns(): Promise<CampaignRecord[]> {
  const { data, error } = await supabase
    .from("campaigns")
    .select("*")
    .order("created_at", { ascending: false });

  if (error) {
    console.error("[dashboardApi] Failed to fetch campaigns", error);
    throw error;
  }

  return (data ?? []) as CampaignRecord[];
}

export async function fetchCampaignRecipients(
  campaignId: string,
): Promise<CampaignRecipientRecord[]> {
  const { data, error } = await supabase
    .from("campaign_recipients")
    .select("*")
    .eq("campaign_id", campaignId)
    .order("created_at", { ascending: true });

  if (error) {
    console.error("[dashboardApi] Failed to fetch campaign recipients", error);
    throw error;
  }

  return (data ?? []) as CampaignRecipientRecord[];
}

export async function createCampaignWithRecipients(input: {
  name: string;
  template_id: string;
  recipient_source: "manual" | "csv";
  payload?: Record<string, unknown> | null;
  recipients: Array<{
    phone: string;
    customer_name: string | null;
    variables: Record<string, unknown> | null;
  }>;
}): Promise<CampaignRecord> {
  const { data: campaign, error: campaignError } = await supabase
    .from("campaigns")
    .insert({
      name: input.name,
      template_id: input.template_id,
      status: "draft",
      recipient_source: input.recipient_source,
      payload: input.payload ?? null,
      created_by: null,
    })
    .select("*")
    .single();

  if (campaignError || !campaign) {
    console.error("[dashboardApi] Failed to create campaign", campaignError);
    throw campaignError;
  }

  if (input.recipients.length > 0) {
    const { error: recipientError } = await supabase
      .from("campaign_recipients")
      .insert(
        input.recipients.map((recipient) => ({
          campaign_id: campaign.id,
          phone: recipient.phone,
          customer_name: recipient.customer_name,
          variables: recipient.variables,
          send_status: "pending",
          error_message: null,
          sent_at: null,
        })),
      );

    if (recipientError) {
      console.error("[dashboardApi] Failed to attach campaign recipients", recipientError);
      throw recipientError;
    }
  }

  return campaign as CampaignRecord;
}

export async function sendCampaign(campaignId: string): Promise<void> {
  const { error } = await supabase.functions.invoke("campaign-sender", {
    body: { campaign_id: campaignId },
  });

  if (error) {
    console.error("[dashboardApi] Failed to invoke campaign sender", error);
    throw error;
  }
}
