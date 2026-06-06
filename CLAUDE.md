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
- **QuestionType** : `CONNAISSANCE` / `MISE_SITUATION` (civique) · `CO` / `CO_IMAGE` / `CE` /
  `STRUCTURE` (TCF). `CO_IMAGE` = format de Compréhension orale « image + 4 propositions
  lues » : `media_id` porte l'image, `audio_media_id` l'audio, choix en lettres A/B/C/D.
  Tiré dans les mêmes pools que `CO` (un filtre `CO` inclut `CO_IMAGE`). Publié depuis un
  `audio_question_draft` portant une image (`inline_svg` ou `image_url`). Image
  remplaçable côté admin via `POST /api/admin/{questions,audio-drafts}/{id}/image` (R2).
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

## Freemium (validé 2026-06-06, source backend)

- **Guest (web)** : navigation libre des hubs ; **série 1** offerte par thème
  civique / (épreuve TCF × niveau) et **examen diagnostic complet 1** par
  module (templates free de /examens-blancs), joués en anonyme (attempt
  `user NULL` + `clientIp` — sert d'analytics « combien se testent »). Tirages
  guests déterministes. Série 2+/examen 2+ → inscription. `GET /api/public/lots`
  + `POST /api/public/attempts/demo` (TRAINING lotNumero=1 ou MOCK_EXAM
  template free). **Examens ciblés** (thème civique / épreuve TCF) et EE/EO :
  compte obligatoire — le backend renvoie 403 sur un MOCK_EXAM guest avec
  themeId ou moduleExamQuestionType ; côté web les pages `*/examens` restent
  des vitrines (grille visible, tout verrouillé → GuestGateSheet).
- **Compte gratuit, EE/EO** : 1 essai d'entraînement par épreuve à vie + 1
  examen blanc production offert. L'examen est marqué `attempts.slot_number=1`
  au start (`ProductionAttemptStartRequest.exam`) ; ses soumissions bypassent
  le quota d'entraînement. Refaire l'examen 1 = toléré une fois mais consomme
  les essais d'entraînement restants ; une session ne compte que si ≥ 1 tâche
  soumise. Règles dans `ProductionSubmissionService` /
  `AttemptService.startProductionAttempt`. QCM : série 1 gratuite, 2+ premium.

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
- `POST /api/billing/cancel` — authentifié, résiliation de l'abonnement courant.
  Routing selon `source` via `SubscriptionCancellationService` : Stripe →
  `cancel_at_period_end=true` côté API + statut local CANCELED (réponse
  `action=DONE`) ; Apple/Google → réponse `action=REDIRECT` vers
  `apps.apple.com/account/subscriptions` ou `play.google.com/store/account/subscriptions`
  (les stores n'autorisent pas l'annulation serveur). Le statut local Apple/Google
  N'EST PAS modifié — c'est le webhook qui tranche quand l'user confirme côté store.
- `POST /api/admin/subscriptions/{id}/cancel` — admin (ROLE_ADMIN), même routing
  via `cancelSubscriptionById`. Rejette en 409 si statut non cancellable
  (CANCELED / EXPIRED / REFUNDED). Pour Apple/Google l'admin reçoit le `REDIRECT`
  comme l'user — à charge pour le support de transmettre l'URL au client.

**Emails transactionnels Premium** (`MailService.sendSubscriptionActivatedEmail`
+ `sendSubscriptionCanceledEmail`) :
- **Activation** envoyée une fois lors de la première souscription. Triggers :
  Stripe `handleCheckoutCompleted` quand création neuve ; Apple/Google
  `activateFromReceipt` quand la ligne `user_subscriptions` n'existait pas
  encore (les restaurations sur un originalTransactionId connu n'envoient pas).
- **Premier achat vs prolongation (achat unique)** : `OneTimeAccessService`
  distingue les deux selon qu'un accès de module ≥ était déjà en cours
  (`currentEndForAtLeast`). Premier achat → `sendSubscriptionActivatedEmail`
  (bienvenue) ; prolongation → `sendAccessExtendedEmail` (template
  `access-extended.html`, wording « durées cumulées, accès ouvert jusqu'au … »).
- **Résiliation** envoyée sur transition `oldStatus ≠ CANCELED → newStatus = CANCELED`.
  Triggers : `SubscriptionCancellationService.cancelStripe` (cancel via notre
  endpoint, le webhook qui arrive après ne renvoie pas car oldStatus est déjà
  CANCELED) ; webhook Stripe `customer.subscription.updated` (user annule
  directement dans Stripe), Apple `DID_CHANGE_RENEWAL_STATUS`, Google
  `subscriptionsv2.get` → SUBSCRIPTION_STATE_CANCELED. Pas de mail sur
  expiration naturelle ni sur refund/revoke (sémantique différente).
- **Templates HTML externalisés** dans `backend_sejourfr/src/main/resources/mail/`
  (`layout.html` + un fragment par email : `access-activated`, `access-expiring`,
  `subscription-canceled`, `password-reset`, `email-change`), rendus par
  `MailTemplateRenderer` (placeholders `{{escaped}}` / `{{{raw}}}`). Inline CSS
  (compat Gmail/Outlook) + preheader, logo en image inline CID depuis
  `resources/static/mail/logo.png`. **Tous** les emails clients (y compris reset
  mot de passe + changement d'email) passent par ce layout brandé.
- **Wording achat unique** : aucun « abonnement » / « renouvellement automatique »
  côté client. `sendSubscriptionActivatedEmail(..., boolean autoRenew)` —
  `autoRenew=false` (achat unique : « accès ouvert jusqu'au … ») posé par
  `OneTimeAccessService` ; `autoRenew=true` (récurrent dormant : « prochain
  renouvellement… ») posé par les flux Stripe/Apple/Google abonnement.
  `sendSubscriptionCanceledEmail` n'est déclenché que par ces flux dormants.
- Envoi **asynchrone** (`@Async` sur `sendSubscriptionActivatedEmail` /
  `sendSubscriptionCanceledEmail`, `@EnableAsync` global) : le SMTP est hors du
  chemin critique, donc `verify-receipt`/`cancel` répondent sans attendre l'envoi
  (sinon un SMTP lent/injoignable bloquait la requête ~15-20 s). Un mail raté log
  warn sans propager (cf. pattern reset password).
- `POST /api/billing/webhook` — Stripe (signé HMAC).
- `POST /api/billing/webhooks/apple` — Apple ASSN V2 (JWS signé, à vérifier).
- `POST /api/billing/webhooks/google` — Google RTDN via Pub/Sub.

**État des lots** :
- **Lot 1 (✅ fait)** : schéma multi-source, migration V103, agrégateur,
  endpoints `subscription-status` + scaffolds verify-receipt / webhooks.
- **Lot 2 (✅ fait)** : intégration Apple complète — lib
  `app-store-server-library` 5.2.0, vérif JWS (transactions + notifications +
  renewal info), App Store Server API client. `verify-receipt` branch APPLE
  + webhook `/webhooks/apple` opérationnels (idempotence via
  `processed_external_events`, anti-account-stealing en 409, mapping
  `NotificationTypeV2` → `SubscriptionStatus`). Mapping productId → Plan
  via colonnes `plans.apple_product_id` (migration V104).
- **Lot 3 (✅ fait)** : intégration Google Play Billing complète — lib
  `google-api-services-androidpublisher` + `google-auth-library-oauth2-http`,
  Service Account JSON, `purchases.subscriptionsv2.get` pour l'état autoritatif,
  webhook RTDN via Pub/Sub avec vérification du Bearer JWT (signature, audience,
  email SA). `verify-receipt` branch GOOGLE + webhook `/webhooks/google`
  opérationnels (idempotence via `messageId` Pub/Sub, anti-account-stealing en
  409, mapping `subscriptionState` → `SubscriptionStatus`).
- **Lot 4 (✅ backend fait)** : refonte des plans en abonnements récurrents.
  6 SKUs (Civique + Intégral × mensuel/trimestriel/annuel) + Free. Stripe
  passe en mode `SUBSCRIPTION` (Checkout Session). Stripe Price ID stocké
  sur `plans.stripe_price_id` (migration V105). Webhooks étendus :
  `customer.subscription.created/.updated/.deleted` + `charge.refunded`.
  Endpoint `/payment-link?planCode=<string>` (l'enum `BillingPlan` supprimé).
  Logique extraite dans `service/billing/StripeSubscriptionService` par
  symétrie avec Apple/Google.
- **Lot 4b (à faire, web)** : refonte page `/paiement` avec 3 plans × 3
  périodicités (toggle mensuel/trimestriel/annuel), portail client Stripe
  pour gérer l'abonnement (annuler, changer de plan). API existant
  `/api/billing/plans` renvoie déjà tous les plans actifs.
- **Lot 4c (✅ fait, admin)** : `features/plans/` (table + modal d'édition
  prix/active/store IDs) + `features/subscriptions/` (liste paginée avec
  filtres source/status/module + recherche + modal détail). Backend :
  `GET /api/admin/plans` + `PATCH /api/admin/plans/{id}` +
  `GET /api/admin/subscriptions?…` avec Specifications JPA pour les filtres
  dynamiques + UserSubscriptionMapper.
- **Lot 4d (✅ fait, mobile)** : IAP natif Apple StoreKit + Google Play
  Billing via package `in_app_purchase`. Écran paywall plein écran avec
  toggle périodicité (mensuel/trimestriel/annuel) + 2 cards Civique/Intégral.
  `BillingController` orchestre purchaseStream → verify-receipt → refresh
  AuthUser. Restoration via bouton "Restaurer". L'ancien `openSubscriptionWeb`
  (redirect web) est supprimé — non conforme Apple 3.1.1 dès qu'on vend du
  contenu digital. Cf. `mobile_sejourfr/CLAUDE.md` section "In-App Purchase".
- **Lot 4d (à faire, mobile)** : UI paywall mensuel/trimestriel/annuel,
  branchement package `in_app_purchase`, appel `/verify-receipt` après
  achat, lecture `/subscription-status` au boot.

⚠ **Cassure connue après lot 4** : le web `/paiement` actuel envoie
`?plan=BillingPlan` (CIVIQUE_3MOIS / INTEGRAL_3MOIS) ; il sera 400 jusqu'à
ce que le lot 4b mette à jour l'appel en `?planCode=<string>`.

- **Lot 5 (bascule achat unique — feature-flaggée)** : le produit vend des
  **passes d'accès à durée fixe** (paiement unique, sans reconduction), au lieu
  d'abonnements. Catalogue : Civique 3 mois (9,99) / 1 an (29,99) ; Intégral
  sprint 6 sem (19,99) / 3 mois (35,99) / 1 an (79,99). Modèle : paiement →
  `user_subscriptions` `ACTIVE`, `auto_renew=false`, `ends_at = paiement +
  plans.duration_days` (durée posée par le **backend**, pas le store) ;
  expiration **lazy** à la lecture (`SubscriptionService.isCovering`), pas de
  job. Prolongation cumulative par module (`grantOneTimeAccess`), idempotente
  sur `(source, original_transaction_id)`. **Proration** uniquement à l'upgrade
  Civique→Intégral **côté Stripe** (crédit du reste du pass Civique, on facture
  la différence) — Apple/Google vendent à prix fixe, pas de proration.
  - Backend : `PlanPurchaseType` + `plans.purchase_type`/`duration_days` (V417/
    V418, les 6 plans récurrents passent `is_active=FALSE`, conservés) ;
    `BillingProperties` (`billing.mode`) ; `OneTimeAccessService.grantOneTimeAccess`
    (commun aux 3 canaux) ; Stripe Checkout `mode=PAYMENT` + `price_data`
    dynamique (montant = `plans.price`, **aucun Stripe Price à créer**) ; Apple
    accepte Non-Renewing/Consumable (bypass du garde-fou AUTO_RENEWABLE) ; Google
    `purchases.products.get` + acknowledge, RTDN `voidedPurchaseNotification`.
    `SubscriptionStatusResponse.oneTime` expose la nature aux fronts.
  - Mobile : paywall en **grille de passes** (pilotée par `purchaseType`),
    `buyConsumable` (passes ré-achetables), « Mon accès » sans résiliation.
  - Stores : produits **Consommables** (Apple) / **managed in-app** (Google),
    product IDs = `Plan.code` (Apple MAJ, Google minuscules). Guide pas-à-pas →
    `docs/setup-paiement-one-time.md`.

> **⚠️ RÉVERSIBILITÉ — ne JAMAIS supprimer le code abonnement (lots 2/3/4).** La
> bascule est pilotée par le flag `sejourfr.billing.mode` (`SUBSCRIPTION |
> ONE_TIME`, env `BILLING_MODE`) **+** le drapeau `is_active` : les deux jeux de
> plans coexistent en base. `StripeSubscriptionService`, les handlers webhook
> récurrents Apple/Google, le toggle paywall et l'écran de résiliation restent
> en place, **dormants**. Revenir aux abonnements selon le succès du projet =
> `BILLING_MODE=SUBSCRIPTION` + réactiver les 6 plans récurrents (`V106`) +
> désactiver les 5 passes. Aucune migration destructive, aucun rebuild.

**Setup Apple (lot 2)** :
1. **App Store Connect → Users and Access → Integrations → App Store Server API**
   → générer une clé. Télécharger le P8 (téléchargeable une seule fois). Noter
   l'`Issuer ID` (team-level, UUID) et le `Key ID` (10 caractères).
2. **Root certs Apple** — déposer dans
   `backend_sejourfr/src/main/resources/apple/`, depuis la section *Root
   Certificates* de https://www.apple.com/certificateauthority/ :
   - `AppleRootCA-G3.cer` (**obligatoire**, chaîne de signature actuelle des JWS Apple)
   - `AppleRootCA-G2.cer` (par sécurité)
   - `AppleIncRootCertificate.cer` (legacy, par sécurité)
   ⚠ L'ancien « Apple Computer, Inc. Root Certificate » n'est plus téléchargeable
   (seule sa CRL subsiste) et n'est plus utilisé — ne pas le chercher.
   `SignedDataVerifier` accepte un `Set` de racines ; seul G3 est réellement
   requis. Ne pas commiter de bouchons : le bean `AppleStoreClient` détecte
   l'absence et reste en mode 503.
3. **Variables d'env** : `APPLE_ISSUER_ID`, `APPLE_KEY_ID`,
   `APPLE_PRIVATE_KEY` (contenu du P8 brut), `APPLE_BUNDLE_ID`,
   `APPLE_APP_ID` (numérique, prod uniquement), `APPLE_ENVIRONMENT`
   (`SANDBOX` en dev / TestFlight, `PRODUCTION` en App Store).
4. **App Store Connect → Subscriptions** : créer les produits IAP (SKUs
   définis au lot 4 quand les abonnements récurrents seront en place), puis
   mettre à jour `plans.apple_product_id` en base via SQL.
5. **App Store Connect → App Information → App Store Server Notifications →
   V2** : pointer Production URL et Sandbox URL sur
   `https://<host>/api/billing/webhooks/apple`.

**Notifications Apple gérées** (`NotificationTypeV2`) :
- `SUBSCRIBED`, `DID_RENEW`, `OFFER_REDEEMED` → status ACTIVE, `expiresDate`
  rafraîchi.
- `EXPIRED`, `GRACE_PERIOD_EXPIRED` → status EXPIRED.
- `DID_FAIL_TO_RENEW` + `subtype=GRACE_PERIOD` → status IN_GRACE.
- `DID_FAIL_TO_RENEW` sans subtype → état inchangé (l'abonnement court jusqu'à
  `expiresDate`).
- `DID_CHANGE_RENEWAL_STATUS` + `AUTO_RENEW_DISABLED` → status CANCELED
  (Premium reste ouvert jusqu'à `expiresDate`).
- `DID_CHANGE_RENEWAL_STATUS` + `AUTO_RENEW_ENABLED` → status ACTIVE si on
  était CANCELED.
- `REFUND`, `REVOKE` → status REFUNDED (Premium retiré immédiatement).
- `REFUND_REVERSED` → ACTIVE si `expiresDate` couvre encore.
- `DID_CHANGE_RENEWAL_PREF` → log seulement (changement pour prochain
  renouvellement, pas d'impact courant).
- Autres types (`PRICE_INCREASE`, `METADATA_UPDATE`, `TEST`, `MIGRATION`,
  `PRICE_CHANGE`, `CONSUMPTION_REQUEST`, `RENEWAL_EXTENDED`, ...) → log debug,
  pas d'impact sur l'accès Premium.

**Limites assumées** : Family Sharing pas géré (un `originalTransactionId`
rattaché à User A est verrouillé sur lui — un autre user qui tenterait avec
le même reçu reçoit 409). Seul `AUTO_RENEWABLE_SUBSCRIPTION` est accepté ; les
NON_CONSUMABLE / CONSUMABLE / NON_RENEWING_SUBSCRIPTION renvoient 400.

**Setup Google Play (lot 3)** :
1. **Google Cloud Console → IAM → Service Accounts** : créer un SA dédié,
   générer une clé JSON. Le SA doit avoir le rôle minimal "Service Account
   User".
2. **Play Console → Setup → API access** : lier le compte Google Cloud,
   accorder à ce SA les permissions "View financial data" + "Manage orders
   and subscriptions" (pour pouvoir lire les abonnements et accepter les
   refunds).
3. **Cloud Console → Pub/Sub** : créer un topic (ex: `play-rtdn`), puis une
   subscription **push** :
   - Endpoint : `https://api.sejourfr.fr/api/billing/webhooks/google`
   - Authentication : activer "Enable authentication", choisir un Service
     Account (peut être un SA dédié à Pub/Sub, distinct de celui du Play API)
   - Audience : URL exacte de l'endpoint (claim `aud` du JWT)
4. **Play Console → Monetization setup → Real-time developer notifications** :
   pointer le Cloud project + le topic créé.
5. **Variables d'env** :
   - `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` (contenu JSON brut de la clé SA)
   - `GOOGLE_PLAY_PACKAGE_NAME` (ex: `com.sejourfr.app`)
   - `GOOGLE_PUBSUB_AUDIENCE` = URL du webhook
   - `GOOGLE_PUBSUB_SA_EMAIL` = email du SA configuré sur la push subscription
6. **Play Console → Subscriptions** : créer les produits IAP (SKUs définis au
   lot 4), puis `UPDATE plans SET google_product_id = ...` en base.

**RTDN gérées** (`subscriptionNotification.notificationType` int + état refetché) :
- Tous types (sauf REVOKED) déclenchent un appel `subscriptionsv2.get` qui
  donne l'état autoritatif. Le mapping `subscriptionState` → `SubscriptionStatus` :
  - `SUBSCRIPTION_STATE_ACTIVE` → ACTIVE
  - `SUBSCRIPTION_STATE_CANCELED` → CANCELED (Premium ouvert jusqu'à `expiryTime`)
  - `SUBSCRIPTION_STATE_IN_GRACE_PERIOD` → IN_GRACE
  - `SUBSCRIPTION_STATE_ON_HOLD` / `PAUSED` / `EXPIRED` → EXPIRED
  - `SUBSCRIPTION_STATE_PENDING` → PENDING (pas de Premium)
  - `SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED` → REFUNDED
- `SUBSCRIPTION_REVOKED` (12) → REFUNDED + autoRenew=false **immédiatement**,
  sans attendre le refetch (l'API peut encore renvoyer ACTIVE temporairement).
- `testNotification` → log, no-op.

**Idempotence Google** : Pub/Sub livre at-least-once. On stocke chaque
`message.messageId` traité dans `processed_external_events` (provider=`google`).
Un replay du même messageId est silencieusement skipé.

**Différence sémantique vs Apple** : la RTDN ne porte PAS l'état détaillé —
juste "ça a changé sur ce purchaseToken". On appelle TOUJOURS l'API
`subscriptionsv2.get` pour avoir l'état autoritatif. Côté Apple à l'inverse,
le `signedTransactionInfo` inclus dans la notification est déjà autoritatif
(JWS signé), pas besoin d'appel API.

**Setup Stripe Subscription (lot 4)** :
1. **Stripe Dashboard → Products** : créer 2 Products ("Civique" et
   "Intégral"). Pour chacun, créer 3 prix récurrents (mensuel / trimestriel /
   annuel). Noter les 6 Price IDs (format `price_xxx`).
2. **Base de données** : `UPDATE plans SET stripe_price_id = 'price_xxx'
   WHERE code = 'CIVIQUE_MONTHLY'` etc., pour les 6 plans créés en V106.
3. **Variables d'env Stripe** simplifiées : `STRIPE_SECRET_KEY` +
   `STRIPE_WEBHOOK_SECRET` + `APP_BASE_URL` (les anciens
   `STRIPE_PRICE_*` / `STRIPE_PAYMENT_LINK_*` ne sont plus lus).
4. **Stripe Dashboard → Webhooks → Add endpoint** : pointer
   `https://api.sejourfr.fr/api/billing/webhook`, sélectionner les events :
   `checkout.session.completed`, `customer.subscription.created`,
   `customer.subscription.updated`, `customer.subscription.deleted`,
   `charge.refunded`.

**Events Stripe gérés** (cf. `StripeSubscriptionService`) :
- `checkout.session.completed` (mode=SUBSCRIPTION) → init UserSubscription,
  fetch la Subscription Stripe et applique son état. Les sessions en mode
  PAYMENT (héritage one-shot) sont ignorées.
- `customer.subscription.created/.updated` → mise à jour de l'état :
  - status `active` + `cancel_at_period_end=false` → ACTIVE
  - status `active` + `cancel_at_period_end=true` → CANCELED (Premium ouvert
    jusqu'à `current_period_end`)
  - status `trialing` → TRIAL
  - status `past_due` / `unpaid` → IN_GRACE (Stripe Smart Retries)
  - status `incomplete` → PENDING
  - status `canceled` → CANCELED (ou EXPIRED si ends_at passé)
  - status `paused` → EXPIRED
- `customer.subscription.deleted` → EXPIRED immédiat.
- `charge.refunded` → REFUNDED (Premium retiré).

**Clé d'unicité Stripe** : `(STRIPE, subscription.id)` (sub_xxx). Stable sur
toute la chaîne de renouvellements. Les events arrivant pour un
subscription_id inconnu (race avec checkout.session.completed) sont logués
et ignorés.

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
- `docs/setup-paiement-one-time.md` — passes achat unique (lot 5) : setup Stripe/Apple/Google pas-à-pas + SKU
- `docs/pipeline-audio-co.md` — génération audio TCF CO (Claude → Azure Speech → R2)
- `docs/pipeline-evaluation-eo-ee.md` — éval EO/EE (Whisper → Claude/OpenAI → R2 privé)
- `docs/refonte-entrainement.md` — statut refonte hubs Civique/TCF (mobile + web)
- `docs/roadmap.md` — roadmap commune (Stripe, refresh JWT web, tests, etc.)
- `docs/audio-pipeline/` — spec exhaustive du pipeline audio CO (10 fichiers)
