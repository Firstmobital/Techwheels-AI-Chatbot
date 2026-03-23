import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  calculatePricing,
  formatPricingForWhatsApp,
  type PricingRequest,
} from "../_shared/pricing-engine.ts";

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

    let requestBody: PricingRequest;

    try {
      requestBody = await req.json();
    } catch (error) {
      console.error("[pricing-engine] Invalid JSON request body", error);
      return jsonResponse({ error: "Invalid JSON payload" }, 400);
    }

    if (!requestBody.variant_id || typeof requestBody.variant_id !== "string") {
      return jsonResponse({ error: "variant_id is required" }, 400);
    }

    if (typeof requestBody.exchange_required !== "boolean") {
      return jsonResponse({ error: "exchange_required must be boolean" }, 400);
    }

    console.info("[pricing-engine] Pricing request received", {
      variantId: requestBody.variant_id,
      exchangeRequired: requestBody.exchange_required,
      useBhRto: requestBody.use_bh_rto ?? false,
      useScrapRto: requestBody.use_scrap_rto ?? false,
    });

    const breakdown = await calculatePricing(requestBody);
    const whatsappReply = formatPricingForWhatsApp(breakdown);

    console.info("[pricing-engine] Pricing calculated", {
      variantId: requestBody.variant_id,
      finalOnRoadPrice: breakdown.final_on_road_price,
      totalDiscount: breakdown.total_discount,
    });

    return jsonResponse({
      success: true,
      breakdown,
      whatsapp_reply: whatsappReply,
    });
  } catch (error) {
    console.error("[pricing-engine] Unhandled error", error);

    if (error instanceof Error && error.message === "Variant not found") {
      return jsonResponse({ error: "Variant not found" }, 404);
    }

    return jsonResponse({ error: "Internal server error" }, 500);
  }
});
