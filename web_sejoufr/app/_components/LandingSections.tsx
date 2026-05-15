import Link from "next/link";

// ============================================================================
// STRIP — bandeau de confiance
// ============================================================================
export function TrustStrip() {
  return (
    <div
      style={{
        padding: "36px 0",
        borderTop: "1px solid var(--color-line)",
        borderBottom: "1px solid var(--color-line)",
        background: "var(--color-paper-2)",
      }}
    >
      <div
        style={{
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          gap: 48,
          flexWrap: "wrap",
          fontFamily: "var(--font-mono)",
          fontSize: 11,
          color: "var(--color-muted)",
          letterSpacing: "0.1em",
          textTransform: "uppercase",
        }}
      >
        <span style={{ color: "var(--color-ink)", fontWeight: 500 }}>
          Préparez en confiance
        </span>
        {["Examen civique CSP", "Carte de résident", "Naturalisation", "TCF A2 · B1 · B2"].map(
          (label) => (
            <span
              key={label}
              style={{ display: "flex", alignItems: "center", gap: 8 }}
            >
              <span
                style={{
                  width: 18,
                  height: 1,
                  background: "var(--color-muted-2)",
                  display: "inline-block",
                }}
              />
              {label}
            </span>
          ),
        )}
      </div>
    </div>
  );
}

// ============================================================================
// SectionHead — titre éditorial réutilisable
// ============================================================================
function SectionHead({
  eyebrow,
  title,
  emphasis,
  sub,
}: {
  eyebrow: string;
  title: string;
  emphasis: string;
  sub?: string;
}) {
  return (
    <div style={{ maxWidth: 720, margin: "0 auto 60px", textAlign: "center" }}>
      <span className="eyebrow" style={{ display: "block", marginBottom: 14 }}>
        {eyebrow}
      </span>
      <h2 className="sec-h2">
        {title} <em>{emphasis}</em>
      </h2>
      {sub && <p className="sec-sub">{sub}</p>}
      <style>{`
        .sec-h2 {
          font-family: var(--font-display);
          font-weight: 500;
          font-size: clamp(32px, 4vw, 46px);
          line-height: 1.08;
          letter-spacing: -0.02em;
          margin: 0 0 16px;
        }
        .sec-h2 em { color: var(--color-red); font-style: italic; }
        .sec-sub { color: var(--color-muted); font-size: 17px; margin: 0; }
      `}</style>
    </div>
  );
}

