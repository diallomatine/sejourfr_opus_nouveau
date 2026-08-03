# Spécification — Évaluation IA des productions TCF IRN

**Destination :** implémentation par Codex  
**Périmètre :** expression orale (EO) et expression écrite (EE), évaluation par tâche, conversation temps réel des tâches orales 1 et 2, écran de résultats.  
**Statut :** proposition produit et technique alignée sur les informations publiques de France Éducation international et les descripteurs du CECRL. Cette application produit une **estimation pédagogique**, jamais une note officielle du TCF.

---

## 1. Corrections indispensables du modèle actuel

### 1.1 Format actuel du TCF IRN

Depuis le 12 mai 2025, le TCF IRN évalue jusqu'au niveau **B2**.

#### Expression orale

| Tâche | Nature | Durée | Préparation |
|---|---|---:|---|
| EO1 | Entretien dirigé | 3 min | Aucune |
| EO2 | Interaction pour obtenir des informations | 3 min 30 | Aucune |
| EO3 | Expression d'un point de vue | 3 min 30 | Aucune |

#### Expression écrite

| Tâche | Nature | Longueur officielle TCF IRN |
|---|---|---:|
| EE1 | Message court de description/réponse | **30 à 60 mots** |
| EE2 | Récit ou compte rendu d'expérience | **40 à 90 mots** |
| EE3 | Opinion sur une personne, un lieu, un objet ou un groupe | **40 à 90 mots** |

> À supprimer du paramétrage TCF IRN : 60–120, 120–150 et 150–180 mots. Ces fourchettes ne correspondent pas au format IRN actuel.

### 1.2 Ne pas confondre « difficulté de la tâche » et « niveau attribué »

Les raccourcis suivants sont utiles pédagogiquement mais insuffisants pour noter :

- tâche 1 ≈ communication élémentaire ;
- tâche 2 ≈ interaction autonome ;
- tâche 3 ≈ opinion développée.

Une tâche ne doit pas recevoir automatiquement A2, B1 ou B2 selon son numéro. L'IA doit estimer ce que le candidat **réalise réellement**.

Pour chaque résultat, stocker séparément :

```text
task_expected_level     // niveau principalement sollicité par la tâche
demonstrated_level      // niveau effectivement montré par le candidat
target_status           // BELOW / NEAR / REACHED / EXCEEDED
confidence              // LOW / MEDIUM / HIGH
```

Exemple :

```json
{
  "taskExpectedLevel": "B1",
  "demonstratedLevel": "A2",
  "targetStatus": "BELOW",
  "confidence": "HIGH"
}
```

---

## 2. Principe central de notation

L'évaluation ne doit plus être une simple note générique du texte fondée principalement sur le nombre de fautes.

L'ordre de priorité doit être :

1. **La tâche est-elle accomplie ?**
2. **Le message est-il compréhensible et adapté à la situation ?**
3. **Le discours ou le texte est-il organisé ?**
4. **La langue utilisée permet-elle de communiquer avec suffisamment de précision ?**
5. **À quel niveau CECRL l'ensemble de la performance correspond-il ?**

Les erreurs grammaticales ne doivent pénaliser fortement que lorsqu'elles :

- rendent le message ambigu ou difficile à comprendre ;
- sont très fréquentes sur des structures normalement maîtrisées au niveau estimé ;
- empêchent le candidat de développer ou d'interagir.

Une production simple mais efficace peut être meilleure qu'une production ambitieuse, longue et hors sujet.

---

## 3. Familles de critères communes

France Éducation international indique trois grandes familles de critères pour les productions :

### 3.1 Pragmatique

- respect de la consigne ;
- réalisation de l'objectif communicatif ;
- pertinence des informations ;
- développement thématique ;
- cohérence et cohésion ;
- interaction et gestion des tours de parole à l'oral.

### 3.2 Linguistique

- étendue et précision du lexique ;
- maîtrise du vocabulaire utilisé ;
- étendue des structures ;
- correction grammaticale ;
- orthographe à l'écrit ;
- fluidité et intelligibilité à l'oral.

### 3.3 Sociolinguistique

- registre adapté ;
- vouvoiement/tutoiement cohérent ;
- formules de politesse ;
- ton adapté au destinataire et à la situation ;
- respect du rôle imposé.

---

## 4. Pipeline d'évaluation recommandé

```text
Production
  -> contrôles déterministes
  -> extraction des caractéristiques
  -> évaluation IA n°1
  -> évaluation IA n°2 indépendante
  -> résolution des écarts
  -> génération du feedback pédagogique
  -> validation JSON stricte
  -> sauvegarde du résultat versionné
```

### 4.1 Contrôles déterministes avant le LLM

#### Pour l'écrit

- nombre de mots ;
- tâche vide ou presque vide ;
- langue dominante ;
- copie manifeste de la consigne ;
- présence éventuelle d'éléments demandés ;
- paragraphes ;
- ponctuation minimale ;
- détection de texte identique à une réponse modèle connue.

#### Pour l'oral

