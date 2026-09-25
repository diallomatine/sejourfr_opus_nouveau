# Chantier « Suivi » — journal des décisions

Chantier : remplacer `/dashboard` de l'admin par le dashboard « Suivi »
(`docs/admin/sejourfr-suivi-dashboard.html`), selon `docs/admin/brief-analytics-diagnostic.md`
et l'audit `docs/admin/audit-dashboard-analytics.md`.

**Principe directeur (propriétaire)** : un chiffre inconnu vaut mieux qu'un chiffre faux. Pas
d'attribution devinée, pas de backfill, `null` = inconnu (jamais 0). Pas de seconde vérité,
on étend l'existant.

**Mode d'exécution** : autonome, lots 1a → 4 puis 3b, sans STOP ; build + tests au vert et un
commit par lot. Toute décision prise en cours de route est consignée ci-dessous (§2), au fil
de l'eau, avec : contexte, options, choix et motif, fichiers impactés, difficulté de retour.

---

## 1. Arbitrages du propriétaire au STOP 0 (2026-09-25)

**Q1 — TVA.** `seller_vat_regime = FRANCHISE_293B`, en config versionnée.
- Stripe : `vat = 0` ; `net_ex_vat = net_after_fee = gross − fee`. Frais réel via
  `balance_transaction` en priorité, formule en repli (`fee_source = ESTIMATED`).
- Apple/Google : TVA retenue par le store (20 % FR, en config). Commission **MULTIPLY**, taux
  **par store** ; le propriétaire fournit les taux (0,15 ou 0,30) avant le lot 2.
- Exemples de test : Stripe 9,99 → vat 0, fee 0,40, net 9,59. Store 15 % → net 7,08.
  Store 30 % → net 5,83.

**Q2 — Tunnel TCF = `QUICK_TCF` uniquement.** Scénario 16 testé sur le civique.

**Q3 — `diagnostic_run` : OUI.** Trace du parcours uniquement, aucun contenu candidat.
- Run créée par un appel public dédié, idempotent, à l'affichage du sujet. L'étape 1 se compte
  **uniquement** sur `diagnostic_run` ; pas d'événement `DIAGNOSTIC_SUBJECT_VIEWED` en doublon.
- « Soumis » : une seule fois par run, la run doit exister, appel rate-limité.
- FK vers les sessions en `ON DELETE SET NULL`. `GuestAttemptPurgeJob` ne touche jamais
  `diagnostic_run`.

**Claim diagnostic.**
- À la création de la run, le serveur retourne `diagnosticRunId` + `claimToken` (aléatoire,
  forte entropie). Seul `claim_token_hash` est stocké.
- Le client conserve le `claimToken` avec le brouillon du diagnostic (IndexedDB /
  SharedPreferences). Il ne part **jamais** dans les événements analytics.
- Register / Login / Google / Apple transmettent `diagnosticRunId` + `claimToken`. Claim dans la
  transaction d'auth, `claim_kind = SIGNUP | LOGIN`, `signup_context` posé au même moment.
- Aucune recherche heuristique par `anonymous_id`. Le runId est un identifiant, pas un secret.
- Compte ayant déjà son diagnostic : la run est quand même claimée ; le contenu est refusé
  comme aujourd'hui.
- Ce même `claimToken` sert au lien web → app du lot 3b.

**Q4 — En-têtes** : `X-Sejourfr-Anonymous-Id`, `X-Sejourfr-Client` (`web|ios|android`),
`X-Sejourfr-App-Version`.

**Q5 — Rétention 395 j**, purge au lot 1b. Justification corrigée : 13 mois = durée de vie du
**traceur**, pas une limite CNIL générale sur les données. `/confidentialite` mise à jour dans
la même passe. Vérification RGPD du rattachement visiteur → compte : côté propriétaire, non
bloquante.

**Q6 — `users.is_internal` : OUI, seule autorité.** Initialisé depuis `excluded-emails`, puis la
liste YAML est supprimée.

**Q7 — Visiteurs uniques et sources : inclus.** « Utilisation du plan » reporté au brief suivant,
**sans proxy ni bloc « bientôt »**.

**Q8 — `plan_id = journey.id`.** Le serveur résout journey → `diagnostic_run` fondateur
lui-même, sans faire confiance au runId envoyé par le client.

