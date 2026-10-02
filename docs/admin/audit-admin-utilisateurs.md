# Audit — Admin / Gestion des utilisateurs (phase 1 de `spec-admin-utilisateurs-v2.md`)

> Date : 2026-10-02 · Branche : `develop` · Aucune modification de code, de schéma ni de donnée.
> SQL en lecture seule sur la base **locale** (`sejourfr_db`, données de dev : 62 comptes, 26 lignes
> `user_subscriptions`) — **aucun chiffre de production n'a été mesuré**.
> Légende : **[V]** vérifié dans le code / la base · **[S]** supposé, à confirmer.
> Chemins Java relatifs à `backend_sejourfr/src/main/java/com/sejourfr/app/`.

---

## A. État actuel

### A.1 Modèle `User` (§3.1-1)

`entity/User.java` [V] :

| Besoin spec | Champ | Remarque |
|---|---|---|
| Nom | `first_name`, `last_name` (l.40-44) | nullables (comptes Google/Apple/mobile sans profil complet) |
| Email | `email` (l.27) | unique ; réécrit `deleted-<id>@anon.sejourfr` à la suppression (`User.anonymize`, l.150-167) |
| Inscription | `created_at` (l.75) | |
| Dernière connexion | `last_login_at` (l.78) | écrit **seulement** au login mot de passe / social (`AuthService:82`, `SocialAuthService:135,149,169`). Un `refresh` de jeton ne le met **pas** à jour : c'est « dernière authentification explicite », pas « dernière ouverture de l'app » |
| Statut compte | `is_active` (l.72), `deleted_at` (l.81) | `is_active=false` n'est posé **que** par l'anonymisation (`User.anonymize`). **Aucune notion de blocage admin** : aucun appelant de `setActive` sur `User` |
| Divers utiles | `role`, `auth_provider`, `target_procedure`, `target_level`, `exam_date`, `is_internal` (l.133, comptes seed/internes), `signup_platform`, `signup_source` | |

Statuts de compte réellement exprimables : **Actif** / **Supprimé (anonymisé)**. « Compte bloqué » n'existe pas → hors MVP (§13).

### A.2 Authentification et rôle ADMIN (§3.1-2)