- audio exploitable ;
- durée ;
- ratio de segments inaudibles ;
- transcription par locuteur ;
- nombre de tours ;
- temps de parole candidat/agent ;
- latence de réponse ;
- pauses longues ;
- interruptions ;
- répétitions et autocorrections ;
- débit indicatif.

Ces données ne donnent pas directement le niveau. Elles servent de preuves au modèle.

### 4.2 Double évaluation IA

Effectuer deux passes indépendantes :

- `EVALUATOR_A` : analyse critériée et niveau ;
- `EVALUATOR_B` : analyse critériée et niveau sans voir la première réponse.

Règle :

```text
même niveau ou écart d'un seul palier -> consensus automatique
écart supérieur à un palier -> troisième passe d'arbitrage
```

Cela réduit la variabilité d'un appel LLM unique.

### 4.3 La confiance doit être explicite

`HIGH` : audio/texte complet, consigne claire, preuves nombreuses, évaluateurs concordants.  
`MEDIUM` : production courte, quelques segments incertains ou léger désaccord.  
`LOW` : audio mauvais, tâche incomplète, agent défaillant, transcription incertaine ou fort désaccord.

Ne pas afficher « B1 certain ». Afficher par exemple :

> **Niveau estimé : B1 — confiance moyenne**

---

## 5. Échelle interne par critère

Utiliser une échelle discrète liée au CECRL plutôt qu'une note arbitraire sur 20 pour chaque critère.

```text
0 = A1_NON_ATTEINT
1 = A1
2 = A2
3 = B1
4 = B2
```

Chaque critère contient :

```json
{
  "id": "task_fulfillment",
  "level": "B1",
  "score": 3,
  "evidence": [
    "Le candidat demande le prix, les horaires et les conditions d'inscription."
  ],
  "comment": "L'objectif est atteint, mais certaines informations ne sont pas approfondies."
}
```

### 5.1 Conversion en score visuel

Le score en pourcentage sert uniquement à l'interface :

```text
A1 non atteint = 10
A1 = 25
A2 = 50
B1 = 75
B2 = 100
```

Le pourcentage ne doit jamais être présenté comme un score officiel du TCF.

---

## 6. Règles de décision du niveau d'une tâche

### 6.1 Calcul initial

```text
weightedScore = somme(criterionScore * criterionWeight)
```

Seuils indicatifs :

```text
< 0.75       -> A1_NON_ATTEINT
0.75–1.49    -> A1
1.50–2.49    -> A2
2.50–3.49    -> B1
>= 3.50      -> B2
```

### 6.2 Règles de plafonnement

La moyenne seule est interdite. Appliquer les plafonds suivants :

- objectif communicatif non réalisé : niveau maximal A1 ;
- production majoritairement hors sujet : A1 non atteint ;
- contenu trop limité pour fournir des preuves : niveau maximal A2 et confiance faible ;
- message régulièrement incompréhensible : niveau maximal A1 ;
- EO2 sans véritable échange ni questions adaptées : niveau maximal A2 ;
- EO3 sans opinion identifiable : niveau maximal A2 ;
- EE2 sans récit, expérience ou progression temporelle : niveau maximal A2 ;
- EE3 sans opinion ou justification : niveau maximal A2 ;
- registre complètement incompatible avec la situation : réduire au maximum d'un palier, pas annuler toute la production ;
- hors fourchette de mots en EE : déclencher un avertissement majeur. Dans une simulation complète, la copie entière peut être considérée à risque d'« A1 non atteint », conformément à l'avertissement officiel.

### 6.3 Ne pas transformer les erreurs en comptage brut

Mauvaise logique :

```text
12 erreurs = A2
5 erreurs = B1
```

Bonne logique :

```text
Les erreurs sont-elles locales ou systématiques ?
Empêchent-elles la compréhension ?
Le candidat prend-il des risques linguistiques ?
Les structures simples sont-elles maîtrisées ?
Le candidat peut-il reformuler ?
```

---

# 7. Expression orale — critères généraux

## 7.1 Données à analyser

- transcription fidèle avec séparation `CANDIDATE` / `AGENT` ;
- contenu produit ;
- pertinence par rapport à la question ;
- enchaînement des idées ;
- longueur et autonomie des prises de parole ;
- compréhension des relances ;
- capacité à demander une clarification ;
- fluidité ;
- pauses et hésitations ;
- intelligibilité ;
- lexique ;
- grammaire ;
- registre ;
- gestion de l'interaction.

## 7.2 Intelligibilité, pas imitation d'un accent natif

Ne pas sanctionner un accent étranger en lui-même.

Évaluer :

- l'effort nécessaire pour comprendre ;
- la proportion de mots réellement incompréhensibles ;
- l'effet du rythme, de l'articulation et de l'intonation sur le sens ;
- les confusions phonétiques qui modifient le message.

Libellé UI recommandé : **Clarté et intelligibilité**, pas « Accent ».

