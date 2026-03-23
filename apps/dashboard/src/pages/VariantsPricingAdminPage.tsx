import { useEffect, useState } from "react";
import { PageHeader } from "../components/common/PageHeader";
import { Panel } from "../components/common/Panel";
import {
  fetchPricingRules,
  fetchVariants,
  savePricingRule,
  saveVariant,
} from "../lib/dashboardApi";
import type { PricingRuleRecord, VariantRecord } from "../types";

const emptyVariantForm = {
  model: "",
  variant_name: "",
  fuel_type: "",
  transmission: "",
  ex_showroom_price: 0,
  insurance: 0,
  rto_standard: 0,
  rto_rate: 0,
  rto_bh: 0,
  rto_scrap: 0,
  scheme_consumer: 0,
  scheme_exchange_scrap: 0,
  scheme_additional_scrap: 0,
  scheme_corporate: 0,
  scheme_intervention: 0,
  scheme_solar: 0,
  scheme_msme: 0,
  scheme_green_bonus: 0,
  brochure_url: "",
};

const emptyRuleForm = {
  model: "",
  variant_id: "",
  rule_type: "rto_percent",
  rule_name: "",
  value_type: "fixed",
  value: 0,
};

export function VariantsPricingAdminPage() {
  const [variants, setVariants] = useState<VariantRecord[]>([]);
  const [pricingRules, setPricingRules] = useState<PricingRuleRecord[]>([]);
  const [variantForm, setVariantForm] = useState(emptyVariantForm);
  const [ruleForm, setRuleForm] = useState(emptyRuleForm);

  async function loadData() {
    const [variantRows, pricingRuleRows] = await Promise.all([
      fetchVariants(),
      fetchPricingRules(),
    ]);
    setVariants(variantRows);
    setPricingRules(pricingRuleRows);
  }

  useEffect(() => {
    void loadData();
  }, []);

  async function handleVariantSave() {
    await saveVariant({
      ...variantForm,
      brochure_url: variantForm.brochure_url || null,
      is_active: true,
    });
    setVariantForm(emptyVariantForm);
    await loadData();
  }

  async function handleRuleSave() {
    await savePricingRule({
      ...ruleForm,
      model: ruleForm.model || null,
      variant_id: ruleForm.variant_id || null,
      is_stackable: false,
      conditions: null,
      is_active: true,
    });
    setRuleForm(emptyRuleForm);
    await loadData();
  }

  return (
    <div>
      <PageHeader
        title="Variant and Pricing Admin"
        description="Manage active variants and deterministic pricing inputs."
      />

      <div className="grid gap-6 xl:grid-cols-2">
        <Panel title="Variant Form" description="Basic CRUD-ready input for variant records.">
          <div className="grid gap-4 md:grid-cols-2">
            <TextField label="Model" value={variantForm.model} onChange={(value) => setVariantForm((current) => ({ ...current, model: value }))} />
            <TextField label="Variant Name" value={variantForm.variant_name} onChange={(value) => setVariantForm((current) => ({ ...current, variant_name: value }))} />
            <TextField label="Fuel Type" value={variantForm.fuel_type} onChange={(value) => setVariantForm((current) => ({ ...current, fuel_type: value }))} />
            <TextField label="Transmission" value={variantForm.transmission} onChange={(value) => setVariantForm((current) => ({ ...current, transmission: value }))} />
            <NumberField label="Ex-showroom Price" value={variantForm.ex_showroom_price} onChange={(value) => setVariantForm((current) => ({ ...current, ex_showroom_price: value }))} />
            <TextField label="Brochure URL" value={variantForm.brochure_url} onChange={(value) => setVariantForm((current) => ({ ...current, brochure_url: value }))} />
          </div>
          <div className="mt-6">
            <h3 className="text-sm font-semibold text-slate-700">Charges (₹)</h3>
            <div className="mt-3 grid gap-4 md:grid-cols-2">
              <NumberField label="Insurance" value={variantForm.insurance} onChange={(value) => setVariantForm((current) => ({ ...current, insurance: value }))} min={0} step={1} />
              <NumberField label="RTO Standard" value={variantForm.rto_standard} onChange={(value) => setVariantForm((current) => ({ ...current, rto_standard: value }))} min={0} step={1} />
              <NumberField label="RTO Rate" value={variantForm.rto_rate} onChange={(value) => setVariantForm((current) => ({ ...current, rto_rate: value }))} min={0} step={1} />
              <NumberField label="RTO BH" value={variantForm.rto_bh} onChange={(value) => setVariantForm((current) => ({ ...current, rto_bh: value }))} min={0} step={1} />
              <NumberField label="RTO Scrap" value={variantForm.rto_scrap} onChange={(value) => setVariantForm((current) => ({ ...current, rto_scrap: value }))} min={0} step={1} />
            </div>
          </div>
          <div className="mt-6">
            <h3 className="text-sm font-semibold text-slate-700">Schemes (₹)</h3>
            <div className="mt-3 grid gap-4 md:grid-cols-2">
              <NumberField label="Consumer Scheme" value={variantForm.scheme_consumer} onChange={(value) => setVariantForm((current) => ({ ...current, scheme_consumer: value }))} min={0} step={1} />
              <NumberField label="Exchange Scrap Scheme" value={variantForm.scheme_exchange_scrap} onChange={(value) => setVariantForm((current) => ({ ...current, scheme_exchange_scrap: value }))} min={0} step={1} />
              <NumberField label="Additional Scrap Scheme" value={variantForm.scheme_additional_scrap} onChange={(value) => setVariantForm((current) => ({ ...current, scheme_additional_scrap: value }))} min={0} step={1} />
              <NumberField label="Corporate Scheme" value={variantForm.scheme_corporate} onChange={(value) => setVariantForm((current) => ({ ...current, scheme_corporate: value }))} min={0} step={1} />
              <NumberField label="Intervention Scheme" value={variantForm.scheme_intervention} onChange={(value) => setVariantForm((current) => ({ ...current, scheme_intervention: value }))} min={0} step={1} />
              <NumberField label="Solar Scheme" value={variantForm.scheme_solar} onChange={(value) => setVariantForm((current) => ({ ...current, scheme_solar: value }))} min={0} step={1} />
              <NumberField label="MSME Scheme" value={variantForm.scheme_msme} onChange={(value) => setVariantForm((current) => ({ ...current, scheme_msme: value }))} min={0} step={1} />
              <NumberField label="Green Bonus Scheme" value={variantForm.scheme_green_bonus} onChange={(value) => setVariantForm((current) => ({ ...current, scheme_green_bonus: value }))} min={0} step={1} />
            </div>
          </div>
          <button className="action-button mt-4" onClick={() => void handleVariantSave()}>
            Save Variant
          </button>
        </Panel>

        <Panel title="Pricing Rule Form" description="Basic CRUD-ready input for pricing rules.">
          <div className="grid gap-4 md:grid-cols-2">
            <TextField label="Model" value={ruleForm.model} onChange={(value) => setRuleForm((current) => ({ ...current, model: value }))} />
            <select className="field-input" value={ruleForm.variant_id} onChange={(event) => setRuleForm((current) => ({ ...current, variant_id: event.target.value }))}>
              <option value="">No variant link</option>
              {variants.map((variant) => (
                <option key={variant.id} value={variant.id}>
                  {variant.model} - {variant.variant_name}
                </option>
              ))}
            </select>
            <select className="field-input" value={ruleForm.rule_type} onChange={(event) => setRuleForm((current) => ({ ...current, rule_type: event.target.value }))}>
              <option value="rto_percent">rto_percent</option>
              <option value="insurance_fixed">insurance_fixed</option>
              <option value="handling_fixed">handling_fixed</option>
              <option value="accessory_fixed">accessory_fixed</option>
              <option value="consumer_scheme">consumer_scheme</option>
              <option value="exchange_bonus">exchange_bonus</option>
              <option value="scrap_bonus">scrap_bonus</option>
              <option value="corporate_discount">corporate_discount</option>
            </select>
            <TextField label="Rule Name" value={ruleForm.rule_name} onChange={(value) => setRuleForm((current) => ({ ...current, rule_name: value }))} />
            <select className="field-input" value={ruleForm.value_type} onChange={(event) => setRuleForm((current) => ({ ...current, value_type: event.target.value }))}>
              <option value="fixed">fixed</option>
              <option value="percent">percent</option>
            </select>
            <NumberField label="Value" value={ruleForm.value} onChange={(value) => setRuleForm((current) => ({ ...current, value }))} />
          </div>
          <button className="action-button mt-4" onClick={() => void handleRuleSave()}>
            Save Pricing Rule
          </button>
        </Panel>
      </div>

      <div className="mt-6 grid gap-6 xl:grid-cols-2">
        <Panel title="Variants">
          <SimpleTable
            columns={["Model", "Variant", "Fuel", "Transmission", "Price"]}
            rows={variants.map((variant) => [
              variant.model,
              variant.variant_name,
              variant.fuel_type,
              variant.transmission,
              new Intl.NumberFormat("en-IN").format(variant.ex_showroom_price),
            ])}
          />
        </Panel>

        <Panel title="Pricing Rules">
          <SimpleTable
            columns={["Rule Name", "Rule Type", "Model", "Value Type", "Value"]}
            rows={pricingRules.map((rule) => [
              rule.rule_name,
              rule.rule_type,
              rule.model ?? "Variant linked",
              rule.value_type,
              String(rule.value),
            ])}
          />
        </Panel>
      </div>
    </div>
  );
}

function TextField({
  label,
  value,
  onChange,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
}) {
  return (
    <div>
      <label className="field-label">{label}</label>
      <input className="field-input" value={value} onChange={(event) => onChange(event.target.value)} />
    </div>
  );
}

function NumberField({
  label,
  value,
  onChange,
  min,
  step,
}: {
  label: string;
  value: number;
  onChange: (value: number) => void;
  min?: number;
  step?: number;
}) {
  return (
    <div>
      <label className="field-label">{label}</label>
      <input
        className="field-input"
        type="number"
        min={min}
        step={step}
        value={value}
        onChange={(event) => onChange(Number(event.target.value))}
      />
    </div>
  );
}

function SimpleTable({
  columns,
  rows,
}: {
  columns: string[];
  rows: string[][];
}) {
  return (
    <div className="overflow-x-auto">
      <table className="min-w-full text-sm">
        <thead>
          <tr className="border-b border-slate-200 text-left text-slate-500">
            {columns.map((column) => (
              <th key={column} className="px-3 py-2 font-medium">
                {column}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, index) => (
            <tr key={index} className="border-b border-slate-100">
              {row.map((cell, cellIndex) => (
                <td key={`${index}-${cellIndex}`} className="px-3 py-2 text-slate-700">
                  {cell}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
