# Audit du dashboard « Suivi » en production — 2026-09-29

Demandé par le propriétaire. But : **chaque chiffre affiché sur `/dashboard` doit être vrai.**
Pour chaque indicateur, on a vérifié quatre choses :

1. **La collecte** : ce qui l'alimente, où et quand.
2. **Le calcul** en base.
3. **Le libellé** affiché.
4. **Le recalcul** à la main, en SQL, sur la base de production.

- **Relevé** : le 29/09/2026 à 11 h 51 (heure de Paris).
- **API** : `GET https://api.sejourfr.fr/api/admin/analytics/suivi`, comptes internes exclus,
  aucun filtre. Périodes interrogées : `TODAY`, `YESTERDAY`, `LAST_7_DAYS`, `MONTH`, et la
  plage personnalisée `from=2026-09-28&to=2026-09-29`.
- **SQL** : `sejourfr_db_v2`, en lecture seule (`default_transaction_read_only`), fuseau
  `Europe/Paris`. Les requêtes ont été **réécrites indépendamment** de `SuiviReadRepository`,
  à partir des définitions de `docs/regles/mesure-audience.md` § « Lecture du dashboard
  Suivi ».
- **Correctifs** : ils sont sur la branche `feature/refonte-l1-socle`, **non déployés**. Les
  chiffres « API prod » du tableau sont donc ceux d'**avant** correctif.

## 1. Synthèse

- **Les chiffres de l'API correspondent au recalcul SQL, indicateur par indicateur**, pour
  Aujourd'hui, Hier et la plage 28 → 29/09 : **aucun écart de calcul.** Le fuseau, les bornes,
  l'exclusion des comptes internes, le dédoublonnage par personne et les dénominateurs sont
  justes.
- **Bug principal, corrigé** : « 7 jours » et « Mois » servaient `null` partout, soit des « — »
  à l'écran, alors que les 28 et 29/09 sont mesurés. Voir § 2.
- **Trois défauts d'affichage ou de lecture, corrigés** :
  - visiteurs sans source cachés : la somme des barres ne faisait pas le KPI ;
  - comptes de l'ancienne application rangés en source « direct » ;
  - libellé faux sur « Origine inconnue ».
- **Quatre défauts de collecte, corrigés** en parité web ⇄ mobile. Voir § 4.
- **Huit points relèvent d'un arbitrage produit.** Voir § 6. Les deux plus lourds :
  - le compte personnel du propriétaire n'est pas marqué interne ;
  - « % des diagnostics » rapporte des achats qui ne viennent pas des diagnostics.

## 2. Le bug « 7 jours » (corrigé, D117)

**Symptôme.** Avec « 7 jours » (23 → 29/09) ou « Mois » (01 → 29/09), l'API rendait `null`
pour tous les indicateurs, sauf `signups.total`, qui n'est pas affiché. L'écran ne montrait
donc que des « — ».

**Cause.** `SuiviMapper.Mesure.now()` jugeait un indicateur mesuré seulement si sa date de
début était **antérieure ou égale au premier jour** de la période. Avec toutes les dates au
28/09 (D116), toute période commençant avant le 28 rendait `null`, y compris pour les jours
réellement mesurés.

**Correctif** (commit `72657aeb`, décision D117 dans `decisions-suivi.md`) :

- **Borne basse de chaque lecture SQL.** La période courante est lue à partir de
  `max(début de période, date de début de ses indicateurs)` (`Mesure.since` →
  `SuiviReadManager.Debuts`). Aucun fait antérieur n'est compté : les 5 achats et le
  remboursement antérieurs au 28/09 restent exclus.
- **`null` réservé** aux périodes **entièrement** antérieures à la date, et aux indicateurs
  sans date.
- **Période précédente** : elle n'est lue que si elle est mesurée **de bout en bout**. Sinon,
  `previous` et `deltaPct` valent `null`, jamais un 0 inventé.
- **Garde sur les rapports** : un ratio (« % des visiteurs », « % des diagnostics ») ou le net
  après remboursements n'est servi que si ses deux termes sont mesurés depuis le **même** jour.
