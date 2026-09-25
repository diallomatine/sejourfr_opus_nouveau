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

## D-25 — La couverture d'un accès reste en Java ; le SQL des scénarios ne fait que borner
- Phase : 4
- Importance : structurante
- Contexte : les scénarios de fin d'accès et `PREMIUM_INACTIVE_2_DAYS` ont besoin de la règle
  « cette ligne ouvre-t-elle un accès ? », qui ne vivait qu'en Java (`SubscriptionService
  .isCovering`). La réécrire en SQL en ferait une seconde copie (risque n°4 de l'audit).
- Options : A) SQL complet + un test qui confronte SQL et Java ; B) le SQL borne les candidats
  (fenêtre de fin, achat unique, compte éligible), puis Java décide avec la règle existante,
  rendue publique (`SubscriptionService.covers`), sur les accès de la page chargés en une requête.
- Choix : B — une seule autorité, et le coût reste borné (une requête de candidats + une requête
  d'accès par page).
- Réversibilité : facile.
- Fichiers : `SubscriptionService.covers`, `automation/PremiumAccessEndResolver.java`,
  `automation/EmailAutomationService.java`, `repository/EmailScenarioRepository.java`

## D-32 — Une ligne de gabarit dont tous les placeholders sont vides est retirée
- Phase : revue
- Importance : structurante
- Contexte : revue D-17 — sans priorité, le bloc « Vos premières priorités » doit être absent,
  en HTML comme en texte. Le moteur n'a pas de condition (complément F), et laissait des
  paragraphes vides.
- Options : A) des fragments HTML composés en Java (du HTML dans les variables, mauvais pour
  Brevo) ; B) une condition dans le moteur (interdit) ; C) règle générique de rendu : une ligne
  dont TOUS les placeholders valent la chaîne vide disparaît, balisage compris ; le texte replie
  les lignes blanches en trop.
- Choix : C — la décision reste en Java (la variable vide), le moteur ne fait que ne pas imprimer
  une ligne qui ne dit plus rien. Sert aussi le bloc de désabonnement d'un mail REQUIRED. Chez
  Brevo, le même effet s'écrira avec ses conditions sur les mêmes params.
- Réversibilité : facile.
- Fichiers : `service/email/MailTemplateRenderer.java`, `SpringMailEmailSender.java`

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

## D-17 — La composition de `DIAGNOSTIC_PLAN_READY` lit le Plan en lecture seule (vérifiée en revue)
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
- Revue : le cas nominal (rapide clos par le pipeline, Plan jamais ouvert, aucune épingle) est
  verrouillé par `DiagnosticPlanReadyEmailIT.lesPrioritesDuPlanSontDansLeMail` : le mail porte
  exactement les priorités que le Plan sert ensuite. Aucune lecture pure supplémentaire n'a été
  nécessaire.
- Réversibilité : facile.
- Fichiers : `compose/DiagnosticEmailComposer.java`

## D-18 — L'activation du mode récurrent dormant réutilise `PREMIUM_ACCESS_STARTED`
- Phase : 3
- Importance : mineure
- Contexte : l'ancien `sendSubscriptionActivatedEmail` servait aussi les flux abonnement
  dormants (wording « renouvelé automatiquement »). Aucun type n'était prévu pour eux.
- Options : A) un type dédié `PREMIUM_SUBSCRIPTION_STARTED` ; B) `PREMIUM_ACCESS_STARTED`, le
  wording venant d'une variable plate `accessTerms` calculée en Java selon `auto_renew`.
- Choix : B — même fait (un premier accès), même clé par `accessId`, aucun type de plus à
  maintenir pour un mode dormant. Ces flux (store) ne se testent pas en IT : leurs appelants sont
  tous transactionnels (`BillingService.handleWebhook`, `@Transactional` Apple/Google,
  `SubscriptionCancellationService`) et la publication est couverte par leurs tests unitaires.
- Réversibilité : facile.
- Fichiers : `compose/PremiumEmailComposer.java`, `billing/SubscriptionNotificationService.java`

## D-19 — `EMAIL_CHANGED` cite la nouvelle adresse MASQUÉE
- Phase : 3
- Importance : mineure
- Contexte : le mail part vers l'ancienne adresse (arbitrage n°10) ; citer la nouvelle en clair
  l'exposerait à qui lit l'ancienne boîte.
- Options : A) ne pas la citer ; B) la citer en clair ; C) la citer masquée (`n***@domaine.fr`).
- Choix : C — la victime d'une prise de contrôle reconnaît que ce n'est pas elle, sans que
  l'adresse circule.
- Réversibilité : facile.
- Fichiers : `compose/SecurityEmailComposer.java`

## D-20 — Accusé de contact : publié par la transaction de la conversation
- Phase : 3
- Importance : mineure
- Contexte : `ContactService.submit` n'est pas transactionnel ; un événement publié hors
  transaction serait perdu (complément D). Le numéro de suivi n'est persisté nulle part.
- Options : A) rendre `submit` transactionnel (le relais SMTP synchrone tiendrait alors la
  transaction) ; B) publier depuis `ConversationService.createFromContact`, qui l'est déjà, en lui
  passant le numéro de suivi.
- Choix : B. `CONTACT_RECEIVED` et `SUPPORT_REPLY` ont `user_id` nul (visiteur) ; `CONTACT_RECEIVED`
  n'a **pas** de relance différée (numéro de suivi non reconstructible), `SUPPORT_REPLY` si (relu
  sur le message).
- Réversibilité : facile.
- Fichiers : `ConversationService.java`, `ContactService.java`, `compose/SupportEmailComposer.java`

## D-21 — Date de mise à jour des documents légaux
- Phase : 3
- Importance : mineure
- Contexte : la politique de confidentialité change (e-mails d'accompagnement, conservation du
  journal 12 mois). La date `LEGAL_INFO.lastUpdated` est commune à tous les documents légaux.
- Options : A) ne pas la toucher ; B) la passer au 2026-09-25.
- Choix : B — une politique modifiée sans date modifiée est pire qu'une date commune avancée.
- Réversibilité : facile.
- Fichiers : `web_sejoufr/content/legal/legal-info.ts`, `web_sejoufr/app/confidentialite/page.tsx`

## D-22 — `MailService` survit une phase, réduit à l'ancien rappel d'expiration
- Phase : 3
- Importance : mineure
- Contexte : tous les mails passent par le port en phase 3, mais l'arbitrage n°6 ne supprime
  `ExpiryReminderJob` qu'une fois `PREMIUM_ENDING_*` en service (phase 4).
- Options : A) supprimer le job dès la phase 3 (trou d'un jour sans rappel) ; B) garder
  `MailService` réduit à `sendAccessExpiringSoonEmail` jusqu'à la phase 4.
- Choix : B — puis suppression complète en phase 4 (job, méthode, gabarits `mail/`, logo CID).
- Réversibilité : facile.
- Fichiers : `service/MailService.java`

## D-23 — Écarts de forme entre les deux pages « Notifications par e-mail »
- Phase : 3
- Importance : mineure
- Contexte : parité web ⇄ mobile. Le web réutilise le squelette de chargement des pages du compte
  (`CompteLoading`), le mobile un indicateur centré ; la ligne à interrupteur est une brique
  nouvelle des deux côtés (`CompteToggleRow` ⇄ `AccountSwitch` dans `ListRow.right`, qui gagne
  un `subMaxLines`). `/profil/notifications` est déclaré dans `lib/app-bar.ts` pour le titre de la
  barre du haut sous 900 px.
- Options : A) aligner les chargements ; B) garder la convention locale de chaque front.
- Choix : B — mêmes libellés (miroirs mot pour mot), mêmes états (optimiste, retour arrière et
  alerte d'erreur, confirmation 3 s), même endpoint.
- Réversibilité : facile.
- Fichiers : `web_sejoufr/app/_components/compte/NotificationsView.tsx`,
  `mobile_sejourfr/lib/screens/profile/notifications_screen.dart`

## D-24 — Chaque mail d'un test d'intégration est aussi RENDU
- Phase : 3
- Importance : mineure
- Contexte : un gabarit qui attend une variable que son composeur ne fournit pas laisserait un
  `{{placeholder}}` chez le candidat, et aucun test unitaire ne relie les deux.
- Options : A) un test par gabarit avec des variables écrites à la main ; B) `AbstractEmailIT`
  rend, après chaque test, TOUS les messages réellement composés avec le vrai
  `SpringMailEmailSender` et exige zéro placeholder.
- Choix : B — c'est le couple composeur ⇄ gabarit réel qui est vérifié, pas une copie.
- Réversibilité : facile.
- Fichiers : `support/AbstractEmailIT.java`

## D-26 — Jours calendaires pour l'âge et l'inactivité, instants pour les fins d'accès
- Phase : 4
- Importance : mineure
- Contexte : le brief écrit « entre J-10 et J-7 » pour les uns et « fin dans ]J+2, J+7] » avec
  `now` pour les autres ; l'exemple d'épisode (« activité le 10, mail le 12 ») raisonne en jours.
- Options : A) tout en instants ; B) tout en jours ; C) jours calendaires Europe/Paris pour
  l'ancienneté et l'inactivité, instants pour les fins d'accès.
- Choix : C — c'est la lecture littérale de chaque ligne du brief, et elle colle à un passage
  quotidien à heure fixe.
- Réversibilité : facile — `EmailAutomationService`.
- Fichiers : `automation/EmailAutomationService.java`

## D-27 — `nextStepLabel` n'est pas servi en V1
- Phase : 4
- Importance : mineure
- Contexte : le brief le demande « si disponible » pour les rappels d'inactivité. Le lire exige de
  construire le Plan (22 requêtes, et une écriture d'épinglage, cf. D-17) pour chaque candidat
  pendant le passage.
- Options : A) construire le Plan en lecture seule par candidat ; B) ne pas le servir en V1.
- Choix : B — les gabarits n'y font pas référence ; à ajouter avec une lecture légère du parcours.
- Réversibilité : facile — une variable et une phrase de gabarit.
- Fichiers : `compose/EngagementEmailComposer.java`

## D-28 — Ce qui « se termine » : l'accès couvrait jusqu'à sa fin
- Phase : 4
- Importance : mineure
- Contexte : l'expiration est paresseuse (le statut reste `ACTIVE` après `ends_at`) ; un pass
  remboursé a une `ends_at` aussi.
- Options : A) filtrer par statut en SQL ; B) `covers(accès, fin − 1 ms)` — il couvrait jusqu'au
  bout — et, pour « aucun accès futur », une ligne couvrante qui commence après `now`.
- Choix : B — même autorité que D-25 ; un remboursement ou une révocation ne déclenche pas
  « votre accès est terminé ».
- Réversibilité : facile.
- Fichiers : `automation/PremiumAccessEndResolver.java`

## D-29 — `expiry_reminded_at` reste mappée, plus jamais écrite
- Phase : 4
- Importance : mineure
- Contexte : règle du dépôt « une colonne legacy cesse d'être écrite et mappée » ; mais le champ
  fait partie de l'instantané `EtatAbonnement` du code de paiement.
- Options : A) retirer le mapping (et toucher `EtatAbonnement`) ; B) garder le mapping, documenter
  le champ comme legacy.
- Choix : B — ne pas modifier le code de paiement (interdit du chantier) pour une colonne inerte.
- Réversibilité : facile.
- Fichiers : `entity/UserSubscription.java`

## D-30 — Priorité des scénarios : une constante, pas un réglage
- Phase : 4
- Importance : mineure
- Contexte : le brief externalise « délais, fenêtres, plafond et tentatives » ; il fixe aussi un
  ordre de priorité.
- Options : A) l'ordre dans le JSON versionné ; B) une constante Java.
- Choix : B — c'est une règle produit (la fin d'un accès prime sur un rappel d'inactivité), pas
  un bouton de réglage.
- Réversibilité : facile.
- Fichiers : `automation/EmailAutomationService.PRIORITE`

## D-31 — Tests des scénarios : horloge dans le futur, activité par simulation orale (révisée par D-35)
- Phase : 4
- Importance : mineure
- Contexte : les requêtes de scénario balaient toute la base, où d'autres tests laissent des
  données commitées ; et une question créée pour un test peut être tirée par un autre.
- Options : A) vider les tables ; B) fixer l'horloge en 2027 (les données des autres tests
  tombent hors fenêtre), n'assertionner que sur les comptes du test, et poser l'activité par une
  `realtime_sessions` jointe (aucun contenu partagé créé).
- Choix : B.
- Réversibilité : facile.
- Fichiers : `EmailAutomationIT`, `EmailDeferredRetryIT`, `support/MutableClock`

## D-33 — `PREMIUM_ENDING_7_DAYS` seulement pour un accès d'au moins 14 jours
- Phase : revue
- Importance : mineure
- Contexte : revue du propriétaire, option B validée — un pass 7 jours serait prévenu de sa fin
  presque dès l'achat.
- Options : A) garder la seule ancienneté de 3 jours ; B) une durée totale minimale, en config.
- Choix : B — `scenarios.*.minAccessDurationDays` (14 pour ENDING_7, 0 ailleurs) dans
  `email-automation-config-v1.json`, validé par le chargeur ; durée = `ends_at − starts_at` de la
  ligne d'accès (une prolongation, qui crée une ligne plus longue, reste prévenue). L'ancienneté
  de 3 jours devient redondante pour ENDING_7 (une fin à ≤ 7 jours d'un accès de ≥ 14 jours
  implique ≥ 7 jours d'ancienneté) ; elle est conservée.
- Réversibilité : facile — la valeur de config.
- Fichiers : `email-automation-config-v1.json`, `EmailAutomationConfig`, `EmailAutomationService`

## D-34 — Aucun délai écrit en dur dans les mails ENGAGEMENT
- Phase : revue
- Importance : mineure
- Contexte : revue — la vraie `accessEndDate` est l'autorité. Deux gabarits disaient « une
  semaine » (compte créé, dernier entraînement), faux un jour de rattrapage.
- Options : A) calculer le délai réel en variable ; B) des formulations sans durée.
- Choix : B — « il y a quelques jours », « remonte à plusieurs jours » ; sujets de fin d'accès
  portés par `{{accessEndDate}}`. Figé par `EmailTemplatesConfiguredTest.aucunDelaiEcritEnDur`.
- Réversibilité : facile.
- Fichiers : `resources/email/no-premium-after-7-days.*`, `no-training-7-days.*`

## D-35 — D-31 révisée : horloge des tests relative à l'exécution
- Phase : revue
- Importance : mineure
- Contexte : revue — pas de date fixe (2027) dans les tests.
- Options : A) isoler les données de scénario ; B) un décalage relatif.
- Choix : B — `T` = aujourd'hui (UTC) + 365 jours à 8 h UTC dans `EmailAutomationIT` et
  `EmailDeferredRetryIT` ; les dates attendues se calculent depuis `T`. Aucune infrastructure de
  test partagée modifiée.
- Réversibilité : facile.
- Fichiers : `EmailAutomationIT`, `EmailDeferredRetryIT`

## D-36 — Tests front de la page « Notifications par e-mail » : exception demandée par le propriétaire
- Phase : revue
- Importance : mineure
- Contexte : la règle racine « aucun nouveau test front » ; le propriétaire demande
  explicitement des tests pour cette page (revue du 2026-09-25), exception limitée à ce cas.
- Options : A) tester le composant React (exige une bibliothèque DOM nouvelle) ; B) extraire la
  logique d'état dans un module pur et la tester avec le runner existant.
- Choix : B — web : `lib/notifications.ts` + `lib/notifications.test.ts` (runner `node --test`
  déjà en place, aucune dépendance ajoutée), la vue l'utilise sans changer son rendu ; mobile :
  `test/notifications_screen_test.dart` (notifier + widget, faux dépôt comme les tests
  existants). Couvre chargement, bascule optimiste dans les deux sens, succès, erreur API,
  retour arrière + message d'erreur. Noté dans les deux `CLAUDE.md` des fronts.
- Réversibilité : facile.
- Fichiers : `web_sejoufr/lib/notifications*.ts`, `web_sejoufr/app/_components/compte/NotificationsView.tsx`,
  `mobile_sejourfr/test/notifications_screen_test.dart`

---

# Sujets séparés (interdits sans accord du propriétaire)

- **SS-1 — Stripe « paiement confirmé » (arbitrage n°20).** `StripeSubscriptionService
  .handleOneTimeCheckout` ne vérifie pas `session.payment_status == "paid"` et `BillingService`
  ne restreint pas les moyens de paiement. Si un moyen différé (SEPA…) est activé côté Stripe,
  l'accès — et donc `PREMIUM_ACCESS_STARTED` — part avant l'encaissement. Workflow de paiement :
  non modifié.
- **SS-2 — Newsletter du pied de page (arbitrage n°15).** `Footer.tsx` appelle
  `POST /api/newsletter/subscribe`, qui **n'existe pas** côté backend ; la politique de
  confidentialité annonce pourtant une finalité « newsletters ». Footer non modifié.
- **SS-3 — S5 : `GET /api/auth/confirm-email-change` modifie l'état.** Un scanner de liens peut
  consommer le jeton. Correctif proposé : même patron que le désabonnement (GET affiche une
  confirmation, POST applique).
- **SS-4 — S6 : jetons en query string dans les journaux Nginx** (reset, changement d'email,
  désabonnement). Config Nginx hors dépôt : `log_format` sans `$args` sur `api.sejourfr.fr` et
  `sejourfr.fr`, ou accepter (jetons hachés en base, TTL 1 h ; le jeton de désabonnement ne
  donne que le droit de se désabonner).
- **SS-5 — Liens mobiles** (arbitrage n°14) : les mails pointent vers le web ; universal links /
  app links à traiter séparément.
- **SS-6 — Webhooks Brevo** (rebonds, plaintes → préférences) et `BrevoEmailSender` : hors
  périmètre (brief §11), `provider_message_id` prêt.

# Blocages

## B-1 — Relais du formulaire de contact — ✅ CLOS (revue du propriétaire, 2026-09-25)
- Arbitrage : **statu quo**. La conversation enregistrée dans la boîte admin est la source de
  vérité. Demande enregistrée ⇒ le visiteur voit un succès. La notification email au support est
  secondaire : si elle échoue, log serveur masqué, réponse utilisateur inchangée. Un incident SMTP
  ne doit pas provoquer un second envoi du formulaire et des doublons.
- Le relais n'est donc **pas** une exception au principe « un échec d'envoi ne fait pas échouer le
  parcours » : son erreur remonte techniquement à `ContactService`, qui l'absorbe délibérément.
  Invariant 3 de `docs/regles/emails.md` reformulé en conséquence.
