# Activité des utilisateurs — décisions d'implémentation

> Fichier partagé par les agents du chantier (backend, web/mobile, admin). Chacun n'écrit
> **que dans ses sections**, et relit le fichier juste avant d'écrire.
> Référence : `plan-technique-activite.md` (plan validé) et `audit-activite-utilisateurs.md`.

---

## Contrat (publié par l'agent backend — fait foi pour web, mobile et admin)

> Dernière mise à jour : 2026-10-03 (agent backend ; révision : tolérance des chemins en lot,
> rétention 365 j des `SCREEN_VIEWED`). Toute modification ultérieure du
> contrat est faite ICI et signalée dans le journal « Backend » ci-dessous.

### 1. Heartbeat candidat (web + mobile)

| | |
|---|---|
| Méthode / chemin | `POST /api/me/presence` |
| Corps | **aucun** (pas de `Content-Type` requis) |
| En-têtes | `Authorization: Bearer <access>` (obligatoire) + les en-têtes de contexte habituels, au minimum `X-Sejourfr-Client: web\|ios\|android` (c'est lui qui range la présence par plateforme) |
| Réponse | **204** sans corps. **401** sans jeton ou jeton expiré (le refresh automatique du client s'applique comme pour toute requête) |
| Cadence | un battement immédiat au retour au premier plan, puis toutes les **60 s**, **premier plan uniquement**, compte connecté uniquement |
| Échec | silencieux, aucun rejeu |

Notes :
- Le heartbeat n'a **aucune logique propre** : c'est n'importe quelle requête authentifiée qui
  compte comme activité (filtre serveur, au plus une écriture par minute, par compte, par
  plateforme et par jour). Le heartbeat sert seulement à couvrir les phases sans requête
  (lecture d'un écran, chrono d'examen).
- **Ne comptent pas** : `/api/auth/**` (login, refresh, logout, `me`),
  `/api/public/analytics/**` (file d'analytics), `/files/**`, `/actuator/**`, `/error`, et
  toute requête `OPTIONS`. Une autre route publique appelée **avec** un jeton valide compte.
- Plateforme : `X-Sejourfr-Client` lu par `ClientContextResolver` (`web`/`ios`/`android` ;
  `mobile` = ancienne app ⇒ « App — système inconnu » ; absent ⇒ « Non déclarée »).
- « En ligne » = compte dont la dernière activité date de moins de **180 s** (fenêtre servie
  dans `windowSeconds`, cf. journal DI-B04).

### 2. Événement `SCREEN_VIEWED` (web + mobile)

Envoyé par la file d'analytics existante : `POST /api/public/analytics/events/batch`, un
élément de `events[]` par affichage d'écran.

```json
{
  "eventId": "<UUID v4 tiré par le client, une fois par affichage>",
  "event": "SCREEN_VIEWED",
  "occurredAt": "2026-10-03T08:15:30Z",
  "path": "/plan/etape/:id",
  "properties": {}
}
```

- **Aucune propriété admise** (`properties` vide ou absent). Une propriété ⇒ l'événement est
  rejeté seul (le lot reste en 202).
- **Pas de** `diagnosticRunId` / `diagnosticType` / `journeyId` (rejet sinon).
- `path` = **gabarit** suivi de la table ci-dessous, **jamais une URL concrète** (aucun
  identifiant). Normalisation serveur : minuscules, sans query-string, sans `/` final — les
  gabarits sont donc écrits **en minuscules**, paramètres compris (`:id`, pas `:stepId`).
- Écran non déclaré (route absente de la table) ⇒ `path: null` (ou absent). L'événement est
  accepté et compté « Écrans non déclarés ». Un `path` non nul **hors liste** n'est plus rejeté
  par l'ingestion **en lot** (révision 2026-10-03, DI-B12) : l'événement est gardé, son chemin
  est mis à `null` (donc « non déclaré ») ; idem pour une propriété `landingPath` hors liste,
  simplement omise. Les fronts continuent de n'envoyer que des gabarits listés.
- Rétention : les `SCREEN_VIEWED` sont purgés à **365 j** (historique d'activité), les autres
  événements restent à 395 j (DI-B11).
- Un écran ajouté plus tard = une ligne dans `TrackedScreen` (backend) **et** dans le front,
  dans la même passe.
- `SCREEN_VIEWED` est **exclu** du KPI « Visiteurs » et des sources de Suivi (D8).

**Écrans de référence** (autorité serveur : `enums/TrackedScreen.java`, qui alimente
`AnalyticsPaths.KNOWN`). Les libellés sont **servis** par l'endpoint admin.

| Clé | Libellé servi | Chemin web | Chemin app |
|---|---|---|---|
| `VITRINE` | Vitrine | `/` | — |
| `LANDING_REUSSIR` | Landing « Réussir » | `/reussir` | — |
| `ACCUEIL` | Accueil | `/dashboard` | `/home` |
| `CONNEXION` | Connexion | `/connexion` | `/login` |
| `INSCRIPTION` | Inscription | `/inscription` | `/register` |
| `DIAGNOSTIC_TCF` | Diagnostic TCF rapide | `/diagnostic` | `/diagnostic` |
| `DIAGNOSTIC_TCF_RESULTAT` | Résultat du diagnostic TCF | `/diagnostic/resultat` | — |
| `DIAGNOSTIC_CIVIQUE` | Diagnostic civique | `/diagnostic-civique` | `/diagnostic-civique` |
| `DIAGNOSTIC_CIVIQUE_RESULTAT` | Résultat du diagnostic civique | `/diagnostic-civique/resultat` | `/diagnostic-civique/resultat` |
| `PLAN` | Plan | `/plan` | `/plan` |
| `PLAN_ETAPE` | Étape du Plan | `/plan/etape/:id` | `/plan/etape/:id` |
| `PLAN_DOMAINE` | Domaine du Plan | `/plan/domaine/:domaine` | `/plan/domaine/:domaine` |
| `PLAN_DEBLOQUER` | Débloquer le Plan | `/plan/debloquer` | `/plan/debloquer` |
| `PLAN_PROGRESSION` | Cycles du Plan | `/plan/progression` | `/plan/progression` |
| `PROGRESSION_TCF` | Ma progression TCF | `/progression/tcf` | `/progression/tcf` |
| `PROGRESSION_TCF_EPREUVE` | Progression d'une épreuve | `/progression/tcf/:epreuve` | `/progression/tcf/:epreuve` |
| `PROGRESSION_CIVIQUE` | Ma progression civique | `/progression/civique` | `/progression/civique` |
| `PROGRESSION_CIVIQUE_THEME` | Progression d'un thème | `/progression/civique/:theme` | `/progression/civique/:theme` |
| `REVISER` | Réviser | `/entrainement` | `/reviser` |
| `THEME_CIVIQUE` | Thème civique | `/entrainement/civique/:theme` | `/civique/theme/:theme` |
| `EPREUVE_TCF` | Épreuve TCF (CO, CE, structure) | `/entrainement/tcf/:epreuve` | `/tcf/:epreuve` |
| `LOTS_NIVEAU` | Lots par niveau | `/entrainement/tcf/:epreuve/:niveau` | `/tcf/:epreuve/niveau/:niveau` |
| `EE_HUB` | Expression écrite | `/entrainement/tcf/ee` | `/tcf/ee` |
| `EO_HUB` | Expression orale | `/entrainement/tcf/eo` | `/tcf/eo` |
| `EE_TACHE` | Tâche d'expression écrite | `/entrainement/tcf/ee/tache/:tache` | `/tcf/ee/tache/:tache` |
| `EO_TACHE` | Tâche d'expression orale | `/entrainement/tcf/eo/tache/:tache` | `/tcf/eo/tache/:tache` |
| `COMPETENCES_TACHE` | Compétences d'une tâche | `/entrainement/tcf/:epreuve/tache/:tache/competences` | `/tcf/:epreuve/tache/:tache/competences` |
| `SEANCE_QCM` | Séance d'entraînement | `/sessions/:id` | `/runner/:id` |
| `RESULTAT_EE` | Résultat d'expression écrite | `/entrainement/tcf/ee/resultats/:id` | `/tcf/expression-ecrite/resultats/:id` |
| `RESULTAT_EO` | Résultat d'expression orale | `/entrainement/tcf/eo/resultats/:id` | `/tcf/expression-orale/resultats/:id` |
| `EXAMENS_BLANCS` | Examens blancs | `/examens-blancs` | `/examens` |
| `EXAMEN_TCF` | Examen blanc TCF complet | `/examens-blancs/tcf/:id` | `/tcf/examen-blanc/:id` |
| `EXAMEN_TCF_BILAN` | Bilan d'examen blanc | `/examens-blancs/tcf/:id/bilan` | `/tcf/examen-blanc/:id/bilan` |
| `TARIFS` | Tarifs | `/tarifs` | — |
| `PAIEMENT` | Paiement | `/paiement` | — |
| `PROFIL` | Profil | `/profil` | `/profile` |

Précisions :
- `EPREUVE_TCF` : `:epreuve` couvre `co`, `ce`, `structure` (les hubs `ee`/`eo` ont leur
  propre ligne). `COMPETENCES_TACHE` : `:epreuve` = `ee` ou `eo`.
- Côté app, c'est le **gabarit go_router** qui est traduit vers le chemin de la colonne
  « app » ; un paramètre n'est jamais remplacé par sa valeur.
- Les chemins historiques de `AnalyticsPaths.KNOWN` (`/competences`, `/target-path`,
  `/paywall`) restent admis ; un `SCREEN_VIEWED` qui les porte est servi avec le chemin pour
  libellé.

### 3. Endpoints admin (lot 4)

Rôle `ADMIN` (401 anonyme, 403 USER). Instants en ISO-8601 UTC, jours en `yyyy-MM-dd`
(Europe/Paris). 🛑 `null` = **non mesuré** (avant la date de début de mesure), jamais 0.
Aucun pourcentage ni libellé n'est calculé par le front : tout est servi.

#### 3.1 `GET /api/admin/analytics/activity/live?includeInternal=false`

Rafraîchi toutes les 30 s par l'admin (D11). Ne dépend d'aucune période.

```ts
export type ActivityPlatform = "WEB" | "IOS" | "ANDROID" | "MOBILE" | "UNKNOWN";

/** Une ligne par plateforme, TOUJOURS les cinq, dans cet ordre : WEB, IOS, ANDROID, MOBILE, UNKNOWN. */
export interface ActivityPlatformCount {
  platform: ActivityPlatform;
  /** "Web" | "iOS" | "Android" | "App — système inconnu" | "Non déclarée" */
  label: string;
  /** Faux pour UNKNOWN quand includeInternal = false (N6) : le front n'affiche pas la ligne. */
  displayed: boolean;
  value: number | null;
}

export interface AdminActivityLiveResponse {
  /** Instant de la mesure. */
  at: string;
  /** Fenêtre « en ligne » en secondes (180). */
  windowSeconds: number;
  includeInternal: boolean;
  /** Début de mesure de l'activité (indicateur ACTIVE_USERS) ; null = pas encore mesuré. */
  measurementStart: string | null;
  /** Comptes distincts en ligne, toutes plateformes (un compte compté une fois). null = non mesuré. */
  total: number | null;
  /** Comptes en ligne sur au moins deux plateformes. null = non mesuré. */
  multiPlatformUsers: number | null;
  /** Comptes distincts par plateforme. La somme peut dépasser `total` (multi-plateforme). */
  byPlatform: ActivityPlatformCount[];
}
```

#### 3.2 `GET /api/admin/analytics/activity`

Paramètres : `preset=TODAY|YESTERDAY|LAST_7_DAYS|LAST_30_DAYS|MONTH` (défaut `TODAY`) **ou**
`from`+`to` (`yyyy-MM-dd`, Paris, ≤ 365 j) — jamais les deux (400 nommé, mêmes règles que
`/suivi`) ; `includeInternal=false`.

```ts
export type SuiviPeriodPreset = "TODAY" | "YESTERDAY" | "LAST_7_DAYS" | "LAST_30_DAYS" | "MONTH";
export type ActivityIndicator = "ACTIVE_USERS" | "LOGINS" | "SCREEN_VIEWS_WEB" | "SCREEN_VIEWS_APP";

export interface ActivityKpi {
  value: number | null;
  /** Même mesure sur la période précédente de même durée ; null si elle n'est pas mesurée de bout en bout. */
  previous: number | null;
  /** Variation en %, une décimale ; null si previous est null ou vaut 0. */
  deltaPct: number | null;
}

export interface ActivityDailyPoint {
  day: string;                         // yyyy-MM-dd, un point par jour de la période, sans trou
  total: number | null;                // null = jour non mesuré
  byPlatform: ActivityPlatformCount[]; // les cinq plateformes
}

export interface ActivityPlatformRow {
  platform: ActivityPlatform;
  label: string;
  displayed: boolean;
  /** Comptes actifs uniques sur la période et la plateforme. */
  activeUsers: number | null;
  /** Comptes uniques ayant ouvert au moins une session (login ou inscription). */
  loggedInUsers: number | null;
  /** Nombre de connexions (login + inscription). */
  logins: number | null;
}

export type ActivityLoginMethod = "LOCAL" | "GOOGLE" | "APPLE";

export interface ActivityMethodCount {
  method: ActivityLoginMethod;
  label: string;                       // "E-mail" | "Google" | "Apple"
  value: number | null;
}

export type ActivityScreenRowKind = "SCREEN" | "OTHER" | "UNDECLARED" | "TOTAL";

export interface ActivityScreenRow {
  kind: ActivityScreenRowKind;
  /** Gabarit suivi pour SCREEN ; null pour OTHER / UNDECLARED / TOTAL. */
  path: string | null;
  /** Libellé servi : écran de référence, sinon le chemin ; « Autres écrans suivis », « Écrans non déclarés », « Total ». */
  label: string;
  views: number;
  /** Identifiants de mesure (anonymous_id) distincts. */
  uniqueVisitors: number;
  /** Comptes distincts — PARTIEL (un lot envoyé sans jeton, ex. sendBeacon, n'a pas de compte). */
  uniqueUsers: number;
  /** Onglet App seulement (null sur l'onglet Web) : vues par système. */
  ios: number | null;
  android: number | null;
  appUnknownSystem: number | null;
}

export interface ActivityScreenTable {
  /** Premier jour mesuré dans la période (D117) ; null = non mesuré : rows vide, lignes de synthèse null. */
  measuredSince: string | null;
  /** Nombre maximal de lignes SCREEN servies (20). */
  topLimit: number;
  /** Les écrans les plus vus, vues décroissantes puis chemin. */
  rows: ActivityScreenRow[];
  /** Écrans suivis hors top (uniques calculés par le serveur, non additifs). */
  otherTracked: ActivityScreenRow | null;
  undeclared: ActivityScreenRow | null;
  total: ActivityScreenRow | null;
}

export interface AdminActivityResponse {
  window: {
    preset: SuiviPeriodPreset | null;  // null = période personnalisée
    from: string;
    to: string;
    previousFrom: string;
    previousTo: string;
    timezone: string;                  // "Europe/Paris"
    generatedAt: string;
  };
  includeInternal: boolean;
  /** Les quatre indicateurs ; null = pas encore mesuré. */
  measurementStart: Record<ActivityIndicator, string | null>;
  activeUsers: {
    measuredSince: string | null;
    total: ActivityKpi;
    multiPlatformUsers: number | null;
    daily: ActivityDailyPoint[];       // non additive : un compte actif 3 jours compte 3 fois dans la somme
  };
  logins: {
    measuredSince: string | null;
    /** Comptes uniques connectés (login ou inscription) sur la période. */
    uniqueUsers: ActivityKpi;
    /** Connexions (login + inscription). */
    total: number | null;
    /** Dont inscriptions. */
    signups: number | null;
    byMethod: ActivityMethodCount[];   // LOCAL, GOOGLE, APPLE
  };
  /** Tableau de répartition : les cinq plateformes, dans l'ordre. */
  platforms: ActivityPlatformRow[];
  screens: { web: ActivityScreenTable; app: ActivityScreenTable };
}
```

Règles de lecture :
- Un compte compte s'il a fait **au moins une requête authentifiée ou un heartbeat** sur la
  période (D1). Comptes internes (`users.is_internal`) exclus sauf `includeInternal=true`.
- Connexion = ouverture de session (login ou inscription, locale, Google ou Apple). **Un
  refresh n'est jamais une connexion** (D4).
- Onglet Web = événements de plateforme `WEB` ; onglet App = `IOS`, `ANDROID`, `MOBILE`.
- `screens.*.otherTracked` existe pour que le front n'additionne jamais des uniques.

#### 3.3 Changements de `GET /api/admin/analytics/suivi` (additifs)

- `preset` admet **`LAST_30_DAYS`** (aujourd'hui − 29 → aujourd'hui, Paris).
- `measurementStart` contient quatre clés de plus : `ACTIVE_USERS`, `LOGINS`,
  `SCREEN_VIEWS_WEB`, `SCREEN_VIEWS_APP` (le type `SuiviIndicator` de l'admin s'étend).
- Le KPI « Visiteurs » et les sources **ignorent** `SCREEN_VIEWED` (D8).

---

## Backend

> Journal de l'agent backend : problème · décision · raison · alternative rejetée.

**DI-B01 — Numéros de migration.** Problème : N1 demande de revérifier V086/V087. · Décision :
libres sur `develop` (dernier `V085`), donc `V086__refresh_tokens_purge.sql` (lot 1) et
`V087__schema_activite_utilisateurs.sql` (lot 2), DDL du plan à l'identique. · Rejeté : une
seule migration (le lot 1 doit pouvoir partir seul).

**DI-B02 — Purge de `refresh_tokens`.** Décision : `service/session/RefreshTokenPurgeJob`
(cron `sejourfr.security.jwt.refresh-token-purge-cron`, 04:25 Paris, `"-"` en test) →
`RefreshTokenPurgeService` (boucle, non transactionnelle) → `RefreshTokenManager.deleteExpiredBefore`
(une transaction par lot) → requête native bornée qui **remplace** l'ancien `deleteExpired`
(sans appelant). Marge 7 j et lot 1 000 dans `JwtProperties` + `application.yaml`, mêmes
valeurs. · Rejeté : nouvelle source de config (N5).

**DI-B03 — Écriture de `user_login_event` par `util/ApresCommit`.** Problème : le plan
proposait un événement Spring + `@TransactionalEventListener(AFTER_COMMIT)`. · Décision :
`SessionService.openSession(user, ua, ip, SessionOrigin)` appelle
`ApresCommit.executer(…, userLoginEventService::record)`, `record` en `REQUIRES_NEW`. ·
Raison : c'est l'autorité existante du dépôt pour « un crochet `REQUIRES_NEW` après commit »
(CLAUDE.md backend) ; elle avale et journalise l'échec, et s'exécute tout de suite hors
transaction (tests unitaires). Même garantie : un échec n'empêche jamais un login, un refresh
(`rotate`) n'écrit jamais. · Rejeté : classe d'événement + listener (deux classes pour le même
effet). `SessionOrigin(kind, method, platform)` : `method` = méthode de CETTE connexion
(`identity.provider()` en social), jamais `users.auth_provider`.

**DI-B04 — Fenêtre « en ligne » : 180 s, pas 120 s.** Problème : avec au plus une écriture par
minute (arbitrage) et un battement toutes les 60 s, un battement arrivé à 59,9 s est ignoré et
le suivant écrit à ~120 s : avec une fenêtre de 120 s, un compte présent clignoterait. ·
Décision : `activity.onlineWindowSeconds = 180` (servi dans `windowSeconds`), et le chargeur de
config refuse une fenêtre < 2 × intervalle d'écriture. · Rejeté : écrire plus d'une fois par
minute (contredit l'arbitrage) ; 150 s (libellé peu lisible).

**DI-B05 — Où l'activité est comptée.** Décision : `JwtAuthenticationFilter` pose l'attribut
`sejourfr.userId` (le `sub`) ; `security/UserActivityInterceptor` (branché par
`config/ActivityWebConfig` sur `/api/**`) lit la plateforme via `ClientContextResolver` et
appelle `service/activity/UserActivityService.touch` ; limitation Caffeine
(compte, plateforme, jour Paris) ; upsert natif `ON CONFLICT … GREATEST`. Exclusions :
`/api/auth/**`, `/api/public/analytics/**`, `/files/**`, `/actuator/**`, `/error`, `OPTIONS`.
Les autres routes `/api/public/**` appelées **avec** un jeton comptent (diagnostic d'un compte
connecté). · Rejeté : exclure tout `/api/public/**` (un compte qui passe un diagnostic est
actif). Un échec d'écriture invalide la clé de limitation (retenté à la requête suivante).

**DI-B06 — Heartbeat.** `POST /api/me/presence` → 204, contrôleur vide
(`MePresenceController`) : l'intercepteur est l'unique point d'écriture. Ajouté à
`AuthenticatedRoutesSecurityIT`.

**DI-B07 — Config analytics v2 (convention de versionnement).** Problème : `AnalyticsConfig`
gagne une section et `SuiviIndicator` quatre valeurs, que le chargeur exige — v1 ne pouvait plus
se charger. · Décision : `analytics-config-v1.json` **renommé** en `-v2.json` (`git mv`, même
geste que `campaigns-config` v1→v2), version par défaut 2 (POJO + YAML), et ajouts : section
`activity` (`retentionDays` 365, `writeIntervalSeconds` 60, `onlineWindowSeconds` 180,
`screenTopLimit` 20, `screenViewRetentionDays` 365), `perAnonymousIdBurst` 60 → 120, quatre
dates de début de mesure **à `null`** (`ACTIVE_USERS`, `LOGINS`, `SCREEN_VIEWS_WEB`,
`SCREEN_VIEWS_APP`, N4) — elles se posent au déploiement (D43). Surcharges dev au 2026-01-01
dans `application-dev.yaml`. · Rejeté : laisser v1 à côté (inchargeable : clés manquantes) ;
rendre les nouvelles clés facultatives (repli muet, contraire à la doctrine du chargeur).
⚠️ Si la prod fixe `ANALYTICS_CONFIG_VERSION=1`, le démarrage échoue : variable absente du dépôt,
à vérifier sur le serveur.

**DI-B08 — Autorité de la période.** Problème : Activité réutilise les presets de Suivi
(2ᵉ occurrence). · Décision : `SuiviPeriodPreset.window(today)` porte la table (avec
`LAST_30_DAYS`), `util/PeriodeAdmin.resolve` porte « preset ou from/to, jamais les deux », et
`FenetreMesure.precedente()` la période de comparaison ; `SuiviService` et `ActivityService`
les appellent. La règle D117 (lecture depuis la date de début, précédente mesurée de bout en
bout) est relue par `SuiviMapper.Mesure`, et la tendance par `SuiviMapper.delta`. · Rejeté :
copier le `switch` de `SuiviService`.

**DI-B09 — Registre des écrans.** Décision : `enums/TrackedScreen` (36 clés, libellé, chemin
web, chemin app) ; `AnalyticsPaths.KNOWN` = ses chemins + 3 historiques (`/competences`,
`/target-path`, `/paywall`). Gabarits **en minuscules** (`:id`, `:epreuve`…), puisque la
normalisation existante met tout en minuscules. Libellés servis par l'endpoint ; un chemin
historique sert de libellé à lui-même. · Rejeté : une table de libellés côté admin.

**DI-B10 — Réponse admin.** Écarts au § 3.4 du plan : (a) pas de bloc `live` dans la réponse de
période (endpoint séparé D11, sinon double coût) ; (b) libellés et `displayed` servis par ligne
de plateforme (`ClientPlatform.getLabel`, `AuthProvider.getLabel`, gelés par
`AnalyticsLabelsTest`) — `UNKNOWN` n'est `displayed` qu'avec `includeInternal` (N6) ; (c) top 20
**et** « Autres écrans suivis » calculés en SQL (les uniques ne s'additionnent pas) ; (d) trois
requêtes par période (activité + série, connexions, écrans des deux onglets), une pour le direct
— égalité verrouillée par `ActivityPerformanceIT`. Exclusion des internes sur les écrans : même
règle que Suivi, mais l'ensemble des identifiants internes est une sous-requête hachée (la
version corrélée par événement passait de 0,1 s à 7 s sans statistiques de table).

**DI-B11 — Rétention des `SCREEN_VIEWED` : 365 j** (demande du coordinateur, texte
`/confidentialite` du lot 3). Décision : `activity.screenViewRetentionDays` (365) dans la config
v2, appliqué par `AccountActivityRetentionService` (la passe d'activité de
`AnalyticsRetentionJob`, 04:10) via `AnalyticsEventManager.deleteEventOlderThan(SCREEN_VIEWED, …)`.
Les autres événements restent à `rawEventRetentionDays` (395 j). Test :
`AccountActivityRetentionServiceIT.purge365Jours`. · Rejeté : abaisser la rétention de tout
`analytics_event` (hors périmètre, touche l'exemption CNIL de Suivi).

**DI-B12 — Ingestion en lot tolérante aux chemins** (demande du coordinateur). Constat : le lot
n'était **pas** rejeté en entier (rejet individuel, 202) — mais l'événement au chemin inconnu,
lui, était perdu. Décision : en lot seulement, `path` hors liste ⇒ `null` (événement gardé,
« non déclaré »), propriété `landingPath` hors liste ⇒ omise ; toute autre faute reste un rejet
nommé. `AnalyticsPaths.normalizeOrThrow` (strict) est inchangé pour les autres appelants. Test :
`PublicAnalyticsBatchControllerIT.rejetPartiel` (mis à jour), `AnalyticsEventNormalizerTest`. ·
Rejeté : ajouter les chemins inconnus à l'allowlist (cardinalité infinie).

**DI-B13 — Suppression de compte.** `AccountDeletionService` supprime explicitement
`user_login_event` et `user_activity_day` (la ligne `users` survit à l'anonymisation). Les
`SCREEN_VIEWED` suivent le sort des autres événements (`detachUser` : ils redeviennent anonymes).

**DI-B14 — Tests de coût passant par HTTP.** Problème : l'upsert de présence, écrit au plus
une fois par minute, ajoutait une requête à la première mesure d'`AdminUserControllerIT.listeCoutConstant`
et pas à la seconde (10 ≠ 9). · Décision : la mesure appelle `UserActivityService.resetThrottle()`
juste avant l'appel : l'écriture devient systématique, comptée une fois dans chaque mesure,
l'égalité reste vraie. · Rejeté : écrire la présence hors Hibernate pour la cacher des
statistiques (masquerait un vrai coût).

**Points à valider avant prod (backend).**
1. Poser les dates `ACTIVE_USERS` / `LOGINS` (déploiement du lot 2) et `SCREEN_VIEWS_WEB` /
   `SCREEN_VIEWS_APP` (déploiement web / sortie store) dans `analytics-config-v2.json` : tant
   qu'elles sont `null`, l'écran affiche « non mesuré ».
2. Vérifier qu'aucune variable `ANALYTICS_CONFIG_VERSION=1` n'est posée sur le serveur.
3. Ordre de déploiement : backend lot 2 **avant** web lot 3 (le web envoie de nouveaux gabarits ;
   avec DI-B12 un écart ne coûte plus que le chemin, mais les écrans ne seraient pas nommés).
4. Validation CNIL des vues d'écran rattachées à un compte (risque n° 1 du plan), inchangée.
5. Le texte `/confidentialite` n'est pas servi par le backend (page web, DI-F10).

---

## Web & mobile

> Journal de l'agent web/mobile (lot 3) : problème · décision · raison · alternative rejetée.
> Contrat suivi : sections 1 et 2 ci-dessus (aucun écart de chemin ni de clé).

**DI-F01 — Où vivent les écrans déclarés.**
Problème : D7 exige une déclaration unique par front, en miroir. · Décision : web
`web_sejoufr/lib/tracked-screens.ts` (36 clés, gabarit + expression qui reconnaît l'adresse),
mobile `mobile_sejourfr/lib/core/analytics/tracked_screens.dart` (enum `TrackedScreen`, mêmes
36 clés, chemin app + gabarits go_router tirés d'`AppRoutes`). Les écrans sans équivalent app
(`VITRINE`, `LANDING_REUSSIR`, `DIAGNOSTIC_TCF_RESULTAT`, `TARIFS`, `PAIEMENT`) gardent leur clé
sans chemin. · Raison : clés identiques des deux côtés et au serveur, lecture ligne à ligne. ·
Rejeté : étendre `TRACKED_PATHS` + `DYNAMIC_PATHS` d'`analytics.ts` (deux listes pour une règle).

**DI-F02 — Web : le gabarit sert à TOUS les événements.**
Problème : `trackedPath` (ancienne liste) et la table des écrans auraient été deux autorités. ·
Décision : `analytics.ts` lit le chemin de tout événement dans `tracked-screens.ts` ; l'ancienne
liste est supprimée (dont `/competences`, sans page web). Effet : un événement existant émis
depuis un écran nouvellement déclaré (ex. `PLAN_OPENED` sur `/plan/etape/x`) porte désormais
`/plan/etape/:id` au lieu de `null`, et un `landingPath` de premier contact aussi. · Raison :
une règle, une autorité. · ⚠️ Conséquence de déploiement : le web du lot 3 ne doit partir
**qu'après** le backend du lot 2 (sinon un `landingPath` neuf rejette tout le lot). ·
Rejeté : garder l'ancienne liste pour les autres événements.

**DI-F03 — Web : segments variables bornés.**
Problème : `/entrainement/tcf/ee/examens` a la forme de `LOTS_NIVEAU` (`/entrainement/tcf/:epreuve/:niveau`). ·
Décision : `:epreuve` borné à `co|ce|structure` (et `ee|eo` pour `COMPETENCES_TACHE`),
`:niveau` à `a2|b1|b2` — les valeurs des pages. · Raison : une page statique voisine ne doit
jamais être comptée comme un autre écran. · Rejeté : priorité « statique d'abord » à la Next
(ne suffit pas : `examens` n'est pas dans la table).

**DI-F04 — Mobile : gabarit d'une route poussée (❓ du plan levé).**
Problème : go_router 14 donne-t-il le gabarit d'une route poussée ? · Décision : oui —
`GoRouter.state` (= `routerDelegate.state`) construit l'état de la feuille ; pour une
`ImperativeRouteMatch` il prend `matches.fullPath` (vérifié dans go_router 14.8.1,
`match.dart`). Un seul écouteur `routerDelegate.addListener` posé dans `routerProvider`,
logique dans `core/analytics/screen_view_tracker.dart`. · Rejeté : `NavigatorObserver` (ne voit
pas les changements d'onglet du `ShellRoute`, et ne donne pas le gabarit).

**DI-F05 — Dédoublonnage des vues.**
Problème : pas deux vues pour un même rendu. · Décision : une vue par **adresse** affichée
(web : `pathname` ; app : `state.uri.path`), comparée à la précédente. Une reconstruction, une
notification du routeur sur la même adresse (refresh d'auth), le double effet du mode strict
React ou un changement de seuls paramètres de requête ne comptent pas ; le retour sur un écran
(précédent du navigateur, dépilement go_router) compte, des deux côtés. Le retour au premier
plan ne recompte pas l'écran (des deux côtés). L'écran `/splash` est exclu (technique). ·
Rejeté : dédoublonner sur le gabarit (perdrait le passage d'une étape à une autre).

**DI-F06 — `SCREEN_VIEWED` pour tout visiteur.**
Problème : D3 borne le heartbeat aux comptes connectés ; et les écrans ? · Décision : tout
visiteur, comme les autres événements de la file (le contrat ne le borne pas ; le serveur
rattache le compte quand un jeton accompagne le lot). · Rejeté : réserver aux connectés (la
vitrine, la connexion et l'inscription n'auraient presque aucune vue).

**DI-F07 — Interrupteur CNIL.**
Problème : activation définitive à valider. · Décision : aucun interrupteur côté front — ni la
configuration servie ni le contrat n'en prévoient ; le serveur peut refuser ou ignorer
l'événement. · Rejeté : un drapeau front supplémentaire (consigne).

**DI-F08 — Heartbeat web.**
Décision : `lib/presence.ts` (sans React) + `app/_components/ActivityTracker.tsx` monté une
fois sous `AuthProvider` : armé quand `status === "authenticated"`, chaque battement vérifie
encore le jeton ; immédiat quand l'onglet devient visible (`visibilitychange`, `pageshow`),
puis `setInterval` 60 s ; arrêt sur `hidden` / `pagehide`. Appel `presenceApi.beat()` via
`apiFetch` (jeton, en-têtes de contexte, refresh normal sur 401). Problème : un 401 définitif
dans `apiFetch` renvoie vers `/connexion`, y compris depuis la vitrine ou un article. ·
Décision : option `redirectOnUnauthorized: false` sur ce seul appel (les jetons sont déjà
effacés par l'échec du refresh, les battements suivants s'arrêtent d'eux-mêmes). · Rejeté :
`fetch` direct (perdrait le refresh normal du client), ou laisser la redirection (un appel de
fond ne doit pas faire quitter la page).

**DI-F09 — Heartbeat mobile.**
Décision : `core/presence/presence_heartbeat.dart` (`presenceHeartbeatProvider`, observé par
`SejourFrApp` à côté de la file d'analytics) ; `AppLifecycleListener.onStateChange` : seul
`resumed` est le premier plan (`inactive`, `hidden`, `paused`, `detached` arrêtent) ; armé sur
`AuthAuthenticated` (écoute `authControllerProvider`), désarmé à la déconnexion ;
`PresenceRepository.beat()` = requête Dio ordinaire. Écart assumé avec le web : un 401
définitif suit le comportement normal de l'app (déconnexion globale), puisque toutes les
routes de l'app hors diagnostic sont authentifiées. · Rejeté : `skipRefresh` (couperait le
refresh normal ; la présence disparaîtrait après 60 min de lecture) ou un nouveau drapeau
« sans déconnexion » dans `ApiClient` (un comportement de plus pour un seul appel).

**DI-F10 — `/confidentialite` (N7).**
Décision : article 5, la ligne « Logs de connexion — 12 mois » devient deux lignes : « Adresse
IP et navigateur associés à une session de connexion — durée de la session + 7 jours » et
« Historique de connexion et d'activité (dates de connexion, jours d'activité, pages et écrans
consultés) — 12 mois, supprimé avec le compte ». Ajouts cohérents : 3.2 « Données d'activité de
votre compte » (signal par minute au premier plan seulement, écrans désignés par leur type),
article 4 une finalité « Mesure de l'activité des comptes » (intérêt légitime), 8.3 « la page
ou l'écran consulté (son type, jamais son adresse complète) » et le rattachement des écrans au
compte en statistiques agrégées, jamais en liste nominative. `LEGAL_INFO.lastUpdated` →
2026-10-03. Le mobile n'a pas de texte propre (WebView vers `/confidentialite`). · ⚠️ À valider :
les `SCREEN_VIEWED` vivent dans `analytics_event` (rétention 395 j, plan § 2.3) alors que le
texte, selon la consigne, dit 12 mois pour les pages et écrans d'un compte — purger
`SCREEN_VIEWED` à 365 j côté serveur, ou corriger le texte.

---

## Admin

> Journal de l'agent admin (lot 5) : problème · décision · raison · alternative rejetée.
> Contrat suivi : section 3 ci-dessus, vérifié contre les records Java
> (`AdminActivityResponse`, `AdminActivityLiveResponse`, `ActivityPlatformCount`) : aucun
> écart de nom, de type ni de nullabilité. Miroir : `admin_sejourfr/src/types/api.ts`
> (`ActivityPlatform`, `ActivityIndicator`, `AdminActivityResponse`, `AdminActivityLiveResponse`…),
> `SuiviPeriodPreset` + `LAST_30_DAYS`, `SuiviIndicator` + les quatre clés d'activité.

**DI-A01 — Période partagée Suivi / Activité.** Problème : Activité réutilise la lecture
`?period&from&to` et le sélecteur de Suivi (2ᵉ occurrence). · Décision : extraction dans
`lib/period.ts` (`PeriodId`, table id → preset, libellés, `readPeriod(params, offerts)`,
`writePeriod`, `rangeParams`, `comparedTo` avec « vs 30 jours précédents ») et
`components/ui/PeriodPicker` (sur une nouvelle primitive `Segmented`, qui sert aussi le
sélecteur de type de Suivi). `useSuiviParams` et `useActivityParams` ne gardent que leurs
filtres propres. Chaque écran déclare ses périodes offertes : Suivi garde « Mois », Activité
ne l'offre pas (une URL `?period=month` y retombe sur « Aujourd'hui »). · Rejeté : copier
`useSuiviParams` dans la feature (règle de duplication).

**DI-A02 — Utilitaires remontés dans `lib/`.** `features/suivi/format.ts` → `lib/format.ts`
(déplacé, 8 imports mis à jour) ; `features/suivi/dates.ts` supprimé, `dayMonth` et
`formatRange` vivent dans `lib/dates.ts` (+ `parisDay`) ; la règle « non mesuré / mesuré
depuis » vit dans `lib/measurement.ts` sur (date de début, bornes servies), et
`features/suivi/measurement.ts` n'en est plus qu'une lecture sur la réponse Suivi (les ~30
appels de Suivi restent inchangés). La tuile KPI de Suivi devient `components/ui/StatTile`
(+ ligne `meta`), réutilisée par Activité. · Rejeté : importer les fichiers de
`features/suivi/` depuis `features/activity/` (dépendance de feature à feature pour des
utilitaires génériques).

**DI-A03 — Où vit la carte du direct.** Problème : la même carte sert Suivi (carte légère)
et Activité (bloc « En ligne maintenant »). · Décision : un seul composant,
`features/activity/components/LiveActivityCard` (variantes `compact` / `full`), importé par
`SuiviPage` — c'est de la donnée d'Activité affichée dans Suivi. Requête
`["adminActivityLive", includeInternal]`, `refetchInterval` 30 s,
`refetchIntervalInBackground` laissé à faux (pas de relecture onglet caché), `staleTime`
30 s. Dans Suivi, seule la case « internes » l'influence ; le lien « Voir l'activité → »
la transmet (`?internal=1`). La carte s'affiche au-dessus des KPI, indépendamment du
chargement de la période. · Rejeté : la placer dans `components/ui/` (elle porte une
requête) ; la dupliquer dans `features/suivi/`.

**DI-A04 — Lignes de plateforme affichées.** Décision : le front affiche exactement les
lignes `displayed` servies, dans l'ordre servi (Web, iOS, Android, App — système inconnu,
puis « Non déclarée » si internes), y compris « App — système inconnu » à 0. · Raison :
masquer une ligne selon sa valeur serait une règle d'affichage locale (le plan suggérait
« si > 0 ») ; `displayed` est l'autorité servie. · Rejeté : masquer `MOBILE` à 0.

**DI-A05 — Fenêtre « en ligne ».** Le sous-titre « activité depuis moins de 3 min » est mis
en forme depuis `windowSeconds` (multiple de 60 ⇒ minutes, sinon secondes), jamais écrit en
dur ; l'heure du relevé vient de `at` (heure de Paris).

**DI-A06 — Totaux et uniques.** Le tableau de répartition se termine par la ligne
« Total — un compte compté une fois », lue dans `activeUsers.total.value`,
`logins.uniqueUsers.value` et `logins.total` (jamais une somme de lignes), suivie de
« dont N comptes actifs sur plusieurs plateformes » (`multiPlatformUsers`). Les tables
d'écrans enchaînent le top servi puis `otherTracked`, `undeclared`, `total` tels quels.
Aucune somme, aucun pourcentage n'est calculé côté front.

**DI-A07 — Évolution journalière.** Décision : barres CSS sans librairie (une série, bleu
`--blue`, coins de tête 4 px, 2 px d'écart), hauteur = échelle visuelle rapportée au plus
haut jour de la série (aucun % affiché, même exception que les barres de sources de Suivi) ;
jour `null` = cadre pointillé sans barre, jour à 0 = trait de base. Une ligne de lecture
(survol, focus clavier ou tap) donne le jour, le total et le détail par plateforme ; un
tableau « Détail par jour » repliable sert de vue accessible. Bloc masqué quand la série n'a
qu'un point (Aujourd'hui, Hier, plage d'un jour). · Rejeté : une librairie de graphiques
(hors conventions admin) ; un SVG avec axes gradués (inutile pour une série unique).

**DI-A08 — `cardTable` sans colonne d'actions.** Problème : sous 720 px, la dernière
cellule d'un `cardTable` perd son intitulé (réservée aux actions) ; les tableaux d'Activité
finissent par un chiffre. · Décision : modificateur partagé `noActions` dans
`components/ui/DataTable.module.css`, qui rend son intitulé à la dernière cellule. · Rejeté :
une cellule vide en fin de ligne ; une surcharge locale dans le module de la feature.

**DI-A09 — Navigation.** Entrée « Pilotage › Activité » (`/dashboard/activity`, icône
`activity` ajoutée au jeu `Icon`). Problème : `/dashboard/activity` étant sous
`/dashboard`, le lien « Suivi » restait allumé. · Décision : `hasNestedEntry` (dans
`navigation.ts`) pose `end` sur un lien dont une autre entrée vit sous son chemin ; le fil
d'Ariane prend déjà le préfixe le plus long (`navEntryFor`). Les entrées `hidden` sont
inchangées.

**DI-A10 — Onglets Web / Application.** L'onglet choisi reste un état local (non écrit dans
l'URL) : c'est une vue d'un même appel, pas un filtre de requête. Colonnes système de
l'onglet App intitulées par les libellés de plateforme servis (`platforms[].label`).

Vérifications : `npx tsc --noEmit` ✓, `npm run build` ✓ (avertissement de taille de chunk
préexistant), eslint ✓ sur les fichiers touchés (3 erreurs préexistantes ailleurs :
`MediaPicker.tsx`, `PassagePicker.tsx`, `Toast.tsx`, non touchés). Aucun test front.

## Déploiement — `ANALYTICS_CONFIG_VERSION` (vérifié en production le 2026-10-03)

- **Où elle serait définie** : le service systemd `sejourfr-backend` lit
  `EnvironmentFile=/etc/sejourfr/backend.env` (lancé par
  `java -jar /opt/sejourfr/backend/app.jar`). C'est le seul endroit où poser une variable
  d'environnement du backend en production.
- **Valeur actuelle** : **non définie**. Elle n'est ni dans `/etc/sejourfr/backend.env`, ni dans
  l'environnement du processus en cours. Le backend en production utilise donc le défaut
  embarqué dans son jar : `${ANALYTICS_CONFIG_VERSION:1}` → **v1**. Le jar de production ne
  contient que `analytics/analytics-config-v1.json`.
- **Ce qu'il faut faire au déploiement : rien.** Le nouveau jar embarque
  `${ANALYTICS_CONFIG_VERSION:2}` et `analytics-config-v2.json` ; sans variable, il démarre en
  v2. Le risque de démarrage signalé (variable forcée à `1`) n'existe pas en production.
- **Décision : ne PAS ajouter `ANALYTICS_CONFIG_VERSION=2` dans `backend.env`.** Raison : le
  défaut suit le jar, ce qui garde un **retour arrière sûr** — l'ancien jar (sauvegardé dans
  `/opt/sejourfr/backups/`) redémarre sur son propre défaut v1. Une variable forcée à `2` ferait
  échouer le démarrage de l'ancien jar, qui n'a pas de fichier v2.
  Alternative rejetée : poser la variable à `2` au moment du déploiement — aucun gain, et elle
  casse le rollback.
- **Si on devait un jour la changer** : éditer `/etc/sejourfr/backend.env` (propriétaire
  `sejourfr`, mode 600), puis `systemctl restart sejourfr-backend`. Un redémarrage est
  **nécessaire** : systemd ne relit pas l'`EnvironmentFile` à chaud et `Restart=on-failure` ne
  réagit pas à un changement de fichier. Aucun redéploiement du code n'est requis.

**DI-B09 — Dates de début de mesure de l'activité posées (2026-10-06).** Les quatre indicateurs
`ACTIVE_USERS`, `LOGINS`, `SCREEN_VIEWS_WEB`, `SCREEN_VIEWS_APP` sont datés du **2026-10-06**,
jour de la mise en prod de V087 (19:31, heure de Paris), dans `analytics-config-v2.json` (D43).
Avant ce jour, l'écran dit toujours « non mesuré ». `AnalyticsConfigLoaderTest` et
`AdminActivityControllerIT` verrouillent la date livrée ; le cas « non mesuré ⇒ null » reste
couvert par `ActivityScenariosIT`.
