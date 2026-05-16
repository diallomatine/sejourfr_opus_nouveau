import Link from "next/link";
import { billingApi } from "@/lib/api";
import type { PlanPublicResponse } from "@/lib/types";

// ============================================================================
// STATS STRIP — bandeau de 4 chiffres clés, juste sous le hero
// ============================================================================
export function TrustStrip() {
  const stats = [
    { num: "2 500+", label: "Questions disponibles" },
    { num: "6", label: "Niveaux × mentions" },
    { num: "100 %", label: "Hors-ligne sur mobile" },
    { num: "32/40", label: "Seuil officiel civique" },
  ];
  return (
    <section className="trust-strip">
      <div className="container-x">
        <div className="trust-grid">
          {stats.map((s) => (
            <div className="trust-item" key={s.label}>
              <div className="trust-num">{s.num}</div>
              <div className="trust-label">{s.label}</div>
            </div>
          ))}
        </div>
      </div>
      <style>{`
        .trust-strip {
          border-top: 1px solid var(--color-line);
          border-bottom: 1px solid var(--color-line);
          background: var(--color-paper);
          padding: 36px 0;
        }
        .trust-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 24px;
        }
        .trust-item { text-align: center; }
        .trust-num {
          font-family: var(--font-display);
          font-size: 38px; font-weight: 600;
          color: var(--color-blue);
          letter-spacing: -0.02em; line-height: 1;
        }
        .trust-label {
          font-family: var(--font-mono);
          font-size: 10px;
          letter-spacing: 0.15em;
          text-transform: uppercase;
          color: var(--color-muted);
          margin-top: 8px;
        }
        @media (max-width: 720px) {
          .trust-grid { grid-template-columns: repeat(2, 1fr); gap: 28px; }
        }
      `}</style>
    </section>
  );
}

// ============================================================================
// SectionHead — titre éditorial réutilisable
// ============================================================================
function SectionHead({
  eyebrow,
  children,
  sub,
}: {
  eyebrow: string;
  children: React.ReactNode;
  sub?: string;
}) {
  return (
    <div className="sec-head">
      <span className="eyebrow">{eyebrow}</span>
      <h2 className="sec-h2">{children}</h2>
      {sub && <p className="sec-sub">{sub}</p>}
      <style>{`
        .sec-head {
          max-width: 720px;
          margin: 0 auto 60px;
          text-align: center;
        }
        .sec-head .eyebrow { display: block; margin-bottom: 14px; }
        .sec-h2 {
          font-family: var(--font-display);
          font-weight: 600;
          font-size: clamp(30px, 4vw, 44px);
          line-height: 1.1;
          letter-spacing: -0.02em;
          margin: 0 0 16px;
          color: var(--color-ink);
        }
        .sec-h2 em {
          color: var(--color-blue);
          font-style: italic;
          font-weight: 500;
        }
        .sec-sub {
          color: var(--color-muted);
          font-size: 17px;
          margin: 0;
          line-height: 1.55;
        }
      `}</style>
    </div>
  );
}

