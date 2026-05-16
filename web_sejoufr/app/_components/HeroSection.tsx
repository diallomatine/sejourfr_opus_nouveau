import Link from "next/link";

/**
 * Hero éditorial : titre Fraunces avec emphasis italiques rouges, badge
 * "obligatoire 2026", CTAs, social proof. À droite, mockup d'une qcard
 * d'examen civique avec correction, encadrée de 2 floating chips
 * (timer examen blanc + score). Calé sur la maquette landing-sejourfr.html.
 */
export function HeroSection() {
    return (
        <section className="hero">
            <div aria-hidden className="hero-halo hero-halo-blue"/>
            <div aria-hidden className="hero-halo hero-halo-red"/>

            <div className="container-x hero-inner">
                <div className="hero-copy">
                    <div className="hero-badge">
                        <span className="dot"/>
                        OBLIGATOIRE DEPUIS LE 1<sup>ER</sup> JANVIER 2026
                    </div>
                    <h1 className="hero-h1">
                        Réussissez votre <em>examen civique</em>{" "}
                        <span className="amp">&amp;</span>
                        <br/>
                        votre <span className="accent">TCF</span> en confiance.
                    </h1>
                    <p className="hero-lede">
                        Entraînement par QCM, corrections expliquées, examens blancs en
                        conditions réelles. Pour la carte de séjour pluriannuelle, la
                        carte de résident et la naturalisation.
                    </p>

                    <div className="hero-ctas">
                        <Link href="/entrainement" className="btn btn-lg hero-cta-primary">
                            Démarrer gratuitement
                            <span className="arrow">→</span>
                        </Link>
                        <Link href="#fonctionnalites" className="btn btn-lg hero-cta-ghost">
                            Voir comment ça marche
                        </Link>
                    </div>

                    <div className="hero-trust">
                        <div className="hero-avatars" aria-hidden>
                            <span/>
                            <span/>
                            <span/>
                            <span/>
                        </div>
                        <p>
                            Conçu avec des candidats au CSP, à la CR et à la{" "}
                            <strong>naturalisation</strong>.
                        </p>
                    </div>
                </div>

                <div className="hero-visual">
                    <Qcard/>
                    <FloatChip
                        className="float-1"
                        tone="blue"
                        label="EXAMEN BLANC"
                        value="42:38"
                        icon="⏱"
                    />
                    <FloatChip
                        className="float-2"
                        tone="red"
                        label="SCORE"
                        value="34 / 40 ✓"
                        icon="★"
                    />
                </div>
            </div>

            <style>{heroStyles}</style>
        </section>
    );
}

function Qcard() {
    return (
        <div className="qcard">
            <div className="qcard-head">
                <span className="qcard-tag">CIVIQUE · NAT</span>
                <span className="qcard-progress">
          Question <strong>14</strong> / 40
        </span>
            </div>
            <p className="qcard-q">
                Quelle est la devise de la République française&nbsp;?
            </p>
            <div className="qcard-options">
                <div className="qopt">
                    <span className="qopt-letter">A</span>
                    <span>Travail, Famille, Patrie</span>
                </div>
                <div className="qopt correct">
                    <span className="qopt-letter">B</span>
                    <span>Liberté, Égalité, Fraternité</span>
                    <span className="qopt-mark" aria-hidden>
            ✓
          </span>
                </div>
                <div className="qopt">
                    <span className="qopt-letter">C</span>
                    <span>Unité, Justice, Paix</span>
                </div>
                <div className="qopt">
                    <span className="qopt-letter">D</span>
                    <span>République, Démocratie, Laïcité</span>
                </div>
            </div>
            <div className="qcard-feedback">
                <strong>Correct.</strong> Cette devise apparaît dès la Révolution
                française et est officiellement adoptée par la Troisième République.
                Elle figure à l&apos;article 2 de la Constitution.
            </div>
        </div>
    );
}

