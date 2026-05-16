import { Sparkles } from "lucide-react";

export function PricingHero() {
  return (
    <header className="pricing-hero">
      <span className="pricing-hero-eyebrow">
        <Sparkles className="pricing-hero-eyebrow-icon" />
        Tarifs simples, sans engagement
      </span>
      <h1 className="pricing-hero-title editorial">
        Choisissez la formule qui colle{" "}
        <em>à votre planning</em>.
      </h1>
      <p className="pricing-hero-sub">
        Paiement unique, pas de renouvellement automatique. Vous payez une
        fois, vous accédez à tout pendant la durée du plan.
      </p>

      <style>{`
        .pricing-hero {
          text-align: center;
          max-width: 640px;
          margin: 0 auto 40px;
        }
        .pricing-hero-eyebrow {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          padding: 5px 14px;
          margin-bottom: 14px;
          border-radius: 999px;
          background: var(--color-blue-light);
          color: var(--color-blue);
          font-family: var(--font-mono);
          font-size: 11px;
          font-weight: 600;
          letter-spacing: 0.18em;
          text-transform: uppercase;
        }
        .pricing-hero-eyebrow-icon { width: 12px; height: 12px; }
        .pricing-hero-title {
          margin: 0;
          font-size: clamp(30px, 4.8vw, 52px);
          line-height: 1.1;
          color: var(--color-ink);
        }
        .pricing-hero-sub {
          margin: 16px 0 0;
          font-size: 16.5px;
          line-height: 1.6;
          color: var(--color-muted);
        }
        @media (min-width: 1024px) {
          .pricing-hero { margin-bottom: 56px; }
          .pricing-hero-sub { font-size: 18px; }
        }
      `}</style>
    </header>
  );
}
