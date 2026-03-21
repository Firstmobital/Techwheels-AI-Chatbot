import { getSupabaseAdminClient } from "./supabase-admin.ts";

export type PricingRequest = {
  variant_id: string;
  exchange_required: boolean;
  pricing_context?: Record<string, unknown> | null;
};

type VariantRow = {
  id: string;
  model: string;
  variant_name: string;
  fuel_type: string;
  transmission: string;
  ex_showroom_price: number | string;
  is_active: boolean;
};

type PricingRuleRow = {
  id: string;
  model: string | null;
  variant_id: string | null;
  rule_type: string;
  rule_name: string;
  value_type: string;
  value: number | string;
  is_stackable: boolean;
  conditions: Record<string, unknown> | null;
  is_active: boolean;
};

type AppliedRule = {
  id: string;
  rule_type: string;
  rule_name: string;
  scope: "variant" | "model";
  value_type: string;
  configured_value: number;
  computed_amount: number;
  is_stackable: boolean;
  conditions: Record<string, unknown> | null;
};

export type PricingBreakdown = {
  variant: {
    id: string;
    model: string;
    variant_name: string;
    fuel_type: string;
    transmission: string;
  };
  pricing_context: Record<string, unknown>;
  ex_showroom_price: number;
  rto: number;
  insurance: number;
  handling: number;
  accessories: number;
  total_discounts: number;
  final_on_road_price: number;
  applied_rules: {
    rto: AppliedRule[];
    insurance: AppliedRule[];
    handling: AppliedRule[];
    accessories: AppliedRule[];
    discounts: AppliedRule[];
  };
};

const COMPONENT_RULE_GROUPS: Record<
  string,
  keyof PricingBreakdown["applied_rules"]
> = {
  rto_percent: "rto",
  insurance_fixed: "insurance",
  handling_fixed: "handling",
  accessory_fixed: "accessories",
  consumer_scheme: "discounts",
  exchange_bonus: "discounts",
  scrap_bonus: "discounts",
  corporate_discount: "discounts",
};

export async function calculatePricing(
  request: PricingRequest,
): Promise<PricingBreakdown> {
  const supabase = getSupabaseAdminClient();

  const { data: variant, error: variantError } = await supabase
    .from("variants")
    .select(
      "id, model, variant_name, fuel_type, transmission, ex_showroom_price, is_active",
    )
    .eq("id", request.variant_id)
    .eq("is_active", true)
    .single();

  if (variantError || !variant) {
    console.error("[pricing-engine] Failed to load active variant", {
      variantId: request.variant_id,
      error: variantError,
    });
    throw new Error("Variant not found");
  }

  const normalizedContext = normalizePricingContext(
    request.exchange_required,
    request.pricing_context,
  );

  const { data: variantRules, error: variantRulesError } = await supabase
    .from("pricing_rules")
    .select(
      "id, model, variant_id, rule_type, rule_name, value_type, value, is_stackable, conditions, is_active",
    )
    .eq("is_active", true)
    .eq("variant_id", variant.id);

  if (variantRulesError) {
    console.error("[pricing-engine] Failed to load variant pricing rules", {
      variantId: variant.id,
      error: variantRulesError,
    });
    throw new Error("Failed to load pricing rules");
  }

  const { data: modelRules, error: modelRulesError } = await supabase
    .from("pricing_rules")
    .select(
      "id, model, variant_id, rule_type, rule_name, value_type, value, is_stackable, conditions, is_active",
    )
    .eq("is_active", true)
    .is("variant_id", null)
    .eq("model", variant.model);

  if (modelRulesError) {
    console.error("[pricing-engine] Failed to load model pricing rules", {
      variantId: variant.id,
      model: variant.model,
      error: modelRulesError,
    });
    throw new Error("Failed to load pricing rules");
  }

  const allRules = dedupeRulesById([
    ...(variantRules ?? []),
    ...(modelRules ?? []),
  ]);

  const exShowroomPrice = Number(variant.ex_showroom_price);
  const applicableRules = allRules
    .filter((rule) => COMPONENT_RULE_GROUPS[rule.rule_type])
    .filter((rule) => isRuleApplicable(rule, normalizedContext))
    .map((rule) => buildAppliedRule(rule, variant, exShowroomPrice));

  const groupedAppliedRules = groupAppliedRules(applicableRules);

  const rto = sumRuleAmounts(groupedAppliedRules.rto);
  const insurance = sumRuleAmounts(groupedAppliedRules.insurance);
  const handling = sumRuleAmounts(groupedAppliedRules.handling);
  const accessories = sumRuleAmounts(groupedAppliedRules.accessories);
  const totalDiscounts = sumRuleAmounts(groupedAppliedRules.discounts);

  const finalOnRoadPrice = roundCurrency(
    exShowroomPrice + rto + insurance + handling + accessories - totalDiscounts,
  );

  return {
    variant: {
      id: variant.id,
      model: variant.model,
      variant_name: variant.variant_name,
      fuel_type: variant.fuel_type,
      transmission: variant.transmission,
    },
    pricing_context: normalizedContext,
    ex_showroom_price: exShowroomPrice,
    rto,
    insurance,
    handling,
    accessories,
    total_discounts: totalDiscounts,
    final_on_road_price: finalOnRoadPrice,
    applied_rules: groupedAppliedRules,
  };
}

