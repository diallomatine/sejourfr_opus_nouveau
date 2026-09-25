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

**D18 — Références périmées laissées dans les fichiers des autres lots** · Lot 1a
- Contexte : des Javadoc citent encore des classes supprimées (`PageViewService`, `AudienceFunnel*`, `/api/public/page-views`) — commentaires seuls, sans effet de compilation.
- Options : corriger tout de suite ; laisser aux lots propriétaires.
- Choix : laisser au lot propriétaire, pour éviter les collisions avec le lot 1b (ingestion) et le lot 4 (qui supprime ces fichiers).
- Fichiers : lot 1b → `PublicAnalyticsController:35-38`, `util/TrafficSource:11`, `util/AnalyticsPaths:17` ; lot 4 → `AdminAnalyticsResponse:19`, `AnalyticsReadRepository:29,202`, `AdminAnalyticsService:46,332`.
- Difficulté de retour : faible.

**D19 — Tests de garde des routes supprimées** · Lot 1a
- Contexte : tout changement d'endpoint se verrouille par un test backend.
- Options : aucun test ; asserter 404.
- Choix : 404 asserté sur les 4 routes retirées (admin appelées en ADMIN), pour que l'endpoint public sans rate-limit ne puisse pas revenir en silence.
- Fichiers : `AdminRoutesSecurityIT`, `PublicRoutesSecurityIT`.
- Difficulté de retour : faible.

**D20 — Doc périmée corrigée par note datée, pas réécrite** · Lot 1a
- Contexte : la doc affirmait à tort ces classes supprimées le 2026-08-21 ; les fichiers `docs/decisions/` sont des journaux.
- Options : réécrire / supprimer ; corriger par note datée.
- Choix : note « Supprimé / Correction du 2026-09-25 », l'historique est conservé. Les `CLAUDE.md` web et mobile, qui décrivaient encore `page-views` et `lib/audience*.ts`, ont été corrigés par l'orchestrateur.
- Fichiers : `docs/decisions/mesure-audience.md`, `docs/regles/mesure-audience.md`, `docs/decisions/suspects-perimes.md`, `web_sejoufr/CLAUDE.md`, `mobile_sejourfr/CLAUDE.md`.
- Difficulté de retour : faible.

**D21 — Création de run : route, double idempotence, jeton re-tiré** · Lot 2a
- Contexte : Q3 (appel public idempotent à l'affichage du sujet) et D1 (`client_key` par `anonymous_id`) ; seul le hash du jeton est stocké, donc un rejeu ne peut pas rendre le jeton d'origine.
- Options : rejeu → 409 ; rejeu → même run sans jeton ; rejeu → même run avec un nouveau jeton ; jeton dérivé (HMAC du runId) pour le rendre identique.
- Choix : `POST /api/public/diagnostic-runs` (nouveau `PublicDiagnosticRunController`), **200** avec `created` (pas 201/200 selon le cas, plus simple à consommer). Idempotence dans l'ordre : session déjà tracée → sa run ; `(anonymous_id, clientKey)` déjà vue → sa run ; sinon `INSERT … ON CONFLICT DO NOTHING` (course gagnée par l'autre requête → sa run). Un rejeu rend la **même run et un nouveau jeton** (`rotateToken`), l'ancien ne vaut plus rien : le client garde toujours la dernière réponse. Le HMAC a été écarté (secret serveur de plus, et Q3 demande un aléa). `clientKey` rejouée pour un autre type → 409. `FULL_TCF` sans compte → 403. Jeton 256 bits base64url, TTL `claimTokenTtlDays`.
- Fichiers : `controller/PublicDiagnosticRunController`, `dto/DiagnosticRun{CreateRequest,CreatedResponse,SubmitRequest}`, `service/diagnosticrun/DiagnosticRunService`, `manager/DiagnosticRunManager`, `repository/DiagnosticRunRepository`.
- Difficulté de retour : moyenne après le lot 3 (contrat client).

**D22 — Sans identifiant de mesure, pas d'idempotence par clé** · Lot 2a
- Contexte : l'index `ux_diagnostic_run_client_key (anonymous_id, client_key)` ne lie pas les `NULL` ; une navigation privée ou un stockage bloqué n'a pas d'`anonymous_id`.
- Options : exiger l'en-tête (400) ; borner la clé au compte ; accepter sans idempotence.
- Choix : accepter, sans idempotence par clé (l'idempotence par session reste). Refuser ferait perdre l'étape 1 de ces visiteurs, et élargir la clé à `NULL` ferait résoudre la clé d'un inconnu vers la run d'un autre (même doctrine que V046). Le lot 3 envoie l'en-tête partout.
- Fichiers : `DiagnosticRunRepository.insertIfAbsent`, `DiagnosticRunManager.findByClientKey`.
- Difficulté de retour : faible.

**D23 — Une seule autorité de « soumis » par type** · Lot 2a
- Contexte : Q3 (« soumis » une seule fois) ; le TCF rapide invité n'a aucun fait serveur avant le compte (V053), et `POST /api/diagnostics` est appelé **au démarrage** par un connecté (`DiagnosticView.tsx`), donc le handoff n'est pas une soumission fiable.
- Options : appel client pour tous ; serveur pour tous ; mixte.
- Choix : **`QUICK_TCF` = appel client** `POST /api/public/diagnostic-runs/{id}/submit` (invité et connecté, à « Analyser mes réponses ») ; **`CIVIQUE` = serveur** à la fin de l'attempt (`AttemptInteractionService.doFinish` : fin publique, connectée ou échéance ; et `CivicDiagnosticService.cloturer` s'il ferme l'attempt) ; **`FULL_TCF` = serveur** à `TcfDiagnosticService.cloturer`. L'appel client est refusé en **409** pour les deux derniers : deux autorités se contrediraient. `UPDATE … WHERE submitted_at IS NULL` : une seule fois. `submitted_authenticated` = porteur de l'attempt / appelant JWT **à cet instant** ; un soumis connecté pose aussi `user_id` (« soumis connecté » ⇒ « rattaché »). ⚠️ Une échéance civique close paresseusement compte « soumis » (l'attempt est bien clos).
- Fichiers : `DiagnosticRunService`, `AttemptInteractionService`, `CivicDiagnosticService`, `TcfDiagnosticService`, `DiagnosticRunRepository.markSubmitted*`.
- Difficulté de retour : moyenne.

