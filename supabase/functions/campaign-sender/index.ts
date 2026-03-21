import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  type CampaignSendSummary,
  sendCampaignMessages,
} from "../_shared/campaign-sender.ts";

type CampaignSenderRequest = {
  campaign_id: string;
};

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

    const authHeader = req.headers.get("Authorization");

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
      });
    }

    const token = authHeader.replace("Bearer ", "").trim();
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (token !== serviceKey) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
      });
    }

    let requestBody: CampaignSenderRequest;

    try {
      requestBody = await req.json();
    } catch (error) {
      console.error("[campaign-sender] Invalid JSON payload", error);
      return jsonResponse({ error: "Invalid JSON payload" }, 400);
    }

    if (
      !requestBody.campaign_id || typeof requestBody.campaign_id !== "string"
    ) {
      return jsonResponse({ error: "campaign_id is required" }, 400);
    }

    const summary: CampaignSendSummary = await sendCampaignMessages(
      requestBody.campaign_id,
    );

    return jsonResponse({
      success: true,
      summary,
    });
  } catch (error) {
    console.error("[campaign-sender] Unhandled error", error);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});
