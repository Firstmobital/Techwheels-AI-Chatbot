import { getSupabaseAdminClient } from "./supabase-admin.ts";

type LeadCaptureConversation = {
  id: string;
  phone: string;
  lead_id: string | null;
  current_state: string;
  current_step: string | null;
};

type LeadCaptureLead = {
  id: string;
  phone: string;
  customer_name: string | null;
  interested_model: string | null;
  fuel_type: string | null;
  transmission: string | null;
  exchange_required: boolean | null;
  lead_status: string;
};

export type LeadCaptureContext = {
  conversation: LeadCaptureConversation;
  lead: LeadCaptureLead;
};

export type LeadCaptureResult = {
  replyText: string;
  conversationState: string;
  conversationStep: string | null;
  completed: boolean;
};

const FALLBACK_MODELS = ["Hyundai Creta", "Kia Seltos"];
const SUPPORTED_FUELS = ["petrol", "diesel", "cng", "ev"];
const SUPPORTED_TRANSMISSIONS = ["manual", "automatic"];
const SUPPORTED_EXCHANGE_VALUES = ["yes", "no"];

export async function loadLeadCaptureContext(
  conversationId: string,
): Promise<LeadCaptureContext> {
  const supabase = getSupabaseAdminClient();

  const { data: conversation, error: conversationError } = await supabase
    .from("conversations")
    .select("id, phone, lead_id, current_state, current_step")
    .eq("id", conversationId)
    .single();

  if (conversationError || !conversation) {
    console.error("[lead-capture] Failed to load conversation", {
      conversationId,
      error: conversationError,
    });
    throw new Error("Failed to load lead capture conversation");
  }

  if (!conversation.lead_id) {
    throw new Error("Conversation is missing lead_id");
  }

  const { data: lead, error: leadError } = await supabase
    .from("leads")
    .select(
      "id, phone, customer_name, interested_model, fuel_type, transmission, exchange_required, lead_status",
    )
    .eq("id", conversation.lead_id)
    .single();

  if (leadError || !lead) {
    console.error("[lead-capture] Failed to load lead", {
      conversationId,
      leadId: conversation.lead_id,
      error: leadError,
    });
    throw new Error("Failed to load lead capture lead");
  }

  return {
    conversation,
    lead,
  };
}

export async function handleLeadCaptureStep(
  incomingText: string | null,
  context: LeadCaptureContext,
): Promise<LeadCaptureResult> {
  const conversationState = context.conversation.current_state || "new";
  const currentStep = context.conversation.current_step;

  if (conversationState === "qualified" || currentStep === "complete") {
    return {
      replyText:
        "Thanks, I have your details. I can now help you with variants and pricing.",
      conversationState: "qualified",
      conversationStep: "complete",
      completed: true,
    };
  }

  if (conversationState === "new") {
    await updateConversationState(
      context.conversation.id,
      "lead_capture",
      "ask_name",
    );

    return {
      replyText: "Welcome to Techwheels. May I have your name?",
      conversationState: "lead_capture",
      conversationStep: "ask_name",
      completed: false,
    };
  }

  const effectiveStep = currentStep ?? "ask_name";

  if (effectiveStep === "ask_name") {
    const normalizedName = normalizeCustomerName(incomingText);

    if (!normalizedName) {
      return {
        replyText: "Please share your name so I can help you better.",
        conversationState: "lead_capture",
        conversationStep: "ask_name",
        completed: false,
      };
    }

    await updateLead(context.lead.id, {
      customer_name: normalizedName,
    });
    await updateConversationState(
      context.conversation.id,
      "lead_capture",
      "ask_model",
    );

    const supportedModels = await getSupportedModels();
    return {
      replyText:
        `Thanks ${normalizedName}. Which model are you interested in? Available options: ${
          supportedModels.join(", ")
        }.`,
      conversationState: "lead_capture",
      conversationStep: "ask_model",
      completed: false,
    };
  }

  if (effectiveStep === "ask_model") {
    const supportedModels = await getSupportedModels();
    const selectedModel = normalizeSupportedModel(
      incomingText ?? "",
      supportedModels,
    );

    if (!selectedModel) {
      return {
        replyText: `Please choose one of these models: ${
          supportedModels.join(", ")
        }.`,
        conversationState: "lead_capture",
        conversationStep: "ask_model",
        completed: false,
      };
    }

    await updateLead(context.lead.id, {
      interested_model: selectedModel,
    });
    await updateConversationState(
      context.conversation.id,
      "lead_capture",
      "ask_fuel",
    );

    return {
      replyText:
        "Got it. Which fuel type do you prefer: petrol, diesel, cng, or ev?",
      conversationState: "lead_capture",
      conversationStep: "ask_fuel",
      completed: false,
    };
  }

  if (effectiveStep === "ask_fuel") {
    const fuelType = normalizeChoice(incomingText, SUPPORTED_FUELS);

    if (!fuelType) {
      return {
        replyText:
          "Please reply with one fuel type: petrol, diesel, cng, or ev.",
        conversationState: "lead_capture",
        conversationStep: "ask_fuel",
        completed: false,
      };
    }

    await updateLead(context.lead.id, {
      fuel_type: fuelType,
    });
    await updateConversationState(
      context.conversation.id,
      "lead_capture",
      "ask_transmission",
    );

    return {
      replyText:
        "Thanks. Which transmission would you like: manual or automatic?",
      conversationState: "lead_capture",
      conversationStep: "ask_transmission",
      completed: false,
    };
  }

  if (effectiveStep === "ask_transmission") {
    const transmission = normalizeChoice(incomingText, SUPPORTED_TRANSMISSIONS);

    if (!transmission) {
      return {
        replyText:
          "Please reply with one transmission option: manual or automatic.",
        conversationState: "lead_capture",
        conversationStep: "ask_transmission",
        completed: false,
      };
    }

    await updateLead(context.lead.id, {
      transmission,
    });
    await updateConversationState(
      context.conversation.id,
      "lead_capture",
      "ask_exchange",
    );

    return {
      replyText: "Do you have a car for exchange? Please reply yes or no.",
      conversationState: "lead_capture",
      conversationStep: "ask_exchange",
      completed: false,
    };
  }

  if (effectiveStep === "ask_exchange") {
    const exchangeValue = normalizeChoice(
      incomingText,
      SUPPORTED_EXCHANGE_VALUES,
    );

    if (!exchangeValue) {
      return {
        replyText: "Please reply yes or no for exchange requirement.",
        conversationState: "lead_capture",
        conversationStep: "ask_exchange",
        completed: false,
      };
    }

    const exchangeRequired = exchangeValue === "yes";

    await updateLead(context.lead.id, {
      exchange_required: exchangeRequired,
      lead_status: "qualified",
    });
    await updateConversationState(
      context.conversation.id,
      "qualified",
      "complete",
    );

    return {
      replyText:
        "Perfect. I have your details now. I can help you next with matching variants and on-road pricing.",
      conversationState: "qualified",
      conversationStep: "complete",
      completed: true,
    };
  }

  await updateConversationState(
    context.conversation.id,
    "lead_capture",
    "ask_name",
  );

  return {
    replyText: "Let’s start quickly. May I have your name?",
    conversationState: "lead_capture",
    conversationStep: "ask_name",
    completed: false,
  };
}

