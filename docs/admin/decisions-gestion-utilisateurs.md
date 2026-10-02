# Décisions — Admin / Gestion des utilisateurs (phase 2 : backend, migrations, tests ; phase 3 : front admin)

> Mode autonome (GO du propriétaire du 2026-10-02, §19). Sources : `spec-admin-utilisateurs-v2.md`,
> `audit-admin-utilisateurs.md`, GO du propriétaire (prime sur les deux). Chaque décision suit le
> format demandé ; elles sont classées par importance.
> Branche `develop`, rien de poussé ni déployé. Règle résultante : `docs/regles/paiements.md`
> § « Accès effectif = achats + décisions admin ».

## Bloquant — décision requise

### B-1 — Simulations orales temps réel d'un Intégral ACCORDÉ sans achat Intégral (GO §7)

- **Constat vérifié dans le code** : un achat Intégral reçoit `plans.realtime_eo_sessions`
  sessions (5 pour 7 j, 15 pour 1 mois, 25 pour 2 mois ; Civique 0), posées sur **sa ligne**
  `user_subscriptions.realtime_eo_sessions_remaining` (`OneTimeAccessService`), débitées par
  `UserSubscriptionManager.decrementRealtimeSessions` sur la ligne référencée par
  `realtime_sessions.subscription_id`. Les sessions font donc fonctionnellement partie du pass
  Intégral, et c'est la seule ressource qui distingue deux pass Intégral.
