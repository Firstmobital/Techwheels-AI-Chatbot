import clsx from "clsx";

const colorByStatus: Record<string, string> = {
  new: "bg-sky-100 text-sky-800",
  qualified: "bg-emerald-100 text-emerald-800",
  closed: "bg-slate-200 text-slate-700",
};

export function LeadStatusBadge({ status }: { status: string }) {
  return (
    <span
      className={clsx(
        "inline-flex rounded-full px-2.5 py-1 text-xs font-semibold capitalize",
        colorByStatus[status] ?? "bg-amber-100 text-amber-800",
      )}
    >
      {status}
    </span>
  );
}
