-- Example seed data for local development and schema validation.
-- This file is safe to re-run because inserts are keyed on stable unique combinations.

insert into public.variants (
  model,
  variant_name,
  fuel_type,
  transmission,
  ex_showroom_price,
  brochure_url,
  is_active
)
values
  (
    'Hyundai Creta',
    'S',
    'Petrol',
    'Manual',
    1250000.00,
    'https://example.com/brochures/hyundai-creta-s-petrol-manual.pdf',
    true
  ),
  (
    'Hyundai Creta',
    'SX',
    'Petrol',
    'Automatic',
    1575000.00,
    'https://example.com/brochures/hyundai-creta-sx-petrol-automatic.pdf',
    true
  ),
  (
    'Kia Seltos',
    'HTK Plus',
    'Diesel',
    'Manual',
    1490000.00,
    'https://example.com/brochures/kia-seltos-htk-plus-diesel-manual.pdf',
    true
  )
on conflict (model, variant_name, fuel_type, transmission) do update
set
  ex_showroom_price = excluded.ex_showroom_price,
  brochure_url = excluded.brochure_url,
  is_active = excluded.is_active;

insert into public.pricing_rules (
  model,
  variant_id,
  rule_type,
  rule_name,
  value_type,
  value,
  is_stackable,
  conditions,
  is_active
)
select
  'Hyundai Creta',
  null,
  'rto_percent',
  'Creta Standard RTO',
  'percent',
  10.50,
  false,
  '{"city":"default"}'::jsonb,
  true
where not exists (
  select 1
  from public.pricing_rules
  where model = 'Hyundai Creta'
    and variant_id is null
    and rule_type = 'rto_percent'
    and rule_name = 'Creta Standard RTO'
);

insert into public.pricing_rules (
  model,
  variant_id,
  rule_type,
  rule_name,
  value_type,
  value,
  is_stackable,
  conditions,
  is_active
)
select
  'Hyundai Creta',
  null,
  'insurance_fixed',
  'Creta Insurance Base',
  'fixed',
  45000.00,
  false,
  '{"provider":"default"}'::jsonb,
  true
where not exists (
  select 1
  from public.pricing_rules
  where model = 'Hyundai Creta'
    and variant_id is null
    and rule_type = 'insurance_fixed'
    and rule_name = 'Creta Insurance Base'
);

insert into public.pricing_rules (
  model,
  variant_id,
  rule_type,
  rule_name,
  value_type,
  value,
  is_stackable,
  conditions,
  is_active
)
select
  'Hyundai Creta',
  null,
  'exchange_bonus',
  'Creta Exchange Bonus',
  'fixed',
  25000.00,
  false,
  '{"exchange_required":true}'::jsonb,
  true
where not exists (
  select 1
  from public.pricing_rules
  where model = 'Hyundai Creta'
    and variant_id is null
    and rule_type = 'exchange_bonus'
    and rule_name = 'Creta Exchange Bonus'
);

insert into public.pricing_rules (
  model,
  variant_id,
  rule_type,
  rule_name,
  value_type,
  value,
  is_stackable,
  conditions,
  is_active
)
select
  null,
  v.id,
  'handling_fixed',
  'Seltos HTK Plus Handling',
  'fixed',
  12000.00,
  false,
  '{"location":"default"}'::jsonb,
  true
from public.variants v
where v.model = 'Kia Seltos'
  and v.variant_name = 'HTK Plus'
  and v.fuel_type = 'Diesel'
  and v.transmission = 'Manual'
  and not exists (
    select 1
    from public.pricing_rules pr
    where pr.variant_id = v.id
      and pr.rule_type = 'handling_fixed'
      and pr.rule_name = 'Seltos HTK Plus Handling'
  );

insert into public.campaign_templates (
  template_name,
  language_code,
  category,
  header_type,
  body_example,
  buttons,
  is_active
)
values (
  'new_launch_followup',
  'en',
  'marketing',
  'text',
  'Hello {{1}}, check out our latest offers on {{2}}. Reply to get variant and on-road pricing details.',
  '[{"type":"quick_reply","text":"Show variants"},{"type":"quick_reply","text":"Get pricing"}]'::jsonb,
  true
)
on conflict (template_name) do update
set
  language_code = excluded.language_code,
  category = excluded.category,
  header_type = excluded.header_type,
  body_example = excluded.body_example,
  buttons = excluded.buttons,
  is_active = excluded.is_active;
