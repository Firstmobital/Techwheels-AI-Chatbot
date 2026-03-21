import type { PropsWithChildren } from "react";

type PanelProps = PropsWithChildren<{
  title?: string;
  description?: string;
}>;

export function Panel({ title, description, children }: PanelProps) {
  return (
    <section className="panel p-5">
      {title ? (
        <div className="mb-4">
          <h3 className="text-base font-semibold text-ink">{title}</h3>
          {description ? (
            <p className="mt-1 text-sm text-slate-500">{description}</p>
          ) : null}
        </div>
      ) : null}
      {children}
    </section>
  );
}
