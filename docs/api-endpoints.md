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

- `GET /api/production-tasks?epreuve=TCF_EO&niveau=B1[&tacheNumero=1|2|3]`
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
