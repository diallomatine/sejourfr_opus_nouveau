# AUDIT — Système d'emails — Phase 1

> Brief audité : `docs/email/brief-emails-sejourfr.md` (§0 « Phase 1 »).
> Date : **2026-09-25**, branche `feature/refonte-l1-socle`.
> Lecture seule : aucun fichier de code, de migration ni de test n'a été créé ou modifié, aucun appel
> LLM. Les mesures viennent de requêtes SQL en lecture sur la base locale `sejourfr_db` (38 comptes,
> données de dev et de testeurs, **pas** une copie de la prod : les ordres de grandeur valent pour la
> structure, pas pour le volume).
> Chemins backend abrégés : `B/` = `backend_sejourfr/src/main/java/com/sejourfr/app/`,
> `R/` = `backend_sejourfr/src/main/resources/`.

---

## 1. Synthèse

1. **Le socle existe déjà, mais en un seul bloc** : un `MailService` unique (`B/service/MailService.java`)
   porte à la fois le rendu, le choix du sujet, le wording et l'appel à `JavaMailSender`. 9 méthodes
   d'envoi, 10 gabarits HTML + 1 page HTML servie par le backend, un moteur maison façon Mustache
   (`MailTemplateRenderer`), **pas de Thymeleaf**. Aucune trace d'envoi en base, aucune préférence,
   aucun anti-doublon hors `user_subscriptions.expiry_reminded_at`.
2. **Tous les envois partent aujourd'hui DEPUIS la transaction métier** (`@Async` appelé dans un service
   `@Transactional`), jamais après commit. Il n'y a **aucun événement Spring** dans le dépôt. Le test
   « rollback de l'inscription ⇒ pas de WELCOME » du brief échouerait sur le code actuel.
3. **Infra** : `@EnableAsync` + `@EnableScheduling` + `@EnableRetry` sont déjà posés
   (`B/SejourFrAppApplication.java:17-19`), **aucun executor dédié** (les pipelines LLM payants et les
   mails partagent l'executor par défaut de Spring Boot), **aucun bean `Clock`**, **pas de ShedLock**.
   **Une seule instance backend en prod** (un service systemd, un jar, Nginx `proxy_pass :8080`,
   rate-limits en mémoire) ⇒ **ShedLock inutile**.
4. **Sources de vérité** : l'accès Premium est `user_subscriptions` (une ligne **par achat** de pass,
   `accessId` = `user_subscriptions.id`), expiré **paresseusement** (le statut reste `ACTIVE` après
   `ends_at`). L'**activité d'entraînement fiable** est l'union de 4 actes du candidat
   (`answers.answered_at`, `production_submissions.submitted_at`, `user_skill_attempts.created_at`,
   `realtime_sessions.connected_at`) ; **`attempts.started_at` et `attempts.finished_at` sont
   inutilisables** (mesuré : 276 attempts ouverts sans aucun acte, et un `finished_at` posé 9 jours
   après le dernier acte).
5. **Trois diagnostics, trois tables, quatre chemins de clôture**, et **aucun Plan persisté** : « plan
   généré » n'est pas un événement mais le fait dérivé `planDisponible`. `DIAGNOSTIC_PLAN_READY` doit
   donc s'accrocher aux transitions `→ COMPLETED`, pas à une génération de plan.
6. **Reset / changement de mot de passe** : `password_reset_tokens` (hachée SHA-256, TTL 1 h, id UUID
   stable ⇒ `resetRequestId` tout trouvé) ; **aucune** ligne ni aucun mail pour un changement de mot de
   passe ⇒ `passwordChangeEventId` à générer dans l'événement.
7. **Findings sécurité** (§7) : adresse email **en clair** dans les logs à chaque envoi ; `purchaseToken`
   Google loggé en clair dans un chemin de replay ; **oracle temporel d'énumération de comptes** sur
   « mot de passe oublié » (SMTP synchrone seulement si le compte existe). **Aucun token ni aucune URL
   à token n'est loggé** par le code mail.
8. **Bugs existants que le chantier doit absorber** : `ExpiryReminderJob` prévient « votre accès se
   termine » un candidat dont l'accès a été **prolongé** (la prolongation crée une nouvelle ligne) ; le
   profil `dev` envoie par **vrai SMTP** (`mail.sejourfr.fr`), pas MailHog ; la suppression de compte
   **anonymise** au lieu de supprimer, donc un `ON DELETE CASCADE` ne se déclenchera **jamais**.
9. **Écarts de convention avec le brief** : config sous `sejourfr.*` (pas `email.*`), JSON versionné
   nommé `<x>-config-v{n}.json` chargé par `config-version`, routes publiques sous `/api/public/**`,
   couches `Controller → Service → Manager → Repository`. Aucun ne bloque ; tous sont listés en §6.

---

## 2. Le code mail existant (brief §0-1)

### 2.1 `JavaMailSender` : un seul point d'appel

`grep` sur `B/` : `JavaMailSender`, `MimeMessage` et `SimpleMailMessage` n'apparaissent **que** dans
`B/service/MailService.java`. La contrainte « jamais de `JavaMailSender` hors de l'implémentation Spring
Mail » est donc **déjà vraie au niveau du fichier** — il suffit de déplacer ce fichier derrière le port.