**Q9 — Suppression de l'ancien dashboard acceptée.** Données déjà collectées conservées si elles
ne coûtent rien.

**Q10 — Supprimer le code sans appelant, garder les tables.**

**Q11 — Bugs paiement : OUI, au lot 2, avant les KPI de revenu.**
- `rawPrice` / `amountCents` ;
- anti-rejeu Stripe ;
- remboursement partiel ;
- `payment_status` ;
- prix Apple lu depuis le JWS ; prix Google borné par le catalogue.

**Q12 — Purchase intent, pas d'attribution automatique à la run la plus récente.**
- Une `purchase_intent` serveur est créée avant **chaque** démarrage d'achat, quel que soit le
  CTA : `user_id`, `cta_location`, `product_id`, `journey_id`, `diagnostic_run_id` (résolu
  serveur), `created_at`, `consumed_at`. TTL 24 h en config, usage unique.
- Transport : Stripe `metadata.intentId`. Apple/Google : **ne pas détourner**
  `appAccountToken` / `obfuscatedAccountId` / `obfuscatedProfileId` (identité du compte). Le
  mobile persiste le `purchaseIntentId` (indexé par `productId`) avant d'ouvrir le paiement,
  l'envoie avec verify-receipt, et le réutilise si l'achat est rejoué au lancement suivant.
- Vérification backend : appartient au user, même produit, non expirée, non consommée.
- Intention perdue / expirée / invalide : `origin = UNKNOWN`, `diagnostic_run_id = null`.
  Aucune reconstruction heuristique.
- `origin = DIAGNOSTIC_PLAN | OTHER_CTA | UNKNOWN`. Obligatoire au lot 2.

**Q13 — Template avec filtre Tous / TCF / Civique**, pas de tableau 3 colonnes. Les 3 sous-lignes
de « Compte rattaché », ratios en bloc secondaire, activité en dessous.

**Q14 — Lien web → app : lot 3b séparé, non bloquant.**

**Q15 — File mobile SharedPreferences bornée**, validé.

**Q16 — Aucun backfill.** La réponse indique la **date de début de mesure** de chaque indicateur ;
avant cette date, l'indicateur vaut `null`.

**Q17 — Ingestion en lot : OUI.** L'unitaire est conservé pendant la bascule, puis retiré.

**Scénarios ajoutés au brief §12.**
- **18** : achat sans intention → `UNKNOWN`, hors tunnel. Achat via un autre CTA → `OTHER_CTA`.
  Intention déjà consommée, expirée ou d'un autre user → rejetée → `UNKNOWN`.
- **19** : après la purge des invités, les runs et le compteur « jamais rattachés » sont intacts.
- **20** : claim avec un runId valide mais un `claimToken` absent ou faux → pas de claim.

**Template.** Respecter au maximum `docs/admin/sejourfr-suivi-dashboard.html` (mise en page,
ordre et contenu des blocs, densité, libellés, comportement des filtres). Seuls écarts autorisés,
chacun noté ci-dessous : les ajouts décidés (3 sous-lignes, bloc ratios, bloc activité,
remboursements) ; « Apple » → « iOS » ; couleurs et typographies de la charte admin.

---

## 2. Décisions prises en autonomie pendant l'exécution

Format : **Dn — titre** · Lot · Contexte · Options · Choix et motif · Fichiers · Difficulté de
retour (faible / moyenne / forte).

<!-- Les agents ajoutent leurs décisions ici, dans l'ordre. -->

**D1 — `diagnostic_run` : forme de la table** · Lot 1b
- Contexte : Q3 fixe la table, pas ses colonnes ni l'idempotence de création.
- Options : id tiré par le client (audit §8.0) ; id serveur + clé d'idempotence client.
- Choix et motif : id **serveur** (Q3 : « le serveur retourne `diagnosticRunId` + `claimToken` »)
  et `client_key uuid` unique **par `anonymous_id`** (même doctrine que `clientSubmissionId`,
  V046 : une clé d'un client ne résout jamais vers la run d'un tiers). Étape 1 =
  `subject_viewed_at` (horloge serveur). `claimed_via` ∈ `SAME_DEVICE | APP_LINK` (le claim se
  fait toujours par jeton, aucune heuristique ; `APP_LINK` = lot 3b). `FULL_TCF` admis au
  type pour l'activité (Q2 : le tunnel ne lit que `QUICK_TCF`). **Aucune FK vers
  `analytics_visitor`** (la purge 395 j ne doit pas emporter un fait du tunnel) ; FK sessions
  en `SET NULL` (scénario 19, testé). CHECK de cohérence par paires (soumis, jeton, claim).
