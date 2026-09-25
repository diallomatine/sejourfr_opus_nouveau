# Système d'emails — décisions prises en autonomie

Chantier : phases 2 → 4 du brief `docs/email/brief-emails-sejourfr.md`, sous l'autorité des
arbitrages `docs/email/REPONSES_AUDIT_emails.md`. Ce fichier ne consigne que les points
**non couverts** par le brief, l'audit ou les réponses. Les décisions **structurantes** sont en
tête ; les **mineures** suivent ; puis les sujets séparés (interdits sans accord du propriétaire)
et les blocages.

Règle métier qui en résulte : `docs/regles/emails.md`.

---

# Décisions structurantes

## D-1 — `SKIPPED` occupe la clé anti-doublon
- Phase : 2
- Importance : structurante
- Contexte : le brief pose l'index unique partiel `WHERE status IN ('PENDING','SENT')`. Or le
  complément C exige qu'une adoption de diagnostic invité **consomme** la clé
  `DIAGNOSTIC_PLAN_READY:{userId}:{module}` par une ligne `SKIPPED`, sans « SELECT puis INSERT ».
- Options : A) garder le prédicat du brief et ajouter un SELECT préalable pour les SKIPPED ;
  B) élargir l'index à `IN ('PENDING','SENT','SKIPPED')` ; C) une table de clés consommées à part.
- Choix : B — c'est la seule option atomique (`INSERT … ON CONFLICT DO NOTHING`) qui tient le
  complément C sans lecture préalable. Conséquences assumées : un mail refusé par la préférence
  ou par l'allowlist de dev est définitivement consommé pour sa clé (les clés événementielles sont
  à usage unique ; les clés de scénario portent leur épisode ou leur accès, donc un nouvel épisode
  a une nouvelle clé). `FAILED` continue de libérer la clé : la relance reste possible, comme dans
  le brief.
- Réversibilité : facile — une migration qui recrée l'index avec l'ancien prédicat, et un SELECT
  de garde pour `DIAGNOSTIC_PLAN_READY`.
- Fichiers : `backend_sejourfr/src/main/resources/db/migration/00_schema/V073__schema_emails.sql`,
  `backend_sejourfr/src/main/java/com/sejourfr/app/repository/EmailDeliveryRepository.java`

## D-2 — Relance différée des mails événementiels : une passe de maintenance HORAIRE
- Phase : 2 (mécanique posée), 4 (job)
- Importance : structurante
- Contexte : le brief veut une relance différée « au passage suivant du scheduler » pendant 24 h
  pour `WELCOME`, `PREMIUM_ACCESS_STARTED`, `PASSWORD_CHANGED`. Avec un seul passage quotidien, un
  échec à 10 h n'aurait qu'une chance (le lendemain 9 h), et un échec à 8 h aucune (25 h).
- Options : A) relancer au seul passage quotidien ; B) une passe de maintenance horaire (PENDING
  bloqués + relance différée des types `EVENT_WINDOW`), le passage quotidien gardant les scénarios.
- Choix : B — c'est ce qui donne un sens réel à « relance pendant 24 h au maximum ». Les
  scénarios ENGAGEMENT, eux, sont relancés par leur propre réévaluation quotidienne (une clé
  `FAILED` ne bloque pas).
- Réversibilité : facile — `sejourfr.email.maintenance.retry-cron`.
- Fichiers : `EmailMaintenanceJob`, `EmailDeferredRetryService`, `EmailType.DeferredRetry`

## D-3 — Soumission explicite à `emailTaskExecutor`, pas `@Async`
- Phase : 2
- Importance : structurante
- Contexte : le brief demande `@TransactionalEventListener(AFTER_COMMIT)` + `@Async` sur un executor
  dédié ; le complément E exige qu'un rejet de l'executor devienne une ligne `FAILED`. Un rejet d'un
  proxy `@Async` remonte dans la synchronisation de fin de transaction, où il est seulement journalisé.
