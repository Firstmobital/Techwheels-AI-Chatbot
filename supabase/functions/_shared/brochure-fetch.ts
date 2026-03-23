import { getSupabaseAdminClient } from "./supabase-admin.ts";

export type BrochureFetchResult = {
  brochure_url: string | null;
  brochure_base64: string | null;
  mime_type: "application/pdf" | null;
};

export async function fetchBrochureContext(input: {
  model_name: string;
  fuel_type?: string | null;
  variant_brochure_url?: string | null;
}): Promise<BrochureFetchResult> {
  const brochureUrl = input.variant_brochure_url?.trim()
    ? input.variant_brochure_url.trim()
    : await loadVariantBrochureUrl(
      input.model_name,
      input.fuel_type ?? null,
    );

  if (!brochureUrl) {
    return {
      brochure_url: null,
      brochure_base64: null,
      mime_type: null,
    };
  }

  if (!brochureUrl.toLowerCase().endsWith(".pdf")) {
    console.info("[brochure-fetch] Skipping non-PDF brochure URL", {
      brochureUrl,
    });
    return {
      brochure_url: brochureUrl,
      brochure_base64: null,
      mime_type: null,
    };
  }

  try {
    const response = await fetch(brochureUrl);

    if (!response.ok) {
      const errorBody = await response.text();
      console.error("[brochure-fetch] Failed to fetch brochure PDF", {
        brochureUrl,
        status: response.status,
        errorBody,
      });
      return {
        brochure_url: brochureUrl,
        brochure_base64: null,
        mime_type: null,
      };
    }

    const brochureBytes = new Uint8Array(await response.arrayBuffer());
    const brochureBase64 = toBase64(brochureBytes);

    return {
      brochure_url: brochureUrl,
      brochure_base64: brochureBase64,
      mime_type: "application/pdf",
    };
  } catch (error) {
    console.error("[brochure-fetch] Failed to download brochure URL", {
      brochureUrl,
      error,
    });
    return {
      brochure_url: brochureUrl,
      brochure_base64: null,
      mime_type: null,
    };
  }
}

async function loadVariantBrochureUrl(
  modelName: string,
  fuelType: string | null,
): Promise<string | null> {
  const supabase = getSupabaseAdminClient();
  let query = supabase
    .from("variants")
    .select("brochure_url")
    .eq("model", modelName)
    .eq("is_active", true)
    .not("brochure_url", "is", null)
    .order("updated_at", { ascending: false })
    .limit(10);

  if (fuelType) {
    query = query.eq("fuel_type", fuelType);
  }

  const { data, error } = await query;

  if (error) {
    console.error(
      "[brochure-fetch] Failed to load brochure URL from variants",
      {
        modelName,
        fuelType,
        error,
      },
    );
    throw new Error("Failed to load brochure URL from variants");
  }

  const brochureUrl = (data ?? [])
    .map((variant) => variant.brochure_url)
    .find((value): value is string =>
      typeof value === "string" && value.trim().length > 0
    );

  return brochureUrl?.trim() ?? null;
}

function toBase64(value: Uint8Array): string {
  let binary = "";

  for (const byte of value) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary);
}
