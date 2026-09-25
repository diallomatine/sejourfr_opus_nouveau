# Brief Claude Code — Système d'emails SejourFR

## 0. Mode opératoire (obligatoire)

| Phase | Contenu | Fin de phase |
|---|---|---|
| 1 | Audit du code existant, sans écrire de code | 🛑 **STOP** : rapport et questions |
| 2 | Socle : enums, abstraction d'envoi, templates, préférences, `email_deliveries`, `EmailService` | 🛑 **STOP** : démo sur 1 mail REQUIRED + 1 ENGAGEMENT |
| 3 | Mails événementiels + désabonnement + API préférences | 🛑 **STOP** : validation |
| 4 | Automatisation (scheduler) + tests complets | Livraison |

Les noms de classes dans ce brief sont **indicatifs**. Adapte-les aux conventions du projet constatées pendant l'audit.

### Phase 1 — le rapport d'audit doit couvrir

1. Le code mail existant : usages de `JavaMailSender`, moteur de templates (Thymeleaf ? autre ?), liste des templates présents et variables utilisées.
2. L'infra existante : événements Spring, `@Async` / executors, `@EnableScheduling`, ShedLock, `Clock` injectable, et nombre d'instances backend en prod.
3. Les sources de vérité :
   - création effective du compte ;
   - accès Premium (entité, date de début et de fin, unification Stripe / Apple IAP / Google Play ?) ;
   - **activité d'entraînement** (quelle table/colonne donne la dernière activité ? `attempts` ? `answers` ?) ;
   - diagnostic terminé + plan généré (entités, événement existant ?) ;
   - flux reset / changement de mot de passe.
4. La page front qui pourrait accueillir le toggle « rappels d'entraînement » (paramètres du compte).
5. Les écarts entre ce brief et le code, et les questions ouvertes.

---

## 1. Objectif et contraintes non négociables

L'objectif est un système d'emails centralisé, fonctionnant aujourd'hui avec Spring Mail et les templates existants. Le passage à Brevo ne doit changer **que** l'implémentation d'envoi et la configuration des templates.

Interdit :

- appeler `JavaMailSender` hors de l'implémentation Spring Mail ;
- intégrer Brevo maintenant ;
- introduire une queue externe (Kafka, RabbitMQ) ;
- mettre de la logique métier dans les templates ;
- laisser un échec d'envoi faire échouer une inscription, un paiement, un diagnostic ou un entraînement ;
- permettre de désactiver les mails REQUIRED ;
- logger un token (reset, désabonnement), un mot de passe ou une URL contenant un token.

---

## 2. Catégories et types

| Catégorie | Règle | Désactivable |
|---|---|---|
| `REQUIRED` | Sécurité, compte, paiement | Non |
| `ENGAGEMENT` | Accompagnement de l'apprentissage, actif par défaut | Oui (lien en pied de mail + paramètres) |
| `MARKETING` | Promotions : catégorie et préférence prévues, **aucun mail implémenté** | Oui, opt-in |

| Type | Catégorie | Déclenchement | Clé anti-doublon |
|---|---|---|---|
| `WELCOME` | REQUIRED | Événement : compte créé | `WELCOME:{userId}` |
| `PREMIUM_ACCESS_STARTED` | REQUIRED | Événement : paiement **confirmé** + accès activé | `PREMIUM_ACCESS_STARTED:{accessId}` |
| `PASSWORD_RESET` | REQUIRED | Événement : demande de reset | `PASSWORD_RESET:{resetRequestId}` (chaque demande = un mail) |
| `PASSWORD_CHANGED` | REQUIRED | Événement : mot de passe modifié | `PASSWORD_CHANGED:{passwordChangeEventId}` |