- Options : A) `@Async("emailTaskExecutor")` sur le listener ; B) listener `AFTER_COMMIT` synchrone qui
  soumet explicitement la composition et l'envoi à l'executor (`EmailDispatcher`), en capturant
  `TaskRejectedException`.
- Choix : B — même effet (rien ne s'exécute dans la transaction, rien de lent dans le thread de
  requête), et le rejet est traçable. La **composition** (lecture du compte, du Plan, de l'accès)
  tourne elle aussi sur l'executor. Pour le scheduler : règles + `INSERT PENDING` dans le thread du
  scheduler (le plafond et la priorité voient la ligne aussitôt), envoi et relance immédiate sur
  l'executor.
- Réversibilité : facile — le dispatcher est un point unique.
- Fichiers : `EmailDispatcher`, `EmailService.sendAsync`, `event/EmailEventListener`

## D-4 — « Premier Plan du module » : aucun AUTRE diagnostic clos du module
- Phase : 2
- Importance : structurante
- Contexte : arbitrage n°7 — le mail part quand le diagnostic rend le Plan disponible pour la
  première fois. Aucun Plan n'est persisté ; seule la clé du complément B protégerait, et elle ne
  protège pas un candidat dont le rapide a été clos **avant** le déploiement puis dont le complet se
  clôt après (le mail partirait pour un Plan qui ne fait que s'affiner).
- Options : A) se fier à la seule clé ; B) à la publication, compter les AUTRES diagnostics clos du
  module (rapide + complet pour le TCF, la règle de `PlanFoundationResolver` ; civique pour le
  civique) et ne publier que s'il n'y en a aucun ; la clé reste le second verrou.
- Choix : B — deux lectures indexées dans la transaction de clôture, et la règle d'ouverture du
  Plan reste celle de `PlanFoundationResolver` (rapide clos OU complet clos).
- Réversibilité : facile — `DiagnosticPlanReadyNotifier`.
- Fichiers : `DiagnosticPlanReadyNotifier`, `*DiagnosticSessionRepository.countCompletedExcluding`

## D-5 — Colonnes ajoutées à `email_deliveries`
- Phase : 2
- Importance : structurante
- Contexte : le brief fixe les colonnes ; l'audit a ajouté `occurred_at` (validé, arbitrage n°8).
  Trois besoins restaient : reconstruire les variables d'une relance différée sans parser la clé,
  tracer la raison d'un `SKIPPED` (complément G), compter les tentatives SMTP d'une ligne. Et les
  accusés de contact / réponses du support partent vers des visiteurs sans compte.
- Options : A) parser la clé et stocker la raison dans `error_message` ; B) colonnes dédiées.
- Choix : B — `reference_id UUID NULL` (id de la source : accès, jeton de reset, message support —
  jamais un secret), `skip_reason` (CHECK `PREFERENCE | ALLOWLIST | KEY_CONSUMED`), `attempt_count`,
  et `user_id` **nullable**.
- Réversibilité : coûteuse — colonnes de schéma (additives, jamais supprimées).
- Fichiers : `V073__schema_emails.sql`, `entity/EmailDelivery.java`

## D-6 — La clé de désabonnement est obligatoire au démarrage
- Phase : 2
- Importance : structurante
- Contexte : le trousseau HMAC vient de l'environnement. Sans clé courante, chaque lien de
  désabonnement serait signé avec rien.
- Options : A) défaut en dur dans le YAML de base ; B) échec au démarrage si la clé courante manque
  (patron de `JWT_SECRET`) ; C) dériver la clé du secret JWT.
- Choix : B — clé de dev non secrète dans `application-dev.yaml`, clés fixes dans
  `application-test.yaml`, **`EMAIL_UNSUBSCRIBE_KEY_V1` obligatoire en production**. 🛑 À poser
  sur le VPS avant le prochain déploiement, sinon le backend ne démarre pas.
- Réversibilité : facile — un défaut dans le YAML.
- Fichiers : `UnsubscribeTokenService`, `application*.yaml`

