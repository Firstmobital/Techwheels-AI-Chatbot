import type { PostgrestError } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import { getSupabaseAdminClient } from "./supabase-admin.ts";

export type NormalizedMessage = {
  phone: string;
  whatsapp_message_id: string | null;
  message_type: string;
  content: string | null;
  timestamp: string | null;
  raw_payload: unknown;
};

type LeadRecord = {
  id: string;
  phone: string;
};

type ConversationRecord = {
  id: string;
  phone: string;
  lead_id: string | null;
  campaign_id?: string | null;
};

type MessageRecord = {
  id: string;
  conversation_id: string;
  phone: string;
  direction: string;
  message_type: string;
  content: string | null;
  raw_payload: unknown;
  whatsapp_message_id: string | null;
  status: string | null;
  created_at: string;
};

export type PersistedInboundMessageResult = {
  lead: LeadRecord;
  conversation: ConversationRecord;
  message: MessageRecord;
  duplicate: boolean;
};

function isDuplicateKeyError(error: PostgrestError | null): boolean {
  return error?.code === "23505";
}

export async function findOrCreateLeadPlaceholderByPhone(
  phone: string,
): Promise<LeadRecord> {
  const supabase = getSupabaseAdminClient();

  const { data: existingLead, error: existingLeadError } = await supabase
    .from("leads")
    .select("id, phone")
    .eq("phone", phone)
    .maybeSingle();

  if (existingLeadError) {
    console.error("[conversation-manager] Failed to fetch lead by phone", {
      phone,
      error: existingLeadError,
    });
    throw new Error("Failed to fetch lead");
  }

  if (existingLead) {
    return existingLead;
  }

  const { data: createdLead, error: createLeadError } = await supabase
    .from("leads")
    .insert({
      phone,
      source: "whatsapp",
      lead_status: "new",
    })
    .select("id, phone")
    .single();

  if (createLeadError && !isDuplicateKeyError(createLeadError)) {
    console.error("[conversation-manager] Failed to create lead placeholder", {
      phone,
      error: createLeadError,
    });
    throw new Error("Failed to create lead placeholder");
  }

  if (createdLead) {
    console.info("[conversation-manager] Lead placeholder created", {
      phone,
      leadId: createdLead.id,
    });
    return createdLead;
  }

  const { data: duplicateLead, error: duplicateLeadError } = await supabase
    .from("leads")
    .select("id, phone")
    .eq("phone", phone)
    .single();

  if (duplicateLeadError || !duplicateLead) {
    console.error(
      "[conversation-manager] Failed to fetch lead after duplicate create attempt",
      {
        phone,
        error: duplicateLeadError,
      },
    );
    throw new Error("Failed to resolve lead placeholder");
  }

  return duplicateLead;
}

