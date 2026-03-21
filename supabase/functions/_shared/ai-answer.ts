import { getSupabaseAdminClient } from "./supabase-admin.ts";
import { fetchBrochureContext } from "./brochure-fetch.ts";

export type AIAnswerRequest = {
  question: string;
  model_name: string;
  variant_name?: string | null;
};

type BrochureMetadata = {
  id: string;
  model: string;
  file_name: string;
  storage_path: string;
  public_url: string | null;
  version: string | null;
  created_at: string;
};

type VariantMetadata = {
  id: string;
  model: string;
  variant_name: string;
  fuel_type: string;
  transmission: string;
};

export type AIAnswerResponse = {
  answer: string;
  confidence_flag: "confirmed" | "not_confirmed";
  fallback_required: boolean;
};

type GeminiResponse = {
  candidates?: Array<{
    content?: {
      parts?: Array<{
        text?: string;
      }>;
    };
  }>;
};

const AI_SYSTEM_PROMPT = `You are the dealership brochure knowledge assistant.
Answer only from the provided brochure context and structured metadata.
Do not guess or invent features, specifications, pricing, availability, or claims.
If the answer is not clearly supported by the provided context, say it is not confirmed.
Keep the answer concise, customer-friendly, and sales-friendly.
Never calculate or estimate price.
Return JSON only with this exact shape:
{"answer":"string","confidence_flag":"confirmed|not_confirmed","fallback_required":true|false}`;

const SAFE_FALLBACK_RESPONSE: AIAnswerResponse = {
  answer:
    "I’m not fully sure about that from the brochure details I have right now. I can help with available variants, pricing, or connect you with our sales advisor for confirmation.",
  confidence_flag: "not_confirmed",
  fallback_required: true,
};

export async function answerBrochureQuestion(
  request: AIAnswerRequest,
): Promise<AIAnswerResponse> {
  const variant = request.variant_name
    ? await loadVariantMetadata(request.model_name, request.variant_name)
    : null;
  const brochureContext = await fetchBrochureContext({
    model_name: request.model_name,
    fuel_type: variant?.fuel_type ?? null,
  });

  const contextPayload = buildBrochureContextPayload(
    request,
    brochureContext,
    variant,
  );

  if (!contextPayload.hasUsableContext) {
    console.warn("[ai-answer] Insufficient brochure context for AI response", {
      modelName: request.model_name,
      variantName: request.variant_name ?? null,
      brochureId: brochureContext.brochure?.id ?? null,
      hasBrochureContent: Boolean(brochureContext.brochure_content),
    });
    return SAFE_FALLBACK_RESPONSE;
  }

  const geminiApiKey = Deno.env.get("GEMINI_API_KEY") ?? "";
  const geminiModel = Deno.env.get("GEMINI_MODEL") ?? "gemini-1.5-flash";

  if (!geminiApiKey) {
    console.error("[ai-answer] Missing GEMINI_API_KEY");
    return SAFE_FALLBACK_RESPONSE;
  }

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${geminiApiKey}`,
    {
      method: "POST",
      headers: {
        "content-type": "application/json; charset=utf-8",
      },
      body: JSON.stringify({
        system_instruction: {
          parts: [{ text: AI_SYSTEM_PROMPT }],
        },
        contents: [
          {
            role: "user",
            parts: [
              {
                text: JSON.stringify({
                  question: request.question,
                  context: contextPayload.context,
                }),
              },
            ],
          },
        ],
        generationConfig: {
          temperature: 0.1,
          responseMimeType: "application/json",
        },
      }),
    },
  );

  if (!response.ok) {
    const errorBody = await response.text();
    console.error("[ai-answer] Gemini request failed", {
      status: response.status,
      errorBody,
    });
    return SAFE_FALLBACK_RESPONSE;
  }

  const geminiResponse = await response.json() as GeminiResponse;
  const responseText = geminiResponse.candidates?.[0]?.content?.parts?.[0]
    ?.text;

  if (!responseText) {
    console.error("[ai-answer] Gemini response missing text payload");
    return SAFE_FALLBACK_RESPONSE;
  }

  try {
    const parsed = JSON.parse(responseText) as Partial<AIAnswerResponse>;

    if (
      typeof parsed.answer !== "string" ||
      (parsed.confidence_flag !== "confirmed" &&
        parsed.confidence_flag !== "not_confirmed") ||
      typeof parsed.fallback_required !== "boolean"
    ) {
      console.error("[ai-answer] Gemini response JSON shape invalid", {
        responseText,
      });
      return SAFE_FALLBACK_RESPONSE;
    }

    return parsed as AIAnswerResponse;
  } catch (error) {
    console.error("[ai-answer] Failed to parse Gemini JSON response", {
      error,
      responseText,
    });
    return SAFE_FALLBACK_RESPONSE;
  }
}

export function getAISystemPrompt(): string {
  return AI_SYSTEM_PROMPT;
}

async function loadVariantMetadata(
  modelName: string,
  variantName: string,
): Promise<VariantMetadata | null> {
  const supabase = getSupabaseAdminClient();

  const { data, error } = await supabase
    .from("variants")
    .select("id, model, variant_name, fuel_type, transmission")
    .eq("model", modelName)
    .eq("variant_name", variantName)
    .eq("is_active", true)
    .limit(1)
    .maybeSingle();

  if (error) {
    console.error("[ai-answer] Failed to load variant metadata", {
      modelName,
      variantName,
      error,
    });
    throw new Error("Failed to load variant metadata");
  }

  return data;
}

function buildBrochureContextPayload(
  request: AIAnswerRequest,
  brochureContext: {
    brochure: BrochureMetadata | null;
    brochure_content: string | null;
    extraction_supported: boolean;
  },
  variant: VariantMetadata | null,
): {
  hasUsableContext: boolean;
  context: Record<string, unknown>;
} {
  const brochureContent = brochureContext.brochure_content?.trim() ?? "";

  return {
    hasUsableContext: brochureContent.length > 0,
    context: {
      model_name: request.model_name,
      variant_name: request.variant_name ?? null,
      brochure_metadata: brochureContext.brochure
        ? {
          id: brochureContext.brochure.id,
          file_name: brochureContext.brochure.file_name,
          storage_path: brochureContext.brochure.storage_path,
          public_url: brochureContext.brochure.public_url,
          version: brochureContext.brochure.version,
          created_at: brochureContext.brochure.created_at,
        }
        : null,
      variant_metadata: variant,
      brochure_content: brochureContent || null,
      context_limitations: brochureContent.length > 0 ? [] : [
        brochureContext.brochure
          ? brochureContext.extraction_supported
            ? "Brochure text was empty after fetch."
            : "Phase 1 text extraction supports only text-readable brochure files from Storage."
          : "No active brochure was found for the selected model.",
        "Only confirmed brochure context should be used for specification answers.",
      ],
    },
  };
}
