"use client";

import Link from "next/link";

/**
 * Bandeau persistant en haut de page : pousse l'utilisateur à passer sur
 * l'app mobile pour l'entraînement quotidien. Le web reste une vitrine,
 * un point de paiement et une démo limitée (1 examen blanc gratuit par
 * module + briefing). Tout le reste vit dans l'app.
 */
export function MobileAppBanner() {
  return (
    <div className="mobile-banner">
      <div className="mobile-banner__inner">
        <span className="mobile-banner__dot" aria-hidden>📱</span>
        <span className="mobile-banner__text">
          L&apos;entraînement quotidien (questions illimitées, favoris, hors-ligne) se passe sur l&apos;app mobile.
          <Link href="#telecharger"> Télécharger l&apos;app →</Link>
        </span>
      </div>
      <style>{`
        .mobile-banner {
          background: var(--color-ink);
          color: #fff;
          font-size: 12.5px;
        }
        .mobile-banner__inner {
          max-width: 1180px; margin: 0 auto;
          padding: 8px 28px;
          display: flex; align-items: center; gap: 10px;
          flex-wrap: wrap;
        }
        .mobile-banner__dot { font-size: 14px; }
        .mobile-banner__text { color: rgba(255, 255, 255, 0.85); }
        .mobile-banner__text a {
          color: #ffb3b0; font-weight: 600; text-decoration: none;
          white-space: nowrap;
        }
        .mobile-banner__text a:hover { color: #fff; }
        @media (max-width: 560px) {
          .mobile-banner__inner { padding: 8px 16px; font-size: 12px; }
        }
      `}</style>
    </div>
  );
}

/**
 * Section landing dédiée à l'app mobile. Insiste sur le fait que c'est LE
 * canal d'entraînement réel : le web (gratuit ou Premium) est une vitrine,
 * la pratique quotidienne se fait sur mobile.
 */
