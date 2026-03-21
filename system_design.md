# AI Dealership WhatsApp Chatbot - System Design

## 1. Project Overview

This system is a WhatsApp-first AI chatbot for a car dealership.

Primary goals:
- respond to inbound customer queries on WhatsApp
- capture and qualify leads automatically
- recommend matching car variants
- provide deterministic on-road pricing
- answer brochure/features questions using AI
- store all conversations and leads in Supabase
- allow dealership staff to view leads and chats in a dashboard
- send outbound campaign messages using approved WhatsApp templates

Phase 1 scope:
- inbound WhatsApp chatbot
- lead capture flow
- variant recommendation
- pricing engine
- brochure-aware AI responses
- basic dashboard
- simple outbound campaign sender

Out of scope for Phase 1:
- advanced automation journeys
- finance eligibility engine
- stock management
- advanced analytics
- test drive slot allocation engine
- complex role-based permissions

---

## 2. Tech Stack

### Frontend
- React
- Vite
- TailwindCSS
- Zustand

### Backend
- Supabase PostgreSQL
- Supabase Auth
- Supabase Storage
- Supabase Edge Functions

### Messaging
- WhatsApp Cloud API (Meta)

### AI
- Gemini API for brochure/specification and general product explanation

### Hosting / DevOps
- GitHub
- Supabase CLI
- Vercel or Netlify for frontend (optional)
- Supabase hosted backend

---

## 3. Core Architecture

### High-level flow

1. Customer sends message on WhatsApp
2. Meta webhook calls backend endpoint
3. Backend validates webhook payload
4. System identifies or creates contact / conversation
5. Message router decides what to do:
   - continue lead capture flow
   - answer pricing request
   - answer feature/spec question using AI
   - fallback / escalate
6. Bot sends response via WhatsApp Cloud API
7. All messages are stored in database
8. Leads and conversations appear in dashboard

### Outbound campaign flow

1. Admin creates campaign in dashboard
2. Admin selects approved template
3. Admin uploads recipients or selects leads
4. System sends template messages through WhatsApp API
5. Delivery attempts and statuses are logged
6. If customer replies, inbound chatbot flow resumes

---

## 4. Modules

### Module A - Messaging Gateway
Responsibilities:
- webhook verification
- parse inbound WhatsApp messages
- send outbound WhatsApp replies
- normalize payload shape

### Module B - Conversation Manager
Responsibilities:
- create/find conversation by phone number
- maintain latest state
- link messages to conversations
- track lead capture step

### Module C - Lead Capture Engine
Responsibilities:
- ask sequential qualification questions
- save lead details
- update conversation state
- stop when minimum qualification is complete

Questions:
1. customer name
2. interested model
3. fuel type
4. transmission
5. exchange required or not

### Module D - Variant Engine
Responsibilities:
- fetch matching variants based on model/fuel/transmission
- return best-fit variants
- support recommendation text

### Module E - Pricing Engine
Responsibilities:
- calculate deterministic on-road price
- apply selected pricing rules and schemes
- return structured breakdown
- never rely on AI for final price

### Module F - AI Knowledge Engine
Responsibilities:
- answer brochure/features/specification questions
- compare models at feature level
- stay restricted to approved context
- fallback when uncertain

### Module G - Dashboard
Responsibilities:
- list leads
- show lead details
- show conversation history
- assign lead owner
- manage variants/pricing inputs
- create and send campaigns

### Module H - Campaign Sender
Responsibilities:
- create campaign
- select template
- upload recipients / pick leads
- send template messages
- log delivery results

---

## 5. Database Design

### 5.1 leads
Stores qualified or partially qualified customer leads.

Fields:
- id uuid primary key
- phone text unique not null
- customer_name text
- interested_model text
- fuel_type text
- transmission text
- exchange_required boolean
- lead_status text default 'new'
- assigned_to uuid null
- source text default 'whatsapp'
- city text null
- notes text null
- created_at timestamptz default now()
- updated_at timestamptz default now()

