# Système d'emails — rapport final (phases 2 → 4)

Date : 2026-09-25, branche `feature/refonte-l1-socle`. Autorité : `REPONSES_AUDIT_emails.md`.
Règle métier : `docs/regles/emails.md`. Décisions : `docs/email/decisions.md`.
Rien n'a été poussé ni déployé ; aucun mail réel n'a été envoyé (tests : `RecordingEmailSender`).

## Ce qui est fait

### Phase 2 — socle (commit `b04069e3`)
- **V073** : `user_email_preferences`, `email_deliveries` (+ `occurred_at`, `reference_id`,
  `skip_reason`, `attempt_count`, `user_id` nullable), index unique **partiel** d'anti-doublon
  (`PENDING/SENT/SKIPPED`, décision D-1), index de plafond, de balayage et de purge ; vue
  **`v_derniere_activite_entrainement`** (les 4 actes du candidat) + 3 index d'activité.
- **Socle `service/email/`** : `EmailType` (catégorie, relance différée, exemption de plafond),
  port `EmailSender` + `SpringMailEmailSender` (seul détenteur de `JavaMailSender`, multipart
  HTML + texte, layout commun, logo par URL, `List-Unsubscribe` RFC 8058), gabarits résolus par
  la configuration (`sejourfr.email.templates`), `EmailService` (catégorie → préférences →
  plafond jour Europe/Paris → tentatives → allowlist dev → INSERT PENDING → envoi + relance
  immédiate à `Sleeper` injectable → SENT/FAILED), `emailTaskExecutor` dédié et borné (rejet →
  FAILED), config versionnée `email/email-automation-config-v1.json` à chargeur validant,
  `Clock` injectable.
- **Événements AFTER_COMMIT** via `EmailDispatcher` : `WELCOME` (inscription locale + sociale),
  `DIAGNOSTIC_PLAN_READY` aux 4 points de clôture (dont la clôture paresseuse pendant un GET) ;
  adoption civique = clé consommée (`SKIPPED / KEY_CONSUMED`).
- **Désabonnement** : jeton HMAC à trousseau, `GET/POST /api/public/email/unsubscribe` et
  `/one-click`, pages backend, rate-limit.
- **Sécurité** : S1 (adresses masquées), S2 (`LogMask.token`), S3/S4 (hors transaction et hors
  thread de requête). Dev : allowlist obligatoire (vide = rien ne part), scénarios éteints ;
  documentation MailHog corrigée.
- Suppression de compte : journal (y compris les mails envoyés à son adresse sans compte) et
  préférences purgés.

### Phase 3 — mails événementiels et préférences (commit `c06a9449`)
- `PREMIUM_ACCESS_STARTED` / `PREMIUM_ACCESS_EXTENDED` (octroi effectif, `OneTimeAccessService`),
  `PREMIUM_SUBSCRIPTION_CANCELED` (dormant), `PASSWORD_RESET`, `PASSWORD_CHANGED` (reset appliqué
  **et** changement connecté), `EMAIL_CHANGE_CONFIRMATION`, `EMAIL_CHANGED` (ancienne adresse,
  nouvelle masquée), `CONTACT_RECEIVED`, `SUPPORT_REPLY` ; composeurs qui relisent la source.
- Relais contact → support : synchrone, par le port, sans journal ; échec absorbé par `ContactService` (B-1, clos en revue : statu quo).
- `GET/PATCH /api/me/email-preferences` ; pages **« Notifications par e-mail »** web
  (`/profil/notifications`) ⇄ mobile (`/profile/notifications`), un interrupteur, libellés
  miroirs mot pour mot, nouvelles briques `CompteToggleRow` ⇄ `AccountSwitch`.
- Politique de confidentialité : e-mails d'accompagnement (finalité, base légale, désinscription,
  un par jour au plus), journal conservé 12 mois et supprimé avec le compte ; date des documents
  légaux avancée (D-21).

### Phase 4 — automatisation (commit de ce rapport)
- `EmailAutomationJob` : scénarios quotidiens (9 h Europe/Paris, désactivables), maintenance
  horaire (PENDING > 1 h → FAILED, relance différée des mails événementiels dans les 24 h,
  jamais `PASSWORD_RESET` / `EMAIL_CHANGE_CONFIRMATION`), purge de rétention quotidienne.
