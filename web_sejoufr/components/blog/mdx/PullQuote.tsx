interface Props {
  attribution?: string;
  children: React.ReactNode;
}

export function PullQuote({ attribution, children }: Props) {
  return (
    <blockquote className="mdx-pullquote">
      <p className="mdx-pullquote-text">{children}</p>
      {attribution && (
        <footer className="mdx-pullquote-attr">— {attribution}</footer>
      )}
      <style>{`
        .mdx-pullquote {
          margin: 32px 0;
          padding: 8px 0 8px 20px;
          border-left: 3px solid var(--color-red);
        }
        @media (min-width: 1024px) {
          .mdx-pullquote {
            margin: 40px 0;
            padding: 12px 0 12px 26px;
          }
        }
        .mdx-pullquote-text {
          margin: 0;
          font-family: var(--font-display);
          font-style: italic;
          font-size: 20px;
          line-height: 1.3;
          color: var(--color-ink);
          font-weight: 500;
          letter-spacing: -0.01em;
        }
        @media (min-width: 1024px) {
          .mdx-pullquote-text {
            font-size: 24px;
          }
        }
        .mdx-pullquote-attr {
          margin-top: 12px;
          font-family: var(--font-sans);
          font-style: normal;
          font-size: 14px;
          color: var(--color-muted);
        }
      `}</style>
    </blockquote>
  );
}