- **Tunnel** : une étape n'est mesurée que si sa date couvre **toute** la cohorte.
- **Admin** : les valeurs partielles portent la mention « mesuré depuis le 28/09 »
  (`measuredSinceNote`). Une période entièrement non mesurée affiche « mesuré à partir du
  JJ/MM ».
- **Tests** : `SuiviScenariosIT.periodeQuiChevaucheLeDebutDeMesure` et `debutsDeMesureDecales`,
  `AdminSuiviControllerIT.periodesQuiChevauchentLaMiseEnProduction`.

**Ce que « 7 jours » et « Mois » afficheront après déploiement**, recalculé en SQL :

- toutes les valeurs de la colonne « 28 → 29/09 » du tableau § 3, avec la mention « mesuré
  depuis le 28/09 » ;
- tendances à « — » ;
- `signups.total` : 249 en 7 jours et 1 037 sur le mois, puisque c'est un fait de `users`
  sans date de mesure.

## 3. Indicateur par indicateur

**Notations**

- **T** = Aujourd'hui (29/09), **H** = Hier (28/09), **R** = plage personnalisée 28 → 29/09,
  **7j** = 7 jours, **M** = Mois.
- « API prod » donne les valeurs servies avant correctif ; `null` s'affiche « — ».
- « SQL » donne le recalcul indépendant.

**Collecte commune**

- Événements web : `web_sejoufr/lib/analytics.ts`. Envoi en lot au bout de 4 s ou de 50
  événements, puis `sendBeacon` à la sortie de page.
- Événements mobile : `mobile_sejourfr/lib/core/analytics/analytics_queue.dart`. File
  `SharedPreferences`, rejouée toutes les 60 s et au retour au premier plan.
- Ingestion : `AnalyticsBatchIngestionService`, idempotente sur `event_id`. **Aucun doublon
  trouvé en prod** (0 couple « même visiteur, même événement, même seconde »).