export function formatPricingForWhatsApp(
  breakdown: PricingBreakdown,
): string {
  const lines = [
    `Here is the on-road estimate for ${breakdown.variant.model} ${breakdown.variant.variant_name}:`,
    `Ex-showroom: Rs. ${formatPrice(breakdown.ex_showroom_price)}`,
    `RTO: Rs. ${formatPrice(breakdown.rto)}`,
    `Insurance: Rs. ${formatPrice(breakdown.insurance)}`,
    `Handling: Rs. ${formatPrice(breakdown.handling)}`,
    `Accessories: Rs. ${formatPrice(breakdown.accessories)}`,
    `Discounts: Rs. ${formatPrice(breakdown.total_discounts)}`,
    `Final on-road price: Rs. ${formatPrice(breakdown.final_on_road_price)}`,
  ];

  if (breakdown.applied_rules.discounts.length > 0) {
    const discountNames = breakdown.applied_rules.discounts.map((rule) =>
      rule.rule_name
    );
    lines.push(`Applied offers: ${discountNames.join(", ")}`);
  }

  return lines.join("\n");
}

function normalizePricingContext(
  exchangeRequired: boolean,
  pricingContext: Record<string, unknown> | null | undefined,
): Record<string, unknown> {
  return {
    exchange_required: exchangeRequired,
    ...(pricingContext ?? {}),
  };
}

function dedupeRulesById(rules: PricingRuleRow[]): PricingRuleRow[] {
  const dedupedRules = new Map<string, PricingRuleRow>();

  for (const rule of rules) {
    dedupedRules.set(rule.id, rule);
  }

  return [...dedupedRules.values()];
}

function isRuleApplicable(
  rule: PricingRuleRow,
  pricingContext: Record<string, unknown>,
): boolean {
  if (!rule.conditions) {
    return true;
  }

  for (
    const [conditionKey, conditionValue] of Object.entries(rule.conditions)
  ) {
    const contextValue = pricingContext[conditionKey];

    if (Array.isArray(conditionValue)) {
      if (!conditionValue.includes(contextValue)) {
        return false;
      }
      continue;
    }

    if (conditionValue !== contextValue) {
      return false;
    }
  }

  return true;
}

function buildAppliedRule(
  rule: PricingRuleRow,
  variant: VariantRow,
  exShowroomPrice: number,
): AppliedRule {
  return {
    id: rule.id,
    rule_type: rule.rule_type,
    rule_name: rule.rule_name,
    scope: rule.variant_id === variant.id ? "variant" : "model",
    value_type: rule.value_type,
    configured_value: Number(rule.value),
    computed_amount: computeRuleAmount(
      rule.value_type,
      Number(rule.value),
      exShowroomPrice,
    ),
    is_stackable: rule.is_stackable,
    conditions: rule.conditions,
  };
}

function computeRuleAmount(
  valueType: string,
  configuredValue: number,
  exShowroomPrice: number,
): number {
  if (valueType === "percent") {
    return roundCurrency((exShowroomPrice * configuredValue) / 100);
  }

  return roundCurrency(configuredValue);
}

function groupAppliedRules(
  appliedRules: AppliedRule[],
): PricingBreakdown["applied_rules"] {
  const grouped: PricingBreakdown["applied_rules"] = {
    rto: [],
    insurance: [],
    handling: [],
    accessories: [],
    discounts: [],
  };

  const groupedByRuleType = new Map<string, AppliedRule[]>();

  for (const rule of appliedRules) {
    const existingGroup = groupedByRuleType.get(rule.rule_type) ?? [];
    existingGroup.push(rule);
    groupedByRuleType.set(rule.rule_type, existingGroup);
  }

  for (const [ruleType, rules] of groupedByRuleType.entries()) {
    const targetGroup = COMPONENT_RULE_GROUPS[ruleType];

    if (!targetGroup) {
      continue;
    }

    const selectedRules = selectRulesForAggregation(rules);
    grouped[targetGroup].push(...selectedRules);
  }

  for (const rules of Object.values(grouped)) {
    rules.sort((left, right) => left.computed_amount - right.computed_amount);
  }

  return grouped;
}

function selectRulesForAggregation(rules: AppliedRule[]): AppliedRule[] {
  const stackableRules = rules.filter((rule) => rule.is_stackable);
  const nonStackableRules = rules.filter((rule) => !rule.is_stackable);

  if (nonStackableRules.length === 0) {
    return stackableRules;
  }

  const bestNonStackableRule = [...nonStackableRules].sort((left, right) => {
    if (right.computed_amount !== left.computed_amount) {
      return right.computed_amount - left.computed_amount;
    }

    if (left.scope !== right.scope) {
      return left.scope === "variant" ? -1 : 1;
    }

    return left.rule_name.localeCompare(right.rule_name);
  })[0];

  return [...stackableRules, bestNonStackableRule];
}

function sumRuleAmounts(rules: AppliedRule[]): number {
  return roundCurrency(
    rules.reduce((total, rule) => total + rule.computed_amount, 0),
  );
}

function roundCurrency(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

function formatPrice(value: number): string {
  return new Intl.NumberFormat("en-IN", {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(value);
}
