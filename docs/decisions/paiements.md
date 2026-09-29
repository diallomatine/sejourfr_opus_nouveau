# Journal — lots de paiement 1 → 5 et geste V038

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Journal daté, verbatim et intégral.**
> Origine : lignes 4235-4366 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier consigne les arbitrages et révocations : on l'ouvre **avant de changer une règle**, pas pour l'appliquer.
> Fichier jumeau : `docs/regles/paiements.md`
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

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
> ⚠ **SUSPECTÉ PÉRIMÉ — non vérifié au 2026-08-23, ne pas appliquer sans confirmation.**
> Suspicion #1 — motif et liste complète : `docs/decisions/suspects-perimes.md`.

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
> ⚠ **SUSPECTÉ PÉRIMÉ — non vérifié au 2026-08-23, ne pas appliquer sans confirmation.**
> Suspicion #2 — motif et liste complète : `docs/decisions/suspects-perimes.md`.

- **Lot 4d (à faire, mobile)** : UI paywall mensuel/trimestriel/annuel,
  branchement package `in_app_purchase`, appel `/verify-receipt` après
  achat, lecture `/subscription-status` au boot.

> ⚠ **SUSPECTÉ PÉRIMÉ — non vérifié au 2026-08-23, ne pas appliquer sans confirmation.**
> Suspicion #3 — motif et liste complète : `docs/decisions/suspects-perimes.md`.

⚠ **Cassure connue après lot 4** : le web `/paiement` actuel envoie
`?plan=BillingPlan` (CIVIQUE_3MOIS / INTEGRAL_3MOIS) ; il sera 400 jusqu'à
ce que le lot 4b mette à jour l'appel en `?planCode=<string>`.

- **Lot 5 (bascule achat unique — feature-flaggée)** : le produit vend des
  **passes d'accès à durée fixe** (paiement unique, sans reconduction), au lieu
  d'abonnements. Catalogue **en vigueur (V114, 2026-08-14)** : Civique 3 mois
  (9,99) / 1 an (29,99) — **inchangé** ; Intégral **7 jours (9,99) / 1 mois
  (19,99) / 2 mois (29,99)**, codes `INTEGRAL_PASS_{7J,1M,2M}`, product IDs
  `integral_pass_{7j,1m,2m}`. Les 3 anciens passes Intégral (sprint 6 sem 19,99 /
  3 mois 34,99 / 1 an 79,99) sont **désactivés, jamais supprimés** : les
  souscriptions vendues les référencent par FK et les stores doivent encore
  résoudre leurs product IDs. **Une durée de plan ne se réécrit pas** — `ends_at`
  est figé à l'achat, mais changer `duration_days` d'un plan encore vendu
  falsifierait les achats suivants et le product ID du store, d'où des **codes
  neufs** plutôt qu'une mise à jour en place. Le pass **mis en avant** (« le plus
  populaire ») est `INTEGRAL_PASS_2M`, déclaré une fois par front
  (`POPULAR_PASS_CODE` ⇄ `_popularPassCode`). Ce qu'il reste à faire côté stores
  vit dans `docs/bascule-prix-integral.md`. Modèle : paiement →
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
  - **Affichage des prix (les 3 surfaces)** : le **montant réellement débité**
    est le prix principal (« 19,99 € »), l'équivalent mensuel passe en
    sous-texte (« soit 13,33 €/mois »). Un pass se paie une fois — mettre un
    « /mois » en avant laisse croire à un abonnement. Vaut pour `/paiement`
    (`OneTimePasses`), `/tarifs` (`PassModuleCard`) et le paywall mobile
    (`_PassRow`). Ne pas réinverser sur une seule surface.
  - Stores : produits **Consommables** (Apple) / **managed in-app** (Google),
    product IDs **lus en base** (`plans.apple_product_id` / `google_product_id`,
    identiques et en minuscules), **plus dérivés de `Plan.code`** — un ID Apple
    supprimé n'étant jamais réutilisable, une recréation impose un ID neuf.
    Guide pas-à-pas → `docs/setup-paiement-one-time.md`.

- **Geste envers les acheteurs de l'ANCIEN catalogue (V038, 2026-08-19)** : les
  clients qui avaient payé avant la grille actuelle — `INTEGRAL_PASS_SPRINT`
  (6 semaines) et `INTEGRAL_PASS_3M` — ont vu leur accès Intégral prolongé de
  **14 j / 21 j** et leur solde de simulations orales porté à un **plancher de
  5 / 15**. Quatre règles à ne pas défaire :
  1. **Le solde vit sur la souscription, pas sur le plan** (V019 :
     `user_subscriptions.realtime_eo_sessions_remaining` ;
     `plans.realtime_eo_sessions` n'est plus qu'un cap d'affichage) — toucher le
     plan n'aurait rien changé pour un client existant.
  2. **Le barème est un PLANCHER (`GREATEST`), jamais une valeur imposée** : le
     backfill V019 avait posé jusqu'à 25 / 60 sur ces lignes, fixer sèchement à
     5 / 15 en aurait *retiré* — dans un e-mail qui annonce un cadeau.
  3. **Un seul geste par utilisateur, posé sur la souscription que l'app lira**
     (`RealtimeQuotaService` → `SubscriptionService.currentSubscription()`, qui
     ne retient qu'UNE ligne) : créditer une ligne perdante serait invisible.
  4. **Prolonger un pass expiré, c'est le rouvrir** : `GREATEST(ends_at, now())
     + N j`, et statut `EXPIRED`/`CANCELED` remis à `ACTIVE` — sinon `isCovering`
     bloque quelle que soit la date. `REFUNDED`, `PENDING` et comptes supprimés
     sont exclus.
  **Hors périmètre volontaire, et ils n'ont RIEN reçu** : `INTEGRAL_PASS_1Y`, les
  abonnements récurrents Intégral (dormants) et tous les passes Civique (aucun
  accès TCF, donc aucune simulation utilisable). Élargir = **une nouvelle
  migration** avec une ligne de plus au barème, jamais une réécriture de V038.
  **La table `legacy_pass_compensations` est l'audit, l'anti-doublon et le plan de
  retour arrière** — elle porte l'état d'avant (`ends_at_before`,
  `sessions_before`). ⚠️ **L'annonce est PARTIE le 2026-08-19 et le code qui
  l'envoyait a été SUPPRIMÉ dans la foulée** (panneau admin du dashboard, client
  `mailingApi`, `POST /api/admin/mailing/anciens-acheteurs`, son service, son
  entité JPA et le gabarit `nouveautes-anciens.html`) : c'était une opération
  **unique**, elle ne sera pas refaite, et le dépôt ne garde pas de surface
  dormante « au cas où ». `mailed_at` reste renseignée en base comme trace. Un
  geste futur est une **nouvelle** migration avec son propre envoi, jamais une
  résurrection de celui-ci. ⚠️ Une migration de données ne peut
  pas se tester en place (elle tourne avant tout jeu d'essai) :
  `LegacyPassCompensationIT` **relit le fichier de migration**, le coupe sur sa
  sentinelle `@@APPLICATION_DU_GESTE@@` et rejoue le SQL réel — ne pas supprimer
  cette ligne, et ne jamais recopier la requête dans le test.