| Indicateur (libellé écran) | Source et point de collecte | Moment | Requête (calcul) | API prod | SQL recalculé | Verdict |
|---|---|---|---|---|---|---|
| **Visiteurs uniques** (KPI) | `analytics_event.anonymous_id`. Web : `track()` (`analytics.ts`) ; mobile : `Analytics.track` (`analytics.dart`) | horloge client à la création de l'événement (`occurred_at`) ; lot envoyé plus tard | `anonymous_id` distincts ayant ≥ 1 événement dans la période ; exclus : `is_internal`, ou identifiant lié à un compte interne | T 24 · H 75 · 7j `null` · M `null` · R 95 | T 24 · H 75 · 7j 95 · M 95 · R 95 | **OK** pour T, H et R. **Bug corrigé** pour 7j et M. **À arbitrer** : ne compte que les écrans instrumentés (§ 6-A4) |
| Visiteurs, tendance | idem, période précédente | — | même requête sur `[prevFrom, from)` ; `null` si la période précédente n'est pas mesurée | T −68 % (24 contre 75) · H `null` (27/09 non mesuré) | 75 le 28/09 ; aucun événement avant le 28/09 00:14 | **OK** |
| **Diagnostics soumis** (KPI) | `diagnostic_run.submitted_at`. TCF rapide : client, au bouton d'analyse (`submitQuickTcfRun` web, `DiagnosticRunTracker.submitted` mobile). Civique : serveur, à la clôture | horloge serveur à l'appel « soumis » | runs `QUICK_TCF` ou `CIVIQUE` soumises dans la période ; civique retenu si ≥ 80 % de réponses ; personnes distinctes (`COALESCE(user, anon, run)`) | T 4 · H 7 · 7j/M `null` · R 11 | T 4 · H 7 · 7j/M 11 · R 11 (10 TCF, 1 civique à 40/40) | **OK**. **Bug corrigé** pour 7j et M |
| « % des visiteurs » | soumis / visiteurs | — | ratio servi, une décimale | T 16,7 · H 9,3 · R 11,6 | 4/24, 7/75, 11/95 | **OK** |
| **Achats** (KPI) | `user_subscriptions`. `purchased_at` = date du fournisseur (Stripe `event.created`, Apple JWS, Google `purchaseTimeMillis`), écrite par `OneTimeAccessService` | webhook ou vérification du reçu, dans la transaction qui ouvre l'accès | statut ≠ `PENDING`, remboursés inclus, comptes internes exclus | T 0 · H 2 · 7j/M `null` · R 2 | T 0 · H 2 (Google 9,99 € à 04:23 et 29,99 € à 21:39) · R 2. Avant le 28/09 : 5 achats en 7 jours, 13 sur le mois, tous sans montant (anciennes lignes) | **OK**. **Bug corrigé** pour 7j et M (2, « mesuré depuis le 28/09 ») |
| « % des diagnostics » | achats / soumis | — | ratio de deux comptes de la période | H 28,6 (2/7) · R 18,2 (2/11) | 2/7, 2/11 ; **aucun** des 2 achats ne vient du tunnel (origine `OTHER_CTA` et `UNKNOWN`) | Calcul **OK**, libellé trompeur : **à arbitrer** (§ 6-A2) |
| **Net réel estimé** (KPI, bloc Revenus) | `user_subscriptions.net_ex_vat_cents`, figé à l'écriture (`RevenueCalculator`) + `payment_refunds.net_ex_vat_delta_cents` | écriture de l'achat ou du remboursement | Σ net HT des achats de la période + Σ delta des remboursements datés dans la période | T 0 € · H 28,32 € · R 28,32 € | 7,08 € + 21,24 € = 28,32 € (Google : TVA 20 %, commission 15 % estimée) | **OK**. Taux store **à confirmer** (§ 6-A6) |
| Revenus : brut, TVA, frais, net, par canal | idem | idem | sommes des achats **décomposés** ; brut inconnu compté à part | H : brut 39,98 € · TVA 6,66 € · frais 5,00 € · net 28,32 € · Google 2 · frais estimés 2 | identique | **OK** |
| Remboursements | `payment_refunds` (webhooks Stripe, stores) | webhook | datés par `refunded_at` | 0 | table vide en prod | **OK**, non éprouvé en prod |
| **Tunnel**, étape 1 « Sujet vu » | `diagnostic_run.subject_viewed_at`, `POST /api/public/diagnostic-runs`. Web : `ensureDiagnosticRun` (écrit **ou** oral) ; mobile : `_trackStepReached` (**écrit seulement**, corrigé : écrit ou oral) | horloge serveur à la création | 1ʳᵉ run de la personne par type (toutes dates), sujet vu dans la période ; « Tous » = personnes distinctes | T 6 · H 31 · R 37 · 7j/M `null` | T 6 · H 31 · R 37 | **OK**. **Bug corrigé** pour 7j et M |
| Étape 2 « Soumis » | voir « Diagnostics soumis » | — | soumis retenu avant J+14 | T 3 · H 8 · R 11 | T 3 · H 8 · R 11 | **OK** |
| Étape 3 « Compte rattaché » et ses 3 sous-lignes | `submitted_authenticated`, ou claim (`claimed_at`, `claim_kind`) posé dans la transaction d'authentification | à l'authentification | soumis connecté, ou claim avant J+14 ; sous-lignes par priorité | T 2 (inscrits après 2) · H 8 (8) · R 10 (10), « déjà connectés » 0, « connectés après » 0 | identique ; 10 claims `SIGNUP`, 0 soumis connecté | **OK** |
| Étape 4 « Rapport vu » | `DIAGNOSTIC_REPORT_VIEWED` portant la run (web `diagnostic-run.ts`, mobile `diagnostic_screen.dart`) | à l'affichage du rapport, une fois | premier événement sur la run, avant J+14 | T 2 · H 8 · R 10 | identique (10 événements, tous avec leur run) | **OK** |
| Étape 5 « Plan consulté » | `PLAN_OPENED`, rattaché par `journey_id` → `v_journey_founding_run` | à l'ouverture du Plan | idem | T 2 · H 6 · R 8 | identique ; seuls 17 `PLAN_OPENED` sur 124 remontent à une run (les autres viennent de comptes sans diagnostic) | **OK** |
| Étape 6 « Débloquer » | `PLAN_UNLOCK_CLICKED` (`PlanUnlockScreen.tsx`, `plan_unlock_screen.dart`) | au clic | idem | T 2 · H 2 · R 4 | identique | **OK** |
| Étape 7 « Achat » et CA net de la cohorte | achat attribué à la run (`origin = DIAGNOSTIC_PLAN`, par `purchase_intent`) | à la création de la session d'achat, puis au paiement | achat de la run avant J+14 | 0 · 0 € | 0 : les 2 intentions `LOCKED_PLAN` du 28/09 à 21:52 et du 29/09 à 10:36 n'ont pas été payées | **OK** |
| « Runs sans identifiant » | runs sans `user_id` ni `anonymous_id` | — | — | 0 | 0 | **OK** |
| **Ratios** | tunnel | — | 2/1, inscrits / soumis anonymes, 4/3, 5/4, 6/5, 7/6, 7/2, net / 2 | R : 29,7 · 90,9 · 100 · 80 · 50 · 0 · 0 · 0 € | 11/37 · 10/11 · 10/10 · 8/10 · 4/8 · 0/4 · 0/11 | **OK** |
| **Diagnostic par type** | tunnel, étapes 1, 2 et 7 | — | colonnes TCF (`QUICK_TCF`) et Civique | R : TCF 34 / 10 / 0 · Civique 6 / 1 / 0 | identique ; le total « Tous » vaut 37 (3 personnes ont fait les deux) | **OK** |
| **Inscriptions** : après, hors, origine inconnue | `users.signup_context`, posé par `SignupAttribution` à la création (local, Google, Apple) | dans la transaction d'inscription | comptes créés dans la période, non supprimés, non internes | T 3 / 5 / 6 · H 7 / 8 / 27 · R 10 (9 TCF, 1 civique) / 13 / 33 | identique | Calcul **OK**. **Libellé faux corrigé** : les 33 « origine inconnue » ne sont pas des comptes antérieurs, ce sont des inscriptions de l'ancienne application (Google 25, Apple 6, local 2) |
| Inscriptions par plateforme | `users.signup_platform`, lu dans `X-Sejourfr-Client` | à la création | idem | R : web 10 · iOS 7 · Android 6 · non déclarée 33 | identique | **OK**. 33 comptes sur 56 en `UNKNOWN` : l'app publiée n'envoie aucun en-tête (§ 5) |
| Connexions après diagnostic | claim `LOGIN` dans la période | à l'authentification | comptes distincts | H 1 · R 1 | 1 | **OK** |
| **Sources d'acquisition** | `analytics_visitor.ft_source_raw` (web : `utm_source` → `src` → hôte du référent → `direct`) ; mobile : toujours vide | premier lot accepté du visiteur | visiteurs de la période par groupe (`utmSourceGroups`) | T : instagram 1 · tiktok 6 · facebook 0 · direct 2 · autre 8 (somme 17 pour 24 visiteurs) | T : + **7 inconnue** (app) ; « autre » = www.google.com 6, Gmail 1, recherche Google Android 1. R : tiktok 24, direct 21, **autre 31 (Google 22, Gmail 8, …)**, **inconnue 18** | **Bug corrigé** : les visiteurs sans source étaient cachés, ils sont désormais servis et affichés « Inconnue ». Groupes : **à arbitrer** (§ 6-A3) |
| Source d'un compte (filtre Source du tunnel, des achats, des inscriptions) | visiteur de la run → visiteur d'inscription → plus ancien visiteur lié → `users.signup_source` | — | `SOURCE_INSCRIPTION` | un compte `UNKNOWN` / `direct` était rangé en « direct » | 33 comptes et l'achat de 29,99 € du 28/09 concernés | **Bug corrigé** : plateforme non déclarée sans provenance = source inconnue |
| **Activité** : soumis bruts, achats par origine, soumis anonymes jamais rattachés | voir ci-dessus | — | runs soumises (toutes) ; origine de l'achat ; soumis anonymes sans claim à J+14 | R : 11 bruts (11 en 1ʳᵉ tentative) · Plan 0 / autre CTA 1 / inconnue 1 · 1 jamais rattaché (29/09 08:56, en cours) | identique | **OK** |

