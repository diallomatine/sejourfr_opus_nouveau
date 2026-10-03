# Proposition — Ledger unique du quota EO temps réel (B-1, option 2)

> **Statut : REPORTÉE (arbitrage du propriétaire, 2026-10-02).** Pas de V084 ni de ledger pour le MVP.
> Conservée comme documentation d'une évolution future, à reprendre quand des Intégral complets
> devront être accordés régulièrement. Arbitrages A1 → A8 non tranchés. Voir B-1 dans
> `decisions-gestion-utilisateurs.md` pour la solution MVP retenue.
>
> **Mise à jour du 2026-10-02 (arbitrages n°3 et n°4)** : le MVP retenu est la colonne de solde
> sur le GRANT INTEGRAL admin (`V084__sessions_eo_acces_admin.sql`, décisions D-40 → D-49). Le
> numéro **V084 est donc pris** : si ce ledger revient, il prendra le prochain numéro libre, et
> devra reprendre les DEUX soldes (achats et GRANT INTEGRAL). Le schéma ci-dessous n'est pas à
> jour de ce changement.

Préparé le 2026-10-02, en lecture seule (aucun fichier du dépôt modifié, SQL en lecture
seule sur la base locale). Les numéros de ligne datent de cette lecture : un autre agent modifie
en parallèle `SubscriptionService` / `OneTimeAccessService` (`currentSubscription` →
`currentPurchase` / `effectiveAccess`), ils peuvent donc bouger un peu.

**Objectif** : un Intégral accordé par l'admin (GRANT) donne les mêmes simulations orales en
direct qu'un Intégral acheté. Un seul mécanisme de crédit, un seul de débit, une seule autorité.

**Le problème, en une phrase** : le solde vit aujourd'hui sur la ligne d'ACHAT
(`user_subscriptions.realtime_eo_sessions_remaining`). Un GRANT sans achat Intégral n'a pas de
ligne où poser ce solde, d'où 0 session. Et comme `/api/realtime/eo/quota` renvoie alors `cap = 0`,
**le mobile ouvre le paywall** sur la carte « temps réel » (`realtime_launch_sheet.dart:48`,
`_locked => cap == 0`) chez un utilisateur pourtant Intégral.

---

## 1. Schéma proposé

Une seule table, en ajout pur (migration `V084`, `00_schema/`). Aucune table existante n'est modifiée.

```sql
CREATE TABLE realtime_quota_movements (
    id                   UUID          PRIMARY KEY,
    user_id              UUID          NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    kind                 VARCHAR(24)   NOT NULL
        CONSTRAINT ck_rtq_kind CHECK (kind IN (
            'OPENING_BALANCE',      -- reprise du solde historique (une fois par compte)
            'PURCHASE_CREDIT',      -- achat Intégral (plans.realtime_eo_sessions)
            'ADMIN_ACCESS_CREDIT',  -- GRANT / REACTIVATE / CORRECT_PRODUCT → INTEGRAL
            'EXPIRATION',           -- remise à zéro quand un nouveau droit ne prolonge pas l'Intégral
            'SESSION_DEBIT',        -- une simulation réellement connectée
            'ADMIN_ADJUSTMENT')),   -- correction support (remplace le PATCH absolu)
    delta                INT           NOT NULL,
    idempotency_key      VARCHAR(120)  NOT NULL,   -- ex. PURCHASE:<subId>, ADMIN_OP:<opId>, SESSION:<sessionId>
    subscription_id      UUID          NULL REFERENCES user_subscriptions (id),
    access_operation_id  UUID          NULL REFERENCES admin_access_operations (id),
    realtime_session_id  UUID          NULL REFERENCES realtime_sessions (id) ON DELETE SET NULL,
    admin_user_id        UUID          NULL REFERENCES users (id),
    reason               VARCHAR(500)  NULL,
    created_at           TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT uq_rtq_idempotence UNIQUE (user_id, idempotency_key),
    CONSTRAINT ck_rtq_signe CHECK (
           (kind IN ('OPENING_BALANCE','PURCHASE_CREDIT','ADMIN_ACCESS_CREDIT') AND delta > 0)
        OR (kind = 'SESSION_DEBIT'    AND delta = -1)
        OR (kind = 'EXPIRATION'       AND delta < 0)
        OR (kind = 'ADMIN_ADJUSTMENT' AND delta <> 0)),
    CONSTRAINT ck_rtq_trace CHECK (
           (kind <> 'PURCHASE_CREDIT'     OR subscription_id     IS NOT NULL)
        AND (kind <> 'ADMIN_ACCESS_CREDIT' OR access_operation_id IS NOT NULL)
        AND (kind <> 'ADMIN_ADJUSTMENT'    OR (admin_user_id IS NOT NULL AND reason IS NOT NULL)))
);
-- uq_rtq_idempotence (user_id, …) sert aussi l'index « mouvements d'un compte ».
COMMENT ON TABLE realtime_quota_movements IS
  'Ledger du quota de simulations orales temps réel, par COMPTE. Solde = SUM(delta). Seule source du quota.';
```

