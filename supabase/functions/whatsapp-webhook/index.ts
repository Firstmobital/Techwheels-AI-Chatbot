import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  type PersistedInboundMessageResult,
  persistInboundMessage,
} from "../_shared/conversation-manager.ts";
import {
  type CampaignResponseContext,
  handleCampaignResponseTransition,
} from "../_shared/campaign-response.ts";
import {
  routeInboundMessage,
  type RouterResult,
} from "../_shared/message-router.ts";
import { getSupabaseAdminClient } from "../_shared/supabase-admin.ts";

type WhatsAppNormalizedMessage = {
  phone: string;
  whatsapp_message_id: string | null;
  message_type: string;
  content: string | null;
  timestamp: string | null;
  raw_payload: unknown;
};

type WhatsAppConfig = {
  verifyToken: string;
  accessToken: string;
  phoneNumberId: string;
};

function loadConfig(): WhatsAppConfig {
  const verifyToken = Deno.env.get("WHATSAPP_VERIFY_TOKEN") ?? "";
  const accessToken = Deno.env.get("WHATSAPP_ACCESS_TOKEN") ?? "";
  const phoneNumberId = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID") ?? "";

  if (!verifyToken) {
    console.error("[whatsapp-webhook] Missing WHATSAPP_VERIFY_TOKEN");
  }

  if (!accessToken) {
    console.warn(
      "[whatsapp-webhook] Missing WHATSAPP_ACCESS_TOKEN; outbound replies are not available yet",
    );
  }

  if (!phoneNumberId) {
    console.warn(
      "[whatsapp-webhook] Missing WHATSAPP_PHONE_NUMBER_ID; phone number ownership checks are limited",
    );
  }

  return {
    verifyToken,
    accessToken,
    phoneNumberId,
  };
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
    },
  });
}

function textResponse(body: string, status = 200): Response {
  return new Response(body, {
    status,
    headers: {
      "content-type": "text/plain; charset=utf-8",
    },
  });
}

function parseWhatsAppTimestamp(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const unixSeconds = Number(value);

  if (!Number.isFinite(unixSeconds)) {
    return null;
  }

  const parsedDate = new Date(unixSeconds * 1000);

  if (Number.isNaN(parsedDate.getTime())) {
    return null;
  }

  return parsedDate.toISOString();
}

function extractContent(
  message: Record<string, unknown>,
  messageType: string,
): string | null {
  if (messageType === "text") {
    const text = message.text;
    if (
      text && typeof text === "object" && "body" in text &&
      typeof text.body === "string"
    ) {
      return text.body;
    }
  }

  if (messageType === "button") {
    const button = message.button;
    if (
      button && typeof button === "object" && "text" in button &&
      typeof button.text === "string"
    ) {
      return button.text;
    }
  }

  if (messageType === "interactive") {
    const interactive = message.interactive;

    if (interactive && typeof interactive === "object") {
      if ("button_reply" in interactive) {
        const buttonReply = interactive.button_reply;
        if (
          buttonReply &&
          typeof buttonReply === "object" &&
          "title" in buttonReply &&
          typeof buttonReply.title === "string"
        ) {
          return buttonReply.title;
        }
      }

      if ("list_reply" in interactive) {
        const listReply = interactive.list_reply;
        if (
          listReply &&
          typeof listReply === "object" &&
          "title" in listReply &&
          typeof listReply.title === "string"
        ) {
          return listReply.title;
        }
      }
    }
  }

  if (
    messageType === "image" || messageType === "document" ||
    messageType === "video" || messageType === "audio" ||
    messageType === "sticker"
  ) {
    const media = message[messageType];
    if (
      media && typeof media === "object" && "caption" in media &&
      typeof media.caption === "string"
    ) {
      return media.caption;
    }
  }

  return null;
}

