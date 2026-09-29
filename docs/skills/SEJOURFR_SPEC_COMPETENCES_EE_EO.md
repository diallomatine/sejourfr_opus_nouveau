# SejourFR — Spécification du module « Compétences TCF »

## 1. Objectif du document

Ce document sert de spécification fonctionnelle et technique pour intégrer dans SejourFR un module d'entraînement ciblé aux compétences de production du TCF.

Le prototype HTML fourni sert de référence visuelle et interactive :

- `sejourfr_expression_ecrite_v3_competences.html`

Le module doit couvrir :

- l'expression écrite : EE1, EE2, EE3 ;
- l'expression orale : EO1, EO2, EO3 ;
- **8 compétences maximum par tâche** ;
- plusieurs petits sujets de production ouverte pour chaque compétence ;
- une progression visible sujet par sujet ;
- une analyse IA courte, ciblée et pédagogique.

---

## 2. Positionnement pédagogique

Le module n'est pas un cours général de français et ne doit pas ressembler à Duolingo.

Il ne faut pas proposer comme exercice principal :

- remettre des mots dans l'ordre ;
- sélectionner une réponse parmi plusieurs choix ;
- compléter mécaniquement une phrase ;
- réciter une réponse modèle.

Le candidat doit **produire lui-même** une phrase, un court texte ou une réponse orale à partir d'un contexte.

Le but est de lui faire comprendre ce qui rend une réponse efficace au TCF :

- accomplir la consigne ;
- être compréhensible ;
- donner suffisamment d'informations ;
- structurer sa réponse ;
- développer progressivement sa production.

Une phrase peut être grammaticalement correcte tout en restant insuffisante pour le TCF.

### Principe central

> Une compétence → plusieurs petits sujets → un critère unique par sujet → une production ouverte → une comparaison → un retour IA simple.

---

## 3. Architecture de navigation

### Niveau 1 — Choix de l'épreuve

- Expression écrite
- Expression orale

### Niveau 2 — Choix de la tâche

Pour chaque épreuve :

- Tâche 1
- Tâche 2
- Tâche 3

### Niveau 3 — Deux espaces dans chaque tâche

1. **Sujets TCF complets**
2. **Compétences à travailler**

Les sujets TCF complets déjà présents dans l'application restent disponibles. Ils ne doivent pas être remplacés par les exercices de compétences.

### Niveau 4 — Une compétence

Lorsqu'un candidat ouvre une compétence, afficher :

- son titre ;
- une courte explication ;
- le critère général travaillé ;
- la progression : `X sujets traités / Y` ;
- la liste de tous ses petits sujets ;
- le statut de chaque petit sujet.

### Niveau 5 — Un petit sujet

Lorsqu'un candidat ouvre un petit sujet, afficher :

- la tâche TCF associée ;
- le nom de la compétence ;
- le numéro ou le palier du sujet ;
- le contexte ;
- la consigne ;
- le **critère unique** évalué ;
- la longueur ou la durée conseillée ;
- la zone de production écrite ou l'enregistreur audio ;
- le compteur de mots pour EE ;
- la durée de l'enregistrement pour EO ;
- une auto-évaluation facultative ;
- le bouton de validation.

Les exemples de référence ne doivent apparaître **qu'après la production**.

---

## 4. Statuts et progression

Chaque petit sujet doit avoir l'un des statuts suivants :

```text
TODO          = jamais traité
VALIDATED     = traité et critère globalement validé
TO_REINFORCE  = traité mais critère encore fragile
```

Pour chaque sujet, conserver au minimum :

```text
status
attemptCount
lastAttemptAt
lastProduction
lastAiEvaluation
```

### Affichage attendu dans la liste

- **À faire** : sujet jamais traité ;
- **Validé** : critère acquis sur la dernière tentative ;
- **À renforcer** : sujet traité, mais critère partiellement atteint ;
- nombre de tentatives ;
- date de la dernière tentative.

### Navigation après une tentative

Afficher trois actions :

1. `Retour aux petits sujets`
2. `Refaire ce sujet`
3. `Sujet suivant à travailler`

Le bouton `Sujet suivant à travailler` doit ouvrir en priorité le premier sujet non traité de la compétence.

### Persistance

Pour le prototype, `localStorage` est acceptable.

Pour l'application réelle, la progression doit être enregistrée côté backend et liée à l'utilisateur.

---

# 5. Compétences retenues — Expression écrite

## EE1 — Écrire un message court

Niveau principalement visé : A1–A2.