**Requêtes de recalcul.** Elles vivent dans le carnet de session et ont été lancées en une
seule connexion SSH. Elles reprennent les définitions de `mesure-audience.md` :

- **Visiteurs** : `count(DISTINCT anonymous_id)` sur `analytics_event`, hors
  `is_internal` et hors identifiants liés à un compte interne.
- **Soumis** : `diagnostic_run` avec le seuil civique de 80 %.
- **Tunnel** : 1ʳᵉ run par `(personne, type)`, puis les étapes 2 à 7 bornées à
  `subject_viewed_at + 14 j`, en `bool_or` par personne pour « Tous ».
- **Achats** : `user_subscriptions`, statut ≠ `PENDING`, par `purchased_at`.
- **Inscriptions** : `users.created_at`, `deleted_at IS NULL`, `NOT is_internal`.

## 4. Correctifs (branche `feature/refonte-l1-socle`, non poussée)

| # | Sujet | Commit | Surfaces |
|---|---|---|---|
| 1 | « 7 jours » et « Mois » servis depuis la date de début de mesure (D117) | `72657aeb` | backend, admin, docs |
| 2 | compte sans plateforme déclarée : source inconnue, plus « direct » | `346c2c9e` | backend |
| 3 | visiteurs sans source servis (`unknownSourceVisitors`) et affichés « Inconnue » | `fa4f63d8` | backend (DTO), admin |
| 4 | libellé « Origine inconnue » corrigé | `c0ec083c` | admin, javadoc, docs |
| 5 | mobile : identifiant de mesure tiré deux fois au premier lancement (concurrence) | `693ca2c8` | mobile |
| 6 | web : le lot d'événements porte le jeton du compte (0 événement web sur 431 portait un compte, contre 97 % sur mobile) | `ab1f18f2` | web |
| 7 | mobile : « sujet vu » aussi quand le passage reprend à l'oral (le web le faisait déjà) | `4556d3d8` | mobile |
| 8 | web : « soumis » recrée la run manquante, comme le mobile | `0916ac01` | web |