Whisper seul ne suffit pas pour une analyse phonétique fine. Ne jamais inventer une faute de prononciation à partir d'un texte transcrit correctement.

---

# 8. EO — Tâche 1 : entretien dirigé

## 8.1 Objectif

Échanger avec une personne inconnue et parler de soi, de son environnement, de ses habitudes, de ses expériences et de ses projets.

## 8.2 Critères et poids

| Critère | Poids |
|---|---:|
| Réponse aux questions et pertinence | 25 % |
| Développement des réponses | 20 % |
| Interaction et compréhension des relances | 15 % |
| Lexique du quotidien | 15 % |
| Grammaire et construction des phrases | 15 % |
| Fluidité et intelligibilité | 10 % |

## 8.3 Ce que l'IA doit repérer

### Réussite

- répond réellement à la question ;
- ajoute spontanément un détail ;
- peut raconter brièvement une expérience ;
- comprend les relances normales ;
- utilise le présent, le passé ou le futur selon le besoin ;
- maintient l'échange sans réponses uniquement « oui/non ».

### Difficultés

- réponses mémorisées sans rapport exact avec la question ;
- réponses d'un ou deux mots ;
- contradictions non expliquées ;
- incompréhension répétée de questions simples ;
- blocages très longs ;
- vocabulaire trop limité pour parler de sa vie quotidienne.

## 8.4 Descripteurs simplifiés

**A1** : fournit quelques informations personnelles avec des mots ou phrases isolées.  
**A2** : répond à des questions simples et décrit sa vie avec une série de phrases simples.  
**B1** : développe avec une certaine autonomie, raconte et explique de manière suivie.  
**B2** : répond avec aisance, précision et spontanéité, mais la tâche seule ne suffit pas à confirmer un B2 global.

## 8.5 Feedback attendu

Mauvais :

> Votre grammaire doit être améliorée.

Bon :

> Vous répondez clairement aux questions personnelles, mais vos réponses restent souvent très courtes. Après « Je travaille dans un restaurant », ajoutez votre poste, vos horaires ou ce que vous aimez dans ce travail.

---

# 9. EO — Tâche 2 : interaction en temps réel

## 9.1 Objectif prioritaire

Le candidat doit **obtenir des informations** dans une situation de la vie quotidienne. Il doit mener l'échange, poser des questions adaptées et réagir aux réponses de l'agent.

Le nombre de questions n'est pas suffisant. L'IA doit analyser leur qualité et l'adaptation au dialogue.

## 9.2 Fiche donnée à l'agent IA

Chaque sujet EO2 doit stocker une fiche structurée.

```json
{
  "scenarioId": "eo2_sport_registration_001",
  "candidateRole": "Vous souhaitez inscrire votre enfant dans un club de sport.",
  "agentRole": "Employé du club municipal",
  "relationship": "UNKNOWN_PERSON_FORMAL",
  "candidateGoal": "Obtenir les informations nécessaires avant de décider de l'inscription.",
  "openingLine": "Bonjour, je peux vous renseigner ?",
  "requiredInformationSlots": [
    {"id": "activities", "value": "natation et judo", "importance": "HIGH"},
    {"id": "age", "value": "à partir de 7 ans", "importance": "HIGH"},
    {"id": "schedule", "value": "mercredi à 15 h et samedi à 10 h", "importance": "HIGH"},
    {"id": "price", "value": "120 euros par trimestre", "importance": "HIGH"},
    {"id": "documents", "value": "certificat médical et photo", "importance": "MEDIUM"},
    {"id": "trial", "value": "une séance d'essai gratuite", "importance": "MEDIUM"}
  ],
  "optionalInformationSlots": [
    {"id": "equipment", "value": "le kimono n'est pas fourni"}
  ],
  "agentConstraints": [
    "Ne pas donner toutes les informations spontanément.",
    "Répondre uniquement à la question posée, avec une quantité naturelle d'information.",
    "Demander une précision si la question est ambiguë.",
    "Ne jamais corriger le français du candidat pendant l'épreuve.",
    "Ne jamais lui suggérer directement les questions à poser.",
    "Rester dans le rôle.",
    "Ne pas rendre artificiellement l'échange difficile."
  ],
  "naturalPrompts": [
    "Vous souhaitez savoir autre chose ?",
    "Pour quel âge exactement ?",
    "Vous préférez quel jour ?"
  ],
  "closingCondition": "Le candidat indique qu'il a terminé ou le temps est écoulé."
}
```

## 9.3 Comportement obligatoire de l'agent

L'agent doit :

- garder le rôle et le statut indiqués ;
- répondre de façon naturelle et courte ;
- révéler progressivement les informations ;
- permettre des questions de suivi ;
- demander une clarification lorsqu'une demande est imprécise ;
- accepter les reformulations ;
- utiliser le vouvoiement ou le tutoiement prévu ;
- ne pas monopoliser la parole ;
- ne pas transformer l'épreuve en cours de français ;
- ne pas féliciter ou noter le candidat pendant la conversation ;
- ne pas inventer des informations contradictoires avec la fiche ;
- ne pas répéter mécaniquement la même phrase.