function normalizeInboundPayload(
  payload: unknown,
): WhatsAppNormalizedMessage[] {
  if (!payload || typeof payload !== "object") {
    return [];
  }

  const root = payload as Record<string, unknown>;
  const entries = Array.isArray(root.entry) ? root.entry : [];
  const normalizedMessages: WhatsAppNormalizedMessage[] = [];

  for (const entry of entries) {
    if (!entry || typeof entry !== "object") {
      continue;
    }

    const entryRecord = entry as Record<string, unknown>;
    const changes = Array.isArray(entryRecord.changes)
      ? entryRecord.changes
      : [];

    for (const change of changes) {
      if (!change || typeof change !== "object") {
        continue;
      }

      const changeRecord = change as Record<string, unknown>;
      const value = changeRecord.value;

      if (!value || typeof value !== "object") {
        continue;
      }

      const valueRecord = value as Record<string, unknown>;
      const contacts = Array.isArray(valueRecord.contacts)
        ? valueRecord.contacts
        : [];
      const messages = Array.isArray(valueRecord.messages)
        ? valueRecord.messages
        : [];

      for (const message of messages) {
        if (!message || typeof message !== "object") {
          continue;
        }

        const messageRecord = message as Record<string, unknown>;
        const messageType = typeof messageRecord.type === "string"
          ? messageRecord.type
          : "unknown";
        const whatsappMessageId = typeof messageRecord.id === "string"
          ? messageRecord.id
          : null;
        const timestamp = parseWhatsAppTimestamp(messageRecord.timestamp);

        let phone = typeof messageRecord.from === "string"
          ? messageRecord.from
          : "";

        if (!phone && contacts.length > 0) {
          const contact = contacts[0];
          if (
            contact && typeof contact === "object" && "wa_id" in contact &&
            typeof contact.wa_id === "string"
          ) {
            phone = contact.wa_id;
          }
        }

        normalizedMessages.push({
          phone,
          whatsapp_message_id: whatsappMessageId,
          message_type: messageType,
          content: extractContent(messageRecord, messageType),
          timestamp,
          raw_payload: messageRecord,
        });
      }
    }
  }

  return normalizedMessages;
}

async function processStatusCallbacks(payload: unknown): Promise<void> {
  if (!payload || typeof payload !== "object") {
    return;
  }

  const root = payload as Record<string, unknown>;
  const entries = Array.isArray(root.entry) ? root.entry : [];
  const supabase = getSupabaseAdminClient();

  for (const entry of entries) {
    if (!entry || typeof entry !== "object") {
      continue;
    }

    const entryRecord = entry as Record<string, unknown>;
    const changes = Array.isArray(entryRecord.changes)
      ? entryRecord.changes
      : [];

    for (const change of changes) {
      if (!change || typeof change !== "object") {
        continue;
      }

      const changeRecord = change as Record<string, unknown>;
      const value = changeRecord.value;

      if (!value || typeof value !== "object") {
        continue;
      }

      const valueRecord = value as Record<string, unknown>;
      const statuses = Array.isArray(valueRecord.statuses)
        ? valueRecord.statuses
        : [];

      for (const statusEntry of statuses) {
        if (!statusEntry || typeof statusEntry !== "object") {
          continue;
        }

        const statusRecord = statusEntry as Record<string, unknown>;
        const whatsappMessageId = typeof statusRecord.id === "string"
          ? statusRecord.id
          : null;
        const status = typeof statusRecord.status === "string"
          ? statusRecord.status
          : null;
        const timestamp = parseWhatsAppTimestamp(statusRecord.timestamp);

        if (
          !whatsappMessageId ||
          (status !== "delivered" && status !== "read")
        ) {
          continue;
        }

        try {
          const { error } = await supabase
            .from("messages")
            .update({
              status,
            })
            .eq("whatsapp_message_id", whatsappMessageId);

          if (error) {
            console.error(
              "[whatsapp-webhook] Failed to update message status callback",
              {
                whatsappMessageId,
                status,
                timestamp,
                error,
              },
            );
          }
        } catch (error) {
          console.error(
            "[whatsapp-webhook] Error updating message status callback",
            {
              whatsappMessageId,
              status,
              timestamp,
              error,
            },
          );
        }
      }
    }
  }
}

function validateWebhookSubscription(
  url: URL,
  config: WhatsAppConfig,
): Response {
  const mode = url.searchParams.get("hub.mode");
  const token = url.searchParams.get("hub.verify_token");
  const challenge = url.searchParams.get("hub.challenge");

  console.info("[whatsapp-webhook] Verification request received", {
    mode,
    hasChallenge: Boolean(challenge),
  });

  if (!config.verifyToken) {
    return textResponse("Server verification token is not configured", 500);
  }

  if (mode !== "subscribe" || token !== config.verifyToken || !challenge) {
    console.error("[whatsapp-webhook] Verification failed", {
      mode,
      tokenMatched: token === config.verifyToken,
      hasChallenge: Boolean(challenge),
    });
    return textResponse("Forbidden", 403);
  }

  console.info("[whatsapp-webhook] Verification succeeded");
  return textResponse(challenge, 200);
}

