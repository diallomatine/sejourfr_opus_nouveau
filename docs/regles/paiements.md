# Paiements multi-source (Stripe + Apple + Google)

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Contenu verbatim, aucune réécriture.**
> Origine : lignes 4131-4234, 4367-4508 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier porte la loi de ce sous-système : on l'ouvre **quand on travaille dedans**.
> Fichier jumeau : `docs/decisions/paiements.md`
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

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

**`GET /api/billing/plans`** expose `realtimeEoSessions` (colonne
`plans.realtime_eo_sessions`, V018/V113/V114) : le nombre de simulations orales
en temps réel ouvertes par le pass — **5 (7 j) / 15 (1 mois) / 25 (2 mois)** sur
Intégral, **0** sur Civique et Free. Les fronts l'affichent tel quel au lieu de
coder le quota en dur — il reste éditable côté admin. **C'est la seule ressource
qui distingue deux passes Intégral** (même catalogue, mêmes examens blancs,
mêmes corrections IA : seules la durée et ce quota progressent), donc il est
annoncé **sur chaque ligne de pass** — `/paiement`, `/tarifs`, `/reussir` et le
paywall mobile — par un libellé unique par front, `realtimeSessionsLabel`
(`web_sejoufr/lib/types.ts` ⇄ `PlanPublicResponse.realtimeSessionsLabel` dans
`mobile_sejourfr/lib/core/models/billing_models.dart`), miroirs mot pour mot.
⚠️ Il ne dit **jamais** « sans simulation orale » sur un pass **Intégral** : un
backend antérieur au champ le renvoie à 0, et ce serait faux sur l'argument
principal du produit — il rend alors « incluses », sans chiffre. Seul le module
(source sûre) autorise le « sans », et seule `/reussir` l'écrit, parce que sa
puce de liste doit exister même vide.

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