- **Solde = `SUM(delta)` du compte**, c'est la seule vérité. Pas de colonne `balance_after` ni de
  compteur stocké : avec au plus une centaine de lignes par compte, une somme ne coûte rien, et un
  seul chiffre ne peut pas diverger d'un autre.
- **Idempotence** : chaque mouvement a une clé déterministe, unique par compte. Insertion en
  `ON CONFLICT (user_id, idempotency_key) DO NOTHING` :
  - un crédit par achat : `PURCHASE:<subscription_id>` ;
  - un crédit par opération admin : `ADMIN_OP:<operation_id>` ;
  - un débit par session : `SESSION:<realtime_session_id>` (la clé de session existante) ;
  - une reprise par compte : `OPENING:V084` ;
  - une expiration par crédit qui l'a provoquée : `EXPIRATION:<clé du crédit>` ;
  - un ajustement admin par requête : `ADJUST:<UUID tiré par le client admin>`.
- **Le solde ne descend jamais sous zéro** : garanti par le verrou de compte du §4, qui
  contrôle le solde sous ce verrou avant tout débit ou ajustement négatif. SQL ne peut pas
  exprimer « la somme reste ≥ 0 » ; un IT le vérifie.
- Pour la **suppression de compte (G-8)** : `AccountDeletionService` purge le ledger avant
  `admin_access_operations` (une ligne à ajouter, la FK vers l'opération étant `NO ACTION`).

## 2. Reprise des soldes existants

**Recommandé : `INSERT … SELECT` dans la même migration V084**, sans toucher la colonne source.

```sql
INSERT INTO realtime_quota_movements (id, user_id, kind, delta, idempotency_key, subscription_id, created_at)
SELECT gen_random_uuid(), c.user_id, 'OPENING_BALANCE', c.remaining, 'OPENING:V084', c.id, now()
FROM (
  SELECT DISTINCT ON (us.user_id) us.user_id, us.id, us.realtime_eo_sessions_remaining AS remaining
  FROM user_subscriptions us JOIN plans p ON p.id = us.plan_id
  WHERE p.module_access = 'INTEGRAL'
    AND us.status IN ('ACTIVE','TRIAL','IN_GRACE','CANCELED')
    AND (us.ends_at IS NULL OR us.ends_at > now())
  ORDER BY us.user_id, us.ends_at DESC NULLS FIRST, us.id
) c
WHERE c.remaining > 0;
```

- **On ne reprend que la ligne porteuse**, c'est-à-dire l'achat Intégral couvrant dont la fin
  est la plus tardive. C'est celle que lit aujourd'hui `RealtimeQuotaService`. ⚠️ **Sommer
  toutes les lignes compterait le report en double** : à la prolongation,
  `OneTimeAccessService:154-171` recopie le reste de l'ancien pass sur la nouvelle ligne, mais ne
  met jamais l'ancienne à zéro.
- **Les lignes expirées ne sont pas reprises.** Aujourd'hui, leur solde est déjà perdu au rachat
  suivant (le report vaut 0 hors prolongation).
- **Les décisions admin ne sont pas lues par la reprise.** Le solde repris reste soumis au verrou
  « accès effectif Intégral » (§4), comme aujourd'hui où un achat révoqué ne laisse plus
  consommer.
- **Volumes locaux** : 22 lignes `user_subscriptions`, dont 7 avec un solde > 0 (102 sessions
  au total). La reprise concerne **3 comptes, soit 53 sessions** (14 + 5 + 34). Restent hors
  reprise 4 lignes expirées (49 sessions), déjà inutilisables aujourd'hui.
  `realtime_sessions` : 84 lignes (68 COMPLETED, 9 FAILED, 7 PENDING), toutes avec un
  `subscription_id`, sur 3 comptes. Elles ne sont ni relues ni réécrites.
- **Compatibilité avec la ligne rouge « migrations limitées au schéma additif (aucune
  modification de données existantes) »** : **aucune donnée existante n'est modifiée** (aucun
  UPDATE ni DELETE, colonne source intacte). Mais la migration **écrit des données** dans la
  nouvelle table. Le but de la règle est respecté, sa lettre « schéma seul » ne l'est pas : **à
  arbitrer (A1)**. La sélection SQL recopie une fois, figée, la règle de la ligne porteuse ;
  un IT la compare au choix Java (`achatRepresentatif` sans décision) sur des jeux de données
  types.
