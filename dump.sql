


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."app_users" (
    "id" "uuid" NOT NULL,
    "full_name" "text",
    "role" "text" DEFAULT 'staff'::"text" NOT NULL,
    "phone" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "app_users_role_check" CHECK (("role" = ANY (ARRAY['admin'::"text", 'sales'::"text", 'manager'::"text", 'staff'::"text"])))
);


ALTER TABLE "public"."app_users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."brochures" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "model" "text" NOT NULL,
    "file_name" "text" NOT NULL,
    "storage_path" "text" NOT NULL,
    "public_url" "text",
    "version" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "uploaded_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."brochures" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."campaign_recipients" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "campaign_id" "uuid" NOT NULL,
    "phone" "text" NOT NULL,
    "customer_name" "text",
    "variables" "jsonb",
    "send_status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "error_message" "text",
    "sent_at" timestamp with time zone,
    "delivered_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."campaign_recipients" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."campaign_templates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "template_name" "text" NOT NULL,
    "language_code" "text" NOT NULL,
    "category" "text" NOT NULL,
    "header_type" "text",
    "body_example" "text",
    "buttons" "jsonb",
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."campaign_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."campaigns" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "template_id" "uuid",
    "status" "text" DEFAULT 'draft'::"text" NOT NULL,
    "recipient_source" "text" NOT NULL,
    "payload" "jsonb",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "sent_at" timestamp with time zone,
    CONSTRAINT "campaigns_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'sending'::"text", 'sent'::"text", 'failed'::"text"])))
);


ALTER TABLE "public"."campaigns" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."conversations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "phone" "text" NOT NULL,
    "lead_id" "uuid",
    "current_state" "text" DEFAULT 'new'::"text" NOT NULL,
    "current_step" "text",
    "last_message_at" timestamp with time zone,
    "is_open" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "campaign_id" "uuid"
);


ALTER TABLE "public"."conversations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."leads" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "phone" "text" NOT NULL,
    "customer_name" "text",
    "interested_model" "text",
    "fuel_type" "text",
    "transmission" "text",
    "exchange_required" boolean,
    "lead_status" "text" DEFAULT 'new'::"text" NOT NULL,
    "assigned_to" "uuid",
    "source" "text" DEFAULT 'whatsapp'::"text" NOT NULL,
    "city" "text",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."leads" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "conversation_id" "uuid" NOT NULL,
    "phone" "text" NOT NULL,
    "direction" "text" NOT NULL,
    "message_type" "text" DEFAULT 'text'::"text" NOT NULL,
    "content" "text",
    "raw_payload" "jsonb",
    "whatsapp_message_id" "text",
    "status" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "messages_direction_check" CHECK (("direction" = ANY (ARRAY['inbound'::"text", 'outbound'::"text"])))
);


ALTER TABLE "public"."messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pricing_rules" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "model" "text",
    "variant_id" "uuid",
    "rule_type" "text" NOT NULL,
    "rule_name" "text" NOT NULL,
    "value_type" "text" NOT NULL,
    "value" numeric(12,2) NOT NULL,
    "is_stackable" boolean DEFAULT false NOT NULL,
    "conditions" "jsonb",
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "pricing_rules_check" CHECK ((("model" IS NOT NULL) OR ("variant_id" IS NOT NULL))),
    CONSTRAINT "pricing_rules_value_check" CHECK (("value" >= (0)::numeric)),
    CONSTRAINT "pricing_rules_value_type_check" CHECK (("value_type" = ANY (ARRAY['fixed'::"text", 'percent'::"text"])))
);


