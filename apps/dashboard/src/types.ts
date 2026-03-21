export type LeadStatus = "new" | "qualified" | "closed" | string;

export type LeadRecord = {
  id: string;
  phone: string;
  customer_name: string | null;
  interested_model: string | null;
  fuel_type: string | null;
  transmission: string | null;
  exchange_required: boolean | null;
  lead_status: LeadStatus;
  assigned_to: string | null;
  source: string;
  city: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
};

export type ConversationRecord = {
  id: string;
  phone: string;
  lead_id: string | null;
  current_state: string;
  current_step: string | null;
  last_message_at: string | null;
  is_open: boolean;
  created_at: string;
  updated_at: string;
};

export type MessageRecord = {
  id: string;
  conversation_id: string;
  phone: string;
  direction: "inbound" | "outbound" | string;
  message_type: string;
  content: string | null;
  raw_payload: unknown;
  whatsapp_message_id: string | null;
  status: string | null;
  created_at: string;
};

export type VariantRecord = {
  id: string;
  model: string;
  variant_name: string;
  fuel_type: string;
  transmission: string;
  ex_showroom_price: number;
  brochure_url: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
};

export type PricingRuleRecord = {
  id: string;
  model: string | null;
  variant_id: string | null;
  rule_type: string;
  rule_name: string;
  value_type: string;
  value: number;
  is_stackable: boolean;
  conditions: Record<string, unknown> | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
};

export type CampaignTemplateRecord = {
  id: string;
  template_name: string;
  language_code: string;
  category: string;
  header_type: string | null;
  body_example: string | null;
  buttons: unknown;
  is_active: boolean;
  created_at: string;
};

export type CampaignRecord = {
  id: string;
  name: string;
  template_id: string | null;
  status: string;
  recipient_source: string;
  payload: Record<string, unknown> | null;
  created_by: string | null;
  created_at: string;
  sent_at: string | null;
};

export type CampaignRecipientRecord = {
  id: string;
  campaign_id: string;
  phone: string;
  customer_name: string | null;
  variables: Record<string, unknown> | null;
  send_status: string;
  error_message: string | null;
  sent_at: string | null;
  delivered_at: string | null;
  created_at: string;
};

export type AppUserRecord = {
  id: string;
  full_name: string | null;
  role: string;
  phone: string | null;
  is_active: boolean;
  created_at: string;
};
