"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { Info, Lightbulb, Target, Waves } from "lucide-react";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { ExamsGrid } from "@/app/_components/hub/DetailParts";
import {
  ApiException,
  attemptApi,
  publicAttemptApi,
  publicExamApi,
} from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  type AttemptSummaryResponse,
  canAccessModule,
  type ExamTemplateSummary,
  isProductionAttempt,
  type Module as ModuleEnum,
} from "@/lib/types";

const SLOTS = 20;
const COLLAPSED = 8;

/** Templates de référence des examens complets (briefing + lancement). */
const TCF_FULL_EXAM_SLUG = "tcf-mix-01";
const CIVIQUE_FULL_EXAM_SLUG = "civique-decouverte";

/**
 * /examens-blancs (maquette sejour_fr.html) : « Examens blancs complets » —
 * une grande card par parcours (TCF IRN 60 Q mélangées · Examen civique 40 Q
 * stratifiées tous thèmes) avec stats, 20 épreuves repliées à 8 (+ Voir tout).
 * Épreuve 1 gratuite, 2+ premium. Les guests gardent la page démo.
 */
export default function ExamensBlancsHomePage() {
  const { status } = useAuth();
  if (status === "loading") return <HomeSkeleton />;
  if (status === "guest") return <ExamsGuestHome />;
  return (
    <DualChromeShell>
      <ExamsConnectedHome />
    </DualChromeShell>
  );
}

function ExamsConnectedHome() {
  const router = useRouter();
  const { user, status } = useAuth();

  const [civique, setCivique] = useState<AttemptSummaryResponse[]>([]);
  const [tcf, setTcf] = useState<AttemptSummaryResponse[]>([]);
  const [paywallModule, setPaywallModule] = useState<"CIVIQUE" | "INTEGRAL" | null>(null);

  useEffect(() => {
    if (status !== "authenticated") return;
    let cancelled = false;
    Promise.allSettled([
      attemptApi.listMine({ type: "MOCK_EXAM", module: "CIVIQUE", limit: 100 }),
      attemptApi.listMine({ type: "MOCK_EXAM", module: "TCF", limit: 100 }),
    ]).then(([c, t]) => {
      if (cancelled) return;
      if (c.status === "fulfilled") {
        // Examens complets uniquement (40 Q tous thèmes) : on écarte les
        // examens thématiques (lotThemeId non null). Ordre chronologique.
        setCivique(
          c.value
            .filter((a) => a.finishedAt && !a.lotThemeId)
            .sort((a, b) => a.startedAt.localeCompare(b.startedAt)),
        );
      }
      if (t.status === "fulfilled") {
        // Examens TCF complets (60 Q mélangées) : on écarte les examens
        // module (CO/CE/Structure) et les productions / TCF_COMPLET.
        setTcf(
          t.value
            .filter(
              (a) =>
                a.finishedAt &&
                !a.moduleExamQuestionType &&
                !isProductionAttempt(a) &&
                a.totalQuestions != null,
            )
            .sort((a, b) => a.startedAt.localeCompare(b.startedAt)),
        );
      }
    });
    return () => {
      cancelled = true;
    };
  }, [status]);

  // Démarrer/Refaire passe par la page briefing du template de référence
  // (règles, déroulé, dernier score) — c'est elle qui crée l'attempt.
  function start(module: ModuleEnum) {
    router.push(
      module === "TCF"
        ? `/examens-blancs/${TCF_FULL_EXAM_SLUG}`
        : `/examens-blancs/${CIVIQUE_FULL_EXAM_SLUG}`,
    );
  }

  if (status === "loading" || !user) return <HomeSkeleton />;

  const tcfPremium = canAccessModule(user, "TCF");
  const civiquePremium = canAccessModule(user, "CIVIQUE");

  return (
    <main className="ebh">
      <header className="ebh-head">
        <div className="ebh-eyebrow">
          <Target size={16} aria-hidden />
          <span>Conditions réelles</span>
        </div>
        <h1>Examens blancs complets</h1>
        <p>
          Une épreuve entière par parcours, qui mélange tous les thèmes.
          Retrouvez les examens déjà passés et leur score, ou lancez-en un
          nouveau.
        </p>
      </header>

      <ModuleExamsSection
        tone="red"
        icon={<Waves size={22} strokeWidth={1.8} />}
        title="TCF IRN"
        chip="3 épreuves mélangées"
        brewLine="Brasse toutes les épreuves QCM : Compréhension orale · Compréhension écrite · Structure de la langue."
        exams={tcf}
        scoreOutOf={60}
        premium={tcfPremium}
        starting={false}
        onStart={() => start("TCF")}
        onLocked={() => setPaywallModule("INTEGRAL")}
      />

      <ModuleExamsSection
        tone="blue"
        icon={<Lightbulb size={22} strokeWidth={1.8} />}
        title="Examen civique"
        chip="5 catégories mélangées"
        brewLine="Brasse tous les thèmes : Principes et valeurs de la République · Système institutionnel et politique · Droits et devoirs · Histoire, géographie et culture · Vivre dans la société française."
        exams={civique}
        scoreOutOf={40}
        premium={civiquePremium}
        starting={false}
        onStart={() => start("CIVIQUE")}
        onLocked={() => setPaywallModule("CIVIQUE")}
      />

      <PaywallSheet
        open={paywallModule !== null}
        onClose={() => setPaywallModule(null)}
        module={paywallModule ?? "CIVIQUE"}
      />

      <style>{styles}</style>
    </main>
  );
}

