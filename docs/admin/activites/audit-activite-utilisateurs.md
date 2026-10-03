# Audit — statistiques d'activité utilisateurs (admin `/dashboard`)

> Audit **en lecture seule** du 2026-10-03, branche `develop` (HEAD `e9bf5516`). Aucun code
> modifié, aucune migration créée. Base interrogée : Postgres local `sejourfr_db` (SELECT
> uniquement). ⚠️ La base de dev mélange usage réel de développement, scripts (`curl`, `node`)
> et le jeu `db/migration-dev/R__seed_dev_suivi.sql` : ses volumes **ne représentent pas la
> production**. Les estimations de volume ci-dessous sont donc des scénarios.

---

## 1. Résumé exécutif

1. **Plateforme : déjà résolue, rien à inventer.** Chaque requête des fronts porte
   `X-Sejourfr-Client` (`web` / `ios` / `android`), et `ClientContextResolver` est la seule
   autorité qui le lit. C'est de là que vient le filtre `platform` de l'écran Suivi.
   Exception : l'app publiée avant la distinction envoie `mobile`, ce qui donne `MOBILE`,
   jamais réparti entre iOS et Android.
2. **« En ligne < 2 min » : non calculable aujourd'hui.** Aucune trace « dernière requête »
   n'existe par utilisateur : pas de `last_seen`, pas de journal d'accès, et
   `analytics_event` ne voit que des gestes métier.
3. **« Actifs uniques période » : seulement des proxys partiels.** On a l'entraînement
   (vue V073, sans plateforme) et `analytics_event.user_id` (partiel : `sendBeacon` est sans
   JWT, et beaucoup d'écrans n'émettent rien).