### Cas particulier : question mal formulée mais compréhensible

L'agent doit répondre normalement. Exemple :

> « C'est combien le prix ? »

Réponse naturelle :

> « C'est 120 euros par trimestre. »

Il ne doit pas dire :

> « On dit : Quel est le prix ? »

## 9.4 Journal de conversation à sauvegarder

Pour chaque tour :

```json
{
  "turnIndex": 7,
  "speaker": "CANDIDATE",
  "startMs": 42150,
  "endMs": 46820,
  "text": "Et les cours sont quel jour ?",
  "intent": "ASK_SCHEDULE",
  "questionType": "RELEVANT_NEW_QUESTION",
  "linkedSlot": "schedule",
  "understood": true,
  "agentClarificationNeeded": false
}
```

Types de question candidat :

```text
RELEVANT_NEW_QUESTION
RELEVANT_FOLLOW_UP
CLARIFICATION_REQUEST
CONFIRMATION_QUESTION
REDUNDANT_QUESTION
OFF_TOPIC_QUESTION
NOT_A_QUESTION
UNINTELLIGIBLE
```

## 9.5 Critères et poids EO2

| Critère | Poids |
|---|---:|
| Obtention des informations essentielles | 20 % |
| Pertinence et variété des questions | 20 % |
| Écoute et questions de suivi | 15 % |
| Gestion de l'interaction | 15 % |
| Lexique et grammaire fonctionnels | 15 % |
| Fluidité et intelligibilité | 10 % |
| Adéquation sociolinguistique | 5 % |

## 9.6 Mesures utiles

```text
essentialSlotsCovered / essentialSlotsTotal
relevantQuestionCount
followUpQuestionCount
redundantQuestionCount
offTopicQuestionCount
clarificationRequestCount
candidateSpeakingRatio
averageResponseLatencyMs
longPauseCount
interruptionCount
agentHelpCount
```

Ne pas fixer de règle du type « 8 questions = B1 ». Selon le sujet, cinq bonnes questions avec des suivis peuvent montrer davantage de compétence que douze questions récitées.

## 9.7 Descripteurs simplifiés

**A1** : pose quelques questions très simples, souvent avec aide.  
**A2** : obtient des informations prévisibles avec des questions simples et directes.  
**B1** : conduit l'échange, adapte ses questions, vérifie et approfondit certaines réponses.  
**B2** : négocie ou précise avec aisance et souplesse ; dans le TCF IRN, afficher au maximum B2.

## 9.8 Remarques que l'IA doit remonter

### Sur l'accomplissement

- informations essentielles obtenues ;
- informations importantes oubliées ;
- questions hors sujet ;
- conversation terminée trop tôt.

### Sur l'interaction

- enchaîne ou récite une liste ;
- réagit aux réponses ;
- demande une précision ;
- reformule après une incompréhension ;
- laisse l'agent répondre ;
- coupe systématiquement la parole ;
- utilise une formule d'ouverture et de clôture adaptée.

### Sur la langue

- formes interrogatives disponibles ;
- confusion entre « est-ce que », inversion et intonation, sans sur-sanctionner ;
- vocabulaire suffisant pour le scénario ;
- erreurs qui modifient le sens ;
- intelligibilité.

## 9.9 Exemple de feedback EO2

> **Ce qui est réussi :** vous avez demandé le prix, les horaires, l'âge minimum et les documents nécessaires. Vous avez aussi réagi à la réponse sur le mercredi en demandant s'il existait un autre créneau.  
> **À améliorer :** plusieurs questions ont été posées à la suite sans attendre la réponse complète. L'information sur la séance d'essai n'a pas été demandée.  
> **Priorité :** après chaque réponse, utilisez une relance liée : « D'accord, et le samedi, c'est à quelle heure exactement ? »

---

# 10. EO — Tâche 3 : expression d'un point de vue

## 10.1 Objectif

Répondre spontanément à une question, exprimer une position et la développer de manière continue et convaincante.

## 10.2 Critères et poids

| Critère | Poids |
|---|---:|
| Opinion claire et réponse directe | 15 % |
| Développement des arguments | 25 % |
| Exemples, explications et nuances | 15 % |
| Organisation et cohésion | 15 % |
| Lexique | 10 % |
| Grammaire | 10 % |
| Fluidité et intelligibilité | 10 % |

## 10.3 Ce que l'IA doit analyser

- position identifiable ;
- au moins deux idées développées, sans exiger artificiellement un plan scolaire ;
- raisons explicites ;
- exemple concret ou expérience ;
- avantages/inconvénients lorsque pertinent ;
- conclusion ou fermeture naturelle ;
- connecteurs variés mais naturels ;
- capacité à maintenir un discours continu ;
- répétitions et contradictions ;
- recours excessif à des phrases génériques mémorisées.

## 10.4 Descripteurs simplifiés