// ============================================================================
// PROBLEM / SOLUTION
// ============================================================================
export function ProblemSection() {
  return (
    <section
      id="methode"
      style={{
        background: "var(--color-paper)",
        borderTop: "1px solid var(--color-line)",
        padding: "100px 0",
      }}
    >
      <div className="container-x">
        <SectionHead
          eyebrow="Pourquoi SejourFR"
          title="L'examen a changé."
          emphasis="Votre préparation aussi."
          sub="Depuis janvier 2026, l'examen civique conditionne titre de séjour, carte de résident et naturalisation. La réussite n'est plus optionnelle."
        />

        <div className="problem-grid">
          <div className="problem-col before">
            <span className="problem-tag bad">Sans préparation structurée</span>
            <h3 className="problem-h3">Vous y allez à l'aveugle.</h3>
            <ul className="problem-list">
              <li>
                <span className="ico">✕</span>Des PDF officiels denses, sans entraînement
              </li>
              <li>
                <span className="ico">✕</span>Des vidéos YouTube génériques et obsolètes
              </li>
              <li>
                <span className="ico">✕</span>Aucun feedback sur ce que vous ne maîtrisez pas
              </li>
              <li>
                <span className="ico">✕</span>Le stress de la première tentative à 75 € qui peut être bloquante
              </li>
            </ul>
          </div>
          <div className="problem-col after">
            <span className="problem-tag good">Avec SejourFR</span>
            <h3 className="problem-h3">Vous arrivez préparé.</h3>
            <ul className="problem-list">
              <li>
                <span className="ico">✓</span>Questions calibrées sur le référentiel officiel 2026
              </li>
              <li>
                <span className="ico">✓</span>Correction expliquée après chaque réponse
              </li>
              <li>
                <span className="ico">✓</span>Suivi de progression par thématique et révision ciblée
              </li>
              <li>
                <span className="ico">✓</span>Examens blancs en conditions réelles · 40 questions · 45 min
              </li>
            </ul>
          </div>
        </div>
      </div>

      <style>{`
        .problem-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          border: 1px solid var(--color-line);
          border-radius: 16px;
          overflow: hidden;
          background: #fff;
        }
        .problem-col {
          padding: 44px 40px;
          position: relative;
        }
        .problem-col.before {
          background: var(--color-paper-2);
          border-right: 1px solid var(--color-line);
        }
        .problem-h3 {
          font-family: var(--font-display);
          font-weight: 500;
          font-size: 24px;
          margin: 14px 0 24px;
          letter-spacing: -0.015em;
        }
        .problem-tag {
          font-family: var(--font-mono);
          font-size: 10px;
          letter-spacing: 0.16em;
          text-transform: uppercase;
          padding: 4px 10px;
          border-radius: 100px;
          display: inline-block;
        }
        .problem-tag.bad { background: var(--color-red-light); color: var(--color-red-dark); }
        .problem-tag.good { background: rgba(22, 143, 91, 0.12); color: var(--color-green); }
        .problem-list { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 14px; }
        .problem-list li {
          display: flex; gap: 12px; align-items: flex-start;
          font-size: 14.5px; color: var(--color-ink-2); line-height: 1.5;
        }
        .ico {
          width: 22px; height: 22px;
          border-radius: 50%;
          display: flex; align-items: center; justify-content: center;
          flex-shrink: 0; margin-top: 1px;
          font-size: 12px; font-weight: 700;
        }
        .problem-col.before .ico { background: var(--color-red-light); color: var(--color-red-dark); }
        .problem-col.after .ico { background: rgba(22, 143, 91, 0.12); color: var(--color-green); }

        @media (max-width: 960px) {
          .problem-grid { grid-template-columns: 1fr; }
          .problem-col.before { border-right: none; border-bottom: 1px solid var(--color-line); }
        }
      `}</style>
    </section>
  );
}

