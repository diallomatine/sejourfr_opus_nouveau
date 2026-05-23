# SejourFR — Guide racine pour Claude Code

Monorepo (4 dossiers indépendants, pas de workspace npm/Maven parent) de **SejourFR**,
plateforme d'entraînement aux examens **civique** (CSP, CR, naturalisation) et **TCF IRN**
(A2/B1/B2), obligatoires depuis le **1ᵉʳ janvier 2026**.

> Avant de coder sur un sous-projet, **toujours lire son `CLAUDE.md` local** : les
> conventions précises (state management, styling, runner, etc.) y vivent. Ce fichier-ci est
> un index transverse, pas un substitut.

## Les 4 sous-projets

| Dossier              | Stack                                                                       | Rôle                                                       | Port dev    |
|----------------------|-----------------------------------------------------------------------------|------------------------------------------------------------|-------------|
| `backend_sejourfr/`  | Spring Boot 4 / Java 21 / PostgreSQL / Flyway / JWT                         | API REST unique pour les 3 fronts                          | 8080        |
| `admin_sejourfr/`    | React 19 + Vite + TS strict + TanStack Query + React Router 7 + CSS Modules | Console admin                                              | 5173 (Vite) |
| `web_sejoufr/` ⚠️    | Next.js 16 App Router + React 19 + Tailwind v4 (tokens seuls)               | Vitrine + parcours user + paiement Stripe + démo gratuite  | 3000        |
| `mobile_sejourfr/`   | Flutter 3.6+ / Dart 3.6+ / Riverpod 2 + Dio + go_router                     | App d'entraînement quotidien (cœur produit)                | —           |

⚠️ Le dossier web est `web_sejoufr` (typo : *sejoufr*, pas *sejourfr*).

**Stratégie business** : le web pousse à l'abonnement (paiement Stripe **hors stores** pour
éviter la commission Apple/Google), puis l'utilisateur s'entraîne principalement sur le
mobile. Web : 1 examen blanc + 10 QCM d'entraînement par module pour convertir.

## Domaine métier (vocabulaire)

- **Module** : `CIVIQUE` ou `TCF`
- **TargetProcedure** (civique) : `CSP` / `CR` / `NAT`
- **TargetLevel** (TCF) : `A2` / `B1` / `B2`
- **AttemptType** : `TRAINING` (correction immédiate) / `MOCK_EXAM` (examen blanc, chrono,
  pas de correction live) / `REVIEW`
- **Epreuve** (granularité fine, orthogonale à `mode`/`module`) : `CIVIQUE` / `TCF_CO` /
  `TCF_CE` / `TCF_STRUCTURE` / `TCF_EO` / `TCF_EE` / `TCF_COMPLET`. `TCF_COMPLET` est un
  conteneur d'examen blanc TCF ; sous-attempts liés via `attempts.parent_attempt_id`.
