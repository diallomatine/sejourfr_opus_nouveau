# Emails — la loi du sous-système

> **Lu à la demande.** Brief : `docs/email/brief-emails-sejourfr.md`. Audit :
> `docs/email/AUDIT_emails_phase1.md`. Arbitrages opposables :
> `docs/email/REPONSES_AUDIT_emails.md`. Décisions prises en autonomie (le « pourquoi ») :
> `docs/email/decisions.md`. Bilan : `docs/email/RAPPORT_FINAL.md`.

Code : `backend_sejourfr/src/main/java/com/sejourfr/app/service/email/` (+ `event/`, `compose/`,
`automation/`), gabarits `backend_sejourfr/src/main/resources/email/`, configuration
`sejourfr.email.*` (`EmailProperties`) et `email/email-automation-config-v{n}.json`.

---

## 🛑 Les invariants

1. **Un mail ne part jamais de la transaction métier.** Événement publié DANS la transaction,
   écouté en `@TransactionalEventListener(AFTER_COMMIT)`, composé et envoyé sur
   `emailTaskExecutor` (`EmailDispatcher`). Un rollback n'envoie rien ; un SMTP lent ne retient
   ni la transaction ni la requête. `fallbackExecution` reste à `false` : un événement publié
   hors transaction serait perdu en silence — chaque point de publication est couvert par un IT
   qui prouve sa transaction.
2. **`JavaMailSender` n'existe que dans `SpringMailEmailSender`.** Tout passe par le port
   `EmailSender`. Passer à Brevo = créer `BrevoEmailSender`, renseigner les `brevo-template-id`,
   `EMAIL_PROVIDER=brevo`. Rien d'autre ne bouge.
3. **Un échec d'envoi ne fait jamais échouer** une inscription, un paiement, un diagnostic ou un
   entraînement. Le **relais du formulaire de contact** vers le support n'y fait **pas**
   exception : il est synchrone et son erreur remonte techniquement à `ContactService`, qui
   l'**absorbe délibérément** (log serveur masqué) parce que la conversation enregistrée dans la
   boîte admin est l'autorité. Demande enregistrée ⇒ le visiteur voit un succès ; un incident
   SMTP ne doit jamais provoquer un second envoi du formulaire, donc un doublon (arbitrage B-1).
4. **REQUIRED ne se désactive pas.** Aucun champ de préférence ne le concerne.
5. **Aucun token, mot de passe ni URL à token dans un log**, et aucune adresse en clair
   (`LogMask.email`). Les `record` d'événement et de message redéfinissent `toString()`.
   `error_message` est assaini (`EmailErrors.sanitize` : adresses masquées, `token=` retiré,
   500 caractères).
6. **Le journal ne stocke jamais le HTML ni les variables** (elles peuvent porter une URL à
   jeton). Une relance différée **reconstruit** les variables depuis la source, par le même
   composeur que l'envoi initial.
7. **Aucune logique métier dans un gabarit.** Le moteur (`MailTemplateRenderer`) ne connaît que
   `{{x}}` (échappé) et `{{{x}}}` (brut), en une seule passe. Un passage optionnel arrive en
   variable plate déjà calculée en Java, éventuellement vide ; **une ligne de gabarit dont tous
   les placeholders sont vides est retirée entière** (décision D-32) — ni paragraphe vide ni
   ligne blanche.
8. **Aucun prix, remise, « offre » ni urgence commerciale dans un mail ENGAGEMENT.** Le CTA de fin
   d'accès mène à « Mon pass » (`/profil/abonnement`), jamais à `/paiement`.
9. **Vocabulaire** : « accès Premium », « pass », « accès TCF / Civique ». Jamais « abonnement »
   dans un texte client, sauf le mail du mode récurrent **dormant**
   (`PREMIUM_SUBSCRIPTION_CANCELED`).

## Catégories et types

| Catégorie | Désactivable | Règle |
|---|---|---|
| `REQUIRED` | non | sécurité, compte, paiement |
| `ENGAGEMENT` | oui (lien en pied + « Notifications par e-mail ») | actif par défaut |
| `MARKETING` | opt-in | catégorie et préférence prêtes, **aucun mail** |

