import Link from "next/link";
import { ArrowRight, BookOpen, Mail } from "lucide-react";

export function FAQContactCTA() {
  return (
    <section className="faq-cta">
      <span aria-hidden className="faq-cta-glow" />
      <div className="faq-cta-inner">
        <h2 className="faq-cta-title">
          Vous n&apos;avez pas trouvé votre réponse ?
        </h2>
        <p className="faq-cta-sub">
          Notre équipe répond aux demandes en 24 h ouvrées. En attendant, le
          blog regorge de guides pratiques sur les démarches.
        </p>
        <div className="faq-cta-actions">
          <Link href="/contact" className="faq-cta-primary">
            <Mail />
            Nous contacter
            <ArrowRight />
          </Link>
          <Link href="/blog" className="faq-cta-secondary">
            <BookOpen />
            Lire le blog
          </Link>
        </div>
      </div>

      <style>{`
        .faq-cta {
          position: relative;
          overflow: hidden;
          border-radius: 20px;
          padding: 32px 24px;
          background: linear-gradient(135deg, var(--color-blue) 0%, var(--color-blue-dark) 100%);
          color: #fff;
          box-shadow: 0 22px 48px -28px rgba(30, 58, 140, 0.55);
          margin-top: 64px;
        }
        .faq-cta-glow {
          position: absolute;
          top: -50%;
          right: -15%;
          width: 420px;
          height: 420px;
          border-radius: 50%;
          pointer-events: none;
          background: radial-gradient(circle, rgba(255,255,255,0.15), transparent 70%);
        }
        .faq-cta-inner {
          position: relative;
          max-width: 600px;
        }
        .faq-cta-title {
          margin: 0;
          font-family: var(--font-display);
          font-weight: 600;
          font-size: clamp(24px, 3vw, 36px);
          line-height: 1.15;
          letter-spacing: -0.02em;
        }
        .faq-cta-sub {
          margin: 12px 0 0;
          font-size: 16px;
          line-height: 1.6;
          color: rgba(255, 255, 255, 0.85);
        }
        .faq-cta-actions {
          margin-top: 22px;
          display: flex;
          flex-direction: column;
          gap: 10px;
        }
        .faq-cta-primary,
        .faq-cta-secondary {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          padding: 12px 20px;
          min-height: 48px;
          border-radius: 12px;
          font-family: var(--font-sans);
          font-size: 14.5px;
          font-weight: 600;
          transition: transform 0.15s ease, background 0.15s ease;
        }
        .faq-cta-primary {
          background: #fff;
          color: var(--color-blue);
        }
        .faq-cta-primary:hover {
          transform: translateY(-1px);
        }
        .faq-cta-secondary {
          background: rgba(255, 255, 255, 0.15);
          backdrop-filter: blur(4px);
          color: #fff;
        }
        .faq-cta-secondary:hover {
          background: rgba(255, 255, 255, 0.25);
        }
        .faq-cta-primary svg,
        .faq-cta-secondary svg {
          width: 16px;
          height: 16px;
        }
        @media (min-width: 640px) {
          .faq-cta-actions { flex-direction: row; }
        }
        @media (min-width: 1024px) {
          .faq-cta { padding: 44px 40px; margin-top: 72px; }
        }
      `}</style>
    </section>
  );
}
