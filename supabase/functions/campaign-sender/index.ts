import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  type CampaignSendSummary,
  sendCampaignMessages,
} from "../_shared/campaign-sender.ts";

type CampaignSenderRequest = {
  campaign_id: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json; charset=utf-8",
    },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    if (req.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405);
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Missing Authorization header" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    });

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return jsonResponse({ error: "Unauthorized user" }, 401);
    }

    let requestBody: CampaignSenderRequest;

    try {
      requestBody = await req.json();
    } catch (error) {
      console.error("[campaign-sender] Invalid JSON payload", error);
      return jsonResponse({ error: "Invalid JSON payload" }, 400);
    }

    if (!requestBody.campaign_id || typeof requestBody.campaign_id !== "string") {
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
    return jsonResponse(
      {
        error: error instanceof Error ? error.message : "Internal server error",
      },
      500,
    );
  }
});