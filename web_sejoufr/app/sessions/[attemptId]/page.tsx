"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, use, useEffect, useState } from "react";
import { ArrowLeft } from "lucide-react";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import {
  QuestionRunner,
  type RunnerBackend,
  type RunnerSection,
} from "@/app/_components/QuestionRunner";
import { TrainingResultCard } from "@/app/_components/TrainingResultCard";
import { ExamReport } from "@/app/_components/ExamReport";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import {
  ApiException,
  attemptApi,
  publicAttemptApi,
  userContentApi,
} from "@/lib/api";
import { trackDiagnosticAssessmentCompleted } from "@/lib/analytics";
import {TCF_DIAGNOSTIC_HUB_HREF, TCF_DIAGNOSTIC_PARAM} from "@/lib/tcf-diagnostic";
import {
  CIVIC_DIAGNOSTIC_PARAM,
  civicDiagnosticResultHref,
} from "@/lib/civic-diagnostic";
import { handleStartFailure } from "@/lib/start-failure";
import {
  epreuveExitMessage,
  EPREUVE_EXIT_CANCEL,
  EPREUVE_EXIT_CONFIRM,
  EPREUVE_EXIT_TITLE,
} from "@/lib/full-exam-exit";
import { useAuth } from "@/lib/auth-context";
import type { AttemptResponse, Difficulty } from "@/lib/types";

interface PageProps {
  params: Promise<{ attemptId: string }>;
}

type Phase = "loading" | "running" | "result" | "error";
/** "auth" = attempt récupéré via endpoints authentifiés ; "guest" = via /api/public. */
type SessionMode = "auth" | "guest";

const PREMIUM_BATCH_SIZE = 30;

const GUEST_BACKEND: RunnerBackend = {
  submitAnswer: (id, body) => publicAttemptApi.submitAnswer(id, body),
  finish: (id) => publicAttemptApi.finish(id),
  // Pas d'extension ni de favoris pour la démo guest : volontairement omis
  // pour cacher les fonctionnalités réservées aux comptes.
};

/** Chemin de retour après une série, dérivé du module/épreuve de l'attempt :
 *  civique → séries du thème, TCF → séries de l'épreuve × niveau. */
function lotReturnPath(attempt: AttemptResponse): string | null {
  if (attempt.module === "CIVIQUE") {
    const themeId = attempt.themeId ?? attempt.questions[0]?.question.themeId;
    return themeId ? `/entrainement/civique/${themeId}` : null;
  }
  const q = attempt.questions[0]?.question;
  const code = q?.questionType?.toLowerCase();
  const level = q?.difficulty?.toLowerCase();
  if (code && level && (code === "co" || code === "ce" || code === "structure")) {
    return `/entrainement/tcf/${code}/${level}`;
  }
  return null;
}

const TCF_EPREUVE_LABELS: Record<string, string> = {
  CO: "Compréhension orale",
  CE: "Compréhension écrite",
  STRUCTURE: "Structure de la langue",
};

const TCF_SECTION_ICONS: Record<string, string> = {
  CO: "🎧",
  CE: "📖",
  STRUCTURE: "🧩",
};

/** Parties d'un examen TCF mixte — le backend groupe les questions par
 *  épreuve (orale → écrite → structures). Undefined si l'attempt n'est pas
 *  sectionné (examen mono-épreuve, ou attempt d'avant le tri). */
function tcfExamSections(attempt: AttemptResponse): RunnerSection[] | undefined {
  if (attempt.type !== "MOCK_EXAM" || attempt.module !== "TCF") return undefined;
  const sections: RunnerSection[] = [];
  for (let i = 0; i < attempt.questions.length; i++) {
    const type = attempt.questions[i].question.questionType;
    const key = type === "CO_IMAGE" ? "CO" : type;
    const label = TCF_EPREUVE_LABELS[key];
    if (!label) return undefined;
    const last = sections[sections.length - 1];
    if (last && last.label === label) {
      last.count++;
    } else {
      sections.push({
        label,
        icon: TCF_SECTION_ICONS[key],
        startIndex: i,
        count: 1,
      });
    }
  }
  // Seuls les examens multi-épreuves (diagnostic CO+CE) annoncent leurs
  // parties. 1 seul groupe = examen mono-épreuve : pas d'écran d'intro runner,
  // la modale ExamIntroSheet de la page examens présente déjà le déroulé.
  // Plus de 3 groupes = épreuves entremêlées (attempt historique) → undefined.
  return sections.length >= 2 && sections.length <= 3 ? sections : undefined;
}

