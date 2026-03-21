import { getSupabaseAdminClient } from "./supabase-admin.ts";

type BrochureMetadata = {
  id: string;
  model: string;
  file_name: string;
  storage_path: string;
  public_url: string | null;
  version: string | null;
  created_at: string;
};

export type BrochureFetchResult = {
  brochure: BrochureMetadata | null;
  brochure_content: string | null;
  extraction_supported: boolean;
};

const TEXT_FILE_EXTENSIONS = [".txt", ".md", ".markdown", ".json", ".csv"];

export async function fetchBrochureContext(input: {
  model_name: string;
  fuel_type?: string | null;
}): Promise<BrochureFetchResult> {
  const brochure = await loadActiveBrochureMetadata(
    input.model_name,
    input.fuel_type ?? null,
  );

  if (!brochure) {
    return {
      brochure: null,
      brochure_content: null,
      extraction_supported: false,
    };
  }

  const brochureContent = await fetchBrochureFileAsText(brochure.storage_path);

  return {
    brochure,
    brochure_content: brochureContent,
    extraction_supported: brochureContent !== null,
  };
}

async function loadActiveBrochureMetadata(
  modelName: string,
  fuelType: string | null,
): Promise<BrochureMetadata | null> {
  const supabase = getSupabaseAdminClient();

  const { data, error } = await supabase
    .from("brochures")
    .select(
      "id, model, file_name, storage_path, public_url, version, created_at",
    )
    .eq("model", modelName)
    .eq("is_active", true)
    .order("created_at", { ascending: false });

  if (error) {
    console.error("[brochure-fetch] Failed to load brochure metadata", {
      modelName,
      fuelType,
      error,
    });
    throw new Error("Failed to load brochure metadata");
  }

  const brochures = (data ?? []) as BrochureMetadata[];

  if (brochures.length === 0) {
    return null;
  }

  if (!fuelType) {
    return brochures[0];
  }

  const normalizedFuelType = fuelType.trim().toLowerCase();
  const fuelMatchedBrochure = brochures.find((brochure) =>
    buildBrochureSearchText(brochure).includes(normalizedFuelType)
  );

  return fuelMatchedBrochure ?? brochures[0];
}

async function fetchBrochureFileAsText(
  storagePath: string,
): Promise<string | null> {
  const bucketName = Deno.env.get("SUPABASE_STORAGE_BUCKET") ?? "";

  if (!bucketName) {
    console.warn("[brochure-fetch] Missing SUPABASE_STORAGE_BUCKET");
    return null;
  }

  if (!isTextReadableFile(storagePath)) {
    console.info(
      "[brochure-fetch] Skipping non-text brochure file for Phase 1",
      {
        storagePath,
      },
    );
    return null;
  }

  const supabase = getSupabaseAdminClient();
  const { data, error } = await supabase.storage
    .from(bucketName)
    .download(storagePath);

  if (error || !data) {
    console.error("[brochure-fetch] Failed to download brochure file", {
      storagePath,
      bucketName,
      error,
    });
    return null;
  }

  try {
    const text = await data.text();
    return text.trim().length > 0 ? text.trim() : null;
  } catch (error) {
    console.error("[brochure-fetch] Failed to read brochure file as text", {
      storagePath,
      error,
    });
    return null;
  }
}

function isTextReadableFile(storagePath: string): boolean {
  const lowerPath = storagePath.toLowerCase();
  return TEXT_FILE_EXTENSIONS.some((extension) =>
    lowerPath.endsWith(extension)
  );
}

function buildBrochureSearchText(brochure: BrochureMetadata): string {
  return [
    brochure.file_name,
    brochure.storage_path,
    brochure.public_url ?? "",
    brochure.version ?? "",
  ].join(" ").toLowerCase();
}