// ============================================================================
// EXAMS — Civique + TCF cards avec meta-grid + checklist
// ============================================================================
export function ExamsSection() {
  return (
    <section id="examens" className="exams-sec">
      <div className="container-x">
        <SectionHead
          eyebrow="DEUX EXAMENS, UNE SEULE APP"
          sub="Tous les contenus sont calés sur les référentiels officiels. Les examens blancs reproduisent les conditions du jour J : durée, nombre de questions, seuil de réussite."
        >
          Préparez l&apos;<em>examen civique</em> et le <em>TCF</em> sans
          changer d&apos;outil.
        </SectionHead>

        <div className="exams-grid">
          {/* CIVIQUE */}
          <article className="exam-card civique">
            <span className="exam-tag civique">EXAMEN CIVIQUE</span>
            <h3 className="exam-h3">
              Connaissance des valeurs et principes de la République
            </h3>
            <p className="exam-sub">
              Obligatoire pour la carte de séjour pluriannuelle, la carte de
              résident et la naturalisation depuis le 1<sup>er</sup> janvier
              2026.
            </p>

            <div className="exam-meta">
              <div className="meta-item">
                <div className="meta-label">QUESTIONS</div>
                <div className="meta-value">40 QCM</div>
              </div>
              <div className="meta-item">
                <div className="meta-label">DURÉE</div>
                <div className="meta-value">45 min</div>
              </div>
              <div className="meta-item">
                <div className="meta-label">SEUIL</div>
                <div className="meta-value">32 / 40</div>
              </div>
            </div>

            <ul className="exam-list civique">
              <li><span className="num">01</span> Principes et valeurs de la République</li>
              <li><span className="num">02</span> Système institutionnel et politique</li>
              <li><span className="num">03</span> Droits et devoirs</li>
              <li><span className="num">04</span> Histoire, géographie et culture</li>
              <li><span className="num">05</span> Vivre dans la société française</li>
            </ul>

            <Link href="/inscription" className="btn exam-cta">
              S&apos;entraîner au civique
              <span className="arrow">→</span>
            </Link>
          </article>

          {/* TCF */}
          <article className="exam-card tcf" id="tcf">
            <span className="exam-tag tcf">TCF IRN</span>
            <h3 className="exam-h3">
              Test de connaissance du français pour l&apos;intégration
            </h3>
            <p className="exam-sub">
              Niveau requis selon votre démarche : A2 pour la CSP, B1 pour la
              CR, B2 pour la naturalisation.
            </p>

            <div className="exam-meta">
              <div className="meta-item">
                <div className="meta-label">CSP</div>
                <div className="meta-value">A2</div>
              </div>
              <div className="meta-item">
                <div className="meta-label">CR</div>
                <div className="meta-value">B1</div>
              </div>
              <div className="meta-item">
                <div className="meta-label">NATURALISATION</div>
                <div className="meta-value">B2</div>
              </div>
            </div>

            <ul className="exam-list tcf">
              <li><span className="num">01</span> Compréhension orale (25 QCM · 20 min)</li>
              <li><span className="num">02</span> Compréhension écrite (25 QCM · 35 min)</li>
              <li><span className="num">03</span> Structure de la langue<span className="bonus">entraînement bonus</span></li>
              <li><span className="num">04</span> Supports authentiques : SMS, e-mails, annonces</li>
              <li><span className="num">05</span> Audios natifs avec accents variés</li>
            </ul>

            <Link href="/inscription" className="btn exam-cta exam-cta-red">
              S&apos;entraîner au TCF
              <span className="arrow">→</span>
            </Link>
          </article>
        </div>
      </div>

      <style>{`
        .exams-sec { padding: 100px 0; background: #fff; }
        .exams-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 24px;
        }
        .exam-card {
          border: 1px solid var(--color-line);
          border-radius: 22px;
          padding: 36px;
          background: #fff;
          position: relative;
          overflow: hidden;
          transition: transform 0.25s, border-color 0.25s;
          display: flex;
          flex-direction: column;
        }
        .exam-card:hover {
          border-color: var(--color-ink);
          transform: translateY(-3px);
        }
        .exam-card.civique {
          background:
            radial-gradient(at 100% 0%, var(--color-blue-light) 0px, transparent 50%),
            #fff;
        }
        .exam-card.tcf {
          background:
            radial-gradient(at 100% 0%, var(--color-red-light) 0px, transparent 50%),
            #fff;
        }
        .exam-tag {
          display: inline-block;
          font-family: var(--font-mono);
          font-size: 10px; letter-spacing: 0.12em;
          color: #fff;
          padding: 5px 10px;
          border-radius: 6px; font-weight: 600;
          margin-bottom: 18px;
          align-self: flex-start;
        }
        .exam-tag.civique { background: var(--color-blue); }
        .exam-tag.tcf { background: var(--color-red); }
        .exam-h3 {
          font-family: var(--font-display);
          font-weight: 600; font-size: 27px;
          line-height: 1.18;
          margin: 0 0 12px;
          letter-spacing: -0.015em;
        }
        .exam-sub {
          color: var(--color-muted);
          font-size: 14.5px;
          margin: 0 0 24px;
          line-height: 1.55;
        }
        .exam-meta {
          display: grid;
          grid-template-columns: 1fr 1fr 1fr;
          gap: 12px;
          margin-bottom: 24px;
        }
        .meta-item {
          padding: 12px;
          border: 1px solid var(--color-line);
          border-radius: 12px;
          background: #fff;
        }
        .meta-label {
          font-family: var(--font-mono);
          font-size: 9px;
          color: var(--color-muted);
          letter-spacing: 0.15em;
          text-transform: uppercase;
          margin-bottom: 4px;
        }
        .meta-value {
          font-size: 14px;
          font-weight: 700;
          color: var(--color-ink);
        }
        .exam-list {
          list-style: none;
          padding: 0;
          margin: 0 0 24px;
          flex: 1;
        }
        .exam-list li {
          padding: 10px 0;
          font-size: 14px;
          color: var(--color-ink-2);
          display: flex; align-items: center; gap: 10px;
          border-top: 1px dashed var(--color-line);
        }
        .exam-list li:first-child { border-top: none; padding-top: 0; }
        .exam-list .num {
          font-family: var(--font-mono);
          font-size: 11px;
          width: 22px; font-weight: 600;
        }
        .exam-list.civique .num { color: var(--color-blue); }
        .exam-list.tcf .num { color: var(--color-red); }
        .exam-list .bonus {
          margin-left: auto;
          font-size: 11.5px;
          color: var(--color-muted);
          font-family: var(--font-mono);
          letter-spacing: 0.05em;
        }
        .exam-cta {
          align-self: flex-start;
        }
        .exam-cta-red {
          background: var(--color-red);
          border-color: var(--color-red);
        }
        .exam-cta-red:hover {
          background: var(--color-red-dark);
          border-color: var(--color-red-dark);
        }
        @media (max-width: 900px) {
          .exams-grid { grid-template-columns: 1fr; }
          .exams-sec { padding: 70px 0; }
        }
      `}</style>
    </section>
  );
}