// ============================================================================
// SECTION MODULE — card TCF IRN / Examen civique
// ============================================================================
function ModuleExamsSection({
  tone,
  icon,
  title,
  chip,
  brewLine,
  exams,
  scoreOutOf,
  premium,
  starting,
  onStart,
  onLocked,
}: {
  tone: "blue" | "red";
  icon: React.ReactNode;
  title: string;
  chip: string;
  brewLine: string;
  exams: AttemptSummaryResponse[];
  scoreOutOf: number;
  premium: boolean;
  starting: boolean;
  onStart: () => void;
  onLocked: () => void;
}) {
  const done = Math.min(exams.length, SLOTS);
  const best = exams.reduce((max, a) => Math.max(max, a.score ?? 0), 0);
  const sub =
    done > 0
      ? `${done}/${SLOTS} épreuves passées · meilleur ${best}/${scoreOutOf}`
      : `${SLOTS} épreuves disponibles · aucune passée pour l'instant`;

  return (
    <section className="ebh-module">
      <header className="ebh-module-head">
        <span className={`ebh-module-icon ebh-module-icon-${tone}`} aria-hidden>
          {icon}
        </span>
        <div className="ebh-module-titles">
          <h2>{title}</h2>
          <p>{sub}</p>
        </div>
        <span className="ebh-module-chip">{chip}</span>
      </header>

      <div className="ebh-brew">
        <Info size={15} aria-hidden />
        <span>{brewLine}</span>
      </div>

      <ExamsGrid
        count={SLOTS}
        exams={exams}
        premium={premium}
        starting={starting}
        itemLabel="Épreuve"
        collapsedCount={COLLAPSED}
        onStart={onStart}
        onLocked={onLocked}
      />
    </section>
  );
}

// ============================================================================
// HELPERS
// ============================================================================
function HomeSkeleton() {
  return (
    <div className="ebh-loading">
      <style>{`.ebh-loading { min-height: calc(100vh - 80px); background: #F7F8FC; }`}</style>
    </div>
  );
}

// ============================================================================
// VERSION GUEST — démo gratuite illimitée : même série d'examen rejouable
// ============================================================================