// ============================================================================
// EXAMS GRID
// ============================================================================
export function ExamsSection() {
  return (
    <section
      id="examens"
      style={{
        background: "var(--color-paper-2)",
        borderTop: "1px solid var(--color-line)",
        padding: "100px 0",
      }}
    >
      <div className="container-x">
        <SectionHead
          eyebrow="Les modules"
          title="Deux examens,"
          emphasis="une seule plateforme."
          sub="Civique pour valider les valeurs et institutions, TCF IRN pour le niveau de français. Selon votre démarche."
        />

        <div className="exam-cards">
          {/* Civique */}
          <div className="exam-card">
            <div className="ribbon">Examen civique</div>
            <div className="cocarde lg" aria-hidden />
            <h3 className="exam-h3">Civique</h3>
            <p className="exam-sub">
              Valeurs républicaines, institutions, droits et devoirs, histoire,
              vie en société.
            </p>
            <div className="exam-mentions">
              <span className="mention">CSP</span>
              <span className="mention">Carte de résident</span>
              <span className="mention">Naturalisation</span>
            </div>
            <div className="exam-stats">
              <div className="exam-stat">
                <div className="v">40</div>
                <div className="l">Questions</div>
              </div>
              <div className="exam-stat">
                <div className="v">45 min</div>
                <div className="l">Durée</div>
              </div>
              <div className="exam-stat">
                <div className="v">32/40</div>
                <div className="l">Seuil réussite</div>
              </div>
            </div>
            <div style={{ display: "flex", gap: 10 }}>
              <Link href="/examen-blanc?type=civique" className="btn">
                Examen blanc
              </Link>
              <Link href="/inscription" className="btn btn-ghost">
                Commencer
              </Link>
            </div>
          </div>

          {/* TCF */}
          <div className="exam-card tcf">
            <div className="ribbon">TCF IRN</div>
            <svg width="56" height="56" viewBox="0 0 56 56" aria-hidden>
              <rect
                x="3"
                y="10"
                width="50"
                height="36"
                rx="4"
                fill="none"
                stroke="#E1372F"
                strokeWidth="2.5"
              />
              <line x1="3" y1="22" x2="53" y2="22" stroke="#E1372F" strokeWidth="2.5" />
              <circle cx="11" cy="16" r="1.8" fill="#E1372F" />
              <circle cx="17" cy="16" r="1.8" fill="#E1372F" />
              <path
                d="M 14 32 L 22 32 M 26 32 L 42 32 M 14 38 L 30 38 M 34 38 L 42 38"
                stroke="#E1372F"
                strokeWidth="2"
                strokeLinecap="round"
              />
            </svg>
            <h3 className="exam-h3">TCF IRN</h3>
            <p className="exam-sub">
              Compréhension orale, compréhension écrite, structure de la langue.
              Trois épreuves chronométrées.
            </p>
            <div className="exam-mentions">
              <span className="mention">A2 — CSP</span>
              <span className="mention">B1 — CR</span>
              <span className="mention">B2 — Naturalisation</span>
            </div>
            <div className="exam-stats">
              <div className="exam-stat">
                <div className="v">3</div>
                <div className="l">Épreuves</div>
              </div>
              <div className="exam-stat">
                <div className="v">60 min</div>
                <div className="l">Durée</div>
              </div>
              <div className="exam-stat">
                <div className="v">A2 → B2</div>
                <div className="l">Niveaux</div>
              </div>
            </div>
            <div style={{ display: "flex", gap: 10 }}>
              <Link href="/examen-blanc?type=tcf" className="btn btn-red">
                Examen blanc
              </Link>
              <Link href="/inscription" className="btn btn-ghost">
                Commencer
              </Link>
            </div>
          </div>
        </div>
      </div>

      <style>{`
        .exam-cards { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }
        .exam-card {
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 16px;
          padding: 36px 32px;
          position: relative;
          overflow: hidden;
          transition: transform 0.2s, box-shadow 0.2s;
        }
        .exam-card:hover { transform: translateY(-3px); box-shadow: 0 20px 40px -20px rgba(15, 24, 57, 0.15); }
        .exam-card .ribbon {
          position: absolute; top: 0; right: 0;
          padding: 6px 14px;
          background: var(--color-blue);
          color: #fff;
          font-family: var(--font-mono);
          font-size: 10px; letter-spacing: 0.12em; text-transform: uppercase;
          border-bottom-left-radius: 10px;
        }
        .exam-card.tcf .ribbon { background: var(--color-red); }
        .exam-h3 {
          font-family: var(--font-display);
          font-weight: 500;
          font-size: 30px;
          margin: 24px 0 6px;
          letter-spacing: -0.02em;
        }
        .exam-sub { color: var(--color-muted); font-size: 14.5px; margin: 0 0 24px; }
        .exam-mentions { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 24px; }
        .mention {
          padding: 6px 12px;
          background: var(--color-blue-light);
          color: var(--color-blue);
          border-radius: 6px;
          font-size: 12px;
          font-weight: 600;
        }
        .exam-card.tcf .mention { background: var(--color-red-light); color: var(--color-red-dark); }
        .exam-stats {
          display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px;
          padding: 18px 0;
          border-top: 1px solid var(--color-line-2);
          border-bottom: 1px solid var(--color-line-2);
          margin-bottom: 22px;
        }
        .exam-stat .v {
          font-family: var(--font-display);
          font-size: 24px; font-weight: 500;
          letter-spacing: -0.015em;
        }
        .exam-stat .l {
          font-family: var(--font-mono);
          font-size: 10px; letter-spacing: 0.1em; text-transform: uppercase;
          color: var(--color-muted); margin-top: 2px;
        }

        @media (max-width: 960px) {
          .exam-cards { grid-template-columns: 1fr; }
        }
      `}</style>
    </section>
  );
}

