import type { MessageRecord } from "../../types";

export function MessageTimeline({ messages }: { messages: MessageRecord[] }) {
  if (messages.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center gap-2 rounded-2xl border border-dashed border-slate-200 py-12 text-slate-400">
        <svg width="32" height="32" viewBox="0 0 32 32" fill="none" stroke="currentColor" strokeWidth="1.3">
          <path d="M16 3C8.8 3 3 8.8 3 16c0 2.3.6 4.4 1.6 6.3L3 29l6.9-1.6A13 13 0 0016 29c7.2 0 13-5.8 13-13S23.2 3 16 3z" />
        </svg>
        <p className="text-sm">No messages yet</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-2.5">
      {messages.map((msg) => {
        const isOut = msg.direction === "outbound";
        return (
          <div key={msg.id} className={`flex flex-col gap-0.5 ${isOut ? "items-end" : "items-start"}`}>
            {isOut && <span className="ai-tag">AI reply</span>}
            <div className={isOut ? "bubble-out" : "bubble-in"}>
              {msg.content ?? "(no content)"}
              <div className={isOut ? "bubble-time-out" : "bubble-time-in"}>
                {new Date(msg.created_at).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}
