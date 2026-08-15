# CLAUDE.md — SejourFR Web (Next.js)

Frontend web de SejourFR, plateforme d'entraînement aux examens **civique** (CSP, CR, naturalisation) et **TCF
IRN** (A2/B1/B2), obligatoires depuis le 1er janvier 2026.

## Stack

- **Next.js 16.2.6** (App Router)
- **React 19.2.4**
- **TypeScript 5**
- **Tailwind v4** (config CSS-first via `@theme` dans `globals.css`, plugin `@tailwindcss/postcss`)
- Fonts via `next/font/google` : Plus Jakarta Sans (UI), Fraunces (display éditorial), JetBrains Mono (labels
  techniques)

Pas de librairie UI externe. CSS écrit en `<style>` scoped dans les composants ou dans `globals.css` (les
utilities Tailwind ne sont pas utilisées pour le design — Tailwind est présent uniquement pour les design
tokens via `@theme`).

## Backend cible

Backend Spring Boot Java 21 séparé, qui tourne sur `http://localhost:8080`.

- URL configurable via `NEXT_PUBLIC_API_BASE_URL` (cf. `.env.local.example`)
- CORS allowed-origins inclut `http://localhost:3000` côté backend
- Auth JWT : tokens stockés dans `localStorage` (clés `sejourfr.accessToken`, `sejourfr.refreshToken`) +
  cookie `sejourfr.accessToken` pour le SSR

### Endpoints utilisés

| Méthode | URL                                    | Usage                                           | Auth |
|---------|----------------------------------------|-------------------------------------------------|------|
| POST    | `/api/auth/register`                   | inscription                                     | non  |
| POST    | `/api/auth/login`                      | connexion                                       | non  |
| POST    | `/api/auth/google`                     | sign-in Google (cree compte si besoin)          | non  |
| GET     | `/api/auth/me`                         | user courant                                    | oui  |
| GET     | `/api/themes?module=CIVIQUE\|TCF`      | liste des thèmes                                | oui  |
| POST    | `/api/attempts`                        | démarrer une tentative                          | oui  |
| GET     | `/api/attempts/{id}`                   | reprendre                                       | oui  |
| POST    | `/api/attempts/{id}/answers`           | soumettre une réponse                           | oui  |
| POST    | `/api/attempts/{id}/finish`            | finaliser                                       | oui  |
| GET     | `/api/me/dashboard`                    | agrégat dashboard (streak, stats, catégories)   | oui  |
| GET     | `/api/public/diagnostics/current`      | sujets EE/EO du diagnostic pour un visiteur     | non  |
| GET     | `/api/diagnostics/current`             | état/reprise du diagnostic TCF initial          | oui  |
| POST    | `/api/diagnostics`                     | démarrer ou reprendre (idempotent)               | oui  |
| GET     | `/api/diagnostics/{sessionId}`         | polling et résultat d'un diagnostic              | oui  |
| POST    | `/api/diagnostics/{id}/retry-analysis` | relancer une analyse échouée sans ressaisie      | oui  |
| GET     | `/api/me/plan`                         | priorité courante et Plan personnalisé           | oui  |
| GET     | `/api/billing/plans`                   | liste plans actifs (publique, ISR 30min)        | non  |
| GET     | `/api/billing/payment-link?planCode=…` | Checkout Session Stripe (mode subscription)     | oui  |
| GET     | `/api/billing/subscription-status`     | statut Premium agrégé (Stripe + Apple + Google) | oui  |
| POST    | `/api/billing/cancel`                  | résiliation de l'abonnement courant             | oui  |
| DELETE  | `/api/account`                         | suppression de compte (anonymisation)           | oui  |

### Enums Spring miroirs côté TS (dans `lib/types.ts`)

