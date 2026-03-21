import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  type PersistedInboundMessageResult,
  persistInboundMessage,
} from "../_shared/conversation-manager.ts";
import {
  routeInboundMessage,
  type RouterResult,
} from "../_shared/message-router.ts";

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
    reply_text: string;
    route: string;
    detected_intent: string;
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

      const routerResult: RouterResult = await routeInboundMessage(
        persistenceResult.conversation.id,
        message,
      );

      routerReplies.push({
        conversation_id: persistenceResult.conversation.id,
        reply_text: routerResult.reply_text,
        route: routerResult.route,
        detected_intent: routerResult.detected_intent,
      });
    } catch (error) {
      console.error("[whatsapp-webhook] Failed to persist inbound message", {
        phone: message.phone,
        whatsappMessageId: message.whatsapp_message_id,
        error,
      });
    }
  }

  return jsonResponse({
    success: true,
    message: "Webhook event received",
    normalized_count: normalizedMessages.length,
    persisted_count: persistenceResults.length,
    router_reply_count: routerReplies.length,
    router_replies: routerReplies,
    normalized_messages: normalizedMessages,
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
