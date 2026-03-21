import type { MessageRecord } from "../../types";

export function MessageTimeline({ messages }: { messages: MessageRecord[] }) {
  if (messages.length === 0) {
    return (
      <div className="rounded-2xl border border-dashed border-slate-200 p-6 text-sm text-slate-500">
        No conversation messages found yet.
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {messages.map((message) => (
        <div
          key={message.id}
          className={`flex ${
            message.direction === "outbound" ? "justify-end" : "justify-start"
          }`}
        >
          <div
            className={`max-w-[80%] rounded-2xl px-4 py-3 text-sm shadow-sm ${
              message.direction === "outbound"
                ? "bg-ink text-white"
                : "bg-slate-100 text-slate-800"
            }`}
          >
            <div className="mb-1 text-xs opacity-70">
              {message.direction} • {new Date(message.created_at).toLocaleString()}
            </div>
            <div>{message.content ?? "(no text content)"}</div>
          </div>
        </div>
      ))}
    </div>
  );
}
