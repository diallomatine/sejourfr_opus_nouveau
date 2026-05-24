# Paiements & In-App Purchase — guide d'intégration (Web / iOS / Android)

Ce document explique **tout ce qu'il reste à faire pour que les paiements
marchent réellement** sur les 3 surfaces, après le travail des lots 4 → 4d
(commits `4815bfd` → `d166c55`). Le code est en place ; ce qui manque est
**de la configuration externe** (Stripe Dashboard, App Store Connect, Play
Console, Google Cloud) + **le câblage des identifiants en base et en variables
d'env**.

> Source de vérité du statut Premium = la table backend `user_subscriptions`,
> alimentée par 3 canaux : **Stripe** (web), **Apple** (iOS), **Google**
> (Android). Le client ne décide jamais s'il est Premium — il lit
> `GET /api/billing/subscription-status`. Cf. `CLAUDE.md` racine.

---

## 0. Le modèle commun à comprendre d'abord

Depuis le lot 4, **un Plan = un SKU = un Product ID par store**. Il y a
**6 SKUs payants** (+ FREE), définis en base par la migration `V106` :

| `plans.code`         | Module    | Périodicité  | `billing_cycle` | Prix indicatif |
|----------------------|-----------|--------------|-----------------|----------------|
| `CIVIQUE_MONTHLY`    | CIVIQUE   | mensuel      | `MONTHLY`       | 4,99 €         |
| `CIVIQUE_QUARTERLY`  | CIVIQUE   | trimestriel  | `THREE_MONTHS`  | 12,72 €        |
| `CIVIQUE_YEARLY`     | CIVIQUE   | annuel       | `YEARLY`        | 38,93 €        |
| `INTEGRAL_MONTHLY`   | INTEGRAL  | mensuel      | `MONTHLY`       | 9,99 €         |
| `INTEGRAL_QUARTERLY` | INTEGRAL  | trimestriel  | `THREE_MONTHS`  | 25,47 €        |
| `INTEGRAL_YEARLY`    | INTEGRAL  | annuel       | `YEARLY`        | 77,93 €        |

- **CIVIQUE** = module civique seul (CSP / CR / NAT).
- **INTEGRAL** = civique + TCF + EE/EO IA.

Chaque ligne `plans` porte 3 colonnes d'identifiants de store, **toutes NULL
au départ** :

- `stripe_price_id` — le `price_xxx` Stripe (web)
- `apple_product_id` — le Product ID App Store Connect (iOS)
- `google_product_id` — le Product ID Play Console (Android)

**Règle d'or : ces 3 identifiants doivent matcher EXACTEMENT ce que tu crées
dans chaque dashboard.** Tant qu'un identifiant est NULL ou faux :
- Stripe → `/payment-link` renvoie 404 sur ce plan.
- Apple/Google → le SKU revient dans `notFoundIDs` côté mobile et **la card ne
  s'affiche pas** dans le paywall.

La convention de nommage côté store recommandée est `<MODULE>_<PERIODICITY>`,
identique au `plans.code` (ex: `CIVIQUE_MONTHLY`). Garde le même string partout,
ça élimine une classe entière de bugs.

---

## 1. Backend — config transverse (à faire avant tout le reste)

Tous les flows passent par le backend. Rien ne marche tant que ces variables
d'env ne sont pas posées. Tant qu'un bloc est vide, l'endpoint correspondant
renvoie **503** (comportement volontaire, pas un bug).

### Variables d'env (prod = secrets ; dev = `backend_sejourfr/.env`)

```bash
# --- Stripe (web) ---
STRIPE_SECRET_KEY=sk_live_xxx          # ou sk_test_xxx en dev
STRIPE_WEBHOOK_SECRET=whsec_xxx
APP_BASE_URL=https://sejourfr.fr       # base des redirect success/cancel (dev: http://localhost:3000)

# --- Apple (iOS IAP) ---
APPLE_ISSUER_ID=99b16628-...           # App Store Connect → Integrations (UUID team-level)
APPLE_KEY_ID=ABCDEFGHIJ                 # 10 caractères
APPLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"  # contenu du .p8
APPLE_BUNDLE_ID=com.sejourfr.app
APPLE_APP_ID=1234567890                 # numérique, PROD uniquement
APPLE_ENVIRONMENT=SANDBOX               # SANDBOX en dev/TestFlight, PRODUCTION en store

# --- Google (Android IAP) ---
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'   # JSON brut de la clé SA
GOOGLE_PLAY_PACKAGE_NAME=com.sejourfr.app
GOOGLE_PUBSUB_AUDIENCE=https://api.sejourfr.fr/api/billing/webhooks/google
GOOGLE_PUBSUB_SA_EMAIL=pubsub-pusher@<project>.iam.gserviceaccount.com
```