## D-7 — Le diagnostic TCF « invité » n'est pas une adoption
- Phase : 2
- Importance : structurante
- Contexte : le complément C (« pas de mail à l'adoption, clé consommée ») vise l'**adoption**
  serveur d'une session invitée. Côté TCF, le texte invité vit sur l'appareil et n'est soumis
  qu'**après** la création du compte : il n'existe aucune adoption serveur, et l'analyse est
  asynchrone (le candidat n'est pas forcément devant son Plan quand elle aboutit).
- Options : A) traiter la première soumission TCF post-inscription comme une adoption (pas de
  mail) ; B) la traiter comme un diagnostic normal (mail à la clôture).
- Choix : B — c'est la seule qui se lit sur le code, et le mail prévient justement que l'analyse
  est prête. Seule l'adoption civique (`CivicDiagnosticService.adopter`) consomme la clé.
- Réversibilité : facile — un appel à `civiqueAdopte`-like dans le coordinateur.
- Fichiers : `DiagnosticPlanReadyNotifier`, `CivicDiagnosticService.adopter`

---

# Décisions mineures

## D-8 — Nom du fichier de configuration versionnée
- Phase : 2
- Importance : mineure
- Contexte : la consigne cite `email-automation.v1.json` ; la convention du dépôt (audit C2) est
  `<domaine>/<domaine>-config-v{n}.json` + `sejourfr.<x>.config-version`.
- Options : A) `email-automation.v1.json` ; B) `email/email-automation-config-v1.json`.
- Choix : B — convention du dépôt, chargeur validant (`EmailAutomationConfigLoader`), version
  inconnue = échec au boot.
- Réversibilité : facile — renommer le fichier.
- Fichiers : `backend_sejourfr/src/main/resources/email/email-automation-config-v1.json`

## D-9 — Les gabarits se déclarent en YAML, sans défaut Java
- Phase : 2
- Importance : mineure
- Contexte : règle du dépôt « POJO aux mêmes défauts que le YAML » ; la table des gabarits (17
  types × sujet/preheader/fichier/id Brevo) dupliquée en Java serait une seconde copie.
- Options : A) dupliquer en Java ; B) YAML seul + vérification au démarrage.
- Choix : B — `SpringMailEmailSender` échoue au démarrage si un gabarit configuré n'a pas ses
  fichiers `.html`/`.txt`, et `EmailTemplatesConfiguredTest` fige que chaque `EmailType` est décrit.
- Réversibilité : facile.
- Fichiers : `application.yaml` (`sejourfr.email.templates`), `EmailProperties`

## D-10 — Pas de CHECK sur `email_type`
- Phase : 2
- Importance : mineure
- Contexte : l'audit proposait des CHECK sur les enums.
- Options : A) CHECK sur tous les enums ; B) CHECK sur les axes fermés (catégorie, statut,
  provider, raison), pas sur le type.
- Choix : B — la liste des types grandit à chaque mail ; l'enum Java est l'autorité.
- Réversibilité : facile — une migration additive.
- Fichiers : `V073__schema_emails.sql`

## D-11 — `EmailMessage` porte aussi l'URL one-click
- Phase : 2
- Importance : mineure
- Contexte : le brief décrit `EmailMessage(recipient, type, variables, unsubscribeUrl)`. L'en-tête
  `List-Unsubscribe` (RFC 8058) doit viser l'URL qui accepte un POST sans page, distincte de la page
  de confirmation citée en pied de mail.
- Options : A) une seule URL ; B) deux champs.
- Choix : B — `oneClickUnsubscribeUrl` à côté d'`unsubscribeUrl`, tous deux nuls pour un REQUIRED.
  Un `GET` sur l'URL one-click rend la page de confirmation (un client qui suivrait le lien ne
  désabonne pas).
- Réversibilité : facile.
- Fichiers : `EmailMessage`, `PublicEmailController`