### EE1-C1 — Adapter le message au destinataire

Savoir choisir une formule, un ton et un niveau de politesse adaptés : ami, voisin, collègue, administration, responsable.

**Exemple de petit sujet :**

> Vous écrivez à votre propriétaire pour signaler un problème. Formulez la première phrase du message.

### EE1-C2 — Annoncer clairement l'objet du message

Faire comprendre immédiatement pourquoi on écrit : informer, prévenir, annuler, remercier, demander ou répondre.

**Exemple :**

> Vous ne pourrez pas venir à un rendez-vous. Écrivez une phrase qui annonce clairement l'annulation.

### EE1-C3 — Donner des informations pratiques précises

Indiquer correctement une date, une heure, un lieu, une personne, une quantité ou une modalité.

**Exemple :**

> Informez un ami du lieu et de l'heure de votre fête en une ou deux phrases.

### EE1-C4 — Formuler une demande polie

Demander une information, une aide, un document, une autorisation ou un service de manière claire.

**Exemple :**

> Demandez à votre responsable de modifier votre horaire de travail.

### EE1-C5 — Inviter, proposer, accepter ou refuser

Formuler une invitation ou une proposition et répondre clairement à celle d'une autre personne.

**Exemple :**

> Invitez un voisin à participer à une activité organisée samedi.

### EE1-C6 — S'excuser et expliquer une raison

Présenter une excuse compréhensible et donner une cause suffisante sans écrire un récit trop long.

**Exemple :**

> Excusez-vous auprès d'un ami et expliquez pourquoi vous arriverez en retard.

### EE1-C7 — Décrire simplement une personne, un lieu ou une situation

Donner quelques caractéristiques utiles et compréhensibles adaptées au contexte du message.

**Exemple :**

> Décrivez brièvement le logement que vous proposez à un ami.

### EE1-C8 — Relier les informations dans un message complet

Enchaîner plusieurs phrases simples et terminer le message naturellement.

**Exemple :**

> Écrivez trois phrases pour prévenir d'un changement, donner la nouvelle information et terminer poliment.

---

## EE2 — Raconter une expérience

Niveau principalement visé : A2–B1.

### EE2-C1 — Situer le moment et le lieu

Donner un repère temporel et spatial clair dès le début du récit.

**Exemple :**

> Commencez le récit d'une sortie qui a eu lieu la semaine dernière.

### EE2-C2 — Présenter la situation initiale

Expliquer où l'on était, avec qui et ce que l'on faisait avant l'événement principal.

**Exemple :**

> Présentez en deux phrases le début d'une fête organisée dans votre quartier.

### EE2-C3 — Utiliser les temps du passé de manière compréhensible

Employer le passé composé et, lorsque nécessaire, l'imparfait pour distinguer les actions et le contexte.

**Exemple :**

> Racontez une action terminée pendant qu'une autre situation était en cours.

### EE2-C4 — Introduire un événement déclencheur

Faire apparaître clairement le changement, le problème ou l'événement inattendu.

**Exemple :**

> Ajoutez une phrase commençant par « Soudain » pour introduire un problème.

### EE2-C5 — Raconter les actions dans l'ordre

Organiser les événements avec des connecteurs temporels simples et naturels.

**Exemple :**

> Racontez en trois phrases ce qui s'est passé d'abord, ensuite et finalement.

### EE2-C6 — Ajouter des détails utiles

Préciser les personnes, les actions, l'environnement ou les circonstances sans s'éloigner du sujet.

**Exemple :**

> Enrichissez le récit d'un train raté avec un détail concret sur la gare ou le voyage.

### EE2-C7 — Exprimer une réaction ou un ressenti

Dire ce que l'on a pensé ou ressenti et relier ce ressenti à la situation vécue.

**Exemple :**

> Expliquez en deux phrases comment vous vous êtes senti après avoir perdu un objet important.

### EE2-C8 — Terminer par le résultat ou la conséquence

Expliquer comment la situation s'est terminée et ce qu'elle a changé.

**Exemple :**

> Écrivez la fin d'un récit dans lequel un problème a finalement été résolu.

---

## EE3 — Donner son opinion

Niveau principalement visé : B1–B2.

### EE3-C1 — Exprimer une position claire

Répondre directement à la question et rendre son avis identifiable dès le début.

**Exemple :**

> Donnez clairement votre avis sur le télétravail en une phrase.

### EE3-C2 — Donner un argument pertinent

Présenter une raison directement liée à l'opinion annoncée.

**Exemple :**

