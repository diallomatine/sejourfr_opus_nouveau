import { Info, AlertTriangle, CheckCircle2, type LucideIcon } from "lucide-react";

type Tone = "info" | "warning" | "success";

interface Props {
  tone?: Tone;
  title?: string;
  children: React.ReactNode;
}

const ICONS: Record<Tone, LucideIcon> = {
  info: Info,
  warning: AlertTriangle,
  success: CheckCircle2,
};

export function LegalCallout({ tone = "info", title, children }: Props) {
  const Icon = ICONS[tone];
  return (
    <aside role="note" className={`legal-callout legal-callout--${tone}`}>
      <span aria-hidden className="legal-callout-icon">
        <Icon className="legal-callout-icon-svg" />
      </span>
      <div className="legal-callout-body">
        {title && <div className="legal-callout-title">{title}</div>}
        <div className="legal-callout-content">{children}</div>
      </div>
      <style>{`
        .legal-callout {
          display: flex;
          align-items: flex-start;
          gap: 12px;
          margin: 20px 0;
          padding: 16px;
          border-left: 4px solid transparent;
          border-radius: 0 12px 12px 0;
        }
        @media (min-width: 1024px) {
          .legal-callout {
            margin: 24px 0;
            padding: 20px;
          }
        }
        .legal-callout--info {
          background: rgba(30, 58, 140, 0.05);
          border-left-color: var(--color-blue);
        }
        .legal-callout--warning {
          background: rgba(232, 163, 23, 0.10);
          border-left-color: var(--color-amber);
        }
        .legal-callout--success {
          background: rgba(22, 143, 91, 0.08);
          border-left-color: var(--color-green);
        }
        .legal-callout-icon {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 32px;
          height: 32px;
          border-radius: 8px;
          flex-shrink: 0;
          margin-top: 2px;
        }
        .legal-callout--info .legal-callout-icon {
          background: rgba(30, 58, 140, 0.10);
          color: var(--color-blue);
        }
        .legal-callout--warning .legal-callout-icon {
          background: rgba(232, 163, 23, 0.18);
          color: #8a5d00;
        }
        .legal-callout--success .legal-callout-icon {
          background: rgba(22, 143, 91, 0.16);
          color: var(--color-green);
        }
        .legal-callout-icon-svg {
          width: 16px;
          height: 16px;
        }
        .legal-callout-body {
          min-width: 0;
          flex: 1;
          font-size: 14px;
          line-height: 1.6;
          color: var(--color-ink-2);
        }
        @media (min-width: 1024px) {
          .legal-callout-body {
            font-size: 15px;
          }
        }
        .legal-callout-title {
          font-weight: 600;
          margin-bottom: 4px;
        }
        .legal-callout--info .legal-callout-title {
          color: var(--color-blue);
        }
        .legal-callout--warning .legal-callout-title {
          color: #8a5d00;
        }
        .legal-callout--success .legal-callout-title {
          color: var(--color-green);
        }
        .legal-callout-content p {
          margin: 0;
        }
        .legal-callout-content em {
          font-style: italic;
        }
      `}</style>
    </aside>
  );
}