- **QuestionType** : `KNOWLEDGE` / `SITUATION`
- **Difficulty** : `EASY` / `MEDIUM` / `HARD`
- **MediaType** : `AUDIO` / `IMAGE` / `VIDEO`
- **NiveauCecrl** (eval IA EO/EE) : `A1_NON_ATTEINT` / `A1` / `A2` / `B1` / `B2` / `C1` /
  `C2`. Distinct de `TargetLevel` (palier visé par l'utilisateur).
- **SubmissionStatut** (EO/EE) : `SUBMITTED` → `TRANSCRIBING` (EO) → `EVALUATING` →
  `EVALUATED` | `FAILED`.
- **Role** : `USER` / `ADMIN`
- **AuthProvider** (exposé dans `/api/auth/me`) : `LOCAL` / `GOOGLE` / `APPLE`. Sur iOS,
  **Google ET Apple côte à côte** (Apple obligatoire d'après les guidelines App Store dès
  qu'un autre social sign-in est proposé). Champ immutable.

Le backend est la **source de vérité** des DTOs. Les 3 fronts maintiennent leurs miroirs
**à la main** :

- `admin_sejourfr/src/types/api.ts`
- `web_sejoufr/lib/types.ts`
- `mobile_sejourfr/lib/core/models/*.dart`

→ Quand un DTO Java change, mettre à jour les 3.

## Identité visuelle (résumé)

- Bleu France `#1E3A8C` + Rouge France `#E1372F` (CTAs critiques seulement).
- **Plus Jakarta Sans** (web/mobile) ou **Inter** (admin), **Fraunces** (titres, `<em>`
  toujours rouge), **JetBrains Mono** (labels techniques, badges).
- **Règle absolue** : jamais hardcoder couleur ni font. Toujours passer par les tokens
  locaux (`var(--color-*)`, `AppColors.*`, `AppFonts.*`).

Détails complets (palette, dark/light, logo) → `docs/identite-visuelle.md`.

## API backend partagée

Base : `http://localhost:8080`. CORS dev autorise `localhost:3000` (web) et `localhost:5173`
(admin). Auth JWT Bearer (access ~60 min + refresh 30 j), **refresh automatique** dans le
client HTTP de chaque front.

Liste complète des endpoints → `docs/api-endpoints.md`.

## Démarrage local

```bash
# Backend (depuis backend_sejourfr/)
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
# DB : Postgres local, db = sejourfr_nouveau, user = diallomatine (cf. application-dev.yaml)
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

| Email                    | Mot de passe | Rôle  |
|--------------------------|--------------|-------|
| `admin@sejourfr.fr`      | `Admin123!`  | ADMIN |
| `user@sejourfr.fr`       | `User123!`   | USER  |
| `karim.test@sejourfr.fr` | `User123!`   | USER  |

## Architecture mentale par projet

Tous les fronts suivent l'organisation par feature (miroir du backend Java) :

- **Backend Java** : `entity/`, `repository/`, `manager/`, `service/`, `controller/`,
  `dto/`, `mapper/`, `specification/`, `security/`, `config/`, `exception/`, `enums/`
  (+ sous-module historique `audioquestion/` à part)
- **Admin React** : `features/{questions,themes,conversations,dashboard}/` + `api/`,
  `auth/`, `components/ui/`, `routes/`, `types/`
- **Web Next** : `app/{inscription,connexion,examen-blanc,paiement}/` + `app/_components/`
  + `lib/{api,types}.ts`
- **Mobile Flutter** : `screens/{auth,home,training,exam,question_runner,review,profile,…}/`
  + `core/{api,auth,models,router,theme,utils,widgets}/`

Le **runner de questions** (mobile `screens/question_runner/` et web
`examen-blanc/page.tsx`) est le composant le plus complexe — relire son CLAUDE.md local
avant de toucher.

### Convention backend Java : Controller → Service → Manager → Repository (strict)

- **Controllers** : ultra-fins, délèguent tout au service. Pas de logique, pas de mapping
  inline, pas d'accès repo. `@RequiredArgsConstructor` Lombok.
- **Services** : orchestrent un cas d'usage (validations, règles métier, transactions,
  mapping DTO). N'accèdent JAMAIS un `*Repository` directement — passent par les managers.
  Un service peut appeler plusieurs managers et d'autres services.
- **Managers** (`manager/`) : seule couche autorisée à appeler les `*Repository`. Wrappent
  JPA et exposent une API métier. Un manager par agrégat, même pour du CRUD trivial. `int
  limit` au lieu de `Pageable` quand suffisant ; `Specification + Pageable` quand la
  recherche est dynamique.
- **Mappers** : `@Component`, purs. Reçoivent l'entité + compléments en paramètres,
  retournent un DTO. Ne touchent ni repo ni manager. Si un mapping a besoin d'une lookup,
  le service la fait avant.
- **Lombok** : `@RequiredArgsConstructor` sur tous les controllers/services/managers/mappers.
  `@Slf4j` au lieu du `LoggerFactory.getLogger(...)`. Sur les entités JPA : `@Getter/@Setter`
  OK, **jamais `@Data`** ni `@EqualsAndHashCode` automatique (toString/equals + lazy loading
  = bugs).
- **Exception** : `audioquestion/` est un sous-module isolé non migré (refacto reportée).
  Ses services peuvent encore appeler `MediaRepository` direct.

## Préférences de collaboration (durables — à respecter à chaque tâche)

- **Pas de README ni de docs générés automatiquement.** Ne créer un `.md` que si
  l'utilisateur le demande.
- **Code direct + brèves explications.** Pas de récap de fin de message ni de narration
  d'étapes triviales.
- **Décisions structurantes** : proposer des options avec leurs tradeoffs, pas imposer.
- **Pas de Tailwind utility-first dans le markup web** — Tailwind v4 sert uniquement aux
  tokens via `@theme`. Styles dans `globals.css` ou `<style>` JSX scoped.
- **Responsive obligatoire (web + admin)** : tout écran fonctionne du mobile (~360 px) au
  desktop. Tester mentalement 360 / 768 / 1280 minimum. Pas de largeur fixe en px sans
  `max-width: 100%`, pas de grilles à colonnes fixes sans `@media` de repli, pas de
  tableaux sans alternative carte sur petit écran.
- **Admin & runner** : pas d'UI kit, pas de CSS-in-JS, pas de `clsx`. CSS Modules vanilla.
- **Mobile** : Riverpod uniquement (pas de Bloc/Provider/GetX), `context.go/push`
  (jamais `Navigator.push`), `withValues(alpha:)` (pas `withOpacity`).
- **Tous** : TypeScript/Dart strict, pas de `any`/`dynamic`, imports relatifs, pas de
  commentaire qui paraphrase le code.

### Hygiène d'architecture (non négociable)

La plateforme est faite pour durer, chaque ajout doit préserver une archi propre et
lisible — pas de patch rapide qui s'accumule.

- Tout nouveau fichier prend sa place dans l'arbo `feature/` existante (cf. CLAUDE.md
  local). Si une feature grossit, créer un dossier dédié.
- **Duplication = signal** : à la 2ᵉ occurrence, **extraire** un widget/util/service
  partagé (ex: `hub_widgets.dart`, `paywall_sheet.dart`). À 3 occurrences, c'est de la
  dette.
- **Refonte = suppression immédiate de l'ancien**. Quand un écran/route/composant est
  remplacé, supprimer le fichier + tous les imports + toutes les références CTA dans la
  foulée. Pas de cohabitation "au cas où".
- Respecter la convention de couches du backend Java et les conventions par sous-projet
  documentées dans chaque `CLAUDE.md` local. Pas d'exception "juste pour cette fois".

### Maintenir les `CLAUDE.md` à jour

Après une modif structurante (nouvelle feature, nouveau pipeline, changement de convention,
nouvelle migration importante, nouveau dossier `features/*`), mettre à jour le CLAUDE.md
local concerné et celui de la racine si la modif est transverse. Pas de changelog
exhaustif — juste de quoi qu'un futur Claude se repère vite. Inutile d'y consigner les
bugfixes ou les micro-ajustements.

## Paiements multi-source (Stripe + Apple + Google)

Le statut Premium est centralisé dans `user_subscriptions` (table backend). C'est
**la source de vérité unique**, alimentée par 3 canaux : Stripe (web), Apple
(iOS, IAP) et Google (Android, Play Billing). Le client ne décide JAMAIS s'il est
Premium — il lit le statut auprès du backend.

**Schéma `user_subscriptions`** (cf. migration V103) :
- `source` enum `STRIPE | APPLE | GOOGLE`
- `external_transaction_id` — id de transaction courant (change à chaque renouvellement)
- `original_transaction_id` — **clé de réconciliation**. Apple: `originalTransactionId`,
  Google: `purchaseToken`, Stripe: `subscription_id` ou `session_id` (one-shot).
  Stable sur toute la chaîne de renouvellements pour un même user/produit.
- `product_id` — SKU côté store ou `Plan.code` côté Stripe
- `auto_renew` — true pour les abonnements récurrents (Apple/Google), false en
  one-shot Stripe (changera au lot 4).
- Statuts : `ACTIVE`, `TRIAL`, `IN_GRACE`, `PENDING`, `CANCELED`, `EXPIRED`, `REFUNDED`.

**Index unique `(source, original_transaction_id)`** : un webhook de
renouvellement update la ligne existante, ne crée pas de doublon. Combiné avec
`processed_external_events` (provider, event_id), c'est la double défense contre
les replays.

**Agrégation Premium** : `SubscriptionService.currentSubscription(userId)` retourne
la souscription "qui compte" en cas de cumul — INTEGRAL > CIVIQUE, puis date de
fin la plus tardive. Exposée via `GET /api/billing/subscription-status`.

**Anti-double-paiement** : un user déjà Premium via Stripe télécharge l'app →
`subscription-status` renvoie `isPremium=true, source=STRIPE` → l'app mobile
masque le bouton d'achat IAP. Pareil dans l'autre sens.

**Endpoints** :
- `GET /api/billing/subscription-status` — authentifié, statut agrégé.
- `POST /api/billing/verify-receipt` — authentifié, l'app mobile soumet un reçu
  Apple/Google après achat. Backend re-vérifie côté store avant d'écrire.
- `POST /api/billing/webhook` — Stripe (signé HMAC).
- `POST /api/billing/webhooks/apple` — Apple ASSN V2 (JWS signé, à vérifier).
- `POST /api/billing/webhooks/google` — Google RTDN via Pub/Sub.

**État des lots** :
- **Lot 1 (✅ fait)** : schéma multi-source, migration V103, agrégateur,
  endpoints `subscription-status` + scaffolds verify-receipt / webhooks (501 ou
  log+200 tant que la validation store n'est pas en place).
- **Lot 2 (à faire)** : intégration Apple complète — lib `app-store-server-library`,
  JWT auth pour l'App Store Server API, validation JWS signedTransactionInfo,
  webhook ASSN V2 avec vérif chaîne de certifs Apple.
- **Lot 3 (à faire)** : intégration Google complète — `google-api-services-androidpublisher`,
  service account, `Purchases.subscriptionsv2.get`, webhook RTDN via Pub/Sub.
- **Lot 4 (à faire)** : refonte des plans en abonnements récurrents (mensuel /
  trimestriel), migration de Stripe Payment vers Subscription, alignement des 3
  fronts. Touche les 4 sous-projets.

## Git

- Remote : `git@github.com:diallomatine/sejourfr_opus_nouveau.git`
- Branche par défaut : `develop` (PRs vers `main`)
- Le repo racine est **un seul git** qui couvre les 4 dossiers — un commit peut toucher
  plusieurs surfaces (utile quand on aligne un DTO backend avec ses miroirs front).

## Documentation détaillée (`docs/`)

Référence à consulter quand le contexte le demande — pas chargé par défaut :

- `docs/api-endpoints.md` — liste complète des endpoints REST
- `docs/identite-visuelle.md` — palette complète, fonts, logo
- `docs/migrations-flyway.md` — convention de numérotation et arbo `db/migration/`
- `docs/lots-entrainement.md` — lots TCF/Civique (calcul dynamique sans schéma)
- `docs/exams-tcf.md` — examens module (CO/CE) et examen blanc TCF complet
- `docs/auth-social.md` — Google/Apple sign-in (backend + front, config env)
- `docs/pipeline-audio-co.md` — génération audio TCF CO (Claude → Azure Speech → R2)
- `docs/pipeline-evaluation-eo-ee.md` — éval EO/EE (Whisper → Claude/OpenAI → R2 privé)
- `docs/refonte-entrainement.md` — statut refonte hubs Civique/TCF (mobile + web)
- `docs/roadmap.md` — roadmap commune (Stripe, refresh JWT web, tests, etc.)
- `docs/audio-pipeline/` — spec exhaustive du pipeline audio CO (10 fichiers)
