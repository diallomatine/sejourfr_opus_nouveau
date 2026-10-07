# Décisions — Admin / Gestion des utilisateurs (phase 2 : backend, migrations, tests ; phase 3 : front admin)

> Mode autonome (GO du propriétaire du 2026-10-02, §19). Sources : `spec-admin-utilisateurs-v2.md`,
> `audit-admin-utilisateurs.md`, GO du propriétaire (prime sur les deux). Chaque décision suit le
> format demandé ; elles sont classées par importance.
> Branche `develop`, rien de poussé ni déployé. Règle résultante : `docs/regles/paiements.md`
> § « Accès effectif = achats + décisions admin ».

## Bloquant — décision requise

Aucun. B-1 est résolu en MVP (V084, 2026-10-02) — texte d'origine conservé ci-dessous.

## Résolu

### B-1 — Simulations orales temps réel d'un Intégral ACCORDÉ sans achat Intégral (GO §7)

> **Résolu en MVP le 2026-10-02** (arbitrages n°3 et n°4 du propriétaire, « B-1 modifié ») :
> ni l'option 2 ni l'option 3 telles quelles. L'admin choisit le nombre de sessions EO temps réel
> offertes quand il crée un GRANT INTEGRAL ; le solde vit sur la décision
> (`access_overrides.realtime_eo_sessions_granted` / `_remaining`, V084) et
> `realtime_sessions.access_override_id` trace le débit. Il y a deux lieux de stockage mais **une
> seule règle** (`RealtimeQuotaService.evaluer`) et **un seul point de débit**
> (`RealtimeQuotaService.debiter`) — verrouillé par `QuotaEoAutoriteUniqueTest`. Voir **D-40 →
> D-49**. Le **ledger** (option 2) reste **REPORTÉ** : `proposition-ledger-quota-eo.md`. Le texte
> ci-dessous est celui d'origine, conservé tel quel.

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

Arbitrages du propriétaire du 2026-10-02 (relecture), à relire d'abord : **D-31** (proration sur
les achats, change un prix Stripe), **D-32** (emails : exclusion seulement si une décision change
l'accès), **D-30** (vocabulaire achat / droit), **D-34** (Réactiver un achat révoqué), **D-33**
(identifiants de paiement entiers dans l'admin). D-02, D-05, D-07, D-09 et D-12 sont **révisées** ;
leur texte d'origine est conservé tel quel ci-dessous.

Sessions EO temps réel du GRANT INTEGRAL (B-1 résolu, V084), à relire d'abord : **D-40** (schéma
V084), **D-41** (une seule règle de quota ; valeurs — pas la forme — lues par le mobile qui
changent sous GRANT à sessions), **D-42** (débit), **D-43** (lignée, cumul, perte), **D-48**
(remboursements). D-08 est **révisée** par D-41.

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

> **Révisée par D-34** (2026-10-02) : la règle de troncature est conservée ; « Réactiver » propose
> désormais la fin de l'achat révoqué, et l'aperçu signale l'achat qui restera révoqué.

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

> **Révisée par D-30** (2026-10-02) : `currentSubscription` est supprimé ; `currentPurchase` (achat)
> et `effectiveAccess` (droit) sont les deux seuls noms.

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

> **Révisée par D-31** (2026-10-02) : le crédit se lit sur les achats payés, non remboursés, non
> neutralisés par un REVOKE — plus sur l'accès effectif.

- **Contexte** : audit C.4 / G-5 (`BillingService.computeOneTimeAmountCents`).
- **Options envisagées** : (a) créditer le Civique acheté même révoqué ; (b) ne créditer qu'un
  Civique effectif.
- **Choix retenu** : (b), automatiquement via `currentSubscription` effectif. Conséquence : un
  compte avec Civique acheté + GRANT Intégral voit le module effectif Intégral et paie un Intégral
  plein tarif (qui prolonge depuis la fin du GRANT).
- **Impact** : comportement de prix, Stripe seulement. Code inchangé.
- **Réversibilité** : facile (lire `currentPurchase` dans la proration).

### D-08 — Quota EO temps réel sur l'achat qui compte de l'accès effectif

> **Révisée par D-41** (2026-10-02, V084) : le quota lit d'abord le GRANT INTEGRAL admin, puis
> l'achat qui compte ; un GRANT Intégral nu n'est plus à 0 session si l'admin en a offert.

- **Contexte** : GO §7 ; voir **B-1**.
- **Options envisagées** : voir B-1.
- **Choix retenu** : la part réalisable sans évolution structurelle (une seule autorité de quota,
  débit inchangé) ; le reste est bloquant.
- **Impact** : `RealtimeQuotaService` (code inchangé, sémantique effective), tests
  `quotaApresRevoke`, `quotaGrantSurAchatIntegral`.
- **Réversibilité** : facile.

### D-09 — Emails G-6 : exclusion des comptes sous décision courante

> **Révisée par D-32** (2026-10-02) : exclusion seulement si une décision change l'accès effectif
> par rapport aux achats, maintenant ou d'ici la date annoncée ; plus aucune exclusion en SQL.

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
- **Arbitrage du 2026-10-02** : principe accepté sous réserve de compatibilité production. Le
  **propriétaire vérifie lui-même** en production la disponibilité de `btree_gist` et les droits de
  l'utilisateur Flyway, et donne le résultat. **Aucune implémentation de repli n'est préparée**
  d'ici là (consigne explicite).

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

> **Révisée par D-33** (2026-10-02) : Stripe et Apple entiers ; seul le purchaseToken Google
> reste tronqué.

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

## Arbitrages du propriétaire du 2026-10-02 (relecture des décisions)

> Source : arbitrages verbatim du propriétaire, § 7 « Précisions complémentaires » prioritaire.
> B-1 (ledger de quota EO) est traité à part et n'est pas couvert ici. D-01, D-03 et le modèle
> des fenêtres d'override sont confirmés tels quels.

### D-30 — Vocabulaire : `currentPurchase` (achat) / `effectiveAccess` (droit) — révise D-05

- **Contexte** : arbitrage §4 / §7 — `currentSubscription` avait changé de sens (achat → achat
  qui porte le droit effectif) ; risque qu'un développeur confonde achat et entitlement.
- **Options envisagées** : (a) garder `currentSubscription` effectif (D-05) ; (b) le supprimer,
  deux noms seulement.
- **Choix retenu** : (b). `SubscriptionService.currentSubscription` est **supprimé**. Il reste :
  `currentPurchase(userId)` = l'ACHAT courant (décisions ignorées : résilier, supprimer le
  compte) ; `effectiveAccess(userId)` (ex-`accesEffectif`) = le DROIT effectif (module, fin, et
  `achat()` qui le porte). Chaque appelant, selon son intention : `subscription-status` /
  `verify-receipt` → `effectiveAccess` ; quota EO temps réel et report du solde EO à la
  prolongation → `effectiveAccess(..).achat()` (même sélection qu'avant, aucun changement de
  quota ni de débit : B-1 inchangé) ; proration → les achats (`CreditProration`, D-31).
