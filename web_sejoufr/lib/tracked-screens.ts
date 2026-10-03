/**
 * Les écrans métier suivis par `SCREEN_VIEWED` — **le seul endroit du web où
 * ils sont déclarés**. Miroir de `mobile_sejourfr/lib/core/analytics/tracked_screens.dart`
 * (mêmes clés) et de `enums/TrackedScreen.java` côté serveur, qui fait
 * autorité et alimente `AnalyticsPaths.KNOWN`.
 *
 * `path` est le **gabarit** envoyé, jamais l'adresse concrète : aucun
 * identifiant, aucun paramètre de requête. Il est écrit en minuscules, comme
 * le serveur le normalise. `route` reconnaît l'adresse affichée (déjà mise en
 * minuscules, sans `/` final) ; les segments variables sont bornés aux valeurs
 * réelles quand une page statique voisine partage la même forme
 * (`/entrainement/tcf/ee/examens` n'est pas un « lot par niveau »).
 *
 * Une adresse absente de la table part avec `path: null` (« écran non
 * déclaré »). Ajouter un écran = une ligne ici, une dans le fichier Dart et
 * une dans `TrackedScreen`, dans la même passe.
 */

export type TrackedScreenKey =
  | "VITRINE"
  | "LANDING_REUSSIR"
  | "ACCUEIL"
  | "CONNEXION"
  | "INSCRIPTION"
  | "DIAGNOSTIC_TCF"
  | "DIAGNOSTIC_TCF_RESULTAT"
  | "DIAGNOSTIC_CIVIQUE"
  | "DIAGNOSTIC_CIVIQUE_RESULTAT"
  | "PLAN"
  | "PLAN_ETAPE"
  | "PLAN_DOMAINE"
  | "PLAN_DEBLOQUER"
  | "PLAN_PROGRESSION"
  | "PROGRESSION_TCF"
  | "PROGRESSION_TCF_EPREUVE"
  | "PROGRESSION_CIVIQUE"
  | "PROGRESSION_CIVIQUE_THEME"
  | "REVISER"
  | "THEME_CIVIQUE"
  | "EPREUVE_TCF"
  | "LOTS_NIVEAU"
  | "EE_HUB"
  | "EO_HUB"
  | "EE_TACHE"
  | "EO_TACHE"
  | "COMPETENCES_TACHE"
  | "SEANCE_QCM"
  | "RESULTAT_EE"
  | "RESULTAT_EO"
  | "EXAMENS_BLANCS"
  | "EXAMEN_TCF"
  | "EXAMEN_TCF_BILAN"
  | "TARIFS"
  | "PAIEMENT"
  | "PROFIL";

type TrackedScreen = {
  key: TrackedScreenKey;
  path: string;
  route: RegExp;
};

const SEGMENT = "[^/]+";
const QCM_EPREUVE = "(?:co|ce|structure)";
const NIVEAU = "(?:a2|b1|b2)";

function exact(path: string): RegExp {
  return new RegExp(`^${path.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`);
}

function pattern(source: string): RegExp {
  return new RegExp(`^${source}$`);
}