/** Sous-titre du hero du rapport : épreuve/thème + nature de la session. */
function attemptContextLabel(
  attempt: AttemptResponse,
  lotNumero: number | null,
): string {
  const themeName = attempt.questions[0]?.question.themeName;
  if (attempt.type === "MOCK_EXAM") {
    if (attempt.examTemplateName) return attempt.examTemplateName;
    if (attempt.module === "TCF") {
      const label = attempt.moduleExamQuestionType
        ? TCF_EPREUVE_LABELS[attempt.moduleExamQuestionType]
        : null;
      return `${label ?? "TCF IRN"} · Examen blanc`;
    }
    return attempt.themeId && themeName
      ? `${themeName} · Examen blanc`
      : "Examen civique · Examen blanc";
  }
  const scope =
    attempt.module === "TCF" && attempt.questions[0]
      ? (TCF_EPREUVE_LABELS[attempt.questions[0].question.questionType ?? ""] ??
        "TCF IRN")
      : (themeName ?? "Examen civique");
  return lotNumero != null ? `${scope} · Série ${lotNumero}` : `${scope} · Entraînement`;
}

/** Écran d'origine d'un examen blanc, dérivé de l'attempt : examen
 *  thématique civique → page examens du thème ; examen module TCF → page
 *  examens de l'épreuve ; examens complets (template ou non) →
 *  /examens-blancs. */
function examReturnPath(attempt: AttemptResponse): string {
  if (attempt.examTemplateId) return "/examens-blancs";
  if (attempt.module === "CIVIQUE") {
    return attempt.themeId
      ? `/entrainement/civique/${attempt.themeId}/examens`
      : "/examens-blancs";
  }
  const code = attempt.moduleExamQuestionType?.toLowerCase();
  if (code === "co" || code === "ce" || code === "structure") {
    return `/entrainement/tcf/${code}/examens`;
  }
  return "/examens-blancs";
}

/**
 * Page générique d'une session : training ou examen blanc. Le type de
 * l'attempt détermine le mode du runner et la carte de résultat à afficher.
 *
 * Dual-mode :
 *  - utilisateur connecté → attemptApi.get + flux complet (favoris, extension)
 *  - visiteur guest → publicAttemptApi.getById (IP must match) + démo limitée
 */
export default function SessionRunnerPage({ params }: PageProps) {
  return (
    <Suspense fallback={<div className="sess-loading" />}>
      <SessionRunnerGate params={params} />
    </Suspense>
  );
}

function SessionRunnerGate({ params }: PageProps) {
  const { status } = useAuth();
  if (status === "loading") return <div className="sess-loading" />;
  if (status === "authenticated") {
    return (
      <DualChromeShell>
        <SessionRunnerInner params={params} />
      </DualChromeShell>
    );
  }
  return <SessionRunnerInner params={params} />;
}