// ============================================================================
// HOW IT WORKS
// ============================================================================
export function HowItWorksSection() {
  return (
    <section
      style={{
        background: "var(--color-paper)",
        borderTop: "1px solid var(--color-line)",
        padding: "100px 0",
      }}
    >
      <div className="container-x">
        <SectionHead
          eyebrow="Comment ça marche"
          title="Quatre étapes,"
          emphasis="zéro friction."
        />

        <div className="steps">
          {[
            { n: 1, t: "Créez votre compte", d: "Email, mot de passe. Choisissez votre mention (CSP, CR ou naturalisation)." },
            { n: 2, t: "Entraînez-vous", d: "QCM par thématique, correction expliquée à chaque réponse. Marquez vos favoris." },
            { n: 3, t: "Passez des blancs", d: "40 questions, 45 minutes, conditions réelles. Identifiez vos points faibles." },
            { n: 4, t: "Prêt le jour J", d: "Suivez votre progression jusqu'à atteindre régulièrement le seuil." },
          ].map((step) => (
            <div className="step" key={step.n}>
              <div className="step-num">{step.n}</div>
              <h4>{step.t}</h4>
              <p>{step.d}</p>
            </div>
          ))}
        </div>
      </div>

      <style>{`
        .steps {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 0;
          position: relative;
        }
        .steps::before {
          content: "";
          position: absolute;
          top: 28px;
          left: 12%; right: 12%;
          height: 1px;
          background: repeating-linear-gradient(to right, var(--color-line) 0, var(--color-line) 6px, transparent 6px, transparent 12px);
          z-index: 0;
        }
        .step { text-align: center; padding: 0 18px; position: relative; z-index: 1; }
        .step-num {
          width: 56px; height: 56px;
          border-radius: 50%;
          background: #fff;
          border: 1.5px solid var(--color-blue);
          color: var(--color-blue);
          display: flex; align-items: center; justify-content: center;
          margin: 0 auto 20px;
          font-family: var(--font-display);
          font-size: 22px; font-weight: 500;
          box-shadow: 0 0 0 8px var(--color-paper);
        }
        .step:nth-child(even) .step-num { border-color: var(--color-red); color: var(--color-red); }
        .step h4 {
          font-family: var(--font-sans);
          font-size: 16px; font-weight: 700;
          margin: 0 0 8px;
          letter-spacing: -0.01em;
        }
        .step p { font-size: 14px; color: var(--color-muted); margin: 0; line-height: 1.5; }

        @media (max-width: 960px) {
          .steps { grid-template-columns: 1fr 1fr; gap: 36px 12px; }
          .steps::before { display: none; }
        }
        @media (max-width: 560px) {
          .steps { grid-template-columns: 1fr; }
        }
      `}</style>
    </section>
  );
}