4. **« Connexions » : l'historique existe en partie.** `refresh_tokens` n'est jamais purgée
   et garde chaque session ouverte depuis le 2026-06-01 (494 ouvertures, 41 comptes en dev).
   Il y manque la plateforme (seulement un `user_agent`, interdit d'heuristique) et la
   méthode (local, Google ou Apple). Le refresh y est une ligne comme une autre.
5. **« Pages / écrans » : non mesuré.** Il n'existe aucun événement de vue générique. Le
   `path` n'est porté que par 24 événements métier, sur une allowlist de 20 chemins
   (dont 3 mobiles), alors que le web compte 81 pages et le mobile 77 routes.
6. **Recommandation, schéma :** une seule migration `V086`. Elle crée la table
   `user_activity_day` (une ligne par compte × jour de Paris × plateforme, avec
   `last_seen_at`), qui sert à la fois « en ligne » et « actifs ». Elle ajoute aussi trois
   colonnes à `refresh_tokens` (`opened_by`, `auth_method`, `platform`) pour les connexions.
7. **Recommandation, écriture :** un filtre backend, limité à une écriture par minute,
   enregistre toute requête authentifiée. S'y ajoute un **heartbeat de 60 s au premier plan
   seulement** (web : `visibilityState`, mobile : `AppLifecycleListener`). Sans heartbeat, un
   candidat qui rédige un EE pendant 60 min n'émet aucune requête, car le brouillon est
   local.
8. **Recommandation, écrans :** un événement `SCREEN_VIEWED` dans le pipeline
   `analytics_event` existant (lot, idempotence, purge 395 j), avec des chemins **gabarits**
   sur allowlist fermée. Il doit être exclu du KPI « Visiteurs » de Suivi, sinon ce chiffre
   saute.
9. **UI :** sur `/dashboard`, une carte « Actifs maintenant ». Tout le reste va sur
   `/dashboard/activity`, servi par un appel unique `GET /api/admin/analytics/activity`,
   plus un endpoint `…/activity/live` très léger pour la carte.
10. **Pas d'outil externe.** Firebase, GA ou PostHog casseraient l'acquis « aucun outil
    tiers, aucun bandeau » de `/confidentialite` §8.4, et créeraient une seconde vérité.

---

## 2. État actuel

### 2.1 Backend — ce qui existe

| Élément | Où | Ce que ça donne pour l'activité |
|---|---|---|
| Résolution du contexte client (plateforme, source, anonymousId, version) | `backend_sejourfr/src/main/java/com/sejourfr/app/util/ClientContextResolver.java:46-53` | Autorité unique des 4 en-têtes `X-Sejourfr-*`. Lu **par les controllers qui en ont besoin** (auth, analytics, diagnostic, billing), **pas** par un filtre global |
| Enum plateforme | `…/enums/ClientPlatform.java:20-38` | `WEB`, `IOS`, `ANDROID`, `MOBILE` (historique), `UNKNOWN`. Javadoc l.11-13 : **on ne devine jamais depuis le User-Agent** |
| Filtre Suivi | `…/enums/SuiviPlatformFilter.java:11-15` | `ALL\|WEB\|IOS\|ANDROID` ; `MOBILE`/`UNKNOWN` comptés sous `ALL` seulement |
| Filtre JWT | `…/security/JwtAuthenticationFilter.java:39-67` | Authentifie chaque requête ; le claim `sub` = `userId` (`JwtService.java:46`). **Aucune trace d'activité** |
| Sessions | `…/service/SessionService.java:48-61` (`openSession`), `:71-127` (`rotate`) | Une ligne `refresh_tokens` par ouverture **et** par rotation ; `user_agent` + `ip_address` stockés |
| Ouverture de session = login | `…/service/AuthService.java:82` (`lastLoginAt`), `:243` (`openSession`) ; `…/service/SocialAuthService.java:135,149,169` (`lastLoginAt`), `:178` (`openSession`) | Login local, inscription (via `authenticate(..., SIGNUP)`, `AuthService.java:175`), Google, Apple |
| Refresh | `…/service/AuthService.java:101-103` → `SessionService.rotate` | Crée une nouvelle ligne, révoque l'ancienne (`replaced_by`) — **ne touche pas** `last_login_at` |
| Purge des refresh tokens | `…/repository/RefreshTokenRepository.java:26-27` (`deleteExpired`) | **Méthode sans aucun appelant** : la table n'est jamais purgée |
| `users.last_login_at` | `…/entity/User.java:78-79` | **Dernière** connexion seulement (pas d'historique) ; affichée sur la fiche admin (`admin_sejourfr/src/features/users/UserDetailPage.tsx:190`) |
| Ingestion analytics en lot | `…/service/analytics/AnalyticsBatchIngestionService.java:119-129` | `user_id` résolu depuis le JWT **s'il y en a un** ; `platform` + `app_version` depuis le contexte |
| Registre d'événements | `…/enums/AnalyticsEvent.java:37+` | Fermé ; **aucun** `PAGE_VIEWED` / `SCREEN_VIEWED` |
| Allowlist de chemins | `…/util/AnalyticsPaths.java:34-62` | 20 chemins, dont 3 mobiles (`/home`, `/target-path`, `/paywall`) ; hors liste ⇒ rejet nommé |
| Rate-limit ingestion | `…/ratelimit/AnalyticsBatchRateLimit.java` + `analytics/analytics-config-v1.json` `ingestion.rateLimit` | **Par lot** : 60 lots / 10 min et 1 000 / jour par `anonymousId` ; 120 / 10 min et 3 000 / jour par IP |
| Rétention analytics | `…/service/analytics/AnalyticsRetentionJob.java:23` | 395 j, 04:10 Paris |
| Lecture Suivi — visiteurs | `…/repository/SuiviReadRepository.java:161-171` | `anonymous_id` distincts ayant **n'importe quel** événement (aucun filtre sur `event`) |
| Activité d'entraînement | vue `v_derniere_activite_entrainement` (V073, `docs/regles/emails.md:169-176`) | `max` des 4 actes du candidat par compte. **Un max, pas un historique** ; les tables sources (`answers`, `production_submissions`, `user_skill_attempts`, `realtime_sessions`) sont datées mais **sans plateforme** |
| Mono-instance | `…/ratelimit/InMemoryRateLimiter.java:17` | « un seul process backend » : un cache en mémoire suffit pour limiter les écritures |
| Journal d'accès HTTP | `application-*.yaml` | **Aucun** (`logging` seulement) ; journaux du reverse-proxy : ❓ à confirmer |

### 2.2 Web (`web_sejoufr/`)

- **En-têtes sur toutes les requêtes** : `lib/client-context.ts:188-196` (`X-Sejourfr-Client: web`, `X-Sejourfr-App-Version`, `X-Sejourfr-Source`, `X-Sejourfr-Anonymous-Id`), branchés par `lib/api.ts:73`. En rendu serveur (SSR), seul `X-Sejourfr-Client` part, sans JWT (`client-context.ts:184-186`).
- **Mesure d'audience** : `lib/analytics.ts`. Une file avec lot de 50 et délai de 4 s (`:340-344`), vidée par `sendBeacon` sur `visibilitychange` ou `pagehide` (`:384-394`). 🛑 `sendBeacon` n'envoie **aucun en-tête**, donc ni JWT ni `user_id` sur ces lignes (`:494-520`).
- **Chemins suivis** : `TRACKED_PATHS`, 17 chemins, miroir fermé de `AnalyticsPaths` (`lib/analytics.ts:184-209`). Le web a **81 `page.tsx`**, dont **37 à segment dynamique** (identifiants de session, de tentative ou de soumission).
- **Refresh** : dédoublonné par `refreshPromise` (`lib/api.ts:371-376`).
- **Rédaction EE** : brouillon **local** (`app/_components/production/EeWritingForm.tsx:13-18`), donc aucune requête pendant la rédaction.

### 2.3 Mobile (`mobile_sejourfr/`)

- **En-têtes sur toutes les requêtes**, `skipAuth` comprises : `lib/core/api/api_client.dart:93-100` → `lib/core/analytics/client_context.dart:32-36` (`ios` / `android`, rien hors de ces deux systèmes). Le User-Agent est `SejourFR (ios|android)` (`api_client.dart:51-57`).
- **File d'événements** : `lib/core/analytics/analytics_queue.dart:160-168`. `AppLifecycleListener` vide la file au `onResume` (forcé) et au `onHide`, et un `Timer.periodic` la vide toutes les 60 s. Ce timer ne **fait rien si la file est vide** (`:210-220`).
- **Router** : go_router `^14.6.2` (`pubspec.yaml:20`), **77 `GoRoute`** (`lib/core/router/app_router.dart`). Un seul observer, `appRouteObserver` (`:428`, `route_observer.dart`), qui ne sert qu'au `didPopNext`. **Aucun suivi d'écran.**
- **Requêtes en arrière-plan possibles** : polling de résultat toutes les 3 s (`screens/tcf_production/production_result_polling.dart:10`, `ee_results_screen.dart:66`, `eo_results_screen.dart:84`, `competence_result_screen.dart:166`) et vidage analytics au `onHide`. Sur iOS, l'app est suspendue. Sur Android, ces timers peuvent tourner encore quelques secondes ou minutes : ❓ à confirmer.
- **Version du dépôt** : `0.1.4+21`. Quelle part des installations envoie encore `mobile` : ❓ (cf. la condition de retrait, `docs/regles/mesure-audience.md:203-219`).

### 2.4 Admin (`admin_sejourfr/`)

- `/dashboard` = `SuiviPage` (`src/App.tsx:51`). Navigation : `src/components/layout/navigation.ts:24-27` (section « Pilotage », entrée unique « Suivi »). Fil d'Ariane : préfixe le plus long (`navigation.ts:70-79`).
- Un appel unique `useSuivi`, état dans l'URL (`src/features/suivi/useSuiviParams.ts:51-80`). Les presets sont `TODAY|YESTERDAY|LAST_7_DAYS|MONTH` (`backend …/enums/SuiviPeriodPreset.java:10-18`). **Pas de 30 jours glissants.**
- ⚠️ Une carte « **Activité** » existe déjà dans Suivi (`src/features/suivi/components/ActivityCard.tsx`). Elle porte sur les diagnostics et les achats. Le nouvel écran doit éviter l'homonymie : appeler la carte de Suivi autrement, ou titrer le nouvel écran « Activité des utilisateurs ».
- La console admin n'envoie **pas** `X-Sejourfr-Client` (aucune occurrence dans `admin_sejourfr/src`). Ses requêtes valent donc `UNKNOWN`, et le compte admin est `is_internal`.

### 2.5 Chiffres réels de la base de dev (SELECT)

| Requête | Résultat |
|---|---|
| `analytics_event` | 1 560 lignes (2026-08-22 → 2026-10-03), dont 1 163 sans `received_at` (seed ou endpoint unitaire), 397 reçues par lot ; `user_id` rempli 788, `path` 1 376, `platform` 397 |
| `analytics_event` par plateforme | `NULL` 1 163 · `WEB` 355 · `IOS` 34 · `ANDROID` 6 · `MOBILE` 2 |
| Événements les plus fréquents | `PLAN_OPENED` 797, `LANDING_VIEWED` 174, `LOGIN_CLICKED` 113, `DIAGNOSTIC_REPORT_VIEWED` 86… (24 types) |
| Comptes distincts avec événement sur 30 j | `WEB` 11 · `IOS` 3 · `ANDROID` 1 · `MOBILE` 1 · `NULL` 10 |
| `analytics_visitor` (plateforme × appareil) | `WEB` 31 · `UNKNOWN` 23 · `MOBILE` 4 · `IOS` 4 · `ANDROID` 3 |
| Taille sur disque | `analytics_event` 1 064 kB (≈ **0,7 kB par ligne, index compris**) · `refresh_tokens` 240 kB · `analytics_visitor` 120 kB |
| `users` | 62 (61 non supprimés, 4 `is_internal`, 1 ADMIN interne) ; `last_login_at` rempli pour 41 ; `signup_platform` : `NULL` 22, `WEB` 22, `MOBILE` 11, `IOS` 3, `ANDROID` 3, `UNKNOWN` 1 ; `auth_provider` : `LOCAL` 59, `GOOGLE` 3 |
| `refresh_tokens` | 700 lignes, 41 comptes, 2026-06-01 → 2026-10-03, **jamais purgée** (477 expirées encore présentes), 86 sessions vivantes |
| Ouvertures de session reconstituées (lignes racines : `NOT EXISTS (… replaced_by = jti)`) | **494** ; par User-Agent : navigateur 226, scripts (`curl` / `node` / `python`) 112, `Dart/3.x` (ancienne app) 98, `SejourFR (ios)` 58 |
| Ouvertures par jour (10 derniers jours) | 2026-09-24 : 7 (2 comptes), 09-25 : 3, 09-26 : 18 (3), 09-27 : 11 (2), 09-28 : 2, 09-30 : 2 |
| Actes d'entraînement | `answers` 2 526 (dont 2 158 avec compte), `production_submissions` 219, `user_skill_attempts` 42, `realtime_sessions` 84, `attempts` 741 ; comptes actifs (V073) : 13 sur 30 j, 2 sur 7 j |
| `page_views` (legacy, V020) | toujours en base, **plus écrite** depuis le 2026-09-25 ; agrégat `(path, source, event, day, hits)` **sans** utilisateur ni plateforme : inutilisable ici |
| Flyway | dernière version de `00_schema` : **V085** ; versions appliquées les plus hautes : 879 / 890 / 900 / 901 (autres plages). **Prochain numéro libre : `V086`** |

---

## 3. Plateforme — identification aujourd'hui

**Source unique** : l'en-tête déclaratif `X-Sejourfr-Client`, lu par
`ClientContextResolver.resolve` (`ClientContextResolver.java:46-53`) et parsé par
`ClientPlatform.parse` (`ClientPlatform.java:29-38`). C'est **la même information** qui
alimente le filtre `platform=ALL|WEB|IOS|ANDROID` de Suivi (`docs/regles/mesure-audience.md:458-461` :
plateforme de l'événement pour les visiteurs, `signup_platform` pour les inscriptions,
canal de paiement pour les achats).

| Client | Ce qu'il envoie | Lu comme | Fiabilité |
|---|---|---|---|
| Web (navigateur) | `X-Sejourfr-Client: web` sur chaque `apiFetch` | `WEB` | Bonne. Un `sendBeacon` n'a pas d'en-tête : le corps du lot redéclare `client` (`ClientContextResolver.java:64-74`) |
| Web en rendu serveur | `web`, **sans JWT** | `WEB` | Sans effet sur un comptage d'utilisateurs authentifiés |
| App mobile actuelle (`0.1.4+21`) | `ios` ou `android`, plus UA `SejourFR (ios\|android)` | `IOS` / `ANDROID` | Bonne |
| App publiée avant iOS / Android | `mobile`, UA `Dart/3.x (dart:io)` | `MOBILE` | **Système inconnu**, jamais réparti (règle `SuiviPlatformFilter.java:5-9`) |
| Console admin, scripts, client ancien | rien | `UNKNOWN` | — |

**Trous :**
- La plateforme **n'est persistée nulle part pour une requête ordinaire**. On la trouve
  seulement sur `analytics_event`, `analytics_visitor`, `diagnostic_run`,
  `diagnostic_sessions`, `purchase_intent`, `user_funnel_events` et
  `users.signup_platform` (inventaire `information_schema`).
- `refresh_tokens` n'a **pas** de colonne plateforme : seulement `user_agent`. Le déduire du
  User-Agent est **interdit** par la doctrine `ClientPlatform` (l.11-13), et le dev le montre
  bien : `Mozilla … iPhone` ne distingue pas Safari iOS de l'app.
- Un même compte peut être actif sur plusieurs plateformes le même jour. Les sous-totaux
  par plateforme **ne s'additionnent donc pas** au total des utilisateurs uniques. Le serveur
  doit servir le total **et** le nombre de multi-plateformes : le front ne déduit rien.

**Conclusion** : aucune nouvelle architecture n'est nécessaire pour la plateforme. Il suffit
de **réutiliser `ClientContextResolver`** dans le nouveau point d'écriture.

---

## 4. Disponibilité par métrique

| Métrique | Disponible actuellement ? | Données existantes | Manque | Solution minimale recommandée |
|---|---|---|---|---|
| **En ligne maintenant (< 2 min)**, total + Web/Android/iOS | ❌ Non | `analytics_event.occurred_at` (gestes métier seulement, file différée de 2 à 60 s) ; `analytics_visitor.last_seen_at` (appareil, pas compte) | Une trace « dernière activité » par compte et par plateforme, et un signal de premier plan | Table `user_activity_day.last_seen_at`, écrite par un filtre sur toute requête authentifiée (une écriture par minute au plus) **et** par un heartbeat de 60 s au premier plan (web et mobile) |
| **Actifs uniques période**, total + par plateforme | ⚠️ Proxys seulement | (a) actes d'entraînement datés (V073, **sans plateforme**) ; (b) `analytics_event.user_id` (partiel : beacon sans JWT, écrans muets) | Une ligne par compte × jour × plateforme | La même table `user_activity_day` : `COUNT(DISTINCT user_id)` sur `day BETWEEN` |
| **Utilisateurs connectés** (logins uniques) | ⚠️ Partiel | `refresh_tokens` (ouvertures et rotations depuis le 2026-06-01, jamais purgée) ; `users.last_login_at` (dernière seulement) | Distinction login / inscription / refresh **explicite**, méthode (LOCAL/GOOGLE/APPLE), plateforme | Trois colonnes nullables sur `refresh_tokens` (`opened_by`, `auth_method`, `platform`), posées au seul point d'écriture `SessionService` |
| **Pages / écrans les plus consultés** (vues, uniques, par plateforme) | ❌ Non | `analytics_event.path` sur 24 événements métier, 20 chemins | Événement de vue générique ; chemins gabarits web (81 pages) et mobile (77 routes) | Événement `SCREEN_VIEWED` dans le pipeline existant, émis d'un **seul point** par front ; allowlist élargie |
| Répartition plateforme (transverse) | ✅ Mécanisme oui, persistance non | `X-Sejourfr-Client` → `ClientContextResolver` | Persistance sur l'activité et sur la session | Réutiliser `ClientContextResolver` dans le filtre et dans `SessionService` |

---

## 5. Ce qui est faisable, par nature de travail

### A. Affichable immédiatement, sans modification
Seulement par requête SQL ponctuelle du propriétaire. **Je ne recommande pas d'en faire des
blocs d'écran**, par cohérence avec Q7 de Suivi : ni proxy, ni « bientôt »
(`docs/admin/decisions-suivi.md:59-60`).
- **Comptes ayant fait un acte d'entraînement** par jour ou par période. C'est la `UNION`
  des 4 sources de V073, **sans plateforme**. Ce fait a sa propre autorité et pourra servir
  plus tard de ligne « dont entraînés ».
- **Sessions ouvertes par jour** (lignes racines de `refresh_tokens`), sans plateforme ni
  méthode. ⚠️ Approximatif : deux rotations concurrentes du même jeton laissent une ligne
  orpheline, comptée à tort comme login. Le web dédoublonne (`api.ts:371`) ; le mobile :
  ❓ à confirmer.
- **Comptes distincts avec un événement analytics** par plateforme depuis le 2026-09-28
  (date de `measurementStart`). Biaisé : seuls les écrans instrumentés comptent.

### B. Uniquement du code (sans migration)
- Câbler un appel au purgeur de `refresh_tokens` : `deleteExpired` existe sans appelant.
  À faire **indépendamment** de ce chantier (voir le § RGPD en 6.7).
- Ajouter le preset `LAST_30_DAYS` à `SuiviPeriodPreset`, plus son miroir dans
  `admin_sejourfr/src/types/api.ts`.
- Ajouter l'événement `SCREEN_VIEWED` et élargir `AnalyticsPaths`. **Aucune migration** :
  `analytics_event.event` est un `varchar(48)` sans CHECK. Ce point demande cependant la
  partie D (émetteurs front).
- **Tout le reste (en ligne, actifs, connexions par plateforme) exige une persistance**,
  donc la partie C.

### C. Migration BDD (une seule : `V086`)
- `user_activity_day` (présence et actifs).
- `refresh_tokens` + `opened_by`, `auth_method`, `platform`, plus un index de date.
- SQL au § 7.

### D. Modification web et mobile (dans la même passe, parité)
- **Heartbeat au premier plan** de 60 s : `POST /api/me/presence` → 204.
  - Web : un seul module, branché dans le layout racine. Il ne tourne que si
    `document.visibilityState === "visible"` et s'arrête sur `visibilitychange` (hidden).
  - Mobile : un seul service, branché à côté de la file analytics, sur le patron
    `AppLifecycleListener` (`analytics_queue.dart:162-165`). Démarrage au `onResume` ou
    `onShow`, arrêt au `onHide`, `onPause` ou `onInactive`.
- **`SCREEN_VIEWED`** :
  - Web : un composant client dans `app/layout.tsx` qui écoute `usePathname()` et normalise
    vers le gabarit, en étendant `trackedPath` / `DYNAMIC_PATHS` (`lib/analytics.ts:203-223`),
    qui reste l'autorité unique côté web.
  - Mobile : un listener unique sur le `GoRouter` qui émet le **gabarit de route**
    (`GoRouterState.fullPath`, par ex. `/tcf/sessions/:attemptId`), jamais l'URL concrète.
    ❓ L'API exacte qui donne le gabarit d'une route poussée en go_router 14 reste à
    confirmer à l'implémentation.
- Aucun nouveau test front. Vérification par `npx tsc --noEmit` et `flutter analyze`.

### E. Système externe — probablement pas
- **Firebase Analytics / GA4** : SDK tiers, données hors UE, recoupement possible. Cela
  **fait tomber l'exemption CNIL**, impose un bandeau de consentement
  (`web_sejoufr/app/confidentialite/page.tsx`, §8.4 : « un bandeau de consentement serait
  alors mis en place ») et crée une seconde vérité à côté de `analytics_event`.
- **PostHog / Matomo auto-hébergés** : ils restent conformes, mais doublent tout le
  pipeline existant (lot, idempotence, allowlist, rétention, exclusion des internes)
  pour quatre indicateurs que PostgreSQL sert en quelques requêtes.
- **Seules raisons valables** : des replays de session, des cartes de chaleur ou du temps
  réel à grande échelle. Rien de cela n'est demandé.

---

## 6. Architecture minimale recommandée

### 6.1 Principe
Deux sources, chacune avec **une autorité** :
- **Présence et activité du compte** → `user_activity_day`, côté serveur. On part de ce que
  le serveur voit, sans rien écrire sur le terminal.
- **Navigation** (pages et écrans) → `analytics_event`, pipeline existant, sous l'exemption
  CNIL déjà documentée.

Les connexions se lisent sur `refresh_tokens`, enrichie.

### 6.2 En ligne < 2 min et actifs uniques — `user_activity_day`

**Écriture**, en couches `Controller → Service → Manager → Repository` :
- `UserActivityFilter` (package `security`) est placé **après** `JwtAuthenticationFilter`.
  Pour une requête authentifiée d'un compte, il lit `sub` (userId, sans requête SQL) et la
  plateforme via `ClientContextResolver.resolve(request)`, puis appelle
  `UserActivityService.touch(userId, platform, now)`.
- **Limitation des écritures** : un cache en mémoire `(userId, platform) → dernier instant
  écrit`. On écrit seulement si ≥ 60 s se sont écoulées depuis. Le cache est suffisant
  puisque le backend est **mono-instance** (`InMemoryRateLimiter.java:17`). En
  multi-instance, le pire cas est une écriture par instance et par minute, ce qui reste
  correct.
- Upsert `INSERT … ON CONFLICT (user_id, day, platform) DO UPDATE SET last_seen_at = GREATEST(…)`,
  avec `day` = jour **Europe/Paris** calculé serveur.
- Exécution **best-effort** : `try/catch` et log `warn` sans adresse. Une mesure ne fait
  jamais échouer une requête, comme `AnalyticsIdentityService`.
- **Requêtes exclues** du `touch` : `POST /api/public/analytics/events*` (vidage au
  `onHide`, c'est-à-dire au passage en arrière-plan), `POST /api/auth/refresh` et
  `/api/auth/logout`, plus les requêtes **sans** compte. Le heartbeat
  `POST /api/me/presence` appelle explicitement le même `touch`.

**Lecture** :
- En ligne : `last_seen_at >= now() - interval '2 minutes'` (index `last_seen_at`).
  On renvoie `COUNT(DISTINCT user_id)` pour le total, un compte par plateforme, et le
  nombre de comptes multi-plateformes.
- Actifs période : `day BETWEEN :from AND :to`, avec le même découpage.
- Série journalière : `GROUP BY day` (non additive, comme les visiteurs de Suivi).

**Arrière-plan mobile** :
- Le heartbeat ne tourne **qu'au premier plan**, piloté par le cycle de vie Flutter
  (`AppLifecycleState.resumed` uniquement).
- Les requêtes qui partent malgré tout en arrière-plan sont marginales : polling de
  résultat Android avant gel du processus, et le vidage analytics, exclu ci-dessus. Elles
  prolongent au pire la présence de 2 min.
- Si l'on veut une présence **stricte**, « en ligne » devient « heartbeat seulement »
  (décision D2). Inconvénient : les apps publiées sans heartbeat disparaîtraient de la
  carte jusqu'à leur mise à jour.

**Volume** :
- Une ligne par compte actif, par jour et par plateforme. Même à 1 000 actifs par jour sur
  1,2 plateforme en moyenne, cela fait ≈ 1 200 lignes / jour, soit ≈ 440 000 lignes / an
  et ≈ 50-70 Mo index compris. Négligeable.
- En dev, on aurait aujourd'hui quelques dizaines de lignes.
- Écritures : au plus une par minute et par compte en ligne (100 en ligne ≈ 1,7
  écriture / s), sur des mises à jour de la même ligne.

**Rétention** : purge quotidienne au-delà de 365 j (décision D6, alignée sur « Logs de
connexion : 12 mois », `confidentialite/page.tsx:345`), en passe supplémentaire de
`AnalyticsRetentionJob` ou en job dédié. 🛑 **Suppression de compte** :
`AccountDeletionService` doit supprimer les lignes explicitement, car l'anonymisation ne
déclenche pas la cascade (même piège que `user_funnel_events`,
`docs/regles/mesure-audience.md:110-113`).

### 6.3 Connexions — `refresh_tokens` enrichie
- `opened_by` vaut `LOGIN` | `SIGNUP` | `REFRESH`, `auth_method` vaut `LOCAL` | `GOOGLE` |
  `APPLE` (`NULL` pour `REFRESH`), et `platform` reçoit la valeur de
  `ClientContextResolver`. Les trois sont posés dans `SessionService.openSession` / `rotate`,
  qui est le **seul point d'écriture**. La signature reçoit `AuthKind`, la méthode et la
  plateforme, que `AuthService` et `SocialAuthService` connaissent déjà.
- **Connexion = `opened_by IN ('LOGIN','SIGNUP')`.** Le refresh n'est **pas** une connexion
  (décision D4) : c'est un renouvellement silencieux déclenché par un 401. Il compte
  seulement comme **activité**, via le filtre, et encore pas sur `/api/auth/refresh`
  lui-même.
- La méthode est celle **de cette connexion**, pas `users.auth_provider`, qui est le mode
  de création (`SocialAuthService.java:139-150` : un compte LOCAL peut se connecter par
  Google).
- **Historique** : les lignes antérieures restent `NULL` et ne sont pas rattrapées (Q16).
  L'indicateur `LOGINS` reçoit une `measurementStart` égale à la date de déploiement, et
  rend `null` avant. L'anti-jointure « lignes racines » reste disponible pour une requête
  ponctuelle du propriétaire, jamais comme seconde règle d'écran.
- **Lecture** : connexions totales, utilisateurs uniques ayant ouvert une session dans la
  période, découpage par méthode et par plateforme. Index `(created_at)` partiel sur
  `opened_by IN ('LOGIN','SIGNUP')`.
- **Volume** : inchangé, puisque la table reçoit déjà ces lignes.

### 6.4 Pages / écrans — `SCREEN_VIEWED` dans `analytics_event`
- **Registre** : `SCREEN_VIEWED(Origine.CLIENT)`, sans propriété. `path` est **obligatoire**
  pour cet événement, sauf la valeur nulle déclarée « écran non suivi ».
- **Allowlist** : `AnalyticsPaths.KNOWN` est étendue aux gabarits, avec les segments
  dynamiques ramenés à `[param]` côté web et `:param` côté mobile. **Jamais un identifiant**
  (UUID de tentative ou de session), même parti pris qu'aujourd'hui (`AnalyticsPaths.java:11-18`).
  La règle « ajouter un écran = une ligne dans `KNOWN` dans la même passe » s'applique.
- **Débit** : un événement par changement de page, déjà regroupé en lots (4 s sur le web,
  2 s sur le mobile, 50 au plus).
  - ⚠️ Rate-limit par `anonymousId` : 60 **lots** / 10 min. Une navigation très rapide
    (un lot toutes les 4 s pendant 10 min = 150) peut le dépasser. Pour l'éviter, porter
    le délai d'un `SCREEN_VIEWED` seul à 10-15 s, ou relever `perAnonymousIdBurst` dans
    une `analytics-config-v2.json`, puisqu'on versionne au lieu de réécrire.
  - Sur le web, un lot perdu en 429 n'est pas rejoué ; le mobile a un backoff
    (`analytics_queue.dart:146-148`).
- **Volume** (≈ 0,7 kB par ligne, index compris, mesuré) :

  | Scénario | Vues / jour | Lignes sur 395 j | Taille |
  |---|---|---|---|
  | 100 actifs × 20 écrans | 2 000 | ≈ 0,8 M | ≈ 0,55 Go |
  | 500 × 25 | 12 500 | ≈ 4,9 M | ≈ 3,5 Go |
  | 2 000 × 30 | 60 000 | ≈ 23,7 M | ≈ 17 Go |

  Les volumes de production réels sont ❓ à confirmer. À partir du 2ᵉ scénario, on ajoute
  un **agrégat journalier** `analytics_screen_day (day, platform, path, views,
  unique_visitors, unique_users)`, alimenté chaque nuit, et on purge les `SCREEN_VIEWED`
  bruts au-delà de 90 j. Suivi applique déjà ce principe : vue matérialisée seulement si
  une lecture dépasse 1 s.
- **Index** : `idx_analytics_event_event_date (event, occurred_at DESC)` existe et couvre
  `WHERE event = 'SCREEN_VIEWED' AND occurred_at BETWEEN …`. Aucun index nouveau au départ.
- **Uniques** :
  - Les **visiteurs uniques** (`anonymous_id` distincts) sont fiables sur tous les
    clients.
  - Les **utilisateurs connectés uniques** (`user_id` distincts) sont **partiels** : une
    ligne envoyée par `sendBeacon` n'a pas de `user_id`. On sert les deux, étiquetés, sans
    jamais les fondre.
  - Pour combler le trou sans heuristique, on peut rattacher le `user_id` au sein du même
    `session_id`. Ce n'est qu'une option, à ne pas faire dans un premier temps.
- 🛑 **Impact sur Suivi** : le KPI « Visiteurs uniques » compte les `anonymous_id` ayant
  **n'importe quel** événement (`SuiviReadRepository.java:161-171`). Sans garde,
  `SCREEN_VIEWED` y ferait entrer d'un coup tous les utilisateurs connectés de l'app, ce
  qui casse la comparaison avec les périodes passées. Il faut soit ajouter
  `AND e.event <> 'SCREEN_VIEWED'` dans `ev` et dans les sources (décision D8), soit
  accepter la rupture et lui donner une nouvelle `measurementStart`.
- **Rétention** : les 395 j existants (`AnalyticsRetentionJob`). Rien à ajouter.

### 6.5 Réutilisation de l'existant (récapitulatif)
- `ClientContextResolver` / `ClientPlatform` pour la plateforme.
- `FenetreMesure` et le preset de période de Suivi pour les bornes de Paris.
- `users.is_internal` pour `includeInternal`, qui en est la seule autorité.
- `measurementStart` dans `analytics-config` (versionné) pour le `null` avant la mesure.
- Le pipeline `analytics_event` (lot, idempotence `event_id`, allowlist, purge).
- `SessionService` comme point d'écriture unique des connexions.
- Le patron `AppLifecycleListener` de la file mobile, et le patron `visibilitychange` de
  `lib/analytics.ts`.

### 6.6 Coût de lecture
- **Écran dédié** : 4 requêtes natives **constantes** (en ligne, actifs, connexions,
  écrans), plus éventuellement une 5ᵉ pour la série journalière. À verrouiller par un IT
  d'égalité, comme `SuiviPerformanceIT`.
- **Carte live** : une requête sur `idx_last_seen`, en millisecondes.

### 6.7 RGPD / CNIL — points à signaler
- **Présence et actifs** : ce sont des **données de connexion** du compte, lues côté
  serveur. **Rien n'est écrit sur le terminal**, donc pas de sujet ePrivacy et pas de
  consentement. Base légale : intérêt légitime ou exécution du contrat. C'est déjà couvert
  par « Données de connexion : … dates et heures de connexion »
  (`confidentialite/page.tsx:192-194`), avec une rétention annoncée de 12 mois (`:345`).
  ⚠️ Il faut alors **respecter** ces 12 mois (D6).
- ⚠️ **Écart existant, hors chantier** : `refresh_tokens` conserve **IP et User-Agent sans
  limite de durée** (aucun appelant de `deleteExpired`), alors que la page annonce
  12 mois. C'est sans conséquence aujourd'hui (données depuis le 2026-06-01), mais cela le
  deviendra au 2027-06. Il faut une purge des lignes expirées depuis plus de 12 mois.
  ❓ À vérifier par un test d'intégration : la FK `replaced_by` est sans `ON DELETE`, mais
  une suppression en une seule instruction des maillons expirés devrait passer.
- **Pages par utilisateur identifié** : `analytics_event.user_id` existe déjà, et §8.3
  annonce déjà « la page consultée » et le rattachement au compte. Mais §8.4 fonde
  l'exemption sur des « statistiques d'usage **anonymes** ». Pour rester dans le cadre :
  1. l'écran admin ne montre **que des agrégats** : aucun historique de pages par
     personne, aucune liste « qui est en ligne » ;
  2. on ne croise pas `SCREEN_VIEWED` avec un autre traitement (emails, ciblage) ;
  3. le point 9 de la liste du propriétaire (`docs/admin/decisions-suivi.md:1100`, relire
     §8.2 / §8.4 sur le rattachement au compte) reste **ouvert**, et ce chantier
     l'alourdit. Une relecture juridique est recommandée avant la mise en production
     (❓).
- La page « en ligne » ne doit **jamais** afficher de nom ni d'email : seulement des
  nombres.

---

## 7. Migration éventuelle (texte seulement, NON créée)

Prochain numéro libre vérifié : **`V086`**, plage `00_schema` V001-V099
(`docs/migrations-flyway.md`, dossier `db/migration/00_schema/`, dernier fichier
`V085__schema_signalements_evaluations.sql`). Nom proposé :
`V086__schema_activite_utilisateurs.sql`.

```sql
-- Présence et activité par compte : une ligne par compte × jour (Europe/Paris) × plateforme.
-- Écrite par UserActivityFilter (requêtes authentifiées, limitée à une écriture par minute)
-- et par le heartbeat de premier plan (POST /api/me/presence). Jamais rattrapée : avant le
-- déploiement, l'indicateur vaut null (measurementStart).
CREATE TABLE user_activity_day (
    user_id        uuid         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    day            date         NOT NULL,
    platform       varchar(16)  NOT NULL,
    first_seen_at  timestamptz  NOT NULL,
    last_seen_at   timestamptz  NOT NULL,
    CONSTRAINT pk_user_activity_day PRIMARY KEY (user_id, day, platform),
    CONSTRAINT chk_user_activity_day_platform
        CHECK (platform IN ('WEB', 'IOS', 'ANDROID', 'MOBILE', 'UNKNOWN')),
    CONSTRAINT chk_user_activity_day_order CHECK (last_seen_at >= first_seen_at)
);

-- « En ligne < 2 min »
CREATE INDEX idx_user_activity_day_last_seen ON user_activity_day (last_seen_at DESC);
-- « Actifs sur la période » (+ purge par date)
CREATE INDEX idx_user_activity_day_day ON user_activity_day (day, platform);

-- Connexions : qui a ouvert la session, comment et d'où. NULL = ligne antérieure à la
-- mesure (jamais rattrapée, Q16).
ALTER TABLE refresh_tokens
    ADD COLUMN opened_by   varchar(16),
    ADD COLUMN auth_method varchar(16),
    ADD COLUMN platform    varchar(16),
    ADD CONSTRAINT chk_refresh_tokens_opened_by
        CHECK (opened_by IS NULL OR opened_by IN ('LOGIN', 'SIGNUP', 'REFRESH')),
    ADD CONSTRAINT chk_refresh_tokens_auth_method
        CHECK (auth_method IS NULL OR auth_method IN ('LOCAL', 'GOOGLE', 'APPLE')),
    ADD CONSTRAINT chk_refresh_tokens_platform
        CHECK (platform IS NULL OR platform IN ('WEB', 'IOS', 'ANDROID', 'MOBILE', 'UNKNOWN'));

CREATE INDEX idx_refresh_tokens_logins
    ON refresh_tokens (created_at DESC)
    WHERE opened_by IN ('LOGIN', 'SIGNUP');
```

Notes :
- `varchar` et non `char` : Hibernate refuse `bpchar` sous `ddl-auto: validate`
  (`docs/regles/mesure-audience.md:190-191`).
- **Aucune migration de données.**
- `SCREEN_VIEWED` ne demande **aucune** DDL (`analytics_event.event` est un `varchar(48)`
  sans CHECK). L'agrégat `analytics_screen_day` n'est à créer que si le volume l'exige
  (§ 6.4), dans une migration ultérieure.
- Une ligne dans `measurementStart` (`analytics-config-v2.json`, nouvelle version) pour
  `ACTIVE_USERS`, `LOGINS` et `SCREEN_VIEWS`, plus la surcharge dev correspondante dans
  `application-dev.yaml`.

---

## 8. Organisation UI

### 8.1 Sur `/dashboard` (Suivi) : une carte légère, rien d'autre

```
┌ Actifs maintenant ─────────────────────────────── ● en direct ┐
│  12    Web 7 · Android 3 · iOS 2   (+1 app, système inconnu) │
│                                         Voir l'activité  →    │
└───────────────────────────────────────────────────────────────┘
```
- Placée **en tête**, au-dessus des 4 KPI. Elle ne dépend **pas** de la période ni des
  filtres type, plateforme ou source : c'est « maintenant ». Elle respecte seulement
  `internal=1` de l'URL, par cohérence.
- Données : `GET /api/admin/analytics/activity/live?includeInternal=`, requête TanStack
  séparée (`["adminActivityLive", includeInternal]`), `refetchInterval` 30 s, sans cache
  serveur.
  ⚠️ Cela fait **deux appels** sur la page Suivi. C'est un écart assumé à « un seul
  appel », car la cadence de rafraîchissement diffère (D11). L'alternative est d'inclure
  `live` dans `AdminSuiviResponse`, sans rafraîchissement automatique.
- `null` avant `measurementStart` : la carte affiche « — · mesuré à partir du JJ/MM »,
  jamais 0.
- Les sous-totaux par plateforme **ne somment pas** au total (multi-plateforme) : le total
  est servi tel quel.
- Lien « Voir l'activité → » vers `/dashboard/activity`, en conservant `internal`.

### 8.2 Écran dédié — recommandation : `/dashboard/activity`
Ce chemin est préféré à `/dashboard/analytics` pour trois raisons :
- « analytics » a déjà désigné l'ancien écran supprimé et l'endpoint retiré
  `GET /api/admin/analytics`, ce qui sème la confusion dans la doc ;
- le contenu porte sur l'**activité** des comptes ;
- sous `/dashboard/…`, `navEntryFor` (préfixe le plus long) le rattache naturellement à
  « Pilotage ».

**Navigation** : ajouter `{ to: "/dashboard/activity", label: "Activité", icon: … }` dans
la section « Pilotage » de `navigation.ts`, sous « Suivi ». L'alternative est une entrée
cachée (`hidden: true`), accessible seulement par le lien de la carte (D9).

**Structure de l'écran**, dans l'ordre :

1. **Barre de filtres** : période Aujourd'hui / Hier / 7 j / 30 j / Personnalisé
   (≤ 365 j), case « Inclure les comptes internes ».
   - État dans l'URL (`?period&from&to&internal`), même patron que `useSuiviParams`,
     défaut non écrit.
   - Bornes **servies** affichées (`window.from/to`), en heure de Paris.
   - Pas de filtre plateforme : la plateforme est une **colonne** partout.
2. **En ligne maintenant** : même bloc que la carte, en grand. Il ne dépend pas de la
   période et se rafraîchit seul toutes les 30 s.
3. **KPI de la période**, 2 tuiles :
   - *Utilisateurs actifs* (uniques, `previous` et `deltaPct` servis) ;
   - *Utilisateurs connectés* : comptes uniques ayant ouvert une session, avec « dont N
     inscriptions » et « N connexions au total ».
4. **Répartition par plateforme**, en tableau. Lignes Web / iOS / Android / App (système
   inconnu) / Non déclarée ; colonnes : actifs uniques, comptes connectés, connexions.
   - Pied : « Total — un compte compté une fois », plus « dont N sur plusieurs
     plateformes ».
   - Ligne « par méthode » pour les connexions : e-mail / Google / Apple.
5. **Actifs par jour** : barres, seulement pour 7 j, 30 j ou une période personnalisée de
   plus d'un jour. Série servie et continue, mention « non additive ».
6. **Pages et écrans les plus consultés** : deux onglets, **Web** et **Application**
   (iOS + Android, avec une colonne par système).
   - Colonnes : écran (gabarit, plus un libellé si l'on en ajoute un), vues, visiteurs
     uniques, comptes connectés uniques (partiel, avec mention).
   - Top 20, plus une ligne servie « Autres écrans suivis » et une ligne « Écrans non
     déclarés » (`path` nul), pour que la somme des vues tombe juste.
   - Version mobile : cartes, pas de tableau (responsive 360 / 768 / 1280).

**Endpoint unique de l'écran** : `GET /api/admin/analytics/activity?preset=TODAY|YESTERDAY|LAST_7_DAYS|LAST_30_DAYS`
ou `from`/`to` (jamais les deux, sinon 400), plus `includeInternal`. La chaîne de couches
est `AdminActivityController → ActivityService → ActivityReadManager →
ActivityReadRepository` (SQL natif) avec un mapper pur `ActivityMapper`.

**Esquisse du DTO** (miroir à la main dans `admin_sejourfr/src/types/api.ts`) :
```ts
interface AdminActivityResponse {
  window: { from: string; to: string; timezone: "Europe/Paris";
            measurementStart: { ACTIVE_USERS: string|null; LOGINS: string|null; SCREEN_VIEWS: string|null } };
  live: ActivityLive;                       // identique à GET …/activity/live
  activeUsers: {
    total: number|null; previous: number|null; deltaPct: number|null;
    byPlatform: PlatformCounts;             // web, ios, android, appUnknownSystem, undeclared
    multiPlatformUsers: number|null;
    daily: { day: string; total: number; byPlatform: PlatformCounts }[] | null;
  };
  logins: {
    uniqueUsers: number|null; total: number|null; signups: number|null;
    byMethod: { local: number|null; google: number|null; apple: number|null };
    byPlatform: PlatformCounts;
  };
  screens: {
    web: ScreenRow[]; app: ScreenRow[];
    webOther: ScreenTotals; appOther: ScreenTotals; undeclared: ScreenTotals;
  } | null;
}
interface ActivityLive { at: string; windowSeconds: 120; total: number|null;
                         byPlatform: PlatformCounts; multiPlatformUsers: number|null }
interface PlatformCounts { web: number|null; ios: number|null; android: number|null;
                           appUnknownSystem: number|null; undeclared: number|null }
interface ScreenRow { path: string; views: number; uniqueVisitors: number;
                      uniqueUsers: number; ios?: number; android?: number }
```
Conventions Suivi reprises :
- `null` = non mesuré, jamais 0 ;
- **aucun pourcentage calculé côté front** : `deltaPct` est servi, et la longueur d'une
  barre peut être relative au maximum, sans aucun % affiché ;
- format `format.ts` partagé avec Suivi (espace fine, `—`) ;
- libellé « iOS », jamais « Apple » ;
- tokens CSS uniquement ;
- `includeInternal` = `users.is_internal`.

---

## 9. Décisions à valider

| # | Choix | Options | Recommandation |
|---|---|---|---|
| D1 | Définition d'« actif » | (a) toute requête API authentifiée + heartbeat ; (b) acte d'entraînement (V073) ; (c) événement analytics | **(a)**. C'est la seule qui porte la plateforme et couvre la lecture du Plan, de la progression, etc. (b) peut s'ajouter plus tard en ligne « dont entraînés » |
| D2 | Heartbeat | (a) aucun, requêtes seules ; (b) 60 s au premier plan, plus les requêtes ; (c) heartbeat seul pour « en ligne » | **(b)**. (a) rate la rédaction EE (brouillon local, aucune requête) et la lecture longue. (c) est plus strict mais rend les apps non mises à jour invisibles. On rebascule en (c) quand l'ancienne app passe sous 5 % |
| D3 | Qui est compté « en ligne » | (a) comptes connectés seulement ; (b) plus les visiteurs anonymes (`anonymous_id`) | **(a)**. C'est la demande (« utilisateurs ») ; les visiteurs restent dans Suivi |
| D4 | Un refresh vaut-il connexion ? | (a) non ; (b) oui | **(a) non**. Automatique et silencieux, il compte seulement comme activité |
| D5 | Stockage des connexions | (a) 3 colonnes sur `refresh_tokens` ; (b) table dédiée `user_login_event` sans IP | **(a)**. Point d'écriture unique déjà en place, zéro nouvelle table. Assortir d'une purge à 12 mois de `refresh_tokens` |
| D6 | Rétention de `user_activity_day` | (a) 365 j (= « logs de connexion 12 mois ») ; (b) 395 j (comme analytics) | **(a)**. C'est la durée déjà annoncée publiquement pour ce type de donnée |
| D7 | Granularité des écrans | (a) toutes les routes en gabarit (~81 web, ~77 mobile) ; (b) ~30 écrans métier en gabarit, le reste `path` nul ; (c) une clé d'écran logique commune web ⇄ mobile | **(b)**. Allowlist lisible et tableau utile. (c) imposerait une table de correspondance de plus |
| D8 | `SCREEN_VIEWED` et le KPI « Visiteurs » de Suivi | (a) l'exclure de la requête Visiteurs et Sources ; (b) l'inclure avec une nouvelle `measurementStart` | **(a)**. Pas de rupture de série |
| D9 | Route et navigation | `/dashboard/activity` ou `/dashboard/analytics` ; entrée de nav visible ou cachée | **`/dashboard/activity`, entrée visible « Activité »** sous « Pilotage » |
| D10 | Période « 30 j » | (a) ajouter `LAST_30_DAYS` à `SuiviPeriodPreset` (Suivi en profite) ; (b) enum propre à l'écran | **(a)**. Une seule autorité des périodes |
| D11 | Données de la carte live | (a) endpoint `…/activity/live` séparé, rafraîchi toutes les 30 s ; (b) champ dans `AdminSuiviResponse` | **(a)**. Cadence différente : écart documenté à « un seul appel » |
| D12 | Lignes `MOBILE` (ancienne app) | (a) ligne « App (système inconnu) » à part ; (b) masquées | **(a)**. Jamais réparties, jamais cachées : la somme doit tomber juste |

---

## 10. Inconnues (❓)

- ❓ **Volumes de production** : DAU, événements par jour, taille réelle de
  `refresh_tokens`. Le dev n'est pas représentatif, et l'estimation du § 6.4 est un
  scénario.
- ❓ **Part des apps publiées qui envoient encore `mobile`**. Elle se mesure en production
  par la requête de `docs/regles/mesure-audience.md:207-215`.
- ❓ **Comportement Android en arrière-plan** : combien de temps les `Timer.periodic` de
  polling (3 s) continuent avant le gel du processus.
- ❓ **Dédoublonnage des refresh concurrents côté mobile** (le web l'a,
  `api.ts:371-376`). Cela n'a d'impact que sur la reconstitution historique par
  anti-jointure.
- ❓ **Journaux d'accès du reverse-proxy en production** : existence et rétention. Ils ne
  servent pas de source, mais comptent pour le RGPD.
- ❓ **Comptes admin et de test tous marqués `is_internal` en production** : seule autorité
  de l'exclusion.
- ❓ **API go_router 14** pour récupérer le gabarit (`fullPath`) d'une route **poussée**
  depuis un listener unique.
- ❓ **Lecture juridique de l'exemption CNIL** avec des vues de page rattachées à un compte
  identifié (point 9 ouvert de `docs/admin/decisions-suivi.md:1100`).
- ❓ **Suppression d'une chaîne `refresh_tokens` expirée** malgré la FK `replaced_by` sans
  `ON DELETE`, à vérifier par un IT avant de câbler la purge.
