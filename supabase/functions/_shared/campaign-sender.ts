import {
  findOrCreateConversationByPhone,
  findOrCreateLeadPlaceholderByPhone,
  insertOutboundMessage,
  updateConversationLastMessageAt,
} from "./conversation-manager.ts";
import { getSupabaseAdminClient } from "./supabase-admin.ts";

type CampaignRecord = {
  id: string;
  name: string;
  template_id: string | null;
  status: string;
  recipient_source: string;
  payload: Record<string, unknown> | null;
  created_by: string | null;
  created_at: string;
  sent_at: string | null;
};

type CampaignTemplateRecord = {
  id: string;
  template_name: string;
  language_code: string;
  category: string;
  header_type: string | null;
  body_example: string | null;
  buttons: unknown;
  is_active: boolean;
};

type CampaignRecipientRecord = {
  id: string;
  campaign_id: string;
  phone: string;
  customer_name: string | null;
  variables: Record<string, unknown> | null;
  send_status: string;
  error_message: string | null;
  sent_at: string | null;
  delivered_at: string | null;
  created_at: string;
};

export type CampaignSendSummary = {
  campaign_id: string;
  total_recipients: number;
  sent_count: number;
  failed_count: number;
};

type WhatsAppTemplateSendResult = {
  whatsapp_message_id: string | null;
  raw_response: unknown;
};

const DEFAULT_WHATSAPP_API_VERSION = "v20.0";

export async function sendCampaignMessages(
  campaignId: string,
): Promise<CampaignSendSummary> {
  const supabase = getSupabaseAdminClient();
  const { campaign, template } = await loadCampaignWithTemplate(campaignId);
  const recipients = await loadCampaignRecipients(campaignId);
  const sendStartedAt = new Date().toISOString();

  if (recipients.length === 0) {
    await updateCampaignStatus(campaignId, "failed", null);
    return {
      campaign_id: campaignId,
      total_recipients: 0,
      sent_count: 0,
      failed_count: 0,
    };
  }

  await updateCampaignStatus(campaignId, "sending", null);

  let sentCount = 0;
  let failedCount = 0;

  for (const recipient of recipients) {
    try {
      const sendResult = await sendWhatsAppTemplateMessage(template, recipient);

      await updateRecipientStatus(recipient.id, {
        send_status: "sent",
        error_message: null,
        sent_at: new Date().toISOString(),
      });

      await persistCampaignOutboundMessage(
        campaign,
        template,
        recipient,
        sendResult,
      );

      sentCount += 1;
    } catch (error) {
      const errorMessage = error instanceof Error
        ? error.message
        : "Unknown WhatsApp send error";

      console.error("[campaign-sender] Failed to send campaign message", {
        campaignId,
        recipientId: recipient.id,
        phone: recipient.phone,
        error,
      });

      await updateRecipientStatus(recipient.id, {
        send_status: "failed",
        error_message: errorMessage,
        sent_at: null,
      });

      failedCount += 1;
    }
  }

  await updateCampaignStatus(
    campaignId,
    failedCount > 0 && sentCount === 0 ? "failed" : "sent",
    sendStartedAt,
  );

  return {
    campaign_id: campaignId,
    total_recipients: recipients.length,
    sent_count: sentCount,
    failed_count: failedCount,
  };
}

async function loadCampaignWithTemplate(
  campaignId: string,
): Promise<{
  campaign: CampaignRecord;
  template: CampaignTemplateRecord;
}> {
  const supabase = getSupabaseAdminClient();

  const { data: campaign, error: campaignError } = await supabase
    .from("campaigns")
    .select("*")
    .eq("id", campaignId)
    .single();

  if (campaignError || !campaign) {
    console.error("[campaign-sender] Failed to load campaign", {
      campaignId,
      error: campaignError,
    });
    throw new Error("Campaign not found");
  }

  if (!campaign.template_id) {
    throw new Error("Campaign template is missing");
  }

  const { data: template, error: templateError } = await supabase
    .from("campaign_templates")
    .select("*")
    .eq("id", campaign.template_id)
    .eq("is_active", true)
    .single();

  if (templateError || !template) {
    console.error("[campaign-sender] Failed to load active campaign template", {
      campaignId,
      templateId: campaign.template_id,
      error: templateError,
    });
    throw new Error("Campaign template not found");
  }

  return {
    campaign: campaign as CampaignRecord,
    template: template as CampaignTemplateRecord,
  };
}

async function loadCampaignRecipients(
  campaignId: string,
): Promise<CampaignRecipientRecord[]> {
  const supabase = getSupabaseAdminClient();

  const { data, error } = await supabase
    .from("campaign_recipients")
    .select("*")
    .eq("campaign_id", campaignId)
    .in("send_status", ["pending", "failed"])
    .order("created_at", { ascending: true });

  if (error) {
    console.error("[campaign-sender] Failed to load campaign recipients", {
      campaignId,
      error,
    });
    throw new Error("Failed to load campaign recipients");
  }

  return (data ?? []) as CampaignRecipientRecord[];
}

