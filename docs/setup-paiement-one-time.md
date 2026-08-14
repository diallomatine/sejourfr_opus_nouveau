# Setup paiement — Passes one-time (Lot 5)

Guide pas-à-pas pour activer le modèle **achat unique** (passes à durée fixe,
sans abonnement). À faire une fois côté Stripe, App Store Connect et Google Play
Console, puis renseigner les SKU en base.

> Le modèle abonnement (lots 2/3/4) reste en place, dormant. Pour y revenir :
> `BILLING_MODE=SUBSCRIPTION` + réactiver les plans récurrents (cf. CLAUDE.md
> racine § Paiements, Lot 5).

## Catalogue (rappel)

| Plan.code (backend)  | Product id store (Apple = Google, minuscules) | Module   | Prix    | Durée | Simulations orales |
|----------------------|-----------------------------------------------|----------|---------|-------|--------------------|
| `CIVIQUE_PASS_3M`    | `civique_pass_3m`                             | Civique  | 9,99 €  | 90 j  | —                  |
| `CIVIQUE_PASS_1Y`    | `civique_pass_1y`                             | Civique  | 29,99 € | 365 j | —                  |
| `INTEGRAL_PASS_7J`   | `integral_pass_7j`                            | Intégral | 9,99 €  | 7 j   | 5                  |
| `INTEGRAL_PASS_1M`   | `integral_pass_1m`                            | Intégral | 19,99 € | 30 j  | 15                 |
| `INTEGRAL_PASS_2M`   | `integral_pass_2m`                            | Intégral | 29,99 € | 60 j  | 25                 |

⚠️ **Les trois anciens passes Intégral** (`integral_pass_sprint` 42 j / 19,99 €,
`integral_pass_3m` 90 j / 34,99 €, `integral_pass_1y` 365 j / 79,99 €) sont
**désactivés en base** par `V114`, donc absents de `GET /api/billing/plans`, du
paywall et des grilles de tarifs. **Ne pas les supprimer des stores** : leurs
product IDs doivent rester résolvables pour les remboursements et les webhooks
des achats déjà encaissés. Il suffit de les rendre **indisponibles à la vente**
côté console (cf. `docs/bascule-prix-integral.md`).

Le même Product ID sert pour Apple et Google (en minuscules — contrainte Google,
tolérée par Apple). Le mobile lit ces IDs depuis le backend
(`PlanPublicResponse.appleProductId` / `googleProductId`), il ne les déduit plus
de `Plan.code`.

⚠️ **La durée d'accès est posée par le backend** (`plans.duration_days`), pas par
le store. Le store ne fait qu'encaisser un paiement unique. Donc 7 jours ou
2 mois ne nécessitent aucune config de durée côté store.

---

## 0. Activer le mode (backend)

1. Variable d'environnement : `BILLING_MODE=ONE_TIME` (défaut déjà `ONE_TIME`,
   mais à poser explicitement en prod pour la lisibilité).
2. Les migrations de référence ont activé les passes et désactivé les plans
   récurrents (`V100`), puis remplacé les passes Intégral (`V114`). Vérifier :
   `SELECT code, is_active, purchase_type, duration_days, realtime_eo_sessions
   FROM plans WHERE purchase_type = 'ONE_TIME' ORDER BY code;` doit renvoyer
   **5 lignes actives** (2 Civique + 3 Intégral) et 3 lignes inactives (les
   anciens passes Intégral).

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

On crée 5 produits **Consommables**. ⚠️ Le type est **critique** : seul un
Consommable est ré-achetable (Apple ré-affiche la sheet de paiement à chaque
achat). Un **Non-Consommable** est « possédé à vie » → Apple refuse le rachat et
restaure la transaction d'origine (même `transactionId`) → le backend la traite
en *replay*, **aucune prolongation**. La durée d'accès vient du backend
(`plans.duration_days`), Apple n'encaisse qu'un paiement.

⚠️ Le **Product ID d'un produit Apple supprimé n'est jamais réutilisable**. Si tu
avais d'abord créé ces passes en Non-Consommable, recrée-les en Consommable avec
un ID **différent** — d'où le choix de minuscules ci-dessous : chaîne distincte
des anciens IDs en majuscules, et identique aux IDs Google.

1. Va sur **https://appstoreconnect.apple.com** → **Mes apps** → l'app **SejourFR**.
2. Dans la barre latérale, sous **Monétisation**, clique **Achats intégrés**
   (In-App Purchases).
3. Clique le bouton **+ (Créer)** en haut de la liste.
4. Choisis le type **Consommable** → **Créer**.
5. Renseigne :
    - **Référence** (nom interne, libre) : ex. `Civique - pass 3 mois`.
    - **ID de produit** : en **minuscules**, identique à l'ID Google :
      `civique_pass_3m`.
6. Section **Disponibilité** : laisse tous les pays (ou ta liste).
7. Section **Tarification** → **Ajouter une tarification** → choisis le palier
   le plus proche de **9,99 €** (Apple impose des paliers ; prends le palier
   « Tier » qui donne 9,99 € en zone Euro).
8. Section **Localisations** → **+ Ajouter une localisation** → Français :
    - **Nom affiché** : `Pass Civique 3 mois`.
    - **Description** : `Accès au module civique pendant 3 mois.`
9. **Enregistrer** en haut à droite.
10. **Répète les étapes 3 à 9** pour les 4 autres produits :
    | ID de produit (minuscules) | Prix cible | Nom affiché |
    |---|---|---|
    | `civique_pass_1y` | 29,99 € | Pass Civique 1 an |
    | `integral_pass_7j` | 9,99 € | Pass Intégral 7 jours |
    | `integral_pass_1m` | 19,99 € | Pass Intégral 1 mois |
    | `integral_pass_2m` | 29,99 € | Pass Intégral 2 mois |
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
   | `integral_pass_7j` | 9,99 € | Pass Intégral 7 jours |
   | `integral_pass_1m` | 19,99 € | Pass Intégral 1 mois |
   | `integral_pass_2m` | 29,99 € | Pass Intégral 2 mois |
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

## 4. SKU en base

Convention : `apple_product_id = google_product_id = lower(code)` (même ID store
sur les deux plateformes).

- Posés **automatiquement dans tous les environnements** (dev / test / prod) par
  la migration `db/migration/10_reference/V422__pass_store_product_ids.sql`. Il
  suffit que les produits stores aient été créés avec ces IDs exacts.
- Pour un ID store qui diverge de `lower(code)` : console **admin → Plans**, ou
  SQL ponctuel :

  ```sql
  UPDATE plans SET apple_product_id = '<id>', google_product_id = '<id>'
  WHERE code = '<PLAN_CODE>';
  ```

Vérification :

```sql
SELECT code, apple_product_id, google_product_id
FROM plans
WHERE purchase_type = 'ONE_TIME';
```

`stripe_price_id` reste **NULL** pour les passes (montant dynamique).

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
