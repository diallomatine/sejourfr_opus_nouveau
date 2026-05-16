"use client";

import Link from "next/link";
import {
  ArrowRight,
  BookOpen,
  CheckCircle2,
  Crown,
  Infinity as InfinityIcon,
  Layers,
  Lock,
  Play,
  Sparkles,
  Trophy,
} from "lucide-react";
import { useAuth } from "@/lib/auth-context";
import { SITE } from "@/lib/site";
import {
  TOTAL_MOCK_EXAMS,
  getCategories,
  type LandingCategory,
  type LandingModuleType,
} from "@/lib/modules-data";

interface Props {
  moduleType: LandingModuleType;
  basePath: string;
  /** Titre du module (ex: "Examen civique"). */
  title: string;
  /** Sous-titre court. */
  subtitle: string;
  /** Mention contextuelle ("Pour le titre de séjour pluriannuel", etc.). */
  context: string;
  /** Couleur d'accent (utilisée pour le hero). */
  accent: "blue" | "red";
}

/**
 * Landing publique d'un module (Civique ou Naturalisation).
 *
 * Source du contenu : `lib/modules-data.ts` (catégories statiques alignées
 * sur le seed Flyway). Les pages utilisateur connecté restent gérées par
 * le route group `(app)/entrainement` qui appelle l'API auth.
 *
 * Adaptation du portage : suppression des CTA vers les examens blancs
 * (le projet a recentré la vitrine sur l'inscription puis le passage premium).
 */
export function ModuleLanding({
  moduleType,
  basePath,
  title,
  subtitle,
  context,
  accent,
}: Props) {
  const { user, status } = useAuth();
  const isPremium = !!user?.isPremium;
  const isAuthenticated = status === "authenticated";
  const inApp = isAuthenticated;
  const free = SITE.freeQuestionsPerCategory;

  const categories = getCategories(moduleType);
  const totalCategories = categories.length;
  const totalQuestions = categories.reduce((s, c) => s + c.questionCount, 0);
  const totalSimulations = TOTAL_MOCK_EXAMS;

  const heroSubcopy = isAuthenticated
    ? "40 questions · 30 min · conditions réelles"
    : "1er examen blanc gratuit · sans inscription";

  return (
    <div className={`mod-landing mod-accent-${accent}`}>
      <div className="container-x mod-wrap">
        {inApp ? (
          <HeroApp
            title={title}
            subtitle={subtitle}
            context={context}
            totalCategories={totalCategories}
            totalQuestions={totalQuestions}
            totalSimulations={totalSimulations}
          />
        ) : (
          <HeroMarketing
            title={title}
            subtitle={subtitle}
            context={context}
            totalCategories={totalCategories}
            totalQuestions={totalQuestions}
            totalSimulations={totalSimulations}
            heroSubcopy={heroSubcopy}
          />
        )}

        {!isPremium && (
          <div className="mod-section mod-fade">
            <PremiumBanner
              totalQuestions={totalQuestions}
              freePerCategory={free}
            />
          </div>
        )}

        <section className="mod-section">
          <header className="mod-section-head">
            <div>
              <h2 className="mod-section-title">Catégories d&apos;entraînement</h2>
              <p className="mod-section-sub">
                {isPremium
                  ? "Accès illimité à toutes les questions de chaque catégorie."
                  : `Aperçu gratuit de ${free} questions par catégorie · Premium pour les ${totalQuestions} au total.`}
              </p>
            </div>
          </header>

          <div className="mod-grid">
            {categories.map((c, idx) => (
              <CategoryTile
                key={c.id}
                category={c}
                basePath={basePath}
                isPremium={isPremium}
                free={free}
                index={idx}
              />
            ))}
          </div>
        </section>

        {!isPremium && (
          <section className="mod-section mod-advantages">
            <div className="mod-advantages-grid">
              <Advantage
                icon={InfinityIcon}
                title="Toutes les questions"
                description={`${totalQuestions} questions débloquées contre ${free} par catégorie en gratuit.`}
              />
              <Advantage
                icon={Trophy}
                title="20 examens blancs"
                description="40 questions chronométrées comme le jour J, score et bilan détaillé après chaque tentative."
              />
              <Advantage
                icon={Sparkles}
                title="Stats avancées"
                description="Suivi de progression, perf par catégorie, badges, recommandations intelligentes."
              />
            </div>
          </section>
        )}
      </div>

      <style>{`
        .mod-landing {
          --accent: var(--color-blue);
          --accent-2: var(--color-blue-dark);
          --accent-soft: var(--color-blue-soft);
          padding: 40px 0 80px;
        }
        .mod-landing.mod-accent-red {
          --accent: var(--color-red);
          --accent-2: var(--color-red-dark);
          --accent-soft: var(--color-red-light);
        }
        .mod-wrap { display: flex; flex-direction: column; }
        .mod-section { margin-top: 32px; }
        .mod-section:first-of-type { margin-top: 0; }
        .mod-fade {
          animation: mod-fade-in 0.45s ease-out both;
          animation-delay: 0.05s;
        }
        @keyframes mod-fade-in {
          from { opacity: 0; transform: translateY(8px); }
          to { opacity: 1; transform: translateY(0); }
        }

        .mod-section-head {
          display: flex; align-items: flex-end; justify-content: space-between;
          gap: 12px;
          margin-bottom: 18px;
        }
        .mod-section-title {
          font-family: var(--font-display);
          font-weight: 500;
          font-size: 26px;
          letter-spacing: -0.02em;
          color: var(--color-blue);
          line-height: 1.1;
        }
        .mod-landing.mod-accent-red .mod-section-title {
          color: var(--color-red-dark);
        }
        .mod-section-sub {
          margin-top: 6px;
          font-size: 14px;
          color: var(--color-muted);
          line-height: 1.5;
          max-width: 640px;
        }

        .mod-grid {
          display: grid;
          grid-template-columns: repeat(3, minmax(0, 1fr));
          gap: 16px;
        }
        @media (max-width: 1000px) {
          .mod-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
        }
        @media (max-width: 620px) {
          .mod-grid { grid-template-columns: 1fr; }
        }

        .mod-advantages { margin-top: 48px; }
        .mod-advantages-grid {
          display: grid;
          grid-template-columns: repeat(3, minmax(0, 1fr));
          gap: 16px;
        }
        @media (max-width: 900px) {
          .mod-advantages-grid { grid-template-columns: 1fr; }
        }

        @media (max-width: 720px) {
          .mod-section-title { font-size: 22px; }
          .mod-landing { padding: 28px 0 60px; }
          .mod-section { margin-top: 28px; }
        }
      `}</style>
    </div>
  );
}