async function sendWhatsAppTemplateMessage(
  template: CampaignTemplateRecord,
  recipient: CampaignRecipientRecord,
): Promise<WhatsAppTemplateSendResult> {
  const accessToken = Deno.env.get("WHATSAPP_ACCESS_TOKEN") ?? "";
  const phoneNumberId = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID") ?? "";
  const apiVersion = Deno.env.get("WHATSAPP_API_VERSION") ??
    DEFAULT_WHATSAPP_API_VERSION;

  if (!accessToken || !phoneNumberId) {
    throw new Error("Missing WhatsApp campaign sender configuration");
  }

  const payload = {
    messaging_product: "whatsapp",
    to: recipient.phone,
    type: "template",
    template: {
      name: template.template_name,
      language: {
        code: template.language_code,
      },
      ...(buildTemplateComponents(recipient.variables)),
    },
  };

  const response = await fetch(
    `https://graph.facebook.com/${apiVersion}/${phoneNumberId}/messages`,
    {
      method: "POST",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "content-type": "application/json; charset=utf-8",
      },
      body: JSON.stringify(payload),
    },
  );

  const responseBody = await response.json();

  if (!response.ok) {
    const message = extractWhatsAppErrorMessage(responseBody);
    throw new Error(message);
  }

  const whatsappMessageId =
    Array.isArray(responseBody.messages) && responseBody.messages[0]
      ? responseBody.messages[0].id ?? null
      : null;

  return {
    whatsapp_message_id: whatsappMessageId,
    raw_response: responseBody,
  };
}

function buildTemplateComponents(
  variables: Record<string, unknown> | null,
): { components?: Array<Record<string, unknown>> } {
  if (!variables) {
    return {};
  }

  const orderedValues = Object.keys(variables)
    .sort()
    .map((key) => variables[key])
    .filter((value) => value !== undefined && value !== null)
    .map((value) => ({
      type: "text",
      text: String(value),
    }));

  if (orderedValues.length === 0) {
    return {};
  }

  return {
    components: [
      {
        type: "body",
        parameters: orderedValues,
      },
    ],
  };
}

function extractWhatsAppErrorMessage(responseBody: unknown): string {
  if (
    responseBody &&
    typeof responseBody === "object" &&
    "error" in responseBody &&
    responseBody.error &&
    typeof responseBody.error === "object" &&
    "message" in responseBody.error &&
    typeof responseBody.error.message === "string"
  ) {
    return responseBody.error.message;
  }

  return "WhatsApp template send failed";
}

async function updateRecipientStatus(
  recipientId: string,
  values: {
    send_status: string;
    error_message: string | null;
    sent_at: string | null;
  },
): Promise<void> {
  const supabase = getSupabaseAdminClient();
  const { error } = await supabase
    .from("campaign_recipients")
    .update(values)
    .eq("id", recipientId);

  if (error) {
    console.error("[campaign-sender] Failed to update recipient status", {
      recipientId,
      values,
      error,
    });
    throw new Error("Failed to update campaign recipient");
  }
}

async function updateCampaignStatus(
  campaignId: string,
  status: string,
  sentAt: string | null,
): Promise<void> {
  const supabase = getSupabaseAdminClient();
  const { error } = await supabase
    .from("campaigns")
    .update({
      status,
      sent_at: sentAt,
    })
    .eq("id", campaignId);

  if (error) {
    console.error("[campaign-sender] Failed to update campaign status", {
      campaignId,
      status,
      sentAt,
      error,
    });
    throw new Error("Failed to update campaign status");
  }
}

async function persistCampaignOutboundMessage(
  campaign: CampaignRecord,
  template: CampaignTemplateRecord,
  recipient: CampaignRecipientRecord,
  sendResult: WhatsAppTemplateSendResult,
): Promise<void> {
  const lead = await findOrCreateLeadPlaceholderByPhone(recipient.phone);
  const conversation = await findOrCreateConversationByPhone(
    recipient.phone,
    lead.id,
  );

  const messageText =
    `Campaign: ${campaign.name}\nTemplate: ${template.template_name}`;

  await insertOutboundMessage(conversation.id, {
    phone: recipient.phone,
    whatsapp_message_id: sendResult.whatsapp_message_id,
    message_type: "template",
    content: messageText,
    timestamp: new Date().toISOString(),
    raw_payload: {
      source: "campaign_sender",
      campaign_id: campaign.id,
      campaign_name: campaign.name,
      template_name: template.template_name,
      recipient_id: recipient.id,
      variables: recipient.variables,
      whatsapp_response: sendResult.raw_response,
    },
  }, "sent");

  await updateConversationLastMessageAt(
    conversation.id,
    new Date().toISOString(),
  );
}