**D24 — Un runId n'est jamais cru : règle d'appartenance et liaison aux sessions** · Lot 2a
- Contexte : le runId voyage dans les événements (pas un secret) ; il faut lier la run à sa session (FK V074) sans faire confiance au client.
- Options : jeton dans l'URL des routes de session ; liaison à la création (session prouvée) ; liaison à l'ouverture de session (run prouvée).
- Choix : **appartenance d'une run** = compte porteur, ou `claimToken` valide (et, si run et appelant ont chacun un `anonymous_id`, le même) ; une run portée par un compte n'est écrite par aucun autre compte, même muni du jeton. **Liaison** : à la **création** (`sessionId` facultatif, session vérifiée comme sa propre lecture : compte, ou IP pour le civique invité — 404 sinon) pour civique, complet et rapide connecté ; au **handoff** (`POST /api/diagnostics?diagnosticRunId=`) pour le rapide invité, **seulement si la run appartient déjà au compte** (claimée à l'auth) — aucun jeton en query string (journaux d'accès). Une run inconnue, d'un tiers ou déjà liée est ignorée sans erreur au handoff. Une session déjà tracée rend sa run.
- Fichiers : `DiagnosticRunService`, `DiagnosticService`, `DiagnosticController`, `DiagnosticRunRepository.link*`.
- Difficulté de retour : moyenne.

**D25 — Claim dans la transaction d'auth, jamais une erreur** · Lot 2a
- Contexte : Q3 « claim dans la transaction d'auth » ; doctrine « une mesure n'empêche jamais d'entrer » ; mais une exception SQL dans une transaction Postgres l'avorte, `catch` ou pas.
- Options : best-effort hors transaction (`REQUIRES_NEW`) ; dans la transaction avec vérifications préalables.
- Choix : **dans la transaction**, `DiagnosticRunClaimService.onAuthenticated` appelé à côté du lien d'identité (local, Google, Apple). Toutes les conditions (hash, expiration, jamais claimée, **sans porteur**) sont vérifiées en Java **avant** un `UPDATE` conditionnel qui les redit (deux auths concurrentes ne claiment qu'une fois) : un runId illisible, un jeton faux, expiré ou utilisé ne touchent pas la base et l'auth réussit. Une run déjà portée (créée ou soumise connectée) n'est pas « claimée » : elle était déjà rattachée. Une run claimée mais **non soumise** est rattachée, et l'inscription reste `OUTSIDE_DIAGNOSTIC`. Le claim ne regarde pas le quota (Q3). `claimed_via` : paramètre du service (`SAME_DEVICE` aujourd'hui) — **aucun champ de DTO** pour `APP_LINK` tant que le lot 3b n'a pas de client : il ajoutera le sien. `signup_context` / `signup_diagnostic_*` posés au même instant par `SignupAttribution.stampContext` (autorité unique, local et social).
- Fichiers : `DiagnosticRunClaimService`, `AuthService`, `SocialAuthService`, `SignupAttribution`, `User`, `dto/{Login,Register,GoogleSignIn,AppleSignIn}Request`, `DiagnosticRunClaimVia`, `SignupContext`.
- Difficulté de retour : faible.

