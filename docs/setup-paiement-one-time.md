# Setup paiement — Passes one-time (Lot 5)

Guide pas-à-pas pour activer le modèle **achat unique** (passes à durée fixe,
sans abonnement). À faire une fois côté Stripe, App Store Connect et Google Play
Console, puis renseigner les SKU en base.

> Le modèle abonnement (lots 2/3/4) reste en place, dormant. Pour y revenir :
> `BILLING_MODE=SUBSCRIPTION` + réactiver les plans récurrents (cf. CLAUDE.md
> racine § Paiements, Lot 5).

## Catalogue (rappel)

| Code (Plan.code / Apple) | Google product id (minuscules) | Module | Prix | Durée |
|---|---|---|---|---|
| `CIVIQUE_PASS_3M` | `civique_pass_3m` | Civique | 9,99 € | 90 j |
| `CIVIQUE_PASS_1Y` | `civique_pass_1y` | Civique | 29,99 € | 365 j |
| `INTEGRAL_PASS_SPRINT` | `integral_pass_sprint` | Intégral | 19,99 € | 42 j |
| `INTEGRAL_PASS_3M` | `integral_pass_3m` | Intégral | 35,99 € | 90 j |
| `INTEGRAL_PASS_1Y` | `integral_pass_1y` | Intégral | 79,99 € | 365 j |

⚠️ **La durée d'accès est posée par le backend** (`plans.duration_days`), pas par
le store. Le store ne fait qu'encaisser un paiement unique. Donc 6 semaines (42 j)
ne nécessite aucune config de durée côté store.

---

## 0. Activer le mode (backend)

1. Variable d'environnement : `BILLING_MODE=ONE_TIME` (défaut déjà `ONE_TIME`,
   mais à poser explicitement en prod pour la lisibilité).
2. La migration `V418` a déjà activé les 5 passes et désactivé les 6 plans
   récurrents. Vérifier : `SELECT code, is_active, purchase_type, duration_days
   FROM plans WHERE purchase_type = 'ONE_TIME';` doit renvoyer 5 lignes actives.

---

## 1. Stripe (web) — rien à créer

Le checkout web utilise un **montant dynamique** (`price_data` depuis
`plans.price`), donc **aucun Price Stripe à créer**. Il suffit que la config
existante soit en place :

1. **Dashboard Stripe → Developers → API keys** : `STRIPE_SECRET_KEY` renseignée
   côté backend.
2. **Dashboard Stripe → Developers → Webhooks → ton endpoint**
   (`https://api.sejourfr.fr/api/billing/webhook`) → bouton **« … » → Update
   details → Select events** : s'assurer que ces deux events sont cochés :
   - `checkout.session.completed`
   - `charge.refunded`
   (Les `customer.subscription.*` peuvent rester cochés, ils ne se déclenchent
   pas en mode one-time.) Copier le **Signing secret** dans `STRIPE_WEBHOOK_SECRET`.
3. `APP_BASE_URL` pointe sur le web (pour les URLs de succès/annulation).

