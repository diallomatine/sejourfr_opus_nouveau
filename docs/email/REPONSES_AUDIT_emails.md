# Réponses du propriétaire à l'audit phase 1 — système d'emails

Date : 2026-09-25. Verbatim des arbitrages du propriétaire sur `AUDIT_emails_phase1.md` (§8). Autorité pour les phases 2 → 4.

Audit validé. Très bon travail, notamment sur les sources de vérité, l'activité réelle, les prolongations de pass, les transactions et les risques dev.
Tu peux passer à la phase 2 avec les décisions suivantes.

## 1. Activité d'entraînement
Validé : utiliser les 4 actes candidat :
- réponse QCM ;
- production EE/EO ;
- petit sujet compétence ;
- session orale réellement connectée.

Diagnostics et examens blancs inclus.
Créer la vue SQL unique proposée. Ne pas utiliser `attempts.started_at` / `finished_at`.

## 2. Utilisateur jamais entraîné
Pas de nouveau scénario pour la V1.
Il recevra éventuellement `NO_PREMIUM_AFTER_7_DAYS`.
On pourra ajouter plus tard un scénario `TRAINING_NEVER_STARTED` si les données montrent que c'est utile.

## 3. Pass Civique = Premium
Oui. Un accès Civique est bien un accès Premium.
Pour les mails de fin, attention cependant au wording : si un utilisateur conserve Civique mais perd TCF, ne pas écrire génériquement « votre accès Premium se termine ».
Le mail doit pouvoir indiquer ce qui se termine réellement, par exemple :
- « Votre accès TCF se termine… »
- « Votre accès Civique se termine… »
- ou « Votre pass Intégral se termine… »

Réutiliser la logique de couverture des modules existante.

## 4. Prolongation
Validé : créer un type distinct `PREMIUM_ACCESS_EXTENDED` et garder `PREMIUM_ACCESS_STARTED` pour le premier accès.
`offerName = plans.name` est OK et le mot pass est le bon vocabulaire côté utilisateur.

## 5. Abonnements récurrents dormants
Validé. Les exclure des scénarios `PREMIUM_ENDING_*` et `PREMIUM_ENDED`.
Conserver le code dormant et le type `PREMIUM_SUBSCRIPTION_CANCELED`.

## 6. Ancien ExpiryReminderJob
Validé : il sera supprimé lorsque les nouveaux scénarios seront fonctionnels.
`expiry_reminded_at` reste en base mais n'est plus utilisé.
Les mails `PREMIUM_ENDING_*` peuvent avoir un CTA vers « Mon pass » / la page de gestion de l'accès.
Ne pas pointer directement vers `/paiement` et ne pas mettre de prix, remise ou urgence commerciale.

## 7. DIAGNOSTIC_PLAN_READY
Validé : envoyer le mail lorsque le diagnostic rend un Plan disponible pour la première fois sur le module. Donc :
- TCF rapide terminé ;
- ou TCF complet si aucun plan TCF n'existait auparavant ;
- diagnostic Civique terminé ;
- adoption d'un diagnostic invité si cette adoption rend le Plan disponible (voir complément C, qui précise ce point).

Ne pas renvoyer le mail lorsqu'un diagnostic complet vient seulement affiner un Plan existant.
Une fois maximum par module.

## 8. PASSWORD_CHANGED
Oui, dans les deux cas : changement connecté ; mot de passe changé à la suite d'un reset.
La proposition `occurred_at` dans `email_deliveries` est validée.

## 9. Mails existants hors brief
Validé. Les faire passer eux aussi progressivement par `EmailSender`. Types :
- `EMAIL_CHANGE_CONFIRMATION`
- `CONTACT_RECEIVED`
- `SUPPORT_REPLY`

Le relais du formulaire de contact vers le support reste synchrone et doit continuer à remonter l'échec à l'utilisateur.
Pas besoin de `email_deliveries` pour ce relais interne.

