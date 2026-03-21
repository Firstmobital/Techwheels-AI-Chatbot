import {
  insertOutboundMessage,
  type NormalizedMessage,
} from "./conversation-manager.ts";
import { type AIAnswerResponse, answerBrochureQuestion } from "./ai-answer.ts";
import {
  handleLeadCaptureStep,
  type LeadCaptureResult,
  loadLeadCaptureContext,
} from "./lead-capture.ts";
import {
  calculatePricing,
  formatPricingForWhatsApp,
} from "./pricing-engine.ts";
import { getSupabaseAdminClient } from "./supabase-admin.ts";
import {
  formatVariantRecommendationsForWhatsApp,
  getMatchingVariants,
  type VariantRecommendation,
} from "./variant-engine.ts";

type RouterContext = {
  conversation: {
    id: string;
    phone: string;
    lead_id: string | null;
    current_state: string;
    current_step: string | null;
  };
  lead: {
    id: string;
    phone: string;
    customer_name: string | null;
    interested_model: string | null;
    fuel_type: string | null;
    transmission: string | null;
    exchange_required: boolean | null;
    lead_status: string;
  } | null;
};

type RouteName = "lead_capture" | "pricing" | "features" | "fallback";
type IntentName = "lead_capture" | "pricing" | "features" | "fallback";

export type RouterResult = {
  route: RouteName;
  detected_intent: IntentName;
  reply_text: string;
};

const PRICING_KEYWORDS = [
  "price",
  "pricing",
  "on road",
  "on-road",
  "cost",
  "quote",
  "discount",
  "scheme",
  "offer",
];

const FEATURE_KEYWORDS = [
  "feature",
  "features",
  "spec",
  "specs",
  "specification",
  "specifications",
  "compare",
  "comparison",
  "sunroof",
  "safety",
  "airbag",
  "airbags",
  "mileage",
  "engine",
  "ground clearance",
  "boot",
  "seat",
];

export async function routeInboundMessage(
  conversationId: string,
  inboundMessage: NormalizedMessage,
): Promise<RouterResult> {
  const context = await loadRouterContext(conversationId);
  const detectedIntent = detectIntent(inboundMessage.content);

  let route: RouteName = "fallback";
  let replyText = "";

  if (isLeadCaptureIncomplete(context.conversation)) {
    route = "lead_capture";
    const leadCaptureContext = await loadLeadCaptureContext(conversationId);
    const leadCaptureResult: LeadCaptureResult = await handleLeadCaptureStep(
      inboundMessage.content,
      leadCaptureContext,
    );
    replyText = leadCaptureResult.replyText;
  } else if (detectedIntent === "pricing") {
    route = "pricing";
    replyText = await handlePricingRoute(context, inboundMessage.content);
  } else if (detectedIntent === "features") {
    route = "features";
    replyText = await handleFeaturesRoute(context, inboundMessage.content);
  } else {
    route = "fallback";
    replyText = buildFallbackReply(context);
  }

  await insertOutboundMessage(conversationId, {
    phone: context.conversation.phone,
    whatsapp_message_id: null,
    message_type: "text",
    content: replyText,
    timestamp: new Date().toISOString(),
    raw_payload: {
      source: "message_router",
      route,
      detected_intent: detectedIntent,
      conversation_id: conversationId,
    },
  });

  return {
    route,
    detected_intent: route === "lead_capture" ? "lead_capture" : detectedIntent,
    reply_text: replyText,
  };
}

export function detectIntent(messageText: string | null): IntentName {
  const normalizedText = (messageText ?? "").trim().toLowerCase();

  if (!normalizedText) {
    return "fallback";
  }

  if (PRICING_KEYWORDS.some((keyword) => normalizedText.includes(keyword))) {
    return "pricing";
  }

  if (FEATURE_KEYWORDS.some((keyword) => normalizedText.includes(keyword))) {
    return "features";
  }

  return "fallback";
}

