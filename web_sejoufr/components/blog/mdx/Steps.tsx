interface StepProps {
  title: string;
  children: React.ReactNode;
}

export function Step({ title, children }: StepProps) {
  return (
    <div className="mdx-step">
      <span aria-hidden className="mdx-step-num" data-step-number />
      <h4 className="mdx-step-title">{title}</h4>
      <div className="mdx-step-body">{children}</div>
    </div>
  );
}

interface StepsProps {
  children: React.ReactNode;
}

/**
 * Liste numérotée d'étapes. Numéros calculés via CSS counter pour ne pas
 * dépendre de l'ordre de rendu MDX.
 */
export function Steps({ children }: StepsProps) {
  return (
    <ol className="mdx-steps">
      {children}
      <style>{`
        .mdx-steps {
          counter-reset: mdx-steps;
          list-style: none;
          padding: 0;
          margin: 28px 0;
          display: flex;
          flex-direction: column;
          gap: 28px;
        }
        @media (min-width: 1024px) {
          .mdx-steps {
            margin: 36px 0;
            gap: 32px;
          }
        }
        .mdx-step {
          counter-increment: mdx-steps;
          position: relative;
          padding-left: 52px;
        }
        @media (min-width: 640px) {
          .mdx-step {
            padding-left: 58px;
          }
        }
        .mdx-step-num {
          position: absolute;
          left: 0;
          top: 0;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 38px;
          height: 38px;
          border-radius: 50%;
          background: var(--color-blue);
          color: #fff;
          font-family: var(--font-sans);
          font-size: 14px;
          font-weight: 600;
          box-shadow: 0 8px 20px -10px rgba(30, 58, 140, 0.5);
        }
        @media (min-width: 640px) {
          .mdx-step-num {
            width: 42px;
            height: 42px;
          }
        }
        .mdx-step-num::before {
          content: counter(mdx-steps);
        }
        .mdx-step-title {
          font-family: var(--font-display);
          font-size: 19px;
          font-weight: 600;
          letter-spacing: -0.01em;
          line-height: 1.3;
          color: var(--color-ink);
          margin: 0;
        }
        @media (min-width: 1024px) {
          .mdx-step-title {
            font-size: 22px;
          }
        }
        .mdx-step-body {
          margin-top: 6px;
          font-size: 15px;
          line-height: 1.65;
          color: var(--color-ink-2);
        }
        @media (min-width: 1024px) {
          .mdx-step-body {
            font-size: 16px;
          }
        }
        .mdx-step-body p {
          margin: 0 0 8px 0;
        }
        .mdx-step-body p:last-child {
          margin-bottom: 0;
        }
      `}</style>
    </ol>
  );
}
