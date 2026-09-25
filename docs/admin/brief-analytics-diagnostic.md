# Brief Claude Code — Analytics du tunnel Diagnostic (TCF / Civique)

## 0. Objectif

Mesurer le tunnel **Sujet vu → Soumis → Compte rattaché → Rapport vu → Plan vu → Débloquer → Achat** :
- ventilé par **Tous / TCF / Civique** et par **Web / iOS / Android** ;
- filtrable par **source d'acquisition** (instagram, tiktok, facebook…) ;
- avec le **CA brut et net réellement encaissé**, remboursements déduits.

Hors périmètre de ce brief : visites du site/blog (Plausible), usage du plan vs révision libre, activité des acheteurs. Ils feront l'objet d'un brief suivant.

---

## 1. Règles de travail

1. **Audit d'abord** (Phase 0) : aucun code avant le rapport d'audit et la validation au STOP 0.
2. **STOP** = s'arrêter, présenter le résultat, attendre mon « go ».
3. Les noms de tables, colonnes et endpoints de ce brief sont **indicatifs**. Adapte-les aux conventions existantes du monorepo, identifiées pendant l'audit.
4. Toute constante (fenêtres, taux, frais, rétention) va dans un **JSON versionné** (§8). Rien en dur.
5. Migrations **Flyway**, en suivant la numérotation et les conventions UUID existantes.
6. Montants stockés en **centimes (entiers)**, arrondi `HALF_UP`, devise `EUR`.
7. Fuseau de référence pour toutes les périodes : **Europe/Paris**.

---

## 2. Décisions actées

| Sujet | Décision |
|---|---|
| Stockage | **Hybride**. Les tables métier (`users`, `attempts`, `purchases`, `refunds`) sont la source de vérité des faits : soumission, inscription, achat, CA. La table `analytics_event` ne sert qu'aux comportements : vues, clics, UTM. **Le CA ne se calcule jamais depuis `analytics_event`.** |
| Tunnel | **Cohorte** de 14 jours (configurable). Un achat du 7/09 issu d'un diagnostic du 3/09 appartient à la cohorte du 3/09. Les compteurs « du jour » (achats, CA, inscriptions) sont affichés à part, en logique **période**. |
| Montants | Détaillés et stockés : `gross_paid`, `vat_amount`, `provider_fee`, `net_after_fee`, `net_ex_vat` (§6). |
| Colonne « Tous » | Personne unique. Ahmed fait TCF + Civique : Tous = 1, TCF = 1, Civique = 1. |
| Diagnostic refait | Le tunnel compte **la 1ʳᵉ tentative par type**. Toutes les tentatives restent en base. |
| Achats | **Achat unique**, pas d'abonnement ni de renouvellement. |
| Comptage | **Personnes uniques** dans le dashboard. Les événements bruts sont conservés. |
| Données internes | Les comptes internes et de test (`is_internal`) sont exclus par défaut. |

---

## 3. Identité et rattachement

### 3.1 `anonymous_id`
- **Web** : UUID v4 dans un cookie first-party, durée de vie issue de la config (13 mois par défaut).
- **Mobile** : UUID v4 généré au 1er lancement et persisté localement. Il survit aux connexions et déconnexions.
- Il est envoyé sur **tous** les appels API (header `X-Anonymous-Id`), avec `X-Platform` (`WEB|IOS|ANDROID`) et `X-App-Version`.

### 3.2 Liaison anonyme → compte
Table `analytics_identity(anonymous_id PK, user_id NULL, linked_at, first_touch_*)`. La relation est N `anonymous_id` → 1 `user_id`.
- À l'inscription **et** à la connexion : `user_id` est renseigné sur l'`anonymous_id` courant.
- **Clé personne** (utilisée pour tous les comptages) : `person_key = COALESCE(user_id lié, anonymous_id)`.

### 3.3 Rattachement d'un diagnostic anonyme (« claim »)
Une tentative soumise anonymement stocke son `anonymous_id` et un **`claim_token`**. Le token est aléatoire (≥ 128 bits), seul son hash est stocké, et il expire selon la config (30 j par défaut).