## 10. Notification à l'ancienne adresse après changement d'email
Oui. Ajouter `EMAIL_CHANGED` REQUIRED envoyé à l'ancienne adresse après changement effectif. À faire en phase 3.

## 11. Environnement dev
Mettre `sejourfr.email.automation.enabled=false` par défaut en dev.
Ajouter également une allowlist de destinataires en dev afin qu'un nouveau mail ajouté au système ne puisse pas accidentellement partir vers un vrai utilisateur.
Une allowlist vide doit bloquer les emails utilisateurs en dev tant qu'elle n'est pas explicitement configurée.
Corriger également la documentation MailHog devenue fausse.

## 12. Endpoint désabonnement
Validé : `/api/public/email/unsubscribe` et `/api/public/email/unsubscribe/one-click`.
Utiliser le mécanisme de page HTML backend existant.

## 13. Préférences email
Je valide la page dédiée « Notifications par e-mail » dans Mon compte, web + mobile.
Pour la V1 : un seul toggle visible : « Recevoir les conseils et rappels d'entraînement ».
La préférence marketing reste préparée côté backend mais n'a pas besoin d'être affichée tant qu'on n'utilise pas de mails marketing.

## 14. Liens mobile
Web uniquement pour ce chantier. Les universal links / app links seront traités séparément.

## 15. Newsletter footer
Hors périmètre de ce chantier. Ne pas modifier le footer dans les phases email.
Documenter simplement que l'endpoint n'existe pas afin qu'on le traite séparément.

## 16. Rétention email_deliveries
12 mois validés. Suppression également lors de l'anonymisation/suppression du compte.
Mettre à jour la politique de confidentialité dans la phase prévue.

## 17. Retry immédiat
Je préfère la solution la plus simple et testable : boucle explicite avec `Sleeper` injectable + délais venant de la configuration.
Utiliser impérativement `emailTaskExecutor` dédié et borné.
Ne pas modifier les mécanismes de retry existants des autres sous-systèmes.

## 18. Plafond ENGAGEMENT
Valider un plafond par jour calendaire Europe/Paris, pas une fenêtre glissante de 24 h.
`DIAGNOSTIC_PLAN_READY` est directement provoqué par une action importante du candidat : il ne doit jamais être bloqué par ce plafond.
En revanche, il compte comme un ENGAGEMENT déjà envoyé pour empêcher un scheduler exécuté ensuite dans la même journée d'ajouter un rappel automatique.
Si un rappel automatique est déjà parti plus tôt dans la journée, `DIAGNOSTIC_PLAN_READY` peut quand même partir. C'est assumé.
Donc le plafond concerne surtout les rappels automatisés, pas les mails directement consécutifs à une action utilisateur.

## 19. PREMIUM_INACTIVE_2_DAYS
Validé : `referenceDate = max(dernière activité, starts_at de l'accès couvrant le plus récent)`.
Un nouvel achat/prolongement représente bien une nouvelle intention d'utilisation.

## 20. Paiement Stripe
Ne modifie pas le workflow de paiement dans ce chantier email. Documenter le risque séparément.
Pour les emails, déclencher `PREMIUM_ACCESS_STARTED` uniquement lorsque le système considère effectivement l'accès comme accordé.
On traitera séparément la vérification `payment_status == paid` si les moyens de paiement différés sont ou deviennent activés.

## Sécurité
Profiter du chantier pour corriger immédiatement les éléments directement touchés :
- S1 : masquer les emails dans les logs ;
- S3/S4 : AFTER_COMMIT + async ;
- ne jamais sérialiser/logguer les événements contenant un token brut.

S2, S5 et S6 peuvent être documentés comme sujets séparés sauf si leur correction est triviale et sans impact fonctionnel (S2 : voir complément H).

## Phase 2
GO pour la phase 2 selon le plan proposé : `V073`, vue activité, socle emails, executor dédié, préférences, deliveries / anti-doublon, token désabonnement, `WELCOME`, `DIAGNOSTIC_PLAN_READY`, tests associés.

## Compléments