- `EmailAutomationService` : `NO_PREMIUM_AFTER_7_DAYS`, `NO_TRAINING_7_DAYS`,
  `PREMIUM_INACTIVE_2_DAYS`, `PREMIUM_ENDING_7_DAYS`, `PREMIUM_ENDING_2_DAYS`, `PREMIUM_ENDED` —
  fenêtres bornées, épisodes, priorité sous plafond, pagination à jeu de clés, accès de chaque
  page en une requête, abonnements récurrents dormants exclus, libellé de fin selon le module
  calculé en Java (`PremiumAccessEndResolver`), CTA « Mon pass », aucun prix ni urgence.
- **Supprimés** : `ExpiryReminderJob` (+ test), `MailService` (+ test), gabarits `mail/`, logo
  CID `static/mail/logo.png`, requête `findOneTimeExpiringSoon`, clé YAML morte
  `sejourfr.mail.from`. `expiry_reminded_at` reste en base, plus écrite (D-29).

## Résultats des tests

| Moment | Unitaires (surefire) | Intégration (failsafe) |
|---|---|---|
| Référence avant chantier | 3 104 verts (2 ignorés) | 1 517 verts |
| Fin de phase 2 | 3 172 verts | 1 552 verts |
| Fin de phase 3 (build propre) | 3 172 verts | 1 549 verts |
| **Fin de phase 4 (build propre)** | **3 180 verts, 0 échec (2 ignorés)** | **1 572 verts, 0 échec** |

Les décomptes des phases 1-2 viennent d'un répertoire `target/` non nettoyé (rapports de classes
renommées ou supprimées inclus) ; ceux des phases 3-4 d'un build propre. Fronts (phase 3, seule
phase qui les touche) : web `tsc --noEmit` OK, `npm run build` OK, `npm test` 267/267 ; mobile
`flutter analyze` 0 problème, `flutter test` 296/296. **Aucun test front ajouté.**

Couverture de la matrice du brief §10 : catégories (REQUIRED malgré désabonnement, ENGAGEMENT
tracé SKIPPED, MARKETING refusé par défaut), anti-doublon (même clé, concurrence, FAILED puis
3 relances au plus), plafond (prioritaire le jour J, l'autre le lendemain ; `DIAGNOSTIC_PLAN_READY`
jamais plafonné mais consommateur), relance (immédiate qui réussit, `PASSWORD_RESET` jamais
relancé, `PASSWORD_CHANGED` relancé dans les 24 h et pas au-delà), inactivité (Premium J+2 puis
J+7 jamais un 3ᵉ, non Premium J+7 seul, nouvel épisode), jeton (ancienne clé acceptée, signature
altérée refusée), accès (ENDING_7/ENDING_2/ENDED une fois chacun, prolongation, jour manqué,
libellé TCF/Civique/Intégral, dormant exclu, remboursé exclu), déploiement (hors fenêtre → rien),
transaction (rollback → pas de WELCOME, SMTP en panne → inscription réussie), désabonnement (GET
sans effet, POST, falsifié, one-click, compte supprimé), PENDING bloqué. En plus : un test IT par
point de publication d'événement (complément D) et le **rendu réel de chaque mail composé** en IT
sans placeholder résiduel (D-24).

## Décisions

`docs/email/decisions.md` : **36 décisions, dont 9 structurantes** (D-1 à D-7, D-25 et D-32),
27 mineures — les 31 premières validées en revue, D-32 à D-36 issues de la revue.

## Blocage

- **B-1 — relais du formulaire de contact** : **clos** en revue (statu quo). La conversation
  enregistrée fait foi ; l'échec du relais est absorbé (log masqué), le visiteur voit un succès.

## Sujets séparés (non traités, interdits sans accord)