function SessionRunnerInner({ params }: PageProps) {
  const { attemptId } = use(params);
  const router = useRouter();
  const { user, status } = useAuth();
  const isPremium = user?.isPremium ?? false;
  const searchParams = useSearchParams();
  /** Numéro de lot quand la session est un lot d'entraînement (batch fixe, pas d'extension). */
  const lotParam = searchParams.get("lot");
  const lotNumero = lotParam && /^\d+$/.test(lotParam) ? Number(lotParam) : null;
  /** "tcfLot" (héritage) : bilan d'une série TCF → rapport commun. */
  const resultMode = searchParams.get("result");
  const tcfCode = searchParams.get("code");
  const tcfLevel = searchParams.get("level");
  /** Présent quand Cette session (CO/CE) fait partie d'un examen blanc TCF
   *  complet : pas de rapport individuel, on retourne au hub de progression. */
  const fullExamId = searchParams.get("fullExamId");
  // Section d'un diagnostic TCF : même règle de retour qu'une épreuve
  // d'examen complet — on ramène au hub, jamais au rapport individuel.
  const tcfDiagnosticId = searchParams.get(TCF_DIAGNOSTIC_PARAM);
  /**
   * Diagnostic CIVIQUE : même mécanisme, une seule différence — il n'a qu'une
   * session, donc la fin mène droit au **résultat** plutôt qu'à un accueil qui
   * redemanderait un clic.
   */
  const civicDiagnosticId = searchParams.get(CIVIC_DIAGNOSTIC_PARAM);

  const [phase, setPhase] = useState<Phase>("loading");
  const [sessionMode, setSessionMode] = useState<SessionMode>("auth");
  const [attempt, setAttempt] = useState<AttemptResponse | null>(null);
  const [favoriteIds, setFavoriteIds] = useState<Set<string>>(new Set());
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  /** True si l'attempt était déjà finalisé à l'ouverture (reprise sur session close). */
  const [openedAsFinished, setOpenedAsFinished] = useState(false);
  const [retrying, setRetrying] = useState(false);
  const [retryError, setRetryError] = useState<string | null>(null);
  const [retryPaywallOpen, setRetryPaywallOpen] = useState(false);

  /** "Refaire" depuis le rapport : relance une session avec les mêmes
   *  paramètres (examen template / thématique / module, ou série). */
  async function retryAttempt() {
    if (!attempt || retrying) return;
    setRetryError(null);
    setRetrying(true);
    try {
      if (attempt.type === "MOCK_EXAM") {
        const a = attempt.examTemplateId
          ? await attemptApi.start({
              type: "MOCK_EXAM",
              module: attempt.module,
              examTemplateId: attempt.examTemplateId,
            })
          : attempt.module === "CIVIQUE"
            ? await attemptApi.start({
                type: "MOCK_EXAM",
                module: "CIVIQUE",
                themeId: attempt.themeId ?? undefined,
              })
            : await attemptApi.start({
                type: "MOCK_EXAM",
                module: "TCF",
                moduleExamQuestionType: attempt.moduleExamQuestionType ?? undefined,
              });
        router.push(`/sessions/${a.id}`);
        return;
      }
      // Série : mêmes paramètres que les pages séries.
      if (lotNumero == null) return;
      if (attempt.module === "CIVIQUE") {
        const a = await attemptApi.start({
          type: "TRAINING",
          module: "CIVIQUE",
          themeId: attempt.themeId ?? undefined,
          lotNumero,
        });
        router.push(`/sessions/${a.id}?lot=${lotNumero}`);
        return;
      }
      const q = attempt.questions[0]?.question;
      const code = tcfCode ?? q?.questionType?.toLowerCase();
      const level = tcfLevel ?? q?.difficulty?.toLowerCase();
      const a = await attemptApi.start({
        type: "TRAINING",
        module: "TCF",
        questionType: q?.questionType ?? undefined,
        difficulty: (q?.difficulty ?? undefined) as Difficulty | undefined,
        lotNumero,
      });
      router.push(
        `/sessions/${a.id}?lot=${lotNumero}&result=tcfLot&code=${code}&level=${level}`,
      );
    } catch (e) {
      handleStartFailure(e, {
        onPaywall: () => setRetryPaywallOpen(true),
        onMessage: setRetryError,
        fallbackMessage: "Impossible de relancer la session.",
      });
      setRetrying(false);
    }
  }

  useEffect(() => {
    if (status === "loading") return;
    let cancelled = false;
    (async () => {
      try {
        // Stratégie : si connecté, on tente d'abord l'endpoint auth. En cas
        // de 404/403 on retombe sur le public (cas exotique : connecté mais
        // attempt créé en guest avant login). Pour un guest, on va direct
        // sur le public.
        let a: AttemptResponse | null = null;
        let mode: SessionMode = "auth";

        if (status === "authenticated") {
          try {
            a = await attemptApi.get(attemptId);
          } catch (e) {
            if (
              e instanceof ApiException &&
              (e.status === 404 || e.status === 403)
            ) {
              try {
                a = await publicAttemptApi.getById(attemptId);
                mode = "guest";
              } catch {
                throw e;
              }
            } else {
              throw e;
            }
          }
        } else {
          a = await publicAttemptApi.getById(attemptId);
          mode = "guest";
        }

        if (cancelled || !a) return;
        setSessionMode(mode);

        if (a.finishedAt) {
          // Sous-épreuve CO/CE d'un examen complet déjà terminée : on ne montre
          // pas le rapport individuel, on renvoie au hub de progression.
          if (fullExamId) {
            router.replace(`/examens-blancs/tcf/${fullExamId}`);
            return;
          }
          if (tcfDiagnosticId) {
            router.replace(TCF_DIAGNOSTIC_HUB_HREF);
            return;
          }
          if (civicDiagnosticId) {
            router.replace(civicDiagnosticResultHref(civicDiagnosticId));
            return;
          }
          setAttempt(a);
          setOpenedAsFinished(true);
          setPhase("result");
          // N'émet quelque chose que si cette série avait été lancée pour
          // compléter le profil du diagnostic. Sinon : rien, on n'invente pas.
          trackDiagnosticAssessmentCompleted(attemptId);
          return;
        }

        // Favoris : seulement en mode auth (l'API publique n'expose pas /me).
        if (mode === "auth") {
          try {
            const favList = await userContentApi.favorites(a.module);
            if (!cancelled) setFavoriteIds(new Set(favList.map((q) => q.id)));
          } catch {
            // best-effort
          }
        }
        if (cancelled) return;
        setAttempt(a);
        setPhase("running");
      } catch (e) {
        if (cancelled) return;
        setErrorMsg(e instanceof ApiException ? e.message : "Session introuvable.");
        setPhase("error");
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [attemptId, status, fullExamId, tcfDiagnosticId, civicDiagnosticId, router]);

  if (status === "loading" || phase === "loading") {
    return <div className="sess-loading" />;
  }

  if (phase === "error") {
    const fallbackHref =
      status === "authenticated" ? "/dashboard" : "/entrainement";
    const fallbackLabel =
      status === "authenticated"
        ? "Retour au tableau de bord →"
        : "Retour à l'entraînement →";
    return (
      <main className="sess-error">
        <h1>Session indisponible</h1>
        <p>{errorMsg ?? "Cette session n'existe plus."}</p>
        <Link href={fallbackHref} className="btn btn-blue">
          {fallbackLabel}
        </Link>
        <style>{errorStyles}</style>
      </main>
    );
  }

  if (phase === "result" && attempt) {
    const isExam = attempt.type === "MOCK_EXAM";
    const isGuest = sessionMode === "guest";

    // Une série (lot) affiche le même rapport qu'un examen de thème —
    // à chaud comme en consultation (`?result=tcfLot` est l'héritage du
    // bilan donut TCF, désormais aligné sur le rapport commun).
    const isSerie = !isGuest && (lotNumero != null || resultMode === "tcfLot");
    const serieReturnHref =
      tcfCode && tcfLevel
        ? `/entrainement/tcf/${tcfCode}/${tcfLevel}`
        : (lotReturnPath(attempt) ?? "/entrainement");

    // Retour à l'écran précédent (historique navigateur) ; fallback sur
    // l'écran d'origine dérivé de l'attempt quand la page a été ouverte
    // directement (nouvel onglet, lien partagé).
    const goBack = () => {
      if (typeof window !== "undefined" && window.history.length > 1) {
        router.back();
        return;
      }
      router.push(
        isExam
          ? examReturnPath(attempt)
          : (lotReturnPath(attempt) ?? "/entrainement"),
      );
    };

    return (
      <main className="sess">
        <div className="sess-back-row">
          <button type="button" className="sess-back" onClick={goBack}>
            <ArrowLeft size={16} aria-hidden />
            Retour
          </button>
        </div>
        {retryError && <div className="sess-retry-error">{retryError}</div>}
        {isExam ? (
          <>
            {/* Rapport façon maquette : hero donut + sous-thèmes (examens
                complets uniquement) + « Et maintenant ? » + corrigé. */}
            <ExamReport
              attempt={attempt}
              contextLabel={attemptContextLabel(attempt, lotNumero)}
              onRetry={isGuest ? undefined : retryAttempt}
              retrying={retrying}
              moreHref={isGuest ? undefined : examReturnPath(attempt)}
              moreLabel="Autres examens blancs"
              progressHref={isGuest ? undefined : "/statistiques"}
            />
            {isGuest && <GuestResultCta />}
          </>
        ) : isSerie || (openedAsFinished && !isGuest) ? (
          <>
            {/* Série (à chaud ou consultation) et entraînement déjà fini :
                même rapport qu'un examen de thème, CTAs adaptés. */}
            <ExamReport
              attempt={attempt}
              contextLabel={attemptContextLabel(attempt, lotNumero)}
              onRetry={lotNumero != null ? retryAttempt : undefined}
              retryLabel="Refaire cette série"
              retrying={retrying}
              moreHref={serieReturnHref}
              moreLabel="Autres séries"
              progressHref="/statistiques"
            />
          </>
        ) : (
          <>
            {/* À chaud, fin d'un entraînement libre : carte de score
                célébrative. (Guests : idem + CTA inscription.) */}
            <TrainingResultCard
              attempt={attempt}
              isPremium={isPremium}
              variant="primary"
            />
            {isGuest && <GuestResultCta />}
          </>
        )}
        <PaywallSheet
          open={retryPaywallOpen}
          onClose={() => setRetryPaywallOpen(false)}
          module={attempt.module === "TCF" ? "INTEGRAL" : "CIVIQUE"}
        />
        <style>{`
          .sess { background: var(--color-paper); min-height: calc(100vh - 110px); }
          .sess-back-row {
            max-width: 880px;
            margin: 0 auto;
            padding: 20px 18px 0;
          }
          .sess-back {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            padding: 0;
            background: none;
            border: none;
            font-family: var(--font-sans);
            font-size: 14px;
            font-weight: 600;
            color: var(--color-muted);
            cursor: pointer;
            transition: color 0.15s;
          }
          .sess-back:hover { color: var(--color-blue); }
          .sess-retry-error {
            max-width: 880px;
            margin: 0 auto;
            padding: 12px 16px;
            background: var(--color-red-light);
            border: 1px solid color-mix(in srgb, var(--color-red) 25%, transparent);
            color: var(--color-red-dark);
            border-radius: 12px;
            font-size: 13.5px;
            position: relative;
            top: 18px;
          }
        `}</style>
      </main>
    );
  }

  if (phase === "running" && attempt) {
    const isExam = attempt.type === "MOCK_EXAM";
    const isGuest = sessionMode === "guest";
    // Un lot = batch fixe déterministe : pas d'extension, même pour un
    // premium. Les guests jouent la série 1 dans ce même mode.
    const isLot = lotNumero != null && !isExam;
    // En training auth premium : extension auto. En guest : pas d'extension
    // (un seul batch de 20Q par démo). En exam / lot : pas d'extension.
    const canExtend = !isExam && isPremium && !isGuest && !isLot;
    const firstThemeId = attempt.questions[0]?.question.themeId;
    const allSameTheme =
      firstThemeId !== undefined &&
      attempt.questions.every((q) => q.question.themeId === firstThemeId);
    // Retour vers la liste des séries : les query params (code/level) priment
    // sur la dérivation depuis les questions (robuste face à CO_IMAGE).
    const lotQuitHref = isLot
      ? tcfCode && tcfLevel
        ? `/entrainement/tcf/${tcfCode}/${tcfLevel}`
        : lotReturnPath(attempt)
      : null;

    return (
      <QuestionRunner
        initialAttempt={attempt}
        mode={isExam ? "exam" : "training"}
        infinite={canExtend}
        extensionParams={
          canExtend
            ? {
                module: attempt.module,
                themeId: allSameTheme ? firstThemeId : undefined,
                batchSize: PREMIUM_BATCH_SIZE,
              }
            : undefined
        }
        initialFavoriteIds={favoriteIds}
        eyebrow={
          // 🛑 Un diagnostic civique n'est ni un examen blanc ni une « démo »,
          // et il se joue désormais AVANT le compte (V053) : sans ce cas, un
          // visiteur lisait « Examen blanc · Démo » au-dessus de ses 40
          // questions de diagnostic.
          civicDiagnosticId
            ? "Diagnostic · Examen civique"
            : isGuest
            ? isExam
              ? "Examen blanc · Démo"
              : isLot
                ? `Série ${lotNumero} · Démo`
                : "Entraînement · Démo"
            : isExam
              ? "Examen blanc"
              : isLot
                ? `Série ${lotNumero}`
                : "Entraînement"
        }
        quitHref={
          fullExamId
            ? `/examens-blancs/tcf/${fullExamId}`
            : tcfDiagnosticId
              ? TCF_DIAGNOSTIC_HUB_HREF
              : civicDiagnosticId
                ? civicDiagnosticResultHref(civicDiagnosticId)
                : isExam
              ? examReturnPath(attempt)
              : (lotQuitHref ?? "/entrainement")
        }
        // Une épreuve COMMENCÉE ne se reprend jamais : quitter la clôture, ici
        // comme sur le hub. En examen complet, `onCompleted` ramène au hub sans
        // ouvrir de bilan — les épreuves suivantes restent à passer.
        quitMode={isExam ? "confirmFinish" : "link"}
        quitConfirm={
          fullExamId
            ? {
                title: EPREUVE_EXIT_TITLE,
                message: epreuveExitMessage(
                  attempt.moduleExamQuestionType === "CO"
                    ? "TCF_CO"
                    : attempt.moduleExamQuestionType === "CE"
                      ? "TCF_CE"
                      : null,
                ),
                confirmLabel: EPREUVE_EXIT_CONFIRM,
                cancelLabel: EPREUVE_EXIT_CANCEL,
              }
            : undefined
        }
        timeLimitSeconds={isExam ? attempt.timeLimitSeconds : undefined}
        startedAt={isExam ? attempt.startedAt : undefined}
        // En examen complet, l'épreuve a déjà été lancée depuis le hub
        // (« Commencer · Compréhension orale ») : pas de 2ᵉ écran d'intro.
        sections={fullExamId ? undefined : tcfExamSections(attempt)}
        backend={isGuest ? GUEST_BACKEND : undefined}
        onCompleted={(finalAttempt) => {
          // Épreuve d'un examen complet : retour au hub (qui débloque la
          // suivante) au lieu d'afficher le rapport individuel.
          if (fullExamId) {
            router.push(`/examens-blancs/tcf/${fullExamId}`);
            return;
          }
          if (tcfDiagnosticId) {
            router.push(TCF_DIAGNOSTIC_HUB_HREF);
            return;
          }
          // 🛑 Le diagnostic civique mène DROIT au résultat : sans ce renvoi,
          // le candidat termine ses 40 questions et atterrit sur le bilan de
          // série générique, très loin du diagnostic qu'il vient de faire.
          if (civicDiagnosticId) {
            router.push(civicDiagnosticResultHref(civicDiagnosticId));
            return;
          }
          setAttempt(finalAttempt);
          setPhase("result");
          trackDiagnosticAssessmentCompleted(attemptId);
        }}
      />
    );
  }

  return null;
}

function GuestResultCta() {
  return (
    <section className="sess-guest-cta">
      <div className="sess-guest-cta-inner">
        <div className="sess-guest-cta-eyebrow">DÉMO TERMINÉE</div>
        <h2>
          Sauvegardez vos résultats et continuez à progresser.
        </h2>
        <p>
          Vos réponses ne sont pas conservées tant que vous n&apos;avez pas de
          compte. Créez-en un gratuitement pour suivre vos statistiques par
          thème, réviser vos erreurs et lancer un entraînement illimité.
        </p>
        <div className="sess-guest-cta-actions">
          <Link href="/inscription" className="btn btn-red btn-lg">
            Créer mon compte gratuit →
          </Link>
          <Link href="/connexion" className="btn btn-ghost">
            J&apos;ai déjà un compte
          </Link>
        </div>
      </div>
      <style>{`
        .sess-guest-cta {
          max-width: 720px;
          margin: 0 auto;
          padding: 0 16px 48px;
        }
        .sess-guest-cta-inner {
          background: linear-gradient(135deg, var(--color-blue) 0%, var(--color-blue-dark) 100%);
          color: #fff;
          padding: 32px 36px;
          border-radius: 20px;
          box-shadow: 0 30px 60px -30px rgba(15, 24, 57, 0.4);
        }
        .sess-guest-cta-eyebrow {
          font-family: var(--font-mono);
          font-size: 11px;
          letter-spacing: 0.14em;
          opacity: 0.7;
          font-weight: 700;
          margin-bottom: 12px;
        }
        .sess-guest-cta-inner h2 {
          font-family: var(--font-display);
          font-weight: 500;
          font-size: clamp(22px, 3vw, 28px);
          line-height: 1.2;
          letter-spacing: -0.015em;
          margin: 0 0 12px;
          color: #fff;
        }
        .sess-guest-cta-inner p {
          color: rgba(255, 255, 255, 0.82);
          font-size: 14.5px;
          line-height: 1.55;
          margin: 0 0 22px;
          max-width: 540px;
        }
        .sess-guest-cta-actions {
          display: flex; gap: 10px; flex-wrap: wrap; align-items: center;
        }
      `}</style>
    </section>
  );
}

const errorStyles = `
  .sess-error {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    text-align: center; padding: 40px 24px; gap: 14px;
  }
  .sess-error h1 {
    font-family: var(--font-display); font-weight: 500;
    font-size: 28px; letter-spacing: -0.02em;
    color: var(--color-ink); margin: 0;
  }
  .sess-error p {
    color: var(--color-muted); font-size: 14px;
    max-width: 420px; line-height: 1.55; margin: 0 0 8px;
  }
`;