> Si l'audit montre qu'aucune entité ne porte `resetRequestId` ou `passwordChangeEventId`, proposer un identifiant stable (id de la ligne de token de reset, UUID généré dans l'événement) avant de coder.
| `DIAGNOSTIC_PLAN_READY` | ENGAGEMENT | Événement : diagnostic terminé + plan généré | `DIAGNOSTIC_PLAN_READY:{diagnosticId}` |
| `NO_PREMIUM_AFTER_7_DAYS` | ENGAGEMENT | Scheduler | `NO_PREMIUM_AFTER_7_DAYS:{userId}` |
| `NO_TRAINING_7_DAYS` | ENGAGEMENT | Scheduler | `NO_TRAINING_7_DAYS:{userId}:{lastActivityDate}` |
| `PREMIUM_INACTIVE_2_DAYS` | ENGAGEMENT | Scheduler | `PREMIUM_INACTIVE_2_DAYS:{userId}:{referenceDate}` |
| `PREMIUM_ENDING_7_DAYS` | ENGAGEMENT | Scheduler | `PREMIUM_ENDING_7_DAYS:{accessId}` |
| `PREMIUM_ENDING_2_DAYS` | ENGAGEMENT | Scheduler | `PREMIUM_ENDING_2_DAYS:{accessId}` |
| `PREMIUM_ENDED` | ENGAGEMENT | Scheduler | `PREMIUM_ENDED:{accessId}` |

> Vocabulaire : l'offre est un **achat unique sans reconduction**. On parle d'« accès Premium » partout (types, templates, textes), jamais d'« abonnement ».

---

## 3. Architecture

```text
Événement métier (AFTER_COMMIT, async)  /  Scheduler quotidien
                 ↓
            EmailService
   catégorie → préférences → plafond → anti-doublon (INSERT PENDING)
                 ↓
            EmailSender (port)
        ├─ SpringMailEmailSender   ← aujourd'hui (template local + rendu)
        └─ BrevoEmailSender        ← demain (templateId + params)
                 ↓
      email_deliveries : SENT / FAILED
```

- **`EmailMessage`** : `recipient`, `type`, `variables`, `unsubscribeUrl` (nullable). Pas de sujet ici : chez Brevo, le sujet vit dans le template.
- **Résolution de template par provider**, via la config :

```yaml
email:
  provider: spring-mail          # demain : brevo
  from: "SejourFR <noreply@...>"
  reply-to: "contact@..."
  templates:
    WELCOME:
      subject: "Bienvenue sur SejourFR"
      local-template: emails/welcome
      brevo-template-id:          # renseigné plus tard
```

- L'implémentation active est sélectionnée par `@ConditionalOnProperty(name = "email.provider")`.
- **Variables = futurs params Brevo** : plates, en camelCase, stables, sans objet imbriqué. Aucun ID Brevo dans le code Java.

---

## 4. Données (Flyway, en suivant la numérotation et les conventions UUID existantes)

### `user_email_preferences`

| Colonne | Détail |
|---|---|
| `user_id` | PK + FK users, `ON DELETE CASCADE` |
| `engagement_enabled` | `BOOLEAN NOT NULL DEFAULT TRUE` |
| `marketing_enabled` | `BOOLEAN NOT NULL DEFAULT FALSE` |
| `marketing_consent_at` | `TIMESTAMPTZ NULL` (preuve du consentement) |
| `created_at`, `updated_at` | |

- **Pas de migration de masse** : une ligne absente équivaut aux valeurs par défaut, gérées côté métier. La ligne est créée à la première modification.

### `email_deliveries`

| Colonne | Détail |
|---|---|
| `id` | UUID |
| `user_id` | FK, `ON DELETE CASCADE` |
| `email_type`, `category` | |
| `recipient` | |
| `status` | `PENDING`, `SENT`, `FAILED`, `SKIPPED` |
| `provider` | `SPRING_MAIL`, `BREVO` |
| `provider_message_id` | nullable, servira aux webhooks Brevo |
| `deduplication_key` | nullable |
| `error_message` | tronqué à 500 caractères, sans donnée sensible |
| `created_at`, `sent_at`, `failed_at` | |

- Index unique **partiel** : `UNIQUE (deduplication_key) WHERE status IN ('PENDING','SENT')`. Une ligne FAILED ne bloque donc pas une nouvelle tentative.
- Index sur `(user_id, category, created_at)` pour le plafond.
- Ne jamais stocker le HTML ni les variables (elles peuvent contenir l'URL de reset).
- `SKIPPED` n'est enregistré **que** pour les mails événementiels refusés (préférences). Le scheduler exclut les opt-out directement dans ses requêtes, pour ne pas polluer la table.

---

## 5. `EmailService` : règles d'envoi

Ordre de traitement :

1. Catégorie du type.
2. Préférences (REQUIRED les ignore).
3. **Plafond** : au maximum 1 mail ENGAGEMENT par user et par 24 h (valeur en config). Un mail refusé par le plafond n'est **pas** enregistré : il sera réévalué le lendemain.
4. Anti-doublon : **INSERT PENDING d'abord**. En cas de violation d'unicité, on sort sans erreur. Pas de « SELECT puis INSERT ».
5. Envoi via `EmailSender`.
6. Passage en `SENT` (avec `sent_at`) ou `FAILED` (avec `error_message`).

Robustesse :

- **Relance immédiate (tous types)** : en cas d'échec, 3 tentatives dans le thread async avec backoff (ex : 30 s, 2 min, 5 min, en config), sur la **même** ligne `email_deliveries`. Utiliser le mécanisme de retry disponible dans le projet (ou `@Retryable` de Spring Framework 7 s'il est présent). Couvre les coupures SMTP courtes.
- **Relance différée (scheduler)** : une ligne FAILED encore dans sa fenêtre est retentée au passage suivant, avec au maximum 3 tentatives différées par clé (config). Les variables sont **reconstruites depuis la source** (user, accès), jamais stockées.
  - ENGAGEMENT : relance différée tant que le scénario reste éligible.
  - `WELCOME`, `PREMIUM_ACCESS_STARTED`, `PASSWORD_CHANGED` : relance différée pendant 24 h au maximum.
  - **`PASSWORD_RESET` : aucune relance différée.** L'URL contient un token qui n'est stocké que haché. Le renvoyer imposerait de le stocker en clair, ce qui est interdit. L'utilisateur refait une demande.
- **PENDING bloqué** : au début de chaque passage du scheduler, les PENDING de plus d'1 h passent en `FAILED` avec l'erreur « stale ».
- **Découplage** : les mails événementiels partent via `@TransactionalEventListener(phase = AFTER_COMMIT)` + `@Async`, sur un executor dédié. Jamais d'envoi dans la transaction métier. Toute exception est logguée, jamais propagée.
- **Logs** : l'email est masqué (`a***@domaine.fr`), et aucun token ni aucune URL signée n'apparaît.

---

## 6. Désabonnement (ENGAGEMENT uniquement)

- **Token** : `base64url(userId) + "." + keyVersion + "." + base64url(HMAC-SHA256(secret[keyVersion], "unsub:engagement|" + userId + "|" + keyVersion))`
  - Le serveur lit `userId` et `keyVersion`, recalcule la signature, puis compare à **temps constant** (`MessageDigest.isEqual`).
  - Le **trousseau de clés** vient de l'environnement : la clé courante signe, les anciennes restent acceptées en vérification, pour que les anciens liens survivent aux rotations.
  - Pas d'expiration.
  - Si le user est inconnu ou supprimé, afficher la même page neutre qu'en cas de token invalide.
- **Endpoints** publics, sans authentification :
  - `GET /email/unsubscribe?token=…` : page de **confirmation** avec un bouton, **sans modifier l'état**. Protège contre les scanners de liens.
  - `POST /email/unsubscribe` : passe `engagement_enabled = false` et affiche :
    > Vous ne recevrez plus les conseils et rappels d'entraînement.
    > Les emails indispensables liés à votre compte, votre sécurité ou vos paiements continueront à être envoyés.
  - `POST /email/unsubscribe/one-click?token=…` : cible des en-têtes `List-Unsubscribe` + `List-Unsubscribe-Post: List-Unsubscribe=One-Click` (RFC 8058), ajoutés à tous les mails ENGAGEMENT.
- **Token invalide** : page neutre, sans révéler d'information.
- **Pied des mails ENGAGEMENT** : lien « Ne plus recevoir les conseils et rappels d'entraînement ».
- **Réactivation** : depuis les paramètres du compte (section 8).

---

## 7. Scénarios automatisés

- **Passage** : un scheduler unique, 1 fois par jour (cron en `application.yml`, fuseau `Europe/Paris`), qui délègue à un service central d'automatisation.
- **Tests temporels** : `Clock` injecté partout.
- **Volume** : traitement par lots paginés.

Chaque scénario utilise une **fenêtre bornée**, pour deux raisons :

- tolérer un jour manqué ;
- éviter l'envoi massif rétroactif au premier déploiement.

Dans le tableau ci-dessous, « activité » désigne la dernière activité d'entraînement, dont la source est déterminée en phase 1.

| Type | Condition (tous : user actif, préférence ENGAGEMENT activée) |
|---|---|
| `NO_PREMIUM_AFTER_7_DAYS` | Compte créé entre J-10 et J-7 **et** aucun accès Premium, passé ou actuel |
| `NO_TRAINING_7_DAYS` | Au moins 1 activité passée **et** dernière activité entre J-14 et J-7 |
| `PREMIUM_INACTIVE_2_DAYS` | Accès Premium actif **et** `referenceDate` entre J-5 et J-2, avec `referenceDate = max(dernière activité, début d'accès)` |
| `PREMIUM_ENDING_7_DAYS` | Accès actif, fin dans ]J+2, J+7], accès démarré depuis au moins 3 jours, aucun autre accès prolongeant au-delà |
| `PREMIUM_ENDING_2_DAYS` | Accès actif, fin dans ]now, J+2], aucun autre accès prolongeant au-delà |
| `PREMIUM_ENDED` | Fin dans [J-3, now], aucun autre accès actif ou futur |

