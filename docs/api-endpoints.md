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

- `GET /api/me/questions/favorites?module=...`
- `GET /api/me/questions/wrong?module=...[&questionType=CO|CE][&themeId=<uuid>]`
  → **tous les filtres sont appliqués en base, avant le plafond de 30 erreurs** :
  ce sont les 30 erreurs les plus récentes *correspondant à la demande*. Un
  filtre `CO` inclut `CO_IMAGE` (règle transverse du projet).
- `GET /api/me/stats?module=...` — toute la réponse est scopée au module,
  `attemptsTotal` compris.
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

## Compétences TCF (micro-entraînement EE/EO)

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

**Freemium** : produire, s'auto-évaluer et lire les 3 références est **gratuit et illimité**
pour tout compte inscrit — **aucun sujet n'est verrouillé**. Seule l'**analyse IA** est premium
(module TCF, `hasTcf`), avec **3 analyses offertes à vie**, consommées **à l'acceptation** (au
moment où `analysis_requested` est persisté) et non au succès.

**Oral** : l'audio est conservé dans tous les cas ; la transcription Whisper n'est déclenchée
**que si une analyse est demandée**. Cf. `notation-ia-eo-ee.md` §11 bis.

## Audience des landings

- `POST /api/public/page-views` — public, sans authentification. Corps
  `{path, source, event}` avec `event = VIEW | CTA`. Répond **204** (émis en
  `sendBeacon`, la réponse n'est jamais lue). Le backend n'accepte qu'un `path`
  de la liste blanche `PageViewService.TRACKED_PATHS` et normalise `source`
  (`tiktok|instagram|whatsapp|facebook|youtube|direct`, tout le reste →
  `autre`) : c'est ce qui borne la table face à un endpoint ouvert.
- `GET /api/admin/page-views?path=/reussir&days=30` — agrégat par source et par
  jour (`PageViewStatsResponse`).
- `GET /api/admin/page-views/paths` — pages mesurées, pour le sélecteur admin.

**Aucune donnée personnelle** : ni IP, ni user-agent, ni identifiant de
visiteur, et rien n'est écrit dans le navigateur. Compte des **vues**, pas des
visiteurs uniques. Cf. migration V020.

## Admin

- `/api/admin/{dashboard,questions,themes,conversations,media,passages,audio-questions,calibration/{submissions,stats},page-views}`
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
