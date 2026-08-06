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
├── inscription/, connexion/, mot-de-passe-oublie/, reinitialiser-mot-de-passe/
├── a-propos/page.tsx             # disclaimer non-affiliation + sources officielles (conformité
│                                 #   stores ; LegalPageLayout, miroir de l'écran /about mobile ;
│                                 #   aussi lié depuis le footer : ligne disclaimer + colonne Légal)
├── reussir/page.tsx             # ★ landing de bio réseaux (autoportante, cf. section dédiée)
└── examen-blanc/page.tsx         # ancienne route publique (à dépublier en V2)

lib/
├── api.ts                        # authApi, themeApi, attemptApi, examApi, billingApi,
│                                 #   userContentApi (favoris/wrong/reviewQuestion/targetPath),
│                                 #   statsApi, dashboardApi (summary + summaryCached mémo 30s,
│                                 #   partagé sidebar/dashboard), tokenStorage, ApiException
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
- **Mesure d'audience** : `lib/audience.ts` envoie une vue au montage et un
  clic à chaque CTA de démo, en `sendBeacon` (survit à la navigation).
  Les trois CTA passent par le composant `DemoCta` — un bouton ajouté sans
  lui serait un trou silencieux dans le taux de conversion. Aucun cookie ni
  stockage navigateur (cf. CLAUDE.md racine).
- Liens sociaux dans `lib/site.ts` (`SOCIAL_ACCOUNTS`) : une entrée à
  `url: null` **n'est pas rendue** — on ne publie jamais un lien vers un compte
  qui n'existe pas encore.

### `?next=` sur `/inscription` et `?plan=` sur `/paiement`

- **`/inscription?next=<chemin interne>`** (miroir de `/connexion`) : passé par
  `safeInternalPath` (anti open-redirect), utilisé après `register`, après le
  sign-in Google, et propagé au lien « Se connecter ». Sans le paramètre, le
  comportement historique (`/dashboard`) est inchangé.
- **`/paiement?plan=<code>`** : met en évidence le pass ciblé (`.otp-pass.is-targeted`)
  et scrolle dessus au montage. Le gate non-connecté de `/paiement` conserve
  désormais l'URL complète (module + plan) dans son `?next=`, et propose
  inscription **et** connexion.

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
    - **Quitter = abandonner** : on ne laisse pas d'examen « en cours ». Hub →
      bouton « Abandonner » (`ConfirmSheet`) → finalise les épreuves incomplètes
      (CO/CE `attemptApi.finish` = 0 si rien ; EE/EO `markSubDone`) puis `finish`
      parent → bilan (corrige aussi l'auto-finish chrono 0 qui plantait sur un
      examen incomplet). Examens autonomes (diagnostic guest, mocks) :
      `QuestionRunner` prop `quitMode="confirmFinish"` → avertit + finalise.
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
      30–60, T2/T3 60–90), EO coupe la
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
    `ProductionFullAnalysis` (le repli) et `FeedbackList` ;
    `ProductionCriteriaCard` (les 4 critères annoncés avant de produire),
    `SubmissionRow`, `EeWritingForm`, `EoRecordingForm` + `production.module.css`.
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
  `SkillModeBar`, `TaskPills`, `SectionHead`, `SkillNotice`, `MiniBar`,
  `RowChevron`, `SkillBadge`, `SkillRowCard`, `SkillFilterRow`, `SkillStats`.
- `skill-ui/skill.module.css` : la géométrie de la maquette (rayons, paddings,
  grilles, graisses, survols) avec **les couleurs de l'application**. Un
  `grep -nE "#[0-9a-fA-F]{3,8}"` sur `production/`, `competences/` et
  `skill-ui/` doit **rester vide** — `white` / `color-mix()`, jamais un hex.
- **Un seul accent, `--skill-accent`** (bleu à l'écrit, rouge à l'oral). Il est
  posé par `SkillShell` **ou** par `SkillAccent`, qui existe précisément pour
  les blocs rendus hors colonne : `EeWritingForm` / `EoRecordingForm` sont
  réutilisés par `ProductionSession` (examen blanc) et par `CompetencePrompt`,
  qui n'ont pas le même conteneur. Sans lui, une carte d'exercice d'expression
  orale retombait sur du bleu en pleine épreuve rouge.
- **Le parcours est strictement identique en EE et en EO** : mêmes écrans, même
  structure, même ordre. Seuls l'accent et la **zone de production** (saisie vs
  enregistreur) changent.

### Navigation : la barre des trois modes (`SkillModeBar`)