La catégorie, la politique de relance différée et l'exemption de plafond de chaque type sont des
**règles** : elles vivent dans `enums/EmailType.java`. Clés anti-doublon : `EmailKeys`.

| Type | Cat. | Déclenchement (point de publication) | Clé | Relance différée |
|---|---|---|---|---|
| `WELCOME` | REQ | compte créé : `AuthService.register`, branche création de `SocialAuthService` | `WELCOME:{userId}` | 24 h |
| `PREMIUM_ACCESS_STARTED` | REQ | premier accès accordé : `OneTimeAccessService` ; activation du récurrent dormant | `…:{accessId}` | 24 h |
| `PREMIUM_ACCESS_EXTENDED` | REQ | achat qui prolonge un accès en cours : `OneTimeAccessService` | `…:{accessId}` | 24 h |
| `PREMIUM_SUBSCRIPTION_CANCELED` | REQ | résiliation du récurrent **dormant** | `…:{accessId}` | 24 h |
| `PASSWORD_RESET` | REQ | `AuthService.requestPasswordReset` | `…:{password_reset_tokens.id}` | 🛑 jamais |
| `PASSWORD_CHANGED` | REQ | `AuthService.resetPassword` **et** `UserProfileService.changePassword` | `…:{UUID de l'événement}` | 24 h |
| `EMAIL_CHANGE_CONFIRMATION` | REQ | `UserProfileService.requestEmailChange` → **nouvelle** adresse | `…:{email_change_tokens.id}` | 🛑 jamais |
| `EMAIL_CHANGED` | REQ | `UserProfileService.confirmEmailChange` → **ancienne** adresse (nouvelle masquée) | `…:{email_change_tokens.id}` | 24 h |
| `CONTACT_RECEIVED` | REQ | `ConversationService.createFromContact` (avec numéro de suivi) | `…:{conversationId}` | jamais (suivi non persisté) |
| `SUPPORT_REPLY` | REQ | `ConversationService.reply` (conversation de contact) | `…:{messageId}` | 24 h |
| `DIAGNOSTIC_PLAN_READY` | ENG | premier Plan du module (voir plus bas) | `…:{userId}:{module}` | 24 h |
| `NO_PREMIUM_AFTER_7_DAYS` | ENG | scénario quotidien | `…:{userId}` | tant qu'éligible |
| `NO_TRAINING_7_DAYS` | ENG | scénario quotidien | `…:{userId}:{date de dernière activité}` | tant qu'éligible |
| `PREMIUM_INACTIVE_2_DAYS` | ENG | scénario quotidien | `…:{userId}:{date de référence}` | tant qu'éligible |
| `PREMIUM_ENDING_7_DAYS` / `_2_DAYS` | ENG | scénario quotidien | `…:{accessId}` | tant qu'éligible |
| `PREMIUM_ENDED` | ENG | scénario quotidien | `…:{accessId}` | tant qu'éligible |

**Relance différée** (au plus `maxDeferredAttempts` = 3 nouvelles lignes par clé) : les types
« 24 h » sont repris par la passe de maintenance horaire tant que la PREMIÈRE ligne de la clé a
moins de 24 h, variables reconstruites depuis la source (`reference_id`, `occurred_at`, et pour
`EMAIL_CHANGED` l'ancienne adresse lue sur la ligne du journal) ; les scénarios sont repris par
leur propre réévaluation quotidienne (une clé `FAILED` ne bloque pas). 🛑 `PASSWORD_RESET` et
`EMAIL_CHANGE_CONFIRMATION` jamais : leur jeton n'est stocké que haché.

**Le relais du formulaire de contact** vers le support n'est pas un mail client : synchrone,
`EmailSender.relayToSupport`, **aucune ligne de journal** ; son échec remonte à `ContactService`,
qui l'absorbe (log masqué, réponse inchangée) : la conversation enregistrée fait foi (B-1, clos).

## Les règles d'envoi — `EmailService`, dans l'ordre

1. catégorie du type ;
2. préférences (`EmailCategoryPolicy`) — ligne absente = engagement actif, marketing refusé. Un
   refus d'un mail **événementiel** est tracé `SKIPPED / PREFERENCE` ; le scheduler exclut les
   désabonnés dans ses requêtes et n'écrit rien ;
3. **plafond ENGAGEMENT : 1 par jour calendaire Europe/Paris** (pas 24 h glissantes). Refus non
   tracé, réévalué le lendemain. `DIAGNOSTIC_PLAN_READY` n'y est jamais soumis mais le
   **consomme** (arbitrage n°18) ;
4. tentatives épuisées pour la clé (1 + `maxDeferredAttempts` lignes) ;
5. **liste blanche de dev** : hors liste → `SKIPPED / ALLOWLIST` (complément G) ;
6. **anti-doublon : `INSERT PENDING` d'abord** (`ON CONFLICT DO NOTHING` sur l'index unique
   partiel `WHERE status IN ('PENDING','SENT','SKIPPED')`). Jamais « SELECT puis INSERT ».
   `FAILED` libère la clé ; `SKIPPED` l'occupe (décision D-1) ;