Les clés mappent vers `application.yaml` (`sejourfr.stripe.*`, `sejourfr.apple.*`,
`sejourfr.google.*`). **Les Price IDs / Product IDs ne se mettent PAS en config**
— ils vivent en base sur `plans.*`.

### Certificats racine Apple (obligatoire pour vérifier les JWS)

Déposer les fichiers dans `backend_sejourfr/src/main/resources/apple/`, depuis
la section *Root Certificates* de <https://www.apple.com/certificateauthority/> :
- `AppleRootCA-G3.cer` (**obligatoire** — chaîne de signature actuelle des JWS App Store) — <https://www.apple.com/certificateauthority/AppleRootCA-G3.cer>
- `AppleRootCA-G2.cer` (par sécurité) — <https://www.apple.com/certificateauthority/AppleRootCA-G2.cer>
- `AppleIncRootCertificate.cer` (legacy, par sécurité) — <https://www.apple.com/appleca/AppleIncRootCertificate.cer>

> ⚠ L'ancien « Apple Computer, Inc. Root Certificate » n'est **plus proposé au
> téléchargement** sur la page (seule sa CRL subsiste) et n'est plus utilisé pour
> signer les JWS App Store — ne pas le chercher. `SignedDataVerifier` accepte un
> `Set` de racines : on fournit celles disponibles dans la section Root
> Certificates, G3 étant la seule réellement nécessaire.

Sans le cert G3, le bean reste en mode 503 (il ne commite pas de bouchon).

### Endpoints exposés (rappel)

| Endpoint | Auth | Rôle |
|---|---|---|
| `GET /api/billing/plans` | non | liste des plans actifs (utilisée par web + mobile pour afficher les prix) |
| `GET /api/billing/subscription-status` | oui | statut Premium agrégé (la source de vérité côté client) |
| `GET /api/billing/payment-link?planCode=<code>` | oui | Checkout Session Stripe (web) |
| `POST /api/billing/verify-receipt` | oui | l'app mobile soumet un reçu Apple/Google après achat |
| `POST /api/billing/webhook` | non* | Stripe (signé HMAC) |
| `POST /api/billing/webhooks/apple` | non* | Apple ASSN V2 (JWS signé) |
| `POST /api/billing/webhooks/google` | non* | Google RTDN via Pub/Sub (Bearer JWT vérifié) |

\* non-authentifié JWT user, mais **vérification de signature** propre à chaque provider.

---

## 2. WEB — Stripe (abonnements récurrents)

Surface : `web_sejoufr`, page `/paiement` + `/tarifs` (lot 4b déjà codé).
Modèle = **Checkout Session en mode `SUBSCRIPTION`**.

### 2.1 Stripe Dashboard

1. **Products** → créer 2 produits : « Civique » et « Intégral ».
2. Pour chacun, créer **3 prix récurrents** (mensuel / trimestriel / annuel) →
   6 Price IDs au total (`price_xxx`).
   - Civique : mensuel 4,99 € / trimestriel 12,72 € (tous les 3 mois) / annuel 38,93 €
   - Intégral : mensuel 9,99 € / trimestriel 25,47 € / annuel 77,93 €
   - Devise EUR, facturation récurrente avec l'intervalle correspondant.