Comportement attendu :

- **Inactivité** : **2 rappels au maximum par épisode**, au plus 1 par type. Il faut une nouvelle activité pour ouvrir un nouvel épisode.
  - Premium : `PREMIUM_INACTIVE_2_DAYS` à J+2, puis `NO_TRAINING_7_DAYS` à J+7 si l'utilisateur est toujours inactif, puis plus rien.
  - Non Premium : `NO_TRAINING_7_DAYS` à J+7 uniquement.
  - Exemple : activité le 10, mail J+2 le 12, mail J+7 le 17, puis rien le 19, 24… Nouvelle activité le 20 : nouvel épisode.
- **Priorité** quand le plafond s'applique : `PREMIUM_ENDED` > `ENDING_2` > `ENDING_7` > `PREMIUM_INACTIVE_2_DAYS` > `NO_TRAINING_7_DAYS` > `NO_PREMIUM_AFTER_7_DAYS`.
- **Configuration** : délais, fenêtres, plafond et nombre maximal de tentatives sont externalisés dans un **JSON versionné** (convention du projet), par exemple `email-automation.v1.json`.
- **Multi-instance** : si l'audit révèle plus d'une instance, ajouter ShedLock. L'index unique protège de toute façon contre les doublons.

---

## 8. API préférences

```http
GET /api/me/email-preferences
→ { "engagementEnabled": true, "marketingEnabled": false }
```