- **Variante de repli, s'il refuse toute écriture en migration** : un amorçage paresseux,
  « solde initial = colonne historique ». À la première lecture d'un compte sans ligne `OPENING`,
  l'autorité insère `OPENING` depuis la ligne porteuse. Elle impose une **date de bascule**
  (sinon un achat fait après le déploiement, dont la colonne est encore écrite par les webhooks,
  serait compté deux fois : colonne + crédit), et la colonne resterait lue indéfiniment. Plus
  fragile, déconseillée.

## 3. Crédits : achat et GRANT

**Un seul point d'écriture** : `RealtimeQuotaService.crediter(...)`, sous le verrou de compte
(§4). Deux appelants.

**Achat**
- **Où** : un nouvel écouteur `@TransactionalEventListener(phase = BEFORE_COMMIT)` sur
  l'événement **déjà publié** `PremiumAccessGrantedEvent` (par `OneTimeAccessService:192`, et par
  `SubscriptionNotificationService:29` pour Apple et Google). Le code d'achat et les webhooks ne
  changent pas d'une ligne. Le crédit est **atomique avec l'achat** : même transaction, et un
  rejeu ne republie pas l'événement (`:114-128`), la clé `PURCHASE:<subId>` couvrant le reste.
- **Combien** : `plans.realtime_eo_sessions` du plan acheté (5 / 15 / 25), figé dans `delta`.
  Une modification ultérieure du plan en console ne réécrit donc pas le passé. Un plan à 0
  (Civique) ne produit aucune ligne.
- **Prolongation** (`event.extension = true`) : on ajoute l'allocation au solde, ce qui équivaut
  au report actuel.
- **Nouvel accès** (`extension = false`) : on écrit d'abord `EXPIRATION = −solde`, puis le
  crédit. C'est la règle actuelle (« un premier achat repart de 0 + allocation ») : voir A4.
- Le Stripe récurrent (dormant) ne publie pas l'événement : il ne serait pas crédité. Le TODO
  « renouvellement » existe déjà sur les 3 voies récurrentes.