> Donnez une raison précise pour expliquer pourquoi les transports publics sont utiles.

### EE3-C3 — Développer un argument

Expliquer comment ou pourquoi l'argument soutient la position, au lieu de simplement l'énumérer.

**Exemple :**

> Développez en deux phrases l'idée suivante : « vivre en ville est pratique ».

### EE3-C4 — Illustrer avec un exemple concret

Ajouter un exemple personnel, quotidien ou vraisemblable qui rend l'argument plus clair.

**Exemple :**

> Donnez un exemple concret montrant l'utilité d'apprendre le français.

### EE3-C5 — Ajouter un deuxième argument distinct

Enrichir la réponse avec une nouvelle raison sans répéter la première.

**Exemple :**

> Ajoutez un second argument différent en faveur du sport à l'école.

### EE3-C6 — Comparer des possibilités ou présenter avantages et inconvénients

Mettre en relation deux choix et faire apparaître leurs différences utiles.

**Exemple :**

> Comparez en trois phrases le travail à domicile et le travail au bureau.

### EE3-C7 — Nuancer ou concéder

Reconnaître une limite, une exception ou un avis opposé tout en conservant une position claire.

**Exemple :**

> Nuancez une opinion positive sur les réseaux sociaux en ajoutant une limite.

### EE3-C8 — Organiser et conclure une réponse argumentée

Relier les idées avec des connecteurs logiques et terminer par une conclusion cohérente.

**Exemple :**

> Écrivez trois phrases avec un argument, une conséquence et une conclusion.

---

# 6. Compétences retenues — Expression orale

## EO1 — Entretien dirigé : parler de soi

Niveau principalement visé : A2.

### EO1-C1 — Se présenter avec les informations essentielles

Donner une présentation personnelle courte, claire et adaptée à la question.

**Exemple de petit sujet :**

> Présentez-vous en indiquant votre prénom, votre situation et votre ville.

### EO1-C2 — Répondre directement à une question personnelle

Éviter les réponses hors sujet ou limitées à « oui », « non » ou un seul mot.

**Exemple :**

> « Est-ce que vous aimez votre quartier ? » Répondez directement et expliquez brièvement.

### EO1-C3 — Développer une réponse avec une précision

Ajouter un détail utile : quand, où, avec qui, à quelle fréquence ou pourquoi.

**Exemple :**

> « Que faites-vous le week-end ? » Donnez une activité et une précision.

### EO1-C4 — Parler de son quotidien

Décrire ses habitudes, ses horaires ou une journée habituelle dans un ordre compréhensible.

**Exemple :**

> Expliquez ce que vous faites habituellement le matin.

### EO1-C5 — Décrire son entourage ou son environnement

Parler simplement de sa famille, de son logement, de son quartier ou de son lieu de travail.

**Exemple :**

> Décrivez votre quartier avec deux informations concrètes.

### EO1-C6 — Raconter brièvement une expérience passée

Répondre à une question personnelle en racontant un événement court et compréhensible.

**Exemple :**

> Parlez d'une sortie que vous avez faite récemment.

### EO1-C7 — Parler de ses projets futurs

Exprimer une intention, un projet ou un objectif et donner une précision.

**Exemple :**

> Expliquez ce que vous aimeriez faire l'année prochaine.

### EO1-C8 — Réagir à une relance et maintenir l'échange

Comprendre une demande de précision, compléter sa réponse et continuer naturellement.

**Exemple :**

> Après votre réponse, l'examinateur demande : « Pourquoi ? » Ajoutez une justification.

---

## EO2 — Jeu de rôle : demander et obtenir des informations

Niveau principalement visé : B1.

### EO2-C1 — Commencer poliment et expliquer son besoin

Saluer, présenter rapidement la situation et annoncer ce que l'on recherche.

**Exemple :**

> Vous appelez une agence pour louer un appartement. Commencez la conversation.

### EO2-C2 — Formuler une question claire

Construire une question compréhensible et directement liée à la situation.

**Exemple :**

> Demandez si une activité est encore disponible samedi.

### EO2-C3 — Demander des informations pratiques

Obtenir un prix, un horaire, une date, une adresse, une durée ou une disponibilité.

**Exemple :**

> Posez trois questions sur le prix, l'horaire et le lieu d'un cours.

### EO2-C4 — Demander les conditions et les modalités

Se renseigner sur les documents, l'inscription, le paiement, les règles ou les services inclus.

**Exemple :**

> Demandez quels documents sont nécessaires pour s'inscrire.

### EO2-C5 — Poser une question de suivi

