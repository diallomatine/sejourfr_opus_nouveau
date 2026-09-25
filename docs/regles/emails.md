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
   entraînement. Seule exception, voulue : le **relais du formulaire de contact** vers le support
   est synchrone et son échec remonte à `ContactService` (arbitrage n°9).
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
   variable plate déjà calculée en Java, éventuellement vide.
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
`EmailSender.relayToSupport`, **aucune ligne de journal**, et son échec remonte à
`ContactService` — qui garde la demande (la boîte admin fait foi, point en attente d'arbitrage :
blocage B-1 de `docs/email/decisions.md`).

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
  `priority2/3` **vides** si le Plan provisoire en a moins — jamais comblées.

## Environnement de dev

Le dev pointe sur un **vrai SMTP** (`MAIL_HOST` de `backend_sejourfr/.env`), pas sur MailHog, et
la base locale contient des adresses réelles de testeurs. Donc, en profil `dev` :
`sejourfr.email.allowlist.enabled=true` avec `EMAIL_DEV_ALLOWLIST` (vide = **aucun** mail
utilisateur ne part), et `sejourfr.email.automation.enabled=false`. Les tests n'envoient rien :
`RecordingEmailSender` (@Primary dans `TestSupportConfig`) remplace le port.
