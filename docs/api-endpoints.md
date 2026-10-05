# API backend — endpoints

Base : `http://localhost:8080`. CORS dev autorise `localhost:3000` (web Next.js) et
`localhost:5173` (admin Vite). Auth JWT Bearer (access ~60 min + refresh 30 j), **refresh
automatique** dans le client HTTP de chaque front.

## Auth

- `POST /api/auth/{login,register,refresh,forgot-password,reset-password}`
- `GET /api/auth/me` — `AuthenticatedUser`. Depuis le 2026-09-26, il porte aussi
  `profileIncomplete` (bool) et `missingProfileFields` (`FIRST_NAME` / `LAST_NAME` /
  `TARGET_PROCEDURE`, dans l'ordre du formulaire) : **dérivés serveur**
  (`util/ProfilObligatoire`), jamais persistés, toujours vides pour un ADMIN. Même
  DTO dans la réponse de `login` / `register` / `google` / `apple`. Les fronts lisent
  ce fait pour poser les questions de l'inscription avant l'app (web
  `/completer-profil`, mobile `/target-path`) ; la complétion passe par les routes de
  profil existantes, `PATCH /api/me/profile` puis `PUT /api/me/target-path`.
  `RegisterRequest.targetProcedure` reste **facultatif** côté serveur (le mobile crée
  le compte avant de poser la question ; les builds installés n'envoient rien) — le
  web l'exige dans son formulaire.
- `POST /api/auth/google` (idToken)
- `POST /api/auth/apple` (identityToken + firstName/lastName facultatifs)
  → find-or-create user via JWKS Google/Apple. 503 tant que
  `sejourfr.oauth.{google|apple}.audiences` est vide. Cf. `auth-social.md`.
- **Identifiant de mesure à l'auth** (`login`, `register`, `google`, `apple`) : champ
  facultatif `anonymousId` (UUID) dans le corps, **ou** en-tête
  `X-Sejourfr-Anonymous-Id` ; le corps prime. Pose le lien `analytics_identity`
  (best-effort, idempotent, un identifiant inconnu n'écrit rien) et, à la création du
  compte, `users.signup_anonymous_id`. Client ancien : rien d'envoyé, rien d'écrit.
- **Claim d'une `diagnostic_run` à l'auth** (lot 2a, `login`, `register`, `google`,
  `apple`) : champs facultatifs `diagnosticRunId` (texte UUID) + `claimToken` (texte)
  dans le corps, **et/ou** (contrôle N3, 2026-09-25) une liste facultative
  `diagnosticRunClaims: [{diagnosticRunId, claimToken, claimVia?}]` pour rattacher
  plusieurs runs d'invité (TCF rapide **et** civique, run reçue par lien). Le serveur
  fusionne le trio unique puis la liste, dédoublonne par run, écarte les identifiants
  illisibles et en garde **3** au plus ; chaque run valide est claimée, une fausse
  n'empêche ni les autres ni l'auth. À l'inscription, `signup_context` /
  `signup_diagnostic_*` se lisent sur la run **soumise la plus récente** parmi celles
  claimées. Dans la **transaction d'auth** : la run passe au compte si le jeton
  correspond à son hash, n'est pas expiré, et si la run n'a jamais été claimée ni portée
  (`claim_kind = SIGNUP | LOGIN`). Champ facultatif `claimVia` (lot 3b) : `"APP_LINK"`
  quand la run et son jeton sont arrivés par le lien web → app « Continuer sur
  l'application », toute autre valeur ou rien ⇒ `SAME_DEVICE` (jamais un 400) ; il
  qualifie `claimed_via`, il n'autorise rien — mêmes vérifications. À l'inscription,
  `users.signup_context` est posé au même instant : `AFTER_DIAGNOSTIC` (+
  `signup_diagnostic_type`, `signup_diagnostic_run_id`) si la run claimée est
  **soumise** (soumis retenu : civique ≥ 80 % de réponses, contrôle C),
  `OUTSIDE_DIAGNOSTIC` sinon — sauf **client ancien** (contrôle G :
  `X-Sejourfr-Client` `mobile`, absent ou inconnu, ou `web` sans
  `X-Sejourfr-App-Version`) : `null`, inconnu, car un tel client ne transmet jamais de
  run. Absents, illisibles, faux, expirés, déjà
  utilisés : **aucun claim, aucune erreur**. Aucune recherche par `anonymousId`.

## En-têtes de contexte client (tous les appels)

Lus par `util/ClientContextResolver`, **déclaratifs** (n'ouvrent aucun droit) :

| En-tête | Valeurs | Absent / illisible |
|---|---|---|
| `X-Sejourfr-Client` | `web` \| `ios` \| `android` (`mobile` = client d'avant la distinction, lu `MOBILE`) | `UNKNOWN` |
| `X-Sejourfr-Source` | réseau de provenance, normalisé par `TrafficSource` | `direct` |
| `X-Sejourfr-Anonymous-Id` | UUID de mesure de l'appareil | `null` |
| `X-Sejourfr-App-Version` | `[0-9A-Za-z][0-9A-Za-z.+_-]{0,31}` (ex. `2.4.1+57`) | `null` |

## Analytics — ingestion (public)

- `GET /api/public/app-config` → **200** `AppConfigResponse {minSupportedVersion: {ios,
  android}}` (contrôle G, option a). Public, `Cache-Control: public, max-age=300`. Chaque
  valeur vaut `"MAJOR.MINOR.PATCH"` ou `null` = aucune version minimale (valeur livrée :
  `null` partout, personne n'est bloqué). Réglage serveur :
  `sejourfr.app-config.min-supported-version.{ios,android}` (env `APP_MIN_VERSION_IOS`,
  `APP_MIN_VERSION_ANDROID`), format vérifié au démarrage. L'app compare sa `version`
  (sans `+build`) composant par composant ; erreur réseau ou `null` ⇒ ne jamais bloquer.
- `POST /api/public/analytics/events/batch` → **202** `AnalyticsBatchResponse
  {received, accepted, duplicates, rejected:[{index, eventId, reason}]}`. Public,
  rate-limité par IP **et** par `anonymousId` (seuils `ingestion.rateLimit` de
  `analytics/analytics-config-v2.json`, `perAnonymousIdBurst` 120 / 10 min). `Content-Type` : `application/json` **ou
  `text/plain`** (contrôle N7, `sendBeacon` sans pré-vérification CORS ; même corps JSON,
  mêmes validations). Corps `AnalyticsBatchRequest` :
  `{anonymousId, sessionId, client?, appVersion?, firstTouch?, events:[…]}` ;
  `client`/`appVersion` ne servent que si les en-têtes manquent (`sendBeacon`).
  Chaque événement : `{eventId (UUID tiré à la création, requis), event, occurredAt?
  (ISO-8601), path?, properties?, dedupKey?, diagnosticRunId?, diagnosticType?
  (QUICK_TCF|FULL_TCF|CIVIQUE), journeyId?}`.
  - **Enveloppe invalide** (sans `anonymousId`/`sessionId`, plus de 50 événements)
    → **400**, rien n'est écrit. Garde-fou → **429**. `sessionId` reste requis :
    `analytics_event.session_id` est `NOT NULL` et un id fabriqué serveur ferait
    de chaque lot une « visite ».
  - **L'attribution ne refuse jamais le lot** (lot 4) : `firstTouch.landingPath` hors
    allowlist ou `referrerHost` illisible → `null` (inconnu), UTM trop longues tronquées.
  - **Le visiteur et son first touch sont enregistrés dès que l'enveloppe est valide**,
    même si tous les événements du lot sont rejetés (le first touch n'est jamais réécrit).
  - **Chemin hors allowlist : jamais un rejet** (chantier « Activité », 2026-10-03) :
    `path` hors liste ⇒ `null` (événement gardé), propriété `landingPath` hors liste ⇒
    omise. Allowlist : `AnalyticsPaths.KNOWN` = les gabarits de `enums/TrackedScreen`
    (36 écrans, web et app, `:param` en minuscules) + `/competences`, `/target-path`, `/paywall`.
  - **`SCREEN_VIEWED`** (lot 2) : un écran affiché, `path` = gabarit (ou `null` = écran
    non déclaré), **aucune propriété**, aucun contexte. Exclu des visiteurs et sources de
    Suivi (D8), purgé à 365 j. Contrat : `docs/admin/activites/decisions-implementation.md`.
  - **Rejet individuel** : nom hors registre, événement serveur, propriété hors
    allowlist, `eventId` absent, `occurredAt` illisible ou de plus de 168 h, run
    ou parcours inexistant, contexte non admis par l'événement. Les autres sont écrits.
  - **Idempotent** sur `eventId` (et `dedupKey`) : `ON CONFLICT DO NOTHING`, un rejeu
    compte en `duplicates`. Le client purge sa file de tout sauf 400/429/5xx.
  - `occurredAt` dans le futur au-delà de 10 min → remplacé par l'heure de réception.
  - `diagnosticRunId` : la run doit exister, **son type fait foi** (un
    `diagnosticType` contradictoire est rejeté). `journeyId` (= `plan_id`, Q8) doit
    exister. Admis seulement sur les événements dont `AnalyticsEvent.Contexte` le
    permet (`DIAGNOSTIC_*` : run ; `PLAN_OPENED`, `PLAN_UNLOCK_CLICKED` : run + parcours ;
    `PLAN_EXERCISE_STARTED` : parcours).
  - `is_internal` résolu à l'ingestion (`users.is_internal` de l'appelant JWT ou d'un
    compte lié à l'`anonymousId`).
- `POST /api/public/analytics/events` (unitaire, **204**) : supprimé le 2026-09-25 puis
  **rétabli le même jour** (contrôle N1) — l'application **publiée** poste encore ici,
  la bascule mobile n'a pas eu lieu. Même validation (`AnalyticsEventNormalizer`),
  rate-limit par IP `analytics:burst` 120 / 10 min et `analytics:daily` 2000 / j. Retrait
  quand les événements `MOBILE` passent sous 5 % des événements de l'application sur
  7 jours (requête : `docs/regles/mesure-audience.md`).

## Diagnostic run — trace du tunnel (public, lot 2a)

Trace d'un passage dans le tunnel diagnostic (`diagnostic_run`, V074), **sans aucun
contenu**. Rate-limitées par IP et par `X-Sejourfr-Anonymous-Id`
(`diagnosticRunRateLimit` de `analytics-config-v1.json`, 429 au-delà). Un JWT valide,
s'il accompagne la requête, fait de l'appelant le porteur. Détail et règles :
`docs/regles/diagnostic.md` § « La trace du tunnel ».

- `POST /api/public/diagnostic-runs` → **200** `DiagnosticRunCreatedResponse
  {diagnosticRunId, diagnosticType, claimToken, claimTokenExpiresAt, subjectViewedAt,
  created}`. Appelé **à l'affichage de la première question**. Corps
  `{diagnosticType: QUICK_TCF|FULL_TCF|CIVIQUE, clientKey: UUID (requis, un par
  passage), sessionId?: UUID}`. En-têtes `X-Sejourfr-Client`, `X-Sejourfr-Anonymous-Id`,
  `X-Sejourfr-App-Version` → `platform`, `anonymous_id`, `app_version`.
  - **Idempotent** : même session déjà tracée, ou même `(X-Sejourfr-Anonymous-Id,
    clientKey)` → la **même run** (`created=false`) avec un **nouveau** `claimToken`
    (seul le hash est stocké ; l'ancien ne vaut plus rien). Sans en-tête d'identifiant,
    pas d'idempotence par clé.
  - 🛑 **Réutilisation par la clé bornée** (contrôle F2, 2026-09-25) : la run désignée
    par `(anonymousId, clientKey)` n'est rendue que si son porteur est nul ou est
    l'appelant, **et** si son sujet a été vu il y a moins de `runReuseWindowHours`
    (24 h). Sinon : **run neuve** (`created=true`), la `clientKey` quitte l'ancienne run
    et passe à la neuve (les rejeux suivants retrouvent la neuve).
  - `sessionId` : `civic_diagnostic_sessions` (CIVIQUE, compte **ou IP** de l'invité),
    `tcf_diagnostic_sessions` (FULL_TCF), `diagnostic_sessions` (QUICK_TCF connecté).
    Doit appartenir à l'appelant, sinon **404**.
  - Type inconnu → **400** ; `FULL_TCF` sans compte → **403** ; `clientKey` rejouée pour
    un autre type → **409**.
  - 🛑 `claimToken` (256 bits) : le client le garde avec son brouillon et ne l'envoie
    qu'à `submit` et à l'auth, **jamais** dans un événement. **Échéance ancrée** sur le
    sujet vu : `claimTokenExpiresAt = subjectViewedAt + claimTokenTtlDays` (**2 j**,
    contrôle E) ; un rejeu rend un nouveau jeton **sans repousser l'échéance** (déjà
    passée ⇒ jeton inutilisable). Vaut aussi pour le lien web → app.
- `POST /api/public/diagnostic-runs/{id}/submit` → **204**. « Soumis » d'une run
  **`QUICK_TCF`**, à « Analyser mes réponses ». Corps facultatif `{claimToken?}` : requis
  sauf si l'appelant connecté porte déjà la run. **Une seule fois** (un second appel ne
  redate rien, 204). Run absente ou pas à l'appelant → **404** ; `CIVIQUE` / `FULL_TCF`
  → **409** (leur « soumis » est posé par le serveur : fin de l'attempt civique, clôture du
  complet).

## Emails — désabonnement (public, sans compte)

Le lien des mails ENGAGEMENT porte un jeton HMAC signé (trousseau de clés, sans
expiration). Pages HTML rendues par le backend. Règles : `docs/regles/emails.md`.

- `GET /api/public/email/unsubscribe?token=…` → 200 page de **confirmation** avec un
  bouton. 🛑 **Ne modifie rien** (un scanner de liens ne désabonne personne).
- `POST /api/public/email/unsubscribe` (formulaire, champ `token`) → 200 page « Vous ne
  recevrez plus les conseils et rappels d'entraînement… » ; `engagement_enabled = false`.
- `POST /api/public/email/unsubscribe/one-click?token=…` → 200 sans corps (RFC 8058,
  cible des en-têtes `List-Unsubscribe` + `List-Unsubscribe-Post`). `GET` sur la même URL
  rend la page de confirmation.
- Jeton invalide, compte inconnu ou supprimé → **400** et la **même** page neutre (400 sans
  corps pour le one-click). Rate-limit par IP (`sejourfr.rate-limit.email-unsubscribe`).

## Thèmes & lots

- `GET /api/themes?module=CIVIQUE|TCF`
- `GET /api/themes/{themeId}/exam-slots` → `CivicThemeExamSlotsDto` `{themeId, slots:[{slot, locked}]}`
  (20 créneaux) — la grille **servie** des examens blancs d'un thème civique. Créneau 1 ouvert à
  tous, 2+ aux abonnés Civique (2026-09-24). Variante visiteur :
  `GET /api/public/themes/{themeId}/exam-slots` (seul le créneau 1 est ouvert). 404 si le thème
  n'est pas civique. Le slot 1 visiteur se joue par `POST /api/public/attempts/demo`
  (`type=MOCK_EXAM, module=CIVIQUE, themeId, slotNumber=1`), rate-limité par IP ; slot ≥ 2 → 403.
- `GET /api/exam-slots?epreuve=TCF_CO|TCF_CE|TCF_STRUCTURE|TCF_EE|TCF_EO|TCF_COMPLET|CIVIQUE` →
  `ExamSlotsDto` `{epreuve, slots:[{slot, locked}]}` — la grille **servie** des examens blancs d'une
  épreuve (2026-09-24, « le serveur décide du verrouillage »). 20 créneaux (QCM, examen complet,
  civique global), 10 en EE/EO. Chaque `locked` lit l'autorité que le démarrage oppose en **403** :
  `ExamenBlancAccessService.isExamenBlancVerrouille` (CO/CE/STRUCTURE, examen complet — créneau 1
  offert et rejouable, 2+ aux abonnés du module), `isGrilleGabaritVerrouillee` (civique global :
  créneau 1 = le gabarit gratuit `civique-decouverte`), `ProductionAccessService.isProductionExamSlotLocked`
  (EE/EO : créneau 1 = l'examen offert D-17, fermé à l'oral une fois la gratuité consommée ; 2+ aux
  abonnés TCF). Variante visiteur : `GET /api/public/exam-slots?epreuve=…` (créneau 1 des épreuves
  QCM et du civique global ; `TCF_COMPLET` = l'examen de compréhension offert `tcf-diagnostic` ;
  EE/EO tout fermé).
- `GET /api/lots?module=TCF&questionType=CO|CE&difficulty=A2|B1|B2`
- `GET /api/lots?module=CIVIQUE&themeId=<uuid>`
  Cf. `lots-entrainement.md`.

## Attempts

- `POST /api/attempts`
- `POST /api/attempts/production` (attempt vide pour EO/EE)
- `GET /api/attempts/{id}`
- `POST /api/attempts/{id}/answers`
- `POST /api/attempts/{id}/finish`
- `POST /api/attempts {type:MOCK_EXAM, module:TCF, moduleExamQuestionType:CO|CE}`
  → examen module (premium TCF requis). Cf. `exams-tcf.md`.

## Examen blanc TCF complet

- `POST /api/full-tcf-exams` (premium TCF requis)
- `GET /api/full-tcf-exams/{id}` — l'examen d'un autre utilisateur répond
  **404** (et non 403 : un 403 confirmerait l'existence de l'id).
- `POST /api/full-tcf-exams/{id}/begin?epreuve=TCF_CO|TCF_CE|TCF_EE|TCF_EO`
  — `epreuve` est **requis** (400 s'il manque).
- `POST /api/full-tcf-exams/{id}/finish`
- `GET /api/me/full-tcf-exams?limit=N`
- `POST /api/full-tcf-exams?slotNumber=N` — `slotNumber` borné à 1..20.

🛑 **`finalCecrlLevel` est re-dérivé à chaque lecture** (D19, 2026-09-24) : la
colonne `attempts.final_cecrl_level` n'est plus qu'une trace écrite à la
finalisation, jamais relue ; `null` tant que l'examen n'est pas `COMPLETED`.
`subAttempts[].noteSur20` (EE/EO, 2026-09-24) : la note d'épreuve /20 du bilan,
servie seulement avec un `cecrlLevel`.

Cf. `exams-tcf.md`.

## Me / utilisateur

- `POST /api/me/presence` → **204**, sans corps (401 sans jeton) — **heartbeat de premier
  plan** (chantier « Activité », D2) : web et app l'appellent toutes les 60 s, compte connecté
  et écran visible seulement. Aucune logique propre : toute requête authentifiée est comptée
  comme activité (`UserActivityInterceptor`, au plus une écriture par minute, par compte,
  plateforme `X-Sejourfr-Client` et jour de Paris), sauf `/api/auth/**`,
  `/api/public/analytics/**`, `/files/**`, `/actuator/**`. `docs/regles/mesure-audience.md`
  § « Activité des utilisateurs ».

- `GET /api/me/email-preferences` → `{ "engagementEnabled": true, "marketingEnabled": false }`
  (valeurs par défaut quand le compte n'a jamais rien changé — aucune ligne n'est écrite à la
  lecture). `PATCH /api/me/email-preferences` `{ "engagementEnabled"?: bool,
  "marketingEnabled"?: bool }` → 200 et le même DTO ; un champ absent ne change rien ; passer
  `marketingEnabled` à `true` date le consentement (`marketing_consent_at`, conservé ensuite).
  🛑 Aucun champ ne concerne les mails REQUIRED. Miroirs : `web_sejoufr/lib/types.ts`
  (`EmailPreferences`) ⇄ `mobile_sejourfr/lib/core/models/email_preferences.dart` ; pages
  « Notifications par e-mail » (`/profil/notifications` ⇄ `/profile/notifications`). Admin : aucun.
- `PUT /api/me/exam-date` — `{ "examDate": "2026-10-18" | null }` → 204. Jour de
  l'examen déclaré par le candidat (V047). **Route séparée de `/api/me/target-path`**,
  et elle doit le rester : loger la date dans la mise à jour de la démarche
  l'effacerait à chaque changement de procédure. `null` **efface volontairement**
  (« pas encore de date » est une réponse pleine, et la plus fréquente). Aucune
  validation sur le passé — une date dépassée est une information vraie, et la
  refuser empêcherait de corriger une faute de frappe. Exposée en lecture sur
  `AuthenticatedUser.examDate` (`GET /api/auth/me`), miroir dans les 3 fronts.
  Le décompte en jours est calculé **à la lecture**, jamais persisté.
- `GET /api/me/questions/favorites?module=...`
  → écran « Mes favoris » (web `/favoris`, mobile `MesFavorisScreen`, ouverts
  depuis le Profil) et marque-page du runner.
- ~~`GET /api/me/questions/wrong`~~ — **supprimé le 2026-09-24** avec « Mes
  erreurs » / « Mes questions » (décision du propriétaire : la progression suffit
  pour suivre son avancement). `GET /api/me/questions/{id}/review` reste : c'est
  le détail d'un favori.
- `GET /api/me/stats?module=...` (⚠️ aucun appelant web ni mobile au 2026-09-24) — toute la réponse est scopée au module,
  `attemptsTotal` compris. Les deux attempts techniques du diagnostic initial
  sont exclus de ce compteur et de l'historique `/api/me/attempts`.
- `GET /api/me/plan/journey[?expand=all]` → `JourneyDto` — **le parcours TCF**, la file
  d'étapes que le Plan suit. 🛑 **Créé à la première lecture** (une seule fois, verrou
  consultatif par (candidat, module)) : sans évaluation, c'est le **cycle d'examens par défaut**
  (D-69, un examen par épreuve non mesurée ; plus jamais d'étape `DIAGNOSTIC`). `state` vaut
  `NEEDS_OBJECTIVE` (aucune démarche déclarée, donc
  **aucun parcours en base**), `IN_PROGRESS`, `LOCKED` (des étapes restent, aucune n'est
  exécutable) ou `UP_TO_DATE`. 🛑 **Aucun `targetLevel` en paramètre** : le serveur connaît le
  niveau visé du candidat, l'accepter d'un client laisserait demander un parcours qui n'est pas
  le sien. `current` est la première étape ouverte **et exécutable** — une étape qu'un compte
  gratuit ne peut pas mener à son terme reste **affichée à sa place**, `locked`, mais ne prend
  jamais la main. `status`, `locked` et l'élection de `current` sont **dérivés à la lecture** :
  un abonnement souscrit change la réponse sans qu'une ligne bouge en base. `steps` est déjà
  filtrée pour l'écran ; `?expand=all` rend toutes les étapes non obsolètes. Les étapes
  `OBSOLETE` ne sont **jamais** servies. `progress.unit` (`PROMPT` / `SERIES`) est **servi** :
  les compétences de compréhension n'ont ni tâche ni petit sujet, leur grain est la série.
  Le serveur sert des **faits** (`section`, `taskCode`, `skillCode`, `skillTitle`, `purpose`) —
  « Expression écrite · Tâche 1 » et « Vérifier mes progrès » se composent dans les fronts.
  `assessment` (non `null` sur les seules étapes `SECTION_EXAM`) porte **par quoi mesurer
  l'épreuve**, relayé de `PlanDomainAssessmentResolver.pour` : 🛑 **à lire ici, jamais à
  retrouver dans `domainesAEvaluer`**, qui ne liste que les épreuves **jamais mesurées** alors
  qu'un point d'étape porte toujours sur une épreuve déjà mesurée.
  **Le cycle borné (D-12)** se superpose à la même file : `cycle` (avancement, `numero`,
  `complete`, `cycleDeMesure`, `cycleDAffinage`, `prioritesCycleSuivant` — 🆕 2026-09-27, D-67 :
  le nombre **retenu** de priorités que le cycle suivant portera, `null` en consultation ;
  ⚠️ `finDeCycle` est **supprimé** de ce DTO, D-66), `blocs` — **toujours quatre**, une par épreuve, dans l'ordre
  `CO, CE, EO, EE` (`TcfDomainProfileDto.ORDRE`, non configurable) avec leur `status` dérivé
  (`TERMINE` / `EN_COURS` / `A_EVALUER` / `A_VENIR` ; `INACHEVE` en consultation d'un cycle
  clos seulement), leurs `steps` et leur `exam` — et
  `nextStep` (**`actualisationPossible` seul** depuis D-66 : `examenCompletPossible` est
  supprimé), **`null` sauf cycle terminé**, et 🆕 **`examenComplet`** (D-68, 2026-09-27) : le
  jalon « Faire un examen blanc complet » — `{raison: CYCLES_DE_TRAVAIL | OBJECTIF_ATTEINT,
  cyclesDeTravail}`, **`null` quand il n'est pas proposé** (le cas courant ; jamais sur un cycle
  d'examens). Autorité unique `JourneyJalonExamenComplet`. `state` gagne `CYCLE_COMPLETED`
  (cycle terminé) ; `UP_TO_DATE` garde son sens (plus rien à faire du tout).
  Une étape `TRAIN_SKILL` d'**expression** sert `progress` (`done`/`quota`, unité `PROMPT`),
  `stepPromptIds`, `stepValidatedCount`, `stepCompleted` : **3 sujets** depuis D-71
  (2026-10-04, 5 avant), autorité `LearningPlanStep.PROMPTS_PAR_ETAPE` ; les fronts lisent le
  nombre servi, jamais une constante. Elle se clôt quand ses sujets sont tous **traités**, à
  l'analyse d'un petit sujet **et** à la lecture suivante (étape déjà au quota).
  🛑 **L'examen d'un bloc est `locked` tant qu'une compétence du même bloc reste ouverte**
  (D-15) — un bloc sans compétence a son examen ouvert immédiatement. ⚠️ **Sauf au cycle
  d'affinage** (`cycle.cycleDAffinage`, 2026-09-27, D-64 : premier cycle issu du diagnostic
  rapide) : aucun verrou `PROGRESSION`, compétences facultatives, `complete` dès que les
  examens sont passés, `current` = premier examen exécutable. ⚠️ `steps` et
  `hiddenUpcomingCount` sont **servis pour la transition et disparaîtront en P6**, dans la
  même passe que la bascule des fronts sur `blocs` : un nouveau lecteur se branche sur `blocs`,
  qui porte **toutes** les étapes non obsolètes, sans plafond d'affichage.
  Spec : `docs/progression/SPEC_cycle_plan.md` · arbitrages : `docs/decisions/plan-parcours-tcf.md`.
  `journeyId` (lot 2a) : `journey.id`, le `plan_id` du chantier Suivi (Q8), `null` sans
  parcours. Le serveur en déduit lui-même la run fondatrice
  (`DiagnosticRunManager.findFoundingRun`), il ne la reçoit jamais d'un client.
- `GET /api/me/plan/journey/steps/{stepId}` → `JourneyStepDetailDto` — **l'écran d'ÉTAPE**
  (2026-09-20) : les **2 séries à réussir** d'une compétence de compréhension (CO/CE) ou d'une
  unité officielle civique, leur état, leur score. Sert `bloc`, `unite` *(code, label,
  description — **nulle en civique**)*, `section`, `objectif` *(kind, code, label : un palier
  **ou** une mention)*, `priorite`, `quota` (2), `validees`, `validee` (validée par ses séries), `resolution` (motif de clôture, null si ouverte), `questionsParSerie` (20),
  `seuilReussite` (16), `dureeEstimeeMin`, `locked` (freemium) et `series[]`
  (`index`, `locked`, `validee`, `dernierScore`, `dernierAttemptId`, `dernierEssaiAt`).
  🛑 **`validee` et `validees` sont SERVIS** : sans eux un front comparerait `dernierScore` à
  `seuilReussite`, donc classerait un nombre en état pédagogique. 🛑 **Aucune phrase servie** —
  « À faire » / « Verrouillée » / « Réussie » / « À refaire » se composent des fronts.
  🛑 **Aucun `?module=`** : l'étape porte son module. **404** si elle n'existe pas ou n'est pas
  celle du candidat ; **422** si elle ne se travaille pas par séries (expression, examen).
  → `docs/regles/plan.md` § « L'ÉCRAN D'ÉTAPE ».
- `GET /api/me/plan/journey/history[?module=TCF|CIVIQUE]` → `JourneyHistoryDto` — **« Mes
  cycles »** : `stats` (compétences travaillées et examens passés **cycle en cours compris**,
  cycles terminés) et `cycles` historisés du plus récent au plus ancien — `journeyId`
  (2026-09-27), `numero`, `debut`, `fin`, `finDeCycle` (le geste qui l'a clos — 🆕 V078 :
  `INTERROMPU` ⇒ « Interrompu »), compteurs, niveaux / scores d'entrée et de sortie
  lus tels quels, `blocs` (titres des unités travaillées). Le cycle en attente n'y paraît jamais.
- `GET /api/me/plan/journey/history/{journeyId}` → `JourneyCycleArchiveDto` — **un cycle CLOS en
  consultation** (2026-09-27) : `journeyId`, `numero` (même règle que la liste et le Plan),
  `debut`, `fin`, `finDeCycle` (**le geste qui l'a clos**, V077 / V078 : `ACTUALISATION` /
  `EXAMEN_COMPLET` / `INTERROMPU`, `null` = inconnu pour un cycle clos avant), `objectif`, niveaux / scores
  d'entrée et de sortie, puis **les mêmes `cycle` et `blocs` que `JourneyDto`**, en lecture
  seule : 🛑 aucune étape `locked` (`lockReason`, `assessment`, `exercise`, `progress` nuls),
  une étape restée ouverte est `NON_FAITE`, un bloc incomplet `INACHEVE`, un bloc sans étape
  n'est pas servi, ordre `CO, CE, EO, EE`. Chaque étape sert `closedAt` ; l'examen d'un bloc
  sert `resultat` (`niveau` TCF relu chez `TcfLevelEstimatorService` /
  `EpreuvesProductionQualifiantesResolver`, ou `score`/`maxScore` d'un examen de thème civique
  — `null` = inconnu). **404** sur le cycle d'un autre, un cycle en cours ou en attente.
  🛑 **Aucun `?module=`** : le cycle porte le sien.
- `POST /api/me/plan/journey/steps/{stepId}/series/{index}` → `AttemptResponse` — **lancer (ou
  refaire) la série `index`** de cette étape. Le même DTO que tous les autres lancements : les
  fronts atterrissent sur `/sessions/{attemptId}`. 🛑 **`mode` vaut `EXAMEN`** — aucune
  correction pendant la passation, audio de CO joué une seule fois. **403** si l'étape est
  verrouillée (freemium) **ou** si la série l'est (la précédente n'est pas **réussie**) ;
  **422** si l'index sort du quota ou si la banque ne peut rien servir. 🛑 **Un seul endpoint
  pour les deux modules** : il résout TCF vs civique depuis l'étape et **délègue** la
  composition aux autorités existantes.
- `POST /api/me/plan/journey/refresh` → `JourneyDto` — **« Actualiser mon plan »** (spec §6).
  Le cycle en cours est **historisé** (`historise_at`, `exit_level` = niveau global courant, lu
  chez `TcfProfileService.levelProfile` ; `null` si rien n'a été mesuré, **jamais 0**), le cycle
  **en attente** devient le cycle courant (son `entry_level` = l'`exit_level` du précédent), et
  le prochain cycle en attente reste **paresseux**. Le geste est écrit sur le cycle clos
  (`journey.fin_de_cycle = ACTUALISATION`, V077). 🛑 **Seule issue de fin de cycle depuis D-66.** 🛑 **Aucun paramètre** : le serveur sait
  quel est le cycle en cours du candidat. **409** si le cycle n'est pas terminé (au cycle
  d'affinage : tant qu'un examen reste à passer — ses compétences sont facultatives) — ce geste
  historise, il ne doit jamais jeter un plan en cours ; **422** sans démarche déclarée.
- `POST /api/me/plan/journey/measurement-cycle[?module=TCF|CIVIQUE]` → `JourneyDto` — **le jalon
  « Faire un examen blanc complet »** (D-68, 2026-09-27 ; chemin inchangé). Le cycle en cours est
  **mis de côté** — historisé avec `fin_de_cycle = INTERROMPU` (V078) s'il restait des étapes
  obligatoires ouvertes, `EXAMEN_COMPLET` s'il était déjà terminé — et un **cycle d'examens**
  devient courant : un bloc par épreuve (TCF) ou par thématique (civique), chacun ne portant que
  son examen, tous débloqués (les verrous d'**accès** restent servis en `lockReason = ACCESS`).
  Le cycle en attente est **laissé tel quel** ; les priorités non terminées ne sont pas
  reportées, les examens les recalculent. 🛑 **Il ne démarre aucun examen.** **409** quand le
  jalon n'est pas proposé (`JourneyDto.examenComplet` nul) — la **même autorité**
  (`JourneyJalonExamenComplet`) : moins de 3 cycles de travail depuis le dernier examen complet
  et objectif non atteint partout par examen blanc, ou cycle déjà d'examens. ⚠️ **Révoque** le
  déblocage à 80 % (`finDeCycleExamenRatio`, v3) et le 409 propre au cycle d'affinage.
- `GET /api/me/plan` → `LearningPlanDto`. `state` vaut **toujours `ACTIVE`** depuis D-69
  (2026-09-28) : `NEEDS_DIAGNOSTIC` et `DIAGNOSTIC_IN_PROGRESS` sont supprimés, le Plan existe
  pour tout compte (sans diagnostic, `diagnosticSessionId` = `null` et les priorités viennent de
  ce qui a été mesuré — rien pour un compte neuf). Le serveur fournit
  `currentPriority`, au plus deux `nextPriorities`, les compétences observées
  et l'exercice recommandé. Les clients ne trient ni ne recalculent ces priorités.
  `LearningPlanPriorityDto` **et** `LearningPlanSkillDto` portent
  `promptCount` / `attemptedCount` / `validatedCount` (int) — même sémantique et
  même calcul serveur que les compteurs de `SkillDto` (module Compétences) :
  sujets **actifs** de la compétence, sujets déjà tentés par ce candidat, sujets
  validés. Aucun front ne les recalcule. `recommendedExercise.estimatedMinutes`
  est **dérivé du sujet** (durée de parole conseillée en EO, fourchette de mots
  en EE), plus une constante par épreuve.
  **Le Plan reste intégralement visible sans abonnement** : rien n'est masqué,
  seul `locked: boolean` est posé sur `LearningPlanPriorityDto`,
  `LearningPlanSkillDto` et `PlanRecommendedExerciseDto` (même sémantique que
  dans le module Compétences : `true` ⇒ ce candidat ne peut pas produire
  dessus). La compétence de `currentPriority` est **toujours ouverte** à un
  compte gratuit — sinon l'étape 1 du Plan serait inatteignable. L'exercice
  recommandé, lui, peut sortir `locked: true` : il reste désigné, avec un
  cadenas.
- `GET /api/me/dashboard` — agrégat unique du tableau de bord + hubs web :
  streak de jours d'activité (courant + record, fuseau Europe/Paris), nb
  d'examens blancs finis (global + `civiqueMockExams`/`tcfMockExams` par
  module, sous-attempts TCF_COMPLET exclus), taux de réussite global, niveau
  TCF estimé (dernier examen TCF porteur d'un niveau CECRL), stats par
  catégorie pour les deux modules (tous les thèmes, avec `mockExams` scopé +
  entrées synthétiques `TCF_EE`/`TCF_EO` depuis les évals IA, qui portent
  `subjectsDone`/`subjectsTotal` : sujets publiés distincts produits / sujets
  publiés de l'épreuve, 3 tâches confondues — le « 3/40 sujets » de Réviser).
  Cf. `UserDashboardService`.
- `POST|DELETE /api/me/questions/{id}/favorite`
- `GET /api/me/attempts?type=MOCK_EXAM&module=TCF&moduleExamQuestionType=CO|CE`
- `DELETE /api/account` — suppression de compte (App Store 5.1.1(v)).
  Anonymise le user (email/nom/mot de passe effacés, `deleted_at` posé), purge
  les données de pratique, coupe le Premium, révoque les sessions. Renvoie
  `AccountDeletionResponse {deleted, hasActiveSubscription, subscriptionProvider,
  manualActionMessage}` — `manualActionMessage` non-null si un abonnement
  Apple/Google reste à résilier dans le store.

## EO/EE TCF (production)

- `GET /api/production-tasks?epreuve=TCF_EO&niveau=B1[&tacheNumero=1|2|3]` — `titre` est
  **nullable** (intitulé éditorial du sujet, V028) : les fronts retombent sur « Sujet N ».
- `GET /api/production-tasks/{id}`
- `POST /api/production-submissions` (multipart audio **ou** JSON texte selon `Content-Type`)
  → accepte `clientSubmissionId` (UUID **facultative**, V046) : en JSON dans le corps,
  en `@RequestParam` (query ou champ de formulaire) en multipart. **Renvoyer la même
  clé rend la MÊME submission**, sans second appel LLM ni second décompte de quota —
  le rejeu est intercepté **avant** Whisper. Une clé absente = comportement d'avant à
  l'identique. Unicité bornée à `(user_id, client_submission_id)` : une clé tirée par
  un client ne peut jamais faire échouer ni résoudre vers la production d'un tiers.
- `POST /api/production-submissions/{id}/retry`
- `GET /api/production-submissions/{id}`
- `GET /api/users/me/production-submissions?epreuve=...`
- `GET /api/users/me/production-submissions/last-per-task?epreuve=...&niveau=...`
  → dernière submission de l'utilisateur par numéro de tâche (0 à 3 lignes), utilisé par le hub
  mobile.
- `GET /api/attempts/{attemptId}/production-bilan` → bilan serveur d'une session EE/EO
  (`ProductionBilanResponse`, avec `slotNumber` + `finished`) ; `niveauGlobal` rempli pour
  une session d'examen blanc entièrement évaluée, ou terminée (tâches manquantes comptées
  0) — jamais de niveau CECRL en entraînement.
- `GET /api/attempts/{attemptId}/production-exam-tasks` → les 3 sujets (T1-T3) composés
  déterministiquement pour une session d'examen production (module ou sous-épreuve d'un
  examen complet). 400 sur un entraînement libre.
- `POST /api/attempts/production` accepte `slotNumber` (1-10) avec `exam=true` ; l'attempt
  EE d'examen module porte `timeLimitSeconds=1800` (chrono 30 min enforcé à la soumission).
- `POST /api/attempts/{id}/finish` fonctionne sur les attempts production (pose
  `finishedAt` ; les soumissions suivantes sont refusées).

Cf. `pipeline-evaluation-eo-ee.md`.

## Diagnostic TCF — 4 épreuves (L4)

🛑 **Distinct de `/api/diagnostics`**, qui porte le diagnostic *initial* (une
production écrite + une orale). Ce sont deux objets produit différents et `10_`
§4.1 interdit de les confondre — comme il interdit d'appeler celui-ci un examen
blanc.

- `POST /api/tcf-diagnostics` → `TcfDiagnosticDto`. Ouvre un diagnostic, ou rend
  celui déjà en cours. **Idempotent** : deux appuis sur « Commencer » ne créent
  pas deux diagnostics. Le premier est offert ; les suivants sont une
  réévaluation réservée aux abonnés TCF et espacée de 14 jours (configurable) —
  sans ce délai, une réévaluation à volonté ne mesurerait plus une progression.
- `GET /api/tcf-diagnostics/current` → `TcfDiagnosticDto`, ou **204** si le
  candidat n'en a jamais ouvert. 🛑 Une lecture n'ouvre jamais un diagnostic par
  effet de bord : l'ouverture est un geste, et elle consomme l'unique gratuit.
- `GET /api/tcf-diagnostics/{id}` → l'état des 4 sections.
- `POST /api/tcf-diagnostics/{id}/sections/{epreuve}/start` — pose l'ancre du
  chrono de la section (`TCF_CO|TCF_CE|TCF_EE|TCF_EO`). Idempotent : rappelé, il
  rend le temps réellement restant, il ne le remet pas à zéro.
- `POST /api/tcf-diagnostics/{id}/result` → `TcfDiagnosticResultDto`, et clôture
  le diagnostic. N'exige **pas** les 4 sections : passé le délai de reprise, on
  calcule sur les sections réalisées, les autres restant « non évaluée ».
- `GET /api/tcf-diagnostics/{id}/result` — relire un résultat sans rien
  reclôturer. Depuis L7, la réponse porte `progression` : la comparaison au
  diagnostic clos précédent. 🛑 **`null` est le cas normal** (premier
  diagnostic), et une épreuve non évaluée d'un côté rend `INCONNUE`, jamais
  `STABLE`.
- `GET /api/admin/civic-notions` → `CivicNotionDto[]` (**L8**, ADMIN). Le
  référentiel de travail (40 notions, 5 thèmes) avec la **couverture mesurée**
  par notion **et par mention**.
  🛑 **Aucun seuil n'est appliqué serveur** : la règle de `50_` §6.1 dégrade par
  notion *et* par mention — une notion pleinement utilisable en NAT peut être
  vide en CSP. On sert les comptes, l'appelant tranche pour SA mention.
  🛑 Les `suggestions` ne comptent **pas** comme couverture : une proposition de
  machine n'est pas un tag.
- `GET /api/admin/civic-notions/questions?theme=&tagged=false&limit=&offset=`
  (**L8**, ADMIN). La file de tagging, ordre déterministe (`created_at, id`) :
  paginer ne doit jamais en faire revoir ni en sauter une. Chaque
  `QuestionTaggingDto` porte l'**énoncé**, l'**explication** (nullable), les
  **propositions** (`choix[]`, la bonne marquée), le thème, la mention, la notion
  posée s'il y en a une, et les `suggestions` triées par confiance décroissante —
  chacune avec sa `rationale` (nullable) et son `reviewVerdict` (nullable tant
  qu'elle n'est pas relue).
  🛑 **`notionCode` et `notionLabel` d'une suggestion sont NULLABLES** (V057) :
  `null` = le modèle a conclu qu'**aucune notion du référentiel ne convient**.
  C'est un verdict, pas une erreur ni une absence de suggestion — c'est ainsi que
  l'écran affiche « Aucune notion correspondante ». Jamais de chaîne sentinelle
  (`"AUCUNE"`, `"—"`) : le front a besoin du `null` pour distinguer sans deviner.
  🛑 **La file ne propose que des questions de CONNAISSANCE** : les mises en
  situation relèvent des domaines `sit_*` (`50_` §6.2) et ne se taguent pas par
  notion. `resteATaguer` compte la même chose — c'est l'avancement qui déclenche
  la bascule de grain. Une question **déjà taguée** reste visible quel que soit
  son type, pour qu'une erreur puisse être défaite.
- `PUT /api/admin/civic-notions/questions/{id}` `{notionCode, verdict}`
  (**L8** / V054, ADMIN). Pose le tag **validé par un humain**, ou enregistre ce
  que le relecteur a fait de la proposition de la machine.
  - `notionCode` + `verdict` nul ou `"TAG"` ⇒ la notion est posée et le serveur
    **déduit** `VALIDATED` (la mieux notée a été retenue) ou `CORRECTED` (une
    autre l'a été).
  - `verdict = "REJECTED"` / `"SKIPPED"` ⇒ **aucune** notion posée, on marque
    seulement ; la question reste dans la file. Envoyer un `notionCode` avec eux
    est refusé (400) : deux gestes contraires ne se devinent pas.
  - `notionCode: null` sans verdict ⇒ **effacement**, comportement d'avant V054.
    🛑 **Rétrocompatible** : un corps `{notionCode}` seul marche à l'identique.
  - `verdict = "CONFIRM_NONE"` (sans `notionCode`) ⇒ le relecteur **confirme
    qu'aucune notion ne convient** : il est d'accord avec le modèle. Le serveur
    stocke **`VALIDATED`** — la proposition « aucune » était juste — et **ne pose
    aucun tag**. 🛑 **400** si la meilleure suggestion de la question n'est pas
    « aucune notion » (y compris s'il n'y en a aucune) : le client affirmerait
    quelque chose de faux sur la qualité du modèle. Un `notionCode` avec ce
    verdict est refusé (400) de même.
  - 🛑 Un client **ne peut pas** annoncer `VALIDATED` ni `CORRECTED` (400) :
    c'est la métrique de qualité du modèle, et elle se calcule serveur.
  - **Les quatre gestes sur une suggestion « aucune notion »** (V057) :
    *valider* = `CONFIRM_NONE` → stocké `VALIDATED`, pas de tag ·
    *corriger* = `{notionCode: X}` → stocké **`CORRECTED`** (le modèle s'était
    trompé), tag posé · *rejeter* = `REJECTED` · *passer* = `SKIPPED`.
  - Une notion **fusionnée** est refusée : la poser recréerait du travail à
    défaire.
  🛑 **Aucune de ces routes n'appelle un LLM.** `question_notion_suggestions`
  est créée vide et rien dans le dépôt ne la remplit : « le job propose, un
  humain valide » (`50_` §6.1.3), et lancer le job coûte de l'argent.
- `GET /api/admin/ai-costs?days=30` (ou `from`/`to`) → `AdminAiCostResponse`
  (**L12**, ADMIN). Ce que l'IA a coûté sur la fenêtre : total, par nature
  d'appel, par source, par modèle, et le coût moyen d'un diagnostic mené à
  terme. Tout vient de la vue `v_ai_usage` (V048) — aucune cinquième écriture.
  🛑 **`coutMicroUsd` et `coutLegacyCentimes` ne s'additionnent jamais** : deux
  unités, deux devises, deux époques.
  🛑 **Un coût inconnu vaut `null`, jamais 0**, et `lignesSansCout` le compte :
  sans ce nombre, un total bas se lit « l'IA ne coûte presque rien » là où la
  vérité est « on ne sait pas ce qu'elle a coûté ».
  🛑 Cette route ne déclenche **aucun appel LLM** : elle lit une vue.
- `GET /api/tcf-diagnostics/eligibility` → `TcfReassessmentEligibilityDto`
  (**L7**). « Peut-il relancer, et sinon pourquoi ? » — jamais 204 : sans aucun
  diagnostic la réponse est `{first: true, canStart: true}`.
  🛑 **C'est la seule façon correcte de le savoir.** Le même calcul sert cette
  route **et** le garde d'ouverture de `POST /api/tcf-diagnostics` : un front
  qui recompterait les 14 jours afficherait tôt ou tard un bouton que le serveur
  refuse — et il ne peut de toute façon pas voir la dérogation du Plan.
  `locked` vaut strictement `blocker == PREMIUM_REQUIRED` : un délai non écoulé
  n'est pas un cadenas, payer ne l'ouvre pas.

**La passation ne passe pas par ces routes** : les sections QCM répondent sur
`/api/attempts/{id}/answers`, les productions sur `/api/production-submissions`
avec l'`attemptId` de la section — exactement comme l'examen complet. Aucun
pipeline n'est dupliqué.

🛑 **`niveauGlobal` et le `niveau` d'une épreuve peuvent être `null`** : c'est
« non évaluée », jamais le palier le plus bas. Une épreuve non évaluée est
**exclue** du plancher global (A7) et doit être nommée à l'écran.
🛑 **Aucun `locked` sur ces réponses** : le paywall porte sur le plan, jamais sur
le constat (`10_` §4.5).

## Diagnostic initial TCF et Plan

Parcours offert une fois par version et distinct d'un examen blanc : une EE
hybride de 100–130 mots puis une EO enregistrée de 2–3 minutes. Il ne consomme
pas les quotas d'entraînement, n'écrit aucune évaluation notée `/20` et ne crée
pas de `TCF_COMPLET`.

**Les deux productions se font sans compte, l'analyse exige un compte.** Le
visiteur lit les sujets sur une route publique, rédige et s'enregistre côté
client, puis crée son compte au moment d'« Analyser mes réponses ». Rien n'est
persisté avant : ni session diagnostique anonyme, ni attempt, ni audio invité
sur R2 (`diagnostic_sessions.user_id` reste `NOT NULL`).

- `GET /api/public/diagnostics/current` → `PublicDiagnosticResponse`,
  **public**, sans authentification, rate-limité par IP (120 requêtes / 10 min,
  `sejourfr.rate-limit.public-diagnostic` — lecture de contenu seedé, la borne
  ne sert qu'à couper une boucle automatisée). Champs : `diagnosticCode`,
  `diagnosticVersion`, `written` et `oral`, chacun un
  `PublicDiagnosticExerciseDto` (`productionTaskId`, `epreuve`, `title`,
  `instruction`, `helperText`, `wordsMin`, `wordsMax`, `durationMinSeconds`,
  `durationMaxSeconds`, `instructionAudioUrl`). **Pas** de `attemptId`,
  `submissionId` ni `submissionStatus` : ils n'existent qu'une fois la session
  créée, donc après l'inscription. La version servie est la même que celle que
  `POST /api/diagnostics` utilisera (résolution partagée,
  `DiagnosticContentResolver`).
- Après l'inscription, les fronts enchaînent `POST /api/diagnostics` puis les
  deux `POST /api/production-submissions` **coup sur coup** : cette séquence est
  acceptée telle quelle (verrouillée par `DiagnosticPostSignupSequenceIT`).
  ⚠️ Un compte qui avait **déjà terminé** ce diagnostic reçoit sa session
  existante en `status=COMPLETED`, `nextStep=RESULT` avec son `result` — jamais
  d'erreur, jamais de seconde session ; les deux soumissions qui suivraient sont
  alors refusées en **422** (« Ce diagnostic n'accepte plus de nouvelle
  production. »). C'est au front de lire `status` et de proposer le résultat
  existant plutôt que d'envoyer les productions.
- `GET /api/diagnostics/current` → `DiagnosticResponse` de la version active.
  Renvoie `status=NOT_STARTED` sans créer de données si le candidat ne l'a pas
  commencé ; sinon permet la reprise sur un autre appareil.
- `POST /api/diagnostics` → crée ou reprend idempotemment la session active,
  avec ses deux attempts et ses deux exercices. Deux appels concurrents
  aboutissent à la même session.
  Paramètre facultatif `diagnosticRunId` (lot 2a) : au handoff, la run créée en invité
  est liée à la session **si elle appartient déjà au compte** (claimée à l'auth, ou
  créée connecté) ; ignorée sinon, jamais une erreur.
- `GET /api/diagnostics/{sessionId}` → même DTO agrégé. Une session d'un autre
  utilisateur répond **404**, pour ne pas révéler son existence.
- `POST /api/diagnostics/{sessionId}/retry-analysis` → relance seulement une
  session `FAILED`, avec rate-limit et plafond `max-session-retries`; si les
  deux analyses sont déjà présentes, la synthèse déterministe est simplement
  rejouée sans appel IA.

`DiagnosticResponse` contient `sessionId`, le code/version, `status`,
`nextStep` (`PRESENTATION|WRITTEN|ORAL|ANALYSIS|RESULT`), les deux
`DiagnosticExerciseDto`, puis `result` quand il est prêt. Les rendus réutilisent
`POST /api/production-submissions` avec les `productionTaskId` et `attemptId`
fournis. Le bypass du quota n'est accordé que pour la paire exacte de cette
session ; les contrôles d'appartenance, type EE/EO, taille/durée, rate-limit,
R2 et Whisper restent actifs. Une seule submission est admise par attempt.

Le résultat distingue accomplissement, communication, niveau estimé prudent
(maximum B2, non officiel), compétences observées, preuve exacte, confiance et
priorités. Au plus trois priorités globales sont renvoyées. `result.nextAction`
est toujours un micro-exercice actif du catalogue, y compris lorsqu'aucune
priorité n'est assez fiable (repli sur une compétence observée puis sur
l'allowlist). Le Plan est dérivé et ordonné côté serveur depuis des observations
sourcées ; une ligne `NOT_OBSERVED` reste historisée mais n'efface jamais une
preuve antérieure. Le Plan reste séparé de l'historique et des statistiques de
progression.

**Rapport du diagnostic rapide — champs servis depuis le 2026-10-04** (AR-3/AR-4,
`docs/diagnostic/audit-nouveau-rapport-diagnostic.md`) : la route reste
`GET /api/diagnostics/{sessionId}` (le web l'appelle avec
`prep.estimationSessionId`), `result` gagne trois champs additifs — un client
ancien les ignore.

- `result.planPriorities: DiagnosticPlanPriorityDto[]` — 🛑 **les priorités du
  LOT DU PLAN**, seule autorité des priorités montrées par le rapport, la
  transition et le Plan : étapes `TRAIN_SKILL` dont `source_assessment_id` est la
  session, dans l'ordre du lot. Chaque élément : `skillId`, `skillCode`,
  `skillTitle`, `section` (`EE|EO|CO|CE`), `taskCode` (`EE1..EO3`), `rank`
  (1..n), `explanation` (constat de l'analyse du diagnostic pour cette
  compétence, `null` s'il manque), `generalCriterion` (`skills.general_criterion`),
  `inCurrentCycle` (`true` = cycle `EN_COURS` et étape non `SUPERSEDED` ; `false`
  = lot en attente, cycle historisé ou étape remplacée). **Jamais `null`** ; vide
  = aucun lot — **aucun repli** sur `priorities`. Plusieurs cycles portent le lot
  ⇒ `EN_COURS`, sinon `EN_ATTENTE`, sinon le plus récent.
- `result.objectiveLevel: TargetLevel | null` — `TargetProcedure.niveauVise`,
  même valeur que `/api/auth/me → targetLevel`.
- `result.situationObjectif: OBJECTIF_ATTEINT | UN_PALIER_SOUS_OBJECTIF |
  PLUSIEURS_PALIERS_SOUS_OBJECTIF | null` — `written.levelEstimate` situé par
  `TcfDomaine.ecartAuNiveauCible` ; `null` si le niveau (`NON_EVALUABLE`) ou
  l'objectif est inconnu.

⚠️ `result.priorities` / `result.mainPriorityExplanation` restent servis
(clients installés, `nextAction`) mais sont les priorités **du diagnostic**
(≤ 2 par production) : ils ne coïncident pas avec le Plan et ne s'affichent plus
comme « vos priorités ». **« Revoir ma réponse »** : aucune route nouvelle — la
consigne est `written.instruction`, le texte `texteSoumis` de
`GET /api/production-submissions/{written.submissionId}` (propriétaire seul,
404 sinon, production de diagnostic comprise).

## Diagnostic civique (L9)

Le pendant civique du diagnostic TCF. 🛑 **Ce n'est PAS l'examen blanc civique**
(`20_` §4.1) : même format (40 questions), mais couverture **équilibrée** sur les
5 thèmes au lieu de représentative, et il **crée** le plan là où l'examen blanc
**vérifie** la préparation. Le discriminant `attempts.civic_diagnostic_id` les
tient à l'écart de la grille des examens blancs.

🛑 **Aucune de ces routes n'appelle un LLM** : le civique est du QCM
déterministe, sa correction ne coûte rien. Le quota est donc distinct de celui
des analyses IA.

🛑 **La passation ne passe pas par ces routes** : les réponses vont sur
`/api/attempts/{id}/answers` (ou `/api/public/attempts/{id}/answers` sans
compte), exactement comme n'importe quelle série — aucun runner n'est dupliqué.

- `POST /api/civic-diagnostics` → `CivicDiagnosticDto`. Ouvre, ou rend celui
  déjà en cours. **Idempotent** : deux appuis ne font pas deux tirages, donc pas
  deux mesures incomparables.
- `GET /api/civic-diagnostics/current` → `CivicDiagnosticDto`, ou **204**.
  🛑 Une lecture n'ouvre **jamais** un diagnostic par effet de bord : l'ouverture
  est un geste du candidat, et elle consomme son unique diagnostic gratuit.
- `GET /api/civic-diagnostics/{id}` → l'état d'avancement.
- `POST /api/civic-diagnostics/{id}/result` → `CivicDiagnosticResultDto`, et
  **clôture** la session. `GET` sur la même adresse relit sans rien reclôturer.
  🛑 **Aucun `locked`** : « le constat est intégralement gratuit, le paywall
  porte sur l'accompagnement » (`20_` §4.5).
  🛑 `projection40` vaut `null` quand rien n'a été posé — « on n'a rien mesuré »
  ne se dit pas « vous auriez 0 ».

### Le diagnostic civique se passe AVANT le compte (V053)

🛑 **Arbitrage du propriétaire, 2026-09-10** : « que ce soit le diagnostic examen
civique ou TCF, l'utilisateur doit pouvoir passer le diagnostic avant de créer
son compte, il saisit le texte ou répond au QCM et seulement après on lui demande
de créer son compte pour voir le résultat. »

⚠️ **La mécanique diffère de celle du TCF, et c'est délibéré.** Le TCF invité
garde ses productions **sur l'appareil** (rien à corriger tant qu'aucun modèle
n'est appelé). Le civique est du QCM : le corriger côté client obligerait à
**servir les bonnes réponses à un visiteur**, et jouer 40 questions hors
`attempts` obligerait à écrire un **second runner**. On réutilise donc l'attempt
invité de la démo (`user_id IS NULL` + `client_ip`), et `civic_diagnostic_sessions
.user_id` devient nullable, avec un `client_ip` en regard.

- `POST /api/public/civic-diagnostics?procedure=CSP|CR|NAT` → `CivicDiagnosticDto`
  (**201**, public, rate-limité par IP comme la démo). Tire les 40 questions et
  ouvre la session du visiteur. `procedure` absente ⇒ **CSP**, le périmètre le
  plus étroit — mesurer un candidat sur des questions qu'il n'a pas à connaître
  produirait un diagnostic faussement sévère.
  🛑 **Pas idempotent** : sans compte, il n'y a rien sur quoi retrouver « celui
  déjà en cours ». Le front garde l'identifiant rendu.
- `GET /api/public/civic-diagnostics/{id}` → l'avancement du visiteur.
  **404 dès qu'un compte l'a adoptée** : une session adoptée n'est plus lisible
  que par son porteur, même depuis la même IP — deux personnes derrière le même
  NAT ne se lisent pas.
- 🛑 **Il n'existe AUCUNE route de résultat publique**, et c'est le cœur de la
  règle : le résultat est ce qu'on échange contre le compte.
- `POST /api/civic-diagnostics/{id}/adopt` → `CivicDiagnosticDto`
  (**authentifié**). Le visiteur vient de créer son compte : la session devient
  la sienne. 🛑 **Rien n'est rejoué, rien n'est retiré** — mêmes questions, déjà
  corrigées à la volée ; le serveur ne fait que poser le porteur (et rattache les
  lignes `answers` restées sans compte). **Idempotent** sur une session déjà
  adoptée par ce compte ; **404** sur celle d'un autre navigateur ou d'un autre
  compte. Le **quota du compte s'applique** (`20_` §4.3) : un compte qui a déjà
  son diagnostic gratuit ne s'en offre pas un second en repassant par le tunnel
  invité — le front propose alors le diagnostic existant.

## « Où vous en êtes » (Accueil)

- `GET /api/me/progress` → `ProgressDto { tcf: { objectif, epreuves[4] }, civique: { historique, themes } }` — chaque thème (`CivicPlanDto.ThemeLigne`) porte `evaluation` (`{themeId, slotNumber}`), servi seulement quand il est `NON_EVALUE`.
  🛑 **Élagué le 2026-09-24** : `activite`, `tcf.disponible`, `tcf.niveauActuel`,
  `tcf.historique`, `tcf.competences`, `civique.disponible`, `civique.travaillees`,
  `civique.maitrisees`, `civique.grainNotion` n'étaient lus que par l'ancien écran
  « Votre progression » (`/statistiques` ⇄ `ProgresScreen`), supprimé au profit
  des écrans de progression ci-dessous. Il ne reste que ce que l'Accueil lit.
  🛑 Les 4 épreuves sont **toujours** servies ; `evolution` vaut `INCONNUE` dès
  qu'un côté n'est pas évalué (**`INCONNUE` n'est pas `STABLE`**, `BAISSE` se
  sert) ; `epreuve.provenance` (`EXAMEN_BLANC` / `DIAGNOSTIC`, `null` sans palier,
  2026-09-27) dit d'où vient le palier ; `epreuve.evaluation` (`PlanDomainAssessmentDto`) est
  servi **tant qu'aucun examen blanc n'a mesuré l'épreuve** (`niveau == null` **ou**
  `provenance == DIAGNOSTIC`) — c'est ce qui donne « Évaluer mon niveau » sur la carte. `civique.historique` porte les diagnostics
  clos (l'Accueil en affiche le dernier score), `civique.themes` les lignes du
  moteur du plan civique (`CivicPlanService.themesAccueil`). Leur `etat` vient du dernier
  **examen blanc de thème**, sinon de la part du thème dans le dernier **examen civique global**,
  sinon du diagnostic (`EtatThemeCiviqueParExamens`, 2026-09-28).
- ~~`GET /api/me/progress/tcf/{epreuve}/historique`~~ — **supprimé le
  2026-09-24** (« Vos résultats »), remplacé par
  `GET /api/me/progression/tcf/{epreuve}`.

## Écrans de progression (2026-09-24)

Les quatre maquettes `docs/progression/maquettes-progression/*.html`. Contrat
complet et arbitrages D1–D20 : `docs/regles/progression.md` § « Écrans de
progression » · étude : `docs/progression/ETUDE_FAISABILITE_ecrans_progression.md`.
Authentifiés, `USER`. 🛑 **Tout est servi** (états, bandes, écarts, sens,
ordinaux, meilleur / premier / dernier, durées fiables) ; aucun front ne
recalcule rien. 🛑 **D20** : un compte gratuit voit tous ses résultats ; seul
`cta.locked` peut être vrai. Coût **constant** en requêtes, verrouillé à
l'égalité par `ProgressionSansNPlusUnIT`.

Briques communes :

```text
Echelle  { unite: PROGRESSION_499|NOTE_20|QUESTIONS, min, max, seuil?,
           bandes: [{ niveau?, etat?, min, max }] /* [] en CO/CE */, reperes: int[] }
Mesure   { attemptId, numero /*1 = le plus ancien*/, date, score?, max, niveau? /*TCF*/,
           etat?, seuilAtteint?, pointsManquants?, taux? /*civique*/, dureeSecondes?,
           provenance: EPREUVE_SEULE|EXAMEN_COMPLET|EXAMEN_THEME|EXAMEN_GLOBAL,
           rapport: { kind: QCM|PRODUCTION|EXAMEN_COMPLET, attemptId } }
Resume   { nombre, dernier?, meilleur?, premier?, ecart? /*null à 1 examen*/,
           sens: HAUSSE|STABLE|BAISSE|INCONNUE, serie: number[≤7] }
Cta      { locked }
```

- `GET /api/me/progression/tcf/{epreuve}` → `ProgressionEpreuveDto
  { epreuve, echelle, resume, niveauActuel?, examens: Mesure[≤50], cta }`.
  `{epreuve}` ∈ `TCF_CO|TCF_CE|TCF_EE|TCF_EO`, sinon **400**. Examens = l'épreuve
  passée **seule** + la même épreuve **dans un examen complet** ; ni diagnostic
  (D1), ni examen piloté par un `ExamTemplate` mixte (D18). CO/CE : score de
  progression /499 **sans bande** (D2) ; EE/EO : note /20 + bandes officielles
  `BandeNoteTcf` (D3). `niveauActuel` = le niveau affiché sur l'Accueil (D4).
  `cta.locked` : CO/CE jamais ; EE/EO = `ProductionAccessService.isProductionExamLocked`.
- `GET /api/me/progression/tcf[?tous=true]` → `ProgressionTcfDto { niveauActuel?,
  niveauActuelEpreuves, niveauActuelPartiel, examensComplets: { nombre, dernier?,
  meilleur?, premier?, evolution }, epreuves: [{ epreuve, echelle, resume }×4],
  examens: ExamenComplet[3 | ≤50], cta }` avec `ExamenComplet { attemptId (parent),
  numero, date, niveau?, partiel, epreuvesComptees, continuite?, parEpreuve:
  [{ epreuve, attemptId?, score?, max, niveau?, locked }×4] }`. 🛑 Aucun score
  global (D6). Comptés : examens complets **terminés** avec au moins une épreuve
  mesurée ; meilleur / premier sur les seuls **non partiels** (D7). Le palier
  d'un examen complet est **re-dérivé à la lecture** (D19). `cta.locked` toujours
  `false` (la grille des examens complets est ouverte).
- `GET /api/me/progression/civique[?tous=true]` → `ProgressionCiviqueDto
  { echelle (/40, seuil 32), global: Resume, themes: [{ themeId, code, label,
  echelle (/20), resume }×5], examens: [{ mesure, parTheme: [{ themeId, code,
  label, bonnes, posees }×5] }][3 | ≤50], cta }`. Parts par thème en « x / n
  posées », mises en situation **comprises**, **sans état** (D11). Cartes de
  thème sur les seuls **examens de thème** (D10). `cta.locked` = pas d'accès
  civique **et** aucun template civique gratuit publié.
- `GET /api/me/progression/civique/themes/{themeId}` → `ProgressionThemeDto
  { themeId, code, label, echelle (/20, seuil 16), resume, etat?, etatSource:
  DERNIER_EXAMEN_THEME, etatSourceLabel, examens: Mesure[≤50], cta }`. **404** si
  le thème n'existe pas ou n'est pas civique. `etat` = état du **dernier examen du
  thème**, pas celui de l'Accueil (D13). `cta.locked` = pas d'accès civique
  (examens de thème premium, D-33).
- ~~`GET /api/me/progression?module=`~~ (`ProgressionSummaryResponse`) — code mort,
  **supprimé** ; son chemin est réattribué à la famille ci-dessus.

## Plan civique (L10)

Le pendant civique du Plan TCF. 🛑 **Deux plans, deux moteurs, aucun effet
croisé** (`20_` §12) : le civique ne porte **aucune** métrique CECRL. Règles
complètes : `docs/regles/plan.md`, section « Plan CIVIQUE ».

🛑 **Rien n'est persisté** : le plan se **recalcule à chaque lecture** depuis
l'historique des réponses (aucune table `civic_plan`, `civic_plan_item` ni
`user_civic_notion_progress`, contrairement au schéma de `20_` §10). Corollaire :
il n'existe **pas** de route `/recompute` — recalculer, c'est relire. Ce que ça
rapporte : le tagging est **rétroactif**, et aucun job quotidien n'est nécessaire
pour les échéances.

- `GET /api/me/civic-plan` → `CivicPlanDto`.
  🛑 **Jamais 204** : sans diagnostic terminé, la réponse porte
  `disponible: false`. L'écran a besoin de savoir *pourquoi* il n'a rien à
  montrer pour ouvrir la porte qui débloque.
  🛑 **Le constat est intégralement gratuit** : les priorités sont servies
  entières — titre, état de maîtrise, compteurs — à un compte gratuit comme à un
  abonné. Seule la **série** porte `locked`.
  🛑 `priorites` est un **plafond d'affichage**, jamais un budget de calcul : le
  moteur classe toutes les cibles, et `autresPriorites` compte le reste.
  🛑 `grain` dit à quel **grain** le plan travaille (`THEME` / `NOTION`) et sur
  combien de thèmes il a basculé : le plan ne se présente jamais plus précis
  qu'il ne l'est. Tant que les questions ne sont pas taguées, `THEME` est le mode
  **prévu** par `20_` §3.3 (phase 1), pas une panne.
  🛑 `resultat` est le score du **diagnostic**, pas une estimation courante :
  mélanger des séries d'entraînement à un examen produirait un nombre qui
  ressemble à un score sans en être un.
- `POST /api/me/civic-plan/cibles/{cibleId}/serie?grain=THEME|NOTION` →
  `AttemptResponse` (**201**). Ouvre la **série ciblée** : un `TRAINING`
  ordinaire, joué dans le runner existant, qui ne consomme aucun slot d'examen
  blanc.
  🛑 **403 sans abonnement** — la même règle que le `locked` servi, cette fois
  opposable. À router vers l'offre, jamais à afficher en erreur technique.
  🛑 **Le tirage n'est pas aléatoire** : ce que le candidat a raté en dernier
  vient d'abord, puis ce qu'il n'a jamais vu. Sans cet ordre, « travailler ce
  point » redonnerait les questions déjà réussies.
  `grain` est **rendu tel quel par le plan** : on ne devine pas la nature d'un
  identifiant.

## Expression orale en temps réel (examinateur vocal, EO T1/T2)

Schéma de connexion **(A)** : le backend émet un **token éphémère** dont le setup
(modèle, persona, transcription, VAD, reprise) est **verrouillé côté serveur** ;
le client ouvre lui-même le WebSocket du fournisseur sur l'endpoint **contraint**
— il ne peut donc poser **aucun** champ de setup. Tous ces endpoints sont
**authentifiés**.

- `GET /api/realtime/eo/quota` → `{remaining, cap}` — sommes des deux sources (sessions offertes
  par un GRANT INTEGRAL admin, puis sessions de l'achat Intégral ; V084), calculées par
  `RealtimeQuotaService.evaluer`. Forme inchangée ; sans décision admin, valeurs d'avant.
- `POST /api/realtime/eo/sessions` → `RealtimeSessionDescriptor`. `mode=REALTIME`
  (token + endpoint WS) ou `ASYNC_FALLBACK` (quota épuisé, pass non éligible,
  temps réel non configuré, mint en échec) — le candidat n'est jamais bloqué.
  Le descripteur porte `resumable`, `resumptionsRemaining` et `connectWindowSec`.
- `POST /api/realtime/eo/sessions/{id}/resume` → **reprise après coupure réseau**.
  Corps facultatif `{resumptionHandle}` (repli sur le dernier handle connu du
  serveur). Renvoie un **nouveau** `RealtimeSessionDescriptor` sur la **même**
  session : même transcript, **aucun slot re-débité**. 422 si la session est
  terminée, si la reprise est désactivée ou si le plafond de reprises est atteint.
- `POST /api/realtime/eo/sessions/{id}/transcript` → fragment de dialogue.
  `{speaker, text, turnIndex?, resumptionHandle?}`. `turnIndex` (strictement
  croissant, attribué par le client) rend l'appel **idempotent** : un tour déjà
  appliqué est ignoré, donc un réessai après timeout ne duplique rien. Absent =
  comportement historique. C'est **ici** que le slot est débité, à la transition
  `PENDING -> ACTIVE`, sous verrou de ligne : **une seule fois par session**.
- `POST /api/realtime/eo/sessions/{id}/finish` → clôture + déclenche la notation.

## Compétences TCF (micro-entraînement EE/EO)

`POST /api/skill-attempts` accepte la même `clientSubmissionId` **facultative** que
les productions complètes (V046), avec la même sémantique : rejouer la clé rend la
même production, sans seconde analyse décomptée ni second appel LLM.


Voie **parallèle** aux productions complètes : un « petit sujet » travaille **une seule
compétence**, et l'IA ne rend qu'un verdict sur son critère unique — **jamais de note /20 ni
de niveau CECRL**. Tous ces endpoints sont **authentifiés** ; aucun n'est public.

- `GET /api/skills/progress?section=EE|EO` → 3 `SkillTaskProgressDto`, une par tâche
  (`EE1..EE3` ou `EO1..EO3`). `section` est requis.
- `GET /api/skills?taskCode=EE1|EE2|EE3|EO1|EO2|EO3` → les 8 compétences actives de la tâche,
  avec la progression de l'utilisateur courant.
- `GET /api/skills/{skillId}` → `SkillDetailDto` : la compétence + ses 15 sujets avec leur
  statut (`TODO` / `TREATED` / `VALIDATED` / `TO_REINFORCE`), **dérivé serveur** — aucun
  front ne le recalcule.
- `GET /api/skills/analysis-quota` → `SkillAnalysisQuotaDto
  {premium, unlimited, freeAnalysesTotal, freeAnalysesUsed, remaining}`. `remaining = -1`
  signifie **illimité** : les fronts doivent le traiter comme tel et ne jamais l'afficher brut.
  ⚠️ **Contrat inchangé, valeurs dégénérées depuis le 2026-09-18** (D-17, suppression de
  `free-analyses: 3`) : `freeAnalysesTotal = 0` et `remaining = 0` pour un compte gratuit,
  `-1` pour un abonné ; seul `freeAnalysesUsed` reste un fait. L'endpoint ne dit donc plus
  rien de plus que « cet utilisateur a-t-il l'accès TCF ». **À retirer avec ses lecteurs
  front**, pas avant.
- `GET /api/skill-prompts/{promptId}` → `SkillPromptDto`, le sujet complet pour l'écran de
  production. **Ne contient jamais les références.** Porte aussi `nextPromptId` (premier sujet
  `TODO` de la même compétence) et les champs `skill*` qui évitent un second appel.
- `GET /api/skill-prompts/{promptId}/references` → les 3 références comparatives, ordonnées
  `INSUFFICIENT`, `EXPECTED`, `EXCELLENT`. **403** tant que l'utilisateur n'a **aucune**
  tentative sur ce sujet : les références ne s'ouvrent qu'après sa propre production. La garde
  exige une tentative, pas une tentative *réussie*.
- `GET /api/skill-prompts/{promptId}/attempts?limit=5` → historique de l'utilisateur sur ce
  sujet, plus récent d'abord. `limit` borné **1..20**, défaut **5**.
- `POST /api/skill-attempts` — **deux `@PostMapping` sur le même chemin, distingués par
  `consumes`**, exactement comme `/api/production-submissions` :
  - `application/json` (écrit EE) → `SubmitSkillTextRequest
    {skillPromptId, texte, selfEvaluation?, requestAnalysis}` ;
  - `multipart/form-data` (oral EO) → parts/params `audio`, `skillPromptId`, `durationSec`,
    `selfEvaluation` (facultatif), `requestAnalysis`.

  → **201** + `SkillAttemptDto`. La section du sujet et le média doivent concorder (un sujet
  EE refuse un audio et inversement). Bornes anti-abus : **400 mots** en EE, **180 s** et la
  taille audio max partagée avec les productions complètes en EO. Rate-limit dédié
  (`skill-attempt` : 40 / 10 min et 400 / jour).
- `GET /api/skill-attempts/{id}` → polling du résultat. La tentative d'un autre utilisateur
  répond **404** (et non 403, qui confirmerait l'existence de l'id) — même convention que les
  productions et les examens complets.
- `POST /api/skill-attempts/{id}/analyse` → demande l'analyse IA d'une production **déjà rendue
  sans elle** (statut `RECORDED`), pour l'utilisateur qui produit gratuitement puis s'abonne :
  sans cet endpoint il devait refaire le sujet et perdait sa production. **Consomme le quota**,
  et est refusé sur tout autre statut — sinon le quota serait contournable.
- `POST /api/skill-attempts/{id}/retry` → relance une analyse `FAILED`. **Ne re-consomme pas**
  le quota (l'échec n'est pas du fait du candidat), ce qui **impose** le plafond de 3 essais
  (`retry_count`, appliqué en service *et* en base).

**Freemium (règle du 2026-08-10 — révoque « aucun sujet n'est verrouillé »)** : pour un compte
**sans accès TCF**, seules sont ouvertes **la première compétence de chaque tâche** (6 au
total) **plus la compétence de la priorité n°1 de son Plan**, et dans chacune **les 2 premiers
sujets actifs**. Sur un sujet ouvert, produire, s'auto-évaluer et lire les 3 références restent
gratuits et illimités. Un abonné TCF n'a aucun verrou.
- **`locked: boolean`** est porté par `SkillDto`, `SkillPromptDto`, `SkillPromptSummaryDto`,
  `LearningPlanPriorityDto`, `LearningPlanSkillDto` et `PlanRecommendedExerciseDto`. Sémantique
  unique : `true` ⇒ **ce candidat ne peut pas produire** sur cette compétence / ce sujet → les
  fronts affichent un cadenas et renvoient vers le paiement. Toujours `false` pour un abonné
  TCF. **Décidé par `SkillAccessService`, jamais recalculé par un front.**
- **Le verrou est opposable** : `POST /api/skill-attempts` (JSON et multipart),
  `POST /api/skill-attempts/{id}/analyse` et `.../retry` répondent **403** sur un sujet
  verrouillé, avant tout traitement — aucune ligne créée, aucun audio uploadé.
- **L'analyse IA reste un verrou distinct et cumulé**, mais il n'offre plus rien :
  🛑 depuis le **2026-09-18** (D-17), `free-analyses: 3` est **supprimé** sans remplaçant et
  `SkillAnalysisAccessService` refuse **dès la première** analyse d'un compte sans accès TCF.
  Aucun quota journalier n'a été introduit. *(Le compteur `analysis_requested` reste écrit à
  l'acceptation, pas au succès — ce fait-là n'a pas bougé.)*
- La garde des **références** (« au moins une tentative sur ce sujet ») est **inchangée** et
  indépendante de `locked`.

**Oral** : l'enregistrement **n'est pas conservé** — il sert à produire la transcription
pendant la requête de soumission, puis il disparaît. La transcription est donc
**systématique**, analyse demandée ou non, et le DTO ne porte **aucune URL audio**. Un échec
de transcription rend **503** et rien n'est enregistré : le candidat renvoie. Cf.
`notation-ia-eo-ee.md` §11 bis.

## Paiements (`/api/billing`) — intention d'achat et reçus (lot 2b « Suivi », 2026-09-25)

Règle complète : `docs/regles/paiements.md` § « Revenus nets, remboursements, intention
d'achat ». Seuls les ajouts du lot 2b sont décrits ici ; les autres routes billing
(`/plans`, `/subscription-status`, `/cancel`, webhooks) sont inchangées.

🛑 Depuis V083 (2026-10-02), `/subscription-status` et la réponse de `/verify-receipt` sont
construites par **un seul** service (`SubscriptionStatusService`) sur l'**accès effectif**
(achats + décisions admin) — le même que `/api/auth/me`. Forme inchangée, aucune valeur
nouvelle ; sans décision admin, la réponse est identique à avant
(`AccesEffectifNonRegressionIT`). Accès accordé par l'admin sans achat : `source` /
`productId` absents, `status = ACTIVE`, `oneTime = true`.

- `GET /api/billing/payment-link?planCode=&retour=&ctaLocation=&journeyId=` — authentifié.
  **Nouveaux paramètres facultatifs** `ctaLocation` (valeur de `AnalyticsCtaLocation` :
  `DIAGNOSTIC_REPORT | LOCKED_PLAN | PRICING | AI_CORRECTION | MOCK_EXAM | HERO | MIDDLE |
  STICKY | FOOTER | OTHER`, insensible à la casse) et `journeyId` (le `journey.id` du Plan
  affiché, Q8). En mode pass, ils créent une `purchase_intent` serveur **avant** la Checkout
  Session, transportée par `metadata.intentId`. Absents ou illisibles : **aucune erreur**, pas
  d'intention, l'achat sera `origin = UNKNOWN`. Un `journeyId` d'un autre compte est ignoré.
  🛑 `ctaLocation = LOCKED_PLAN` sans run fondatrice résoluble (pas de `journeyId`, parcours
  d'un autre compte, diagnostic sans run) ⇒ `origin = UNKNOWN`, **jamais `OTHER_CTA`** (lot 4).
- `POST /api/billing/purchase-intents` — authentifié, **nouveau**. Appelé par le mobile
  **avant** d'ouvrir la feuille Apple / Google.
  Corps `{productId, ctaLocation, journeyId?}` : `productId` = code du pass (`plans.code`) **ou**
  SKU store (`apple_product_id` / `google_product_id`) ; `ctaLocation` = même liste que
  ci-dessus. Réponse **201** `{purchaseIntentId: uuid, expiresAt: instant}` (TTL 24 h,
  `analytics-config purchaseIntentTtlHours`). **404** produit inconnu ou inactif, **400** CTA
  hors liste. La plateforme est lue sur `X-Sejourfr-Client`. La run fondatrice est résolue
  serveur depuis le parcours, jamais reçue.
- `POST /api/billing/verify-receipt` — corps étendu, **tous les nouveaux champs facultatifs** :
  `{source, receipt, productId, amountCents?, currency?, purchaseIntentId?, rawPrice?,
  currencyCode?}`. `amountCents` + `currency` (unités mineures, ce que le mobile envoie) sont
  enfin lus ; `rawPrice` + `currencyCode` restent acceptés (anciens clients), `amountCents`
  gagne si les deux sont présents. 🛑 **Apple** : le montant déclaré est ignoré, le prix vient
  du JWS signé. **Google** : le montant déclaré n'est retenu que s'il tient dans
  `plans.price × (1 ± 0,5)`, sinon le prix du catalogue. `purchaseIntentId` : l'id rendu par
  `POST /purchase-intents`, à renvoyer tel quel (y compris au rejeu d'un achat au lancement
  suivant) ; absent, inconnu, expiré, consommé, d'un autre compte ou d'un autre produit ⇒
  l'achat est crédité normalement, `origin = UNKNOWN`.
- `POST /api/billing/webhook` (Stripe) — **plus de rejet sur l'âge de l'évènement** (une
  relance Stripe > 5 min était refusée définitivement) ; idempotence par id d'évènement.
  Nouveaux évènements traités : `checkout.session.async_payment_succeeded` (octroi d'un
  paiement différé) et `checkout.session.async_payment_failed` (journalisé). Une session
  `payment_status ≠ paid` n'ouvre plus d'accès. `charge.refunded` distingue partiel et total.
  Contrôles de la passe Suivi : `charge.dispute.closed` statut `lost` retire l'accès et écrit
  une ligne `payment_refunds` (N6) ; les remboursements concurrents n'écrivent qu'une ligne
  (A). `GET /api/billing/payment-link` crée une session Checkout **carte seule** et
  l'intention d'achat se juge à la création de la session (B).

## Audience des landings — retirée (2026-09-25)

`POST /api/public/page-views`, `GET /api/admin/page-views`, `GET /api/admin/page-views/paths`
et `GET /api/admin/audience/funnel` ont été **supprimés** au lot 1a du chantier « Suivi » :
aucun front ne les appelait plus. La table `page_views` (V020) reste en base, plus jamais
écrite ni lue. La mesure d'audience passe par `POST /api/public/analytics/events/batch`
(et, pour l'app publiée, l'unitaire `POST /api/public/analytics/events` rétabli, cf. plus
haut) et `POST /api/me/funnel-events` (cf. `docs/regles/mesure-audience.md`).

## Admin

- `/api/admin/{dashboard,questions,themes,conversations,media,passages,audio-questions,calibration/{stats,submissions/{id}/human-note},diagnostics,productions}`
- `GET /api/admin/questions?module=&themeId=&difficulty=&type=&active=&media=&search=&page=&size=`
  — `media` vaut `AUDIO | IMAGE | VIDEO | NONE | IMAGE_FILE | IMAGE_SVG | AUDIO_MISSING`
  (`NONE` = questions sans média principal ; `IMAGE_FILE` = image servie par URL ;
  `IMAGE_SVG` = image en SVG inline sans URL — les CO image à remplacer ;
  `AUDIO_MISSING` = CO_IMAGE sans `audioMedia` ou CO sans média principal AUDIO). Les
  valeurs de type portent sur `question.media`, pas sur l'audio secondaire d'une
  `CO_IMAGE`. **Filtre serveur** : la console ne doit plus filtrer la page affichée dans
  le navigateur.
- `QuestionDto` (admin seulement) porte `audioMissing` (même règle que
  `media=AUDIO_MISSING`, autorité `util/AudioManquant`) : une telle question n'est jamais
  tirée.
- `PATCH /api/admin/questions/{id}/status` (et `active` du `PUT`) bascule **ensemble**
  `is_active` et `status` : activer ⇒ `ACTIVE` ; désactiver une `ACTIVE` ⇒ `ARCHIVED` ;
  une `DRAFT` ou une `ARCHIVED` désactivée garde son statut. Les tirages candidats
  exigent `is_active` **et** `status = ACTIVE` (et l'audio pour une `CO_IMAGE`) :
  `QuestionRepository.SERVABLE_JPQL`.
- ⚠️ `GET /api/admin/calibration/submissions` est **supprimé** (404) le 2026-10-03 : la liste
  des productions vit dans `GET /api/admin/productions` (filtre `annotation` =
  `ANNOTEES|NON_ANNOTEES`). La calibration garde `GET /stats`, `GET /stats/niveau`,
  `GET|POST /submissions/{id}/human-note`.

### Admin — Import CO image (`/api/admin/question-imports/co-image`, 2026-10-04)

Import par lot de questions TCF `CO_IMAGE` vers les **brouillons audio**
(`audio_question_draft`, statut `TEXT_VALIDATED`) — jamais vers `questions`. La suite est
le pipeline existant : « Générer l'audio » (`POST /api/admin/audio-drafts/batch-generate`),
revue, puis validation (`POST /api/admin/audio-drafts/{id}/validate`). Détail :
`docs/pipeline-audio-co.md` § « Import par lot ».

- `POST …/analyze` et `POST …/import`, **multipart** :
  - partie `manifest` : le manifeste JSON (Blob `application/json` ou champ texte, UTF-8) ;
  - N parties `images` : un fichier chacune, nom **exact** cité par `questions[].image`.
- Manifeste : `{ "version": "1", "format": "CO_IMAGE", "questions": [ { "externalId",
  "level" (A2|B1|B2), "themeCode"? (défaut `TCF_CO`), "image", "sceneDescription",
  "choices" (4 textes, lus A→D), "correctAnswer" (A-D), "explanation"? } ] }`. Champ
  inconnu = manifeste refusé.
- Réponse `CoImageImportReport` : `ok`, `imported`, `format`, `charteVersion`,
  `maxQuestions`, `questionCount`, `errors[]` (erreurs de **lot**), `questions[]`
  (`index`, `externalId`, `ok`, `level`, `themeCode`, `themeName`, `image`, `imageFormat`,
  `imageWidth`, `imageHeight`, `imageSizeBytes`, `sceneDescription`, `choices[]`
  `{letter,text,correct}`, `correctAnswer`, `explanation`, `transcriptText`, `errors[]`,
  `draftId`, `imageUrl`). Une erreur = `{code, field, message}` (`CoImageImportErrorCode`).
- `analyze` : **200** toujours, rien n'est écrit ni envoyé. `import` : **201** +
  `imported=true` (brouillons créés, `draftId`/`imageUrl` renseignés) ou **422** + le même
  rapport, **rien d'écrit**. Échec R2 pendant l'import : erreur du pipeline audio (5xx,
  `code`), brouillons annulés, images déjà envoyées supprimées au mieux.

### Admin — Productions IA (`/api/admin/productions`, 2026-10-03)

Audit : `docs/admin/productions_corrections/audit-admin-productions-ia.md` ; décisions :
`docs/admin/productions_corrections/decisions-implementation-productions-ia.md`. `ROLE_ADMIN`
(401 / 403 sinon, `AdminRoutesSecurityIT`). Périmètre : productions TCF EE/EO **complètes**
(EO temps réel comprise) — ni diagnostic, ni petits sujets Compétences. DTO **propres à l'admin** :
aucun DTO candidat ne change. Tout est servi (statut, libellés, calcul) : le front ne recalcule rien.

- `GET /api/admin/productions?q=&epreuve=&tache=&niveau=&statut=&signalement=&annotation=&periode=&from=&to=&includeInternal=&sort=&page=&size=`
  → `PageResponse<AdminProductionListItemDto>` (`page` indexée à 0, `size` défaut **25**, bornée
  `[1, 100]`).
  - `q` : UUID complet ⇒ id de production **ou** id utilisateur ; sinon email « contient »,
    sans casse, `%`/`_` échappés.
  - `epreuve=TCF_EE|TCF_EO` ; `tache=1|2|3` ; `niveau=A1_NON_ATTEINT|A1|A2|B1|B2|SANS_NIVEAU`
    (niveau observé de la dernière évaluation ; `SANS_NIVEAU` = en cours, échec, non évaluable) ;
    `statut=EN_COURS|EVALUEE|NON_EVALUABLE|ECHEC` ;
    `signalement=SIGNALEES|VERIFIEES|NON_SIGNALEES` (actif non vérifié / actif vérifié / aucun
    actif — un signalement retiré ne compte plus) ; `annotation=ANNOTEES|NON_ANNOTEES` (note
    humaine de calibration) ; `periode=TODAY|LAST_7_DAYS|LAST_30_DAYS` (jours Europe/Paris)
    **ou** `from`/`to` (`yyyy-MM-dd`, inclus, les deux, 365 j max, `FenetreMesure`) ;
    `includeInternal=false` (comptes `is_internal` exclus par défaut) ;
    `sort=DATE_DESC|DATE_ASC|NIVEAU_DESC|NIVEAU_ASC|EPREUVE` (défaut `DATE_DESC`, toujours
    complété par `submitted_at DESC, id DESC` ; sans niveau en dernier). Valeur inconnue,
    épreuve hors EE/EO, tâche hors 1-3, `periode` + `from`/`to`, borne seule ⇒ **400**.
  - Ligne : `id, submittedAt, userId, userEmail, userInternal, epreuve, tache, source
    (ASYNC|REALTIME), contexte (ENTRAINEMENT|EXAMEN_BLANC|EXAMEN_COMPLET) + contexteLabel,
    niveauObserve (nullable), statutIa + statutIaLabel, etatSignalement (AUCUN|SIGNALE|VERIFIE)
    + etatSignalementLabel, annotee`.
  - **Coût figé : 2 requêtes par page** (contenu + comptage), verrouillé par égalité dans
    `AdminProductionControllerIT`.
- `GET /api/admin/productions/{submissionId}` → `AdminProductionDetailDto` : `entete` (la ligne),
  `sujet` (tel que reçu, sans la fiche examinateur), `reponse` (texte + mots, ou transcription
  recollée + durée + `transcriptionInfo` ; `audioConserve: false` + motif — **aucun audio**),
  `evaluationIa` (dernière évaluation : critères **retenus** + poids de SA grille, note, niveau IA
  vs niveau retenu + écart en crans, confiance, justification), `calcul` (relu avec la grille de
  l'évaluation par les fonctions de la notation ; `statut=CALCULE|CALCUL_PARTIEL|REGLE_NON_TRACABLE|NON_EVALUABLE|SANS_EVALUATION` ;
  `CALCUL_PARTIEL` = grille sans ses propres seuils / couplage / plafonds / poids (v3 → v5) :
  calcul servi, `coherent` toujours `null`, jamais un faux « incohérent »),
  `vueCandidat` (le `ProductionSubmissionDto` exact du candidat, `planChange` nul), `technique`
  (modèle, versions, tokens, `coutMicroUsd` en USD×10⁻⁶, `coutLegacyCentimesEuro`, délai
  soumission → évaluation, relances manuelles, erreur), `jsonPersiste` (`feedback_json` APRÈS
  traitement serveur), `signalements` (historique, retirés compris), `signalable`.
  **Lecture passive** : aucune écriture, aucun appel LLM. Inconnue ou hors périmètre ⇒ **404**.
- `POST /api/admin/productions/{submissionId}/flags` `{ motif, commentaire? }` → **201**
  `AdminProductionFlagDto`. `motif=NIVEAU_INCOHERENT|SCORE_INCOHERENT|FEEDBACK_INCORRECT|REPONSE_MAL_COMPRISE|TRANSCRIPTION|AUTRE`
  (obligatoire, sinon 400), `commentaire` ≤ 1000. Vise la dernière évaluation (NON_EVALUABLE
  comprise). Aucune évaluation ⇒ **422** ; signalement déjà actif ⇒ **409** ; inconnue ⇒ 404.
- `POST /api/admin/productions/flags/{flagId}/verify` → 200, idempotent ; signalement retiré ⇒ **409**.
- `POST /api/admin/productions/flags/{flagId}/remove` → 200, retrait **soft** (historique gardé),
  idempotent. 🛑 Un signalement ne modifie **jamais** l'évaluation (note, niveau, feedback) ni ce
  que voit le candidat (table `ai_evaluation_flags`, V085).

### Admin — Suivi (`GET /api/admin/analytics/suivi`, chantier « Suivi » lot 4, 2026-09-25)

Remplace `GET /api/admin/analytics` et `/api/admin/analytics/annotations` (ancien écran
`/dashboard`), **supprimés** (404) ; les tables `analytics_annotation`, `analytics_event`,
`analytics_visitor` restent. `ROLE_ADMIN` (401 / 403 sinon).

- Paramètres, tous facultatifs : `preset=TODAY|YESTERDAY|LAST_7_DAYS|LAST_30_DAYS|MONTH` (défaut `TODAY`,
  jours Europe/Paris, `MONTH` = du 1er à aujourd'hui) **ou** `from`/`to` (`yyyy-MM-dd`,
  bornes incluses, les deux ou aucun, 365 j max) — `preset` avec `from`/`to` → **400** ;
  `type=ALL|TCF|CIVIQUE` (TCF = `QUICK_TCF`) ; `platform=ALL|WEB|IOS|ANDROID` ;
  `source=ALL|<groupe de la config>` (`instagram|tiktok|facebook|direct|autre`) ;
  `includeInternal=false`. Valeur inconnue → **400** nommé.
- Réponse `AdminSuiviResponse` : `window`, `filters` (+ `availableSources`),
  `measurementStart` (toutes les clés `SuiviIndicator`), `kpis` (visiteurs, soumis, achats,
  net réel estimé, inscriptions — `signups` = `signups.total`, D118 ; valeur, période
  précédente, variation, ligne secondaire), `funnel`
  (7 étapes, % depuis la précédente et % de l'étape 1, 3 sous-lignes de « Compte rattaché »,
  CA net cohorte, « en cours », `runsWithoutIdentifier` = entrées de l'étape 1 sans
  compte ni identifiant de mesure, doublons possibles — contrôle D), `revenue` (brut, TVA,
  frais, nets, remboursements, net après remboursements, par canal,
  `grossUnknownPurchases` = achats au brut inconnu, le brut est alors partiel — contrôle
  N5), `byType`, `signups`, `sources`, `unknownSourceVisitors` (visiteurs sans source ;
  groupes + inconnue = KPI visiteurs), `ratios` (§7.4),
  `activity` (§7.3). Montants en centimes, % à une décimale.
- 🛑 `null` = inconnu ou **pas encore mesuré** (date `measurementStart` absente ou postérieure
  à la FIN de la période, D43), jamais 0. Une période qui chevauche la date est servie
  **depuis cette date** (D117) ; la période précédente n'est lue que mesurée de bout en bout.
- Définitions de chaque indicateur : `docs/regles/mesure-audience.md` § « Lecture du
  dashboard Suivi ». Six requêtes SQL constantes, ~160 ms sur un mois réaliste
  (`SuiviPerformanceIT`), sans cache. Le KPI visiteurs et les sources **ignorent
  `SCREEN_VIEWED`** (D8). `measurementStart` porte aussi `ACTIVE_USERS`, `LOGINS`,
  `SCREEN_VIEWS_WEB`, `SCREEN_VIEWS_APP` (écran « Activité »).

### Admin — Activité (`/api/admin/analytics/activity`, chantier « Activité », 2026-10-03)

`ROLE_ADMIN` (401 / 403 sinon). Contrat TypeScript complet :
`docs/admin/activites/decisions-implementation.md` § Contrat. Définitions :
`docs/regles/mesure-audience.md` § « Activité des utilisateurs ».

- `GET /api/admin/analytics/activity/live?includeInternal=false` →
  `AdminActivityLiveResponse {at, windowSeconds (180), includeInternal, measurementStart,
  total, multiPlatformUsers, byPlatform[5]}` — comptes connectés actifs depuis moins de
  `windowSeconds` (D3, D11 : l'admin le relit toutes les 30 s). Une requête SQL.
- `GET /api/admin/analytics/activity` — mêmes `preset` (dont `LAST_30_DAYS`) / `from`+`to`
  que Suivi, mêmes 400, `includeInternal=false` → `AdminActivityResponse {window,
  includeInternal, measurementStart (4 indicateurs), activeUsers {measuredSince, total
  {value, previous, deltaPct}, multiPlatformUsers, daily[]}, logins {measuredSince,
  uniqueUsers (KPI), total, signups, byMethod[LOCAL, GOOGLE, APPLE]}, platforms[5]
  {activeUsers, loggedInUsers, logins}, screens {web, app} (top 20 + « autres écrans
  suivis » + « non déclarés » + total ; vues, visiteurs uniques, comptes uniques partiels ;
  iOS / Android / app inconnue sur l'onglet App)}`. Trois requêtes SQL constantes
  (`ActivityPerformanceIT`).
- Plateformes toujours dans l'ordre `WEB, IOS, ANDROID, MOBILE, UNKNOWN`, avec `label` servi
  (« App — système inconnu » pour `MOBILE`, l'ancienne app) et `displayed` (`UNKNOWN`
  seulement avec `includeInternal`, N6). 🛑 `null` = non mesuré, jamais 0 ; règle D117 de
  Suivi.

### Admin — Abonnements (`/subscriptions`)

- `GET /api/admin/subscriptions?source=&status=&moduleAccess=&search=&purchasedMonth=&page=&size=` →
  `PageResponse<AdminSubscriptionDto>` (`content`, `page`, `size`, `totalElements`,
  `totalPages`, `first`, `last`). ⚠️ Remplace l'ancienne enveloppe
  `AdminSubscriptionListResponse {items, total, page, size}`, supprimée le 2026-09-25.
  - **Pagination serveur** : `page` indexée à 0 (négative ⇒ 0), `size` défaut 25 et
    bornée à `[1, 100]`. Une page au-delà de la dernière rend `content: []` avec les
    totaux justes (le front s'y recale).
  - **Filtres dans la requête SQL**, jamais en mémoire : `source` (`STRIPE|APPLE|GOOGLE`),
    `status` (`SubscriptionStatus`), `moduleAccess` (`CIVIQUE|INTEGRAL`, via le plan) et
    `search` — « contient », sans casse, sur l'email, le prénom, le nom ou « prénom nom » ;
    `%` et `_` saisis sont échappés (un `_` d'email n'est pas un joker).
  - `purchasedMonth=yyyy-MM` : achats de ce **mois civil en heure de Paris** —
    `purchased_at` dans `[1er du mois 00:00 Paris, 1er du mois suivant 00:00 Paris[`
    (début inclus, fin exclue ; changements d'heure compris). Une ligne sans
    `purchased_at` (antérieure à la mesure, V074) n'appartient à aucun mois. Valeur
    illisible (`2026-13`) ⇒ 400.
  - `AdminSubscriptionDto.purchasedAt` (`Instant` ou `null`) : date réelle de l'achat
    (≠ `startsAt` pour un pass empilé).
  - **Tri imposé et stable** : `updatedAt` DESC puis `id` DESC. Le second critère empêche
    une ligne d'apparaître sur deux pages (ou sur aucune) quand plusieurs partagent le
    même `updated_at`. Pas de paramètre `sort` exposé.
  - **Coût figé : 2 requêtes par page** (contenu avec `user` et `plan` joints par
    `@EntityGraph`, + comptage), quel que soit `size` — verrouillé par égalité dans
    `AdminSubscriptionControllerIT`.
- `POST /api/admin/subscriptions/{id}/cancel` → `CancelSubscriptionResponse`
  (`DONE` Stripe / `REDIRECT` Apple-Google).
- `PATCH /api/admin/subscriptions/{id}/realtime-sessions` `{ remaining }` → `AdminSubscriptionDto`.
  Écriture ciblée (UPDATE en masse) : **ne fait pas avancer `updatedAt`**. Inconnue ⇒ 404.
- 🛑 Identifiants de paiement (`util/ReferenceExterne`, D-33) : Stripe et Apple **entiers** ;
  seul l'`originalTransactionId` d'un achat Google (= purchaseToken) est **tronqué**
  (« 8 premiers…4 derniers »). `externalTransactionId` (dont l'orderId Google) est entier.
  Forme (chaîne) inchangée.

### Admin — Utilisateurs (console « Utilisateurs », V083, 2026-10-02)

Règle : `docs/regles/paiements.md` § « Accès effectif = achats + décisions admin ».
Décisions : `docs/admin/utilisateurs/decisions-gestion-utilisateurs.md`. Miroir TS : `admin_sejourfr/src/types/api.ts`.
Tout est calculé serveur (statuts, dates incluses, libellés, actions proposées) : le front n'en
recalcule rien.

- `GET /api/admin/users?q=&filter=&page=&size=` → `PageResponse<AdminUserListItemDto>`
  (`id`, `displayName`, `email`, `createdAt`, `effectiveAccess {effectiveProduct, …Label,
  openModules, openModulesLabel}`, `accesses[] {product, productLabel, status, statusLabel}`
  — un badge par produit CIVIQUE / INTEGRAL —, `nextEndsAt` / `nextEndDateInclusive` /
  `nextEndLabel` (fin la plus proche parmi les produits actifs), `lastActivityAt` (vue V073),
  `accountStatus` `ACTIVE|DELETED` + label, `manualAccess`).
  - `q` : UUID complet ⇒ égalité d'id ; sinon « contient », sans casse, email / prénom / nom /
    « prénom nom », jokers échappés.
  - `filter` : `ALL` (défaut) · `TCF_ACTIVE` · `CIVIQUE_ACTIVE` (Civique ouvert, Intégral compris) ·
    `NO_ACTIVE_ACCESS` · `EXPIRED` (au moins un achat ou GRANT, aucun accès actif) ·
    `MANUAL_ACCESS` (décision admin courante non terminée). Valeur inconnue ⇒ 400.
  - `page` indexée à 0, `size` défaut 25, bornée `[1, 100]`. Tri `createdAt` DESC, `id` DESC.
  - Coût constant par page (sur-ensemble SQL résolu en Java, puis pagination) — verrouillé par
    égalité dans `AdminUserControllerIT`.
- `GET /api/admin/users/{userId}` → `AdminUserDetailDto` : `account` (sans hash ni jeton),
  `effectiveAccess`, `lastActivityAt`, `accesses[]` (`AdminUserAccessDto` : `status`
  `ACTIVE|SCHEDULED|REVOKED|EXPIRED|NONE` + label, `summary`, `startsAt`, `endsAt` (borne
  exclusive), `endDateInclusive` (seulement pour une fin posée par l'admin), `endLabel`
  (« 31/10/2026 inclus » ou « 01/11/2026 à 14:37 » pour un achat), `defaultEndDateInclusive`
  (`yyyy-MM-dd`, valeur que la modale pré-remplit dans « Fin (incluse) » : date incluse d'une fin
  admin, sinon jour Paris de la fin d'achat ; pour un produit RÉVOQUÉ, jour Paris de la fin de
  l'achat révoqué — `DateMetierParis.finProposee`, D-22 / D-34), `origin`
  `PURCHASE_STRIPE|PURCHASE_APPLE|PURCHASE_GOOGLE|ADMIN_GRANT|ADMIN_REVOKE` + label,
  `alerts[] {code, label}`, `availableOperations[] {code, label}`, `realtimeEoSessions` —
  carte INTEGRAL seulement, `null` pour CIVIQUE : `{remaining, grantGranted, grantRemaining,
  purchaseRemaining, scheduledGrantGranted, label, info}`, servis par l'autorité du quota ; `label`
  ex. « 14 sessions restantes — accès manuel : 14 restantes sur 20 accordées ; achat : 0 » (le
  total de la lignée se dit « accordées », jamais « offertes », D-54) ; `info`
  = « Cet accès manuel n'ajoute pas actuellement de sessions EO temps réel. » quand l'accès manuel
  affiché n'en offre aucune), `purchases[]`
  (`externalReference` : identifiant d'origine, entier sauf purchaseToken Google tronqué ;
  `recurring`), `progression[]` (TCF puis Civique :
  diagnostic clos + date, cycle en cours, cycles historisés — lecture en tables, jamais
  `JourneyService.lire()`), `history[]` (une entrée par action, `changes[]` en phrases),
  `accessVersion`. Inconnu ⇒ 404.
- `GET /api/admin/access-products` → `AdminAccessProductDto[]` : `CIVIQUE` (Civique) puis
  `INTEGRAL` (TCF + Civique). Pas de produit « TCF » seul. `maxRealtimeEoSessions` : plafond des
  sessions EO offertes par action (INTEGRAL : 50 par défaut, config ; CIVIQUE : `null`).
- `POST /api/admin/users/{userId}/access-operations` `AdminAccessOperationRequest`
  `{operation, product, fromProduct?, startDate?, endDateInclusive?, reason, dryRun, expectedVersion?,
  realtimeEoSessions?}`
  → `AdminAccessOperationResponse {dryRun, operationId, operation, preview,
  confirmationRequired, changes[], effectiveAccess, accesses[], accessVersion}`.
  - `operation` : `GRANT` · `EXTEND` · `SHORTEN` · `END` · `REACTIVATE` · `CORRECT_PRODUCT`
    (`fromProduct` → `product`, une seule opération atomique).
  - Dates `yyyy-MM-dd`, jours Europe/Paris : fin incluse ⇒ borne `lendemain 00:00 Paris` ;
    début « aujourd'hui » = maintenant, futur = 00:00 Paris.
  - `dryRun: true` : aperçu + état résultant, rien n'est écrit. `dryRun: false` exige
    `expectedVersion` (= `accessVersion` de la fiche).
  - `realtimeEoSessions` (V084, absent = 0) : sessions EO temps réel offertes ; > 0 accepté
    seulement pour `GRANT` / `REACTIVATE` INTEGRAL et `CORRECT_PRODUCT` vers INTEGRAL, au plus
    `maxRealtimeEoSessions`. Sur un GRANT INTEGRAL actif, elles **s'ajoutent** à son solde (pas
    de 409).
  - `preview` annonce le devenir des sessions EO : « Cet accès manuel offre N sessions… »,
    « Sessions EO temps réel : 4 sessions restantes + 10 offertes → 14 sessions disponibles. »,
    « Les N sessions … restantes de l'accès manuel sont conservées. » / « … seront perdues. »,
    la phrase d'information quand l'accès manuel posé n'en offre aucune, et pour Prolonger un
    Intégral acheté « Les N sessions EO temps réel de l'achat restent utilisables jusqu'au … ».
    `changes[]` ajoute « Intégral — sessions EO temps réel : 4 → 14 ».
  - `preview` (phrase serveur) : quand un GRANT posé par l'action laisse, à sa fin, un achat du
    même produit révoqué, la phrase se termine par « Attention : l'achat X révoqué ne sera pas
    rétabli. À partir du JJ/MM/AAAA, l'accès X sera de nouveau fermé. » (D-34).
  - 400 : motif hors 3–500 caractères, produit `NONE`/inconnu, fin manquante ou passée, fin <
    début, début passé, `fromProduct` manquant ou égal, sens de date incohérent
    (Prolonger vers plus tôt, Raccourcir vers plus tard), `expectedVersion` absent à l'écriture,
    `realtimeEoSessions` négatif, au-delà du plafond, ou > 0 hors des trois opérations qui créent
    un GRANT INTEGRAL.
  - 409 : état changé depuis la lecture (`expectedVersion` périmé), précondition
    (Prolonger/Raccourcir un accès non actif, Réactiver un accès non expiré/révoqué, Corriger un
    produit inactif, Terminer sans accès), « Terminer Civique » isolé sous un Intégral actif.
  - 401 / 403 / 404 conformes. Aucun achat, paiement, montant ni abonnement récurrent n'est touché.

### Admin — Campagnes de service (`incident`, `reprise`, 2026-09-28)

- `POST /api/admin/campaigns/{code}/send?mode=dry-run|test|send&batch=N&to=…` →
  `EmailCampaignRunResponse` (`status` ∈ `DRY_RUN` / `TEST_SENT` / `COMPLETED` /
  `NOTHING_TO_SEND` / `IN_PROGRESS` / `STOPPED_ON_ERROR`, `remaining` =
  `remainingNeverAttempted` + `remainingRetry`, `servedTotal`, `failedTotal`, compteurs de la
  vague dont `waveRejected` (adresses refusées, la vague a continué) et `waveFailed` (échec
  systémique, la vague s'est arrêtée), `error`, `sample` masqué, `waveSize`, `pauseSeconds`).
  `dry-run` n'écrit rien ; `test` exige `to` et n'envoie qu'à cette adresse ; `send` sert une
  vague (réglages : `email/campaigns-config-v2.json`). Une seule vague à la fois (sinon 409).
  Code ou mode inconnu ⇒ 400.

### Admin — Moteur de progression V4.2

Le **seul** endroit du produit où `masteryScore` et `confidence` sortent du moteur
(§25 bis.2). Un front candidat n'y a jamais accès : lui servir ces valeurs lui
permettrait de reconstituer un seuil, donc de reclasser un nombre en état
pédagogique. → `docs/regles/progression.md`

- `GET /api/admin/progression/shadow` → `ProgressionShadowReportDto`
  `{ mode, engineVersion, precisionSolid, predictionsAvecResultat,
  predictionsEnAttente, predictionsTotal, objectifPrecision, recommandation }`.
  **`precisionSolid` est `null`** tant qu'aucune prédiction n'a reçu de résultat —
  absence de mesure, jamais 0 %. La base est servie à côté du pourcentage : 100 %
  sur deux prédictions ne veut rien dire, et `recommandation` le dit en clair.
- `POST /api/admin/progression/shadow/rattacher` → `{ rattachees }`. Rattache
  chaque prédiction en attente au **premier** examen qualifiant du même `stateKey`
  survenu dans les 30 jours (§47.3). Idempotent, déclenché à la main : un job de
  plus est une chose de plus qui peut échouer en silence.
- `GET /api/admin/progression/utilisateurs/{userId}/etats` → les lignes brutes de
  `progression_state`, accumulateurs epoch compris.
- `GET /api/admin/progression/utilisateurs/{userId}/etats-servis?objectif=A2|B1|B2`
  → `ProgressionStateDto[]` — **la forme servable à un front** : état, libellé,
  ton, `visibleProgress` (nullable), prérequis. Aucun score interne : le DTO n'a
  pas de champ pour ça.
- `POST /api/admin/progression/utilisateurs/{userId}/replay` →
  `{ clesReconstruites }`. Rejoue tout l'historique sur la version courante
  (§29), en repartant d'une projection vide.

### Admin — Calibration du catalogue

L'outillage du tagging `difficulty_band` (§7). **Taguer précède mesurer, qui précède
basculer** : tant qu'aucune question n'a de bande, toutes les séries d'entraînement sont
`UNCALIBRATED`, aucun palier n'avance par l'entraînement, et les métriques shadow ne voient
que des examens blancs — échantillon minuscule et biaisé.

🛑 Aucun de ces endpoints ne pose une bande automatiquement. L'observé **propose**, un humain
tranche.

- `GET /api/admin/progression/catalogue/inventaire` → **l'indicateur d'avancement**. Par
  (domaine, palier) : `taguees`, `nonTaguees`, `easy/medium/hard`, `seriesConstructibles` et
  `bandeLimitante`. `seriesConstructibles` = `min(easy/6, medium/10, hard/4)` — un **minimum**,
  pas une moyenne : 200 MEDIUM ne valent rien avec 3 HARD.
- `GET /api/admin/progression/catalogue/export?section=CO|CE&level=A2|B1|B2` → CSV
  `questionId,domain,level,difficulty_band,enonce`. **Non taguées d'abord** : c'est le travail
  restant, et une liste qui commence par ce qui est fait se referme sans être lue.
- `POST /api/admin/progression/catalogue/bandes` — corps
  `{ affectations: [{ questionId, band }] }`. Chaque ligne est indépendante : un id inconnu est
  compté et ignoré, il n'annule pas le lot. `band: null` **dé-tague** (cas légitime : retirer
  un tag qu'on sait faux vaut mieux que le remplacer par un tag douteux). Réponse
  `{ posees, retirees, introuvables[] }`.
- `GET /api/admin/progression/catalogue/difficulte-observee?questionType=&difficulty=` → taux
  de réussite réel par item, avec `reponses` (la taille de l'échantillon, jamais masquée).
- `GET /api/admin/progression/catalogue/propositions?…` → les non taguées pour lesquelles les
  données suffisent. **Sous 30 réponses, rien n'est proposé** : un taux sur trois réponses est
  du bruit. Bornes : `EASY p > 0,75` · `MEDIUM 0,45 ≤ p ≤ 0,75` · `HARD p < 0,45`.
- `GET /api/admin/progression/catalogue/desaccords?…` → les questions dont la bande déclarée
  contredit l'observé (taguée HARD, réussie à 90 %). Une telle question fausse la
  comparabilité de **toutes** les séries qui la contiennent.

### Admin — Compétences TCF

Console de contenu du module Compétences (cf. la section utilisateur plus haut).

- `GET /api/admin/skills?section=&taskCode=&active=&q=&page=&size=` →
  `PageResponse<AdminSkillDto>` (l'enveloppe maison : `content`, `page`, `size`,
  `totalElements`, `totalPages`, `first`, `last` — pas un `Page` Spring brut). Tri imposé
  `taskCode` ASC puis `displayOrder` ASC ; `q` cherche sans casse dans `code`, `title` et
  `description` ; filtres dynamiques via `Specification` JPA.
- `GET /api/admin/skills/{id}` → `AdminSkillDetailDto {skill, prompts[]}`, les sujets portant
  leur `attemptCount` **et** leurs `references`.
- `POST /api/admin/skills` · `PATCH /api/admin/skills/{id}` → `AdminSkillDto`. `code`,
  `section` et `taskCode` sont **immuables** après création : les seeds générés s'appuient sur
  `code`.
- `DELETE /api/admin/skills/{id}` → **204**, ou **409** dès qu'un candidat a déjà produit sur
  un de ses sujets. On **désactive** (`active=false`), on ne détruit jamais d'historique
  candidat.
- `GET /api/admin/skills/stats?section=` → `AdminSkillStatsDto[]`. `validatedRate` est
  **null** quand `analysedCount == 0` — surtout pas `0.0`, qui se lirait comme « 0 % de
  réussite » au lieu de « aucune analyse ».
- `GET /api/admin/skill-prompts/{id}` → `AdminSkillPromptDto` complet, **références
  comprises** ; c'est cet appel que font les modals d'édition, pas le détail de compétence.
- `POST /api/admin/skill-prompts` → `section` n'est pas envoyée : le serveur la **déduit de la
  compétence parente** (colonne dénormalisée, verrouillée par une FK composite).
- `PATCH /api/admin/skill-prompts/{id}` → **sémantique de remplacement, pas de fusion** : un
  `null` sur une borne de longueur signifie « efface », pas « ne touche pas ». Sans ça une
  borne serait ineffaçable depuis l'admin, et un sujet EE pourrait garder une durée.
- `DELETE /api/admin/skill-prompts/{id}` → **204**, ou **409** si des tentatives existent
  (même règle que pour une compétence).
- `PUT /api/admin/skill-prompts/{id}/references` → remplace les **3** références d'un seul coup
  et de façon **atomique**. Corps `{references: [{level, text, pedagogicalNote} × 3]}` (un objet
  enveloppe, pas un tableau nu) ; les 3 niveaux sont exigés, sans doublon.

### Titres des sujets EE/EO (console de contenu)

- `GET /api/admin/production-tasks?epreuve=TCF_EE|TCF_EO[&tacheNumero=1|2|3]` →
  `AdminProductionTaskDto[]`, **sujets dépubliés compris** (la route candidat
  `/api/production-tasks` ne rend que les actifs) et dans l'ordre où le candidat les voit
  (tâche puis niveau), pour que le rang affiché en console corresponde au « Sujet N » du front.
- `PATCH /api/admin/production-tasks/{id}/titre` → `AdminProductionTaskDto`. Corps
  `{titre}`. **Sémantique de remplacement** : `null` ou blanc **efface** le titre — « pas de
  titre » se dit NULL en base (contrainte `chk_prod_task_titre`), jamais par une chaîne vide,
  et les fronts réaffichent alors « Sujet N ». C'est la seule surface d'écriture du catalogue
  de sujets : consigne, bornes, activation et fiche de scénario T2 restent pilotées par les
  migrations de contenu.

### Audio fixe du diagnostic

- `GET /api/admin/diagnostics/{code}/versions/{version}/instruction-audio` →
  `DiagnosticInstructionAudioDto`, avec la tâche EO, la clé R2 stable, l'URL,
  l'état de configuration Azure/R2 et le résultat d'un HEAD sur l'objet.
- `POST /api/admin/diagnostics/{code}/versions/{version}/instruction-audio` →
  vérifie d'abord la clé déterministe de l'UUID de tâche ; si l'objet existe,
  répare seulement son URL (même sans Azure), sinon génère explicitement la
  consigne avec Azure Speech, l'envoie dans R2 et persiste l'URL.
  `?force=true` **régénère** au lieu de réparer : c'est le seul moyen de refaire
  l'audio quand la consigne a été corrigée en base (sans lui, l'objet existant
  fait sortir la route avant toute synthèse, et la voix continue d'annoncer
  l'ancien texte). Opt-in délibéré — une synthèse est un appel payant, elle ne
  doit jamais partir parce qu'un client rejoue la route. L'écrasement se fait
  sous la **même** clé, donc l'URL déjà servie ne change pas, et `generatedNow`
  ne vaut `true` que si Azure a réellement été appelé.

Il n'existe volontairement aucun CRUD admin des sujets diagnostiques : contenu,
bornes, version, URL fixe et allowlists restent **seed-only**. La migration ne
fait aucun appel externe : V755 référence l'objet préalablement généré et vérifié.
L'audio n'est jamais généré au boot ou au démarrage candidat.

**Pagination** : `?size=` est plafonné à **100** sur toutes les listes paginées
(`spring.data.web.pageable.max-page-size`), défaut 20.

## Contrat d'erreur

Toute réponse d'erreur a la même forme :
`{timestamp, status, error, message, path[, fieldErrors]}`.

| Situation | Statut |
|---|---|
| Paramètre de requête au mauvais type (enum inconnu, UUID malformé) | **400**, message nommant le paramètre (+ valeurs acceptées pour un enum) |
| Paramètre de requête requis absent | **400**, message nommant le paramètre |
| Corps JSON absent / mal formé | **400**, message générique (aucun détail interne) |
| Validation de DTO (`@Valid`) | **400** + `fieldErrors` |
| Segment de chemin au mauvais type (`/api/attempts/mine`) | **404** |
| Chemin inexistant | **404** |
| Mauvaise méthode HTTP sur une route existante | **405** |
| Règle métier violée (`BusinessException`) | **422** |

Les 4xx sont loguées en `warn` sur une ligne, sans stack trace ; seules les 5xx
partent en `error` avec la stack.

## À implémenter

- `POST /api/billing/create-checkout-session` (Stripe)