/* ---------------------------------------------------------------- */
/*  Hero marketing (visiteur non connecté)                          */
/* ---------------------------------------------------------------- */
function HeroMarketing({
  title,
  subtitle,
  context,
  totalCategories,
  totalQuestions,
  totalSimulations,
  heroSubcopy,
}: {
  title: string;
  subtitle: string;
  context: string;
  totalCategories: number;
  totalQuestions: number;
  totalSimulations: number;
  heroSubcopy: string;
}) {
  return (
    <section className="hero-mkt mod-fade">
      <span aria-hidden className="hero-mkt-glow" />
      <div className="hero-mkt-grid">
        <div className="hero-mkt-main">
          <div className="hero-mkt-eyebrow">{context}</div>
          <h1 className="hero-mkt-title">{title}</h1>
          <p className="hero-mkt-subtitle">{subtitle}</p>
          <div className="hero-mkt-stats">
            <Stat icon={Layers} value={totalCategories} label="catégories" />
            <Stat icon={BookOpen} value={totalQuestions} label="questions" />
            <Stat icon={Trophy} value={totalSimulations} label="examens blancs" />
          </div>
        </div>
        <div className="hero-mkt-cta">
          <Link href="/inscription" className="btn btn-lg hero-mkt-btn">
            Créer un compte gratuit
            <ArrowRight className="arrow" size={16} />
          </Link>
          <span className="hero-mkt-cta-note">{heroSubcopy}</span>
        </div>
      </div>

      <style>{`
        .hero-mkt {
          position: relative;
          overflow: hidden;
          border-radius: 24px;
          color: #fff;
          padding: 40px;
          background: linear-gradient(135deg, var(--accent), var(--accent-2));
          margin-bottom: 32px;
        }
        .hero-mkt-glow {
          position: absolute;
          top: -50%; right: -15%;
          width: 420px; height: 420px;
          border-radius: 50%;
          pointer-events: none;
          background: radial-gradient(circle, rgba(255,255,255,0.18), transparent 70%);
        }
        .hero-mkt-grid {
          position: relative;
          display: grid;
          grid-template-columns: 1fr auto;
          gap: 24px;
          align-items: center;
        }
        .hero-mkt-main { min-width: 0; }
        .hero-mkt-eyebrow {
          font-family: var(--font-mono);
          font-size: 11px;
          letter-spacing: 0.18em;
          text-transform: uppercase;
          font-weight: 500;
          opacity: 0.85;
          margin-bottom: 10px;
        }
        .hero-mkt-title {
          font-family: var(--font-display);
          font-weight: 600;
          font-size: 40px;
          letter-spacing: -0.025em;
          line-height: 1.05;
        }
        .hero-mkt-subtitle {
          margin-top: 14px;
          font-size: 15.5px;
          line-height: 1.55;
          opacity: 0.92;
          max-width: 580px;
        }
        .hero-mkt-stats {
          margin-top: 22px;
          display: flex;
          flex-wrap: wrap;
          column-gap: 28px;
          row-gap: 10px;
          font-size: 14px;
        }
        .hero-mkt-cta {
          display: flex;
          flex-direction: column;
          align-items: flex-end;
          gap: 8px;
        }
        .hero-mkt-btn {
          background: #fff !important;
          color: var(--accent) !important;
          border-color: #fff !important;
        }
        .hero-mkt-btn:hover {
          background: rgba(255,255,255,0.92) !important;
          color: var(--accent-2) !important;
        }
        .hero-mkt-cta-note {
          font-size: 11.5px;
          opacity: 0.85;
          text-align: right;
        }
        @media (max-width: 760px) {
          .hero-mkt { padding: 28px 22px; border-radius: 20px; }
          .hero-mkt-grid { grid-template-columns: 1fr; }
          .hero-mkt-title { font-size: 30px; }
          .hero-mkt-cta { align-items: stretch; }
          .hero-mkt-cta-note { text-align: left; }
          .hero-mkt-btn { width: 100%; }
        }
      `}</style>
    </section>
  );
}