ALTER TABLE "public"."pricing_rules" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."variants" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "model" "text" NOT NULL,
    "variant_name" "text" NOT NULL,
    "fuel_type" "text" NOT NULL,
    "transmission" "text" NOT NULL,
    "ex_showroom_price" numeric(12,2) NOT NULL,
    "brochure_url" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "insurance" numeric(12,2) DEFAULT 0,
    "rto_standard" numeric(12,2) DEFAULT 0,
    "rto_rate" numeric(5,4) DEFAULT 0,
    "rto_bh" numeric(12,2) DEFAULT 0,
    "rto_scrap" numeric(12,2) DEFAULT 0,
    "scheme_consumer" numeric(12,2) DEFAULT 0,
    "scheme_exchange_scrap" numeric(12,2) DEFAULT 0,
    "scheme_additional_scrap" numeric(12,2) DEFAULT 0,
    "scheme_corporate" numeric(12,2) DEFAULT 0,
    "scheme_intervention" numeric(12,2) DEFAULT 0,
    "scheme_solar" numeric(12,2) DEFAULT 0,
    "scheme_msme" numeric(12,2) DEFAULT 0,
    "scheme_green_bonus" numeric(12,2) DEFAULT 0,
    CONSTRAINT "variants_ex_showroom_price_check" CHECK (("ex_showroom_price" >= (0)::numeric))
);


ALTER TABLE "public"."variants" OWNER TO "postgres";


ALTER TABLE ONLY "public"."app_users"
    ADD CONSTRAINT "app_users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."brochures"
    ADD CONSTRAINT "brochures_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."campaign_recipients"
    ADD CONSTRAINT "campaign_recipients_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."campaign_templates"
    ADD CONSTRAINT "campaign_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."campaign_templates"
    ADD CONSTRAINT "campaign_templates_template_name_key" UNIQUE ("template_name");



ALTER TABLE ONLY "public"."campaigns"
    ADD CONSTRAINT "campaigns_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."leads"
    ADD CONSTRAINT "leads_phone_key" UNIQUE ("phone");



ALTER TABLE ONLY "public"."leads"
    ADD CONSTRAINT "leads_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pricing_rules"
    ADD CONSTRAINT "pricing_rules_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."variants"
    ADD CONSTRAINT "variants_model_variant_name_fuel_type_transmission_key" UNIQUE ("model", "variant_name", "fuel_type", "transmission");



ALTER TABLE ONLY "public"."variants"
    ADD CONSTRAINT "variants_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_app_users_phone" ON "public"."app_users" USING "btree" ("phone");



CREATE INDEX "idx_app_users_role" ON "public"."app_users" USING "btree" ("role");



CREATE INDEX "idx_brochures_model_active" ON "public"."brochures" USING "btree" ("model", "is_active");



CREATE INDEX "idx_campaign_recipients_campaign_id" ON "public"."campaign_recipients" USING "btree" ("campaign_id");



CREATE INDEX "idx_campaign_recipients_phone" ON "public"."campaign_recipients" USING "btree" ("phone");



CREATE INDEX "idx_campaign_recipients_send_status" ON "public"."campaign_recipients" USING "btree" ("send_status");



CREATE INDEX "idx_campaign_templates_active" ON "public"."campaign_templates" USING "btree" ("is_active");



CREATE INDEX "idx_campaigns_created_at" ON "public"."campaigns" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_campaigns_created_by" ON "public"."campaigns" USING "btree" ("created_by");



CREATE INDEX "idx_campaigns_status" ON "public"."campaigns" USING "btree" ("status");



CREATE INDEX "idx_campaigns_template_id" ON "public"."campaigns" USING "btree" ("template_id");



CREATE INDEX "idx_conversations_campaign_id" ON "public"."conversations" USING "btree" ("campaign_id");



CREATE INDEX "idx_conversations_last_message_at" ON "public"."conversations" USING "btree" ("last_message_at" DESC);



CREATE INDEX "idx_conversations_lead_id" ON "public"."conversations" USING "btree" ("lead_id");



CREATE INDEX "idx_conversations_state_open" ON "public"."conversations" USING "btree" ("current_state", "is_open");



CREATE INDEX "idx_leads_assigned_to" ON "public"."leads" USING "btree" ("assigned_to");



CREATE INDEX "idx_leads_created_at" ON "public"."leads" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_leads_interested_model" ON "public"."leads" USING "btree" ("interested_model");



