# Audit Phase 0 — Dashboard « Suivi » (tunnel diagnostic) — 2026-09-25

> Périmètre : `docs/admin/brief-analytics-diagnostic.md` (§13 Phase 0) + template
> `docs/admin/sejourfr-suivi-dashboard.html` + demande du propriétaire (remplacer `/dashboard`,
> supprimer `/audience`). **Aucun code modifié.** Légende : **[V]** = fait vérifié dans le code
> (fichier:ligne), **[S]** = supposition non vérifiée, **[D≠C]** = la doc dit autre chose que le code.
> Chemins courts : `BE` = `backend_sejourfr/src/main/java/com/sejourfr/app`,
> `MIG` = `backend_sejourfr/src/main/resources/db/migration`, `WEB` = `web_sejoufr`,
> `MOB` = `mobile_sejourfr/lib`, `ADM` = `admin_sejourfr/src`.

---

## 0. Résumé exécutif

1. **Un système Analytics complet existe déjà** (V043, 2026-08-21) : `analytics_visitor` (first/last touch), `analytics_event` (allowlist, `dedup_key`), `analytics_identity` (anonyme ⇄ compte), ingestion publique rate-limitée, écran admin `/dashboard` à 5 onglets (5 544 lignes). Le brief propose en grande partie **des doublons** de ces tables : on **étend**, on ne recrée pas.
2. **La route `/audience` n'existe plus côté admin** [V] : elle a été supprimée le 2026-08-21. En revanche, **son backend est resté orphelin** [V] : `AdminAudienceController`, `AudienceFunnel*`, `PageView*`, et `POST /api/public/page-views` (public, **sans rate-limit**). Ce sont eux qu'il faut supprimer.
3. **Écart n°1, le tunnel ne peut pas se lire aujourd'hui.** Le diagnostic TCF rapide invité ne laisse **aucune trace serveur** avant le compte (invariant V053). Aucun identifiant de tentative ne circule dans les événements. Et **`analytics_identity` n'est jamais écrite** : ni le web ni le mobile n'envoient `anonymousId` au login ou à l'inscription [V]. La liaison anonyme → compte est donc morte en pratique.
4. **Écart n°2, le revenu.** Seul le brut est stocké. Il n'y a ni TVA, ni frais, ni net, ni table de remboursements (seulement un statut `REFUNDED`). Aucune attribution d'achat n'existe (`metadata` Stripe = `planCode` seul, `appAccountToken` et `obfuscatedAccountId` inutilisés). Deux bugs faussent le brut : les montants store sont ignorés à cause d'un décalage de noms de champs, et l'anti-rejeu Stripe rejette les retries après 5 min.
5. **Découverte bloquante sur la TVA** : la facture Stripe porte « **TVA non applicable, art. 293 B du CGI** » (franchise en base) [V]. Le `vat_rate 20 %` du brief est donc **faux pour Stripe** tant que la franchise s'applique. Côté stores, la TVA est retenue par Apple/Google dans tous les cas.
6. **Recommandation** : un endpoint unique `GET /api/admin/analytics/suivi`, une feature admin `features/suivi/` qui **remplace** `features/analytics/`. On ajoute une table `diagnostic_run` (le fait « tentative de tunnel », sans contenu, ce qui préserve l'invariant V053), des colonnes de revenu sur `user_subscriptions`, une table `payment_refunds` et deux configs JSON versionnées (patron `*-config-v1.json` déjà en place).
7. **`store_commission.mode` : MULTIPLY** (seule formule conforme à la commission réelle), avec un taux **par store** en config.
8. **Questions bloquantes au STOP 0** : Q1 (TVA / franchise), Q2 (quel « diagnostic TCF »), Q3 (`diagnostic_run`), Q5 (rétention 760 j vs CNIL 13 mois), Q7 (template hors brief : visiteurs, sources, utilisation du plan), Q9 (ce qu'on perd de l'ancien dashboard).

---

## 1. Tables — existant vs brief §4

Prochaine migration de schéma libre : **`V074`** (dossier `00_schema/`, plage V001-V099 ; V059 est un trou volontaire, V879 est l'exception documentée) [V `docs/migrations-flyway.md:220-223`]. `out-of-order: true` est actif.

### 1.1 `users`

| Champ brief §3.4 | Existant | Origine |
|---|---|---|
| `created_at` | ✅ + index `idx_users_created_at WHERE deleted_at IS NULL` | V001 / V036:46 |
| `signup_platform` | ⚠️ existe, mais valeurs `WEB`/`MOBILE`/`UNKNOWN` (`ClientPlatform`) : **pas de iOS/Android** | V036:35-37 |
| `signup_source` (first-touch au compte) | ✅ existe, normalisé par `util/TrafficSource` | V036 |
| `signup_context`, `signup_diagnostic_type`, `signup_diagnostic_attempt_id`, `signup_anonymous_id` | ❌ absents. Un `registrationContext` n'existe que **côté client** (propriété de `SIGNUP_STARTED`, `AnalyticsRegistrationContext`) | — |
| `is_internal` | ❌ absent partout [V]. Remplacé par `sejourfr.analytics.excluded-emails` (`application.yaml:335`, 3 comptes seed), appliqué **seulement** aux requêtes côté compte, jamais côté visiteur | — |

### 1.2 Diagnostic : 3 flux, 3 tables, aucune n'est « attempts avec is_diagnostic »

| | TCF rapide (`QUICK_TCF`) | TCF complet 4 épreuves | Civique |
|---|---|---|---|
| Table | `diagnostic_sessions` (V029:55-84) | `tcf_diagnostic_sessions` (V049:52-85) | `civic_diagnostic_sessions` (V052:27-47, V053) |
| `user_id` | **NOT NULL** | NOT NULL | **nullable** depuis V053 (+ `client_ip`, CHECK porteur) |
| Lien attempts | `written_attempt_id` / `oral_attempt_id` (oral nullable V050) | `parent_attempt_id` + `attempts.tcf_diagnostic_id` | `attempt_id` + `attempts.civic_diagnostic_id` |
| `platform` | ✅ `varchar(16)` WEB/MOBILE (V036:51) | ❌ | ❌ |
| `started_at` / fin | `started_at`, `completed_at` ; **pas de `submitted_at`** (il vit sur `production_submissions`) | `started_at`, `expires_at`, `completed_at` | `started_at`, `completed_at` (clôture = `POST …/result`, authentifié) |
| Unicité | `UNIQUE (user_id, diagnostic_code, diagnostic_version)` → **un seul par version** | aucune (refaisable : 1er gratuit puis premium + 14 j) | aucune (refaisable : 1er gratuit puis premium + 14 j) |
| `anonymous_id`, `claim_token_hash`, `claim_token_expires_at`, `claimed_at`, `claimed_via`, `submitted_authenticated` | ❌ | ❌ | ❌ (la « claim » est une adoption par id de session + IP) |

**[D≠C]** `docs/regles/diagnostic.md:51-58` décrit le rapide comme « EE + EO ». Le code actif (`QUICK_TCF`, V757) ne comporte **que l'écrit** (V050).

### 1.3 Plan : pas de `plan_id` au sens du brief

- Il n'existe **aucune table `plan`** : le Plan est **dérivé à la lecture** (`LearningPlanService`). Collision de nom : `plans` désigne le **catalogue commercial** (V002 / V100 / V114).
- Ce qui est persisté : **`journey`** (V066/V067/V069, un cycle par `(user_id, module)`, statut `EN_COURS`/`EN_ATTENTE`/`HISTORISE`), `journey_step`, `journey_step_series` (V072, lien étape ⇄ attempt), `plan_pinned_priorities` (V065).
- **`journey.id` n'est exposé par aucun DTO** (`JourneyDto`, `JourneyCycleDto`) [V]. Candidat naturel pour `plan_id` → **Q8**.

### 1.4 Achats : `user_subscriptions` joue déjà le rôle de `purchases`

Colonnes [V `MIG/00_schema/V002__schema_billing.sql:38-58`, V019, V043:271-281] :
`id`, `user_id`, `plan_id`, `status`, `starts_at`, `ends_at`, `source` (STRIPE/APPLE/GOOGLE), `external_transaction_id`, `original_transaction_id` NOT NULL, `product_id`, `auto_renew`, `amount_cents`, `currency`, `amount_eur_cents`, `fx_rate_to_eur`, `realtime_eo_sessions_remaining`, `updated_at`, `created_at` [S : `created_at` à confirmer, sinon `starts_at` fait office de date d'achat].

| Champ brief §4.2 `purchases` | Existant |
|---|---|
| `provider_transaction_id` UNIQUE | ✅ `UNIQUE (source, original_transaction_id)` : `payment_intent` (Stripe), `transactionId` (Apple), `purchaseToken` (Google) |
| `payment_provider`, `product_id`, `currency` | ✅ |
| `gross_paid` | ⚠️ `amount_cents` / `amount_eur_cents`, **faux pour les stores** (bug §3.4) |
| `platform` | ❌ (déductible de `source` : STRIPE=WEB, APPLE=IOS, GOOGLE=ANDROID) |
| `vat_amount`, `provider_fee`, `net_after_fee`, `net_ex_vat`, `fee_source`, `revenue_rules_version` | ❌ |
| `origin`, `diagnostic_type`, `diagnostic_attempt_id`, `plan_id` | ❌ |
| `purchased_at` | ⚠️ `starts_at` ≠ date d'achat quand les pass s'empilent (le pass démarre à la fin du précédent) [V `OneTimeAccessService.java:114-118`]. **Ajouter `purchased_at`** |

Idempotence webhooks : `processed_external_events (provider, event_id)` PK (V002:65-70) [V].

### 1.5 Remboursements

❌ **Aucune table.** Un remboursement se traduit seulement par `status = 'REFUNDED'` sur la ligne. On ne garde ni montant, ni date, ni id de remboursement. **L'analytics actuel compte délibérément les remboursés dans le revenu** (`AnalyticsReadRepository.java:209-211`) [V].

### 1.6 Tables analytics existantes (V043, V036, V020)

| Table | Contenu clé | Verdict pour le brief |
|---|---|---|
| `analytics_visitor` (PK `anonymous_id`) | `first_seen_at`, `last_seen_at`, **first touch** `ft_source/medium/campaign/content/term/landing_path/referrer_host` (**jamais réécrit**), last touch `lt_*`, `country_code`, `device_type`, `platform` | = la partie `first_touch_*` d'`analytics_identity` du brief. **Réutiliser** |
| `analytics_event` | `id` PK serveur, `event varchar(48)`, `occurred_at`, `anonymous_id` NOT NULL (FK visitor), `session_id`, `user_id` NULL, `path`, `properties jsonb` (clés allowlistées **par événement**), `dedup_key` UNIQUE | ≈ `analytics_event` du brief. **Étendre** avec `received_at`, `platform`, `app_version`, `diagnostic_type`, `diagnostic_run_id`, `journey_id`. Garder `dedup_key` comme clé de dédup (le client y met son `event_id`). Garder le nom de colonne `event` |
| `analytics_identity` (PK `(anonymous_id, user_id)`, `linked_at`) | N ⇄ N (appareil partagé) | ≈ celle du brief (qui est N → 1). **Réutiliser**. Le first touch reste sur `analytics_visitor` |
| `analytics_annotation` | repères de courbe | Sans lecteur dans le template → **Q9** |
| `user_funnel_events` (V036) | `UNIQUE(user_id, event)` : `PAYWALL_VIEWED`, `SUBSCRIBE_CLICKED`, `CHECKOUT_STARTED` | Sans lecteur dans le template → **Q10** |
| `page_views` (V020/V030) | legacy, plus écrite par aucun front | La table reste en base (doctrine « donnée réelle »). Seul le code part (§6) |

---

## 2. Parcours diagnostic anonyme actuel

| | TCF rapide | TCF complet | Civique |
|---|---|---|---|
| Accessible sans compte ? | **Oui**, web `/diagnostic` + mobile `/diagnostic` (routes publiques) [V] | **Non** : aucune route publique, le mobile redirige vers login [V] | **Oui**, web `/diagnostic-civique` + mobile [V] |
| Création serveur au démarrage en invité ? | **Non.** `GET /api/public/diagnostics/current` sert les sujets seulement. Rien n'est persisté avant le compte (invariant V053, `diagnostic_sessions.user_id NOT NULL`) [V] | n/a (`POST /api/tcf-diagnostics` authentifié) | **Oui, au 1er tirage** : `POST /api/public/civic-diagnostics` crée l'attempt invité (`user_id NULL`, `client_ip`) et la session [V `CivicDiagnosticService.java:110-176`] |
| Où vit la soumission avant le compte | **Sur l'appareil** : IndexedDB `sejourfr-diagnostic` (web), SharedPreferences + fichier audio (mobile) | — | **Sur le serveur** (`answers` via `/api/public/attempts/{id}/answers`) ; l'appareil ne garde que 2 UUID (`sejourfr.civic-diagnostic.invite`) |
| Rattachement au compte | **Rejeu (« handoff »)** après auth : `POST /api/diagnostics`, puis `POST /api/production-submissions` avec `clientSubmissionId`, puis purge locale (`DiagnosticView.tsx:465-573`, `diagnostic_controller` mobile `:421-556`). **Compte ayant déjà son diagnostic ⇒ productions abandonnées** (HandoffNotice) | — | **Adoption** : `POST /api/civic-diagnostics/{id}/adopt` (id + IP identique ; quota du compte appliqué) [V `CivicDiagnosticService.java:313-345`] |
| Identifiant de tentative dans les événements | ❌ aucun (`diagnosticType` toujours `rapid`/`RAPID`) | ❌ | ❌ |
| « Soumis » côté serveur | seulement **après** le compte (production reçue). Avant : événement client `DIAGNOSTIC_ACCOUNT_REQUIRED` | `completed_at` | l'attempt invité est fini par `POST /api/public/attempts/{id}/finish` [S : `finished_at` posé, à confirmer]. Le résultat exige le compte |
| Refaire | impossible pour une même version | oui (1er gratuit, puis premium + 14 j) | oui (1er gratuit, puis premium + 14 j) |

**Conséquences pour le tunnel du brief :**
- **TCF rapide** : l'ordre « Soumis (2) → Compte rattaché (3) » n'a **aucun fait serveur** pour l'étape 2 en invité. Le brief suppose une tentative serveur créée au démarrage (§4.2 « à confirmer à l'audit ») : **ce n'est pas le cas, et le faire violerait l'invariant V053** (aucune production persistée avant le compte, choix délibéré). → **Q3**.
- **Civique** : la tentative serveur existe dès le tirage, mais elle est identifiée par l'IP, pas par un `anonymous_id`.
- ⚠️ **Risque** : `GuestAttemptPurgeJob` (livré **éteint**, rétention 2 h si on l'active) supprimerait les attempts civiques invités non adoptés. La mesure « soumis anonymes jamais rattachés » serait détruite. Sa propre Javadoc le dit [V `GuestAttemptPurgeJob.java`].

---

## 3. Paiements et webhooks

### 3.1 Ce qui est vendu (réalité vs brief)

Le brief a raison : **achat unique** [V]. `sejourfr.billing.mode` n'est défini dans aucun YAML, donc le défaut `ONE_TIME` s'applique (`BE/config/BillingProperties.java:18`). Grille active [V V100/V114] :

| Code | Prix | Durée |
|---|---|---|
| `CIVIQUE_PASS_3M` | 9,99 € | 90 j |
| `CIVIQUE_PASS_1Y` | 29,99 € | 365 j |
| `INTEGRAL_PASS_7J` | 9,99 € | 7 j |
| `INTEGRAL_PASS_1M` | 19,99 € | 30 j |
| `INTEGRAL_PASS_2M` | 29,99 € | 60 j |

Les produits sont **consommables** côté Apple et Google. Le code d'abonnement est toujours là, mais inactif. Racheter un pass **s'empile** : le nouveau démarre à la fin du précédent.

### 3.2 Webhooks

| | Stripe | Apple | Google |
|---|---|---|---|
| Endpoint | `POST /api/billing/webhook` (`BillingController.java:147`) | `POST /api/billing/webhooks/apple` (`BillingWebhookController.java:37`) | `POST /api/billing/webhooks/google` (`:51`) |
| Vérif | signature `Webhook.constructEvent` | JWS `SignedDataVerifier` + certificats racine | JWT Pub/Sub (audience + service account) |
| Idempotence | `processed_external_events("stripe", event.id)` + `UNIQUE(source, original_transaction_id)` | `("apple", notificationUUID)` | `("google", messageId)` |
| Achat | `checkout.session.completed` (mode `PAYMENT`, `price_data` dynamique) | **pas de webhook d'achat** : c'est `verify-receipt` (JWS envoyé par l'app) qui crédite | idem, `verify-receipt` + `purchases.products.get` + acknowledge |
| Attribution transportable | `metadata` = **`planCode` seul** + `client_reference_id = userId` | `appAccountToken` **jamais posé** | `obfuscatedAccountId` / `ProfileId` **jamais posés** |
| Remboursement | `charge.refunded` → `REFUNDED` (**partiel traité comme total**) | `REFUND` / `REVOKE` → `REFUNDED` (`REFUND_REVERSED` ignoré en one-time) | `voidedPurchaseNotification` → `REFUNDED` (pas de rattrapage Voided Purchases API) |

⚠️ **Écart avec le brief §5** (« Achat = webhook uniquement ») : sur mobile, l'achat est **crédité par `verify-receipt`** (appel client vérifié serveur), pas par une notification store. C'est la **ligne `user_subscriptions`** qui fait foi, quel que soit le chemin. **Garder ce fait comme source** : exiger le webhook pour Apple/Google retarderait ou perdrait des achats.

### 3.3 Montants stockés

- **Brut seulement.** Stripe : `session.amount_total` [V `StripeSubscriptionService.java:197-200`]. Apple et Google : prix envoyé par le client, sinon `plans.price`.
- Aucune lecture de `balance_transaction`, de frais ou de TVA. Pas d'`automatic_tax`.
- Autorité unique d'écriture : `service/billing/MontantEncaisse` + `MontantEncaisseResolver`. **À étendre**, pas à doubler.

### 3.4 Bugs trouvés (hors périmètre strict, mais ils faussent le CA du dashboard)

1. **Montants store ignorés** [V] : le backend attend `rawPrice` / `currencyCode` (`dto/VerifyReceiptRequest.java:36-42`), le mobile envoie `amountCents` / `currency` (`MOB/core/models/billing_models.dart:414-422`). Jackson les ignore en silence, donc **toute ligne Apple/Google = `plans.price` en EUR**.
2. **Anti-rejeu Stripe à 300 s** [V `BillingService.java:435-444`] : Stripe garde le `created` d'origine sur ses retries. **Tout retry au-delà de 5 min est rejeté en 400, définitivement** : un achat peut ne jamais être crédité.
3. `payment_status` de la Checkout Session non vérifié [S : un moyen de paiement différé serait crédité avant encaissement].
4. Tests one-time Apple (dont remboursement) et `voidedPurchaseNotification` Google : **aucun test** [V].

→ **Q11** : les corriger dans ce chantier (lot 2) ou à part.

---

## 4. Identité

| | Web | Mobile |
|---|---|---|
| `anonymous_id` | UUID v4 en **localStorage** `sejourfr.aid` (pas un cookie), 13 × 30 j (`WEB/lib/analytics.ts:153-252`) | UUID v4 en **SharedPreferences** `sejourfr.analytics.anonymousId`, 396 j (`MOB/core/analytics/analytics_identity.dart:34-42`) |
| Transport | **corps JSON** de `POST /api/public/analytics/events` seulement ; **aucun en-tête** | idem (via Dio) |
| En-têtes envoyés | `X-Sejourfr-Client: web`, `X-Sejourfr-Source` si détectée (`WEB/lib/api.ts:395-400`) ; **les envois analytics contournent ce client** (sendBeacon, sans en-tête) | `X-Sejourfr-Client: mobile`, `User-Agent: SejourFR (ios\|android)`, `X-Sejourfr-Source` **jamais posé** (`remember()` n'a aucun appelant) |
| iOS vs Android | n/a | **seulement via User-Agent** (`DeviceTypeResolver`) |
| Version d'app | — | ❌ (pas de `package_info_plus`) |
| Liaison anonyme → compte | Backend prêt (`anonymousId` optionnel sur `LoginRequest`, `RegisterRequest`, `GoogleSignInRequest`, `AppleSignInRequest` ; `AuthService.java:85`, `SocialAuthService.java:74,82`), **mais aucun front ne l'envoie** [V : grep `anonymousId` hors module analytics = 0 résultat web, 0 mobile] | idem |

Côté serveur, aucun `X-Anonymous-Id`, `X-Platform` ni `X-App-Version` n'est lu [V]. Conventions existantes : préfixe `X-Sejourfr-*`, résolution centralisée dans `util/ClientContextResolver` (patron `ClientIpResolver`).

**Recommandation** : suivre la convention du repo plutôt que les noms du brief. En-têtes `X-Sejourfr-Anonymous-Id`, `X-Sejourfr-App-Version`, et **élargir `X-Sejourfr-Client` à `web|ios|android`** (`mobile` reste accepté et vaut `UNKNOWN_MOBILE`). Tout est posé par **un seul point de câblage** par front (`lib/api.ts`, `BaseOptions` Dio) et lu par `ClientContextResolver`. → **Q4**.

---

## 5. Instrumentation existante

- **Ingestion** : `POST /api/public/analytics/events` (`PublicAnalyticsController`) : **un événement par appel** (pas de lot), 204.
  - Allowlist fermée : 27 événements (`enums/AnalyticsEvent.java:43-186`), clés de propriétés par événement (`AnalyticsProperty`), 17 chemins (`util/AnalyticsPaths`).
  - `occurredAt` accepté à ±24 h. Dédup `ON CONFLICT (dedup_key) DO NOTHING`.
  - Rate-limit par IP : 120 / 10 min et 2 000 / j.
  - Pays par géo-IP (inerte sans base MaxMind), device résolu serveur.
- **Web** : `lib/analytics.ts` (564 l.). Envoi immédiat en `sendBeacon`, **sans lot, sans file, sans retry**, dédup mémoire par onglet. First-touch complet (utm_*, `src`, referrer hôte, landing) au 1er événement.
- **Mobile** : `core/analytics/analytics.dart`, fire-and-forget. **Aucune file persistante, aucun retry**. Pas d'`occurredAt`. First-touch = `source` seule (toujours nulle en pratique).
- **Tiers** : **aucun** (ni Plausible, ni GA, ni pixel) [V]. Le brief suppose Plausible : il n'existe pas.
- **Drift** : **absent**. Persistance mobile disponible : `shared_preferences`, `flutter_secure_storage` [V `pubspec.yaml`].
- **Purge 13 mois** : **n'existe pas** [V]. C'est pourtant une **condition de l'exemption CNIL** (`docs/regles/mesure-audience.md:265-268`) sur laquelle repose l'absence de bandeau.

Correspondance entre les événements du brief et l'existant :

| Brief | Existant | Écart |
|---|---|---|
| `diagnostic_subject_viewed` (1ʳᵉ question) | TCF : `DIAGNOSTIC_EE_STARTED` (web + mobile) ≈ 1ʳᵉ question. Civique : **rien** | Ajouter un événement dédié `DIAGNOSTIC_SUBJECT_VIEWED` (TCF + civique, web + mobile) avec `diagnosticType` + `diagnosticRunId` |
| `diagnostic_report_viewed` | `DIAGNOSTIC_REPORT_VIEWED` : TCF rapide seulement. Civique et TCF complet : **rien** | Émettre sur le résultat civique (web + mobile) ; ajouter `diagnosticRunId` |
| `diagnostic_plan_viewed` | `PLAN_OPENED` (web + mobile), sans id de tentative ni de plan | Ajouter `diagnosticType`, `diagnosticRunId`, `journeyId` |
| `plan_unlock_clicked` | `PREMIUM_CTA_CLICKED {ctaLocation: LOCKED_PLAN}`. **Le « Débloquer » mobile du Plan n'est pas tracé** (`plan_tcf_view.dart:80,204`, `civic_plan_view.dart:113,165`) | Nouvel événement `PLAN_UNLOCK_CLICKED` (distinct, cf. doctrine « une vue n'est pas une intention ») avec `planCode` / `displayedPrice` |
| Déclarés mais jamais émis | `PLAN_CURTAIN_SHOWN`, `PLAN_CURTAIN_EXPANDED`, `PLAN_PAYWALL_VIEWED` | À émettre ou à retirer du registre (**Q10**) |

Nommage : le repo utilise `UPPER_SNAKE` (enum Java miroir web/mobile). **Garder cette convention** plutôt que le snake minuscule du brief (§1.3 l'autorise).

---

## 6. Admin : état actuel et liste de suppression

### 6.1 État

- **Routeur** `ADM/App.tsx` :
  - `/` redirige vers `/dashboard` (`:46`)
  - `/dashboard` rend `AnalyticsPage` (`:47`)
  - la route catch-all redirige vers `/dashboard` (`:92`)
  - `pages/LoginPage.tsx:16,24` redirige aussi vers `/dashboard`
- **Nav** `ADM/components/layout/AppLayout.tsx:61` : « ↳ Analytics » dans la section *Pilotage*.
- `GET /api/admin/dashboard` (`DashboardDto`) : **ce n'est pas de l'analytics**, il ne sert qu'aux badges de la sidebar → **conserver**.
- **Rôles** : `ProtectedRoute.tsx:12` (`role !== "ADMIN"`, cosmétique). La vraie barrière est `SecurityConfig.java:101` (`/api/admin/**` exige `ROLE_ADMIN`) + `@PreAuthorize` sur `AdminAnalyticsController`.
- **`/audience`** : aucune route, aucun menu, aucun fichier front [V].

### 6.2 À supprimer (règle « refonte = suppression immédiate »)

**Admin** (remplacé par `features/suivi/`) :
- `ADM/features/analytics/` en entier : 30 fichiers, 5 544 lignes (`AnalyticsPage`, `dates.ts`, `storage.ts`, `period.ts`, `types.ts`, `format.ts`, `derive.ts`, `labels.ts`, `analytics.module.css`, `tabs/*` ×5, `components/*` ×15).
- `ADM/api/analyticsApi.ts`.
- Types `ADM/types/api.ts:1092-1350` (`Analytics*`).
- L'entrée de nav `AppLayout.tsx:61` est à renommer « Suivi ».
- **À récupérer avant suppression, sans les dupliquer** : `dates.ts` (`parisToday`, seule notion d'« aujourd'hui » Paris), les formats de `format.ts` (U+202F, U+2212, `—` pour null), `Funnel.tsx` (compression puissance 0,42), `Delta.tsx`. Ils déménagent dans `features/suivi/`, ou dans `lib/` s'ils servent ailleurs.

**Backend, orphelins de `/audience` (aucun appelant front, [V])** :
- `controller/AdminAudienceController`, `service/AudienceFunnelService`, `manager/AudienceFunnelManager`, `repository/AudienceFunnelRepository`, `dto/AudienceFunnelResponse`, `enums/FunnelStage`
- `controller/AdminPageViewController`, `controller/PublicPageViewController` (**public, non rate-limité**), `service/PageViewService`, `manager/PageViewManager`, `repository/PageViewRepository`, `entity/PageView`, `enums/PageViewEvent`, `dto/PageViewRequest`, `dto/PageViewStatsResponse`
- Tests : `AdminAudienceControllerIT`, `AudienceFunnelServiceIT`, `AudienceFunnelServiceTest`, `PageViewManagerIT`, `PageViewServiceTest`
- Mentions à nettoyer : `RateLimitGuard.java:113-116`, la Javadoc de `PublicAnalyticsController:35-38`, et les entrées `AdminRoutesSecurityIT` / `PublicRoutesSecurityIT` [S : à vérifier au grep]
- **[D≠C]** `docs/decisions/mesure-audience.md` affirme ces classes « supprimées » alors qu'elles sont présentes. `docs/api-endpoints.md` § « Audience des landings » les documente encore.
- La **table `page_views` reste** (pas de migration destructive, doctrine du repo).

**Backend, lecture de l'ancien `/dashboard` (devient orpheline quand `features/analytics` part)** :
- `AdminAnalyticsController` (GET analytics + annotations), `AdminAnalyticsService`, `AnalyticsInsightsBuilder`, `AnalyticsCalculs`, `AnalyticsReadManager`, `AnalyticsReadRepository`, `AdminAnalyticsResponse`, `enums/AnalyticsGrain`
- Annotations (`AnalyticsAnnotation*`) selon **Q9**
- `util/AnalyticsLibelles` [S : vérifier les autres lecteurs]
- Tests : `AdminAnalyticsControllerIT`, `AdminAnalyticsServiceIT`, `AdminAnalyticsCoutIT`, `AnalyticsCalculsTest`, `AnalyticsInsightsBuilderTest`, `AnalyticsGrainTest`, `AnalyticsLabelsTest` [S], `AnalyticsLibellesTest`
- **À conserver et réutiliser** : `FenetreMesure` (+ test), `RepartitionArrondie` (+ test), `ClientContextResolver`, `TrafficSource`, `AnalyticsPaths`, toute l'ingestion (`PublicAnalyticsController`, `AnalyticsIngestionService`, `AnalyticsVisitor*`, `AnalyticsEvent*`, `AnalyticsIdentity*`), `MontantEncaisse*`
- `GeoIpCountryResolver` + `country_code` / `device_type` : plus aucun lecteur une fois l'écran supprimé → **Q9**

---

## 7. Mapping template → données (vue synthétique)

L'état détaillé de chaque chiffre est dans le §8. Légende : ✅ existe · 🟡 dérivable ou à étendre · ❌ manque.

| Bloc du template | État |
|---|---|
| Filtres période (Aujourd'hui / Hier / 7 j / Mois / Personnalisé) | 🟡 `FenetreMesure` + `parisToday` existent ; ajouter les presets « hier » et « mois en cours » |
| Filtre type (Tous / TCF / Civique) | ❌ (aucune dimension type sur les faits) |
| Filtres plateforme / source / `includeInternal` (brief §7.1, absents du template) | ❌ plateforme iOS/Android · 🟡 source · ❌ `is_internal` |
| KPI Visiteurs uniques | ✅ `analytics_event` / `analytics_visitor` (hors brief) |
| KPI Diagnostics soumis | ❌ TCF invité (aucun fait) · 🟡 civique |
| KPI Achats | 🟡 `user_subscriptions` (sans type ni attribution) |
| KPI Net réel estimé | ❌ |
| Tunnel 7 étapes | ❌ (identifiant de tentative absent de bout en bout) |
| Revenus : brut / TVA / frais / net / par provider | 🟡 brut (faussé côté stores) · ❌ le reste |
| Diagnostic par type | ❌ (dépend du tunnel) |
| Inscriptions après / hors diagnostic, par type | ❌ |
| Inscriptions Web / Android / Apple | 🟡 WEB/MOBILE seulement |
| Utilisation du plan | ❌ (hors brief) |
| Sources d'acquisition | ✅ `analytics_visitor.ft_source` ; 🟡 regroupement de config (hors brief pour les visiteurs) |

---

## 8. Construction backend de chaque donnée affichée

### 8.0 Briques communes (proposées)

- **Fenêtre** : `preset=TODAY|YESTERDAY|LAST_7_DAYS|MONTH_TO_DATE` **ou** `from`/`to` (`yyyy-MM-dd`, bornes incluses), résolus en `[début, fin)` **Europe/Paris** par `FenetreMesure` (étendue aux presets). La réponse **rend les bornes appliquées**, ainsi que la **période de comparaison** (même durée, juste avant : aujourd'hui → hier) pour les tendances.
- **Clé personne** : `person_key = COALESCE(user_id, anonymous_id)`.
  - Pour un événement, `user_id` vient de `analytics_event.user_id` ou du **plus ancien** `analytics_identity.user_id` lié à son `anonymous_id`.
  - Pour une `diagnostic_run`, c'est `COALESCE(run.user_id, run.anonymous_id)`.
- **Tentative de référence** : la table proposée `diagnostic_run` (**Q3**). Une ligne par passage de tunnel, sans aucun contenu :

  | Colonne | Rôle |
  |---|---|
  | `id` UUID | tiré par le client dès l'affichage du sujet, voyage dans les événements (`diagnosticRunId`) |
  | `diagnostic_type` | `TCF` \| `CIVIQUE` |
  | `anonymous_id`, `user_id` NULL, `platform` | identité et plateforme |
  | `subject_viewed_at` | horodatage serveur de réception |
  | `submitted_at`, `submitted_authenticated` | le fait « soumis » |
  | `claimed_at`, `claimed_via` (`SAME_DEVICE`\|`TOKEN`), `claim_kind` (`SIGNUP`\|`LOGIN`) | la liaison au compte |
  | `claim_token_hash`, `claim_token_expires_at` | le lien web → app |
  | `diagnostic_session_id` / `civic_diagnostic_session_id` / `tcf_diagnostic_session_id` NULL | le rattachement à la session réelle, une fois connue |

- **Dédup « 1ʳᵉ tentative par type »** : `ROW_NUMBER() OVER (PARTITION BY person_key, diagnostic_type ORDER BY subject_viewed_at)` = 1.
- **Exclusion interne** : `users.is_internal = false` (**Q6**) sur toute ligne portant un `user_id`. Pour les visiteurs, l'exclusion passe par `analytics_identity` ; un visiteur jamais lié ne peut pas être exclu (limite à afficher).
- **Montants** : en centimes (`long`), en EUR. Les pourcentages sont calculés **serveur** (le front n'en recalcule aucun, doctrine existante). Répartitions arrondies à somme conservée (`RepartitionArrondie`).
- **Endpoint unique** : `GET /api/admin/analytics/suivi` (précédent du repo : un seul appel, une seule fenêtre cohérente) au lieu des 3 endpoints du brief §9. Coût SQL figé et verrouillé par un IT d'égalité (patron `AdminAnalyticsCoutIT`).

**DTO proposé (`AdminSuiviResponse`)** :

```
window{from,to,prevFrom,prevTo,timezone,cohortWindowDays,cohortOngoing}
filters{type,platform,source,includeInternal}
kpis{visitors,visitorsPrev,submitted,submittedPrev,submittedRaw,purchases,purchasesPrev,
     netExVatCents,netExVatCentsPrev,
     submittedPctOfVisitors,purchasesPctOfSubmitted}
funnel{columns:[ALL,TCF,CIVIQUE], steps:[{code, counts{ALL,TCF,CIVIQUE}, pctFromPrev{…}}],
       attachedBreakdown{alreadyAuthenticated,signedUpAfter,loggedInAfter}{…},
       cohortNetExVatCents{…}}
revenue{grossCents,vatCents,feeCents,netAfterFeeCents,netExVatCents,refundsCount,refundsCents,
        byProvider:[{provider,purchases,grossCents,feeCents,netExVatCents}], feeEstimatedShare}
byType:[{type,subjectViewed,submitted,purchases}]
signups{total, afterDiagnostic{total,TCF,CIVIQUE}, outsideDiagnostic, loggedInAfterDiagnostic,
        byPlatform{WEB,IOS,ANDROID,MOBILE_UNKNOWN,UNKNOWN}}
ratios{…§7.4}
activity{submittedFirst,submittedRaw,purchasesByOrigin,anonymousSubmittedNeverClaimed}
sources:[{group,visitors}]          // si Q7 = oui
planUsage{…} | null                 // si Q7 = oui
```

### 8.1 Filtres

| Élément | (a) Définition | (b) Construction | (c) Champ | (d) État |
|---|---|---|---|---|
| Période | brief §7.1, bornes Paris | `FenetreMesure` + presets. Période pour l'activité, date d'entrée en cohorte pour le tunnel | `window.*` | 🟡 à étendre (hier, mois en cours) |
| Type Tous / TCF / Civique | §7.1 ; « Tous » = personnes distinctes (§2) | filtre `diagnostic_run.diagnostic_type` (tunnel). Pour les achats : type de la run attribuée, ou `plans.module_access` si `origin=OTHER` (**Q12**) | `filters.type` | ❌ |
| Plateforme, source, `includeInternal` | §7.1 (absents du template → **les ajouter à l'écran**) | plateforme de l'étape 1 = `diagnostic_run.platform` ; source = groupe du first-touch `analytics_visitor.ft_source` (via config) | `filters.*` | ❌ / 🟡 / ❌ |

### 8.2 Les 4 KPI

| KPI | (a) Définition | (b) Construction | (c) Champ | (d) État |
|---|---|---|---|---|
| **Visiteurs uniques** | **Hors brief.** Proposition : nombre d'`anonymous_id` distincts ayant ≥ 1 événement dans la période (Paris). Pas une `person_key` : un visiteur non lié n'a pas de compte | `COUNT(DISTINCT e.anonymous_id) FROM analytics_event e WHERE occurred_at ∈ période`, exclusion interne via identity | `kpis.visitors` | ✅ (c'est la métrique `v` actuelle) |
| « +12,4 % vs hier » | variation par rapport à la période de comparaison ; `null` si la précédente vaut 0 (doctrine `Delta`) | même requête sur `prevFrom/prevTo` | `kpis.visitorsPrev` → delta calculé **serveur** (`visitorsDeltaPct`) | 🟡 |
| **Diagnostics soumis** | §7.3 : runs soumises dans la période, **1ʳᵉ tentative par personne et par type**, + total brut | `diagnostic_run WHERE submitted_at ∈ période`, dédup `ROW_NUMBER`. « Tous » = personnes distinctes | `kpis.submitted`, `kpis.submittedRaw` | ❌ (TCF invité sans fait) · 🟡 civique |
| « 11,4 % des visiteurs » | **hors brief** : ratio de période `submitted / visitors`. ⚠️ mélange de personnes et d'`anonymous_id` : libellé « rapporté aux visiteurs », pas un taux de conversion | serveur | `kpis.submittedPctOfVisitors` | 🟡 |
| **Achats** | §7.3 : nombre d'achats dans la période (`purchased_at`), hors `PENDING` ; remboursés **inclus** au compte (le remboursement est compté à part) | `user_subscriptions WHERE status<>'PENDING' AND purchased_at ∈ période AND is_internal=false` | `kpis.purchases` | 🟡 (manque `purchased_at` et le type) |
| « 12,3 % des diagnostics » | **hors brief** : ratio de période `purchases / submitted` (≠ conversion cohorte, étape 7 / étape 2, qui vit dans `ratios`) | serveur | `kpis.purchasesPctOfSubmitted` | 🟡 |
| **Net réel estimé** « après TVA et frais » | §6.1 `net_ex_vat`, KPI principal ; §7.3 remboursements **de la période** déduits | `Σ net_ex_vat_cents` (achats de la période) + `Σ net_ex_vat_delta_cents` (remboursements de la période) | `kpis.netExVatCents` | ❌ |

### 8.3 Tunnel diagnostic (cohorte, §7.2)

Population : personnes dont la **1ʳᵉ run d'un type** a son `subject_viewed_at` (ou le 1er événement `DIAGNOSTIC_SUBJECT_VIEWED`) dans la période. Fenêtre = `cohort_window_days` (14) à partir de l'entrée. Chaque étape exige l'étape précédente.

| # | Libellé template | (a) Brief | (b) Construction (sur la run de référence R) | (d) État |
|---|---|---|---|---|
| 1 | Sujet vu | §7.2 entrée en cohorte | `R.subject_viewed_at ∈ période` | ❌ (ni run, ni événement civique) |
| 2 | Soumis | `submitted_at` dans la fenêtre | `R.submitted_at < entrée + 14 j`. TCF invité : posé par un appel public sans contenu à « Analyser mes réponses » ; TCF connecté : à la réception de la production ; civique : à la fin de l'attempt (public ou non) | ❌ |
| 3 | Compte rattaché | `user_id` non nul (connecté à la soumission, ou claim dans la fenêtre) | `R.submitted_authenticated OR R.claimed_at < entrée + 14 j` | ❌ |
| 3↳ | « 46 déjà inscrits » | `submitted_authenticated = true` | idem | ❌ |
| 3↳ | « 72 inscrits après diagnostic » | claim lors d'une inscription | `claim_kind='SIGNUP'` | ❌ |
| 3↳ | *(absent du template)* | connecté après diagnostic | `claim_kind='LOGIN'`. **Le template n'affiche que 2 sous-lignes ; le brief en exige 3 → afficher les 3** | ❌ |
| 4 | Rapport vu | ≥ 1 `diagnostic_report_viewed` sur R | `EXISTS analytics_event WHERE event='DIAGNOSTIC_REPORT_VIEWED' AND diagnostic_run_id=R.id AND occurred_at` dans la fenêtre. Le scénario 1 (7 vues → 1) est garanti par `EXISTS` | 🟡 TCF (sans id) · ❌ civique |
| 5 | Plan consulté | ≥ 1 `diagnostic_plan_viewed` | `PLAN_OPENED` enrichi de `diagnosticRunId`. **Hypothèse** : le front connaît la run qui a fondé le plan (voir **Q8**) | ❌ |
| 6 | Débloquer | ≥ 1 `plan_unlock_clicked` | `PLAN_UNLOCK_CLICKED` + `diagnosticRunId` | ❌ (et le Plan mobile n'est pas tracé) |
| 7 | Achat | `purchases.diagnostic_attempt_id = R` dans la fenêtre | `user_subscriptions.diagnostic_run_id = R.id AND purchased_at < entrée + 14 j AND status<>'PENDING'` | ❌ |
| — | % par étape | % depuis l'étape précédente | serveur, `null` si le dénominateur vaut 0 | ❌ |
| — | CA net cohorte (sous l'étape 7) | `net_ex_vat` après remboursements | `Σ net_ex_vat` des achats de l'étape 7 + `Σ` deltas de leurs remboursements (**quelle que soit la date du remboursement**) | ❌ |
| — | Badge « TCF + Civique » | écho du filtre type | libellé front depuis `filters.type` servi | ✅ trivial |
| — | « Fenêtre : 14 jours » + cohorte « en cours » | §7.2 | `window.cohortWindowDays` (config) ; `cohortOngoing = to + 14 j > maintenant` | ❌ |
| — | Colonnes Tous / TCF / Civique | §7.2 : le brief veut un **tableau 3 colonnes** ; le template ne montre qu'une barre | 3 compteurs par étape ; « Tous » = `COUNT(DISTINCT person_key)` ayant atteint l'étape dans ≥ 1 type | ❌. **Écart de présentation → Q13** |

### 8.4 Revenus du jour (§6, §7.3, logique période)

| Ligne | (a) | (b) | (c) | (d) |
|---|---|---|---|---|
| NET RÉEL ESTIMÉ | `net_ex_vat` après remboursements de la période | voir KPI | `revenue.netExVatCents` | ❌ |
| Brut payé | `Σ gross_paid` | `Σ gross_paid_cents` des achats de la période. (Faut-il déduire les remboursements du brut ? Le brief §7.3 dit « remboursements de la période déduits » → afficher le brut **et** une ligne « Remboursements ») | `revenue.grossCents`, `refundsCents` | 🟡 (`amount_eur_cents`, faussé côté stores) |
| TVA retirée | `Σ vat_amount` | figée à l'écriture par les règles de revenus | `revenue.vatCents` | ❌ (**Q1**) |
| Frais plateformes | `Σ provider_fee` (Stripe + stores) | figés ; part estimée signalée (`fee_source`) | `revenue.feeCents`, `feeEstimatedShare` | ❌ |
| Stripe / Apple / Google « n achats » | achats par provider | `GROUP BY source` | `revenue.byProvider[]` | ✅ dérivable dès aujourd'hui |
| *(brief, absent du template)* nombre et montant des remboursements, `net_after_fee` | §6.4, §7.3 | `payment_refunds WHERE refunded_at ∈ période` | `revenue.refundsCount`, `netAfterFeeCents` | ❌ → **ajouter au bloc** |
| Titre « Revenus du jour » | logique période | libellé à dériver de la période servie (« du jour », « de la période ») | — | front |

Invariant vérifié à l'écriture **et** en test : `gross = vat + fee + net_ex_vat`.

### 8.5 Diagnostic par type

| Élément | (a) | (b) | (c) | (d) |
|---|---|---|---|---|
| « 168 sujets vus · 112 soumis · 12 achats » par type | **Non défini par le brief.** Proposition : **ce sont les colonnes TCF et Civique du tunnel** (étapes 1, 2, 7, cohorte). Ainsi le bloc est cohérent avec le tunnel, et « Tous » ≤ TCF + Civique | réutilise le calcul du tunnel | `byType[]` | ❌ |

### 8.6 Inscriptions (§3.4, §7.3, période)

| Élément | (a) | (b) | (c) | (d) |
|---|---|---|---|---|
| Après diagnostic (TCF / Civique) | `signup_context = AFTER_DIAGNOSTIC` × `signup_diagnostic_type` | `users WHERE created_at ∈ période AND deleted_at IS NULL AND NOT is_internal`, `GROUP BY signup_context, signup_diagnostic_type`. La colonne est posée **serveur** à l'inscription si ≥ 1 run soumise non rattachée porte l'`anonymous_id` reçu (ou le jeton) | `signups.afterDiagnostic` | ❌ |
| Hors diagnostic « Inscription directe » | `OUTSIDE_DIAGNOSTIC` | idem | `signups.outsideDiagnostic` | ❌ |
| *(brief)* connecté après diagnostic | pas une inscription (§3.4) | `diagnostic_run.claim_kind='LOGIN'` dans la période | `signups.loggedInAfterDiagnostic` | ❌ |
| Web / Android / **Apple** | `signup_platform` | `GROUP BY signup_platform`. Legacy `MOBILE` = « Mobile (non ventilé) », `NULL` = « inconnu » (affichés en clair, doctrine existante). **Libellé template « Apple » → « iOS »** | `signups.byPlatform` | 🟡 (WEB/MOBILE seulement) |
| Comptes legacy | `signup_context` NULL | affiché « inconnu », pas de rattrapage (`null` = inconnu) | — | — |

### 8.7 Utilisation du plan (**hors brief**, §0 « brief suivant »)

| Élément | Proposition | État |
|---|---|---|
| « Action recommandée par le plan » vs « Entraînement libre » | Définition du template : « attribuée au plan si le contenu travaillé était recommandé, **quel que soit l'écran** ». **Irreconstituable a posteriori** : le Plan est dérivé à la lecture, sa recommandation à l'instant T n'est pas persistée (même raisonnement que V072). Il faudrait **persister au lancement d'un attempt** un indicateur `plan_recommended` calculé serveur (nouvelle exception « décision prise à un instant »). **Proxy disponible aujourd'hui** : série lancée depuis une carte (`journey_step_series`, TCF et civique) + événement `PLAN_EXERCISE_STARTED` = « depuis le plan » ; les autres attempts TRAINING des utilisateurs ayant un plan = « libre ». Ce proxy mesure l'**écran** d'origine, pas le **contenu** | ❌ → **Q7** |

### 8.8 Sources d'acquisition

| Élément | (a) | (b) | (c) | (d) |
|---|---|---|---|---|
| Instagram / TikTok / Facebook / Direct-autre, en nombre | **Hors brief** (le brief traite la source comme un **filtre**, §3.5 / §7.1). Proposition : visiteurs actifs dans la période, groupés par **groupe de first-touch** | `analytics_visitor.ft_source` → groupe via `utm_source_groups` (config), `COUNT(DISTINCT anonymous_id)` des visiteurs ayant un événement dans la période | `sources[]` | ✅ données · 🟡 regroupement |
| Regroupement `ig` → instagram (scénario 17) | §3.5 + config | aujourd'hui `TrafficSource` ne connaît que tiktok, instagram, whatsapp, facebook, youtube, direct ; **`ig` devient `autre`** [V] | — | ❌. Appliquer les groupes **à l'ingestion** (normalisation) ou **à la lecture** (préférable : réversible, versionné) |
| whatsapp / youtube | absents du template et du brief | groupés dans « autre » par la config v1 | — | décision de config |
| Mobile | `inconnu` massif (aucune provenance mobile) | à afficher tel quel, jamais converti en `direct` (règle existante) | — | limite connue |

### 8.9 Ratios §7.4 (absents du template)

Tous se calculent sur les compteurs du tunnel :
- sujet → soumission = 2 / 1
- diagnostic → inscription = inscrits après / soumis **anonymes**, les « déjà connecté » exclus
- rapport = 4 / 3 ; plan = 5 / 4 ; intention = 6 / 5 ; clic = 7 / 6 ; globale = 7 / 2
- net par soumis = CA net cohorte / étape 2

Champ `ratios`. **À afficher** (le template les omet) → **Q13**.

### 8.10 Activité §7.3 absente du template

Soumis bruts, achats par `origin`, **soumis anonymes jamais rattachés** (soumis anonymes de la période sans claim à J+14). Champ `activity`, à afficher dans un bloc « Activité ».

### 8.11 Couverture des 17 scénarios du §12

| # | Scénario | Couvert par ce design ? |
|---|---|---|
| 1 | 7 vues du rapport → 1 | ✅ `EXISTS` sur la run |
| 2 | Ahmed TCF + Civique → Tous = 1 | ✅ `COUNT(DISTINCT person_key)` |
| 3 | Anonyme web → inscription même navigateur → `AFTER_DIAGNOSTIC` | ✅ **à condition** que le web envoie `anonymousId` à l'inscription (aujourd'hui non) |
| 4 | Web → app installée via lien + `claim_token` | ❌ **non couvert en MVP** : aucun universal link / app link n'existe (pas d'AASA, pas d'`assetlinks.json`, pas d'intent-filter, pas d'associated-domains, pas de lien vers l'app sur le résultat) [V]. Il faut un lot dédié → **Q14** |
| 5 | Même cas sans jeton → `OUTSIDE_DIAGNOSTIC` + jamais rattaché | ✅ |
| 6 | Déjà connecté → « déjà connecté », exclu du ratio | ✅ |
| 7 | Compte existant déconnecté → diagnostic → connexion → « connecté après diagnostic » | ⚠️ couvert pour le **comptage** (claim au login par `anonymous_id`). Mais si le compte a **déjà** son diagnostic, les productions ou l'adoption sont **abandonnées** par le quota : la personne est rattachée, le diagnostic non. À documenter, sans en faire une erreur |
| 8 | Vu le 3/09, achat le 7/09 → cohorte du 3 + activité du 7 | ✅ |
| 9 | Achat J+15 → hors tunnel, dans l'activité | ✅ |
| 10 | Lot mobile envoyé 2 fois → aucun doublon | ✅ si l'`event_id` client est posé à la **création** (dans `dedup_key`) et que la file mobile est persistante. Aujourd'hui : pas de file, pas de `dedupKey` mobile |
| 11 | Webhook reçu 2 fois → 1 achat | ✅ déjà vrai (`processed_external_events` + UNIQUE) |
| 12 | Montants §6.3 au centime | ✅ via un calculateur pur + test. ⚠️ la ligne Stripe « TVA 1,66 » est **fausse sous franchise** (**Q1**) |
| 13 | Remboursement Stripe → −0,40 ; store → 0 | ✅ avec `payment_refunds` |
| 14 | 23h30 UTC le 3/09 → compté le 4/09 | ✅ bornes Paris (01h30 le 4/09) |
| 15 | `is_internal` exclu par défaut, visible avec le toggle | ✅ avec la colonne (**Q6**) |
| 16 | TCF refait 3 fois → 1 personne, 3 soumissions brutes | ⚠️ **impossible pour le TCF rapide** (UNIQUE par version). Possible pour le TCF complet et le civique. Tester le scénario sur le **civique**, ou sur « TCF » = complet si **Q2** l'y inclut |
| 17 | `/reussir?utm_source=IG` puis achat → instagram | ✅ avec le regroupement de config + la liaison identité → achat (aujourd'hui `ig` devient `autre` et la liaison n'est jamais écrite) |

**Non couverts** : **#4** (lien web → app) en l'état. **#16** n'est testable que hors TCF rapide. **#7** comporte une nuance produit.

---

## 9. Écarts, risques et contradictions avec les invariants

| # | Sujet | Constat | Proposition |
|---|---|---|---|
| E1 | **Invariant V053** (rien n'est persisté avant le compte pour le TCF) vs brief §4.2 (tentative serveur au démarrage) | contradiction directe | `diagnostic_run` **sans contenu** : aucun texte, aucun audio. L'invariant porte sur la production, pas sur la trace du passage (**Q3**). Vérifier la formulation de `/confidentialite` 8.3 |
| E2 | « **Aucune seconde vérité** » (`docs/regles/mesure-audience.md`) | brief §2 conforme (faits métier dans les tables métier) | `diagnostic_run.submitted_at` est un **fait**, pas un événement. `DIAGNOSTIC_ACCOUNT_REQUIRED` reste un comportement |
| E3 | **Rétention** : brief `raw_event_retention_days: 760` (≈ 25 mois) | **contredit l'exemption CNIL 13 mois** et le texte actuel de `/confidentialite` art. 5 (« 13 mois, puis suppression ») | **395 j** ; écrire le job de purge (dette existante) dans le lot 1 (**Q5**) |
| E4 | Brief : cookie web | l'existant est en **localStorage**, décrit tel quel dans `/confidentialite` 8.2 | garder le localStorage (un cookie sur le domaine web ne part pas vers l'API de toute façon) ; ajouter l'en-tête. **Q4** |
| E5 | **RGPD** | 8.3 annonce déjà « les données de parcours antérieures peuvent être rattachées au compte ». Nouveauté : le lien web → app (jeton) et le rattachement du **diagnostic** anonyme | ajuster 3.2 / 8.3 **dans la même passe**. **[D≠C]** 8.2 dit « trois choses, et rien d'autre » alors que d'autres clés existent (`sejourfr.ee.draft.*`, `sejourfr.civic-diagnostic.invite`, IndexedDB `sejourfr-diagnostic`…) : à corriger au passage |
| E6 | **Parité web ⇄ mobile ⇄ admin** | nouveaux événements, en-têtes, `anonymousId` à l'auth : 2 fronts ; DTO admin : 1 miroir (`ADM/types/api.ts`) ; `AnalyticsEvent` a **3 miroirs** (Java, `WEB/lib/analytics.ts`, `MOB/core/analytics/analytics_events.dart`) | chaque lot front touche web **et** mobile dans la même passe |
| E7 | **Pas de nouveau test front** | la file mobile, le SDK web et l'écran admin ne se vérifient que par `tsc` / `build` / `flutter analyze` | toute la logique (dédup, allowlist, cohorte, montants, 17 scénarios) vit **côté backend**, en IT Zonky |
| E8 | **Tests backend obligatoires** | brief §12 = 17 IT | faisable avec l'infra `AbstractIntegrationTest` + `TestData` |
| E9 | **Config JSON versionnée** (brief §8) | le repo a déjà ce patron : `plan/plan-config-v1.json`, `progression-config-v1.json`, `email-automation-config-v1.json`, chacun avec son loader. Mais les constantes analytics actuelles sont en YAML (`fx-rates`, `excluded-emails`) ou en dur (`ECART_HORODATE_MAX=24h`, cache 60 s) | `analytics/analytics-config-v1.json` + `billing/revenue-rules-v1.json` (nommage repo `-v1`, pas `.v1`), chargés par des loaders sur le patron `PlanConfigLoader`. Clock skew : brief 10 min vs existant 24 h (ce sont deux usages distincts : rejet vs remplacement par `received_at`) |
| E10 | **Fuseau** | `FenetreMesure.PARIS` + plusieurs copies de `ZoneId.of("Europe/Paris")` (`LearningPlanService`, `UserDashboardService`, `EmailFormats`…) | réutiliser `FenetreMesure.PARIS`. Pas de nouvelle copie |
| E11 | **Centimes / HALF_UP** | `MontantEncaisse` est déjà l'autorité (centimes) | l'étendre (`RevenueBreakdown`), ne pas créer une seconde autorité |
| E12 | **`is_internal`** | absent ; exclusion par e-mails en YAML, partielle (visiteurs non exclus) | colonne `users.is_internal` (**Q6**) |
| E13 | **Drift** | absent du mobile | file bornée en `SharedPreferences` (JSON, plafond N événements), pas de dépendance codegen (**Q15**) |
| E14 | **Plateforme** | `ClientPlatform` = WEB / MOBILE / UNKNOWN ; brief = WEB / IOS / ANDROID | étendre l'enum (IOS, ANDROID), garder MOBILE pour le legacy |
| E15 | **« Un plafond d'affichage n'est pas un budget »** / « null = inconnu » | un maillon non mesuré (ex. étape 5 avant instrumentation) ne doit jamais valoir 0 | servir `null` pour une étape non instrumentée sur la période (doctrine `co2`/`ce2`) |
| E16 | **Bugs paiement** (§3.4) | brut store faux, retries Stripe perdus | **Q11** |
| E17 | Docs périmées | `docs/api-endpoints.md` (Audience des landings), `docs/decisions/mesure-audience.md` (classes « supprimées »), `web_sejoufr/CLAUDE.md` (`lib/audience*.ts`, carte « Débloquez » du rapport), `docs/regles/diagnostic.md` (rapide EE + EO), `docs/regles/paiements.md` (migrations V103-V106/V417/V422 inexistantes ; « durée éditable en admin » faux) | mise à jour dans les lots concernés |
| E18 | Le rapport TCF rapide ne pousse **aucun** abonnement [V] | le « Débloquer » n'existe que sur le Plan (`/plan`, `/plan/debloquer`) | cohérent avec le tunnel (étape 6 = Plan). Rien à changer |
| E19 | Stripe checkout = **GET** `/api/billing/payment-link?planCode` | pour transmettre l'attribution, ajouter `runId` / `journeyId` en query, ou mieux, la résoudre serveur (**Q12**) | — |

---

## 10. Décisions à trancher au STOP 0

### `store_commission.mode` : **recommandation MULTIPLY**

- La commission Apple et Google est un **pourcentage du prix hors taxes** : le store retient la TVA, puis prélève `taux × HT`. Le développeur reçoit donc `HT × (1 − taux)`. C'est exactement **MULTIPLY**.
- **DIVIDE** (`HT / 1,15`) revient à une commission de 13,04 % : il **surestime** le net d'environ 0,16 € sur un pass à 9,99 €, soit ≈ 2 % d'erreur systématique de CA.
- **Taux** :
  - **15 %** si SejourFR est inscrit au *App Store Small Business Program* (moins de 1 M$ de produits par an, **sur inscription**) et au palier 15 % de Google Play (premier million de dollars annuel, **sur inscription** au groupe de comptes) ;
  - **30 %** sinon (taux standard des achats intégrés).
- **Proposition de config** :

  ```json
  "store_commission": { "mode": "MULTIPLY",
    "apple":  { "rate": 0.15 },
    "google": { "rate": 0.15 } }
  ```

  Un taux **par store**, versionné (`revenue_rules_version` figé sur chaque achat). **À confirmer : l'inscription effective aux deux programmes.** Sinon 0,30.
- Arrondis du §6.3 vérifiés : `HT = round_HALF_UP(999 / 1,2) = 833` ; `fee = round(833 × 0,15 = 124,95) = 125` ; net = 708 ✔.

### Questions numérotées

| # | Question | Recommandation |
|---|---|---|
| **Q1 (bloquante)** | **TVA** : la facture Stripe dit « TVA non applicable, art. 293 B du CGI » (franchise en base) [V `BillingService.java:329-334`]. Le `vat_rate 20 %` du brief s'applique-t-il ? | Sous franchise : **Stripe `vat = 0`**, `HT = gross`. **Stores : TVA retenue quand même** (Apple / Google collectent et reversent la TVA UE comme revendeurs), donc `vat = gross − round(gross / 1,2)`. Config : `vat` **par provider** + un `seller_vat_regime` versionné, pour basculer le jour où la franchise saute. L'exemple Stripe du §6.3 est à recalculer : fee 0,40, net_ex_vat 9,59 |
| **Q2 (bloquante)** | « Diagnostic TCF » du tunnel = rapide (`QUICK_TCF`, porte d'entrée invitée) ou aussi le complet (authentifié, refaisable) ? | **Rapide seulement** pour le tunnel. Le complet se fait après le Plan ; il peut apparaître dans l'activité (« diagnostics complets soumis ») |
| **Q3 (bloquante)** | Créer la table `diagnostic_run` (trace du passage sans contenu, id tiré client, « soumis » posé serveur à « Analyser mes réponses » pour le TCF invité) plutôt qu'ajouter les colonnes du brief sur `attempts` ? | **Oui.** `attempts` est la table du runner et le diagnostic s'étale sur 3 tables de sessions. Une table dédiée porte les champs du §4.2 sans toucher V053 ni le runner. Nom à valider (`diagnostic_run` ou `diagnostic_funnel_run`) |
| Q4 | En-têtes : noms du brief (`X-Anonymous-Id`, `X-Platform`, `X-App-Version`) ou convention repo ? | `X-Sejourfr-Anonymous-Id`, `X-Sejourfr-Client: web\|ios\|android`, `X-Sejourfr-App-Version`. Web : localStorage conservé (pas de cookie) |
| **Q5 (bloquante)** | Rétention des événements bruts : 760 j (brief) ou 13 mois (CNIL + `/confidentialite`) ? | **395 j**, et purge écrite au lot 1 (sur `analytics_event` **et** `analytics_visitor` inactifs) |
| Q6 | `users.is_internal` (colonne, toggle admin) ou garder `excluded-emails` ? | **Colonne**, initialisée depuis `excluded-emails` par la migration, puis éditable. Supprimer la liste YAML (une seule autorité) |
| **Q7 (bloquante)** | Le template affiche Visiteurs uniques, Sources d'acquisition et Utilisation du plan, que le brief exclut | **Option B** : inclure **Visiteurs** et **Sources** (données déjà collectées, coût faible, dont une requête existante réutilisable). **Reporter** « Utilisation du plan » au brief suivant (elle exige de persister la recommandation au lancement) ; en attendant, bloc masqué ou « bientôt » (précédent : onglet Rétention). Option A : strict brief (retirer les 3 blocs). Option C : proxy « depuis l'écran Plan » tout de suite, étiqueté comme tel |
| Q8 | `plan_id` = `journey.id` (cycle persisté, jamais exposé aujourd'hui) ? | Oui. L'exposer dans `JourneyDto` / `LearningPlanDto` et le passer dans les événements 5 et 6. Côté civique, `journey` (module CIVIQUE, V069) joue le même rôle |
| Q9 | Que perd-on de l'ancien `/dashboard` : pays (MaxMind), appareils, campagnes, table des CTA, parcours types, insights, annotations, séries ? | Accepter la perte (règle « refonte = suppression ») : supprimer les annotations (table conservée), l'`AnalyticsInsightsBuilder` et `GeoIpCountryResolver` si plus rien ne lit le pays. Si le propriétaire veut garder des vues, les prévoir dans les entrées de nav futures du template (« Acquisition », « Achats »…) |
| Q10 | `user_funnel_events` (V036) et `POST /api/me/funnel-events` + `PLAN_CURTAIN_*` / `PLAN_PAYWALL_VIEWED` jamais émis : garder ? | Le nouvel écran ne les lit pas. **Supprimer le code** (endpoint, service, émetteurs web `lib/funnel-events.ts` et mobile `funnel_events.dart`, appel dans `BillingService`) et **garder la table**. Retirer les 3 événements jamais émis du registre (3 miroirs) |
| Q11 | Corriger dans ce chantier les bugs paiement (champs `rawPrice`, anti-rejeu 300 s, remboursement partiel, `payment_status`) ? | **Oui, au lot 2** : sans eux, le CA affiché est faux par construction. Pour Apple, préférer le `price` du JWS signé au prix déclaré par le client |
| Q12 | Attribution achat → diagnostic : transport par store (metadata, `appAccountToken`, `obfuscatedAccountId`) ou résolution serveur ? | **Résolution serveur à l'écriture** : achat d'un user ⇒ sa run soumise la plus récente de type compatible (`CIVIQUE_*` → civique ; `INTEGRAL_*` → TCF, sinon civique) dans la fenêtre de 14 j ⇒ `origin = DIAGNOSTIC_PLAN`. Zéro changement store. En complément, une **intention serveur** créée au clic « Débloquer » (`purchase_intent`, UUID) : UUID passé en `metadata.intentId` (Stripe), `applicationUserName` → `appAccountToken` (Apple), `obfuscatedAccountId` (Google). Elle prime quand elle existe. Proposé en lot 2b, optionnel |
| Q13 | Présentation : le brief veut les 3 colonnes Tous / TCF / Civique et les sections A/B/C ; le template montre une barre unique + un filtre type | Garder la mise en page du template (filtre type), **ajouter** les 3 sous-lignes de l'étape 3, le CA net cohorte, un bloc « Ratios » (§7.4) et un bloc « Activité » (§7.3, dont « soumis anonymes jamais rattachés »). Charte admin (voir §11) |
| Q14 | Lien web → app avec `claim_token` (scénario 4) dans le MVP ? | **Lot séparé (3b)**, après le reste. Il demande AASA + `assetlinks.json` + entitlements + intent-filters + routage go_router + page résultat. Le scénario 5 (sans jeton) mesure déjà l'ampleur du trou |
| Q15 | File mobile : Drift ou SharedPreferences ? | **SharedPreferences** (liste JSON bornée, `event_id` à la création, purge après 2xx). Drift ajouterait codegen et migrations pour une file de quelques dizaines d'événements |
| Q16 | Comptes et achats **antérieurs** : rattrapage (`signup_context`, montants TVA / frais) ? | **Aucun rattrapage** (`null` = inconnu, montants figés à l'écriture). Legacy affiché « inconnu ». Option : backfill `ESTIMATED` des montants par migration, clairement marqué `fee_source=ESTIMATED`, `revenue_rules_version=0` |
| Q17 | Ingestion en lot (brief §9 : batch 50, réponse 202, rejet individuel) vs l'existant (1 événement, 204, 400 si invalide) ? | Ajouter un **format lot** sur le même endpoint (ou `/batch`), 202 + rapport de rejets par élément. Garder l'unitaire le temps de la bascule des deux fronts, puis le supprimer |

---

## 11. Charte : écarts du template

Le template est **hors charte** ; seules sa mise en page, sa densité et ses libellés sont repris (précédent du 2026-08-21).

| Template | Charte admin (`ADM/styles/global.css`) |
|---|---|
| bleu `#2759d7`, dégradé `#2759d7 → #6f8df0` | `var(--blue)` `#1e3a8f` ; dégradés en `color-mix(in srgb, var(--blue) …%, var(--paper))` |
| vert `#1f8f63` / `#125a3e`, ambre `#b56b16` | `var(--green)`, `var(--green-soft)`, `var(--amber)`, `var(--amber-soft)` |
| fond `#f6f8fb`, cartes `#fff`, lignes `#e8edf3` | `var(--paper)`, `var(--surface)`, `var(--rule-2)` |
| **Inter partout**, titres en 800/900 | **Fraunces** pour `h1` / titres de panneau, Inter pour le corps, **JetBrains Mono** pour eyebrows, badges, « NET RÉEL ESTIMÉ » |
| sidebar sombre `#111827` + nav (Vue d'ensemble / Suivi / Diagnostics / Utilisation / Achats / Acquisition) | **sidebar existante** `AppLayout` conservée. Seule l'entrée « Analytics » devient « Suivi ». Les autres entrées du template n'existent pas (hors périmètre) |
| rayons 18 px, ombres ad hoc | `var(--shadow-sm/md)` (les ombres sont des tokens) |
| `.segmented` en boutons | réutiliser `Controls.tsx` de l'ancienne feature (à déménager) |
| libellé « Apple » (plateforme) | « iOS » |
| responsive (1050 / 640 px) | conforme à l'exigence 360 / 768 / 1280 ; pas de tableau sans repli carte (`DataTable.module.css`) |

Note annexe : `docs/identite-visuelle.md:15` signale déjà l'écart `#1E3A8C` (web) / `#1E3A8F` (admin). Hors périmètre.

---

## 12. Découpage proposé

Les STOP du brief sont repris et ajustés à l'existant. Volumes indicatifs (fichiers créés ou modifiés, tests backend compris).

| Lot | Contenu | Volume | Agents parallélisables |
|---|---|---|---|
| **0** | Cet audit → **STOP 0** | 1 | — |
| **1a Nettoyage orphelins** | suppression backend `/audience` + page-views (§6.2) et de leurs tests ; mise à jour de `api-endpoints.md` et `decisions/mesure-audience.md` | ~20 supprimés, ~4 modifiés | **1 agent**, en parallèle de 1b (fichiers disjoints ; seul `RateLimitGuard` est à réserver à 1a) |
| **1b Fondations backend** | migration **V074** (`diagnostic_run`, colonnes `analytics_event`, `users.signup_*` + `is_internal`, revenu sur `user_subscriptions` + `purchased_at`, `payment_refunds`) ; loaders `analytics-config-v1.json` et `revenue-rules-v1.json` ; `ClientContextResolver` (anonymous-id, ios/android, app-version) ; ingestion en lot + `event_id` ; nouveaux événements au registre ; **job de purge 395 j** ; liaison identité à l'auth | ~30 main + ~12 tests | 1 agent (la migration est un point de collision unique) → **STOP 1** (dédup, allowlist, rejet partiel, purge) |
| **2 Enrichissement métier** | cycle de vie de `diagnostic_run` (endpoint public « soumis » TCF, hooks handoff TCF, fin d'attempt civique, adoption) ; claim même appareil au login et à l'inscription ; `signup_context` ; `RevenueCalculator` pur (§6, invariant) branché dans `MontantEncaisse` ; remboursements (3 providers) ; attribution serveur (Q12) ; **bugs paiement** (Q11) | ~25 main + ~15 tests | **2 agents** : (2a) diagnostic, claim, signup ; (2b) revenu, remboursements, webhooks. Collision : `user_subscriptions` / `MontantEncaisse` réservés à 2b → **STOP 2** (scénarios 3, 5-7, 11-13) |
| **3 Clients** | web : en-têtes, `anonymousId` à l'auth (login, register, Google), SDK en lot + `pagehide`, `DIAGNOSTIC_SUBJECT_VIEWED`, rapport civique, `PLAN_OPENED` enrichi, `PLAN_UNLOCK_CLICKED`, run id dans le brouillon IndexedDB et l'appel « soumis ». Mobile : idem + file SharedPreferences + app version (`package_info_plus` ou `--dart-define`) + ios/android. `/confidentialite` | web ~12, mobile ~14 | **2 agents** (web ∥ mobile), après gel du contrat au lot 1b. Miroirs `AnalyticsEvent` ×3 vérifiés en fin de lot → **STOP 3** (événements reçus depuis web, iOS, Android) |
| **3b (option, Q14)** | lien « Continuer sur l'application » + `claim_token` : AASA, assetlinks, entitlements, intent-filters, go_router, endpoint de claim | ~12 | 1 agent, après 3 |
| **4 KPI + écran** | backend : `SuiviReadRepository` (SQL, coût figé), service, DTO, `GET /api/admin/analytics/suivi`, **IT des 17 scénarios** + IT de coût. Admin : `features/suivi/` (≈ 12-15 fichiers) + `api/suiviApi.ts` + types, **suppression de `features/analytics/` et du backend de lecture** (§6.2), nav, `admin_sejourfr/CLAUDE.md`, `docs/regles/mesure-audience.md` | backend ~8 + ~6 tests ; admin ~16 créés, ~33 supprimés | **2 agents** : backend ∥ admin, dès que le DTO est gelé (l'admin code sur le contrat, `types/api.ts` étant sa seule surface commune) → **STOP 4** |
| **5 (brief suivant)** | Utilisation du plan (persistance de la recommandation au lancement), rapprochement des rapports stores | — | — |

**Ordre critique** : 1b → 2 → 4 (backend). 1a est libre. 3 dépend du contrat 1b. L'admin (4) dépend du DTO. **Aucun lot ne touche deux fois la même migration** : tout le DDL est dans V074 (ou V074 + V075 si le 2b découvre un besoin ; ne jamais réécrire V074 une fois appliquée).