**A1** : juxtapose quelques phrases très simples, opinion difficile à identifier.  
**A2** : donne une opinion simple avec une raison élémentaire.  
**B1** : présente une suite cohérente d'idées, explique et illustre son point de vue.  
**B2** : développe clairement, relie les arguments, nuance et soutient ses idées avec des exemples pertinents.

## 10.5 Pièges de notation à éviter

- ne pas exiger une dissertation académique ;
- ne pas exiger des connaissances spécialisées ;
- ne pas pénaliser l'opinion choisie ;
- ne pas donner B2 uniquement parce que le candidat utilise « premièrement/deuxièmement » ;
- ne pas confondre longueur et qualité ;
- ne pas survaloriser des expressions apprises si le contenu reste vide.

---

# 11. Expression écrite — contrôles généraux

## 11.1 Validité

Produire les indicateurs suivants :

```json
{
  "wordCount": 52,
  "minWords": 40,
  "maxWords": 90,
  "wordCountStatus": "VALID",
  "isEmpty": false,
  "isOffTopic": false,
  "promptCopyRatio": 0.04,
  "dominantLanguage": "fr",
  "validityRisk": "NONE"
}
```

Valeurs `wordCountStatus` :

```text
TOO_SHORT
VALID
TOO_LONG
```

Valeurs `validityRisk` :

```text
NONE
WARNING
MAJOR
POSSIBLE_A1_NOT_REACHED
```

Le respect de la fourchette doit apparaître en haut de l'écran, car une copie hors format est exposée à une sanction très forte dans le test officiel.

## 11.2 Analyse des erreurs

Chaque correction doit contenir :

- extrait original ;
- correction proposée ;
- catégorie ;
- explication courte ;
- gravité communicative ;
- règle ou exemple réutilisable.

```json
{
  "original": "Je suis allé avec ma amie.",
  "correction": "Je suis allé avec mon amie.",
  "category": "DETERMINER",
  "impact": "LOW",
  "explanation": "Devant un nom féminin commençant par une voyelle, on emploie « mon ».",
  "reusableExample": "mon école, mon amie"
}
```

Catégories minimales :

```text
TASK_FULFILLMENT
MEANING
GRAMMAR
VERB_TENSE
AGREEMENT
DETERMINER
PREPOSITION
WORD_ORDER
VOCABULARY
REGISTER
SPELLING
PUNCTUATION
COHESION
```

Ne montrer au candidat que les erreurs les plus utiles, regroupées par priorité. Éviter une liste de 30 micro-corrections décourageantes.

---

# 12. EE — Tâche 1 : message court

## 12.1 Objectif

Réagir à un message et décrire une personne, un lieu, un objet ou un groupe, en donnant les informations demandées au bon destinataire.

## 12.2 Critères et poids

| Critère | Poids |
|---|---:|
| Respect de la consigne et informations demandées | 35 % |
| Clarté du message | 20 % |
| Adéquation au destinataire | 15 % |
| Lexique | 10 % |
| Grammaire | 10 % |
| Orthographe et ponctuation | 10 % |

## 12.3 Analyse spécifique

- présence de toutes les informations explicitement demandées ;
- type de message approprié ;
- destinataire correctement pris en compte ;
- ouverture et fermeture utiles, sans les rendre obligatoires si le format ne les exige pas ;
- description compréhensible ;
- phrases simples correctement reliées.

## 12.4 Descripteurs simplifiés

**A1** : transmet quelques informations avec des phrases isolées.  
**A2** : produit un message simple et compréhensible, relié par des connecteurs élémentaires.  
**B1** : message complet, clair et assez précis, avec quelques détails.  
**B2** : formulation souple et précise, mais cette tâche courte donne peu de preuves pour confirmer seule un B2.

---

# 13. EE — Tâche 2 : récit ou expérience

## 13.1 Objectif

Raconter une expérience ou faire un compte rendu d'activités quotidiennes à un ou plusieurs destinataires.

## 13.2 Critères et poids

| Critère | Poids |
|---|---:|
| Réalisation du récit/compte rendu | 25 % |
| Chronologie et cohérence | 20 % |
| Détails, actions et ressentis | 15 % |
| Adéquation au destinataire | 10 % |
| Lexique | 10 % |
| Temps verbaux et grammaire | 15 % |
| Orthographe et ponctuation | 5 % |

## 13.3 Analyse spécifique

- situation initiale identifiable ;
- événements principaux ;
- ordre temporel ;
- connecteurs : puis, ensuite, quand, après, finalement, etc. ;
- temps verbaux cohérents ;
- ressenti ou réaction lorsque la consigne le demande ;
- conclusion ou résultat de l'expérience ;
- absence de contradictions majeures.

## 13.4 Descripteurs simplifiés

**A1** : énumère quelques actions sans véritable récit.  
**A2** : raconte une suite simple d'événements avec des connecteurs fréquents.  
**B1** : produit un récit suivi, ajoute des détails, des réactions et des explications.  
**B2** : récit clair, précis et bien organisé, avec variété et bonne maîtrise ; preuves limitées par la longueur IRN.