// ============================================================================
// FEATURES — 6 cells avec icônes
// ============================================================================
export function ProblemSection() {
  // (Conservé sous ce nom pour ne pas casser l'import depuis page.tsx.)
  const feats: {
    tone: "blue" | "red" | "green" | "amber";
    icon: React.ReactNode;
    title: string;
    body: string;
  }[] = [
    {
      tone: "blue",
      icon: <CheckIcon />,
      title: "Correction expliquée",
      body:
        "Après chaque question, on vous explique la règle et pourquoi les autres réponses sont fausses. Une à une.",
    },
    {
      tone: "red",
      icon: <ClockIcon />,
      title: "Examens blancs réalistes",
      body:
        "40 questions, 45 minutes, seuil officiel. La simulation respecte la répartition par thématique du jour J.",
    },
    {
      tone: "green",
      icon: <TrendingIcon />,
      title: "Suivi de progression",
      body:
        "Vos scores par thématique, vos questions favorites, vos erreurs récurrentes. Tout est tracé pour vous concentrer sur l'essentiel.",
    },
    {
      tone: "amber",
      icon: <StarIcon />,
      title: "Révision ciblée",
      body:
        "Une session « mes erreurs » qui ne re-pose que les questions ratées. Pareil pour vos favoris.",
    },
    {
      tone: "blue",
      icon: <DeviceIcon />,
      title: "Web et mobile",
      body:
        "Bossez sur ordinateur à la maison, sur mobile dans le RER. Votre progression vous suit partout, hors-ligne aussi.",
    },
    {
      tone: "red",
      icon: <ShieldIcon />,
      title: "Conformité référentielle",
      body:
        "Les questions civiques suivent les 5 thématiques officielles. Le TCF reproduit fidèlement la structure de l'examen IRN.",
    },
  ];

  return (
    <section className="feats" id="fonctionnalites">
      <div className="container-x">
        <SectionHead
          eyebrow="LA MÉTHODE SEJOURFR"
          sub="Vous apprenez en répondant. Chaque erreur déclenche une explication précise. Vous re-tombez dessus jusqu'à la maîtriser."
        >
          Pas de cours. Que de la <em>pratique active</em>.
        </SectionHead>

        <div className="feats-grid">
          {feats.map((f) => (
            <div className="feat" key={f.title}>
              <div className={`feat-icon feat-${f.tone}`}>{f.icon}</div>
              <h3>{f.title}</h3>
              <p>{f.body}</p>
            </div>
          ))}
        </div>
      </div>

      <style>{`
        .feats {
          background: var(--color-paper);
          border-top: 1px solid var(--color-line);
          border-bottom: 1px solid var(--color-line);
          padding: 100px 0;
        }
        .feats-grid {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 20px;
        }
        .feat {
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 18px;
          padding: 28px;
          transition: border-color 0.2s, transform 0.2s;
        }
        .feat:hover {
          border-color: var(--color-ink);
          transform: translateY(-2px);
        }
        .feat-icon {
          width: 44px; height: 44px;
          border-radius: 12px;
          display: flex; align-items: center; justify-content: center;
          margin-bottom: 18px;
        }
        .feat-blue { background: var(--color-blue-light); color: var(--color-blue); }
        .feat-red { background: var(--color-red-light); color: var(--color-red); }
        .feat-green { background: rgba(22, 143, 91, 0.1); color: var(--color-green); }
        .feat-amber { background: rgba(232, 163, 23, 0.12); color: var(--color-amber); }
        .feat h3 {
          font-family: var(--font-display);
          font-weight: 600; font-size: 20px;
          margin: 0 0 8px;
          letter-spacing: -0.01em;
        }
        .feat p {
          margin: 0; color: var(--color-muted);
          font-size: 14.5px; line-height: 1.55;
        }
        @media (max-width: 900px) {
          .feats-grid { grid-template-columns: 1fr 1fr; }
          .feats { padding: 70px 0; }
        }
        @media (max-width: 600px) {
          .feats-grid { grid-template-columns: 1fr; }
        }
      `}</style>
    </section>
  );
}

function CheckIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}
function ClockIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" />
      <polyline points="12 6 12 12 16 14" />
    </svg>
  );
}
function TrendingIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="23 6 13.5 15.5 8.5 10.5 1 18" />
      <polyline points="17 6 23 6 23 12" />
    </svg>
  );
}
function StarIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}
function DeviceIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="2" y="3" width="20" height="14" rx="2" />
      <line x1="8" y1="21" x2="16" y2="21" />
      <line x1="12" y1="17" x2="12" y2="21" />
    </svg>
  );
}
function ShieldIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
    </svg>
  );
}

// ============================================================================
// HOW IT WORKS — 4 étapes
// ============================================================================
export function HowItWorksSection() {
  const steps = [
    {
      tag: "01 — DÉMARCHE",
      title: "Choisissez votre objectif",
      body:
        "CSP, carte de résident ou naturalisation. On adapte le contenu à votre niveau visé.",
    },
    {
      tag: "02 — ENTRAÎNEMENT",
      title: "Répondez par thématique",
      body:
        "Vous travaillez les sujets à votre rythme. La correction tombe juste après votre réponse.",
    },
    {
      tag: "03 — EXAMEN BLANC",
      title: "Testez-vous en conditions",
      body:
        "40 questions, 45 minutes, sans aide. On vous indique si vous auriez réussi.",
    },
    {
      tag: "04 — RÉVISION",
      title: "Concentrez-vous sur les erreurs",
      body:
        "L'app re-propose les questions ratées jusqu'à ce qu'elles soient acquises.",
    },
  ];

  return (
    <section className="steps-sec">
      <div className="container-x">
        <SectionHead eyebrow="EN 4 ÉTAPES">
          Comment ça <em>marche</em>.
        </SectionHead>

        <div className="steps-grid">
          {steps.map((s) => (
            <div className="step" key={s.tag}>
              <div className="step-num">{s.tag}</div>
              <h4>{s.title}</h4>
              <p>{s.body}</p>
            </div>
          ))}
        </div>
      </div>

      <style>{`
        .steps-sec { padding: 100px 0; background: #fff; }
        .steps-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 20px;
        }
        .step {
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 16px;
          padding: 26px;
          transition: border-color 0.2s, transform 0.2s;
        }
        .step:hover {
          border-color: var(--color-blue);
          transform: translateY(-2px);
        }
        .step-num {
          font-family: var(--font-mono);
          font-size: 11px;
          color: var(--color-blue);
          font-weight: 700;
          letter-spacing: 0.15em;
          margin-bottom: 12px;
        }
        .step h4 {
          font-family: var(--font-display);
          font-weight: 600; font-size: 19px;
          margin: 0 0 8px;
          letter-spacing: -0.01em;
        }
        .step p {
          margin: 0;
          color: var(--color-muted);
          font-size: 14px;
          line-height: 1.55;
        }
        @media (max-width: 900px) {
          .steps-grid { grid-template-columns: 1fr 1fr; }
          .steps-sec { padding: 70px 0; }
        }
        @media (max-width: 560px) {
          .steps-grid { grid-template-columns: 1fr; }
        }
      `}</style>
    </section>
  );
}

// ============================================================================
// PRICING — plans dynamiques depuis le backend
// ============================================================================

