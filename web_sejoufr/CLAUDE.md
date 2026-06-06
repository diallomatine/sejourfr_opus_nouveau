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
│   ├── profil/page.tsx           # ★ vue compte : identité, parcours (tile cliquable), abonnement,
│   │                              #   sécurité (mdp via /mot-de-passe-oublie, suppr compte stub), logout
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
└── types.ts                      # DTOs miroirs Java + helper canAccessModule()
```

**Le QuestionRunner est la pièce centrale** : c'est lui qui matérialise la session
de QCM (training avec correction immédiate, ou exam avec submission silencieuse).
Le state est interne (questions cumulées, currentIndex, answersByQuestion,
attemptIdByQuestionId, lastResult, favoriteIds). En mode `infinite=true` (training
premium), il étend automatiquement la session avec un nouveau batch quand on
arrive sur la dernière question — un prefetch est déclenché dès que la correction
de l'avant-dernière s'affiche, pour rendre le passage instantané.

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

## Résiliation d'abonnement

Page `app/(app)/profil/abonnement/page.tsx` (route `/profil/abonnement`)
accessible depuis le CTA « Gérer mon abonnement » du `/profil` quand
`user.isPremium`. La page fetch `billingApi.getSubscriptionStatus()` au
montage et affiche plan + source + date + CTA **Résilier mon abonnement**
en rouge avec confirmation modal locale.

Routing décidé côté backend selon la source :

- **Stripe** → `action=DONE`. On appelle `useAuth().refreshUser()` puis
  re-fetch le status pour refléter `status=CANCELED` immédiatement.
- **Apple/Google** → `action=REDIRECT`. On ouvre `redirectUrl` dans un
  nouvel onglet (`window.open(..., '_blank', 'noopener,noreferrer')`).
  Le statut local ne bascule qu'à réception du webhook du store.

Helpers ajoutés à `billingApi` (`lib/api.ts`) : `getSubscriptionStatus()`
et `cancel()`. Types miroirs `SubscriptionStatusResponse` et
`CancelSubscriptionResponse` dans `lib/types.ts`.

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
    - **Bilan donut lot TCF** : `TcfLotResultCard` (score donut + résumé + conseil
        + rapport dépliable), servi par la session via
          `?lot=N&result=tcfLot&code&level` (parité `TcfLotResultScreen` mobile). Le
          bilan civique reste le rapport Q-par-Q (`ExamReport`).
    - `module_detail/parts.tsx` ne garde que `ModuleDetailGate` + `moduleDetailStyles`.
    - **Reste au lot suivant** : examen blanc TCF complet orchestré (CO→CE→EE→EO).
      En attendant, le hero « examen complet » du hub TCF pointe sur
      `/examens-blancs/tcf`. (`ProductionMobileSheet` n'est plus utilisé par le hub —
      conservé pour les promos mobile du dashboard/historique.)

- **Vague 8 (branche `web_refonte`)** ✅ — **Refonte shell app + dashboard**
  (maquette "Tableau de bord" SaaS) :
    - **Sidebar** (`AppSidebar.tsx`) recomposée : Tableau de bord, section
      **PARCOURS** (TCF IRN → `/entrainement?module=TCF`, Examen civique →
      `/entrainement?module=CIVIQUE`), section **SUIVI** (Progression →
      `/statistiques`, Résultats → `/historique`, Recommandations →
      `/recommandations`). Item actif = fond bleu clair + barre gauche. En
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
      dashboard et `/recommandations` ; helpers dans `lib/dashboard.ts`.
    - Pas de heatmap de régularité (décision produit) — seul le streak est
      exposé.

- **Vague 7** ✅ — **Productions IA web : Expression écrite (EE) + orale (EO)**,
  parité mobile (`screens/tcf_production/*`). Les cartes EE et EO du `TcfHub`
  ouvrent `/entrainement/tcf/ee` et `/entrainement/tcf/eo`.
  - **Architecture générique** : un seul jeu de composants `Production*` piloté par
    une `ProductionConfig` (`app/_components/production/config.ts` : `EE_CONFIG` /
    `EO_CONFIG` — `epreuve`, `base`, `mode` text/audio, `accent`, `inputSegment`).
    Les 14 routes (`tcf/ee/*` et `tcf/eo/*`) sont de **fines enveloppes** rendant
    `<ProductionHub|Subjects|InputPage|Results|Exams|Session|History config={…} />`.
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
  - **Composants partagés** `app/_components/production/` : `CecrlScoreDonut`,
    `ProductionFeedbackView` (critères + points forts/à améliorer/suggestions/
    corrections), `SubmissionRow`, `EeWritingForm`, `EoRecordingForm` +
    `production.module.css`.
  - **Gating** (source backend) : entraînement par tâche = **2 essais gratuits à
    vie** par épreuve pour non-abonnés (403 au-delà → `PaywallSheet` Intégral) ;
    examen blanc 3-tâches = **premium-only**. Premium TCF (Intégral) = illimité.
  - **Fix backend lié** : `ProductionTaskManager.findActive` filtrait mal par
    `tacheNumero` seul (sans niveau) → renvoyait toute l'épreuve. Branche ajoutée +
    query `findByEpreuveAndTacheNumeroAndActiveTrueOrderByNiveauCibleAscCreatedAtAsc`.

### Endpoints backend manquants (à créer si besoin)

Côté Spring, ces endpoints n'existent pas encore et leur absence est gérée par
des stubs/fallbacks côté web :

- `PATCH /api/me/profile` (firstName/lastName) — non utilisé pour l'instant,
  les champs sont en lecture seule sur `/profil`.
- `POST /api/me/change-password` — workaround actuel : la page profil envoie
  vers `/mot-de-passe-oublie` qui utilise le flow par email.
- `POST /api/auth/logout` (révocation serveur du refresh token) — actuellement
  on clear juste le storage côté client.

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