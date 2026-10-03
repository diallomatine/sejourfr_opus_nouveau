# Plan technique — activité des utilisateurs (admin `/dashboard` + `/dashboard/activity`)

> **Point de départ** : `docs/admin/activites/audit-activite-utilisateurs.md` (audit du
> 2026-10-03, non modifié, qui reste la référence des constats et des chiffres de dev).
> Ce plan est **en lecture seule** : aucun code ni aucune migration n'ont été créés.
> Toutes les références `fichier:ligne` ont été vérifiées sur `develop` (HEAD `e9bf5516`).

## Arbitrages du propriétaire (2026-10-03)

| # | Décision retenue |
|---|---|
| D1 | **Actif** = requête API authentifiée + heartbeat |
| D2 | Heartbeat **60 s, premier plan uniquement** |
| D3 | « En ligne » = **comptes connectés uniquement** |
| D4 | Un refresh **ne compte jamais** comme connexion |
| D5 🔁 **révisé** | `refresh_tokens` **reste technique** : aucune colonne ajoutée, **purge automatique**. Les connexions vont dans une **table dédiée `user_login_event`** (sans IP, sans User-Agent, sans refresh, 365 j) |
| D6 | Activité conservée **365 j** |
| D7 | **~30 écrans métier**, le reste en « écran non déclaré » |
| D8 | `SCREEN_VIEWED` **exclu** du KPI « Visiteurs » de Suivi |
| D9 | Écran **`/dashboard/activity`**, entrée **« Activité »** sous « Pilotage » |
| D10 | `LAST_30_DAYS` ajouté aux périodes de Suivi |
| D11 | Endpoint **live séparé**, rafraîchi toutes les 30 s |
| D12 | Ligne **« App — système inconnu »** pour les anciennes versions (`mobile`) |

## Les quatre sources, une autorité chacune

| Table | Rôle | Écrite par | Rétention |
|---|---|---|---|
| `refresh_tokens` | **technique** : sessions vivantes, rotation, détection de réutilisation | `SessionService` (inchangé) | expirée depuis plus de 7 j ⇒ purgée (§ 2.1) |
| `user_login_event` (nouvelle) | **connexions** : login et inscription, par méthode et par plateforme | `SessionService.openSession` → événement `AFTER_COMMIT` | 365 j |
| `user_activity_day` (nouvelle) | **présence** (en ligne < 2 min) et **actifs** sur une période | intercepteur des requêtes authentifiées + heartbeat | 365 j |
| `analytics_event` (nom vérifié : `\d analytics_event`) | **pages et écrans** (`SCREEN_VIEWED`) | pipeline d'ingestion en lot existant | 395 j (existant) |

---

## 1. Migrations

Le prochain numéro libre est **`V086`**, dans la plage `00_schema` (V001-V099, dernier
fichier `V085__schema_signalements_evaluations.sql`). Les versions 879, 890, 900 et 901
appartiennent à d'autres plages.

**Recommandation : deux migrations.** Le lot 1 (purge de `refresh_tokens`) est
indépendant et se déploie seul, avant le reste. C'est la règle « déployer après chaque
modif ». Les deux numéros sont à revérifier au moment du codage, si une autre branche a
posé `V086` entre-temps.

### 1.1 `V086__refresh_tokens_purge.sql` (lot 1)

**Vérification de la FK**, faite sur la base (`\d refresh_tokens`) :
- `refresh_tokens_replaced_by_fkey FOREIGN KEY (replaced_by) REFERENCES refresh_tokens(jti)` :
  c'est une **auto-référence**, **sans `ON DELETE`**, donc `NO ACTION`.
- `refresh_tokens_user_id_fkey … ON DELETE CASCADE` vers `users`.
- Aucune autre table ne référence `refresh_tokens` (section « Référencé par » : seulement
  elle-même).
- La colonne `replaced_by` **n'est jamais lue** dans le code : elle est seulement écrite
  (`SessionService.java:121`). Le commentaire de l'entité le dit aussi (« pas exploité pour
  l'instant », `RefreshToken.java:40-44`).
- **Risque si on ne change rien** : supprimer par lots une ligne B encore référencée par
  une ligne A (son prédécesseur) qui n'est pas dans le même lot fait échouer tout le lot.
  `NO ACTION` est vérifié en fin d'instruction, pas en fin de transaction.
- **Correction** : passer la FK en `ON DELETE SET NULL`. On perd un chaînage que personne
  ne lit, et la purge devient sûre quel que soit l'ordre ou la taille des lots.

```sql
-- refresh_tokens reste une table TECHNIQUE (sessions). Elle n'est pas un historique de
-- connexions : les connexions vivent dans user_login_event (V087).
-- La purge (RefreshTokenPurgeJob) supprime par lots les lignes expirées depuis plus de
-- la marge configurée. Avec ON DELETE SET NULL, un lot qui emporte le successeur d'une
-- ligne restante ne viole plus la FK.
ALTER TABLE refresh_tokens
    DROP CONSTRAINT refresh_tokens_replaced_by_fkey,
    ADD CONSTRAINT refresh_tokens_replaced_by_fkey
        FOREIGN KEY (replaced_by) REFERENCES refresh_tokens (jti) ON DELETE SET NULL;

-- Prédicat de purge (expires_at < cutoff). Aucun index n'existe aujourd'hui sur cette
-- colonne.
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens (expires_at);
```

### 1.2 `V087__schema_activite_utilisateurs.sql` (lot 2)

