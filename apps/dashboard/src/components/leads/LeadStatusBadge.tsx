export function LeadStatusBadge({ status }: { status: string }) {
  const map: Record<string, string> = {
    hot: "chip chip-hot",
    warm: "chip chip-warm",
    new: "chip chip-new",
    qualified: "chip chip-qualified",
    sold: "chip chip-sold",
    lost: "chip chip-lost",
  };
  const cls = map[status] ?? "chip chip-lost";
  return <span className={cls}>{status}</span>;
}