**GRANT admin**
- **Où** : dans `AdminAccessOperationService.executer`, hors `dryRun`, dans sa transaction,
  après l'insertion des décisions (`:115-117`). La clé est `ADMIN_OP:<operationId>`.
- **Quelles opérations créditent** : `GRANT INTEGRAL`, `CORRECT_PRODUCT → INTEGRAL`, et
  `REACTIVATE INTEGRAL` uniquement depuis l'état `EXPIRED`. Un `REACTIVATE` depuis `REVOKED`
  ne crédite rien : il lève le REVOKE, et le crédit de l'achat, jamais retiré, redevient
  utilisable. Sinon ce serait un double crédit. `EXTEND`, `SHORTEN` et `END` ne créditent ni ne
  retirent rien (voir A3).
- **Combien (règle simple proposée)** : on prend **le plus petit pass Intégral actif du
  catalogue dont la durée couvre la fenêtre accordée**, et on donne ses sessions. Au-delà du
  plus long pass, on donne ses sessions par tranche entamée. Avec le catalogue actuel
  (7 j → 5, 30 j → 15, 60 j → 25), cela donne :
  - 1 à 7 jours → 5 ;
  - 8 à 30 jours → 15 ;
  - 31 à 60 jours → 25 ;
  - 61 à 120 jours → 50 ;
  - etc.

  Le calcul est lu dans `plans` (aucun chiffre en dur) et servi par le `dryRun` (« +15
  simulations orales »), pour que l'admin le voie avant de valider. Le front ne recalcule rien.
- **Nouvel accès** pour un GRANT : quand la fenêtre commence maintenant et qu'aucun Intégral
  n'était effectif juste avant l'opération (l'état « avant » est déjà calculé, `:89`), on écrit
  l'`EXPIRATION` puis le crédit. Pour un GRANT **programmé dans le futur**, il n'y a pas
  d'expiration : le choix est généreux et assumé, sinon on viderait le solde d'un Intégral
  encore en cours.

**Cas demandés**

| Cas | Ledger | Effet |
|---|---|---|
| CORRECT_PRODUCT Civique → Intégral | `ADMIN_ACCESS_CREDIT` = palier de la fenêtre (précédé d'une `EXPIRATION` si le compte avait un ancien reste) | Intégral complet, sessions comprises. Le Civique ne portait aucune session. |
| CORRECT_PRODUCT Intégral → Civique | rien | Solde conservé mais inutilisable (accès effectif ≠ Intégral) |
| Prolongation par achat | `PURCHASE_CREDIT` (+ allocation), sans expiration | Cumul, comme aujourd'hui |
| EXTEND admin | rien (A3) | Les sessions restantes restent utilisables plus longtemps |
| REVOKE (END / SHORTEN) | rien | Gel : inutilisable tant que l'accès n'est pas Intégral ; à nouveau utilisable sur REACTIVATE |
| Remboursement | rien (les webhooks ne sont pas touchés) | Si l'Intégral se ferme : inutilisable, puis remis à zéro au prochain nouvel accès. Si un autre Intégral couvre encore (remboursement d'une prolongation), l'allocation remboursée reste utilisable. Aujourd'hui, la ligne précédente garde de même un solde périmé. Voir A6. |
| Fin d'accès naturelle | rien | Inutilisable ; remis à zéro au prochain nouvel accès (règle actuelle) |

## 4. Débit d'une session

**Un seul mécanisme**, `RealtimeQuotaService.debiterSession(userId, sessionId)`. Il remplace
`UserSubscriptionManager.decrementRealtimeSessions`. Il est appelé **au même endroit
qu'aujourd'hui** : `RealtimeSessionService.appendTranscript`, au passage `PENDING → ACTIVE`
(`:197-208`).

1. On pose un verrou consultatif de compte,
   `pg_advisory_xact_lock(hashtextextended('rt-quota:' || userId, 0))`. Le patron existe
   déjà dans `AccessOverrideRepository.verrouiller` et `JourneyRepository` ; c'est sa
   **3ᵉ occurrence**, à extraire dans un utilitaire partagé, conformément à la règle
   « duplication = signal ».
2. Si `SUM(delta) ≤ 0`, on n'écrit rien. La session continue sans débit, **exactement comme
   aujourd'hui**, où le `UPDATE … WHERE remaining > 0` touche 0 ligne.
3. Sinon, on insère `SESSION_DEBIT −1` avec la clé `SESSION:<sessionId>`, en
   `ON CONFLICT DO NOTHING`.

**Concurrence**
- Le verrou de ligne existant sur la session (`ownedSessionForUpdate`) garantit une seule
  transition par session.
- Le verrou de compte sérialise deux sessions du même candidat, ainsi qu'un débit concurrent
  d'un crédit ou d'un ajustement.
- La clé unique rend le débit idempotent, même si la transition était rejouée.

**Démarrage** (`start`, `:93-95`) : `canStartRealtime = accès effectif Intégral ET solde > 0`.
`realtime_sessions.subscription_id` reste renseigné **pour la traçabilité seulement** (achat
représentatif, ou `null` pour un GRANT sans achat ; la colonne est déjà nullable) et n'est plus
lu pour le quota. Rien ne change sur la reprise d'une session ni sur l'affichage
« remaining − 1 ».

## 5. Garantie d'autorité unique

- **L'autorité** : `service/realtime/RealtimeQuotaService`. On garde le nom, ce qui épargne
  4 appelants. Elle porte la lecture (`evaluate`, `remaining`) et les trois écritures
  (`crediter`, `debiterSession`, `ajuster`). Seul `RealtimeQuotaMovementManager` touche
  `RealtimeQuotaMovementRepository` (règle Controller → Service → Manager → Repository).
  L'accès effectif est lu via `SubscriptionService` (`effectiveAccess`, une fois le renommage
  fait), jamais recalculé.