| Cas | Mécanisme | Résultat |
|---|---|---|
| Même appareil | À l'inscription ou la connexion, le serveur claim les tentatives soumises non rattachées ayant le même `anonymous_id`. | Rattaché |
| Web → app installée | La page résultat web propose « Continuer sur l'application ». Un universal / app link porte le `claim_token`, et l'app le transmet à l'inscription. | Rattaché |
| Web → app non installée | Le deferred deep link est **hors MVP**. | Non rattaché, compté `OUTSIDE_DIAGNOSTIC` |

Un compteur « **soumis anonymes jamais rattachés** » permet de mesurer l'ampleur du trou cross-device.

### 3.4 Contexte d'inscription (déterminé côté serveur uniquement)
Colonnes ajoutées sur `users` : `signup_platform`, `signup_context`, `signup_diagnostic_type`, `signup_diagnostic_attempt_id`, `signup_anonymous_id`, `is_internal`.

- `signup_context = AFTER_DIAGNOSTIC` si l'inscription claim ≥ 1 tentative de diagnostic soumise. `signup_diagnostic_type` prend alors le type de la tentative claimée la plus récente.
- Sinon, `signup_context = OUTSIDE_DIAGNOSTIC`.
- Un compte **existant** qui se connecte après un diagnostic anonyme donne un claim, mais pas d'inscription. Il apparaît dans le sous-type « connecté après diagnostic » (§7.2).

### 3.5 Acquisition (first-touch)
Au premier hit d'un `anonymous_id`, on enregistre dans `analytics_identity` : `utm_source`, `utm_medium`, `utm_campaign`, `landing_path`, `referrer_domain`.
- Ces valeurs ne sont **jamais écrasées**.
- Au lien avec un user, le user hérite du first-touch le plus ancien parmi ses `anonymous_id`.
- `utm_source` est normalisé en minuscules. Les valeurs sont regroupées via la config : instagram, tiktok, facebook, direct, autre.

---

## 4. Tables

### 4.1 `analytics_event` (comportements uniquement)

| Colonne | Type | Note |
|---|---|---|
| `event_id` | UUID PK | Généré **côté client**. Sert à la déduplication : `ON CONFLICT DO NOTHING`. |
| `event_name` | text | Allowlist du §5 |
| `occurred_at` | timestamptz | Horodatage client |
| `received_at` | timestamptz | Horodatage serveur |
| `anonymous_id` | UUID | Obligatoire |
| `user_id` | UUID NULL | |
| `platform` | text | WEB / IOS / ANDROID |
| `app_version` | text NULL | |
| `diagnostic_type` | text NULL | TCF / CIVIQUE |
| `diagnostic_attempt_id` | UUID NULL | |
| `plan_id` | UUID NULL | |
| `properties` | jsonb | Validé par un schéma propre à chaque événement |
| `is_internal` | boolean | Résolu à l'ingestion |

Index : `(event_name, occurred_at)`, `(diagnostic_attempt_id)`, `(anonymous_id)`, `(user_id)`.

Horodatage de référence pour les KPI : `occurred_at`. Si `occurred_at` est postérieur à `received_at` + tolérance de config, on prend `received_at` (horloge client fausse).

### 4.2 Tables métier (à compléter si manquant, à vérifier à l'audit)

- **`attempts`** (diagnostic) : `anonymous_id`, `user_id NULL`, `diagnostic_type`, `is_diagnostic`, `started_at`, `submitted_at`, `submitted_authenticated` (bool), `claim_token_hash`, `claim_token_expires_at`, `claimed_at`, `claimed_via` (`SAME_DEVICE|TOKEN`), `platform`.
  - La tentative doit être **créée côté serveur au démarrage**, y compris en anonyme, pour disposer d'un `diagnostic_attempt_id` dès la vue du sujet. À confirmer à l'audit.
