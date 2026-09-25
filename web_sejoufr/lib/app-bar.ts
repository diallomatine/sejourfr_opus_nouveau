/**
 * **Ce que dit la barre du haut de l'espace connecté, sous 900 px** (`AppTopBar`).
 *
 * 🛑 **L'autorité unique du titre de la barre.** Une route, un titre : on ne
 * l'écrit ni dans la page, ni dans le composant. Correspondance par **préfixe
 * le plus long** — `/profil/informations/email` l'emporte sur `/profil`.
 *
 * Les titres sont ceux des en-têtes de l'app Flutter pour le même écran :
 * l'onglet de la barre du bas pour les écrans d'onglet (Accueil, Plan,
 * Réviser, Examens blancs, Profil), le `ScreenHeader` pour les écrans du
 * compte, du centre d'aide et des favoris (mêmes constantes que la page).
 *
 * ⚠️ **Un titre de donnée (un thème, une épreuve de progression, un sujet) ne
 * s'invente pas ici** : la table donne le **parent** (« Examen civique »,
 * « Progression »), repli du rendu serveur.
 *
 * Seconde voie : la page pose elle-même le titre de son `ScreenHeader` Flutter
 * (`useAppBarTitle`, `app/_components/AppBarTitle.tsx`) — le Plan, et les
 * coquilles de sous-écran (`DetailShell`, `SkillShell` avec `title`), qui
 * montent leur titre + ligne de contexte dans la barre. La table reste le
 * repli. La flèche de retour d'un sous-écran suit la même voie
 * (`useAppBarBack`).
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
import {moduleDeLUrl} from "./module-switch";
import {questionTypeLabel, SKILL_SECTION_LABEL} from "./types";

export interface AppBarInfo {
  title: string;
  /** Une ligne de contexte courte (le parcours), jamais une donnée de la page. */
  subtitle?: string;
}

const TCF = "TCF IRN";
const CIVIQUE = "Examen civique";

const APP_BAR_ROUTES: ReadonlyArray<readonly [prefix: string, info: AppBarInfo]> = [
  ["/dashboard", {title: "Accueil"}],

  ["/plan", {title: "Plan"}],
  ["/plan/progression", {title: JOURNEY_HISTORY_TITLE, subtitle: "Plan"}],

  ["/progression/tcf", {title: "Progression", subtitle: TCF}],
  ["/progression/civique", {title: "Progression", subtitle: CIVIQUE}],

  ["/diagnostic", {title: "Diagnostic"}],
  ["/diagnostic-tcf", {title: "Diagnostic", subtitle: TCF}],
  ["/diagnostic-civique", {title: "Diagnostic", subtitle: CIVIQUE}],

  ["/entrainement/tcf", {title: TCF}],
  ["/entrainement/tcf/co", {title: SKILL_SECTION_LABEL.CO, subtitle: TCF}],
  ["/entrainement/tcf/ce", {title: SKILL_SECTION_LABEL.CE, subtitle: TCF}],
  ["/entrainement/tcf/ee", {title: SKILL_SECTION_LABEL.EE, subtitle: TCF}],
  ["/entrainement/tcf/eo", {title: SKILL_SECTION_LABEL.EO, subtitle: TCF}],
  ["/entrainement/tcf/structure", {title: questionTypeLabel("STRUCTURE"), subtitle: TCF}],
  ["/entrainement/civique", {title: CIVIQUE}],

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

/**
 * Le titre de la barre pour `pathname`. `searchParams` ne sert qu'à Réviser
 * (`/entrainement?module=`), dont le parcours est dans l'URL et pas le chemin.
 */
export function appBarInfo(
  pathname: string | null,
  searchParams?: {get(name: string): string | null} | null,
): AppBarInfo {
  if (!pathname) return FALLBACK;
  if (pathname === "/entrainement") {
    return {
      title: "Réviser",
      subtitle: moduleDeLUrl(searchParams) === "TCF" ? TCF : CIVIQUE,
    };
  }
  let best: readonly [string, AppBarInfo] | null = null;
  for (const entry of APP_BAR_ROUTES) {
    if (matches(pathname, entry[0]) && (!best || entry[0].length > best[0].length)) {
      best = entry;
    }
  }
  return best ? best[1] : FALLBACK;
}