### 5.2 conversations
One active conversation thread per phone number.

Fields:
- id uuid primary key
- phone text unique not null
- lead_id uuid references leads(id) on delete set null
- current_state text default 'new'
- current_step text null
- last_message_at timestamptz
- is_open boolean default true
- created_at timestamptz default now()
- updated_at timestamptz default now()

### 5.3 messages
Stores all inbound and outbound messages.

Fields:
- id uuid primary key
- conversation_id uuid references conversations(id) on delete cascade
- phone text not null
- direction text not null
- message_type text default 'text'
- content text
- raw_payload jsonb
- whatsapp_message_id text null
- status text null
- created_at timestamptz default now()

direction values:
- inbound
- outbound

status examples:
- queued
- sent
- delivered
- read
- failed

### 5.4 variants
Master variant catalog.

Fields:
- id uuid primary key
- model text not null
- variant_name text not null
- fuel_type text not null
- transmission text not null
- ex_showroom_price numeric not null
- brochure_url text null
- is_active boolean default true
- created_at timestamptz default now()
- updated_at timestamptz default now()

### 5.5 pricing_rules
Stores price components and scheme logic.

Fields:
- id uuid primary key
- model text null
- variant_id uuid null references variants(id) on delete cascade
- rule_type text not null
- rule_name text not null
- value_type text not null
- value numeric not null
- is_stackable boolean default false
- conditions jsonb null
- is_active boolean default true
- created_at timestamptz default now()
- updated_at timestamptz default now()

rule_type examples:
- rto_percent
- insurance_fixed
- handling_fixed
- accessory_fixed
- consumer_scheme
- exchange_bonus
- scrap_bonus
- corporate_discount

value_type examples:
- fixed
- percent

### 5.6 brochures
Stores uploaded brochure metadata.

Fields:
- id uuid primary key
- model text not null
- file_name text not null
- storage_path text not null
- public_url text null
- version text null
- is_active boolean default true
- uploaded_by uuid null
- created_at timestamptz default now()

### 5.7 campaign_templates
Reference table for approved template metadata.

Fields:
- id uuid primary key
- template_name text unique not null
- language_code text not null
- category text not null
- header_type text null
- body_example text null
- buttons jsonb null
- is_active boolean default true
- created_at timestamptz default now()

### 5.8 campaigns
Campaign master record.

Fields:
- id uuid primary key
- name text not null
- template_id uuid references campaign_templates(id)
- status text default 'draft'
- recipient_source text not null
- payload jsonb null
- created_by uuid null
- created_at timestamptz default now()
- sent_at timestamptz null

status values:
- draft
- sending
- sent
- failed

### 5.9 campaign_recipients
Recipients attached to campaign.

Fields:
- id uuid primary key
- campaign_id uuid references campaigns(id) on delete cascade
- phone text not null
- customer_name text null
- variables jsonb null
- send_status text default 'pending'
- error_message text null
- sent_at timestamptz null
- delivered_at timestamptz null
- created_at timestamptz default now()

### 5.10 app_users
Optional profile table for dashboard users.

Fields:
- id uuid primary key
- full_name text
- role text default 'staff'
- phone text null
- is_active boolean default true
- created_at timestamptz default now()

roles:
- admin
- sales
- manager

---

## 6. State Machine Design

### States
- new
- lead_capture
- qualified
- pricing_query
- ai_query
- waiting_human
- closed

### Lead capture steps
- ask_name
- ask_model
- ask_fuel
- ask_transmission
- ask_exchange
- complete

### Example flow
- user says "Hi"
- state becomes lead_capture
- step ask_name
- after answer -> ask_model
- after answer -> ask_fuel
- after answer -> ask_transmission
- after answer -> ask_exchange
- then mark lead as qualified

---

## 7. Intent Routing

Incoming message handling priority:

1. if conversation has unfinished lead capture step:
   - continue lead capture

2. else if message asks price / on-road / discount / scheme:
   - call pricing engine

3. else if message asks feature/specification/comparison:
   - call AI knowledge engine

