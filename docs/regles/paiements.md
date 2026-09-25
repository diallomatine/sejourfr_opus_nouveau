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

**Emails Premium** — système d'emails, `docs/regles/emails.md` (refonte du 2026-09-25 ;
l'ancien `MailService` n'existe plus pour eux) :
- **`PREMIUM_ACCESS_STARTED`** (premier accès) / **`PREMIUM_ACCESS_EXTENDED`** (achat qui
  **prolonge** un accès de module ≥ en cours, « durées cumulées ») : publiés par
  `OneTimeAccessService` au moment où l'accès est **accordé** (arbitrage n°20), commun aux
  trois canaux ; clé `…:{user_subscriptions.id}` ; envoyés **après commit**. `offerName` =
  `plans.name` (« pass »). Un rejeu du même reçu ne crée ni ligne ni mail.
- Flux **abonnement récurrent dormants** (Stripe/Apple/Google, via
  `SubscriptionNotificationService`) : activation = `PREMIUM_ACCESS_STARTED` (wording
  « renouvelé automatiquement » porté par `accessTerms`), résiliation =
  `PREMIUM_SUBSCRIPTION_CANCELED` (transition `oldStatus ≠ CANCELED → CANCELED`, triggers
  inchangés). Pas de mail sur expiration naturelle ni sur refund/revoke.
- **Fin d'accès** : scénarios ENGAGEMENT `PREMIUM_ENDING_7_DAYS` / `_2_DAYS` / `PREMIUM_ENDED`
  (passage quotidien), qui remplacent l'ancien `ExpiryReminderJob` ; `expiry_reminded_at` reste
  en base mais n'est plus écrit. Les abonnements récurrents dormants en sont exclus.
- **Wording achat unique** : aucun « abonnement » / « renouvellement automatique » côté client,
  sauf dans les deux mails du mode récurrent dormant.
- 🛑 Un échec d'envoi ne fait jamais échouer un paiement : l'événement est publié dans la
  transaction, le mail part après son commit sur l'executor email.
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

### 🛑 Un webhook ne sauvegarde que si l'état métier a changé

Valable pour les **trois** sources. `updated_at` (colonne « mise à jour » de la
console admin) n'avance **que sur un vrai changement** — c'est un
`@PreUpdate` sur `UserSubscription`, il ne se déclenche que si un `UPDATE` est
réellement émis.

- La dédup par `event_id` / `notificationUUID` / `messageId`
  (`processed_external_events`) dit « ce **message**-là a déjà été vu ». Elle ne
  dit **jamais** « cet **état**-là est déjà en base ». Les deux sont
  nécessaires : plusieurs messages **légitimement distincts** décrivent le même
  événement métier (Stripe émet une rafale d'events par cycle, Pub/Sub est
  at-least-once par design, Apple renotifie).
- Donc, avant tout `save()` : on **photographie** l'état métier
  (`EtatAbonnement.de(sub)`), on applique l'état entrant, on **compare**
  (`identiqueA`). Rien n'a bougé ⇒ **pas de `save()`**. Toute nouvelle colonne
  métier de `user_subscriptions` s'ajoute à ce record — un champ oublié serait
  un changement réel qui ne déclencherait aucune sauvegarde.
- Les `apply*` n'écrivent que ce qui diffère (`EtatAbonnement.poser`). Le
  dirty-checking par défaut d'Hibernate compare au snapshot de chargement (une
  ré-affectation identique ne salit donc pas l'entité), mais on ne fait pas
  reposer une règle de facturation sur un réglage : un dirty-tracking par
  bytecode suivrait l'appel du setter, pas la valeur.
- 🛑 **`null` = inconnu, jamais « effacé »** sur un identifiant servi par un
  store : un `customer.subscription.updated` dont `latest_invoice` est encore
  `null`, ou un état Play sans `latestOrderId`, ne fait **pas** oublier l'id
  déjà connu (`EtatAbonnement.connuOu`). Sans ça, la ligne perd sa traçabilité
  **et** l'aller-retour `null ⇄ in_xxx` fait avancer `updated_at` deux fois
  sans le moindre changement métier. Même convention que les
  `toInstant(valeur, fallback)` / `parseExpiry(…)` / `deriveAutoRenew(…)` des
  autres champs.
- `expiry_reminded_at` n'est plus écrit (l'ancien `ExpiryReminderJob` est supprimé depuis le
  2026-09-25, remplacé par les scénarios `PREMIUM_ENDING_*` du système d'emails).

Verrouillé par `StripeSubscriptionServiceTest` / `AppleSubscriptionServiceTest` /
`GoogleSubscriptionServiceTest` (un webhook rejoué à état identique ⇒ `save()`
appelé **au plus une fois**) et par `StripeWebhookUpdatedAtIT`, qui le vérifie
contre la vraie base : `updated_at` ne bouge pas sur un webhook sans
changement, et avance sur un renouvellement.


---

## Le paywall est CONTEXTUALISÉ (lot L5, 2026-09-10)