// ============================================================================
// PRICING
// ============================================================================
export function PricingSection() {
  return (
    <section
      id="tarifs"
      style={{
        background: "var(--color-paper-2)",
        borderTop: "1px solid var(--color-line)",
        padding: "100px 0",
      }}
    >
      <div className="container-x">
        <SectionHead
          eyebrow="Tarifs"
          title="Choisissez ce qui"
          emphasis="vous correspond."
          sub="Commencez gratuitement, passez Premium quand vous êtes prêt. Sans engagement, résiliable à tout moment."
        />

        <div className="plans">
          {/* Découverte */}
          <div className="plan">
            <div className="plan-name">Découverte</div>
            <p className="plan-desc">Pour tester la méthode et voir où vous en êtes.</p>
            <div className="plan-price">
              <span className="amount">0</span>
              <span className="currency">€</span>
            </div>
            <div className="plan-period">Gratuit · pour toujours</div>
            <div style={{ marginBottom: 24 }}>
              <Link href="/inscription" className="btn btn-ghost" style={{ width: "100%" }}>
                Créer mon compte
              </Link>
            </div>
            <ul className="plan-feat">
              <li>10 QCM par catégorie</li>
              <li>1 examen blanc civique complet</li>
              <li>1 examen blanc TCF complet</li>
              <li>Correction expliquée</li>
              <li className="muted">Banque complète de questions</li>
              <li className="muted">Examens blancs illimités</li>
            </ul>
          </div>

          {/* Premium mensuel */}
          <div className="plan featured">
            <div className="plan-tag">Recommandé</div>
            <div className="plan-name">Premium mensuel</div>
            <p className="plan-desc">L&apos;essentiel pour préparer votre examen sereinement.</p>
            <div className="plan-price">
              <span className="amount">9,99</span>
              <span className="currency">€</span>
            </div>
            <div className="plan-period">par mois · sans engagement</div>
            <div style={{ marginBottom: 24 }}>
              <Link href="/paiement?plan=premium" className="btn btn-red" style={{ width: "100%" }}>
                Passer Premium
              </Link>
            </div>
            <ul className="plan-feat">
              <li><strong>1 200+ questions</strong> tous modules</li>
              <li>Examens blancs <strong>illimités</strong></li>
              <li>Entraînement illimité sur l&apos;app</li>
              <li>Révision ciblée des erreurs</li>
              <li>Mode hors-ligne (app mobile)</li>
              <li>Garantie satisfait remboursé 14 jours</li>
            </ul>
          </div>

          {/* Premium annuel */}
          <div className="plan">
            <div className="plan-tag plan-tag-green">−26 %</div>
            <div className="plan-name">Premium annuel</div>
            <p className="plan-desc">Préparez plusieurs examens dans l&apos;année.</p>
            <div className="plan-price">
              <span className="amount">89</span>
              <span className="currency">€</span>
            </div>
            <div className="plan-period">par an · soit 7,42 €/mois</div>
            <div style={{ marginBottom: 24 }}>
              <Link href="/paiement?plan=annuel" className="btn" style={{ width: "100%" }}>
                Choisir l&apos;annuel
              </Link>
            </div>
            <ul className="plan-feat">
              <li>Tout le Premium mensuel inclus</li>
              <li><strong>Économisez 31 €</strong> sur l&apos;année</li>
              <li>Accès prioritaire aux nouveautés</li>
              <li>Support email sous 24 h</li>
              <li>Sans rappel d&apos;échéance</li>
            </ul>
          </div>
        </div>
      </div>

      <style>{`
        .plans { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; }
        .plan {
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 16px;
          padding: 32px 28px;
          display: flex; flex-direction: column;
          position: relative;
        }
        .plan.featured {
          border-color: var(--color-blue);
          border-width: 2px;
          background: linear-gradient(180deg, var(--color-blue-soft) 0%, #fff 40%);
          box-shadow: 0 20px 50px -25px rgba(30, 58, 140, 0.25);
          transform: translateY(-6px);
        }
        .plan-tag {
          position: absolute; top: -12px; left: 28px;
          background: var(--color-red);
          color: #fff;
          font-family: var(--font-mono);
          font-size: 10px; letter-spacing: 0.12em; text-transform: uppercase;
          padding: 5px 12px; border-radius: 100px;
          font-weight: 600;
        }
        .plan-tag-green { background: var(--color-green); }
        .plan-name {
          font-family: var(--font-sans);
          font-weight: 700; font-size: 18px;
          color: var(--color-ink); margin: 0 0 4px;
        }
        .plan-desc {
          font-size: 13.5px; color: var(--color-muted);
          margin: 0 0 22px; min-height: 40px;
        }
        .plan-price { display: flex; align-items: baseline; gap: 6px; margin-bottom: 4px; }
        .plan-price .amount {
          font-family: var(--font-display);
          font-size: 44px; font-weight: 500;
          letter-spacing: -0.02em; line-height: 1;
        }
        .plan-price .currency { font-size: 22px; font-family: var(--font-display); }
        .plan-period { font-size: 13px; color: var(--color-muted); margin-bottom: 22px; }
        .plan-feat {
          list-style: none; padding: 22px 0 0; margin: 0;
          border-top: 1px solid var(--color-line-2);
          display: flex; flex-direction: column; gap: 12px;
          flex-grow: 1;
        }
        .plan-feat li {
          font-size: 14px; color: var(--color-ink-2);
          display: flex; gap: 10px; align-items: flex-start;
        }
        .plan-feat li::before {
          content: "";
          width: 16px; height: 16px; margin-top: 3px; flex-shrink: 0;
          background: var(--color-green);
          -webkit-mask: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'><path fill='none' stroke='white' stroke-width='2.4' stroke-linecap='round' stroke-linejoin='round' d='M3 8.5l3 3 7-7'/></svg>") no-repeat center / contain;
                  mask: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'><path fill='none' stroke='white' stroke-width='2.4' stroke-linecap='round' stroke-linejoin='round' d='M3 8.5l3 3 7-7'/></svg>") no-repeat center / contain;
        }
        .plan-feat li.muted { color: var(--color-muted); }
        .plan-feat li.muted::before { background: var(--color-muted-2); }

        @media (max-width: 960px) {
          .plans { grid-template-columns: 1fr; }
          .plan.featured { transform: none; }
        }
      `}</style>
    </section>
  );
}

