import { MessagesSquare } from "lucide-react";

export function ContactHero() {
  return (
    <header className="contact-hero">
      <span className="contact-hero-eyebrow">
        <MessagesSquare className="contact-hero-eyebrow-icon" />
        Contactez-nous
      </span>
      <h1 className="contact-hero-title editorial">
        Une question ? <em>Nous sommes là.</em>
      </h1>
      <p className="contact-hero-sub">
        Notre équipe répond à toutes vos demandes sous 24 heures ouvrées —
        question technique, administrative, partenariat ou simple retour.
      </p>

      <style>{`
        .contact-hero { margin-bottom: 32px; }
        .contact-hero-eyebrow {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          padding: 5px 12px;
          margin-bottom: 14px;
          border-radius: 999px;
          background: var(--color-blue-light);
          color: var(--color-blue);
          font-family: var(--font-mono);
          font-size: 11px;
          letter-spacing: 0.18em;
          text-transform: uppercase;
          font-weight: 600;
        }
        .contact-hero-eyebrow-icon { width: 12px; height: 12px; }
        .contact-hero-title {
          margin: 0;
          font-size: clamp(30px, 4.5vw, 48px);
          line-height: 1.1;
          color: var(--color-ink);
        }
        .contact-hero-sub {
          margin: 14px 0 0;
          max-width: 620px;
          color: var(--color-muted);
          font-size: 16.5px;
          line-height: 1.6;
        }
        @media (min-width: 1024px) {
          .contact-hero { margin-bottom: 40px; }
          .contact-hero-sub { font-size: 18px; }
        }
      `}</style>
    </header>
  );
}