**A. Endpoints de désabonnement remontés en phase 2.** `GET/POST /api/public/email/unsubscribe` + `/one-click` passent en phase 2 : `DIAGNOSTIC_PLAN_READY` et l'en-tête `List-Unsubscribe` y pointent déjà. Aucun lien mort, même en dev. L'API `/api/me/email-preferences` et les pages front restent en phase 3.

**B. Clé `DIAGNOSTIC_PLAN_READY`.** `DIAGNOSTIC_PLAN_READY:{userId}:{module}` (module ∈ {TCF, CIVIQUE}). C'est ce qui garantit « une fois maximum par module », quelle que soit la session qui ouvre le Plan.

**C. Adoption d'un diagnostic invité.** Pas de `DIAGNOSTIC_PLAN_READY` à l'adoption : le candidat est dans l'app, sur son Plan, et reçoit déjà WELCOME. En revanche, la clé du point B est quand même consommée (ligne `SKIPPED`), pour qu'un diagnostic ultérieur sur ce module ne déclenche pas le mail.

**D. Événements hors transaction.** Un `@TransactionalEventListener` sans transaction active perd l'événement en silence. Vérifie chaque point de publication (en particulier `cloturerSiAttemptTermine`, appelé pendant un GET) et couvre chaque chemin par un test IT. N'active pas `fallbackExecution = true` par défaut ; si un chemin en a besoin, signale-le.

**E. Rejet de `emailTaskExecutor`.** Pas de `CallerRunsPolicy` : la boucle de retry ne doit jamais tourner dans un thread de requête. En cas de rejet, log masqué + ligne `FAILED`, reprise par la relance différée (sauf `PASSWORD_RESET` et `EMAIL_CHANGE_CONFIRMATION`).

**F. Libellé de fin d'accès.** Le moteur n'a pas de conditions : le libellé « Votre accès TCF / Civique / pass Intégral » et la phrase éventuelle « Votre accès Civique reste actif jusqu'au … » sont calculés en Java et passés en variables plates.

**G. Allowlist dev.** Un mail bloqué par l'allowlist est enregistré `SKIPPED` avec la raison, pour rester visible.

**H. S2.** Corrige-le maintenant (`LogMask.token`), c'est une ligne.

## Mode d'exécution : jusqu'au bout

Enchaîne les phases 2, 3 et 4 sans t'arrêter. Les STOP du brief sont levés.

**Entre chaque phase :** tous les tests passent (existants + nouveaux) avant de passer à la phase suivante. Un commit par phase, message explicite (`feat(email): phase 2 — socle…`).

**Décisions :** chaque fois qu'il faut trancher un point non couvert par le brief, l'audit ou ces réponses : choisir la meilleure option, l'implémenter, la consigner dans `docs/email/decisions.md`. Une décision ne doit jamais contredire une décision déjà validée ; si c'est inévitable, c'est un blocage.

Format de chaque entrée :

    ## D-<n> — <titre court>
    - Phase : 2 | 3 | 4
    - Importance : structurante | mineure
    - Contexte : <1-2 phrases>
    - Options : A) … B) … (C) …)
    - Choix : <option> — <pourquoi>
    - Réversibilité : facile | coûteuse — <ce qu'il faudrait changer>
    - Fichiers : <chemins>

Les décisions structurantes vont en tête du fichier.

**Interdit sans accord du propriétaire** (le noter dans la section « Sujets séparés » et continuer) :
- modifier le workflow de paiement, les autres mécanismes de retry ou le footer newsletter ;
- toute migration destructive (DROP, suppression de colonne, modification de données existantes) ;
- déployer, ou envoyer un mail réel hors allowlist.

**Blocage réel :** si une décision validée rend impossible une partie du travail, s'arrêter uniquement sur cette partie, la documenter et continuer le reste.

**À la fin**, livrer `docs/email/RAPPORT_FINAL.md` : ce qui est fait phase par phase ; le résultat des tests ; le renvoi vers `decisions.md` (avec le nombre de décisions structurantes) ; les sujets séparés ; les écarts éventuels avec le brief.
