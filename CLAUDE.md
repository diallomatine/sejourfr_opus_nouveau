# SejourFR — Guide racine pour Claude Code

Monorepo (4 dossiers indépendants, pas de workspace npm/Maven parent) de **SejourFR**, plateforme d'entraînement aux examens **civique** (CSP, CR, naturalisation) et **TCF IRN** (A2/B1/B2), obligatoires depuis le **1ᵉʳ janvier 2026**.

> Avant de coder sur un sous-projet, **toujours lire son `CLAUDE.md` local** : les conventions précises (state management, styling, runner, etc.) y vivent. Ce fichier-ci est un index transverse, pas un substitut.

## Les 4 sous-projets

| Dossier | Stack | Rôle | Port dev | Guide |
|---|---|---|---|---|
| `backend_sejourfr/` | Spring Boot 4 / Java 21 / PostgreSQL / Flyway / JWT | API REST unique pour les 3 fronts | 8080 | `README.md` |
| `admin_sejourfr/` | React 19 + Vite + TS strict + TanStack Query + React Router 7 + CSS Modules | Console admin (questions, thèmes, conversations, médias) | 5173 (Vite) | `CLAUDE.md` |
| `web_sejoufr/` ⚠️ (typo : *sejoufr*, pas *sejourfr*) | Next.js 16 App Router + React 19 + Tailwind v4 (tokens seuls) | Vitrine + parcours utilisateur + paiement Stripe + 1 examen blanc / 10 QCM démo | 3000 | `CLAUDE.md` |
| `mobile_sejourfr/` | Flutter 3.6+ / Dart 3.6+ / Riverpod 2 + Dio + go_router | App d'entraînement quotidien (cœur produit) | — | `CLAUDE.md` |

**Stratégie business** : le web pousse à l'abonnement (paiement Stripe **hors stores** pour éviter la commission Apple/Google), puis l'utilisateur s'entraîne principalement sur le mobile. Le web permet aussi 1 examen blanc + 10 QCM d'entraînement par module pour convertir.

## Domaine métier (vocabulaire commun)

- **Module** : `CIVIQUE` ou `TCF`
- **TargetProcedure** (civique) : `CSP` (titre de séjour) / `CR` (résident) / `NAT` (naturalisation)
- **TargetLevel** (TCF) : `A2` / `B1` / `B2`
- **AttemptType** : `TRAINING` (correction immédiate après chaque réponse) / `MOCK_EXAM` (examen blanc, pas de correction live, chrono) / `REVIEW`
- **QuestionType** : `KNOWLEDGE` / `SITUATION`
- **Difficulty** : `EASY` / `MEDIUM` / `HARD`
- **MediaType** : `AUDIO` / `IMAGE` / `VIDEO` (TCF compréhension orale → audio surtout)
- **Role** : `USER` / `ADMIN`

Le backend est la **source de vérité** des DTOs. Les 3 fronts maintiennent leurs miroirs **à la main** :
- `admin_sejourfr/src/types/api.ts`
- `web_sejoufr/lib/types.ts`
- `mobile_sejourfr/lib/core/models/*.dart`

→ Quand un DTO Java change, mettre à jour les 3.

## Identité visuelle commune

Strictement identique sur les 4 surfaces (les écarts sont des **bugs**).

**Couleurs**
- Bleu France `#1E3A8C` (dark `#15296B`, light `#E8ECF8`, soft `#F4F6FC`)
- Rouge France `#E1372F` (dark `#B5251E`, light `#FDECEB`) — réservé aux CTAs critiques + signaux d'urgence
- Ink `#0F1839` / Ink-2 `#1F2950`
- Muted `#6B7299` / `#9CA2BD`
- Vert succès `#168F5B` · Ambre `#E8A317`
- Lignes `#E4E7F2` / `#EEF0F8` · Papier `#FAFAF7` / `#F2F1EC`

⚠️ Note : le web utilise `#1E3A8C`, l'admin documente `#1E3A8F` dans son CLAUDE.md — vérifier le code source en cas de doute (le code fait foi).

**Typographies**
- **Plus Jakarta Sans** (web/mobile) ou **Inter** (admin) — corps, UI, boutons
- **Fraunces** — titres éditoriaux ; les `<em>` dans les titres sont **toujours rouges**
- **JetBrains Mono** — eyebrows, labels techniques, badges, valeurs numériques

**Logo** : Cocarde (3 cercles concentriques bleu/blanc/rouge) + Wordmark (`Sejour` bleu, `FR` rouge) + Tagline `EXAMEN CIVIQUE · TCF`.

**Règle absolue** : ne jamais hardcoder une couleur ou une font. Toujours passer par les tokens locaux (`var(--color-*)`, `AppColors.*`, `AppFonts.*`).

## API backend partagée