// ============================================================================
// TESTIMONIALS
// ============================================================================
export function TestimonialsSection() {
  const testimonials = [
    {
      body: "J'ai passé l'examen pour la naturalisation après six semaines d'entraînement. 37/40. Les examens blancs sont identiques au format réel.",
      initials: "FA",
      name: "Fatima A.",
      meta: "Naturalisation · Marseille",
      cls: "",
    },
    {
      body: "Le TCF B1 me faisait peur. Les exercices de compréhension orale m'ont vraiment préparé. J'ai eu ma carte de résident.",
      initials: "VO",
      name: "Viktor O.",
      meta: "Carte de résident · Lyon",
      cls: "r",
    },
    {
      body: "L'app mobile m'a permis de réviser dans le métro tous les jours. Les explications après chaque question font la différence.",
      initials: "CB",
      name: "Chen B.",
      meta: "CSP · Paris",
      cls: "g",
    },
  ];

  return (
    <section
      id="temoignages"
      style={{
        background: "var(--color-paper)",
        borderTop: "1px solid var(--color-line)",
        padding: "100px 0",
      }}
    >
      <div className="container-x">
        <SectionHead
          eyebrow="Témoignages"
          title="Ils ont réussi"
          emphasis="avec SejourFR."
        />

        <div className="testi-grid">
          {testimonials.map((t, i) => (
            <div className="testi-card" key={i}>
              <span className="quote-mark">"</span>
              <p className="testi-body">{t.body}</p>
              <div className="testi-foot">
                <div className={`avatar ${t.cls}`}>{t.initials}</div>
                <div>
                  <div className="testi-name">{t.name}</div>
                  <div className="testi-meta">{t.meta}</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <style>{`
        .testi-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; }
        .testi-card {
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 14px;
          padding: 28px 26px;
          display: flex; flex-direction: column;
          position: relative;
        }
        .quote-mark {
          position: absolute; top: 16px; right: 22px;
          font-family: var(--font-display);
          font-size: 70px; line-height: 1;
          color: var(--color-blue-light); font-weight: 500;
        }
        .testi-body {
          font-family: var(--font-display);
          font-weight: 400;
          font-size: 17.5px;
          line-height: 1.45;
          color: var(--color-ink);
          margin: 0 0 24px;
          letter-spacing: -0.005em;
          position: relative; z-index: 1;
        }
        .testi-foot {
          display: flex; gap: 12px; align-items: center;
          margin-top: auto; padding-top: 18px;
          border-top: 1px solid var(--color-line-2);
        }
        .avatar {
          width: 42px; height: 42px;
          border-radius: 50%;
          display: flex; align-items: center; justify-content: center;
          color: #fff;
          font-weight: 700;
          font-size: 14px;
          flex-shrink: 0;
          background: var(--color-blue);
        }
        .avatar.r { background: var(--color-red); }
        .avatar.g { background: var(--color-green); }
        .testi-name { font-weight: 600; font-size: 14px; color: var(--color-ink); }
        .testi-meta {
          font-size: 12px; color: var(--color-muted);
          font-family: var(--font-mono);
          letter-spacing: 0.05em;
        }
        @media (max-width: 960px) {
          .testi-grid { grid-template-columns: 1fr; }
        }
      `}</style>
    </section>
  );
}

// ============================================================================
// FAQ
// ============================================================================
export function FaqSection() {
  const faqs: { q: string; a: React.ReactNode; open?: boolean }[] = [
    {
      q: "L'examen civique est-il vraiment obligatoire ?",
      a: (
        <>
          Oui. Depuis le 1<sup>er</sup> janvier 2026, l'examen civique est
          obligatoire pour toute demande de carte de séjour pluriannuelle (CSP),
          de carte de résident (CR) et de naturalisation. Il se passe dans un
          centre agréé et conditionne l'instruction de votre dossier.
        </>
      ),
      open: true,
    },
    {
      q: "Quelle est la différence entre les trois mentions ?",
      a: "Le contenu de l'examen est ajusté selon votre démarche. La mention CSP couvre les bases ; la carte de résident exige davantage de précision sur les institutions ; la naturalisation inclut une connaissance plus poussée de l'histoire et de la culture. SejourFR vous permet de choisir votre mention et d'avoir des questions adaptées.",
    },
    {
      q: "Quel niveau de français dois-je viser pour le TCF ?",
      a: "A2 pour la CSP, B1 pour la carte de résident, B2 pour la naturalisation. Nos modules couvrent les trois niveaux avec compréhension orale, compréhension écrite et structure de la langue.",
    },
    {
      q: "Puis-je tester avant de payer ?",
      a: "Bien sûr. Le plan Découverte est gratuit et permanent : 10 QCM par catégorie, plus un examen blanc complet pour le civique et un pour le TCF. Vous voyez votre niveau avant de vous engager.",
    },
    {
      q: "Le contenu est-il à jour ?",
      a: "Notre banque est calibrée sur le référentiel officiel 2026 du Ministère de l'Intérieur. Notre équipe pédagogique met à jour les questions à chaque évolution réglementaire — sans surcoût pour les abonnés.",
    },
    {
      q: "Comment résilier mon abonnement Premium ?",
      a: "En un clic depuis votre espace personnel. Aucun engagement de durée, aucun frais caché. Vous gardez l'accès jusqu'à la fin de la période payée.",
    },
    {
      q: "Est-ce que SejourFR remplace une formation civique ?",
      a: "Non. SejourFR est un outil d'entraînement intensif aux QCM, conçu pour vous mettre en conditions d'examen. Pour les contenus pédagogiques (cours, vidéos), nous vous orientons vers les ressources officielles et les formations agréées.",
    },
  ];

  return (
    <section
      id="faq"
      style={{
        background: "var(--color-paper-2)",
        borderTop: "1px solid var(--color-line)",
        padding: "100px 0",
      }}
    >
      <div className="container-x">
        <SectionHead
          eyebrow="Questions fréquentes"
          title="Tout ce que vous voulez savoir,"
          emphasis="avant de commencer."
        />

        <div className="faq-list">
          {faqs.map((f, i) => (
            <details className="faq-item" key={i} open={f.open}>
              <summary>{f.q}</summary>
              <p>{f.a}</p>
            </details>
          ))}
        </div>
      </div>

      <style>{`
        .faq-list { max-width: 820px; margin: 0 auto; }
        .faq-item {
          border-top: 1px solid var(--color-line);
          padding: 22px 0;
        }
        .faq-item:last-child { border-bottom: 1px solid var(--color-line); }
        .faq-item summary {
          cursor: pointer;
          list-style: none;
          display: flex; justify-content: space-between; align-items: center;
          gap: 24px;
          font-family: var(--font-display);
          font-size: 20px;
          font-weight: 500;
          color: var(--color-ink);
          letter-spacing: -0.015em;
        }
        .faq-item summary::-webkit-details-marker { display: none; }
        .faq-item summary::after {
          content: "+";
          font-size: 26px;
          font-family: var(--font-sans);
          font-weight: 300;
          color: var(--color-blue);
          transition: transform 0.2s;
        }
        .faq-item[open] summary::after { transform: rotate(45deg); }
        .faq-item p {
          margin: 14px 0 0;
          color: var(--color-ink-2);
          font-size: 15.5px;
          line-height: 1.6;
        }
      `}</style>
    </section>
  );
}

// ============================================================================
// FINAL CTA
// ============================================================================
export function FinalCtaSection() {
  return (
    <section className="finalcta">
      <div aria-hidden className="finalcta-halo" />
      <div aria-hidden className="finalcta-grid" />

      <div className="container-x" style={{ position: "relative", zIndex: 1 }}>
        <span className="finalcta-eyebrow">Prêt&nbsp;?</span>
        <h2 className="final-h2">
          Votre titre de séjour <em>vaut mieux</em>
          <br />
          qu&apos;une préparation au hasard.
        </h2>
        <p className="finalcta-lede">
          Créez un compte en 30&nbsp;secondes, téléchargez l&apos;app, et lancez
          votre première session ce soir. Sans carte bancaire pour commencer.
        </p>

        <div className="finalcta-actions">
          <Link href="/inscription" className="btn btn-lg finalcta-primary">
            Créer mon compte gratuit
            <span className="arrow">→</span>
          </Link>
          <Link href="/examens-blancs" className="btn btn-lg finalcta-ghost">
            Voir les examens blancs
          </Link>
        </div>

        <div className="finalcta-stores">
          <span className="finalcta-stores-label">L&apos;app est dispo sur</span>
          <a href="#" className="finalcta-store">
            <span>Télécharger sur</span>
            <strong>App Store</strong>
          </a>
          <a href="#" className="finalcta-store">
            <span>Disponible sur</span>
            <strong>Google Play</strong>
          </a>
        </div>
      </div>

      <style>{`
        .finalcta {
          background: var(--color-blue);
          color: #fff;
          text-align: center;
          padding: 110px 0 100px;
          position: relative;
          overflow: hidden;
          border-top: 4px solid var(--color-red);
        }
        .finalcta-halo {
          position: absolute; inset: 0;
          background:
            radial-gradient(circle at 20% 30%, rgba(255,255,255,0.08) 0%, transparent 55%),
            radial-gradient(circle at 80% 70%, rgba(225,55,47,0.25) 0%, transparent 55%);
          pointer-events: none;
        }
        .finalcta-grid {
          position: absolute; inset: 0;
          background-image:
            linear-gradient(rgba(255,255,255,0.04) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255,255,255,0.04) 1px, transparent 1px);
          background-size: 40px 40px;
          mask-image: radial-gradient(ellipse at 50% 50%, #000 0%, transparent 65%);
          -webkit-mask-image: radial-gradient(ellipse at 50% 50%, #000 0%, transparent 65%);
          pointer-events: none;
        }
        .finalcta-eyebrow {
          display: inline-block;
          font-family: var(--font-mono);
          font-size: 11px;
          letter-spacing: 0.18em;
          text-transform: uppercase;
          color: rgba(255, 255, 255, 0.6);
          margin-bottom: 18px;
          padding: 5px 14px;
          border: 1px solid rgba(255, 255, 255, 0.2);
          border-radius: 100px;
        }
        .final-h2 {
          font-family: var(--font-display); font-weight: 500;
          font-size: clamp(34px, 4.8vw, 56px);
          line-height: 1.05; letter-spacing: -0.025em;
          margin: 0 0 18px; color: #fff;
        }
        .final-h2 em { font-style: italic; color: #ffb3b0; }
        .finalcta-lede {
          color: rgba(255,255,255,0.82); font-size: 18px;
          margin: 0 auto 36px; max-width: 580px;
          line-height: 1.55;
        }
        .finalcta-actions {
          display: flex; gap: 12px; flex-wrap: wrap;
          justify-content: center; margin-bottom: 56px;
        }
        .finalcta-primary {
          background: #fff; color: var(--color-blue); border-color: #fff;
          font-weight: 700;
        }
        .finalcta-primary:hover { background: rgba(255,255,255,0.92); }
        .finalcta-ghost {
          background: transparent; color: #fff;
          border-color: rgba(255,255,255,0.3);
        }
        .finalcta-ghost:hover {
          background: rgba(255,255,255,0.08);
          border-color: rgba(255,255,255,0.5);
        }

        .finalcta-stores {
          display: flex; gap: 12px; align-items: center;
          justify-content: center; flex-wrap: wrap;
          padding-top: 36px;
          border-top: 1px solid rgba(255, 255, 255, 0.12);
        }
        .finalcta-stores-label {
          font-family: var(--font-mono);
          font-size: 10px; letter-spacing: 0.18em;
          text-transform: uppercase;
          color: rgba(255, 255, 255, 0.55);
          margin-right: 4px;
        }
        .finalcta-store {
          display: flex; flex-direction: column;
          padding: 8px 18px;
          background: #fff; color: var(--color-ink);
          border-radius: 10px; text-decoration: none;
          min-width: 150px;
          transition: transform 0.15s;
        }
        .finalcta-store:hover { transform: translateY(-2px); }
        .finalcta-store span {
          font-family: var(--font-mono);
          font-size: 9px; letter-spacing: 0.16em;
          text-transform: uppercase;
          color: var(--color-muted);
        }
        .finalcta-store strong {
          font-family: var(--font-sans);
          font-weight: 700; font-size: 16px;
          letter-spacing: -0.01em;
        }
      `}</style>
    </section>
  );
}
