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
  getDefaultPricingRequest,
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
    campaign_id: string | null;
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

export type IntentName =
  | "greeting"
  | "lead_capture"
  | "pricing"
  | "features"
  | "comparison"
  | "fallback";

type RouteName =
  | "lead_capture"
  | "pricing"
  | "features"
  | "comparison"
  | "fallback"
  | "multi_intent";

export type RouterResult = {
  route: RouteName;
  detected_intents: IntentName[];
  reply_text: string;
};

type ReplySection = {
  title: string;
  body: string;
};

const GREETING_KEYWORDS = [
  "hi",
  "hello",
  "hey",
  "good morning",
  "good afternoon",
  "good evening",
  "namaste",
];

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
  "kitna",
  "rate",
];

const FEATURE_KEYWORDS = [
  "feature",
  "features",
  "spec",
  "specs",
  "specification",
  "specifications",
  "sunroof",
  "mileage",
  "range",
  "adas",
  "safety",
  "airbag",
  "airbags",
  "engine",
  "ground clearance",
  "boot",
  "seat",
];

const COMPARISON_KEYWORDS = [
  "compare",
  "comparison",
  "vs",
  "versus",
  "better than",
  "difference",
];

export async function routeInboundMessage(
  conversationId: string,
  inboundMessage: NormalizedMessage,
): Promise<RouterResult> {
  const context = await loadRouterContext(conversationId);

  if (isLeadCaptureIncomplete(context.conversation, context.lead)) {
    const leadCaptureContext = await loadLeadCaptureContext(conversationId);
    const leadCaptureResult: LeadCaptureResult = await handleLeadCaptureStep(
      inboundMessage.content,
      leadCaptureContext,
    );

    await persistRouterReply(
      conversationId,
      context.conversation.phone,
      leadCaptureResult.replyText,
      "lead_capture",
      ["lead_capture"],
    );

    return {
      route: "lead_capture",
      detected_intents: ["lead_capture"],
      reply_text: leadCaptureResult.replyText,
    };
  }

  const detectedIntents = detectIntents(inboundMessage.content);
  const actionableIntents = detectedIntents.filter((intent) =>
    intent === "pricing" || intent === "features" || intent === "comparison"
  );
  const isCampaignContinuation = Boolean(context.conversation.campaign_id) &&
    isCampaignEngagementMessage(inboundMessage);

  if (isCampaignContinuation && !actionableIntents.includes("pricing")) {
    actionableIntents.push("pricing");
  }
  const effectiveDetectedIntents = [
    ...new Set([
      ...detectedIntents,
      ...(isCampaignContinuation ? ["pricing" as const] : []),
    ]),
  ];

  let route: RouteName;
  let replyText: string;

  if (actionableIntents.length === 0) {
    route = "fallback";
    replyText = buildFallbackReply(context);
  } else {
    const sections: ReplySection[] = [];

    if (actionableIntents.includes("pricing")) {
      const pricingBody = await handlePricingRoute(
        context,
        inboundMessage.content,
      );
      sections.push({
        title: "Price",
        body: pricingBody,
      });
    }

    if (
      actionableIntents.includes("features") ||
      actionableIntents.includes("comparison")
    ) {
      const featuresBody = await handleFeaturesRoute(
        context,
        inboundMessage.content,
      );
      sections.push({
        title: actionableIntents.includes("comparison")
          ? "Comparison / Features"
          : "Features",
        body: featuresBody,
      });
    }

    route = actionableIntents.length > 1
      ? "multi_intent"
      : actionableIntents[0] === "comparison"
      ? "comparison"
      : actionableIntents[0];
    replyText = formatCombinedReply(
      sections,
      effectiveDetectedIntents.includes("greeting"),
    );
  }

  await persistRouterReply(
    conversationId,
    context.conversation.phone,
    replyText,
    route,
    effectiveDetectedIntents.length > 0
      ? effectiveDetectedIntents
      : ["fallback"],
  );

  if (context.lead) {
    await updateLeadScore(
      context.lead.id,
      conversationId,
      effectiveDetectedIntents,
      route,
    ).catch(
      (err) => console.error("[message-router] Failed to update lead score", err),
    );
  }

  return {
    route,
    detected_intents: effectiveDetectedIntents.length > 0
      ? effectiveDetectedIntents
      : ["fallback"],
    reply_text: replyText,
  };
}