- JWT access 60 min (`application.yaml:249`, prod `JWT_ACCESS_TTL_MIN`), refresh 30 j. Claims : `sub`, `type`, `email`, `role` (`security/JwtService.java:46-49`). **Aucun claim d'accès / de plan** [V].
- `JwtAuthenticationFilter.java:53-59` recharge l'utilisateur **en base à chaque requête** (`AppUserDetailsService:23-35`, autorité `ROLE_<role>`).
- `/api/admin/**` → `hasRole("ADMIN")` (`security/SecurityConfig.java:101`). 401 via `authenticationEntryPoint`, 403 via `accessDeniedHandler` (l.65-69) [V].
- Admin courant : `security/CurrentUser.get()` (lecture du contexte de sécurité) — c'est ce qu'il faudra utiliser pour `createdBy`.
- Matrice de droits testée : `AdminRoutesSecurityIT`, `AuthenticatedRoutesSecurityIT` (tout nouvel endpoint admin s'y ajoute — `backend_sejourfr/CLAUDE.md:154`).
- Remarque annexe [V] : le filtre JWT ne lit pas `isEnabled()` — un compte anonymisé garde son jeton d'accès jusqu'à expiration (≤ 60 min) ; le refresh, lui, est refusé (`SessionService:106`). Sans incidence ici.

### A.3 Achats / pass / abonnements (§3.1-3, 3.1-5)

**Une seule table porte à la fois l'achat ET l'accès : `user_subscriptions`** (`V002__schema_billing.sql:38-58`, entité `entity/UserSubscription.java`). Une ligne = un achat (Stripe / Apple / Google), clé unique `(source, original_transaction_id)` (V002:58). Ses colonnes `status` + `starts_at`/`ends_at` **sont** l'accès : il n'existe aucune autre représentation.

**Catalogue réel** (`plans`, lecture locale, cohérent avec `docs/setup-paiement-one-time.md` et `docs/bascule-prix-integral.md`) [V] :

| Plan.code | `module_access` | Type | Actif | Durée |
|---|---|---|---|---|
| `CIVIQUE_PASS_3M` / `CIVIQUE_PASS_1Y` | CIVIQUE | ONE_TIME | oui | 90 / 365 j |
| `INTEGRAL_PASS_7J` / `_1M` / `_2M` | INTEGRAL | ONE_TIME | oui | 7 / 30 / 60 j |
| `INTEGRAL_PASS_SPRINT` / `_3M` / `_1Y` | INTEGRAL | ONE_TIME | **non** (V114, conservés) | 42 / 90 / 365 j |
| 6 plans récurrents `CIVIQUE_*` / `INTEGRAL_*` (+ `*_3MOIS` legacy) | CIVIQUE / INTEGRAL | SUBSCRIPTION | **non** (dormants) | — |
| `FREE` | NONE | — | oui | ignoré par `covers` |

**Granularité réelle — écart majeur avec la spec et la maquette** [V] :
- L'enum produit est `enums/ModuleAccess.java` : `NONE | CIVIQUE | INTEGRAL`. **Il n'existe aucun produit « TCF » seul.** `INTEGRAL` = Civique **+** TCF (`hasCivique()` vrai pour CIVIQUE et INTEGRAL, `hasTcf()` vrai pour INTEGRAL seulement — l.15-22).
- **Intégral est donc un pack** ; Civique est inclus dans Intégral. Aucune granularité niveau/mention (pas de « TCF B1 », pas de « Civique NAT ») : la démarche et le palier sont des données du profil (`users.target_*`), sans effet sur l'accès.
- Le droit consommé par le code est **par module** (`enums/Module.java` : `CIVIQUE | TCF`) via `hasCivique` / `hasTcf`.
- La maquette (`maquette-admin-utilisateurs-mvp.html`) montre un produit « TCF » à 39,99 € : **il n'existe pas**. La correction « Civique → TCF » se traduit en réalité par **« Civique → Intégral »**.

**Abonnements auto-renouvelables (signalement §2.1)** [V] : le code récurrent existe et reste **volontairement dormant** (`docs/regles/paiements.md` § « RÉVERSIBILITÉ — ne JAMAIS supprimer le code abonnement ») : `StripeSubscriptionService` (handlers `customer.subscription.*`), branches récurrentes d'`AppleSubscriptionService` / `GoogleSubscriptionService`, `SubscriptionCancellationService`, flag `sejourfr.billing.mode` (`BillingMode`, défaut `ONE_TIME`). En base locale, **2 lignes** pointent vers des plans récurrents (`INTEGRAL_QUARTERLY` Stripe, `INTEGRAL_MONTHLY` Apple), toutes deux `auto_renew = false` (seed / historiques). **En production : non mesuré** [S] — requête à passer : `SELECT p.code, s.status, s.auto_renew, count(*) FROM user_subscriptions s JOIN plans p ON p.id=s.plan_id WHERE p.purchase_type='SUBSCRIPTION' GROUP BY 1,2,3;`. Le modèle override ne crée aucune logique de renouvellement ; si le mode `SUBSCRIPTION` était un jour réactivé, les webhooks récurrents réécrivent `ends_at` **de leur propre ligne d'achat** uniquement — compatible avec des overrides stockés à part.

**Empilement des pass** [V] (`service/billing/OneTimeAccessService.java:139-166`) : un rachat prolonge depuis la fin d'accès **achats** courante de module ≥ (`SubscriptionService.currentEndForAtLeast`, l.104-116), mais la nouvelle ligne a `starts_at = now` et `ends_at = base + durée`. Les fenêtres des lignes se **chevauchent** ; l'accès se lit comme « au moins une ligne couvre t ». Conséquence observée : rembourser le **premier** pass d'une pile ne raccourcit pas le second (il couvre déjà depuis son propre achat). Hors périmètre, mais à connaître pour l'affichage « Début / Fin » par achat.

Annexes : `payment_refunds` (remboursements, V074), `purchase_intent`, `processed_external_events` (idempotence webhooks), `legacy_pass_compensations` (geste V038), `free_entitlement_usage` (gratuités EE/EO, sans rapport avec l'accès payant).

### A.4 Où l'accès est calculé aujourd'hui (§3.1-4) — **centralisé, une autorité**

Autorité unique [V] : **`service/SubscriptionService.java`**
- `covers(UserSubscription, Instant)` (l.176-194) : statut ∈ {ACTIVE, TRIAL, IN_GRACE, CANCELED}, plan ≠ FREE, `ends_at` null ou **strictement après** t → borne de fin **exclusive** (`endsAt.isAfter(now)`).
- `currentAccess` (l.68-87) → `(ModuleAccess le plus permissif, fin la plus tardive)` ; `effectiveModuleAccess`, `isPremium`, `hasCivique`, `hasTcf` (l.41-61) en dérivent.
- `currentSubscription` (l.133-143) → **la ligne d'achat** « qui compte » (INTEGRAL > CIVIQUE, puis fin la plus tardive).
- `currentEndForAtLeast` (l.104-116) → base de prolongation d'un pass.
- Aucun cache serveur (`@Cacheable` absent du dépôt hors rate-limit/Azure) : relu en base à chaque appel [V].

Points d'appel (tous passent par ce service ; aucune copie de la règle en SQL — les requêtes d'emails « ne font que borner », `repository/EmailScenarioRepository.java:23-26`) [V] :

| Lecture | Appelants |
|---|---|
| `hasTcf` | `ProductionAccessService:263,319,370,398` · `SkillAccessService:116` · `SkillAnalysisAccessService:78,97` · `FreeExamEntitlementService:153` · `ExamenBlancAccessService:101` · `AttemptService:950` · `diagnostictcf/TcfReassessmentService:139` |
| `hasCivique` | `ExamenBlancAccessService:100` · `AttemptService:949` · `diagnosticcivique/CivicDiagnosticService:192` · `journey/JourneyReadService:235,616` · `plancivique/CivicPlanService:280,604,708` |
| `isPremium` (agrégat) | `AttemptService:158` (mode démo d'un TRAINING) |
| `currentAccess` → DTO `/me` et login | `AuthService:119,249` · `SocialAuthService:179` → `AuthenticatedUser.from` (`dto/AuthenticatedUser.java:59-79` : `isPremium`, `hasCivique`, `hasTcf`, `premiumEndsAt`) |
| `currentSubscription` (**ligne d'achat**) | `BillingController:124` (`GET /api/billing/subscription-status`) · `ReceiptVerificationService:74` (réponse de `verify-receipt`) · `realtime/RealtimeQuotaService:45` (quota EO temps réel) · `BillingService:398` (proration Civique→Intégral) · `OneTimeAccessService:151` (report du solde EO) · `SubscriptionCancellationService:64` · `AccountDeletionService:87` |
| `covers` direct | `email/automation/EmailAutomationService:155` · `PremiumAccessEndResolver:37-77` |

🛑 **Le point structurant** : la moitié « verrous » (hasX) est déjà sur une autorité unique et se branchera toute seule sur un accès effectif enrichi. La moitié « `currentSubscription` » rend **une ligne d'achat** et sert de statut d'accès à `subscription-status` / `verify-receipt` / quota EO : ces lectures **ignoreraient** un GRANT (aucune ligne) et **contrediraient** un REVOKE (la ligne d'achat couvre toujours).

### A.5 Lecture par les fronts (point d'attention 2)

**Web** [V] : l'accès vient de `/api/auth/me` (`hasCivique` / `hasTcf`), chargé à l'ouverture de l'app (`web_sejoufr/lib/auth-context.tsx:54`) et par `refreshUser`. `authApi.me()` purge les caches mémoire porteurs de `locked` quand la signature `id|hasCivique|hasTcf|premiumEndsAt` change (`lib/api.ts:210-217, 568-571`). `subscription-status` n'est lu que pour l'affichage « Mon pass » : `app/(app)/profil/page.tsx:77,149`, `profil/abonnement/page.tsx:38,139` (`moduleAccess === "INTEGRAL"`), `paiement/recapitulatif/page.tsx:93,154` (rang du module pour l'upgrade). Les `locked` des grilles sont servis (`docs/regles/freemium.md`).

**Mobile** [V] — 🛑 **dérivation côté client** :
- Démarrage, login, inscription : `/api/auth/me` **puis** `/api/billing/subscription-status`, et le second **écrase** le premier (`mobile_sejourfr/lib/core/auth/auth_controller.dart:116-123, 243-246`, `_applyStatus` l.194-201).
- `SubscriptionStatusResponse.hasCivique/hasTcf` sont **recalculés à partir de `moduleAccess`** (`lib/core/models/billing_models.dart:449-451`) : `hasTcf ⇔ moduleAccess == integral`. La valeur `"TCF"` est parsée (`ModuleAccess.tcf`, l.67-79) mais **ne donne ni Civique ni TCF**.
- Rafraîchi ensuite **uniquement** après un achat / une restauration (`refreshSubscriptionStatus`, l.158-183, appelé par `billing_controller.dart:429,592`). Aucun rafraîchissement au retour au premier plan (aucun `AppLifecycleState.resumed` côté auth).
- Les `locked` servis (17 sources `keepAlive`) se relisent sur `accesRevisionProvider`, émis au même seul endroit.
- Persistance : `flutter_secure_storage` (dernier `AuthUser` connu) + `shared_preferences`. **Pas de Drift / base locale offline-first** (`pubspec.yaml:23,32`).
- Parsing tolérant : `source`, `status` inconnus → `null` (`billing_models.dart:91-129`) ; « Géré par » affiche `—` (`manage_subscription_screen.dart:261-266`).

### A.6 Webhooks, RTDN, restauration Apple (§3.1-7) et remboursements (§3.1-8)

Mode actuel `ONE_TIME` [V] :

| Canal | Ce qui est écrit | Portée |
|---|---|---|
| Stripe `checkout.session.completed` / `async_payment_succeeded` | `OneTimeAccessService.grantOneTimeAccess` : **insère** une ligne ; rejeu ⇒ renvoie la ligne existante, **aucune écriture** (l.110-128) | sa propre ligne |
| Stripe `charge.refunded` / `charge.dispute.closed` (lost) | ligne retrouvée par `(STRIPE, payment_intent)`, verrou `FOR UPDATE`, `status=REFUNDED` si total, `payment_status` PARTIALLY_/REFUNDED, ligne `payment_refunds` (`StripeSubscriptionService:400-406, 432-447, 476-498`) | sa propre ligne |
| Apple `verify-receipt` + « Restaurer » | `grantOneTimeAccess` → rejeu idempotent, 409 si reçu d'un autre compte | sa propre ligne |
| Apple ASSN `REFUND` / `REVOKE` | même schéma, verrou puis `REFUNDED` (`AppleSubscriptionService:249-275`) ; `REFUND_REVERSED` ignoré | sa propre ligne |
| Google `verify-receipt` | `grantOneTimeAccess` | sa propre ligne |
| Google RTDN `voidedPurchaseNotification` | ligne par `(GOOGLE, purchaseToken)`, verrou, `REFUNDED` (`GoogleSubscriptionService:466-482`) | sa propre ligne |

Conclusions [V] :
- **Aucun canal ne recalcule ni ne supprime les droits d'un utilisateur dans leur ensemble** : chacun ne touche que la ligne de son achat, retrouvée par sa clé de réconciliation. Aucun `DELETE` sur `user_subscriptions` hors cascade de suppression physique d'un `users` (qui n'arrive pas : la suppression de compte anonymise).
- ⇒ Des overrides stockés **dans une autre table** survivent par construction à tout webhook / RTDN / restauration (cas §11-6).
- Un remboursement total pose `REFUNDED` sur la ligne : l'achat cesse de couvrir ; il ne toucherait pas un GRANT stocké ailleurs (cas §11-11). Partiel ⇒ accès conservé.
- Exception écrite qui **lit** l'état d'accès dans le flux d'achat : la base de prolongation (`OneTimeAccessService:139-143`) et la proration Stripe (`BillingService:393-405`). Voir G-5.

### A.7 Mécanisme proche d'un override (§3.1-9)

[V] **Aucun.** L'existant le plus proche :
- **V038 « geste envers les anciens acheteurs »** : migration one-shot qui a **réécrit `ends_at` des lignes d'achat** (`GREATEST(ends_at, now()) + N j`) et remis `EXPIRED/CANCELED → ACTIVE`, tracée dans `legacy_pass_compensations` (état d'avant). C'est exactement le contre-modèle de la spec (achat modifié) ; la table d'audit est spécifique, non réutilisable.
- **Admin `/subscriptions`** : `POST /api/admin/subscriptions/{id}/cancel` (résiliation, utile surtout au récurrent dormant) et `PATCH /api/admin/subscriptions/{id}/realtime-sessions` (pose le solde EO, `UPDATE` en masse, trace = un `log.info`) — `controller/AdminSubscriptionController.java:61-75`.
- Pas de seed d'accès « lifetime » côté prod ; `covers` accepte `ends_at NULL` (0 ligne locale).

### A.8 Dates (§3.1-6)

[V] `user_subscriptions.starts_at` `timestamptz NOT NULL`, `ends_at` `timestamptz` nullable, `purchased_at` `timestamptz` immuable (V079). Fin **exclusive** (`covers` : `endsAt.isAfter(now)`). Les fins d'achat sont **à l'heure de l'achat**, pas à minuit : `Instant.plus(N, DAYS)` = N × 24 h (en local : 03:03, 23:12, 13:17…). Europe/Paris n'est utilisé qu'à l'**affichage** et au filtre « Achats du mois » (mois civil de Paris, début inclus / fin exclue). `users.exam_date` est un `LocalDate`.

⇒ La convention §2.5 (instant `timestamptz`, fin exclusive) **est déjà celle du dépôt** ; seule nouveauté : aligner les fins d'**override** sur minuit Paris. Deux formes cohabiteront à l'écran : fin d'achat « 01/11 à 14:37 » vs fin d'override « 31/10 inclus ». Voir G-7.

### A.9 Caches et délai de prise en compte (§3.1-10)

| Couche | Mécanisme | Délai réel [V sauf mention] |
|---|---|---|
| Backend | aucun cache ; accès relu en base à chaque requête | **immédiat** : tout 403 / `locked` servi suit au prochain appel |
| JWT | aucun claim d'accès | rien à invalider |
| Web | `user` en état React (rechargé au chargement de page et `refreshUser`) ; caches mémoire purgés quand la signature d'accès de `/me` change | prochain chargement de page / prochain `refreshUser` |
| Mobile | `AuthUser` en mémoire + `secure_storage` ; écrasé par `subscription-status` au démarrage ; aucun refresh au retour au premier plan | **prochain démarrage à froid** (ou achat/restauration). Hors ligne : dernier état connu, sans limite de durée |

Conséquence : un **REVOKE** est opposé immédiatement par le serveur (403), l'app mobile affichant encore « débloqué » jusqu'au prochain démarrage ; un **GRANT** est autorisé immédiatement par le serveur, mais l'app mobile montre ses cadenas (et pousse le paywall) jusqu'au prochain démarrage. Le web suit au rechargement. Accepté par §10 pour l'offline ; à documenter au support.

### A.10 Concurrence (§3.1-11)

[V] Webhooks : `processed_external_events` + clé unique `(source, original_transaction_id)` + `UserSubscriptionManager.verrouiller` (`SELECT … FOR UPDATE`, l.64-71) dans les remboursements. Patron de sérialisation par utilisateur déjà en place : verrou consultatif `JourneyManager.verrouillerLaCreation`. Webhook et admin n'écriraient **jamais la même ligne** (achats vs overrides) : pas de conflit d'écriture. Les risques réels sont admin ⇄ admin sur le même couple (user, produit) et la modale ouverte sur un état périmé (cf. C.6).

### A.11 Audit log (§3.1-12)

[V] **Aucun audit log générique.** Tables du dépôt contenant « log/event/history » : `audio_question_generation_logs`, `email_campaign_log`, `analytics_event`, `user_funnel_events`, `journey_assessment_event`, `processed_external_events`, `progression_prediction_log` — toutes spécifiques. `legacy_pass_compensations` est un audit one-shot. L'ajustement admin des sessions EO n'a qu'un `log.info` (`docs/regles/paiements.md`).

### A.12 API et front admin (§3.1-13, point 9)

Backend [V] : pas d'endpoint `/api/admin/users` (aucune occurrence). Pagination : `dto/PageResponse` + `Specification + Pageable` (`AdminSubscriptionService:69`, `specification/UserSubscriptionSpecifications.java:44-56` : recherche `lower(email|firstName|lastName|fullName) LIKE`, échappement des jokers — réutilisable pour `User`). ⚠️ `AdminSubscriptionDto` expose `originalTransactionId` / `externalTransactionId` **en clair** (dont le `purchaseToken` Google) : à ne pas reprendre dans les nouveaux DTO (§9).

Admin front [V] (`admin_sejourfr/`) : React 19 + TanStack Query + CSS Modules ; routes dans `src/App.tsx` (l.47-92, pas de page utilisateurs ; `admin_sejourfr/CLAUDE.md` § Roadmap : « Clients / utilisateurs : pas encore d'API » et « créer `features/users/` sur le modèle de `features/subscriptions/` »). Réutilisables : `components/ui/{Pagination, DataTable.module.css (tableWrap + cardTable), Modal, Panel, Tag, Button, Form, PageHeader, RowMenu, Toast, Spinner}` ; modèle de liste à état dans l'URL `features/subscriptions/useSubscriptionListParams.ts` ; client `api/http.ts` (refresh JWT, `HttpError`). Types miroirs `src/types/api.ts` (`ModuleAccess = "NONE" | "CIVIQUE" | "INTEGRAL"`, l.608).

### A.13 Progression disponible (§3.1-14)

[V] Tous les services utilisateur sont paramétrés par `userId`, mais :
- 🛑 **`JourneyService.lire(userId, module)` ÉCRIT** (`service/journey/JourneyService.java:160-161, 444-447` : `@Transactional`, création du cycle à la première lecture, réinitialisation au lancement V082). Une fiche admin qui l'appellerait **créerait ou archiverait le Plan du candidat**. Interdit pour l'admin.
- Lisibles sans effet de bord, par requête directe :
  - **Plan / cycle** : `journey` (`module`, `status` EN_COURS/EN_ATTENTE/HISTORISE, `entry_level`, `exit_level`, `target_level`, `created_at`) + `journey_step` (`closed_at` ⇒ progression « n étapes closes / total ») ; historique en lecture seule `JourneyHistoryService.lire` (l.88).
  - **Diagnostics** : `diagnostic_sessions` (EE/EO initial, `status`, `completed_at`), `tcf_diagnostic_sessions`, `civic_diagnostic_sessions`, `diagnostic_run` (tunnel).
  - **Niveau** : `journey.entry_level` / `exit_level` (valeurs persistées, lues telles quelles, D-12).
- Coûteux / à sortir du MVP : moteur de progression (`ProgressionExamensService`, état pédagogique servi), maîtrise par compétence, « progression principale » civique au sens de l'écran `/progression` — calculs lourds, et le CLAUDE.md interdit au front de reclasser des nombres.

### A.14 Dernière activité (§3.1-15)

[V] **Pas de colonne stockée**, mais une **autorité existe** : la vue `v_derniere_activite_entrainement` (`V073__schema_emails.sql:141-173`) = `max` de 4 actes (réponse QCM, production EE/EO, petit sujet, session temps réel), avec index dédiés. Utilisée par les emails d'engagement (`docs/regles/emails.md:169`). Pour une page de 25 lignes : `WHERE user_id = ANY(:ids)` ; local : 1,3 ms pour 25 comptes (tables minuscules, scans séquentiels). Coût prod non mesuré [S] — la poussée du prédicat dans le `UNION ALL … GROUP BY` est attendue mais à vérifier par `EXPLAIN` en phase 2. **Par module** (dernière activité TCF vs Civique) : non disponible dans la vue ; dérivable via `attempts.module`/`epreuve` mais requête supplémentaire → hors MVP proposé. Alternative « dernière connexion » : `users.last_login_at` (sens restreint, cf. A.1).

---

## B. Matrice des écarts

| # | Fonctionnalité de la spec | État | Commentaire |
|---|---|---|---|
| 1 | Rechercher par email / nom / ID | 🟠 | prédicats `LIKE` existants sur `UserSubscription` → à transposer à `User` ; ID = égalité UUID |
| 2 | Liste paginée serveur | 🟠 | `PageResponse` + `Pagination.tsx` réutilisables ; endpoint à créer |
| 3 | Badges d'accès par produit + statut (Actif/Programmé/Expiré/Révoqué/Aucun) | 🔴 | aucun statut par produit ; « Programmé » et « Révoqué » n'existent pas |
| 4 | Prochaine fin | 🟠 | `currentAccess.endsAt` = fin la plus tardive tous modules, pas « la plus proche par produit » |
| 5 | Dernière activité en liste | 🟠 | vue V073 existante ; coût par page à mesurer |
| 6 | Statut compte | ✅ | Actif / Supprimé (`is_active`, `deleted_at`) ; pas de « bloqué » |
| 7 | Filtres accès TCF / Civique / sans accès / expiré | 🔴 | stratégie de requête à créer (C.5) |
| 8 | Filtre « Accès manuel » | 🔴 🗄 | dépend de la table d'overrides |
| 9 | Fiche : bloc Accès par produit, origine, alertes | 🔴 | |
| 10 | Fiche : historique des achats lecture seule | 🟠 | données complètes (`user_subscriptions`, `payment_refunds`, montant figé, `payment_status`) ; DTO tronqué à créer |
| 11 | Fiche : progression | 🟠 | lecture directe `journey`/`journey_step`/sessions de diagnostic ; **ne jamais appeler `JourneyService.lire`** |
| 12 | Fiche : compte | ✅ | champs présents |
| 13 | Override GRANT / REVOKE, invariant « un courant par couple » | 🔴 🗄 | nouvelle table |
| 14 | Calcul d'accès effectif unifié | 🟠 | autorité unique déjà là (`SubscriptionService`) ; à enrichir, et à faire lire par les 7 appelants de `currentSubscription` concernés |
| 15 | REVOKE ne bloque pas un nouvel achat | 🔴 | règle à coder ; interaction avec l'empilement (G-5) |
| 16 | Webhooks n'écrivent pas les overrides | ✅ | vrai par construction (A.6) |
| 17 | Remboursement n'affecte pas un GRANT + alerte | 🟠 | statut REFUNDED disponible ; alerte à dériver |
| 18 | Dates inclusives UI / exclusives stockage, Paris | 🟠 | instant exclusif déjà généralisé ; conversion Paris à ajouter |
| 19 | Opération admin atomique + `dryRun` + aperçu serveur | 🔴 | |
| 20 | Historique admin (avant/après, motif, operationId) | 🔴 🗄 | aucun audit générique |
| 21 | Produits disponibles servis | 🟠 | `ModuleAccess` existe ; endpoint à créer (pas de liste en dur au front) |
| 22 | Sécurité 401/403/404 | ✅ | mécanisme existant ; 404 à poser dans le service |
| 23 | Visibilité « au prochain appel » | 🟠 | serveur immédiat ; mobile au prochain démarrage (A.9) |
| 24 | Sessions EO temps réel d'un accès accordé | 🔴 | le solde vit sur la ligne d'achat ; un GRANT n'en a pas (G-4) |
| 25 | Emails Premium cohérents avec les overrides | 🔴 | scénarios lisent les achats seuls (G-6) |

---

## C. Modèle recommandé

### C.1 Principe : achats intacts, overrides à part, une autorité

- **Achats** : `user_subscriptions` **inchangée**, aucune colonne ajoutée, aucun webhook modifié. Elle reste l'achat **et** l'accès « brut » acheté.
- **Overrides** : nouvelle table `access_overrides` (D.2), lue et écrite **uniquement** par le service d'accès et le service admin.
- **Opérations admin** : nouvelle table `admin_access_operations` (D.1) = historique §7, une ligne par action (une correction de produit = **une** ligne, deux overrides).
- **Accès effectif** : calculé dans **`SubscriptionService`** (on étend l'autorité existante, on n'en crée pas une seconde). Ajout d'un résolveur pur `AccesEffectifResolver` (patron `*Resolver` du dépôt) : entrée = lignes d'achat + overrides courants + `now`, sortie = par produit `{statut, actif, début, fin, origine, alertes}`. `hasCivique`, `hasTcf`, `isPremium`, `currentAccess` en dérivent : **les 20+ appelants de A.4 ne changent pas de signature**.

### C.2 Dimension « produit » de l'override

Recommandé : l'override porte sur **le produit vendu**, `ModuleAccess ∈ {CIVIQUE, INTEGRAL}` (enum existant, `NONE` exclu) — pas sur `Module {CIVIQUE, TCF}`.
- C'est « l'enum produit existant » de §2.2, et le seul que l'app mobile en production sait représenter (cf. section Impact mobile : `"TCF"` seul ⇒ tout verrouillé).
- Accès effectif par produit : `P_eff(t) ⊆ {CIVIQUE, INTEGRAL}` selon §2.3 appliqué à chaque produit ; module effectif = max(P_eff) avec INTEGRAL ⊃ CIVIQUE ; `hasTcf = INTEGRAL ∈ P_eff`, `hasCivique = P_eff ≠ ∅`.
- Traduction des actions de la spec : « Corriger Civique → TCF » = **Civique → Intégral** ; « rétrograder » = Intégral → Civique (REVOKE INTEGRAL + GRANT CIVIQUE). « Terminer Civique » pour un compte qui a un Intégral actif **ne retire pas Civique** (le pack le couvre) : le `dryRun` doit le dire, et l'API le refuser en 409 explicite plutôt que créer un REVOKE sans effet (G-1).

### C.3 Règle §2.3 sur l'existant

Pour (user, produit p, t) :
- *achat valide à t* = ligne `user_subscriptions` de plan `module_access = p` avec `SubscriptionService.covers(s, t)` (règle **réutilisée**, pas réécrite).
- *achat après le REVOKE* = `coalesce(purchased_at, starts_at) > override.created_at` (`purchased_at` est immuable et renseigné partout depuis V079).
- GRANT courant couvrant t ⇒ OUI ; REVOKE courant couvrant t ⇒ OUI ssi achat valide postérieur ; sinon achat valide.
- Statut affiché (§2.4) dérivé, jamais persisté : Actif / Programmé (GRANT courant avec `starts_at > now`) / Révoqué (REVOKE courant couvrant now et pas de rachat) / Expiré (au moins un achat ou GRANT passé) / Aucun. Alertes : « Achat remboursé » (un achat du produit `REFUNDED` ou `payment_status` ≠ PAID pendant un GRANT), « Révocation programmée le … » (REVOKE courant futur).

### C.4 Lectures à faire passer par l'accès effectif

| Appelant | Aujourd'hui | Cible |
|---|---|---|
| `GET /api/billing/subscription-status` (`BillingController:124`) et réponse `verify-receipt` (`ReceiptVerificationService:74`) | ligne d'achat | même DTO, rempli depuis l'accès effectif (cf. Impact mobile) |
| `RealtimeQuotaService:45` | ligne d'achat | ne rendre la ligne porteuse du solde **que si** l'accès INTEGRAL est effectif (sinon un REVOKE laisserait consommer des sessions) |
| `BillingService:398` (proration Stripe) | ligne Civique | ne créditer qu'un Civique **effectif** (sinon un Civique révoqué serait encore remboursé en crédit) |
| `OneTimeAccessService:139-151` (base de prolongation, report EO) | achats | G-5 |
| `AccountDeletionService:87`, `SubscriptionCancellationService:64` | ligne d'achat | **inchangés** (ils agissent sur l'achat, c'est voulu) |
| Emails (`EmailAutomationService:155`, `PremiumAccessEndResolver`, `EmailScenarioRepository`) | achats | G-6 |

### C.5 Stratégie de requête de la liste (filtres performants, une seule autorité)

Pas de copie SQL de la règle (précédent du dépôt : `EmailScenarioRepository` « ne fait que borner », Java décide).
1. **Sur-ensemble SQL des « peut-être actifs »** : comptes ayant une ligne d'achat non FREE, statut ∈ couvrants, `ends_at IS NULL OR ends_at > now`, **ou** un override courant. Taille ≈ nombre de payants + overrides (petit).
2. **Décision Java** par `AccesEffectifResolver` sur ce sur-ensemble (2 requêtes en lot : `findByUserIdIn` existe déjà avec `@EntityGraph(plan)`, `UserSubscriptionRepository:28-30`) ⇒ ensembles exacts `A_tcf`, `A_civique`, `A_any`.
3. **Pagination SQL exacte** sur `users` avec `id IN (:A_x)` / `id NOT IN (:A_any)` ; « Expiré » = a eu un achat ou un GRANT ∧ `NOT IN (:A_any)` ; « Accès manuel » = `EXISTS` override courant. Recherche `q` combinable.
4. Page courante : accès effectif complet + « prochaine fin » + dernière activité (`v_derniere_activite_entrainement`, `user_id = ANY(:ids)`) chargés en lot pour les seuls ids de la page.
Coût : O(payants) par requête de liste, pas O(comptes). À verrouiller par un test d'**égalité** du nombre de requêtes (convention `backend_sejourfr/CLAUDE.md:117-119`).

### C.6 Concurrence

Transaction unique par opération ; dans le service admin : verrou consultatif par utilisateur (`pg_advisory_xact_lock`, patron `JourneyManager.verrouillerLaCreation`) **+** index unique partiel « un override courant par (user, produit) » en filet. Recommandé en plus : la requête porte `expectedCurrentOverrideId` (ou null) lu par la modale ⇒ 409 si un autre admin a agi entre-temps (verrou optimiste sans colonne `version`). Webhooks : aucun verrou à ajouter (lignes disjointes).

### C.7 Historique admin

`admin_access_operations` réutilisé comme journal (pas d'audit générique à inventer pour ce MVP). `before_state` / `after_state` = **photo jsonb de l'accès effectif par produit** calculée par le service au moment de l'action. ⚠️ C'est une donnée figée à un instant — même famille que les exceptions assumées « décision prise à un instant » (`backend_sejourfr/CLAUDE.md:39-65`) ; elle ne sert **jamais** à calculer un accès, seulement à afficher l'historique.

---

## D. Migrations (aucune écrite avant le GO)

Numérotation : prochaine version libre de `00_schema/` = **V083** (V082 est la dernière du schéma ; les plages 100+/800+ sont du contenu). Une seule migration additive, aucun impact sur les données existantes.

### D.1 `admin_access_operations` — journal des actions admin
- **Pourquoi** : §7 (qui, quand, avant/après, motif, operationId), aucune table réutilisable.
- Colonnes : `id uuid PK` (= operationId) · `user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE` · `admin_user_id uuid NOT NULL REFERENCES users(id)` · `operation varchar(24) NOT NULL CHECK (operation IN ('GRANT','EXTEND','SHORTEN','END','REACTIVATE','CORRECT_PRODUCT'))` · `product varchar(16)` · `from_product varchar(16)` · `reason varchar(500) NOT NULL CHECK (char_length(btrim(reason)) BETWEEN 3 AND 500)` · `before_state jsonb NOT NULL` · `after_state jsonb NOT NULL` · `created_at timestamptz NOT NULL DEFAULT now()`.
- Index : `(user_id, created_at DESC)`.

### D.2 `access_overrides` — overrides GRANT / REVOKE
- **Pourquoi** : §2.2. Jamais supprimé, toujours remplacé.
- Colonnes : `id uuid PK` · `user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE` · `product varchar(16) NOT NULL CHECK (product IN ('CIVIQUE','INTEGRAL'))` · `type varchar(8) NOT NULL CHECK (type IN ('GRANT','REVOKE'))` · `starts_at timestamptz NOT NULL` · `ends_at timestamptz` (exclusif) · `reason varchar(500) NOT NULL` · `created_by uuid NOT NULL REFERENCES users(id)` · `created_at timestamptz NOT NULL DEFAULT now()` · `superseded_at timestamptz` · `superseded_by uuid REFERENCES access_overrides(id)` · `operation_id uuid NOT NULL REFERENCES admin_access_operations(id)`.
- Contraintes : `CHECK (type <> 'GRANT' OR ends_at IS NOT NULL)` · `CHECK (ends_at IS NULL OR ends_at > starts_at)` · `CHECK ((superseded_at IS NULL) = (superseded_by IS NULL))`.
- **Invariant §2.2** : `CREATE UNIQUE INDEX ux_access_overrides_courant ON access_overrides (user_id, product) WHERE superseded_at IS NULL;`
- Index : `(user_id)` ; l'index partiel sert aussi le filtre « Accès manuel ».
- Ordre d'écriture (l'index partiel interdit deux courants, même un instant) : l'id du nouvel override est tiré en Java (UUID) ; (1) `UPDATE` de l'ancien `SET superseded_at = now(), superseded_by = :nouvelId`, (2) `INSERT` du nouveau. La FK `superseded_by` est donc déclarée `DEFERRABLE INITIALLY DEFERRED` (vérifiée au commit). Proposition à valider en phase 2 par un IT.

### D.3 Rien sur `user_subscriptions`, `plans`, `users`
Aucune colonne `version` (C.6), aucune colonne « dernière activité » (vue V073). Suppression de compte : voir G-8 (overrides et motifs nominatifs).

---

## E. Plan d'implémentation (phase 2 puis 3)

**Base** : `V083__schema_acces_admin.sql` (D.1, D.2) + mise à jour de `docs/migrations-flyway.md`.

**Backend** (Controller → Service → Manager → Repository) :
- `entity/AccessOverride`, `entity/AdminAccessOperation` ; `enums/AccessOverrideType`, `enums/AdminAccessOperationType` ; repositories + `manager/AccessOverrideManager`, `manager/AdminAccessOperationManager`, extension de `UserManager` (recherche paginée, `Specification` sur `User` : `specification/UserSpecifications`).
- `service/access/AccesEffectifResolver` (pur, sans Spring) + `service/access/DateMetierParis` (conversion date inclusive ⇄ instant exclusif, Europe/Paris — **seul** endroit de conversion).
- `SubscriptionService` : `effectiveAccess(userId, now)` et `effectiveAccessFor(Collection<UUID>)` ; `hasCivique/hasTcf/isPremium/currentAccess` réécrits dessus ; `currentSubscription` conservé pour les usages « achat ».
- Bascule des lectures de C.4 (`BillingController`, `ReceiptVerificationService`, `RealtimeQuotaService`, `BillingService`).
- `service/admin/AdminUserService` (liste, fiche), `service/admin/AdminAccessOperationService` (traduction §2.6, validations, `dryRun`, aperçu, transaction, verrou), `mapper/AdminUserMapper` (pur ; références externes tronquées).
- `controller/AdminUserController` : `GET /api/admin/users`, `GET /api/admin/users/{id}`, `GET /api/admin/access-products`, `POST /api/admin/users/{id}/access-operations`.
- DTO : `AdminUserListItemDto`, `AdminUserDetailDto` (compte, accès par produit, achats, progression, historique), `AdminAccessOperationRequest/Response`. Configuration éventuelle (taille max de page) en `@ConfigurationProperties` + YAML.
- Docs dans la même passe : `docs/regles/paiements.md` (§ overrides), `docs/regles/freemium.md` (accès effectif), `docs/api-endpoints.md`, `backend_sejourfr/CLAUDE.md` / `admin_sejourfr/CLAUDE.md` (nouvelle feature), et index racine seulement pour l'invariant transverse « achat ≠ accès ».

**Tests backend (même passe)** :
- `AccesEffectifResolverTest` : matrice §2.3 + statuts §2.4 + cas §11 n° 1-4, 7-12 (dont 31/10 23:30 vs 01/11 00:01 Paris, et un passage d'heure d'été).
- `AdminAccessOperationServiceTest` (traductions §2.6, validations §6 → 400, 409 « Terminer Civique sous Intégral », 409 état périmé).
- `AdminAccessOperationIT` (Zonky) : atomicité de la correction (§11-15, erreur injectée sur le GRANT ⇒ REVOKE non persisté), index unique partiel, achat intact (§11-5 : égalité de la ligne `user_subscriptions` avant/après).
- `OverrideSurvitAuxWebhooksIT` : rejeu Stripe `checkout.session.completed` / `charge.refunded`, Apple `verify-receipt` rejoué, Google voided ⇒ override intact (§11-6, §11-11).
- Non-régression : `SubscriptionServiceTest`, `OneTimeAccessServiceTest`, tests `subscription-status` / `verify-receipt` (DTO identique sans override).
- `AdminRoutesSecurityIT` (401/403) + 404 utilisateur inexistant ; test d'égalité du nombre de requêtes de la liste.

**Admin front** (phase 3) : `features/users/` (`UsersPage`, `UserDetailPage`, `AccessOperationModal`, `useUserListParams` sur le modèle de `useSubscriptionListParams`), `api/usersApi.ts`, types dans `src/types/api.ts`, routes `/users` et `/users/:id` dans `App.tsx`, entrée de sidebar `AppLayout`. Primitives `components/ui/*` existantes. Aucun calcul de statut, de date ni d'aperçu côté front ; libellés produit servis. Vérification : `npx tsc --noEmit` (+ build si le port 5173 n'est pas en dev). **Aucun nouveau test front.**

**Web et mobile** : aucune modification **requise** pour le MVP (cf. Impact mobile). Parité : les miroirs `web_sejoufr/lib/types.ts` et `mobile_sejourfr/lib/core/models/billing_models.dart` ne changent que si un champ additif est retenu (G-3).

---

## F. Verdict

🟠 **Petites évolutions — avec un point structurant à arbitrer.**

Faisable sans toucher aux achats ni aux webhooks : l'autorité d'accès est déjà unique et les webhooks n'écrivent que leur propre ligne, donc des overrides en table séparée sont sûrs par construction. Deux tables additives, un résolveur, une API admin, une feature admin.

Ce qui n'est pas « tel quel » : (1) la spec raisonne en produits **TCF / Civique**, le dépôt vend **Civique / Intégral (pack)** ; (2) `subscription-status`, `verify-receipt` et le quota EO lisent aujourd'hui **une ligne d'achat** et doivent passer par l'accès effectif ; (3) l'app mobile en production **recalcule** `hasTcf` depuis `moduleAccess` et ne sait pas représenter « TCF sans Civique ».

---

## Impact app mobile en production

Hypothèse [S] : l'app publiée (pubspec `0.1.4+21`) a le comportement du code `mobile_sejourfr/` de `develop` décrit en A.5.

**Surfaces touchées par la solution recommandée** :

| Surface lue par le mobile | Changement | L'app actuelle continue-t-elle de fonctionner ? |
|---|---|---|
| `GET /api/auth/me`, login/register/social (`AuthenticatedUser`) | **aucun champ** ; `hasCivique`/`hasTcf`/`isPremium`/`premiumEndsAt` désormais issus de l'accès effectif | ✅ oui, même forme |
| `GET /api/billing/subscription-status` et réponse de `POST /api/billing/verify-receipt` | **même DTO**, rempli depuis l'accès effectif : GRANT sans achat ⇒ `isPremium=true`, `moduleAccess` = produit effectif (`CIVIQUE`/`INTEGRAL`), `expiresAt` = fin effective, `source`/`productId` `null`, `status=ACTIVE`, `oneTime=true` ; REVOKE ⇒ `notPremium` ou le produit restant | ✅ oui **à condition de n'émettre que `NONE`/`CIVIQUE`/`INTEGRAL`** (le parsing tolère `source` null → « Géré par : — ») |
| `locked` servis (grilles, Plan, compétences…) et 403 | aucun changement de forme ; suivent l'accès effectif | ✅ oui |
| Quota EO temps réel (`realtimeSessionsRemaining`) | `null` pour un accès sans ligne d'achat (selon G-4) | ✅ oui (le compteur se masque déjà quand `null`) |

🛑 **Ce qui casserait l'app en production — à NE PAS faire sans nouvelle version mobile** :
1. Servir un accès **« TCF seul »** : `moduleAccess = "TCF"` ⇒ `hasTcf = false` **et** `hasCivique = false` côté app (`billing_models.dart:449-451`) alors que le serveur autoriserait TCF ; et `moduleAccess = "INTEGRAL"` mentirait sur Civique (cadenas ouverts, 403 serveur). D'où C.2 : overrides au grain CIVIQUE / INTEGRAL.
2. Ajouter une valeur à `ModuleAccess` ou changer le sens d'un champ existant de `subscription-status`.
3. Laisser `subscription-status` sur la ligne d'achat **alors que `/me` suit les overrides** : le démarrage mobile écrase `/me` par `subscription-status` (`auth_controller.dart:116-123`) — un GRANT disparaîtrait de l'app, un REVOKE y resterait ouvert (403 serveur). Les deux endpoints doivent basculer **dans le même déploiement**.

**Comportement accepté (documenté, sans mise à jour d'app)** : le serveur applique tout changement au prochain appel ; l'app mobile ne relit l'accès qu'au **démarrage à froid** (ou après achat/restauration). Un GRANT s'y voit donc après relance de l'app ; un REVOKE est opposé en 403 dès la requête suivante, même si un écran affiche encore « débloqué ». Hors ligne : dernier état connu (pas de Drift, pas d'expiration locale). Amélioration future, **qui demande une version mobile** : relire `/me` + `subscription-status` au retour au premier plan.

**Avant tout déploiement backend de la phase 2 : prévenir le propriétaire**, la bascule de `subscription-status` / `verify-receipt` étant la seule modification d'une surface lue par le mobile (forme inchangée, contenu désormais issu de l'accès effectif). Un test de non-régression doit prouver qu'**en l'absence de tout override**, les deux réponses sont octet pour octet identiques à aujourd'hui.

---

## Respect des invariants du dépôt

- **Une règle = une autorité** : `covers` reste la seule règle « un achat couvre-t-il t » ; la règle override vit dans `AccesEffectifResolver` appelé par `SubscriptionService` ; la liste ne recopie rien en SQL (C.5) ; conversion de dates en un seul util.
- **Dérivé serveur jamais persisté** : statuts, origine, alertes, « prochaine fin » calculés à la lecture. Seules exceptions : l'override (une **décision**) et la photo avant/après du journal (affichage seul).
- **Controller → Service → Manager → Repository** : respecté par le plan E (le service admin n'accède à aucun repository).
- **Parité des 3 fronts** : aucun DTO partagé ne change de forme ; si G-3 retient un champ additif, il s'ajoute aux trois miroirs dans la même passe.
- **Pas de nouveau test front** ; **tests backend dans la même passe** (E).
- **Aucun appel LLM** dans tout ce chantier.

---

## G. Points ouverts (à trancher)

**G-1. Grain du produit des overrides.**
1. `ModuleAccess {CIVIQUE, INTEGRAL}` — produits réellement vendus, compatible mobile ; « Civique → TCF » devient « Civique → Intégral » ; « Terminer Civique » sous un Intégral actif refusé en 409 explicite. **← recommandé**
2. `Module {CIVIQUE, TCF}` — fidèle à la spec, mais « TCF sans Civique » est inaffichable par le mobile en production (cassure) et sans produit correspondant.
3. Option 2 avec invariant serveur « TCF ⇒ Civique » — complexité sans bénéfice métier visible.

**G-2. Libellés et maquette.** 1. Reprendre la maquette en remplaçant « TCF » par « Intégral (Civique + TCF) » et le prix fictif 39,99 € par les vraies lignes d'achat. **← recommandé** · 2. Afficher deux badges dérivés « Civique » / « TCF » (lecture des modules) tout en agissant sur Civique / Intégral — plus lisible pour le support, mais deux vocabulaires dans le même écran.

**G-3. Signaler l'origine « Admin » aux fronts candidats.** 1. Rien de nouveau : `source = null` (« Géré par : — »). **← recommandé pour le MVP** · 2. Champ additif `accessOrigin: "PURCHASE" | "ADMIN"` dans `SubscriptionStatusResponse` (ignoré par l'app actuelle ; miroirs web + mobile à mettre à jour) · 3. Nouvelle valeur `source = "ADMIN"` — à éviter (enum partagé, parsing tolérant mais sémantique « qui a payé » faussée).

**G-4. Simulations orales temps réel d'un accès Intégral accordé (le solde vit sur la ligne d'achat).**
1. Un GRANT n'ouvre **aucune** session temps réel (le reste de l'Intégral fonctionne) ; l'admin peut toujours ajuster le solde d'une ligne d'achat existante. **← recommandé pour le MVP**
2. Colonne `realtime_eo_sessions` sur l'override, lue par `RealtimeQuotaService` quand aucun achat ne porte le solde — 🗄 + logique de débit à dupliquer.
3. Le prolongement d'un achat (GRANT au-dessus d'un achat) garde le solde de cet achat ; seul le GRANT « nu » vaut 0 — combinable avec 1.

**G-5. Rachat pendant un REVOKE ou un GRANT (base de prolongation `OneTimeAccessService:139-143`).**
1. Laisser le flux d'achat lire seulement les achats (lettre de §2.3) : un rachat sur un achat révoqué **s'empile sur sa fin**, donc accorde plus que le pass payé ; un rachat pendant un GRANT ne s'y ajoute pas.
2. La base de prolongation lit la **fin effective** (lecture seule des overrides, jamais d'écriture) : rachat après REVOKE ⇒ part de maintenant ; rachat pendant un GRANT ⇒ part de la fin du GRANT. Déroge à « les webhooks ne lisent jamais les overrides » sur ce seul calcul de date. **← recommandé**
3. Base = « maintenant » dès qu'un override courant existe.
Même question pour la proration Stripe (`BillingService:393-405`) : ne créditer qu'un Civique effectif (recommandé).

**G-6. Emails Premium (scénarios ENGAGEMENT et `PREMIUM_ACCESS_*`).**
1. MVP : inchangés (lisent les achats) + exclusion des comptes ayant un override courant des scénarios `PREMIUM_ENDING_*` / `PREMIUM_ENDED` / « jamais premium », pour éviter un mail faux. **← recommandé**
2. Brancher les scénarios sur l'accès effectif (fins de GRANT annoncées, REVOKE silencieux) — plus juste, plus long, touche `PremiumAccessEndResolver` et `EmailScenarioRepository`.
3. Rien changer (risque : « votre accès se termine » envoyé à un compte révoqué, relances de conversion à un compte accordé).

**G-7. Affichage des fins d'ACHAT (instants à l'heure de l'achat, pas à minuit).**
1. Fin d'achat affichée avec l'heure (« jusqu'au 01/11/2026 à 14:37 »), fin d'override en date incluse (« 31/10/2026 inclus »). **← recommandé** (exact, aucune réécriture)
2. Date seule pour les deux (« fin incluse » = date Paris de `ends_at − 1 ms`) — plus simple mais l'accès réel s'arrête en cours de journée.
Dans les deux cas, « Prolonger un achat » = GRANT `[maintenant, nouvelle fin + 1 j 00:00 Paris)` et « Raccourcir » = REVOKE `[nouvelle fin + 1 j 00:00 Paris, ∅)` ; aucune date d'achat modifiée.

**G-8. Suppression / anonymisation de compte.** 1. Conserver overrides et journal (le motif peut contenir des données personnelles → consigne : motif sans donnée personnelle) · 2. Les supprimer dans `AccountDeletionService` comme les autres données nominatives. **← recommandé** (cohérent avec la purge existante ; `ON DELETE CASCADE` ne joue pas, la ligne `users` survit) · 3. Anonymiser le motif seulement.

**G-9. Dernière activité.** 1. Colonne liste = vue V073 (entraînement), fiche = V073 + `last_login_at` libellé « Dernière connexion (identifiants) ». **← recommandé, après `EXPLAIN` sur un volume réaliste en phase 2** · 2. Colonne absente de la liste, fiche seulement · 3. Dernière activité par module (TCF / Civique) — requête supplémentaire, hors MVP.

**G-10. Progression dans la fiche.** 1. MVP = par module : diagnostic fait (date), cycle en cours (statut, `entry_level`, étapes closes / total, date), nombre de cycles historisés — lectures directes en tables, jamais `JourneyService.lire`. **← recommandé** · 2. Réutiliser les DTO candidat (`/api/me/progression`, journey) — refusé : `JourneyService.lire` écrit, et le moteur de progression est coûteux.

**G-11. Contrôle de l'état périmé (admin ⇄ admin).** 1. Verrou consultatif par utilisateur + index unique partiel + `expectedCurrentOverrideId` (409 si l'état a bougé). **← recommandé** · 2. Verrou + index seulement (le dernier admin gagne, tracé dans l'historique).

**G-12. Abonnements récurrents en production.** Passer la requête de A.3 en prod (lecture seule) avant la phase 2 pour confirmer qu'aucun abonnement auto-renouvelable n'est actif ; s'il en existe, les traiter en lecture seule (aucune action « Prolonger » sur une ligne récurrente) dans le MVP.

🛑 **STOP 1 — en attente du GO.**