- **`purchases`** : `id`, `user_id`, `platform`, `payment_provider` (`STRIPE|APPLE|GOOGLE`), `provider_transaction_id` **UNIQUE**, `product_id`, `currency`, `gross_paid`, `vat_amount`, `provider_fee`, `net_after_fee`, `net_ex_vat`, `fee_source` (`ACTUAL|ESTIMATED`), `revenue_rules_version`, `origin` (`DIAGNOSTIC_PLAN|OTHER`), `diagnostic_type NULL`, `diagnostic_attempt_id NULL`, `plan_id NULL`, `purchased_at`.
- **`refunds`** : `id`, `purchase_id`, `provider_refund_id` **UNIQUE**, `refunded_gross`, `net_ex_vat_delta` (négatif), `refunded_at`.

---

## 5. Événements

Les faits métier ne passent **pas** par `analytics_event`. Ils sont lus dans les tables métier.

| Événement | Source | Déclencheur exact | Propriétés spécifiques |
|---|---|---|---|
| `diagnostic_subject_viewed` | Client → `analytics_event` | Affichage de la **1ʳᵉ question** du diagnostic. La page de présentation ne compte pas. | `diagnostic_type`, `diagnostic_attempt_id` |
| *Diagnostic soumis* | `attempts.submitted_at` | Soumission acceptée par le serveur | — |
| *Inscription* | `users.created_at` + colonnes signup | Création du compte | — |
| `diagnostic_report_viewed` | Client → `analytics_event` | Rapport affiché avec ses données | `diagnostic_type`, `diagnostic_attempt_id` |
| `diagnostic_plan_viewed` | Client → `analytics_event` | Plan affiché | `diagnostic_type`, `diagnostic_attempt_id`, `plan_id` |
| `plan_unlock_clicked` | Client → `analytics_event` | Tap sur « Débloquer mon plan » | `diagnostic_type`, `diagnostic_attempt_id`, `plan_id`, `product_id`, `displayed_price` |
| *Achat* | `purchases` | **Webhook uniquement** : Stripe `checkout.session.completed`, Apple App Store Server Notifications v2, Google RTDN (+ validation). Idempotent sur `provider_transaction_id`. | — |
| *Remboursement* | `refunds` | Webhook Stripe `charge.refunded`, Apple `REFUND`, Google voided purchases | — |

### Attribution de l'achat au diagnostic
Le `diagnostic_attempt_id` et le `plan_id` sont transmis au checkout, puis relus dans le webhook :
- **Stripe** : `metadata` de la Checkout Session ;
- **Apple** : `appAccountToken`, ou une table d'intention côté serveur si le champ ne suffit pas ;
- **Google** : `obfuscatedProfileId` ou `obfuscatedAccountId` + intention côté serveur.

`origin = DIAGNOSTIC_PLAN` si un `diagnostic_attempt_id` est retrouvé, sinon `OTHER`. Le mécanisme exact par store est à proposer à l'audit.

---

## 6. Montants

### 6.1 Définitions

| Champ | Sens |
|---|---|
| `gross_paid` | TTC payé par le client |
| `vat_amount` | TVA incluse (`gross − HT`, avec `HT = round(gross / (1 + taux))`) |
| `provider_fee` | Frais ou commission du provider |
| `net_after_fee` | Montant qui arrive réellement sur le compte bancaire |
| `net_ex_vat` | Revenu réel HT après frais (**KPI principal du dashboard**) |

**Invariant (assert dans le code et dans les tests)** : `gross_paid = vat_amount + provider_fee + net_ex_vat`.

### 6.2 Règles (`revenue-rules.v1.json`)

**Stripe**
- `provider_fee` : frais **réel** lu depuis la `balance_transaction` quand il est disponible (`fee_source = ACTUAL`). Sinon, formule de config `1,5 % × gross + 0,25 €` (`ESTIMATED`).
- `net_after_fee = gross − provider_fee`
- `net_ex_vat = HT − provider_fee`

**Apple / Google**
- La commission s'applique sur le HT. Le store reverse la TVA lui-même.
- `provider_fee` : calculé selon `store_commission.mode` (voir le point à confirmer ci-dessous).
- `net_after_fee = net_ex_vat = HT − provider_fee`
- `fee_source = ESTIMATED`. Un rapprochement avec les rapports des stores est hors MVP.