- Fichiers : `V074__schema_suivi_tunnel_diagnostic.sql`, `entity/DiagnosticRun`,
  `manager/DiagnosticRunManager`, `SuiviSchemaV074IT`.
- Difficulté de retour : moyenne (V075 pour changer une colonne ; aucune donnée tant que le
  lot 2 n'écrit pas).

**D2 — Revenu : pas de colonne « gross », invariant tenu par la base** · Lot 1b
- Contexte : le brief liste `gross_paid` ; `user_subscriptions.amount_eur_cents` (V043) est
  déjà le brut encaissé en euros, via l'autorité `MontantEncaisse`.
- Options : colonne `gross_cents` en plus ; réutiliser `amount_eur_cents`.
- Choix et motif : **réutiliser** (une règle = une autorité). Colonnes ajoutées :
  `vat_cents`, `provider_fee_cents`, `net_after_fee_cents`, `net_ex_vat_cents`, `fee_source`,
  `revenue_rules_version` (tout ou rien, CHECK), `purchased_at`, `origin`, `diagnostic_run_id`,
  `journey_id`, `purchase_intent_id`, `payment_status` (sans CHECK : l'enum Java du lot 2 fait
  autorité). CHECK `amount_eur_cents = vat + fee + net_ex_vat` : l'invariant §6.1 est
  **opposable par la base**, pas seulement par le code. `net_after_fee` non contraint (il vaut
  `gross − fee` chez Stripe, `net_ex_vat` chez les stores). `payment_refunds` : unicité
  `(provider, provider_refund_id)` (plus juste qu'un `provider_refund_id` unique global),
  partiels multiples permis, `net_ex_vat_delta_cents <= 0`.
- Fichiers : V074, `SuiviSchemaV074IT`.
- Difficulté de retour : moyenne (V075).

**D3 — `is_internal` : initialisation en migration + seed dev** · Lot 1b
- Contexte : Q6, initialiser depuis `excluded-emails` puis supprimer la liste.
- Options : au démarrage (Java) ; dans la migration.
- Choix et motif : **dans V074** (après une sentinelle, rejouée par `SuiviSchemaV074IT`) pour
  les bases qui ont déjà les comptes, et `migration-dev/V901` car sur une base dev neuve V900
  crée les comptes **après** V074. Liste initialisée = la valeur par défaut du YAML (3 comptes
  seed). ⚠️ **Action propriétaire** : si la prod surchargeait `ANALYTICS_EXCLUDED_EMAILS`,
  appliquer `UPDATE users SET is_internal = true WHERE lower(email) IN (…)` avec cette liste ;
  la variable n'est plus lue. Pas d'écran d'édition dans ce lot (SQL).
- Fichiers : V074, `db/migration-dev/V901__seed_dev_comptes_internes.sql`, `User`,
  `AnalyticsProperties`, `application.yaml`, `AnalyticsReadRepository/Manager`,
  `AdminAnalyticsService`, `AdminAnalyticsServiceIT`.
- Difficulté de retour : faible.

**D4 — `event_id` à côté de `dedup_key`** · Lot 1b
- Contexte : l'audit proposait de mettre l'`event_id` client dans `dedup_key`.
- Options : réutiliser `dedup_key` ; colonne `event_id uuid` unique.
- Choix et motif : **colonne `event_id`** (idempotence de *transport*, obligatoire en lot) ;
  `dedup_key` reste l'idempotence *métier* facultative. Insertion `ON CONFLICT DO NOTHING`
  **sans cible** : l'une ou l'autre contrainte écarte un rejeu.
- Fichiers : V074, `AnalyticsEventRepository`, `AnalyticsEventManager`.
- Difficulté de retour : faible.

**D5 — Endpoint en lot : chemin, contrôleur, contrat** · Lot 1b
- Contexte : Q17 ; lot 1a édite la Javadoc de `PublicAnalyticsController` en parallèle.
- Options : même URL en surcharge ; `/events/batch` dans le même contrôleur ; nouveau contrôleur.
- Choix et motif : `POST /api/public/analytics/events/batch` dans
  **`PublicAnalyticsBatchController`** (zéro collision avec 1a ; le contrôleur unitaire
  disparaîtra après la bascule). Enveloppe invalide (ids manquants, > `maxBatchSize`,
  attribution hors allowlist) → 400 ; chaque événement reçu **en texte** (UUID, nom, date) pour
  qu'un champ mal formé rejette l'événement et pas le lot ; 202 + `{received, accepted,
  duplicates, rejected[]}`. Le client purge tout sauf 400/429/5xx (un rejet renvoyé serait
  rejeté de nouveau). Le compte appelant est résolu dans le service depuis le principal JWT.
- Fichiers : `controller/PublicAnalyticsBatchController`, `dto/AnalyticsBatch*`,
  `service/analytics/AnalyticsBatchIngestionService`, `PublicAnalyticsBatchControllerIT`.
- Difficulté de retour : faible avant le lot 3, moyenne après (contrat client).

**D6 — Horloge du lot** · Lot 1b
- Contexte : brief §4.1 (futur > tolérance ⇒ `received_at`) ; l'unitaire refuse à ± 24 h ; la
  file mobile hors ligne peut être vieille de plusieurs jours.
- Choix et motif : futur > `clockSkewToleranceMinutes` (10) ⇒ **remplacé** par l'heure de
  réception ; passé > `maxEventAgeHours` (168 h) ⇒ **rejet individuel** (sinon un endpoint
  public fabrique l'historique) ; absent ⇒ réception. L'unitaire garde ses ± 24 h.
- Fichiers : `AnalyticsBatchIngestionService`, `analytics-config-v1.json`.
- Difficulté de retour : faible (config).

**D7 — Contextes en colonnes, validés serveur** · Lot 1b
- Contexte : les étapes 4-6 joignent événement ⇄ run ⇄ parcours.
- Options : ids en propriétés jsonb ; colonnes libres ; colonnes FK validées.
- Choix et motif : colonnes `diagnostic_run_id`, `diagnostic_type`, `journey_id` avec FK
  `SET NULL` ; l'ingestion vérifie l'existence (une requête par nature, par lot) et **rejette**
  une run ou un parcours inconnu ; **le type de la run fait foi** (type client contradictoire
  rejeté). Admis par événement via `AnalyticsEvent.Contexte` (comme les propriétés). Pas de
  contrôle d'appartenance du parcours : un `sendBeacon` ne porte pas de JWT.
- Fichiers : `AnalyticsEvent`, `AnalyticsBatchIngestionService`, `JourneyManager/Repository`,
  `DiagnosticRunManager`, V074.
- Difficulté de retour : moyenne.

**D8 — Registre : enrichir plutôt que doubler** · Lot 1b
- Contexte : « rapport vu, plan vu, `PLAN_UNLOCK_CLICKED` ».
- Choix et motif : `DIAGNOSTIC_REPORT_VIEWED` (même nom que le brief) et `PLAN_OPENED`
  sont **enrichis** (contexte run / parcours) plutôt que doublés par un `DIAGNOSTIC_PLAN_VIEWED`
  (deux événements pour un écran = seconde vérité). **Nouveau** : `PLAN_UNLOCK_CLICKED`
  (`ctaLocation`, `planCode`, `displayedPriceCents` — nouvelle propriété bornée à 6 chiffres,
  jamais un montant encaissé). Pas de `DIAGNOSTIC_SUBJECT_VIEWED` (Q3, verrouillé par test).
  Chemins ajoutés : `/diagnostic-civique`, `/diagnostic-civique/resultat`, `/plan/debloquer`.
- Fichiers : `AnalyticsEvent`, `AnalyticsProperty`, `AnalyticsPaths`, `AnalyticsEventRegistryTest`.
- Difficulté de retour : faible.

**D9 — Rate-limit du lot hors `RateLimitGuard`** · Lot 1b
- Contexte : 1a est seul propriétaire de `RateLimitGuard`.
- Choix et motif : composant `ratelimit/AnalyticsBatchRateLimit` sur le même
  `InMemoryRateLimiter`, seuils dans `analytics-config` (IP 120 / 10 min et 3 000 / j ;
  `anonymousId` 60 / 10 min et 1 000 / j), **un lot = un appel** (la taille est bornée à part).
  Respecte l'interrupteur global `sejourfr.rate-limit.enabled`.
- Fichiers : `AnalyticsBatchRateLimit`, `AnalyticsBatchRateLimitTest`.
- Difficulté de retour : faible.

**D10 — Plateforme : iOS / Android, repli par le corps** · Lot 1b
- Contexte : Q4 ; un `sendBeacon` ne peut poser aucun en-tête.
- Choix et motif : `ClientPlatform` gagne `IOS`, `ANDROID` ; `mobile` reste accepté et lu
  `MOBILE` (jamais réparti). L'enveloppe du lot porte `client` / `appVersion`, utilisés
  **seulement si l'en-tête manque**. Un iOS/Android déclaré fixe `device_type` sans lire le
  user-agent. ⚠️ L'ancien écran `/dashboard` filtre `WEB/MOBILE` : les lignes iOS/Android n'y
  entrent pas dans le filtre « MOBILE » (écran supprimé au lot 4, aucun client n'envoie encore
  `ios/android`).
- Fichiers : `ClientPlatform`, `ClientContext`, `ClientContextResolver`, `DeviceTypeResolver`.
- Difficulté de retour : faible.

**D11 — Source déclarée brute (`ft_source_raw`)** · Lot 1b
- Contexte : scénario 17 (`ig` → instagram) ; `TrafficSource` range `ig` en « autre » à
  l'ingestion, perte irréversible.
- Options : alias dans `TrafficSource` (code) ; valeur brute + regroupement à la lecture.
- Choix et motif : `analytics_visitor.ft_source_raw` (minuscules, `[a-z0-9._-]`, 40 car.,
  jamais réécrite) + `AnalyticsConfig.groupOfSource` (lecture, réversible, versionné).
  `ft_source` inchangé. Lecture recommandée au lot 4 : `COALESCE(ft_source_raw, ft_source)`.
- Fichiers : V074, `AnalyticsEventNormalizer`, `AnalyticsVisitorRepository/Manager`,
  `AnalyticsConfig`.
- Difficulté de retour : faible.

**D12 — Dates de début de mesure (Q16)** · Lot 1b
- Choix et motif : `measurementStart` exige une entrée par `SuiviIndicator` ; `null` = pas
  encore mesuré. `VISITORS` et `ACQUISITION_SOURCES` = `2026-08-21` (date de V043 dans la
  doc) — ⚠️ **à confirmer par le propriétaire** contre la date réelle de mise en prod
  (`min(analytics_event.occurred_at)` en prod). Tous les indicateurs du tunnel et du revenu
  restent `null` : **chaque lot qui les met en service pose sa date** (lot 2 : run, soumis,
  rattaché, achats, origine, revenu, remboursements, contexte d'inscription ; lot 3 : rapport,
  plan, débloquer, plateforme iOS/Android).
- Fichiers : `analytics-config-v1.json`, `SuiviIndicator`, `AnalyticsConfig`.
- Difficulté de retour : faible.

**D13 — Règles de revenus v1** · Lot 1b
- Choix et motif : `seller.vatRegime = FRANCHISE_293B` (`vatRateIfLiable` 0,20 servira le
  jour d'un passage `ASSUJETTI`), `stores.vatRate` 0,20, `commissionMode` **MULTIPLY** seul
  admis (DIVIDE refusé au boot), taux par store **APPLE 0,15 / GOOGLE 0,15 — provisoires, à
  confirmer par le propriétaire avant le lot 2** (15 % = programmes petites entreprises sur
  inscription ; sinon 0,30), Stripe 1,5 % + 25 c, `preferActualFee`. Chargées au boot dès
  maintenant (échec au démarrage sur une règle fausse) ; consommées au lot 2.
- Fichiers : `billing/revenue-rules-v1.json`, `RevenueRules*`, `BillingProperties`.
- Difficulté de retour : faible (nouvelle version ; les achats figent la leur).

**D14 — Purge de rétention** · Lot 1b
- Choix et motif : quotidienne 04:10 Paris ; événements par `occurred_at` (date retenue), puis
  visiteurs par **dernière activité** (cascade sur `analytics_identity`), par lots de
  `purgeBatchSize`. `diagnostic_run.anonymous_id` et `users.signup_anonymous_id` ne sont pas
  touchés (pas de FK) — ⚠️ **au lot 2 de décider** si la run doit oublier son `anonymous_id`
  au-delà de 395 j (le lien ne pointe plus sur rien, mais reste un identifiant de traceur).
- Fichiers : `AnalyticsRetentionService`, `AnalyticsRetentionJob`, `AnalyticsRetentionServiceIT`.
- Difficulté de retour : faible.

**D15 — Liaison identité à l'auth et point d'extension** · Lot 1b
- Contexte : le champ `anonymousId` existait sur les 4 requêtes d'auth mais aucun front ne
  l'envoyait ; la provenance d'inscription vivait en 2 copies.
- Choix et motif : identifiant = corps s'il est lisible, **sinon l'en-tête**
  (`ClientContext.anonymousIdPreferring`) ; `AuthService.login` reçoit désormais le
  `ClientContext`. Extraction de `util/SignupAttribution` (source, plateforme,
  `signup_anonymous_id`), autorité unique local + social. `AnalyticsIdentityService
  .onAuthenticated(userId, AuthKind, anonymousId)` : `AuthKind` (`SIGNUP|LOGIN`, dérivé de la
  branche de création côté social) est la future `claim_kind` ; le lot 2 y ajoute le claim de
  la run et `signup_context`. `signup_anonymous_id` est effacé par `User.anonymize()`.
- Fichiers : `AuthService`, `SocialAuthService`, `AuthController`, `AnalyticsIdentityService`,
  `SignupAttribution`, `AuthKind`, `User`, `AuthAnalyticsIdentityIT`, `SocialAuthServiceTest`.
- Difficulté de retour : faible.

**D16 — Test intermittent corrigé hors périmètre** · Lot 1b
- Contexte : `./mvnw verify` rouge sur `UnsubscribeTokenServiceTest.uneSignatureAltereeEstRefusee`
  (~1 fois sur 16) : changer le **dernier** caractère base64url d'une signature de 32 octets
  peut ne toucher que les bits de bourrage.
- Choix et motif : le test altère désormais le **premier** caractère. Même passe :
  `EmailDeferredRetryIT.passwordChangedRelanceDansLes24h` échouait aussi par intermittence
  (ligne relancée encore `PENDING` quand l'executor paraît au repos) ; le test attend l'état
  final (borné par `EmailTestSupport.await`, une ligne bloquée échoue toujours). Code de
  production inchangé.
- Fichiers : `UnsubscribeTokenServiceTest`, `EmailDeferredRetryIT`.
- Difficulté de retour : faible.

**D17 — `/confidentialite`** · Lot 1b
- Choix et motif : art. 5 → « 395 jours au plus (13 mois), puis suppression automatique ;
  l'identifiant a lui-même une durée de vie de 13 mois » ; 8.4 → 13 mois = condition CNIL
  **du traceur**, la purge à 395 j est notre choix ; 8.3 → identifiant mobile, rattachement
  du parcours antérieur à la création de compte **et à la connexion**, y compris un
  diagnostic passé sans compte (jamais les réponses) ; 3.2 → système et version de l'app ;
  8.2 → « trois choses et rien d'autre » était faux (audit E5) : ajout des brouillons
  (`sejourfr-diagnostic`, `sejourfr.civic-diagnostic.invite`, `sejourfr.ee.draft.*`) et de
  `sejourfr.prodQuotaInfo.*`. ⚠️ Pour le propriétaire (vérif. RGPD, Q5) : 8.4 affirme que les
  données « ne sont recoupées avec aucun autre traitement », à relire au regard du
  rattachement au compte (préexistant en 8.3).
- Fichiers : `web_sejoufr/app/confidentialite/page.tsx`.
- Difficulté de retour : faible.

---

## 3. Récapitulatif final

_(rempli en fin de chantier : lots livrés, état des 20 scénarios, points ouverts, actions du
propriétaire)_