CREATE INDEX "idx_leads_status" ON "public"."leads" USING "btree" ("lead_status");



CREATE INDEX "idx_messages_conversation_id_created_at" ON "public"."messages" USING "btree" ("conversation_id", "created_at" DESC);



CREATE INDEX "idx_messages_direction" ON "public"."messages" USING "btree" ("direction");



CREATE INDEX "idx_messages_phone" ON "public"."messages" USING "btree" ("phone");



CREATE INDEX "idx_messages_whatsapp_message_id" ON "public"."messages" USING "btree" ("whatsapp_message_id");



CREATE INDEX "idx_pricing_rules_model_active" ON "public"."pricing_rules" USING "btree" ("model", "is_active");



CREATE INDEX "idx_pricing_rules_rule_type" ON "public"."pricing_rules" USING "btree" ("rule_type");



CREATE INDEX "idx_pricing_rules_variant_active" ON "public"."pricing_rules" USING "btree" ("variant_id", "is_active");



CREATE INDEX "idx_variants_filters" ON "public"."variants" USING "btree" ("model", "fuel_type", "transmission", "is_active");



CREATE INDEX "idx_variants_model_active" ON "public"."variants" USING "btree" ("model", "is_active");



CREATE UNIQUE INDEX "uq_conversations_phone_open" ON "public"."conversations" USING "btree" ("phone") WHERE ("is_open" = true);



CREATE UNIQUE INDEX "uq_messages_whatsapp_message_id" ON "public"."messages" USING "btree" ("whatsapp_message_id") WHERE ("whatsapp_message_id" IS NOT NULL);



CREATE OR REPLACE TRIGGER "set_conversations_updated_at" BEFORE UPDATE ON "public"."conversations" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_leads_updated_at" BEFORE UPDATE ON "public"."leads" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_pricing_rules_updated_at" BEFORE UPDATE ON "public"."pricing_rules" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_variants_updated_at" BEFORE UPDATE ON "public"."variants" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



ALTER TABLE ONLY "public"."app_users"
    ADD CONSTRAINT "app_users_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."brochures"
    ADD CONSTRAINT "brochures_uploaded_by_fkey" FOREIGN KEY ("uploaded_by") REFERENCES "public"."app_users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."campaign_recipients"
    ADD CONSTRAINT "campaign_recipients_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."campaigns"
    ADD CONSTRAINT "campaigns_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."app_users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."campaigns"
    ADD CONSTRAINT "campaigns_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "public"."campaign_templates"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_lead_id_fkey" FOREIGN KEY ("lead_id") REFERENCES "public"."leads"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."leads"
    ADD CONSTRAINT "leads_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "public"."app_users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pricing_rules"
    ADD CONSTRAINT "pricing_rules_variant_id_fkey" FOREIGN KEY ("variant_id") REFERENCES "public"."variants"("id") ON DELETE CASCADE;



CREATE POLICY "Allow authenticated users to create campaigns" ON "public"."campaigns" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Allow authenticated users to insert campaign recipients" ON "public"."campaign_recipients" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Allow authenticated users to read app_users" ON "public"."app_users" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow authenticated users to read campaign recipients" ON "public"."campaign_recipients" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow authenticated users to read campaigns" ON "public"."campaigns" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow authenticated users to read conversations" ON "public"."conversations" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow authenticated users to read leads" ON "public"."leads" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow authenticated users to read messages" ON "public"."messages" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow authenticated users to update campaigns" ON "public"."campaigns" FOR UPDATE TO "authenticated" USING (true);