- `Module` = `"CIVIQUE" \| "TCF"`
- `TargetProcedure` = `"CSP" \| "CR" \| "NAT"`
- `TargetLevel` = `"A2" \| "B1" \| "B2"`
- `Difficulty` = `"EASY" \| "MEDIUM" \| "HARD"`
- `QuestionType` = `"KNOWLEDGE" \| "SITUATION"`
- `AttemptType` = `"TRAINING" \| "MOCK_EXAM" \| "REVIEW"`
- `MediaType` = `"AUDIO" \| "IMAGE" \| "VIDEO"`
- `Role` = `"USER" \| "ADMIN"`
- `AudioMode` = `"WRITTEN_QUESTION" \| "FULL_AUDIO"` (sur `Question`, nullable ; en mode `FULL_AUDIO` les labels sont
  `"Réponse A/B/C/D"` et le contenu réel est lu dans l'audio — cf CLAUDE.md racine)

## Structure

```
app/
├── layout.tsx                    # injection fonts via next/font, variables CSS
├── globals.css                   # @import "tailwindcss" + @theme (tokens design)
├── page.tsx                      # landing one-pager (compose les sous-sections)
├── _components/                  # composants partagés (PascalCase.tsx, "use client")
│   ├── Brand.tsx, TopNav.tsx, SiteHeader.tsx, Footer.tsx,
│   ├── AppSidebar.tsx            # nav latérale des routes (app)
│   ├── HeroSection.tsx, LandingSections.tsx, MobileAppPromo.tsx
│   ├── MediaView.tsx             # rend MediaResponse (audio/image/vidéo/SVG inline)
│   ├── QuestionRunner.tsx        # ★ runner réutilisable training/exam (favoris, prev/next,
│   │                              #   training infini avec extension auto, raccourcis 1-4/Enter/B/←/→)
│   ├── ModuleSwitch.tsx          # segmented Civique/TCF avec icônes
│   ├── ThemeCard.tsx             # tile d'un thème en radio + état lock
│   ├── TargetPathBanner.tsx      # bandeau parcours visé (CSP/CR/NAT ou A2/B1/B2)
│   ├── TcfPaywallCard.tsx        # carte legacy si user.hasTcf === false — non utilisée
│   │                              #   depuis hotfix démo TCF, conservée pour future cas d'usage
│   ├── PaywallSheet.tsx          # modal paywall (bottom sheet mobile, dialog desktop)
│   ├── TrainingResultCard.tsx    # carte de résultat fin de session training (à chaud)
│   └── TcfScoreCard.tsx          # carte compacte points + niveau CECRL (détail TCF)
│
├── (app)/                        # route group : connecté, layout sidebar+main
│   ├── layout.tsx                # grid 248px / 1fr, passe en drawer sous 900px
│   ├── dashboard/page.tsx        # ★ tableau de bord (refonte web_refonte) : un seul fetch
│   │                              #   GET /api/me/dashboard → 4 stat cards (maîtrise globale,
│   │                              #   examens blancs, streak, niveau TCF estimé), 2 cards
│   │                              #   catégories TCF/Civique, "À renforcer en priorité" (top 3),
│   │                              #   bandeaux reprendre/onboarding
│   ├── plan/page.tsx             # ★ action prioritaire, suivantes, compétences observées,
│   │                              #   accès secondaire à l'ancienne Progression
│   ├── recommandations/page.tsx  # ★ liste complète des catégories triées faibles d'abord
│   │                              #   (tag module, CTA Réviser) + raccourcis erreurs/favoris
│   │                              #   vers /revision (qui n'a plus d'entrée sidebar)
│   ├── statistiques/page.tsx     # ★ progression par thème (tri faibles d'abord), couleurs
│   │                              #   vert/ambre/rouge, clic sur thème → start training ciblé
│   ├── revision/page.tsx         # ★ tabs erreurs/favoris avec compteurs, modal détail
│   │                              #   (statement, choix résolus, explanation, toggle favori)
│   ├── historique/page.tsx       # ★ liste examens MOCK_EXAM passés, header résumé (taux moyen),
│   │                              #   graphique custom SVG (barres + ligne seuil), clic → /sessions/<id>
│   ├── profil/page.tsx           # ★ profil (parité onglet Profil mobile, design web) : hero
│   │                              #   éditorial + identité, 3 stat cards (maîtrise/série/niveau via
│   │                              #   /api/me/dashboard), « Mon pass » (subscription-status →
│   │                              #   /profil/abonnement|/paiement), « Mon objectif » → /parcours,
│   │                              #   « Mes informations » = modale d'édition (identité PATCH + email
│   │                              #   change-request + mot de passe change), suppr compte, logout.
│   │                              #   Sans date d'examen / plan de révision / centre d'aide / reset
│   ├── parcours/page.tsx         # ★ édition target path (CSP/CR/NAT) avec cards radio + niveau TCF
│   │                              #   dérivé. Sert d'onboarding si user.targetProcedure manquant.
│   │                              #   Support ?from=<route> pour retour.
│   ├── entrainement/page.tsx     # ★ setup : module/thème/taille/gating démo par module,
│   │                              #   redirige vers /sessions/<attemptId> après attemptApi.start
│   ├── examens-blancs/page.tsx   # ★ liste des templates (free/premium, gating par module)
│   ├── examens-blancs/[slug]/page.tsx  # ★ briefing + start, redirige vers /sessions/<id>
│   ├── sessions/[attemptId]/page.tsx   # ★ runner générique : training OU exam selon attempt.type
│   │                              #   (charge l'attempt + favoris, gère running/result/error,
│   │                              #   timer si MOCK_EXAM via QuestionRunner)
│   ├── paiement/page.tsx, succes/page.tsx        # Stripe Payment Link
│
├── diagnostic/page.tsx           # ★ route DUALE (guest + connecté) : présentation → EE → EO
│                                 #   enregistré → (invité : écran de compte) → analyse
│                                 #   asynchrone → résultat. Cf. section dédiée.
├── inscription/, connexion/, mot-de-passe-oublie/, reinitialiser-mot-de-passe/
├── a-propos/page.tsx             # disclaimer non-affiliation + sources officielles (conformité
│                                 #   stores ; LegalPageLayout, miroir de l'écran /about mobile ;
│                                 #   aussi lié depuis le footer : ligne disclaimer + colonne Légal)
├── reussir/page.tsx             # ★ landing de bio réseaux (autoportante, cf. section dédiée)
└── examen-blanc/page.tsx         # ancienne route publique (à dépublier en V2)

lib/
├── api.ts                        # authApi, themeApi, attemptApi, examApi, billingApi,
│                                 #   userContentApi (favoris/wrong/reviewQuestion/targetPath),
│                                 #   statsApi, dashboardApi, diagnosticApi, learningPlanApi,
│                                 #   caches/invalidation, tokenStorage, ApiException
├── diagnostic.ts                 # helpers purs : état dashboard, adaptation exercice,
│                                 #   route exacte du micro-exercice recommandé
├── audience-events.ts            # allowlist fermée path × événement, miroir backend
├── chrome-routes.ts              # APP_GROUP_PREFIXES + DUAL_CHROME_PREFIXES +
│                                 #   shouldHideGlobalChrome (connecté sur route app → pas de
│                                 #   header/footer/bandeau marketing, la sidebar porte tout)
├── dashboard.ts                  # helpers catégories dashboard : categoryHref (CTA Réviser),
│                                 #   barTone (vert ≥80 / ambre <60 / bleu), moduleAverage
├── start-failure.ts              # classifyStartFailure / handleStartFailure : un 403 au
│                                 #   démarrage d'un attempt = paywall, pas erreur technique
└── types.ts                      # DTOs miroirs Java + helper canAccessModule()
```

**Le QuestionRunner est la pièce centrale** : c'est lui qui matérialise la session
de QCM (training avec correction immédiate, ou exam avec submission silencieuse).
Le state est interne (questions cumulées, currentIndex, answersByQuestion,
attemptIdByQuestionId, lastResult, favoriteIds). En mode `infinite=true` (training
premium), il étend automatiquement la session avec un nouveau batch quand on
arrive sur la dernière question — un prefetch est déclenché dès que la correction
de l'avant-dernière s'affiche, pour rendre le passage instantané.

**Examens sectionnés** : les examens TCF mixtes (templates `tcf-diagnostic` /
`tcf-mix-*`) font **50 Q / 55 min** (migration V111) et sont composés par le
backend comme le vrai TCF — compréhension orale (25 Q · 20 min) puis écrite
(25 Q · 35 min), chacune stratifiée 8 A2 + 9 B1 + 8 B2, pas de STRUCTURE ni
EE/EO (`AttemptService.pickQuestionsForTemplate` → `drawTcfEpreuveStrata`). La page
session dérive des `RunnerSection[]` (`tcfExamSections`) passées au runner via
la prop `sections` : bandeau « Partie x/y · i/n » au-dessus des tags + écran
d'intro à chaque changement de partie (le chrono global continue) + bouton
« Partie suivante » en fin de partie. `tcfExamSections` n'émet des sections
que pour les examens **multi-épreuves** (diagnostic CO+CE) ; les examens TCF
mono-épreuve (CO/CE/STRUCTURE) ne passent plus de section → pas d'écran d'intro
runner, leur présentation (déroulé + seuil) vit dans `ExamIntroSheet` côté page
examens. Undefined aussi sur les attempts d'avant le tri (groupes > 3). **Notation TCF calibrée** : tous les examens TCF
stratifiés (module CO/CE/STRUCTURE + templates diagnostic) portent
`calibratedScore` 100-499 + `cecrlLevel`, calculés UNIQUEMENT backend
(`TcfLevelEstimatorService` — score corrigé du hasard 25 %, niveau = bande du
score ; V112 a invalidé les niveaux de l'ancienne règle « palier ») — le hero
`ExamReport`, `/historique` et les stats « meilleur score » affichent `x/499`
quand présent, le score brut sinon. **Examens multi-épreuves** : le backend
expose `AttemptResponse.epreuveResults` (score + niveau par épreuve, CO_IMAGE
sous CO) et le `cecrlLevel` global est le PLANCHER des épreuves (règle TCF
IRN : il faut le niveau partout) ; `ExamReport` rend la card « Votre niveau
par épreuve » + note expliquant le min. **Aucun niveau ne se colore en rouge** :
le badge prend la teinte de son PALIER (`epreuveLevelTone`, `lib/exam-levels.ts`,
qui dérive de l'unique table `tcfNiveauTone`) et l'épreuve plancher est signalée
**par le texte** (« · niveau retenu »), seulement quand elle se distingue des
autres (`floorMarks`) — un candidat B2 partout n'a pas de point faible.
Miroirs `AttemptEpreuveResult` dans lib/types.ts et attempt_models.dart. **CO en examen = conditions réelles** : audio
autoplay à écoute unique sans contrôles (`MediaView` prop `examAudio`,
fallback bouton one-shot si l'autoplay est bloqué). **Retour arrière interdit
sur tout examen** (`mode === "exam"` → `canGoPrevious = false`, toutes épreuves
confondues civique/CO/CE/STRUCTURE : une réponse validée est définitive,
conditions réelles — parité mobile `runner_screen.dart`). En TRAINING (séries),
le lecteur natif et la navigation restent libres.

## Blog (`/blog`) — contenu SEO

Blog éditorial statique (SSG), sans backend : les articles sont des fichiers **MDX** dans
`content/articles/*.mdx`, lus par `lib/blog/articles.ts` (gray-matter + reading-time,
mémoïsé au build). Le `slug` du frontmatter doit **matcher le nom du fichier**.

- **Catégories** : `content/categories.json` + union `ArticleCategorySlug` dans
  `lib/blog/types.ts` + tonalité couleur dans `categoryTone()` (`lib/blog/categories.ts`).
  Cinq catégories : `titre-de-sejour` (bleu), `naturalisation` (rouge), **`tcf` (vert)**,
  `actualite` (ambre), `conseils` (indigo). Ajouter une catégorie = toucher ces 3 fichiers.
- **Pagination (9 articles/page, multiple de 3 pour remplir les lignes desktop)** :
  helpers `getBlogPage` / `getCategoryPage` / `blogPageCount` / `categoryPageCount` +
  constante `ARTICLES_PER_PAGE` dans `lib/blog/articles.ts`. L'article **à la une n'existe
  qu'en page 1**. Routes : `/blog` (page 1) + `/blog/page/[page]` (2..N, `generateStaticParams`,
  404 hors bornes), idem `/blog/category/[slug]` + `/blog/category/[slug]/page/[page]`.
  Les corps de page vivent dans `components/blog/BlogIndexView.tsx` et
  `CategoryListView.tsx` (partagés page 1 / pages suivantes) ; `components/blog/Pagination.tsx`
  rend la nav (fenêtre de numéros + ellipses, libellés Précédent/Suivant masqués < 640 px).
- **Rédaction** : conventions dans `content/articles/BLOG_STYLE_GUIDE.md` (frontmatter, ton,
  composants MDX, longueur, maillage interne).
- **`content/articles/ARTICLES_INDEX.md`** : index des sujets déjà traités + pistes libres.
  **À lire avant d'écrire un article** (anti-doublon SEO) et **à compléter dans la même passe**
  quand on en ajoute un.

## Identité visuelle (à ne pas dévier)

### Couleurs (variables CSS définies dans `@theme`)

- Bleu France `--color-blue: #1E3A8C` (dark `#15296B`, light `#E8ECF8`, soft `#F4F6FC`)
- Rouge France `--color-red: #E1372F` (dark `#B5251E`, light `#FDECEB`)
- Encre `--color-ink: #0F1839` (variante `--color-ink-2: #1F2950`)
- Texte secondaire `--color-muted: #6B7299` / `--color-muted-2: #9CA2BD`
- Lignes `--color-line: #E4E7F2` / `--color-line-2: #EEF0F8`
- Fond papier `--color-paper: #FAFAF7` / `--color-paper-2: #F2F1EC`
- Succès `--color-green: #168F5B`
- Ambre `--color-amber: #E8A317`

**Règle d'usage du rouge** : réservé aux CTAs critiques (démarrer un examen blanc, payer, créer un compte
depuis le CTA final) et aux signaux d'urgence (timer en cours, badges de validation). Le bleu domine partout
ailleurs.

### Typographie

- `--font-sans` (Plus Jakarta Sans) : UI, boutons, paragraphes
- `--font-display` (Fraunces) : titres H1/H2 éditoriaux, scores, prix. Les italiques `<em>` à l'intérieur des
  titres sont **toujours rouges** (`color: var(--color-red)`).
- `--font-mono` (JetBrains Mono) : eyebrows, labels de formulaire (uppercase + tracking), valeurs numériques
  tabulaires, étiquettes techniques

### Cocarde

Logo en pur CSS via `.cocarde` (3 cercles concentriques : bleu extérieur, blanc, rouge centre). Taille
standard 36px, variante `.cocarde.lg` à 56px.

### Wordmark

`Sejour` en bleu, `FR` en rouge. Classe `.wordmark` avec span enfant `.fr`.

## Conventions de code

- 🛑 **Tests : on n'en écrit PLUS sur ce sous-projet** (règle posée le 2026-08-09, cf. § Tests du
  `CLAUDE.md` racine). Aucun nouveau `*.test.ts` — ni test de helper, ni gel de libellé, ni test de
  composant. La vérification d'un changement web, c'est `npx tsc --noEmit` + `npm run build`, et le
  propriétaire teste lui-même à l'écran. Les tests déjà présents (`npm test`, runner natif de Node)
  restent en place et doivent rester verts : un test qui devient rouge à cause d'un changement voulu
  se **met à jour ou se supprime**, il ne bloque jamais le changement. Toute la couverture de règles
  métier vit côté backend, d'où elle protège les trois fronts d'un seul endroit.
- **🏆 RÈGLE D'OR — TOUT est responsive.** Chaque page et chaque composant doit fonctionner
  parfaitement du **mobile (~360 px)** au **desktop (1280+)**. Aucune page n'est « finie » tant
  qu'elle n'a pas été pensée mobile-first et vérifiée mentalement à **360 / 768 / 1280**. Concrètement :
  pas de largeur fixe en px sans `max-width: 100%` ; `min-width: 0` sur les enfants de grille/flex pour
  éviter le *blowout* (scroll horizontal) ; grilles multi-colonnes qui retombent en 1 colonne sous les
  breakpoints ; **inputs en `font-size: 16px` minimum** (sinon iOS zoome au focus → scroll horizontal) ;
  pas de tableau sans alternative carte sur petit écran. Le mobile est le cas d'usage principal — il prime.
- **Pas de Tailwind utility-first dans le markup.** Les utilities ne sont pas générées au-delà des design
  tokens. Pour styler, soit `globals.css`, soit `<style>` JSX scoped en fin de composant.
- **Classes globales réutilisables** définies dans `globals.css` : `.btn`, `.btn-lg`, `.btn-red`,
  `.btn-ghost`, `.btn-link-soft`, `.field`, `.field-label`, `.field-input`, `.container-x`, `.eyebrow`,
  `.editorial`, `.cocarde`, `.wordmark`, `.form-error`, `.pill-success`.
- **Pages avec formulaires** = `"use client"` obligatoire (état local + handlers).
- **`useSearchParams()`** doit être dans un composant enfant enveloppé par `<Suspense>` (cf.
  `paiement/page.tsx`).
- **CSS Modules** adoptés lors de la refonte pour les nouveaux composants lourds (ex.
  `app/_components/landing/landing.module.css`, `app/_components/auth/auth.module.css`) : un `.module.css`
  co-localisé qui consomme les tokens `@theme` (`var(--color-*)`). Les `<style>` JSX scoped restent OK pour
  les composants plus simples / hérités. Pas d'utility-first dans les deux cas.

**Hygiène (rappel transverse, cf. CLAUDE.md racine)**

- **Parité web ⇄ mobile (impératif)** : le web et le mobile partagent le même backend et doivent offrir
  **le même fonctionnement et le même rôle**. Tout **bug corrigé**, **changement** ou **ajout de
  fonctionnalité** sur une surface partagée (freemium, paywall, runner, examens, productions EE/EO, EO
  temps réel, chrono…) doit être **répercuté et vérifié sur l'autre front DANS LA MÊME PASSE** : aucune
  **régression** de l'autre côté, et les deux fronts restent **synchronisés au maximum**. Avant de fermer
  une tâche, se poser explicitement la question : « web et mobile font-ils exactement pareil, sans
  régression ? ». Détail complet : `CLAUDE.md` racine (Hygiène d'architecture).
- Toute nouvelle page App Router prend sa place dans `app/<segment>/`. Les composants partagés à 2+ pages
  remontent dans `app/_components/`. Si un helper apparaît dans 2 pages, le mettre dans `lib/`. À la 2ᵉ
  duplication, pas plus tard.
- Quand un parcours est remplacé : supprimer dans la foulée la route (`page.tsx`), ses sous-composants
  morts, les `Link href=` et `router.push(...)` qui le ciblaient, et les types/fetchers devenus
  inutilisés. `grep` sur le path avant de fermer le lot.
- Classes globales `.btn`, `.field`, etc. : ne pas en redéfinir une variante locale juste pour gagner du
  temps — si une nouvelle variante est utile, l'ajouter proprement dans `globals.css` avec un nom cohérent.
- Le miroir des DTOs backend vit dans `lib/types.ts` : quand un DTO Java change, mettre à jour ce fichier
  en même temps que la page qui le consomme. Pas de duplication ad-hoc d'un type côté page.
- Mettre à jour ce CLAUDE.md à chaque modif structurante (nouvelle vague de parité mobile, nouvelle
  route, nouvelle convention). Pas de PR qui change l'archi sans synchroniser la doc.

## Gestion des erreurs API

Le client `apiFetch` lève une `ApiException` avec `{ status, message, payload }`. Le `payload` peut contenir
`fieldErrors: Record<string, string>` que les pages d'auth concatènent pour affichage. Les pages traitent
spécifiquement le 401 (mauvais credentials sur connexion, "créez un compte" sur examen blanc).

**Échec de démarrage d'un attempt** (série, examen blanc QCM, session EE/EO, « Refaire ») : passer par
`lib/start-failure.ts` — `handleStartFailure(e, {onPaywall, onMessage, fallbackMessage})` ouvre l'offre sur
un **403** et affiche le message backend sinon. Le paywall des examens blancs est appliqué **par le
backend** (`AttemptService.enforceMockExamSlotAccess`, slot 1 offert / 2+ abonnés) : un écran dont le statut
premium en cache est périmé reçoit un 403 là où son UI croyait le slot ouvert — c'est un refus attendu, pas
une panne, il ne doit jamais s'afficher en erreur technique. **Ne pas réécrire ce `if (status === 403)` dans
une page** : la règle vit à un seul endroit (miroir de `core/utils/start_failure.dart` côté mobile). Les
écrans duals guest/connecté routent le 403 vers `GuestGateSheet` en guest, `PaywallSheet` sinon.

## Examen blanc — flux

La page `examen-blanc/page.tsx` est la plus complexe. Quatre stages dans la même page sans routing :

1. **`choice`** — sélection du module (CIVIQUE ou TCF)
2. **`briefing`** — règles de l'examen + bouton "Démarrer" qui déclenche
   `attemptApi.start({ type: "MOCK_EXAM", module })`
3. **`running`** — runner : timer décompté via `setTimeout` sur `secondsLeft`, navigation question par
   question, `attemptApi.submitAnswer()` à chaque "Suivant". Quand le timer atteint 0 ou que la dernière
   question est validée, on appelle `attemptApi.finish()`.
4. **`result`** — score, seuil de réussite (32/40 par défaut), CTA "créer un compte pour sauvegarder"

**Mode mono-sélection** par défaut (un seul `choiceId` par question). Si le backend renvoie des questions
multi-réponses, adapter `toggleChoice` pour additionner au lieu de remplacer.

**Sans compte** : `POST /api/attempts` renverra 401. Le front affiche un message d'incitation à l'inscription.
Pour autoriser vraiment une démo publique, il faudra exposer côté Spring un endpoint `POST /api/attempts/demo`
qui ne demande pas de Bearer et limite à 1 tentative/mois par IP.

## Temps des examens blancs TCF — un chrono PAR ÉPREUVE (2026-08-15)

🛑 **Le chrono global de 90 min n'existe plus**, et `FULL_TCF_EXAM_DURATION_SEC` a été
supprimée : le temps d'une épreuve ne se transfère jamais à la suivante, et la reprise
**entre** épreuves est officiellement supportée (cf. § *Suspendre un examen complet* :
on reprend aux épreuves **jamais commencées**, jamais celle qui est en cours). Ne pas la
réintroduire.

- **Une seule source de vérité : le serveur.** `FullTcfExamSubAttempt` porte
  `timeLimitSeconds` (1200 CO · 2100 CE · 1800 EE · **null en EO**), `timerStartedAt` et
  `deadlineAt`. **`deadlineAt` est L'UNIQUE base du compte à rebours**, y compris au retour
  dans l'app — quitter ne suspend rien, le temps a couru pendant l'absence. **Ne jamais
  recalculer une échéance côté client.**
- **`POST /api/full-tcf-exams/{id}/begin?epreuve=…` est appelé sur les 4 épreuves** au
  lancement (obligatoire pour l'EE) : sans lui l'épreuve n'a **aucune** échéance.
  Idempotent — une reprise rend le temps réellement restant.
- **CE = 35 min partout**, y compris dans l'examen complet (elle y était raccourcie à 30
  pour tenir dans les 90 min, qui n'existent plus).
- **`lib/exam-durations.ts` est la seule table de durées du web.** Elle ne sert qu'aux
  écrans **antérieurs à l'examen** (briefing de lancement, vitrines) : dès qu'un objet
  serveur existe, c'est lui qui fait foi (`subAttemptDurationLabel`). Le total annoncé
  (≈ 95 min) est **recalculé** depuis la table, jamais écrit — raccourcir une épreuve
  raccourcit la promesse. `EE_ADVISED_MINUTES_BY_TACHE` (7 / 10 / 13) est **éditorial** et
  purement indicatif : le seul chrono réel de l'EE porte sur les 3 tâches ensemble, et rien
  ne bloque sur le temps conseillé.
- **L'expression orale n'a PAS de chrono d'épreuve.** Elle se chronomètre **par tâche**, et
  le décompte ne part **qu'au lancement de la tâche** (`EoRecordingForm`, `examMode`) : la
  consigne s'affiche **sans aucun décompte** — `examIdle` masque le chrono — et un CTA
  « Je suis prêt · Commencer la tâche » met le temps en marche sur `dureeMaxSec`. Auto-stop
  à zéro, puis tâche suivante. Vaut pour l'EO **d'un examen complet ET jouée seule**.
  `AttemptResponse.timeLimitSeconds` est absent sur une session d'examen EO.
- **Réponse hors délai** : `POST /api/attempts/{id}/answers` renvoie **422**. Le refus porte
  sur **une réponse**, jamais sur la session — `QuestionRunner` affiche le message du
  serveur et bascule sur l'écran de fin (`finishCurrentAttempt(true)`, qui conserve le
  message). Les réponses précédentes sont conservées.
- **Une épreuve hors délai est clôturée par le SERVEUR** à la lecture (`GET /attempts/{id}`,
  `GET /full-tcf-exams/{id}`) : un retour dans l'app peut rendre une épreuve déjà
  `finishedAt`, c'est normal. Le hub relit l'examen à l'expiration au lieu de finaliser
  lui-même. **Il n'existe aucun flux « recommencer une épreuve interrompue » — ne pas en
  construire.**
- **`continuite`** (`SESSION_UNIQUE` / `PLUSIEURS_SESSIONS`, **null tant que l'examen n'est
  pas terminé**) s'affiche sur le bilan de l'examen complet. Libellés **gelés par le
  backend**, déclarés une seule fois dans `FULL_TCF_EXAM_CONTINUITE_LABEL` (`lib/types.ts`),
  miroir mot pour mot du mobile — jamais une chaîne recopiée dans un composant. Le cas
  « pas de résultat global définitif » reste porté par `finalLevelPartial` /
  `epreuvesCountedInFinalLevel` : **ne pas créer de notion parallèle**.

## Suspendre un examen complet — la règle de sortie (2026-08-15)

> **Une épreuve COMMENCÉE ne se reprend jamais. Une épreuve JAMAIS COMMENCÉE
> attend le candidat aussi longtemps qu'il faut.**

Arbitrage propriétaire. Il **révoque** « quitter = abandonner » (vague 9) et
complète le correctif de la flèche retour de la veille.

- 🛑 **Aucun résultat tant que les 4 épreuves ne sont pas terminées.** Le hub
  `/examens-blancs/tcf/[id]` n'a plus d'action menant au bilan depuis sa modale
  de sortie : le bouton du bas est **« Suspendre l'examen »**, et sa modale ne
  propose que **« Suspendre et reprendre plus tard »** / **« Continuer
  l'examen »**. Rien n'appelle `fullTcfExamApi.finish` depuis cet écran.
- **Suspendre clôture l'épreuve commencée, épargne les autres**, puis **sort de
  la page** (`/examens-blancs`). Un examen suspendu **reste « en cours »
  indéfiniment**, sans résultat, reprenable, et **garde son slot** dans la
  grille : c'est **voulu**, ne pas le clôturer automatiquement pour libérer la
  place.
- **« Commencée » = `timerStartedAt != null`** sur le sous-attempt (l'ancre
  posée par `POST /begin`). Même discriminant que l'état `not_taken` de
  `subAttemptView` — **ne pas en inventer un second**.
- **Règle et libellés déclarés une seule fois : `lib/full-exam-exit.ts`**
  (`epreuvesAClore`, `fullExamSuspendMessage`, `epreuveExitMessage`,
  `FULL_EXAM_SUSPEND_*`, `EPREUVE_EXIT_*`), **miroir mot pour mot** de
  `mobile_sejourfr/lib/screens/tcf_full_exam/full_exam_exit_labels.dart`. La
  modale **nomme l'épreuve** qui va être close ; **sans** épreuve commencée elle
  dit simplement que la progression est conservée — on ne fait pas peur pour
  rien.
- **Quitter une épreuve la clôture aussi**, sur les trois écrans d'épreuve :
  runner CO/CE (`/sessions/[id]?fullExamId=` → `quitMode="confirmFinish"` +
  `quitConfirm`, `onCompleted` ramène au hub) et session EE/EO
  (`ProductionSession` → `DetailShell onBack` = confirmation, puis
  `markSubDone`). ⚠️ Cela **revient sur** le retrait de `markSubDone` du
  « quitter » livré la veille : la règle produit a changé.
- **Ce qui ne clôture RIEN** : la flèche/lien de retour du **hub**, un
  démontage de composant, un back navigateur, une fermeture d'onglet. L'effet de
  démontage de `ProductionSession` continue de **sauter** le cas `fullExamId` —
  ne pas y ajouter de `markSubDone`, une navigation interne le déclencherait.
  Et **aucune** épreuve jamais commencée n'est fermée par un geste de sortie.
- **La grille dit « En cours · Reprendre »** : `ExamSlotData` porte
  `reportLabel` et `restartable` — un examen `IN_PROGRESS` ouvre le **hub**,
  jamais le bilan, et ne propose pas « Refaire » (parité mobile).
- **Un examen dont les 4 épreuves sont closes reste finissable** : le hub
  réaffiche « Voir mon résultat », et c'est la page bilan qui appelle `finish`.
- **Backend inchangé** : `finish` refuse tant qu'un sous-attempt n'est pas
  terminé, `beginEpreuve` ne ré-ancre jamais une épreuve terminée, et un attempt
  fini refuse toute réponse (`submitAnswer` → « Session déjà terminée ») comme
  toute soumission (`ProductionAccessService`). Rien à ajouter côté serveur.

## Quitter un examen blanc QCM joué seul (2026-08-15)

> **Quitter un examen, c'est le terminer.** La croix n'est pas un « je
> reviendrai » : l'attempt est finalisé, donc définitif et non reprenable, et le
> candidat arrive **directement sur son résultat**.

Périmètre : civique global (40 Q), civique **par thème** (20 Q), examens TCF par
épreuve (CO / CE / STRUCTURE via `moduleExamQuestionType`) et examens issus d'un
`ExamTemplate` (diagnostic CO+CE, démo guest). **Hors périmètre** : les séries
(`TRAINING`), où quitter n'a jamais rien coûté — `quitMode="link"`, comportement
inchangé — et les sous-épreuves d'un examen complet (`fullExamId` présent), qui
gardent les libellés de `lib/full-exam-exit.ts` : là, quitter **clôt l'épreuve
sans ouvrir de bilan**.

- **Mécanique inchangée** : `QuestionRunner quitMode="confirmFinish"` →
  `ConfirmSheet` → `finishCurrentAttempt()` → `onCompleted` → écran de résultat.
  Rien n'a été ajouté ; c'est le **texte** qui a changé, et il vit **une seule
  fois** dans **`lib/mock-exam-exit.ts`** (`MOCK_EXAM_QUIT_TITLE` / `_MESSAGE` /
  `_CONFIRM` / `_CANCEL`), **miroir mot pour mot** de
  `mobile_sejourfr/lib/screens/question_runner/mock_exam_exit_labels.dart`.
- **Le message dit les TROIS conséquences**, avant l'action : il ne pourra plus
  reprendre cet examen ; il aura son résultat sur ce qu'il a déjà répondu ; les
  questions restantes seront comptées **non répondues** (et pas « comptées comme
  fausses », qui décrivait mal ce que fait le serveur).
- **Le bouton de confirmation NOMME l'issue** — « Quitter et voir mon
  résultat », jamais un « Confirmer » neutre. C'est une demande explicite du
  propriétaire : la croix devient destructrice sur un simple appui, la
  confirmation est la seule protection, elle doit être lisible.
- **Annuler ne coûte rien… sauf le temps** : on revient à la question, aucune
  réponse n'est perdue, mais le chrono a continué de courir — quitter ne
  suspend jamais rien (règle du dépôt).
- **Ce qui ne finalise RIEN** : le back navigateur, la fermeture d'onglet, un
  rechargement. Aucun `beforeunload` n'est posé — un examen ne doit **jamais**
  être finalisé sans confirmation. Conséquence assumée : sortir par le
  navigateur laisse l'attempt reprenable, le serveur restant l'arbitre.
  ⚠️ Ne pas « corriger » ce trou en finalisant sur `unload` ou au démontage.
- **Ce qui finalise sans confirmation, et c'est normal** : l'expiration du
  chrono (`timeLimitSeconds` atteint → `finishCurrentAttempt()`) et le **422**
  « hors délai » sur une réponse (`finishCurrentAttempt(true)`, message serveur
  conservé). Ce ne sont pas des gestes de sortie : c'est la règle de l'examen.

## Paiement — abonnements récurrents (lot 4b)

Depuis le **lot 4b** (refonte backend lot 4) le web vend des **abonnements
récurrents Stripe** au lieu de paiements one-shot. 6 SKUs proposés : Civique +
Intégral × mensuel / trimestriel / annuel.

**Flow d'achat** :

1. L'utilisateur arrive sur `/paiement` (depuis paywall, sidebar, ou
   `/tarifs`). Optionnel : `?module=CIVIQUE|INTEGRAL` pour mettre l'accent
   sur un module, `?period=monthly|quarterly|yearly` pour pré-sélectionner
   la périodicité.
2. Toggle de périodicité (mensuel / trimestriel / annuel, par défaut
   trimestriel) → met à jour les prix sur les 2 cards (Civique + Intégral).
3. Clic sur un CTA → `billingApi.getPaymentLink(planCode)` où le `planCode`
   est dérivé via `planCodeFor(module, periodicity)` (ex: `INTEGRAL_QUARTERLY`).
4. Le backend renvoie `{ url }` d'une Checkout Session Stripe en mode
   `SUBSCRIPTION` ; le front fait `window.location.assign(url)`.
5. Stripe redirige vers `/paiement/succes?session_id=…&plan=<code>` après
   paiement. La page poll `refreshUser()` jusqu'à voir `hasCivique`/`hasTcf`
   activé (webhook backend → DB).

**Composants** :

- `components/pricing/PricingPlans.tsx` (client) — toggle + 3 cards
  (Free/Civique/Intégral). Variante `compact` pour la landing. Partagé entre
  `/tarifs` et la `PricingSection` du `/` (landing).
- `app/_components/PaywallSheet.tsx` — bottom sheet d'incitation à l'achat,
  prop `module: "CIVIQUE" | "INTEGRAL"` (plus de `plan`).
- `app/(app)/paiement/page.tsx` — page de checkout authentifiée, toggle
    + 2 cards, gestion du status courant (CurrentSubscriptionCard) et cas
      upgrade (CIVIQUE → INTEGRAL).

**Helpers `lib/api.ts`** :

- `planCodeFor(module, periodicity)` — dérive le code backend.
- `periodicityFromCycle(billingCycle)` — convertit le `billingCycle` backend
  (`MONTHLY` / `THREE_MONTHS` / `YEARLY`) vers la périodicité UI.

**Types `lib/types.ts`** :

- `PlanModuleTarget = "CIVIQUE" | "INTEGRAL"`
- `PlanPeriodicity = "monthly" | "quarterly" | "yearly"`

**Backend** : géré dans le lot 4 (cf. `CLAUDE.md` racine — Stripe Subscription
mode, `customer.subscription.*` webhooks, `plans.stripe_price_id` en DB).

## « Mon pass » (détail de l'accès — lot 5, achat unique)

Page `app/(app)/profil/abonnement/page.tsx` (route `/profil/abonnement`),
parité avec l'écran mobile `manage_subscription_screen.dart`. Accessible
depuis la carte « Mon pass » du `/profil` quand `user.isPremium`. La page
fetch `billingApi.getSubscriptionStatus()` + `billingApi.listPlans()` au
montage et affiche :

- **carte pass gradient** (« PASS ACTIF », nom du pass, formule, barre de
  jours restants = `daysUntil(expiresAt) / plan.durationDays`, date d'expiration) ;
- **détails** (Formule / Périmètre / Géré par / Expire le) ;
- **inclusions** (liste Civique ou Intégral) ;
- **prolongation / upgrade** via `/paiement?module=CIVIQUE|INTEGRAL`.

**Aucune résiliation** : un pass est payé une fois, sans renouvellement
automatique — il n'y a rien à annuler (les durées se cumulent à chaque
rachat). `billingApi.cancel()` et `CancelSubscriptionResponse` restent
définis (mode abonnement dormant, cf. réversibilité racine) mais ne sont
plus consommés par cette page. Le plan courant est retrouvé via
`status.productId` (Stripe = `Plan.code`, mobile = apple/googleProductId).

## `/reussir` — landing de bio réseaux

Page **autoportante** destinée au lien unique des bios TikTok / Instagram /
WhatsApp / Facebook. `app/reussir/page.tsx` (server, `revalidate = 1800`, fetch
`billingApi.listPlans()`) + `app/_components/reussir/ReussirView.tsx` (client) +
`reussir.module.css`.

- **Chrome global masqué pour tout le monde** : `STANDALONE_PREFIXES` +
  `isStandaloneRoute` dans `lib/chrome-routes.ts`, et `shouldHideGlobalChrome`
  retourne `true` sur ces routes **avant** le test d'authentification. Une
  landing de bio n'a qu'un seul job — chaque lien de nav en plus est une fuite.
  Ajouter une future landing = une entrée dans `STANDALONE_PREFIXES`.
- **Message match multi-réseaux** : le titre ne nomme aucun réseau ; un badge
  affiche la provenance détectée (`?utm_source=` / `?src=`, puis `document.referrer`)
  parmi TikTok / Instagram / WhatsApp / Facebook / YouTube, et retombe sur
  « Bienvenue sur SejourFR ». Lu via `useSyncExternalStore` (snapshot serveur
  neutre → pas de mismatch d'hydratation).
- **Tarifs pilotés par la base** : les cartes viennent de `/api/billing/plans`
  filtrées `purchaseType === "ONE_TIME"`, triées par `durationDays`. Le
  sélecteur de parcours (**TCF par défaut**) affiche **strictement** les pass du
  module choisi — Intégral (rouge) ou Civique (bleu) — jamais les deux. Le
  nombre de simulations orales vient de `PlanPublicResponse.realtimeEoSessions`
  (cf. CLAUDE.md racine), jamais codé en dur.
- **Parcours d'achat continu** : un clic sur un pass va sur
  `/paiement?module=…&plan=<code>` si l'utilisateur est connecté, sinon sur
  `/inscription?next=<cette URL>`. C'est ce qui a motivé les deux ajouts
  ci-dessous.
- **Section app mobile** : bloc encre dédié (iOS + Android, même compte, même
  progression) avec un aperçu d'écran rendu en **CSS pur** (`PhoneMockup`) —
  pas de capture à re-shooter à chaque refonte de l'app, rien à charger. Les
  badges stores viennent de `STORE_LINKS` (`lib/site.ts`), partagés avec le
  bloc final.
- **Acquisition = diagnostic** (2026-08-09) : le hero promet 1 écrit + 1 oral
  enregistré en ≈ 8 à 10 min, sans carte bancaire. Son visuel est un **exemple
  de résultat diagnostic** ; la simulation orale temps réel reste dans la
  section IA suivante comme bénéfice avancé. Les trois CTA passent par
  `DiagnosticCta` : compte connecté → `/diagnostic`, visiteur →
  `/inscription?next=%2Fdiagnostic`, diagnostic déjà terminé → `/plan`.
- **Mesure d'audience** : `lib/audience.ts` utilise `sendBeacon` (survit à la
  navigation), sans cookie ni stockage navigateur. `lib/audience-events.ts`
  borne strictement les couples chemin/événement autorisés par le backend.
  `/reussir` envoie `VIEW` et `SOCIAL_LANDING_DIAGNOSTIC_CLICKED` ; les étapes
  diagnostic et Plan ont leurs événements dédiés, sans réponse ni identifiant.
- Liens sociaux dans `lib/site.ts` (`SOCIAL_ACCOUNTS`) : une entrée à
  `url: null` **n'est pas rendue** — on ne publie jamais un lien vers un compte
  qui n'existe pas encore.

### `?next=` sur `/inscription` et `?plan=` sur `/paiement`

- **`/inscription?next=<chemin interne>`** (miroir de `/connexion`) : passé par
  `safeInternalPath` (anti open-redirect), utilisé après `register`, après le
  sign-in Google, et propagé au lien « Se connecter ». `/connexion` le propage
  réciproquement au lien « Créer un compte gratuit » : un visiteur venu de
  `/reussir` retombe donc toujours sur `/diagnostic`. Sans le paramètre, le
  comportement historique (`/dashboard`) est inchangé.
- **`/paiement?plan=<code>`** : met en évidence le pass ciblé (`.otp-pass.is-targeted`)
  et scrolle dessus au montage. Le gate non-connecté de `/paiement` conserve
  désormais l'URL complète (module + plan) dans son `?next=`, et propose
  inscription **et** connexion.

## Diagnostic TCF initial + Plan (2026-08-09)

- **Le backend décide du parcours** : `DiagnosticResponse.status` et
  `nextStep` font foi. `/diagnostic` ne déduit pas l'étape depuis le navigateur
  et ne demande jamais de refaire une production dont `submissionId` existe.
  États : `NOT_STARTED`, `IN_PROGRESS`, `ANALYZING`, `COMPLETED`, `FAILED` ;
  reprise : `PRESENTATION`, `WRITTEN`, `ORAL`, `ANALYSIS`, `RESULT`.
- **Deux exercices SejourFR, pas un examen officiel** : EE réutilise
  `EeWritingForm`, EO réutilise `EoRecordingForm` sans `onModeChoice` (donc
  aucun temps réel). Les cartes de consigne sont propres au diagnostic afin de
  ne montrer ni numéro de tâche officielle ni niveau factice. L'audio EO fixe
  vient de `DiagnosticExerciseDto.instructionAudioUrl`.
- **Soumissions existantes** : EE → JSON et EO → multipart sur
  `POST /api/production-submissions`, avec les `productionTaskId` / `attemptId`
  fournis par le diagnostic. Ensuite seul `GET /api/diagnostics/{id}` est pollé
  jusqu'à la décision serveur. `retry-analysis` conserve les deux productions.
- **Restitution prudente** : aucun `/20`, maximum 3 points solides et 3
  priorités, seulement les compétences `observed`, mention « estimation
  d'entraînement, non officielle ». Le détail est replié ; le CTA principal
  ouvre `/plan`.
- **Plan ≠ Progression** : `/plan` rend les trois états
  `NEEDS_DIAGNOSTIC`, `DIAGNOSTIC_IN_PROGRESS`, `ACTIVE`. En actif, il affiche
  une seule priorité immédiate et au maximum 2 suivantes (3 priorités au total),
  les compétences observées,
  la réévaluation et le micro-exercice fourni par `recommendedExercise`.
  `/statistiques` reste l'historique chiffré et est accessible par « Voir ma
  progression », mais n'a plus d'entrée principale dans `AppSidebar`.
- **Une ÉTAPE, ce sont les 5 premiers sujets de la compétence, pas ses 15.**
  `LearningPlanPriorityDto` porte **deux** jeux de compteurs :
  `promptCount`/`attemptedCount`/`validatedCount` = la **compétence entière**
  (ce que lisent les cartes « compétences observées », inchangées), et
  `stepPromptCount`/`stepAttemptedCount`/`stepValidatedCount`/`stepCompleted` =
  l'**étape**. L'anneau d'une étape (`PathStep` → `SkillRing`) lit le second
  couple — « 2/5 », jamais « 2/15 ». Ne pas les mélanger : c'est le seul piège
  de cet écran. `stepCompleted` est **servi**, plus déduit d'un
  `attemptedCount >= promptCount` local.
- **Une étape peut être TERMINÉE, et elle reste affichée** : le badge passe de
  « En cours » à « Terminée » (état `done`, vert), et une ligne apparaît sous le
  titre — « Réévaluée à ta prochaine production. ». Les priorités ne changent
  qu'à l'arrivée d'une nouvelle observation, donc à la prochaine production :
  sans cette phrase, un candidat qui a fini son étape et la voit toujours là
  croit à un bug. Terminée **sans** être toute validée ⇒ une seconde ligne
  discrète « N validés sur M » (rien quand tout est validé). Libellés gelés,
  miroir mot pour mot de `_StepDoneLines` côté mobile. Un compte gratuit plafonne
  à 2/5 (2 sujets ouverts par compétence) : `stepCompleted` reste faux et le CTA
  reste « Débloquer cette étape » — rien ne laisse croire l'étape finissable.
- **L'état de maîtrise remplace le compteur sur une carte de compétence**
  (décision propriétaire) : `SkillDto.masteryState` (« Priorité » / « À
  renforcer » / « En consolidation » / « Solide », `SKILL_MASTERY_STATE_LABEL`,
  libellés gelés) s'affiche à la place de `competenceProgressLabel` dans
  `CompetencesList`, et à la place du badge de statut sur les cartes
  « compétences observées » du Plan. **`null` (aucune observation) est le seul
  cas où le compteur reste** — le serveur n'a rien vu, il n'y a pas d'état à
  annoncer. Une seule brique, `SkillMasteryPill` (`skill-ui/SkillLayout`), qui
  réemploie les tons de `SkillBadge` : jamais une teinte nouvelle. Les
  compteurs restent sur les DTO, ils alimentent toujours l'anneau.
- **La trajectoire d'une compétence vit dans SA fiche**, pas dans le Plan ni
  dans un écran de plus : `SkillDetailDto.trajectory` → `SkillTrajectory`
  (`competences/`), une frise du **plus ancien au plus récent** (l'ordre vient
  du serveur), une ligne par observation = source
  (`LEARNING_PLAN_SOURCE_LABEL`, libellés gelés) + verdict + date, l'explication
  en second plan. **Vide ⇒ aucune section**, pas d'encart d'excuse.
  `confidence` n'est **jamais** montrée au candidat : c'est la certitude du
  correcteur, pas son niveau.
- **Une étape du Plan peut devenir une VÉRIFICATION** —
  `recommendedExercise.kind === "REASSESSMENT"` : **même carte, même
  emplacement**, badge « VÉRIFICATION » (là où s'affiche « EN COURS »), CTA
  « Vérifier ma progression » sur `TodayCard` comme sur `PathStep`. Jamais une
  seconde carte concurrente. Le routage vit **en un seul endroit**,
  `recommendedExerciseHref` : micro-sujet → l'écran de petit sujet ;
  vérification → l'écran de production du sujet
  (`/entrainement/tcf/{ee|eo}/{redaction|enregistrement}/{productionTaskId}`,
  segment déclaré une seule fois dans `lib/production-catalog.ts` et lu par
  `ProductionConfig.inputSegment`). `locked` : cadenas + paywall, l'exercice
  reste **désigné**.
- **Le Plan porte un JALON, à côté des étapes** — `LearningPlanDto.milestone`
  (`PlanMilestoneExerciseDto`) → `PlanMilestoneCard`, **sous** les priorités et
  au-dessus des compétences observées. Un jalon n'est pas une étape : il désigne
  un **examen blanc déjà existant** par son `epreuve` + `slotNumber`, et
  `PlanExerciseKind` gagne pour cela `EPREUVE_MOCK_EXAM` / `FULL_TCF_MOCK_EXAM`.
  **`milestone === null` est le cas NORMAL** (même sursis que `planChange`) :
  rien ne s'affiche, aucun indicateur, aucun message.
  ⚠️ **Sur un jalon, `title`, `skillCode`, `skillId` et `section` sont `null`** —
  d'où l'**union discriminée** `PlanRecommendedExerciseDto =
  PlanStepExerciseDto | PlanMilestoneExerciseDto` dans `lib/types.ts` : le type
  interdit de lire un titre qui n'existe pas, plutôt qu'une convention à
  relire. `recommendedExercise` et `nextAction` restent des **étapes**
  (`PlanStepExerciseDto`), `recommendedExerciseHref` aussi — un jalon n'a pas
  d'URL, il se **démarre**.
  **Le serveur ne fournit AUCUN libellé** (il expose des faits) : les phrases
  vivent dans `lib/diagnostic.ts` (`PLAN_MILESTONE_*`, `planMilestoneTitle` /
  `planMilestoneText` / `planMilestoneMeta`), **miroir mot pour mot** de
  `mobile/lib/screens/plan/plan_milestone_labels.dart`. La durée vient
  d'`estimatedMinutes`, jamais d'un nombre écrit ici.
  **Aucune route ni aucun appel n'est créé** : `EPREUVE_MOCK_EXAM` réutilise
  `productionApi.startAttempt({exam: true, slotNumber})` → `{base}/session/{id}`
  (le chemin de `ProductionExams`), `FULL_TCF_MOCK_EXAM` réutilise
  `fullTcfExamApi.start(slotNumber)` → `/examens-blancs/tcf/{id}` (celui de
  `TcfFullExamBriefingSheet`), 403 → `handleStartFailure` → `PaywallSheet`.
  `locked` : cadenas + `SKILL_PREMIUM_HREF`, **sans rien masquer**.
- **« Ce que ça change dans le Plan » sur le rapport d'une tâche** :
  `ProductionSubmissionDto.planChange` → `PlanChangeLine`, **une ligne** en fin
  de rapport (« X confirmée » / « Nouvelle priorité : Y. » + « Voir » vers
  `/plan`), les deux moitiés indépendamment nullables. **`planChange === null`
  est un cas NORMAL** (rien n'a bougé, ou observations pas encore écrites) :
  rien ne s'affiche, aucun spinner. Les observations arrivant **après** le plan
  d'action, `ProductionResults` étend la **même** boucle de polling dans le
  **même** sursis (`ACTION_PLAN_GRACE_MS`, même `graceStartedAt`) — pas de
  seconde boucle, pas une seconde de plus, et **aucun indicateur d'attente**.
- **`priority.explanation` n'est affiché sur AUCUNE carte d'action** — ni
  « À faire maintenant » (`TodayCard`), ni les étapes du parcours, ni la carte
  « Votre priorité du jour » du tableau de bord. C'est le constat d'une
  production **déjà faite** : il raconte le passé sur une carte qui annonce
  l'action à mener. Le champ reste sur le DTO et vit dans le diagnostic ; le
  mobile ne l'a jamais affiché sur ces cartes — ne pas le rebrancher.
- **Cache** : dashboard mutualise les requêtes en vol de
  `diagnosticApi.currentCached()` sans conserver le snapshot résolu (le pipeline
  peut le faire évoluer sans écriture du navigateur), et conserve
  `learningPlanApi.getCached()`. Toute production complète ou tentative de
  compétence terminale purge les préfixes concernés dans `lib/api.ts`; les
  écrans `/diagnostic` et `/plan` lisent directement le serveur pour ne pas
  figer une analyse asynchrone.
- **Accueil** : carte non bloquante en trois états — invitation (+ « Plus
  tard » local), reprise avec `N / 2`, puis priorité du jour et accès au Plan.
- **Routes** : `middleware.ts` ne protège plus que `/plan` (et `/dashboard`,
  `/paiement`) ; `/diagnostic` est une route **duale**
  (`DUAL_CHROME_PREFIXES`), sous `app/diagnostic/`, hors du groupe `(app)` :
  `DiagnosticView` porte lui-même le `DualChromeShell` (sidebar pour un compte,
  fond applicatif nu + header/footer publics pour un visiteur).

### Écran de présentation — « 5 minutes », pas un examen (2026-08-14)

`DiagnosticIntro` (dans `DiagnosticView.tsx`, **partagé visiteur ⇄ compte**) annonce
un budget court **en tête** (pilule `.duration`, avant le titre) puis les **deux
exercices séparément**, chacun avec sa mesure. Le premier contact décidait de tout :
« 2 exercices · environ 8 à 10 min » et trois puces de promesses donnaient
l'impression d'un examen complet.

- 🛑 **Aucun chiffre n'est écrit en dur.** Les mesures se dérivent des sujets servis
  (`wordsMin/Max`, `durationMin/MaxSeconds`) par les règles **pures** de
  `lib/diagnostic.ts` — `diagnosticBudgetLabel`, `diagnosticWrittenMeasureLabel`,
  `diagnosticOralMeasureLabel` (+ `DIAGNOSTIC_WRITING_WORDS_PER_MINUTE = 40`,
  vitesse de rédaction retenue **pour cet écran seulement**, à ne pas confondre
  avec les 12 mots/min d'`ExerciseDuration` côté serveur). Le budget de tête est la
  **somme** des deux : raccourcir un sujet en base raccourcit la promesse, l'écran
  ne peut pas mentir. Miroir mot pour mot :
  `mobile_sejourfr/lib/screens/diagnostic/diagnostic_intro_labels.dart`.
- **Repli sans chiffre, jamais un chiffre inventé** : sans borne exploitable, la
  pilule dit « Diagnostic express · 2 exercices » et les lignes « un court texte » /
  « un court enregistrement ».
- **Un compte sans session (`NOT_STARTED`) ne reçoit AUCUN sujet** (le serveur ne
  les attache qu'à `POST /api/diagnostics`) : `useIntroMeasures` relit alors
  `diagnosticApi.publicCurrent()` — un seul appel, sur cette page, en best-effort.
  Sans lui, le visiteur lisait ses mesures et le compte connecté n'en voyait
  aucune. Un échec laisse la présentation sans chiffre, il ne bloque jamais le
  démarrage.
- « ~5 min » est un **ordre de grandeur**, jamais un compte à rebours : rien dans le
  parcours ne chronomètre le candidat dessus.
- Les garanties restent : « Commencez sans compte… » en visiteur, « Estimation
  d'entraînement, non officielle. » partout, et la mention « aucune note sur 20 »
  vit toujours sur `ExerciseHeader`.

### Diagnostic en INVITÉ — produire d'abord, créer le compte ensuite (2026-08-10)

Le mur d'inscription est passé **après** les deux productions : un visiteur
ouvre `/diagnostic`, rédige, s'enregistre, puis on lui demande un compte pour
lancer l'analyse. `/reussir` pointe donc directement sur `/diagnostic`, sans
détour par `/inscription`.

- **Deux régimes, deux composants** dans `DiagnosticView.tsx` :
  `GuestDiagnostic` (sujets via `diagnosticApi.publicCurrent()`, productions
  gardées localement) et `ConnectedDiagnostic` (**le parcours serveur
  historique, inchangé** : session, polling, reprise cross-device, retry). Un
  visiteur déjà connecté ne voit aucune différence avec avant.
- **`GET /api/public/diagnostics/current`** ne sert que les **sujets**
  (`PublicDiagnosticResponse` / `PublicDiagnosticExerciseDto` dans
  `lib/types.ts`) : ni `attemptId`, ni `submissionId` — ils n'existent qu'une
  fois la session créée, donc après le compte.
- 🛑 **On ne perd JAMAIS une production.** `lib/diagnostic-local-store.ts`
  écrit le texte EE **et le Blob audio EO** dans **IndexedDB** (clé
  `code/vN`) — `localStorage` ne stocke pas de binaire ; l'audio est persisté en
  `ArrayBuffer` + type MIME et rebâti en `Blob` à la lecture. Ça survit à un
  rafraîchissement, à une fermeture d'onglet et à un sign-in social qui quitte
  la page. Écriture impossible (navigation privée, quota) ⇒ la production reste
  en mémoire dans l'onglet **et on le dit** au candidat.
- **Ordre des opérations après authentification** (`runHandoff`) : `POST
  /api/diagnostics` → soumission de l'écrit → attente de son enregistrement
  (`refreshAfterSubmission`) → soumission de l'oral → attente → **et seulement
  là** `clearLocalDiagnostic`. Toute sortie anticipée (erreur réseau, session
  déjà terminée, sujets d'une autre version) **laisse le travail intact** et
  propose de réessayer. Le démarrage est verrouillé par un `ref` : `user`
  change d'identité à chaque `refreshUser()`, rejouer la reprise renverrait les
  mêmes productions deux fois. 🛑 **Ce corps async n'a PAS de drapeau
  `cancelled`, et il ne faut pas en remettre** : le nettoyage de l'effet se
  déclenche à chaque nouvelle identité de `user` (donc juste après
  l'inscription) et au premier montage en StrictMode. Interrompre le corps
  sortait sans lancer `runHandoff` ni repasser `loading` à `false`, pendant que
  le `ref` interdisait toute reprise — écran gris définitif et **plus aucune
  session de diagnostic créée depuis la refonte invité**. Le « exactement une
  fois » est tenu par le `ref` posé **avant le premier `await`** ; un `setState`
  après démontage est un no-op en React 18+.
- **Un transfert en cours prime sur le squelette.** `loading` reste vrai
  pendant tout `runHandoff` : les branches `handoff` (`running` / `error` /
  `version-mismatch`) sont testées **avant** `if (!user || loading)`, sinon la
  carte « Nous enregistrons vos deux réponses » et surtout celle
  « Vos réponses n'ont pas été envoyées / Réessayer l'envoi » restent
  inatteignables. Un `LOADING_WATCHDOG_MS` (20 s) rend la main avec la carte
  d'erreur si le chargement n'aboutit jamais : un squelette est un état de
  chargement, pas un état d'échec.
- **Attente de l'analyse IA** (`AnalysisWaiting`) : pendant `ANALYZING` /
  `nextStep === "ANALYSIS"`, l'écran nomme l'analyse, liste les étapes
  franchies (`role="status"`) et fait tourner un compteur mm:ss démarré à
  l'entrée dans l'écran (`aria-live="off"` sur le chiffre). La réassurance
  bascule au-delà de 2 min sur « c'est plus long que d'habitude » — on ne
  promet pas un délai qu'on ne tient pas. Un aléa réseau du polling s'affiche en
  gris (`waitTransient`), jamais en rouge : seul `status === "FAILED"` est un
  échec.
- **Compte qui a déjà un diagnostic** : `POST /api/diagnostics` est idempotent
  et peut renvoyer une session `COMPLETED` — une tâche n'accepte qu'une
  soumission. On n'envoie alors rien, on affiche le résultat existant avec un
  bandeau honnête (`HandoffNotice`) et un bouton explicite pour supprimer les
  réponses gardées sur l'appareil. Jamais de suppression silencieuse.
- **Écran de demande de compte** (`DiagnosticAccountGate.tsx`) : inscription
  **et** connexion (+ Google), en modale de page — pas de navigation vers
  `/inscription`, qui ferait perdre le contexte. Il montre un **exemple**
  illustratif du bilan, badgé « Exemple — pas votre résultat » et légendé
  « valeurs fictives » : aucun résultat réel n'est calculé avant le compte
  (l'analyse coûte deux appels LLM payés).
- **Audience** : le funnel reste mesurable en invité (`/api/public/page-views`
  est public). Nouvel événement **`DIAGNOSTIC_ACCOUNT_REQUIRED`** (allowlist
  `lib/audience-events.ts`, miroir backend) émis à l'affichage de l'écran de
  compte — c'est LA mesure de conversion du parcours.

## Stratégie produit — parité fonctionnelle avec le mobile

Décision **2026-05-16** : le web n'est plus une simple vitrine, c'est désormais une
surface d'entraînement complète à parité fonctionnelle avec l'app mobile, avec le
même paywall Stripe. Depuis le **lot 4b (mai 2026)** le modèle commercial est
en abonnements récurrents (mensuel / trimestriel / annuel) sur deux modules
(Civique / Intégral). Le mobile reste l'app quotidienne (offline futur,
notifs), mais tout est faisable depuis le web.

Chantier découpé en vagues :

- **Vague 1** ✅ — Cœur entraînement : runner réutilisable, route
  `/sessions/[attemptId]` (générique), gating démo (20Q) / premium (illimité),
  favoris, raccourcis clavier, target path banner, paywall sheet.
- **Vague 2** ✅ — Examens blancs complets : `QuestionRunner` enrichi avec timer
  (mode exam, urgence rouge sous 5min, auto-finish à 0), refonte `/examens-blancs`
  (liste sectionnée free/premium, gating par module, paywall sheet) +
  `/examens-blancs/[slug]` (briefing + start qui POST l'attempt et redirige vers
  `/sessions/<id>`). Ancien `ExamRunnerClient.tsx` supprimé,
  `/examen-blanc` redirige vers `/examens-blancs`. (NB lot 6 : `ExamResultCard`
  retiré — le détail d'un examen montre directement le rapport `ExamReport` ;
  côté TCF une carte compacte `TcfScoreCard` points + niveau précède le rapport.)
- **Vague 3** ✅ — Stats / Historique / Révision / Favoris :
  `/statistiques` (stats par thème + tri faibles d'abord, couleurs vert/ambre/rouge),
  `/revision` (tabs erreurs+favoris avec modal détail réutilisant `QuestionReviewResponse`),
  `/historique` (liste MOCK_EXAM via `attemptApi.listMine`, graphique custom SVG).
  Dashboard refondu : snapshot par module, action cards, dernières sessions, bandeau
  "reprendre" si attempt en cours. Sidebar enrichie (3 nouveaux liens).
- **Vague 4** ✅ — Profil, parcours, onboarding intégré : `/profil` (identité,
  parcours, abonnement, sécurité avec stubs pour update profile/delete account
  en attendant les endpoints backend), `/parcours` (édition target path CSP/CR/NAT,
  cards radio + niveau TCF dérivé, sert aussi d'onboarding quand `targetProcedure`
  est null). Bandeau onboarding sur dashboard si pas de parcours choisi.
  `TargetPathBanner` pointe désormais vers `/parcours?from=<courant>` pour
  édition directe + retour au contexte. Sidebar enrichie avec "Mon profil".
- **Vague 5** ✅ — Pages détail de module (parité écrans mobiles
  `module_detail/`). Un clic sur un module depuis `/entrainement` ouvre un
  écran détail à onglets, branché sur le runner existant :
    - **Civique** `/entrainement/civique/[themeId]` — onglets **Lots / Examens /
      Erreurs**. Lots → `TRAINING {themeId, lotNumero}` → runner mode lot.
      Examens → 10 slots (abonné = tous lançables, gratuit = slot 1 seul, 2+ →
      paywall), `MOCK_EXAM {themeId}` (20 Q/20 min/seuil 16). Erreurs → liste
      cliquable → `QuestionDetailModal`.
    - **TCF QCM** `/entrainement/tcf/[code]` (code = `co`/`ce`) — onglets
      **Séries / Examens / Erreurs**. Séries = 3 cartes niveau (A2/B1/B2) →
      `/entrainement/tcf/[code]/[level]` (lots du niveau via
      `lotApi.listTcf(questionType, difficulty)`, lot gated premium → paywall
      INTEGRAL). Examens → `MOCK_EXAM {moduleExamQuestionType}` (25 Q,
      20 min CO / 35 min CE, score /50). EE/EO restent sur le
      `ProductionMobileSheet` (productions mobiles uniquement).
    - **Composants partagés** `app/_components/module_detail/` :
      `parts.tsx` (ModuleDetailShell/Hero/Tabs, LotsGrid, ExamSlots, ErrorsList,
      SkeletonGrid) + `ModuleDetail.module.css` (accent bleu/rouge via
      `data-accent`). `QuestionDetailModal` extrait de `/revision`.
    - **Runner mode lot** : `/sessions/[id]?lot=<numero>` force le batch fixe
      (pas d'extension premium), eyebrow "Lot N", retour au détail via
      `lotReturnPath(attempt)` (civique → thème, TCF → épreuve×niveau).

- **Vague 6** ✅ — Refonte **single-scroll** des hubs et pages détail au design
  de l'app mobile (`screens/civique`, `screens/tcf`, `module_detail/`). Les
  onglets disparaissent ; chaque écran est un scroll unique. L'onglet « Erreurs »
  est retiré partout (les erreurs vivent dans `/revision`, comme sur mobile).
    - **Composants partagés** `app/_components/hub/` (miroir de
      `hub_home_widgets.dart`) : `HubParts.tsx` (HubHeader, HubDetailHeader,
      ExamBlancHero, EpreuveCard, SectionLabel/Counter/Link, LotRow,
      ExamHistoryList, CiviqueMasteryCard), `ExamSlotsView.tsx` (stats + progress +
      chips + slots), `CiviqueHub.tsx`, `TcfHub.tsx` + `hub.module.css` (accents
      pilotés par variables CSS `--accent`/`--accent-bg`).
    - **`/entrainement`** = simple dispatcher : `?module=TCF` → `TcfHub`, sinon
      `CiviqueHub` (les deux dual guest/connecté). L'ancien `EntrainementHub` à
      onglets (~1500 l.) est supprimé.
    - **Civique** : hub (hero examen 40 Q → `/examens-blancs/civique` existant +
      thèmes + maîtrise) → détail thème (hero examen 20 Q + lots + historique) →
      page examens thème dédiée `/entrainement/civique/[themeId]/examens`
      (20 Q, 10 slots).
    - **TCF** : hub (hero examen complet + 5 épreuves + carte CECRL + stats ;
      EE + EO branchées web) → détail QCM (hero + 3 niveaux + historique) →
      `/entrainement/tcf/[code]/examens` (10 slots) et `[code]/[level]` (lots,
      lot 1 gratuit / 2+ premium).
    - **Bilan de série (ex-lot)** : depuis la refonte web_refonte, toutes les
      séries (TCF et civique) affichent le rapport commun `ExamReport` — à
      chaud comme en consultation. `?result=tcfLot&code&level` est conservé
      comme héritage d'URL (sert au chemin « Autres séries ») ;
      `TcfLotResultCard` est supprimé.
    - `module_detail/parts.tsx` ne garde que `ModuleDetailGate` + `moduleDetailStyles`.
    - (`ProductionMobileSheet` n'est plus utilisé par le hub — conservé pour les
      promos mobile du dashboard/historique.)

- **Vague 9** ✅ — **Examen blanc TCF complet orchestré (CO → CE → EE → EO)**,
  parité mobile (`screens/tcf_full_exam/*`, `screens/module_detail/tcf_full_exams_*`).
  Le parent `TCF_COMPLET` porte 4 sous-attempts ; le backend
  (`FullTcfExamController`, endpoints `/api/full-tcf-exams*` + `/api/me/full-tcf-exams`)
  agrège le statut `IN_PROGRESS | PENDING_EVALUATIONS | COMPLETED`.
    - **Pas de route `/tcf/examen-blanc`** : tout vit sous **`app/examens-blancs/`**
      (la liste, c'est `/examens-blancs`). `tcf/[id]/page.tsx` (hub de progression :
      4 StepCards, chrono 90 min auto-finish à 0 → bilan ; **le chrono ne démarre
      qu'au 1er « Commencer · Compréhension orale »** — pas à la création de
      l'examen. Le bouton appelle `fullTcfExamApi.begin(id, epreuve)` AVANT
      d'ouvrir le runner CO/CE : le backend pose `timer_started_at` sur le parent
      au 1er appel (ancre du décompte global, exposé en
      `FullTcfExamResponse.timerStartedAt`) **et recale le `started_at` de la
      sous-épreuve lancée** (CO **et** CE) sur l'instant réel — sinon la CE,
      créée en même temps que la CO, héritait du temps déjà écoulé et démarrait
      amputée (bug « la CE n'avait que 10 min »). Le runner décompte depuis ce
      `started_at` réaligné (re-fetché à l'ouverture de `/sessions/[id]`). Tant
      que `timerStartedAt` est null, le badge affiche 90:00 sans décompter.
      Backend : `FullTcfExamService.beginEpreuve(userId, parentId, epreuve)`
      idempotent par ancre (`sub.timer_started_at` = garde) + endpoint
      `POST /api/full-tcf-exams/{id}/begin?epreuve=TCF_CO|TCF_CE` + migration V013
      `attempts.timer_started_at`. `startedAt` (création) reste l'ancre de tri /
      dédup par slot des grilles. Parité mobile faite (`beginEpreuve` côté
      `tcf_full_exam_progress_screen`). Sous-épreuves EE/EO du complet :
      **pas** de `timeLimitSeconds` backend → repli front 30 min pour l'EE,
      **aucun chrono local pour l'EO** (le temps y est tenu par le compteur
      global des 90 min du hub ; un second décompte se contredirait).),
      `tcf/[id]/bilan/page.tsx` (CECRL plancher + polling 3 s rapide 30 s puis 8 s,
      max 5 min, sur `status === COMPLETED`), `tcf/TcfFullExamBriefingSheet.tsx`
      (lancement + 403 → paywall, ouvert **inline** depuis la carte TCF).
    - **Règles de lecture du bilan** → `lib/exam-levels.ts` (pures, testées) :
      `subAttemptView` (état d'une épreuve : verrouillée / non terminée /
      évaluée / en cours / **en échec** / **stale**), `examIsStale` (examen
      finalisé depuis > 2 min sans être COMPLETED ⇒ plus rien ne tourne : on
      coupe le spinner et on propose « Actualiser », parité mobile),
      `epreuveLevelTone` / `floorMarks` (couleur = palier, plancher = texte),
      **`qcmScoreLabel`** (le score d'une sous-épreuve CO/CE, **toujours sur
      l'échelle du relevé TCF** : `calibratedScore` 100-499 dérivé serveur par
      `TcfLevelEstimatorService`, repli sur le pondéré `x/maxScore` seulement
      quand il manque, `null` quand il n'y a rien — EE/EO, épreuve verrouillée,
      pas encore notée). Le `score`/`maxScore` du DTO est le score **pondéré
      interne** (A2=1, B1=2, B2=3) : « 23/50 » ne correspond à rien sur le relevé
      d'un candidat, et **on ne dérive jamais un /499 d'un pondéré côté front**.
      Lu par le hub de progression (`StepBadge`) et par `subAttemptView` (donc le
      bilan), miroir de `FullTcfExamSubAttempt.qcmScoreLabel` côté mobile. Même
      barème que les examens **module** CO/CE, déjà en /499 — le **civique** n'est
      pas concerné (/40 ou /20),
      `floorScope` + `floorRuleSentence` (la phrase du plancher dit le
      **périmètre réel**), `isCompleteExamResult`. Une épreuve dont
      `failedSubmissionIds` n'est pas vide affiche une bannière rouge +
      « Réessayer » (`productionApi.retrySubmission` sur chaque id) au lieu de
      tourner à vide. **Bilan partiel** (`finalLevelPartial`, aussi porté par le
      résumé) : le niveau ne porte pas sur les 4 épreuves (EE/EO verrouillée,
      évaluations échouées) → phrase « Bilan partiel : … N épreuves sur 4 », et
      l'examen est **écarté** des stats « Meilleur niveau » / « Dernier examen »
      de `/examens-blancs` + annoté « · partiel » dans sa carte de slot (pas de
      check de réussite). Miroirs `epreuvesCountedInFinalLevel`,
      `epreuvesExpected`, `finalLevelPartial` dans `lib/types.ts`.
    - **Évaluation IA en arrière-plan (parité mobile)** : EE/EO soumettent T1/T2
      sans attendre l'éval (`SUBMITTED` ~500 ms) ; après T3, `fullTcfExamApi.markSubDone`
      pose `finishedAt` et débloque l'épreuve suivante au hub sans attendre l'IA.
      Le bilan ne reste en attente que sur la dernière tâche → résultat en ~15 s.
    - **Intégration runners** : CO/CE (`/sessions/[attemptId]?fullExamId=`) et EE/EO
      (`ProductionSession`, `?fullExamId=`) détectent le param → retour au hub
      (`/examens-blancs/tcf/[id]`) au lieu du rapport individuel.
    - ⚠️ **« Quitter = abandonner » est RÉVOQUÉ** (2026-08-15) : le hub ne
      finalise plus l'examen et n'ouvre plus le bilan. Cf. la section
      *Suspendre un examen complet* ci-dessous, qui fait foi. Les examens
      autonomes (diagnostic guest, mocks) gardent, eux,
      `QuestionRunner quitMode="confirmFinish"` → avertit + finalise + résultat.
    - **Freemium** : sur `/examens-blancs`, **connecté gratuit ET abonné voient
      la même grille d'examen complet** (`fullExamSlotData`, `fullTcfExamApi`).
      Gratuit → `premium={false} freeSlots={1}` : **examen 1 offert** (EE/EO
      évaluées une fois, message via `TcfFullExamBriefingSheet isFreeAccount`),
      examens 2-20 → paywall INTEGRAL. Abonné → `premium` (20 slots). Le backend
      (`FullTcfExamService.start`) n'exige plus `hasTcf` ; au refaire de l'examen
      1, EE/EO arrivent verrouillées (`SubAttempt.locked` → cadenas au hub
      `tcf/[id]` et au bilan, pas de lien). L'ancien diagnostic CO+CE connecté
      gratuit (`tcf-mix-01`) est retiré de cette page (reste pour les **invités**
      via la page briefing `[slug]`). `ModuleExamsSection` = chrome + grille en
      `children`. Miroir `FullTcfExamSubAttempt.locked` dans `lib/types.ts`.
    - **Statut backend** (`FullTcfExamService`) : un examen abandonné sans soumettre
      EE/EO ne reste PAS `PENDING_EVALUATIONS` — le statut ne dépend que des
      submissions réellement en pipeline (`hasInFlightProduction`) ; une épreuve
      production terminée sans soumission compte `A1_NON_ATTEINT`.
    - **Types/api** `lib/types.ts` (`FullTcfExamResponse`, `FullTcfExamSubAttempt`,
      `FullTcfExamSummaryResponse`, `FullTcfExamStatus`, `FULL_TCF_EXAM_DURATION_SEC`,
      `FULL_TCF_EXAM_EPREUVES`) + `lib/api.ts` (`fullTcfExamApi`).

### Niveau TCF estimé (source unique backend, arbitré 2026-08-08)

`DashboardSummaryResponse.estimatedTcfLevel` est le **seul** endroit d'où sort ce niveau,
et il est **dérivé serveur** (`TcfProfileService`) : plancher des 4 épreuves, chacune
retenant son **meilleur** résultat, une épreuve abandonnée sans rien rendre (0 réponse /
0 soumission) étant **exclue** — détail dans le `CLAUDE.md` racine. `null` = inconnu
(afficher « — »), **jamais** « < A1 ». Cinq surfaces l'affichent : `/dashboard`, `/profil`,
`/statistiques`, `TcfHub`, `/examens-blancs` — **aucune ne le recalcule** et toutes disent
« estimé » (parité mot pour mot avec le mobile : accueil « Niveau TCF estimé », profil
« Niveau estimé »). À ne pas confondre avec `finalCecrlLevel` d'un **examen complet**
(« Meilleur niveau » / « Dernier examen » sur `/examens-blancs`), qui reste le plancher de
**cet examen-là**, épreuve abandonnée comprise.

**Le périmètre part avec le niveau.** `estimatedTcfLevelEpreuvesCounted` /
`…EpreuvesExpected` / `…Partial` (même contrat que `epreuvesCountedInFinalLevel` /
`epreuvesExpected` / `finalLevelPartial` d'un examen complet) disent sur **combien
d'épreuves sur 4** le niveau porte — sans eux, un candidat qui n'avait passé que
l'expression écrite lisait « Niveau TCF estimé : B1 » sans le moindre signal. Dérivé
serveur (`TcfLevelProfile`) : **aucun front ne recompte**. Le rendu passe par
`estimatedTcfLevelScopeLabel` (`lib/types.ts`), **une seule chaîne** — « D'après 1 épreuve
sur 4 » — affichée en petite ligne sous le niveau sur les **cinq** surfaces, et gelée en
miroir du mobile par `lib/estimated-tcf-level.test.ts`. Elle **constate un périmètre**,
elle ne reproche pas un inachèvement, et ne porte aucun chiffre de barème. 4/4 ⇒ rien ;
0/4 ⇒ le niveau vaut déjà « — », donc rien non plus.
La forme **courte** du niveau (« <A1 ») vient de `niveauCecrlShort` — `/dashboard` et
`/profil` en tenaient chacun une copie inline.

### Règle de progression (validée 2026-06-06 — source unique backend)

Toute valeur de « progression » d'un thème / d'une épreuve vient de
`GET /api/me/dashboard` (`CategoryStat.percent`, calculé dans
`UserDashboardService`) — ne jamais recalculer autrement côté front.

- **QCM** : `progression = réussite × confiance` avec
  `réussite = questions distinctes réussies / répondues` et
  `confiance = min(1, répondues / min(40, taille du pool))` (40 ≈ 2 examens
  blancs : un seul examen réussi n'affiche pas « Solide », un gros pool
  n'écrase pas la note). Null si jamais travaillée.
- **EE/EO** : `réussite = moyenne des notes /20 des 3 dernières soumissions
  évaluées ×5`, `confiance = min(1, soumissions/3)`.
- **Module** = moyenne des progressions de ses catégories (front :
  `moduleAverage`) ; **global** (`globalSuccessPercent`) = moyenne de toutes
  les catégories renseignées, calculée backend.
- Exemples : 1 examen blanc 16/20 → 80 % × 20/40 = **40 %** ; 60 répondues
  dont 48 bonnes → **80 %** ; 1 soumission EE notée 14/20 → 70 % × 1/3 =
  **23 %**.

### Règles des recommandations (validées 2026-06-06)

`/recommandations` ouvre sur **« Vos priorités »** : max 5 cards avec raison
chiffrée + CTA, dérivées côté front (`buildPriorities`) des `CategoryStat`
du dashboard + du compteur d'erreurs. Une seule reco par catégorie, dans
cet ordre :

1. **En baisse** — dernier examen < avant-dernier → Refaire un examen
2. **Point faible** — progression < 60 % avec ≥ 20 répondues (EE/EO : note
   basse) → Série ciblée / S'exercer
3. **À confirmer** — réussite brute (progression ÷ confiance) ≥ 70 % mais
   < 40 répondues → Examen blanc
4. **Jamais travaillé** — percent null, EE/EO d'abord (épreuves obligatoires
   TCF IRN) → Découvrir
5. **Erreurs** — ≥ 5 erreurs non revues → /revision

Tri : n° de règle puis progression croissante ; si rien ne matche → card
« Rien d'urgent » (CTA examen complet). En dessous : le classement complet
filtrable (Tous / TCF / Civique) reste comme détail.

### Mode guest & quotas gratuits (validés 2026-06-06)

**Guests (non connectés)** — header public aligné sur la sidebar (Accueil ·
TCF IRN · Examen civique · Examens blancs · Tarifs, cf. `SiteHeader`) ;
navigation libre des hubs et pages détail (`DualChromeShell` rend les
enfants sans sidebar quand `status !== "authenticated"`).

- **Série 1 offerte** par thème civique et par (épreuve TCF × niveau) :
  pages séries duales — lots via `publicLotApi` (`/api/public/lots`,
  `PublicLotController` backend), start anonyme via
  `publicAttemptApi.startDemo({type:"TRAINING", …, lotNumero:1})`
  (`AttemptService.startGuestLot` : attempt user NULL + clientIp, même
  fenêtre déterministe que les comptes). Série 2+ → `GuestGateSheet`
  (modal inscription, badge « Compte gratuit » via `lockedLabel`).
  Backend : lotNumero ≠ 1 sans compte → 403.
- **Examen complet 1 jouable** par module sur `/examens-blancs` (même
  grille `ModuleExamsSection`/`ExamsGrid` que les connectés, `freeSlots=1`,
  start anonyme MOCK_EXAM template free). Examens 2-20 → `GuestGateSheet`.
  Les attempts guests sont en base (user NULL + IP) → analytics « combien
  de visiteurs se testent ».
- **Examens ciblés = compte requis, pages vitrines** : les pages `*/examens`
  (civique thème + TCF CO/CE/STRUCTURE) s'affichent en guest (grille des 20
  examens, stats « — · compte requis ») mais tout slot est verrouillé
  (`freeSlots=0`, badge « Compte gratuit ») → `GuestGateSheet`. Le backend
  double le verrou (403 sur MOCK_EXAM guest themeId/moduleExamQuestionType).
  Le seul examen guest est le diagnostic complet de /examens-blancs.
  **EE/EO** : réservés aux comptes (`ModuleDetailGate`).

**URLs civique en slugs** : `/entrainement/civique/[theme]` où `theme` est le
slug dérivé du code thème (`CIV_DROITS_DEVOIRS` → `droits-devoirs`, helpers
`themeSlug`/`resolveThemeRef` dans `lib/themes.ts`). Les UUID hérités
continuent de résoudre (retours de session via `lotReturnPath`/`examReturnPath`
passent l'UUID). Liens nominaux (hubs, dashboard) émis en slug.

**Connecté gratuit, EE/EO** (source backend `ProductionSubmissionService` +
`AttemptService.startProductionAttempt`) :

- **1 essai d'entraînement** par épreuve (EE et EO) à vie (était 2).
  Annoncé par une **modale d'info one-time** (`ConfirmSheet tone="info"`,
  « Un essai gratuit par épreuve ») portée par **`ProductionSubjects`**
  (`…/tache/[n]`), mémorisée en localStorage `sejourfr.prodQuotaInfo.<épreuve>`
  et **jamais montrée à un abonné TCF**. Elle vivait sur `ProductionHub`
  (supprimé) ; elle est **sur l'écran des sujets et nulle part ailleurs** —
  c'est le seul écran de l'épreuve où la règle s'applique, et il précède
  l'écran de production qui consomme l'essai (on annonce avant, pas après un
  403). ⚠️ **Surtout pas sur l'écran d'entrée** (mode « Compétences ») : les
  micro-exercices ne verrouillent aucun sujet et ont leur **propre** quota
  (analyses IA offertes) — l'y afficher annoncerait une règle fausse.
  Décision + libellé partagés mot pour mot avec le mobile ; la règle du
  « quand » vit dans `lib/production-quota-info.ts` (pur, testé).
- **1 examen blanc production offert** (examen 1, `ProductionExams`
  `freeSlots=1`). Le start passe `exam: true`
  (`ProductionAttemptStartRequest.exam`) → attempt marqué
  `slotNumber=1` ; ses soumissions bypassent le quota d'entraînement.
- **Refaire l'examen 1** : autorisé une fois mais consomme les essais
  d'entraînement restants — `ConfirmSheet` d'avertissement avant
  (`ProductionExams`, si `past.length ≥ 1`). 3ᵉ session → 403 → paywall.
- Côté backend, une session d'examen ne compte que si ≥ 1 tâche a été
  soumise (un start abandonné est gratuit) ; à 2 sessions soumises, les
  entraînements gratuits sont verrouillés (403). Premium TCF : illimité.

- **Vague 8 (branche `web_refonte`)** ✅ — **Refonte shell app + dashboard**
  (maquette "Tableau de bord" SaaS) :
    - **Sidebar** (`AppSidebar.tsx`) recomposée : Accueil → `/` (landing
      publique), Tableau de bord, section **PARCOURS** (TCF IRN →
      `/entrainement?module=TCF`, Examen civique →
      `/entrainement?module=CIVIQUE`, Examens blancs → `/examens-blancs`),
      section **SUIVI** (Progression → `/statistiques`, Résultats →
      `/historique`, Recommandations → `/recommandations`). Item actif = fond bleu clair + barre gauche. En
      pied : badge streak ("N jours de suite", via `dashboardApi.summaryCached`)
      + carte user (avatar, nom, objectif dérivé du parcours) cliquable →
      `/profil` (le logout vit là-bas). Les entrées Mes erreurs / Favoris /
      Profil ont disparu du menu — erreurs/favoris accessibles depuis
      `/recommandations`.
    - **Chrome global masqué pour les connectés** sur les routes app :
      `shouldHideGlobalChrome` (lib/chrome-routes.ts) est actif — SiteHeader,
      Footer et MobileAppBanner retournent null quand l'utilisateur est
      authentifié sur une route (app) ou duale. Les guests gardent tout.
    - **Backend** : nouvel endpoint `GET /api/me/dashboard`
      (`UserDashboardService`) — streak jours consécutifs (Europe/Paris,
      courant + record), total examens blancs finis, réussite globale, niveau
      TCF estimé, catégories par module (5 thèmes civique + CO/CE/STRUCTURE +
      EE/EO synthétiques). Miroirs `DashboardSummaryResponse` /
      `DashboardCategoryStat` dans lib/types.ts.
    - **Composants partagés** : `ReinforceRow` + `CategoryBarLine`
      (`app/_components/ReinforceRow.tsx` + `.module.css`) utilisés par le
      dashboard et `/recommandations` ; helpers dans `lib/dashboard.ts`
      (`categoryHref`, `barTone`, `moduleAverage`, `masteryHint`,
      `categoryStatus`).
    - Pas de heatmap de régularité (décision produit) — seul le streak est
      exposé.
    - **Pages détail refondues** (maquette `sejour_fr.html`) — briques dans
      `app/_components/hub/DetailParts.tsx` + `detail.module.css` (DetailShell,
      LevelChoiceCard, SeriesProgressCard, SerieCard, DetailStatCard,
      ExamsGrid) :
        - `/entrainement/tcf/[code]` = **« Choisissez votre niveau »** (3 cards
          A2/B1/B2 avec donut = moyenne des séries faites + compteur x/y).
        - `/entrainement/tcf/[code]/[level]` et `/entrainement/civique/[themeId]`
          = **« Séries d'entraînement »** : carte de progression + grille de
          cards Série. Un lot s'affiche « Série » partout (sessions, bilan TCF)
          et fait **20 questions** (constantes `LotService.LOT_SIZE_*` backend).
          Série 1 gratuite, 2+ premium. Série faite → ExamDoneSheet
          (bilan / refaire).
        - Pages `*/examens` = **20 examens blancs** : 3 stat cards (passés,
          meilleur score, niveau estimé TCF via `cecrlLevel` ajouté au miroir
          `AttemptSummaryResponse` / restant civique) + grille de cards Examen
          (Démarrer / Refaire + Rapport / Premium). Examen 1 gratuit.
          **Démarrer / Refaire ouvre d'abord `ExamIntroSheet`**
          (`app/_components/hub/ExamIntroSheet.tsx`, bottom-sheet façon
          ConfirmSheet) qui rappelle déroulé + seuil avant le lancement réel ;
          son « Démarrer » POST l'attempt. Branchée sur les 3 surfaces
          d'examens ciblés (TCF QCM `[code]/examens`, civique `[theme]/examens`,
          EE/EO `ProductionExams`). Pour la CO, l'écran d'écoute du runner reste
          une 2ᵉ confirmation après ; côté EE/EO l'avertissement « refaire
          l'examen 1 » s'enchaîne ensuite si compte gratuit.
          **Grille indexée par slot (parité mobile, migration V110)** : TCF QCM
          et civique passent `slotNumber` au start (`StartAttemptRequest`) et
          rangent les attempts via `examSlotGrid` (`lib/exam-slots.ts`) — case N
          = examen du slot N, on garde le **plus récent** par slot. Refaire
          l'examen N met à jour la note du slot N (au lieu d'ajouter un slot
          N+1) ; les attempts sans `slotNumber` (historique d'avant V110) sont
          ignorés dans la grille (toujours visibles dans /historique). Miroir
          `AttemptSummaryResponse.slotNumber` ajouté. EE/EO restent chronos
          (le backend force `slotNumber=1` sur les sessions d'examen production).
        - Supprimés : `ExamSlotsView`, `LotRow`, `LevelRow`, `ExamHistoryList`,
          `SeeMoreButton` + styles orphelins (HubParts ne garde que
          ExamBlancHero, SectionLabel/Counter/Link, HubDetailHeader pour les
          parcours production).
    - **Parcours production EE/EO refondu** (maquette) : cards hub avec
      **S'exercer + Examens** (comme CO/CE). `ProductionHub` = « Choisissez
      votre tâche » (3 cards T1/T2/T3 façon LevelChoiceCard, donut = dernière
      note ×5, + carte historique) — l'examen blanc n'y figure plus.
      ⚠️ **`ProductionHub` est supprimé** (cf. « Entrée dans une épreuve »).
      `ProductionExams` = grille de **10 examens** (3 stat cards : passés /
      meilleure note moyenne / niveau CECRL plancher du meilleur essai ;
      Rapport → `{base}/session/{attemptId}` via `ExamsGrid.reportPath`,
      Refaire = nouvelle session, premium-only via `freeSlots=0`).
      `ProductionSubjects` = onglets **Sujets / Exemples** au design detail
      (cards niveau cible). `ExamsGrid` accepte `ExamSlotData` minimal ;
      `LevelChoiceCard.footLabel` ; HubParts réduit à SectionLabel +
      HubDetailHeader (ExamBlancHero/SectionCounter/SectionLink supprimés).
      ⚠️ **Périmé pour EE/EO** : ces écrans sont passés sur la maquette client
      (`skill-ui/`, cf. section « Parcours TCF EE/EO ») — plus de `DetailShell`,
      plus d'onglets, les exemples ont leur propre page. Le reste de la vague
      (CO/CE, civique) est inchangé.

    - **Examen blanc production EE/EO (composition déterministe + chrono)** :
      la session (`ProductionSession`) ne compose plus les 3 tâches via
      `listTasks` + premier sujet (les 10 examens étaient identiques). Elle
      lit l'**attempt** (`attemptApi.get` → `startedAt` + `timeLimitSeconds`)
      et `productionApi.getExamTasks(attemptId)`
      (`GET /api/attempts/{id}/production-exam-tasks` → exactement 3
      `ProductionTaskDto` T1/T2/T3 ordonnés, composition backend par slot).
      `ProductionExams` passe `slotNumber` (1..10) au start
      (`startAttempt({exam:true, slotNumber})`) ; la grille est **indexée par
      slot** via `bilan.slotNumber` (anciennes sessions sans slot → slot 1).
      Difficulté progressive par slot (1-3 A2 / 4-6 B1 / 7-10 B2), légende
      `bandLegend`. **Chrono d'épreuve (EE 30:00, EO 15:00)** ancré sur
      `startedAt + timeLimitSeconds` backend — c'est le backend qui l'impose
      (`AttemptService.PRODUCTION_E{E,O}_EXAM_SECONDS`, 60 s de grâce à la
      soumission), le front ne fait que l'afficher ; survit au refresh ;
      alerte rouge sous 5 min. Repli front 30 min **pour l'EE seule** quand
      `timeLimitSeconds` est null (sous-épreuve d'examen complet) ; l'EO n'a
      alors **aucun** chrono local. À 0:00 : EE auto-soumet le texte courant
      s'il est recevable (mots ∈ [`motsMin`, `motsMax`] strictement : T1
      30–60, T2/T3 40–90 ; règle partagée `lib/ee-word-bounds.ts`), EO coupe la
      capture en cours et l'envoie en best-effort (`timeoutSignal` /
      `onTimeout` sur `EoRecordingForm`, pendant de `autoSubmitSignal` /
      `onAutoSubmit` côté EE) ; puis `attemptApi.finish` puis bilan.
      **EO en examen** (`EoRecordingForm examMode`) : en plus du chrono
      d'épreuve, décompte par tâche (`dureeMaxSec`), auto-stop à 0, soumission
      immédiate au stop (pas de réécoute). **Une tâche rendue ne se refait pas
      en session d'examen** (règle backend `ProductionAccessService`) : la
      tâche courante est toujours `TACHES.find(n => !subs.has(n))`, le bouton
      micro est désactivé après le stop et « Refaire » n'existe qu'hors examen ;
      relancer l'évaluation IA d'une soumission (`retrySubmission`) reste
      légitime. Fin normale (T3) et abandon (navigation sortante) →
      `attemptApi.finish`. `ProductionBilanResponse` gagne `slotNumber` +
      `finished` : en `finished` avec < 3 tâches évaluées, le bilan affiche
      « Non rendue » (pas de polling infini) et le niveau global dès qu'il
      arrive. Examen TCF complet : même endpoint `getExamTasks`, EE à 0:00 →
      `fullTcfExamApi.markSubDone(TCF_EE)` + retour au hub.
    - **`/historique` refondu** : « Mes résultats » — 3 stat cards (examens
      passés ce mois-ci, score moyen, meilleur score), filtres Tous / TCF
      IRN / Examen civique, lignes d'examens blancs finis (icône catégorie,
      date + durée, badge CECRL, score coloré + % + mini-barre) → rapport ;
      bouton « Refaire » relance le même examen (template / thème / épreuve,
      paywall si non-abonné). Trainings et productions n'y figurent plus
      (les séries vivent sur leurs pages, EE/EO sur leurs historiques).
      `ProductionMobileSheet` supprimé (orphelin).
    - **`/statistiques` refondu** : « Ma progression » — 3 cards donut
      (maîtrise globale / TCF avec niveau estimé / civique) + une section par
      parcours listant chaque catégorie (icône, « n examens · record x/y »,
      barre de réussite, **tendance dernier vs avant-dernier examen** ↗/↘/—,
      badge Solide/En bonne voie/À renforcer). Ligne → entraînement de la
      catégorie (`categoryHref`). Données : `GET /api/me/dashboard` étendu
      (`CategoryStat.bestMockScore`/`lastMockScore`/`prevMockScore`).
      L'ancien écran stats par thème avec toggle module est supprimé.
    - **`/examens-blancs` refondu** (connecté) : « Examens blancs complets » —
      **toggle segmenté `ModuleToggle` en tête (TCF IRN / Examen civique, 2
      boutons demi-largeur)** : on n'affiche QUE le parcours sélectionné (état
      local `active`, défaut TCF), plus d'empilement vertical des 2 cards.
      Chaque parcours = une `ModuleExamsSection` avec, sous le header, une
      rangée de **3 stat cards** (`StatItem`) + des **tips chips** (`tips`,
      remplacent l'ancienne phrase `brewLine`). TCF abonné → Meilleur niveau /
      Dernier examen / Niveau estimé (CECRL) ; TCF gratuit → Meilleur score /
      Dernier examen (/499 calibré ou /50) / Niveau estimé ; Civique → Meilleur
      score / Dernier examen (/40) / Progression %. Niveau estimé + progression
      viennent de `dashboardApi.summaryCached()` (`estimatedTcfLevel`,
      `moduleAverage(summary.civique)`) ; meilleur/dernier des attempts déjà
      chargés (helpers `bestScored`/`bestTcfScore`/`mostRecent`). Grille de
      20 épreuves **repliée à 8 + « Voir tout »** (`ExamsGrid` props
      `collapsedCount`/`itemLabel`). Épreuve 1 gratuite, 2+ premium.
      **Démarrer/Refaire passe par la page briefing du template de
      référence** (`/examens-blancs/tcf-mix-01` et
      `/examens-blancs/civique-decouverte`) qui crée l'attempt ; le déroulé
      TCF du briefing pointe EE/EO vers leurs examens web (plus de mention
      « app mobile »). Les sous-routes `/examens-blancs/civique|tcf` et
      `ExamsModuleView` sont supprimées. Page démo guest inchangée. Miroir
      `AttemptSummaryResponse` complété (`moduleExamQuestionType`,
      `lotThemeId`).
      **Grille indexée par slot (V110)** : les 3 grilles (TCF complet,
      diagnostic TCF gratuit, civique) sont rangées par `slotNumber` via
      `examSlotGrid` — refaire l'examen N met à jour la case N au lieu d'en
      empiler une nouvelle. **Backend** : `startFromTemplate` honore désormais
      `req.slotNumber()` (avant, la branche template court-circuitait
      l'assignation du slot). Attempts sans slot (avant V110) absents de la
      grille, visibles dans /historique.
      **Lancement civique = modale inline** (`ExamIntroSheet`, comme le full
      exam TCF) : Démarrer/Refaire ouvre la modale (déroulé + seuil, facts du
      template `civique-decouverte` chargé une fois) puis `attemptApi.start`
      (template + `slotNumber`) → `/sessions/[id]`. Plus de navigation vers la
      page briefing pour le civique connecté. Le diagnostic TCF gratuit, lui,
      passe encore par la page briefing via `?slot=N` (`[slug]/page.tsx` lit
      `searchParams`, `ExamBriefingClient` repasse `slotNumber`) ; le full exam
      TCF garde `TcfFullExamBriefingSheet` (`fullTcfExamApi.start(slot)`). La
      page briefing reste utilisée par les guests (démo civique/TCF).
    - **Rapport d'examen / de série refondu** (`ExamReport.tsx`) : hero teinté
      vert/rouge (donut bonnes réponses, « Vous avez obtenu X% », Score /
      Temps / Niveau estimé TCF ou Seuil civique), **« Réussite par
      sous-thème » uniquement quand l'attempt couvre ≥ 2 thèmes** (examens
      complets — jamais sur les examens scopés à un thème/épreuve),
      « Et maintenant ? » (point à renforcer + Refaire via `onRetry` posé par
      la page session, Autres examens/séries, Voir ma progression), corrigé
      détaillé en accordéon filtrable. Prop `embedded` = corrigé seul (bilan
      série TCF). `TcfScoreCard` supprimé (le hero porte score + niveau) ;
      miroir `AttemptResponse` enrichi (`calibratedScore`, `cecrlLevel`).
    - **Hubs TCF / Civique refondus** (maquette `sejour_fr.html`) :
      `TcfHub`/`CiviqueHub` = header eyebrow + bande de 4 stats (maîtrise,
      catégories, examens blancs du module, niveau estimé) + grille de cards
      catégorie (icône, donut teinté Solide/En bonne voie/À renforcer, chips
      de contenus, badge statut + nb d'examens, CTAs S'entraîner / Examen
      blanc — EE/EO : S'exercer). Briques dans
      `app/_components/hub/ModuleHubParts.tsx` + `moduleHub.module.css`.
      Données : `GET /api/me/dashboard` (étendu : `civiqueMockExams`,
      `tcfMockExams`, `CategoryStat.mockExams`) ; guests → cards sans stats
      via `publicThemeApi`. Les heros examen blanc / carte CECRL / carte
      maîtrise de la vague 6 sont supprimés des hubs (l'entrée examens vit
      dans la sidebar) ; `HubHeader`, `EpreuveCard`, `CiviqueMasteryCard`
      retirés de `HubParts.tsx` (le reste sert toujours aux pages détail).

- **Vague 7** ✅ — **Productions IA web : Expression écrite (EE) + orale (EO)**,
  parité mobile (`screens/tcf_production/*`). Les cartes EE et EO du `TcfHub`
  ouvrent `/entrainement/tcf/ee` et `/entrainement/tcf/eo`.
  - **Architecture générique** : un seul jeu de composants `Production*` piloté par
    une `ProductionConfig` (`app/_components/production/config.ts` : `EE_CONFIG` /
    `EO_CONFIG` — `epreuve`, `base`, `mode` text/audio, `accent`, `inputSegment`).
    Les routes (`tcf/ee/*` et `tcf/eo/*`) sont de **fines enveloppes** rendant
    `<ProductionSubjects|InputPage|Results|Exams|Session|History config={…} />`
    (la racine `tcf/{ee,eo}` ne rend rien : elle **redirige**, cf. « Entrée dans
    une épreuve »).
    Seul l'input diffère selon `mode` : `EeWritingForm` (texte, compteur de mots +
    brouillon localStorage) vs `EoRecordingForm` (micro `MediaRecorder` → blob,
    chrono + durée cible, réécoute/refaire).
  - **Endpoints** (aucun changement backend hors fix ci-dessous) : `productionApi`
    dans `lib/api.ts` — `startAttempt` (`POST /api/attempts/production`), `listTasks`
    / `getTask` / `listExamples`, `submitText` (JSON, EE) / `submitAudio` (multipart,
    EO), `getSubmission` (polling, EO passe par `TRANSCRIBING`), `retrySubmission`,
    `listMine`, `lastPerTask`. **Tout est authentifié** (le catalogue n'est PAS sous
    `/api/public/**`).
  - **Types** `lib/types.ts` : `ProductionTaskDto`, `ProductionSubmissionDto`,
    `EvaluationResultDto`, `ProductionExampleDto`, `SubmissionStatut`, `NiveauCecrl`
    + helpers (`productionTaskTitle/Subtitle(epreuve,n)`, `niveauCecrlLabel`,
    `cecrlIndex`, `formatDurationSec`, `resolveTcfLevel`, `parseEeFeedback`).
  - **Composants partagés** `app/_components/production/` : `ProductionFeedbackView`
    (orchestre les 6 blocs de l'écran de résultat, cf. section dédiée) avec
    `ProductionObjectiveBanner`, `ProductionScoreHero` (note + échelle TCF),
    `EvaluationNotice` (la note « à savoir ») ;
    `ProductionCriteriaCard` (les 4 critères annoncés avant de produire),
    `SubmissionRow`, `EeWritingForm`, `EoRecordingForm` + `production.module.css`.
  - **Retour visuel de la capture EO** — `RecordingLevelMeter` (même dossier),
    monté par `EoRecordingForm` pendant `phase === "recording"`, donc **par les
    quatre parcours qui passent par ce formulaire** : production EO, examen blanc
    EO (`examMode`), micro-exercice de compétence, oral du diagnostic. Il rend la
    pastille « Enregistrement… » à **point pulsant**, une forme d'onde de 33
    barres et l'aveu « On ne vous entend pas… » (libellé gelé, miroir mot pour mot
    de `_VoiceHint` côté mobile) après **3 s** sans voix — une pause pour chercher
    ses mots est normale.
    ⚠️ **Le mouvement suit la voix, il ne la simule pas** : le niveau vient d'un
    `AnalyserNode` branché sur le `MediaStream` du `MediaRecorder`
    (`getByteTimeDomainData` → RMS → dBFS → mêmes `NOISE_FLOOR` / `VOICE_CEILING`
    / `AUDIBLE_LEVEL` que `recording_waveform.dart`). Une animation décorative à
    amplitude fixe rendrait un micro muet indiscernable d'un enregistrement qui
    marche — le vrai symptôme rapporté. Plancher de mouvement conservé : une
    forme d'onde figée se lit comme une page plantée.
    Contraintes techniques à ne pas relâcher : horloge **monotone**
    (`performance.now()`), **aucun `setState` par frame** (écriture directe de
    `transform: scaleY()` sur des `ref`, `setState` seulement à la bascule du
    verdict), `AudioContext.resume()` au démarrage (le geste utilisateur est
    acquis, le contexte peut naître `suspended`), et **fermeture de
    l'`AudioContext` + `cancelAnimationFrame` au démontage comme à l'arrêt** —
    `EoRecordingForm` remet `micStream` à `null` dans `onstop`, sinon on fuirait
    un contexte audio par enregistrement.
  - **Gating** (source backend) : entraînement par tâche = **2 essais gratuits à
    vie** par épreuve pour non-abonnés (403 au-delà → `PaywallSheet` Intégral) ;
    examen blanc 3-tâches = **premium-only**. Premium TCF (Intégral) = illimité.
  - **Fix backend lié** : `ProductionTaskManager.findActive` filtrait mal par
    `tacheNumero` seul (sans niveau) → renvoyait toute l'épreuve. Branche ajoutée +
    query `findByEpreuveAndTacheNumeroAndActiveTrueOrderByNiveauCibleAscCreatedAtAsc`.

## Parcours TCF EE/EO — briques partagées `app/_components/skill-ui/`

**Tout le parcours productif suit la maquette client**
(`docs/skills/sejourfr_expression_ecrite_v3_competences.html`), « de la page
d'accueil de l'épreuve jusqu'au terminus » : écran de tâche,
réponses-modèles, exercice, résultat, examens blancs, historique — **et** le
sous-module Compétences. Ce n'est plus un habillage local : les briques vivent
dans `skill-ui/` et **aucun écran ne les recopie**.

- `skill-ui/SkillLayout.tsx` : `SkillShell`, `SkillAccent`, `SkillHero`,
  `SkillModeTabs`, `ParcoursHero`, `ParcoursNextCard`, `TaskCards`, `ExamTrail`,
  `SkillRing`, `SectionHead`, `SkillNotice`, `MiniBar`, `RowChevron`,
  `SkillBadge`, `SkillRowCard`, `SkillFilterRow`.
- `production/ParcoursTop.tsx` (**2026-08-09**) : la **tête commune** aux trois
  modes (héros chiffré, « Prochain entraînement », barre des modes, sélecteur de
  tâche), plus `useParcoursLevel` et `PRODUCTION_EXAM_SLOTS`.
- `skill-ui/skill.module.css` : la géométrie de la maquette (rayons, paddings,
  grilles, graisses, survols) avec **les couleurs de l'application**. Un
  `grep -nE "#[0-9a-fA-F]{3,8}"` sur `production/`, `competences/` et
  `skill-ui/` doit **rester vide** — `white` / `color-mix()`, jamais un hex.
- **Un seul accent, `--skill-accent`** — et depuis le 2026-08-09 il vaut le
  **bleu pour les deux épreuves** (cf. ci-dessous). Il est posé par `SkillShell`
  **ou** par `SkillAccent`, qui existe précisément pour les blocs rendus hors
  colonne : `EeWritingForm` / `EoRecordingForm` sont réutilisés par
  `ProductionSession` (examen blanc) et par `CompetencePrompt`, qui n'ont pas le
  même conteneur.
- **Le parcours est strictement identique en EE et en EO** : mêmes écrans, même
  structure, même ordre. Seule la **zone de production** (saisie vs
  enregistreur) change.

### ⚠️ Les DEUX épreuves sont BLEUES (décision client 2026-08-09)

`ProductionConfig` n'a **plus de champ `accent`** : l'expression orale n'est plus
rouge, et le rouge redevient ce que `docs/identite-visuelle.md` prévoit — CTA
critiques et signaux d'urgence, rien d'autre. Deux épreuves du même module qui
se peignent différemment se lisent comme deux produits.

Ce qui distingue l'écrit de l'oral, déclaré une seule fois dans `config.ts` :
le **titre** (`label`), le sous-titre d'épreuve (`epreuveMeta`), le
**pictogramme** (dérivé de `mode` : stylo / micro) et le **verbe**
(`actionVerb` : « Rédiger » / « Enregistrer »). `TcfHub` aligne la vignette EO
sur celle de EE (`iconTone: "slate"`). Miroir mobile : `TcfProductionModule`.

### Structure du parcours — maquettes client (2026-08-09)

Les trois modes partagent une **tête commune**, `ParcoursTop`, reprise des trois
maquettes fournies par le propriétaire :

1. **en-tête de parcours** — `SkillShell` avec `title` / `meta` / `level` :
   flèche de retour, nom de l'épreuve, `epreuveMeta`, et à droite le badge
   « NIVEAU VISÉ » + le palier de la démarche (`niveauViseTcf`). L'eyebrow dit
   « visé » en toutes lettres : ce n'est **pas** le niveau estimé du candidat,
   et le repo interdit d'afficher un niveau sans le qualifier. Sans `title`,
   `SkillShell` garde le lien de retour historique (modèles, historique) ;
2. **`ParcoursHero`** : anneau + trois colonnes chiffrées (Score moyen `/20`,
   Examens blancs `/10`, Sujets traités `/N`) + « Progression du parcours » ;
3. **`ParcoursNextCard`** : la prochaine compétence non terminée, « Tâche N ·
   <titre> » + « Continuer ». Rien à faire ⇒ **aucune carte** ;
4. **`SkillModeTabs`** : barre segmentée **dans le flux**, sous la carte
   « Prochain entraînement ». L'ancienne `SkillModeBar` flottante en bas est
   **supprimée** — elle masquait le dernier élément de chaque liste, imposait
   118 px de réserve en pied de colonne (`.wrapBar`) et faisait doublon avec la
   barre latérale de l'application au-delà de 900 px ;
5. **`TaskCards`** : trois cartes « 1 · Message · 30-60 mots », qui remplacent
   `TaskPills` (**supprimé**). Absentes de la grille d'examens blancs, portée
   par l'épreuve entière. `onPick` les garde en **filtre local** (URL réécrite
   en navigation superficielle) ; les clics modifiés restent natifs.

Sans `taskNumero` (grille d'examens blancs), « Sujets » comme « Compétences »
retombent sur la **tâche 1** : une destination par défaut, **jamais un chiffre
affiché** qui serait faux.

⚠️ **Conséquence assumée sur les appels** : `ParcoursTop` lit les trois sources
d'épreuve (`productionTasksKey`, `productionMineKey`, `skillsSectionKey`) — mais
**sous les mêmes clés de cache** que les écrans, donc un aller-retour entre les
modes ne coûte toujours **aucun appel de plus** (`lib/parcours-tcf-navigation.test.ts`).

`SkillStats` est **supprimé** : ses trois cartes redisaient ce que le héros
affiche déjà. La grille des examens blancs ouvre sur `ExamTrail`
(« Parcours examens blancs · 1/10 »), qui porte aussi le niveau estimé.

**Une ligne de compétence** porte un `SkillRing` « 2/5 » + l'état en clair
(« 2 réussis · 3 restants ») ; **une carte de sujet** porte sa contrainte et sa
tâche — le palier a quitté la carte, il est annoncé une fois par le badge de
l'en-tête.

**Libellés gelés partagés avec le mobile** (chaque front en tient une copie
écrite à la main, un test par couche sur exactement les mêmes chaînes) :
`productionTaskShortTitle`, `productionTaskConstraint` et
`productionSubjectTitle` (`lib/types.ts` ⇄ `widgets/production_common.dart`),
`competenceProgressLabel` (`lib/skill-progress.ts` ⇄
`competences/widgets/competence_card.dart`).

**Le titre d'une carte de sujet vient de la base** : `ProductionTaskDto.titre`
(colonne `production_tasks.titre`, V028, contenu V754), éditable en console
admin. Il est **nullable** — contenu antérieur, sujet créé sans titre — et le
repli est `productionSubjectTitle(titre, ordre)` → « Sujet N », **jamais** un
titre vide ni un placeholder ; la consigne reste affichée dessous dans les deux
cas. Ne pas réécrire ce repli dans un composant.

### Navigation fluide : un seul appel, pas de remontage (parité mobile)

Constat client (fait sur le mobile, le web avait le même défaut) : *« quand on
change de Compétences / Sujets / Examens, ou de Tâche 1 / 2 / 3, j'ai
l'impression qu'il y a un appel au back, un changement d'écran lourd »*. Chaque
mode et chaque tâche étant une **route**, la bascule remontait la page et
relançait les `fetch`. Trois décisions, dans l'ordre du moins coûteux au plus :

1. **Cache mémoire maison, `lib/data-cache.ts`** (aucune dépendance ajoutée : le
   projet n'a pas de librairie de cache de données et n'en prend pas une pour
   ça). Une `Map`, un dédoublonnage des chargements en vol, un `peek` synchrone
   — c'est lui qui supprime le squelette au retour sur un écran déjà visité — et
   une invalidation **par préfixe**. Rien n'expire tout seul, une erreur n'est
   jamais mise en cache, et le singleton est **inerte au rendu serveur** (une
   `Map` de module y serait partagée entre utilisateurs). Vidé par
   `tokenStorage.clear()`.
2. **Un loader par donnée, `lib/skill-catalog.ts` et `lib/production-catalog.ts`**
   (purs, clients injectés, testés). Ils portent la clé de cache **et** le
   regroupement des appels :
   - `loadSectionSkills` → `GET /api/skills?section=EE|EO`, **les 24 compétences
     de l'épreuve en un appel** (repli : les 3 appels `taskCode`, une fois, sous
     la même clé — les écrans n'ont qu'un contrat, « la liste, c'est l'épreuve ») ;
   - `loadEpreuveTasks` → `GET /api/production-tasks?epreuve=` **sans**
     `tacheNumero` : les 3 tâches en un appel ;
   - `loadMySubmissions` → **une seule** entrée `production:mine:<épreuve>`
     partagée par l'écran des sujets et la grille des examens blancs
     (`limit=100`, le défaut backend de 20 ne suffisait pas à la grille) ;
   - `loadBilan` → mis en cache **seulement si le bilan est final**
     (`finished` **et** 3 tâches évaluées) : sinon l'IA travaille encore et rien
     n'invaliderait une note figée trop tôt.
3. **Le sélecteur de tâche est un filtre**, plus une navigation :
   `TaskCards` accepte `onPick` (le clic simple est intercepté, les clics
   modifiés gardent « ouvrir dans un nouvel onglet »), l'écran filtre localement
   et **réécrit l'URL en navigation superficielle** (`replaceUrlShallow`,
   `lib/shallow-url.ts` → `window.history.replaceState`, API native supportée
   par l'App Router). Une tâche reste donc une adresse partageable et ouvrable
   directement ; `replaceState` et non `pushState` parce que **filtrer n'est pas
   naviguer** — sinon il faudrait trois « précédent » pour sortir de l'épreuve.
   Les écrans lisent `pickedTask ?? routeTask` : le choix local l'emporte, mais
   l'URL décide toujours de la tâche d'arrivée.

Les six routes `…/tache/[n]{,/competences,/exemples}` déclarent
`generateStaticParams` (`PRODUCTION_TASK_PARAMS`) : prérendues, elles sont
préchargées par les liens de la barre de modes, donc **une bascule de mode ne
redemande plus rien**, ni au backend ni au serveur Next.

**Ce qui reste frais — le piège de ce cache.** Le catalogue est éditorial, la
**progression** ne l'est pas. Toute écriture invalide, **à la source dans
`lib/api.ts`** (jamais dans un écran, qui finirait par l'oublier) :
soumission / relance d'évaluation de production et **fin de polling**
(`EVALUATED`/`FAILED`, c'est là que la note apparaît) → `production:mine:` +
`production:bilan:` ; production ou analyse de compétence → tout `skills:`.
Un écran qui ajoute une lecture met sa clé sous ces préfixes, sinon il affichera
une progression mensongère.

**Vérifié par les tests** (`npm test`, runner natif de Node) : un client factice
**compte les appels**. `lib/parcours-tcf-navigation.test.ts` rejoue les deux
parcours du constat client — T1 → T2 → T1 (**2 appels à l'arrivée, 0 ensuite**,
au lieu de 2 par tâche) et le tour des trois modes (**5 appels au premier tour,
0 au second**, au lieu de 5 par tour) — et vérifie qu'après une soumission
l'historique, **et lui seul**, est rechargé.

### Entrée dans une épreuve : pas d'écran d'accueil

Demande client : « dès qu'on vient du menu Réviser → EO ou EE, on arrive
directement sur l'écran comme celui du template ». On ouvre donc l'**espace de
travail** — le mode « Compétences » de la **tâche 1**,
`…/tache/1/competences` — et on change de tâche par les pastilles T1/T2/T3, de
mode par la barre Compétences · Sujets · Examens.

- **Destination déclarée une seule fois** : `PRODUCTION_ENTRY_SUFFIX` /
  `productionEntryHref(base)` dans `production/config.ts`. `TcfHub` s'en sert
  pour les cards EE/EO ; les **routes `…/tcf/{ee,eo}` restent servies en
  `redirect()`**, parce qu'elles sont référencées ailleurs (`lib/dashboard.ts`
  `categoryHref`, landing `/reussir`, `?back=`, historiques d'URL). Une
  redirection n'est pas du code mort — c'est ce qui permet de déplacer l'entrée
  sans repasser sur tous les appelants.
- **`ProductionHub` est supprimé** (cartes T1/T2/T3 + historique récent +
  modale de quota). Son écran parent, le hub TCF, est la nouvelle destination de
  tout retour arrière qui sort de l'épreuve : `TCF_HUB_HREF` / `TCF_HUB_LABEL`
  (mêmes constantes, même fichier). Ne **jamais** faire pointer un retour sur
  `config.base` : la redirection ramènerait sur l'espace Compétences, donc en
  boucle depuis Sujets.
- **Conséquence non traitée** : `ProductionHistory` (`…/historique`) n'a plus
  de point d'entrée — le client a demandé d'oublier l'historique « pour
  l'instant ». La page et sa route existent toujours, joignables seulement par
  URL directe.

### Les « Exemples » ne sont pas un mode

La barre n'a que trois entrées. Les réponses-modèles sont une **ressource
d'appoint** : lien discret en tête de la liste des sujets → page dédiée
`…/tache/[n]/exemples` (`ProductionExamples`). En faire un onglet mettait sur le
même plan « je produis » et « je lis un modèle ». L'appel
`productionApi.listExamples` est inchangé — c'est le point d'entrée qui bouge.

### Écrans repris et invariants conservés

`ProductionSubjects` (hero, pastilles de tâche, filtres Tous/À faire/Traités
avec compteurs, cartes de sujet à liseré de statut), `ProductionExamples`,
`ProductionInputPage` + le chrome de `EeWritingForm`/`EoRecordingForm` (carte
d'exercice : badge de contrainte, palier, titre d'intention, consigne, contexte,
chips de format, zone de production, compteur flottant, actions),
`ProductionResults` (le rapport, puis les actions — l'accusé de traitement a
disparu, cf. « rapport express »), `ProductionExams` (hero, 3 indicateurs, packs d'examen),
`ProductionHistory`.

- **Aucun contrat d'API n'a changé, aucun endpoint n'a été ajouté.** Une donnée
  que les DTO ne portent pas n'est pas affichée : à l'oral, l'écho de la
  production est la **transcription** — `ProductionSubmissionDto` n'expose pas
  d'URL audio (contrairement à `SkillAttemptDto`), donc pas de lecteur inventé.
- **Les règles de lecture de `ProductionFeedbackView` ne bougent pas** (niveau ⇒
  confiance, confiance haute muette, bande et non note par critère, échelle du
  TCF affichée avec la note) : ce sont des décisions de **notation**. Sa **mise
  en page**, elle, a été refondue — cf. « rapport express ».
- Les props ajoutées aux formulaires partagés (`exerciseTitle`) sont
  **optionnelles**, comportement actuel par défaut — `ProductionSession` (chrono,
  auto-soumission, `examMode`, `timeoutSignal`) et le parcours d'examen TCF
  complet sont inchangés.
- `production.module.css` a perdu ~440 lignes devenues mortes (carte de
  consigne, textarea, lignes de liste, cartes d'exemple, chrono, légende de
  bandes) : la refonte supprime l'ancien, elle ne le laisse pas cohabiter.

## Compétences TCF — micro-exercices EE/EO

Troisième espace d'une tâche productive, **à côté** des sujets TCF complets et
des exemples (spec `docs/skills/SEJOURFR_SPEC_COMPETENCES_EE_EO.md`, contrat
gelé partagé backend/mobile/admin). Un petit sujet entraîne **un seul critère**,
pas une copie entière : 6 tâches × 8 compétences × 15 sujets, chacun livré avec
3 productions de référence.

**Ce n'est pas la voie de notation des productions.** Un micro-exercice n'a
**ni note /20 ni niveau CECRL** (interdit par le §9 de la spec — quinze mots ne
situent personne sur l'échelle du TCF) : le seul verdict est
`SkillCriterionStatus` (`VALIDATED | PARTIAL | NOT_VALIDATED`) sur le critère du
sujet. Ne jamais réintroduire `ProductionScoreHero`/`formatNoteSur20` ici.

- **Point d'entrée** : 3ᵉ onglet « Compétences » de `ProductionSubjects`
  (`Sujets | Compétences | Exemples`) — il **pousse** vers
  `…/tache/[n]/competences`, ce n'est pas un état d'onglet local.
- **Routes** (wrappers minces injectant `EE_CONFIG`/`EO_CONFIG`, comme toutes
  les pages production), sous `/entrainement/tcf/{ee,eo}/tache/[n]/competences` :
  `/` (les 8 compétences) · `/[skillId]` (15 sujets + filtres) ·
  `/[skillId]/[promptId]` (production) ·
  `/[skillId]/[promptId]/resultat/[attemptId]` (retour + références).
- **Composants** `app/_components/competences/` : `CompetencesList`,
  `CompetenceDetail`, `CompetencePrompt`, `CompetenceResult`,
  `CompetenceReferences`, `CompetenceStatusBadge`, plus les 4 blocs du retour v3
  (`CompetenceLevelCard`, plus les blocs **partagés** du plan d'action —
  `skill-ui/ActionPlan.tsx`). (`SelfEvaluationPicker` a été
  **supprimé** — cf. « Allègements », plus bas.)
  Les briques de mise en page et leur feuille de style ont été **promues en
  partagé** dans `app/_components/skill-ui/` (`SkillLayout.tsx` +
  `skill.module.css`) quand tout le parcours TCF est passé sur la même
  maquette — cf. la section « Parcours TCF EE/EO » ci-dessus.
- **Le module suit la maquette client**
  (`docs/skills/sejourfr_expression_ecrite_v3_competences.html`) et **pas** les
  briques génériques `DetailShell` / `hub.hub` — c'est une demande explicite du
  client, avec **sa navigation** : hero en dégradé porteur de la progression de
  toute la tâche, pastilles T1/T2/T3 pour changer de tâche sans revenir en
  arrière, intertitres de section, encart « Principe pédagogique ».
  `skill-ui/SkillLayout.tsx` porte ces briques partagées — les quatre écrans du
  module les consomment comme le reste du parcours, aucun ne les recopie. **La barre d'onglets du
  haut de la maquette (« Compétences | Sujets TCF | Examens ») n'est PAS
  reproduite** : cette navigation existe déjà dans l'application, la maquette la
  duplique parce qu'elle est autonome.
  - **Géométrie de la maquette, couleurs de l'application.** Rayons, paddings,
    grilles, graisses et survols viennent de la maquette ; les couleurs restent
    `var(--color-*)`. Un `grep -nE "#[0-9a-fA-F]{3,8}"` sur les fichiers du
    module doit **rester vide** — utiliser `white` / `color-mix()` plutôt qu'un
    hex, y compris pour les blancs translucides du hero.
  - **Un seul accent, `--skill-accent`**, posé par `SkillShell` selon
    `config.accent` (bleu à l'écrit, rouge à l'oral) : aucune brique du module
    ne choisit sa couleur. Les internes des formulaires partagés
    (`production.module.css`) restent bleus — ils appartiennent aussi aux écrans
    de production TCF, les retinter est une décision sur **ces** écrans.
  - **Même largeur de colonne (880 px) sur les quatre écrans** : la colonne ne
    doit plus rétrécir au milieu du parcours.
  - Tokens ajoutés à `globals.css` pour ce module : `--color-amber-dark`
    (ambre **lisible en texte** ; `--color-amber` est un ambre de remplissage,
    illisible sur blanc), `--gradient-hero-blue` / `--gradient-hero-red` (2ᵉ
    butée dérivée de la couleur de marque par `color-mix`, aucune teinte
    nouvelle) et `--gradient-ink-blue` (bandeau d'analyse IA).
- **Progression : calculée côté client, dans `lib/skill-progress.ts`** (pur,
  testé par `skill-progress.test.ts`). Aucun endpoint ne sert « sujets traités »
  prêt à afficher : le hero somme les 8 compétences de
  `GET /api/skills?taskCode=`, et la barre « Progression de la compétence » de
  l'écran d'un sujet retrouve sa compétence dans cette même liste. Ne pas
  refaire la division dans un JSX — deux écrans finiraient par afficher deux
  pourcentages pour la même tâche.
- **Types** `lib/types.ts` (section COMPÉTENCES) : `SkillDto`, `SkillDetailDto`,
  `SkillPromptDto`, `SkillPromptSummaryDto`, `SkillReferenceDto`,
  `SkillAttemptDto`, `SkillAnalysisDto` (+ `SkillLevelProgressDto`,
  `SkillNiveauViseDto`, `SkillLevierDto`, `SkillExempleCibleDto`,
  `SkillSegmentDto`, `SkillARetenirDto`, `SituationNiveauVise`),
  `SkillAnalysisQuotaDto` + les enums et
  les tables de libellés FR (`SKILL_PROMPT_STATUS_LABEL`,
  `SKILL_SELF_EVALUATION_LABEL`, `SKILL_REFERENCE_LEVEL_LABEL`,
  `SKILL_SITUATION_NIVEAU_VISE_LABEL`) — **libellés
  gelés par le contrat, à ne pas reformuler**. ⚠️ `SkillAnalysisDto` porte
  **deux générations de champs** (v1/v2 `successPoint`/`improvementPriority`/
  `improvedVersion`, v3 `strengthTag`/`focusTag`/`levelProgress`/`niveauVise`),
  **toutes nullables et sans migration** : afficher ce qu'on trouve, ne jamais
  supposer un champ présent. ⚠️ `SkillDifficulty`
  (`EASY|MEDIUM|HARD`) est le **vrai** `enums.Difficulty` Java ; le `Difficulty`
  historique de ce fichier encode un niveau de cible (CSP/CR/NAT/A2/B1/B2) et
  n'a rien à voir. Client : namespace `skillApi` dans `lib/api.ts`.
- **Statut d'un sujet** : `TODO | TREATED | VALIDATED | TO_REINFORCE`, **dérivé
  par le backend**, jamais recalculé côté front. `TREATED` (« Fait ») est l'état
  d'une production enregistrée **sans** analyse IA — sans verdict de critère,
  « Validé » comme « À renforcer » seraient tous les deux faux. Les quatre
  statuts se distinguent par couleur **et** icône **et** libellé, plus un liseré
  vertical sur la carte de sujet.

### Le candidat est TUTOYÉ dans tout le module (décision client)

Règle de langue du module « Compétences », des deux côtés (web ⇄ mobile), à ne
pas laisser redériver.

- **Périmètre : le chrome, et rien d'autre** — titres de cartes, libellés de
  champs, boutons, aides, messages d'état, d'erreur et d'encouragement.
  « Votre réponse » → « **Ta réponse** », « Votre ressenti » → « **Ton
  ressenti** », « Comparez avec les niveaux de référence » → « **Compare**
  avec… », « Rédigez votre réponse ici… » → « **Écris ta réponse ici…** ».
  Conjugaisons, accords et pronoms suivent : « vous pouvez » → « tu peux »,
  « Décochez » → « Décoche ».
- **Ce qui ne change PAS : le texte des sujets** (`context`, `instruction`,
  `uniqueCriterion`, les 3 références, `checklist`, `tip`, `answerStarter`). Il
  vient de la base et reproduit une situation d'examen TCF, où l'énoncé vouvoie
  (« Vous partez trois jours… »). Le retoucher demanderait de régénérer les 240
  sujets et les rendrait moins fidèles à l'épreuve. Une passe éditoriale à part,
  à demander explicitement.
- **Ce qui ne change pas non plus : les écrans hors module.** Les sujets TCF
  complets, la session d'examen blanc production et `ProductionResults`
  vouvoient toujours. C'est pourquoi les formulaires partagés
  (`EeWritingForm`, `EoRecordingForm`, `EoTranscriptNotice`) reçoivent une prop
  **`voice`** (`ProductionVoice`, dans `production/config.ts`) qui vaut
  `"vouvoiement"` par défaut : le module pose `"tutoiement"`, personne d'autre.
  **Ne jamais tutoyer en dur dans un fichier partagé.**
- **Relecture** : `grep -rniE "vous |votre |vos |-vous" app/_components/competences/
  app/_components/skill-ui/` doit rester vide, hors commentaires nommant des
  écrans de production TCF. Un tutoiement à moitié appliqué est pire que pas de
  tutoiement.

### Plafonds durs de production (400 mots / 180 s)

`SKILL_ANALYSIS_MAX_WORDS` et `SKILL_ANALYSIS_MAX_AUDIO_SEC`
(`lib/skill-guidance.ts`, figés par `skill-guidance.test.ts`) recopient les
gardes **serveur** `sejourfr.competences.analysis.*`. Au-delà, la soumission est
refusée et la production est perdue — donc :

- l'écrit **annonce** la limite au-dessus du bouton de validation (avertissement,
  pas blocage) ;
- l'oral **borne la capture** (`maxDurationSec`), au lieu d'envoyer un fichier
  qui sera refusé ; le candidat garde sa prise, la réécoute, la refait ou
  l'envoie.

Ils ne remplacent pas `recommendedMinWords` / `recommendedMaxWords` /
`recommendedDurationSeconds`, qui restent **conseillés et non bloquants** (spec
§8 règle 15). ⚠️ Aucun DTO ne les publie : ce sont des réglages serveur
recopiés dans les deux fronts, qui divergeront à la première modification
d'`application.yaml` (point C2 de l'audit de parité). La vraie solution est de
les exposer, par exemple sur `SkillAnalysisQuotaDto`.

### Écran de saisie d'un petit sujet — il fait faire, il n'explique pas

Refonte demandée par le client (« beaucoup trop verbeux et pas du tout
intuitif »), **menée dans la même passe que le mobile**, contre la même capture
de référence. **Supprimés** : le fil d'Ariane sur deux lignes, les badges « Une
compétence · un critère » et « Petit sujet i/N », le titre « Produisez votre
propre réponse. », le paragraphe d'objectif, l'encart « COMPÉTENCE ÉVALUÉE »,
l'encart « Pourquoi cet exercice ? » et les puces méta « Accessible » / « Un
seul critère ». Ils repoussaient la zone de production à plus de 1 200 px du
haut : le candidat lisait une leçon au lieu de produire.

**Structure, de haut en bas** (identique en EE et en EO) : en-tête · ligne
compacte `Sujet i/N` + pilule de palier · `Progression` + barre · carte **« Ce
qu'il faut faire »** (la check-list) · carte **« Situation »** · rangée de puces
(longueur + contraintes) · carte **« Ta réponse »** (champ ou enregistreur,
astuce et compteur en pied) · pied sobre (plafond de longueur en EE, reliquat
d'analyses offertes, rappel ambre) · actions `Valider et comparer` / `Effacer`.

### Allègements de l'écran de saisie et des listes (parité mobile)

Le client a allégé ces composants côté mobile ; le web applique **les mêmes
retraits**, la parité web ⇄ mobile n'étant pas négociable. À ne pas rétablir
« pour le contexte » — c'est exactement la verbosité qu'on retire :

- **L'auto-évaluation est supprimée.** Le sélecteur, son état et le composant
  `SelfEvaluationPicker` n'existent plus, et l'écran de résultat n'affiche plus
  la puce « Ton ressenti » (aucune tentative n'en portera). Elle était
  déclarative et sans effet, et coûtait une décision de plus avant de produire.
  ⚠️ **Le contrat d'API ne change pas** : `selfEvaluation` reste optionnel sur
  `SubmitSkillTextRequest` / `skillApi.submitAudio` et sur `SkillAttemptDto` —
  on cesse simplement de l'envoyer.
- **La description ne s'affiche plus sous le titre** dans la liste des
  compétences (niveau 4). Elle reste derrière la **pastille d'information** de
  l'écran de détail.
- **Le critère unique ne s'affiche plus sous le titre** dans la liste des petits
  sujets. Il est déjà rendu en gestes vérifiables par la check-list de l'écran
  de saisie.
- **La pastille de niveau est retirée** de la carte de résumé d'une compétence :
  le palier est celui de toute la tâche, déjà porté par le hero de la liste et
  par l'écran d'un sujet.
- Classes CSS supprimées de `skill-ui/skill.module.css` faute d'appelant :
  `selfBlock` / `selfLabel` / `selfHint` / `selfRow` / `selfBtn` / `selfBtnOn`,
  `analysisBlock` / `analysisRow` / `analysisCheck` / `analysisLock` /
  `analysisBody` / `analysisTitle` / `analysisHint`, `invite` / `inviteBody` /
  `inviteTitle` / `inviteSub`. Ajoutées pour le dépliant des références :
  `refSection` / `refToggle` / `refToggleBody` / `refToggleTitle` /
  `refToggleHint` / `refToggleAction` / `refChevron` / `refChevronOpen` /
  `refPanel`.

- **Critère de réussite, mesuré** : à 360 px la carte « Ta réponse » commence
  à ~468 px et le champ à ~516 px — visible sans défiler. C'est ce chiffre qui
  justifie le bloc `@media (max-width: 420px)` de `skill.module.css` (rythme
  resserré, puces à 11 px pour tenir sur **une** ligne : une seconde ligne de
  puces coûte 39 px prélevés exactement là). Ne pas le desserrer sans
  remesurer.
- **Les quatre champs de guidage** (`checklist`, `constraintTags`,
  `answerStarter`, `tip`, migration V026) sont **tous nullables**. Les règles de
  dégradation vivent dans **`lib/skill-guidance.ts`** (pur, testé par
  `skill-guidance.test.ts`) et **nulle part ailleurs** : pas de check-list ⇒ la
  carte retombe sur la consigne, pas de contexte ⇒ pas de carte « Situation »,
  pas d'étiquette ⇒ seule la puce de longueur, pas de bornes ⇒ pas de rangée,
  pas d'amorce ⇒ texte grisé neutre, pas d'astuce ⇒ le pied n'affiche que le
  compteur. **Jamais de carte vide, jamais de « null » à l'écran.**
- **La puce de longueur est DÉRIVÉE des bornes** (`lengthChipLabel`), jamais
  stockée dans `constraintTags` — la dupliquer, c'est se garantir de la voir
  diverger. Elle reste **indicative** : `lengthAdvisory` continue d'avertir sans
  bloquer.
- **Une seule table icône ⇄ contrainte**, dans
  `competences/PromptGuidance.tsx` : `Record<SkillConstraintIcon, LucideIcon>`
  (donc exhaustive — une famille ajoutée au contrat sans icône ne compile plus)
  + une icône neutre pour une valeur que ce front ne connaît pas encore.
- **Parité EE ⇄ EO** : l'oral reçoit exactement la même structure. L'amorce y
  devient une **suggestion de démarrage**, le compteur de mots une **durée**
  (`0:12 / 0:45`), et l'avertissement de transcription passe **sous**
  l'enregistreur pour ne pas repousser le micro.
- **Réutilisation des formulaires** : `EeWritingForm` / `EoRecordingForm` sont
  employés tels quels via un adaptateur `SkillPromptDto → ProductionTaskDto`
  (`toProductionTask`, dans `CompetencePrompt`). Des props **optionnelles** ont
  été ajoutées aux deux formulaires, sans changer leur comportement par défaut :
  `consigneLabel`, `headerSlot`, **`promptSlot`** (remplace **entièrement** la
  carte d'exercice : c'est là que vit le guidage du petit sujet),
  `criteriaSlot` (remplace la carte des 4 critères du TCF — un micro-exercice
  n'en a qu'un ; `null` la retire), **`answerCard`** (présente la zone de
  production en carte : icône + titre, amorce grisée, pied astuce / compteur ;
  absent = présentation historique), `footerSlot` (plafond de longueur,
  reliquat d'analyses offertes et rappel ambre, juste au-dessus du bouton de
  validation) et, côté
  EE seulement, `lengthAdvisory` + `clearLabel`. ⚠️ Ces formulaires sont
  partagés avec les écrans de production TCF et la session d'examen blanc :
  **toute prop ajoutée reste optionnelle**, comportement actuel par défaut.
  - **`voice`** (les deux formulaires, + `EoTranscriptNotice`) : `"vouvoiement"`
    par défaut, `"tutoiement"` posé par le module — cf. la règle de tutoiement
    plus bas. Elle ne pilote que le **chrome** (texte grisé du champ,
    avertissement de longueur non bloquant, aides du micro, messages de
    permission), jamais le sujet ni l'amorce venus de la base.
  - **`footerAlwaysVisible`** (EO) : rend `footerSlot` **dès l'ouverture**, au
    lieu d'attendre l'arrêt de l'enregistrement. Ce que ce pied porte — reliquat
    d'analyses offertes, rappel sur les références — se lit **avant de
    parler** : arrivé après coup, le candidat avait déjà consommé une de ses
    analyses offertes sans le savoir (parité mobile, où ces blocs sont
    permanents sous la carte de réponse). Faux par défaut : les écrans de
    production TCF gardent leur pied d'après-prise.
  - **`maxDurationSec`** (EO) : plafond **dur** de capture hors examen — la
    prise s'arrête d'elle-même et la durée transmise est bornée. Reflet d'un
    garde serveur, pas d'un réglage d'affichage : sans lui, un enregistrement de
    cinq minutes partait puis était refusé, production perdue. À ne pas
    confondre avec `task.dureeMaxSec`, qui reste la durée **conseillée** et
    pilote seule le décompte du mode examen. Absent = aucune borne.
  - **`lengthAdvisory` (EE) : la fourchette AVERTIT sans bloquer.** `motsMin` /
    `motsMax` sont désormais **transmis** (ils étaient annulés, ce qui rendait la
    fourchette purement décorative) ; avec ce drapeau la soumission reste ouverte
    hors bornes et un message le dit explicitement (spec §8 règle 15 — une
    production courte qui satisfait le critère est valide). Les tâches TCF, elles,
    gardent des bornes **strictes** : le drapeau y reste `false`. Ne pas
    réintroduire de blocage ici, ni annuler les bornes à nouveau.
  - `clearLabel` ajoute le bouton secondaire « Effacer » à côté de la
    validation ; absent par défaut (en examen, effacer n'a pas de sens).
  `niveauCible` reçoit `SkillPromptDto.skillTargetLevel` :
  le palier est **exigé** sur l'écran d'un petit sujet (spec §3 niveau 5), et
  supprimer un appel réseau ne doit rien lui coûter. `setEeDraft` (exporté à côté
  de `clearEeDraft`) alimente « Reprendre ma réponse », appliqué par un
  changement de `key`.
- **Deux textes, deux endroits** : `SkillDto.generalCriterion` = le critère
  général → encart **« Critère travaillé »** de l'écran compétence ;
  `SkillDto.description` = la courte explication → **derrière le bouton
  d'information** de la carte de résumé (niveau 4), plus dans son corps : six
  lignes de texte y repoussaient le critère et la liste des sujets sous la ligne
  de flottaison (demande client, menée en parité avec le mobile). Le bouton est
  une pastille `Info` en haut à droite de la carte (`.infoBtn` / `.infoDot`,
  zone cliquable 44 × 44 pour une pastille de 28), il ouvre la `ConfirmSheet`
  `tone="info"` — titre = nom de la compétence, corps = la description — et
  **n'est pas rendu du tout quand `description` est vide** (pas de feuille
  vide). Le focus revient sur la pastille à la fermeture.
  Ne jamais rendre le même texte aux deux places. Le critère
  du **sujet**, lui, est `SkillPromptDto.uniqueCriterion` — encore un troisième
  texte. ⚠️ Depuis la refonte de l'écran de saisie, **ni `description` ni
  `uniqueCriterion` ne s'affichent sur l'écran d'un petit sujet** : la
  check-list a remplacé le critère abstrait par des gestes vérifiables. Ils
  restent servis par le DTO et lus ailleurs — ne pas les y réintroduire « pour
  le contexte », c'est exactement la verbosité qu'on a retirée.
- **Un seul appel sur l'écran de sujet** : `SkillPromptDto` porte
  `skillPromptCount`, `skillDescription`, `skillGeneralCriterion` et
  `skillTargetLevel`, donc le repère `Sujet i/5` (`displayOrder` /
  `skillPromptCount`) et la pilule de palier se rendent **sans** second
  `GET /api/skills/{skillId}`. Ne pas réintroduire cet aller-retour.
- **Bandeau « Sujet déjà traité »**, libellés gelés par le contrat (parité mot
  pour mot avec le mobile) : **une seule** action, `Reprendre ma réponse` en EE
  (préremplit la zone de saisie depuis `lastAttemptId`) et
  `Écouter ma dernière réponse` en EO (ouvre l'écran de résultat de
  `lastAttemptId`). Un enregistrement ne se « reprend » pas — il se réécoute.
- **Freemium (§14) — l'analyse IA n'est PAS une option.** **Aucun sujet n'est
  verrouillé** : produire et lire les 3 références sont gratuits partout. Seule
  **l'analyse IA** est premium, avec **3 analyses offertes à vie**. Il n'y a
  **plus de case à cocher** (décision client) : l'analyse est le comportement
  naturel, `requestAnalysis` vaut simplement « le candidat y a droit » (abonné,
  ou compte gratuit avec du reliquat). **Quota épuisé ⇒ la production part sans
  analyse**, jamais en 403 — demander une analyse interdite ferait perdre la
  production, alors que c'est **l'écran de résultat** qui porte l'invitation à
  s'abonner (`PaywallSheet` INTEGRAL). Ne pas réintroduire de contrôle
  d'analyse sur l'écran de saisie.
  - Seule information conservée sous la zone de production : **« Il te reste N
    analyses offertes »**, et **uniquement quand N > 0** sur un compte gratuit.
    C'est une information, plus une décision : la retirer prélèverait un essai
    en silence. Rien n'est affiché à zéro — l'invitation vit après la
    production. `GET /api/skills/analysis-quota` renvoie `remaining = -1` pour
    illimité : **cette valeur ne s'affiche jamais telle quelle**.
  - `skillApi.requestAnalysis` (`POST /api/skill-attempts/{id}/analyse`) demande
    l'analyse d'une tentative déjà `RECORDED` — le cas « produire d'abord,
    s'abonner ensuite ». Le client existe, **l'UI reste à brancher** (le bandeau
    de résultat renvoie aujourd'hui vers « refaire le sujet »).
- **Ordre imposé de l'écran de résultat — contrat d'analyse v3** : bandeau de
  confirmation (`Production analysée` / `Progression mise à jour` ; une
  tentative **sans** analyse garde l'accusé historique « Sujet marqué comme
  traité », l'annoncer analysée serait faux) → **carte `NIVEAU DE TA RÉPONSE`**
  (intitulé gelé, miroir de `kSkillLevelCardEyebrow` côté mobile : il nomme la
  **production**, jamais le candidat — ce palier porte sur quinze à trente mots,
  pas sur le niveau TCF de la personne, qui se mesure sur des épreuves entières ;
  « TON NIVEAU » laissait cette confusion, et c'est la lecture la plus
  décourageante) (niveau
  démontré en très grand, puce `Objectif {targetLevel}`, `situationLabel` rendu
  **tel quel**, jauge à 3 crans, puces `strengthTag` / `focusTag`) →
  `Pour viser {niveau}` (leviers) → `Une version plus aboutie` (texte réécrit,
  extraits surlignés, puce par segment) → `À retenir` → `Ta production`
  **repliée** → dépliant de références (replié) → 2 actions (`Sujet suivant` via
  `nextPromptId`, désactivé si null ; `S'entraîner sur ce point`, primaire
  pleine largeur, qui **refait le sujet courant**). Le retour en arrière reste la
  flèche de l'en-tête. Blocs : `CompetenceLevelCard`, puis le **plan d'action
  partagé** `skill-ui/ActionPlan.tsx` (`ActionPlanLeviers`,
  `ActionPlanExemple`, `ActionPlanReformulations`, `ActionPlanMemoCard` +
  les libellés gelés `pourViserTitle` / `ACTION_PLAN_EXEMPLE_TITLE` /
  `ACTION_PLAN_REFORMULATIONS_TITLE`). ⚠️ **Ces blocs sont partagés avec le
  rapport de correction EE/EO** (`production/ProductionActionPlan.tsx`) depuis
  qu'il rend le même plan : ils ne se recopient pas. Ils rendent le **corps
  seul** — chaque écran pose son propre intertitre.
  - 🛑 **AUCUNE carte englobante** (aligné sur le mobile le 2026-08-15) : les
    blocs sont posés **à plat** sur le fond de page, comme la `ListView` de
    `competence_result_screen.dart`. Chacun porte déjà sa propre surface (carte
    de niveau teintée, leviers en liste blanche, exemple, mémo ambre, dépliants,
    boîte de production) ; les empiler dans un `s.card s.panel` écrasait la
    hiérarchie et faisait lire l'écran comme un seul pavé. **Ne pas les y
    remettre.**
  - **L'en-tête porte le sujet** : `SkillShell title={prompt.title}
    meta={"compétence · épreuve"}`, miroir de `ScreenHeader` côté mobile. Sans
    lui, l'écran rendait un verdict orphelin — on ne savait pas quel sujet
    venait d'être traité. Le bandeau de confirmation est donc un `h2` : le `h1`
    de la page, c'est le titre du sujet.
  - **La boîte de production reprend la tête de `_ProductionCard`** : intitulé
    « TA PRODUCTION » à gauche, mesure à droite (durée à l'oral, nombre de mots
    à l'écrit). À l'oral **sans transcription**, la phrase est celle du mobile
    (« Ta réponse orale est enregistrée. La transcription n'est produite que
    lorsqu'une analyse IA est demandée. ») : l'ancien « Production
    indisponible. » laissait croire à une perte, alors que l'audio est bien là.
  - **Le dépliant des références s'ouvre sur « Comparer »**, pas « Afficher »
    (le repli reste « Masquer ») — miroir du `collapsedLabel` de
    `_SectionToggle` : l'invite nomme le geste que la section propose.
  - **Rien n'est calculé côté front** : `levelReached`, `targetLevel`,
    `situation`, `situationLabel`, `scale` (toujours 3 crans) et `cursorIndex`
    sont dérivés serveur (`SkillLevelProgressResolver`). Ne jamais recomposer la
    phrase de situation ni recalculer une position de curseur.
  - **`extrait` est garanti sous-chaîne exacte** de `exempleCible.texte` : on
    surligne par recherche de chaîne, en nœuds React (`<mark>`), **jamais** de
    `dangerouslySetInnerHTML`. Introuvable ⇒ texte brut, aucun surlignage
    inventé, aucun rendu cassé.
  - **`niveauVise == null` est un cas NORMAL** (second appel best-effort,
    objectif déjà atteint, sortie refusée) : les sections leviers / exemple /
    mémo disparaissent, sans message d'échec, sans spinner, sans encart
    d'excuse.
  - **Repli legacy v1/v2** : `levelProgress == null` ⇒ pas de carte de niveau, on
    retombe **intégralement** sur l'affichage historique (intertitre
    « Analyse IA du critère », verdict du critère, `Ce qui est réussi` /
    `À travailler en priorité`, `Proposition améliorée`). Ces analyses sont déjà
    en base et n'ont pas été migrées : aucune régression admise. Sous v3, le
    verdict du critère n'est **pas** réaffiché — la carte de niveau ouvre
    l'écran, deux verdicts empilés se disputeraient la première lecture
    (parité stricte avec `_VerdictCard` côté mobile).
  - **Course du second appel** : quand la tentative devient `EVALUATED` avec
    `levelProgress`, une situation ≠ `OBJECTIF_ATTEINT` et `niveauVise` encore
    absent, on poursuit le polling **15 s au maximum**
    (`skillNiveauViseMayStillArrive`, `lib/skill-result-view.ts`, + la durée
    `ACTION_PLAN_GRACE_MS` — cf. « Le sursis du plan d'action » plus bas), le
    budget global restant la borne dure. Sans ce sursis, un écran s'affichait
    sans leviers alors qu'ils arrivaient une seconde plus tard ; pendant qu'il
    court, la place du bloc porte `<ActionPlanPending />`.
  Les
  références ne sont **jamais** visibles avant d'avoir produit (§13.2, doublé
  d'un 403 serveur). **Polling 3 s, plafond 120 s — valeur de parité, partagée
  mot pour mot avec le mobile** et déclarée en **durée** (`POLL_BUDGET_MS`), pas
  en nombre de tirages : c'est en la traduisant chacun de son côté (« 40
  tirages » ici, « timeout 90 s » là-bas) que les deux fronts avaient divergé,
  une analyse de 100 s aboutissant sur le web et échouant sur le mobile. On
  retient la valeur la plus généreuse — abandonner une analyse qui allait
  aboutir est le pire des deux défauts. En EO,
  le bloc `Ta production` porte le **lecteur audio** (`SkillAttemptDto.audioUrl`,
  URL R2 présignée 15 min, même `<audio controls preload="metadata">` que
  `EoRecordingForm`) **et** la durée : se réécouter en lisant le retour est la
  moitié de la valeur de l'oral.
- **Le retour IA est DÉPLIÉ, les références sont REPLIÉES** (inversion demandée
  par le client — c'était l'inverse). Règles pures dans
  **`lib/skill-result-view.ts`** (`skillResultAnalysisView`,
  `skillResultHasBanner`, `skillResultBannerAction`,
  `ANALYSIS_OPEN_BY_DEFAULT`, `REFERENCES_OPEN_BY_DEFAULT`), testées par
  `lib/skill-result-view.test.ts` — ne pas réimplémenter ces décisions dans un
  composant.
  - **Cas nominal : ni bandeau ni bouton.** L'analyse s'affiche telle quelle
    sous son intertitre « Analyse IA du critère ». C'est le retour que le
    candidat vient de mériter (et qui a consommé un de ses essais) : le lui
    faire déverrouiller d'un clic ajoutait une étape à un contenu déjà acquis.
  - **Le bandeau ne subsiste que quand il n'y a rien à déplier** : analyse en
    échec (→ `retryAnalysis`), quota épuisé (→ `PaywallSheet`), production
    enregistrée sans analyse alors qu'il en restait (→ refaire le sujet). Un
    bandeau qui disparaîtrait dans ces cas-là ne dirait jamais au candidat ce
    qu'il rate — c'est le point premium du module. Une analyse présente
    **l'emporte toujours** sur un quota épuisé ou un statut en échec.
  - **Les 3 références sont derrière un dépliant** (`CompetenceReferences`) :
    vrai `<button>` avec `aria-expanded` / `aria-controls`, libellé explicite
    dans les deux sens (« Afficher » ⇄ « Masquer »), `:focus-visible`. Le
    candidat lit son propre retour d'abord, il va se comparer ensuite.
  - **L'ordre du contrat ne bouge pas** : accusé de traitement → ta production →
    analyse → références → actions.
- **Le verdict `NOT_VALIDATED` est ROUGE** (parité mobile, et cohérent avec la
  référence « Insuffisant ») : c'est un **critère**, pas un niveau CECRL — la
  règle « jamais de rouge sur un palier » ne s'applique pas ici. Les onglets de
  références portent le même code : rouge / vert / bleu.
- **Le liseré vertical d'une carte de sujet ne marque QUE les sujets traités**
  (3 px, en retrait vertical). Un liseré gris sur les sujets « à faire » lui
  retirait tout pouvoir de distinction.

### Écran de résultat d'une production — « rapport express » (parité mobile)

`ProductionFeedbackView` (rendu par `ProductionResults`, routes
`/entrainement/tcf/{ee,eo}/resultats/[submissionId]`) n'est **pas un rapport
d'expertise pour un professeur** : c'est ce dont un candidat a besoin, dans
l'ordre où il en a besoin, et une même erreur n'est expliquée qu'**une** fois.

**Passe 2026-08-08 — verdict client : « le contenu est bon, mais trop verbeux,
un candidat ne lira pas tout ça ».** **Aucune information n'a été retirée** : ce
qui disait deux fois la même chose a été **fusionné**, ce qui se consulte a été
**replié**. Structure de référence : maquette « Résultats TCF — Rapport express »,
**couleurs de l'application** (le `grep -nE "#[0-9a-fA-F]{3,8}"` doit rester
vide : `white` / `color-mix()`, jamais un hex). **Menée dans la même passe que
le mobile** (`evaluation_report.dart`) — les deux fronts sont identiques, écran
par écran.

**Quatre sections, dans cet ordre :**

1. **Hero** (`ProductionResultsHero`) — le `.hero` de la maquette : dégradé de
   marque + **halo clair** en haut à droite, eyebrow « Expression écrite ·
   Tâche 1 », **verdict d'objectif** en gros, `objectif_resume`, puis le panneau
   `.level` **translucide** (blanc 13 %, bordure blanc 18 %) : niveau estimé +
   pastille + barre des cinq paliers, et enfin le **rappel d'enjeu**. Les trois
   blocs d'avant (accusé « Production évaluée », `ProductionObjectiveBanner`,
   `ProductionScoreHero`) n'en font plus qu'un, et les deux composants sont
   **supprimés**. Pas de verdict (≈ 100 évaluations legacy) → titre neutre
   « Votre correction ». **Aucune pastille d'icône devant le verdict** : la
   maquette n'en a pas, et « Objectif non atteint » se lit en toutes lettres.
2. **Deux bandeaux pleine largeur, empilés et repliés** (`ResultsSummaryTiles`,
   `<details>` natif) : **« Ce qui marche »** (vert — `N/M points traités`, ou
   le compte de points forts sans check-list) et **« À corriger en priorité »**
   (**rouge** — `N priorité(s)`). Chacun tient sur **une ligne** : titre,
   chiffre, chevron. Appuyer ouvre le détail **dans le même encart, juste en
   dessous** — points traités puis points **oubliés** (intertitre rouge, depuis
   v15/v9) puis points forts d'un côté (ces derniers séparés par un filet, deux
   natures différentes), la ou les priorités **complètes** de l'autre
   (`PriorityBody` : ni carte propre ni étiquette, le bandeau les porte déjà).
   ⚠️ **La priorité vit désormais à UN SEUL endroit.** Elle était résumée en tête
   puis répétée en entier plus bas : c'était la dernière redite du rapport. Le
   rouge est assumé — c'est le seul bloc qui dit « à refaire », et il ne peint
   aucun palier CECRL (la règle « jamais de rouge sur un niveau » n'est pas en
   cause).
3. **Profil par critère** (`CriteriaOverview`) — **une carte par critère**
   (`.criterion` de la maquette : pastille 40×40, nom, barre 6 px, bande à
   droite), **sortie du repli** (elle y était, donc personne ne la voyait).
   Commentaire, preuve **et définition complète** se déplient carte par carte via
   **« Voir pourquoi »**.
4. **Votre rédaction** (`ProductionTextCard`) — le texte rendu, **et rien
   d'autre** : la bascule « Voir la version améliorée » a été **retirée le
   2026-08-08** (cf. la règle dédiée ci-dessous). La phrase visée par la
   priorité n° 1 y est **surlignée** (`splitHighlight`, première occurrence
   **exacte** ; aucune correspondance ⇒ aucun repère, jamais un repère faux),
   avec pour seule action « Masquer les repères » (douce). Puis, juste en
   dessous, le **plan d'action** : `ProductionActionPlan`.

5. **Le plan d'action** (`ProductionActionPlan`, `version_ciblee`) — les mêmes
   blocs que le retour d'un micro-exercice de compétence, via les composants
   **partagés** `skill-ui/ActionPlan.tsx` : « Pour viser {niveau} » (leviers
   action / exemple), puis « Une version plus aboutie » à l'écrit (texte réécrit,
   extraits surlignés, puce par segment) ou « Des versions plus abouties » à
   l'oral (une ligne par reformulation : `original` atténué, `reformule` en
   accent, puce `apport`), puis « À retenir ». ⚠️ **Le titre n'étiquette plus un
   texte d'un palier** : l'ancien bloc « LA MARCHE AU-DESSUS » / « Au niveau B2,
   votre réponse pourrait ressembler à ceci » est **supprimé**, parce que rien ne
   vérifie qu'un texte atteint le palier annoncé — un candidat a recopié un
   exemple étiqueté B2 et l'analyse l'a noté B1. Seul l'**objectif** est nommé.
   Chaque section se masque indépendamment ; bloc absent ⇒ rien du tout.

### Le sursis du plan d'action (2026-08-11)

Le plan d'action vient d'un **second appel LLM**, lancé côté serveur **après**
que la correction est persistée et la soumission passée à `EVALUATED` — hors
transaction, pour qu'il ne puisse jamais retarder ni faire échouer la
correction. **Ce comportement serveur est volontaire et ne change pas** : le
correctif est entièrement côté front. L'écran s'affichait sans plan alors qu'il
arrivait dix à quinze secondes plus tard, et le candidat devait sortir puis
revenir pour le voir.

- **Le polling existant est prolongé**, pas doublé : `ProductionResults` garde sa
  boucle unique (3 s, `MAX_POLLS` = borne dure) et continue **15 s au maximum**
  après `EVALUATED` tant que le feedback ne porte ni `version_ciblee` ni
  `niveau_vise_atteint` (`productionActionPlanMayStillArrive`,
  `lib/production-feedback.ts`).
- **Durée, libellé et indicateur vivent à un seul endroit par front**, dans
  `app/_components/skill-ui/ActionPlan.tsx` — partagé avec le résultat d'un
  micro-exercice, qui attend exactement le même bloc :
  `ACTION_PLAN_GRACE_MS` (**15 s**, miroir de `kActionPlanGrace` côté mobile ;
  l'ancien `SKILL_NIVEAU_VISE_GRACE_MS` à 10 s est **supprimé**, deux durées pour
  la même attente n'avaient aucune justification), `ACTION_PLAN_PENDING_LABEL`
  (**« On prépare tes conseils… »**, contrat gelé) et `<ActionPlanPending />`.
- **Ce que voit le candidat** : un petit spinner et une ligne, à l'emplacement
  du bloc. **Non bloquant** (le rapport reste entièrement lisible), et il
  **disparaît en silence** à la fin du sursis — pas de message d'échec, pas de
  « indisponible » : un plan absent est un cas normal.
- ⚠️ **Jamais sur un rapport rouvert plus tard.** Les deux règles exigent
  `observedInFlight` — l'écran a vu la correction dans un statut non final depuis
  son ouverture. Une correction de trois jours ne poste donc **qu'un seul appel**,
  ne poll pas et n'annonce aucun conseil. Ne pas relâcher cette condition.

⚠️ **« Voir l'analyse complète » n'existe plus (contrat v15 / tool-schema v9,
2026-08-11).** Le correcteur ne produit plus `exemples_corriges` ni
`suggestions`, et ce repli — que personne n'ouvrait — part avec eux :
`ProductionFullAnalysis.tsx` et `FeedbackList.tsx` sont **supprimés**, ainsi que
les classes CSS `.details*`, `.limits*`, `.acc*`, `.subBlock/.subTitle`, `.fb*`
et `.corr*`. Les deux champs restent **typés et parsés** dans `lib/types.ts`
(une centaine d'évaluations en base les portent) et **aucun écran candidat ne
les lit**. Ce qui vivait dans le repli sans venir du LLM a été **remonté**, pas
perdu :
- **« À savoir sur cette évaluation »** (`avertissements`, écrit par le
  **serveur** : limite de l'oral, purges automatiques) devient une **note
  discrète sous le hero** (`EvaluationNotice.tsx`) — ni `<details>`, ni carte
  pleine, et rien du tout quand la liste est vide ;
- **la check-list de la consigne** vit désormais dans le dépliant du bandeau
  **« Ce qui marche »** : `treatedPointsSummary` rend aussi `oublies`, affichés
  sous un intertitre rouge « Points oubliés ». Sans eux, le candidat lisait
  « 2/3 points traités » sans jamais savoir lequel manquait. Les **pistes non
  abordées**, qui ne coûtent aucun point, ne sont plus rendues — d'où le retrait
  de `hasAccomplishmentDetail`, devenu orphelin (`groupAccomplishment` reste,
  c'est lui qui garantit qu'aucune piste ne se glisse dans la fraction).
La transcription EO reste dans son `<details>` séparé de `ProductionResults`
(`ProductionSubmissionDto` ne porte pas d'URL audio — pas de lecteur inventé).

**Trois arbitrages de la passe, à ne pas défaire :**
- **Les points forts ne sont plus en clair.** Deux phrases entières = cinq lignes
  de prose pour une information que « Ce qui marche » donne en un chiffre.
- **La technique d'une priorité (`comment`) est repliée** derrière « Comment
  faire ». Le correcteur y écrit jusqu'à huit lignes : à plat, c'était le plus
  gros bloc du rapport et il chassait hors écran la seule chose vraiment
  actionnable — la **réécriture**, qui elle **ne se replie jamais** (phrase barrée
  en rouge, nouvelle en vert, sans étiquettes : la rature dit « avant » mieux que
  le mot « avant »).
- **Un critère se lit sous son NOM COURT** (Communiquer · Interagir · Vocabulaire ·
  Grammaire, `shortLabel` dans `CriteriaOverview`). Le `label` du serveur est une
  **définition** (« Communiquer : accomplir la tâche et enchaîner les idées ») :
  sur deux lignes, il pousse la bande hors de vue. La définition réapparaît au
  déplié.

**Nouvelles règles pures** (`lib/production-feedback.ts`, testées) :
`treatedPointsSummary` (le `N/M` du bandeau vert — **pistes exclues des deux
côtés**, sinon une consigne entièrement remplie s'affiche « 3/5 ») et
`splitHighlight` (le repérage exact dans la production). `niveauCecrlShort`
(`lib/types.ts`) rend `A1_NON_ATTEINT` en **« <A1 »** — le tronquer en « A1 »
annoncerait un niveau non atteint.

**La barre des paliers sur le dégradé** (`HeroScale`) : cinq segments et **une
seule ligne** de libellés (`<A1 · A1 · A2 · B1 · B2`), le palier atteint en
**blanc plein** — sur du bleu, les teintes de palier ne se voient plus, et c'est
la **pastille (blanche, texte teinté)** qui porte la couleur. Le `<details>` du
panneau ouvre `avertissementNiveau` (ou `NIVEAU_PORTEE_TACHE`) — une ligne
« Comment lire ce niveau ? » écrite en toutes lettres coûtait une ligne de plus
dans le bloc qu'on allège.

### ⚠️ Pas de note /20 sur le résultat d'une TÂCHE (décision 2026-08-08)

Au TCF, un correcteur attribue **un niveau par tâche, jamais une note** : le /20
ne porte que sur l'**épreuve entière** (3 tâches). Et comme 10/20 y vaut déjà B2,
un A2 parfaitement normal s'affichait « 3,5/20 », qu'un francophone lit comme une
catastrophe scolaire. Trois conséquences, à ne pas défaire :

- **`ProductionResultsHero` n'affiche aucune note** — ni en gros, ni en petit, ni
  dans un repli — et **aucune borne chiffrée de barème** (« 2-5 → A2 ») : la
  table des paliers et `tcfBandRange` ont été supprimées avec elle. Le
  **niveau** est le héros de la carte.
- **La note reste affichée dès qu'on agrège les 3 tâches** : bilan d'épreuve
  EE/EO (`noteEpreuve`) et bilan d'examen blanc TCF complet. Le critère est
  « 3 productions agrégées », pas « examen complet ».
- **La règle vaut PARTOUT, pas seulement sur l'écran de résultat** (passe du
  2026-08-08, second lot) : le « détail par tâche » du bilan de session
  (`ProductionSession`), les badges des sujets traités (`ProductionSubjects`) et
  les lignes d'entraînement libre de l'historique (`SubmissionRow`) portent
  désormais le **niveau** de la tâche. Ce qui agrège reste chiffré : hero du
  bilan de session, stats et slots de `ProductionExams`.
- **Trois helpers partagés dans `lib/production-feedback.ts`** :
  `tacheNiveau(evaluation)` (le niveau affichable, `null` sans confiance ou sur
  une éval antérieure au contrat v4 — on n'invente rien, on écrit « Évaluée » /
  « Traité »), `tacheNiveauLabel(niveau)` (**libellé gelé** : « Niveau B2 » …,
  et « A1 non atteint » pour le plancher, qui se contredirait en « Niveau A1 non
  atteint » — miroir mot pour mot de `tacheNiveauLabel` côté mobile, verrouillé
  par test des deux côtés) et `tacheNiveauTone(niveau)`. **`tcfNoteTone` est
  supprimé** : plus rien ne teinte à partir d'une note.
- **Le niveau s'affirme** : `niveauAtteintLabel` rend « Votre production est au
  niveau A2 », plus jamais « Proche du niveau A2 » — « proche de » veut dire
  « pas encore » en français courant, alors que le niveau EST A2. Le plancher a
  sa propre formulation (« n'atteint pas encore le niveau A1 »).

**Rappel d'enjeu** (`demarcheRappel`, rendu par `.heroStake`) : le niveau obtenu
mis en face de la démarche du candidat (A2 → carte de séjour pluriannuelle ·
B1 → carte de résident · B2 → naturalisation, seuils du 1ᵉʳ janvier 2026). C'est
le vrai anti-découragement — un A2 qui vise la carte de séjour **est** au niveau
demandé, et personne ne le lui disait. Le palier visé vient de
`user.targetLevel ?? tcfLevelFromProcedure(user.targetProcedure)`, **sans** le
repli « B1 » de `resolveTcfLevel` : parcours inconnu ⇒ **rien** ne s'affiche,
jamais un message générique.

**Libellés des bandes de critère gelés** (`bandeCritereLabel`, `lib/types.ts`) :
« Niveau B2 / B1 / A2 / A1 / Non évaluable ». Les bornes des bandes (10 / 6 / 2)
sont exactement celles des paliers du TCF — « En cours d'acquisition » couvrait
donc TOUTE la bande A2, et un candidat A2 ne pouvait voir que ça, quoi qu'il
produise. Ces chaînes ne transitent pas par le réseau : **miroir mot pour mot de
`BandeCritere.displayName` côté mobile**, verrouillé par test des deux côtés
(cf. le module Compétences, même technique).

Règles à ne pas défaire :

- **Les règles de lecture vivent dans `lib/production-feedback.ts`** (pures,
  testées par `lib/production-feedback.test.ts`, `npm test` = runner natif de
  Node, aucune dépendance ajoutée) : `TCF_NOTE_BANDS` (la table officielle),
  `tcfBandIndex`, `tcfPalierIndex`, `niveauAtteintLabel`, `demarcheRappel`,
  `canShowNiveau`, `shouldShowConfiance`, `objectifPresentation`,
  `groupAccomplishment`. Ne pas réimplémenter ces décisions dans un composant.
- **Les paliers du TCF sont dessinés à largeur ÉGALE**, pas à l'échelle réelle
  (B2 = la moitié des notes, « A1 non atteint » = une seule valeur :
  proportionnels, ils seraient illisibles). `tcfBandIndex` reste la lecture d'une
  note (une note à décimale entre deux bandes reste dans la bande **basse**,
  comme le niveau calculé serveur), mais ne sert plus qu'à **teinter** et à
  relire la bande d'un critère legacy ; la barre du hero se place, elle, par
  `tcfPalierIndex(niveau)`.
- **Le niveau n'est JAMAIS affiché sans sa confiance** (`EvaluationResultDto.
  niveauObserve` + `confiance` + `avertissementNiveau`, tous fournis par le
  backend) — `canShowNiveau`, appliqué dans `ProductionResultsHero` : sans
  confiance, le panneau écrit « Niveau indisponible pour cette production » et ne
  rend ni pastille ni barre. Le seul niveau qui fait foi reste celui du bilan
  d'épreuve — dit dans le dépliant de la règle de lecture.
- **Une confiance HAUTE ne s'affiche PAS** (`shouldShowConfiance`) : c'est le
  cas normal, l'écrire n'apprend rien et fait douter d'un résultat qui ne le
  mérite pas. Elle n'apparaît, avec ses `confiance_raisons`, que lorsqu'elle
  nuance vraiment — dans le panneau de niveau du hero.
- **Une piste n'est pas un manque** (`obligatoire: false` = simple idée
  suggérée par le sujet, qui n'enlève aucun point) : elle ne compte ni au
  numérateur ni au dénominateur de « N/M points traités », et depuis v15/v9 elle
  n'est plus affichée du tout. Seuls les points **exigés** non traités le sont,
  dans le dépliant de « Ce qui marche ».
- **Un critère s'affiche en bande, pas en note** (`scores_criteres[].bande`,
  calculée serveur) : une IA ne distingue pas honnêtement un 13 d'un 14 — et
  depuis le 2026-08-08 le rapport d'une tâche ne porte plus **aucun** chiffre.
  La `preuve` (citation littérale) s'affiche sous le commentaire.
- **Quatre critères, les mêmes sur les six tâches** (`communiquer`, `interagir`,
  `lexique`, `morphosyntaxe`, à poids égaux) : c'est la grille réelle du TCF. Les
  codes par tâche des évaluations antérieures restent dans la table de repli
  `eeCriterionLabel` — elles sont toujours en base et doivent s'afficher.
  `ProductionCriteriaCard` annonce cette même liste avant la production (ne plus
  la faire varier par tâche : ce sont les attentes qui changent, pas les
  critères).
- **Les notes portent UNE décimale** (12,5 et non 13). Un seul formateur,
  `formatNoteSur20` (`lib/types.ts`) — ne pas réintroduire de copie locale ni
  d'arrondi à l'entier (la moyenne d'examen de `ProductionExams` inclus).
- **Une priorité ENSEIGNE** (`points_a_ameliorer[]` =
  `{constat, comment?, exemple?{avant,apres}}`) : le `comment` (technique
  réutilisable) et l'`exemple` avant/après sont du contenu principal, jamais une
  note de bas de page. `parseEeFeedback` accepte **les deux formes** — les
  évaluations déjà en base portent de simples chaînes, rendues en `constat` seul.
  Ne pas présumer que le serveur normalise à la lecture d'un ancien
  enregistrement.
- `exemplesCorriges` et `suggestions` restent **parsés** (rétrocompatibilité)
  mais ne sont **plus affichés nulle part** : le contrat v15 / tool-schema v9 ne
  les produit plus.
- **Plafonds backend** : `points_forts` ≤ 2, `points_a_ameliorer` ≤ 2. Ne pas
  rajouter de « voir plus ».
- **La note /20 suit l'échelle du profil TCF IRN** : 0 = A1 non atteint, 1 = A1,
  2-5 = A2, 6-9 = B1, 10-20 = B2 ; la notation active v7/v4 est plafonnée à B2
  et ne renvoie jamais C1/C2. On n'affiche **aucune** correspondance TCF sur une tâche — une tâche
  isolée n'a pas de note officielle. La correspondance
  (`ProductionBilanResponse.correspondanceTcf` → `correspondanceTcfPhrase`) ne
  s'affiche qu'au **bilan d'épreuve** (`BilanView` dans `ProductionSession.tsx`),
  au même wording que le mobile. Cf. `docs/notation-ia-eo-ee.md` §6.6.
- L'échelle du bilan affiche uniquement A1→B2. C1/C2 restent acceptés dans les
  types pour relire l'historique, mais sont rabattus visuellement sur le plafond B2.
- **Rétrocompatibilité (~100 évaluations en base)** : les plus anciennes n'ont ni
  verdict d'objectif, ni version améliorée, ni niveau, ni confiance, ni
  accomplissement, ni bandes, ni preuves, leurs critères portent d'autres codes
  et leurs priorités sont de simples chaînes. Les blocs concernés ne sont pas
  rendus, les critères retombent sur l'affichage chiffré historique.
  `parseEeFeedback` tolère l'absence de tous ces champs. C'est un cas normal,
  jamais une erreur — vérifier les deux formes à l'écran avant de fermer une
  modif de cet écran.
- L'avertissement « évaluation fondée sur la transcription, la voix n'est pas
  analysée » vient désormais du backend en tête de `feedback.avertissements`
  (EO). `EoTranscriptNotice` ne sert plus qu'**avant**
  l'enregistrement (`EoRecordingForm`) ; le résultat le rend dans
  `EvaluationNotice`, sous le hero, avec un repli statique du même message si
  l'évaluation ne porte aucun avertissement (éval v3).


### Situation dans le palier + version au niveau visé (2026-08-08, 3ᵉ lot)

Deux champs backend nouveaux, câblés dans la même passe (miroirs :
`lib/types.ts`, `mobile_sejourfr/lib/core/models/production_models.dart`,
`admin_sejourfr/src/types/api.ts`).

- **`EvaluationResultDto.situationDansNiveau` / `situationDansNiveauLabel`** —
  le cran de progression **dans** la bande (`ENTREE_DE_PALIER` /
  `PALIER_CONFIRME` / `PALIER_SOLIDE`), qui remplace la note disparue du
  résultat d'une tâche. Lu par `situationView` (`lib/production-feedback.ts`) et
  rendu en pastille discrète sous le niveau du hero, à la forme **composée**
  (« A2 solide ») — celle qu'annonce `docs/notation-ia-eo-ee.md` §6.3 bis.
  ⚠️ **Jamais « presque B1 »** : aucun cran ne nomme un manque, c'est la
  contrepartie de la note masquée. Deux gardes : rien sans niveau affichable
  (donc rien sans confiance), rien quand le backend n'envoie pas de cran (évals
  antérieures, `A1_NON_ATTEINT`, C1/C2). Libellés gelés par test des deux côtés
  (`SITUATION_LIBELLES` / `SITUATION_QUALIFICATIFS`).
- **`feedback.version_ciblee`** → `EeFeedback.versionCiblee` +
  `ProductionActionPlan`, rendu **juste sous** la carte de rédaction. **EE ET
  EO** depuis le contrat v2 (le `isOral` qui l'annulait a été retiré). **Trois
  formes, une seule clé**, distinguées à la présence de `exemple_cible` ou de
  `reformulations` — cf. `EeVersionCiblee` dans `lib/types.ts` :
  - **v2, écrit** : `leviers[2..3]{action, exemple}` + `exemple_cible{texte,
    segments[2..3]{extrait, apport}}` + `a_retenir{formule, explication}` ;
  - **v2, oral** : idem, mais `reformulations[2..3]{original, reformule,
    apport}` **à la place de** `exemple_cible`. **Aucun texte modèle complet à
    l'oral** — la production n'est jamais réécrite en entier ;
  - **v1** (une centaine d'évaluations en base) : `texte` + `ce_qui_manque[]`,
    écrit seulement. Rendu comme avant, **sans l'étiquette de palier** sur le
    texte.
  Chaque `segments[].extrait` est **garanti sous-chaîne exacte** de
  `exemple_cible.texte` : on surligne par recherche de chaîne, en nœuds React,
  **jamais** de `dangerouslySetInnerHTML` ; un extrait introuvable ⇒ texte brut.
  L'ordre des leviers vient du backend (du plus rentable au moins rentable) :
  **ne jamais le retrier**. Bloc absent ⇒ **rien n'est rendu** (éval antérieure,
  second appel en échec, oral dégradé, niveau visé déjà atteint) — pas de
  squelette, pas de « non disponible ». Chaque sous-bloc se masque
  **indépendamment**.
- ⚠️ **`version_amelioree` N'EST PLUS AFFICHÉE NULLE PART (2026-08-08).** Elle
  réécrit la production au niveau **déjà constaté** et vivait en bascule sous la
  rédaction, sans mention de niveau : c'était le texte le plus visible et le
  plus copiable du rapport, et il ne fait pas monter d'un palier. Mesuré : le
  propriétaire l'a recopiée telle quelle, resoumise, et a obtenu **la même note
  et le même niveau au dixième près** (4,5/20, A2). Le champ **reste dans le
  contrat serveur et dans `lib/types.ts`** — le retirer imposerait une version
  de tool-schema sur la grille de notation — mais **aucun composant ne le lit**,
  et `lib/production-feedback.test.ts` le verrouille en relisant tout
  `app/_components/production/`. Sont morts et supprimés : la prop
  `versionAmelioree` de `ProductionTextCard`, sa bascule, la carte autonome de
  repli de `ProductionFeedbackView`, les classes `.improved` / `.prodImproved*`
  / `.prodBtn` et le libellé « Comparez en 10 secondes ». Même retrait, même
  passe côté mobile (`improved_version_card.dart` supprimé).
- **Libellés partagés** : `TACHE_TRAITEE_LABEL` (« Traité ») et
  `TACHE_EVALUEE_LABEL` (« Évaluée ») vivent dans `lib/production-feedback.ts`
  et sont gelés en miroir du mobile, qui affichait « Fait » pour le même état.
  **« Évaluée » est le repli, partout** : une soumission corrigée sans niveau
  affichable (éval antérieure au contrat v4) l'affiche aussi bien au détail par
  tâche du bilan que dans `SubmissionRow`, qui n'affichait rien — ni badge, ni
  chevron, donc une ligne qui semblait ne mener nulle part.
- **Le conseil de fin de bilan est partagé** : `BILAN_PROCHAINES_ETAPES_TITLE`
  (« Vos prochaines étapes ») + `bilanProchainesEtapesMessage(niveau)`
  (`lib/production-feedback.ts`). Il vivait **en double**, écrit à la main de
  chaque côté, et les copies avaient divergé (le mobile tutoyait) ; surtout,
  chacune recopiait la table **démarche → palier**, donnée légale que
  `TargetProcedure` interdit de réécrire dans un écran. `DEMARCHE_PAR_NIVEAU`
  est la seule table, et **tout texte qui nomme une démarche passe par elle**.
  Le bloc est rendu **même sans niveau** (le message dit alors que l'IA n'a pas
  fini) — il disparaissait ici et restait là-bas.
- **`PRODUCTION_EXAM_MIN_SUBMISSIONS = 2`** (`lib/production-catalog.ts`) : le
  seuil qui distingue une session d'examen d'un entraînement libre, consommé par
  `examDrafts` **et** `ProductionHistory`. Miroir de
  `kProductionExamMinSubmissions` côté mobile, qui valait 3 — un examen
  abandonné après 2 tâches apparaissait ici et nulle part là-bas.

### Endpoints backend manquants (à créer si besoin)

Côté Spring, ces endpoints n'existent pas encore et leur absence est gérée par
des stubs/fallbacks côté web :

- `POST /api/auth/logout` (révocation serveur du refresh token) — actuellement
  on clear juste le storage côté client.

**Édition du profil (branchée)** : `/profil` édite l'identité, l'email et le
mot de passe via la modale « Mes informations » (`accountApi.updateProfile` →
`PATCH /api/me/profile`, `accountApi.requestEmailChange` →
`POST /api/me/change-email-request` avec vérif par lien mail,
`accountApi.changePassword` → `POST /api/me/change-password`). Comptes
Google/Apple : email + mot de passe en lecture seule (gérés côté provider).
Parité avec l'écran mobile `personal_info_screen.dart`.

**Suppression de compte (branchée)** : `DELETE /api/account` (anonymisation
backend) est appelé depuis la carte « Supprimer mon compte » du `/profil` via
`accountApi.deleteAccount()` (`lib/api.ts`) → modale de confirmation (avertit de
la perte de l'accès payant non remboursable si `user.isPremium`) → si
`manualActionMessage` (abonnement store à résilier), modale d'info → `logout()` +
redirect `/`. Type miroir `AccountDeletionResponse` dans `lib/types.ts`.

## À faire ensuite (transverse, hors vagues)

1. **Refresh token automatique** — intercepteur dans `apiFetch` qui rejoue la
   requête après un 401 si un refresh token est disponible. Le mobile le fait
   via Dio interceptor.
2. **Étendre le Middleware Next si une nouvelle route privée apparaît** — il
   lit déjà le cookie `sejourfr.accessToken` et protège `/dashboard`,
   `/paiement`, `/diagnostic` et `/plan`, avec retour `?next=`. Les autres
   écrans historiques restent encore gardés côté client par `useAuth`.
3. **Mode sombre** — non prévu pour l'instant, mais le design system est
   compatible (variables CSS centralisées).

## Social sign-in Google

Bouton "Continuer avec Google" sur `/connexion` et `/inscription`, implémenté dans
`app/_components/GoogleSignInButton.tsx`. Charge le script `https://accounts.google.com/gsi/client`
une seule fois, puis appelle `google.accounts.id.initialize` + `renderButton`. Le callback POST
`/api/auth/google` (helper `authApi.google` dans `lib/api.ts`) avec le credential JWT, refresh
le user via `loginWithGoogle` exposé par `AuthContext`, puis redirige.

Configuration : variable `NEXT_PUBLIC_GOOGLE_CLIENT_ID` (le **Web client ID** Google, format
`xxx-xxx.apps.googleusercontent.com`). Tant que vide, le composant ne rend rien (silencieux en
dev sans clés). Le même client ID doit aussi être listé dans `sejourfr.oauth.google.audiences`
côté backend pour que la validation passe.

Pas d'Apple sur le web — Apple est réservé à iOS (cf. `CLAUDE.md` racine). Le bouton Google
mène à un compte créé avec `authProvider = GOOGLE` côté backend, exposé dans `AuthenticatedUser`.
L'absence de `targetProcedure` après login Google déclenche le bandeau onboarding sur le
dashboard (cf. Vague 4).

## Préférences utilisateur

- Pas de README générés automatiquement, pas d'images de rendu
- Code direct + quelques explications
- Pour les décisions structurantes : proposer des options, pas imposer