export function MobileAppSection() {
  return (
    <section id="telecharger" className="mobile-section">
      <div className="mobile-section__inner">
        <div className="mobile-section__copy">
          <span className="eyebrow">§ Application mobile</span>
          <h2>
            L&apos;entraînement quotidien, <em>c&apos;est dans l&apos;app</em>.
          </h2>
          <p>
            Le site sert à découvrir la plateforme, passer un examen blanc et vous abonner.
            <strong> La pratique réelle — questions illimitées, favoris, révision des erreurs, hors-ligne — se fait sur l&apos;application mobile.</strong>
          </p>
          <ul className="mobile-section__features">
            <li>📚 1 200+ questions tous modules, mises à jour mensuelles</li>
            <li>⭐ Favoris, révision ciblée des erreurs récentes</li>
            <li>📊 Statistiques par thématique et par parcours (CSP / CR / NAT)</li>
            <li>✈️ Mode hors-ligne pour réviser dans les transports</li>
            <li>🔔 Rappels quotidiens : 10 questions par jour, sans pression</li>
          </ul>
          <div className="mobile-section__cta">
            <a href="#" className="store-btn ios" aria-label="Télécharger sur l'App Store">
              <span className="store-eyebrow">Télécharger sur</span>
              <span className="store-name">App Store</span>
            </a>
            <a href="#" className="store-btn android" aria-label="Disponible sur Google Play">
              <span className="store-eyebrow">Disponible sur</span>
              <span className="store-name">Google Play</span>
            </a>
          </div>
          <p className="mobile-section__note">
            Votre abonnement Premium pris ici se synchronise automatiquement avec l&apos;app.
          </p>
        </div>

        <div className="mobile-section__visual" aria-hidden>
          <div className="phone">
            <div className="phone-screen">
              <div className="phone-top">
                <span className="dot blue" /> <span className="dot red" />
                <span className="phone-eyebrow">Examen civique · CSP</span>
              </div>
              <div className="phone-q">Quelle est la devise de la République française ?</div>
              <div className="phone-options">
                <div className="phone-opt selected">A · Liberté, Égalité, Fraternité</div>
                <div className="phone-opt">B · Liberté, Égalité, Solidarité</div>
                <div className="phone-opt">C · Unité, Égalité, Fraternité</div>
                <div className="phone-opt">D · Liberté, Justice, Fraternité</div>
              </div>
              <div className="phone-cta">Question suivante →</div>
            </div>
          </div>
        </div>
      </div>

      <style>{`
        .mobile-section {
          background: var(--color-paper);
          padding: 96px 0;
          border-top: 1px solid var(--color-line);
          border-bottom: 1px solid var(--color-line);
        }
        .mobile-section__inner {
          max-width: 1180px; margin: 0 auto; padding: 0 28px;
          display: grid; grid-template-columns: 1.1fr 0.9fr;
          gap: 64px; align-items: center;
        }
        .mobile-section__copy h2 {
          font-family: var(--font-display); font-weight: 500; font-size: 42px;
          line-height: 1.05; letter-spacing: -0.025em;
          margin: 14px 0 16px;
        }
        .mobile-section__copy h2 em { font-style: italic; color: var(--color-red); }
        .mobile-section__copy p {
          color: var(--color-ink-2); font-size: 16px; line-height: 1.55;
          margin: 0 0 22px;
        }
        .mobile-section__copy p strong {
          color: var(--color-ink); font-weight: 600;
        }
        .mobile-section__features {
          list-style: none; padding: 0; margin: 0 0 28px;
          display: flex; flex-direction: column; gap: 10px;
        }
        .mobile-section__features li {
          font-size: 14.5px; color: var(--color-ink-2); line-height: 1.45;
        }
        .mobile-section__cta {
          display: flex; gap: 12px; flex-wrap: wrap; margin-bottom: 14px;
        }
        .store-btn {
          display: flex; flex-direction: column;
          padding: 10px 22px;
          background: var(--color-ink); color: #fff;
          border-radius: 10px;
          text-decoration: none;
          min-width: 160px;
          transition: transform 0.15s;
        }
        .store-btn:hover { transform: translateY(-2px); }
        .store-eyebrow {
          font-family: var(--font-mono); font-size: 9.5px;
          letter-spacing: 0.16em; text-transform: uppercase;
          color: rgba(255, 255, 255, 0.65);
        }
        .store-name {
          font-family: var(--font-sans); font-weight: 700; font-size: 18px;
          margin-top: 2px; letter-spacing: -0.01em;
        }
        .mobile-section__note {
          font-size: 12px; color: var(--color-muted);
          margin-top: 14px;
        }

        .mobile-section__visual {
          display: flex; justify-content: center;
        }
        .phone {
          background: var(--color-ink);
          padding: 14px;
          border-radius: 36px;
          box-shadow: 0 40px 80px -30px rgba(15, 24, 57, 0.35);
          width: 280px;
        }
        .phone-screen {
          background: #fff;
          border-radius: 22px;
          padding: 20px 18px;
        }
        .phone-top {
          display: flex; align-items: center; gap: 6px;
          margin-bottom: 14px;
        }
        .dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; }
        .dot.blue { background: var(--color-blue); }
        .dot.red { background: var(--color-red); }
        .phone-eyebrow {
          font-family: var(--font-mono); font-size: 9.5px;
          letter-spacing: 0.14em; text-transform: uppercase; color: var(--color-muted);
          margin-left: 4px;
        }
        .phone-q {
          font-family: var(--font-display); font-weight: 500;
          font-size: 16px; line-height: 1.3;
          margin-bottom: 14px;
        }
        .phone-options {
          display: flex; flex-direction: column; gap: 6px;
          margin-bottom: 16px;
        }
        .phone-opt {
          padding: 10px 12px;
          border: 1.5px solid var(--color-line);
          border-radius: 9px;
          font-size: 12px; color: var(--color-ink-2);
        }
        .phone-opt.selected {
          border-color: var(--color-blue);
          background: var(--color-blue-light);
          color: var(--color-blue-dark);
          font-weight: 600;
        }
        .phone-cta {
          background: var(--color-red); color: #fff;
          padding: 10px; border-radius: 9px;
          text-align: center; font-size: 12.5px; font-weight: 700;
        }

        @media (max-width: 900px) {
          .mobile-section { padding: 64px 0; }
          .mobile-section__inner { grid-template-columns: 1fr; gap: 40px; }
          .mobile-section__copy h2 { font-size: 32px; }
          .mobile-section__visual { order: -1; }
        }
      `}</style>
    </section>
  );
}