- **Ce qui est supprimé** : `UserSubscriptionRepository.decrementRealtimeSessions` et
  `setRealtimeSessions` (`:59-84`), ainsi que les méthodes correspondantes de
  `UserSubscriptionManager` (`:77-91`). Ce sont des UPDATE sur `user_subscriptions` : on en
  enlève, on n'en ajoute pas.
- **Ce que plus personne n'a le droit de lire pour le quota** :
  `UserSubscription.realtimeEoSessionsRemaining`. Le getter reste utilisé uniquement par
  `EtatAbonnement:95`, qui compare l'état de la ligne d'achat. Les écritures des webhooks
  (`OneTimeAccessService:171`, `Stripe:548`, `Google:637`, `Apple:472`) restent telles quelles
  (ligne rouge), mais **la colonne ne fait plus foi** : voir A8.
- **Verrous automatisés** (pas d'ArchUnit dans le `pom`, on n'ajoute pas de dépendance) :
  - **Un test qui scanne les sources**, `QuotaEoAutoriteUniqueTest`, sur le modèle de
    `EvaluationBornesMotsSourceUniqueTest`. Dans `src/main/java`, il vérifie que :
    1. `getRealtimeEoSessionsRemaining` n'apparaît que dans `EtatAbonnement` ;
    2. `RealtimeQuotaMovementRepository` n'apparaît que dans son manager ;
    3. `RealtimeQuotaMovementManager` n'apparaît que dans `RealtimeQuotaService` ;
    4. `decrementRealtimeSessions` et `setRealtimeSessions` n'existent plus.
  - **Des IT** : achat puis débit ; GRANT nu puis débit ; deux débits concurrents avec un solde
    de 1, dont un seul passe ; rejeu d'un crédit sans doublon ; reprise V084 égale à la
    sélection Java ; Σ ≥ 0 en toutes circonstances.

## 6. Impacts et risques

