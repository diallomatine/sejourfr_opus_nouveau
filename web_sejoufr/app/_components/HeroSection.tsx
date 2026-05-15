import Link from "next/link";

/**
 * Hero refondu : l'app mobile est visible immédiatement à droite via un
 * mockup phone calqué sur la capture réelle de l'écran d'entraînement.
 * Le message principal : le web sert à découvrir et passer un examen blanc,
 * l'entraînement quotidien se fait sur mobile.
 */
export function HeroSection() {
  return (
    <header className="hero">
      <div aria-hidden className="hero-halo hero-halo-blue" />
      <div aria-hidden className="hero-halo hero-halo-red" />
      <div aria-hidden className="hero-grid-bg" />

      <div className="container-x hero-inner">
        <div className="hero-copy">
          <div className="hero-badge">
            <span className="dot" />
            Obligatoire depuis le 1<sup>er</sup> janvier 2026
          </div>
          <h1 className="hero-h1">
            Réussissez l&apos;examen civique
            <br />
            <em>et</em> le TCF, sans stress.
          </h1>
          <p className="hero-lede">
            Plus de 1 200 questions calibrées sur le référentiel officiel.
            Examens blancs en conditions réelles ici, entraînement quotidien
            sur l&apos;app mobile.
          </p>

          <div className="hero-ctas">
            <Link href="#telecharger" className="btn btn-lg btn-red">
              Télécharger l&apos;app
              <span className="arrow">↓</span>
            </Link>
            <Link href="/examens-blancs" className="btn btn-lg btn-ghost">
              Tester un examen blanc
            </Link>
          </div>

          <div className="hero-trust">
            <div className="stat">
              <span className="stat-num">1 240+</span>
              <span className="stat-lbl">Questions</span>
            </div>
            <div className="stat">
              <span className="stat-num">94 %</span>
              <span className="stat-lbl">Taux de réussite</span>
            </div>
            <div className="stat">
              <span className="stat-num">8 200+</span>
              <span className="stat-lbl">Candidats inscrits</span>
            </div>
          </div>
        </div>

        <div className="hero-phone-wrap">
          <PhoneMockup />
        </div>
      </div>

      <style>{heroStyles}</style>
    </header>
  );
}

/**
 * Mockup phone qui rejoue l'écran d'entraînement mobile : eyebrow + tags,
 * question, 4 options avec C sélectionnée en vert, bloc explication vert,
 * bouton bleu en bas. Identique à la capture utilisateur.
 */
function PhoneMockup() {
  return (
    <div className="phone">
      <div className="phone-screen">
        <div className="phone-status">
          <span className="phone-time">9:41</span>
          <div className="phone-status-right">
            <span className="phone-bar" />
            <span className="phone-bar" />
            <span className="phone-batt" />
          </div>
        </div>

        <div className="phone-topbar">
          <button type="button" className="phone-x" aria-label="Fermer">✕</button>
          <div className="phone-topbar-center">
            <span className="phone-eyebrow">Entraînement</span>
            <span className="phone-qcount">Question 3</span>
          </div>
          <button type="button" className="phone-bookmark" aria-label="Favori">
            <svg viewBox="0 0 16 20" fill="none" width="14" height="18">
              <path
                d="M2 2h12v17l-6-4-6 4V2z"
                stroke="currentColor"
                strokeWidth="1.5"
                strokeLinejoin="round"
              />
            </svg>
          </button>
        </div>

        <div className="phone-tags">
          <span className="ptag ptag-red">CSP</span>
          <span className="ptag ptag-blue">CONNAISSANCE</span>
          <span className="ptag-meta">Système inst…</span>
        </div>

        <h3 className="phone-q">
          Qui est élu lors des élections municipales&nbsp;?
        </h3>

        <div className="phone-options">
          <div className="popt">
            <span className="popt-letter">A</span>
            <span>Les députés</span>
          </div>
          <div className="popt">
            <span className="popt-letter">B</span>
            <span>Les préfets</span>
          </div>
          <div className="popt popt-correct">
            <span className="popt-letter popt-letter-correct">C</span>
            <span>Les conseillers municipaux (qui élisent le maire)</span>
            <span className="popt-check" aria-hidden>
              <svg viewBox="0 0 16 16" width="14" height="14">
                <circle cx="8" cy="8" r="8" fill="currentColor" />
                <path
                  d="M4.5 8.5l2.4 2.2 4.6-5"
                  stroke="#fff"
                  strokeWidth="1.6"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  fill="none"
                />
              </svg>
            </span>
          </div>
          <div className="popt">
            <span className="popt-letter">D</span>
            <span>Le président de la République</span>
          </div>
        </div>

        <div className="phone-explain">
          <div className="phone-explain-head">
            <span className="phone-explain-title">✓ Bonne réponse</span>
            <span className="phone-explain-tag">EXPLICATION</span>
          </div>
          <p>
            Les élections municipales élisent les conseillers municipaux. Ces
            conseillers élisent ensuite le maire de la commune.
          </p>
        </div>

        <button type="button" className="phone-cta">Suivant</button>
      </div>

      <div className="phone-glow" aria-hidden />
    </div>
  );
}