```http
PATCH /api/me/email-preferences
{ "engagementEnabled": false }
```

- Passer `marketingEnabled` à `true` renseigne `marketing_consent_at`.
- Aucun champ ne concerne REQUIRED : impossible de désactiver ces mails.
- Front : un toggle « Recevoir les conseils et rappels d'entraînement » dans les paramètres du compte (périmètre à confirmer après l'audit).

---

## 9. Templates

- **Réutiliser** les templates existants, dans le moteur existant, sans imposer de syntaxe.
- **Uniformiser** via un layout commun : logo (URL absolue hébergée), contenu, CTA optionnel, footer, bloc désabonnement affiché **uniquement** si la catégorie est ENGAGEMENT.
- **Contenu** : variables uniquement, aucune logique métier.
- **Format** : multipart HTML + texte brut.
- **Contenu interdit** dans les mails ENGAGEMENT, et en particulier `NO_PREMIUM_AFTER_7_DAYS` et `PREMIUM_ENDED` : aucun prix, remise, « offre » ou urgence commerciale. Ton informatif et d'accompagnement uniquement.

| Type | Variables attendues |
|---|---|
| `WELCOME` | `firstName`, `appUrl` |
| `PREMIUM_ACCESS_STARTED` | `firstName`, `offerName`, `accessStartDate`, `accessEndDate` |
| `PASSWORD_RESET` | `firstName`, `resetUrl`, `expiresInMinutes` |
| `PASSWORD_CHANGED` | `firstName`, `changedAt`, `supportUrl` (« Si vous n'êtes pas à l'origine… ») |
| `DIAGNOSTIC_PLAN_READY` | `firstName`, `diagnosticType`, `planUrl`, `priority1`, `priority2`, `priority3` (pas le plan complet) |
| `NO_TRAINING_7_DAYS` / `PREMIUM_INACTIVE_2_DAYS` | `firstName`, `resumeUrl`, `nextStepLabel` si disponible |
| `PREMIUM_ENDING_*` | `firstName`, `accessEndDate` |
| `PREMIUM_ENDED` | `firstName`, `dashboardUrl` (« Votre progression et vos résultats restent disponibles. ») |

