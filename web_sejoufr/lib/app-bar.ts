/**
 * **Le titre d'un écran connecté dans la barre du haut** (`AppTopBar`) — la
 * page du fil d'Ariane `SejourFR / {Section} / {Page}` sur un sous-écran.
 * Sur l'adresse racine d'une entrée de menu, le fil prend le libellé du menu
 * (`shellCrumb`, `lib/shell-nav.ts`) ; la section vient du module de l'entrée.
 *
 * 🛑 **L'autorité unique du titre par défaut.** Une route, un titre : on ne
 * l'écrit ni dans la page, ni dans le composant. Correspondance par **préfixe
 * le plus long** — `/profil/informations/email` l'emporte sur `/profil`.
 *
 * ⚠️ **Un titre de donnée (un thème, une épreuve de progression, un sujet) ne
 * s'invente pas ici** : la table donne le **parent**, repli du rendu serveur ;
 * la page pose elle-même le titre de son `ScreenHeader` Flutter
 * (`useAppBarTitle`, `app/_components/AppBarTitle.tsx`).
 */
import {AIDE_TITLE} from "./aide";
import {
  COMPTE_EMAIL_TITLE,
  COMPTE_IDENTITY_TITLE,
  COMPTE_INFO_TITLE,
  COMPTE_NOTIF_TITLE,
  COMPTE_PASSWORD_TITLE,
} from "./compte";
import {FAVORIS_TITLE} from "./favoris";
import {JOURNEY_HISTORY_TITLE} from "./journey";
import {questionTypeLabel, SKILL_SECTION_LABEL} from "./types";

export interface AppBarInfo {
  title: string;
}

const TCF = "TCF IRN";
const CIVIQUE = "Examen civique";

const APP_BAR_ROUTES: ReadonlyArray<readonly [prefix: string, info: AppBarInfo]> = [
  ["/dashboard", {title: "Accueil"}],

  ["/plan", {title: "Plan"}],
  ["/plan/progression", {title: JOURNEY_HISTORY_TITLE}],
  ["/plan/progression/cycle", {title: "Cycle terminé"}],

  ["/progression/tcf", {title: "Progression"}],
  ["/progression/civique", {title: "Progression"}],

  ["/diagnostic", {title: "Diagnostic"}],
  ["/diagnostic-civique", {title: "Diagnostic"}],

  ["/entrainement/tcf", {title: TCF}],
  ["/entrainement/tcf/co", {title: SKILL_SECTION_LABEL.CO}],
  ["/entrainement/tcf/ce", {title: SKILL_SECTION_LABEL.CE}],
  ["/entrainement/tcf/ee", {title: SKILL_SECTION_LABEL.EE}],
  ["/entrainement/tcf/eo", {title: SKILL_SECTION_LABEL.EO}],
  ["/entrainement/tcf/structure", {title: questionTypeLabel("STRUCTURE")}],
  ["/entrainement/civique", {title: CIVIQUE}],

  ["/entrainement", {title: "Entraînement"}],
  ["/examens-blancs", {title: "Examens blancs"}],
  ["/sessions", {title: "Entraînement"}],

  ["/parcours", {title: "Mon objectif"}],
  ["/paiement", {title: "Paiement"}],

  ["/profil", {title: "Profil"}],
  ["/profil/abonnement", {title: "Mon pass"}],
  ["/profil/informations", {title: COMPTE_INFO_TITLE}],
  ["/profil/informations/identite", {title: COMPTE_IDENTITY_TITLE}],
  ["/profil/informations/email", {title: COMPTE_EMAIL_TITLE}],
  ["/profil/informations/mot-de-passe", {title: COMPTE_PASSWORD_TITLE}],
  ["/profil/notifications", {title: COMPTE_NOTIF_TITLE}],
  ["/favoris", {title: FAVORIS_TITLE}],
  ["/aide", {title: AIDE_TITLE}],
];

/**
 * `/sessions/[attemptId]` : runner et rapport sur la même route, le titre suit
 * la phase et le type d'attempt servi (posé par la page, `useAppBarTitle`).
 * Miroir des écrans Flutter : `ExamResultScreen` (« Résultat », fin à chaud
 * d'un examen blanc et d'un entraînement), `ExamReportScreen` (« Rapport
 * d'examen », « Bilan de la série » pour une série). Le runner Flutter n'a pas
 * de titre (en-tête de progression) : la barre dit la nature de la session.
 */
export function sessionAppBarInfo(s: {
  phase: "running" | "result";
  isExam: boolean;
  isDiagnostic: boolean;
  isSerie: boolean;
  openedAsFinished: boolean;
}): AppBarInfo {
  if (s.phase === "running") {
    if (s.isDiagnostic) return {title: "Diagnostic"};
    return {title: s.isExam ? "Examen blanc" : "Entraînement"};
  }
  if (s.isSerie && !s.isExam) return {title: "Bilan de la série"};
  if (s.openedAsFinished) return {title: "Rapport d'examen"};
  return {title: "Résultat"};
}

const FALLBACK: AppBarInfo = {title: "SejourFR"};

function matches(pathname: string, prefix: string): boolean {
  return pathname === prefix || pathname.startsWith(`${prefix}/`);
}

/** Le titre de la barre pour `pathname` (préfixe le plus long). */
export function appBarInfo(pathname: string | null): AppBarInfo {
  if (!pathname) return FALLBACK;
  let best: readonly [string, AppBarInfo] | null = null;
  for (const entry of APP_BAR_ROUTES) {
    if (matches(pathname, entry[0]) && (!best || entry[0].length > best[0].length)) {
      best = entry;
    }
  }
  return best ? best[1] : FALLBACK;
}