Utiliser la réponse de l'interlocuteur pour demander une information supplémentaire pertinente.

**Exemple :**

> On vous dit que le logement est disponible. Demandez ensuite si les charges sont comprises.

### EO2-C6 — Demander une précision ou reformuler

Réagir lorsque l'information est incomplète, ambiguë ou mal comprise.

**Exemple :**

> Vous n'avez pas compris l'heure annoncée. Demandez poliment de la répéter.

### EO2-C7 — Comparer les possibilités et faire un choix

Questionner sur plusieurs options, leurs différences et celle qui correspond au besoin.

**Exemple :**

> Comparez deux formules d'abonnement avant de choisir.

### EO2-C8 — Confirmer les informations et terminer l'échange

Récapituler l'essentiel, vérifier une dernière information et prendre congé naturellement.

**Exemple :**

> Confirmez la date du rendez-vous puis terminez la conversation.

---

## EO3 — Exprimer et développer un point de vue

Niveau principalement visé : B2.

### EO3-C1 — Annoncer une position claire

Répondre immédiatement à la question et rendre son opinion identifiable.

**Exemple :**

> Dites clairement si vous préférez vivre en ville ou à la campagne.

### EO3-C2 — Donner un argument pertinent

Présenter une première raison directement liée à la position.

**Exemple :**

> Donnez une raison en faveur du télétravail.

### EO3-C3 — Développer oralement un argument

Expliquer la raison avec une cause, une conséquence ou une précision.

**Exemple :**

> Développez l'idée : « les transports publics facilitent la vie quotidienne ».

### EO3-C4 — Donner un exemple concret

Illustrer l'argument par une situation personnelle ou vraisemblable.

**Exemple :**

> Donnez un exemple montrant pourquoi le sport est important.

### EO3-C5 — Ajouter un deuxième argument distinct

Continuer le discours avec une nouvelle raison sans répéter la première.

**Exemple :**

> Ajoutez un second argument différent sur l'utilité du travail en équipe.

### EO3-C6 — Comparer ou présenter avantages et inconvénients

Mettre en relation deux situations et expliquer leurs principales différences.

**Exemple :**

> Comparez les achats en ligne et les achats en magasin.

### EO3-C7 — Nuancer ou reconnaître une limite

Introduire une réserve, une concession ou une exception sans perdre sa position.

**Exemple :**

> Présentez un avantage des réseaux sociaux, puis ajoutez une limite.

### EO3-C8 — Organiser un discours continu et conclure

Utiliser des connecteurs naturels, éviter l'accumulation d'idées et terminer clairement.

**Exemple :**

> Répondez en quatre phrases : opinion, argument, exemple et conclusion.

---

# 7. Règles de création des petits sujets

## Quantité

- MVP : au moins **5 petits sujets par compétence** ;
- cible éditoriale : **8 à 12 petits sujets par compétence** ;
- éviter des formulations trop proches qui entraîneraient la mémorisation.

## Chaque petit sujet doit contenir

```text
id
skillId
title
context
instruction
uniqueCriterion
targetLevel
recommendedLength ou recommendedDuration
difficultyLevel
referenceInsufficient
referenceExpected
referenceExcellent
referenceNotes
```

## Règles éditoriales

1. Un seul critère principal par petit sujet.
2. La consigne doit déclencher une production ouverte.
3. Le sujet doit rester lié à une situation possible du TCF.
4. Le vocabulaire de la consigne doit être accessible au niveau cible.
5. Les sujets doivent varier : vie quotidienne, travail, études, logement, loisirs, démarches, services, société.
6. Ne pas exiger une formulation unique.
7. Ne pas transformer l'exercice en test de pièges grammaticaux.
8. La contrainte doit être réaliste : une information, une précision, un argument, un exemple, un enchaînement, etc.

## Références comparatives

Chaque sujet possède trois références pré-écrites :

```text
INSUFFICIENT
EXPECTED
EXCELLENT
```

Ces références servent à montrer la cible, pas à imposer un modèle unique.

Elles apparaissent uniquement après la production.

Chaque référence contient :

- un texte ;
- une note pédagogique très courte expliquant pourquoi le niveau est insuffisant, attendu ou très réussi.

---

# 8. Analyse IA des productions de compétence

## Principe

L'IA ne doit pas corriger toute la production comme dans une tâche TCF complète.

Elle doit analyser **uniquement le critère annoncé** dans le petit sujet.