La maquette porte **deux** navigations pour les mêmes trois modes. On ne
reproduit **pas** la barre d'onglets du haut (`.mode-tabs`) — c'est une redite
d'un prototype autonome. On reproduit `nav.bottom` : **Compétences · Sujets ·
Examens**, icône au-dessus du libellé, carte blanche à 3 colonnes.

- Elle est rendue **par `SkillShell`** via sa prop `mode` (+ `taskNumero`),
  jamais en direct : c'est ce qui garantit qu'elle est au même endroit partout
  et que la colonne réserve la place nécessaire (`.wrapBar`).
- **Décision de placement (responsive)** : **fixée en bas sous 900 px** —
  l'idiome mobile de la maquette, et le point où `DualChromeShell` replie sa
  barre latérale en tiroir. **Au-delà de 900 px elle repasse dans le flux**, en
  tête de colonne, en segmenté de 440 px. Une barre flottante en bas d'un écran
  large entrerait en concurrence avec la navigation latérale de l'application :
  deux navigations superposées valent moins qu'une seule lisible.
- Elle n'est **pas** posée sur les écrans de production (exercice, résultat,
  session d'examen) : l'action principale y vit en bas de page, une barre
  flottante s'assoirait dessus.
- Sans `taskNumero` (grille d'examens blancs), « Sujets » comme
  « Compétences » retombent sur la **tâche 1**. C'est une destination par
  défaut, **jamais un chiffre affiché** qui serait faux. Il n'y a plus d'écran
  d'accueil d'épreuve où retomber.

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
`ProductionResults` (accusé de traitement → écho de la production → retour IA →
actions), `ProductionExams` (hero, 3 indicateurs, packs d'examen),
`ProductionHistory`.

- **Aucun contrat d'API n'a changé, aucun endpoint n'a été ajouté.** Une donnée
  que les DTO ne portent pas n'est pas affichée : à l'oral, l'écho de la
  production est la **transcription** — `ProductionSubmissionDto` n'expose pas
  d'URL audio (contrairement à `SkillAttemptDto`), donc pas de lecteur inventé.
- **`ProductionFeedbackView` et ses blocs internes ne bougent pas** : leur ordre
  et leurs règles de lecture sont des décisions de **notation**, pas de mise en
  page (cf. la section dédiée plus bas).
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
pas une copie entière : 6 tâches × 8 compétences × 5 sujets, chacun livré avec
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
  `/` (les 8 compétences) · `/[skillId]` (5 sujets + filtres) ·
  `/[skillId]/[promptId]` (production) ·
  `/[skillId]/[promptId]/resultat/[attemptId]` (retour + références).
- **Composants** `app/_components/competences/` : `CompetencesList`,
  `CompetenceDetail`, `CompetencePrompt`, `CompetenceResult`,
  `CompetenceReferences`, `CompetenceStatusBadge`. (`SelfEvaluationPicker` a été
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
  `SkillAttemptDto`, `SkillAnalysisDto`, `SkillAnalysisQuotaDto` + les enums et
  les tables de libellés FR (`SKILL_PROMPT_STATUS_LABEL`,
  `SKILL_SELF_EVALUATION_LABEL`, `SKILL_REFERENCE_LEVEL_LABEL`) — **libellés
  gelés par le contrat, à ne pas reformuler**. ⚠️ `SkillDifficulty`
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
- **Ordre imposé de l'écran de résultat** (§13.4) : **accusé de traitement**
  (« Sujet marqué comme traité » — la progression a bougé, c'est ce que le
  candidat vient chercher) → `Ta production` → verdict →
  `Ce qui est réussi` / `À travailler en priorité` → `Proposition améliorée` →
  **puis seulement** le dépliant de références (replié ; ouvert, ses onglets
  `Insuffisant | Attendu | Très réussi`) → les 3 actions
  (`Retour aux petits sujets`, `Refaire ce sujet`,
  `Sujet suivant à travailler` via `nextPromptId`, désactivé si null). Les
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

### Écran de résultat d'une production (6 blocs, parité mobile)

`ProductionFeedbackView` (rendu par `ProductionResults`, routes
`/entrainement/tcf/{ee,eo}/resultats/[submissionId]`) n'est **pas un rapport
d'expertise pour un professeur** : c'est ce dont un candidat a besoin, dans
l'ordre où il en a besoin, et une même erreur n'est expliquée qu'**une** fois.
Six blocs, dans cet ordre exact (miroir mobile) :

1. **Objectif de la tâche** (`ProductionObjectiveBanner`) — `accomplissement.
   objectif` (`ATTEINT | PARTIELLEMENT_ATTEINT | NON_ATTEINT`) +
   `objectif_resume`, trois traitements visuels distincts. **Absent des ~100
   évaluations legacy → le bandeau n'est pas rendu du tout**, l'écran commence
   à la note.
2. **Note + échelle du TCF** (`ProductionScoreHero`) — la note, le niveau
   observé, et **l'échelle officielle dessinée avec un curseur sur la note**.
   Aucun pourcentage, aucune jauge « sur 20 points » : notre note EST celle du
   TCF, un 4,5/20 vaut A2 et doit se lire comme tel.
3. **Points forts** (≤ 2 côté backend).
4. **Priorités** (≤ 2) — constat → « Comment faire » → avant/après (✗ / ✓).
5. **Version améliorée** — `version_amelioree`, la production réécrite en
   entier. **EE uniquement** : absente en EO par construction, sans trou visuel.
6. **« Voir l'analyse complète »** (`ProductionFullAnalysis`, `<details>`
   **replié par défaut**) — tout le reste, sans rien perdre, dans l'ordre
   avertissements → **Détail par critère** → accomplissement → exemples
   corrigés → **Suggestions**. La transcription EO / le texte soumis EE restent
   en `<details>` séparés dans `ProductionResults`.

Règles à ne pas défaire :

- **Les règles de lecture vivent dans `lib/production-feedback.ts`** (pures,
  testées par `lib/production-feedback.test.ts`, `npm test` = runner natif de
  Node, aucune dépendance ajoutée) : `TCF_NOTE_BANDS` (la table officielle),
  `tcfScalePosition`, `canShowNiveau`, `shouldShowConfiance`,
  `objectifPresentation`, `groupAccomplishment`. Ne pas réimplémenter ces
  décisions dans un composant.
- **L'échelle du TCF est dessinée à bandes de largeur ÉGALE**, pas à l'échelle
  réelle (B2 = la moitié des notes, « A1 non atteint » = une seule valeur :
  proportionnelles, elles seraient illisibles). Le curseur, lui, est placé
  proportionnellement DANS sa bande, avec 10 % d'inset de chaque côté pour
  qu'une note pile au seuil (2/20) ne tombe pas sur une frontière. Une note à
  décimale entre deux bandes (5,5) reste dans la bande **basse**, comme le
  niveau calculé serveur.
- **Le niveau n'est JAMAIS affiché sans sa confiance** (`EvaluationResultDto.
  niveauObserve` + `confiance` + `avertissementNiveau`, tous fournis par le
  backend) — `canShowNiveau`, appliqué dans `ProductionScoreHero` : sans
  confiance, l'en-tête retombe sur le repli « Note de la tâche ». Le seul
  niveau qui fait foi reste celui du bilan d'épreuve — dit dans le pied.
- **Une confiance HAUTE ne s'affiche PAS** (`shouldShowConfiance`) : c'est le
  cas normal, l'écrire n'apprend rien et fait douter d'un résultat qui ne le
  mérite pas. Elle n'apparaît, avec ses `confiance_raisons`, que lorsqu'elle
  nuance vraiment.
- **L'accomplissement se rend en TROIS groupes** (parité mobile) : points
  traités / manques obligatoires / pistes non abordées. Mélanger les deux
  derniers fait paniquer pour des points qui n'enlèvent rien
  (`obligatoire: false` = simple piste suggérée par le sujet).
- **Un critère s'affiche en bande, pas en note** (`scores_criteres[].bande`,
  calculée serveur) : une IA ne distingue pas honnêtement un 13 d'un 14. La
  note **globale** /20, elle, reste chiffrée. La `preuve` (citation littérale)
  s'affiche sous le commentaire.
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
- `exemples_corriges[].gain` (ce que la reformulation démontre de plus) s'affiche
  sous l'explication quand il est là, absent sur les anciennes évaluations.
- **Plafonds backend** : `points_forts` ≤ 2, `points_a_ameliorer` ≤ 2 (titre
  « Vos priorités »), `exemples_corriges` ≤ 3. Ne pas rajouter de « voir plus ».
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
  (EO), et se lit dans le bloc 6. `EoTranscriptNotice` ne sert plus qu'**avant**
  l'enregistrement (`EoRecordingForm`) ; le résultat garde un repli statique du
  même message si l'évaluation ne porte aucun avertissement (éval v3).

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
2. **Middleware Next** pour protéger les routes auth — lecture du cookie
   `sejourfr.accessToken` et redirect vers `/connexion` si absent. Aujourd'hui
   géré côté client par `useAuth` mais flash possible au SSR.
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