**Taux de TVA** : 20 % (FR) pour le MVP, en config.

⚠️ **À confirmer au STOP 0, `store_commission.mode`** :
- `MULTIPLY` : `net = HT × (1 − 0,15)`, soit une commission réelle de 15 % ;
- `DIVIDE` : `net = HT / 1,15`, la formule d'origine, qui sous-estime la commission.

### 6.3 Exemples de référence (tests)

| Provider | gross | HT | vat | fee | net_after_fee | net_ex_vat |
|---|---:|---:|---:|---:|---:|---:|
| Stripe (formule) | 9,99 | 8,33 | 1,66 | 0,40 | 9,59 | 7,93 |
| Apple/Google `MULTIPLY` | 9,99 | 8,33 | 1,66 | 1,25 | 7,08 | 7,08 |
| Apple/Google `DIVIDE` | 9,99 | 8,33 | 1,66 | 1,09 | 7,24 | 7,24 |

### 6.4 Remboursements
- **Stripe** : Stripe conserve ses frais, donc `net_ex_vat_delta = −HT`. Le net final de l'achat est `−provider_fee`.
- **Stores** : `net_ex_vat_delta = −net_ex_vat`.
- Le dashboard affiche le **net après remboursements** et le nombre de remboursements.

---

## 7. KPI et règles de comptage

### 7.1 Filtres communs
- **Période** : Aujourd'hui / Hier / 7 jours / Mois en cours / Personnalisé. Bornes en Europe/Paris.
- **Type** : Tous / TCF / Civique.
- **Plateforme** : Toutes / Web / iOS / Android. C'est la plateforme de l'étape 1 pour le tunnel, et celle de l'événement pour l'activité.
- **Source** : Toutes / instagram / tiktok / facebook / direct / autre (first-touch).
- `is_internal` est exclu, avec un toggle admin pour l'inclure.

### 7.2 Section A — Tunnel (cohorte)

**Entrée en cohorte** : une personne (`person_key`) entre dans la cohorte d'un type à la date de son **1er** `diagnostic_subject_viewed` de ce type, si cette date tombe dans la période. La tentative de référence est la **1ʳᵉ tentative** de ce type.