async function getSupportedModels(): Promise<string[]> {
  const supabase = getSupabaseAdminClient();

  const { data, error } = await supabase
    .from("variants")
    .select("model")
    .eq("is_active", true);

  if (error) {
    console.error("[lead-capture] Failed to fetch models from variants", {
      error,
    });
    return FALLBACK_MODELS;
  }

  const uniqueModels = [
    ...new Set(
      (data ?? [])
        .map((variant) => variant.model)
        .filter((model): model is string =>
          typeof model === "string" && model.length > 0
        ),
    ),
  ];

  return uniqueModels.length > 0 ? uniqueModels : FALLBACK_MODELS;
}

async function updateLead(
  leadId: string,
  updates: Record<string, string | boolean | null>,
): Promise<void> {
  const supabase = getSupabaseAdminClient();
  const { error } = await supabase
    .from("leads")
    .update(updates)
    .eq("id", leadId);

  if (error) {
    console.error("[lead-capture] Failed to update lead", {
      leadId,
      updates,
      error,
    });
    throw new Error("Failed to update lead");
  }
}

async function updateConversationState(
  conversationId: string,
  currentState: string,
  currentStep: string | null,
): Promise<void> {
  const supabase = getSupabaseAdminClient();
  const { error } = await supabase
    .from("conversations")
    .update({
      current_state: currentState,
      current_step: currentStep,
    })
    .eq("id", conversationId);

  if (error) {
    console.error("[lead-capture] Failed to update conversation state", {
      conversationId,
      currentState,
      currentStep,
      error,
    });
    throw new Error("Failed to update conversation state");
  }
}

function normalizeCustomerName(value: string | null): string | null {
  if (!value) {
    return null;
  }

  const cleaned = value.replace(/\s+/g, " ").trim();

  if (cleaned.length < 2) {
    return null;
  }

  return cleaned
    .split(" ")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
    .join(" ");
}

function normalizeChoice(
  value: string | null,
  supportedValues: string[],
): string | null {
  if (!value) {
    return null;
  }

  const normalized = value.trim().toLowerCase();

  if (supportedValues.includes(normalized)) {
    return normalized;
  }

  if (normalized === "y" && supportedValues.includes("yes")) {
    return "yes";
  }

  if (normalized === "n" && supportedValues.includes("no")) {
    return "no";
  }

  return null;
}

export function normalizeSupportedModel(
  input: string,
  supportedModels: string[],
): string | null {
  if (!input) return null;
  const normalizedInput = input.toLowerCase().trim().replace(/\s+/g, " ");

  for (const model of supportedModels) {
    const normalizedModel = model.toLowerCase();
    if (
      normalizedModel.includes(normalizedInput) ||
      normalizedInput.includes(normalizedModel)
    ) {
      return model;
    }
  }

  const inputTokens = normalizedInput.split(/[\s.\-_]+/).filter((t) =>
    t.length > 1
  );
  for (const model of supportedModels) {
    const modelTokens = model.toLowerCase().split(/[\s.\-_]+/).filter((t) =>
      t.length > 1
    );
    if (
      inputTokens.length > 0 &&
      inputTokens.every((token) =>
        modelTokens.some((m) => m.startsWith(token) || token.startsWith(m))
      )
    ) {
      return model;
    }
  }

  const stripped = normalizedInput.replace(/[\s.\-_]/g, "");
  for (const model of supportedModels) {
    const strippedModel = model.toLowerCase().replace(/[\s.\-_]/g, "");
    if (strippedModel.includes(stripped) || stripped.includes(strippedModel)) {
      return model;
    }
  }

  return null;
}