4. else:
   - send fallback and offer human assistance

Intent categories:
- greeting
- lead_capture
- pricing
- features
- comparison
- exchange
- fallback

---

## 8. Pricing Engine Rules

Principles:
- pricing must be deterministic
- AI must never calculate final price
- rule evaluation should be transparent and auditable

Base formula:
on_road_price =
ex_showroom_price
+ rto
+ insurance
+ handling_charges
+ accessories
- applicable_discounts

Inputs:
- model
- variant
- exchange_required
- optional pricing context

Output:
- variant details
- base ex-showroom price
- each component
- total on-road
- applied schemes list

Future enhancement:
- city-based tax and registration logic
- EV subsidies
- corporate eligibility
- finance offers

---

## 9. AI Knowledge Engine Design

Use AI for:
- feature questions
- brochure-based specs
- model comparisons
- simplified explanations

Do not use AI for:
- final pricing
- scheme amount computation
- lead status updates
- message delivery status

Prompt constraints:
- answer only from provided brochure/context
- if answer is uncertain, say not confirmed
- suggest connecting with dealership executive for confirmation
- keep answers concise and sales-friendly

Context sources:
- active brochure URL/content
- structured variant metadata
- dealership prompt instructions

Fallback:
- "I’m not fully sure about this feature for that exact variant. I can connect you with our sales advisor or help with available variant and pricing details."

---

## 10. API Design

### Public webhook endpoints
- GET /webhook
  - for Meta verification

- POST /webhook
  - receive inbound WhatsApp events

### Internal endpoints / edge functions
- POST /messages/send
- POST /router/handle-message
- POST /pricing/calculate
- POST /ai/answer
- POST /campaigns/send
- POST /campaigns/upload-recipients

### Dashboard data endpoints
- GET /leads
- GET /leads/:id
- GET /conversations/:id/messages
- GET /variants
- GET /campaigns
- POST /campaigns

---

## 11. Frontend Screens

### 11.1 Leads List
- search by phone/name
- filter by status
- assign owner

### 11.2 Lead Detail
- lead fields
- qualification data
- assigned salesperson
- notes

### 11.3 Conversation View
- full message timeline
- inbound/outbound labels
- timestamps

### 11.4 Variant & Pricing Admin
- manage active variants
- manage pricing rules
- upload brochures

### 11.5 Campaign Sender
- campaign name
- template selection
- CSV upload / select leads
- send action
- basic status results

---

## 12. Security and Permissions

Phase 1 simple role model:
- admin: full access
- manager: leads, conversations, campaigns
- sales: assigned leads + conversations

Phase 1 simplified rule:
- only authenticated users can access dashboard
- only admins can edit pricing rules and brochures
- campaigns can be sent by admin/manager only

---

## 13. Logging and Monitoring

Log these events:
- inbound webhook received
- outbound send attempted
- lead created
- lead updated
- pricing request handled
- AI fallback triggered
- campaign message sent/failed

Store raw payloads where useful for debugging.

---

## 14. Folder Structure

/apps
  /dashboard
    /src
      /pages
      /components
      /store
      /lib

/supabase
  /functions
    /whatsapp-webhook
    /message-router
    /pricing-engine
    /ai-answer
    /campaign-sender
  /migrations

/docs
  system_design.md
  api_contracts.md
  pricing_rules.md
  prompt_strategy.md

---

## 15. Recommended Build Order

1. database schema
2. webhook receiver
3. conversation + message persistence
4. lead capture flow
5. variant engine
6. pricing engine
7. AI answer engine
8. router integration
9. dashboard
10. campaign sender

---

## 16. Definition of Done for Phase 1

Phase 1 is complete when:
- inbound WhatsApp messages are received and stored
- bot can capture qualified leads
- bot can suggest variants
- bot can return deterministic pricing breakdown
- bot can answer brochure-based feature questions with safe fallback
- dashboard shows leads and conversation history
- admin can send template-based outbound campaigns
- campaign replies continue inside chatbot flow