Les templates manquants sont à créer dans le même layout.

---

## 10. Tests minimum

| Domaine | Cas |
|---|---|
| Catégories | REQUIRED envoyé même si engagement désactivé. ENGAGEMENT envoyé si activé, bloqué sinon (`SKIPPED`). MARKETING bloqué par défaut |
| Anti-doublon | Même clé → 1 envoi. Deux appels concurrents → 1 seul SENT. FAILED puis nouvelle tentative autorisée, 3 au maximum |
| Plafond | 2 scénarios éligibles le même jour → seul le prioritaire part, l'autre part le lendemain |
| Relance | SMTP en échec puis rétabli → le mail REQUIRED part via la relance immédiate. `PASSWORD_RESET` en FAILED → jamais relancé par le scheduler. `PASSWORD_CHANGED` en FAILED → relancé dans les 24 h, pas au-delà |
| Inactivité | Premium : J+2 puis J+7, jamais un 3ᵉ. Non Premium : J+7 seul. Nouvelle activité → nouvel épisode → rappels à nouveau possibles |
| Token | Signature valide avec une ancienne `keyVersion` → accepté. Signature altérée → refus neutre |
| Accès Premium | ENDING_7, ENDING_2 et ENDED envoyés une fois chacun. Aucun si un autre accès prolonge. Jour manqué rattrapé dans la fenêtre |
| Déploiement | Anciens users hors fenêtre → aucun envoi |
| Transaction | Rollback de l'inscription → pas de WELCOME. Échec SMTP → l'inscription réussit quand même |
| Désabonnement | GET ne modifie rien. POST avec token valide → engagement désactivé. Token falsifié → refus neutre. One-click fonctionnel |
| PENDING bloqué | PENDING de plus d'1 h → FAILED |

`EmailSender` est mocké dans les tests unitaires. GreenMail est optionnel pour l'intégration Spring Mail.

---

## 11. Hors périmètre (à préparer, ne pas implémenter)

- `BrevoEmailSender` et son appel API (`templateId` + `params`).
- Webhooks Brevo (bounces, désabonnements Brevo à synchroniser vers `user_email_preferences`) : la colonne `provider_message_id` est prévue pour ça.
- Mails MARKETING, UI admin, purge RGPD de `email_deliveries` (proposer une durée de rétention dans le rapport d'audit).

## Critère de réussite

Passer à Brevo = créer `BrevoEmailSender`, renseigner les `brevo-template-id` et passer `email.provider: brevo`. **Aucune** modification des règles, du scheduler, des événements, des préférences, du désabonnement ni de l'anti-doublon.
