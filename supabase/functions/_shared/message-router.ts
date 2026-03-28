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
  | "test_drive"
  | "emi"
  | "delivery"
  | "fallback";

type RouteName =
  | "lead_capture"
  | "pricing"
  | "features"
  | "comparison"
  | "test_drive"
  | "emi"
  | "delivery"
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
  "namaskar",
  "hlo",
  "hii",
];

const PRICING_KEYWORDS = [
  "price",
  "pricing",
  "on road",
  "on-road",
  "onroad",
  "cost",
  "quote",
  "discount",
  "scheme",
  "offer",
  "kitna",
  "kimat",
  "keemat",
  "daam",
  "paisa",
  "rupee",
  "lakh",
  "rate",
  "bata",
  "btao",
  "batao",
  "kitne ka",
  "kya hai price",
  "kya price",
  "total price",
  "ex showroom",
  "ex-showroom",
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
  "camera",
  "screen",
  "display",
  "touchscreen",
  "charging",
  "battery",
  "colour",
  "color",
  "colors",
  "colours",
  "warranty",
  "guarantee",
  "space",
  "luggage",
  "power",
  "torque",
  "pickup",
  "comfort",
  "interior",
  "exterior",
  "ventilated",
  "wireless",
  "carplay",
  "android auto",
  "cruise control",
  "parking",
  "sensor",
  "v2l",
  "v2v",
];

const COMPARISON_KEYWORDS = [
  "compare",
  "comparison",
  "vs",
  "versus",
  "better than",
  "difference",
  "fark",
  "antar",
  "kaun sa better",
  "which is better",
  "konsa",
];

const TEST_DRIVE_KEYWORDS = [
  "test drive",
  "test-drive",
  "testdrive",
  "test karna",
  "drive karna",
  "chalana",
  "dekhna hai",
  "showroom aana",
  "visit",
  "sunday",
  "saturday",
  "kal aana",
  "aa sakta",
  "aa sakti",
  "book",
  "slot",
  "appointment",
];

const EMI_KEYWORDS = [
  "emi",
  "loan",
  "finance",
  "monthly",
  "installment",
  "kist",
  "downpayment",
  "down payment",
  "interest",
  "bank",
  "financer",
  "kitni emi",
  "monthly kitna",
];

const DELIVERY_KEYWORDS = [
  "delivery",
  "waiting",
  "waiting period",
  "kitne din",
  "kab milegi",
  "kab milega",
  "stock",
  "available",
  "availability",
  "kitne time",
  "booking",
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
    intent === "pricing" ||
    intent === "features" ||
    intent === "comparison" ||
    intent === "test_drive" ||
    intent === "emi" ||
    intent === "delivery"
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

    if (actionableIntents.includes("test_drive")) {
      sections.push({
        title: "Test Drive",
        body: handleTestDriveRoute(context),
      });
    }

    if (actionableIntents.includes("emi")) {
      sections.push({
        title: "Finance & EMI",
        body: handleEmiRoute(context),
      });
    }

    if (actionableIntents.includes("delivery")) {
      sections.push({
        title: "Delivery",
        body: handleDeliveryRoute(context),
      });
    }

    const primaryActionable = actionableIntents.filter((i) =>
      i === "pricing" || i === "features" || i === "comparison" ||
      i === "test_drive" || i === "emi" || i === "delivery"
    );

    route = primaryActionable.length > 1
      ? "multi_intent"
      : primaryActionable[0] === "comparison"
      ? "comparison"
      : primaryActionable[0] as RouteName;

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

  if (TEST_DRIVE_KEYWORDS.some((keyword) => normalizedText.includes(keyword))) {
    intents.add("test_drive");
  }

  if (EMI_KEYWORDS.some((keyword) => normalizedText.includes(keyword))) {
    intents.add("emi");
  }

  if (DELIVERY_KEYWORDS.some((keyword) => normalizedText.includes(keyword))) {
    intents.add("delivery");
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
    return "Price jaanne ke liye pehle model select karein. Kaun si car mein interested hain aap?";
  }

  const matchingVariants = await getMatchingVariants({
    interested_model: context.lead.interested_model,
    fuel_type: context.lead.fuel_type,
    transmission: context.lead.transmission,
    limit: 3,
  });

  if (matchingVariants.length === 0) {
    return `${context.lead.interested_model} ke active variants abhi available nahi hain. Main aapko sales advisor se connect karta hoon.`;
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
    return "Features ke baare mein poochne ke liye pehle model select karein.";
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
  const name = context.lead?.customer_name
    ? ` ${context.lead.customer_name}` : "";
  const modelRef = context.lead?.interested_model
    ? ` for ${context.lead.interested_model}` : "";

  return `Main aapki kaise help kar sakta hoon${name}? 😊\n\nAap ye pooch sakte hain:\n• *Price* — on-road breakdown${modelRef}\n• *Features* — specifications, safety, tech\n• *Test Drive* — slot book karna\n• *EMI* — finance options\n• *Delivery* — waiting period & stock`;
}

function handleTestDriveRoute(context: RouterContext): string {
  const name = context.lead?.customer_name ?? "Sir/Ma'am";
  const model = context.lead?.interested_model ?? "the car";
  return `Bilkul ${name}! 🚗 ${model} ka test drive arrange kar denge.\n\nHamari team aapko call karke slot confirm karegi.\nHum Mon–Sat 9am–7pm available hain.\n\nKya aap preferred date & time bata sakte hain?`;
}

function handleEmiRoute(context: RouterContext): string {
  const model = context.lead?.interested_model ?? "this car";
  return `${model} ke liye EMI options available hain! 💰\n\nHamari finance team aapko best rates ke saath complete breakdown share karegi — including down payment, tenure options, and bank partners.\n\nKya aap chahenge ki finance advisor aapko call kare?`;
}

function handleDeliveryRoute(context: RouterContext): string {
  const model = context.lead?.interested_model ?? "this model";
  return `${model} ki delivery ke baare mein — ⏱️\n\nCurrent waiting period typically 2–4 weeks hai, but exact availability aapke chosen variant par depend karti hai.\n\nHamari team aapko exact stock status aur delivery date confirm karegi. Shall I arrange a callback?`;
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
  const wantsTestDrive = detectedIntents.includes("test_drive") ||
    route === "test_drive";

  let newStatus: string | null = null;

  if (wantsTestDrive || (wantsPricing && messageCount >= 2)) {
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