**D26 — L'état d'une run se relit en colonnes, jamais en entité** · Lot 2a
- Contexte : les transitions sont des `UPDATE` natifs ; une entité déjà chargée dans le contexte de persistance garde ses anciennes valeurs (constaté en test : l'ancien jeton restait valide après un rejeu dans la même transaction).
- Options : `clearAutomatically` (détache tout au milieu d'une fin d'attempt ou d'une auth) ; projection scalaire.
- Choix : toute vérification (appartenance, claim, handoff) lit `DiagnosticRunManager.findState` (projection JPQL relue en base). Les `UPDATE` ne vident jamais le contexte.
- Fichiers : `DiagnosticRunRepository.findStateById`, `DiagnosticRunManager.State`.
- Difficulté de retour : faible.

**D27 — La run oublie son `anonymous_id` au-delà de 395 j (tranche D14)** · Lot 2a
- Contexte : D14 laissait au lot 2 le sort de `diagnostic_run.anonymous_id` après la purge du visiteur.
- Options : garder ; oublier.
- Choix : **oublier** `anonymous_id` et `client_key` des runs vues avant la limite de rétention, par lots, troisième passe d'`AnalyticsRetentionService` (non comptée dans le total « lignes supprimées »). La run et ses faits restent ; l'identifiant, qui ne désigne plus aucun visiteur, reste un identifiant de traceur (Q5). Conséquence : une cohorte de plus de 13 mois ne déduplique plus ses anonymes, sans effet sur un dashboard à 14 j. `users.signup_anonymous_id` (donnée de compte) n'est pas touché.
- Fichiers : `AnalyticsRetentionService`, `DiagnosticRunRepository.forgetAnonymousIdBefore`, `AnalyticsRetentionServiceIT`.
- Difficulté de retour : faible.

**D28 — Dates de début de mesure laissées à `null`, posées par le lot 3** · Lot 2a
- Contexte : Q16 et D12 (« chaque lot qui met un indicateur en service pose sa date »). Le serveur est prêt, mais sans les clients du lot 3 aucune run n'est créée, et **toute inscription s'écrit `OUTSIDE_DIAGNOSTIC`** faute de jeton.
- Options : dater au jour du lot 2a ; laisser `null`.
- Choix : **`null`** pour `DIAGNOSTIC_SUBJECT_VIEWED`, `DIAGNOSTIC_SUBMITTED`, `ACCOUNT_ATTACHED`, `SIGNUP_CONTEXT`. Une date posée aujourd'hui afficherait des zéros et 100 % d'« inscription directe » jusqu'au déploiement des fronts : un chiffre faux, là où Q16 veut un chiffre inconnu. ⚠️ **Le lot 3 pose la date de sa mise en production** (web et mobile le même jour, sinon la plus tardive) ; le lot 4 ignore les lignes antérieures (`users.created_at`, `subject_viewed_at`).
- Fichiers : `analytics/analytics-config-v1.json` (inchangé sur ces clés).
- Difficulté de retour : faible (config).

**D29 — Plan ↔ run (Q8) : la run fondatrice** · Lot 2a
- Contexte : Q8 (`plan_id = journey.id`, le serveur résout la run lui-même) ; le lot 2b s'en sert pour `purchase_intent`. Rien ne relie `journey` à un diagnostic, sauf le journal `journey_assessment_event`.
- Options : run la plus récente du compte (heuristique interdite par Q12) ; journal des évaluations.
- Choix : `DiagnosticRunManager.findFoundingRun(UUID journeyId, UUID userId) : Optional<DiagnosticRun>` — la run du diagnostic (`QUICK_DIAGNOSTIC` → session, `CIVIC_DIAGNOSTIC` → session civique, `FULL_DIAGNOSTIC` → section → `attempts.tcf_diagnostic_id`) **le plus ancien** journalisé sur le parcours, reliée par les FK de session, appartenant au porteur du parcours (`j.user_id = :userId` : l'id d'un autre parcours ne résout rien). Vide si aucun diagnostic n'a de run liée : inconnu. `JourneyDto.journeyId` expose `journey.id` (`null` sans parcours). ⚠️ **Miroirs fronts au lot 3** : `web_sejoufr/lib/types.ts`, `mobile_sejourfr/lib/core/models/` (`JourneyDto`), admin non concerné.
- Fichiers : `DiagnosticRunRepository.findFoundingRun`, `DiagnosticRunManager`, `dto/JourneyDto`, `JourneyReadService`, `DiagnosticRunFoundingIT`, `JourneyControllerIT`.
- Difficulté de retour : faible.

**D30 — Extractions et configuration** · Lot 2a
- Contexte : un 3ᵉ SHA-256 privé et une 2ᵉ copie des quatre fenêtres de rate-limit se profilaient.
- Choix : `util/JetonSecret` (tirage, SHA-256 hex, comparaison à temps constant), désormais utilisé par `AuthService` (réinitialisation, format inchangé) ; `UserProfileService` garde son hash base64url (jetons déjà émis). `ratelimit/IpEtIdentifiantLimites` porte les quatre fenêtres, partagées par `AnalyticsBatchRateLimit` et `DiagnosticRunRateLimit` (compteurs séparés création / soumission). Nouvelle section **`diagnosticRunRateLimit`** dans `analytics-config-v1.json` (IP 30 / 10 min et 300 / j ; identifiant 20 / 10 min et 100 / j), validée au boot : v1 n'est pas encore en production, on l'étend plutôt que d'ouvrir une v2. **Aucune migration** : V074 suffisait, V075 reste libre.
- Fichiers : `util/JetonSecret`, `AuthService`, `ratelimit/*`, `AnalyticsConfig`, `AnalyticsConfigLoader`, `analytics-config-v1.json`.
- Difficulté de retour : faible.

**D31 — Résolution journey → run fondatrice, version minimale** · Lot 2b
- Contexte : la méthode du lot 2a n'existait pas encore quand le lot 2b l'a utilisée.
- Options : attendre 2a ; heuristique « run la plus récente » ; lecture par FK.
- Choix : lecture par FK dans `PurchaseIntentRepository.foundingRunOf` (1er `journey_assessment_event` diagnostic → run du même compte liée à cette session), aucune heuristique. **Réconciliée au lot 4** : remplacée par `DiagnosticRunManager.findFoundingRun` (une règle = une autorité).
- Fichiers : `PurchaseIntentRepository`, `PurchaseIntentManager`.
- Difficulté de retour : faible.

**D32 — « CTA du Plan » = `LOCKED_PLAN` seul ; la run n'est posée que pour `DIAGNOSTIC_PLAN`** · Lot 2b
- Contexte : Q12 dit « CTA du plan » sans liste ; tous les « Débloquer » du Plan envoient déjà `LOCKED_PLAN`.
- Options : `{LOCKED_PLAN}` ; `{LOCKED_PLAN, DIAGNOSTIC_REPORT}`.
- Choix : `{LOCKED_PLAN}`. En `OTHER_CTA`, `journey_id` conservé mais `diagnostic_run_id` nul : l'achat n'entre pas dans le tunnel.
- Fichiers : `PurchaseIntentService.CTA_DU_PLAN`, `AttributionAchat`.
- Difficulté de retour : faible (un ensemble à modifier).

**D33 — Sans `ctaLocation` lisible au checkout : pas d'intention, jamais d'erreur** · Lot 2b
- Contexte : Q12 veut une intention quel que soit le CTA, mais un client ancien n'envoie rien et un paiement ne doit jamais être bloqué.
- Options : intention par défaut `OTHER` ; 400 ; pas d'intention.
- Choix : pas d'intention → achat `UNKNOWN` (un CTA par défaut produirait un `OTHER_CTA` faux). L'endpoint mobile exige un CTA valide (400).
- Fichiers : `PurchaseIntentService.creerPourCheckout`, `BillingService`.
- Difficulté de retour : faible.

**D34 — Expiration de l'intention jugée à l'instant d'achat du canal** · Lot 2b
- Contexte : une relance de webhook ou un reçu rejoué arrive parfois bien après l'achat.
- Options : heure de réception ; heure d'achat du canal.
- Choix : `created` Stripe / `purchaseDate` Apple / `purchaseTimeMillis` Google, sinon maintenant. Consommation par `UPDATE` conditionnel (même compte, produit, non expirée, non consommée) ; une intention refusée reste intacte.
- Fichiers : `PurchaseIntentRepository.consume`, `PurchaseIntentService.consommer`.
- Difficulté de retour : faible.

**D35 — Identifiant de remboursement Stripe = `<charge>:<cumul remboursé>`** · Lot 2b
- Contexte : avec la version d'API actuelle, `charge.refunded` ne liste plus les remboursements.
- Options : appel `Refund.list` ; clé calculée depuis `amount_refunded`.
- Choix : clé calculée, sans appel réseau ; le montant écrit = cumul − déjà enregistré, un état rejoué n'écrit rien.
- Fichiers : `StripeSubscriptionService.rembourserPass`.
- Difficulté de retour : moyenne (les lignes écrites gardent ce format).

**D36 — Règles de calcul des remboursements** · Lot 2b
- Contexte : le brief §6.4 fixe les deltas, pas l'identifiant, la conversion ni les achats anciens.
- Options : —
- Choix : devise de l'achat convertie au taux figé ; delta `null` si l'achat n'a pas de décomposition ; Apple : `transactionId`, prorata `revocationPercentage` (absent = total), `REVOKE` retire l'accès sans ligne, `REFUND_REVERSED` ignoré ; Google : `orderId` sinon `purchaseToken`, toujours total, date = `publishTime`.
- Fichiers : `PaymentRefundService`, `AppleSubscriptionService`, `GoogleSubscriptionService`.
- Difficulté de retour : moyenne.

**D37 — `payment_status` = `PAID | PARTIALLY_REFUNDED | REFUNDED`, distinct du statut d'accès** · Lot 2b
- Contexte : V074 laissait la colonne sans CHECK.
- Options : —
- Choix : une ligne n'existe qu'une fois le paiement encaissé (pas d'état « en attente ») ; seul un remboursement total retire l'accès.
- Fichiers : `PaymentStatus`, `UserSubscription`, `EtatAbonnement`.
- Difficulté de retour : faible.

**D38 — Prix Apple lu dans le JWS, jamais dans la requête** · Lot 2b
- Contexte : bug Q11.
- Options : —
- Choix : `price` (millièmes) → centimes HALF_UP ; JWS sans prix → prix du plan.
- Fichiers : `MontantEncaisseResolver.duJwsApple`, `AppleSubscriptionService`.
- Difficulté de retour : faible.

**D39 — Prix Google borné par le catalogue à ±50 %, en configuration** · Lot 2b
- Contexte : Play ne renvoie aucun prix pour un consommable ; seul le client le connaît.
- Options : tolérance stricte ; large ; ignorer le client.
- Choix : ±50 % de `plans.price` en euros (`sejourfr.billing.store-price-tolerance: 0.5`), large car vendu en devise locale ; hors borne ou devise sans taux → prix catalogue.
- Fichiers : `MontantEncaisseResolver.borneParCatalogue`, `BillingProperties`, `application.yaml`.
- Difficulté de retour : faible (config).

**D40 — Anti-rejeu Stripe : garde sur l'âge (300 s) supprimée** · Lot 2b
- Contexte : Stripe garde la date de création d'origine sur ses relances (jusqu'à 3 j) : la garde rejetait définitivement des relances légitimes.
- Options : garder ; élargir ; supprimer.
- Choix : supprimée : le rejeu reste bloqué par la signature (tolérance sur l'horodatage de signature, régénéré à chaque livraison) et l'idempotence sur l'id d'événement.
- Fichiers : `BillingService`.
- Difficulté de retour : faible.

**D41 — Frais réel Stripe lu seulement pour un achat neuf** · Lot 2b
- Contexte : un webhook rejoué ne doit pas rappeler Stripe.
- Options : —
- Choix : erreur ou devise ≠ EUR → formule (`ESTIMATED`).
- Fichiers : `StripeFeeClient`, `StripeSubscriptionService`.
- Difficulté de retour : faible.

**D42 — Abonnements récurrents dormants hors décomposition et attribution** · Lot 2b
- Contexte : ces chemins ne sont pas en service (mode `ONE_TIME`).
- Options : —
- Choix : ils écrivent le montant comme avant, colonnes de revenu `null` = inconnu.
- Fichiers : aucun.
- Difficulté de retour : faible.

**D43 — Dates de début de mesure : posées au déploiement, pas au commit** · Orchestrateur
- Contexte : D12 prévoit une date `measurementStart` par indicateur ; D28 (2a) et le lot 2b ont laissé `null` les indicateurs du tunnel, des achats et des revenus. La « bonne » date est celle où le code est **en production**, inconnue au moment du commit.
- Options : poser la date du commit ; poser une date prévisionnelle ; laisser `null` et la faire poser au déploiement.
- Choix : laisser `null`. Une date de commit antérieure au déploiement afficherait des zéros faux entre les deux. Le lot 4 affiche « non mesuré » pour tout indicateur à `null` ou dont la période précède la date. Poser les dates est une **action du propriétaire** au déploiement (§3).
- Fichiers : `analytics/analytics-config-v1.json` (inchangé).
- Difficulté de retour : faible (une valeur de config).

**D44 — Rendu d'une étape de tunnel non mesurée** · Lot 4 admin
- Contexte : aujourd'hui les 7 étapes valent `null` ; une barre grise vide se lirait « personne ».
- Options : barre vide ; « 0 » ; cadre pointillé avec mention ; encart unique.
- Choix : tunnel entièrement `null` → un encart unique « Non mesuré… » ; tunnel partiel → étapes `null` en cadre pointillé « non mesuré » / « mesuré depuis le JJ/MM », taux « — ». Une étape à 0 réel affiche « 0 » sans barre (le template imposait 52 px minimum, qui dessinait une barre pour zéro).
- Fichiers : `FunnelCard.tsx`, `measurement.ts`.
- Difficulté de retour : faible.

**D45 — Longueur des barres de sources calculée par le front** · Lot 4 admin
- Contexte : le contrat ne sert pas de largeur de barre pour les sources ; le template en dessine.
- Options : pas de barre ; échelle au plus gros groupe ; champ backend.
- Choix : échelle visuelle rapportée au maximum, aucun pourcentage affiché. Seule arithmétique de l'écran, documentée dans `admin_sejourfr/CLAUDE.md`.
- Fichiers : `SourcesCard.tsx`.
- Difficulté de retour : faible.

**D46 — « Apple » conservé dans le bloc Revenus** · Lot 4 admin
- Contexte : l'écart « Apple → iOS » vise la plateforme ; dans Revenus, APPLE est le fournisseur de paiement.
- Options : « iOS » partout ; « iOS » pour les plateformes seulement.
- Choix : « iOS » dans la grille Inscriptions ; « Stripe / Apple / Google » dans Revenus.
- Fichiers : `labels.ts`.
- Difficulté de retour : triviale.

**D47 — Placement Activité / Sources** · Lot 4 admin
- Contexte : le retrait du bloc « Utilisation du plan » libère la place de gauche de la dernière rangée.
- Options : Sources seul ; Activité pleine largeur dessous ; [Activité | Sources].
- Choix : rangée [Activité | Sources] : Sources garde sa place du template, pas de trou. Activité n'est pas un proxy du bloc Plan (libellés explicites).
- Fichiers : `SuiviPage.tsx`.
- Difficulté de retour : triviale.

**D48 — Filtres dans l'URL** · Lot 4 admin
- Contexte : l'ancien écran gardait ses filtres en `localStorage` ; `/subscriptions` les met dans l'URL.
- Options : `localStorage` ; URL.
- Choix : URL (`?period&from&to&type&platform&source&internal`), défauts non écrits, valeurs illisibles ignorées ; plage incomplète ou inversée → « Aujourd'hui » ; > 365 j → 400 affiché en erreur.
- Fichiers : `useSuiviParams.ts`, `SuiviFilters.tsx`.
- Difficulté de retour : faible.

**D49 — Formatage des pourcentages servis** · Lot 4 admin
- Contexte : le serveur sert une décimale (64.0) ; le template affiche « 64 % » et « 11,4 % ».
- Options : —
- Choix : `maximumFractionDigits: 1` (affichage seul, aucun recalcul) ; variations signées ; montants retirés avec le signe moins U+2212.
- Fichiers : `format.ts`, `labels.ts`.
- Difficulté de retour : triviale.

**D50 — Écarts de template non listés, gardés au minimum** · Lot 4 admin
- Contexte : le template ne prévoit ni les filtres plateforme/source/internes, ni la période appliquée, ni les notes d'inconnu.
- Options : —
- Choix : ligne « période appliquée » sous le titre ; seconde ligne de filtres discrets (Plateforme et Source en `<select>`, case « Inclure internes », dates visibles seulement en « Personnalisé ») ; badge « en cours » dans l'en-tête du tunnel ; notes de bas de bloc conditionnelles (achats sans décomposition, frais estimés, bloc qui ignore le filtre type, connexions après diagnostic, plateformes anciennes, « Origine inconnue » seulement si > 0) ; palier responsive à 400 px pour tenir 360 px ; charte admin (tokens, Fraunces pour titres et chiffres principaux, JetBrains Mono pour badges).
- Fichiers : `features/suivi/*`.
- Difficulté de retour : faible.

**D51 — Un module unique pour le contexte client** · Lot 3 web
- Contexte : `api.ts` a besoin de l'identifiant (en-têtes) et `analytics.ts` importe `api` : cycle d'import.
- Options : identité dans `analytics.ts` ; module dédié.
- Choix : `lib/client-context.ts` (identifiant, visite, en-têtes, version), qui n'importe que `traffic-source`. Version : `NEXT_PUBLIC_APP_VERSION`, sinon `npm_package_version`.
- Fichiers : `client-context.ts`, `api.ts`, `analytics.ts`, `next.config.ts`.
- Difficulté de retour : faible.

**D52 — Run + jeton stockés dans l'IndexedDB du diagnostic** · Lot 3 web
- Contexte : Q3 : jeton gardé avec le brouillon ; deux modules ne peuvent pas ouvrir la même base à deux versions.
- Options : `localStorage` ; même base IndexedDB.
- Choix : base `sejourfr-diagnostic` v2 avec un magasin `runs` (une entrée par type), un seul ouvreur (`openDiagnosticDb`), repli mémoire.
- Fichiers : `diagnostic-local-store.ts`, `diagnostic-run-store.ts`, `confidentialite/page.tsx`.
- Difficulté de retour : faible.

**D53 — Ce qu'est un « passage »** · Lot 3 web
- Contexte : quand réutiliser une `clientKey` et quand en tirer une nouvelle.
- Options : —
- Choix : même session, ou trace d'invité sans session non soumise (un invité qui se connecte continue le même passage) → même clé ; sinon nouvelle. Pas d'appel si la trace est complète et le jeton valide. Clé écrite avant l'appel pour être rejouée après coupure.
- Fichiers : `diagnostic-run.ts`.
- Difficulté de retour : faible.

**D54 — Quelle run une authentification envoie** · Lot 3 web
- Contexte : —
- Options : écran par écran ; dans `authApi`.
- Choix : dans `authApi` : la run invitée la plus récente de l'appareil dont le jeton est valide. Jeton conservé après l'auth (lot 3b) ; le renvoyer est sans effet serveur.
- Fichiers : `api.ts`, `diagnostic-run-store.ts`.
- Difficulté de retour : faible.

**D55 — « Soumis » du TCF rapide sur le web** · Lot 3 web
- Contexte : le bouton « Analyser mes réponses » n'existe pas sur le web.
- Options : —
- Choix : le bouton de la dernière production (« Valider mon diagnostic » / « Terminer et analyser » en invité ; envoi de la dernière production connecté). Jamais la run d'une autre session.
- Fichiers : `DiagnosticView.tsx`.
- Difficulté de retour : faible.

**D56 — Les événements du Plan ne portent pas de run** · Lot 3 web
- Contexte : Q8 (le serveur résout la run fondatrice) contredisait la consigne « run + journey » donnée par l'orchestrateur.
- Options : run + journey ; journey seul.
- Choix : `journeyId` seul sur `PLAN_OPENED` et `PLAN_UNLOCK_CLICKED` ; la lecture Suivi joint journey → run fondatrice. **Arbitrage orchestrateur : Q8 prime, le mobile est aligné.**
- Fichiers : `LearningPlanView.tsx`, `CivicPlanPanel.tsx`, `PlanUnlockScreen.tsx`.
- Difficulté de retour : faible.

**D57 — Le rapport ne cite que la run de sa propre session** · Lot 3 web
- Contexte : —
- Options : —
- Choix : run jointe seulement si la trace locale désigne cette session, sinon `null`. Le rapport du TCF complet émet aussi l'événement (activité).
- Fichiers : `diagnostic-run.ts`, écrans de résultat.
- Difficulté de retour : faible.

**D58 — Emplacement et contenu de `PLAN_UNLOCK_CLICKED`** · Lot 3 web
- Contexte : —
- Options : —
- Choix : bouton rouge de `/plan/debloquer` (seul à afficher un prix) ; `planCode` = pass d'entrée affiché, `displayedPriceCents = round(prix × 100)` ; catalogue injoignable ⇒ ni code ni prix.
- Fichiers : `PlanUnlockScreen.tsx`, `passes.ts`.
- Difficulté de retour : faible.

**D59 — Transport de l'intention d'achat par l'adresse** · Lot 3 web
- Contexte : —
- Options : —
- Choix : `?cta=` et `?journey=` validés à l'arrivée ; sans rien : `PRICING` sur `/paiement` ; `PaywallSheet` et les CTA `OTHER` transmettent leur `ctaLocation` ; `origin` obligatoire dans `getPaymentLink`. **Suite orchestrateur** : toutes les feuilles du Plan en `LOCKED_PLAN` transmettent aussi `journeyId`.
- Fichiers : `purchase-origin.ts`, `api.ts`, pages de paiement, `PaywallSheet.tsx`, `SkillLayout.tsx`, `TcfPaywallCard.tsx`, `profil/abonnement`.
- Difficulté de retour : faible.

**D60 — Politique d'envoi des lots** · Lot 3 web
- Contexte : —
- Options : —
- Choix : 202 → purge (rejets compris) ; 400 → lot abandonné (écart à la lettre de D5 : renvoyer à l'identique échouerait toujours) ; 429/5xx/réseau → nouvel essai à 30 s sous les mêmes `eventId` ; sans identifiant de mesure, rien ne part ; file plafonnée à 200.
- Fichiers : `analytics.ts`.
- Difficulté de retour : faible.

**D61 — Allowlist de chemins miroir et first-touch au premier chargement** · Lot 3 web
- Contexte : l'accueil n'émet rien et perdait ses UTM à la première navigation.
- Options : —
- Choix : `TRACKED_PATHS` recopie `AnalyticsPaths.KNOWN` ; écran non déclaré → `path: null` ; first-touch capté au premier chargement (`FirstTouchCapture` dans le layout racine).
- Fichiers : `analytics.ts`, `FirstTouchCapture.tsx`, `layout.tsx`.
- Difficulté de retour : faible.

**D62 — « Sujet vu » du TCF complet dans le hub** · Lot 3 web
- Contexte : les sections EE/EO ne passent pas par le runner.
- Options : —
- Choix : création de la run au lancement de section (`lancerSection`), idempotente par session.
- Fichiers : `TcfDiagnosticHub.tsx`.
- Difficulté de retour : faible.

**D63 — Achat `LOCKED_PLAN` sans parcours résoluble** · Orchestrateur
- Contexte : plusieurs feuilles d'achat du Plan envoyaient `LOCKED_PLAN` sans `journeyId` ; la règle 2b (D32) aurait rangé l'achat en `OTHER_CTA`, ce qui est faux (c'est bien le CTA du Plan).
- Options : `OTHER_CTA` ; `DIAGNOSTIC_PLAN` sans run ; résoudre le parcours actif côté serveur ; `UNKNOWN`.
- Choix : `UNKNOWN`, run nulle (inconnu plutôt que faux, aucune résolution devinée), et le web comme le mobile transmettent le `journeyId` sur toutes les feuilles du Plan pour que ce cas reste marginal.
- Fichiers : backend lot 4 (`AttributionAchat`), web et mobile (feuilles d'achat du Plan).
- Difficulté de retour : faible.

**D64 — Un seul contexte client, `package_info_plus` en dépendance directe** · Lot 3 mobile
- Contexte : Q4 demande trois en-têtes ; l'app n'avait aucune source pour sa version.
- Options : `--dart-define` ; `package_info_plus`.
- Choix : `ClientContext`, posé par l'intercepteur d'`ApiClient` et par le refresh. `package_info_plus` était déjà embarqué par `wakelock_plus` (9.0.1) : binaire inchangé. `X-Sejourfr-Client` vaut `ios|android`, plus jamais `mobile`.
- Fichiers : `client_context.dart`, `api_client.dart`, `analytics_identity.dart`, `auth_controller.dart`, `pubspec.yaml`.
- Difficulté de retour : faible.

**D65 — Retour réseau détecté par les réponses du serveur, sans `connectivity_plus`** · Lot 3 mobile
- Contexte : Q15 demande un envoi au retour du réseau.
- Options : paquet de connectivité ; réponses d'`ApiClient`.
- Choix : `ApiClient.onReachable` relance la file si le dernier échec était réseau ; + reprise de l'app, minuterie 60 s, délai croissant 5 s → 5 min. Aucune dépendance ajoutée.
- Fichiers : `analytics_queue.dart`, `api_client.dart`.
- Difficulté de retour : faible.

**D66 — File SharedPreferences groupée par visite** · Lot 3 mobile
- Contexte : l'enveloppe ne porte qu'un `sessionId`, la file hors ligne mélange plusieurs visites.
- Options : —
- Choix : chaque événement garde son `anonymousId` et son `sessionId` ; un lot = la visite la plus ancienne, ≤ 50 ; file ≤ 200 événements et ≤ 160 h (le serveur rejette à 168 h) ; 202 purge (rejets compris), 4xx abandonne, 429/5xx/réseau réessaie sous les mêmes `eventId`.
- Fichiers : `analytics_queue.dart`, `analytics_repository.dart`, `analytics.dart`, `analytics_events.dart`.
- Difficulté de retour : faible.

**D67 — Une trace de run par type, rattachée à un passage** · Lot 3 mobile
- Contexte : un visiteur peut commencer le civique et le TCF rapide.
- Options : —
- Choix : `DiagnosticRunTracker`, seul stockage run + jeton, une entrée par type ; `clientKey` réutilisée tant que le passage n'est pas clos et la session identique. Le « soumis » du TCF rapide crée la run si elle manque (étape 1 datée un peu tard, passage non perdu).
- Fichiers : `diagnostic_run_tracker.dart`, `diagnostic_controller.dart`, `diagnostic_screen.dart`, `runner_screen.dart`, `tcf_diagnostic_screen.dart`.
- Difficulté de retour : moyenne.

**D68 — Moments de création de la run sur mobile** · Lot 3 mobile
- Contexte : « à l'affichage de la 1ʳᵉ question ».
- Options : —
- Choix : écran de l'écrit (TCF rapide) ; ouverture du runner `civicDiagnosticId` (civique) ; démarrage d'une section (TCF complet), comme le web (D62).
- Fichiers : idem D67.
- Difficulté de retour : faible.

**D69 — Un événement ne porte que la run du compte connecté** · Lot 3 mobile
- Contexte : appareil partagé entre plusieurs comptes. Le web vérifie la session (D57) : mécanisme différent, contrat identique.
- Options : —
- Choix : le tracker note le compte porteur de la run ; `runIdFor` ne renvoie rien pour un autre compte.
- Fichiers : `diagnostic_run_tracker.dart`, `auth_controller.dart`.
- Difficulté de retour : faible.

**D70 — CTA par défaut `OTHER` — **révoqué**** · Lot 3 mobile
- Contexte : l'agent mobile avait choisi `OTHER` par défaut quand une offre ne connaît pas son CTA.
- Options : `OTHER` ; aucune intention.
- Choix : **Révoqué par l'orchestrateur** : un `OTHER` fabriqué rangerait à tort un achat du Plan en `OTHER_CTA`. Parité web : CTA inconnu → aucune intention → `UNKNOWN`.
- Fichiers : `paywall_sheet.dart`, `premium_lock.dart`, `paywall_screen.dart`, `start_failure.dart`.
- Difficulté de retour : faible.

**D71 — Cycle de vie de l'intention d'achat** · Lot 3 mobile
- Contexte : Q12.
- Options : —
- Choix : ancienne intention du même produit effacée ; nouvelle créée (délai max 4 s) et enregistrée par SKU avant la feuille du store ; tout échec ouvre quand même l'achat ; effacée seulement après la vérification réussie d'un achat réellement nouveau (pas d'une transaction restaurée) ; purge à 7 j ; `appAccountToken` / `obfuscated*` intacts.
- Fichiers : `billing_controller.dart`, `purchase_intent_store.dart`, `billing_repository.dart`, `billing_models.dart`.
- Difficulté de retour : faible.

**D72 — `PLAN_OPENED` une fois par ouverture, Plan affiché connu** · Lot 3 mobile
- Contexte : l'événement partait au montage, avant de savoir quel parcours était affiché.
- Options : —
- Choix : émis une fois par ouverture, onglet TCF / civique connu, `journeyId` lu en cache ; sans parcours chargé, il part sans contexte.
- Fichiers : `plan_screen.dart`.
- Difficulté de retour : faible.

**D73 — Parité web** · Lot 3 mobile
- Contexte : arbitrage orchestrateur après le lot 3 web.
- Options : —
- Choix : événements du Plan en `journeyId` seul (D56) ; `PLAN_UNLOCK_CLICKED` sur le bouton à prix ; toute offre du Plan transmet `LOCKED_PLAN` + `journeyId` (y compris sur un 403) ; même politique de lots ; l'auth envoie la run invitée la plus récente au jeton valide, conservé pour le lot 3b ; `DIAGNOSTIC_REPORT_VIEWED` aussi sur le résultat du TCF complet.
- Fichiers : commits `f0031a2c` et suivant.
- Difficulté de retour : faible.

**D74 — Parcours → run fondatrice dans une vue SQL (V075)** · Lot 4 backend
- Contexte : la règle avait deux lecteurs (`purchase_intent` pour un parcours, étapes 5–6 du tunnel pour beaucoup) et la copie du lot 2b divergeait déjà (départage différent).
- Options : seconde copie SQL ; résolution Java par événement (N+1) ; vue.
- Choix : `v_journey_founding_run`, lue par `findFoundingRun` et par `SuiviReadRepository` : une règle, une autorité. La copie 2b (D31) est supprimée. Les événements du Plan passent par le parcours, sinon par la run qu'ils portent.
- Fichiers : `V075__vue_run_fondatrice_parcours.sql`, `DiagnosticRunRepository`, `SuiviReadRepository`, `PurchaseIntentService`.
- Difficulté de retour : faible.

**D75 — Dates de mesure injectées dans le calcul** · Lot 4 backend
- Contexte : la config de production laisse les dates à `null` jusqu'au déploiement (D43) : un test qui la lit ne verrait que `null`.
- Options : config de test sur le classpath ; contexte Spring séparé ; paramètre.
- Choix : `SuiviService.compute(query, starts)` : les scénarios passent 2020-01-01, `AdminSuiviControllerIT` vérifie la config réelle.
- Fichiers : `SuiviService`, `SuiviScenariosIT`.
- Difficulté de retour : faible.

**D76 — Ce qu'une mesure manquante annule** · Lot 4 backend
- Contexte : D43 dit « non mesuré = `null` » sans dire comment cela se propage dans un tunnel séquentiel ou un filtre plateforme.
- Options : annuler l'étape seule ; l'étape et les suivantes.
- Choix : une étape non mesurée annule elle-même et toutes les suivantes. Un filtre iOS / Android exige aussi `SIGNUP_PLATFORM_DETAIL` pour visiteurs, sources et inscriptions (sinon faux 0). Une somme mesurée et vide vaut 0.
- Fichiers : `SuiviMapper`.
- Difficulté de retour : faible.

**D77 — Règles de type, de source et de personne à la lecture** · Lot 4 backend
- Contexte : le brief ne dit pas comment typer un achat, quelle source a une personne, ni comment compter « Tous ».
- Options : deviner ; laisser inconnu.
- Choix : type d'achat : run attribuée, sinon module du parcours, sinon Civique pour un pass Civique seul ; un pass Intégral non attribué n'a pas de type (compté sous « Tous » seulement). `FULL_TCF` exclu de tout indicateur. Source : first-touch déclaré (visiteur de la run → visiteur d'inscription → plus ancien visiteur lié → `signup_source`), groupé par la config ; sans source → « Toutes » seulement, jamais « autre ». Le filtre type ne s'applique ni aux visiteurs, ni aux sources, ni aux inscriptions, ni au bloc par type. Sous « Tous », les 3 sous-lignes de « Compte rattaché » sont comptées par priorité (déjà connecté → inscrit après → connecté après) et somment l'étape 3.
- Fichiers : `SuiviReadRepository`, `SuiviMapper`.
- Difficulté de retour : moyenne.

**D78 — Sommes partielles signalées, pas effacées** · Lot 4 backend
- Contexte : un achat sans décomposition (ex. devise sans taux) rend les sommes incomplètes.
- Options : `null` pour tout le total ; somme partielle signalée.
- Choix : sommes sur les achats à décomposition connue, et `purchasesWithoutBreakdown` / `cohortPurchasesWithoutBreakdown` servis à côté (l'écran affiche une note).
- Fichiers : `SuiviReadRepository`, `SuiviMapper`.
- Difficulté de retour : faible.

**D79 — Ancien backend de lecture supprimé, restes compris** · Lot 4 backend
- Contexte : Q9/Q10.
- Options : garder `RepartitionArrondie` et les annotations (l'audit §6.2 le suggérait) ; supprimer.
- Choix : supprimés (plus aucun appelant) : `AdminAnalyticsController/Service`, `AnalyticsReadManager/Repository`, `AdminAnalyticsResponse`, `AnalyticsInsightsBuilder`, `AnalyticsCalculs`, `AnalyticsGrain`, `AnalyticsLibelles`, `RepartitionArrondie`, annotations, 8 classes de test ; tables conservées ; 404 verrouillé. `GeoIpCountryResolver` reste (l'ingestion l'utilise), bien que plus rien ne lise le pays : point ouvert.
- Fichiers : voir commit `e708af0f`.
- Difficulté de retour : faible (git).

**D80 — Retours du lot 3 web appliqués** · Lot 4 backend
- Contexte : écarts 1, 2, 3, 5 remontés par le web.
- Options : —
- Choix : champs de first-touch illisibles → `null`, lot accepté ; une enveloppe valide enregistre le visiteur et son first-touch même si tous les événements sont rejetés ; `sessionId` reste requis (colonne `NOT NULL`, un id serveur ferait de chaque lot une visite) ; `LOCKED_PLAN` sans run fondatrice → `UNKNOWN` (remplace en partie D32, applique D63).
- Fichiers : `AnalyticsEventNormalizer`, `AnalyticsBatchIngestionService`, `PurchaseIntentService`, `PurchaseOrigin`, tests associés.
- Difficulté de retour : faible.

**D81 — Pas de cache** · Lot 4 backend
- Contexte : l'ancien dashboard mettait sa lecture en cache 60 s.
- Options : cache ; pas de cache.
- Choix : pas de cache : 6 requêtes fixes (verrouillé par `SuiviPerformanceIT`), ≈ 160 ms sur un mois réaliste (3 000 comptes, 40 000 événements, 6 000 runs, 900 achats) — pas de vue matérialisée.
- Fichiers : `SuiviService`.
- Difficulté de retour : faible.

---

## 3. Récapitulatif final

_(rempli en fin de chantier : lots livrés, état des 20 scénarios, points ouverts, actions du
propriétaire)_