SS-1 vérification `payment_status == "paid"` côté Stripe ; SS-2 endpoint newsletter absent
(footer) ; SS-3 S5 (`GET confirm-email-change` modifie l'état) ; SS-4 S6 (jetons dans les journaux
Nginx) ; SS-5 liens universels mobiles ; SS-6 `BrevoEmailSender` et webhooks Brevo (templates Brevo : reproduire D-32 par des conditions, cf. `decisions.md`).

## Avant le prochain déploiement

- 🛑 Poser **`EMAIL_UNSUBSCRIBE_KEY_V1`** (secret aléatoire, ≥ 32 octets) sur le VPS : sans elle
  le backend ne démarre pas (D-6).
- Vérifier `MAIL_FROM` (l'expéditeur devient « SejourFR <MAIL_FROM> ») et que
  `https://sejourfr.fr/logo_sejourFR.png` est servi.
- Les scénarios démarrent le lendemain 9 h ; leurs fenêtres bornées empêchent tout envoi
  rétroactif aux anciens comptes.

## Écarts avec le brief

- Index anti-doublon élargi à `SKIPPED` (D-1) ; relance différée événementielle par une passe
  **horaire** (D-2) ; soumission explicite à l'executor plutôt qu'`@Async` (D-3).
- Configuration sous `sejourfr.email.*` et `email/email-automation-config-v1.json` (conventions du
  dépôt, D-8) ; routes publiques sous `/api/public/email/…` (arbitrage n°12).
- `EmailMessage` porte aussi l'URL one-click (D-11) ; variable `greeting` en plus de `firstName`
  (D-13).
- `nextStepLabel` non servi en V1 (D-27). `CONTACT_RECEIVED` sans relance différée (D-20).
- Types ajoutés au brief, validés par les arbitrages : `PREMIUM_ACCESS_EXTENDED`,
  `PREMIUM_SUBSCRIPTION_CANCELED`, `EMAIL_CHANGE_CONFIRMATION`, `EMAIL_CHANGED`,
  `CONTACT_RECEIVED`, `SUPPORT_REPLY`.

## Corrections de revue (2026-09-25)

Toutes les décisions D-1 → D-31 validées par le propriétaire, sous réserve des corrections
suivantes, faites dans un commit dédié :

- **B-1 clos** : statu quo (voir plus haut) ; invariant 3 de `docs/regles/emails.md` reformulé —
  le relais n'est pas une exception, son erreur est absorbée délibérément par `ContactService`.
- **D-17 vérifiée** : nouveau test d'intégration du cas nominal (rapide TCF clos par le pipeline,
  Plan jamais ouvert, aucune épingle) : le mail porte **exactement** les priorités que le Plan
  sert ensuite. Constat : les priorités étaient bien présentes, la lecture seule suffit, aucune
  lecture pure supplémentaire n'a été écrite. Sans priorité, le bloc « Vos premières priorités »
  disparaît **entier** du HTML et du texte (règle de rendu D-32, testée).
- **Pass courts (D-33)** : `PREMIUM_ENDING_7_DAYS` exige un accès d'au moins 14 jours
  (`minAccessDurationDays`, config versionnée validée par le chargeur). Un pass 7 jours reçoit
  `ENDING_2` puis `ENDED`, jamais `ENDING_7` (testé). Aucun délai écrit en dur dans un mail
  ENGAGEMENT (D-34, testé) : deux gabarits corrigés (« une semaine »).
- **Horloge des tests (D-35)** : plus de date 2027 fixe ; instant de référence = horloge
  d'exécution + 365 jours. Infrastructure de test partagée non modifiée.
- **Tests front (D-36)**, à la demande explicite du propriétaire (exception à « aucun nouveau
  test front », notée dans les deux `CLAUDE.md` des fronts) : web `lib/notifications.test.ts`
  (logique extraite dans `lib/notifications.ts`), mobile `test/notifications_screen_test.dart`
  — chargement, bascule optimiste dans les deux sens, succès, erreur API, retour arrière + erreur.
  Aucune dépendance ajoutée.

Résultats après corrections (build propre) : backend **3 186 unitaires** (2 ignorés) et
**1 575 d'intégration**, 0 échec ; web `tsc` OK, `build` OK, **275/275** tests ; mobile
`flutter analyze` 0 problème, **303/303** tests.
