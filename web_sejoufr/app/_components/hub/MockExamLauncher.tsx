"use client";

import {useRouter} from "next/navigation";
import {createContext, useCallback, useContext, useState, type ReactNode} from "react";
import {attemptApi, productionApi, publicAttemptApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {comprehensionExamIntro} from "@/lib/exam-intro";
import {loadEpreuveTasks, productionTasksKey} from "@/lib/production-catalog";
import {unlockCoAudio} from "@/lib/co-audio";
import {handleStartFailure} from "@/lib/start-failure";
import {adresseCourante, withRetour} from "@/lib/retour";
import type {QuestionType} from "@/lib/types";
import {useCachedData} from "@/lib/use-cached-data";
import {EE_CONFIG, EO_CONFIG} from "@/app/_components/production/config";
import {ProductionExamBriefingSheet} from "@/app/_components/production/ProductionExamBriefingSheet";
import {ExamIntroSheet} from "./ExamIntroSheet";

/**
 * Ce qu'un point d'entrée demande : l'examen à lancer — servi par son
 * descripteur (Plan, Accueil, Réviser…) ou par la grille — et **sa propre
 * porte d'offre** sur un 403 (sa `ctaLocation`, son écran : la mesure
 * d'audience ne bouge pas).
 */
export type MockExamLaunch =
  | {
      kind: "PRODUCTION";
      epreuve: "TCF_EE" | "TCF_EO";
      slotNumber: number;
      onPaywall: () => void;
    }
  | {
      kind: "COMPREHENSION";
      questionType: Extract<QuestionType, "CO" | "CE" | "STRUCTURE">;
      /** Intitulé et durée annoncée de l'épreuve, lus par l'appelant dans la
       *  table de référence (`lib/exam-durations.ts`). */
      title: string;
      durationLabel: string;
      slotNumber: number;
      /** Visiteur : voie publique (attempt anonyme), jamais l'API authentifiée. */
      guest?: boolean;
      onPaywall: () => void;
      /** Appelé avec l'attempt créé, avant la navigation (marque d'analytics
       *  posée par la mesure d'un domaine). */
      onStarted?: (attemptId: string) => void;
    }
  | {
      /** L'examen blanc d'un **thème civique** (20 questions du thème) — la
       *  grille du thème et l'étape d'examen d'un bloc du Plan civique, dont le
       *  thème et le créneau sont servis (`JourneyStepDto.examenTheme`). */
      kind: "CIVIQUE";
      themeId: string;
      /** L'intitulé du thème, tel qu'il est servi. */
      themeName: string;
      slotNumber: number;
      /** Visiteur : voie publique (attempt anonyme), jamais l'API authentifiée. */
      guest?: boolean;
      onPaywall: () => void;
    };

type Launch = (request: MockExamLaunch) => void;

const LauncherContext = createContext<Launch | null>(null);

/** Ce que la feuille d'un examen de thème civique annonce. Miroir mobile :
 *  `showCiviqueThemeExamBriefingSheet`. */
const CIVIC_THEME_EXAM_FACTS = [
  {label: "questions du thème", value: "20"},
  {label: "en conditions réelles", value: "20 min"},
  {label: "seuil de réussite", value: "16/20", highlight: true},
];

const CIVIC_THEME_EXAM_TIPS = [
  "Aucune correction pendant l'examen : votre résultat s'affiche à la fin.",
  "Le chronomètre tourne et l'examen se termine automatiquement à la fin du temps.",
  "Pas de retour en arrière : une réponse validée est définitive, comme le jour J.",
];

/**
 * **LE point de lancement d'un examen blanc d'épreuve TCF — et d'un thème
 * civique — du web** — miroir de `launchProductionExam` (EE/EO,
 * `production_exam_launcher.dart`), de `showModuleExamBriefingSheet` (CO/CE)
 * et de `launchCiviqueThemeExam` (thème civique) côté mobile.
 *
 * Tous les points d'entrée passent par lui — la grille « Examens blancs » de
 * l'épreuve, l'Accueil, le Plan (jalon, étape « Examen blanc », séance),
 * Réviser, la fiche d'un domaine ou d'une compétence — et il fait toujours la
 * même chose : **la feuille d'information d'abord**, puis, au clic, la
 * création de l'attempt et la première question / la tâche 1.
 *
 * 🛑 **Le chrono ne part qu'au clic.** Il est ancré sur `startedAt` de
 * l'attempt : le créer à l'ouverture de la feuille ferait courir le temps
 * pendant la lecture.
 *
 * Monté **une fois** à la racine (`app/layout.tsx`) : les lanceurs du Plan
 * sont des hooks utilisés par neuf écrans, aucun n'a à rendre la feuille.
 */
export function MockExamLauncherProvider({children}: {children: ReactNode}) {
  const router = useRouter();
  const {status} = useAuth();
  const [request, setRequest] = useState<MockExamLaunch | null>(null);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Le déroulé EE/EO lit ses contraintes sur les sujets servis — même clé de
  // cache que la liste des tâches et la grille : aucun appel de plus s'ils ont
  // déjà été vus.
  const productionEpreuve = request?.kind === "PRODUCTION" ? request.epreuve : null;
  const tasksQuery = useCachedData(
    status === "authenticated" && productionEpreuve ? productionTasksKey(productionEpreuve) : null,
    () => loadEpreuveTasks(productionApi, productionEpreuve ?? "TCF_EE"),
  );

  const launch = useCallback<Launch>((next) => {
    setError(null);
    setStarting(false);
    setRequest(next);
  }, []);

  const close = useCallback(() => {
    if (starting) return;
    setRequest(null);
    setError(null);
  }, [starting]);

  const start = useCallback(async () => {
    if (!request || starting) return;
    // Dans le clic, avant tout `await` : la 1re question CO partira seule.
    if (request.kind === "COMPREHENSION" && request.questionType === "CO") unlockCoAudio();
    setError(null);
    setStarting(true);
    // L'écran d'où l'examen part (la feuille est posée dessus) : le bilan y
    // ramène par son « Retour » (`retourExamenDe`).
    const origine = adresseCourante();
    try {
      if (request.kind === "PRODUCTION") {
        const config = request.epreuve === "TCF_EO" ? EO_CONFIG : EE_CONFIG;
        const attempt = await productionApi.startAttempt({
          module: "TCF",
          epreuve: config.epreuve,
          exam: true,
          slotNumber: request.slotNumber,
        });
        router.push(withRetour(`${config.base}/session/${attempt.id}`, origine));
      } else if (request.kind === "CIVIQUE") {
        const body = {
          type: "MOCK_EXAM" as const,
          module: "CIVIQUE" as const,
          themeId: request.themeId,
          slotNumber: request.slotNumber,
        };
        const attempt = request.guest
          ? await publicAttemptApi.startDemo(body)
          : await attemptApi.start(body);
        router.push(withRetour(`/sessions/${attempt.id}`, origine));
      } else {
        const body = {
          type: "MOCK_EXAM" as const,
          module: "TCF" as const,
          moduleExamQuestionType: request.questionType,
          slotNumber: request.slotNumber,
        };
        const attempt = request.guest
          ? await publicAttemptApi.startDemo(body)
          : await attemptApi.start(body);
        request.onStarted?.(attempt.id);
        router.push(withRetour(`/sessions/${attempt.id}`, origine));
      }
      setRequest(null);
    } catch (e) {
      handleStartFailure(e, {
        // Une seule feuille à la fois : la nôtre se ferme avant l'offre.
        onPaywall: () => {
          setRequest(null);
          request.onPaywall();
        },
        onMessage: setError,
        fallbackMessage: "Impossible de démarrer l'examen.",
      });
    } finally {
      setStarting(false);
    }
  }, [request, starting, router]);

  let sheet: ReactNode = null;
  if (request?.kind === "PRODUCTION") {
    sheet = (
      <ProductionExamBriefingSheet
        open
        epreuve={request.epreuve}
        tasks={tasksQuery.data ?? null}
        starting={starting}
        error={error}
        onStart={() => void start()}
        onClose={close}
      />
    );
  } else if (request?.kind === "CIVIQUE") {
    sheet = (
      <ExamIntroSheet
        open
        eyebrow={`Examen blanc · ${request.themeName}`}
        title={`${request.themeName} en conditions réelles`}
        subtitle="Avant de commencer, voici comment se déroule l'examen."
        facts={CIVIC_THEME_EXAM_FACTS}
        tips={CIVIC_THEME_EXAM_TIPS}
        loading={starting}
        error={error}
        onConfirm={() => void start()}
        onClose={close}
      />
    );
  } else if (request?.kind === "COMPREHENSION") {
    const intro = comprehensionExamIntro(request.questionType, "25", request.durationLabel);
    sheet = (
      <ExamIntroSheet
        open
        eyebrow={`Examen blanc · ${request.title}`}
        title={`${request.title} en conditions réelles`}
        subtitle="Avant de commencer, voici comment se déroule l'épreuve."
        facts={intro.facts}
        tips={intro.tips}
        loading={starting}
        error={error}
        onConfirm={() => void start()}
        onClose={close}
      />
    );
  }

  return (
    <LauncherContext.Provider value={launch}>
      {children}
      {sheet}
    </LauncherContext.Provider>
  );
}

/** Ouvre la feuille d'information puis démarre l'examen blanc demandé. */
export function useMockExamLauncher(): Launch {
  const launch = useContext(LauncherContext);
  if (!launch) {
    throw new Error("useMockExamLauncher doit être rendu sous MockExamLauncherProvider.");
  }
  return launch;
}
