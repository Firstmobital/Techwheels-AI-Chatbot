import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  routeInboundMessage,
  type RouterResult,
} from "../_shared/message-router.ts";
import type { NormalizedMessage } from "../_shared/conversation-manager.ts";

type MessageRouterRequest = {
  conversation_id: string;
  inbound_message: NormalizedMessage;
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

    let requestBody: MessageRouterRequest;

    try {
      requestBody = await req.json();
    } catch (error) {
      console.error("[message-router] Invalid JSON payload", error);
      return jsonResponse({ error: "Invalid JSON payload" }, 400);
    }

    if (
      !requestBody.conversation_id ||
      typeof requestBody.conversation_id !== "string"
    ) {
      return jsonResponse({ error: "conversation_id is required" }, 400);
    }

    if (
      !requestBody.inbound_message ||
      typeof requestBody.inbound_message !== "object"
    ) {
      return jsonResponse({ error: "inbound_message is required" }, 400);
    }

    const result: RouterResult = await routeInboundMessage(
      requestBody.conversation_id,
      requestBody.inbound_message,
    );

    return jsonResponse({
      success: true,
      result,
    });
  } catch (error) {
    console.error("[message-router] Unhandled error", error);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});