async function loadRouterContext(
  conversationId: string,
): Promise<RouterContext> {
  const supabase = getSupabaseAdminClient();

  const { data: conversation, error: conversationError } = await supabase
    .from("conversations")
    .select("id, phone, lead_id, current_state, current_step")
    .eq("id", conversationId)
    .single();

  if (conversationError || !conversation) {
    console.error("[message-router] Failed to load conversation", {
      conversationId,
      error: conversationError,
    });
    throw new Error("Failed to load conversation");
  }

  if (!conversation.lead_id) {
    return {
      conversation,
      lead: null,
    };
  }

  const { data: lead, error: leadError } = await supabase
    .from("leads")
    .select(
      "id, phone, customer_name, interested_model, fuel_type, transmission, exchange_required, lead_status",
    )
    .eq("id", conversation.lead_id)
    .single();

  if (leadError) {
    console.error("[message-router] Failed to load lead", {
      conversationId,
      leadId: conversation.lead_id,
      error: leadError,
    });
    throw new Error("Failed to load lead");
  }

  return {
    conversation,
    lead,
  };
}

function isLeadCaptureIncomplete(
  conversation: RouterContext["conversation"],
): boolean {
  return conversation.current_state === "new" ||
    conversation.current_state === "lead_capture" ||
    (conversation.current_step !== null &&
      conversation.current_step !== "complete");
}

async function handlePricingRoute(
  context: RouterContext,
  inboundText: string | null,
): Promise<string> {
  if (!context.lead?.interested_model) {
    return "I can help with pricing. First, please tell me which model you are interested in.";
  }

  const matchingVariants = await getMatchingVariants({
    interested_model: context.lead.interested_model,
    fuel_type: context.lead.fuel_type,
    transmission: context.lead.transmission,
    limit: 3,
  });

  if (matchingVariants.length === 0) {
    return `I could not find an active variant for ${context.lead.interested_model} right now. I can connect you with our sales advisor for the latest pricing help.`;
  }

  const selectedVariant = resolveVariantForPricing(
    matchingVariants,
    inboundText,
  );

  if (!selectedVariant) {
    return formatVariantRecommendationsForWhatsApp(matchingVariants, {
      interested_model: context.lead.interested_model,
      fuel_type: context.lead.fuel_type,
      transmission: context.lead.transmission,
    });
  }

  const breakdown = await calculatePricing({
    variant_id: selectedVariant.id,
    exchange_required: context.lead.exchange_required ?? false,
    pricing_context: {
      exchange_required: context.lead.exchange_required ?? false,
    },
  });

  return formatPricingForWhatsApp(breakdown);
}

async function handleFeaturesRoute(
  context: RouterContext,
  inboundText: string | null,
): Promise<string> {
  if (!context.lead?.interested_model) {
    return "I can help with features and specifications. Please tell me which model you want to know about.";
  }

  const aiResult: AIAnswerResponse = await answerBrochureQuestion({
    question: inboundText ?? "",
    model_name: context.lead.interested_model,
    variant_name: extractVariantNameForFeatures(
      inboundText,
      context.lead.interested_model,
    ),
  });

  return aiResult.answer;
}

function buildFallbackReply(context: RouterContext): string {
  const modelReference = context.lead?.interested_model
    ? ` for ${context.lead.interested_model}`
    : "";

  return `I can help with pricing${modelReference}, features and specifications, or connect you with a human advisor. Just tell me what you need.`;
}

function resolveVariantForPricing(
  variants: VariantRecommendation[],
  inboundText: string | null,
): VariantRecommendation | null {
  if (variants.length === 1) {
    return variants[0];
  }

  const normalizedText = (inboundText ?? "").trim().toLowerCase();

  if (!normalizedText) {
    return null;
  }

  const exactVariant = variants.find((variant) =>
    normalizedText.includes(variant.variant_name.toLowerCase())
  );

  return exactVariant ?? null;
}

function extractVariantNameForFeatures(
  inboundText: string | null,
  modelName: string,
): string | null {
  const normalizedText = (inboundText ?? "").trim();

  if (!normalizedText) {
    return null;
  }

  const normalizedModelName = modelName.trim().toLowerCase();
  const lowerText = normalizedText.toLowerCase();

  if (
    lowerText === normalizedModelName ||
    lowerText.startsWith(normalizedModelName)
  ) {
    return null;
  }

  return null;
}