**Données existantes**
- Aucune ligne existante n'est modifiée. `user_subscriptions.realtime_eo_sessions_remaining`
  continue d'être écrite par les webhooks mais **n'est plus lue**. Elle dérivera du vrai solde,
  sans que cela se voie nulle part une fois l'admin migré.
- L'index `idx_rt_session_quota` devient inutile ; on le garde pour l'instant (rien n'est
  supprimé).
- Le geste V038 et l'historique restent intacts.

**DTO lus par le mobile : forme inchangée**
- `SubscriptionStatusResponse.realtimeSessionsRemaining` (`Integer`, `:42`) est servi quand
  l'accès effectif est Intégral. Aujourd'hui, il l'est quand le plan de la ligne porteuse a
  `cap > 0`. Un GRANT Intégral affiche donc enfin son décompte (mobile
  `manage_subscription_screen.dart:190`, web `profil/abonnement/page.tsx:220`).
- `GET /api/realtime/eo/quota` `{remaining, cap}` (`RealtimeEoController:43-44`) : `cap` vaut
  l'allocation du droit Intégral courant (le plan de l'achat représentatif, sinon le palier du
  GRANT courant), et 0 sans accès Intégral. **Cela corrige le paywall à tort** (mobile
  `realtime_launch_sheet.dart:48`, web `useRealtimeEo.ts:57`).
- `RealtimeSessionDescriptor.sessionsRemaining` (`:33`) et
  `RealtimeSessionStateResponse.sessionsRemaining` (`:22`) gardent leur valeur, désormais tirée
  du ledger.
- Le catalogue `PlanPublicResponse.realtimeEoSessions` ne change pas.
- **Aucun changement sur le mobile ni sur le web.**

**Admin**
- `AdminSubscriptionDto.realtimeEoSessionsRemaining` (`:39`, mapper `:43`), affiché par ligne
  d'achat, devient trompeur. Le solde est un fait du **compte** : on le sert sur la fiche
  utilisateur.