`10_` §5 : « Personnalisation obligatoire : niveau actuel, niveau cible, les 3
priorités réelles, et la date d'examen si renseignée. **Un paywall sans ces
éléments est un bug.** »

🛑 **Mais un paywall qui MENT est pire qu'un paywall générique.** Chaque élément
est **facultatif** et se calcule sur ce que le serveur a réellement servi :

| Donnée absente | Ce qu'on affiche |
|---|---|
| Plan pas en cache | le message générique, inchangé |
| `startingLevel` nul | on n'annonce aucun niveau mesuré |
| `objectiveLevel` nul | « Votre plan est prêt », sans palier |
| aucune priorité | aucune liste |
| `examDate` nulle | ni échéance, ni recommandation de pass |

🛑 **Best-effort, jamais bloquant, jamais de spinner.** La feuille s'ouvre tout
de suite ; le contexte s'ajoute quand il arrive. Un indicateur d'attente devant
une offre est le meilleur moyen de perdre l'acheteur. Un échec de chargement ne
dégrade rien et n'empêche jamais l'achat.

**Aucun appel réseau de plus** : le web lit le Plan **en cache**
(`learningPlanApi.getCached`) et le mobile son provider **déjà vivant** ; le
catalogue de pass vient des produits que le contrôleur de facturation a déjà
chargés.

### Le levier propre aux pass : aligner la durée sur l'échéance

> « Votre examen est le 18 octobre. Le pass 2 mois couvre toute votre
> préparation. »

🛑 **On ne recommande que ce que le catalogue propose réellement**, et seulement
un pass qui **couvre** l'échéance — promettre une couverture qu'un pass ne tient
pas serait pire que se taire. Et parmi ceux qui couvrent, **le plus court** : on
répond au besoin, on ne pousse pas au plus cher. Aucun pass assez long ⇒ on
n'affiche rien.

Ce levier n'existe que depuis `users.exam_date` (V047, lot L1).

### Ce que la spec demandait de réécrire, et qui n'existait pas

`50_` §3.4 liste des formulations à supprimer (« 14,99 €/mois », « Annulable à
tout moment », « renouvellement le 9 octobre », « Passez Premium »).
**Vérifié à la livraison de L5 : aucune n'existe dans le code.** Le dépôt parle
déjà correctement des pass (« Paiement unique — aucun renouvellement
automatique »). Le seul « S'abonner » du web est le bouton de **newsletter** du
pied de page, sans rapport avec le paiement. La réécriture portait sur les
specs, pas sur l'application.

⚠️ Le mobile garde « annulable à tout moment » **uniquement dans la branche
abonnement** (`oneTime == false`), qui est dormante et exacte pour un abonnement
récurrent. Ne pas la supprimer : elle redeviendra vraie si les abonnements sont
réactivés.

**Règles pures, une fois par front** : `web_sejoufr/lib/paywall-context.ts` ⇄
`mobile_sejourfr/lib/core/widgets/paywall_context.dart`, miroirs l'un de
l'autre.

---

## Revenus nets, remboursements, intention d'achat (chantier « Suivi », lot 2b, 2026-09-25)

Arbitrages opposables : `docs/admin/decisions-suivi.md` §1 (Q1, Q11, Q12, scénario 18).
Schéma : V074 (colonnes de revenu et d'attribution de `user_subscriptions`,
`purchase_intent`, `payment_refunds`).

### Décomposition du revenu — figée à l'écriture

- **Autorité unique** : `service/billing/RevenueCalculator` (pur), sur les règles versionnées
  `billing/revenue-rules-v{n}.json`. Appelée par `OneTimeAccessService` à la **création** d'un
  achat (jamais sur un rejeu), après `MontantEncaisse` — `amount_eur_cents` **est** le brut.
- **Stripe** (`FRANCHISE_293B`) : `vat = 0`, `HT = gross`. Frais = `balance_transaction.fee`
  réel (`StripeFeeClient`, `fee_source = ACTUAL`) ; sinon formule `gross × 1,5 % + 25 c`
  (`ESTIMATED`). `net_after_fee = gross − fee`, `net_ex_vat = HT − fee`.
  9,99 € → TVA 0, frais 0,40, net 9,59.
- **Apple / Google** : TVA store 20 % retirée, `HT = round(gross / 1,2)` HALF_UP ; commission
  **MULTIPLY** au taux **du store** (config, provisoire 0,15) ; `net_after_fee = net_ex_vat =
  HT − fee` ; toujours `ESTIMATED`. 9,99 € → 7,08 (15 %) ; 5,83 (30 %).
- 🛑 Invariant `amount_eur_cents = vat + fee + net_ex_vat` asserté par `RevenueBreakdown` **et**
  par la base (CHECK V074). `revenue_rules_version` figée avec la ligne : changer de règle ne
  recalcule rien.
- 🛑 **Pas de backfill.** Un achat antérieur, ou dont le brut en euros est inconnu (devise sans
  taux), garde ses six colonnes à `NULL` — inconnu, jamais zéro.