## 13.5 Exemple de feedback

> La chronologie est claire grâce à « d'abord », « ensuite » et « enfin ». En revanche, vous racontez les actions sans expliquer votre réaction. Ajoutez une phrase comme : « J'étais inquiet au début, mais le personnel m'a rapidement rassuré. »

---

# 14. EE — Tâche 3 : opinion

## 14.1 Objectif

Donner une opinion au destinataire indiqué et la justifier dans un texte très court de 40 à 90 mots.

## 14.2 Critères et poids

| Critère | Poids |
|---|---:|
| Position claire et respect du sujet | 20 % |
| Justification et développement | 25 % |
| Exemple ou illustration | 10 % |
| Cohérence et connecteurs | 15 % |
| Adéquation au destinataire | 10 % |
| Lexique | 10 % |
| Grammaire, orthographe et ponctuation | 10 % |

## 14.3 Analyse spécifique

- opinion explicite ;
- une ou plusieurs raisons réellement expliquées ;
- exemple pertinent ;
- possibilité de nuance, sans l'exiger à A2/B1 ;
- relations logiques claires ;
- texte compatible avec la contrainte de 90 mots ;
- pas de remplissage générique.

## 14.4 Descripteurs simplifiés

**A1** : opinion très élémentaire, justification absente ou difficile à comprendre.  
**A2** : donne une opinion simple et une raison compréhensible.  
**B1** : justifie clairement, relie les idées et fournit un exemple pertinent.  
**B2** : développe et nuance avec précision dans un texte court, organisé et adapté.

---

# 15. Estimation du résultat global EO ou EE

## 15.1 Résultat d'une tâche isolée

Afficher :

```text
Niveau démontré sur cette tâche
Statut par rapport à l'objectif
Confiance
Score pédagogique /100
```

Ne pas afficher une « note TCF officielle /20 » sur une tâche isolée.

## 15.2 Résultat d'une épreuve complète de trois tâches

France Éducation international utilise des évaluations par tâche et une règle de calcul propre. L'application ne doit pas prétendre reproduire exactement cette règle non publique.

Algorithme de simulation conseillé :

1. obtenir un niveau consensuel par tâche ;
2. convertir en valeurs 0 à 4 ;
3. calculer une moyenne des trois tâches ;
4. appliquer les règles de cohérence ci-dessous ;
5. convertir en note /20 **estimée** ;
6. afficher une marge d'incertitude.

### 15.3 Règles de cohérence de l'épreuve

Pour estimer **B2** :

- tâche 3 au moins B2 ;
- tâche 2 au moins B1 ;
- aucune tâche A1 non atteint ;
- langue globalement intelligible/compréhensible.

Pour estimer **B1** :

- au moins une preuve B1 forte en tâche 2 ou 3 ;
- tâche 1 au moins A2 ou performance compensée par les autres tâches ;
- aucune invalidité majeure.

Pour estimer **A2** :

- communication simple réussie dans plusieurs tâches ;
- message généralement compréhensible malgré des erreurs fréquentes.

### 15.4 Correspondance TCF IRN simulée

Pour l'IRN actuel, plafonner l'affichage à B2 :

| Note estimée | Niveau affiché |
|---:|---|
| 0 | A1 non atteint |
| 1 | A1 |
| 2–5 | A2 |
| 6–9 | B1 |
| 10–20 | B2 |

Pour une autre déclinaison TCF, utiliser une table différente et versionnée.

### 15.5 Marge d'incertitude

Exemple :

```text
Niveau estimé : B1
Note simulée : 8/20
Intervalle plausible : 7–10/20
Confiance : moyenne
```

---

# 16. Écran de résultats recommandé

L'écran actuel avec quatre notes génériques comme « pertinence », « grammaire », « lexique » et « cohérence » est insuffisant. Le contenu doit dépendre de la tâche.

## 16.1 Bloc supérieur

Afficher immédiatement :

- `Niveau estimé : B1` ;
- `Objectif de la tâche : B1 — atteint` ;
- confiance ;
- statut de validité ;
- longueur ou durée ;
- phrase de synthèse.

Exemple :

> **B1 estimé — objectif atteint**  
> Vous conduisez l'échange et obtenez les informations principales. Vos questions de suivi restent encore limitées.

## 16.2 Accomplissement de la tâche

Pour EO2, utiliser une checklist :

```text
✓ Prix demandé
✓ Horaires demandés
✓ Conditions demandées
○ Séance d'essai non demandée
```

Pour EE1 :

```text
✓ Lieu décrit
✓ Date indiquée
○ Moyen de transport absent
```

Cette partie doit précéder la grammaire.

## 16.3 Détail par critères

Chaque carte contient :

- nom du critère adapté à la tâche ;
- niveau atteint, pas seulement une barre ;
- une preuve concrète ;
- une action courte.

Exemple :

```text
Interaction : B1
Preuve : vous avez rebondi sur le créneau du mercredi.
Action : demandez aussi une confirmation ou une alternative.
```

## 16.4 Points forts