```sql
-- =====================================================================
-- Connexions : une ligne par OUVERTURE DE SESSION (login ou inscription).
-- Jamais de refresh, jamais d'IP, jamais de User-Agent. Rétention 365 j.
-- Écrite après commit de la transaction d'authentification : un échec
-- d'insertion ne bloque jamais une connexion.
-- =====================================================================
CREATE TABLE user_login_event (
    id           uuid         NOT NULL,
    user_id      uuid         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    occurred_at  timestamptz  NOT NULL,
    kind         varchar(16)  NOT NULL,
    auth_method  varchar(16)  NOT NULL,
    platform     varchar(16)  NOT NULL,
    CONSTRAINT pk_user_login_event PRIMARY KEY (id),
    CONSTRAINT chk_user_login_event_kind
        CHECK (kind IN ('LOGIN', 'SIGNUP')),
    CONSTRAINT chk_user_login_event_auth_method
        CHECK (auth_method IN ('LOCAL', 'GOOGLE', 'APPLE')),
    CONSTRAINT chk_user_login_event_platform
        CHECK (platform IN ('WEB', 'IOS', 'ANDROID', 'MOBILE', 'UNKNOWN'))
);

-- Lecture par période (+ purge par date)
CREATE INDEX idx_user_login_event_occurred ON user_login_event (occurred_at DESC);
-- Suppression de compte, fiche utilisateur éventuelle
CREATE INDEX idx_user_login_event_user ON user_login_event (user_id, occurred_at DESC);

-- =====================================================================
-- Présence et activité : une ligne par compte × jour (Europe/Paris) × plateforme.
-- Upsert au plus une fois par minute et par (compte, plateforme, jour).
-- Rétention 365 j.
-- =====================================================================
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
-- « Actifs sur la période » + purge par jour
CREATE INDEX idx_user_activity_day_day ON user_activity_day (day, platform);
```

Notes :
- **Valeurs de plateforme** : on reprend la convention existante `ClientPlatform`
  (`WEB|IOS|ANDROID|MOBILE|UNKNOWN`, `ClientPlatform.java:20-26`), pas une valeur
  « MOBILE_INCONNU » de plus. L'écran affiche `MOBILE` sous le libellé « App — système
  inconnu » (D12) et `UNKNOWN` sous « Non déclarée ».
- **Méthode** : enum `AuthProvider` existant (`LOCAL|GOOGLE|APPLE`, `AuthProvider.java:3-7`).
  **Type** : enum `AuthKind` existant (`SIGNUP|LOGIN`, `AuthKind.java:12-15`).
- `varchar` et non `char`, car Hibernate refuse `bpchar` sous `ddl-auto: validate`
  (`docs/regles/mesure-audience.md:190-191`).
- **`ON DELETE CASCADE` sur `users`** : la cascade ne joue que sur une vraie suppression.
  La suppression de compte étant une **anonymisation**, la ligne `users` survit.
  `AccountDeletionService` supprime donc ces lignes **explicitement**, sur le patron de
  `user_funnel_events` (`AccountDeletionService.java:133-146`).
- **Aucune migration de données** : avant le déploiement, les indicateurs valent `null`
  (`measurementStart`, § 3.6).
- **`SCREEN_VIEWED` n'a besoin d'aucune DDL.** `analytics_event.event` est un
  `varchar(48)` sans CHECK : la seule contrainte de la table porte sur `diagnostic_type`.
  Le registre est l'enum Java `AnalyticsEvent`, et l'allowlist est
  `AnalyticsPaths.KNOWN`, en code.

---

## 2. Jobs de purge

Les conventions existantes, reprises telles quelles :
- `@EnableScheduling` (`SejourFrAppApplication.java:19`), mono-instance
  (`InMemoryRateLimiter.java:17`), donc pas de ShedLock ;
- cron dans `application.yaml`, zone `Europe/Paris` ;
- un `Job` non transactionnel qui attrape et logge, et un `Service` qui supprime **par
  lots**, une transaction par lot, en boucle tant qu'un lot est plein. C'est le patron de
  `AnalyticsRetentionJob.java:23-30`, `AnalyticsRetentionService.java:47-75` et
  `GuestAttemptPurgeJob`.

### 2.1 `refresh_tokens` — `RefreshTokenPurgeJob` (lot 1)

**Durée proposée : supprimer une ligne 7 jours après son `expires_at`**, révoquée ou
non. Une ligne vit donc au plus 30 j (TTL) + 7 j = **37 j**.

Justification, à partir du code :
- Le JWT de refresh et la ligne partagent la même échéance, `refreshTokenTtl` = 30 j
  (`JwtService.java:64-71` et `:90-92`, `SessionService.java:53,115`).
- Passé `exp`, `parseAndValidate` rejette le JWT **avant** toute lecture de la ligne
  (`SessionService.java:73-77`). La ligne n'a alors plus aucun usage.
- Avant l'échéance, une ligne **révoquée** sert encore : c'est la **détection de
  réutilisation** (`SessionService.java:92-99`, log `warn` puis refus). On la garde donc
  jusqu'à son expiration.
- Si on la purgeait plus tôt, le jeton serait refusé de toute façon (« Session révoquée
  ou inconnue », `:89-90`), mais on perdrait le signal de vol.
- La marge de 7 j laisse le temps de rapprocher un `warn` de réutilisation d'une session
  pendant une analyse d'incident. Elle n'a pas d'autre rôle.

Le reste du dispositif :
- **Méthode existante réutilisée** : `RefreshTokenRepository.deleteExpired(Instant before)`
  (`RefreshTokenRepository.java:26-27`) n'a aujourd'hui **aucun appelant**. On la
  transforme en suppression **bornée** (requête native
  `DELETE … WHERE jti IN (SELECT jti … WHERE expires_at < :before ORDER BY expires_at LIMIT :limit)`),
  sans en ajouter une seconde. Elle est exposée par
  `RefreshTokenManager.deleteExpiredBefore(cutoff, batch)`.
- **Ordre et sûreté** : grâce à V086 (`ON DELETE SET NULL`), l'ordre n'importe plus.
  `ORDER BY expires_at` est gardé par lisibilité, puisque les prédécesseurs partent en
  premier.
- **Lecteurs d'un jeton révoqué** : seulement `SessionService.rotate` (lookup par `jti`) et
  `closeSession` (`:140`). Les deux tolèrent une ligne absente : refus dans le premier cas,
  logout silencieux dans le second.