3. **Webhooks → Add endpoint** : `https://api.sejourfr.fr/api/billing/webhook`.
   Sélectionner exactement ces events :
   - `checkout.session.completed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `charge.refunded`
   Copier le **Signing secret** (`whsec_xxx`) → `STRIPE_WEBHOOK_SECRET`.

### 2.2 Lier les Price IDs en base

```sql
UPDATE plans SET stripe_price_id = 'price_civ_month'  WHERE code = 'CIVIQUE_MONTHLY';
UPDATE plans SET stripe_price_id = 'price_civ_quart'  WHERE code = 'CIVIQUE_QUARTERLY';
UPDATE plans SET stripe_price_id = 'price_civ_year'   WHERE code = 'CIVIQUE_YEARLY';
UPDATE plans SET stripe_price_id = 'price_int_month'  WHERE code = 'INTEGRAL_MONTHLY';
UPDATE plans SET stripe_price_id = 'price_int_quart'  WHERE code = 'INTEGRAL_QUARTERLY';
UPDATE plans SET stripe_price_id = 'price_int_year'   WHERE code = 'INTEGRAL_YEARLY';
```

Ou plus simple : via l'admin (`/plans`, lot 4c) → modal d'édition, champ
« Stripe Price ID ». **Garde anti-incohérence** : un plan payant actif doit avoir
au moins un SKU renseigné, sinon le `PATCH` renvoie 400.

### 2.3 Variables web

`web_sejoufr/.env.local` :
```
NEXT_PUBLIC_API_BASE_URL=https://api.sejourfr.fr   # ou http://localhost:8080 en dev
```

### 2.4 Flow et points de vigilance

- Achat : `/paiement` → toggle périodicité → `billingApi.getPaymentLink(planCode)`
  (`planCode` dérivé par `planCodeFor(module, periodicity)`) → `window.location.assign(url)`.
- Retour : `/paiement/succes?session_id=…&plan=<code>` → la page poll `refreshUser()`
  jusqu'à voir `hasCivique`/`hasTcf` activé (mis à jour par le webhook backend).
- **`customer_email` est injecté sur la Session** (commit `d166c55`) pour empêcher
  Stripe Link de pré-remplir les cartes d'un autre compte sur le même navigateur.
  Ne pas retirer cette injection.
- **Cassure historique** : l'ancien web envoyait `?plan=BillingPlan`. Le lot 4b
  est passé à `?planCode=<string>`. Si une vieille URL traîne, elle renvoie 400.

### 2.5 Portail client (gérer / annuler l'abonnement)

Reste à brancher si pas encore fait : le **Stripe Customer Portal** (annulation,
changement de plan, mise à jour CB). Activer le portail dans Stripe Dashboard →
Settings → Billing → Customer portal, puis exposer un endpoint backend qui crée
une `billingPortal.Session` et rediriger l'utilisateur depuis `/profil`.

---

## 3. iOS — Apple StoreKit (In-App Purchase)

Surface : `mobile_sejourfr`, écran `screens/paywall/paywall_screen.dart` (lot 4d
déjà codé via le package `in_app_purchase`). **Obligatoire** : sur iOS on ne peut
PAS vendre de contenu digital hors IAP (guideline 3.1.1). L'ancien
`openSubscriptionWeb()` a été supprimé — ne pas le réintroduire.

### 3.1 App Store Connect

1. **Users and Access → Integrations → App Store Server API** → générer une clé.
   Télécharger le **.p8 (une seule fois)**. Noter `Issuer ID` (UUID) + `Key ID`
   (10 car.) → variables `APPLE_*` du backend.
2. **App → Subscriptions** : créer **un Subscription Group** (ex: « SejourFR
   Premium »), puis **6 abonnements** avec ces Product IDs exacts :
   `CIVIQUE_MONTHLY`, `CIVIQUE_QUARTERLY`, `CIVIQUE_YEARLY`,
   `INTEGRAL_MONTHLY`, `INTEGRAL_QUARTERLY`, `INTEGRAL_YEARLY`.
   - Durée : 1 mois / 3 mois / 1 an respectivement.
   - Renseigner prix, localisations, et **soumettre les métadonnées** (sinon le
     SKU ne remonte pas en sandbox).
   - Astuce Apple : Civique et Intégral sont deux niveaux du même service → on
     peut les mettre dans le même Subscription Group pour permettre l'upgrade/
     downgrade géré par Apple (proration). Sinon 2 groupes séparés.
3. **App Information → App Store Server Notifications → V2** : pointer
   **Production URL** et **Sandbox URL** sur
   `https://api.sejourfr.fr/api/billing/webhooks/apple`.

### 3.2 Lier les Product IDs en base