## 5. Collecte : trous et risques

1. **L'application publiée ne mesure rien.** En prod, aucun événement `MOBILE` et aucun reçu
   par l'endpoint unitaire (`event_id IS NULL` = 0) ; tous les événements natifs viennent des
   versions `0.1.3` / `0.1.4`. Ses connexions Google / Apple s'inscrivent `UNKNOWN`, sans
   contexte ni source : **33 des 56 comptes** créés les 28 et 29/09. Tant qu'elle circule,
   « Origine inconnue » et « plateforme non déclarée » resteront élevés. Levier : la version
   minimale (`APP_MIN_VERSION_*`, § 6-A8).
2. **« Visiteurs uniques » ne compte que les écrans instrumentés.** Ce sont l'accueil public,
   `/reussir`, le diagnostic, le Plan, le paiement, la connexion et le paywall. L'accueil de
   l'app, l'entraînement et les examens blancs n'émettent rien : un candidat qui s'entraîne
   sans passer par ces écrans n'est **jamais** visiteur. Le KPI et « % des visiteurs » sont
   donc biaisés (§ 6-A4).
3. **Provenance mobile toujours inconnue** : `AnalyticsTrafficSource.remember` n'est appelé
   nulle part, et il n'y a ni deep link ni install referrer. Cela représente 18 visiteurs sur
   95 depuis le 28/09. Limite documentée ; elle est désormais **visible** (ligne
   « Inconnue »).
4. **Liens des e-mails sans UTM** : les clics depuis Gmail arrivent avec le référent
   `com.google.android.gm` et tombent dans « autre » (8 visiteurs). La recherche Google
   organique y tombe aussi (22). Plus de la moitié de « autre » est donc Google.