- **Impact** : `SubscriptionService`, `SubscriptionStatusService`, `RealtimeQuotaService` (appel
  seulement), `OneTimeAccessService`, `BillingService`. Tests adaptés : `SubscriptionServiceTest`
  (`effectiveAccessAchat_*`), `RealtimeQuotaServiceTest`, `OneTimeAccessServiceTest`. Aucun DTO,
  aucun endpoint, aucune réponse mobile ne change (`AccesEffectifNonRegressionIT` vert).
- **Réversibilité** : facile (renommage).

### D-31 — Proration : crédit calculé sur les achats payés, pas sur l'accès effectif — révise D-07

- **Contexte** : arbitrage §2 / §7 — les overrides disent ce que l'utilisateur peut utiliser,
  les achats ce qu'il a payé. D-07 faisait perdre le crédit Civique à un compte sous GRANT
  Intégral.
- **Options envisagées** : (a) accès effectif (D-07) ; (b) achats seuls ; (c) achats payés, non
  remboursés, non neutralisés par un REVOKE applicable (règle du §7).
- **Choix retenu** : (c), dans `service/billing/CreditProration` (pur, seule autorité ;
  `BillingService.computeOneTimeAmountCents` l'appelle). Un achat est créditable s'il est valide
  (`covers`), payé et non remboursé, et non neutralisé par un REVOKE courant applicable
  maintenant (achat antérieur à la décision — même lecture que l'accès effectif ; un rachat
  postérieur au REVOKE reste créditable). Puis meilleur achat au sens historique : un Intégral
  payé ⇒ pas de crédit. Trois choix faits en autonomie, les plus sûrs :
  1. **Origine du REVOKE non lue** : le journal ne la donne pas directement — une copie tronquée
     (D-02) porte l'`operation_id` de l'action qui l'a tronquée, l'origine ne se retrouve qu'en
     remontant la chaîne `replaces_override_id` à travers les lignes supersédées. Inutile :
     un REVOKE ne naît que de Terminer, Raccourcir ou Corriger le produit. **Tout REVOKE
     applicable neutralise** ; Raccourcir est donc traité comme Terminer une fois sa date
     atteinte (la valeur coupée par l'admin n'est pas créditée). Aucun schéma nouveau.
  2. **REVOKE programmé** (Raccourcir) : l'achat reste créditable, mais les jours crédités
     s'arrêtent au début de la révocation.
  3. **Remboursement partiel** (`PARTIALLY_REFUNDED`) : **pas de crédit** (« non remboursés »).
     C'est le seul écart sans aucune décision admin par rapport au calcul d'avant (qui le
     créditait) — à confirmer. Statut de paiement `null` (achat antérieur à la mesure) = payé.
- **Impact** : **prix Stripe** d'un upgrade Civique → Intégral (Apple / Google : prix fixe,
  inchangé). Civique payé + GRANT Intégral ⇒ crédit conservé (D-07 le perdait). Tests :
  `CreditProrationTest` (7) ; `ProrationAchatsIT` (7, actions admin réelles) :
  `grantIntegralConserveLeCredit`, `correctionDeProduitSupprimeLeCredit`, `achatRembourse`,
  `achatPartiellementRembourse`, `terminerSupprimeLeCredit`, `raccourcirLimiteLeCredit`,
  `temoinSansDecision`.
- **Réversibilité** : facile (une classe pure ; le partiel tient en une ligne).

### D-32 — Emails : exclusion seulement si une décision change l'accès — révise D-09

- **Contexte** : arbitrage §3 / §7 — D-09 excluait à vie tout compte ayant une décision non
  remplacée, même un GRANT terminé depuis longtemps.
- **Options envisagées** : (a) D-09 (toute décision courante, en SQL) ; (b) décisions non
  terminées, en SQL (recopie partielle de la règle) ; (c) SQL borne, Java décide via le resolver.
