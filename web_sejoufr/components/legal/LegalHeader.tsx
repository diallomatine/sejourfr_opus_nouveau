import { ScrollText } from "lucide-react";
import { formatLegalDate, LEGAL_INFO } from "@/content/legal/legal-info";

interface Props {
  title: string;
  description?: string;
}

export function LegalHeader({ title, description }: Props) {
  return (
    <header className="legal-header">
      <span className="legal-header-eyebrow">
        <ScrollText className="legal-header-eyebrow-icon" />
        Document légal
      </span>
      <h1 className="legal-header-title">{title}</h1>
      {description && <p className="legal-header-desc">{description}</p>}
      <p className="legal-header-meta">
        Dernière mise à jour :{" "}
        <time
          dateTime={LEGAL_INFO.lastUpdated}
          className="legal-header-meta-date"
        >
          {formatLegalDate(LEGAL_INFO.lastUpdated)}
        </time>
      </p>
      <style>{`
        .legal-header {
          margin-bottom: 32px;
        }
        @media (min-width: 1024px) {
          .legal-header {
            margin-bottom: 40px;
          }
        }
        .legal-header-eyebrow {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          font-family: var(--font-mono);
          font-size: 11px;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.18em;
          color: var(--color-blue);
          background: rgba(30, 58, 140, 0.10);
          border-radius: 999px;
          padding: 4px 12px;
          margin-bottom: 12px;
        }
        .legal-header-eyebrow-icon {
          width: 12px;
          height: 12px;
        }
        .legal-header-title {
          font-family: var(--font-display);
          font-size: 30px;
          font-weight: 600;
          letter-spacing: -0.02em;
          line-height: 1.1;
          color: var(--color-ink);
          margin: 0;
        }
        @media (min-width: 768px) {
          .legal-header-title {
            font-size: 36px;
          }
        }
        @media (min-width: 1024px) {
          .legal-header-title {
            font-size: 44px;
          }
        }
        .legal-header-desc {
          margin: 12px 0 0 0;
          font-size: 16px;
          line-height: 1.6;
          color: var(--color-muted);
          max-width: 60ch;
        }
        @media (min-width: 1024px) {
          .legal-header-desc {
            font-size: 17px;
          }
        }
        .legal-header-meta {
          margin: 16px 0 0 0;
          font-size: 14px;
          color: var(--color-muted);
        }
        .legal-header-meta-date {
          font-weight: 500;
          color: var(--color-ink-2);
        }
      `}</style>
    </header>
  );
}