- **Endpoint de correction** : le `PATCH /api/admin/subscriptions/{id}/realtime-sessions` (pose
  d'un solde absolu sur une ligne, sans journal) est **remplacé** par
  `POST /api/admin/users/{id}/realtime-sessions/adjustments`, qui prend
  `{delta, reason, expectedBalance, clé}`. Il écrit `ADMIN_ADJUSTMENT` avec l'admin et le motif,
  et répond 409 si le solde attendu a changé.
- On y gagne un journal, que l'ancien endpoint n'avait pas (`AdminSubscriptionService:79-80`,
  « la trace est la ligne de log »).
- L'ancien endpoint, son DTO, `UserSubscriptionMapper:43`, ainsi que `subscriptionsApi.ts:34`
  et `SubscriptionsPage.tsx:440-484` côté admin, sont supprimés lors de la finalisation du front
  admin (refonte = suppression).

**Risques**
1. Interprétation de la ligne rouge sur deux points : les données insérées en migration (A1),
   et une écriture ajoutée dans la transaction d'achat via l'écouteur (A2).
2. Régression du débit : couverte par des IT de concurrence et d'idempotence.
3. Coût Gemini des sessions offertes par GRANT : il dépend de la règle de palier (A3).
4. Cas généreux assumés : un GRANT futur n'expire rien ; une prolongation remboursée reste
   utilisable (A6).
5. Collision avec l'agent parallèle : on s'appuie sur `effectiveAccess` / `currentPurchase` après
   son renommage. Il faut sérialiser les deux chantiers sur `SubscriptionService`,
   `OneTimeAccessService` et `RealtimeQuotaService`.
6. Le Stripe récurrent dormant n'est pas crédité : c'est déjà un TODO.
7. Ordre de purge à la suppression de compte : ligne à ajouter, couverte par l'IT existant.

---

## Alternatives écartées (une ligne chacune)

- **Option 1 (statu quo)** : refusée par le propriétaire (un GRANT nu donne 0 session et le
  paywall s'affiche à tort).
- **Option 3 (colonne de solde sur `access_overrides` + `realtime_sessions.access_override_id`)** :
  deux cibles de débit, contraire à « ne pas dupliquer le débit ».
- **Revenir au comptage des `realtime_sessions` (modèle V016)** : ne sait exprimer ni crédit de
  GRANT, ni ajustement, ni cumul (raison de V019).
- **Compteur stocké `balance` ou `balance_after`** : deux représentations du même chiffre ; la
  somme suffit vu les volumes.
- **Écouteur `AFTER_COMMIT` + rattrapage paresseux** : fenêtre de crédit perdu, et le rattrapage
  impose une date de bascule.
- **Reprise Java au démarrage (ApplicationRunner)** : une écriture de données au boot, moins
  traçable qu'une migration.
- **Amorçage paresseux depuis la colonne** : variante de repli du §2 seulement (bascule
  nécessaire, colonne lue à vie).

## Points à arbitrer par le propriétaire

- **A1** — Reprise par `INSERT … SELECT` dans V084 (écriture dans une table NEUVE, aucune donnée
  existante modifiée) : acceptée comme compatible avec la ligne rouge ? *Recommandé : oui.*
- **A2** — Crédit d'achat écrit **dans la transaction d'achat** par un écouteur `BEFORE_COMMIT`
  (code d'achat et webhooks inchangés) : accepté ? Sinon, `AFTER_COMMIT`, qui laisse une petite
  fenêtre de crédit perdu, compensable par l'admin. *Recommandé : BEFORE_COMMIT.*
- **A3** — Règle de palier d'un GRANT (5 / 15 / 25, puis par tranche de 60 j), et `EXTEND` admin
  sans crédit. *Recommandé : tels quels.* L'alternative : `EXTEND` crédite le palier de la durée
  ajoutée.
- **A4** — Remise à zéro quand un nouveau droit ne prolonge pas un Intégral (règle actuelle,
  *recommandé*), ou conservation du reste à vie (plus simple, plus généreux, change le
  comportement actuel).
- **A5** — Un GRANT Intégral posé sur un achat Intégral en cours crédite aussi son palier
  (équivalent d'un rachat). *Recommandé : oui.*
- **A6** — Remboursement : aucune reprise des sessions (webhooks intouchés). *Recommandé : oui.*
- **A7** — Remplacer le `PATCH` absolu par ligne d'achat par un ajustement journalisé par compte,
  l'ancien endpoint étant supprimé avec la finalisation du front admin. *Recommandé : oui.*
- **A8** — Garder écrite, mais plus jamais lue, la colonne `realtime_eo_sessions_remaining`
  (ligne rouge) ; arrêter de l'écrire et la supprimer dans un chantier ultérieur, quand la ligne
  rouge sera levée. C'est une tension assumée avec « refonte = suppression immédiate ».

## Estimation

- **Backend, environ 20 fichiers de code principal** :
  - **Créés** : migration V084, entité, enum `kind`, repository, manager, écouteur, utilitaire
    de verrou consultatif, DTO et endpoint d'ajustement.
  - **Modifiés** : `RealtimeQuotaService` (réécrit), `RealtimeSessionService`,
    `SubscriptionStatusService`, `RealtimeEoController`, `AdminAccessOperationService` et son
    aperçu, `AccountDeletionService`, `UserSubscriptionRepository` et `UserSubscriptionManager`
    (retraits), `AccessOverrideRepository` et `JourneyRepository` (verrou extrait).
  - **Supprimés** (avec la finalisation du front admin) : l'ancien endpoint admin et son DTO,
    plus le champ DTO admin.
- **Tests backend, environ 10 fichiers** :
  - **Réécrit** : `RealtimeQuotaServiceTest`.
  - **Créés** : un IT ledger (concurrence et idempotence), un IT de reprise V084, un IT de
    crédit achat et GRANT, un test scanner d'autorité unique.
  - **Mis à jour** : `RealtimeSessionServiceTest`, `UserSubscriptionManagerIT`,
    `AdminSubscriptionControllerIT`, et un IT d'opérations admin.
- **Front admin, environ 4 fichiers** : `types/api.ts`, `subscriptionsApi.ts`,
  `SubscriptionsPage.tsx`, fiche utilisateur.
- **Mobile 0, web 0.**
- **Docs** : `docs/regles/paiements.md` (§ quota), `docs/admin/utilisateurs/decisions-gestion-utilisateurs.md`
  (B-1 clos + D-30+), `docs/api-endpoints.md`.

---

## Annexe — cartographie de l'existant (lecture / écriture du solde)

Chemins sous `backend_sejourfr/src/main/java/com/sejourfr/app/` sauf mention.

| Rôle | Emplacement |
|---|---|
| Allocation par plan (lecture) | `entity/Plan.java:62-63,120` ; migrations V018, V113, V114 (Intégral 7 j = 5, 1 mois = 15, 2 mois = 25 ; Civique 0) |
| Colonne de solde | `entity/UserSubscription.java:130-131,264-266` ; migration V019 (création + backfill) ; V038:114,141 (geste) |
| **Écriture** à l'achat one-time (report + allocation) | `service/billing/OneTimeAccessService.java:149-171` (lit `currentSubscription` `:155`) |
| **Écriture** récurrent (création seule) | `StripeSubscriptionService.java:547-548`, `GoogleSubscriptionService.java:636-637`, `AppleSubscriptionService.java:471-472` |
| **Écriture** débit | `repository/UserSubscriptionRepository.java:64-70` ← `manager/UserSubscriptionManager.java:81-83` ← `service/realtime/RealtimeSessionService.java:197-208` |
| **Écriture** ajustement admin | `UserSubscriptionRepository.java:78-84` ← `UserSubscriptionManager.java:89-91` ← `service/AdminSubscriptionService.java:82-94` ← `controller/AdminSubscriptionController.java:70-75` (`PATCH /api/admin/subscriptions/{id}/realtime-sessions`, DTO `AdminSetRealtimeSessionsRequest`) |
| **Lecture** autorité | `service/realtime/RealtimeQuotaService.java:52-67` (ligne porteuse = `currentSubscription`) |
| Lecture : démarrage / reprise / état | `RealtimeSessionService.java:93-95,109,164,171,284,296` |
| Lecture : `/quota` | `controller/RealtimeEoController.java:41-45` |
| Lecture : statut Premium | `service/billing/SubscriptionStatusService.java:27-35` (exposé si `cap > 0`) |
| Lecture : admin | `mapper/UserSubscriptionMapper.java:43` → `dto/AdminSubscriptionDto.java:39` |
| Lecture : comparaison d'état (`updated_at`) | `service/billing/EtatAbonnement.java:62,95` |
| Rattachement de session | `realtime_sessions.subscription_id` (V016, nullable, SET NULL) ; `RealtimeSessionService.java:109` |
| DTO mobile | `mobile_sejourfr/lib/core/models/billing_models.dart:430,444` (`realtimeSessionsRemaining`) ; `realtime_models.dart:47,81,100-106,125,137` (`sessionsRemaining`, `RealtimeQuota{remaining,cap}`) ; `screens/tcf_production/realtime/realtime_launch_sheet.dart:48` (`cap == 0` ⇒ paywall) |
| DTO web | `web_sejoufr/lib/types.ts:2847,2867-2870,2877,3922` ; `app/_components/production/useRealtimeEo.ts:53-71` ; `app/(app)/profil/abonnement/page.tsx:220` |
| DTO admin | `admin_sejourfr/src/types/api.ts:679` ; `src/api/subscriptionsApi.ts:34` ; `src/features/subscriptions/SubscriptionsPage.tsx:440-484` |