Base : `http://localhost:8080`. CORS dev autorise `localhost:3000` (web) et `localhost:4200` (héritage Angular, à ajuster si l'admin Vite passe sur un autre port). Auth JWT Bearer (access ~60 min + refresh 30 j) — **refresh automatique** dans le client HTTP de chaque front.

Endpoints clés :
- `POST /api/auth/{login,register,refresh,forgot-password,reset-password}` · `GET /api/auth/me`
- `GET /api/themes?module=CIVIQUE|TCF`
- `POST /api/attempts` · `GET /api/attempts/{id}` · `POST /api/attempts/{id}/answers` · `POST /api/attempts/{id}/finish`
- `GET /api/me/{questions/favorites,questions/wrong,stats}?module=...` · `POST|DELETE /api/me/questions/{id}/favorite`
- Admin : `/api/admin/{dashboard,questions,themes,conversations,media,passages}`
- **À implémenter** : `POST /api/billing/create-checkout-session` (Stripe)

## Démarrage local (rappels)

```bash
# Backend (depuis backend_sejourfr/)
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
# DB attendue : Postgres local, db = sejourfr_nouveau, user = diallomatine (cf. application-dev.yaml)
# Mail : MailHog sur localhost:1025 (UI http://localhost:8025)

# Admin (depuis admin_sejourfr/)
npm install && npm run dev

# Web (depuis web_sejoufr/)
npm install && npm run dev-web   # ⚠️ script "dev-web", pas "dev"

# Mobile (depuis mobile_sejourfr/)
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8080   # iOS sim
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080    # Android emu
```

## Comptes seed (profil dev uniquement)

| Email | Mot de passe | Rôle |
|---|---|---|
| `admin@sejourfr.fr` | `Admin123!` | ADMIN |
| `user@sejourfr.fr` | `User123!` | USER |
| `karim.test@sejourfr.fr` | `User123!` | USER |

## Migrations Flyway — convention de numérotation

Le backend a **un schéma central** + des **lots de seed civique/TCF** :
- `V1__schema.sql`, `V2__seed_reference.sql`, `V3__seed_dev.sql` (dev only, dossier `migration-dev/`)
- `V4__seed_principes_republique.sql`, `V5__seed_civique_themes_2_a_5.sql`, `V6__password_reset_tokens.sql`, `V7__runner_extensions.sql`
- Lots civique : `V2xx` institutions, `V3xx` droits/devoirs, `V4xx` histoire/géo, `V5xx` société (chaque centaine = reformulations + élargissements CSP/CR/NAT)
- Sous-dossiers `migration/civique/` et `migration/tcf/` pour les lots à venir

→ Pour un nouveau seed, prendre le prochain numéro libre dans la centaine cohérente avec le thème.

## Architecture mentale par projet

**Tous les fronts suivent l'organisation par feature** (miroir du backend Java) :
- Backend Java : `entity/`, `repository/`, `service/`, `controller/`, `dto/`, `mapper/`, `specification/`, `security/`, `config/`, `exception/`, `enums/`
- Admin React : `features/{questions,themes,conversations,dashboard}/` + `api/`, `auth/`, `components/ui/`, `routes/`, `types/`
- Web Next : `app/{inscription,connexion,examen-blanc,paiement}/` + `app/_components/` + `lib/{api,types}.ts`
- Mobile Flutter : `screens/{auth,home,training,exam,question_runner,review,profile,…}/` + `core/{api,auth,models,router,theme,utils,widgets}/`

Le **runner de questions** (mobile `screens/question_runner/` et web `examen-blanc/page.tsx`) est le composant le plus complexe — relire son CLAUDE.md local avant de toucher.

## Préférences de collaboration (durables)

- **Pas de README ni de docs générés automatiquement.** Ne créer un `.md` que si l'utilisateur le demande.
- **Code direct + brèves explications.** Pas de récap de fin de message ni de narration d'étapes triviales.
- **Pour les décisions structurantes : proposer des options avec leurs tradeoffs, pas imposer.**
- **Pas de Tailwind utility-first dans le markup web** — Tailwind v4 sert uniquement aux tokens via `@theme`. Styles dans `globals.css` ou `<style>` JSX scoped.
- **Admin & runner** : pas d'UI kit, pas de CSS-in-JS, pas de `clsx`. CSS Modules vanilla.
- **Mobile** : Riverpod uniquement (pas de Bloc/Provider/GetX), `context.go/push` (jamais `Navigator.push`), `withValues(alpha:)` (pas `withOpacity`).
- **Tous** : TypeScript/Dart strict, pas de `any`/`dynamic`, imports relatifs, pas de commentaire qui paraphrase le code.

## Git

- Remote : `git@github.com:diallomatine/sejourfr_opus_nouveau.git`
- Branche par défaut : `develop` (PRs vers `main`)
- Le repo racine est **un seul git** qui couvre les 4 dossiers — un commit peut toucher plusieurs surfaces (utile quand on aligne un DTO backend avec ses miroirs front).

## Roadmap commune (qui n'existe pas encore)

- **Paiement Stripe** : front prêt (web `paiement/page.tsx`), endpoint `POST /api/billing/create-checkout-session` **à créer côté Java** (dep `com.stripe:stripe-java`, Price IDs en `application.yaml`).
- **Refresh JWT côté web** : l'intercepteur n'est pas encore branché dans `web_sejoufr/lib/api.ts` (admin et mobile l'ont déjà).
- **Middleware Next** pour protéger les routes auth via cookie `sejourfr.accessToken`.
- **Dashboard utilisateur, entraînement libre, révision, succès post-paiement** côté web.
- **Clients / abonnements / stats par user** côté admin (entités existent, pas d'endpoints encore).
- **Offline-first mobile** (SQLite/Drift dans `core/storage/`) — non commencé.
- **In-app purchase** mobile : **volontairement reporté**, on pousse l'utilisateur à payer sur le web.
- **Tests** : aucun sur les 4 projets. Cibles à venir : Vitest+RTL (admin/web), `flutter_test`+`mocktail` (mobile, prioriser les controllers Riverpod), JUnit (backend).