Le prix est géré en base : pour ajuster, `UPDATE plans SET price = … WHERE code = …`
(ou via l'admin), aucune action Stripe.

---

## 2. Apple — App Store Connect (produits **Consommables**)

On crée 5 produits **Consommables** (re-achetables après expiration). Le type
n'a pas d'importance pour le backend en mode one-time, mais Consommable est le
bon choix pour des passes ré-achetables via `in_app_purchase`.

1. Va sur **https://appstoreconnect.apple.com** → **Mes apps** → l'app **SejourFR**.
2. Dans la barre latérale, sous **Monétisation**, clique **Achats intégrés**
   (In-App Purchases).
3. Clique le bouton **+ (Créer)** en haut de la liste.
4. Choisis le type **Consommable** → **Créer**.
5. Renseigne :
   - **Référence** (nom interne, libre) : ex. `Civique - pass 3 mois`.
   - **ID de produit** : **exactement** le code du plan, en MAJUSCULES :
     `CIVIQUE_PASS_3M`.
6. Section **Disponibilité** : laisse tous les pays (ou ta liste).
7. Section **Tarification** → **Ajouter une tarification** → choisis le palier
   le plus proche de **9,99 €** (Apple impose des paliers ; prends le palier
   « Tier » qui donne 9,99 € en zone Euro).
8. Section **Localisations** → **+ Ajouter une localisation** → Français :
   - **Nom affiché** : `Pass Civique 3 mois`.
   - **Description** : `Accès au module civique pendant 3 mois.`
9. **Enregistrer** en haut à droite.
10. **Répète les étapes 3 à 9** pour les 4 autres produits :
    | ID de produit (MAJ) | Prix cible | Nom affiché |
    |---|---|---|
    | `CIVIQUE_PASS_1Y` | 29,99 € | Pass Civique 1 an |
    | `INTEGRAL_PASS_SPRINT` | 19,99 € | Pass Intégral sprint 6 semaines |
    | `INTEGRAL_PASS_3M` | 35,99 € | Pass Intégral 3 mois |
    | `INTEGRAL_PASS_1Y` | 79,99 € | Pass Intégral 1 an |
11. **Sandbox de test** : **Utilisateurs et accès → Sandbox → Testeurs** →
    **+** pour créer un compte de test, puis teste l'achat via **TestFlight**.
12. **Webhook** (déjà configuré au lot 2, à vérifier) : **App Information →
    App Store Server Notifications → Production/Sandbox URL** =
    `https://api.sejourfr.fr/api/billing/webhooks/apple`. (Sert aux refunds.)

> Pas besoin de la capability « Sign in with Apple » ici ; l'In-App Purchase
> est activée dans Xcode → cible Runner → Signing & Capabilities → **+ Capability
> → In-App Purchase** (déjà fait au lot 4d).

---

## 3. Google — Play Console (produits intégrés **managed**)

On crée 5 **produits intégrés** (in-app products), product IDs en **minuscules**.

1. Va sur **https://play.google.com/console** → sélectionne l'app **SejourFR**.
2. Barre latérale → **Monétiser** → **Produits** → **Produits intégrés**
   (In-app products).
3. Clique **Créer un produit**.
4. Renseigne :
   - **ID de produit** : **exactement** le code en **minuscules** :
     `civique_pass_3m`. ⚠️ Google **refuse les majuscules** — c'est pour ça que
     le backend minuscule le code pour Google.
   - **Nom** : `Pass Civique 3 mois`.
   - **Description** : `Accès au module civique pendant 3 mois.`
5. Section **Prix** → **Définir le prix** → **9,99 €** (Google convertit pour
   les autres devises).
6. Mets le produit **Actif** (toggle / statut) puis **Enregistrer**.
7. **Répète les étapes 3 à 6** pour les 4 autres :
   | ID de produit (minuscules) | Prix | Nom |
   |---|---|---|
   | `civique_pass_1y` | 29,99 € | Pass Civique 1 an |
   | `integral_pass_sprint` | 19,99 € | Pass Intégral sprint 6 semaines |
   | `integral_pass_3m` | 35,99 € | Pass Intégral 3 mois |
   | `integral_pass_1y` | 79,99 € | Pass Intégral 1 an |
8. **RTDN** (refunds, déjà configuré au lot 3) : **Monétiser → Configuration de
   la monétisation → Notifications développeur en temps réel** pointe sur le
   topic Pub/Sub `play-rtdn`. La push subscription Pub/Sub pointe sur
   `https://api.sejourfr.fr/api/billing/webhooks/google`.
9. **Test** : **Configuration → Tests sur les versions internes** (piste de test
   interne) + ajouter des comptes Google testeurs.

> Les passes sont **consommés** côté client (le plugin `in_app_purchase` avec
> `autoConsume: true`) pour être ré-achetables après expiration — rien à faire
> côté Console.

---

## 4. Renseigner les SKU en base

Une fois les produits créés des deux côtés, lier les SKU aux plans :

```sql
UPDATE plans SET apple_product_id = 'CIVIQUE_PASS_3M',       google_product_id = 'civique_pass_3m'       WHERE code = 'CIVIQUE_PASS_3M';
UPDATE plans SET apple_product_id = 'CIVIQUE_PASS_1Y',       google_product_id = 'civique_pass_1y'       WHERE code = 'CIVIQUE_PASS_1Y';
UPDATE plans SET apple_product_id = 'INTEGRAL_PASS_SPRINT',  google_product_id = 'integral_pass_sprint'  WHERE code = 'INTEGRAL_PASS_SPRINT';
UPDATE plans SET apple_product_id = 'INTEGRAL_PASS_3M',      google_product_id = 'integral_pass_3m'      WHERE code = 'INTEGRAL_PASS_3M';
UPDATE plans SET apple_product_id = 'INTEGRAL_PASS_1Y',      google_product_id = 'integral_pass_1y'      WHERE code = 'INTEGRAL_PASS_1Y';
```

(ou via la console admin → Plans, qui édite les store IDs + le prix.)

`stripe_price_id` reste **NULL** pour les passes (Stripe utilise le montant
dynamique).

---

## 5. Vérifier de bout en bout

1. **Mobile** : ouvrir le paywall → la grille de passes s'affiche avec les prix
   du store (devise locale). Si des SKU manquent → ils reviennent dans
   `notFoundIDs` (log) et la card ne s'affiche pas : vérifier l'alignement
   product id ↔ `plans.apple/google_product_id`.
2. Acheter un pass (sandbox/test) → l'app appelle `verify-receipt` → Premium
   activé → le paywall se ferme.
3. **Web** : `/paiement` → choisir un pass → Checkout Stripe (mode paiement
   unique) → succès → Premium.
4. **Expiration** : forcer `UPDATE user_subscriptions SET ends_at = now() -
   interval '1 day'` → l'accès retombe non-Premium à la prochaine lecture de
   `/subscription-status` (pas de job, c'est lazy).
5. **Refund** : déclencher un remboursement store/Stripe → webhook → statut
   `REFUNDED` → accès retiré.