const PLAN_PRESENTATION: Record<
  string,
  {
    name: string;
    desc: string;
    features: { label: string; muted?: boolean; strong?: boolean }[];
    cta: { label: string; href: string; variant: "ghost" | "red" | "primary" };
    featured?: boolean;
    badge?: { label: string; tone: "red" | "green" };
  }
> = {
  FREE: {
    name: "DÉCOUVERTE",
    desc: "Un échantillon représentatif pour évaluer la méthode.",
    cta: { label: "Commencer gratuitement", href: "/inscription", variant: "ghost" },
    features: [
      { label: "20 questions par module" },
      { label: "Corrections expliquées" },
      { label: "1 examen blanc par module" },
      { label: "Pas de suivi de progression complet", muted: true },
      { label: "Pas d'accès hors-ligne", muted: true },
    ],
  },
  CIVIQUE_3MOIS: {
    name: "CIVIQUE",
    desc: "Accès complet au module civique. Sans renouvellement.",
    cta: { label: "Choisir Civique", href: "/paiement?plan=CIVIQUE_3MOIS", variant: "primary" },
    features: [
      { label: "Banque complète civique", strong: true },
      { label: "Examens blancs civiques illimités" },
      { label: "Entraînement par thème" },
      { label: "Révision des erreurs et favoris" },
      { label: "Statistiques par thématique" },
      { label: "3 mois d'accès" },
    ],
  },
  INTEGRAL_3MOIS: {
    name: "INTÉGRAL",
    desc: "Civique + TCF IRN. Le plus complet pour CR ou naturalisation.",
    cta: { label: "Passer Intégral", href: "/paiement?plan=INTEGRAL_3MOIS", variant: "primary" },
    featured: true,
    badge: { label: "RECOMMANDÉ", tone: "red" },
    features: [
      { label: "Tout le Civique inclus", strong: true },
      { label: "Module TCF complet (CO + CE + Structure)", strong: true },
      { label: "Diagnostic CECRL (A2 / B1 / B2)" },
      { label: "Examens blancs TCF illimités" },
      { label: "Révision + statistiques" },
      { label: "3 mois d'accès" },
    ],
  },
};

const PLANS_FALLBACK: PlanPublicResponse[] = [
  { code: "FREE", name: "Découverte", billingCycle: "NONE", price: 0, originalPrice: null, moduleAccess: "NONE", durationDays: 0 },
  { code: "CIVIQUE_3MOIS", name: "Civique — 3 mois", billingCycle: "THREE_MONTHS", price: 5.99, originalPrice: 9.99, moduleAccess: "CIVIQUE", durationDays: 90 },
  { code: "INTEGRAL_3MOIS", name: "Intégral — 3 mois", billingCycle: "THREE_MONTHS", price: 14.99, originalPrice: 19.99, moduleAccess: "INTEGRAL", durationDays: 90 },
];

const PLAN_ORDER = ["FREE", "CIVIQUE_3MOIS", "INTEGRAL_3MOIS"];

function formatPrice(value: number): string {
  if (value === 0) return "0";
  if (Number.isInteger(value)) return String(value);
  return value.toFixed(2).replace(".", ",").replace(/,?0+$/, (m) => (m.startsWith(",") ? "" : m));
}

function formatPeriod(plan: PlanPublicResponse): string {
  if (plan.code === "FREE") return "pour toujours";
  if (plan.durationDays >= 30) {
    const months = Math.round(plan.durationDays / 30);
    return `pour ${months} mois`;
  }
  return `pour ${plan.durationDays} jours`;
}