7. envoi par le port, **relance immédiate** : boucle explicite, `Sleeper` injectable, délais de la
   configuration versionnée (30 s, 2 min, 5 min), **sur la même ligne** ;
8. `SENT` (+ `sent_at`, `attempt_count`) ou `FAILED` (+ erreur assainie).

`send` fait tout dans le thread appelant (réservé à l'executor email) ; `sendAsync` (scheduler,
relance différée) écrit la ligne PENDING dans le thread appelant puis confie l'envoi à
l'executor. **Rejet de l'executor → ligne `FAILED`**, jamais d'exécution dans le thread appelant
(pas de `CallerRunsPolicy`, complément E).

## L'executor

`emailTaskExecutor` (`config/EmailAsyncConfig`) : dédié, **borné** (2 → 4 threads, file de 500,
`AbortPolicy`). Une panne SMTP ne ralentit jamais la notation IA, qui tourne sur l'executor par
défaut.

## Le journal `email_deliveries` (V073)

`status` ∈ `PENDING / SENT / FAILED / SKIPPED`, `skip_reason` ∈ `PREFERENCE / ALLOWLIST /
KEY_CONSUMED`, `reference_id` (la source à relire), `occurred_at` (l'instant du fait quand aucune
table ne le porte), `attempt_count`, `provider_message_id` (webhooks Brevo, futur). `user_id` est
nullable (accusé de contact et réponse du support vers un visiteur sans compte).

- **Rétention : 12 mois** (arbitrage n°16), purge quotidienne par lots.
- **Suppression / anonymisation du compte** : `AccountDeletionService` supprime ses lignes **et**
  celles envoyées à son adresse sans compte rattaché, puis ses préférences. (La cascade SQL ne
  joue pas : un compte est anonymisé, pas supprimé.)

## L'activité d'entraînement — une vue, une autorité