| élément | où | constat |
|---|---|---|
| dépendance | `backend_sejourfr/pom.xml:83` `spring-boot-starter-mail` | Spring Boot **4.0.6** (`pom.xml:8`), Spring Framework **7.0.7** (vérifié dans `~/.m2`) |
| envoi HTML | `MailService.sendHtmlWithLogo` `:273-302` | `MimeMessageHelper(MULTIPART_MODE_RELATED)`, `setText(html, true)` ⇒ **HTML seul, pas de partie texte**. Logo en **image inline CID** (`static/mail/logo.png`, `:288-293`). Try/catch qui **avale** et loggue en warn. |
| envoi texte | `MailService.sendContactMessage` `:308-333` | `SimpleMailMessage` texte brut vers le support, **synchrone**, et c'est le seul qui **propage** (`IllegalStateException`) : l'utilisateur doit savoir que son message n'est pas parti. |
| From | `@Value("${sejourfr.mail.from:no-reply@sejourfr.fr}")` `:56` | adresse nue, **sans nom affiché** (« SejourFR <…> » absent). dev : `MAIL_FROM` (`R/application-dev.yaml:99-100`) ; prod : `MAIL_FROM:no-reply@sejourfr.fr` (`R/application-prod.yaml:57-58`) |
| Reply-To | `:282-284` | **uniquement** sur la réponse du support (`sendConversationReplyEmail`, reply-to = `sejourfr.contact.to`) et sur le relais contact (reply-to = l'expéditeur). **Aucun reply-to global.** |
| adresse support | `@Value("${sejourfr.contact.to:support@sejourfr.fr}")` `:58` | en dev = `MAIL_FROM` (`application-dev.yaml:101-102`), en prod **non surchargée** ⇒ défaut Java |
| URLs des liens | `sejourfr.app.base-url` / `sejourfr.backend.base-url` `:57`, `:59` | déclarées dans le YAML **de base** exprès (`R/application.yaml:74-84`) après un mail de bienvenue de prod parti vers `localhost:3000` |
| dates | `formatFrenchDate` `:78-82` | « 20 octobre 2026 », fuseau `Europe/Paris` codé en dur, table des mois privée |
| salutation | `displayNameOrFallback` `:69-72` | repli **« à toi »** (tutoiement) alors que tous les gabarits vouvoient — incohérence de ton |

### 2.2 Moteur de templates

**Pas de Thymeleaf, ni Freemarker, ni Mustache** (`pom.xml`). Le moteur est
`B/service/MailTemplateRenderer.java` :

- `{{cle}}` ⇒ valeur **échappée** (`& < > "`, `:57-63` — l'apostrophe n'est pas échappée, sans effet
  aujourd'hui car tous les attributs sont entre guillemets doubles) ; `{{{cle}}}` ⇒ valeur **brute**
  (sert à injecter le corps dans le layout).
- Substitution par `String.replace` sur la map fournie (`:35-43`) : **aucune condition, aucune boucle,
  aucun partial**. Une clé absente reste littéralement dans le HTML.
- Cache mémoire sans invalidation (`:29`, `:45-54`).

Conséquence pour le brief §9 : « bloc désabonnement affiché uniquement si ENGAGEMENT », « CTA
optionnel » et « `priority2`/`priority3` absents » ne peuvent pas s'écrire **dans** le gabarit avec ce
moteur. C'est plutôt une bonne nouvelle pour la règle « aucune logique dans les templates » : la
décision se prend en Java, le gabarit reçoit un fragment déjà rendu (`{{{unsubscribeBlock}}}`) ou une
chaîne vide. Il faudra en revanche **un gabarit texte par mail** (`.txt`) pour le multipart.

### 2.3 Inventaire des gabarits (`R/mail/`) et de leurs variables

Aucun gabarit mail ailleurs (`find R -name '*.html'` : seulement `R/mail/`).

| gabarit | variables | méthode | déclencheur | sync / async | dans une transaction ? |
|---|---|---|---|---|---|
| `layout.html` | `title`, `preheader`, `{{{body}}}`, `year`, `supportEmail` | `renderLayout` `:248-256` | tous les mails clients | — | — |
| `welcome.html` | `greeting`, `ctaUrl` | `sendWelcomeEmail` `:102-113` | `AuthService.register` `B/service/AuthService.java:153` ; `SocialAuthService.findOrCreate` `B/service/SocialAuthService.java:145` (branche création) | `@Async` | **oui** — classes `@Transactional` (`AuthService:40`, `SocialAuthService:51`) ; l'envoi part **avant** le commit, et `register` enchaîne ensuite `login` qui peut encore échouer |
| `password-reset.html` | `ctaUrl` (**contient le token brut**) | `sendPasswordResetEmail` `:115-125` | `AuthService.requestPasswordReset` `:186` | **synchrone** | **oui** (`AuthService:40`) |
| `email-change.html` | `ctaUrl` (**contient le token brut**) | `sendEmailChangeConfirmation` `:132-140` | `UserProfileService.requestEmailChange` `B/service/UserProfileService.java:158` | **synchrone** | **oui** (`:121`) |
| `access-activated.html` | `greeting`, `planName`, `accessIntro`, `endsLabel`, `ctaUrl` | `sendSubscriptionActivatedEmail` `:156-175` | `OneTimeAccessService.grantOneTimeAccess` `B/service/billing/OneTimeAccessService.java:154` (premier achat) ; `SubscriptionNotificationService.sendActivation` `:21-27` (flux abonnement **dormants**, Stripe/Apple/Google) | `@Async` | **oui** (`OneTimeAccessService:40-41`) |
| `access-extended.html` | `greeting`, `planName`, `endsLabel`, `ctaUrl` | `sendAccessExtendedEmail` `:183-198` | `OneTimeAccessService:151` (achat qui **prolonge** un accès en cours) | `@Async` | **oui** |
| `access-expiring.html` | `greeting`, `planName`, `endsLabel`, `ctaUrl` (= `/paiement`, bouton « Prolonger mon accès ») | `sendAccessExpiringSoonEmail` `:204-218` | `ExpiryReminderJob.sendExpiryReminders` `B/service/billing/ExpiryReminderJob.java:58` | **synchrone** (dans le job) | **oui** (`:40`) |
| `subscription-canceled.html` | `greeting`, `planName`, `endsLabel`, `ctaUrl`, `reactivateHint` | `sendSubscriptionCanceledEmail` `:225-241` | `SubscriptionNotificationService.sendCancellation` `:29-35` (flux abonnement **dormants**) | `@Async` | selon l'appelant |
| `contact-received.html` | `greeting`, `subject`, `message`, `ticketId` | `sendContactReceivedEmail` `:362-376` | `ContactService` `B/service/ContactService.java:68` | `@Async` | non |
| `conversation-reply.html` | `greeting`, `subject`, `reply` | `sendConversationReplyEmail` `:347-360` | `ConversationService` `B/service/ConversationService.java:94` | `@Async` | **oui** (`:33`) |
| *(texte, pas de gabarit)* | — | `sendContactMessage` `:308-333` | `ContactService:62` (relais vers le support) | **synchrone**, propage | non |
| `email-change-confirmed.html` | `title`, `accent`, `emoji`, `message` | **pas un mail** : page HTML servie par `GET /api/auth/confirm-email-change` | `UserProfileService.renderEmailChangeConfirmationPage` `:228-235`, `AuthController` `:110-121` | — | — |

Remarques :

- La page `email-change-confirmed.html` est **le précédent exact** des pages de confirmation de
  désabonnement du brief §6 (page HTML autonome rendue par le backend, sans session).
- `access-expiring.html` porte un CTA « Prolonger mon accès » vers `/paiement` : c'est **exactement** le
  contenu que le brief §9 interdit dans un mail ENGAGEMENT (« aucune urgence commerciale »).
- Couleurs en dur dans tous les gabarits (`#1E3A8C`, `#E1372F`…) : **inévitable** en email (CSS inline,
  pas de variables), à ne pas confondre avec la règle « jamais de couleur en dur » des fronts.
- Javadoc orpheline `MailService:335-341` (celle de `sendContactReceivedEmail`, collée au-dessus d'une
  autre méthode) et retour `boolean` de `sendHtmlWithLogo` `:267-272` justifié par « les envois en lot »
  — l'envoi en lot (annonce V038) a été supprimé le 2026-08-19 (`docs/decisions/paiements.md`).

### 2.4 MailHog et configuration de dev

🛑 **Le `CLAUDE.md` racine dit « Mail : MailHog sur localhost:1025 », le code dit autre chose.**
`R/application-dev.yaml:11-31` pointe sur `MAIL_HOST` avec le commentaire « En dev on pointe sur un vrai
SMTP (mail.sejourfr.fr) via .env. Pour repasser sur MailHog : … », et le `backend_sejourfr/.env` local
contient bien `MAIL_HOST=mail.sejourfr.fr`, `MAIL_PORT=587`. La base locale contient des adresses réelles
de testeurs (`@gmail.com`, `@bowlfuel.com`). **Un scheduler d'engagement démarré en dev enverrait de
vrais mails.** → question Q11.

Tests : `backend_sejourfr/src/test/resources/application-test.yaml:26-32` donne un SMTP bidon (port
fermé) ; les envois `@Async` avalent l'erreur. Pas de GreenMail, pas d'Awaitility (`pom.xml`).

### 2.5 Logs d'emails et de tokens

| ligne | ce qui est loggé | verdict |
|---|---|---|
| `MailService:296` `log.info("HTML mail '{}' sent to {}", subject, to)` | **adresse en clair**, au niveau INFO (actif en prod, `application-prod.yaml:37-40`) | **finding S1** |
| `MailService:299` `log.warn("Failed to send HTML mail '{}' to {} : {}", …)` | adresse en clair + `e.getMessage()` (un `SendFailedException` y met souvent les adresses refusées) | **finding S1** |
| `MailService:328`, `:330` | `LogMask.email(senderEmail)` | conforme |
| sujet des mails | aucun sujet ne contient de token ni d'URL | conforme |
| `password-reset` / `email-change` | le token brut n'est **jamais** loggé ; il n'existe qu'en mémoire et dans le corps du mail | conforme |

`B/util/LogMask.java` fournit déjà `email()` (`k***@sejourfr.fr`, exactement le format du brief) et
`token()`. Il suffit de l'appeler.

---

## 3. L'infra existante (brief §0-2)

| sujet | état | preuve |
|---|---|---|
| Événements Spring | **aucun événement métier**. Seuls `@EventListener(ContextRefreshedEvent)` et `@EventListener(ApplicationReadyEvent)` | `B/config/StartupProfileLogger.java:28`, `B/service/ProductionRubricsValidator.java:104`. Aucun `ApplicationEventPublisher`, aucun `@TransactionalEventListener` |
| `@EnableAsync` | oui, global | `B/SejourFrAppApplication.java:18` |
| Executors | **aucun bean d'executor, aucune propriété `spring.task.*`** : tous les `@Async` tournent sur l'executor auto-configuré de Spring Boot (8 threads cœur, file non bornée) | `@Async` : `MailService` (×5), `ProductionPipelineAsyncRunner:76`, `SkillAnalysisAsyncRunner:65`. Aucun `@Async("…")` |
| `@EnableScheduling` | oui | `SejourFrAppApplication.java:19` |
| `@Scheduled` existants | 2 jobs | `ExpiryReminderJob:39` `cron = "0 0 9 * * *"` (**heure serveur, sans zone**) ; `GuestAttemptPurgeJob:82` `cron = "${sejourfr.guest-attempt-purge.cron:0 0/30 * * * *}"` (patron à suivre : cron en config, `Job → Service`, `Properties`, lots) |
| ShedLock | **absent** | ni dépendance, ni `@SchedulerLock` |
| `Clock` injectable | **aucun bean `Clock`**. Deux classes seulement acceptent une horloge, par constructeur avec défaut `Clock.systemUTC()` : `B/util/CoutAppelLlm.java:39-45`, `B/audioquestion/service/GenerationRateLimiter.java:24-31`. **193** appels `Instant.now()` dans `B/` (+ 7 `LocalDate/…now(`) | `grep` |
| Retry | **spring-retry 2.0.12** + `@EnableRetry` (`pom.xml:24`, `:175-177`, `SejourFrAppApplication.java:17`), 9 classes annotées `@Retryable` (clients Anthropic, Azure, R2, Whisper…), backoff **codé en annotation** (`CloudflareR2Client:42-46`). **Spring Framework 7.0.7 est sur le classpath** : `org.springframework.resilience.annotation.@Retryable` + `@EnableResilientMethods` existent (vérifié dans le jar `spring-context-7.0.7`), **non utilisés**, ainsi que `org.springframework.core.retry.RetryTemplate` | — |
| Nombre d'instances en prod | **1** | `backend_sejourfr/deploy_backend.sh` : un seul `SERVICE="sejourfr-backend"` systemd, un seul `app.jar`, `systemctl stop` puis `start` ; `docs/vps-config-iap.md:66` (`EnvironmentFile` du service), `:145` (« Nginx `api.sejourfr.fr` fait déjà `proxy_pass :8080` pour tout ») ; `R/application.yaml:198-205` rate-limit « appliqué en mémoire » — il serait faux à 2 instances. Aucun docker-compose, aucun `Dockerfile` backend |

**Conclusions** :

- **ShedLock : non nécessaire** à une instance. L'index unique partiel protège de toute façon des
  doublons si on passe un jour à deux. Seule vraie conséquence du déploiement `stop → start` : un passage
  quotidien peut sauter s'il tombe pendant un déploiement — c'est exactement ce que les fenêtres bornées
  du brief §7 absorbent.
- **Un executor dédié est obligatoire**, pas optionnel : la relance immédiate du brief (30 s, 2 min,
  5 min **dans le thread async**) bloquerait jusqu'à ~7 min un des 8 threads qui font aussi tourner la
  correction IA des productions et l'analyse des compétences. Une panne SMTP ralentirait la notation.
- **Retry** : les délais du brief (30 s → 2 min → 5 min) ne forment pas une progression géométrique
  (×4 puis ×2,5) ; ni `@Backoff` de spring-retry ni `@Retryable` de SF7 ne prennent une **liste** de
  délais. Recommandation en Q17.
- **`Clock`** : à créer (un `@Bean Clock` unique) et à injecter **dans le seul sous-système email** ; ne
  pas migrer les 193 `Instant.now()` existants dans ce chantier.

---

## 4. Les sources de vérité (brief §0-3)

### 4.1 Création effective du compte

- `users.created_at` `TIMESTAMPTZ NOT NULL` (`B/entity/User.java:73-74`), posé explicitement à
  l'inscription locale (`AuthService.java:143`) et par `@PrePersist` pour le social (`User.java:99-102`).
  Index `idx_users_created_at (created_at DESC) WHERE deleted_at IS NULL` déjà présent.
- **Deux chemins de création** : `AuthService.register` (`:130-160`) et la branche 3 de
  `SocialAuthService.findOrCreate` (`:128-146`). Les branches 1-2 du social sont des **connexions**, pas
  des créations — elles n'envoient rien et ne doivent rien envoyer.
- **Aucune vérification d'email** : pas de colonne `email_verified`, pas de token de vérification. Seuls
  Google/Apple garantissent l'adresse (`SocialAuthService:113-118`). Des adresses jetables existent en
  base (`@bowlfuel.com`). Risque de délivrabilité pour les mails ENGAGEMENT (rebonds), à traiter avec les
  webhooks Brevo (hors périmètre).
- **Suppression = anonymisation, jamais `DELETE`** : `User.anonymize()` `:112-128` pose `deleted_at`,
  `is_active = false`, `email = deleted-{id}@anon.sejourfr`. Appelé par
  `B/service/AccountDeletionService.java:142`, qui purge à la main une liste de tables (`:100-139`).
- **« User actif »** proposé : `deleted_at IS NULL AND is_active AND role = 'USER'`. Mesure locale :
  38 comptes, 37 non supprimés et actifs, 36 `USER`.

### 4.2 Accès Premium

**Entité** : `user_subscriptions` / `B/entity/UserSubscription.java` (`00_schema/V002`), source de vérité
unique des trois canaux (`docs/regles/paiements.md`).

| besoin du brief | réponse du code |
|---|---|
| début | `starts_at` `NOT NULL` (`UserSubscription.java:44-45`) |
| fin | `ends_at` nullable (`:47-48`) ; `NULL` = « sans fin » (cas seed / lifetime), traité comme couvrant (`SubscriptionService.java:184`) |
| unification Stripe / Apple / Google | **oui, déjà faite** : `source ∈ {STRIPE, APPLE, GOOGLE}`, une seule table, `OneTimeAccessService.grantOneTimeAccess` commun aux trois canaux (Stripe `StripeSubscriptionService:197`, Apple `AppleSubscriptionService:137`, Google `GoogleSubscriptionService:184`) |
| « couvrant » | règle **en Java seulement** : `SubscriptionService.isCovering` `:167-185` — statut ∈ {ACTIVE, TRIAL, IN_GRACE, CANCELED}, plan ≠ `FREE`, `ends_at` nul ou futur |
| « expiré » | **paresseux** : aucun job ne passe un pass en `EXPIRED` (`docs/decisions/paiements.md`, lot 5). Mesuré : 3 lignes `ACTIVE` dont `ends_at` est passé |
| module | `plans.module_access ∈ {NONE, CIVIQUE, INTEGRAL}` ; « Premium » = n'importe quel module (`SubscriptionService.isPremium` `:41-43`) |
| achat unique vs abonnement | `plans.purchase_type ∈ {ONE_TIME, SUBSCRIPTION}` ; les 6 plans récurrents sont `is_active = false` mais des lignes existent encore (`auto_renew`, dormant et réversible) |

**Ce que vaut `accessId`** : `user_subscriptions.id`. Une ligne = **un achat** de pass (clé
`(source, original_transaction_id)`, `ux_user_subscriptions_source_original`). Pour les abonnements
dormants, une ligne = toute une chaîne de renouvellements (sa `ends_at` avance) — raison de les exclure
des scénarios de fin d'accès (Q5).

**La prolongation crée une NOUVELLE ligne qui chevauche l'ancienne** — c'est le point structurant.
`OneTimeAccessService:105-137` : `starts_at = now` (l'instant de l'achat, **pas** la fin de l'accès en
cours) et `ends_at = max(fin courante de module ≥, now) + durée`. Exemple réel en base :
`INTEGRAL_PASS_7J` 12/09 → 19/09 puis `INTEGRAL_PASS_1M` 20/09 → 20/10. Conséquences :

- « **aucun autre accès prolongeant au-delà** » = il existe une autre ligne couvrante du même
  utilisateur, de module **≥** (même ordre que `currentEndForAtLeast`, `SubscriptionService:104-117`),
  dont `ends_at` est **postérieure** à celle de l'accès qui se termine ;
- « **accès futur** » au sens strict (`starts_at > now`) **n'existe pas** dans le modèle actuel : une
  prolongation démarre toujours à l'achat. La condition « aucun autre accès actif **ou futur** » de
  `PREMIUM_ENDED` se réduit donc à « aucun autre accès couvrant à `now` » — mais on garde la clause
  `starts_at > now` dans la requête, elle ne coûte rien et survit à un changement de modèle ;
- **`ExpiryReminderJob` a précisément ce bug** : sa requête
  (`B/repository/UserSubscriptionRepository.java:61-71`) sélectionne les lignes qui se terminent dans
  5 jours **sans regarder les autres lignes** du candidat. Un acheteur qui prolonge reçoit « Votre accès se
  termine bientôt » pour l'ancienne ligne alors que son accès continue. Elle ne filtre pas non plus les
  comptes supprimés (le mail partirait vers `deleted-…@anon.sejourfr`).

**Autres points relevés** :

- Anomalie de données locale : une ligne `INTEGRAL_PASS_7J` a `ends_at < starts_at` (manipulation de
  dev). La requête de scénario doit rester correcte sur une telle ligne (elle l'est si elle ne lit que
  `ends_at`).
- **« Paiement confirmé »** : `StripeSubscriptionService.handleOneTimeCheckout` ne vérifie pas
  `session.payment_status == "paid"`, et `BillingService:321` ne restreint pas les moyens de paiement
  (`payment_method_types` absent ⇒ ceux du dashboard). Si un moyen **différé** (SEPA…) est activé côté
  Stripe, l'accès **et** le mail partent avant l'encaissement. Hors périmètre, mais le brief écrit
  « paiement **confirmé** » : à vérifier (Q20).

### 4.3 Activité d'entraînement — mesure

Toutes les colonnes candidates, mesurées sur la base locale :

| source | lignes (comptes) | nature | verdict |
|---|---|---|---|
| `attempts.started_at` | 630 (28) | posé à l'**ouverture** d'une carte / d'une session | ❌ **276 attempts** (hors sous-attempts) n'ont **aucune** réponse ni production : ouvrir n'est pas s'entraîner |
| `attempts.finished_at` | 247 (25) | posé par le **système** : clôture paresseuse à la lecture (`AttemptInteractionService:318-323`), fin d'évaluation asynchrone (`ProductionEvaluationService:321`), clôture d'examen (`FullTcfExamService:181`, `:292`, `:379`) | ❌ mesuré : 3 comptes où il dépasse le dernier acte de plus d'1 h, **un de 9 jours** — il ouvrirait un faux nouvel épisode |
| `answers.answered_at` | 1 963 (11) | réponse QCM (civique, CO, CE, structure, diagnostics) | ✅ `answers.user_id` fiable : 0 écart avec `attempts.user_id` |
| `production_submissions.submitted_at` | 208 (23) | production EE/EO (async **et** temps réel, diagnostics compris) | ✅ index `(user_id, submitted_at DESC)` |
| `user_skill_attempts.created_at` | 42 (5) | petit sujet du module Compétences | ✅ |
| `realtime_sessions.connected_at` | 67 connectées / 83 | simulation orale temps réel | ✅ en ne gardant que `connected_at IS NOT NULL` (9 `FAILED`, 7 `PENDING` jamais connectées) |
| `learning_evidence.occurred_at` | 164 (11) | **dérivé** des actes ci-dessus | redondant : jamais postérieur au dernier acte (vérifié) |
| `user_question_statuses.last_seen_at` | 3 lignes, toutes nulles | code mort en écriture | ❌ |

**Recommandation** : « activité d'entraînement » = **tout acte produit par le candidat lui-même**, donc
`max(answers.answered_at, production_submissions.submitted_at, user_skill_attempts.created_at,
realtime_sessions.connected_at)` par utilisateur. Diagnostics et examens blancs inclus (ce sont des
entraînements au sens du candidat). Une seule autorité : une **vue SQL** (précédent : `V048__vue_cout_ia`,
« une VUE, pas une table »), lue par le scheduler, jamais recopiée en Java. Il manque un index
`answers (user_id, answered_at)` (seul `idx_answer_user (user_id)` existe).

Mesure sur la base locale avec cette définition (aujourd'hui = 2026-09-25) : 36 comptes `USER`,
**12 n'ont jamais eu d'activité** (aucun scénario d'inactivité ne les couvre, Q2), 5 seraient éligibles à
`NO_TRAINING_7_DAYS`, 15 sont hors fenêtre (inactifs depuis plus de 14 jours, jamais relancés — c'est
voulu : pas d'envoi rétroactif), 1 à `NO_PREMIUM_AFTER_7_DAYS`.

### 4.4 Diagnostic terminé + plan généré

**Il n'y a pas de « plan généré »** : le Plan est **dérivé à la lecture** de bout en bout
(`docs/regles/diagnostic.md` §« Le recalcul ») et le fait servi est `planDisponible`. Il n'existe aucun
événement. Trois agrégats et quatre chemins de clôture :

| diagnostic | table / `diagnosticId` | transition `→ COMPLETED` | contexte |
|---|---|---|---|
| **TCF rapide** (`QUICK_TCF`, 1 production EE, ± EO) | `diagnostic_sessions.id` | `DiagnosticSessionCoordinator.onAnalysisCompleted` `B/service/diagnostic/DiagnosticSessionCoordinator.java:93-156` (`:150-151`) | appelé **de manière asynchrone** après l'analyse IA (`ProductionPipelineAsyncRunner:96`, `:116`) ou par le retry (`DiagnosticService:121`) ; méthode `@Transactional` ⇒ un listener `AFTER_COMMIT` fonctionne |
| **TCF complet** (4 épreuves) | `tcf_diagnostic_sessions.id` | `TcfDiagnosticService.cloturer` `B/service/diagnostictcf/TcfDiagnosticService.java:162-181` | quand le candidat demande son résultat ; `@Transactional` |
| **Civique** | `civic_diagnostic_sessions.id` | `CivicDiagnosticService.cloturer` `:348-363` (explicite) **et** `cloturerSiAttemptTermine` `:243-253` (**paresseuse, pendant un GET**) ; session d'invité **adoptée** au moment du compte (`adopter` `:296`) | `@Transactional` partout |

Quand le Plan devient disponible (`docs/regles/diagnostic.md` §« Le fait servi : planDisponible » et
§« le complet CLOS fonde un Plan à lui seul ») : TCF = rapide `COMPLETED` **ou** complet clos ; civique =
diagnostic civique clos. Le complet qui suit un rapide **affine** un Plan qui existait déjà.

**Top-3 priorités servies** (lisibles par un compte gratuit : « LISIBLE mais INEXÉCUTABLE »,
`docs/regles/freemium.md:127-133`, donc les citer dans un mail ne dévoile rien) :

- TCF : `LearningPlanService.get(userId)` (`B/service/LearningPlanService.java:140`) ⇒
  `LearningPlanDto.currentPriority.title` puis `nextPriorities[*].title` ;
- civique : `CivicPlanService.plan(userId)` (`B/service/plancivique/CivicPlanService.java:139`) ⇒
  `CivicPlanDto.prioritesVisibles[*].label` (`B/dto/CivicPlanDto.java:78-86`).

🛑 Un Plan provisoire a **souvent moins de 3 priorités** (« peu de priorités, toutes vraies, est le bon
résultat ») : `priority2` / `priority3` **doivent pouvoir être absentes**, et jamais comblées.

### 4.5 Reset et changement de mot de passe

| flux | stockage | id stable | mail aujourd'hui |
|---|---|---|---|
| **demande de reset** `AuthService.requestPasswordReset` `:172-187` | `password_reset_tokens` (`00_schema/V001`) : `token_hash` SHA-256 **hex**, `expires_at` = +1 h (`RESET_TOKEN_TTL` `:44`), `used_at`, `created_at`. Toutes les demandes précédentes sont invalidées (`:177`). ⚠️ colonnes en `timestamp` **sans** fuseau, contrairement au reste du schéma | ✅ `password_reset_tokens.id` (UUID `@GeneratedValue`, `B/entity/PasswordResetToken.java:21-23`) ⇒ **`resetRequestId`** | `password-reset.html`, synchrone, dans la transaction ; silencieux si le compte n'existe pas (`:174`) |
| **reset appliqué** `AuthService.resetPassword` `:194-213` | `used_at` posé, sessions révoquées | ✅ le même `password_reset_tokens.id` pourrait servir | **aucun** |
| **changement connecté** `UserProfileService.changePassword` `:79-106` | aucune ligne | ❌ aucun | **aucun** |
| changement d'email `requestEmailChange` / `confirmEmailChange` `:121-215` | `email_change_tokens` (SHA-256 **base64url** — autre encodage que le reset : duplication de `sha256`, `AuthService:238-248` vs `UserProfileService:252-260`) | `email_change_tokens.id` | lien au **nouvel** email ; **rien à l'ancienne adresse** |

**Proposition** : `PASSWORD_RESET:{password_reset_tokens.id}` ; `PASSWORD_CHANGED:{UUID tiré dans
l'événement}`, envoyé **par les deux flux** (changement connecté **et** reset appliqué — un reset est un
changement de mot de passe, et c'est justement le cas d'une prise de contrôle). `expiresInMinutes` se
lit sur `RESET_TOKEN_TTL` (60), jamais recopié en dur dans le gabarit.

---

## 5. Où poser le toggle « rappels d'entraînement » (brief §0-4)

Aucun écran de préférences ni aucune notion de notification n'existe sur les fronts. Il n'y a **aucun
interrupteur** dans les composants de compte web (`CompteRow` : lien / bouton / lecture seule), et côté
mobile `ListRow` accepte un widget `right` (`mobile_sejourfr/lib/core/widgets/list_group.dart:41-61`) qui
peut porter un `Switch`.

| front | où est « Mon compte » | fichiers |
|---|---|---|
| web | `/profil`, carte « Mon compte » : Mes informations · Mes favoris · Aide & assistance · Se déconnecter · Supprimer | `web_sejoufr/app/(app)/profil/page.tsx:226-262`, composants `web_sejoufr/app/_components/compte/CompteParts.tsx`, libellés `web_sejoufr/lib/compte.ts` |
| web | `/profil/informations` (hub) + `identite` / `email` / `mot-de-passe` | `web_sejoufr/app/(app)/profil/informations/`, `app/_components/compte/InformationsView.tsx` |
| mobile | onglet Profil, groupe « Mon compte » : Mes informations · Ma progression · Mes favoris · Centre d'aide · À propos | `mobile_sejourfr/lib/screens/profile/profile_screen.dart:141-180` |
| mobile | `/profile/personal-info` (+ `identity` / `email` / `password`) | `personal_info_screen.dart:37-62`, `account_labels.dart` (miroir mot pour mot de `lib/compte.ts`), routes `lib/core/router/app_router.dart:285-288` |

**Recommandation** : une ligne **« Notifications par e-mail »** dans « Mon compte » des deux fronts,
ouvrant une page dédiée `/profil/notifications` (web) ⇄ `/profile/notifications` (mobile), bâtie avec les
briques du compte (`CompteShell` / `CompteCard` ⇄ `ListGroup`), contenant **un** interrupteur « Recevoir
les conseils et rappels d'entraînement » et la phrase fixe « Les emails indispensables liés à votre
compte, votre sécurité ou vos paiements continueront à être envoyés. » Motifs : la phrase d'explication
n'a pas sa place dans une ligne de liste ; la page accueillera la préférence MARKETING le jour où elle
existera ; et le hub « Mes informations » est réservé à l'identité (ses trois lignes sont des champs du
compte). Libellés dans `lib/compte.ts` ⇄ `account_labels.dart`, miroirs. Un interrupteur est une
**nouvelle brique** : à ajouter côté web (`CompteToggleRow`) et côté mobile (switch dans `ListRow.right`)
dans la même passe. Alternative plus légère : l'interrupteur directement dans la carte « Mon compte »
(Q13).

---

## 6. Écarts entre le brief et le code, conflits avec les invariants du dépôt

### 6.1 Conventions du dépôt que le brief ne connaît pas

| # | brief | dépôt | proposition |
|---|---|---|---|
| C1 | config racine `email:` | toute la config applicative est sous `sejourfr.*`, **avec un POJO `@ConfigurationProperties` aux mêmes défauts** (`backend_sejourfr/CLAUDE.md` « Les nombres vivent en configuration ») | `sejourfr.email.*` + `EmailProperties` |
| C2 | `email-automation.v1.json` | `R/<domaine>/<domaine>-config-v{n}.json`, version choisie par `sejourfr.<x>.config-version: ${ENV:1}`, **version inconnue = échec au boot** (`PlanProperties`, `R/application.yaml:1434-1445`) | `R/email/email-automation-config-v1.json` + `sejourfr.email.automation.config-version: ${EMAIL_AUTOMATION_CONFIG_VERSION:1}` |
| C3 | `GET/POST /email/unsubscribe` | routes publiques sous `/api/public/**`, **déjà** `permitAll` (`B/security/SecurityConfig.java:100`) ; Nginx proxie tout `api.sejourfr.fr` | `/api/public/email/unsubscribe` (+ `/one-click`). Pas de nouveau matcher de sécurité ; ajout à `PublicRoutesSecurityIT` + rate-limit |
| C4 | `EmailService` accède à `email_deliveries` | `Controller → Service → Manager → Repository` **strict** | `EmailDeliveryManager`, `UserEmailPreferenceManager` ; les requêtes de scénarios (SQL natif) dans des repositories, appelées par un manager ; `EmailSender` est un **port**, pas un manager |
| C5 | « `Clock` injecté partout » | aucun bean `Clock` ; 193 `Instant.now()` | un `@Bean Clock` créé dans ce chantier, injecté dans le **seul** sous-système email |
| C6 | `ON DELETE CASCADE` sur `users` | les comptes ne sont **jamais** supprimés, ils sont anonymisés (`User.anonymize()`) ⇒ la cascade ne se déclenchera jamais | garder la FK en cascade (utile aux tests et à une purge future), **et** ajouter `emailDeliveryManager.deleteByUserId` + `userEmailPreferenceManager.deleteByUserId` à `AccountDeletionService` (`:100-139`) — sinon `email_deliveries.recipient` garde l'adresse réelle d'un compte supprimé |
| C7 | un DTO de préférences | règle de parité : backend source de vérité, miroirs à la main | `web_sejoufr/lib/types.ts` + `mobile_sejourfr/lib/core/models/`. L'admin n'en a pas besoin |
| C8 | variables `firstName`, `offerName`, `accessEndDate`… | gabarits actuels : `greeting`, `planName`, `endsLabel`, `ctaUrl` ; `greeting` porte déjà un repli (« à toi ») calculé en Java | renommer vers les noms du brief (ce sont les futurs params Brevo) ; dates **déjà formatées** en français par Java (Brevo ne formate pas une date ISO) — donc `formatFrenchDate` sort de `MailService` vers un util partagé ; repli de prénom **vouvoyant** |
| C9 | logo « URL absolue hébergée » | logo en **CID inline** (`MailService:288-293`), incompatible avec un template Brevo | `https://sejourfr.fr/logo_sejourFR.png` (fichier présent : `web_sejoufr/public/logo_sejourFR.png`) via une propriété `sejourfr.email.logo-url` |
| C10 | « multipart HTML + texte » | HTML seul, `MULTIPART_MODE_RELATED` | `MimeMessageHelper(MULTIPART_MODE_MIXED_RELATED)` + `setText(texte, html)` ; un `.txt` par gabarit |

### 6.2 Vocabulaire

- Le code Java parle d'« abonnement » partout (`UserSubscription`, `SubscriptionService`, colonnes) :
  c'est un nom **technique** hérité, à ne pas renommer. Le brief vise « types, templates, textes » : les
  **types** d'email s'appelleront `PREMIUM_ACCESS_*`, les textes client disent déjà « accès »
  (`access-activated.html`, sujet « Votre accès Premium est activé »).
- Les fronts disent « **pass** » (« Mon pass », « pass 7 jours ») et `plans.name` aussi (« Intégral — pass
  7 jours »). `offerName` = `plans.name` portera donc le mot « pass » : ce n'est **pas** « abonnement »,
  le brief ne l'interdit pas, et c'est le vocabulaire client en vigueur. À confirmer (Q4).
- `subscription-canceled.html` dit « abonnement » **à raison** : il ne sert qu'au mode récurrent dormant,
  qui doit rester réversible (`docs/regles/paiements.md`, « ne JAMAIS supprimer le code abonnement »).

### 6.3 Contradictions internes du brief

- **Plafond vs mail événementiel** : « un mail refusé par le plafond n'est pas enregistré, il sera
  réévalué le lendemain » — vrai pour le scheduler, **faux** pour `DIAGNOSTIC_PLAN_READY`, que personne ne
  réévaluera. → Q18.
- **Plafond « par 24 h »** : avec un passage quotidien à heure fixe, une fenêtre glissante de 24 h fait
  sauter un jour entier dès qu'un mail événementiel est parti plus tard dans la journée (mail à 10 h, passage
  suivant à 9 h = 23 h ⇒ refus). → Q18.
- **Épisode d'inactivité** : les deux clés n'ont pas la même base (`{lastActivityDate}` pour
  `NO_TRAINING_7_DAYS`, `{referenceDate} = max(activité, début d'accès)` pour `PREMIUM_INACTIVE_2_DAYS`).
  Ça tient (chaque clé porte son propre épisode et la séquence « J+2 puis J+7 puis rien » est respectée),
  mais un premium **qui ne s'est jamais entraîné** reçoit `PREMIUM_INACTIVE_2_DAYS` et jamais
  `NO_TRAINING_7_DAYS` (qui exige une activité passée). À assumer.
- **Relance différée des mails REQUIRED** : « variables reconstruites depuis la source » — pour
  `PASSWORD_CHANGED`, `changedAt` n'existe dans aucune source (aucune ligne). Il faut soit le porter
  dans la clé/l'événement, soit l'écrire au moment de l'INSERT PENDING (une date n'est pas une donnée
  sensible). Proposition : colonne `occurred_at` nullable sur `email_deliveries`.
- **`error_message` sans donnée sensible** : les exceptions SMTP (`SendFailedException`) contiennent les
  adresses refusées ⇒ le message doit être assaini (adresses masquées par `LogMask.email`) avant
  troncature.

### 6.4 Mails existants hors brief

Le brief interdit `JavaMailSender` hors de l'implémentation Spring Mail, donc **tous** les mails actuels
doivent passer par le port — y compris ceux qu'il ne liste pas : confirmation de changement d'email,
accusé de réception du contact, réponse du support, relais du contact vers le support, prolongation
d'accès, résiliation (dormante), rappel d'expiration. Traitement proposé en Q4, Q5, Q6, Q9.

### 6.5 Risques

1. **Executor partagé** (§3) : sans pool dédié, une panne SMTP ralentit la notation IA payante.
2. **Envoi réel depuis le dev** (§2.4) dès que le scheduler existe.
3. **Double mail de fin d'accès** tant que `ExpiryReminderJob` coexiste avec `PREMIUM_ENDING_*`.
4. **Règle « couvrant » dupliquée** : `isCovering` vit en Java ; les requêtes SQL du scheduler devront
   la réécrire. C'est une 2ᵉ copie d'une règle (invariant « une règle = une autorité »). Mitigation :
   un test IT qui confronte, sur un jeu de lignes couvrant tous les statuts, la requête SQL et
   `SubscriptionService.currentAccess`.
5. **Page de confidentialité** (`web_sejoufr/app/confidentialite/page.tsx:260-268`, `:287-320`) : elle
   ne liste que les emails transactionnels et les newsletters. Les emails d'accompagnement (finalité,
   base légale, désinscription) et la durée de conservation d'`email_deliveries` devront y figurer.
6. **Newsletter du pied de page** : `web_sejoufr/app/_components/Footer.tsx:380-392` appelle
   `POST /api/newsletter/subscribe` (`web_sejoufr/lib/api.ts:746-752`, « à implémenter côté Java ») qui
   **n'existe pas** ; la page de confidentialité annonce pourtant une finalité « newsletters ». La
   préférence MARKETING du brief (compte connecté) ne couvre pas un visiteur sans compte.
7. **Liens des mails = web** : aucune universal link / app link dans `mobile_sejourfr` ; un candidat
   « mobile d'abord » atterrit sur le web, souvent déconnecté. À assumer ou à traiter plus tard (Q14).

---

## 7. Findings sécurité

| id | gravité | constat | où | correction proposée |
|---|---|---|---|---|
| **S1** | moyenne (RGPD) | adresse email **en clair** dans les logs à chaque envoi (INFO, actif en prod) et à chaque échec, contrairement à `LogMask` et à son commentaire « les logs ne doivent pas contenir d'email en clair » | `B/service/MailService.java:296`, `:299` | `LogMask.email(to)` ; disparaît naturellement avec le nouveau `SpringMailEmailSender` |
| **S2** | faible à moyenne | `originalTransactionId` loggé **en clair** sur un replay ; pour Google c'est le **`purchaseToken`**, que tout le reste du code masque par `LogMask.token` | `B/service/billing/OneTimeAccessService.java:96-97` | `LogMask.token(originalTransactionId)` — hors chantier email, correctif d'une ligne |
| **S3** | moyenne | **oracle temporel d'énumération de comptes** : « mot de passe oublié » répond toujours 200, mais n'appelle le SMTP (synchrone, jusqu'à 10 s de timeout, `application-prod.yaml:30-32`) **que si le compte existe** | `AuthService.java:172-187`, `MailService.java:115` (pas d'`@Async`) | corrigé par construction avec l'envoi `AFTER_COMMIT` + `@Async` du brief |
| **S4** | fonctionnelle | tous les mails partent **dans** la transaction : un rollback après l'appel n'empêche pas le mail (bienvenue, activation d'accès) | cf. §2.3 | le découplage `AFTER_COMMIT` du brief |
| **S5** | faible | `GET /api/auth/confirm-email-change?token=` **modifie l'état** : un scanner de liens (Outlook SafeLinks, antivirus) peut consommer le token. Le brief protège le désabonnement contre ce même risque (GET = confirmation seulement) | `B/controller/AuthController.java:110-121` | même patron que le désabonnement (GET affiche, POST applique) — hors périmètre, à noter |
| **S6** | faible, non vérifiable | les tokens (reset, changement d'email, et demain désabonnement) voyagent en **query string** : le journal d'accès Nginx les enregistre par défaut. La config Nginx n'est pas dans le dépôt | VPS | `log_format` sans `$args` sur `api.sejourfr.fr` et `sejourfr.fr`, ou accepter (tokens hachés en base, TTL 1 h) |
| **S7** | moyenne | aucun mail sur changement de mot de passe **ni** à l'**ancienne** adresse lors d'un changement d'email : une prise de contrôle est invisible pour la victime | `UserProfileService:79-106`, `:168-215` | `PASSWORD_CHANGED` (brief) ; `EMAIL_CHANGED` vers l'ancienne adresse (Q10) |
| — | info | **aucun token, mot de passe ni URL à token n'est loggé** par le code mail ; les tokens sont stockés hachés | — | à préserver : l'événement de reset transportera le token brut en mémoire vers le listener, il ne doit **jamais** être un champ d'un `record` loggé tel quel (`toString()` d'un record imprime tout) |

---

## 8. Questions ouvertes pour le propriétaire

Chaque question porte la recommandation de l'audit.

1. **Définition de l'activité d'entraînement.** Recommandation : les 4 actes du candidat (réponse QCM,
   production EE/EO, petit sujet de compétence, simulation orale connectée), **diagnostics et examens
   blancs compris**, exposés par **une vue SQL** unique ; `attempts.started_at/finished_at` exclus
   (mesures §4.3).
2. **Les inscrits qui ne se sont jamais entraînés** (12 sur 36 en local) ne reçoivent qu'un seul mail
   possible, `NO_PREMIUM_AFTER_7_DAYS`. Ajouter un scénario « jamais commencé » ? Recommandation : non
   dans ce chantier ; le noter pour une v2 de `email-automation-config`.
3. **Un pass Civique est-il un « accès Premium » ?** Recommandation : oui (même règle que
   `isPremium`). « Autre accès prolongeant au-delà » = autre ligne couvrante de **module ≥**, `ends_at`
   postérieure. Conséquence : un Intégral qui se termine alors qu'un Civique court encore **déclenche**
   `PREMIUM_ENDING_*` (le candidat perd le TCF) — à valider.
4. **Prolongation d'un accès.** Aujourd'hui, un achat qui prolonge envoie `access-extended.html` (« durées
   cumulées »), pas le mail d'activation. Recommandation : un type REQUIRED distinct
   `PREMIUM_ACCESS_EXTENDED:{accessId}` ; `PREMIUM_ACCESS_STARTED` réservé au premier achat.
   `offerName` = `plans.name`, qui contient « pass » : OK ?
5. **Abonnements récurrents dormants** (`auto_renew = true`). Recommandation : exclus de
   `PREMIUM_ENDING_*` / `PREMIUM_ENDED` (ils se renouvellent) ; `subscription-canceled` devient un type
   REQUIRED `PREMIUM_SUBSCRIPTION_CANCELED` (dormant, conservé pour la réversibilité).
6. **`ExpiryReminderJob` et `access-expiring.html`.** Recommandation : **supprimés** dans la foulée
   (refonte = suppression), remplacés par `PREMIUM_ENDING_7_DAYS` / `_2_DAYS` ; la colonne
   `user_subscriptions.expiry_reminded_at` cesse d'être écrite mais **reste** (règle « additif par
   défaut »). Le CTA « Prolonger mon accès » vers `/paiement` disparaît (contenu commercial interdit en
   ENGAGEMENT). Question liée : le mail `PREMIUM_ENDING_*` peut-il au moins pointer vers « Mon pass » ?
7. **Quels diagnostics déclenchent `DIAGNOSTIC_PLAN_READY` ?** Recommandation : **celui qui ouvre le Plan
   d'un module**, une fois par module — TCF rapide terminé, **ou** TCF complet clos sans rapide
   préalable, **ou** diagnostic civique clos (y compris à l'adoption d'une session d'invité). Pas de
   mail quand le complet vient affiner un Plan existant. `diagnosticId` = l'id de la session dans sa
   table ; `diagnosticType` ∈ {`TCF`, `CIVIQUE`}.
8. **`PASSWORD_CHANGED` dans les deux flux** (changement connecté **et** reset appliqué) ?
   Recommandation : oui ; clé `PASSWORD_CHANGED:{UUID tiré dans l'événement}` ; `changedAt` écrit sur la
   ligne de livraison (§6.3).
9. **Mails existants hors brief** (confirmation de changement d'email, accusé de contact, réponse du
   support, relais vers le support). Recommandation : types REQUIRED `EMAIL_CHANGE_CONFIRMATION`
   (pas de relance différée : token, même règle que `PASSWORD_RESET`), `CONTACT_RECEIVED`,
   `SUPPORT_REPLY` ; le relais vers le support passe par `EmailSender` mais **reste synchrone** et
   **propage** son échec (l'utilisateur doit le savoir), sans ligne `email_deliveries` (le destinataire
   n'est pas un utilisateur).
10. **Prévenir l'ancienne adresse lors d'un changement d'email** (`EMAIL_CHANGED`, REQUIRED) ? Hors
    brief ; recommandé pour la sécurité (S7), à faire dans la phase 3.
11. **Envois depuis le dev.** Le dev envoie aujourd'hui par le vrai SMTP. Recommandation : en profil
    `dev`, scheduler d'emails **désactivé par défaut** (`sejourfr.email.automation.enabled`) et une
    **liste blanche de destinataires** (`sejourfr.email.dev-recipient-allowlist`), ou retour à MailHog.
    Et corriger la ligne MailHog du `CLAUDE.md` racine, qui ne décrit plus la réalité.
12. **Chemin des endpoints de désabonnement** : `/api/public/email/unsubscribe` (recommandé, C3) plutôt
    que `/email/unsubscribe` ? Pages rendues par le backend (patron `email-change-confirmed.html`).
13. **Emplacement du toggle** : page dédiée « Notifications par e-mail » (recommandé, §5) ou
    interrupteur directement dans la carte « Mon compte » ?
14. **Destination des liens** : web uniquement (aucun lien universel mobile). Recommandation : accepter
    pour ce chantier ; `planUrl` = `{appBaseUrl}/plan?module=…`, `resumeUrl` / `dashboardUrl` = pages web.
15. **Newsletter du pied de page** (endpoint inexistant) : hors périmètre ? Recommandation : oui, mais
    retirer ou désactiver le formulaire tant qu'il appelle une route absente — décision séparée.
16. **Rétention d'`email_deliveries`.** Recommandation : **12 mois** glissants (aligné sur « Logs de
    connexion : 12 mois » de la politique de confidentialité), purge par un job, **et** suppression des
    lignes à la suppression du compte (C6). Besoin technique minimal : ~30 jours (fenêtres ≤ 14 jours +
    24 h de relance différée), donc la durée est un choix de preuve et d'analyse, pas de fonctionnement.
    La politique de confidentialité est à mettre à jour dans la même passe.
17. **Mécanisme de relance immédiate.** Recommandation : `org.springframework.core.retry.RetryTemplate`
    de Spring Framework 7 (présent, non déprécié, contrairement à spring-retry qui reste pour les
    clients existants) avec un `BackOff` qui lit la **liste** de délais en config, exécuté sur un
    **executor dédié borné** (`emailTaskExecutor`). Alternative acceptable : une boucle explicite sur la
    liste de délais, plus lisible et testable avec un `Sleeper` injecté.
18. **Plafond ENGAGEMENT.** Recommandation : **jour calendaire `Europe/Paris`** plutôt que 24 h
    glissantes ; les mails ENGAGEMENT **événementiels** (`DIAGNOSTIC_PLAN_READY`) ne sont **pas bloqués**
    par le plafond mais **le consomment** (le scheduler du jour s'efface devant eux).
19. **Début d'accès pour `PREMIUM_INACTIVE_2_DAYS`.** Une prolongation a `starts_at` = date d'achat, donc
    un achat ouvre un nouvel épisode. Recommandation : `referenceDate = max(dernière activité,
    starts_at de la ligne couvrante la plus récente)` — acheter, c'est un signal d'intention.
20. **« Paiement confirmé » côté Stripe** : vérifier que seuls des moyens **immédiats** sont activés sur
    le dashboard (sinon ajouter la garde `payment_status == "paid"`). Hors chantier email, mais c'est ce
    qui déclenche `PREMIUM_ACCESS_STARTED`.

**Version Flyway** : **`V073`** (`00_schema/V073__schema_emails.sql`). Maximum réellement appliqué en
local et présent sur la branche : `V072__journey_step_series`. ⚠️ `docs/migrations-flyway.md` annonce
encore « Max actuel : V067 » — périmé, à corriger dans la même passe. La vue d'activité (Q1) peut vivre
dans le même fichier ou en `V074`.

---

## 9. Plan proposé pour la phase 2 (non implémenté)

Périmètre du brief phase 2 : socle + démo sur 1 mail REQUIRED (`WELCOME`) et 1 ENGAGEMENT
(`DIAGNOSTIC_PLAN_READY`, qui exerce la chaîne événement → préférence → plafond → désabonnement).

**Migration**
- `R/db/migration/00_schema/V073__schema_emails.sql` : `user_email_preferences`, `email_deliveries`
  (+ `occurred_at` nullable, §6.3), index unique **partiel** sur `deduplication_key`, index
  `(user_id, category, created_at)`, `CHECK` sur les enums, `COMMENT`s ; vue
  `v_derniere_activite_entrainement` + index `answers (user_id, answered_at)`.
- `docs/migrations-flyway.md` : max `V073`.

**Backend** (`B/`, tout sous un paquet `service/email/` comme `service/billing/`)
- `enums/` : `EmailType`, `EmailCategory`, `EmailDeliveryStatus`, `EmailProvider`.
- `entity/` : `EmailDelivery`, `UserEmailPreference` (`@Getter/@Setter`, jamais `@Data`).
- `repository/` + `manager/` : `EmailDeliveryManager` (INSERT PENDING sans SELECT préalable, passage
  SENT/FAILED, `deleteByUserId`, marquage des PENDING « stale »), `UserEmailPreferenceManager`.
- `config/` : `EmailProperties` (`sejourfr.email.*`, mêmes défauts que le YAML), `EmailAsyncConfig`
  (`emailTaskExecutor` borné), `ClockConfig` (`@Bean Clock`).
- `service/email/` : `EmailMessage` (record : destinataire, type, variables plates, `unsubscribeUrl`),
  port `EmailSender`, `SpringMailEmailSender` (`@ConditionalOnProperty sejourfr.email.provider=spring-mail`,
  **seul** détenteur de `JavaMailSender` ; multipart texte + HTML ; `List-Unsubscribe` en ENGAGEMENT),
  `EmailTemplateResolver` (sujet + gabarit local par type, depuis la config), `EmailService` (règles du
  brief §5), `UnsubscribeTokenService` (HMAC, trousseau de clés, comparaison à temps constant),
  `EmailDates` (formatage français extrait de `MailService`).
- Événements : `AccountCreatedEvent` publié par `AuthService.register` et `SocialAuthService`
  (branche création) ; `DiagnosticPlanReadyEvent` publié aux transitions retenues en Q7 ; listeners
  `@TransactionalEventListener(AFTER_COMMIT)` + `@Async("emailTaskExecutor")`.
- Gabarits : `R/mail/layout.html` refait (logo par URL, CTA et bloc désabonnement en fragments injectés),
  `welcome.html` + `welcome.txt`, `diagnostic-plan-ready.html` + `.txt`, fragment de désabonnement.
- `R/application.yaml` : bloc `sejourfr.email` (provider, from avec nom affiché, reply-to, logo-url,
  templates par type, clés de désabonnement par variables d'environnement) ; `application-dev.yaml` :
  garde-fous de Q11.
- `MailService` : `sendWelcomeEmail` retiré au profit du nouveau chemin ; le reste migre en phase 3
  (puis `MailService` et `MailTemplateRenderer` fusionnent ou disparaissent — pas de cohabitation au-delà
  de la phase 3).

**Tests (même passe)** : `EmailServiceTest` (catégories, préférences, plafond, anti-doublon, `EmailSender`
mocké), `EmailDeliveryManagerIT` (deux INSERT concurrents ⇒ un seul PENDING/SENT ; FAILED ne bloque pas),
`WelcomeEmailIT` (rollback ⇒ aucun envoi ; échec SMTP ⇒ inscription réussie), `UnsubscribeTokenServiceTest`,
test de la vue d'activité, et mise à jour d'`AuthServiceTest` / `MailServiceTest` rendus rouges.

**Phases suivantes** (rappel) : phase 3 = autres types événementiels, endpoints de désabonnement et
`/api/me/email-preferences`, pages front « Notifications par e-mail » (web + mobile, miroirs), mise à
jour de la politique de confidentialité ; phase 4 = `EmailAutomationJob → EmailAutomationService`,
`email-automation-config-v1.json`, suppression d'`ExpiryReminderJob`, purge de rétention, tests
temporels à `Clock` fixe. Documentation : un `docs/regles/emails.md` indexé dans le `CLAUDE.md` racine
à la livraison (nouvel invariant transverse : « un mail ne part jamais de la transaction métier »).