Chaque étape est comptée si elle est atteinte **dans la fenêtre** (`cohort_window_days` à partir de l'entrée) **et** si l'étape précédente est atteinte. Le tunnel est séquentiel, donc aucun pourcentage ne peut dépasser 100 %.

| # | Étape | Condition (sur la tentative de référence) |
|---|---|---|
| 1 | Sujet vu | Entrée en cohorte |
| 2 | Diagnostic soumis | `submitted_at` dans la fenêtre |
| 3 | Compte rattaché | `user_id` non nul (soumis connecté, ou claim dans la fenêtre) |
|   | ↳ déjà connecté | `submitted_authenticated = true` |
|   | ↳ inscrit après diagnostic | claim lors d'une inscription |
|   | ↳ connecté après diagnostic | claim lors d'une connexion à un compte existant |
| 4 | Rapport vu | ≥ 1 `diagnostic_report_viewed` sur la tentative |
| 5 | Plan vu | ≥ 1 `diagnostic_plan_viewed` sur la tentative |
| 6 | Débloquer cliqué | ≥ 1 `plan_unlock_clicked` sur la tentative |
| 7 | Achat | `purchases.diagnostic_attempt_id` = tentative, dans la fenêtre |

Affichage :
- pour chaque étape, le nombre et le **% depuis l'étape précédente** ;
- sous l'étape 7, le **CA net cohorte** (`net_ex_vat` après remboursements) ;
- le tableau présente les 3 colonnes Tous / TCF / Civique.

**Colonne « Tous »** : on compte les personnes distinctes ayant atteint l'étape dans au moins un type. Tous ≤ TCF + Civique.

Une cohorte récente dont la fenêtre n'est pas encore écoulée est marquée « en cours ».

### 7.3 Section B — Activité (période, sans cohorte)

| KPI | Source et règle |
|---|---|
| Diagnostics soumis | `attempts` soumis dans la période, 1ʳᵉ tentative par personne et par type, + total brut |
| Inscriptions | `users.created_at` dans la période, ventilées par `signup_context` × `signup_diagnostic_type` × `signup_platform` |
| Achats | Nombre dans la période, par provider, plateforme et `origin` |
| CA | Somme de `gross_paid`, `net_after_fee` et `net_ex_vat`, remboursements de la période déduits |
| Remboursements | Nombre et montant dans la période |
| Soumis anonymes jamais rattachés | Soumis anonymes de la période sans claim à J+14 |

### 7.4 Section C — Ratios (sur la cohorte, avec filtres identiques)

| Ratio | Formule |
|---|---|
| Sujet → soumission | étape 2 / étape 1 |
| Diagnostic → inscription | inscrits après diagnostic / soumis **anonymes**. Les « déjà connecté » sont exclus du numérateur et du dénominateur. |
| Rapport consulté | étape 4 / étape 3 |
| Plan consulté | étape 5 / étape 4 |
| Intention d'achat | étape 6 / étape 5 |
| Conversion clic | étape 7 / étape 6 |
| Conversion globale | étape 7 / étape 2 |
| Net par diagnostic soumis | CA net cohorte / étape 2 |

---

## 8. Configuration versionnée

**`analytics-config.v1.json`**
```json
{
  "version": 1,
  "timezone": "Europe/Paris",
  "cohort_window_days": 14,
  "claim_token_ttl_days": 30,
  "anonymous_cookie_ttl_days": 395,
  "raw_event_retention_days": 760,
  "clock_skew_tolerance_minutes": 10,
  "ingest_max_batch_size": 50,
  "utm_source_groups": {
    "instagram": ["instagram", "ig"],
    "tiktok": ["tiktok", "tt"],
    "facebook": ["facebook", "fb", "meta"]
  }
}
```

**`revenue-rules.v1.json`**
```json
{
  "version": 1,
  "currency": "EUR",
  "vat_rate": 0.20,
  "rounding": "HALF_UP",
  "stripe": { "percent_fee": 0.015, "fixed_fee_cents": 25, "prefer_actual_fee": true },
  "store_commission": { "rate": 0.15, "mode": "A_CONFIRMER_MULTIPLY_OU_DIVIDE" }
}
```

Chaque achat stocke la `revenue_rules_version` appliquée. Un changement de règle n'a donc aucun effet rétroactif.

---

## 9. API (contrats indicatifs)

- `POST /api/analytics/events`
  - Accepte un lot d'événements, accessible en anonyme.
  - Allowlist des noms d'événements + validation du schéma de chaque événement.
  - Idempotent sur `event_id`, rate-limit par `anonymous_id` et par IP.
  - Réponse `202`. Les événements invalides sont rejetés individuellement, sans faire échouer le lot.
- `GET /api/admin/analytics/diagnostic/funnel?preset|from&to&type&platform&source&includeInternal`
- `GET /api/admin/analytics/diagnostic/activity?...`
- `GET /api/admin/analytics/diagnostic/ratios?...`

Tous les endpoints admin sont réservés au rôle admin. MVP : calcul SQL à la volée. Une vue matérialisée est à proposer seulement si les temps de réponse dépassent 1 s sur un jeu de test réaliste.

---

## 10. Clients

- **Web** :
  - SDK léger `track(eventName, props)` ;
  - buffer mémoire, envoi par lots et au `visibilitychange` / `pagehide` (`sendBeacon`) ;
  - capture UTM et referrer au 1er hit.
- **Mobile (Flutter, offline-first)** :
  - file persistante locale des événements (Drift) ;
  - flush au retour réseau, à la reprise de l'app et périodiquement ;
  - retry avec backoff ; purge seulement après `202`.
  - Le `event_id` est généré à la création de l'événement, pas à l'envoi.
- **Admin** : écran « Analytics diagnostic » avec les filtres §7.1 et les sections A, B, C. Présentation libre, cohérente avec l'admin existant.

---

## 11. RGPD

- Mentionner dans la politique de confidentialité la mesure first-party et le rattachement du parcours anonyme au compte.
- Aucune donnée personnelle dans `properties` : pas d'email, pas de réponses aux questions.
- Rétention des événements bruts pilotée par la config, via un job de purge.

---

## 12. Scénarios d'acceptation (tests d'intégration)

1. Jean ouvre son rapport 7 fois → Rapport vu = **1**.
2. Ahmed fait TCF + Civique → Tous = 1, TCF = 1, Civique = 1 à chaque étape atteinte.
3. Diagnostic anonyme sur web, puis inscription sur le même navigateur → `AFTER_DIAGNOSTIC`, compté dans « inscrit après diagnostic ».
4. Diagnostic anonyme sur web, puis app installée via le lien avec `claim_token` → rattaché, `claimed_via = TOKEN`.
5. Même cas sans token → non rattaché, inscription `OUTSIDE_DIAGNOSTIC`, compté dans « soumis anonymes jamais rattachés ».
6. Utilisateur déjà connecté qui fait le diagnostic → « déjà connecté », absent du ratio diagnostic → inscription.
7. Compte existant déconnecté, diagnostic, puis connexion → « connecté après diagnostic », pas d'inscription.
8. Diagnostic vu le 3/09, achat le 7/09 → achat dans la cohorte du 3/09, et dans l'activité du 7/09.
9. Achat à J+15 → hors tunnel de la cohorte, mais présent dans l'activité et le CA.
10. Même lot d'événements mobile envoyé 2 fois → aucun doublon.
11. Webhook d'achat reçu 2 fois → 1 seul achat.
12. Montants §6.3 exacts au centime, et invariant respecté.
13. Remboursement Stripe → net de l'achat = −0,40 € ; remboursement store → net = 0.
14. Événement à 23h30 UTC le 3/09 (heure d'été) → compté le **4/09**.
15. Compte `is_internal` → exclu par défaut, visible avec le toggle.
16. Diagnostic TCF refait 3 fois → 1 personne dans le tunnel, 3 soumissions en brut.
17. Arrivée via `/reussir?utm_source=IG` puis achat → attribué à instagram dans le tunnel filtré.

---

## 13. Phases et STOP

### Phase 0 — Audit (aucun code)
Rapporter :
- les tables existantes : users, attempts ou diagnostic, plans, purchases, refunds ; les champs présents et manquants par rapport au §4 ;
- le parcours diagnostic anonyme actuel : où la tentative est créée, comment elle est liée au user, où la soumission est persistée ;
- les webhooks de paiement existants (Stripe, Apple, Google), leur idempotence, et ce qu'ils permettent de transporter pour l'attribution (§5) ;
- l'identité : présence éventuelle d'un id anonyme web ou mobile, les headers existants ;
- l'instrumentation existante (Plausible, etc.) et la façon de capter les UTM ;
- l'écran admin existant et le système de rôles ;
- les écarts, risques et la proposition de découpage adapté au repo.

**🛑 STOP 0** — rapport d'audit + décision sur `store_commission.mode`.

### Phase 1 — Fondations
Migrations, fichiers de config, `analytics_identity`, `analytics_event`, endpoint d'ingestion, headers d'identité, liaison anonyme → user à l'inscription et à la connexion.

**🛑 STOP 1** — migrations et tests de l'ingestion (dédup, allowlist, rejet partiel).

### Phase 2 — Enrichissement métier
- claim des tentatives (même appareil + token) ;
- `signup_context` ;
- montants §6 dans les webhooks ;
- remboursements ;
- attribution `origin` et `diagnostic_attempt_id`.

**🛑 STOP 2** — tests des scénarios 3 à 7 et 11 à 13.

### Phase 3 — Instrumentation clients
SDK web, file Drift mobile, 4 événements client, lien « Continuer sur l'application ».

**🛑 STOP 3** — démonstration des événements reçus depuis web, iOS et Android.

### Phase 4 — KPI et dashboard
Requêtes des sections A, B, C, endpoints admin, écran admin, jeu de données de test couvrant les 17 scénarios.

**🛑 STOP 4** — tous les scénarios au vert + captures des valeurs calculées.
