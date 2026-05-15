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

| Méthode | URL                                    | Usage                                | Auth |
|---------|----------------------------------------|--------------------------------------|------|
| POST    | `/api/auth/register`                   | inscription                          | non  |
| POST    | `/api/auth/login`                      | connexion                            | non  |
| GET     | `/api/auth/me`                         | user courant                         | oui  |
| GET     | `/api/themes?module=CIVIQUE\|TCF`      | liste des thèmes                     | oui  |
| POST    | `/api/attempts`                        | démarrer une tentative               | oui  |
| GET     | `/api/attempts/{id}`                   | reprendre                            | oui  |
| POST    | `/api/attempts/{id}/answers`           | soumettre une réponse                | oui  |
| POST    | `/api/attempts/{id}/finish`            | finaliser                            | oui  |
| POST    | `/api/billing/create-checkout-session` | **à implémenter côté back** — Stripe | oui  |

### Enums Spring miroirs côté TS (dans `lib/types.ts`)

- `Module` = `"CIVIQUE" \| "TCF"`
- `TargetProcedure` = `"CSP" \| "CR" \| "NAT"`
- `TargetLevel` = `"A2" \| "B1" \| "B2"`
- `Difficulty` = `"EASY" \| "MEDIUM" \| "HARD"`
- `QuestionType` = `"KNOWLEDGE" \| "SITUATION"`
- `AttemptType` = `"TRAINING" \| "MOCK_EXAM" \| "REVIEW"`
- `MediaType` = `"AUDIO" \| "IMAGE" \| "VIDEO"`
- `Role` = `"USER" \| "ADMIN"`
- `AudioMode` = `"WRITTEN_QUESTION" \| "FULL_AUDIO"` (sur `Question`, nullable ; en mode `FULL_AUDIO` les labels sont `"Réponse A/B/C/D"` et le contenu réel est lu dans l'audio — cf CLAUDE.md racine)

## Structure

```
app/
├── layout.tsx                    # injection fonts via next/font, variables CSS
├── globals.css                   # @import "tailwindcss" + @theme (tokens design)
├── page.tsx                      # landing one-pager (compose les sous-sections)
├── _components/
│   ├── Brand.tsx                 # Cocarde (CSS pur, 3 cercles), Wordmark, Brand (Link)
│   ├── TopNav.tsx                # nav sticky avec ancres vers sections landing
│   ├── Footer.tsx                # footer 4 colonnes
│   ├── HeroSection.tsx           # hero + preview QCM
│   └── LandingSections.tsx       # TrustStrip, Problem, Exams, HowItWorks, Pricing,
│                                 #   Testimonials, Faq, FinalCta (tout dans 1 fichier)
├── inscription/page.tsx          # "use client" + authApi.register()
├── connexion/page.tsx            # "use client" + authApi.login()
├── examen-blanc/page.tsx         # "use client", 4 stages: choice/briefing/running/result
│                                 #   + timer, soumission par question, finalize
└── paiement/page.tsx             # "use client" + Suspense + useSearchParams
                                  #   plan switcher (mensuel/annuel), Stripe Checkout

lib/
├── api.ts                        # client HTTP : authApi, themeApi, attemptApi
│                                 #   + tokenStorage (localStorage + cookie)
│                                 #   + ApiException (status + payload.fieldErrors)
└── types.ts                      # types miroirs des DTOs Java
```

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

- **Pas de Tailwind utility-first dans le markup.** Les utilities ne sont pas générées au-delà des design
  tokens. Pour styler, soit `globals.css`, soit `<style>` JSX scoped en fin de composant.
- **Classes globales réutilisables** définies dans `globals.css` : `.btn`, `.btn-lg`, `.btn-red`,
  `.btn-ghost`, `.btn-link-soft`, `.field`, `.field-label`, `.field-input`, `.container-x`, `.eyebrow`,
  `.editorial`, `.cocarde`, `.wordmark`, `.form-error`, `.pill-success`.
- **Pages avec formulaires** = `"use client"` obligatoire (état local + handlers).
- **`useSearchParams()`** doit être dans un composant enfant enveloppé par `<Suspense>` (cf.
  `paiement/page.tsx`).
- **Pas de fichier .module.css** pour l'instant. Si le CSS scoped des composants devient lourd, c'est l'option
  de refactor à privilégier.

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

## Paiement — état

La structure de la page paiement est complète (form de facturation, plan switcher mensuel/annuel avec recalcul
du total et de la TVA, récap, badges trust). Le clic sur "Payer" appelle
`POST /api/billing/create-checkout-session` avec `{ plan: "MENSUEL" | "ANNUEL" }`, attend une réponse
`{ url: string }`, puis fait `window.location.assign(url)` pour rediriger vers Stripe Checkout.

**Le backend doit implémenter cette route.** Côté Java :

1. Ajouter dépendance `com.stripe:stripe-java`
2. Créer `BillingController` avec endpoint `POST /api/billing/create-checkout-session`
3. Lire les Price IDs Stripe depuis `application.yaml` (`sejourfr.stripe.price-monthly`,
   `sejourfr.stripe.price-annual`)
4. Créer la `Session` avec `mode = SUBSCRIPTION`, `success_url`, `cancel_url`
5. Retourner `{ url: session.getUrl() }`

Si la route renvoie 404, le front affiche un `alert()` explicite (fallback démo, ne pas garder en prod).

## À faire ensuite (priorisé)

1. **Dashboard utilisateur** après connexion (`/dashboard`) — stats par thématique, dernière tentative, taux
   de réussite, liste des examens blancs passés
2. **Entraînement libre** (`/entrainement`) — sélection thème + difficulté + nombre de questions, runner
   partagé avec l'examen blanc (mêmes composants, mais avec correction immédiate par question puisque
   `type: "TRAINING"`)
3. **Révision des erreurs / favoris** (`/revision`) — liste des questions ratées ou marquées
4. **Page de succès post-paiement** (`/paiement/succes`) — récupère `?session_id=...` envoyé par Stripe,
   confirme l'abonnement côté back
5. **Middleware Next** pour protéger les routes auth — lecture du cookie `sejourfr.accessToken` et redirect
   vers `/connexion` si absent
6. **Mot de passe oublié** — page `/mot-de-passe-oublie` qui appelle `POST /api/auth/forgot-password`, puis
   `/reinitialiser-mot-de-passe?token=...` qui appelle `POST /api/auth/reset-password` (endpoints déjà prévus
   côté back)
7. **Refresh token automatique** — intercepteur dans `apiFetch` qui rejoue la requête après un 401 si un
   refresh token est disponible
8. **Mode sombre** — non prévu pour l'instant, mais le design system est compatible (variables CSS
   centralisées)

## Préférences utilisateur

- Pas de README générés automatiquement, pas d'images de rendu
- Code direct + quelques explications
- Pour les décisions structurantes : proposer des options, pas imposer