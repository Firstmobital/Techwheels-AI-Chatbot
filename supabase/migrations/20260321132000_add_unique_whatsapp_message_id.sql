create unique index if not exists uq_messages_whatsapp_message_id
on public.messages (whatsapp_message_id)
where whatsapp_message_id is not null;