function ExamsGuestHome() {
  const router = useRouter();
  const [exams, setExams] = useState<ExamTemplateSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [starting, setStarting] = useState<ModuleEnum | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    publicExamApi
      .list()
      .then((list) => {
        if (cancelled) return;
        setExams(list);
        setLoading(false);
      })
      .catch((e: unknown) => {
        if (cancelled) return;
        setError(
          e instanceof ApiException
            ? e.message
            : "Impossible de charger les examens.",
        );
        setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  /** Pour la démo guest on prend le premier exam free (ou défaut) de chaque module. */
  const examsByModule = useMemo(() => {
    const civique =
      exams.find((e) => e.module === "CIVIQUE" && e.free) ??
      exams.find((e) => e.module === "CIVIQUE") ??
      null;
    const tcf =
      exams.find((e) => e.module === "TCF" && e.free) ??
      exams.find((e) => e.module === "TCF") ??
      null;
    return { CIVIQUE: civique, TCF: tcf };
  }, [exams]);

  async function startDemo(module: ModuleEnum) {
    const tpl = examsByModule[module];
    if (!tpl) return;
    setError(null);
    setStarting(module);
    try {
      const a = await publicAttemptApi.startDemo({
        type: "MOCK_EXAM",
        module,
        examTemplateId: tpl.id,
      });
      router.push(`/sessions/${a.id}`);
    } catch (e) {
      setError(
        e instanceof ApiException
          ? e.message
          : "Impossible de démarrer la démo.",
      );
      setStarting(null);
    }
  }

  return (
    <main className="ebh-guest">
      <div className="guest-banner" role="status">
        <div className="guest-banner-icon" aria-hidden>
          <ShieldIcon />
        </div>
        <div className="guest-banner-content">
          <div className="guest-banner-title">
            Vous êtes en démo gratuite — un examen blanc par module, sans
            création de compte.
          </div>
          <div className="guest-banner-sub">
            Vos résultats ne seront pas sauvegardés.{" "}
            <Link href="/inscription" className="guest-banner-link">
              Créer un compte gratuit →
            </Link>
          </div>
        </div>
      </div>

      <header className="guest-topbar">
        <div className="breadcrumb">
          ACCUEIL <span className="sep">/</span> EXAMENS BLANCS
        </div>
        <h1>
          Préparez-vous en <em>conditions réelles</em>.
        </h1>
        <p className="guest-lede">
          Lancez un examen blanc pour découvrir le format, le chronomètre et le
          niveau attendu. Aucun email demandé.
        </p>
      </header>

      {error && <div className="form-error ebh-error">{error}</div>}

      <section className="guest-tiles">
        <GuestExamCard
          tone="blue"
          module="CIVIQUE"
          title="Examen civique"
          desc="Valeurs et principes de la République. 40 questions chronométrées, seuil de réussite officiel."
          exam={examsByModule.CIVIQUE}
          loading={loading}
          starting={starting === "CIVIQUE"}
          onStart={() => startDemo("CIVIQUE")}
        />
        <GuestExamCard
          tone="red"
          module="TCF"
          title="TCF IRN"
          desc="Compréhension orale, écrite, structure de la langue. Diagnostic CECRL A2 / B1 / B2."
          exam={examsByModule.TCF}
          loading={loading}
          starting={starting === "TCF"}
          onStart={() => startDemo("TCF")}
        />
      </section>

      <div className="guest-foot">
        Pour passer plusieurs examens, consulter l&apos;historique et débloquer
        les variantes (CSP, CR, naturalisation, A2/B1/B2),{" "}
        <Link href="/inscription">créez votre compte gratuit</Link>.
      </div>

      <style>{guestExamStyles}</style>
    </main>
  );
}

function GuestExamCard({
  tone,
  module,
  title,
  desc,
  exam,
  loading,
  starting,
  onStart,
}: {
  tone: "blue" | "red";
  module: ModuleEnum;
  title: string;
  desc: string;
  exam: ExamTemplateSummary | null;
  loading: boolean;
  starting: boolean;
  onStart: () => void;
}) {
  const minutes = exam ? Math.round(exam.durationSeconds / 60) : null;
  const tag = module === "CIVIQUE" ? "EXAMEN CIVIQUE · DÉMO" : "TCF IRN · DÉMO";
  return (
    <div className={`gex gex-${tone}`}>
      <span className={`gex-tag gex-tag-${tone}`}>{tag}</span>
      <h2 className="gex-title">{title}</h2>
      <p className="gex-desc">{desc}</p>
      <div className="gex-meta">
        <div className="gex-meta-item">
          <div className="l">QUESTIONS</div>
          <div className="v">{exam ? exam.totalQuestions : "—"}</div>
        </div>
        <div className="gex-meta-item">
          <div className="l">DURÉE</div>
          <div className="v">{minutes ? `${minutes} min` : "—"}</div>
        </div>
        <div className="gex-meta-item">
          <div className="l">{module === "CIVIQUE" ? "SEUIL" : "RESTITUTION"}</div>
          <div className="v">
            {module === "CIVIQUE"
              ? exam
                ? `${exam.passingScore}/${exam.totalQuestions}`
                : "—"
              : "Niveau CECRL"}
          </div>
        </div>
      </div>
      <button
        type="button"
        className={`btn btn-${tone === "blue" ? "blue" : "red"} btn-lg gex-cta`}
        onClick={onStart}
        disabled={loading || starting || !exam}
      >
        {starting ? "Préparation…" : "Démo gratuite →"}
      </button>
    </div>
  );
}

const guestExamStyles = `
  .ebh-guest {
    max-width: 1080px;
    margin: 0 auto;
    padding: 32px 24px 80px;
  }
  @media (max-width: 760px) {
    .ebh-guest { padding: 22px 16px 56px; }
  }

  .guest-banner {
    display: flex; align-items: center; gap: 14px;
    background: linear-gradient(135deg, rgba(232, 163, 23, 0.10), rgba(232, 163, 23, 0.02));
    border: 1px solid rgba(232, 163, 23, 0.35);
    border-radius: 14px;
    padding: 14px 18px;
    margin-bottom: 28px;
  }
  .guest-banner-icon {
    width: 36px; height: 36px;
    background: var(--color-amber); color: #fff;
    border-radius: 10px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .guest-banner-content { flex: 1; min-width: 0; }
  .guest-banner-title {
    font-weight: 700; font-size: 14px;
    color: var(--color-ink); line-height: 1.3;
  }
  .guest-banner-sub {
    font-size: 12.5px; color: var(--color-muted);
    line-height: 1.45; margin-top: 4px;
  }
  .guest-banner-link {
    color: var(--color-blue); font-weight: 700;
    text-decoration: none;
  }
  .guest-banner-link:hover { text-decoration: underline; }

  .guest-topbar { margin-bottom: 26px; }
  .breadcrumb {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--color-muted);
    letter-spacing: 0.12em;
    text-transform: uppercase;
    margin-bottom: 10px;
  }
  .breadcrumb .sep { margin: 0 6px; opacity: 0.5; }
  .guest-topbar h1 {
    font-family: var(--font-display);
    font-size: clamp(28px, 4vw, 40px);
    font-weight: 500;
    letter-spacing: -0.02em;
    margin: 0 0 8px;
    line-height: 1.1;
    color: var(--color-ink);
  }
  .guest-topbar h1 em {
    color: var(--color-red);
    font-style: italic;
    font-weight: 500;
  }
  .guest-lede {
    color: var(--color-muted);
    font-size: 15px;
    line-height: 1.55;
    margin: 0;
    max-width: 600px;
  }

  .guest-tiles {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
  }
  @media (max-width: 880px) {
    .guest-tiles { grid-template-columns: 1fr; }
  }

  .gex {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 20px;
    padding: 28px;
    display: flex; flex-direction: column;
    transition: all 0.18s;
    box-shadow: 0 30px 60px -30px rgba(15, 24, 57, 0.18);
  }
  .gex-blue:hover:not(.is-locked) { border-color: var(--color-blue); transform: translateY(-3px); }
  .gex-red:hover:not(.is-locked) { border-color: var(--color-red); transform: translateY(-3px); }
  .gex.is-locked {
    background:
      repeating-linear-gradient(45deg, var(--color-paper) 0 6px, #fff 6px 14px);
  }
  .gex-tag {
    display: inline-block; align-self: flex-start;
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.14em;
    padding: 4px 9px;
    border-radius: 5px;
    font-weight: 700;
    margin-bottom: 14px;
  }
  .gex-tag-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .gex-tag-red { background: var(--color-red-light); color: var(--color-red); }
  .gex-title {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 28px;
    letter-spacing: -0.02em;
    margin: 0 0 10px;
    color: var(--color-ink);
    line-height: 1.1;
  }
  .gex-desc {
    color: var(--color-muted);
    font-size: 14px;
    line-height: 1.55;
    margin: 0 0 22px;
  }
  .gex-meta {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 10px;
    margin-bottom: 22px;
  }
  .gex-meta-item {
    background: var(--color-paper);
    border: 1px solid var(--color-line);
    border-radius: 10px;
    padding: 10px;
  }
  .gex-meta-item .l {
    font-family: var(--font-mono);
    font-size: 9px;
    letter-spacing: 0.14em;
    color: var(--color-muted);
    font-weight: 700;
    margin-bottom: 4px;
  }
  .gex-meta-item .v {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 18px;
    color: var(--color-ink);
    letter-spacing: -0.01em;
    line-height: 1.1;
  }
  .gex-cta { align-self: flex-start; margin-top: auto; }

  .gex-locked { display: flex; flex-direction: column; gap: 10px; margin-top: auto; }
  .gex-locked-msg {
    font-size: 13.5px;
    color: var(--color-muted);
    line-height: 1.5;
  }

  .ebh-error { margin-bottom: 16px; }

  .guest-foot {
    margin-top: 28px;
    text-align: center;
    font-size: 13px;
    color: var(--color-muted);
    line-height: 1.55;
  }
  .guest-foot a {
    color: var(--color-blue); font-weight: 700;
    text-decoration: none;
  }
  .guest-foot a:hover { text-decoration: underline; }
`;

// ============================================================================
// ICONS
// ============================================================================
const I = (props: React.SVGProps<SVGSVGElement>) => (
  <svg
    width="18"
    height="18"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
    {...props}
  />
);
const ShieldIcon = () => (
  <I>
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
  </I>
);

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .ebh {
    max-width: 1180px;
    margin: 0 auto;
    padding: 30px 40px 80px;
  }

  /* ===== header ===== */
  .ebh-head { margin-bottom: 24px; }
  .ebh-eyebrow {
    display: inline-flex; align-items: center; gap: 8px;
    font-size: 13px; font-weight: 700;
    letter-spacing: 0.04em; text-transform: uppercase;
    color: var(--color-blue);
    margin-bottom: 8px;
  }
  .ebh-head h1 {
    margin: 0 0 8px;
    font-family: var(--font-sans);
    font-size: clamp(24px, 4vw, 32px);
    font-weight: 800; letter-spacing: -0.02em;
    color: var(--color-ink); line-height: 1.1;
  }
  .ebh-head p {
    margin: 0;
    color: var(--color-muted);
    font-size: 15.5px; line-height: 1.5;
    max-width: 640px;
  }

  .ebh-error {
    background: var(--color-red-light);
    border: 1px solid color-mix(in srgb, var(--color-red) 25%, transparent);
    color: var(--color-red-dark);
    border-radius: 12px;
    padding: 12px 16px;
    font-size: 13.5px;
    margin-bottom: 16px;
  }

  /* ===== card module ===== */
  .ebh-module {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    padding: 22px;
    box-shadow: 0 1px 3px rgba(15, 24, 57, 0.04);
    margin-bottom: 22px;
  }
  .ebh-module-head {
    display: flex; align-items: center; gap: 14px;
    margin-bottom: 14px;
  }
  .ebh-module-icon {
    width: 46px; height: 46px;
    border-radius: 13px;
    display: grid; place-items: center;
    flex-shrink: 0;
    color: #fff;
  }
  .ebh-module-icon-blue { background: var(--color-blue); }
  .ebh-module-icon-red { background: var(--color-red); }
  .ebh-module-titles { flex: 1; min-width: 0; }
  .ebh-module-titles h2 {
    margin: 0 0 2px;
    font-family: var(--font-sans);
    font-size: 18px; font-weight: 800; letter-spacing: -0.01em;
    color: var(--color-ink);
  }
  .ebh-module-titles p {
    margin: 0;
    font-size: 13px; color: var(--color-muted);
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
  }
  .ebh-module-chip {
    font-size: 12px; font-weight: 700;
    color: var(--color-blue);
    background: var(--color-blue-light);
    padding: 5px 12px; border-radius: 999px;
    white-space: nowrap;
    flex-shrink: 0;
  }

  .ebh-brew {
    display: flex; align-items: flex-start; gap: 8px;
    background: var(--color-blue-soft);
    border: 1px solid var(--color-line);
    border-radius: 11px;
    padding: 10px 14px;
    font-size: 12.5px; line-height: 1.5;
    color: var(--color-muted);
    margin-bottom: 16px;
  }
  .ebh-brew svg { flex-shrink: 0; margin-top: 2px; color: var(--color-blue); }

  /* ===== responsive ===== */
  @media (max-width: 768px) {
    /* padding-top dégage le burger fixed du drawer mobile (.ms-toggle). */
    .ebh { padding: 64px 18px 48px; }
    .ebh-module-chip { display: none; }
    .ebh-module-titles p { white-space: normal; }
  }
`;
