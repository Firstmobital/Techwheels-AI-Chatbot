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

  const effectiveFetchUrl = resolveToDirectDownloadUrl(brochureUrl);

  try {
    const response = await fetch(effectiveFetchUrl);

    if (!response.ok) {
      const errorBody = await response.text();
      console.error("[brochure-fetch] Failed to fetch brochure PDF", {
        brochureUrl,
        effectiveFetchUrl,
        status: response.status,
        errorBody,
      });
      return {
        brochure_url: brochureUrl,
        brochure_base64: null,
        mime_type: null,
      };
    }

    const contentType = response.headers.get("content-type")?.toLowerCase() ??
      "";
    const brochureBytes = new Uint8Array(await response.arrayBuffer());

    if (!contentType.includes("pdf") && brochureBytes.length === 0) {
      console.error("[brochure-fetch] Brochure download returned empty body", {
        brochureUrl,
        effectiveFetchUrl,
        contentType,
      });
      return {
        brochure_url: brochureUrl,
        brochure_base64: null,
        mime_type: null,
      };
    }

    const brochureBase64 = toBase64(brochureBytes);

    return {
      brochure_url: brochureUrl,
      brochure_base64: brochureBase64,
      mime_type: "application/pdf",
    };
  } catch (error) {
    console.error("[brochure-fetch] Failed to download brochure URL", {
      brochureUrl,
      effectiveFetchUrl,
      error,
    });
    return {
      brochure_url: brochureUrl,
      brochure_base64: null,
      mime_type: null,
    };
  }
}

function resolveToDirectDownloadUrl(url: string): string {
  const googleDriveMatch = url.match(
    /^https:\/\/drive\.google\.com\/file\/d\/([^/]+)\/view(?:\?.*)?$/i,
  );

  if (!googleDriveMatch) {
    return url;
  }

  const [, fileId] = googleDriveMatch;
  return `https://drive.google.com/uc?export=download&id=${fileId}`;
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