```sql
UPDATE plans SET apple_product_id = 'CIVIQUE_MONTHLY'    WHERE code = 'CIVIQUE_MONTHLY';
UPDATE plans SET apple_product_id = 'CIVIQUE_QUARTERLY'  WHERE code = 'CIVIQUE_QUARTERLY';
UPDATE plans SET apple_product_id = 'CIVIQUE_YEARLY'     WHERE code = 'CIVIQUE_YEARLY';
UPDATE plans SET apple_product_id = 'INTEGRAL_MONTHLY'   WHERE code = 'INTEGRAL_MONTHLY';
UPDATE plans SET apple_product_id = 'INTEGRAL_QUARTERLY' WHERE code = 'INTEGRAL_QUARTERLY';
UPDATE plans SET apple_product_id = 'INTEGRAL_YEARLY'    WHERE code = 'INTEGRAL_YEARLY';
```
(ou via l'admin `/plans`).

### 3.3 Config native Xcode

- **Runner → Signing & Capabilities → + Capability → In-App Purchase.**
- (Déjà présent pour le social login : « Sign in with Apple » via
  `Runner.entitlements`.)
- Bundle ID = `com.sejourfr.app`, identique à `APPLE_BUNDLE_ID`.

### 3.4 Tests sandbox

- App Store Connect → **Sandbox → Testers** : créer un compte Apple sandbox.
- Sur l'appareil : se déconnecter de l'App Store réel, builder via **TestFlight**
  ou run direct, et l'achat utilisera l'environnement sandbox.
- Backend en `APPLE_ENVIRONMENT=SANDBOX`.

### 3.5 Flow (déjà codé, pour comprendre)

1. Paywall → tap card → `IapService` ouvre la sheet native.
2. `purchaseStream` émet `purchased` → l'app envoie le **JWS** (`serverVerificationData`)
   à `POST /api/billing/verify-receipt`.
3. Le backend re-vérifie auprès d'Apple (source de vérité) puis écrit
   `user_subscriptions` et renvoie le statut.
4. `AuthController.refreshSubscriptionStatus()` met à jour `hasCivique/hasTcf`.
5. **Seulement alors** l'app acquitte le store (`completePurchase`). Si le backend
   échoue, on n'acquitte PAS → re-livraison au prochain boot, pas de double paiement.
- Bouton **« Restaurer mes achats »** : obligatoire pour la validation Apple
  (`restorePurchases` → même flow verify-receipt).

---

## 4. Android — Google Play Billing

Surface : même écran paywall mobile (le package `in_app_purchase` gère iOS et
Android). `IapService.currentSource` détecte Android → GOOGLE et extrait le
`purchaseToken` (`GooglePlayPurchaseDetails.billingClientPurchase`).

### 4.1 Google Cloud Console

1. **IAM → Service Accounts** : créer un SA dédié, générer une **clé JSON** →
   `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`.
2. **Pub/Sub** : créer un topic (ex: `play-rtdn`), puis une **subscription push** :
   - Endpoint : `https://api.sejourfr.fr/api/billing/webhooks/google`
   - Activer « Enable authentication », choisir un Service Account (peut être
     dédié Pub/Sub, distinct du SA Play API).
   - Audience : l'URL exacte de l'endpoint → `GOOGLE_PUBSUB_AUDIENCE`.
   - L'email de ce SA → `GOOGLE_PUBSUB_SA_EMAIL`.

### 4.2 Play Console

1. **Setup → API access** : lier le projet Google Cloud, accorder au SA Play API
   les permissions **« View financial data »** + **« Manage orders and
   subscriptions »**.
2. **Monetization setup → Real-time developer notifications** : pointer le Cloud
   project + le topic `play-rtdn`.
3. **Subscriptions** : créer **6 abonnements**, chacun avec **un Base Plan** dont
   la billing period correspond (mensuel / trimestriel / annuel). Product IDs
   exacts : `CIVIQUE_MONTHLY` … `INTEGRAL_YEARLY`.
4. `GOOGLE_PLAY_PACKAGE_NAME = com.sejourfr.app`.

### 4.3 Lier les Product IDs en base

```sql
UPDATE plans SET google_product_id = 'CIVIQUE_MONTHLY'    WHERE code = 'CIVIQUE_MONTHLY';
UPDATE plans SET google_product_id = 'CIVIQUE_QUARTERLY'  WHERE code = 'CIVIQUE_QUARTERLY';
UPDATE plans SET google_product_id = 'CIVIQUE_YEARLY'     WHERE code = 'CIVIQUE_YEARLY';
UPDATE plans SET google_product_id = 'INTEGRAL_MONTHLY'   WHERE code = 'INTEGRAL_MONTHLY';
UPDATE plans SET google_product_id = 'INTEGRAL_QUARTERLY' WHERE code = 'INTEGRAL_QUARTERLY';
UPDATE plans SET google_product_id = 'INTEGRAL_YEARLY'    WHERE code = 'INTEGRAL_YEARLY';
```
(ou via l'admin `/plans`).

> Note Play : avec les Base Plans, le Product ID exposé au client est celui de
> l'abonnement ; si tu utilises des `basePlanId` distincts, c'est cet identifiant
> qui doit matcher `google_product_id`. Garde l'alignement strict avec ce que
> remonte `loadProducts`.

### 4.4 Config native Android

- Rien à changer dans le code Flutter. Le `google_sign_in` / billing fonctionne
  via le `serverClientId`.
- **OAuth Client Android** dans Google Cloud Console : package name + SHA-1 des
  keystores **debug ET release** (le SHA-1 release est obligatoire pour que le
  billing marche sur un build signé).

### 4.5 Tests

- Play Console → **Testing track** (internal testing) + comptes Google de test
  (License testers). L'achat est gratuit pour ces comptes.
- Le build doit être **uploadé sur un track** et installé via le lien de test
  (le billing ne marche pas sur un APK side-loadé hors track).

### 4.6 Flow (idem iOS)

`purchased` → reçoit le `purchaseToken` → `verify-receipt` → le backend appelle
`purchases.subscriptionsv2.get` (état autoritatif) → écrit `user_subscriptions`.
Les renouvellements/annulations arrivent ensuite par RTDN sur le webhook Google.

---

## 5. Anti-double-paiement (cross-canal)

Géré côté backend, rien à configurer, mais à connaître pour les tests :

- Un user déjà Premium via **Stripe** qui ouvre l'app mobile →
  `subscription-status` renvoie `isPremium=true, source=STRIPE` → le paywall IAP
  masque le bouton d'achat. Et inversement.
- `original_transaction_id` est la **clé de réconciliation** stable (Apple:
  `originalTransactionId`, Google: `purchaseToken`, Stripe: `subscription_id`).
  Index unique `(source, original_transaction_id)` → un renouvellement update la
  ligne, ne crée pas de doublon.
- **Account stealing** : un reçu déjà rattaché à un user A → 409 si un user B
  tente le même reçu (Family Sharing non géré, limite assumée).

---

## 6. Checklist de mise en prod

**Backend**
- [ ] `STRIPE_SECRET_KEY` + `STRIPE_WEBHOOK_SECRET` + `APP_BASE_URL` posés
- [ ] `APPLE_*` (6 vars) + 3 certs racine dans `resources/apple/`
- [ ] `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` + `GOOGLE_PLAY_PACKAGE_NAME` + `GOOGLE_PUBSUB_*`
- [ ] `APPLE_ENVIRONMENT=PRODUCTION` au passage en store

**Base de données** (les 18 colonnes : 6 plans × 3 stores)
- [ ] `plans.stripe_price_id` rempli sur les 6 plans
- [ ] `plans.apple_product_id` rempli sur les 6 plans
- [ ] `plans.google_product_id` rempli sur les 6 plans

**Stripe**
- [ ] 2 produits × 3 prix créés
- [ ] webhook → `/api/billing/webhook` avec les 5 events

**Apple**
- [ ] Subscription Group + 6 SKUs (métadonnées soumises)
- [ ] ASSN V2 → `/api/billing/webhooks/apple` (prod + sandbox URLs)
- [ ] Capability In-App Purchase dans Xcode

**Google**
- [ ] 6 abonnements (Base Plans) créés
- [ ] SA Play API + permissions financières/abonnements
- [ ] Pub/Sub topic + push sub authentifiée → `/api/billing/webhooks/google`
- [ ] RTDN pointée sur le topic
- [ ] SHA-1 release dans l'OAuth client Android

**Validation end-to-end**
- [ ] Achat Stripe test → webhook → `subscription-status` repasse Premium
- [ ] Achat sandbox iOS → verify-receipt → Premium → restore fonctionne
- [ ] Achat test Android → verify-receipt → Premium
- [ ] Annulation (chaque canal) → reste Premium jusqu'à `ends_at` puis EXPIRED
- [ ] Remboursement → REFUNDED + Premium retiré
- [ ] Cross-canal : Premium Stripe masque le paywall mobile, et inversement

---

## 7. Pièges fréquents (debugging)

| Symptôme | Cause probable |
|---|---|
| `/payment-link` → 404 | `plans.stripe_price_id` NULL ou plan inactif |
| `/api/billing/*` → 503 | variable d'env du provider non posée (clé vide) |
| Card absente du paywall mobile | Product ID store ≠ `plans.apple/google_product_id`, ou SKU pas encore approuvé/soumis |
| Achat OK mais user reste démo | webhook non reçu (mauvaise URL/secret) ou verify-receipt en échec → vérifier les logs |
| Webhook Stripe rejeté | `STRIPE_WEBHOOK_SECRET` ne correspond pas à l'endpoint |
| Webhook Apple/Google ignoré | signature JWS / Bearer JWT invalide, ou `messageId`/`event_id` déjà traité (idempotence — normal) |
| Cartes d'un autre compte pré-remplies | injection `customer_email` retirée (cf. `d166c55`) |

---

*Le code applicatif des 3 surfaces est terminé (lots 4 → 4d). Ce qui reste est
purement de la configuration de comptes externes + le remplissage des 18
identifiants de store en base. Une fois la checklist §6 verte, les paiements
sont opérationnels de bout en bout.*