/* ---------------------------------------------------------------- */
/*  Hero in-app (utilisateur connecté)                              */
/* ---------------------------------------------------------------- */
function HeroApp({
  title,
  subtitle,
  context,
  totalCategories,
  totalQuestions,
  totalSimulations,
}: {
  title: string;
  subtitle: string;
  context: string;
  totalCategories: number;
  totalQuestions: number;
  totalSimulations: number;
}) {
  return (
    <section className="hero-app mod-fade">
      <span aria-hidden className="hero-app-glow" />
      <div className="hero-app-inner">
        <div className="hero-app-eyebrow">{context}</div>
        <h2 className="hero-app-title">{title}</h2>
        <p className="hero-app-subtitle">{subtitle}</p>
        <div className="hero-app-stats">
          <Stat icon={Layers} value={totalCategories} label="catégories" />
          <Stat icon={BookOpen} value={totalQuestions} label="questions" />
          <Stat icon={Trophy} value={totalSimulations} label="examens blancs" />
        </div>
      </div>

      <style>{`
        .hero-app {
          position: relative;
          overflow: hidden;
          border-radius: 18px;
          color: #fff;
          padding: 26px 28px;
          background: linear-gradient(135deg, var(--accent), var(--accent-2));
          margin-bottom: 24px;
        }
        .hero-app-glow {
          position: absolute;
          top: -50%; right: -20%;
          width: 300px; height: 300px;
          border-radius: 50%;
          pointer-events: none;
          background: radial-gradient(circle, rgba(255,255,255,0.18), transparent 70%);
        }
        .hero-app-inner { position: relative; min-width: 0; }
        .hero-app-eyebrow {
          font-family: var(--font-mono);
          font-size: 10px;
          letter-spacing: 0.15em;
          text-transform: uppercase;
          font-weight: 500;
          opacity: 0.85;
          margin-bottom: 8px;
        }
        .hero-app-title {
          font-family: var(--font-display);
          font-weight: 500;
          font-size: 26px;
          letter-spacing: -0.01em;
          line-height: 1.15;
        }
        .hero-app-subtitle {
          margin-top: 8px;
          font-size: 14px;
          opacity: 0.92;
          line-height: 1.5;
          max-width: 580px;
        }
        .hero-app-stats {
          margin-top: 16px;
          display: flex;
          flex-wrap: wrap;
          column-gap: 22px;
          row-gap: 6px;
          font-size: 12.5px;
          opacity: 0.92;
        }
        @media (max-width: 620px) {
          .hero-app { padding: 22px; }
          .hero-app-title { font-size: 22px; }
        }
      `}</style>
    </section>
  );
}

