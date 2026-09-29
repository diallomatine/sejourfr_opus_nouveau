interface Props {
  id: string;
  number: number;
  title: string;
  children: React.ReactNode;
}

/**
 * Article numéroté avec ancre URL (`/cgu#article-6`). Marge généreuse
 * en haut pour bien séparer les articles, scroll-margin pour ne pas
 * que le titre passe sous le header sticky lors d'un scroll vers l'ancre.
 */
export function LegalSection({ id, number, title, children }: Props) {
  return (
    <section id={id} className="legal-section">
      <h2 className="legal-section-title">
        <span className="legal-section-num">Article {number} —</span>{" "}
        <span>{title}</span>
      </h2>
      <div className="legal-section-body">{children}</div>
      <style>{`
        .legal-section {
          margin-top: 48px;
          scroll-margin-top: 96px;
        }
        .legal-section:first-child {
          margin-top: 0;
        }
        @media (min-width: 1024px) {
          .legal-section {
            margin-top: 56px;
          }
        }
        .legal-section-title {
          font-family: var(--font-display);
          font-size: 24px;
          font-weight: 600;
          letter-spacing: -0.015em;
          line-height: 1.15;
          color: var(--color-ink);
          margin: 0 0 20px 0;
        }
        @media (min-width: 1024px) {
          .legal-section-title {
            font-size: 30px;
          }
        }
        .legal-section-num {
          color: var(--color-blue);
        }
        .legal-section-body {
          display: flex;
          flex-direction: column;
          gap: 16px;
          font-size: 16px;
          line-height: 1.7;
          color: var(--color-ink-2);
          max-width: 65ch;
        }
        @media (min-width: 1024px) {
          .legal-section-body {
            font-size: 17px;
          }
        }
        .legal-section-body p {
          margin: 0;
        }
        .legal-section-body strong {
          color: var(--color-ink);
          font-weight: 600;
        }
        .legal-section-body a {
          color: var(--color-blue);
          text-decoration: underline;
          text-decoration-color: rgba(30, 58, 140, 0.30);
          text-underline-offset: 2px;
          transition: text-decoration-color 0.15s;
        }
        .legal-section-body a:hover {
          text-decoration-color: var(--color-blue);
        }
        .legal-section-body ul {
          margin: 0;
          padding-left: 20px;
          display: flex;
          flex-direction: column;
          gap: 6px;
          list-style: disc;
        }
        .legal-section-body ul::marker,
        .legal-section-body ul li::marker {
          color: var(--color-blue);
        }
      `}</style>
    </section>
  );
}

interface SubProps {
  id?: string;
  number: string;
  title: string;
  children: React.ReactNode;
}

export function LegalSubsection({ id, number, title, children }: SubProps) {
  return (
    <div id={id} className="legal-subsection">
      <h3 className="legal-subsection-title">
        <span className="legal-subsection-num">{number}</span> {title}
      </h3>
      <div className="legal-subsection-body">{children}</div>
      <style>{`
        .legal-subsection {
          margin-top: 28px;
          scroll-margin-top: 96px;
        }
        .legal-subsection-title {
          font-size: 18px;
          font-weight: 600;
          color: var(--color-ink);
          margin: 0 0 10px 0;
          line-height: 1.35;
        }
        @media (min-width: 1024px) {
          .legal-subsection-title {
            font-size: 20px;
          }
        }
        .legal-subsection-num {
          color: var(--color-blue);
        }
        .legal-subsection-body {
          display: flex;
          flex-direction: column;
          gap: 12px;
        }
        .legal-subsection-body p {
          margin: 0;
        }
      `}</style>
    </div>
  );
}