- **Config**, sans nouvelle source : `sejourfr.security.jwt` (`JwtProperties.java:5`,
  `application.yaml:247-250`) reçoit :
  - `refresh-token-purge-cron: "0 25 4 * * *"` (après la purge analytics de 04:10) ;
  - `refresh-token-purge-grace-days: 7` ;
  - `refresh-token-purge-batch-size: 1000`.
- **Fréquence** : quotidienne. Au premier passage, ≈ 477 lignes en dev, toutes expirées.

**Conséquence sur `/confidentialite`**, à signaler et **non modifiée** ici :
- la page annonce « Données de connexion : adresse IP, type et version du navigateur… »
  (`web_sejoufr/app/confidentialite/page.tsx:192-194`) et « Logs de connexion : 12 mois »
  (`:345`) ;
- après le plan, l'IP et le User-Agent seront gardés **au plus ~37 j**, et seulement pour
  la sécurité des sessions. L'**historique des connexions** (date, méthode, plateforme,
  sans IP) et les jours d'activité sont gardés **12 mois** ;
- la promesse de 12 mois **devient tenue**, alors qu'elle est aujourd'hui dépassable
  (`refresh_tokens` n'est jamais purgée). Mais le texte mélange les deux. Il faudra le
  scinder, dans la même passe que le lot 2 : « IP et navigateur : durée de la session + 7
  jours » d'un côté, « historique de connexion et d'activité : 12 mois » de l'autre.
  **À faire valider avant la modification de la page.**

### 2.2 `user_login_event` et `user_activity_day` (lot 2)

- **Pas de nouveau job.** Une passe s'ajoute à la purge quotidienne existante
  `AnalyticsRetentionJob` (04:10 Paris), via un service dédié `AccountActivityRetentionService`
  appelé par le même job. On garde ainsi une seule heure de purge pour la mesure, et
  chaque service porte son périmètre.
- **Config**, sans nouvelle source : nouvelle version du fichier versionné,
  `analytics/analytics-config-v2.json` (on versionne au lieu de réécrire v1 ;
  `ANALYTICS_CONFIG_VERSION=2`). Ajouts :
  - `"accountActivityRetentionDays": 365` ;
  - les trois indicateurs du § 3.6 ;
  - le seuil d'ingestion du § 2.3.

  `purgeBatchSize` (1 000) est réutilisé.
- **Prédicats** :
  - `user_login_event` : `occurred_at < now − 365 j`, par lots sur
    `idx_user_login_event_occurred` ;
  - `user_activity_day` : `day < (aujourd'hui Paris − 365 j)`, par lots sur
    `idx_user_activity_day_day`.

### 2.3 `SCREEN_VIEWED`

- **Rétention : celle de `analytics_event`** (395 j, `AnalyticsRetentionJob`). Aucune
  rétention spécifique au départ.
- Si le volume l'exige (audit § 6.4, à partir d'environ 10 000 vues par jour), on ajoute un
  agrégat journalier `analytics_screen_day` et une purge des bruts à 90 j. Ce sera une
  migration et une décision **ultérieures**.
- **Rate-limit** : `perAnonymousIdBurst` = 60 lots / 10 min. On passe à 120 dans
  `analytics-config-v2.json`, car une navigation rapide peut dépasser 60 lots (audit
  § 6.4).

---

## 3. Backend

### 3.1 Écriture de l'activité — `user_activity_day`

| Couche | Classe | Rôle |
|---|---|---|
| Sécurité (modifiée) | `security/JwtAuthenticationFilter.java:53-59` | Pose en plus l'attribut de requête `sejourfr.userId` = `claims.getSubject()` (le `sub` est l'id, `JwtService.java:46`). Aucune requête SQL de plus |
| Web (nouvelle) | `config/ActivityWebConfig` (`WebMvcConfigurer`) + `security/UserActivityInterceptor` (`HandlerInterceptor.preHandle`) | Lit l'attribut, résout la plateforme par `ClientContextResolver.resolve(request)` (autorité unique), appelle le service. **Ne refuse jamais** une requête (retour toujours `true`, `try/catch`, `warn` sans adresse) |
| Service (nouveau) | `service/activity/UserActivityService` | `touch(userId, platform, now)`. **Limitation à une écriture par minute** via un cache Caffeine (dépendance déjà présente, `pom.xml:186`) sur la clé `(userId, platform, jourParis)` → dernier instant écrit, accès expiré à 2 min. Écrit seulement si ≥ 60 s se sont écoulées ou si la clé est nouvelle (le changement de jour force une ligne) |
| Manager (nouveau) | `manager/UserActivityManager` | Seul accès au repository |
| Repository (nouveau) | `repository/UserActivityDayRepository` | Upsert natif : `INSERT … ON CONFLICT (user_id, day, platform) DO UPDATE SET last_seen_at = GREATEST(user_activity_day.last_seen_at, EXCLUDED.last_seen_at)` |
| Entité (nouvelle) | `entity/UserActivityDay` (+ `@Embeddable` id) | `@Getter/@Setter`, jamais `@Data` |

**Règle d'écriture** : une requête compte si elle porte un JWT d'accès valide, donc un
compte, quel que soit son rôle. L'exclusion des internes et de l'admin se fait **à la
lecture**, par `users.is_internal`.

