import Link from "next/link";

export function HeroSection() {
  return (
    <header
      style={{
        padding: "80px 0 60px",
        position: "relative",
        overflow: "hidden",
      }}
    >
      {/* halos décoratifs */}
      <div
        aria-hidden
        style={{
          position: "absolute",
          top: -200,
          right: -300,
          width: 700,
          height: 700,
          background:
            "radial-gradient(circle, var(--color-blue-light) 0%, transparent 65%)",
          pointerEvents: "none",
        }}
      />
      <div
        aria-hidden
        style={{
          position: "absolute",
          bottom: -200,
          left: -200,
          width: 500,
          height: 500,
          background:
            "radial-gradient(circle, var(--color-red-light) 0%, transparent 65%)",
          pointerEvents: "none",
        }}
      />

      <div className="container-x">
        <div className="hero-grid">
          <div>
            <div className="hero-badge">
              <span className="dot" />
              Obligatoire depuis le 1<sup>er</sup> janvier 2026 · CSP · CR ·
              Naturalisation
            </div>
            <h1 className="hero-h1">
              Réussir l'examen civique <em>et</em> le TCF,
              <br />
              sans stress.
            </h1>
            <p className="hero-lede">
              Plus de 1 200 questions calibrées sur le référentiel officiel, des
              examens blancs en conditions réelles, et une correction expliquée
              à chaque réponse. Pour faire votre demande la tête tranquille.
            </p>
            <div
              style={{
                display: "flex",
                gap: 12,
                flexWrap: "wrap",
                alignItems: "center",
              }}
            >
              <Link href="/inscription" className="btn btn-lg btn-red">
                Commencer gratuitement
                <span className="arrow">→</span>
              </Link>
              <Link href="/examen-blanc" className="btn btn-lg btn-ghost">
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

          {/* Preview Card */}
          <div>
            <div className="preview">
              <div className="preview-inner">
                <div className="preview-bar">
                  <span className="preview-timer">● Examen blanc · CSP</span>
                  <span className="preview-progress">12 / 40</span>
                </div>
                <div className="preview-cat">
                  Principes & valeurs · Question 12
                </div>
                <h3 className="preview-q">
                  Que signifie la devise « Liberté, Égalité, Fraternité » ?
                </h3>
                <div className="preview-options">
                  <div className="preview-opt">
                    <span className="letter">A</span>
                    Trois objectifs économiques de l'État
                  </div>
                  <div className="preview-opt correct">
                    <span className="letter">B</span>
                    Les valeurs fondamentales de la République
                  </div>
                  <div className="preview-opt">
                    <span className="letter">C</span>
                    Le nom du gouvernement actuel
                  </div>
                </div>
                <div className="preview-explain">
                  <strong>Bonne réponse.</strong> Cette devise figure dans
                  l'article 2 de la Constitution et résume les valeurs
                  républicaines depuis 1848.
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <style>{`
        .hero-grid {
          display: grid;
          grid-template-columns: 1.15fr 0.85fr;
          gap: 64px;
          align-items: center;
          position: relative;
          z-index: 1;
        }
        .hero-badge {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          padding: 7px 14px;
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 100px;
          font-family: var(--font-mono);
          font-size: 11px;
          letter-spacing: 0.08em;
          color: var(--color-ink-2);
          margin-bottom: 24px;
        }
        .hero-badge .dot {
          width: 7px;
          height: 7px;
          border-radius: 50%;
          background: var(--color-green);
          box-shadow: 0 0 0 3px rgba(22, 143, 91, 0.18);
        }
        .hero-h1 {
          font-family: var(--font-display);
          font-weight: 500;
          font-size: clamp(38px, 5.2vw, 62px);
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
        .hero-trust {
          display: flex;
          gap: 28px;
          margin-top: 36px;
          padding-top: 28px;
          border-top: 1px solid var(--color-line);
        }
        .hero-trust .stat { display: flex; flex-direction: column; gap: 2px; }
        .hero-trust .stat-num {
          font-family: var(--font-display);
          font-size: 28px;
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

        .preview {
          background: #fff;
          border-radius: 16px;
          border: 1px solid var(--color-line);
          padding: 6px;
          box-shadow:
            0 1px 2px rgba(15, 24, 57, 0.04),
            0 20px 50px -20px rgba(15, 24, 57, 0.18),
            0 60px 100px -50px rgba(30, 58, 140, 0.12);
          position: relative;
        }
        .preview::before {
          content: "";
          position: absolute;
          inset: -12px;
          background: linear-gradient(135deg, var(--color-blue-light), var(--color-red-light));
          border-radius: 24px;
          z-index: -1;
          opacity: 0.5;
        }
        .preview-inner {
          background: var(--color-paper);
          border-radius: 12px;
          padding: 22px;
        }
        .preview-bar {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding-bottom: 14px;
          border-bottom: 1px solid var(--color-line-2);
          margin-bottom: 18px;
        }
        .preview-timer {
          font-family: var(--font-mono);
          font-size: 12px;
          color: var(--color-red);
          font-weight: 500;
          display: flex; align-items: center; gap: 6px;
        }
        .preview-progress {
          font-family: var(--font-mono);
          font-size: 11px;
          color: var(--color-muted);
          letter-spacing: 0.08em;
        }
        .preview-cat {
          font-family: var(--font-mono);
          font-size: 10px;
          color: var(--color-blue);
          letter-spacing: 0.15em;
          text-transform: uppercase;
          margin-bottom: 8px;
        }
        .preview-q {
          font-family: var(--font-display);
          font-weight: 500;
          font-size: 19px;
          line-height: 1.3;
          letter-spacing: -0.01em;
          margin: 0 0 18px;
        }
        .preview-options { display: flex; flex-direction: column; gap: 8px; }
        .preview-opt {
          border: 1px solid var(--color-line);
          border-radius: 8px;
          padding: 12px 14px;
          font-size: 14px;
          color: var(--color-ink-2);
          display: flex; align-items: center; gap: 12px;
          background: #fff;
          transition: all 0.15s;
        }
        .preview-opt .letter {
          width: 22px; height: 22px;
          border-radius: 50%;
          background: var(--color-paper-2);
          color: var(--color-muted);
          display: flex; align-items: center; justify-content: center;
          font-family: var(--font-mono);
          font-size: 11px;
          font-weight: 500;
          flex-shrink: 0;
        }
        .preview-opt.correct {
          border-color: var(--color-green);
          background: rgba(22, 143, 91, 0.06);
          color: var(--color-ink);
        }
        .preview-opt.correct .letter { background: var(--color-green); color: #fff; }
        .preview-opt.correct::after {
          content: "✓";
          margin-left: auto;
          color: var(--color-green);
          font-weight: 700;
        }
        .preview-explain {
          margin-top: 14px;
          padding: 12px 14px;
          background: var(--color-blue-light);
          border-radius: 8px;
          font-size: 13px;
          color: var(--color-ink-2);
          line-height: 1.5;
          border-left: 3px solid var(--color-blue);
        }
        .preview-explain strong { color: var(--color-blue); font-weight: 600; }

        @media (max-width: 960px) {
          .hero-grid { grid-template-columns: 1fr; gap: 48px; }
        }
      `}</style>
    </header>
  );
}
