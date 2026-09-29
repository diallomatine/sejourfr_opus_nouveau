import { Info, AlertTriangle, Lightbulb, type LucideIcon } from "lucide-react";

type CalloutType = "info" | "warning" | "tip";

const ICONS: Record<CalloutType, LucideIcon> = {
  info: Info,
  warning: AlertTriangle,
  tip: Lightbulb,
};

interface Props {
  type?: CalloutType;
  title?: string;
  children: React.ReactNode;
}

export function Callout({ type = "info", title, children }: Props) {
  const Icon = ICONS[type];
  return (
    <aside role="note" className={`mdx-callout mdx-callout--${type}`}>
      <span aria-hidden className="mdx-callout-icon">
        <Icon className="mdx-callout-icon-svg" />
      </span>
      <div className="mdx-callout-body">
        {title && <div className="mdx-callout-title">{title}</div>}
        <div className="mdx-callout-content">{children}</div>
      </div>
      <style>{`
        .mdx-callout {
          display: flex;
          align-items: flex-start;
          gap: 12px;
          margin: 24px 0;
          padding: 16px;
          border-left: 4px solid transparent;
          border-radius: 0 16px 16px 0;
        }
        @media (min-width: 1024px) {
          .mdx-callout {
            margin: 32px 0;
            padding: 22px;
          }
        }
        .mdx-callout--info {
          background: rgba(30, 58, 140, 0.05);
          border-left-color: var(--color-blue);
        }
        .mdx-callout--warning {
          background: rgba(232, 163, 23, 0.10);
          border-left-color: var(--color-amber);
        }
        .mdx-callout--tip {
          background: rgba(22, 143, 91, 0.08);
          border-left-color: var(--color-green);
        }
        .mdx-callout-icon {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 32px;
          height: 32px;
          border-radius: 8px;
          flex-shrink: 0;
          margin-top: 2px;
        }
        .mdx-callout--info .mdx-callout-icon {
          background: rgba(30, 58, 140, 0.10);
          color: var(--color-blue);
        }
        .mdx-callout--warning .mdx-callout-icon {
          background: rgba(232, 163, 23, 0.18);
          color: #8a5d00;
        }
        .mdx-callout--tip .mdx-callout-icon {
          background: rgba(22, 143, 91, 0.16);
          color: var(--color-green);
        }
        .mdx-callout-icon-svg {
          width: 16px;
          height: 16px;
        }
        .mdx-callout-body {
          min-width: 0;
          flex: 1;
          font-size: 15px;
          line-height: 1.65;
          color: var(--color-ink-2);
        }
        @media (min-width: 1024px) {
          .mdx-callout-body {
            font-size: 16px;
          }
        }
        .mdx-callout-title {
          font-weight: 600;
          font-size: 14px;
          margin-bottom: 6px;
        }
        @media (min-width: 1024px) {
          .mdx-callout-title {
            font-size: 15px;
          }
        }
        .mdx-callout--info .mdx-callout-title {
          color: var(--color-blue);
        }
        .mdx-callout--warning .mdx-callout-title {
          color: #8a5d00;
        }
        .mdx-callout--tip .mdx-callout-title {
          color: var(--color-green);
        }
        .mdx-callout-content p {
          margin: 0 0 8px 0;
        }
        .mdx-callout-content p:last-child {
          margin-bottom: 0;
        }
      `}</style>
    </aside>
  );
}
