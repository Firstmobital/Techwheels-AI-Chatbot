import {
  updateConversationCampaign,
  updateConversationFlow,
} from "./conversation-manager.ts";
import { getSupabaseAdminClient } from "./supabase-admin.ts";

export type CampaignResponseContext = {
  campaign_id: string | null;
  is_campaign_message: boolean;
  flow_restarted: boolean;
  next_state: string | null;
  next_step: string | null;
};

type LeadData = {
  customer_name: string | null;
  interested_model: string | null;
  fuel_type: string | null;
  transmission: string | null;
  exchange_required: boolean | null;
};

const AFFIRMATIVE_TEXTS = [
  "yes",
  "interested",
  "i am interested",
  "haan",
  "ha",
  "ok",
];

export async function handleCampaignResponseTransition(input: {
  conversationId: string;
  phone: string;
  messageType: string;
  content: string | null;
  lead?: LeadData | null;
}): Promise<CampaignResponseContext> {
  const matchedCampaign = await findRecentCampaignByPhone(input.phone);

  if (!matchedCampaign) {
    return {
      campaign_id: null,
      is_campaign_message: false,
      flow_restarted: false,
      next_state: null,
      next_step: null,
    };
  }

  await updateConversationCampaign(
    input.conversationId,
    matchedCampaign.campaign_id,
  );

  if (!isCampaignEngagementResponse(input.messageType, input.content)) {
    return {
      campaign_id: matchedCampaign.campaign_id,
      is_campaign_message: true,
      flow_restarted: false,
      next_state: null,
      next_step: null,
    };
  }

  const lead = input.lead ?? await loadLeadData(input.conversationId);
  const nextFlow = deriveNextConversationFlow(lead);

  await updateConversationFlow(input.conversationId, {
    current_state: nextFlow.current_state,
    current_step: nextFlow.current_step,
    campaign_id: matchedCampaign.campaign_id,
  });

  return {
    campaign_id: matchedCampaign.campaign_id,
    is_campaign_message: true,
    flow_restarted: true,
    next_state: nextFlow.current_state,
    next_step: nextFlow.current_step,
  };
}

async function loadLeadData(conversationId: string): Promise<LeadData | null> {
  const supabase = getSupabaseAdminClient();
  const { data: conversation, error: conversationError } = await supabase
    .from("conversations")
    .select("lead_id")
    .eq("id", conversationId)
    .maybeSingle();

  if (conversationError) {
    console.error("[campaign-response] Failed to load lead context", {
      conversationId,
      error: conversationError,
    });
    throw new Error("Failed to load campaign lead context");
  }

  if (!conversation?.lead_id) {
    return null;
  }

  const { data: lead, error: leadError } = await supabase
    .from("leads")
    .select(
      "customer_name, interested_model, fuel_type, transmission, exchange_required",
    )
    .eq("id", conversation.lead_id)
    .maybeSingle();

  if (leadError) {
    console.error("[campaign-response] Failed to load lead details", {
      conversationId,
      leadId: conversation.lead_id,
      error: leadError,
    });
    throw new Error("Failed to load campaign lead context");
  }

  return (lead as LeadData | null) ?? null;
}

async function findRecentCampaignByPhone(phone: string): Promise<
  {
    campaign_id: string;
  } | null
> {
  const supabase = getSupabaseAdminClient();
  const threshold = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000)
    .toISOString();

  const { data, error } = await supabase
    .from("campaign_recipients")
    .select("campaign_id, sent_at")
    .eq("phone", phone)
    .not("sent_at", "is", null)
    .gte("sent_at", threshold)
    .order("sent_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) {
    console.error(
      "[campaign-response] Failed to load recent campaign recipient",
      {
        phone,
        error,
      },
    );
    throw new Error("Failed to load campaign response context");
  }

  if (!data?.campaign_id) {
    return null;
  }

  return {
    campaign_id: data.campaign_id,
  };
}

function isCampaignEngagementResponse(
  messageType: string,
  content: string | null,
): boolean {
  if (messageType === "button" || messageType === "interactive") {
    return true;
  }

  const normalizedText = (content ?? "").trim().toLowerCase();
  return AFFIRMATIVE_TEXTS.includes(normalizedText);
}

function deriveNextConversationFlow(lead: LeadData | null): {
  current_state: string;
  current_step: string | null;
} {
  if (!lead) {
    return {
      current_state: "lead_capture",
      current_step: "ask_name",
    };
  }

  if (!lead.customer_name) {
    return { current_state: "lead_capture", current_step: "ask_name" };
  }

  if (!lead.interested_model) {
    return { current_state: "lead_capture", current_step: "ask_model" };
  }

  if (!lead.fuel_type) {
    return { current_state: "lead_capture", current_step: "ask_fuel" };
  }

  if (!lead.transmission) {
    return { current_state: "lead_capture", current_step: "ask_transmission" };
  }

  if (lead.exchange_required === null) {
    return { current_state: "lead_capture", current_step: "ask_exchange" };
  }

  return {
    current_state: "qualified",
    current_step: "complete",
  };
}