export function detectIntents(messageText: string | null): IntentName[] {
  const normalizedText = normalizeText(messageText);

  if (!normalizedText) {
    return ["fallback"];
  }

  const intents = new Set<IntentName>();

  if (GREETING_KEYWORDS.some((keyword) => normalizedText.includes(keyword))) {
    intents.add("greeting");
  }

  if (PRICING_KEYWORDS.some((keyword) => normalizedText.includes(keyword))) {
    intents.add("pricing");
  }

  if (FEATURE_KEYWORDS.some((keyword) => normalizedText.includes(keyword))) {
    intents.add("features");
  }

  if (COMPARISON_KEYWORDS.some((keyword) => normalizedText.includes(keyword))) {
    intents.add("comparison");
    intents.add("features");
  }

  if (intents.size === 0) {
    intents.add("fallback");
  }

  return [...intents];
}

async function persistRouterReply(
  conversationId: string,
  phone: string,
  replyText: string,
  route: RouteName,
  detectedIntents: IntentName[],
): Promise<void> {
  await insertOutboundMessage(conversationId, {
    phone,
    whatsapp_message_id: null,
    message_type: "text",
    content: replyText,
    timestamp: new Date().toISOString(),
    raw_payload: {
      source: "message_router",
      route,
      detected_intents: detectedIntents,
      conversation_id: conversationId,
    },
  });
}

async function loadRouterContext(
  conversationId: string,
): Promise<RouterContext> {
  const supabase = getSupabaseAdminClient();

  const { data: conversation, error: conversationError } = await supabase
    .from("conversations")
    .select("id, phone, lead_id, campaign_id, current_state, current_step")
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
  lead: RouterContext["lead"] | null,
): boolean {
  if (
    conversation.current_state === "new" ||
    conversation.current_state === "lead_capture" ||
    (conversation.current_step !== null &&
      conversation.current_step !== "complete")
  ) {
    return true;
  }

  if (!lead) return true;
  if (!lead.interested_model || !lead.fuel_type || !lead.transmission) {
    return true;
  }

  return false;
}

async function handlePricingRoute(
  context: RouterContext,
  inboundText: string | null,
): Promise<string> {
  if (!context.lead?.interested_model) {
    return "I can help with price. First, please tell me which model you are interested in.";
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

  const breakdown = await calculatePricing(
    getDefaultPricingRequest(
      selectedVariant.id,
      context.lead.exchange_required ?? false,
    ),
  );

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

  return `I can help with price${modelReference}, features, or the best variant. Do you want price, features, or best variant? I can also connect you with a human advisor.`;
}

function formatCombinedReply(
  sections: ReplySection[],
  includeGreeting: boolean,
): string {
  const uniqueSections = sections.filter((section, index) =>
    sections.findIndex((candidate) => candidate.body === section.body) === index
  );

  const parts: string[] = [];

  if (includeGreeting) {
    parts.push("Sure, here are the details:");
  }

  for (const section of uniqueSections) {
    parts.push(`${section.title}:\n${section.body}`);
  }

  return parts.join("\n\n").trim();
}

function resolveVariantForPricing(
  variants: VariantRecommendation[],
  inboundText: string | null,
): VariantRecommendation | null {
  if (variants.length === 1) {
    return variants[0];
  }

  const normalizedText = normalizeText(inboundText);

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

function normalizeText(value: string | null): string {
  return (value ?? "").trim().toLowerCase();
}

function isCampaignEngagementMessage(message: NormalizedMessage): boolean {
  if (
    message.message_type === "button" || message.message_type === "interactive"
  ) {
    return true;
  }

  const normalizedText = normalizeText(message.content);
  return normalizedText === "yes" ||
    normalizedText === "interested" ||
    normalizedText === "i am interested";
}

async function updateLeadScore(
  leadId: string,
  conversationId: string,
  detectedIntents: IntentName[],
  route: RouteName,
): Promise<void> {
  const supabase = getSupabaseAdminClient();

  const { data: lead, error } = await supabase
    .from("leads")
    .select("lead_status")
    .eq("id", leadId)
    .single();

  if (error || !lead) return;
  if (lead.lead_status === "hot") return;

  const { count } = await supabase
    .from("messages")
    .select("id", { count: "exact", head: true })
    .eq("conversation_id", conversationId)
    .eq("direction", "inbound");

  const messageCount = count ?? 0;
  const wantsPricing = detectedIntents.includes("pricing") || route === "pricing";
  const wantsFeatures = detectedIntents.includes("features");

  let newStatus: string | null = null;

  if (wantsPricing && messageCount >= 2) {
    newStatus = "hot";
  } else if (wantsPricing || wantsFeatures) {
    newStatus = "warm";
  }

  if (!newStatus) return;
  if (newStatus === "warm" && lead.lead_status === "warm") return;

  await supabase
    .from("leads")
    .update({ lead_status: newStatus })
    .eq("id", leadId);

  console.info("[message-router] Lead score updated", { leadId, newStatus });
}