export async function findOrCreateConversationByPhone(
  phone: string,
  leadId: string,
): Promise<ConversationRecord> {
  const supabase = getSupabaseAdminClient();

  const { data: existingConversation, error: existingConversationError } =
    await supabase
      .from("conversations")
      .select("id, phone, lead_id, campaign_id")
      .eq("phone", phone)
      .maybeSingle();

  if (existingConversationError) {
    console.error(
      "[conversation-manager] Failed to fetch conversation by phone",
      {
        phone,
        error: existingConversationError,
      },
    );
    throw new Error("Failed to fetch conversation");
  }

  if (existingConversation) {
    if (!existingConversation.lead_id) {
      const { data: linkedConversation, error: linkConversationError } =
        await supabase
          .from("conversations")
          .update({ lead_id: leadId })
          .eq("id", existingConversation.id)
          .select("id, phone, lead_id, campaign_id")
          .single();

      if (linkConversationError) {
        console.error(
          "[conversation-manager] Failed to link lead to existing conversation",
          {
            phone,
            leadId,
            conversationId: existingConversation.id,
            error: linkConversationError,
          },
        );
        throw new Error("Failed to link lead to conversation");
      }

      return linkedConversation;
    }

    return existingConversation;
  }

  const { data: createdConversation, error: createConversationError } =
    await supabase
      .from("conversations")
      .insert({
        phone,
        lead_id: leadId,
        current_state: "new",
        is_open: true,
      })
      .select("id, phone, lead_id, campaign_id")
      .single();

  if (
    createConversationError && !isDuplicateKeyError(createConversationError)
  ) {
    console.error("[conversation-manager] Failed to create conversation", {
      phone,
      leadId,
      error: createConversationError,
    });
    throw new Error("Failed to create conversation");
  }

  if (createdConversation) {
    console.info("[conversation-manager] Conversation created", {
      phone,
      leadId,
      conversationId: createdConversation.id,
    });
    return createdConversation;
  }

  const { data: duplicateConversation, error: duplicateConversationError } =
    await supabase
      .from("conversations")
      .select("id, phone, lead_id, campaign_id")
      .eq("phone", phone)
      .single();

  if (duplicateConversationError || !duplicateConversation) {
    console.error(
      "[conversation-manager] Failed to fetch conversation after duplicate create attempt",
      {
        phone,
        error: duplicateConversationError,
      },
    );
    throw new Error("Failed to resolve conversation");
  }

  if (!duplicateConversation.lead_id) {
    const { data: linkedDuplicateConversation, error: linkDuplicateError } =
      await supabase
        .from("conversations")
        .update({ lead_id: leadId })
        .eq("id", duplicateConversation.id)
        .select("id, phone, lead_id, campaign_id")
        .single();

    if (linkDuplicateError || !linkedDuplicateConversation) {
      console.error(
        "[conversation-manager] Failed to link lead to duplicate conversation",
        {
          phone,
          leadId,
          conversationId: duplicateConversation.id,
          error: linkDuplicateError,
        },
      );
      throw new Error("Failed to resolve linked conversation");
    }

    return linkedDuplicateConversation;
  }

  return duplicateConversation;
}

export async function updateConversationLastMessageAt(
  conversationId: string,
  lastMessageAt: string | null,
): Promise<void> {
  const supabase = getSupabaseAdminClient();
  const effectiveTimestamp = lastMessageAt ?? new Date().toISOString();

  const { data: existingConversation, error: existingConversationError } =
    await supabase
      .from("conversations")
      .select("last_message_at")
      .eq("id", conversationId)
      .single();

  if (existingConversationError) {
    console.error(
      "[conversation-manager] Failed to fetch conversation before timestamp update",
      {
        conversationId,
        error: existingConversationError,
      },
    );
    throw new Error("Failed to load conversation timestamp");
  }

  const currentTimestamp = existingConversation.last_message_at
    ? new Date(existingConversation.last_message_at).getTime()
    : null;
  const nextTimestamp = new Date(effectiveTimestamp).getTime();

  if (currentTimestamp && currentTimestamp >= nextTimestamp) {
    return;
  }

  const { error } = await supabase
    .from("conversations")
    .update({ last_message_at: effectiveTimestamp })
    .eq("id", conversationId);

  if (error) {
    console.error(
      "[conversation-manager] Failed to update conversation timestamp",
      {
        conversationId,
        lastMessageAt: effectiveTimestamp,
        error,
      },
    );
    throw new Error("Failed to update conversation timestamp");
  }
}

export async function updateConversationCampaign(
  conversationId: string,
  campaignId: string | null,
): Promise<void> {
  const supabase = getSupabaseAdminClient();

  const { error } = await supabase
    .from("conversations")
    .update({ campaign_id: campaignId })
    .eq("id", conversationId);

  if (error) {
    console.error(
      "[conversation-manager] Failed to update conversation campaign",
      {
        conversationId,
        campaignId,
        error,
      },
    );
    throw new Error("Failed to update conversation campaign");
  }
}

export async function updateConversationFlow(
  conversationId: string,
  values: {
    current_state?: string;
    current_step?: string | null;
    campaign_id?: string | null;
  },
): Promise<void> {
  const supabase = getSupabaseAdminClient();

  const { error } = await supabase
    .from("conversations")
    .update(values)
    .eq("id", conversationId);

  if (error) {
    console.error("[conversation-manager] Failed to update conversation flow", {
      conversationId,
      values,
      error,
    });
    throw new Error("Failed to update conversation flow");
  }
}