- `purchased_at` = date donnée par le canal (évènement Stripe signé, `purchaseDate` du JWS
  Apple, `purchaseTimeMillis` Play), sinon l'heure d'écriture. `payment_status = PAID` à la
  création (`PaymentStatus` : `PAID | PARTIALLY_REFUNDED | REFUNDED`, distinct du statut
  d'accès).

### Prix des stores (bug Q11)

- Le mobile envoie `amountCents` + `currency` ; le backend n'attendait que `rawPrice` (ignoré en
  silence par Jackson). Les deux formes sont lues (`ReceiptVerificationService.montantDeclare`).
- **Apple** : le prix se lit dans le **JWS signé** (`price` en millièmes → centièmes, HALF_UP,
  `currency`) ; celui déclaré par l'app n'est plus lu. JWS sans prix ⇒ prix du plan.
- **Google** : `purchases.products.get` ne rend aucun prix ; le montant déclaré n'est retenu que
  si son équivalent en euros tient dans `plans.price × (1 ± sejourfr.billing.store-price-tolerance)`
  (0,5), sinon le prix du catalogue. Devise sans taux ⇒ catalogue.

### Stripe : encaissement et rejeu (bug Q11)

- 🛑 `checkout.session.completed` n'accorde l'accès que si `payment_status = paid`. Un paiement
  différé est accordé sur `checkout.session.async_payment_succeeded`.
  ⚠️ **Action propriétaire** : abonner l'endpoint webhook Stripe à
  `checkout.session.async_payment_succeeded` et `checkout.session.async_payment_failed`.
- 🛑 **Plus aucune garde sur l'âge de l'évènement** : Stripe garde le `created` d'origine sur ses
  relances (jusqu'à 3 jours), l'ancienne garde de 300 s rejetait définitivement un achat payé.
  Le rejeu est tenu par la tolérance de la **signature** (`Webhook.constructEvent`, horodatage
  régénéré à chaque livraison) et par `processed_external_events`.

### Remboursements — `payment_refunds`

Autorité unique : `PaymentRefundService`. Idempotence `(provider, provider_refund_id)` ;
plusieurs partiels par achat possibles. Montant dans la devise de l'achat, converti au taux
**figé sur l'achat**. `net_ex_vat_delta_cents` (≤ 0) figé avec la version des règles, `NULL` si
la décomposition de l'achat est inconnue.

| Canal | Déclencheur | `provider_refund_id` | Montant | Delta de net HT |
|---|---|---|---|---|
| Stripe | `charge.refunded` | `<charge>:<amount_refunded cumulé>` | cumul − déjà enregistré | `−HT` du rendu (Stripe garde ses frais) |
| Apple | ASSN `REFUND` | `transactionId` | brut × `revocationPercentage` (absent ⇒ total) | `−net_ex_vat` au prorata |
| Google | `voidedPurchaseNotification` | `orderId` (sinon `purchaseToken`) | brut entier | `−net_ex_vat` |

- Remboursement **total** ⇒ `status = REFUNDED` (accès retiré), `payment_status = REFUNDED`.
  **Partiel** ⇒ accès conservé, `payment_status = PARTIALLY_REFUNDED` (bug Q11 : un partiel
  Stripe retirait l'accès).
- Scénario 13 : Stripe total ⇒ net de l'achat `959 − 999 = −40` ; store total ⇒ `0`.
- Apple `REVOKE` (partage familial) retire l'accès sans ligne de remboursement ;
  `REFUND_REVERSED` reste ignoré en mode pass.

### Intention d'achat — `purchase_intent` (Q12)

- Créée côté serveur **avant chaque démarrage d'achat** : web = dans `GET /payment-link`
  (paramètres `ctaLocation`, `journeyId`), transportée par `metadata.intentId` ; mobile =
  `POST /api/billing/purchase-intents`, puis `purchaseIntentId` dans `verify-receipt`.
  🛑 **Jamais** `appAccountToken` / `obfuscatedAccountId` / `obfuscatedProfileId`.
- `diagnostic_run_id` résolu **serveur** depuis le parcours (`journey_assessment_event` du
  premier diagnostic → `diagnostic_run` du même compte), jamais reçu. TTL 24 h, usage unique.
- Consommée dans la transaction qui écrit l'achat, par un `UPDATE` conditionnel : même compte,
  même produit (`plans.code`), non expirée **à l'instant de l'achat**, non consommée. Sinon
  `origin = UNKNOWN`, run nulle, l'intention reste intacte.
- `origin = DIAGNOSTIC_PLAN` si CTA du Plan (`LOCKED_PLAN`) **et** run fondatrice connue ;
  `OTHER_CTA` pour toute autre intention valide (run non posée, parcours conservé) ; `UNKNOWN`
  sinon. 🛑 Aucune reconstruction heuristique (pas de « run la plus récente »).
- Les chemins d'abonnement récurrent (dormants) ne décomposent ni n'attribuent : ils ne sont
  pas en service.