## D-12 — Réponses des endpoints de désabonnement
- Phase : 2
- Importance : mineure
- Contexte : le brief exige une page neutre sur jeton invalide, sans fixer de statut.
- Options : A) 200 partout ; B) 400 + page neutre identique pour jeton invalide, compte inconnu et
  compte supprimé ; one-click : 200 sans corps / 400 sans corps.
- Choix : B — le statut ne distingue que « valide » de « pas valide », jamais la raison.
- Réversibilité : facile.
- Fichiers : `EmailUnsubscribeService`, `PublicEmailController`

## D-13 — Variable `greeting` à côté de `firstName`
- Phase : 2
- Importance : mineure
- Contexte : le moteur n'a pas de condition ; un prénom absent donnerait « Bonjour , ». L'ancien
  repli « à toi » tutoyait (audit C8).
- Options : A) prénom vide ; B) une variable plate `greeting` calculée en Java (« Bonjour Alice » /
  « Bonjour »), `firstName` restant fournie telle quelle.
- Choix : B.
- Réversibilité : facile.
- Fichiers : `EmailFormats.greeting`

## D-14 — Logo hébergé par défaut dans tous les environnements
- Phase : 2
- Importance : mineure
- Contexte : le logo passe d'une image CID à une URL absolue (audit C9). En dev, une URL
  `localhost` ne s'afficherait dans aucun client mail.
- Options : A) `${APP_BASE_URL}/logo_sejourFR.png` ; B) `https://sejourfr.fr/logo_sejourFR.png` par
  défaut, surchargeable (`EMAIL_LOGO_URL`).
- Choix : B.
- Réversibilité : facile.
- Fichiers : `application.yaml`, `EmailProperties.logoUrl`

## D-15 — Moteur de gabarits : une seule passe, apostrophe échappée
- Phase : 2
- Importance : mineure
- Contexte : le remplacement clé par clé relisait une valeur injectée comme un placeholder (un
  message de contact contenant `{{body}}` aurait été substitué).
- Options : A) garder l'ancien moteur ; B) une passe unique par expression régulière, et échapper
  aussi l'apostrophe.
- Choix : B — même syntaxe (`{{x}}` échappé, `{{{x}}}` brut), aucune condition ajoutée.
- Réversibilité : facile.
- Fichiers : `service/email/MailTemplateRenderer.java`

## D-16 — `DIAGNOSTIC_PLAN_READY` est relancé 24 h comme un mail événementiel
- Phase : 2
- Importance : mineure
- Contexte : le brief fixe la relance différée des REQUIRED (24 h) et des scénarios (tant
  qu'éligibles) ; `DIAGNOSTIC_PLAN_READY` est ENGAGEMENT mais événementiel.
- Options : A) aucune relance différée ; B) fenêtre événementielle de 24 h, variables relues
  depuis le Plan.
- Choix : B — le Plan reste disponible, la clé par module garantit l'unicité.
- Réversibilité : facile — `EmailType.DIAGNOSTIC_PLAN_READY`.
- Fichiers : `EmailType`

## D-17 — La composition de `DIAGNOSTIC_PLAN_READY` lit le Plan en lecture seule
- Phase : 2
- Importance : mineure
- Contexte : lire le Plan TCF (`LearningPlanService.get`) épingle sa première place. Composé sur
  l'executor pendant que le candidat ouvre son Plan, le mail provoquait deux épinglages
  concurrents : violation de clé primaire, et c'est la requête **du candidat** qui échouait
  (constaté en IT).
- Options : A) extraire une lecture pure des priorités du moteur ; B) composer dans une
  transaction en lecture seule (connexion comprise) : aucune écriture possible, une écriture
  tentée devient un mail sans priorité.
- Choix : B — correctif local, sans toucher au moteur du Plan ; verrouillé par
  `DiagnosticPlanReadyEmailIT` (aucune ligne `plan_pinned_priorities` écrite par le mail).
- Réversibilité : facile.
- Fichiers : `compose/DiagnosticEmailComposer.java`

---

# Sujets séparés (interdits sans accord du propriétaire)

*(complétés au fil des phases)*

# Blocages

Aucun.
