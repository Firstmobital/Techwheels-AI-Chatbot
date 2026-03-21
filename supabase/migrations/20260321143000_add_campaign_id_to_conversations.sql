alter table public.conversations
add column if not exists campaign_id uuid references public.campaigns (id) on delete set null;

create index if not exists idx_conversations_campaign_id
on public.conversations (campaign_id);