export async function PricingSection() {
  let plans: PlanPublicResponse[];
  try {
    const fetched = await billingApi.listPlans();
    plans = fetched.length > 0 ? fetched : PLANS_FALLBACK;
  } catch {
    plans = PLANS_FALLBACK;
  }

  const sorted = [...plans].sort((a, b) => {
    const ai = PLAN_ORDER.indexOf(a.code);
    const bi = PLAN_ORDER.indexOf(b.code);
    return (ai === -1 ? 99 : ai) - (bi === -1 ? 99 : bi);
  });
  const display = sorted.slice(0, 3);

  return (
    <section id="tarifs" className="pricing-sec">
      <div className="container-x">
        <SectionHead
          eyebrow="TARIFS"
          sub="Pas de carte bancaire pour démarrer. Vous goûtez, vous décidez."
        >
          Commencez <em>gratuitement</em>. Passez Premium quand vous serez
          prêt.
        </SectionHead>

        <div className="plans">
          {display.map((plan) => (
            <PlanCard key={plan.code} plan={plan} />
          ))}
        </div>

        <p className="plans-foot">
          Paiement sécurisé Stripe · TVA incluse · L&apos;accès se termine
          automatiquement à la fin de la période, vous rachetez si besoin.
        </p>
      </div>

      <style>{`
        .pricing-sec {
          background: var(--color-paper);
          border-top: 1px solid var(--color-line);
          border-bottom: 1px solid var(--color-line);
          padding: 100px 0;
        }
        .plans {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 22px;
          max-width: 1100px;
          margin: 0 auto;
        }
        .plans-foot {
          margin: 32px auto 0;
          max-width: 600px;
          text-align: center;
          font-size: 12.5px;
          color: var(--color-muted);
          line-height: 1.6;
        }
        .plan {
          border: 1px solid var(--color-line);
          border-radius: 22px;
          padding: 36px 32px;
          background: #fff;
          position: relative;
          display: flex;
          flex-direction: column;
        }
        .plan.featured {
          border: 2px solid var(--color-blue);
          background:
            radial-gradient(at 0% 0%, var(--color-blue-light) 0px, transparent 50%),
            #fff;
          box-shadow: 0 20px 50px -20px rgba(30, 58, 140, 0.25);
        }
        .plan-badge {
          position: absolute; top: -12px; left: 32px;
          background: var(--color-red); color: #fff;
          font-family: var(--font-mono);
          font-size: 10px;
          padding: 5px 10px; border-radius: 6px;
          letter-spacing: 0.1em; font-weight: 600;
        }
        .plan-badge.green { background: var(--color-green); }
        .plan-name {
          font-family: var(--font-mono);
          font-size: 11px;
          color: var(--color-muted);
          letter-spacing: 0.18em;
          margin-bottom: 16px;
          font-weight: 600;
        }
        .plan-price {
          display: flex; align-items: baseline; gap: 6px;
          margin-bottom: 8px;
        }
        .plan-price .num {
          font-family: var(--font-display);
          font-size: 52px; font-weight: 600;
          color: var(--color-ink);
          letter-spacing: -0.03em;
          line-height: 1;
        }
        .plan-price .num-old {
          font-family: var(--font-display);
          font-size: 22px;
          color: var(--color-muted-2);
          text-decoration: line-through;
          margin-right: 4px;
          align-self: center;
        }
        .plan-price .per {
          font-size: 14px;
          color: var(--color-muted);
        }
        .plan-desc {
          color: var(--color-muted);
          font-size: 14px;
          margin: 0 0 24px;
          min-height: 42px;
        }
        .plan-feat {
          list-style: none; padding: 0;
          margin: 0 0 28px;
          flex: 1;
        }
        .plan-feat li {
          padding: 9px 0;
          font-size: 14px;
          color: var(--color-ink-2);
          display: flex; align-items: flex-start; gap: 10px;
        }
        .plan-feat .tick {
          color: var(--color-green); font-weight: 700; flex-shrink: 0;
        }
        .plan-feat .dash {
          color: var(--color-muted-2); flex-shrink: 0;
        }
        .plan-feat li.muted span:last-child { color: var(--color-muted); }
        .plan-cta {
          width: 100%;
        }
        @media (max-width: 980px) {
          .plans { grid-template-columns: 1fr; max-width: 480px; }
          .pricing-sec { padding: 70px 0; }
        }
      `}</style>
    </section>
  );
}