function FloatChip({
                       className,
                       tone,
                       label,
                       value,
                       icon,
                   }: {
    className: string;
    tone: "blue" | "red";
    label: string;
    value: string;
    icon: string;
}) {
    return (
        <div className={`float-chip ${className}`}>
      <span className={`chip-icon chip-${tone}`} aria-hidden>
        {icon}
      </span>
            <span className="chip-text">
        <span className="chip-label">{label}</span>
        <span className="chip-value">{value}</span>
      </span>
        </div>
    );
}

const heroStyles = `
  .hero {
    position: relative;
    padding: 92px 0 110px;
    overflow: hidden;
    background:
      radial-gradient(at 8% -8%, rgba(232, 236, 248, 0.85) 0px, transparent 45%),
      radial-gradient(at 100% 110%, rgba(253, 236, 235, 0.85) 0px, transparent 40%),
      #fff;
  }
  .hero-halo {
    position: absolute;
    border-radius: 50%;
    filter: blur(60px);
    pointer-events: none;
  }
  .hero-halo-blue {
    top: -180px; right: 50%;
    width: 540px; height: 540px;
    background: radial-gradient(circle, rgba(30, 58, 140, 0.10), transparent 70%);
  }
  .hero-halo-red {
    bottom: -180px; left: 60%;
    width: 460px; height: 460px;
    background: radial-gradient(circle, rgba(225, 55, 47, 0.10), transparent 70%);
  }
  .hero-inner {
    display: grid;
    grid-template-columns: 1.05fr 1fr;
    gap: 70px;
    align-items: center;
    position: relative;
    z-index: 1;
  }

  /* badge */
  .hero-badge {
    display: inline-flex; align-items: center; gap: 8px;
    padding: 6px 13px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 999px;
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
  .hero-badge sup { font-size: 0.7em; }

  /* h1 + lede */
  .hero-h1 {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: clamp(40px, 5.4vw, 62px);
    line-height: 1.04;
    letter-spacing: -0.025em;
    margin: 0 0 22px;
    color: var(--color-ink);
  }
  .hero-h1 em {
    font-style: italic;
    font-weight: 500;
    color: var(--color-blue);
  }
  .hero-h1 .accent {
    color: var(--color-red);
    font-style: normal;
  }
  .hero-h1 .amp {
    color: var(--color-muted);
    font-weight: 400;
  }
  .hero-lede {
    font-size: 18px;
    color: var(--color-muted);
    max-width: 520px;
    margin: 0 0 32px;
    line-height: 1.55;
  }

  /* CTAs */
  .hero-ctas {
    display: flex; gap: 12px; flex-wrap: wrap;
    align-items: center; margin-bottom: 32px;
  }
  .hero-cta-primary {
    background: var(--color-blue); color: #fff;
    border-color: var(--color-blue);
  }
  .hero-cta-primary:hover {
    background: var(--color-blue-dark);
    border-color: var(--color-blue-dark);
  }
  .hero-cta-ghost {
    background: #fff; color: var(--color-ink);
    border-color: var(--color-line);
  }
  .hero-cta-ghost:hover {
    border-color: var(--color-blue);
    color: var(--color-blue);
    background: #fff;
  }

  /* social proof */
  .hero-trust {
    display: flex; align-items: center; gap: 18px;
    font-size: 13.5px; color: var(--color-muted);
  }
  .hero-trust strong { color: var(--color-ink); font-weight: 700; }
  .hero-trust p { margin: 0; max-width: 360px; line-height: 1.5; }
  .hero-avatars { display: flex; flex-shrink: 0; }
  .hero-avatars span {
    width: 30px; height: 30px; border-radius: 50%;
    border: 2px solid #fff;
    margin-left: -8px;
    background: linear-gradient(135deg, var(--color-blue), var(--color-red));
    display: inline-block;
  }
  .hero-avatars span:first-child { margin-left: 0; }
  .hero-avatars span:nth-child(2) {
    background: linear-gradient(135deg, var(--color-red), var(--color-amber));
  }
  .hero-avatars span:nth-child(3) {
    background: linear-gradient(135deg, var(--color-green), var(--color-blue));
  }
  .hero-avatars span:nth-child(4) {
    background: linear-gradient(135deg, var(--color-amber), var(--color-red));
  }

  /* ===== qcard + floating chips ===== */
  .hero-visual { position: relative; }
  .qcard {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 22px;
    padding: 26px;
    box-shadow:
      0 30px 60px -25px rgba(15, 24, 57, 0.22),
      0 10px 25px -15px rgba(15, 24, 57, 0.1);
    transform: rotate(-1deg);
  }
  .qcard-head {
    display: flex; justify-content: space-between; align-items: center;
    padding-bottom: 14px;
    border-bottom: 1px solid var(--color-line-2);
    margin-bottom: 18px;
  }
  .qcard-tag {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.1em;
    background: var(--color-blue-light);
    color: var(--color-blue);
    padding: 4px 10px; border-radius: 6px;
    font-weight: 600;
  }
  .qcard-progress {
    font-family: var(--font-mono);
    font-size: 11px; color: var(--color-muted);
  }
  .qcard-progress strong { color: var(--color-ink); }
  .qcard-q {
    font-family: var(--font-display);
    font-size: 19px; font-weight: 500;
    line-height: 1.35; color: var(--color-ink);
    margin: 0 0 18px;
  }
  .qcard-options { display: flex; flex-direction: column; gap: 8px; }
  .qopt {
    display: flex; align-items: center; gap: 12px;
    padding: 12px 14px;
    border: 1.5px solid var(--color-line);
    border-radius: 12px;
    font-size: 14px; color: var(--color-ink-2);
  }
  .qopt-letter {
    width: 26px; height: 26px; border-radius: 7px;
    background: var(--color-paper-2);
    display: flex; align-items: center; justify-content: center;
    font-family: var(--font-mono);
    font-size: 11px; font-weight: 700;
    color: var(--color-muted);
    flex-shrink: 0;
  }
  .qopt.correct {
    border-color: var(--color-green);
    background: rgba(22, 143, 91, 0.04);
  }
  .qopt.correct .qopt-letter {
    background: var(--color-green); color: #fff;
  }
  .qopt-mark {
    margin-left: auto; color: var(--color-green); font-weight: 700;
  }
  .qcard-feedback {
    margin-top: 16px; padding: 14px;
    background: var(--color-blue-soft);
    border-left: 3px solid var(--color-blue);
    border-radius: 10px;
    font-size: 13px; color: var(--color-ink-2);
    line-height: 1.5;
  }
  .qcard-feedback strong { color: var(--color-blue); }

  /* floating chips */
  .float-chip {
    position: absolute;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    padding: 10px 14px;
    box-shadow: 0 12px 30px -15px rgba(15, 24, 57, 0.22);
    display: flex; align-items: center; gap: 10px;
    font-size: 13px;
  }
  .float-1 { top: -22px; right: -16px; transform: rotate(3deg); }
  .float-2 { bottom: -18px; left: -28px; transform: rotate(-2deg); }
  .chip-icon {
    width: 32px; height: 32px; border-radius: 9px;
    display: flex; align-items: center; justify-content: center;
    font-size: 16px;
  }
  .chip-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .chip-red { background: var(--color-red-light); color: var(--color-red); }
  .chip-text { display: flex; flex-direction: column; gap: 1px; }
  .chip-label {
    font-family: var(--font-mono);
    font-size: 9px; color: var(--color-muted);
    letter-spacing: 0.12em; text-transform: uppercase;
  }
  .chip-value {
    font-weight: 700; font-size: 14px; color: var(--color-ink);
  }

  @media (max-width: 960px) {
    .hero { padding: 64px 0 84px; }
    .hero-inner { grid-template-columns: 1fr; gap: 56px; }
    .hero-h1 { font-size: clamp(32px, 8vw, 44px); }
    .float-1 { top: -18px; right: 8px; }
    .float-2 { bottom: -18px; left: 4px; }
  }
  @media (max-width: 560px) {
    .hero-trust { flex-wrap: wrap; gap: 12px; }
    .hero-trust p { font-size: 12.5px; }
  }
`;