Maximum trois, spécifiques et prouvés.

Mauvais :

> Bon vocabulaire.

Bon :

> Vous utilisez correctement « tarif », « inscription », « document nécessaire » et « séance d'essai » dans le contexte du club.

## 16.5 Priorités d'amélioration

Maximum trois, ordonnées :

1. une priorité liée à la réalisation de la tâche ;
2. une priorité de discours/interaction ;
3. une priorité linguistique.

## 16.6 Corrections utiles

Afficher 3 à 6 corrections prioritaires, pas toutes les fautes.

Pour l'oral, conserver une formulation proche de ce qui a été dit :

```text
Vous avez dit : « Les cours ils commencent quelle heure ? »
Formulation plus naturelle : « À quelle heure commencent les cours ? »
```

Ne pas présenter la forme du candidat comme incompréhensible si elle a permis la communication.

## 16.7 Exemple amélioré

Fournir deux niveaux d'aide :

- `Amélioration légère` : même idée, mieux formulée ;
- `Exemple plus développé` : réponse modèle adaptée au niveau suivant.

Ne jamais remplacer la production complète sans expliquer ce qui change.

## 16.8 Plan d'entraînement automatique

Créer trois exercices directs à partir des erreurs :

```json
[
  {
    "type": "FOLLOW_UP_QUESTIONS",
    "instruction": "Posez une question de suivi après chaque réponse de l'agent.",
    "priority": 1
  },
  {
    "type": "QUESTION_FORMATION",
    "instruction": "Transformez cinq phrases en questions avec « est-ce que ».",
    "priority": 2
  },
  {
    "type": "ROLE_PLAY_RETRY",
    "instruction": "Rejouez le même scénario en demandant les six informations.",
    "priority": 3
  }
]
```

## 16.9 Transcription ou texte annoté

À proposer dans un onglet séparé :

- transcription complète par locuteur ;
- segments incertains ;
- lecture de l'audio synchronisée ;
- erreurs surlignées par catégorie ;
- possibilité de masquer les corrections pour réessayer.

---

# 17. Schéma JSON de sortie recommandé

```json
{
  "schemaVersion": "tcf-irn-eval-2.0",
  "rubricVersion": "tcf-irn-2025-cefr-1.0",
  "exam": "TCF_IRN",
  "skill": "EO",
  "taskNumber": 2,
  "validity": {
    "status": "VALID",
    "risk": "NONE",
    "reasons": []
  },
  "taskObjective": {
    "expectedLevel": "B1",
    "summary": "Obtenir des informations dans une situation quotidienne."
  },
  "result": {
    "demonstratedLevel": "B1",
    "targetStatus": "REACHED",
    "pedagogicalScore": 76,
    "confidence": "HIGH",
    "confidenceReasons": [
      "Conversation complète",
      "Deux évaluateurs concordants"
    ],
    "summary": "Le candidat mène l'échange et obtient l'essentiel, mais approfondit peu certaines réponses."
  },
  "taskCompletion": {
    "completed": true,
    "coveredItems": ["price", "schedule", "age", "documents"],
    "missingItems": ["trial"],
    "offTopicElements": []
  },
  "criteria": [
    {
      "id": "information_gathering",
      "label": "Obtention des informations",
      "weight": 0.20,
      "level": "B1",
      "score": 3,
      "evidence": ["Le prix, les horaires, l'âge et les documents ont été demandés."],
      "action": "Pensez aussi à demander les possibilités d'essai."
    }
  ],
  "interactionMetrics": {
    "relevantQuestions": 7,
    "followUpQuestions": 2,
    "redundantQuestions": 1,
    "offTopicQuestions": 0,
    "candidateSpeakingRatio": 0.56,
    "longPauses": 2,
    "agentHelpCount": 1
  },
  "strengths": [],
  "improvements": [],
  "corrections": [],
  "trainingPlan": [],
  "evaluatorConsensus": {
    "evaluatorALevel": "B1",
    "evaluatorBLevel": "B1",
    "adjudicationRequired": false
  }
}
```

---

# 18. Modifications backend conseillées

## 18.1 `ai_evaluations`

Ajouter ou garantir :

```sql
rubric_version VARCHAR(80) NOT NULL,
schema_version VARCHAR(80) NOT NULL,
evaluator_model VARCHAR(120) NOT NULL,
evaluator_passes JSONB NOT NULL,
result_json JSONB NOT NULL,
confidence VARCHAR(16) NOT NULL,
validity_status VARCHAR(32) NOT NULL,
estimated_cefr_level VARCHAR(16),
estimated_score_20 NUMERIC(4,1),
pedagogical_score SMALLINT,
created_at TIMESTAMPTZ NOT NULL DEFAULT now()
```

## 18.2 `conversation_turns`

```sql
id UUID PRIMARY KEY,
submission_id UUID NOT NULL,
turn_index INTEGER NOT NULL,
speaker VARCHAR(16) NOT NULL,
start_ms INTEGER,
end_ms INTEGER,
transcript TEXT NOT NULL,
intent VARCHAR(64),
question_type VARCHAR(64),
linked_slot VARCHAR(80),
metadata JSONB NOT NULL DEFAULT '{}'::jsonb
```

