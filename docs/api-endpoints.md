# API backend — endpoints

Base : `http://localhost:8080`. CORS dev autorise `localhost:3000` (web Next.js) et
`localhost:5173` (admin Vite). Auth JWT Bearer (access ~60 min + refresh 30 j), **refresh
automatique** dans le client HTTP de chaque front.

## Auth

- `POST /api/auth/{login,register,refresh,forgot-password,reset-password}`
- `GET /api/auth/me`
- `POST /api/auth/google` (idToken)
- `POST /api/auth/apple` (identityToken + firstName/lastName facultatifs)
  → find-or-create user via JWKS Google/Apple. 503 tant que
  `sejourfr.oauth.{google|apple}.audiences` est vide. Cf. `auth-social.md`.

## Thèmes & lots

- `GET /api/themes?module=CIVIQUE|TCF`
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

Cf. `exams-tcf.md`.

## Me / utilisateur

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
- `GET /api/me/questions/wrong?module=...[&questionType=CO|CE][&themeId=<uuid>]`
  → **tous les filtres sont appliqués en base, avant le plafond de 30 erreurs** :
  ce sont les 30 erreurs les plus récentes *correspondant à la demande*. Un
  filtre `CO` inclut `CO_IMAGE` (règle transverse du projet).
- `GET /api/me/stats?module=...` — toute la réponse est scopée au module,
  `attemptsTotal` compris. Les deux attempts techniques du diagnostic initial
  sont exclus de ce compteur et de l'historique `/api/me/attempts`.
- `GET /api/me/plan` → `LearningPlanDto`. `state` vaut `NEEDS_DIAGNOSTIC`,
  `DIAGNOSTIC_IN_PROGRESS` ou `ACTIVE`; une fois actif, le serveur fournit
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
  entrées synthétiques `TCF_EE`/`TCF_EO` depuis les évals IA).
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
  paginer 1 016 questions ne doit jamais en faire revoir ni en sauter une.
- `PUT /api/admin/civic-notions/questions/{id}` `{notionCode}` (**L8**, ADMIN).
  Pose le tag **validé par un humain**. `notionCode: null` efface — se tromper
  doit rester rattrapable. Une notion **fusionnée** est refusée : la poser
  recréerait du travail à défaire.
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

## Expression orale en temps réel (examinateur vocal, EO T1/T2)

Schéma de connexion **(A)** : le backend émet un **token éphémère** dont le setup
(modèle, persona, transcription, VAD, reprise) est **verrouillé côté serveur** ;
le client ouvre lui-même le WebSocket du fournisseur sur l'endpoint **contraint**
— il ne peut donc poser **aucun** champ de setup. Tous ces endpoints sont
**authentifiés**.

- `GET /api/realtime/eo/quota` → `{remaining, cap}`.
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
- `GET /api/skills/{skillId}` → `SkillDetailDto` : la compétence + ses 5 sujets avec leur
  statut (`TODO` / `TREATED` / `VALIDATED` / `TO_REINFORCE`), **dérivé serveur** — aucun
  front ne le recalcule.
- `GET /api/skills/analysis-quota` → `SkillAnalysisQuotaDto
  {premium, unlimited, freeAnalysesTotal, freeAnalysesUsed, remaining}`. `remaining = -1`
  signifie **illimité** : les fronts doivent le traiter comme tel et ne jamais l'afficher brut.
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
- **L'analyse IA reste un verrou distinct et cumulé** : **3 analyses offertes à vie**,
  consommées **à l'acceptation** (au moment où `analysis_requested` est persisté) et non au
  succès. Inchangé.
- La garde des **références** (« au moins une tentative sur ce sujet ») est **inchangée** et
  indépendante de `locked`.

**Oral** : l'enregistrement **n'est pas conservé** — il sert à produire la transcription
pendant la requête de soumission, puis il disparaît. La transcription est donc
**systématique**, analyse demandée ou non, et le DTO ne porte **aucune URL audio**. Un échec
de transcription rend **503** et rien n'est enregistré : le candidat renvoie. Cf.
`notation-ia-eo-ee.md` §11 bis.

## Audience des landings

- `POST /api/public/page-views` — public, sans authentification. Corps
  `{path, source, event}`. Répond **204** (émis en `sendBeacon`, la réponse
  n'est jamais lue). Le backend vérifie la paire dans
  `PageViewService.EVENTS_BY_PATH` et normalise `source`
  (`tiktok|instagram|whatsapp|facebook|youtube|direct`, tout le reste →
  `autre`) : c'est ce qui borne la table face à un endpoint ouvert.
- Chemins/événements : `/reussir` accepte `VIEW`, `CTA` et
  `SOCIAL_LANDING_DIAGNOSTIC_CLICKED`; `/diagnostic` accepte les six étapes
  `DIAGNOSTIC_*` du parcours, `DIAGNOSTIC_ACCOUNT_REQUIRED` (le visiteur a
  produit ses deux réponses sans compte et atteint l'écran qui en demande un —
  la mesure de conversion du parcours invité) et
  `DIAGNOSTIC_TO_PREMIUM_CLICKED`; `/plan`
  accepte `PLAN_OPENED`, `PLAN_RECOMMENDED_EXERCISE_STARTED` et le clic Premium.
- `GET /api/admin/page-views?path=/reussir&days=30` — agrégat par source, par
  jour et compte brut par événement (`PageViewStatsResponse.events`).
- `GET /api/admin/page-views/paths` — pages mesurées, pour le sélecteur admin.

**Aucune donnée personnelle** : ni IP, ni user-agent, ni identifiant de
visiteur, et rien n'est écrit dans le navigateur. Compte des **vues**, pas des
visiteurs uniques. Cf. migration V020.

## Admin

- `/api/admin/{dashboard,questions,themes,conversations,media,passages,audio-questions,calibration/{submissions,stats},page-views,diagnostics}`
- `GET /api/admin/questions?module=&themeId=&difficulty=&type=&active=&media=&search=&page=&size=`
  — `media` vaut `AUDIO | IMAGE | VIDEO | NONE` (`NONE` = questions sans média
  principal ; le filtre porte sur `question.media`, pas sur l'audio secondaire
  d'une `CO_IMAGE`). **Filtre serveur** : la console ne doit plus filtrer la
  page affichée dans le navigateur.
- `GET /api/admin/calibration/submissions?status=evaluated&hasHumanNote=&limit=`
  — renvoie des `CalibrationSubmissionDto`
  `{ submission, rubricsVersion, promptVersion }` : la soumission au format
  partagé, plus les versions de la dernière évaluation IA. `rubricsVersion` est
  `null` pour une évaluation antérieure à la colonne
  `ai_evaluations.rubrics_version` (V022). DTO propre à l'admin — ces versions
  ne sont PAS ajoutées à `ProductionSubmissionDto` / `EvaluationResultDto`, que
  le web et le mobile consomment aussi.

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