5. **Le lien identité ne se pose qu'à la connexion**, pas au rafraîchissement du jeton. Un
   compte resté connecté depuis avant le 28/09 n'a aucun lien `analytics_identity`. Sur le
   web, c'est désormais compensé par le jeton joint au lot (correctif 6). Sur les deux
   fronts, ce compte garde la source `signup_source`.
6. **Lots perdus sans bruit** : un 400 (web) ou un autre 4xx (mobile) abandonne le lot. Le
   repli `fetch` de sortie du web part en `application/json`, ce qui déclenche une
   pré-vérification CORS pendant le déchargement : il est peu fiable, mais c'est `sendBeacon`
   qui passe en premier. Sans `localStorage`, le web ne mesure rien.
7. **Mobile, `PLAN_OPENED`** : l'événement est perdu si l'écran est quitté avant la lecture du
   parcours (délai de 10 s). Sans effet sur le tunnel, qui ne lit que la première ouverture.
8. **Offres ouvertes sur un 403 sans CTA** (D70) : aucune intention n'est créée, donc l'achat
   est `UNKNOWN`. C'est le cas de l'achat de 29,99 € du 28/09, fait depuis l'ancienne app.
9. **Clics Premium sans intention** : 31 `PREMIUM_CTA_CLICKED` Android (6 visiteurs) pour
   1 seule `purchase_intent`. Cohérent avec un paywall affiché puis abandonné, mais à
   surveiller.

## 6. À arbitrer

- **A1 — Le compte personnel du propriétaire n'est pas interne.** Il pèse 4 visiteurs sur 75
  le 28/09 et 1 sur 24 le 29/09 (web, iOS, Android), plus des `PLAN_OPENED`. Seuls les 3
  comptes seed `@sejourfr.fr` sont `is_internal`.
  **Recommandation** : `UPDATE users SET is_internal = true WHERE email = '<ton adresse>';`,
  ainsi que tes comptes de test éventuels (5 autres comptes à préfixe proche, sans activité
  depuis le 28/09).
- **A2 — « % des diagnostics » sous « Achats ».** C'est achats de la période ÷ diagnostics
  soumis de la période. Hier, l'écran affichait 28,6 % alors qu'**aucun** achat ne venait d'un
  diagnostic.
  **Recommandation** : remplacer par la conversion de la cohorte (7/2, déjà servie), ou
  renommer en « pour 100 diagnostics soumis ».
- **A3 — Groupes de sources.**
  **Recommandation** :
  - ajouter un groupe `google` (`www.google.com`, `com.google.android.googlequicksearchbox`) ;
  - ajouter un groupe `email` (`com.google.android.gm`, `email`) ;
  - poser `utm_source=email&utm_campaign=<campagne>` sur les liens des e-mails.

  Les groupes relèvent de la configuration, réversible et sans migration ; les UTM relèvent
  des gabarits d'e-mails.
- **A4 — « Visiteurs uniques ».**
  **Recommandation** : un événement d'ouverture d'écran ou d'application, émis une fois par
  session, web et mobile. À défaut, renommer en « Visiteurs des écrans suivis ».
- **A5 — Achats antérieurs au 28/09.** « 7 jours » en affichera 2, alors que 7 achats réels
  existent : 5 antérieurs, sans montant (colonnes nulles, aucune rétro-migration).
  **Recommandation** : garder `PURCHASES` au 28/09. Un nombre d'achats sans brut ni origine ne
  se compare à rien.
- **A6 — Commission Apple / Google à 15 %.** Toujours provisoire ; les 2 achats Google ont des
  frais `ESTIMATED`. Point déjà ouvert.
- **A7 — `signups.total` servi mais non affiché.** 249 comptes en 7 jours et 1 037 sur le mois,
  dont seuls ceux créés depuis le 28/09 sont ventilés.
  **Recommandation** : afficher « N comptes créés », puis la ventilation « mesurée depuis le
  28/09 ».
- **A8 — Ancienne application.**
  **Recommandation** : poser `APP_MIN_VERSION_IOS` / `APP_MIN_VERSION_ANDROID` à `0.1.3` dès
  que l'adoption le permet. Tant que l'ancienne app circule, 6 inscriptions sur 10 échappent
  au contexte et à la plateforme.