/* ---------------------------------------------------------------- */
/*  Petits composants                                               */
/* ---------------------------------------------------------------- */
function Stat({
  icon: Icon,
  value,
  label,
}: {
  icon: React.ComponentType<{ size?: number; className?: string }>;
  value: number;
  label: string;
}) {
  return (
    <span className="stat">
      <Icon size={16} className="stat-icon" />
      <span className="stat-value">{value}</span>
      <span className="stat-label">{label}</span>

      <style>{`
        .stat {
          display: inline-flex;
          align-items: center;
          gap: 6px;
        }
        .stat-icon { opacity: 0.85; }
        .stat-value {
          font-family: var(--font-mono);
          font-weight: 600;
          font-variant-numeric: tabular-nums;
        }
        .stat-label { opacity: 0.85; }
      `}</style>
    </span>
  );
}

function PremiumBanner({
  totalQuestions,
  freePerCategory,
}: {
  totalQuestions: number;
  freePerCategory: number;
}) {
  return (
    <div className="pm-banner">
      <div className="pm-banner-icon" aria-hidden>
        <Crown size={28} />
      </div>
      <div className="pm-banner-body">
        <div className="pm-banner-head">
          <Crown size={16} className="pm-banner-icon-mobile" aria-hidden />
          <span className="pm-banner-label">Compte gratuit</span>
          <span className="pm-banner-pill">Limité</span>
        </div>
        <p className="pm-banner-text">
          Vous voyez <strong>{freePerCategory} questions par catégorie</strong>.
          Premium débloque les {totalQuestions} questions et les{" "}
          <strong>20 examens blancs</strong>.
        </p>
      </div>
      <Link href="/#tarifs" className="btn pm-banner-cta">
        <Crown size={16} />
        Passer Premium · {SITE.premiumPriceLabel}
      </Link>

      <style>{`
        .pm-banner {
          position: relative;
          display: grid;
          grid-template-columns: auto 1fr auto;
          gap: 20px;
          align-items: center;
          padding: 22px 24px;
          border-radius: 18px;
          border: 1px solid #F4D89E;
          background: linear-gradient(135deg, #FFF7E0, #FCEDC8);
        }
        .pm-banner-icon {
          width: 56px; height: 56px;
          border-radius: 16px;
          display: inline-flex;
          align-items: center; justify-content: center;
          background: linear-gradient(135deg, #F4B83A, #C9870D);
          color: #fff;
          flex-shrink: 0;
        }
        .pm-banner-icon-mobile { display: none; color: #B27500; }
        .pm-banner-body { min-width: 0; }
        .pm-banner-head {
          display: flex;
          align-items: center;
          gap: 8px;
          margin-bottom: 4px;
        }
        .pm-banner-label {
          font-weight: 700;
          color: #6F4500;
        }
        .pm-banner-pill {
          font-family: var(--font-mono);
          font-size: 10px;
          letter-spacing: 0.12em;
          text-transform: uppercase;
          font-weight: 600;
          padding: 3px 8px;
          border-radius: 5px;
          background: rgba(180, 120, 0, 0.18);
          color: #7A4F00;
        }
        .pm-banner-text {
          font-size: 13.5px;
          color: #5A3B00;
          line-height: 1.5;
        }
        .pm-banner-text strong { color: #3D2700; font-weight: 700; }
        .pm-banner-cta { white-space: nowrap; }

        @media (max-width: 760px) {
          .pm-banner {
            grid-template-columns: 1fr;
            padding: 18px;
          }
          .pm-banner-icon { display: none; }
          .pm-banner-icon-mobile { display: inline-flex; }
          .pm-banner-cta { width: 100%; }
        }
      `}</style>
    </div>
  );
}