function PlanCard({ plan }: { plan: PlanPublicResponse }) {
  const preset = PLAN_PRESENTATION[plan.code];
  const name = preset?.name ?? plan.name.toUpperCase();
  const desc = preset?.desc ?? "";
  const cta = preset?.cta ?? {
    label: plan.code === "FREE" ? "Créer mon compte" : "Choisir ce plan",
    href: plan.code === "FREE" ? "/inscription" : `/paiement?plan=${plan.code}`,
    variant: "primary" as const,
  };
  const featured = preset?.featured ?? false;
  const badge = preset?.badge ?? null;
  const features = preset?.features ?? [];

  const btnClass =
    cta.variant === "ghost" ? "btn btn-ghost plan-cta" :
    cta.variant === "red" ? "btn btn-red plan-cta" : "btn plan-cta";

  return (
    <div className={`plan ${featured ? "featured" : ""}`}>
      {badge && (
        <span className={`plan-badge ${badge.tone === "green" ? "green" : ""}`}>
          {badge.label}
        </span>
      )}
      <div className="plan-name">{name}</div>
      <div className="plan-price">
        {plan.originalPrice !== null && plan.originalPrice > plan.price && (
          <span className="num-old">{formatPrice(plan.originalPrice)}€</span>
        )}
        <span className="num">{formatPrice(plan.price)}€</span>
        <span className="per">/ {formatPeriod(plan)}</span>
      </div>
      <p className="plan-desc">{desc}</p>
      <ul className="plan-feat">
        {features.map((f, i) => (
          <li key={i} className={f.muted ? "muted" : ""}>
            <span className={f.muted ? "dash" : "tick"}>
              {f.muted ? "—" : "✓"}
            </span>
            <span>{f.strong ? <strong>{f.label}</strong> : f.label}</span>
          </li>
        ))}
      </ul>
      <Link href={cta.href} className={btnClass}>
        {cta.label}
      </Link>
    </div>
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
    <section id="temoignages" className="testi-sec">
      <div className="container-x">
        <SectionHead eyebrow="TÉMOIGNAGES">
          Ils ont réussi <em>avec SejourFR</em>.
        </SectionHead>

        <div className="testi-grid">
          {testimonials.map((t) => (
            <div className="testi-card" key={t.name}>
              <span className="quote-mark">&ldquo;</span>
              <p className="testi-body">{t.body}</p>
              <div className="testi-foot">
                <div className={`testi-avatar ${t.cls}`}>{t.initials}</div>
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
        .testi-sec { padding: 100px 0; background: #fff; }
        .testi-grid {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 20px;
        }
        .testi-card {
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 18px;
          padding: 30px 28px;
          display: flex; flex-direction: column;
          position: relative;
          transition: border-color 0.2s, transform 0.2s;
        }
        .testi-card:hover {
          border-color: var(--color-blue);
          transform: translateY(-2px);
        }
        .quote-mark {
          position: absolute; top: 12px; right: 22px;
          font-family: var(--font-display);
          font-size: 64px; line-height: 1;
          color: var(--color-blue-light); font-weight: 600;
        }
        .testi-body {
          font-family: var(--font-display);
          font-weight: 500;
          font-size: 17px;
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
        .testi-avatar {
          width: 42px; height: 42px; border-radius: 50%;
          display: flex; align-items: center; justify-content: center;
          color: #fff; font-weight: 700; font-size: 13px;
          flex-shrink: 0;
          background: linear-gradient(135deg, var(--color-blue), var(--color-red));
        }
        .testi-avatar.r { background: linear-gradient(135deg, var(--color-red), var(--color-amber)); }
        .testi-avatar.g { background: linear-gradient(135deg, var(--color-green), var(--color-blue)); }
        .testi-name { font-weight: 700; font-size: 14px; color: var(--color-ink); }
        .testi-meta {
          font-size: 11.5px; color: var(--color-muted);
          font-family: var(--font-mono);
          letter-spacing: 0.06em;
          margin-top: 2px;
        }
        @media (max-width: 960px) {
          .testi-grid { grid-template-columns: 1fr; }
          .testi-sec { padding: 70px 0; }
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
          Oui, depuis le 1<sup>er</sup> janvier 2026, il est requis pour la
          délivrance de la carte de séjour pluriannuelle, de la carte de
          résident et pour la naturalisation. Le contenu varie selon la
          démarche : SejourFR adapte automatiquement le niveau de difficulté.
        </>
      ),
      open: true,
    },
    {
      q: "Quelle est la différence entre le TCF et le TCF IRN ?",
      a: "Le TCF IRN (Intégration · Résidence · Nationalité) est la version utilisée pour les démarches administratives en France. Il comprend 4 épreuves : compréhension orale, compréhension écrite, expression orale et expression écrite. SejourFR vous prépare aux deux épreuves de QCM (CO et CE).",
    },
    {
      q: "Puis-je m'entraîner sans connexion internet ?",
      a: "Oui, sur mobile. L'app Flutter télécharge la banque de questions en local et synchronise votre progression dès qu'une connexion est disponible. Pratique dans les transports.",
    },
    {
      q: "Combien de temps faut-il pour être prêt ?",
      a: "Cela dépend de votre niveau de départ. La plupart des candidats atteignent le seuil de 32/40 à l'examen civique après 3 à 6 semaines d'entraînement régulier (15 à 30 minutes par jour). Le TCF demande plus de temps, surtout pour viser le B2.",
    },
    {
      q: "Les questions sont-elles celles de l'examen officiel ?",
      a: "Non. SejourFR n'utilise pas les questions officielles (qui sont confidentielles). Nos questions sont conçues d'après les référentiels publics et reproduisent fidèlement le format, la difficulté et les thématiques de l'examen.",
    },
    {
      q: "Puis-je résilier à tout moment ?",
      a: "Nos abonnements sont à paiement unique 3 mois, sans renouvellement automatique. Vous ne pouvez pas être prélevé par surprise — vous rachetez seulement si vous voulez prolonger.",
    },
  ];

  return (
    <section id="faq" className="faq-sec">
      <div className="container-x">
        <SectionHead eyebrow="QUESTIONS FRÉQUENTES">
          On vous a peut-être <em>déjà répondu</em>.
        </SectionHead>

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
        .faq-sec { padding: 100px 0; background: #fff; }
        .faq-list { max-width: 780px; margin: 0 auto; }
        .faq-item {
          border-bottom: 1px solid var(--color-line);
          padding: 22px 0;
        }
        .faq-item summary {
          font-family: var(--font-display);
          font-size: 19px; font-weight: 500;
          color: var(--color-ink);
          cursor: pointer;
          list-style: none;
          display: flex; justify-content: space-between; align-items: center;
          gap: 16px;
          letter-spacing: -0.01em;
        }
        .faq-item summary::-webkit-details-marker { display: none; }
        .faq-item summary::after {
          content: '+';
          font-family: var(--font-mono);
          font-size: 22px; color: var(--color-blue);
          transition: transform 0.25s;
        }
        .faq-item[open] summary::after { content: '−'; }
        .faq-item p {
          color: var(--color-muted);
          margin: 12px 0 0;
          font-size: 15px;
          line-height: 1.6;
        }
        @media (max-width: 600px) {
          .faq-sec { padding: 70px 0; }
          .faq-item summary { font-size: 17px; }
        }
      `}</style>
    </section>
  );
}

// ============================================================================
// FINAL CTA — bandeau bleu sombre avec halos
// ============================================================================
export function FinalCtaSection() {
  return (
    <section className="finalcta-wrap">
      <div className="container-x">
        <div className="cta-block">
          <h2>
            Votre <em>titre de séjour</em> ne devrait pas dépendre d&apos;un
            coup de chance.
          </h2>
          <p>
            Démarrez aujourd&apos;hui. Les premières questions sont gratuites,
            sans inscription longue, sans carte bancaire.
          </p>
          <Link href="/inscription" className="btn btn-lg cta-block-btn">
            Commencer maintenant <span className="arrow">→</span>
          </Link>
        </div>
      </div>

      <style>{`
        .finalcta-wrap {
          padding: 60px 0 100px;
          background: #fff;
        }
        .cta-block {
          background: var(--color-blue);
          border-radius: 28px;
          padding: 60px 50px;
          color: #fff;
          position: relative;
          overflow: hidden;
          background-image:
            radial-gradient(at 100% 0%, var(--color-blue-dark) 0px, transparent 40%),
            radial-gradient(at 0% 100%, rgba(225, 55, 47, 0.55) 0px, transparent 35%);
        }
        .cta-block h2 {
          font-family: var(--font-display);
          font-weight: 600;
          font-size: clamp(28px, 4vw, 40px);
          line-height: 1.15;
          margin: 0 0 14px;
          letter-spacing: -0.02em;
          max-width: 580px;
        }
        .cta-block h2 em {
          color: #FFB3B0;
          font-style: italic;
          font-weight: 500;
        }
        .cta-block p {
          color: rgba(255,255,255,0.82);
          margin: 0 0 28px;
          font-size: 16px;
          max-width: 540px;
          line-height: 1.55;
        }
        .cta-block-btn {
          background: #fff;
          color: var(--color-blue);
          border-color: #fff;
        }
        .cta-block-btn:hover {
          background: var(--color-paper);
          border-color: var(--color-paper);
        }
        @media (max-width: 720px) {
          .finalcta-wrap { padding: 40px 0 70px; }
          .cta-block { padding: 40px 28px; }
        }
      `}</style>
    </section>
  );
}