## 18.3 `production_tasks`

Ajouter une configuration par tâche :

```sql
rubric JSONB NOT NULL,
agent_role_card JSONB,
expected_level VARCHAR(16),
min_words INTEGER,
max_words INTEGER,
min_duration_seconds INTEGER,
max_duration_seconds INTEGER,
format_version VARCHAR(40) NOT NULL
```

## 18.4 Historisation

Ne jamais recalculer silencieusement une ancienne évaluation avec une nouvelle grille.

Stocker :

```text
promptVersion
rubricVersion
schemaVersion
model
transcriptionModel
agentVersion
```

---

# 19. Prompts IA — règles obligatoires

Le prompt évaluateur doit imposer :

1. évaluer l'accomplissement avant la langue ;
2. utiliser uniquement les preuves présentes ;
3. ne pas supposer une erreur de prononciation à partir de la transcription seule ;
4. ne pas pénaliser une opinion ou un accent ;
5. distinguer erreurs locales et systématiques ;
6. respecter le format spécifique TCF IRN ;
7. ne pas inventer de note officielle ;
8. produire du JSON strict ;
9. donner des preuves textuelles pour chaque critère ;
10. limiter les conseils à trois priorités concrètes.

### 19.1 Sortie invalide

Rejeter et relancer si :

- niveau hors enum ;
- poids manquant ;
- score incohérent avec le niveau ;
- absence de preuve ;
- critère générique non prévu pour la tâche ;
- total des poids différent de 1 ;
- JSON non conforme.

---

# 20. Calibration et tests

## 20.1 Jeu de calibration

Créer pour chaque tâche au moins :

- 20 productions A1 non atteint/A1 ;
- 20 productions A2 ;
- 20 productions B1 ;
- 20 productions B2 ;
- accents et langues maternelles variés ;
- productions courtes, longues, hors sujet et mémorisées ;
- audio de qualité variable.

Chaque production doit être annotée par au moins deux enseignants FLE connaissant le TCF.

## 20.2 Mesures

- accord exact IA/humain ;
- accord à ±1 niveau ;
- matrice de confusion ;
- stabilité sur trois exécutions ;
- taux de JSON invalide ;
- sévérité moyenne par tâche ;
- différences selon accent, genre de voix et qualité audio ;
- taux de faux « hors sujet » ;
- taux de faux « B2 » sur texte mémorisé.

## 20.3 Critère de mise en production

Objectif minimum conseillé :

```text
>= 80 % d'accord exact sur A2/B1/B2
>= 95 % d'accord à un palier près
< 2 % de réponses JSON invalides après retry
pas de biais notable selon l'accent ou le type de voix
```

---

# 21. Ordre d'implémentation

## Priorité 1 — corriger la notation actuelle

- corriger les longueurs EE du TCF IRN ;
- remplacer les quatre critères génériques par des rubriques par tâche ;
- ajouter contrôles de validité ;
- ajouter `demonstratedLevel`, `targetStatus` et `confidence` ;
- afficher l'accomplissement avant la grammaire.

## Priorité 2 — EO2 temps réel

- fiche agent structurée ;
- sauvegarde des tours ;
- classification des questions ;
- couverture des informations ;
- analyse des questions de suivi ;
- feedback adapté à l'interaction.

## Priorité 3 — fiabilisation

- double évaluation IA ;
- arbitrage automatique ;
- calibration humaine ;
- versionnement complet ;
- tests de non-régression par tâche et par niveau.

---

# 22. Sources de référence

- France Éducation international — Présentation actuelle du TCF IRN : format, durées, objectifs, longueurs et avertissements de validité.  
  https://www.france-education-international.fr/test/tcf-irn
- France Éducation international — Évaluation des épreuves du TCF : critères linguistiques, pragmatiques et sociolinguistiques.  
  https://www.france-education-international.fr/article/evaluation-epreuves-tcf
- France Éducation international — Déroulement d'une passation : double évaluation de l'oral et absence de préparation EO2 pour l'IRN.  
  https://www.france-education-international.fr/article/deroulement-passation-tcf
- Conseil de l'Europe — CECRL, volume complémentaire 2020 : production, interaction, cohérence, compétence phonologique et intelligibilité.  
  https://rm.coe.int/common-european-framework-of-reference-for-languages-learning-teaching/16809ea0d4

---

## Décision produit finale

L'écran de résultat ne doit plus répondre seulement à :

> « Combien de fautes avez-vous faites ? »

Il doit répondre, dans cet ordre, à :

1. **Avez-vous accompli la tâche ?**
2. **Quel niveau avez-vous réellement montré ?**
3. **Quelles preuves expliquent ce niveau ?**
4. **Quelle est votre priorité pour passer au niveau suivant ?**
5. **Quel exercice précis devez-vous refaire maintenant ?**
