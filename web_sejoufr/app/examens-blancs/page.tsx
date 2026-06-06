"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { Info, Lightbulb, Target, Waves } from "lucide-react";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { GuestGateSheet } from "@/app/_components/GuestGateSheet";
import { ExamsGrid } from "@/app/_components/hub/DetailParts";
import {
  ApiException,
  attemptApi,
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
 * Épreuve 1 gratuite, 2+ premium.
 *
 * Guests : même grille — l'examen 1 de chaque parcours passe par la page
 * briefing du template free, qui crée l'attempt anonyme (user NULL + IP
 * côté backend) ; les examens 2-20 ouvrent la GuestGateSheet.
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
  lockedLabel,
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
  lockedLabel?: string;
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
        lockedLabel={lockedLabel}
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
// VERSION GUEST — même grille que les connectés : examen 1 jouable en
// anonyme (analytics : attempt user NULL + clientIp), 2-20 → inscription.
// Démarrer passe par la page briefing du template free (présentation +
// règles), comme en connecté — c'est elle qui crée l'attempt anonyme.
// ============================================================================

function ExamsGuestHome() {
  const router = useRouter();
  const [exams, setExams] = useState<ExamTemplateSummary[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [guestGateOpen, setGuestGateOpen] = useState(false);

  useEffect(() => {
    let cancelled = false;
    publicExamApi
      .list()
      .then((list) => {
        if (!cancelled) setExams(list);
      })
      .catch((e: unknown) => {
        if (!cancelled)
          setError(
            e instanceof ApiException ? e.message : "Impossible de charger les examens.",
          );
      });
    return () => {
      cancelled = true;
    };
  }, []);

  /** Template free de référence de chaque module pour l'examen 1 anonyme. */
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

  function startDemo(module: ModuleEnum) {
    const tpl = examsByModule[module];
    if (!tpl) return;
    router.push(`/examens-blancs/${tpl.slug}`);
  }

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
          Le premier examen de chaque parcours est offert, sans création de
          compte — vos résultats ne seront pas sauvegardés.
        </p>
      </header>

      {error && <div className="ebh-error">{error}</div>}

      <ModuleExamsSection
        tone="red"
        icon={<Waves size={22} strokeWidth={1.8} />}
        title="TCF IRN"
        chip="3 épreuves mélangées"
        brewLine="Brasse toutes les épreuves QCM : Compréhension orale · Compréhension écrite · Structure de la langue."
        exams={[]}
        scoreOutOf={60}
        premium={false}
        starting={false}
        lockedLabel="Compte gratuit"
        onStart={() => startDemo("TCF")}
        onLocked={() => setGuestGateOpen(true)}
      />

      <ModuleExamsSection
        tone="blue"
        icon={<Lightbulb size={22} strokeWidth={1.8} />}
        title="Examen civique"
        chip="5 catégories mélangées"
        brewLine="Brasse tous les thèmes : Principes et valeurs de la République · Système institutionnel et politique · Droits et devoirs · Histoire, géographie et culture · Vivre dans la société française."
        exams={[]}
        scoreOutOf={40}
        premium={false}
        starting={false}
        lockedLabel="Compte gratuit"
        onStart={() => startDemo("CIVIQUE")}
        onLocked={() => setGuestGateOpen(true)}
      />

      <div className="ebh-guest-foot">
        Pour passer les examens suivants, retrouver vos scores et suivre votre
        progression, <Link href="/inscription?next=/examens-blancs">créez votre compte gratuit</Link>.
      </div>

      <GuestGateSheet
        open={guestGateOpen}
        onClose={() => setGuestGateOpen(false)}
        message="Le premier examen blanc de chaque parcours est offert. Créez un compte gratuit pour passer les suivants et conserver vos résultats."
      />

      <style>{styles}</style>
    </main>
  );
}

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

  .ebh-guest-foot {
    margin-top: 6px;
    text-align: center;
    font-size: 13px;
    color: var(--color-muted);
    line-height: 1.55;
  }
  .ebh-guest-foot a {
    color: var(--color-blue); font-weight: 700;
    text-decoration: none;
  }
  .ebh-guest-foot a:hover { text-decoration: underline; }

  /* ===== responsive ===== */
  @media (max-width: 768px) {
    /* padding-top dégage le burger fixed du drawer mobile (.ms-toggle). */
    .ebh { padding: 64px 18px 48px; }
    .ebh-module-chip { display: none; }
    .ebh-module-titles p { white-space: normal; }
  }
`;
