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
- `GET /api/full-tcf-exams/{id}`
- `POST /api/full-tcf-exams/{id}/finish`
- `GET /api/me/full-tcf-exams?limit=N`

Cf. `exams-tcf.md`.

## Me / utilisateur

- `GET /api/me/questions/favorites?module=...`
- `GET /api/me/questions/wrong?module=...[&questionType=CO|CE]`
- `GET /api/me/stats?module=...`
- `GET /api/me/dashboard` — agrégat unique du tableau de bord web : streak de
  jours d'activité (courant + record, fuseau Europe/Paris), nb d'examens
  blancs finis, taux de réussite global, niveau TCF estimé (dernier examen
  TCF porteur d'un niveau CECRL), stats par catégorie pour les deux modules
  (tous les thèmes + entrées synthétiques `TCF_EE`/`TCF_EO` depuis les évals
  IA). Cf. `UserDashboardService`.
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

Cf. `pipeline-evaluation-eo-ee.md`.

## Admin

- `/api/admin/{dashboard,questions,themes,conversations,media,passages,audio-questions,calibration/{submissions,stats}}`

## À implémenter

- `POST /api/billing/create-checkout-session` (Stripe)
