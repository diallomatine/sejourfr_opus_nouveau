import Link from "next/link";
import { ArrowRight, Mail, Shield } from "lucide-react";

const PAGES = [
  { href: "/mentions-legales", label: "Mentions légales" },
  { href: "/cgu", label: "Conditions d'utilisation" },
  { href: "/confidentialite", label: "Politique de confidentialité" },
];

interface Props {
  currentPath: "/mentions-legales" | "/cgu" | "/confidentialite";
}

export function LegalFooterNav({ currentPath }: Props) {
  const others = PAGES.filter((p) => p.href !== currentPath);

  return (
    <footer className="legal-foot">
      <div className="legal-foot-grid">
        {others.map((p) => (
          <Link key={p.href} href={p.href} className="legal-foot-link">
            <span className="legal-foot-link-label">{p.label}</span>
            <ArrowRight className="legal-foot-link-arrow" />
          </Link>
        ))}
      </div>

      <div className="legal-foot-contact">
        <span className="legal-foot-contact-icon">
          <Mail className="legal-foot-contact-icon-svg" />
        </span>
        <div className="legal-foot-contact-body">
          <p className="legal-foot-contact-title">
            Une question sur ce document ?
          </p>
          <p className="legal-foot-contact-desc">
            Notre équipe répond à toutes vos demandes sous 24 h ouvrées.
          </p>
          <Link href="/contact" className="legal-foot-contact-cta">
            Nous contacter
            <ArrowRight className="legal-foot-contact-cta-arrow" />
          </Link>
        </div>
      </div>

      <p className="legal-foot-cnil">
        <Shield className="legal-foot-cnil-icon" />
        <span>
          Conformément au RGPD, vous pouvez à tout moment exercer vos droits
          ou déposer une réclamation auprès de la CNIL —{" "}
          <a
            href="https://www.cnil.fr"
            target="_blank"
            rel="noopener noreferrer"
            className="legal-foot-cnil-link"
          >
            www.cnil.fr
          </a>
          .
        </span>
      </p>

      <style>{`
        .legal-foot {
          margin-top: 48px;
          padding-top: 32px;
          border-top: 1px solid var(--color-line);
          display: flex;
          flex-direction: column;
          gap: 24px;
        }
        @media (min-width: 1024px) {
          .legal-foot {
            margin-top: 64px;
          }
        }
        .legal-foot-grid {
          display: grid;
          grid-template-columns: 1fr;
          gap: 12px;
        }
        @media (min-width: 640px) {
          .legal-foot-grid {
            grid-template-columns: 1fr 1fr;
          }
        }
        .legal-foot-link {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 12px;
          padding: 16px;
          border: 1px solid var(--color-line);
          border-radius: 16px;
          background: #fff;
          transition: border-color 0.15s, box-shadow 0.15s, transform 0.15s;
        }
        .legal-foot-link:hover {
          border-color: rgba(30, 58, 140, 0.40);
          box-shadow: 0 4px 16px rgba(15, 24, 57, 0.06);
        }
        .legal-foot-link-label {
          font-size: 14px;
          font-weight: 600;
          color: var(--color-ink);
        }
        .legal-foot-link-arrow {
          width: 16px;
          height: 16px;
          color: var(--color-muted-2);
          transition: color 0.15s, transform 0.15s;
        }
        .legal-foot-link:hover .legal-foot-link-arrow {
          color: var(--color-blue);
          transform: translateX(2px);
        }
        .legal-foot-contact {
          display: flex;
          align-items: flex-start;
          gap: 12px;
          padding: 20px;
          background: rgba(30, 58, 140, 0.05);
          border: 1px solid rgba(30, 58, 140, 0.20);
          border-radius: 16px;
        }
        .legal-foot-contact-icon {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 36px;
          height: 36px;
          flex-shrink: 0;
          border-radius: 8px;
          background: rgba(30, 58, 140, 0.10);
          color: var(--color-blue);
        }
        .legal-foot-contact-icon-svg {
          width: 16px;
          height: 16px;
        }
        .legal-foot-contact-body {
          min-width: 0;
          flex: 1;
        }
        .legal-foot-contact-title {
          font-size: 14px;
          font-weight: 600;
          color: var(--color-ink);
          margin: 0;
        }
        .legal-foot-contact-desc {
          margin: 2px 0 0 0;
          font-size: 14px;
          color: var(--color-muted);
        }
        .legal-foot-contact-cta {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          margin-top: 8px;
          font-size: 14px;
          font-weight: 500;
          color: var(--color-blue);
        }
        .legal-foot-contact-cta:hover {
          text-decoration: underline;
        }
        .legal-foot-contact-cta-arrow {
          width: 14px;
          height: 14px;
        }
        .legal-foot-cnil {
          display: flex;
          align-items: flex-start;
          gap: 8px;
          margin: 0;
          font-size: 12px;
          line-height: 1.6;
          color: var(--color-muted);
        }
        .legal-foot-cnil-icon {
          width: 14px;
          height: 14px;
          flex-shrink: 0;
          margin-top: 2px;
          color: var(--color-muted-2);
        }
        .legal-foot-cnil-link {
          color: var(--color-blue);
          text-decoration: underline;
          text-decoration-color: rgba(30, 58, 140, 0.30);
          text-underline-offset: 2px;
        }
        .legal-foot-cnil-link:hover {
          text-decoration-color: var(--color-blue);
        }
      `}</style>
    </footer>
  );
}