function CategoryTile({
  category,
  basePath,
  isPremium,
  free,
  index,
}: {
  category: LandingCategory;
  basePath: string;
  isPremium: boolean;
  free: number;
  index: number;
}) {
  const total = category.questionCount;
  const visible = isPremium ? total : Math.min(free, total);
  const locked = !isPremium && total > free;
  const delay = Math.min(index * 0.05, 0.3);

  return (
    <Link
      href={`${basePath}/${category.slug}`}
      className="ct-link"
      style={{ animationDelay: `${delay}s` }}
    >
      <article className="ct-card">
        <header className="ct-head">
          <div className="ct-emoji" aria-hidden>{category.emoji}</div>
          {locked ? (
            <span className="ct-badge ct-badge-amber">
              <Lock size={12} /> Premium
            </span>
          ) : isPremium ? (
            <span className="ct-badge ct-badge-green">
              <CheckCircle2 size={12} /> Tout débloqué
            </span>
          ) : (
            <span className="ct-badge ct-badge-blue">Gratuit</span>
          )}
        </header>

        <div className="ct-body">
          <h3 className="ct-title">{category.name}</h3>
          <p className="ct-desc">{category.description}</p>
        </div>

        <footer className="ct-foot">
          <div className="ct-count">
            {locked ? (
              <>
                <span className="ct-count-strong">{visible}</span>
                <span> sur </span>
                <span className="ct-count-strong">{total}</span>
                <span> questions</span>
              </>
            ) : (
              <>
                <span className="ct-count-strong">{total}</span>
                <span> question{total > 1 ? "s" : ""}</span>
              </>
            )}
          </div>
          <span className="ct-go">
            <Play size={13} />
            S&apos;entraîner
            <ArrowRight size={12} />
          </span>
        </footer>
      </article>

      <style>{`
        .ct-link {
          display: block;
          height: 100%;
          text-decoration: none;
          color: inherit;
          opacity: 0;
          animation: ct-in 0.3s ease-out both;
        }
        @keyframes ct-in {
          from { opacity: 0; transform: translateY(8px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .ct-card {
          display: flex;
          flex-direction: column;
          height: 100%;
          gap: 12px;
          padding: 20px;
          border-radius: 16px;
          background: #fff;
          border: 1px solid var(--color-line);
          transition: all 0.18s ease;
          box-shadow: 0 2px 12px -6px rgba(15, 24, 57, 0.06);
        }
        .ct-link:hover .ct-card {
          border-color: var(--accent);
          transform: translateY(-2px);
          box-shadow: 0 12px 28px -16px rgba(15, 24, 57, 0.18);
        }
        .ct-link:hover .ct-go { transform: translateX(2px); }

        .ct-head {
          display: flex;
          align-items: flex-start;
          justify-content: space-between;
          gap: 12px;
        }
        .ct-emoji { font-size: 30px; line-height: 1; }

        .ct-badge {
          display: inline-flex;
          align-items: center;
          gap: 4px;
          font-family: var(--font-mono);
          font-size: 10px;
          letter-spacing: 0.1em;
          text-transform: uppercase;
          font-weight: 600;
          padding: 4px 8px;
          border-radius: 6px;
          white-space: nowrap;
        }
        .ct-badge-amber {
          background: rgba(232, 163, 23, 0.14);
          color: #946100;
        }
        .ct-badge-green {
          background: rgba(22, 143, 91, 0.14);
          color: var(--color-green);
        }
        .ct-badge-blue {
          background: var(--color-blue-light);
          color: var(--color-blue);
        }

        .ct-body { min-width: 0; }
        .ct-title {
          font-weight: 700;
          font-size: 15.5px;
          color: var(--color-blue);
          line-height: 1.25;
          margin: 0;
        }
        .mod-accent-red .ct-title { color: var(--color-red-dark); }
        .ct-desc {
          font-size: 13px;
          color: var(--color-muted);
          margin-top: 4px;
          line-height: 1.45;
          display: -webkit-box;
          -webkit-line-clamp: 2;
          -webkit-box-orient: vertical;
          overflow: hidden;
        }

        .ct-foot {
          margin-top: auto;
          padding-top: 12px;
          border-top: 1px solid var(--color-line-2);
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 8px;
        }
        .ct-count {
          font-size: 12px;
          color: var(--color-muted);
        }
        .ct-count-strong {
          font-family: var(--font-mono);
          font-weight: 600;
          font-variant-numeric: tabular-nums;
          color: var(--color-ink);
        }
        .ct-go {
          display: inline-flex;
          align-items: center;
          gap: 5px;
          font-size: 12px;
          font-weight: 600;
          color: var(--accent);
          transition: transform 0.18s ease;
        }
      `}</style>
    </Link>
  );
}

function Advantage({
  icon: Icon,
  title,
  description,
}: {
  icon: React.ComponentType<{ size?: number; className?: string }>;
  title: string;
  description: string;
}) {
  return (
    <div className="adv">
      <div className="adv-icon" aria-hidden>
        <Icon size={20} />
      </div>
      <div className="adv-title">{title}</div>
      <p className="adv-desc">{description}</p>

      <style>{`
        .adv {
          padding: 22px;
          border-radius: 18px;
          background: #fff;
          border: 1px solid var(--color-line);
        }
        .adv-icon {
          width: 40px; height: 40px;
          border-radius: 12px;
          display: inline-flex;
          align-items: center; justify-content: center;
          background: var(--accent-soft);
          color: var(--accent);
          margin-bottom: 14px;
        }
        .adv-title {
          font-weight: 700;
          font-size: 15px;
          color: var(--color-ink);
        }
        .adv-desc {
          margin-top: 6px;
          font-size: 13.5px;
          color: var(--color-muted);
          line-height: 1.5;
        }
      `}</style>
    </div>
  );
}
