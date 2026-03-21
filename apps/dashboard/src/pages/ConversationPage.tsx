import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { MessageTimeline } from "../components/conversations/MessageTimeline";
import { PageHeader } from "../components/common/PageHeader";
import { Panel } from "../components/common/Panel";
import { fetchConversationById, fetchMessages } from "../lib/dashboardApi";
import type { ConversationRecord, MessageRecord } from "../types";

export function ConversationPage() {
  const { conversationId = "" } = useParams();
  const [conversation, setConversation] = useState<ConversationRecord | null>(null);
  const [messages, setMessages] = useState<MessageRecord[]>([]);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      const [conversationRow, messageRows] = await Promise.all([
        fetchConversationById(conversationId),
        fetchMessages(conversationId),
      ]);

      if (!cancelled) {
        setConversation(conversationRow);
        setMessages(messageRows);
      }
    }

    void load();
    return () => {
      cancelled = true;
    };
  }, [conversationId]);

  return (
    <div>
      <PageHeader
        title="Conversation View"
        description={
          conversation
            ? `Full WhatsApp timeline for ${conversation.phone}.`
            : "Conversation timeline."
        }
      />

      <Panel title="Timeline">
        <MessageTimeline messages={messages} />
      </Panel>
    </div>
  );
}