Exemple : si le critère est « situer le moment et le lieu », l'IA ne doit pas produire une longue liste de remarques sur les accords, les accents, le vocabulaire ou la conclusion.

## Entrées minimales envoyées à l'IA

```json
{
  "exam": "TCF_IRN",
  "section": "EE|EO",
  "taskCode": "EE2",
  "skillId": "EE2-C1",
  "skillName": "Situer le moment et le lieu",
  "targetLevel": "B1",
  "context": "...",
  "instruction": "...",
  "uniqueCriterion": "...",
  "candidateProduction": "...",
  "transcript": "..."
}
```

Pour EE, `candidateProduction` contient le texte du candidat.

Pour EO :

- conserver l'audio ;
- transcrire l'audio ;
- envoyer la transcription à l'évaluation ;
- ne pas prétendre analyser précisément la prononciation à partir de la transcription ;
- parler de clarté ou d'intelligibilité seulement si les données disponibles permettent réellement de le faire.

## Statuts possibles

```text
VALIDATED
PARTIAL
NOT_VALIDATED
```

### VALIDATED

Le critère est clairement visible et compréhensible, même si la production contient quelques erreurs qui ne bloquent pas la communication.

### PARTIAL

Le candidat essaie de réaliser le critère, mais il manque une information, une précision, un développement ou un lien logique.

### NOT_VALIDATED

Le critère est absent, la réponse ne traite pas la consigne ou la production est trop difficile à comprendre pour identifier la compétence.

## Règles de comportement de l'IA

1. Évaluer seulement le critère unique.
2. Ne pas sanctionner fortement les erreurs sans lien avec ce critère.
3. Tolérer les erreurs si la communication reste claire.
4. Ne jamais comparer mécaniquement la réponse du candidat aux mots des références.
5. Accepter plusieurs formulations correctes.
6. Conserver l'idée et l'intention du candidat dans la reformulation.
7. Donner une seule priorité d'amélioration.
8. Éviter les commentaires répétitifs.
9. Utiliser un langage simple, encourageant et direct.
10. Ne pas attribuer de niveau CECRL global sur un micro-exercice.
11. Ne pas attribuer de note sur 20 sur un micro-exercice.
12. Ne pas inventer des défauts pour remplir le retour.
13. Si le critère est validé, le dire clairement sans chercher une faute secondaire.
14. Si la production est très courte mais suffit au critère demandé, elle peut être validée.
15. La longueur ne devient un problème que si elle empêche d'accomplir le critère ou si le sujet impose explicitement une longueur.

---

## 9. Format JSON attendu de l'IA

La réponse doit être un JSON strict, court et stable :

```json
{
  "status": "VALIDATED|PARTIAL|NOT_VALIDATED",
  "verdict": "Une phrase courte indiquant si le critère est atteint.",
  "successPoint": "Un seul point réussi, concret et lié à la production.",
  "improvementPriority": "Une seule amélioration prioritaire et réalisable.",
  "improvedVersion": "Une reformulation courte qui conserve l'idée du candidat."
}
```

## Contraintes de longueur

```text
verdict              : 20 mots maximum
successPoint          : 30 mots maximum
improvementPriority   : 35 mots maximum
improvedVersion       : longueur proche de la production demandée
```

## Interdictions

L'IA ne doit pas retourner :

- une liste de dix erreurs ;
- plusieurs priorités concurrentes ;
- un cours grammatical long ;
- une note globale TCF ;
- un niveau CECRL global ;
- une réponse entièrement différente de l'idée du candidat ;
- des formulations comme « très mauvais », « niveau faible » ou « vous ne savez pas écrire ».

---

## 10. Exemple d'analyse IA — EE2

### Sujet

```text
Compétence : Situer le moment et le lieu
Contexte : Vous racontez une sortie qui s'est mal passée.
Consigne : Écrivez la première phrase du récit.
Critère unique : indiquer clairement quand et où la situation s'est passée.
```

### Production

```text
La semaine dernière, je suis allé dans un restaurant avec mes amis.
```

### Réponse attendue de l'IA

```json
{
  "status": "VALIDATED",
  "verdict": "Le moment et le lieu sont clairement indiqués.",
  "successPoint": "Vous utilisez un repère temporel précis et vous situez l'action dans un restaurant.",
  "improvementPriority": "Aucune correction prioritaire pour ce critère ; gardez cette précision dans le récit complet.",
  "improvedVersion": "La semaine dernière, je suis allé dans un restaurant du centre-ville avec mes amis."
}
```

---

## 11. Exemple d'analyse IA — EO1

### Sujet