- **Ce qui est livré** : le quota lit l'achat Intégral « qui compte » de l'accès EFFECTIF. Un achat
  révoqué ne laisse plus consommer ; un GRANT qui prolonge un achat Intégral encore couvrant garde
  le solde de cet achat. Mais un **GRANT Intégral sans achat Intégral couvrant** (ex. correction
  Civique → Intégral, ou geste sur un compte gratuit) n'a **aucune ligne porteuse ⇒ 0 session**
  (l'épreuve EO bascule en mode asynchrone, jamais bloquée). C'est un Intégral dégradé.
- **Pourquoi non écrit** : donner le même droit exige de stocker un solde hors
  `user_subscriptions` ET de faire débiter ce solde — soit une colonne de solde sur
  `access_overrides` + une seconde cible de débit (`realtime_sessions` devrait référencer
  l'override), soit une table-ledger de quota. C'est une évolution structurelle hors des deux
  tables prévues, que le GO §7 demande de signaler avant de l'écrire.
- **Options** :
  1. Laisser tel quel (GRANT nu = 0 session), l'admin ne pouvant compenser que sur une ligne d'achat
     existante (`PATCH /api/admin/subscriptions/{id}/realtime-sessions`).
  2. Ledger unique de quota : nouvelle table `realtime_quota_credit` (crédit par achat OU par
     GRANT, avec son nombre) ; `RealtimeQuotaService` devient la seule autorité qui somme crédits et
     débits, `decrementRealtimeSessions` est remplacé par une écriture de débit. Une autorité, mais
     migration de données (reprise des soldes) et touche au débit existant.
  3. Colonne `realtime_eo_sessions_remaining` sur `access_overrides` (solde choisi dans la modale
     GRANT Intégral) + `realtime_sessions.access_override_id` ; le débit cible l'un OU l'autre —
     deux cibles de débit, ce que le GO demande d'éviter.
- **Recommandation** : 2 si l'Intégral accordé doit être strictement équivalent ; 1 sinon.

## À relire en priorité

Touchent le schéma, les DTO lus par le mobile, le calcul d'accès effectif, les flux d'achat ou les
emails : **D-01, D-02, D-03, D-04, D-05, D-06, D-07, D-08, D-09, D-10.**

---

### D-01 — Modèle des décisions : fenêtres non chevauchantes tenues par EXCLUDE gist

- **Contexte** : spec §2.2 (« un override courant par (user, produit) ») vs GO §4 et §18 (décision
  active + décision programmée, troncature, non-chevauchement).
- **Options envisagées** : (a) index unique partiel « un courant » (audit D.2) — interdit de
  programmer ; (b) contrainte d'EXCLUSION gist sur `(user_id, product, tstzrange(starts_at,
  ends_at,'[)'))` des lignes courantes ; (c) contrôle Java sous verrou.
- **Choix retenu** : (b), plus le verrou consultatif par compte (G-11) en amont. Colonnes
  ajoutées à la proposition de l'audit : `decided_at` (instant de la décision d'origine, copié sur
  une copie tronquée — c'est lui que lit « achat postérieur au REVOKE », sinon une troncature
  rendrait « antérieur » un rachat légitime), `replaces_override_id` (lignée d'une copie),
  `superseded_by_operation_id` (FK vers le journal, posée AVANT l'insertion : plus besoin de FK
  différée). Supersessions flushées avant insertions (contrainte immédiate).
  `btree_gist` vérifiée présente dans les binaires Zonky darwin-arm64 et linux-amd64 et en local.
- **Impact** : `V083__schema_acces_admin.sql` (2 tables, 1 extension, 0 donnée), entités
  `AccessOverride`, `AdminAccessOperation`. Tests : `AccesAdminSchemaIT`, `AdminUserControllerIT.exclusionEnBase`.
- **Réversibilité** : moyenne — passer au contrôle Java = retirer la contrainte (migration additive
  `DROP CONSTRAINT` dans une nouvelle version) et garder le verrou.

### D-02 — Troncature : la queue d'un REVOKE survit à un GRANT, la queue d'un GRANT jamais

- **Contexte** : GO §18 (« tronque à new.starts_at », « un REVOKE à fin ouverte est tronqué de la
  même façon par tout GRANT ultérieur ») ne dit pas ce qui suit la fin du nouveau GRANT.
- **Options envisagées** : (a) la nouvelle décision remplace tout à partir de son début (après un
  GRANT de réactivation, l'achat révoqué redevient valide) ; (b) la part d'un REVOKE au-delà de la
  fin du GRANT est réinsérée ; celle d'un GRANT jamais.
- **Choix retenu** : (b) — sûr : un achat révoqué (fraude, erreur) ne « revient » pas tout seul à
  la fin d'un geste admin, même esprit que « le reliquat n'est pas restitué » (GO §18). La queue
  d'un GRANT est abandonnée, sinon « Raccourcir un GRANT » ne raccourcirait rien. Un rachat
  postérieur au REVOKE rouvre toujours l'accès.
- **Impact** : `AccessOverridePlanner` (pur ; même plan pour l'aperçu et l'écriture).
  `AccessOverridePlannerTest`.
- **Réversibilité** : facile — une branche du planner.

### D-03 — Traduction des actions en décisions

- **Contexte** : spec §2.6, GO §5 / §18.
- **Options envisagées** : (a) tableau §2.6 tel quel (nouveau GRANT pour raccourcir un GRANT,
  REVOKE pour raccourcir un achat) ; (b) une traduction unique par action.
- **Choix retenu** : (b). Donner / Réactiver = `GRANT [début, fin+1j)` ; Prolonger =
  `GRANT [maintenant, fin+1j)` (la nouvelle fin doit dépasser la fin effective) ; Raccourcir =
  `REVOKE [fin+1j, ∅)` pour un achat comme pour un GRANT (le GRANT recouvert est tronqué : même
  résultat que §2.6, et un achat qui court au-delà est bien coupé) ; Terminer = `REVOKE
  [maintenant, ∅)` (accepté aussi sur un accès Programmé : l'annule) ; Corriger A → B = `REVOKE A
  [maintenant, ∅)` + `GRANT B [maintenant, fin+1j)`, un `operation_id`, sans le 409 « Civique via
  Intégral » (GO §5), dans les deux sens (Civique ↔ Intégral). « Donner » est accepté quel que
  soit le statut (c'est l'action qui programme une décision future, GO §4). Fin obligatoire pour
  Donner, Réactiver, Prolonger, Raccourcir et Corriger (le front pré-remplit la fin de A, servie).
  Préconditions refusées en 409, exactement celles servies dans `availableOperations`.
- **Impact** : `AdminAccessOperationService`, `OperationsDisponibles`. Tests :
  `AdminAccessOperationServiceTest`, `AdminUserControllerIT`.
- **Réversibilité** : facile.

### D-04 — `subscription-status` / `verify-receipt` construits sur l'accès effectif (DTO lus par le mobile)

- **Contexte** : audit A.4/C.4 et GO §16 : `/me` et `subscription-status` doivent lire le même
  accès (le mobile écrase l'un par l'autre).
- **Options envisagées** : (a) garder la ligne d'achat ; (b) même DTO rempli depuis l'accès
  effectif ; (c) champ additif `accessOrigin` (refusé par GO §6).
- **Choix retenu** : (b), une seule construction (`SubscriptionStatusService`) pour les deux
  endpoints. `moduleAccess` et `expiresAt` = accès effectif ; `source`, `productId`, `status`,
  `autoRenew`, `oneTime` = achat qui compte de ce module ; sans achat de ce module (GRANT) :
  `source`/`productId` absents, `ACTIVE`, `autoRenew=false`, `oneTime=true`. Aucune valeur
  nouvelle. Sans décision : réponse identique, prouvée par `AccesEffectifNonRegressionIT` (arbres
  JSON complets contre une copie figée du calcul d'avant, 10 scénarios d'achats).
- **Impact** : `BillingController`, `ReceiptVerificationService`, `SubscriptionStatusResponse.from(module,
  expiresAt, achat)`. ⚠️ Changement de comportement (pas de forme) côté mobile pour un compte
  sous décision : `expiresAt` = fin effective (ex. fin du GRANT qui prolonge un achat).
- **Réversibilité** : facile côté code ; mais **le déploiement doit être annoncé au propriétaire**
  (surface lue par le mobile).

### D-05 — `currentSubscription` devient effectif ; `currentPurchase` pour résilier / supprimer

- **Contexte** : audit A.4 (7 appelants lisant une ligne d'achat).
- **Options envisagées** : (a) un seul `currentSubscription` effectif partout ; (b) effectif pour
  l'accès, achat brut pour les gestes sur l'achat.
- **Choix retenu** : (b). Effectif : statut, reçus, quota EO, proration, report du solde EO.
  Achat brut (`currentPurchase`) : `SubscriptionCancellationService` et `AccountDeletionService`
  — un REVOKE admin ne doit jamais empêcher de couper un renouvellement (G-12).
- **Impact** : `SubscriptionService` (règle déléguée à `AccesEffectifResolver`, départage
  historique `meilleurQue` déplacé dans le resolver, une seule copie).
- **Réversibilité** : facile.

### D-06 — G-5 : base de prolongation sur la fin effective, ligne d'achat inchangée

- **Contexte** : GO §8, ligne rouge « ne pas modifier la ligne d'achat au-delà de la valeur de fin
  qu'elle calcule déjà ».
- **Options envisagées** : (a) achats seuls ; (b) fin effective (lecture des décisions) ; (c)
  maintenant dès qu'une décision existe.
- **Choix retenu** : (b) via `currentEndForAtLeast`, réécrit sur l'accès effectif. La ligne
  écrite reste la même (`starts_at = now`, `ends_at = base + durée`) : seule la base change.
  Report du solde EO : depuis l'achat qui compte de l'accès effectif (un achat révoqué ne reporte
  rien). Aucun blocage rencontré.
- **Impact** : `OneTimeAccessService` (commentaire seulement), `OverrideEtAchatsIT`
  (`cas7RachatApresRevoke`, `g5AchatPendantUnGrant`).
- **Réversibilité** : facile.

### D-07 — Proration Stripe Civique → Intégral : seul un Civique effectif est crédité

- **Contexte** : audit C.4 / G-5 (`BillingService.computeOneTimeAmountCents`).
- **Options envisagées** : (a) créditer le Civique acheté même révoqué ; (b) ne créditer qu'un
  Civique effectif.
- **Choix retenu** : (b), automatiquement via `currentSubscription` effectif. Conséquence : un
  compte avec Civique acheté + GRANT Intégral voit le module effectif Intégral et paie un Intégral
  plein tarif (qui prolonge depuis la fin du GRANT).
- **Impact** : comportement de prix, Stripe seulement. Code inchangé.
- **Réversibilité** : facile (lire `currentPurchase` dans la proration).

### D-08 — Quota EO temps réel sur l'achat qui compte de l'accès effectif

- **Contexte** : GO §7 ; voir **B-1**.
- **Options envisagées** : voir B-1.
- **Choix retenu** : la part réalisable sans évolution structurelle (une seule autorité de quota,
  débit inchangé) ; le reste est bloquant.
- **Impact** : `RealtimeQuotaService` (code inchangé, sémantique effective), tests
  `quotaApresRevoke`, `quotaGrantSurAchatIntegral`.
- **Réversibilité** : facile.

### D-09 — Emails G-6 : exclusion des comptes sous décision courante

- **Contexte** : GO §9, option 1.
- **Options envisagées** : (a) exclure les comptes ayant une décision non terminée ; (b) toute
  décision courante (non remplacée), même passée ; (c) rebrancher le moteur sur l'accès effectif.
- **Choix retenu** : (b), en SQL (`NOT EXISTS access_overrides … superseded_at IS NULL`) dans les
  trois requêtes des scénarios fondés sur les achats : `NO_PREMIUM_AFTER_7_DAYS`,
  `PREMIUM_INACTIVE_2_DAYS`, `PREMIUM_ENDING_7/2_DAYS`, `PREMIUM_ENDED`. Plus simple et plus sûr :
  un compte qui a connu un geste admin ne reçoit plus de relance « commerciale » fausse ;
  `NO_TRAINING_7_DAYS` (inactivité, pas d'achat) reste envoyé.
- **Impact** : `EmailScenarioRepository` ; `EmailOverrideExclusionIT`.
- **Réversibilité** : facile.

### D-10 — Production : l'extension `btree_gist` doit être autorisée

- **Contexte** : V083 fait `CREATE EXTENSION IF NOT EXISTS btree_gist`.
- **Options envisagées** : (a) extension ; (b) contrôle Java seul.
- **Choix retenu** : (a). Extension contrib standard, « trusted » depuis PostgreSQL 13 : le
  propriétaire de la base peut la créer. **Action propriétaire avant déploiement** : vérifier en
  prod `SELECT * FROM pg_available_extensions WHERE name = 'btree_gist';` (paquet
  `postgresql-contrib` présent) et que l'utilisateur Flyway possède la base ; sinon la créer une
  fois en superutilisateur. Sans cela, V083 échoue au démarrage (aucune donnée touchée).
- **Impact** : déploiement.
- **Réversibilité** : moyenne (voir D-01).

### D-11 — État attendu (G-11) : empreinte des décisions + achats, obligatoire pour écrire

- **Contexte** : GO §14 ; spec §8.
- **Options envisagées** : (a) `expectedCurrentOverrideId` (audit) — ne voit pas un webhook de
  remboursement ; (b) empreinte SHA-256 (16 hex) des décisions courantes et des achats (id,
  statut, fin, statut de paiement), servie `accessVersion`, renvoyée `expectedVersion`.
- **Choix retenu** : (b). Obligatoire si `dryRun=false` (400 sinon), facultatif en aperçu ;
  différent ⇒ 409 « L'accès de cet utilisateur a changé… ». Comparaison faite sous le verrou
  consultatif par compte.
- **Impact** : `VersionAcces`, `AdminAccessOperationService` ; `AdminUserControllerIT.g11EtatPerime`.
- **Réversibilité** : facile.

### D-12 — `AdminSubscriptionDto` : identifiants de paiement tronqués

- **Contexte** : audit A.12, spec §9.
- **Options envisagées** : (a) retirer les champs (casse le front admin) ; (b) les tronquer, même
  forme.
- **Choix retenu** : (b) `util/ReferenceExterne` (« 8 premiers…4 derniers », plus court pour une
  chaîne courte). Le front admin affiche la chaîne telle quelle (`SubscriptionsPage`), `tsc` OK ;
  type inchangé, commentaire ajouté dans `api.ts`.
- **Impact** : `UserSubscriptionMapper`, `UserSubscriptionMapperTest`. DTO admin seulement.
- **Réversibilité** : facile.

### D-13 — G-9 : dernière activité dans la liste (EXPLAIN local)

- **Contexte** : GO §12.
- **Options envisagées** : (a) colonne liste via la vue V073 ; (b) fiche seulement.
- **Choix retenu** : (a). `EXPLAIN ANALYZE` sur `sejourfr_db` (lecture seule) de
  `v_derniere_activite_entrainement WHERE user_id = ANY(25 ids)` : le prédicat est poussé dans
  les 4 branches de l'`UNION ALL` (avant l'agrégat) ; 47 ms à froid sur la base locale
  (2 526 réponses) ; avec `enable_seqscan=off`, chaque branche passe par son index
  (`idx_answer_user`, `idx_prod_sub_user_submitted`, `idx_user_skill_attempts_user_created`,
  `idx_rt_session_user_connected`). Coût borné par la page (≤ 100 comptes). Volume prod non
  mesuré : si un compte cumule beaucoup de réponses, la branche `answers` lit toutes ses lignes ;
  repli prévu : retirer la colonne de la liste (option 2) sans autre changement.
- **Impact** : `AdminUserReadRepository.findLastActivity`.
- **Réversibilité** : facile.

### D-14 — G-10 : progression lue en tables

- **Contexte** : GO §13.
- **Choix retenu** : par module (TCF puis Civique) : dernier diagnostic clos (TCF = rapide
  `diagnostic_sessions` ou complet `tcf_diagnostic_sessions` ; Civique =
  `civic_diagnostic_sessions`), cycle `EN_COURS` (statut, niveau d'entrée, palier / démarche
  visés, date, étapes closes / total), nombre de cycles `HISTORISE`. Aucun appel à
  `JourneyService.lire()`. Options écartées : DTO candidat (écrit), moteur de progression (coûteux).
- **Impact** : `AdminUserReadRepository` (3 requêtes natives).
- **Réversibilité** : facile.

### D-15 — Statuts par produit : ordre de priorité et alertes

- **Contexte** : spec §2.4 (les conditions peuvent se recouvrir).
- **Options envisagées** : Révoqué avant Programmé, ou l'inverse.
- **Choix retenu** : Actif > Programmé > Révoqué > Expiré > Aucun (un GRANT programmé après une
  révocation est l'information actionnable ; la révocation reste lisible via l'historique).
  Expiré = au moins un achat (remboursé compris) ou un GRANT passé. Alertes servies : achat
  (partiellement) remboursé, révocation programmée, accès programmé, accès rouvert par un rachat,
  « Civique reste ouvert via Intégral », abonnement récurrent en lecture seule (G-12).
  Origine affichée : décision applicable, sinon achat qui compte.
- **Impact** : `AccesEffectifResolver.etat`, `AdminUserMapper`.
- **Réversibilité** : facile.

### D-16 — Dates (G-7) : début et fin

- **Contexte** : GO §10, spec §2.5.
- **Choix retenu** : `util/DateMetierParis`, seul convertisseur. `startDate` n'est lu que pour
  Donner / Réactiver (ignoré ailleurs) ; date passée ⇒ 400 ; aujourd'hui ⇒ maintenant.
  `endDateInclusive` servie seulement quand la borne tombe à minuit Paris (fin admin) ;
  `endLabel` donne l'heure réelle pour une fin d'achat. Aucune date d'achat réécrite.
  Passage à l'heure d'hiver couvert (`AccesEffectifResolverTest.BornesParis`).
- **Impact** : DTO admin.
- **Réversibilité** : facile.

### D-17 — G-8 : purge avec le compte

- **Contexte** : GO §11, option 2.
- **Choix retenu** : `AccountDeletionService` supprime les décisions puis le journal du compte
  (la ligne `users` survit à l'anonymisation : la cascade SQL ne joue pas). Les lignes où le compte
  est l'AUTEUR (admin) restent (référence d'auteur). Le motif est documenté « sans donnée
  personnelle inutile » (DTO de requête, `api-endpoints.md`).
- **Impact** : `AccountDeletionServiceIT.deleteAccount_purgesAdminAccessDecisionsAndJournal`.
- **Réversibilité** : facile.

### D-18 — Liste : stratégie de filtres et définitions

- **Contexte** : spec §4, audit C.5.
- **Choix retenu** : sur-ensemble SQL (achats non terminés, statut non filtré + GRANT courant qui
  couvre maintenant) résolu en Java par l'autorité, puis `id IN / NOT IN` paginé en SQL.
  « Accès manuel » = décision courante non terminée (même définition en SQL et en Java :
  `UserSpecifications.hasOpenOverride` ⇄ `AccesEffectifResolver.aDecisionOuverte`). « Expiré »
  inclut un achat révoqué. Comptes ADMIN et supprimés listés (statut de compte servi). Coût
  constant verrouillé par égalité. Recherche « contient » partagée avec la console Abonnements
  (`LikePattern`, extrait à la 2ᵉ occurrence).
- **Impact** : `AdminUserService`, `UserSpecifications`.
- **Réversibilité** : facile.

### D-19 — Chemins d'API

- **Contexte** : spec §8 (indicatif).
- **Choix retenu** : préfixe existant `/api/admin` : `GET /users`, `GET /users/{id}`,
  `GET /access-products`, `POST /users/{id}/access-operations`. Ajoutés à
  `AdminRoutesSecurityIT`.
- **Réversibilité** : facile.

### D-20 — Coût d'un contrôle d'accès : une requête de plus

- **Contexte** : chaque `hasCivique` / `hasTcf` lit désormais aussi les décisions courantes.
- **Options envisagées** : (a) requête dédiée (index partiel `user_id WHERE superseded_at IS NULL`) ;
  (b) cache.
- **Choix retenu** : (a), inconditionnelle et indépendante des données. Une seule égalité de
  nombre de requêtes a bougé : le budget du Plan (`LearningPlanCycleIT`) passe de 23 à 24,
  justification consignée dans le test. Pas de cache (le dépôt n'en a pas pour l'accès).
- **Réversibilité** : facile.

### D-21 — Plans « sans module » non gratuits

- **Contexte** : l'ancien `currentAccess` comptait dans « fin la plus tardive » une ligne d'un plan
  `module_access = NONE` dont le code n'est pas `FREE`.
- **Choix retenu** : le resolver ignore tout plan sans module. Aucun tel plan n'existe (vérifié en
  local : seul `FREE` est `NONE`) ; divergence théorique seulement.
- **Réversibilité** : facile.

## Phase 3 — front admin

> Console `admin_sejourfr/src/features/users/` (routes `/users`, `/users/:id`). Aucune de ces
> décisions ne touche le schéma, un DTO lu par le mobile, le calcul d'accès effectif, les achats
> ou les emails. B-1 inchangé : la fiche affiche ce que le serveur sert.

### D-22 — Pré-remplissage de « Fin (incluse) » servi par le backend

- **Contexte** : spec §2.6 (« la date de fin proposée par défaut est celle de A »), D-03 (« le
  front pré-remplit la fin de A, servie »). Or `endDateInclusive` n'est servie que pour une fin
  admin ; une fin d'achat (« 21/12/2026 à 10:14 ») n'a pas de date incluse, et la déduire dans le
  navigateur serait une conversion de date côté front (interdite).
- **Options envisagées** : (a) champ vide pour un achat (l'admin retape la date) ; (b) convertir
  `endsAt` en date de Paris dans le front ; (c) champ admin servi `defaultEndDateInclusive`.
- **Choix retenu** : (c). `AdminUserAccessDto.defaultEndDateInclusive` = date incluse d'une fin
  admin, sinon jour (Paris) de la fin d'achat — même convention que `cas2CorrectionDeProduit`.
  Calcul unique dans `DateMetierParis.finProposee`. La modale l'utilise pour Prolonger,
  Raccourcir et Corriger ; Donner / Réactiver partent d'un champ vide.
- **Impact** : DTO **admin** seulement (aucun DTO mobile), `AdminUserMapper`, tests
  `DateMetierParisTest.finProposee…`, `AdminUserControllerIT.fiche` / `cas1DonnerUnAcces`,
  `docs/api-endpoints.md`, miroir `admin_sejourfr/src/types/api.ts`.
- **Réversibilité** : facile — retirer le champ et laisser le champ de date vide.

### D-23 — Début « aujourd'hui » = champ vide, jamais une date calculée par le navigateur

- **Contexte** : spec §6 (« Début : par défaut aujourd'hui »). Le jour du navigateur peut
  différer du jour de Paris (admin à l'étranger, autour de minuit) ; un début « hier » est refusé
  en 400.
- **Options envisagées** : (a) pré-remplir avec la date locale du navigateur ; (b) champ vide,
  `startDate` absent ⇒ le serveur prend « maintenant ».
- **Choix retenu** : (b), libellé « Vide : dès maintenant. Une date future programme l'accès. »
  Le champ n'est affiché que pour Donner / Réactiver (seules opérations où l'API le lit).
- **Impact** : `AccessOperationModal`.
- **Réversibilité** : facile.

### D-24 — Une seule modale, aperçu `dryRun` automatique, écriture conditionnée à un aperçu à jour

- **Contexte** : spec §6, §8 ; GO §14.
- **Options envisagées** : (a) bouton « Prévisualiser » explicite ; (b) aperçu automatique
  (`dryRun: true`, debounce 400 ms) dès que les champs exigés sont remplis.
- **Choix retenu** : (b). L'aperçu porte déjà `expectedVersion` (l'`accessVersion` lue à
  l'ouverture, figée dans la modale) : un état périmé se voit avant même d'écrire. « Enregistrer »
  n'est actif que si l'aperçu correspond aux champs actuels ; la seconde étape (« Confirmer »)
  n'apparaît que si `confirmationRequired` est servi, avec la phrase `preview` et les `changes`
  servis. Les champs affichés dépendent de l'opération (contrat de la requête), jamais du statut.
  Le produit est figé pour une action de carte ; on ne le choisit que pour « Donner un accès »
  global et pour la cible d'une correction (produits servis moins le produit corrigé).
  Après succès : invalidation du préfixe `["adminUsers"]` (liste + fiche).
- **Impact** : `AccessOperationModal` ; aperçu en `queryKey` séparée
  (`["adminUserAccessPreview", …]`) pour ne pas être rejoué par l'invalidation.
- **Réversibilité** : facile.

### D-25 — 409 et 400 dans la modale

- **Contexte** : spec §6, GO §14.
- **Choix retenu** : 409 à l'écriture ⇒ message fixe « L'état de cet utilisateur a changé depuis
  l'ouverture de la fenêtre. Rechargez la fiche avant de recommencer. » + bouton « Recharger la
  fiche » (invalide et ferme) ; 409 à l'aperçu (précondition ou état périmé) ⇒ message serveur +
  même bouton ; 400 ⇒ message serveur tel quel. Aucune validation métier dupliquée côté front
  (seul le motif 3–500 conditionne l'appel, pour ne pas déclencher un aperçu voué au 400).
- **Réversibilité** : facile.

### D-26 — Deux routes (liste, fiche) plutôt que le panneau scindé de la maquette

- **Contexte** : maquette (liste + fiche côte à côte), spec §4/§5 (routes indicatives
  `/admin/users`, `/admin/users/{id}`), conventions admin (`/skills`, `/skills/:id`).
- **Options envisagées** : (a) panneau scindé ; (b) deux routes.
- **Choix retenu** : (b) `/users` et `/users/:id` : fiche partageable par lien, place pour les
  six blocs du §5, repli mobile trivial. Le retour à la liste conserve recherche, filtre et page
  (la query string est passée en `state` du lien).
- **Impact** : `App.tsx`, entrée de nav « Support › Utilisateurs ».
- **Réversibilité** : facile.

### D-27 — Pas de bandeau de statistiques

- **Contexte** : la maquette initiale affichait 4 compteurs (utilisateurs, accès actifs, TCF
  actifs, expirent sous 7 j) ; aucun endpoint ne les sert et le §13 sort les statistiques du MVP.
- **Choix retenu** : retirés de l'écran et de la maquette, plutôt que de les calculer sur une
  page de liste (faux) ou d'ajouter un endpoint d'agrégats.
- **Réversibilité** : facile (endpoint d'agrégats + bandeau).

### D-28 — `/subscriptions` conservée : pas de doublon

- **Contexte** : « refonte = suppression de l'ancien » si un écran concurrent existe.
- **Choix retenu** : la console Abonnements est une vue **transverse des achats** (filtre par
  source, statut, mois d'achat ; résiliation ; solde de sessions EO — seule compensation possible
  de B-1, option 1). La fiche utilisateur montre les achats **d'un** compte en lecture seule.
  Aucun recouvrement d'action : conservée. Leur mécanique commune est mutualisée (2ᵉ occurrence) :
  état de liste dans l'URL et recherche debouncée (`hooks/useUrlListState.ts`), message d'erreur
  HTTP (`httpErrorMessage`, `api/http.ts`), dates de Paris (`lib/dates.ts`).
- **Réversibilité** : facile.

### D-29 — Couleur des statuts : simple correspondance d'un enum servi

- **Contexte** : « le front ne recalcule jamais un statut ».
- **Choix retenu** : `AccessStatusBadge` associe une couleur à `ProductAccessStatus` (Actif vert,
  Programmé bleu, Révoqué rouge, Expiré ambre, Aucun gris) et affiche le **libellé servi**. Les
  boutons d'une carte sont exactement `availableOperations` (libellés servis), leur ton suit le
  code d'opération. Aucun seuil, aucune date, aucune déduction.
- **Réversibilité** : facile.

## Écarts avec la spec

- Produits `CIVIQUE` / `INTEGRAL` (GO §1) : la correction « Civique → TCF » est « Civique →
  Intégral ». Les modules ouverts sont servis à côté (GO §2) ; la maquette est mise à jour en phase 3.
- Pas de statut de compte « bloqué » (n'existe pas). Pas de dernière activité par module.
- Quota EO d'un GRANT Intégral nu : voir B-1.
- Phase 3 : pas de filtre « Compte bloqué » (la notion n'existe pas). Pas de bouton générique
  « Modifier l'accès » : chaque carte propose exactement les actions servies (Prolonger,
  Raccourcir, Terminer, Corriger le produit, Donner un accès, Réactiver). « Donner un accès »
  apparaît aussi sur une carte active (programmer une décision future, GO §4). Pas de
  statistiques (D-27). Liste et fiche sur deux routes (D-26).