- **Choix retenu** : (c). Les trois `NOT EXISTS access_overrides` sont retirés
  d'`EmailScenarioRepository` (il borne seulement). `EmailAutomationService` charge achats +
  décisions de la page par l'autorité (`SubscriptionService.charger`, deux requêtes par page, pas
  de N+1) et écarte un compte si `AccesEffectifResolver.decisionsChangentLAcces` : le module
  effectif diffère de celui des seuls achats à un instant de la fenêtre dont parle le message —
  `NO_PREMIUM_AFTER_7_DAYS` et `PREMIUM_INACTIVE_2_DAYS` : maintenant ; `PREMIUM_ENDING_*` :
  de maintenant à la fin annoncée ; `PREMIUM_ENDED` : de juste avant la fin annoncée à
  maintenant. On compare aux extrémités et à chaque borne intérieure (début / fin de décision,
  fin d'achat). Le moteur d'emails n'est pas rebranché sur l'accès effectif (MVP conservé).
  Choix fait : la comparaison porte sur le **module** effectif (un GRANT Intégral sur un Civique
  acheté change le module ⇒ exclu ; un REVOKE Civique sous un Intégral acheté ne le change pas ⇒
  non exclu).
- **Impact** : `EmailScenarioRepository`, `EmailAutomationService`, `AccesEffectifResolver`.
  Comptes retrouvant leurs scénarios : décision terminée ou sans effet sur l'accès. Tests :
  `EmailOverrideExclusionIT` — `grantAncienRetablitLesScenarios`, `revokePuisRachatEnvoieLaFin`,
  `grantProgrammeQuiProlongeExclut`, + `grantExclutJamaisPremium`, `revokeExclutFinDAcces`
  (existants, toujours verts) ; `AccesEffectifResolverTest.DecisionsEtEmails` (5).
- **Réversibilité** : facile.

### D-33 — Identifiants de paiement : Stripe et Apple entiers, purchaseToken Google tronqué — révise D-12

- **Contexte** : arbitrage §7 — la console Abonnements doit montrer les identifiants Stripe et
  Apple en entier.
- **Options envisagées** : (a) console Abonnements seulement ; (b) même règle pour la fiche
  utilisateur (`AdminUserPurchaseDto.externalReference`).
- **Choix retenu** : (b), une seule règle dans `util/ReferenceExterne` :
  `identifiantOrigine(source, ref)` tronque le seul `original_transaction_id` d'un achat GOOGLE
  (= purchaseToken) ; `identifiantTransaction(ref)` rend l'`external_transaction_id` entier
  (id Stripe, transaction Apple, orderId Google « GPA.… »). Montrer un même identifiant Stripe
  entier dans une console et tronqué dans l'autre n'aurait aucun sens.
- **Impact** : DTO **admin** seulement (forme inchangée). `UserSubscriptionMapper`,
  `AdminUserMapper`. Front admin : libellés inchangés, commentaires de `api.ts` corrigés,
  `tsc` OK. Tests : `UserSubscriptionMapperTest` (`…seulLePurchaseTokenGoogleTronque`),
  `DateMetierParisTest.referenceExterne_seulLePurchaseTokenGoogleEstTronque`,
  `AdminUserControllerIT.fiche` (référence Stripe entière).
- **Réversibilité** : facile.

### D-34 — Réactiver un achat révoqué : fin proposée = fin de l'achat, aperçu explicite — révise D-02

- **Contexte** : arbitrage §7 — avec D-02, un GRANT de réactivation plus court que l'achat laisse
  l'achat révoqué ensuite, sans que l'admin le voie.
- **Options envisagées** : (a) inchangé ; (b) fin par défaut = fin de l'achat + avertissement
  dans la phrase d'aperçu serveur.
- **Choix retenu** : (b). `EtatProduit.finAchatRevoque` (resolver) = fin de l'achat que le REVOKE
  applicable neutralise ; pour un produit Révoqué, `defaultEndDateInclusive` = jour (Paris) de
  cette fin (même convention que D-22). L'aperçu (`dryRun` et écriture) ajoute à la phrase :
  « Attention : l'achat Civique révoqué ne sera pas rétabli. À partir du JJ/MM/AAAA, l'accès
  Civique sera de nouveau fermé. » dès qu'à la fin d'un GRANT posé par l'action un achat du
  produit couvrirait encore mais reste révoqué (`AccesEffectifResolver.achatResteRevoque`, lu sur
  l'état d'après l'action). Vaut pour toute action qui pose un GRANT. Aucun champ de DTO ajouté.
  ⚠️ Le front admin (D-22) laisse aujourd'hui « Fin » vide pour Réactiver : la valeur servie
  sera reprise à la finalisation du front.
- **Impact** : `AccesEffectifResolver`, `AdminUserMapper`, `AdminAccessOperationService`. Tests :
  `AdminAccessOperationServiceTest` — `reactiverProposeLaFinDeLAchat`,
  `reactiverAvantLaFinSignaleLAchatRevoque`, `reactiverJusquALaFinNeSignaleRien` ;
  `AccesEffectifResolverTest.AchatRevoque` (2).
- **Réversibilité** : facile.

## Phase 3 bis — refonte visuelle de l'admin (2026-10-02)

> Retour du propriétaire : « adapter l'existant au template, beaucoup plus premium ; écrans
> fonctionnels sur mobile ; menu via un burger ». La maquette
> `docs/admin/utilisateurs/maquette-admin-utilisateurs-mvp.html` fait foi pour le DESIGN ; les données restent
> celles du backend. Aucun DTO, endpoint ni calcul touché.

### D-35 — Palette : les tokens globaux réalignés sur l'identité visuelle

> ✅ **Validée par le propriétaire le 2026-10-02.**

- **Contexte** : l'admin portait des teintes à part (bleu `#1E3A8F`, rouge `#E1252C`, gris chauds
  `--rule` / `--muted`), la maquette des teintes voisines (`#21469A`, `#EA3430`…).
- **Choix retenu** : `styles/global.css` reprend les valeurs de `docs/identite-visuelle.md`
  (bleu `#1E3A8C`, dark `#15296B`, light `#E8ECF8`, soft `#F4F6FC` ; rouge `#E1372F` ; ink
  `#0F1839` ; muted `#6B7299` / `#9CA2BD` ; lignes `#E4E7F2` / `#EEF0F8` ; vert `#168F5B`). Les
  usages de la maquette sans équivalent deviennent des tokens : `--bg`, `--surface-2`,
  `--rule-strong`, `--blue-line`, `--red-line`, `--green-line`, `--amber-ink`, `--blue-bright`
  (second arrêt du dégradé), `--on-dark-*`, rayons `--radius-*`, ombres `--shadow-panel|tile|
  button|modal|toast|drawer`, `--focus-ring`. Aucun nom existant supprimé : toutes les pages
  héritent de la palette sans être réécrites.
- **Réversibilité** : facile (valeurs de tokens).

### D-36 — Titres en Inter gras (maquette), primitives restylées une fois pour toutes les pages

> ✅ **Validée par le propriétaire le 2026-10-02.**

- **Contexte** : la maquette titre en Inter 800 ; l'admin titrait en Fraunces.
- **Choix retenu** : `PageHeader`, `Panel`, `Modal` titrent en `--font-ui` 800 ; l'`emphasis`
  reste rouge (non italique). `PageHeader` gagne `description`, `Modal` gagne `description`,
  un bouton de fermeture, `role="dialog"`, focus posé/rendu et défilement bloqué
  (`hooks/useBodyScrollLock`). `Tag` devient la pastille de la maquette (tons génériques
  `info|success|danger|warning|neutral` + `dot`) et remplace `AccessStatusBadge` (supprimé ;
  correspondance d'enum D-29 dans `features/users/accessTones.ts`). Nouveaux : `Icon` (SVG
  locaux, aucune dépendance), `Avatar` (initiales d'affichage), `Chips`. Pas de `StatTile`
  (D-27 tient, aucun chiffre servi à y mettre).
- **Réversibilité** : facile.

### D-37 — Coquille : trois paliers et tiroir burger

> ✅ **Validée par le propriétaire le 2026-10-02.**

- **Choix retenu** : ≥ 1180 px barre latérale complète (marque, sections, icônes, carte admin
  + déconnexion) ; 721–1179 px barre réduite aux icônes (libellés masqués visuellement mais
  lus, infobulle `title`, compteurs en pastille sur l'icône) ; ≤ 720 px barre retirée, bouton
  burger dans la topbar ouvrant la même barre en tiroir (voile, fermeture par voile / Échap /
  bouton / lien / changement de route / retour en palier large, focus piégé puis rendu au
  burger, `aria-expanded` + `aria-controls`, défilement bloqué). Les entrées vivent dans
  `components/layout/navigation.ts` (barre, tiroir et fil d'Ariane lisent la même liste) ;
  aucune route retirée. Topbar : fil d'Ariane (dernier segment « Fiche » sur `/users/:id`) et
  « Actualiser » global = relecture des requêtes actives. « Donner un accès » n'est pas dans la
  topbar : il exige un compte, il reste dans le héros de la fiche.
- **Réversibilité** : facile.

### D-38 — Fiche : deux colonnes ≥ 1180 px, carte dégradée = accès effectif servi

> ✅ **Validée par le propriétaire le 2026-10-02.**

- **Contexte** : D-26 (deux routes) maintenu ; la maquette juxtapose liste et fiche.
- **Choix retenu** : la fiche reproduit la sensation du panneau sur deux colonnes ≥ 1180 px
  (gauche : héros, carte d'accès, cartes produit ; droite : achats, progression, compte,
  historique), une seule en dessous. La carte dégradée affiche `effectiveAccess`
  (produit effectif + « Modules ouverts ») puis, par produit, le `summary` et l'`originLabel`
  servis, et la dernière activité. Le « Ouvre : TCF + Civique » d'une carte produit est le
  `modulesLabel` de `GET /api/admin/access-products` (lookup d'affichage). La barre de
  progression de la maquette n'est **pas** reprise : sa largeur serait un pourcentage calculé
  dans le front. Le bouton « Retour aux utilisateurs » reste visible à tous les paliers (il
  conserve recherche, filtre et page, ce que le fil d'Ariane ne fait pas).
- **Réversibilité** : facile.

### D-39 — Écarts assumés avec la maquette

> ✅ **Validée par le propriétaire le 2026-10-02.** Nuance : la colonne « Inscription » est rétablie par D-53 (la colonne « Compte » reste retirée).

- Pas de tuiles de statistiques (D-27) : seul `totalElements` est servi, il est dans le
  sous-titre du panneau.
- Pas de select de statut en plus des puces : l'API n'a qu'un paramètre `filter`, déjà exposé
  en puces (un select dupliquerait le même contrôle).
- Colonnes « Inscription » et « Compte » retirées de la liste (la maquette ne les a pas) : un
  compte non actif garde une pastille rouge sous son nom ; l'inscription est dans la fiche.
  ⚠️ « Inscription » rétablie par D-53 ; « Compte » reste retirée.
- Confirmation : bouton « Confirmer » contouré rouge (`danger`, maquette) au lieu du rouge plein.
- Mobile : tableau → cartes empilées (`cardTable`), bouton « Ouvrir la fiche » pleine largeur ;
  modale pleine largeur, boutons empilés ; toasts pleine largeur.

## Sessions EO temps réel du GRANT INTEGRAL (B-1 modifié, V084, 2026-10-02)

> Arbitrages n°3 (« B-1 modifié ») et n°4 (« reco partout », avec précisions) du propriétaire ;
> schéma validé avant écriture. Lignes rouges tenues : `user_subscriptions` et les écritures des
> webhooks non touchées, aucune forme de DTO lu par le mobile modifiée, migration additive, pas de
> reprise de données, pas de ledger. Règle résultante : `docs/regles/paiements.md` § « Quota EO
> temps réel : deux SOURCES, une seule AUTORITÉ ».

### D-40 — Schéma V084 : deux colonnes sur la décision, un porteur sur la session

- **Contexte** : arbitrage n°3 (« colonne du type `realtime_eo_sessions_remaining` »), point ouvert
  n°2 du schéma ; validé par l'arbitrage n°4 §1.
- **Options envisagées** : (a) une seule colonne de solde (un GRANT épuisé rend `cap = 0` ⇒ le
  mobile ouvre le paywall, `realtime_launch_sheet.dart:48`) ; (b) `granted` (allocation, pendant de
  `plans.realtime_eo_sessions`) + `remaining` ; (c) ledger (reporté).
- **Choix retenu** : (b). `V084__sessions_eo_acces_admin.sql` : `access_overrides.
  realtime_eo_sessions_granted` / `_remaining` (`INT NOT NULL DEFAULT 0`, métadonnée seule) +
  4 CHECK (positifs ; `remaining <= granted` ; sessions seulement sur GRANT INTEGRAL ; ligne
  remplacée ⇒ `remaining = 0`) ; `realtime_sessions.access_override_id` (FK `ON DELETE SET NULL`
  pour la purge G-8) + CHECK « un seul porteur » + index partiel. Aucun UPDATE ni INSERT. Le
  plafond (50) vit en configuration (`sejourfr.realtime.admin-grant-max-sessions` ⇄
  `RealtimeProperties`), pas en base : un cumul peut légitimement le dépasser.
- **Impact** : entités `AccessOverride`, `RealtimeSession`. Tests : `AccesAdminSchemaIT` (8 cas
  V084), `AccountDeletionServiceIT.deleteAccount_purgesAdminAccessDecisionsAndJournal` (purge avec
  une session débitée sur un GRANT).
- **Réversibilité** : moyenne — colonnes laissées à 0 si on revient en arrière ; une migration
  additive les rendrait inertes, aucune donnée existante n'a été touchée.

### D-41 — Une seule règle : `RealtimeQuotaService.evaluer` (révise D-08)

- **Contexte** : arbitrage n°3 (« RealtimeQuotaService reste l'UNIQUE autorité »), n°4 §5
  (priorité GRANT puis achat).
- **Options envisagées** : (a) deux calculs (GRANT côté admin, achat côté candidat) ; (b) une
  méthode pure qui choisit les deux porteurs en réutilisant `AccesEffectifResolver`.
- **Choix retenu** : (b). `evaluer(DonneesAcces, t)` : GRANT = `decisionApplicable(INTEGRAL)` de
  type GRANT ; achat = `achatRepresentatif` (inchangé). `remaining` = somme des soldes, `cap` =
  somme des allocations ; `grantPorteur()` puis `achatPorteur()`. `evaluate(userId)` charge par
  `SubscriptionService.charger` (même coût qu'avant : deux requêtes). Fiche admin :
  `vueAdmin(d, t)` sur la même règle. `QuotaEoAutoriteUniqueTest` interdit tout autre lecteur du
  solde d'une décision et tout autre appelant des débits.
- **Impact** : 🛑 **DTO lus par le mobile et le web : forme inchangée, VALEURS modifiées** pour
  un compte sous GRANT INTEGRAL avec N > 0 : `/api/realtime/eo/quota` `{remaining, cap}`,
  `SubscriptionStatusResponse.realtimeSessionsRemaining` (servi dès `cap > 0`),
  `RealtimeSessionDescriptor.sessionsRemaining`, `RealtimeSessionStateResponse.sessionsRemaining`.
  Sans décision : identiques (`AccesEffectifNonRegressionIT.sansDecisionReponsesIdentiques`
  compare aussi le quota au calcul d'avant ; `grantAvecSessionsFormeInchangee`). **Mobile : 0
  fichier, web : 0 fichier** — le déploiement est à annoncer comme D-04. Tests :
  `RealtimeQuotaServiceTest` (priorité, sommes, cap d'un GRANT épuisé, GRANT sans session,
  GRANT expiré / programmé, achat remboursé, lignée 4 → 4, cumul, fin ⇒ perdu).
- **Réversibilité** : facile — `evaluer` redevient « achat seul ».

### D-42 — Débit : porteur réservé au démarrage, relu et débité sous le verrou du compte

- **Contexte** : arbitrage n°3 (« traçable, impossible à débiter deux fois ») ; l'action admin
  réécrit l'entité entière à la supersession (`saveAndFlush`, sans `@DynamicUpdate`).
- **Options envisagées** : (a) débiter la ligne réservée au démarrage ; (b) relire le GRANT
  applicable sous le verrou consultatif `access-override:<userId>` (celui des actions admin) puis
  `UPDATE … WHERE id = :id AND superseded_at IS NULL AND remaining > 0` ; (c) en cas d'échec,
  basculer sur l'achat.
- **Choix retenu** : (b), sans (c). Au démarrage, `RealtimeSessionService.start` pose
  `subscription_id` **ou** `access_override_id` (jamais les deux). À la transition
  `PENDING → ACTIVE` (déjà unique : verrou de ligne + garde), `RealtimeSessionService` appelle
  `RealtimeQuotaService.debiter(session)` et ne dépend plus de `UserSubscriptionManager`. Achat :
  même SQL qu'avant. GRANT : la ligne réellement débitée est réécrite sur la session (une
  prolongation a pu déplacer le solde), `null` si aucun débit (course perdue, GRANT terminé) — la
  session continue sans débit, comme un achat à 0. Pas de bascule vers l'achat : course de
  quelques secondes, et une session n'a qu'un porteur. Ordre des verrous : ligne de session puis
  compte ; l'admin ne prend que le compte ⇒ pas d'interblocage.
- **Impact** : `RealtimeSessionService`, `RealtimeQuotaService`, `AccessOverrideManager` /
  `AccessOverrideRepository.decrementRealtimeSessions`. Traçabilité : `access_override_id` →
  `operation_id` → `admin_access_operations`. Tests : `RealtimeGrantQuotaIT` (vraies transactions :
  `debitIdempotentEtTrace`, `deuxConnexionsConcurrentesUnSeulDebit`, `debitPendantUnProlonger`,
  `grantTermineAvantConnexion`), `RealtimeSessionServiceTest`
  (`start_reserve_le_grant_admin_d_abord_un_seul_porteur`, `start_grant_epuise_reserve_l_achat`,
  `appendTranscript_session_portee_par_un_grant_rejeu_ne_debite_qu_une_fois`),
  `RealtimeQuotaServiceTest` (débit achat inchangé, ordre verrou → relecture → débit, GRANT
  disparu).
- **Réversibilité** : facile.

### D-43 — Le solde suit la lignée ; cumul « 4 + 10 → 14 » ; perdu à la fin

> ✅ **Validée par le propriétaire le 2026-10-02.** Cumul et report du solde d'un GRANT programmé tronqué compris.

- **Contexte** : arbitrage n°3 (prolongation sans perte, fin ⇒ perdu), n°4 §2 (cumul, `granted`
  cohérent, pas de 409), §6.
- **Options envisagées** pour l'allocation de la nouvelle décision lors d'un cumul : (a)
  `granted = P.remaining + N` (14 sur 14) ; (b) `granted = P.granted + N` (total offert sur la
  lignée). Pour un GRANT FUTUR tronqué : (c) solde perdu ; (d) solde reporté sur sa propre tête.
- **Choix retenu** : (b) et (d). Dans `AccessOverridePlanner` (pur, même plan pour l'aperçu et
  l'écriture) : nouvelle décision GRANT INTEGRAL ⇒ `granted = remaining = N` ; copie ⇒ `granted`
  de la source, `remaining = 0` ; le solde du GRANT INTEGRAL remplacé qui couvre MAINTENANT passe
  sur le GRANT INTEGRAL inséré qui couvre maintenant (si c'est une nouvelle décision, son
  `granted` reçoit aussi celui de l'ancien : « Conserver le nombre initialement offert », §1, et
  `remaining <= granted` tient) ; celui d'un GRANT futur remplacé passe sur sa tête ; sinon il est
  **perdu** et le plan le compte (`SessionsEo.perdues`). À l'écriture seulement
  (`AdminAccessOperationService`), chaque ligne remplacée reçoit `remaining = 0` avec
  `superseded_at` — jamais dans le planner (entités gérées, un aperçu serait flushé). Résultats :
  Prolonger 4 → 4 ; Donner +10 sur 4 → 14 (sur 10 + 10 offertes) ; Raccourcir garde le solde
  jusqu'à la nouvelle fin ; Donner programmé : la tête garde le solde jusqu'au début, le futur a
  son N ; Terminer / Corriger vers Civique / Terminer un GRANT programmé ⇒ perdu ; fin naturelle
  ⇒ inutilisable (jamais transféré).
- **Impact** : `AccessOverridePlanner` (`Decision.sessionsEo`, `Plan.sessionsEo`). Tests :
  `AccessOverridePlannerTest` (9 cas « Sessions — … »), `RealtimeGrantQuotaIT.prolongerDeBoutEnBout`.
- **Réversibilité** : facile — (a) est une ligne du planner.

### D-44 — `realtimeEoSessions` : 400 plutôt qu'ignoré, plafond configurable

- **Contexte** : arbitrage n°3 (« ≥ 0 + plafond de sécurité »), n°4 §1 (50 pour le MVP).
- **Options envisagées** : (a) ignorer la valeur hors des opérations concernées ; (b) 400.
- **Choix retenu** : (b) — un admin ne doit jamais croire avoir offert des sessions qui n'existent
  pas. Absent ou 0 ⇒ accepté partout. > 0 seulement pour `GRANT`/`REACTIVATE` INTEGRAL et
  `CORRECT_PRODUCT` vers INTEGRAL (message : « Les sessions EO temps réel ne s'offrent qu'en
  donnant, réactivant ou corrigeant vers un accès Intégral. »). Négatif ⇒ 400 (`@PositiveOrZero`
  côté HTTP, contrôle répété dans le service) ; > `admin-grant-max-sessions` (50) ⇒ 400. Le
  plafond porte sur le nombre DEMANDÉ par action, pas sur le solde cumulé. Pas de 409 quand un
  GRANT INTEGRAL est déjà actif (cumul, D-43).
- **Impact** : `AdminAccessOperationRequest`, `AdminAccessOperationService.sessionsEoOffertes`,
  `RealtimeProperties`, `application.yaml`. Tests : `AdminAccessOperationServiceTest.sessionsEo400`,
  `sessionsEoPlafondConfigurable`, `AdminUserControllerIT.sessionsEo400`.
- **Réversibilité** : facile.

### D-45 — Fiche admin : un bloc servi, le front n'additionne rien

- **Contexte** : mission (« sessions offertes / restantes du GRANT et sessions de l'achat servies
  séparément ») ; arbitrage n°3 (phrase quand 0).
- **Choix retenu** : `AdminUserAccessDto.realtimeEoSessions` (`AdminRealtimeEoSessionsDto`, carte
  INTEGRAL seulement, `null` pour CIVIQUE) : `remaining` (total), `grantGranted` /
  `grantRemaining` (`null` sans GRANT applicable), `purchaseRemaining` (`null` sans achat qui
  compte), `scheduledGrantGranted` (GRANT INTEGRAL programmé, `null` sinon), `label`
  (« 14 sessions restantes — accès manuel : 14 restantes sur 20 accordées ; achat : 0 » — libellé révisé par D-54 ; à l'origine « 14 sur 20 »), `info` (« Cet accès
  manuel n'ajoute pas actuellement de sessions EO temps réel. » quand l'accès manuel affiché — le
  GRANT applicable, sinon le prochain programmé — a `granted = 0`). `AdminAccessProductDto.
  maxRealtimeEoSessions` (50 pour INTEGRAL, `null` pour CIVIQUE) : la modale affiche le champ
  pour ce produit et les trois opérations seulement. Le mapper ne lit aucune colonne : il formate
  `RealtimeQuotaService.VueAdmin`.
- **Impact** : DTO **admin** seulement ; miroir `admin_sejourfr/src/types/api.ts` (`tsc` OK) ; la
  modale et la carte restent à faire (finalisation du front). Tests :
  `AdminAccessOperationServiceTest.ficheSessions`, `AdminUserControllerIT.sessionsEoFicheEtProduits`.
- **Réversibilité** : facile.

### D-46 — Aperçu : le devenir des sessions, dit par le serveur

- **Contexte** : arbitrage n°4 §2 (phrase du cumul imposée), §3, §6 ; schéma point ouvert n°3.
- **Choix retenu** : la phrase `preview` (chaîne, forme inchangée) ajoute, après la phrase de
  l'action : « Cet accès manuel offre N sessions EO temps réel. » ; « Sessions EO temps réel :
  4 sessions restantes + 10 offertes → 14 sessions disponibles. » (cumul sur la nouvelle
  décision) ; « Les N sessions EO temps réel restantes de l'accès manuel sont conservées. »
  (Prolonger, Raccourcir, Donner programmé) ; « … seront perdues. » (Terminer, Corriger vers
  Civique ; insérée avant « Continuer ? ») ; la phrase d'information quand le GRANT INTEGRAL posé
  n'offre rien (y compris Prolonger un Intégral acheté) ; et, pour Prolonger un Intégral acheté,
  « Les N sessions EO temps réel de l'achat restent utilisables jusqu'au … » (§3 : aucun
  transfert achat → GRANT). Accord au singulier pour 0 et 1.
- **Impact** : `AdminUserMapper.preview` / `ApercuSessions`. Tests :
  `AdminAccessOperationServiceTest.apercuCumul`, `apercusSessions`,
  `prolongerAchatGardeSesSessions`, `dryRunNEcritRien` (mis à jour : phrase d'information),
  `AdminUserControllerIT.sessionsEoCumul`.
- **Réversibilité** : facile.

### D-47 — Historique : le total de sessions dans la photo du journal

- **Contexte** : schéma §6 (« Sessions EO : 4 → 14 »).
- **Choix retenu** : la photo `before_state` / `after_state` de la carte INTEGRAL porte
  `realtimeEoSessions` (total consommable, contenu JSONB, pas de schéma) ; `changes` ajoute
  « Intégral — sessions EO temps réel : 4 → 14 » quand il change. Une entrée d'avant V084 n'a pas
  la clé : rien n'est comparé (pas de fausse ligne).
- **Impact** : `AdminUserMapper.snapshot` / `changes`. Tests : `AdminUserControllerIT.
  sessionsEoTroisOperations` (historique + photo en base), `AdminAccessOperationServiceTest.apercuCumul`.
- **Réversibilité** : facile.

### D-48 — Remboursements : vrais traitements, seules les vérifications de signature simulées

- **Contexte** : arbitrage n°4 §4 (tests OBLIGATOIRES), mission (« pas d'écriture SQL directe »).
- **Options envisagées** : (a) simuler le remboursement par écriture de la ligne (comme
  `OverrideEtAchatsIT.cas11`) ; (b) passer par `StripeSubscriptionService.dispatch`
  (`charge.refunded`), `AppleSubscriptionService.handleNotification` (`REFUND`, vérification JWS
  simulée par `@MockitoBean AppleStoreClient`) et `GoogleSubscriptionService.handleNotification`
  (`voidedPurchaseNotification`, jeton Pub/Sub simulé par `@MockitoBean GoogleStoreClient`).
- **Choix retenu** : (b), `RemboursementEtGrantIT` : pour chaque fournisseur, achat Intégral
  (7 sessions) + GRANT INTEGRAL indépendant (5) ⇒ après remboursement total : quota = 5 (achat
  plus « qui compte »), décisions et journal identiques colonne par colonne, rejeu sans aucune
  écriture (achat, `payment_refunds`, décisions, journal), connexion suivante débitée sur le
  GRANT. Variantes : total sans GRANT (Stripe, Apple, Google : `cap = 0`) ; partiel (Stripe,
  Apple — Google n'a pas de partiel pour un pass) : l'achat et ses 7 sessions restent. Filet
  structurel : `QuotaEoAutoriteUniqueTest.paiementsSansDecisionAdmin` (aucun service ni contrôleur
  de paiement ne référence une décision admin, `CreditProration` exceptée, D-31). Fin d'un GRANT
  ⇒ achat intact : `RealtimeGrantQuotaIT.finDuGrantNeModifieJamaisLAchat` ; rachat pendant un
  GRANT ⇒ report du seul achat : `OverrideEtAchatsIT.rachatPendantGrantNeReporteQueLAchat`.
- **Impact** : tests seulement ; aucun code de paiement modifié.
- **Réversibilité** : sans objet.

### D-49 — `accessVersion` ne hache pas le solde

- **Contexte** : G-11 (D-11), débit concurrent d'une modale ouverte.
- **Options envisagées** : (a) inclure le solde dans l'empreinte ; (b) non.
- **Choix retenu** : (b). Un débit ne change aucun identifiant de décision : pas de faux 409 si
  le candidat s'entraîne pendant que la modale est ouverte (le débit d'achat ne le faisait pas
  non plus). Contrepartie assumée : le solde de l'aperçu peut retarder d'une session ; l'écriture
  relit sous verrou et reporte le vrai solde, et la réponse de l'action est exacte.
- **Impact** : `VersionAcces` inchangé. Test : `RealtimeGrantQuotaIT.debitIdempotentEtTrace`.
- **Réversibilité** : facile.

## Phase 3 ter — front des sessions EO et de Réactiver (2026-10-02)

> Branche le front admin sur D-34 et D-44 → D-46. Aucun DTO ni endpoint touché ; tout ce qui
> s'affiche est servi.

### D-50 — Champ « Sessions EO temps réel » : visibilité par le contrat D-44 + le plafond servi

- **Contexte** : aucune donnée servie ne dit « cette opération pose un GRANT » ; le contrat de la
  requête (D-44) refuse en 400 une valeur > 0 hors de `GRANT` / `REACTIVATE` / `CORRECT_PRODUCT`
  vers INTEGRAL.
- **Options envisagées** : (a) produit cible codé en dur (`=== "INTEGRAL"`) ; (b) liste des trois
  opérations (contrat) × produit cible dont `maxRealtimeEoSessions` est servi non nul.
- **Choix retenu** : (b). `AccessOperationModal` : `POSES_GRANT = [GRANT, REACTIVATE,
  CORRECT_PRODUCT]`, champ affiché si l'opération en fait partie et que le produit cible (figé par
  la carte, ou choisi) porte `maxRealtimeEoSessions`. Défaut 0, entier 0 … plafond servi ; hors
  bornes ⇒ aucun aperçu ni écriture (le serveur reste l'autorité, 400 affiché tel quel). La valeur
  part dans l'aperçu `dryRun` **et** l'écriture ; absent quand le champ est masqué. Le cumul
  (« 4 sessions restantes + 10 offertes → 14 sessions disponibles ») et la phrase « Cet accès
  manuel n'ajoute pas actuellement de sessions EO temps réel. » sont lus dans `preview`, jamais
  construits.
- **Réversibilité** : facile — si le serveur sert un jour « opérations à sessions », remplacer
  `POSES_GRANT` par ce champ.

### D-51 — Carte Intégral : soldes servis côte à côte, aucune somme

- **Choix retenu** : bloc « Sessions EO temps réel » sur la carte dont `realtimeEoSessions` n'est
  pas `null` (INTEGRAL) : la phrase `label`, puis « Achat (restantes) » = `purchaseRemaining`,
  « Accès manuel (restantes / offertes) » = `grantRemaining / grantGranted`, « Accès programmé
  (offertes) » = `scheduledGrantGranted` s'il est servi, et `info` en note ambre. `null` ⇒ « — »,
  jamais 0. `remaining` (total) n'est pas réaffiché à part : il est dans `label`.
  ⚠️ Libellés révisés par D-54 : « Accès manuel : 14 restantes sur 20 accordées », « Accès
  programmé : 10 accordées », « Achat : 3 restantes ».
- **Réversibilité** : facile.

### D-52 — Réactiver : « Fin » pré-remplie avec la valeur servie (D-34)

- **Choix retenu** : `REACTIVATE` rejoint Prolonger / Raccourcir / Corriger dans le
  pré-remplissage par `defaultEndDateInclusive` (révise la note de D-34 « champ vide »). Le
  « Début » reste vide (D-23). L'avertissement « l'achat … révoqué ne sera pas rétabli » vient de
  la phrase d'aperçu servie.
- **Réversibilité** : facile.

Maquette `maquette-admin-utilisateurs-mvp.html` mise à jour : champ de sessions (plafond servi,
mêmes conditions), bloc sessions des cartes Intégral, fin pré-remplie pour Réactiver, phrases
d'aperçu mimées.

## Ajustements finaux du propriétaire (2026-10-02)

### D-53 — Liste : date d'inscription rétablie

- **Contexte** : demande du propriétaire (révise D-39 pour cette seule colonne).
- **Choix retenu** : `AdminUserListItemDto.createdAt` était déjà servi (`users.created_at`) :
  aucun changement backend. Colonne « Inscription » (JJ/MM/AAAA, `formatParisDate`) après
  « Dernière activité » sur desktop et tablette ; ≤ 720 px, pas de ligne à part dans la carte :
  « Inscrit le … » sous l'email. La colonne « Compte » n'est pas rétablie. Maquette alignée.
- **Réversibilité** : facile.

### D-54 — Sessions : « restantes sur N accordées », jamais « offertes » pour le total de la lignée

- **Contexte** : « 14 sur 20 » laissait lire 20 comme disponible ; 20 est le total accordé sur
  la lignée (D-43 (b)), pas un solde.
- **Choix retenu** : corrigé à la source, `AdminUserMapper.sessionsEo` : `label` = « 14 sessions
  restantes — accès manuel : 14 restantes sur 20 accordées ; achat : 0 », accès programmé
  « 10 sessions accordées » (accord singulier pour 0 et 1). La phrase d'aperçu du cumul
  (« + 10 offertes → 14 disponibles ») est inchangée : 10 y désigne les sessions offertes PAR
  CETTE ACTION, qui s'ajoutent bien au disponible. Carte Intégral du front : « Accès manuel :
  14 restantes sur 20 accordées », « Accès programmé : 10 accordées », « Achat : 3 restantes ».
  Le champ de la modale reste « offertes par cet accès manuel » (nombre de l'action).
- **Impact** : `AdminUserMapper`, Javadoc `AdminRealtimeEoSessionsDto`, commentaire `api.ts`,
  `docs/api-endpoints.md`. Tests mis à jour : `AdminUserControllerIT.sessionsEoCumul`,
  `AdminAccessOperationServiceTest.ficheSessions`. Forme du DTO inchangée ; DTO admin seulement.
- **Réversibilité** : facile.

### D-55 — ESLint : trois erreurs préexistantes, hors de ce chantier

- `react-refresh/only-export-components` sur `components/ui/Toast.tsx` (`useToast` exporté avec
  le provider) et `react-hooks/set-state-in-effect` sur `components/ui/MediaPicker.tsx` et
  `components/ui/PassagePicker.tsx`. Antérieures à la console Utilisateurs, **non corrigées** à
  la demande du propriétaire ; `tsc` et le build n'en dépendent pas. Les fichiers créés ou
  refaits ici passent ESLint.

## Écarts avec la spec

- Produits `CIVIQUE` / `INTEGRAL` (GO §1) : la correction « Civique → TCF » est « Civique →
  Intégral ». Les modules ouverts sont servis à côté (GO §2) ; la maquette est mise à jour en phase 3.
- Pas de statut de compte « bloqué » (n'existe pas). Pas de dernière activité par module.
- Quota EO d'un GRANT Intégral nu : résolu par V084 (B-1, D-40 → D-49) — sessions saisies par
  l'admin à la création du GRANT ; pas de « sessions supplémentaires » sur un GRANT existant hors
  cumul par « Donner » (futur explicite, arbitrage n°3).
- Phase 3 : pas de filtre « Compte bloqué » (la notion n'existe pas). Pas de bouton générique
  « Modifier l'accès » : chaque carte propose exactement les actions servies (Prolonger,
  Raccourcir, Terminer, Corriger le produit, Donner un accès, Réactiver). « Donner un accès »
  apparaît aussi sur une carte active (programmer une décision future, GO §4). Pas de
  statistiques (D-27). Liste et fiche sur deux routes (D-26).

### D-56 — Liste : les comptes supprimés n'apparaissent plus (révise D-18)

- **Contexte** : consigne du propriétaire (2026-10-04). Dans `/users`, un compte supprimé par son
  titulaire ne doit être ni compté ni listé. D-18 les listait, avec le statut de compte servi.
- **Options envisagées** : (a) garder D-18 ; (b) un filtre « Comptes supprimés » facultatif ;
  (c) les exclure de la liste, toujours.
- **Choix retenu** : (c). `UserSpecifications.notDeleted()` (`deleted_at IS NULL`) est posé en
  tête de la spécification de `AdminUserService.list`. Il s'applique donc à tous les filtres, à la
  recherche (y compris par UUID complet) et à `totalElements`.
  - La **fiche** `/users/{id}` reste lisible par lien direct : historique d'achats et journal
    admin pour le support. Elle garde son statut « Compte supprimé ».
  - Le badge « Compte supprimé » de la **liste**, devenu inutile, est retiré.
- **Impact** : `UserSpecifications`, `AdminUserService`, `UsersPage.tsx` (+ `.module.css`),
  `AdminUserControllerIT.listeExclutLesComptesSupprimes`.
- **Réversibilité** : facile (retirer le prédicat).

### D-57 — Fiche : productions IA du compte (soumises, avec examinateur IA)

- **Contexte** : demande du propriétaire (2026-10-07) — voir sur la fiche combien de productions
  corrigées par IA la personne a soumises, et combien en temps réel avec l'examinateur IA.
- **Choix retenu** : `AdminUserDetailDto.productions` = `AdminProductionCompteursDto` (le même
  bloc que l'encart de « Productions IA », DI-35), calculé par `AdminProductionService.
  compteursDuCandidat` sur la CTE de la liste Productions IA : **depuis toujours, comptes internes
  compris, hors diagnostic**, recherche par UUID utilisateur. Le compteur est donc exactement ce
  que montre le lien `/productions-ia?q=<userId>&internes=1` (et `&examinateur=AVEC` pour le
  temps réel) — aucune seconde définition du périmètre.
  - **On compte des soumissions** : une production compte une fois quel que soit son statut
    (évaluée, non évaluable, en échec, en cours) ; la répartition par statut est servie à côté
    (`evaluees + nonEvaluables + enEchec + enCours = total`), avec EE / EO et les signalées.
  - « Avec examinateur IA » = `source = REALTIME` (DI-34).
  - Front : carte compacte dans « Progression » (deux chiffres-liens + une ligne de répartition),
    le front n'additionne rien.
- **Coût** : une requête de plus, constante — `AdminUserControllerIT.ficheCoutConstant` (1 ou 6
  productions, égalité du nombre de requêtes ; il n'existait pas de test de coût de la fiche).
- **Impact** : `AdminUserDetailDto`, `AdminUserService`, `AdminProductionService`,
  `AdminProductionReadRepository.compter`, `types/api.ts`, `UserDetailPage`. DTO admin seulement.
- **Réversibilité** : facile.

### D-58 — Écrire à un compte depuis la console : une conversation, un mail `ADMIN_MESSAGE`

- **Contexte** : demande du propriétaire (2026-10-07) — depuis `/conversations` (choisir un
  compte) et depuis la fiche `/users/:id`, envoyer un email libre (objet + texte) à un
  utilisateur, avec un gabarit à l'identité SejourFR.
- **Options envisagées** : (a) un envoi « nu », sans trace hors `email_deliveries` ; (b) ajouter
  le message à la dernière conversation ouverte du compte ; (c) une **nouvelle conversation** par
  message, objet = sujet du mail.
- **Choix retenu** : (c). `POST /api/admin/users/{id}/messages` (`AdminUserController` →
  `ConversationService.sendToUser`) crée la conversation rattachée au compte (`user_id`, statut
  `REPONDU`, non lue côté admin, non lue côté compte), son premier message signé par l'admin
  connecté, et publie `AdminMessageEvent` ; le mail `ADMIN_MESSAGE` part **après commit**
  (règles : `docs/regles/emails.md` § « Message d'un admin à un compte »). Aucune migration :
  le schéma `conversations` / `messages` suffit.
  - **Catégorie REQUIRED** (message de service, comme `SUPPORT_REPLY`) : ni préférence
    marketing/engagement, ni désabonnement ; tracé dans `email_deliveries`, relance 24 h.
  - **Réponses suivantes** : `ConversationService.reply` dans une conversation **rattachée à un
    compte** envoie désormais aussi un `ADMIN_MESSAGE` (à l'adresse actuelle du compte). Avant,
    une telle réponse n'était envoyée nulle part (« lue dans l'app » — il n'existe aucune
    messagerie in-app). Les conversations de contact gardent `SUPPORT_REPLY`.
  - **Compte supprimé** : 409 (« Ce compte a été supprimé : il ne peut plus recevoir de
    message. ») ; le bouton de la fiche est masqué pour un compte supprimé, et le sélecteur de
    `/conversations` ne les propose pas (recherche de la liste, D-56).
  - **Bornes** : objet nettoyé (blancs/CR-LF → une espace, en-tête de mail) puis 3–150 ; message
    1–5000 après retrait des blancs de bord. Pas de rate-limit (ADMIN seulement).
  - **Aperçu** : `POST …/messages/preview` rend le mail par le vrai gabarit et les mêmes
    variables (`SupportEmailComposer.adminMessageVariables`) — l'écran ne recompose ni la
    salutation ni la signature ; affiché dans une `iframe sandbox=""`.
  - **Front** : un seul composant, `features/conversations/components/ComposeMessageModal.tsx`
    (+ `RecipientPicker.tsx`, combobox sur `GET /api/admin/users?q=`). Il vit dans
    `conversations/` parce qu'il crée une conversation et appelle l'API : ce n'est pas une
    primitive d'UI, `components/ui/` reste sans appel réseau métier. `users/UserDetailPage`
    l'**importe** (destinataire fixé) — un import, pas une copie. Après envoi : depuis
    `/conversations` le fil créé s'ouvre ; depuis la fiche, la modale propose « Ouvrir la
    conversation ».
- **Impact** : `EmailType.ADMIN_MESSAGE`, `application.yaml` (gabarit), `email/admin-message.{html,txt}`,
  `EmailFormats.multilineHtml|excerpt`, `SupportEmailComposer`, `AdminMessageEvent`,
  `EmailEventListener`, `EmailDeferredRetryService`, `ConversationService`, `AdminUserController`,
  DTO `AdminUserMessageRequest` / `AdminMessagePreviewDto` ; tests `AdminUserMessageIT`,
  `AdminMessageEmailTest`, `SupportEmailComposerTest`, matrice `AdminRoutesSecurityIT`. Admin :
  `types/api.ts`, `usersApi.ts`, `ConversationsPage`, `UserDetailPage`. DTO admin seulement (web
  et mobile non concernés).
- **Réversibilité** : facile (retirer les deux routes ; les conversations créées restent des
  conversations ordinaires).