`v_derniere_activite_entrainement` (V073) = `max` des **quatre actes du candidat** : réponse QCM
(`answers.answered_at`), production EE/EO (`production_submissions.submitted_at`), petit sujet
(`user_skill_attempts.created_at`), simulation orale **réellement jointe**
(`realtime_sessions.connected_at`). Diagnostics et examens blancs compris. 🛑 **Jamais
`attempts.started_at` / `finished_at`** (ouvrir n'est pas s'entraîner ; `finished_at` est posé par
le système, jusqu'à 9 jours après le dernier acte). Lue par le scheduler, jamais recopiée en Java.

## Désabonnement (ENGAGEMENT seulement)

- Jeton `base64url(userId).keyVersion.base64url(HMAC-SHA256(secret[kv], "unsub:engagement|userId|kv"))`,
  comparaison à temps constant, **sans expiration**. Trousseau `sejourfr.email.unsubscribe`
  (la clé courante signe, les anciennes vérifient). `EMAIL_UNSUBSCRIBE_KEY_V1` **obligatoire**
  en production (échec au démarrage sinon).
- `GET /api/public/email/unsubscribe?token=` : page de confirmation, **ne modifie rien**.
  `POST /api/public/email/unsubscribe` : désabonne. `POST …/one-click?token=` : RFC 8058.
  Jeton invalide / compte inconnu ou supprimé : **même page neutre**, 400.
- En-têtes `List-Unsubscribe` + `List-Unsubscribe-Post: List-Unsubscribe=One-Click` et bloc de
  pied « Ne plus recevoir les conseils et rappels d'entraînement » : **ENGAGEMENT uniquement**.
- Réactivation : page « Notifications par e-mail » des deux fronts (`/profil/notifications` ⇄
  `/profile/notifications`), un seul interrupteur en V1 (« Recevoir les conseils et rappels
  d'entraînement »), `GET/PATCH /api/me/email-preferences`. La préférence MARKETING est prête
  côté backend (consentement daté) mais n'est affichée nulle part tant qu'aucun mail marketing
  n'existe.

## `DIAGNOSTIC_PLAN_READY`

- Part quand un diagnostic rend le Plan d'un module disponible **pour la première fois**
  (arbitrage n°7) : TCF rapide clos ; TCF complet clos sans Plan TCF préalable ; civique clos.
  « Première fois » = aucun **autre** diagnostic clos du module (`DiagnosticPlanReadyNotifier`,
  même règle que `PlanFoundationResolver`) **et** la clé `DIAGNOSTIC_PLAN_READY:{userId}:{module}`
  (complément B). Un complet qui affine un Plan existant n'envoie rien.
- Quatre points de publication, tous transactionnels : `DiagnosticSessionCoordinator
  .onAnalysisCompleted`, `TcfDiagnosticService.cloturer`, `CivicDiagnosticService.cloturer` et sa
  **clôture paresseuse** pendant une lecture.
- **Adoption** d'un diagnostic civique invité : pas de mail, la clé est **consommée**
  (`SKIPPED / KEY_CONSUMED`, complément C). Le TCF invité n'a pas d'adoption serveur : sa première
  soumission après inscription est un diagnostic ordinaire (décision D-7).
- Variables : au plus les **trois premières priorités servies** par le Plan du module,
  `priority2/3` **vides** si le Plan provisoire en a moins — jamais comblées. Lues en
  **lecture seule** (aucun épinglage) : ce sont bien celles que le candidat verra en ouvrant son
  Plan (`DiagnosticPlanReadyEmailIT.lesPrioritesDuPlanSontDansLeMail`). Sans priorité, le bloc
  « Vos premières priorités » **disparaît entier**, en HTML comme en texte.

## Les scénarios automatisés (passage quotidien)

`EmailAutomationJob.scenarios` (cron `sejourfr.email.automation.cron`, 9 h Europe/Paris) →
`EmailAutomationService.runDaily(now)`. Une seule instance en production : pas de ShedLock.
Au début de chaque passage (et à chaque passe de maintenance horaire) : les `PENDING` de plus
d'une heure passent `FAILED` (« stale »).

**Priorité sous plafond** (règle, constante `EmailAutomationService.PRIORITE`) :
`PREMIUM_ENDED` > `PREMIUM_ENDING_2_DAYS` > `PREMIUM_ENDING_7_DAYS` > `PREMIUM_INACTIVE_2_DAYS` >
`NO_TRAINING_7_DAYS` > `NO_PREMIUM_AFTER_7_DAYS`. Les scénarios passent dans cet ordre ; chaque
envoi écrit sa ligne PENDING dans le thread du passage, donc le plafond retient les suivants pour
le même compte — sans trace, et ils repartent le lendemain si leur fenêtre le permet.

**Fenêtres bornées** (`email-automation-config-v1.json`, `scenarios`) — elles rattrapent un jour
manqué et n'envoient rien rétroactivement au premier déploiement :

| Scénario | Condition (tous : compte actif, USER, rappels activés) | Fenêtre |
|---|---|---|
| `NO_PREMIUM_AFTER_7_DAYS` | inscrit, **jamais** d'accès payant (passé ou actuel) | 7 à 10 jours calendaires depuis l'inscription |
| `NO_TRAINING_7_DAYS` | au moins une activité | 7 à 14 jours depuis la dernière activité |
| `PREMIUM_INACTIVE_2_DAYS` | un accès couvrant | 2 à 5 jours depuis `max(dernière activité, début de l'accès couvrant le plus récent)` (arbitrage n°19) |
| `PREMIUM_ENDING_7_DAYS` | pass couvrant, commencé il y a ≥ 3 jours, **d'une durée totale ≥ 14 jours** (`minAccessDurationDays`), rien ne le prolonge | fin dans `]now+2 j, now+7 j]` |
| `PREMIUM_ENDING_2_DAYS` | pass couvrant, rien ne le prolonge | fin dans `]now, now+2 j]` |
| `PREMIUM_ENDED` | le pass couvrait jusqu'à sa fin, aucun accès de module ≥ actif ni à venir | fin dans `[now−3 j, now]` |

- **Pass courts** : un pass de 7 jours ne reçoit jamais `PREMIUM_ENDING_7_DAYS` (il serait
  prévenu de sa fin dès l'achat) — au plus le rappel d'inactivité, `ENDING_2`, puis `ENDED`.
- 🛑 **Aucun délai écrit en dur** dans un mail ENGAGEMENT (« dans 7 jours », « une semaine »…) :
  un rappel peut partir un jour de rattrapage et un pass peut être prolongé. La vraie date
  (`accessEndDate`) est la seule autorité (figé par `EmailTemplatesConfiguredTest`).
- Jours **calendaires Europe/Paris** pour l'âge du compte et l'inactivité ; **instants** pour les
  fins d'accès (décision D-26).
- **Épisodes d'inactivité** : la clé porte la date qui a ouvert l'épisode ⇒ au plus un mail par
  type et par épisode. Premium : J+2 puis J+7, puis rien ; non Premium : J+7 seul ; une nouvelle
  activité ouvre un nouvel épisode. Un Premium qui ne s'est jamais entraîné reçoit
  `PREMIUM_INACTIVE_2_DAYS` (daté du début d'accès), jamais `NO_TRAINING_7_DAYS`.
- 🛑 **Fins d'accès** : seuls les **achats uniques** (`purchase_type = ONE_TIME`, `auto_renew`
  faux) — les abonnements récurrents dormants sont exclus (arbitrage n°5). « Rien ne le prolonge »
  = aucune autre ligne couvrante de module ≥ qui finit plus tard (une prolongation crée une
  nouvelle ligne qui chevauche l'ancienne). La **couverture** se lit sur
  `SubscriptionService.covers`, l'autorité unique : le SQL ne fait que borner les candidats
  (décision D-25). Un pass remboursé ne « se termine » pas.
- **Libellé selon le module** (`PremiumAccessEndResolver`, complément F) : « Votre pass
  Intégral », « Votre accès Civique », ou « Votre accès TCF » + « Votre accès Civique reste actif
  jusqu'au … » quand un Civique survit à l'Intégral. Variables plates, aucune condition dans le
  gabarit.
- **Contenu** : informatif, aucun prix/remise/offre/urgence (figé par
  `EmailTemplatesConfiguredTest`) ; fin d'accès → « Voir mon pass » (`/profil/abonnement`) ; fin
  effective → « Votre progression et vos résultats restent disponibles ».
- `nextStepLabel` (brief §9, « si disponible ») n'est pas servi en V1 (décision D-27).

Les candidats se lisent **par pages** à jeu de clés (`id > :after`, `batchSize`), et les accès
d'une page en **une** requête (`UserSubscriptionManager.findByUserIds`) : pas de N+1.

**Maintenance** (`EmailAutomationJob.maintenance`, horaire) : PENDING bloqués + relance différée
des mails événementiels (`EmailDeferredRetryService`). **Rétention**
(`EmailAutomationJob.retention`, quotidienne) : purge des lignes de plus de 12 mois, par lots.

L'ancien `ExpiryReminderJob` (rappel « Prolonger mon accès » vers `/paiement`, qui prévenait à
tort un acheteur ayant prolongé) est **supprimé** ; `user_subscriptions.expiry_reminded_at`
reste en base, plus jamais écrite (arbitrage n°6).

## Environnement de dev

Le dev pointe sur un **vrai SMTP** (`MAIL_HOST` de `backend_sejourfr/.env`), pas sur MailHog, et
la base locale contient des adresses réelles de testeurs. Donc, en profil `dev` :
`sejourfr.email.allowlist.enabled=true` avec `EMAIL_DEV_ALLOWLIST` (vide = **aucun** mail
utilisateur ne part), et `sejourfr.email.automation.enabled=false`. Les tests n'envoient rien :
`RecordingEmailSender` (@Primary dans `TestSupportConfig`) remplace le port.