const heroStyles = `
  .hero {
    position: relative;
    padding: 88px 0 96px;
    overflow: hidden;
  }
  .hero-halo {
    position: absolute;
    border-radius: 50%;
    filter: blur(60px);
    opacity: 0.6;
    pointer-events: none;
  }
  .hero-halo-blue {
    top: -260px; right: -180px;
    width: 620px; height: 620px;
    background: radial-gradient(circle, rgba(30, 58, 140, 0.22), transparent 65%);
  }
  .hero-halo-red {
    bottom: -260px; left: -200px;
    width: 520px; height: 520px;
    background: radial-gradient(circle, rgba(225, 55, 47, 0.18), transparent 65%);
  }
  .hero-grid-bg {
    position: absolute; inset: 0;
    background-image:
      linear-gradient(rgba(30,58,140,0.04) 1px, transparent 1px),
      linear-gradient(90deg, rgba(30,58,140,0.04) 1px, transparent 1px);
    background-size: 32px 32px;
    mask-image: radial-gradient(ellipse at 50% 30%, #000 0%, transparent 70%);
    -webkit-mask-image: radial-gradient(ellipse at 50% 30%, #000 0%, transparent 70%);
    pointer-events: none;
  }
  .hero-inner {
    display: grid;
    grid-template-columns: 1.1fr 0.9fr;
    gap: 64px;
    align-items: center;
    position: relative;
    z-index: 1;
  }

  .hero-badge {
    display: inline-flex; align-items: center; gap: 8px;
    padding: 7px 14px;
    background: rgba(255, 255, 255, 0.7);
    backdrop-filter: blur(8px);
    border: 1px solid var(--color-line);
    border-radius: 100px;
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.08em;
    color: var(--color-ink-2);
    margin-bottom: 24px;
  }
  .hero-badge .dot {
    width: 7px; height: 7px; border-radius: 50%;
    background: var(--color-green);
    box-shadow: 0 0 0 3px rgba(22, 143, 91, 0.18);
  }
  .hero-h1 {
    font-family: var(--font-display);
    font-weight: 500;
    font-size: clamp(40px, 5.4vw, 64px);
    line-height: 1.02;
    letter-spacing: -0.025em;
    margin: 0 0 22px;
    color: var(--color-ink);
  }
  .hero-h1 em {
    font-style: italic;
    color: var(--color-red);
    font-weight: 500;
  }
  .hero-lede {
    font-size: 19px;
    color: var(--color-ink-2);
    max-width: 540px;
    margin: 0 0 32px;
    line-height: 1.55;
  }
  .hero-ctas {
    display: flex; gap: 12px; flex-wrap: wrap; align-items: center;
  }
  .hero-trust {
    display: flex; gap: 36px;
    margin-top: 40px;
    padding-top: 28px;
    border-top: 1px solid var(--color-line);
  }
  .hero-trust .stat { display: flex; flex-direction: column; gap: 4px; }
  .hero-trust .stat-num {
    font-family: var(--font-display);
    font-size: 30px;
    font-weight: 500;
    color: var(--color-blue);
    letter-spacing: -0.02em;
  }
  .hero-trust .stat-lbl {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: var(--color-muted);
  }

  /* --- phone mockup --- */
  .hero-phone-wrap {
    display: flex; justify-content: center; align-items: center;
    position: relative;
  }
  .phone {
    position: relative;
    width: 320px;
    background: linear-gradient(180deg, #0F1839, #1F2950);
    padding: 12px;
    border-radius: 44px;
    box-shadow:
      0 1px 2px rgba(15, 24, 57, 0.1),
      0 30px 80px -30px rgba(15, 24, 57, 0.4),
      0 60px 120px -40px rgba(30, 58, 140, 0.3);
  }
  .phone-glow {
    position: absolute;
    inset: -40px;
    background:
      radial-gradient(circle at 30% 20%, rgba(30, 58, 140, 0.25) 0%, transparent 60%),
      radial-gradient(circle at 70% 80%, rgba(225, 55, 47, 0.18) 0%, transparent 60%);
    border-radius: 60px;
    z-index: -1;
    filter: blur(20px);
  }
  .phone-screen {
    background: #F7F8FC;
    border-radius: 32px;
    padding: 14px 18px 20px;
    position: relative;
  }
  .phone-status {
    display: flex; justify-content: space-between; align-items: center;
    font-family: var(--font-sans);
    font-size: 12px;
    font-weight: 700;
    color: var(--color-ink);
    margin-bottom: 12px;
  }
  .phone-status-right { display: flex; gap: 4px; align-items: center; }
  .phone-bar {
    width: 14px; height: 8px;
    background: var(--color-ink);
    border-radius: 1px;
  }
  .phone-batt {
    width: 22px; height: 11px;
    border: 1px solid var(--color-ink);
    border-radius: 3px;
    position: relative;
  }
  .phone-batt::after {
    content: '';
    position: absolute;
    inset: 1.5px;
    background: var(--color-green);
    border-radius: 1px;
  }

  .phone-topbar {
    display: flex; justify-content: space-between; align-items: center;
    padding-bottom: 14px;
    border-bottom: 1px solid var(--color-line-2);
    margin-bottom: 14px;
  }
  .phone-x, .phone-bookmark {
    background: none; border: none;
    width: 28px; height: 28px;
    display: flex; align-items: center; justify-content: center;
    color: var(--color-ink);
    font-size: 18px;
    cursor: pointer;
  }
  .phone-bookmark { color: var(--color-muted); }
  .phone-topbar-center {
    display: flex; flex-direction: column; align-items: center;
  }
  .phone-eyebrow {
    font-family: var(--font-mono);
    font-size: 9px;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--color-muted);
  }
  .phone-qcount {
    font-family: var(--font-sans);
    font-size: 14px; font-weight: 700;
    color: var(--color-ink);
    margin-top: 1px;
  }

  .phone-tags {
    display: flex; align-items: center; gap: 6px;
    margin-bottom: 14px;
  }
  .ptag {
    padding: 3px 9px;
    border-radius: 5px;
    font-family: var(--font-mono);
    font-size: 9.5px;
    letter-spacing: 0.1em;
    font-weight: 600;
    border: 1px solid;
  }
  .ptag-red {
    background: var(--color-red-light);
    color: var(--color-red);
    border-color: rgba(225, 55, 47, 0.3);
  }
  .ptag-blue {
    background: var(--color-blue-light);
    color: var(--color-blue);
    border-color: rgba(30, 58, 140, 0.3);
  }
  .ptag-meta {
    font-family: var(--font-mono);
    font-size: 9px;
    color: var(--color-muted);
    letter-spacing: 0.06em;
    margin-left: auto;
  }

  .phone-q {
    font-family: var(--font-sans);
    font-weight: 700;
    font-size: 16px;
    line-height: 1.3;
    color: var(--color-ink);
    margin: 0 0 14px;
  }

  .phone-options { display: flex; flex-direction: column; gap: 7px; margin-bottom: 14px; }
  .popt {
    background: #fff;
    border: 1.5px solid var(--color-line);
    border-radius: 10px;
    padding: 11px 12px;
    display: flex; align-items: center; gap: 10px;
    font-size: 13px;
    color: var(--color-ink-2);
    position: relative;
  }
  .popt-letter {
    width: 24px; height: 24px;
    border-radius: 50%;
    background: var(--color-line-2);
    color: var(--color-muted);
    display: flex; align-items: center; justify-content: center;
    font-family: var(--font-mono);
    font-size: 11px;
    font-weight: 600;
    flex-shrink: 0;
  }
  .popt-correct {
    border-color: var(--color-green);
    background: #fff;
    box-shadow: 0 0 0 1px var(--color-green);
  }
  .popt-letter-correct {
    background: rgba(22, 143, 91, 0.12);
    color: var(--color-green);
  }
  .popt-check {
    margin-left: auto;
    display: flex; align-items: center;
    color: var(--color-green);
  }

  .phone-explain {
    background: rgba(22, 143, 91, 0.06);
    border: 1px solid rgba(22, 143, 91, 0.25);
    border-radius: 10px;
    padding: 12px 14px;
    margin-bottom: 14px;
  }
  .phone-explain-head {
    display: flex; justify-content: space-between; align-items: center;
    margin-bottom: 6px;
  }
  .phone-explain-title {
    font-family: var(--font-sans);
    font-weight: 700;
    font-size: 13px;
    color: var(--color-green);
  }
  .phone-explain-tag {
    font-family: var(--font-mono);
    font-size: 9px;
    letter-spacing: 0.14em;
    color: var(--color-green);
    background: rgba(22, 143, 91, 0.12);
    padding: 2px 7px;
    border-radius: 4px;
    font-weight: 600;
  }
  .phone-explain p {
    font-size: 12px;
    line-height: 1.45;
    color: var(--color-ink-2);
    margin: 0;
  }

  .phone-cta {
    width: 100%;
    background: var(--color-blue);
    color: #fff;
    border: none;
    padding: 13px;
    border-radius: 12px;
    font-family: var(--font-sans);
    font-weight: 700;
    font-size: 14px;
    cursor: pointer;
    box-shadow: 0 8px 20px -8px rgba(30, 58, 140, 0.45);
  }

  @media (max-width: 960px) {
    .hero-inner { grid-template-columns: 1fr; gap: 56px; }
    .hero-phone-wrap { order: -1; }
    .phone { width: 280px; }
  }
  @media (max-width: 560px) {
    .hero { padding: 56px 0 72px; }
    .hero-trust { flex-wrap: wrap; gap: 24px; }
  }
`;