const SCREENS: ReadonlyArray<TrackedScreen> = [
  {key: "VITRINE", path: "/", route: exact("/")},
  {key: "LANDING_REUSSIR", path: "/reussir", route: exact("/reussir")},
  {key: "ACCUEIL", path: "/dashboard", route: exact("/dashboard")},
  {key: "CONNEXION", path: "/connexion", route: exact("/connexion")},
  {key: "INSCRIPTION", path: "/inscription", route: exact("/inscription")},
  {key: "DIAGNOSTIC_TCF", path: "/diagnostic", route: exact("/diagnostic")},
  {key: "DIAGNOSTIC_TCF_RESULTAT", path: "/diagnostic/resultat", route: exact("/diagnostic/resultat")},
  {key: "DIAGNOSTIC_CIVIQUE", path: "/diagnostic-civique", route: exact("/diagnostic-civique")},
  {
    key: "DIAGNOSTIC_CIVIQUE_RESULTAT",
    path: "/diagnostic-civique/resultat",
    route: pattern(`/diagnostic-civique/${SEGMENT}/resultat`),
  },
  {key: "PLAN", path: "/plan", route: exact("/plan")},
  {key: "PLAN_ETAPE", path: "/plan/etape/:id", route: pattern(`/plan/etape/${SEGMENT}`)},
  {key: "PLAN_DOMAINE", path: "/plan/domaine/:domaine", route: pattern(`/plan/domaine/${SEGMENT}`)},
  {key: "PLAN_DEBLOQUER", path: "/plan/debloquer", route: exact("/plan/debloquer")},
  {key: "PLAN_PROGRESSION", path: "/plan/progression", route: exact("/plan/progression")},
  {key: "PROGRESSION_TCF", path: "/progression/tcf", route: exact("/progression/tcf")},
  {
    key: "PROGRESSION_TCF_EPREUVE",
    path: "/progression/tcf/:epreuve",
    route: pattern(`/progression/tcf/${SEGMENT}`),
  },
  {key: "PROGRESSION_CIVIQUE", path: "/progression/civique", route: exact("/progression/civique")},
  {
    key: "PROGRESSION_CIVIQUE_THEME",
    path: "/progression/civique/:theme",
    route: pattern(`/progression/civique/${SEGMENT}`),
  },
  {key: "REVISER", path: "/entrainement", route: exact("/entrainement")},
  {
    key: "THEME_CIVIQUE",
    path: "/entrainement/civique/:theme",
    route: pattern(`/entrainement/civique/${SEGMENT}`),
  },
  {
    key: "EPREUVE_TCF",
    path: "/entrainement/tcf/:epreuve",
    route: pattern(`/entrainement/tcf/${QCM_EPREUVE}`),
  },
  {
    key: "LOTS_NIVEAU",
    path: "/entrainement/tcf/:epreuve/:niveau",
    route: pattern(`/entrainement/tcf/${QCM_EPREUVE}/${NIVEAU}`),
  },
  {key: "EE_HUB", path: "/entrainement/tcf/ee", route: exact("/entrainement/tcf/ee")},
  {key: "EO_HUB", path: "/entrainement/tcf/eo", route: exact("/entrainement/tcf/eo")},
  {
    key: "EE_TACHE",
    path: "/entrainement/tcf/ee/tache/:tache",
    route: pattern(`/entrainement/tcf/ee/tache/${SEGMENT}`),
  },
  {
    key: "EO_TACHE",
    path: "/entrainement/tcf/eo/tache/:tache",
    route: pattern(`/entrainement/tcf/eo/tache/${SEGMENT}`),
  },
  {
    key: "COMPETENCES_TACHE",
    path: "/entrainement/tcf/:epreuve/tache/:tache/competences",
    route: pattern(`/entrainement/tcf/(?:ee|eo)/tache/${SEGMENT}/competences`),
  },
  {key: "SEANCE_QCM", path: "/sessions/:id", route: pattern(`/sessions/${SEGMENT}`)},
  {
    key: "RESULTAT_EE",
    path: "/entrainement/tcf/ee/resultats/:id",
    route: pattern(`/entrainement/tcf/ee/resultats/${SEGMENT}`),
  },
  {
    key: "RESULTAT_EO",
    path: "/entrainement/tcf/eo/resultats/:id",
    route: pattern(`/entrainement/tcf/eo/resultats/${SEGMENT}`),
  },
  {key: "EXAMENS_BLANCS", path: "/examens-blancs", route: exact("/examens-blancs")},
  {key: "EXAMEN_TCF", path: "/examens-blancs/tcf/:id", route: pattern(`/examens-blancs/tcf/${SEGMENT}`)},
  {
    key: "EXAMEN_TCF_BILAN",
    path: "/examens-blancs/tcf/:id/bilan",
    route: pattern(`/examens-blancs/tcf/${SEGMENT}/bilan`),
  },
  {key: "TARIFS", path: "/tarifs", route: exact("/tarifs")},
  {key: "PAIEMENT", path: "/paiement", route: exact("/paiement")},
  {key: "PROFIL", path: "/profil", route: exact("/profil")},
];

/** Gabarit suivi de cette adresse, ou `null` (écran non déclaré). */
export function trackedScreenPath(raw: string | null | undefined): string | null {
  if (!raw) return null;
  let path = raw.split(/[?#]/)[0].trim().toLowerCase();
  if (path.length > 1 && path.endsWith("/")) path = path.slice(0, -1);
  if (!path) path = "/";
  return SCREENS.find((screen) => screen.route.test(path))?.path ?? null;
}
