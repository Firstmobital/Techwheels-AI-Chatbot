-- Foundation schema for the AI dealership WhatsApp chatbot.
-- Aligned to docs/system_design.md Phase 1 database design.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.app_users (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  role text not null default 'staff' check (role in ('admin', 'sales', 'manager', 'staff')),
  phone text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  phone text not null unique,
  customer_name text,
  interested_model text,
  fuel_type text,
  transmission text,
  exchange_required boolean,
  lead_status text not null default 'new',
  assigned_to uuid references public.app_users (id) on delete set null,
  source text not null default 'whatsapp',
  city text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  phone text not null unique,
  lead_id uuid references public.leads (id) on delete set null,
  current_state text not null default 'new',
  current_step text,
  last_message_at timestamptz,
  is_open boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  phone text not null,
  direction text not null check (direction in ('inbound', 'outbound')),
  message_type text not null default 'text',
  content text,
  raw_payload jsonb,
  whatsapp_message_id text,
  status text,
  created_at timestamptz not null default now()
);

create table if not exists public.variants (
  id uuid primary key default gen_random_uuid(),
  model text not null,
  variant_name text not null,
  fuel_type text not null,
  transmission text not null,
  ex_showroom_price numeric(12, 2) not null check (ex_showroom_price >= 0),
  brochure_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (model, variant_name, fuel_type, transmission)
);

create table if not exists public.pricing_rules (
  id uuid primary key default gen_random_uuid(),
  model text,
  variant_id uuid references public.variants (id) on delete cascade,
  rule_type text not null,
  rule_name text not null,
  value_type text not null check (value_type in ('fixed', 'percent')),
  value numeric(12, 2) not null,
  is_stackable boolean not null default false,
  conditions jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (value >= 0),
  check (model is not null or variant_id is not null)
);

create table if not exists public.brochures (
  id uuid primary key default gen_random_uuid(),
  model text not null,
  file_name text not null,
  storage_path text not null,
  public_url text,
  version text,
  is_active boolean not null default true,
  uploaded_by uuid references public.app_users (id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.campaign_templates (
  id uuid primary key default gen_random_uuid(),
  template_name text not null unique,
  language_code text not null,
  category text not null,
  header_type text,
  body_example text,
  buttons jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.campaigns (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  template_id uuid references public.campaign_templates (id) on delete restrict,
  status text not null default 'draft' check (status in ('draft', 'sending', 'sent', 'failed')),
  recipient_source text not null,
  payload jsonb,
  created_by uuid references public.app_users (id) on delete set null,
  created_at timestamptz not null default now(),
  sent_at timestamptz
);

create table if not exists public.campaign_recipients (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns (id) on delete cascade,
  phone text not null,
  customer_name text,
  variables jsonb,
  send_status text not null default 'pending',
  error_message text,
  sent_at timestamptz,
  delivered_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_app_users_role on public.app_users (role);
create index if not exists idx_app_users_phone on public.app_users (phone);

create index if not exists idx_leads_status on public.leads (lead_status);
create index if not exists idx_leads_assigned_to on public.leads (assigned_to);
create index if not exists idx_leads_interested_model on public.leads (interested_model);
create index if not exists idx_leads_created_at on public.leads (created_at desc);

create index if not exists idx_conversations_lead_id on public.conversations (lead_id);
create index if not exists idx_conversations_state_open on public.conversations (current_state, is_open);
create index if not exists idx_conversations_last_message_at on public.conversations (last_message_at desc);

create index if not exists idx_messages_conversation_id_created_at on public.messages (conversation_id, created_at desc);
create index if not exists idx_messages_phone on public.messages (phone);
create index if not exists idx_messages_whatsapp_message_id on public.messages (whatsapp_message_id);
create index if not exists idx_messages_direction on public.messages (direction);

create index if not exists idx_variants_model_active on public.variants (model, is_active);
create index if not exists idx_variants_filters on public.variants (model, fuel_type, transmission, is_active);

create index if not exists idx_pricing_rules_model_active on public.pricing_rules (model, is_active);
create index if not exists idx_pricing_rules_variant_active on public.pricing_rules (variant_id, is_active);
create index if not exists idx_pricing_rules_rule_type on public.pricing_rules (rule_type);

create index if not exists idx_brochures_model_active on public.brochures (model, is_active);

create index if not exists idx_campaign_templates_active on public.campaign_templates (is_active);

create index if not exists idx_campaigns_template_id on public.campaigns (template_id);
create index if not exists idx_campaigns_status on public.campaigns (status);
create index if not exists idx_campaigns_created_by on public.campaigns (created_by);
create index if not exists idx_campaigns_created_at on public.campaigns (created_at desc);

create index if not exists idx_campaign_recipients_campaign_id on public.campaign_recipients (campaign_id);
create index if not exists idx_campaign_recipients_send_status on public.campaign_recipients (send_status);
create index if not exists idx_campaign_recipients_phone on public.campaign_recipients (phone);

drop trigger if exists set_leads_updated_at on public.leads;
create trigger set_leads_updated_at
before update on public.leads
for each row
execute function public.set_updated_at();

drop trigger if exists set_conversations_updated_at on public.conversations;
create trigger set_conversations_updated_at
before update on public.conversations
for each row
execute function public.set_updated_at();

drop trigger if exists set_variants_updated_at on public.variants;
create trigger set_variants_updated_at
before update on public.variants
for each row
execute function public.set_updated_at();

drop trigger if exists set_pricing_rules_updated_at on public.pricing_rules;
create trigger set_pricing_rules_updated_at
before update on public.pricing_rules
for each row
execute function public.set_updated_at();
