"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState, type ReactNode } from "react";
import { Info, Lightbulb, Target, Waves } from "lucide-react";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { GuestGateSheet } from "@/app/_components/GuestGateSheet";
import { ExamsGrid, type ExamSlotData } from "@/app/_components/hub/DetailParts";
import { examSlotGrid } from "@/lib/exam-slots";
import { TcfFullExamBriefingSheet } from "@/app/examens-blancs/tcf/TcfFullExamBriefingSheet";
import {
  ApiException,
  attemptApi,
  fullTcfExamApi,
  publicExamApi,
} from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  type AttemptSummaryResponse,
  canAccessModule,
  cecrlIndex,
  type ExamTemplateSummary,
  type FullTcfExamSummaryResponse,
  isProductionAttempt,
  type Module as ModuleEnum,
  niveauCecrlLabel,
} from "@/lib/types";

const SLOTS = 20;
const COLLAPSED = 8;

/** Templates de référence des examens complets (briefing + lancement). */
const TCF_FREE_DIAGNOSTIC_SLUG = "tcf-mix-01";
const CIVIQUE_FULL_EXAM_SLUG = "civique-decouverte";

/**
 * /examens-blancs : « Examens blancs complets » — une card par parcours.
 *
 * - **TCF abonné (Intégral)** : grille des 20 examens TCF complets (CO+CE+EE+EO
 *   orchestrés) ; « Démarrer » ouvre le briefing inline → hub
 *   `/examens-blancs/tcf/[id]`.
 * - **TCF invité / compte gratuit** : diagnostic gratuit CO+CE (`tcf-mix-01`),
 *   EE/EO cadenassés, rapport sur les 2 épreuves de compréhension. C'est le
 *   hook de conversion (examen 1 offert, 2+ premium).
 * - **Civique** : MOCK_EXAM 40 Q stratifiées (`civique-decouverte`).
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
  const [tcfComprehension, setTcfComprehension] = useState<AttemptSummaryResponse[]>([]);
  const [fullExams, setFullExams] = useState<FullTcfExamSummaryResponse[]>([]);
  const [paywallModule, setPaywallModule] = useState<"CIVIQUE" | "INTEGRAL" | null>(null);
  /** Slot dont le briefing d'examen complet est ouvert (lancement inline). */
  const [briefingSlot, setBriefingSlot] = useState<number | null>(null);

  const tcfPremium = user != null && canAccessModule(user, "TCF");
  const civiquePremium = user != null && canAccessModule(user, "CIVIQUE");

  useEffect(() => {
    if (status !== "authenticated") return;
    let cancelled = false;
    Promise.allSettled([
      attemptApi.listMine({ type: "MOCK_EXAM", module: "CIVIQUE", limit: 100 }),
      attemptApi.listMine({ type: "MOCK_EXAM", module: "TCF", limit: 100 }),
    ]).then(([c, t]) => {
      if (cancelled) return;
      if (c.status === "fulfilled") {
        // Examens complets civiques (40 Q tous thèmes) : on écarte les examens
        // thématiques (lotThemeId non null). Rangés par slot plus bas.
        setCivique(c.value.filter((a) => a.finishedAt && !a.lotThemeId));
      }
      if (t.status === "fulfilled") {
        // Diagnostic de compréhension TCF (50 Q CO → CE) : on écarte les examens
        // module (CO/CE/Structure) et les productions / TCF_COMPLET. Sert de
        // carte pour les comptes gratuits (1 offert).
        setTcfComprehension(
          t.value.filter(
            (a) =>
              a.finishedAt &&
              !a.moduleExamQuestionType &&
              !isProductionAttempt(a) &&
              a.totalQuestions != null,
          ),
        );
      }
    });
    return () => {
      cancelled = true;
    };
  }, [status]);

  // Examens TCF complets : seulement pour les abonnés (le backend exige hasTcf).
  useEffect(() => {
    if (status !== "authenticated" || !tcfPremium) return;
    let cancelled = false;
    fullTcfExamApi
      .listMine(SLOTS)
      .then((list) => {
        if (!cancelled) setFullExams(list);
      })
      .catch(() => {
        /* silencieux : la grille s'affichera vide */
      });
    return () => {
      cancelled = true;
    };
  }, [status, tcfPremium]);

  // Grilles indexées par slot : refaire l'examen N met à jour la case N.
  const { bySlot: civiqueBySlot, latest: civiqueLatest } = useMemo(
    () => examSlotGrid(civique, SLOTS),
    [civique],
  );
  const { bySlot: tcfCompBySlot, latest: tcfCompLatest } = useMemo(
    () => examSlotGrid(tcfComprehension, SLOTS),
    [tcfComprehension],
  );
  const { bySlot: fullExamBySlot, latest: fullExamLatest } = useMemo(
    () => examSlotGrid(fullExams, SLOTS),
    [fullExams],
  );

  if (status === "loading" || !user) return <HomeSkeleton />;

  // Cards full-exam (abonné) : mêmes cards que Civique. Un slot rempli =
  // examen complet déjà passé (Refaire relance, Rapport → bilan ou hub si
  // encore en cours). « Démarrer » ouvre le briefing inline. Rangé par slot :
  // refaire l'examen N met à jour la case N (parité mobile, V110).
  const fullExamSlotData: (ExamSlotData | null)[] = fullExamBySlot.map((e) =>
    e
      ? {
          id: e.id,
          metaOverride:
            e.status === "COMPLETED"
              ? niveauCecrlLabel(e.finalCecrlLevel)
              : e.status === "PENDING_EVALUATIONS"
                ? "Éval en cours…"
                : "En cours",
        }
      : null,
  );
  // « Rapport » : examen en cours → hub (reprise), terminé/éval → bilan.
  function fullExamReportPath(id: string): string {
    const e = fullExams.find((x) => x.id === id);
    return e?.status === "IN_PROGRESS"
      ? `/examens-blancs/tcf/${id}`
      : `/examens-blancs/tcf/${id}/bilan`;
  }
  // « Démarrer / Refaire » : ouvre le briefing inline (il crée l'examen et
  // route vers le hub /examens-blancs/tcf/[id]).
  function startFullExam(slot: number) {
    setBriefingSlot(slot);
  }
  // Le slot voulu est transmis au briefing (?slot=N) qui le repasse au start :
  // refaire l'examen N réutilise slot_number=N.
  function startCivique(slot: number) {
    router.push(`/examens-blancs/${CIVIQUE_FULL_EXAM_SLUG}?slot=${slot}`);
  }
  function startTcfDiagnostic(slot: number) {
    router.push(`/examens-blancs/${TCF_FREE_DIAGNOSTIC_SLUG}?slot=${slot}`);
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
          Retrouvez les examens déjà passés et leur score, ou lancez-en un
          nouveau.
        </p>
      </header>

      <ModuleExamsSection
        tone="red"
        icon={<Waves size={22} strokeWidth={1.8} />}
        title="TCF IRN"
        chip={tcfPremium ? "CO · CE · EE · EO" : "CO puis CE"}
        brewLine={
          tcfPremium
            ? "L'examen complet enchaîne les 4 épreuves dans l'ordre du vrai TCF IRN : compréhension orale et écrite, puis expression écrite et orale évaluées par l'IA. 90 min, niveau CECRL plancher des 4 épreuves."
            : "Enchaîne les épreuves de compréhension dans l'ordre du vrai TCF : orale (25 questions · 20 min) puis écrite (25 questions · 35 min). L'expression écrite et orale se débloquent avec l'abonnement Intégral."
        }
        sub={
          tcfPremium
            ? fullExamSubline(fullExamLatest)
            : comprehensionSubline(tcfCompLatest)
        }
      >
        {tcfPremium ? (
          <ExamsGrid
            count={SLOTS}
            exams={fullExamSlotData}
            premium
            starting={false}
            itemLabel="Examen"
            collapsedCount={COLLAPSED}
            reportPath={fullExamReportPath}
            onStart={startFullExam}
            onLocked={() => setPaywallModule("INTEGRAL")}
          />
        ) : (
          <ExamsGrid
            count={SLOTS}
            exams={tcfCompBySlot}
            premium={false}
            starting={false}
            itemLabel="Épreuve"
            collapsedCount={COLLAPSED}
            onStart={startTcfDiagnostic}
            onLocked={() => setPaywallModule("INTEGRAL")}
          />
        )}
      </ModuleExamsSection>

      <ModuleExamsSection
        tone="blue"
        icon={<Lightbulb size={22} strokeWidth={1.8} />}
        title="Examen civique"
        chip="5 catégories mélangées"
        brewLine="Brasse tous les thèmes : Principes et valeurs de la République · Système institutionnel et politique · Droits et devoirs · Histoire, géographie et culture · Vivre dans la société française."
        sub={comprehensionSubline(civiqueLatest, 40)}
      >
        <ExamsGrid
          count={SLOTS}
          exams={civiqueBySlot}
          premium={civiquePremium}
          starting={false}
          itemLabel="Examen"
          collapsedCount={COLLAPSED}
          onStart={startCivique}
          onLocked={() => setPaywallModule("CIVIQUE")}
        />
      </ModuleExamsSection>

      {briefingSlot !== null && (
        <TcfFullExamBriefingSheet
          slotNumber={briefingSlot}
          onClose={() => setBriefingSlot(null)}
          onNeedsPremium={() => {
            setBriefingSlot(null);
            setPaywallModule("INTEGRAL");
          }}
        />
      )}

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
// Sous-titres de card (stats récap)
// ============================================================================

/** Récap des examens QCM (compréhension TCF / civique) : score brut ou échelle
 *  calibrée TCF (100-499) dès qu'un examen calibré existe. */
function comprehensionSubline(
  exams: AttemptSummaryResponse[],
  scoreOutOf = 50,
): string {
  const done = Math.min(exams.length, SLOTS);
  if (done === 0) {
    return `${SLOTS} épreuves disponibles · aucune passée pour l'instant`;
  }
  const bestCalibrated = exams.reduce(
    (max: number | null, a) =>
      a.calibratedScore != null ? Math.max(max ?? 0, a.calibratedScore) : max,
    null,
  );
  const best = exams.reduce((max, a) => Math.max(max, a.score ?? 0), 0);
  const bestLabel =
    bestCalibrated != null ? `${bestCalibrated}/499` : `${best}/${scoreOutOf}`;
  return `${done}/${SLOTS} épreuves passées · meilleur ${bestLabel}`;
}

/** Récap des examens TCF complets : nombre terminés + meilleur niveau CECRL. */
function fullExamSubline(exams: FullTcfExamSummaryResponse[]): string {
  const completed = exams.filter(
    (e) => e.status === "COMPLETED" && e.finalCecrlLevel != null,
  );
  if (completed.length === 0) {
    return `${SLOTS} examens complets disponibles · aucun terminé pour l'instant`;
  }
  const bestLevel = completed.reduce<FullTcfExamSummaryResponse["finalCecrlLevel"]>(
    (best, e) =>
      best == null || cecrlIndex(e.finalCecrlLevel) > cecrlIndex(best)
        ? e.finalCecrlLevel
        : best,
    null,
  );
  return `${completed.length}/${SLOTS} examens complets · meilleur niveau ${niveauCecrlLabel(bestLevel)}`;
}

// ============================================================================
// SECTION MODULE — card TCF IRN / Examen civique (chrome + grille en children)
// ============================================================================
function ModuleExamsSection({
  tone,
  icon,
  title,
  chip,
  brewLine,
  sub,
  children,
}: {
  tone: "blue" | "red";
  icon: ReactNode;
  title: string;
  chip: string;
  brewLine: string;
  sub: string;
  children: ReactNode;
}) {
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

      {children}
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
// VERSION GUEST — même grille que les connectés gratuits : examen 1 jouable en
// anonyme (diagnostic CO+CE, analytics user NULL + clientIp), 2-20 →
// inscription. Le full exam (EE/EO) exige un compte + abonnement.
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
        chip="CO puis CE"
        brewLine="Enchaîne les épreuves de compréhension dans l'ordre du vrai TCF : orale (25 questions · 20 min) puis écrite (25 questions · 35 min). L'expression écrite et orale se débloquent avec un compte abonné."
        sub={`${SLOTS} épreuves disponibles · 1 offerte sans compte`}
      >
        <ExamsGrid
          count={SLOTS}
          exams={[]}
          premium={false}
          starting={false}
          itemLabel="Épreuve"
          collapsedCount={COLLAPSED}
          lockedLabel="Compte gratuit"
          onStart={() => startDemo("TCF")}
          onLocked={() => setGuestGateOpen(true)}
        />
      </ModuleExamsSection>

      <ModuleExamsSection
        tone="blue"
        icon={<Lightbulb size={22} strokeWidth={1.8} />}
        title="Examen civique"
        chip="5 catégories mélangées"
        brewLine="Brasse tous les thèmes : Principes et valeurs de la République · Système institutionnel et politique · Droits et devoirs · Histoire, géographie et culture · Vivre dans la société française."
        sub={`${SLOTS} épreuves disponibles · 1 offerte sans compte`}
      >
        <ExamsGrid
          count={SLOTS}
          exams={[]}
          premium={false}
          starting={false}
          itemLabel="Examen"
          collapsedCount={COLLAPSED}
          lockedLabel="Compte gratuit"
          onStart={() => startDemo("CIVIQUE")}
          onLocked={() => setGuestGateOpen(true)}
        />
      </ModuleExamsSection>

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