ALTER TABLE "public"."app_users" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "auth_delete" ON "public"."app_users" FOR DELETE TO "authenticated" USING (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_delete" ON "public"."campaign_recipients" FOR DELETE TO "authenticated" USING (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_delete" ON "public"."campaign_templates" FOR DELETE TO "authenticated" USING (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_delete" ON "public"."campaigns" FOR DELETE TO "authenticated" USING (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_delete" ON "public"."variants" FOR DELETE TO "authenticated" USING (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_insert" ON "public"."app_users" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_insert" ON "public"."campaign_recipients" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_insert" ON "public"."campaign_templates" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_insert" ON "public"."campaigns" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_insert" ON "public"."conversations" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_insert" ON "public"."leads" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_insert" ON "public"."messages" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_insert" ON "public"."variants" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_select" ON "public"."app_users" FOR SELECT TO "authenticated" USING (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_select" ON "public"."campaign_recipients" FOR SELECT TO "authenticated" USING (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_select" ON "public"."campaign_templates" FOR SELECT TO "authenticated" USING (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_select" ON "public"."campaigns" FOR SELECT TO "authenticated" USING (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_select" ON "public"."conversations" FOR SELECT TO "authenticated" USING (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_select" ON "public"."leads" FOR SELECT TO "authenticated" USING (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_select" ON "public"."messages" FOR SELECT TO "authenticated" USING (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_select" ON "public"."variants" FOR SELECT TO "authenticated" USING (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_update" ON "public"."app_users" FOR UPDATE TO "authenticated" USING (("auth"."uid"() IS NOT NULL)) WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_update" ON "public"."campaign_recipients" FOR UPDATE TO "authenticated" USING (("auth"."uid"() IS NOT NULL)) WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_update" ON "public"."campaign_templates" FOR UPDATE TO "authenticated" USING (("auth"."uid"() IS NOT NULL)) WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_update" ON "public"."campaigns" FOR UPDATE TO "authenticated" USING (("auth"."uid"() IS NOT NULL)) WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_update" ON "public"."conversations" FOR UPDATE TO "authenticated" USING (("auth"."uid"() IS NOT NULL)) WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_update" ON "public"."leads" FOR UPDATE TO "authenticated" USING (("auth"."uid"() IS NOT NULL)) WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_update" ON "public"."messages" FOR UPDATE TO "authenticated" USING (("auth"."uid"() IS NOT NULL)) WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "auth_update" ON "public"."variants" FOR UPDATE TO "authenticated" USING (("auth"."uid"() IS NOT NULL)) WITH CHECK (("auth"."uid"() IS NOT NULL));



ALTER TABLE "public"."campaign_recipients" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."campaign_templates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."campaigns" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."conversations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."leads" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."variants" ENABLE ROW LEVEL SECURITY;


REVOKE USAGE ON SCHEMA "public" FROM PUBLIC;
GRANT USAGE ON SCHEMA "public" TO "service_role";
GRANT USAGE ON SCHEMA "public" TO "authenticated";



GRANT ALL ON TABLE "public"."app_users" TO "service_role";
GRANT ALL ON TABLE "public"."app_users" TO "authenticated";



GRANT ALL ON TABLE "public"."brochures" TO "service_role";
GRANT ALL ON TABLE "public"."brochures" TO "authenticated";



GRANT ALL ON TABLE "public"."campaign_recipients" TO "service_role";
GRANT ALL ON TABLE "public"."campaign_recipients" TO "authenticated";



GRANT ALL ON TABLE "public"."campaign_templates" TO "service_role";
GRANT ALL ON TABLE "public"."campaign_templates" TO "authenticated";



GRANT ALL ON TABLE "public"."campaigns" TO "service_role";
GRANT ALL ON TABLE "public"."campaigns" TO "authenticated";



GRANT ALL ON TABLE "public"."conversations" TO "service_role";
GRANT ALL ON TABLE "public"."conversations" TO "authenticated";



GRANT ALL ON TABLE "public"."leads" TO "service_role";
GRANT ALL ON TABLE "public"."leads" TO "authenticated";



GRANT ALL ON TABLE "public"."messages" TO "service_role";
GRANT ALL ON TABLE "public"."messages" TO "authenticated";



GRANT ALL ON TABLE "public"."pricing_rules" TO "service_role";
GRANT ALL ON TABLE "public"."pricing_rules" TO "authenticated";



GRANT ALL ON TABLE "public"."variants" TO "service_role";
GRANT ALL ON TABLE "public"."variants" TO "authenticated";




