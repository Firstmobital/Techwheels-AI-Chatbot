import { getSupabaseAdminClient } from "./supabase-admin.ts";

export type VariantRecommendationInput = {
  interested_model: string;
  fuel_type: string | null;
  transmission: string | null;
  limit?: number;
};

export type VariantRecommendation = {
  id: string;
  model: string;
  variant_name: string;
  fuel_type: string;
  transmission: string;
  ex_showroom_price: number;
};

type VariantRow = {
  id: string;
  model: string;
  variant_name: string;
  fuel_type: string;
  transmission: string;
  ex_showroom_price: number | string;
};

const DEFAULT_LIMIT = 3;

export async function getMatchingVariants(
  input: VariantRecommendationInput,
): Promise<VariantRecommendation[]> {
  const supabase = getSupabaseAdminClient();
  const normalizedModel = input.interested_model.trim();
  const normalizedFuelType = normalizeOptionalValue(input.fuel_type);
  const normalizedTransmission = normalizeOptionalValue(input.transmission);
  const limit = input.limit ?? DEFAULT_LIMIT;

  const { data, error } = await supabase
    .from("variants")
    .select(
      "id, model, variant_name, fuel_type, transmission, ex_showroom_price",
    )
    .eq("is_active", true)
    .eq("model", normalizedModel)
    .order("ex_showroom_price", { ascending: true });

  if (error) {
    console.error("[variant-engine] Failed to fetch variants", {
      interestedModel: normalizedModel,
      fuelType: normalizedFuelType,
      transmission: normalizedTransmission,
      error,
    });
    throw new Error("Failed to fetch variants");
  }

  const variants = (data ?? []).map(mapVariantRow);

  if (variants.length === 0) {
    console.info("[variant-engine] No variants found for model", {
      interestedModel: normalizedModel,
    });
    return [];
  }

  const exactMatches = variants.filter((variant) =>
    matchesExactPreferences(
      variant,
      normalizedFuelType,
      normalizedTransmission,
    )
  );

  if (exactMatches.length > 0) {
    return exactMatches.slice(0, limit);
  }

  const fallbackMatches = variants
    .map((variant) => ({
      variant,
      score: calculateFallbackScore(
        variant,
        normalizedFuelType,
        normalizedTransmission,
      ),
    }))
    .sort((left, right) => {
      if (right.score !== left.score) {
        return right.score - left.score;
      }

      return left.variant.ex_showroom_price - right.variant.ex_showroom_price;
    })
    .map((entry) => entry.variant)
    .slice(0, limit);

  console.info("[variant-engine] Returning fallback variants", {
    interestedModel: normalizedModel,
    fuelType: normalizedFuelType,
    transmission: normalizedTransmission,
    fallbackCount: fallbackMatches.length,
  });

  return fallbackMatches;
}

export function formatVariantRecommendationsForWhatsApp(
  variants: VariantRecommendation[],
  input: Pick<
    VariantRecommendationInput,
    "interested_model" | "fuel_type" | "transmission"
  >,
): string {
  const normalizedFuelType = normalizeOptionalValue(input.fuel_type);
  const normalizedTransmission = normalizeOptionalValue(input.transmission);

  if (variants.length === 0) {
    return `I could not find an active variant for ${input.interested_model} right now. Please connect with our sales team for the latest availability.`;
  }

  const exactMatchFound = variants.some((variant) =>
    matchesExactPreferences(
      variant,
      normalizedFuelType,
      normalizedTransmission,
    )
  );

  const intro = exactMatchFound
    ? `Here are the best matching ${input.interested_model} variants for you:`
    : `I could not find an exact ${input.interested_model} match for your selected fuel and transmission, but here are the closest available options:`;

  const lines = variants.map((variant, index) =>
    `${
      index + 1
    }. ${variant.variant_name} | ${variant.fuel_type} | ${variant.transmission} | Ex-showroom Rs. ${
      formatPrice(variant.ex_showroom_price)
    }`
  );

  return [intro, ...lines].join("\n");
}

function mapVariantRow(row: VariantRow): VariantRecommendation {
  return {
    id: row.id,
    model: row.model,
    variant_name: row.variant_name,
    fuel_type: row.fuel_type,
    transmission: row.transmission,
    ex_showroom_price: Number(row.ex_showroom_price),
  };
}

function matchesExactPreferences(
  variant: VariantRecommendation,
  fuelType: string | null,
  transmission: string | null,
): boolean {
  const fuelMatches = fuelType
    ? variant.fuel_type.toLowerCase() === fuelType
    : true;
  const transmissionPreferenceMatches = transmission
    ? transmissionMatches(variant.transmission, transmission)
    : true;

  return fuelMatches && transmissionPreferenceMatches;
}

function transmissionMatches(
  variantTransmission: string,
  preference: string | null,
): boolean {
  if (preference === null) {
    return true;
  }

  const normalizedVariantTransmission = variantTransmission.toLowerCase();
  const normalizedPreference = preference.toLowerCase();

  if (normalizedPreference === "manual") {
    return normalizedVariantTransmission === "manual";
  }

  if (normalizedPreference === "automatic") {
    return normalizedVariantTransmission === "automatic" ||
      normalizedVariantTransmission === "dca";
  }

  return normalizedVariantTransmission === normalizedPreference;
}

function calculateFallbackScore(
  variant: VariantRecommendation,
  fuelType: string | null,
  transmission: string | null,
): number {
  let score = 0;

  if (fuelType && variant.fuel_type.toLowerCase() === fuelType) {
    score += 2;
  }

  if (transmission && transmissionMatches(variant.transmission, transmission)) {
    score += 1;
  }

  return score;
}

function normalizeOptionalValue(value: string | null): string | null {
  if (!value) {
    return null;
  }

  const normalized = value.trim().toLowerCase();
  return normalized.length > 0 ? normalized : null;
}

function formatPrice(value: number): string {
  return new Intl.NumberFormat("en-IN", {
    maximumFractionDigits: 0,
  }).format(value);
}
