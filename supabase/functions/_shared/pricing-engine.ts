import { getSupabaseAdminClient } from "./supabase-admin.ts";

export type PricingRequest = {
  variant_id: string;
  exchange_required: boolean;
  use_bh_rto?: boolean;
  use_scrap_rto?: boolean;
  apply_consumer?: boolean;
  apply_exchange_scrap?: boolean;
  apply_additional_scrap?: boolean;
  apply_corporate?: boolean;
  apply_intervention?: boolean;
  apply_solar?: boolean;
  apply_msme?: boolean;
  apply_green_bonus?: boolean;
};

export type PricingBreakdown = {
  variant: {
    id: string;
    model: string;
    variant_name: string;
    fuel_type: string;
    transmission: string;
  };
  ex_showroom_price: number;
  insurance: number;
  rto: number;
  total_on_road: number;
  schemes_applied: Array<{ name: string; amount: number }>;
  total_discount: number;
  final_on_road_price: number;
};

type VariantRow = {
  id: string;
  model: string;
  variant_name: string;
  fuel_type: string;
  transmission: string;
  ex_showroom_price: number | string | null;
  insurance: number | string | null;
  rto_standard: number | string | null;
  rto_bh: number | string | null;
  rto_scrap: number | string | null;
  scheme_consumer: number | string | null;
  scheme_exchange_scrap: number | string | null;
  scheme_additional_scrap: number | string | null;
  scheme_corporate: number | string | null;
  scheme_intervention: number | string | null;
  scheme_solar: number | string | null;
  scheme_msme: number | string | null;
  scheme_green_bonus: number | string | null;
};

type SchemeDefinition = {
  flag: keyof PricingRequest;
  column: keyof VariantRow;
  name: string;
};

const SCHEME_DEFINITIONS: SchemeDefinition[] = [
  {
    flag: "apply_consumer",
    column: "scheme_consumer",
    name: "Consumer 2026",
  },
  {
    flag: "apply_exchange_scrap",
    column: "scheme_exchange_scrap",
    name: "Exchange & Scrap 2026",
  },
  {
    flag: "apply_additional_scrap",
    column: "scheme_additional_scrap",
    name: "Additional Scrap 2026",
  },
  {
    flag: "apply_corporate",
    column: "scheme_corporate",
    name: "Corporate 2026",
  },
  {
    flag: "apply_intervention",
    column: "scheme_intervention",
    name: "Intervention 2026",
  },
  {
    flag: "apply_solar",
    column: "scheme_solar",
    name: "Solar 2026",
  },
  {
    flag: "apply_msme",
    column: "scheme_msme",
    name: "MSME 2026",
  },
  {
    flag: "apply_green_bonus",
    column: "scheme_green_bonus",
    name: "Green Bonus 2026",
  },
];

export async function calculatePricing(
  request: PricingRequest,
): Promise<PricingBreakdown> {
  const supabase = getSupabaseAdminClient();

  const { data: variant, error } = await supabase
    .from("variants")
    .select(
      "id, model, variant_name, fuel_type, transmission, ex_showroom_price, insurance, rto_standard, rto_bh, rto_scrap, scheme_consumer, scheme_exchange_scrap, scheme_additional_scrap, scheme_corporate, scheme_intervention, scheme_solar, scheme_msme, scheme_green_bonus",
    )
    .eq("id", request.variant_id)
    .eq("is_active", true)
    .maybeSingle();

  if (error) {
    console.error("[pricing-engine] Failed to load active variant", {
      variantId: request.variant_id,
      error,
    });
    throw new Error("Failed to load variant pricing data");
  }

  if (!variant) {
    console.warn("[pricing-engine] Active variant not found", {
      variantId: request.variant_id,
    });
    throw new Error("Variant not found");
  }

  const exShowroomPrice = toAmount(variant.ex_showroom_price);
  const insurance = toAmount(variant.insurance);
  const rto = request.use_scrap_rto
    ? toAmount(variant.rto_scrap)
    : request.use_bh_rto
    ? toAmount(variant.rto_bh)
    : toAmount(variant.rto_standard);
  const totalOnRoad = roundCurrency(exShowroomPrice + insurance + rto);
  const schemesApplied = SCHEME_DEFINITIONS
    .filter((scheme) => request[scheme.flag] === true)
    .map((scheme) => ({
      name: scheme.name,
      amount: toAmount(variant[scheme.column]),
    }))
    .filter((scheme) => scheme.amount > 0);
  const totalDiscount = roundCurrency(
    schemesApplied.reduce((sum, scheme) => sum + scheme.amount, 0),
  );
  const finalOnRoadPrice = roundCurrency(
    Math.max(0, totalOnRoad - totalDiscount),
  );

  console.info("[pricing-engine] Pricing calculated from variant row", {
    variantId: variant.id,
    useBhRto: request.use_bh_rto ?? false,
    useScrapRto: request.use_scrap_rto ?? false,
    schemesApplied: schemesApplied.map((scheme) => scheme.name),
    totalDiscount,
    finalOnRoadPrice,
  });

  return {
    variant: {
      id: variant.id,
      model: variant.model,
      variant_name: variant.variant_name,
      fuel_type: variant.fuel_type,
      transmission: variant.transmission,
    },
    ex_showroom_price: exShowroomPrice,
    insurance,
    rto,
    total_on_road: totalOnRoad,
    schemes_applied: schemesApplied,
    total_discount: totalDiscount,
    final_on_road_price: finalOnRoadPrice,
  };
}

export function formatPricingForWhatsApp(
  breakdown: PricingBreakdown,
): string {
  const lines = [
    `*${breakdown.variant.model} ${breakdown.variant.variant_name}*`,
    `Ex-showroom: ₹${formatPrice(breakdown.ex_showroom_price)}`,
    `Insurance: ₹${formatPrice(breakdown.insurance)}`,
    `RTO: ₹${formatPrice(breakdown.rto)}`,
    "─────────────────",
    `On-road (before offers): ₹${formatPrice(breakdown.total_on_road)}`,
  ];

  if (breakdown.schemes_applied.length > 0) {
    lines.push("");
    lines.push("Offers applied:");

    for (const scheme of breakdown.schemes_applied) {
      lines.push(`- ${scheme.name}: -₹${formatPrice(scheme.amount)}`);
    }
  }

  lines.push("");
  lines.push("─────────────────");
  lines.push(
    `*Final on-road price: ₹${formatPrice(breakdown.final_on_road_price)}*`,
  );

  return lines.join("\n");
}

export function getDefaultPricingRequest(
  variant_id: string,
  exchange_required: boolean,
): PricingRequest {
  return {
    variant_id,
    exchange_required,
    apply_consumer: true,
    apply_exchange_scrap: exchange_required,
    apply_additional_scrap: false,
    apply_corporate: false,
    apply_intervention: false,
    apply_solar: false,
    apply_msme: false,
    apply_green_bonus: true,
    use_bh_rto: false,
    use_scrap_rto: false,
  };
}

function toAmount(value: number | string | null | undefined): number {
  if (value === null || value === undefined || value === "") {
    return 0;
  }

  const numericValue = Number(value);

  if (!Number.isFinite(numericValue)) {
    console.warn(
      "[pricing-engine] Invalid numeric value in variant pricing row",
      {
        value,
      },
    );
    return 0;
  }

  return roundCurrency(numericValue);
}

function roundCurrency(value: number): number {
  return Math.round(value);
}

function formatPrice(value: number): string {
  return new Intl.NumberFormat("en-IN", {
    maximumFractionDigits: 0,
  }).format(value);
}
