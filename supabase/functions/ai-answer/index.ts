import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  type AIAnswerRequest,
  answerBrochureQuestion,
  getAISystemPrompt,
} from "../_shared/ai-answer.ts";

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
    },
  });
}

serve(async (req) => {
  try {
    if (req.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "access-control-allow-origin": "*",
          "access-control-allow-methods": "POST, OPTIONS",
          "access-control-allow-headers": "content-type, authorization",
        },
      });
    }

    if (req.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405);
    }

    let requestBody: AIAnswerRequest;

    try {
      requestBody = await req.json();
    } catch (error) {
      console.error("[ai-answer] Invalid JSON request body", error);
      return jsonResponse({ error: "Invalid JSON payload" }, 400);
    }

    if (!requestBody.question || typeof requestBody.question !== "string") {
      return jsonResponse({ error: "question is required" }, 400);
    }

    if (!requestBody.model_name || typeof requestBody.model_name !== "string") {
      return jsonResponse({ error: "model_name is required" }, 400);
    }

    if (
      requestBody.variant_name !== undefined &&
      requestBody.variant_name !== null &&
      typeof requestBody.variant_name !== "string"
    ) {
      return jsonResponse({ error: "variant_name must be a string" }, 400);
    }

    console.info("[ai-answer] AI brochure question received", {
      modelName: requestBody.model_name,
      variantName: requestBody.variant_name ?? null,
      brochureFetchMode: "automatic",
    });

    const result = await answerBrochureQuestion(requestBody);

    return jsonResponse({
      success: true,
      result,
      system_prompt: getAISystemPrompt(),
    });
  } catch (error) {
    console.error("[ai-answer] Unhandled error", error);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});