async function sendWhatsAppReply(
  phone: string,
  replyText: string,
  config: WhatsAppConfig,
): Promise<boolean> {
  const { accessToken, phoneNumberId } = config;

  if (!accessToken || !phoneNumberId) {
    console.warn("Missing WhatsApp config");
    return false;
  }

  try {
    const response = await fetch(
      `https://graph.facebook.com/v20.0/${phoneNumberId}/messages`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          messaging_product: "whatsapp",
          to: phone,
          type: "text",
          text: {
            body: replyText,
          },
        }),
      },
    );

    if (!response.ok) {
      const responseBody = await response.text();
      console.error("[whatsapp-webhook] Failed to send WhatsApp reply", {
        phone,
        status: response.status,
        body: responseBody,
      });
      return false;
    }

    return true;
  } catch (error) {
    console.error("[whatsapp-webhook] Error sending WhatsApp reply", {
      phone,
      error,
    });
    return false;
  }
}

async function handleInboundEvent(
  req: Request,
  config: WhatsAppConfig,
): Promise<Response> {
  let payload: unknown;

  try {
    payload = await req.json();
  } catch (error) {
    console.error("[whatsapp-webhook] Invalid JSON payload", error);
    return jsonResponse({ error: "Invalid JSON payload" }, 400);
  }

  const root = payload && typeof payload === "object"
    ? payload as Record<string, unknown>
    : null;
  const objectType = root && typeof root.object === "string"
    ? root.object
    : null;

  if (objectType !== "whatsapp_business_account") {
    console.error("[whatsapp-webhook] Unsupported webhook object", {
      objectType,
    });
    return jsonResponse({ error: "Unsupported webhook object" }, 400);
  }

  const normalizedMessages = normalizeInboundPayload(payload);

  await processStatusCallbacks(payload).catch((err) =>
    console.error("[whatsapp-webhook] Failed to process status callbacks", err)
  );

  const metadataPhoneNumberIds: string[] = [];
  const entries = Array.isArray(root?.entry) ? root.entry : [];

  for (const entry of entries) {
    if (!entry || typeof entry !== "object") {
      continue;
    }

    const entryRecord = entry as Record<string, unknown>;
    const changes = Array.isArray(entryRecord.changes)
      ? entryRecord.changes
      : [];

    for (const change of changes) {
      if (!change || typeof change !== "object") {
        continue;
      }

      const changeRecord = change as Record<string, unknown>;
      const value = changeRecord.value;

      if (!value || typeof value !== "object") {
        continue;
      }

      const valueRecord = value as Record<string, unknown>;
      const metadata = valueRecord.metadata;

      if (
        metadata &&
        typeof metadata === "object" &&
        "phone_number_id" in metadata &&
        typeof metadata.phone_number_id === "string"
      ) {
        metadataPhoneNumberIds.push(metadata.phone_number_id);
      }
    }
  }

  if (
    config.phoneNumberId &&
    metadataPhoneNumberIds.length > 0 &&
    metadataPhoneNumberIds.some((id) => id !== config.phoneNumberId)
  ) {
    console.warn(
      "[whatsapp-webhook] Incoming payload phone_number_id does not match configured value",
      {
        configuredPhoneNumberId: config.phoneNumberId,
        payloadPhoneNumberIds: metadataPhoneNumberIds,
      },
    );
  }

  console.info("[whatsapp-webhook] Inbound event processed", {
    objectType,
    normalizedMessageCount: normalizedMessages.length,
    hasAccessTokenConfigured: Boolean(config.accessToken),
    hasPhoneNumberIdConfigured: Boolean(config.phoneNumberId),
  });

  const persistenceResults: PersistedInboundMessageResult[] = [];
  const routerReplies: Array<{
    conversation_id: string;
    campaign_id: string | null;
    campaign_flow_restarted: boolean;
    phone: string;
    reply_text: string;
    route: string;
    detected_intents: string[];
  }> = [];

  for (const message of normalizedMessages) {
    console.info("[whatsapp-webhook] Normalized inbound message", message);

    if (!message.phone) {
      console.warn(
        "[whatsapp-webhook] Skipping normalized message without phone",
        {
          whatsappMessageId: message.whatsapp_message_id,
          messageType: message.message_type,
        },
      );
      continue;
    }

    try {
      const persistenceResult = await persistInboundMessage(message);
      persistenceResults.push(persistenceResult);

      console.info("[whatsapp-webhook] Message persisted", {
        phone: message.phone,
        conversationId: persistenceResult.conversation.id,
        leadId: persistenceResult.lead.id,
        messageId: persistenceResult.message.id,
        duplicate: persistenceResult.duplicate,
      });

      if (persistenceResult.duplicate) {
        continue;
      }

      const campaignResponseResult: CampaignResponseContext =
        await handleCampaignResponseTransition({
          conversationId: persistenceResult.conversation.id,
          phone: message.phone,
          messageType: message.message_type,
          content: message.content,
          lead: null,
        }).catch(async (error) => {
          console.error(
            "[whatsapp-webhook] Failed to process campaign response",
            {
              phone: message.phone,
              conversationId: persistenceResult.conversation.id,
              error,
            },
          );
          return {
            campaign_id: null,
            is_campaign_message: false,
            flow_restarted: false,
            next_state: null,
            next_step: null,
          };
        });

      const routerResult: RouterResult = await routeInboundMessage(
        persistenceResult.conversation.id,
        message,
      );

      routerReplies.push({
        conversation_id: persistenceResult.conversation.id,
        campaign_id: campaignResponseResult.campaign_id,
        campaign_flow_restarted: campaignResponseResult.flow_restarted,
        phone: message.phone,
        reply_text: routerResult.reply_text,
        route: routerResult.route,
        detected_intents: routerResult.detected_intents,
      });
    } catch (error) {
      console.error("[whatsapp-webhook] Failed to persist inbound message", {
        phone: message.phone,
        whatsappMessageId: message.whatsapp_message_id,
        error,
      });
    }
  }

  for (const routerReply of routerReplies) {
    const sendSucceeded = await sendWhatsAppReply(
      routerReply.phone,
      routerReply.reply_text,
      config,
    );

    if (!sendSucceeded) {
      console.error("[whatsapp-webhook] Outbound reply send failed", {
        phone: routerReply.phone,
        replyTextLength: routerReply.reply_text.length,
      });

      const supabase = getSupabaseAdminClient();
      const { data: pendingMessage, error: pendingMessageError } =
        await supabase
          .from("messages")
          .select("id")
          .eq("conversation_id", routerReply.conversation_id)
          .eq("direction", "outbound")
          .or("status.is.null,status.eq.pending")
          .order("created_at", { ascending: false })
          .limit(1)
          .maybeSingle();

      if (pendingMessageError) {
        console.error(
          "[whatsapp-webhook] Failed to load pending outbound message after send failure",
          {
            conversationId: routerReply.conversation_id,
            phone: routerReply.phone,
            error: pendingMessageError,
          },
        );
        continue;
      }

      if (!pendingMessage) {
        continue;
      }

      const { error: updateFailedStatusError } = await supabase
        .from("messages")
        .update({ status: "failed" })
        .eq("id", pendingMessage.id);

      if (updateFailedStatusError) {
        console.error(
          "[whatsapp-webhook] Failed to mark outbound message as failed",
          {
            conversationId: routerReply.conversation_id,
            phone: routerReply.phone,
            messageId: pendingMessage.id,
            error: updateFailedStatusError,
          },
        );
      }
    }
  }

  return jsonResponse({
    success: true,
    normalized_count: normalizedMessages.length,
    persisted_count: persistenceResults.length,
    router_reply_count: routerReplies.length,
  });
}

serve(async (req) => {
  const config = loadConfig();
  const url = new URL(req.url);

  try {
    if (req.method === "GET") {
      return validateWebhookSubscription(url, config);
    }

    if (req.method === "POST") {
      return await handleInboundEvent(req, config);
    }

    return jsonResponse({ error: "Method not allowed" }, 405);
  } catch (error) {
    console.error("[whatsapp-webhook] Unhandled error", error);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});