```text
Compétence : Développer une réponse avec une précision
Question : Que faites-vous le week-end ?
Critère unique : donner une activité et au moins une précision.
```

### Production transcrite

```text
J'aime le sport.
```

### Réponse attendue de l'IA

```json
{
  "status": "PARTIAL",
  "verdict": "L'activité est donnée, mais la réponse manque encore de précision.",
  "successPoint": "Vous répondez directement en parlant d'une activité que vous aimez.",
  "improvementPriority": "Ajoutez quand, où ou avec qui vous pratiquez cette activité.",
  "improvedVersion": "J'aime le sport. Le samedi matin, je joue au football avec mes amis."
}
```

---

# 12. Modèle de données recommandé

```text
Skill
- id
- section: EE | EO
- taskCode: EE1 | EE2 | EE3 | EO1 | EO2 | EO3
- code
- title
- description
- targetLevel
- displayOrder
- active

SkillPrompt
- id
- skillId
- title
- context
- instruction
- uniqueCriterion
- recommendedMinWords
- recommendedMaxWords
- recommendedDurationSeconds
- difficultyLevel
- displayOrder
- active

SkillReference
- id
- skillPromptId
- level: INSUFFICIENT | EXPECTED | EXCELLENT
- text
- pedagogicalNote

UserSkillAttempt
- id
- userId
- skillPromptId
- writtenProduction
- audioUrl
- transcript
- selfEvaluation
- status: VALIDATED | PARTIAL | NOT_VALIDATED
- aiEvaluationJson
- createdAt
```

## Progression calculée

```text
skillProgress = nombre de petits sujets ayant au moins une tentative
validatedCount = nombre de sujets dont la dernière tentative est VALIDATED
reinforceCount = nombre de sujets dont la dernière tentative est PARTIAL ou NOT_VALIDATED
```

La progression affichée doit principalement montrer les **sujets traités**, sans donner l'impression que tout doit être parfaitement validé pour avancer.

---

# 13. Règles UX importantes

1. Afficher le critère avant la production.
2. Cacher les références avant la validation.
3. Marquer immédiatement le sujet comme traité après une tentative enregistrée.
4. Afficher un retour court au-dessus des références comparatives.
5. Permettre de reprendre une ancienne production.
6. Toujours offrir un retour à la liste des petits sujets.
7. Ne pas bloquer l'accès au sujet suivant si le critère n'est pas validé.
8. Différencier visuellement les statuts `À faire`, `Validé` et `À renforcer`.
9. Garder la séparation entre entraînement par compétence et sujet TCF complet.
10. Sur mobile, rendre le bouton principal visible sans obliger à parcourir une page excessivement longue.

---

# 14. Freemium recommandé

## Gratuit

- accès à une sélection de petits sujets ;
- production écrite ou orale ;
- références comparatives pré-écrites ;
- auto-évaluation ;
- progression locale ou limitée.

## Premium

- analyse IA ciblée ;
- historique complet ;
- reprise et suivi des tentatives ;
- davantage de petits sujets ;
- recommandations personnalisées sur les compétences à renforcer.

Les références comparatives doivent rester indépendantes de l'IA et être enregistrées en base.

---

# 15. Critères d'acceptation pour Claude Code

L'intégration est considérée comme terminée lorsque :

- les 6 tâches EE/EO possèdent chacune exactement 8 compétences actives ;
- chaque compétence ouvre une liste de petits sujets ;
- chaque sujet affiche son statut et son nombre de tentatives ;
- le candidat peut ouvrir un sujet, produire, valider puis revenir à la liste ;
- le sujet traité change immédiatement de statut ;
- le prochain sujet non traité peut être ouvert en un clic ;
- les références restent masquées avant la production ;
- le résultat affiche uniquement : verdict, point réussi, priorité, reformulation ;
- l'IA retourne le JSON strict défini dans ce document ;
- les sujets TCF complets restent accessibles séparément ;
- les productions EE et EO sont gérées avec des composants adaptés ;
- l'oral conserve l'audio et la transcription ;
- aucune analyse phonétique précise n'est inventée à partir de Whisper.

---

# 16. Résumé à respecter

```text
Sujets TCF complets
+ Compétences ciblées
+ Petits sujets de production ouverte
+ Un critère unique
+ Trois références comparatives après production
+ Une analyse IA courte
+ Une progression visible sujet par sujet
```

Le module doit aider le candidat à transformer son français actuel en une réponse plus efficace pour le TCF, sans devenir une application généraliste d'apprentissage de la langue.
