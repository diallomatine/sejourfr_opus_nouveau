import Link from "next/link";
import { ArrowRight } from "lucide-react";

interface Props {
  title: string;
  description?: string;
  href: string;
  cta: string;
}

export function CTABox({ title, description, href, cta }: Props) {
  const isExternal = href.startsWith("http");
  const innerLabel = (
    <>
      {cta}
      <ArrowRight className="mdx-ctabox-arrow" />
    </>
  );

  return (
    <div className="mdx-ctabox">
      <h3 className="mdx-ctabox-title">{title}</h3>
      {description && <p className="mdx-ctabox-desc">{description}</p>}
      <div className="mdx-ctabox-actions">
        {isExternal ? (
          <a
            href={href}
            target="_blank"
            rel="noopener noreferrer"
            className="mdx-ctabox-btn"
          >
            {innerLabel}
          </a>
        ) : (
          <Link href={href} className="mdx-ctabox-btn">
            {innerLabel}
          </Link>
        )}
      </div>
      <style>{`
        .mdx-ctabox {
          margin: 32px 0;
          padding: 24px;
          border-radius: 20px;
          background: linear-gradient(
            135deg,
            var(--color-blue),
            var(--color-ink-2)
          );
          color: #fff;
          box-shadow: 0 12px 32px -16px rgba(15, 24, 57, 0.45);
        }
        @media (min-width: 1024px) {
          .mdx-ctabox {
            margin: 40px 0;
            padding: 32px;
          }
        }
        .mdx-ctabox-title {
          margin: 0;
          font-family: var(--font-display);
          font-weight: 600;
          letter-spacing: -0.02em;
          font-size: 22px;
          line-height: 1.2;
          color: #fff;
        }
        @media (min-width: 1024px) {
          .mdx-ctabox-title {
            font-size: 26px;
          }
        }
        .mdx-ctabox-desc {
          margin: 8px 0 0 0;
          font-size: 15px;
          line-height: 1.55;
          color: rgba(255, 255, 255, 0.85);
          max-width: 60ch;
        }
        @media (min-width: 1024px) {
          .mdx-ctabox-desc {
            font-size: 16px;
          }
        }
        .mdx-ctabox-actions {
          margin-top: 20px;
        }
        .mdx-ctabox-btn {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          padding: 12px 22px;
          min-height: 44px;
          border-radius: 10px;
          background: #fff;
          color: var(--color-blue);
          font-family: var(--font-sans);
          font-size: 14.5px;
          font-weight: 600;
          letter-spacing: -0.005em;
          text-decoration: none;
          transition: transform 0.15s ease;
        }
        .mdx-ctabox-btn:hover {
          transform: translateY(-1px);
        }
        .mdx-ctabox-arrow {
          width: 16px;
          height: 16px;
          transition: transform 0.15s ease;
        }
        .mdx-ctabox-btn:hover .mdx-ctabox-arrow {
          transform: translateX(3px);
        }
      `}</style>
    </div>
  );
}