export async function insertInboundMessage(
  conversationId: string,
  message: NormalizedMessage,
): Promise<{ message: MessageRecord; duplicate: boolean }> {
  return await insertMessage(conversationId, "inbound", message, null);
}

export async function insertOutboundMessage(
  conversationId: string,
  message: NormalizedMessage,
  status: string | null = "queued",
): Promise<{ message: MessageRecord; duplicate: boolean }> {
  return await insertMessage(conversationId, "outbound", message, status);
}

async function insertMessage(
  conversationId: string,
  direction: "inbound" | "outbound",
  message: NormalizedMessage,
  status: string | null,
): Promise<{ message: MessageRecord; duplicate: boolean }> {
  const supabase = getSupabaseAdminClient();

  if (message.whatsapp_message_id) {
    const { data: existingMessage, error: existingMessageError } =
      await supabase
        .from("messages")
        .select(
          "id, conversation_id, phone, direction, message_type, content, raw_payload, whatsapp_message_id, status, created_at",
        )
        .eq("whatsapp_message_id", message.whatsapp_message_id)
        .maybeSingle();

    if (existingMessageError) {
      console.error(
        "[conversation-manager] Failed to check duplicate message",
        {
          conversationId,
          whatsappMessageId: message.whatsapp_message_id,
          error: existingMessageError,
        },
      );
      throw new Error("Failed to check duplicate message");
    }

    if (existingMessage) {
      return {
        message: existingMessage,
        duplicate: true,
      };
    }
  }

  const createdAt = message.timestamp ?? new Date().toISOString();

  const { data: insertedMessage, error: insertError } = await supabase
    .from("messages")
    .insert({
      conversation_id: conversationId,
      phone: message.phone,
      direction,
      message_type: message.message_type,
      content: message.content,
      raw_payload: message.raw_payload,
      whatsapp_message_id: message.whatsapp_message_id,
      status,
      created_at: createdAt,
    })
    .select(
      "id, conversation_id, phone, direction, message_type, content, raw_payload, whatsapp_message_id, status, created_at",
    )
    .single();

  if (insertError && !isDuplicateKeyError(insertError)) {
    console.error("[conversation-manager] Failed to insert message", {
      conversationId,
      direction,
      whatsappMessageId: message.whatsapp_message_id,
      error: insertError,
    });
    throw new Error("Failed to insert message");
  }

  if (insertedMessage) {
    return {
      message: insertedMessage,
      duplicate: false,
    };
  }

  if (!message.whatsapp_message_id) {
    throw new Error("Message insert failed without whatsapp_message_id");
  }

  const { data: duplicateMessage, error: duplicateMessageError } =
    await supabase
      .from("messages")
      .select(
        "id, conversation_id, phone, direction, message_type, content, raw_payload, whatsapp_message_id, status, created_at",
      )
      .eq("whatsapp_message_id", message.whatsapp_message_id)
      .single();

  if (duplicateMessageError || !duplicateMessage) {
    console.error(
      "[conversation-manager] Failed to resolve duplicate message after insert conflict",
      {
        conversationId,
        whatsappMessageId: message.whatsapp_message_id,
        error: duplicateMessageError,
      },
    );
    throw new Error("Failed to resolve duplicate message");
  }

  return {
    message: duplicateMessage,
    duplicate: true,
  };
}

export async function persistInboundMessage(
  message: NormalizedMessage,
): Promise<PersistedInboundMessageResult> {
  const lead = await findOrCreateLeadPlaceholderByPhone(message.phone);
  const conversation = await findOrCreateConversationByPhone(
    message.phone,
    lead.id,
  );
  const messageInsertResult = await insertInboundMessage(
    conversation.id,
    message,
  );

  if (!messageInsertResult.duplicate) {
    await updateConversationLastMessageAt(conversation.id, message.timestamp);
  }

  return {
    lead,
    conversation,
    message: messageInsertResult.message,
    duplicate: messageInsertResult.duplicate,
  };
}