**Exclusions** (`excludePathPatterns` de l'intercepteur) :
- `/api/public/analytics/**` (vidage de file au passage en arrière-plan,
  `analytics_queue.dart:165`) ;
- `/api/auth/**` (refresh, logout ; le login n'a pas de JWT) ;
- `/files/**`, `/actuator/**`, `OPTIONS`.

**Heartbeat** : `POST /api/me/presence` → **204**, corps vide.
- Le contrôleur `controller/MePresenceController` est vide de logique : c'est
  l'intercepteur qui fait le `touch`, ce qui garde **un seul point d'écriture**.
- La route est authentifiée par la règle `anyRequest().authenticated()` existante
  (`SecurityConfig.java:102`).

### 3.2 Écriture des connexions — `user_login_event`

**Point d'écriture unique : `SessionService.openSession`** (`SessionService.java:47-61`).
- Ouvrir une session, c'est une connexion ; `rotate` (le refresh) n'en publie jamais, d'où
  D4 par construction.
- La signature devient `openSession(User, userAgent, ip, SessionOrigin origin)`, avec
  `record SessionOrigin(AuthKind kind, AuthProvider method, ClientPlatform platform)`.

Appelants à adapter, qui sont les deux seuls existants :

| Point d'entrée | Où | `kind` | `method` | `platform` |
|---|---|---|---|---|
| Login local | `AuthService.authenticate` → `buildTokenResponse` (`AuthService.java:69-99`, `:242-245`) | `LOGIN` | `LOCAL` | `ctx.platform()` (déjà résolu à `:88`) |
| Inscription locale | `AuthService.register` → `authenticate(…, AuthKind.SIGNUP)` (`:174-175`) | `SIGNUP` | `LOCAL` | idem |
| Google (login ou création) | `SocialAuthService.loginWithGoogle` → `buildTokenResponse` (`SocialAuthService.java:74-83`, `:177-178`) | `r.created() ? SIGNUP : LOGIN` (déjà calculé à `:120`) | `identity.provider()`, c'est-à-dire la méthode **de cette connexion**, pas `users.auth_provider` | `client.platform()` |
| Apple (login ou création) | `SocialAuthService.loginWithApple` (`:85-93`) | idem | idem | idem |

**Transaction** : `openSession` publie `UserLoggedInEvent(userId, kind, method, platform,
occurredAt)` **dans** la transaction d'authentification (`AuthService` et
`SocialAuthService` sont `@Transactional`, `AuthService.java:43`,
`SocialAuthService.java:59`).
- Un listener `service/activity/UserLoginEventListener`
  (`@TransactionalEventListener(phase = AFTER_COMMIT)`, même patron que
  `EmailEventListener.java:43`) appelle `UserLoginEventService.record(…)`, qui est
  `@Transactional(propagation = REQUIRES_NEW)`, dans un `try/catch` qui logge en `warn`.
- **Pourquoi `AFTER_COMMIT`** : en Postgres, un `INSERT` en échec **dans** la transaction
  de login l'empoisonne (« current transaction is aborted »). Un `try/catch` ne suffit pas,
  et le login échouerait.
- Après commit, l'échec ne coûte qu'une ligne de mesure. La seule perte possible est un
  arrêt du processus entre le commit et l'insert, ce qui est acceptable pour une
  statistique.
- **Pas d'exécuteur asynchrone** : l'insert est en mémoire de pile, ~1 ms, et rester
  synchrone garde l'ordre et facilite les tests.

Chaîne en couches : `UserLoginEventService → UserLoginEventManager →
UserLoginEventRepository` (+ entité `UserLoginEvent`).

### 3.3 `SCREEN_VIEWED`

- `enums/AnalyticsEvent.java` : ajouter `SCREEN_VIEWED(Origine.CLIENT)`, **sans
  propriété**. `path` est porté par la colonne, `null` = « écran non déclaré ».
- `util/AnalyticsPaths.java:34-62` : ajouter les gabarits du § 4.3. Un chemin déjà connu
  (`/plan`, `/diagnostic`, `/diagnostic-civique/resultat`…) est **réutilisé**, jamais
  doublé.
- `AnalyticsEventNormalizer` : rien de spécifique. Le chemin facultatif et l'allowlist
  existent déjà.
- **Suivi (D8)** : `SuiviReadRepository.java:161-171` (CTE `ev`, visiteurs et sources)
  reçoit `AND e.event <> 'SCREEN_VIEWED'`. Toute autre lecture « n'importe quel
  événement » du même fichier est à passer en revue au codage. Les lectures du tunnel
  filtrent déjà par nom d'événement.

### 3.4 Lecture — endpoints admin

**`GET /api/admin/analytics/activity/live?includeInternal=false`** (D11, carte et bloc
« maintenant »).

```java
record ActivityLiveResponse(
    Instant at, int windowSeconds,                 // 120
    Integer total,                                 // comptes distincts, null avant measurementStart
    PlatformCounts byPlatform,
    Integer multiPlatformUsers,
    LocalDate measurementStart) {}
record PlatformCounts(Integer web, Integer ios, Integer android,
                      Integer appUnknownSystem /* MOBILE */, Integer undeclared /* UNKNOWN */) {}
```

Une requête :
```sql
SELECT platform, COUNT(DISTINCT user_id) FROM user_activity_day
 WHERE last_seen_at >= now() - interval '2 minutes'
   AND day >= :parisToday - 1
   AND (:includeInternal OR user_id NOT IN (SELECT id FROM users WHERE is_internal))
 GROUP BY ROLLUP(platform)
```
Le nombre de comptes multi-plateformes vient de la même lecture, par un `HAVING` sur un
sous-agrégat.

**`GET /api/admin/analytics/activity?preset=TODAY|YESTERDAY|LAST_7_DAYS|LAST_30_DAYS|MONTH`**
ou `from`/`to` (`yyyy-MM-dd`, Paris, ≤ 365 j, jamais les deux, sinon 400), plus
`includeInternal`.
- La fenêtre est résolue par `FenetreMesure`, avec la **même** résolution de preset que
  Suivi (`SuiviService.java:118-126`).
- Recommandation : extraire cette résolution dans une méthode de `SuiviPeriodPreset` ou de
  `FenetreMesure`, pour éviter une deuxième copie de la table des presets.

```java
record AdminActivityResponse(
    Window window,                       // from, to, timezone, measurementStart{ACTIVE_USERS, LOGINS, SCREEN_VIEWS_WEB, SCREEN_VIEWS_APP}
    ActivityLiveResponse live,
    ActiveUsers activeUsers,             // total, previous, deltaPct, byPlatform, multiPlatformUsers, daily[{day,total,byPlatform}]
    Logins logins,                       // uniqueUsers, total, signups, byMethod{local,google,apple}, byPlatform (comptes uniques)
    Screens screens) {}                  // web[], app[], webOther, appOther, undeclaredWeb, undeclaredApp
record ScreenRow(String path, long views, long uniqueVisitors, long uniqueUsers,
                 Long ios, Long android) {}   // ios/android renseignés pour l'onglet App
```

Règles, reprises de Suivi :
- `null` = non mesuré ;
- `previous` n'est lu que si la période précédente est mesurée de bout en bout (D117) ;
- `deltaPct` est servi, et `previous = 0` ⇒ `null` ;
- les internes sont exclus en SQL ;
- **aucun % calculé par le front** ;
- `uniqueVisitors` = `anonymous_id` distincts ; `uniqueUsers` = `user_id` distincts,
  partiel puisque `sendBeacon` part sans JWT. Les deux sont servis et étiquetés.

Coût fixe : **5 requêtes natives constantes** (live, actifs + série, connexions, écrans
web, écrans app), sans agrégation Java. Couches :
`AdminActivityController → ActivityService → ActivityReadManager → ActivityReadRepository`,
avec un mapper pur `ActivityMapper` (`@Component`, sans lookup).

### 3.5 `LAST_30_DAYS` (D10)

- `enums/SuiviPeriodPreset.java:10-18` : ajouter `LAST_30_DAYS` (« les 30 derniers jours,
  aujourd'hui compris »).
- Le `switch` de `SuiviService.java:118-126` reçoit `today.minusDays(29)`, ou mieux la
  méthode extraite (§ 3.4).
- Message d'erreur de `parse` mis à jour (`:29`).
- Miroir admin : `SuiviPeriodPreset` dans `admin_sejourfr/src/types/api.ts` et
  `PERIOD_OPTIONS` / `PRESETS` dans `useSuiviParams.ts:10-25`.

### 3.6 Configuration et indicateurs

- `enums/SuiviIndicator` : ajouter `ACTIVE_USERS`, `LOGINS`, `SCREEN_VIEWS_WEB`,
  `SCREEN_VIEWS_APP` (cf. décision nouvelle N4).
- `analytics-config-v2.json` : `measurementStart` du lot 2 pour `ACTIVE_USERS` et
  `LOGINS`, du déploiement web du lot 3 pour `SCREEN_VIEWS_WEB`, et de la sortie store du
  lot 3 pour `SCREEN_VIEWS_APP`. On y ajoute `accountActivityRetentionDays` et le seuil
  d'ingestion relevé.
- `application-dev.yaml` : surcharges dev de ces quatre dates, au même endroit que les
  quatorze existantes (`:49-63`).
- ❓ À vérifier au codage : `AnalyticsConfigLoader` exige-t-il toutes les clés de l'enum ?

### 3.7 Suppression de compte

`AccountDeletionService` ajoute `userLoginEventManager.deleteByUserId` et
`userActivityManager.deleteByUserId`, à côté de `analyticsIdentityManager.deleteByUserId`
(`:146`).

### 3.8 Compatibilité avec l'app mobile déjà publiée

- **Aucun endpoint n'est rendu plus strict.**
  - L'allowlist de chemins ne fait que **s'agrandir**.
  - `SCREEN_VIEWED` est un événement **nouveau** que l'ancienne app n'envoie jamais.
  - Le heartbeat est un endpoint **nouveau**.
  - L'intercepteur ne refuse rien.
  - `TokenResponse` et les DTO d'authentification sont inchangés : la signature de
    `openSession` est interne.
- **L'ancienne app** (`X-Sejourfr-Client: mobile`) produit de l'activité **dès le lot 2**,
  par ses requêtes ordinaires, rangée en `MOBILE` (« App — système inconnu »). Elle n'a ni
  heartbeat ni écrans : sa présence est donc sous-estimée pendant les phases sans requête.
  Limite à afficher, jamais à combler.
- Les clients sans en-tête (console admin, scripts) sont rangés en `UNKNOWN` et
  normalement exclus comme internes.

---

## 4. Web et mobile (lot 3, même passe, parité)

### 4.1 Heartbeat de premier plan

| | Web | Mobile |
|---|---|---|
| Fichier (un seul point) | `web_sejoufr/lib/presence.ts` (logique) + un composant client monté une fois dans `app/layout.tsx` | `mobile_sejourfr/lib/core/presence/presence_heartbeat.dart` (provider Riverpod), démarré à côté de la file analytics |
| Condition | un jeton d'accès présent (`tokenStorage`) **et** `document.visibilityState === "visible"` | état `AuthAuthenticated` **et** `AppLifecycleState.resumed` |
| Démarrage | au montage si visible, puis sur `visibilitychange` → visible | `AppLifecycleListener` `onResume` / `onShow`, sur le patron de `analytics_queue.dart:162-165` |
| Arrêt | `visibilitychange` → hidden, `pagehide` | `onHide` / `onInactive` / `onPause`, et à la déconnexion |
| Cadence | un battement immédiat au retour au premier plan, puis toutes les 60 s | idem |
| Appel | `apiFetch("/api/me/presence", {method:"POST"})` : JWT, refresh automatique, en-têtes de contexte | `ApiClient` Dio : JWT et en-têtes `X-Sejourfr-*` |
| Échec | silencieux, aucun rejeu (un battement perdu n'a pas d'importance) | idem |

Rien n'est écrit sur le terminal : `/confidentialite` §8 n'est pas concernée par le
heartbeat.

### 4.2 `SCREEN_VIEWED`

- **Web** : le composant client du layout racine écoute `usePathname()` et appelle
  `track("SCREEN_VIEWED", {})` à chaque changement.
  - `track` pose déjà `path: currentPath()` (`lib/analytics.ts:589-595`), normalisé par
    `trackedPath`.
  - Seul endroit déclaré : `TRACKED_PATHS` + `DYNAMIC_PATHS` (`lib/analytics.ts:184-223`),
    étendus aux gabarits. Une adresse hors liste part avec `path: null`, ce qui donne
    « écran non déclaré ».
- **Mobile** : un listener unique sur le `GoRouter`
  (`routerDelegate.addListener` dans `app_router.dart`) émet le **gabarit** de la route
  courante, jamais l'URL concrète.
  - Seul endroit déclaré : la classe `AnalyticsPath` (`lib/core/analytics/analytics_events.dart:230-244`),
    étendue d'une table `gabarit go_router → chemin suivi`. Un gabarit absent donne `null`.
  - ❓ L'API go_router 14 qui donne le `fullPath` d'une route **poussée** est à confirmer
    au codage.
  - Les feuilles et dialogues (dont le `PaywallSheet`) ne sont pas des routes et ne sont
    pas comptés : le paywall a déjà ses propres événements.
- **Débit** : un `SCREEN_VIEWED` emprunte la file existante (lot de 4 s sur le web, 2 s
  sur le mobile). Rien à changer côté client, le seuil serveur est relevé (§ 2.3).

### 4.3 Les écrans métier (~30), miroir web ⇄ mobile

Les chemins suivis sont les **gabarits**. Un segment dynamique est noté `:param`, ou bien
ramené à un chemin existant de `AnalyticsPaths`. Une même ligne métier peut avoir un
chemin web et un chemin app différents : l'écran admin les affiche dans deux onglets
(D7).

| # | Écran métier | Web (chemin suivi) | App (gabarit go_router → chemin suivi) |
|---|---|---|---|
| 1 | Vitrine | `/` | — |
| 2 | Landing campagne | `/reussir` | — |
| 3 | Accueil connecté | `/dashboard` | `/` → `/home` (déjà dans `KNOWN`) |
| 4 | Connexion | `/connexion` | `/login` |
| 5 | Inscription | `/inscription` | `/register` |
| 6 | Diagnostic TCF rapide | `/diagnostic` | `/diagnostic` |
| 7 | Résultat diagnostic TCF | `/diagnostic/resultat` | — (rendu dans `/diagnostic`) |
| 8 | Diagnostic civique | `/diagnostic-civique` | `/diagnostic-civique` |
| 9 | Résultat diagnostic civique | `/diagnostic-civique/[sessionId]/resultat` → `/diagnostic-civique/resultat` | `/diagnostic-civique/:sessionId/resultat` → `/diagnostic-civique/resultat` |
| 10 | Plan | `/plan` | `/plan` |
| 11 | Étape du Plan | `/plan/etape/:stepId` | `/plan/etape/:stepId` |
| 12 | Domaine du Plan | `/plan/domaine/:domaine` | `/plan/domaine/:domainKey` |
| 13 | Débloquer le Plan | `/plan/debloquer` | `/plan/debloquer` |
| 14 | Progression du Plan (cycles) | `/plan/progression` | `/plan/progression` |
| 15 | Ma progression TCF | `/progression/tcf` | `/progression/tcf` |
| 16 | Progression d'une épreuve | `/progression/tcf/:epreuve` | `/progression/tcf/:domainKey` |
| 17 | Ma progression civique | `/progression/civique` | `/progression/civique` |
| 18 | Progression d'un thème | `/progression/civique/:theme` | `/progression/civique/:themeId` |
| 19 | Réviser (hub) | `/entrainement` | `/reviser` |
| 20 | Thème civique | `/entrainement/civique/:theme` | `/civique/theme/:themeId` |
| 21 | Épreuve TCF (CO/CE/structure) | `/entrainement/tcf/:code` | `/tcf/co`, `/tcf/ce`, `/tcf/structure` |
| 22 | Lots par niveau | `/entrainement/tcf/:code/:level` | `/tcf/:moduleKey/niveau/:level` |
| 23 | Expression écrite (hub) | `/entrainement/tcf/ee` | `/tcf/ee` |
| 24 | Expression orale (hub) | `/entrainement/tcf/eo` | `/tcf/eo` |
| 25 | Tâche EE / EO | `/entrainement/tcf/ee/tache/:n`, `/entrainement/tcf/eo/tache/:n` | `/tcf/ee/tache/:tacheNumero`, `/tcf/eo/tache/:tacheNumero` |
| 26 | Compétences d'une tâche | `/entrainement/tcf/{ee,eo}/tache/:n/competences` | `/tcf/:moduleKey/tache/:tacheNumero/competences` |
| 27 | Séance QCM (runner) | `/sessions/:attemptId` | `/runner/:attemptId` |
| 28 | Résultat de production EE / EO | `/entrainement/tcf/{ee,eo}/resultats/:submissionId` | `/tcf/expression-ecrite/resultats/:submissionId`, `/tcf/expression-orale/resultats/:submissionId` |
| 29 | Examens blancs (liste) | `/examens-blancs` | `/examens` |
| 30 | Examen blanc TCF complet | `/examens-blancs/tcf/:id` | `/tcf/examen-blanc/:parentId` |
| 31 | Bilan d'examen blanc | `/examens-blancs/tcf/:id/bilan` | `/tcf/examen-blanc/:parentId/bilan` |
| 32 | Tarifs / paiement | `/tarifs`, `/paiement` | — (paywall = feuille, déjà mesurée) |
| 33 | Profil | `/profil` | `/profile` |

La liste finale est à figer au codage, à ±3 écrans près. Un écran ajouté plus tard coûte
une ligne dans `AnalyticsPaths.KNOWN` **et** une dans le front concerné, dans la même
passe (règle existante, `docs/regles/mesure-audience.md:230-231`).

Vérification : `npx tsc --noEmit` (web) et `flutter analyze` (mobile). **Aucun nouveau
test front.**

---

## 5. Admin (lot 5)

### 5.1 Carte « Actifs maintenant » sur `/dashboard`

- Nouveau composant `features/suivi/components/LiveActiveCard.tsx`, placé **au-dessus**
  des KPI de `SuiviPage.tsx`.
- Contenu :
  `Actifs maintenant : N — Web a · Android b · iOS c · App — système inconnu d`.
  La ligne « système inconnu » s'affiche si elle vaut plus de 0 ; « Non déclarée »
  seulement avec `includeInternal`. Lien **« Voir l'activité → »** vers
  `/dashboard/activity`, en conservant `internal`.
- Données : `useActivityLive(includeInternal)`, clé TanStack
  `["adminActivityLive", includeInternal]`, `refetchInterval: 30_000`. C'est le second
  appel de la page, écart assumé (D11).
- La carte ne dépend pas de la période ni des filtres type, plateforme ou source.
  `null` s'affiche « — · mesuré à partir du JJ/MM » (`measurement.ts` réutilisé).
- Les sous-totaux ne somment pas au total (comptes multi-plateformes) : le total servi
  fait foi.

### 5.2 Écran `/dashboard/activity`

- **Nouvelle feature** `admin_sejourfr/src/features/activity/` : `ActivityPage.tsx`,
  `useActivity.ts`, `useActivityParams.ts`, `components/…`, `activity.module.css`.
- **Route** : `src/App.tsx`, à côté de `/dashboard` (`:51`).
- **Navigation** (D9) : `navigation.ts:24-27`, section « Pilotage », ajouter
  `{ to: "/dashboard/activity", label: "Activité", icon: … }`. `navEntryFor` (préfixe le
  plus long) sélectionne la bonne entrée.
- **Période** :
  - `useActivityParams` partage avec Suivi la table des presets et la lecture
    `period/from/to/internal`. C'est la 2ᵉ occurrence : on **extrait** la partie période
    de `useSuiviParams.ts:10-80` dans un module commun aux deux features, au lieu de la
    copier.
  - Options : Aujourd'hui, Hier, 7 jours, 30 jours, Personnalisé. « Mois » reste propre à
    Suivi, au choix au codage.

**Blocs, dans l'ordre** :
1. **Filtres** : période et « Inclure les comptes internes ». L'état vit dans l'URL
   (`?period&from&to&internal`), le défaut n'est pas écrit. Les bornes **servies** sont
   affichées, en heure de Paris.
2. **En ligne maintenant** : le bloc live en grand, rafraîchi toutes les 30 s.
3. **KPI** :
   - *Utilisateurs actifs*, uniques, avec la tendance servie ;
   - *Utilisateurs connectés*, comptes uniques avec au moins une connexion, avec « N
     connexions · dont M inscriptions ».
4. **Répartition par plateforme** :
   - Lignes Web / iOS / Android / App — système inconnu / Non déclarée ; colonnes : actifs
     uniques, comptes connectés, connexions.
   - Pied : « Total — un compte compté une fois · dont N sur plusieurs plateformes ».
   - Sous le tableau : connexions par méthode (E-mail / Google / Apple).
5. **Évolution journalière** des actifs : barres, masquées pour Aujourd'hui et Hier.
   Série servie et continue, mention « non additive ».
6. **Pages et écrans les plus consultés** : onglets **Web** et **Application** (colonnes
   iOS et Android dans le second).
   - Colonnes : écran, vues, visiteurs uniques, comptes connectés uniques (avec la mention
     « partiel »).
   - Top 20, plus les lignes servies « Autres écrans suivis » et « Écrans non déclarés ».
   - Cartes sous 640 px, comme les paliers 1050 / 640 de Suivi.

**Conventions** :
- un seul appel `useActivity` pour l'écran, plus le live ;
- `null` ≠ 0 ;
- aucun pourcentage calculé côté front ;
- `format.ts` de Suivi réutilisé (à remonter en module commun si besoin, même règle de
  duplication) ;
- tokens CSS seulement ;
- libellé « iOS ».
- **Aucun nom ni email affiché** : uniquement des agrégats (§ 7, CNIL).

Miroir des DTO : `admin_sejourfr/src/types/api.ts`. Le web et le mobile ne consomment pas
ces DTO admin.

---

## 6. Tests backend (aucun test front)

| Test | Vérifie |
|---|---|
| `RefreshTokenPurgeIT` | supprime les lignes expirées depuis plus de 7 j, garde les révoquées non expirées et les vivantes ; **une chaîne `replaced_by` coupée en deux lots passe** (FK `SET NULL`) ; boucle par lots ; `rotate` d'un jeton purgé ⇒ refus |
| `SchemaV086IT` / `SchemaV087IT` | FK `ON DELETE SET NULL` ; CHECK de `user_login_event` et `user_activity_day` (valeur hors liste refusée) |
| `UserLoginEventIT` | login local, inscription locale, Google (création, puis reconnexion), Apple : **une** ligne chacun, `kind` / `method` / `platform` justes ; un **refresh n'écrit rien** ; un compte LOCAL qui se connecte par Google ⇒ `GOOGLE` ; échec simulé de l'insert ⇒ le login réussit quand même |
| `UserActivityInterceptorIT` | requête authentifiée ⇒ une ligne (plateforme d'en-tête, `mobile` ⇒ `MOBILE`, absent ⇒ `UNKNOWN`) ; deux requêtes à moins de 60 s ⇒ une écriture ; ≥ 60 s ⇒ `last_seen_at` avancé ; chemins exclus (`/api/public/analytics/**`, `/api/auth/refresh`) ⇒ rien ; requête anonyme ⇒ rien ; changement de jour Paris ⇒ nouvelle ligne ; erreur d'écriture ⇒ requête servie |
| `MePresenceControllerIT` | 204 authentifié, 401 sans jeton |
| `AdminActivityControllerIT` | 403 non-admin ; presets dont `LAST_30_DAYS` ; `from`/`to` invalides ⇒ 400 ; `includeInternal` |
| `ActivityScenariosIT` | en ligne : fenêtre de 2 min exacte, multi-plateforme compté une fois au total ; actifs période ; connexions uniques / totales / méthodes ; écrans : vues, uniques, `null` ⇒ « non déclaré » ; `null` avant `measurementStart` et période à cheval (D117) |
| `ActivityPerformanceIT` | **nombre de requêtes constant** (égalité), sur le patron de `SuiviPerformanceIT` |
| `SuiviScenariosIT` (ajout) | des `SCREEN_VIEWED` **ne changent pas** visiteurs et sources (D8) ; `LAST_30_DAYS` |
| `AnalyticsEventNormalizerTest` (ajout) | `SCREEN_VIEWED` accepté, avec ou sans chemin ; gabarit connu accepté ; URL concrète avec identifiant refusée |
| `AccountActivityRetentionServiceIT` | purge à 365 j des deux tables, par lots |
| `AccountDeletionServiceIT` (ajout) | les lignes des deux tables partent avec le compte |
| `SuiviPeriodPresetTest` (ajout) | `LAST_30_DAYS` = aujourd'hui − 29 → aujourd'hui |

Infra : Postgres embarqué Zonky, migrations réelles, `./mvnw verify`.

---

## 7. Ordre des lots et risques résiduels

| Lot | Contenu | Prérequis | Déploiement |
|---|---|---|---|
| **1** | V086 + `RefreshTokenPurgeJob` + config `sejourfr.security.jwt.*` + tests | aucun | backend seul, **immédiat**. Corrige l'écart de rétention indépendamment du reste |
| **2** | V087 ; `user_login_event` (signature de `openSession`, listener `AFTER_COMMIT`) ; intercepteur + heartbeat ; purges à 365 j ; suppression de compte ; `SCREEN_VIEWED` au registre et à l'allowlist + exclusion Suivi (D8) ; `LAST_30_DAYS` ; `analytics-config-v2.json` + `SuiviIndicator` ; tests | lot 1 | backend. **La collecte commence** (requêtes de toutes les apps, y compris l'ancienne) |
| **3** | Web et mobile, dans la même passe : heartbeat + `SCREEN_VIEWED` + écrans du § 4.3 | lot 2 en production | web immédiat ; mobile via les stores. `SCREEN_VIEWS_APP` est daté à la sortie store |
| **4** | Lecture : `AdminActivityController` / `ActivityService` / `ActivityReadManager` / `ActivityReadRepository` / `ActivityMapper`, DTO, tests IT et perf | lot 2 (peut avancer en parallèle du 3) | backend |
| **5** | Admin : carte live + `/dashboard/activity` + nav + `LAST_30_DAYS` dans Suivi + extraction période / format partagés | lot 4 | admin |
| **Docs** | `docs/regles/mesure-audience.md` (nouvelle section « Activité des utilisateurs »), `admin_sejourfr/CLAUDE.md` (Suivi + Activité), `docs/api-endpoints.md`, index racine si un invariant transverse naît | avec chaque lot | — |

**Risques résiduels** :
1. ⚠️ **Validation CNIL ou juridique à obtenir avant le lot 3.** Des vues d'écran sont
   rattachées à un compte identifié (`analytics_event.user_id`), alors que §8.4 fonde
   l'exemption sur des statistiques « anonymes ». Le point 9 de
   `docs/admin/decisions-suivi.md:1100` est toujours ouvert. Mesures de réduction déjà
   dans ce plan : agrégats seuls à l'écran, aucune liste nominative, aucun croisement avec
   les emails.
2. **`/confidentialite` à ajuster**, à faire valider : séparer « IP / navigateur : session
   + 7 j » de « historique de connexion et d'activité : 12 mois » (§ 2.1).
3. **Ancienne app** : présence sous-estimée (pas de heartbeat), pas d'écrans, et `MOBILE`
   non réparti tant qu'elle reste installée. C'est visible à l'écran (D12), jamais comblé.
4. **Requêtes en arrière-plan sur Android** (polling de résultat à 3 s) : elles peuvent
   prolonger la présence de 2 min au plus. ❓ Durée réelle avant le gel du processus.
5. **Volume de `SCREEN_VIEWED`** inconnu en production : à surveiller après le lot 3
   (taille de `analytics_event`, temps de lecture). On décide de l'agrégat journalier si
   une lecture dépasse 1 s.
6. **Passage en multi-instance** : le cache de limitation devient local à chaque
   instance (au pire une écriture par instance et par minute) et le job de purge tourne en
   double, ce qui est idempotent. C'est acceptable, mais à revoir avec un verrou si cela
   arrive.
7. ❓ L'API go_router 14 pour le gabarit d'une route poussée, et la tolérance de
   `AnalyticsConfigLoader` aux nouvelles clés d'indicateur.

---

## 8. Décisions nouvelles à valider

| # | Question | Recommandation |
|---|---|---|
| N1 | Une ou deux migrations ? | **Deux** : V086 (purge `refresh_tokens`, lot 1, déployable seul) et V087 (tables d'activité, lot 2) |
| N2 | Marge de purge de `refresh_tokens` | **7 j après `expires_at`**, soit 37 j au plus de vie d'une ligne. Une ligne révoquée reste jusqu'à son expiration pour la détection de réutilisation |
| N3 | FK `replaced_by` | Passer en **`ON DELETE SET NULL`** (colonne jamais lue) |
| N4 | Dates de début de mesure des écrans | **Deux indicateurs**, `SCREEN_VIEWS_WEB` et `SCREEN_VIEWS_APP` : le web et l'app ne commencent pas le même jour (sortie store) |
| N5 | Où vit la rétention de 365 j | `analytics-config-v2.json` (`accountActivityRetentionDays`), purge accrochée à `AnalyticsRetentionJob` ; la purge de `refresh_tokens` vit sous `sejourfr.security.jwt` dans `application.yaml` |
| N6 | Libellé des plateformes non déclarées | `MOBILE` ⇒ « App — système inconnu » (D12) ; `UNKNOWN` ⇒ « Non déclarée », visible seulement avec `includeInternal` (console admin, scripts) |
| N7 | Texte de `/confidentialite` | Le scinder comme au § 2.1, **dans la même passe que le lot 2**, après relecture du propriétaire |
