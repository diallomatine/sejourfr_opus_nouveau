# SejourFR — Algorithme d'évolution candidat via le Plan
## V4.2 FINAL — Spécification normative, offline-safe, calibrable et fermée côté front

> **Document de référence unique pour l'implémentation.**
> Cette version intègre la V4, ses correctifs V4.1 (correction du hasard CO/CE, agrégation commutative offline-first, inférence de prérequis sans fausses preuves, politique des séries/examens interrompus, shadow mode mesurable) et les correctifs V4.2 :
>
> - §11.0 — définition explicite de `eligibleEvidenceMassNow` pour `RECEPTIVE_LEVEL` ;
> - §12 bis — règle normative d'attribution de `contentId` et `independenceClass` pour les séries CO/CE (fermeture de la dernière faille du `qualificationGate`) ;
> - §25 bis — contrat de rendu front : le front ne calcule aucun état, aucun niveau, aucun seuil ;
> - §27.2 — types SQL obligatoires des accumulateurs epoch ;
> - §18.6 — `visibleProgress` d'un niveau sans preuve directe ;
> - T33/T34 — tests d'acceptation associés.
>
> En cas de contradiction avec V3 / V3.1 / V4 / V4.1, **V4.2 FINAL prévaut**.

---

# 1. Principe architectural non négociable

La progression ne dépend jamais du point d'entrée.

```text
Activité utilisateur
    ↓
LearningEvidence
    ↓
ProgressionEngine
    ↓
DomainState / SkillState / LevelState
    ↓
PlanEngine
    ↓
Meilleure prochaine action
```

Le Plan ne possède pas la progression.

Une activité faite depuis :

- Plan ;
- Réviser ;
- CO ;
- CE ;
- EE ;
- EO ;
- examen blanc par épreuve ;
- examen complet ;
- vrai sujet ;
- entraînement compétence ;

produit des `LearningEvidence` et peut donc modifier le Plan.

Il est interdit d'utiliser :

```text
startedFromPlan == true
```

comme condition pour qu'une preuve compte.

---

# 2. Objectifs du moteur

Le moteur doit garantir simultanément :

1. cohérence pédagogique ;
2. progression visible et motivante ;
3. validation de maîtrise stricte ;
4. absence de yo-yo ;
5. prise en compte des activités hors Plan ;
6. progression par paliers A2 → B1 → B2 ;
7. un seul niveau actif à la fois pour CO/CE ;
8. pas de remise à zéro après un mauvais examen ;
9. calcul déterministe pour CO/CE ;
10. calcul auditable et versionnable ;
11. coût de recalcul O(1) lors d'un nouvel événement ;
12. possibilité de rejouer tout l'historique lors d'un changement d'algorithme.

---

# 3. Niveaux

Ordre :

```text
A1 < A2 < B1 < B2
```

Pour le Plan TCF IRN, le niveau minimum d'apprentissage proposé dans CO/CE est A2.

Exemple :

```text
niveau estimé CO = A1
objectif = B2
→ activeLearningLevel(CO) = A2
```

Le candidat ne reçoit pas simultanément A2 et B1 pour le même domaine réceptif.

---

# 4. Configuration unique du moteur — À FIGER AVANT LE CODE

Créer un seul fichier versionné :

```text
progression-config-v1.json
```

**Règle absolue : Claude Code ne modifie jamais ce fichier de sa propre initiative.**

Toute modification de valeur métier impose :

```text
nouveau fichier progression-config-vN.json
+ engineVersion N
+ replay contrôlé
```

Configuration normative initiale :

```json
{
  "engineVersion": 1,
  "weightEpoch": "2026-01-01T00:00:00Z",
  "recencyHalfLifeDays": 45,

  "sourceWeights": {
    "FULL_MOCK_EXAM": 1.00,
    "DOMAIN_MOCK": 0.95,
    "FULL_TASK": 0.80,
    "REASSESSMENT": 0.85,
    "DIAGNOSTIC": 0.70,
    "CO_CE_20_SERIES": 0.70,
    "CO_CE_20_SERIES_UNCALIBRATED": 0.50,
    "MICRO_SKILL": 0.35
  },

  "assistanceFactors": {
    "NONE": 1.00,
    "LIGHT": 0.85,
    "HEAVY": 0.60,
    "ANSWER_OR_MODEL_SEEN_BEFORE_SUBMISSION": 0.45
  },

  "independenceFactors": {
    "NEW_CONTENT": 1.00,
    "NEW_CONTENT_SAME_BLUEPRINT": 0.90,
    "REPEATED_EXACT_CONTENT": 0.50
  },

  "independence": {
    "overlapWindowDays": 60,
    "independenceOverlapThreshold": 0.50
  },

  "confidenceK": {
    "RECEPTIVE_LEVEL": 1.50,
    "PRODUCTIVE_SKILL": 1.60
  },

  "thresholds": {
    "RECEPTIVE_LEVEL": {
      "fragileMax": 0.35,
      "progressIn": 0.50,
      "progressOut": 0.40,
      "solidIn": 0.70,
      "solidOut": 0.55,
      "minConfidenceForProgress": 0.35,
      "minConfidenceForSolid": 0.60
    },
    "PRODUCTIVE_SKILL": {
      "fragileMax": 0.45,
      "progressIn": 0.55,
      "progressOut": 0.45,
      "readyForReassessment": 0.70,
      "solidIn": 0.75,
      "solidOut": 0.60,
      "minConfidenceForProgress": 0.35,
      "minConfidenceForReady": 0.50,
      "minConfidenceForSolid": 0.60
    }
  },

  "strongEvidence": {
    "RECEPTIVE_LEVEL": {
      "positiveResult": 0.80,
      "negativeResult": 0.25,
      "windowDays": 30,
      "negativeCountToDowngradeSolid": 2
    },
    "PRODUCTIVE_SKILL": {
      "positiveResult": 0.85,
      "negativeResult": 0.40,
      "windowDays": 30,
      "negativeCountToDowngradeSolid": 2
    }
  },

  "qualificationGates": {
    "RECEPTIVE_LEVEL": {
      "mockStrongResult": 0.80,
      "seriesPositiveResult": 0.70,
      "diagnosticPositiveResult": 0.70,
      "confirmationPositiveResult": 0.70
    },
    "PRODUCTIVE_SKILL": {
      "transferResult": 0.75
    }
  },

  "microEvidenceCaps": {
    "maxConfidenceMass": 0.80
  },

  "visibleProgress": {
    "coverageWeight": 0.55,
    "masteryWeight": 0.45,
    "unconfirmedCap": 95,
    "practicePointsRequired": 3.0,
    "practicePoints": {
      "FULL_MOCK_EXAM": 1.50,
      "DOMAIN_MOCK": 1.50,
      "FULL_TASK": 1.20,
      "REASSESSMENT": 1.20,
      "DIAGNOSTIC": 0.80,
      "CO_CE_20_SERIES": 1.00,
      "CO_CE_20_SERIES_UNCALIBRATED": 0.75,
      "MICRO_SKILL": 0.40
    }
  },

  "receptiveSeriesBlueprint": {
    "questionCount": 20,
    "easy": 6,
    "medium": 10,
    "hard": 4
  },

  "shadowValidation": {
    "predictionWindowDays": 30,
    "minSolidPrecision": 0.70
  },

  "maintenance": {
    "maxEpochAgeDays": 1095
  }
}
```

### Pourquoi CO/CE et EE/EO ont des seuils distincts

CO/CE utilise un `result` **corrigé du hasard**. EE/EO utilise les observations IA `0 / 0.5 / 1`.

Les deux échelles ont donc des seuils différents par construction.

Il est interdit de réutiliser silencieusement :

```text
thresholds.PRODUCTIVE_SKILL
```

pour un `RECEPTIVE_LEVEL`, ou l'inverse.

---

# 5. LearningEvidence — registre immuable de ce qui a réellement été fait

Une preuve doit contenir au minimum :

```text
id
userId
attemptId
occurredAt
ingestedAt
entryPoint
sourceType
domain
level
skillId nullable
result               // [0,1], déjà normalisé selon le type d'état
scoringConfidence    // [0,1]
assistanceLevel
contentId
blueprintId nullable
calibrationStatus
independenceClass
engineVersionAtCreation
metadata JSON
```

`entryPoint` décrit l'endroit depuis lequel l'utilisateur a démarré.

`sourceType` décrit la valeur pédagogique de ce qu'il a réellement fait.

Ces deux champs ne doivent jamais être confondus.

### Interdiction des fausses preuves

`LearningEvidence` signifie :

> une observation issue d'une activité réellement effectuée par le candidat.

Il est donc interdit de créer :

```text
syntheticEvidence
syntheticResult
syntheticWeight
```

pour simuler un niveau inférieur validé par un niveau supérieur.

Cette déduction est gérée par `prerequisiteSatisfied`, section 18.

### Temps de l'événement

`occurredAt` est l'heure pédagogique de réalisation/fin de l'activité, pas l'heure de synchronisation.

`ingestedAt` est l'heure d'arrivée serveur.

Une preuve offline arrivée plus tard conserve son `occurredAt`.

Un `occurredAt` impossible dans le futur doit être rejeté ou normalisé par une règle serveur explicite ; il ne doit jamais être accepté silencieusement.

---

# 6. Résultat normalisé `result ∈ [0,1]`

Tous les calculs internes utilisent un résultat normalisé.

## 6.1 CO / CE — correction du hasard obligatoire

Pour toute preuve CO/CE issue de QCM :

```text
accuracy = correctAnswers / totalQuestions

guessRate = moyenne(
    1 / numberOfOptions(question)
) sur toutes les questions de la preuve

result = clamp(
    (accuracy - guessRate) / (1 - guessRate),
    0,
    1
)
```

**Le dénominateur d'une preuve émise est toujours `totalQuestions`, jamais `answeredCount`.**

Exemple, 4 choix par question :

```text
16/20 brut
accuracy = 0.80
guessRate = 0.25
result = (0.80 - 0.25) / 0.75
       = 0.733333...
```

Exemple, 3 choix par question :

```text
16/20 brut
accuracy = 0.80
guessRate = 1/3
result = 0.70
```

Le score affiché à l'utilisateur reste :

```text
16/20
```

La correction du hasard est **interne au moteur de progression**. Elle ne remplace pas les scores TCF affichés ni les statistiques brutes.

## 6.2 Série CO / CE calibrée de 20 questions

Une série est `CALIBRATED` si elle respecte :

```text
20 questions
6 EASY
10 MEDIUM
4 HARD
```

Son `result` est calculé avec §6.1.

## 6.3 Série CO / CE non calibrée

Si l'ancien contenu ne possède pas encore `difficultyBand` ou ne respecte pas le blueprint :

```text
sourceType = CO_CE_20_SERIES_UNCALIBRATED
calibrationStatus = UNCALIBRATED
```

Elle :

- compte dans la progression visible ;
- compte dans `masteryScore` ;
- a un poids réduit à `0.50` ;
- utilise quand même la correction du hasard ;
- ne peut jamais, seule ou avec uniquement d'autres séries non calibrées, satisfaire `qualificationGate`.

## 6.4 Examen blanc CO / CE et examen complet

Chaque question doit posséder au minimum :

```text
level
numberOfOptions
```

Pour chaque niveau `L` réellement mesuré :

```text
questionsL = toutes les questions du domaine au niveau L
accuracyL = correctQuestionsL / totalQuestionsL
guessRateL = moyenne(1 / numberOfOptions(q)) pour questionsL
result(domain,L) = clamp((accuracyL - guessRateL) / (1 - guessRateL), 0, 1)
```

Le moteur peut donc produire plusieurs preuves directes à partir d'un même examen :

```text
CO:A2
CO:B1
CO:B2
```

Il ne faut jamais réduire un examen à un unique niveau opaque si les réponses question par question existent.

## 6.5 EE / EO — observation IA de compétence

Mapping obligatoire :

```text
VALIDATED      → 1.00
PARTIAL        → 0.50
NOT_VALIDATED  → 0.00
```

La confiance renvoyée par l'évaluateur IA devient `scoringConfidence`.

Exemple :

```json
{
  "skillId": "EE_CONNECTEURS_B1",
  "status": "VALIDATED",
  "confidence": 0.86
}
```

produit :

```text
result = 1.00
scoringConfidence = 0.86
```

Aucune correction du hasard n'est appliquée à EE/EO.

---

# 7. Difficulté CO / CE

Chaque question CO/CE doit à terme contenir :

```text
level: A2 | B1 | B2
difficultyBand: EASY | MEDIUM | HARD
```

Pour une série qualifiante de 20 questions :

```text
6 EASY
10 MEDIUM
4 HARD
```

Si la composition n'est pas respectée :

```text
calibrationStatus = UNCALIBRATED
```

et la série ne peut pas confirmer seule un palier.

## Migration progressive

Ne pas bloquer la mise en production si le catalogue actuel n'a pas encore ces tags.

Phase migration :

```text
questions historiques → MEDIUM par défaut
series historiques → UNCALIBRATED
```

Puis enrichir le catalogue.

À terme, les tags manuels pourront être remplacés par une difficulté empirique calculée à partir du taux de réussite par item.

---

# 8. Poids d'une preuve

## 8.1 Décroissance temporelle

```text
lambda = ln(2) / 45
recencyFactor(days) = exp(-lambda × days)
```

Donc une preuve perd la moitié de son poids après 45 jours.

Elle n'est jamais supprimée automatiquement.

## 8.2 Poids hors récence

```text
baseEffectiveWeight =
    sourceWeight(sourceType)
  × scoringConfidence
  × assistanceFactor
  × independenceFactor
```

## 8.3 Poids effectif à l'instant t

```text
effectiveWeight(t) =
    baseEffectiveWeight
  × recencyFactor(daysSinceEvidence)
```

Aucun plancher artificiel n'est appliqué à la maîtrise.

Une preuve très assistée doit réellement peser moins.

---

# 9. Deux systèmes séparés : progression visible et maîtrise

C'est obligatoire.

## 9.1 Mastery

Le `masteryScore` décide des états pédagogiques.

Il peut monter ou descendre.

Il reste strict.

## 9.2 VisibleProgress

Le `visibleProgress` sert à montrer au candidat qu'il avance.

Il est plus généreux.

Pendant un même palier d'apprentissage il ne redescend jamais suite à une seule mauvaise activité.

Il est plafonné à 95 tant que le palier n'est pas confirmé.

À confirmation :

```text
visibleProgress = 100
```

Puis le niveau suivant démarre dans un nouveau cycle de progression visible.

Cette séparation évite que :

```text
20 exercices utiles
→ presque aucun mouvement UI
```

simplement parce que leurs poids de maîtrise sont faibles.

---

# 10. Agrégation exacte, commutative et offline-safe

La mise à jour ne doit jamais dépendre de l'ordre de synchronisation.

Définir :

```text
EPOCH = config.weightEpoch
lambda = ln(2) / recencyHalfLifeDays
```

Pour chaque preuve `e` :

```text
baseW = baseEffectiveWeight(e)
daysFromEpoch = days(EPOCH, e.occurredAt)

storedW = baseW × exp(lambda × daysFromEpoch)
```

Pour un `stateKey`, stocker :

```text
sumWeightEpoch
sumWeightedResultEpoch
```

À l'écriture :

```text
sumWeightEpoch += storedW
sumWeightedResultEpoch += storedW × e.result
```

Aucun decay n'est appliqué à l'écriture.

Le `masteryScore` est :

```text
masteryScore =
    if sumWeightEpoch == 0 then null
    else sumWeightedResultEpoch / sumWeightEpoch
```

Cette moyenne contient déjà la préférence de récence : une preuve plus récente reçoit un `storedW` supérieur.

### Propriété obligatoire

Pour deux preuves A et B :

```text
apply(A); apply(B)
```

doit produire exactement le même agrégat que :

```text
apply(B); apply(A)
```

à l'erreur flottante près (`epsilon <= 1e-12`).

Le moteur est donc :

```text
commutatif
associatif
rejouable
offline-safe
```

Il est interdit d'appeler :

```text
decayStateTo(state, e.occurredAt)
```

dans le chemin d'ingestion.

---

# 11. Confiance exacte

La confiance n'est pas le score.

À l'instant `t` :

```text
decayToNow = exp(-lambda × days(EPOCH, t))
rawMassNow = sumWeightEpoch × decayToNow
```

Puis :

```text
confidence = min(1, eligibleEvidenceMassNow / K)
```

avec :

```text
K = 1.50 pour RECEPTIVE_LEVEL
K = 1.60 pour PRODUCTIVE_SKILL
```

## 11.0 Masse éligible par type d'état — définition obligatoire

`eligibleEvidenceMassNow` n'a pas la même définition selon le `stateType`. Les deux cas sont normatifs et **aucun des deux ne doit être déduit par analogie**.

### RECEPTIVE_LEVEL

```text
eligibleEvidenceMassNow = rawMassNow
```

Aucun cap de famille de sources n'est appliqué à CO/CE.

La protection contre les preuves faibles y est déjà assurée par trois mécanismes distincts :

```text
sourceWeights (UNCALIBRATED = 0.50)
qualificationGate (§16)
independenceClass (§12 et §12 bis)
```

### PRODUCTIVE_SKILL

```text
eligibleEvidenceMassNow =
    nonMicroMassNow
  + min(microMassNow, microEvidenceCaps.maxConfidenceMass)
```

Voir §11.1.

### Interdiction

Il est interdit d'appliquer le cap micro à un `RECEPTIVE_LEVEL`, et interdit d'omettre le cap micro sur un `PRODUCTIVE_SKILL`.

## 11.1 Cap des micro-sujets

Pour une compétence EE/EO, maintenir séparément la masse epoch des familles de sources.

À l'instant `t` :

```text
microMassNow = microSumWeightEpoch × decayToNow
nonMicroMassNow = nonMicroSumWeightEpoch × decayToNow

eligibleEvidenceMassNow =
    nonMicroMassNow
  + min(microMassNow, 0.80)
```

Donc 50 micro-sujets ne peuvent jamais, à eux seuls, fournir toute la confiance nécessaire à `SOLID`.

La partie restante doit venir de preuves de transfert :

```text
FULL_TASK
REASSESSMENT
DOMAIN_MOCK
FULL_MOCK_EXAM
```

## 11.2 Effet du temps

Sans nouvelle preuve :

- `masteryScore` reste identique ;
- `confidence` diminue progressivement ;
- le moteur peut recommander une vérification/entretien ;
- la simple baisse de confiance avec le temps ne constitue pas une contradiction forte et ne rétrograde pas seule un `SOLID`.

---

# 12. Diversité / indépendance

Une répétition exacte ne doit pas être équivalente à un nouveau sujet.

```text
NEW_CONTENT                 = 1.00
NEW_CONTENT_SAME_BLUEPRINT  = 0.90
REPEATED_EXACT_CONTENT      = 0.50
```

Pour compter comme deux contradictions indépendantes ou deux confirmations indépendantes :

```text
contentId différents
ET
attemptId différents
```

Une simple seconde correction de la même soumission n'est pas une nouvelle preuve indépendante.

---

# 12 bis. Attribution normative de `contentId` et `independenceClass`

Cette section ferme la dernière faille exploitable du `qualificationGate`.

Sans elle, avec une banque de questions de taille MVP, deux séries « différentes » partagent une large part de leurs items. Un candidat qui relance des séries jusqu'à retomber sur les questions qu'il connaît déjà satisfait le Cas B de §16 sans avoir rien appris.

`independenceClass` n'est donc **jamais** fourni par le client. Il est **toujours** calculé côté serveur au moment de créer la `LearningEvidence`.

## 12 bis.1 `contentId` d'une série CO / CE

```text
contentId = sha256( join( sort( questionIds ), "|" ) )
```

Deux séries composées exactement des mêmes questions, quel que soit l'ordre de présentation, ont donc le même `contentId`.

Pour une tâche EE/EO :

```text
contentId = sujetId (identifiant du sujet réellement traité)
```

Pour un examen blanc ou complet :

```text
contentId = examTemplateInstanceId
```

## 12 bis.2 Calcul du recouvrement

Soit `S` la série en cours d'ingestion et `H` l'ensemble des séries déjà enregistrées pour le même :

```text
userId + domain + level
```

dans une fenêtre de :

```text
overlapWindowDays = 60
```

Pour chaque série antérieure `P` :

```text
overlap(S, P) =
    | questionIds(S) ∩ questionIds(P) |
    / | questionIds(S) |

maxOverlap = max( overlap(S, P) ) pour P ∈ H
             0 si H est vide
```

## 12 bis.3 Attribution

```text
if contentId(S) existe déjà dans H:
    independenceClass = REPEATED_EXACT_CONTENT      // 0.50

else if maxOverlap >= independenceOverlapThreshold: // 0.50
    independenceClass = NEW_CONTENT_SAME_BLUEPRINT  // 0.90

else:
    independenceClass = NEW_CONTENT                 // 1.00
```

## 12 bis.4 Effet sur le `qualificationGate`

Règle dure, en complément de §16 Cas B :

```text
Deux séries ne comptent comme deux preuves qualifiantes indépendantes
que si :

    contentId différents
ET  attemptId différents
ET  independenceClass != REPEATED_EXACT_CONTENT
ET  overlap(S, P) < independenceOverlapThreshold
```

Autrement dit :

```text
maxOverlap >= 0.50
→ la série alimente masteryScore, confidence et visibleProgress
→ mais ne peut PAS servir de deuxième preuve qualifiante
```

## 12 bis.5 Conséquence pour la génération de séries

Le générateur de séries doit préférer, à niveau et blueprint constants, les questions les moins vues récemment par l'utilisateur.

Si la banque de questions d'un couple `domain + level` est trop petite pour produire une seconde série sous le seuil de recouvrement, le moteur ne doit pas assouplir la règle : il doit remonter l'information.

```text
CONTENT_BANK_TOO_SMALL(domain, level)
```

Cet événement est loggué (§46) et sert à prioriser la production de contenu. Il ne modifie jamais les seuils.

## 12 bis.6 Ajout à la configuration

Ajouter à `progression-config-v1.json`, bloc `independence` :

```json
"independence": {
  "overlapWindowDays": 60,
  "independenceOverlapThreshold": 0.50
}
```

---

# 13. États normalisés

```text
NOT_EVALUATED
FRAGILE
PROGRESSING
READY_FOR_REASSESSMENT
SOLID
WATCH
```

---

# 14. Machine à états — fonctions pures par type d'état

Toujours sélectionner les seuils via :

```text
thresholdProfile(stateType)
```

Jamais via des constantes codées en dur.

## 14.1 État sans preuve

```text
sumWeightEpoch == 0
→ NOT_EVALUATED
```

## 14.2 Transition vers PROGRESSING

### RECEPTIVE_LEVEL

```text
masteryScore >= 0.50
AND confidence >= 0.35
```

### PRODUCTIVE_SKILL

```text
masteryScore >= 0.55
AND confidence >= 0.35
```

Si ces conditions ne sont pas atteintes et qu'il existe des preuves :

```text
FRAGILE
```

## 14.3 READY_FOR_REASSESSMENT — uniquement EE/EO

```text
stateType = PRODUCTIVE_SKILL
AND masteryScore >= 0.70
AND confidence >= 0.50
AND transferGate == false
```

## 14.4 SOLID — CO/CE

```text
stateType = RECEPTIVE_LEVEL
AND masteryScore >= 0.70
AND confidence >= 0.60
AND qualificationGate == true
```

## 14.5 SOLID — EE/EO

```text
stateType = PRODUCTIVE_SKILL
AND masteryScore >= 0.75
AND confidence >= 0.60
AND transferGate == true
```

## 14.6 Hystérésis PROGRESSING

Un état déjà `PROGRESSING` ne retourne à `FRAGILE` que si une nouvelle preuve directe fait passer :

```text
RECEPTIVE_LEVEL  masteryScore < 0.40
PRODUCTIVE_SKILL masteryScore < 0.45
```

La baisse de confiance par vieillissement seule ne provoque pas ce retour.

## 14.7 Hystérésis SOLID

Un état `SOLID` ne sort jamais de `SOLID` par simple franchissement marginal du seuil d'entrée.

Sortie possible uniquement via le mécanisme `WATCH` de §15.

---

# 15. Contradictions et WATCH

Une preuve négative forte dépend du type d'état.

### RECEPTIVE_LEVEL

```text
result <= 0.25
AND sourceType in [DOMAIN_MOCK, FULL_MOCK_EXAM, CO_CE_20_SERIES]
AND occurredAt dans les 30 derniers jours
```

Une série `UNCALIBRATED` ne déclenche jamais à elle seule une contradiction forte.

### PRODUCTIVE_SKILL

```text
result <= 0.40
AND sourceType in [FULL_TASK, REASSESSMENT, DOMAIN_MOCK, FULL_MOCK_EXAM]
AND occurredAt dans les 30 derniers jours
```

Si un état est `SOLID` et reçoit une première contradiction forte indépendante :

```text
SOLID → WATCH
```

Le Plan propose une vérification ciblée.

Pour rétrograder réellement :

### RECEPTIVE_LEVEL

```text
>= 2 contradictions fortes indépendantes dans 30 jours
AND masteryScore < 0.55
AND confidence >= 0.60
```

### PRODUCTIVE_SKILL

```text
>= 2 contradictions fortes indépendantes dans 30 jours
AND masteryScore < 0.60
AND confidence >= 0.60
```

Alors :

```text
WATCH → PROGRESSING
```

ou `FRAGILE` si le score est sous `fragileMax` du profil correspondant.

Une nouvelle preuve forte positive pendant `WATCH` peut ramener :

```text
WATCH → SOLID
```

si les conditions `SOLID` sont de nouveau satisfaites.

---

# 16. QualificationGate CO / CE — preuves directes uniquement

Un niveau CO/CE peut devenir `SOLID` si score/confiance sont atteints ET si une des conditions suivantes est vraie.

## Cas A — examen fort

Au moins une preuve **directe** :

```text
DOMAIN_MOCK ou FULL_MOCK_EXAM
result >= 0.80
```

## Cas B — entraînement confirmé

Au moins deux séries :

```text
sourceType = CO_CE_20_SERIES
calibrationStatus = CALIBRATED
contentId différents
attemptId différents
```

et :

```text
au moins une des deux a result >= 0.70
```

## Cas C — diagnostic + confirmation

```text
DIAGNOSTIC direct result >= 0.70
+ au moins une preuve directe indépendante parmi :
  - série CALIBRATED result >= 0.70
  - DOMAIN_MOCK result >= 0.70
  - FULL_MOCK_EXAM result >= 0.70
```

Un diagnostic seul ne verrouille jamais durablement un palier.

Une série `UNCALIBRATED` ne satisfait jamais un `qualificationGate`.

### directQualification

Définir :

```text
directQualification(levelState) =
    levelState.status == SOLID
    AND qualificationGateDirect(levelState) == true
```

Ce booléen signifie :

> le candidat a directement prouvé ce niveau avec de vraies preuves qualifiantes de ce niveau.

---

# 17. TransferGate EE / EO

Pour qu'une compétence EE/EO devienne `SOLID`, il faut au moins une preuve de transfert directe :

```text
FULL_TASK
REASSESSMENT
DOMAIN_MOCK
FULL_MOCK_EXAM
```

avec :

```text
result >= 0.75
```

Les micro-sujets seuls peuvent atteindre :

```text
READY_FOR_REASSESSMENT
```

mais jamais `SOLID`.

Plusieurs vraies tâches positives peuvent rendre une compétence `SOLID` sans obliger le candidat à faire les 5 micro-sujets.

---

# 18. Inférence hiérarchique des prérequis CO / CE — sans preuve synthétique

Une performance directe qualifiante à un niveau supérieur permet de considérer les prérequis inférieurs comme satisfaits **pour la prescription**, sans falsifier leur historique.

Il n'est créé aucun `LearningEvidence` inférieur.

## 18.1 Fonction normative

```text
function prerequisiteSatisfied(domain, lowerLevel, levelStates):

    for higherLevel in levelsStrictlyAbove(lowerLevel):
        if levelStates[higherLevel].status == SOLID
           AND directQualification(levelStates[higherLevel]) == true:
            return true

    return false
```

## 18.2 Transitivité explicite

```text
B1 direct SOLID
→ prerequisiteSatisfied(A2) = true

B2 direct SOLID
→ prerequisiteSatisfied(B1) = true
→ prerequisiteSatisfied(A2) = true
```

## 18.3 Source valide

Seul un niveau supérieur :

```text
status = SOLID
AND directQualification = true
```

peut satisfaire un prérequis inférieur.

Un niveau qui est seulement :

```text
prerequisiteSatisfied = true
```

ne propage rien à son tour.

## 18.4 Révocabilité

`prerequisiteSatisfied` est **dérivé à la lecture/reprojection**, pas enregistré comme acquis définitif.

Si le niveau supérieur passe :

```text
SOLID → WATCH
```

ou sous `SOLID`, il ne peut plus satisfaire le prérequis inférieur tant que le WATCH n'est pas résolu.

## 18.5 UI

Si A2 n'a pas de preuve directe mais est satisfait via B1 :

```text
ne pas afficher : A2 = 0 %
ne pas inventer : A2 masteryScore = 1.0
```

Afficher :

```text
A2 — Validé via B1
```

Si B2 est la preuve directe la plus proche disponible :

```text
A2 — Validé via B2
```

Pour ce cas, le pourcentage de progression peut être masqué. `prerequisiteSatisfied` n'est pas un score TCF.

## 18.6 `visibleProgress` d'un niveau sans preuve directe

Règle normative :

```text
si sumWeightEpoch(stateKey) == 0
   (aucune LearningEvidence directe n'a jamais été enregistrée)

alors visibleProgress = null
```

`null` signifie **absence de mesure**, jamais `0`.

Conséquences :

```text
null → le front n'affiche aucun pourcentage
null → le front affiche uniquement l'état textuel
null → la règle max(previousVisibleProgress, candidate) de §25 ne s'applique pas
```

Ceci couvre notamment le chemin de révocation :

```text
1. B1 devient SOLID direct
2. prerequisiteSatisfied(A2) = true
   → A2 affiché « Validé via B1 », pourcentage masqué
3. B1 reçoit une contradiction forte → WATCH
4. prerequisiteSatisfied(A2) redevient false
5. A2 n'a toujours aucune preuve directe
   → visibleProgress(A2) reste null
   → statut A2 = NOT_EVALUATED
   → le front affiche « À évaluer », toujours sans pourcentage
```

Il est interdit d'afficher `A2 — 0 %` dans ce cas : le candidat n'a pas régressé, il n'a simplement jamais été mesuré directement à ce niveau.

Voir T33.

---

# 19. activeLearningLevel CO / CE

Définir :

```text
function isLevelCleared(domain, level, levelStates):
    return levelStates[level].status == SOLID
        OR prerequisiteSatisfied(domain, level, levelStates)
```

Puis :

```text
function computeActiveLearningLevel(domain, objectiveLevel, levelStates):

    if objectiveLevel < A2:
        return null

    if not isLevelCleared(domain, A2, levelStates):
        return A2

    if objectiveLevel == A2:
        return null

    if not isLevelCleared(domain, B1, levelStates):
        return B1

    if objectiveLevel == B1:
        return null

    if not isLevelCleared(domain, B2, levelStates):
        return B2

    return null
```

### WATCH prioritaire

`activeLearningLevel` désigne le niveau normal d'apprentissage.

Si un ancien niveau direct est en `WATCH`, définir :

```text
prescriptionLevel(domain) = WATCH level prioritaire
```

sinon :

```text
prescriptionLevel(domain) = activeLearningLevel(domain)
```

Pendant cette vérification, le Plan ne propose pas simultanément le niveau inférieur nouvellement redevenu non-cleared.

Donc même avec une révocation de prérequis :

```text
B1 WATCH
A2 plus satisfait implicitement
```

le Plan fait d'abord :

```text
Vérification B1
```

et ne produit jamais :

```text
CO A2 + CO B1
```

le même jour.

---

# 20. Règle dure du Plan pour CO / CE

Au moment de construire `Aujourd'hui` :

```text
for domain in [CO, CE]:
    level = prescriptionLevel(domain)
    candidates = candidates.filter(level == level)
```

Les actions `WATCH_RECHECK` sont générées au niveau du WATCH et ont priorité sur l'entraînement normal du domaine.

Il est interdit de produire :

```text
Aujourd'hui
- CO A2
- CO B1
```

Il est permis de produire :

```text
Aujourd'hui
- CO A2
- CE B1
- EE tâche 2
```

car les domaines évoluent indépendamment.

**Invariant : au maximum un niveau CO et un niveau CE sont prescrits dans une même séance Plan.**

---

# 21. Activité hors Plan à un niveau supérieur

Exemple :

```text
activeLearningLevel(CO) = A2
utilisateur va dans Réviser → CO B1
```

Comportement :

1. enregistrer uniquement la vraie preuve `CO:B1` ;
2. recalculer `CO:B1` ;
3. ne créer aucune preuve synthétique A2 ;
4. recalculer `directQualification(B1)` ;
5. recalculer `prerequisiteSatisfied(A2)` ;
6. recalculer `activeLearningLevel` ;
7. recalculer le Plan.

Si B1 devient directement `SOLID` :

```text
A2 peut devenir "Validé via B1"
```

et le candidat ne sera pas forcé de refaire A2.

Si B1 n'est pas directement `SOLID` :

```text
Plan normal reste A2
```

Ses preuves B1 sont conservées et réutilisées lorsque B1 deviendra le niveau actif.

---

# 22. Diagnostic incomplet

Si le candidat n'a jamais été évalué sur certains domaines :

```text
CO = connu
CE = inconnu
EE = connu
EO = inconnu
```

le Plan doit considérer les domaines inconnus comme `NOT_EVALUATED`.

Il peut proposer :

```text
Compléter votre diagnostic
```

si cela améliore significativement la personnalisation.

Priorité recommandée :

```text
si >= 2 domaines inconnus → diagnostic complet dans les priorités hautes
si 1 seul domaine inconnu → diagnostic de ce domaine ou activité qualifiante
```

Ne jamais inventer un niveau pour un domaine non évalué.

---

# 23. Examen blanc / série interrompue — politique normative

Il faut distinguer `practice` et `assessment`.

## 23.1 Série Réviser CO/CE incomplète

Si :

```text
sourceType = CO_CE_20_SERIES
answeredCount < totalQuestions
```

alors :

```text
AUCUNE LearningEvidence de maîtrise
```

L'abandon n'est pas un échec pédagogique.

Ajouter uniquement des points de parcours proratisés :

```text
partialPracticePoints =
    fullPracticePoints(sourceType)
    × answeredCount / totalQuestions
```

Pour une série calibrée standard :

```text
1.00 × answeredCount / 20
= 0.05 × answeredCount
```

Exemple :

```text
12 questions répondues
→ 0 LearningEvidence
→ 0.60 practicePoints
```

## 23.2 Examen blanc abandonné volontairement

Si :

```text
completionStatus = ABANDONED
```

alors :

```text
aucune LearningEvidence de maîtrise
```

Les points de parcours peuvent être proratisés, mais l'examen ne peut ni confirmer ni contredire un acquis.

## 23.3 Interruption technique

Si :

```text
completionStatus = INTERRUPTED_TECHNICAL
```

alors :

- ne pas émettre de preuve ;
- ne pas pénaliser ;
- autoriser la reprise si le produit le permet.

## 23.4 Examen soumis ou temps expiré

Si :

```text
completionStatus = SUBMITTED
ou
completionStatus = TIME_EXPIRED
```

alors la tentative est qualifiante et :

```text
accuracy = correctAnswers / totalQuestions
```

Les questions non répondues comptent donc comme incorrectes.

Puis appliquer la correction du hasard de §6.1.

**Il est interdit d'utiliser `correctAnswers / answeredCount` pour une LearningEvidence émise.**

## 23.5 Portée d'un DOMAIN_MOCK

Un examen blanc lancé depuis n'importe où produit des preuves fortes uniquement pour le domaine concerné.

Il peut :

- confirmer un palier ;
- faire passer `SOLID → WATCH` ;
- révéler de nouvelles compétences EE/EO faibles ;
- modifier les priorités du Plan.

Il ne doit jamais :

- effacer l'historique ;
- remettre toutes les compétences à zéro ;
- modifier les domaines non concernés.

---

# 24. Examen complet

Un examen complet produit des preuves pour les 4 domaines.

Il a le poids maximal :

```text
FULL_MOCK_EXAM = 1.00
```

Mais il n'efface jamais les preuves précédentes.

Il agit comme une nouvelle mesure forte.

Un examen complet très bon peut :

- confirmer plusieurs paliers ;
- faire avancer immédiatement le Plan ;
- corriger un diagnostic initial trop faible.

Un examen complet faible peut :

- mettre certains acquis en WATCH ;
- ouvrir des vérifications ;
- réordonner les priorités ;

mais pas tout réinitialiser.

---

# 25. Progression visible exacte — toujours libellée « Progression du parcours »

Pour le palier actif d'un domaine ou d'une compétence :

```text
coverage = min(1, practicePoints / 3.0)
masteryComponent = masteryScore ?? 0

candidateVisibleProgress =
    100 × (
        0.55 × coverage
      + 0.45 × masteryComponent
    )
```

Si palier non `SOLID` :

```text
candidateVisibleProgress = min(95, candidateVisibleProgress)
visibleProgress = max(previousVisibleProgress, round(candidateVisibleProgress))
```

Si palier directement `SOLID` :

```text
visibleProgress = 100
```

Quand on passe au niveau suivant :

```text
nouveau levelCycleId
visibleProgress du nouveau cycle = 0
```

Le 100 % de l'ancien niveau reste visible dans l'historique.

## Contrat UI

Le pourcentage doit être nommé explicitement :

```text
Progression du parcours
```

Il ne doit jamais être présenté comme :

```text
score TCF
niveau CECRL
probabilité de réussite
```

Toujours lui associer un état textuel :

```text
NOT_EVALUATED           → À évaluer
FRAGILE                 → À renforcer
PROGRESSING             → En progression
READY_FOR_REASSESSMENT  → Prêt à vérifier
SOLID                   → Acquis
WATCH                   → À vérifier
```

Pour un niveau seulement satisfait par prérequis :

```text
Validé via B1
Validé via B2
```

et masquer le pourcentage de ce niveau si aucune progression directe n'existe.

---

# 25 bis. Contrat de rendu front — normatif

## 25 bis.1 Principe

```text
LE FRONT NE CALCULE AUCUN ÉTAT,
AUCUN NIVEAU CECRL,
AUCUN SEUIL.
```

Toute logique de classement d'un nombre en état pédagogique ou en niveau CECRL est une **duplication du moteur** et est interdite au même titre qu'un second référentiel ou un second moteur d'examen (§50).

Cette règle s'applique au web Next.js, au mobile Flutter et à la console admin.

## 25 bis.2 Contrat de données

Le serveur expose, par `stateKey` :

```text
stateKey
stateType                       // RECEPTIVE_LEVEL | PRODUCTIVE_SKILL
status                          // enum, 6 valeurs de §13
statusLabel                     // libellé FR fourni par le serveur
visibleProgress                 // int 0-100, ou null (§18.6)
directQualification             // bool
prerequisiteSatisfied           // bool
prerequisiteSatisfiedByLevel    // A2 | B1 | B2 | null
levelCycleId
```

Le front consomme ces champs tels quels.

Il ne reçoit jamais :

```text
masteryScore
confidence
sumWeightEpoch
```

Ces valeurs sont internes au moteur. Elles ne sont exposées que dans la console admin et dans `progression_prediction_log` (§47).

## 25 bis.3 Mapping état → rendu

Le `tone` visuel est dérivé de `status`, **jamais d'un nombre** :

```text
NOT_EVALUATED           → neutral   → « À évaluer »
FRAGILE                 → danger    → « À renforcer »
PROGRESSING             → primary   → « En progression »
READY_FOR_REASSESSMENT  → accent    → « Prêt à vérifier »
SOLID                   → success   → « Acquis »
WATCH                   → warn      → « À vérifier »
```

Les six états doivent tous être représentés. Une UI qui ne gère que quatre états est non conforme : `WATCH` et `READY_FOR_REASSESSMENT` sont précisément ceux qui portent la valeur pédagogique du produit.

Rappel design system : le rouge est réservé aux CTA critiques et aux signaux d'urgence. `FRAGILE` utilise le rouge de la charte ; les autres états utilisent le bleu, le vert ou l'ambre.

## 25 bis.4 Code à supprimer du design existant

Le prototype Claude Design fourni contient un second moteur de progression. Il doit être supprimé, non adapté :

```js
// À SUPPRIMER INTÉGRALEMENT
function masteryTone(v)  { return v >= 80 ? "success" : v >= 60 ? "primary"
                                 : v >= 40 ? "warn" : "danger"; }

function masteryLabel(v) { return v >= 80 ? "Solide" : v >= 60 ? "En bonne voie"
                                 : v >= 40 ? "À renforcer" : "Fragile"; }

function cefr(v)         { return v >= 85 ? "B2" : v >= 65 ? "B1"
                                 : v >= 45 ? "A2" : "A1"; }
```

Ainsi que **tous leurs appels**, notamment les formes suivantes, qui déduisent un niveau CECRL d'un score brut :

```js
cefr(best / 20 * 100)
cefr(sheet.res.last / 20 * 100)
cefr(p.mastery)
cefr(overall)
cefr(tcfAvg)
```

Et toute constante littérale `40 / 45 / 60 / 65 / 80 / 85` utilisée pour classer un état ou un niveau.

Le prototype contient également quatre vocabulaires d'états concurrents :

```text
priorite / renforcer / solide / evaluer
renforcer / acquerir / solide / nonObs
… / solide / nonEvalue / priorite / « Presque acquis »
« Solide » / « En bonne voie » / « À renforcer » / « Fragile »
```

Aucun ne contient `WATCH`. Tous doivent être remplacés par l'unique mapping de §25 bis.3.

## 25 bis.5 Interdiction d'adjacence

```text
Le pourcentage « Progression du parcours » et un libellé de niveau CECRL
ne doivent jamais apparaître dans le même bloc visuel.
```

Le motif suivant, présent dans le prototype, est interdit :

```js
{ v: `${overall}%`, k: "Maîtrise" }, { v: cefr(...), k: "Niveau" }
```

Un pourcentage accolé à un niveau se lit comme un score TCF officiel. C'est exactement l'affichage que §25 interdit.

## 25 bis.6 Affichage d'un niveau CECRL

Un niveau CECRL n'est affiché que si le serveur envoie explicitement :

```text
confirmedLevel        // calculé par §35
confirmedLevelSource  // FULL_MOCK_EXAM | DOMAIN_MOCK | …
```

Il n'est **jamais** dérivé côté client, jamais déduit d'un pourcentage, et jamais affiché sur une compétence isolée, un micro-sujet, un drill ou une série de 20 questions.

Sur ces surfaces, seul l'état textuel de §25 bis.3 est autorisé.

## 25 bis.7 Test de conformité front

Un test statique doit échouer si le code front contient :

```text
- une fonction retournant "A1" | "A2" | "B1" | "B2" à partir d'un nombre ;
- une comparaison d'un pourcentage à 40, 45, 60, 65, 80 ou 85
  suivie d'un libellé d'état ;
- un libellé d'état absent du mapping de §25 bis.3.
```

---

# 26. PracticePoints

Les points de progression visible ne sont pas des preuves de maîtrise.

```text
FULL_MOCK_EXAM                   1.50
DOMAIN_MOCK                      1.50
FULL_TASK                        1.20
REASSESSMENT                     1.20
DIAGNOSTIC                       0.80
CO_CE_20_SERIES                  1.00
CO_CE_20_SERIES_UNCALIBRATED     0.75
MICRO_SKILL                       0.40
```

L'assistance ne doit pas annuler le sentiment d'effort utilisateur.

Pour une activité de pratique interrompue mais réellement travaillée :

```text
partialPracticePoints =
    fullPracticePoints × completedUnits / totalUnits
```

Ces points :

- alimentent uniquement `visibleProgress` ;
- n'ajoutent aucune masse de confiance ;
- n'ajoutent aucun `masteryScore` ;
- ne satisfont aucun gate.

---

# 27. Données matérialisées

Créer au minimum les structures suivantes.

## 27.1 `learning_evidence`

Historique immuable, auditable, idempotent et rejouable.

## 27.2 `progression_state`

Une ligne par :

```text
userId + stateKey + engineVersion
```

Champs minimaux :

```text
stateKey
stateType
masteryScore
confidence
status
sumWeightEpoch
sumWeightedResultEpoch
microSumWeightEpoch
nonMicroSumWeightEpoch
qualifyingEvidenceCount
recentStrongNegativeCount
visibleProgress
practicePoints
levelCycleId
lastEvidenceAt
engineVersion
updatedAt
```

Ne plus utiliser `lastAggregatedAt` pour appliquer un decay lors de l'ingestion.

### 27.2.1 Types SQL obligatoires des accumulateurs epoch

Les accumulateurs epoch croissent exponentiellement par construction :

```text
storedW = baseW × exp(lambda × daysFromEpoch)
lambda  = ln(2) / 45
```

Ordres de grandeur pour `baseW = 1` :

```text
J+365    ≈ 2.8e2
J+1000   ≈ 1.1e5
J+2000   ≈ 1.2e10
J+3650   ≈ 2.6e24
```

Un type décimal à précision fixe déborde donc en quelques années, silencieusement, sur une donnée matérialisée que rien ne recalcule dans le chemin nominal.

**Types obligatoires — Flyway :**

```sql
sum_weight_epoch            double precision NOT NULL DEFAULT 0,
sum_weighted_result_epoch   double precision NOT NULL DEFAULT 0,
micro_sum_weight_epoch      double precision NOT NULL DEFAULT 0,
non_micro_sum_weight_epoch  double precision NOT NULL DEFAULT 0
```

Interdits pour ces quatre colonnes :

```text
NUMERIC(p, s)
DECIMAL(p, s)
BigDecimal côté Java
REAL / float4
```

Côté Java : `double` (primitif) ou `Double`, jamais `BigDecimal`.

Même règle pour `progression_state_family_aggregate` (§27.3).

### 27.2.2 Re-basage de l'epoch

À chaque incrément d'`engineVersion` impliquant un replay complet (§29), le replay **re-base** `weightEpoch` sur la date courante :

```text
progression-config-vN.json
  weightEpoch = date d'activation de la version N
```

Le replay recalcule tous les `storedW` depuis `learning_evidence`, qui reste immuable et exprimé en dates absolues. Aucune conversion d'accumulateur n'est nécessaire.

Un replay complet est donc obligatoire au moins tous les :

```text
maxEpochAgeDays = 1095   // 3 ans
```

même sans changement de seuil, afin de maintenir les accumulateurs dans une plage numérique confortable. Ajouter à la configuration :

```json
"maintenance": {
  "maxEpochAgeDays": 1095
}
```

## 27.3 `progression_state_family_aggregate`

Pour les caps et l'audit des familles de sources :

```text
userId
stateKey
sourceFamily
sumWeightEpoch
sumWeightedResultEpoch
engineVersion
updatedAt
```

## 27.4 Champs de prérequis

`prerequisiteSatisfied` et `prerequisiteSatisfiedByLevel` sont des projections dérivées.

Ils ne doivent pas être traités comme des acquisitions immuables.

Ils peuvent être mis en cache pour performance uniquement si le cache est recalculé à chaque changement d'un niveau supérieur pertinent.

---

# 28. Mise à jour O(1), indépendante de l'ordre

À chaque nouvelle preuve :

```text
handleEvidence(e):

    assertUniqueNaturalKey(e)

    state = lockState(e.stateKey, engineVersion)

    baseW = computeBaseEffectiveWeight(e)
    storedW = toEpochWeight(baseW, e.occurredAt)

    state.sumWeightEpoch += storedW
    state.sumWeightedResultEpoch += storedW * e.result

    updateSourceFamilyEpochAggregates(state, e, storedW)
    updateQualifyingCounters(state, e)
    updatePracticePointsIfApplicable(state, e)

    state.masteryScore = computeMasteryFromEpochSums(state)
    state.confidence = computeConfidenceAt(state, now)
    state.status = transitionPure(state, e, config)
    state.visibleProgress = computeVisibleProgress(state)

    save(state)

    recomputeDerivedPrerequisites(e.userId, e.domain)
    recomputeDomainProjection(e.userId, e.domain)
    writeShadowPredictionIfEligible(e.userId, e.domain)
    recomputePlanProjectionIfEngineActive(e.userId)
```

Aucune lecture de tout l'historique n'est nécessaire dans le chemin nominal.

Aucun tri par `occurredAt` n'est nécessaire pour obtenir le même agrégat mathématique.

---

# 29. Replay complet et déterminisme

Le replay complet est réservé à :

- nouvelle `engineVersion` ;
- changement de config ;
- correction/invalidation de données ;
- audit ;
- migration.

Processus :

```text
1. figer progression-config-vN.json
2. créer engineVersion N
3. relire learning_evidence
4. reconstruire progression_state N
5. calculer les projections dérivées
6. comparer N-1 et N
7. valider les tests et métriques shadow
8. activer N si décision produit
```

Grâce à l'agrégat epoch :

```text
l'ordre de lecture des LearningEvidence ne doit pas modifier le résultat final
```

Pour les compteurs dépendant explicitement de fenêtres temporelles ou de transitions `WATCH`, le replay doit utiliser les timestamps `occurredAt` et les règles normatives, mais pas l'ordre d'ingestion.

Même multiensemble de preuves + même config + même `now` de référence = même projection.

---

# 30. Recommandation du Plan

Le Plan reçoit uniquement des états/projections calculés.

Priorité, dans cet ordre :

```text
1. WATCH à vérifier
2. action sticky encore pertinente
3. READY_FOR_REASSESSMENT
4. compétence bloquante du niveau actif
5. niveau CO/CE actif
6. domaine non évalué important
7. faiblesse secondaire
8. entretien / consolidation
```

Pour CO/CE :

```text
level = prescriptionLevel(domain)
filterReceptionCandidatesByPrescriptionLevel(level)
```

Puis dédupliquer.

Si un `WATCH` existe sur un niveau supérieur, il prend le contrôle du `prescriptionLevel` pour éviter d'afficher simultanément un niveau inférieur et le niveau à vérifier.

---

# 31. Sticky

Une recommandation commencée peut rester prioritaire jusqu'à résolution raisonnable.

Mais elle doit être invalidée automatiquement si une nouvelle preuve forte montre qu'elle n'est plus utile.

Exemple :

```text
Plan recommande micro-compétence EE
utilisateur fait librement deux vraies tâches complètes
compétence devient SOLID
→ supprimer la recommandation sticky
```

---

# 32. Changement d'objectif

Exemple :

```text
objectif initial B1
puis objectif B2
```

Ne jamais recalculer les acquis depuis zéro.

Les états A2/B1 restent.

Le moteur active simplement le prochain palier non `cleared` (`SOLID` direct ou `prerequisiteSatisfied`) jusqu'à B2.

Inversement :

```text
objectif B2 → objectif B1
```

ne supprime pas les preuves B2 déjà acquises.

---

# 33. Changement de niveau estimé

Ne jamais stocker seulement :

```text
currentLevel = B1
```

comme vérité unique.

Stocker les états par niveau :

```text
CO A2 = SOLID
CO B1 = PROGRESSING
CO B2 = NOT_EVALUATED
```

Le niveau estimé affiché est une projection de ces états et des dernières évaluations qualifiantes.

---

# 34. EE / EO : niveau et compétences

Le niveau d'une épreuve productive ne doit pas être la moyenne aveugle de toutes les compétences.

L'évaluation complète renvoie :

```text
estimatedLevel
skillObservations[]
```

Le niveau estimé de domaine utilise les évaluations globales :

```text
DIAGNOSTIC
FULL_TASK quand pertinent
DOMAIN_MOCK
FULL_MOCK_EXAM
```

Les micro-sujets servent principalement aux `SkillState`.

Ils ne doivent pas gonfler directement le niveau global EE/EO.

---

# 35. Promotion d'un palier

## CO / CE

```text
if levelState(activeLearningLevel) becomes SOLID:
    mark current levelCycle completed
    activeLearningLevel = next non-cleared level <= objective
    generate next plan
```

## EE / EO

Le Plan ne doit pas considérer « 5 micro-sujets terminés » comme une promotion.

Il doit chercher :

```text
compétences bloquantes SOLID
+ preuve globale de production cohérente avec le niveau cible
```

---

# 36. Exemple complet — candidat CO A1 objectif B2

État initial :

```text
CO A2 = FRAGILE
CO B1 = NOT_EVALUATED
CO B2 = NOT_EVALUATED
activeLearningLevel = A2
```

Aujourd'hui :

```text
CO — série A2
```

Jamais :

```text
CO A2
CO B1
```

Deux séries calibrées, 4 options par question :

```text
Série #1 : 16/20
rawAccuracy = 0.80
result = 0.733333
weight = 0.70

Série #2 : 17/20
rawAccuracy = 0.85
result = 0.800000
weight = 0.70
```

Même jour, sans assistance :

```text
masteryScore = (0.70×0.733333 + 0.70×0.800000) / 1.40
             = 0.766667

confidence = min(1, 1.40 / 1.50)
           = 0.933333

qualificationGate = true
```

Donc :

```text
CO A2 = SOLID
activeLearningLevel = B1
visibleProgress(A2) = 100
visibleProgress(B1 nouveau cycle) = 0
```

---

# 37. Exemple — candidat ignore le Plan et réussit directement B1

Plan :

```text
CO A2
```

Utilisateur :

```text
Réviser → CO B1
```

Le moteur :

```text
stocke uniquement les vraies preuves B1
recalcule B1
```

Si B1 obtient :

```text
status = SOLID
directQualification = true
```

alors :

```text
prerequisiteSatisfied(CO,A2) = true
UI A2 = "Validé via B1"
```

Le prochain niveau normal est calculé sans imposer artificiellement A2.

Aucune preuve A2 synthétique n'est créée.

---

# 38. Exemple — EE micro-sujets

Candidat travaille plusieurs petits sujets sur une compétence.

Résultats bons :

```text
masteryScore >= 0.70
confidence >= 0.50
transferGate = false
```

État :

```text
READY_FOR_REASSESSMENT
```

Plan :

```text
Vérifier cette compétence sur une vraie tâche EE
```

Vraie tâche réussie :

```text
transferGate = true
masteryScore >= 0.75
confidence >= 0.60
→ SOLID
```

---

# 39. Exemple — candidat saute les micro-sujets

Deux vraies tâches EE indépendantes montrent clairement la compétence.

```text
FULL_TASK #1 result = 1.0
FULL_TASK #2 result = 1.0
```

Si score/confiance/transferGate atteints :

```text
SOLID
```

Il ne faut pas lui imposer artificiellement les 5 micro-sujets.

---

# 40. Exemple — mauvais examen blanc après SOLID

Avant :

```text
CO B1 = SOLID
```

Examen blanc qualifiant :

```text
B1 result = 0.20
```

Comme :

```text
0.20 <= strongEvidence.RECEPTIVE_LEVEL.negativeResult(0.25)
```

première contradiction forte :

```text
CO B1 = WATCH
```

Si A2 était seulement `Validé via B1`, cette inférence est momentanément révoquée.

Mais le Plan prescrit d'abord :

```text
Vérification CO B1
```

et non :

```text
CO A2 + CO B1
```

Deuxième contradiction indépendante + conditions de sortie :

```text
WATCH → PROGRESSING/FRAGILE
```

Une vérification forte positive peut au contraire restaurer :

```text
WATCH → SOLID
```

et réactiver immédiatement les prérequis inférés.

---

# 41. Cas diagnostic non fait

Utilisateur commence directement par Réviser.

Comportement :

- enregistrer ses preuves normalement ;
- ne pas bloquer l'app ;
- le Plan peut déjà exploiter les domaines renseignés par ces activités ;
- proposer un diagnostic uniquement pour les domaines toujours inconnus.

Donc le diagnostic est un accélérateur de personnalisation, pas une condition d'entrée obligatoire.

---

# 42. Idempotence

Chaque tentative ne doit produire ses preuves qu'une fois.

Clé recommandée :

```text
evidenceNaturalKey =
attemptId + sourceType + domain + level + skillId + observationIndex
```

Insertion unique en base.

Un retry réseau ne doit pas doubler la progression.

---

# 43. Événements corrigés / invalidés

Si une évaluation IA est invalidée ou recalculée :

Ne jamais modifier silencieusement l'ancienne preuve immuable.

Créer :

```text
EvidenceInvalidated(oldEvidenceId)
```

puis une nouvelle preuve.

Comme l'agrégat nominal est incrémental, une invalidation nécessite :

- soit une opération delta inverse exacte ;
- soit un replay du `stateKey` concerné.

Choix recommandé : replay ciblé du `stateKey`, car les invalidations sont rares.

---

# 44. IA EE / EO

Le prompt d'évaluation doit renvoyer un JSON strict :

```json
{
  "estimatedLevel": "B1",
  "globalConfidence": 0.84,
  "skillObservations": [
    {
      "skillId": "...",
      "status": "VALIDATED",
      "confidence": 0.87
    }
  ]
}
```

Contraintes :

```text
confidence ∈ [0,1]
status ∈ VALIDATED | PARTIAL | NOT_VALIDATED
skillId doit appartenir au référentiel connu
```

Un `skillId` inconnu doit être rejeté, jamais créé dynamiquement par le LLM.

---

# 45. Tests de stabilité IA

Créer un corpus fixe de productions :

```text
A2 faibles
A2 limites
B1 limites
B1 solides
B2 limites
B2 solides
hors sujet
très courtes
très longues
une compétence forte / reste faible
```

À chaque nouvelle version de prompt/modèle mesurer :

```text
estimatedLevel drift
skill status drift
confidence drift
Plan impact
```

Un changement de modèle ne doit pas être déployé uniquement parce que le JSON parse correctement.

---

# 46. Observabilité

Pour chaque recommandation du Plan, pouvoir expliquer :

```text
Pourquoi cette recommandation ?
```

Log interne minimal :

```text
stateKey
masteryScore
confidence
status
directQualification
prerequisiteSatisfied
prerequisiteSatisfiedByLevel
activeLearningLevel
prescriptionLevel
qualifyingEvidenceCount
recentStrongNegativeCount
topEvidenceIds
engineVersion
recommendationReasonCode
```

Exemples :

```text
ACTIVE_LEVEL_NOT_CLEARED
VALIDATED_VIA_HIGHER_LEVEL
SKILL_FRAGILE
READY_FOR_REASSESSMENT
WATCH_RECHECK
MISSING_ASSESSMENT
NEXT_LEVEL_UNLOCKED
```

---

# 47. Shadow mode — obligatoire avant pilotage réel du Plan

Le moteur doit pouvoir tourner en :

```text
PROGRESSION_ENGINE_MODE=SHADOW
```

Dans ce mode :

- les `LearningEvidence` sont créées ;
- les états V4.1 sont calculés ;
- les prédictions sont persistées ;
- **le Plan utilisateur existant n'est pas modifié par V4.1**.

Le mode :

```text
PROGRESSION_ENGINE_MODE=ACTIVE
```

n'est activé qu'après validation produit des métriques shadow.

## 47.1 Table obligatoire `progression_prediction_log`

Champs minimaux :

```text
id
userId
stateKey
stateType
engineVersion
predictedAt
levelCycleId nullable
masteryScore
confidence
status
readyForMock
directQualification
prerequisiteSatisfied
predictionReason
outcomeAttemptId nullable
outcomeResult nullable
outcomeAt nullable
createdAt
updatedAt
```

## 47.2 Quand écrire une prédiction

Au minimum :

```text
- transition vers SOLID
- transition vers READY_FOR_REASSESSMENT
- transition vers WATCH
- changement de readyForMock
```

Pour la métrique primaire, utiliser la **première transition vers SOLID du cycle** afin d'éviter de compter dix fois le même candidat.

## 47.3 Rattachement à un résultat futur

Pour une prédiction `stateKey = CO:A2` :

chercher le premier :

```text
DOMAIN_MOCK ou FULL_MOCK_EXAM
```

qui :

```text
- appartient au même userId
- contient une mesure directe du même stateKey
- est SUBMITTED ou TIME_EXPIRED
- survient après predictedAt
- survient dans les 30 jours
```

Puis enregistrer :

```text
outcomeAttemptId
outcomeResult // result chance-adjusted du même stateKey
outcomeAt
```

## 47.4 Métrique primaire

Pour les états réceptifs :

```text
SOLID precision =
    nombre de prédictions SOLID dont mock suivant result >= 0.70
    / nombre de prédictions SOLID avec outcome disponible
```

Objectif initial :

```text
SOLID precision >= 70 %
```

Mesurer aussi une métrique stricte :

```text
result >= 0.75
```

mais ne pas l'utiliser comme seuil unique de go/no-go en V1.

Si la précision primaire est < 70 % :

```text
ne pas bricoler progression-config-v1.json
→ analyser les données
→ créer progression-config-v2.json
→ engineVersion 2
→ replay
```

Les seuils initiaux sont des hypothèses produit ; le shadow mode sert à les calibrer avec les vrais candidats SejourFR.

---

# 48. Tests d'acceptation obligatoires

**Les tests sont écrits avant l'implémentation du moteur.**

Pour T01–T06, les valeurs ci-dessous sont normatives et doivent être vérifiées avec une tolérance numérique `1e-6`.

## T01 — une seule bonne série A2 ne suffit pas à verrouiller

Données :

```text
CO:A2
20 questions
4 options chacune
16 correctes
CALIBRATED
NEW_CONTENT
NONE assistance
scoringConfidence = 1
même date de référence
```

Attendu :

```text
rawAccuracy = 0.800000
guessRate = 0.250000
result = 0.733333
baseWeight = 0.700000
masteryScore = 0.733333
confidence = 0.466667
qualificationGate = false
status = PROGRESSING
activeLearningLevel(CO) = A2
visibleProgress = 51
```

Le Plan ne contient aucune activité CO B1.

## T02 — deuxième série 17/20 confirme A2

Ajouter une deuxième série calibrée indépendante :

```text
17/20
4 options
NEW_CONTENT
```

Attendu :

```text
result2 = 0.800000
masteryScore = 0.766667
confidence = 0.933333
qualificationGate = true
status = SOLID
directQualification = true
visibleProgress(A2) = 100
activeLearningLevel(CO) = B1
```

## T03 — preuve B1 isolée hors Plan ne mélange pas A2/B1

Partir de T01 puis ajouter :

```text
CO:B1
18/20
4 options
une seule série calibrée
```

Attendu pour B1 :

```text
result = 0.866667
masteryScore = 0.866667
confidence = 0.466667
qualificationGate = false
status = PROGRESSING
directQualification = false
```

Attendu global :

```text
prerequisiteSatisfied(A2) = false
activeLearningLevel(CO) = A2
```

Aujourd'hui ne contient jamais simultanément CO A2 et CO B1.

## T04 — domaines indépendants

CO utilise l'état de T01.

CE :

```text
A2 = SOLID direct via deux séries 16/20 + 17/20
B1 = une seule série 16/20, 4 options
```

Attendu :

```text
activeLearningLevel(CO) = A2
activeLearningLevel(CE) = B1
```

Le Plan peut contenir :

```text
CO A2
CE B1
```

## T05 — deux séries non calibrées parfaites ne verrouillent pas

Données :

```text
CO:A2
2 séries UNCALIBRATED
20/20 chacune
sourceWeight = 0.50 chacune
```

Attendu :

```text
result1 = result2 = 1.000000
masteryScore = 1.000000
confidence = 0.666667
qualificationGate = false
status != SOLID
status = PROGRESSING
activeLearningLevel = A2
```

## T06 — correction du hasard fonctionne aussi avec 3 options

Deux séries calibrées indépendantes :

```text
16/20 puis 17/20
3 options chacune
```

Attendu :

```text
guessRate = 0.333333
result1 = 0.700000
result2 = 0.775000
masteryScore = 0.737500
confidence = 0.933333
qualificationGate = true
status = SOLID
```

Le comportement ne doit donc pas basculer arbitrairement parce qu'une série possède 3 plutôt que 4 choix.

## T07 — DOMAIN_MOCK fort peut verrouiller seul

```text
DOMAIN_MOCK direct
masteryScore >= 0.70
confidence >= 0.60
result >= 0.80
```

→ `SOLID`.

## T08 — diagnostic seul ne verrouille jamais

Même avec résultat excellent :

```text
DIAGNOSTIC seul
→ qualificationGate = false
→ status != SOLID
```

## T09 — série pratique interrompue

```text
12/20 répondues
completionStatus = ABANDONED/INCOMPLETE
```

Attendu :

```text
0 LearningEvidence
practicePoints = 0.60 pour série calibrée standard
aucune modification mastery/confidence
```

## T10 — mock expiré utilise totalQuestions

```text
20 questions, 4 options
12 répondues
8 correctes
TIME_EXPIRED
```

Attendu :

```text
accuracy = 8/20 = 0.40
result = 0.20
```

et jamais `8/12`.

## T11 — ordre d'ingestion invariant

Trois preuves datées différentes sont injectées dans les 6 permutations possibles.

Attendu :

```text
sumWeightEpoch identique
sumWeightedResultEpoch identique
masteryScore identique
confidence(now) identique
status final identique
```

à `epsilon <= 1e-12` pour les agrégats.

## T12 — retry réseau idempotent

Même `evidenceNaturalKey` injecté deux fois.

Attendu : une seule preuve et aucun doublement d'agrégat.

## T13 — B1 direct SOLID satisfait A2 sans fausse preuve

```text
A2 = NOT_EVALUATED
B1 = SOLID
directQualification(B1) = true
```

Attendu :

```text
prerequisiteSatisfied(A2) = true
aucune LearningEvidence A2 créée
UI A2 = "Validé via B1"
```

## T14 — transitivité B2

```text
B2 = SOLID direct
A2/B1 sans preuve directe
```

Attendu :

```text
prerequisiteSatisfied(B1) = true
prerequisiteSatisfied(A2) = true
```

## T15 — pas de chaîne artificielle

Un niveau B1 seulement `prerequisiteSatisfied` ne peut pas, par lui-même, satisfaire A2.

Seule la vraie qualification directe du niveau supérieur source est utilisée.

## T16 — prérequis révocable

B1 direct `SOLID` valide A2, puis B1 passe `WATCH`.

Attendu :

```text
prerequisiteSatisfied(A2) = false
prescriptionLevel(CO) = B1 // WATCH prioritaire
```

Pas de CO A2 + CO B1 simultané.

## T17 — mauvaise preuve B2 ne dégrade pas automatiquement A2/B1

Une performance B2 négative reste attachée à B2.

Aucune preuve négative synthétique inférieure n'est créée.

## T18 — première contradiction

Un `SOLID` reçoit une première contradiction forte indépendante.

Attendu : `WATCH`, jamais remise à zéro.

## T19 — deuxième contradiction

Deux contradictions indépendantes + seuil de sortie correspondant au type d'état.

Attendu : sortie possible de `WATCH` vers `PROGRESSING/FRAGILE`.

## T20 — 20 micro-sujets seuls ne rendent jamais SOLID

Même `masteryScore = 1`, le cap de confiance + absence de transferGate empêchent SOLID.

## T21 — micro-sujets peuvent rendre READY

Si :

```text
mastery >= 0.70
confidence >= 0.50
transferGate = false
```

→ `READY_FOR_REASSESSMENT`.

## T22 — vraies tâches peuvent rendre une compétence SOLID sans micro-sujets

Deux vraies tâches indépendantes positives, score/confiance/transferGate atteints → `SOLID`.

## T23 — examen blanc EE n'affecte pas CO/CE/EO

Isolation stricte des domaines.

## T24 — examen complet hors Plan = même effet que depuis Plan

`entryPoint` ne modifie jamais la valeur pédagogique.

## T25 — visibleProgress ne baisse pas dans un cycle

Une mauvaise activité isolée ne diminue pas le pourcentage déjà affiché.

## T26 — cap visible avant confirmation

Tant que non `SOLID` :

```text
visibleProgress <= 95
```

## T27 — SOLID direct = 100

À confirmation directe :

```text
visibleProgress = 100
```

## T28 — niveau suivant = nouveau cycle

Nouveau `levelCycleId`, progression visible initiale 0.

## T29 — domaine inconnu

Aucune preuve → `NOT_EVALUATED`; aucun niveau n'est inventé.

## T30 — sticky invalidé par preuve hors Plan

Une recommandation sticky disparaît si une activité externe la rend inutile.

## T31 — shadow prediction immuable dans le temps

Une prédiction persistée conserve les valeurs calculées à `predictedAt`, même si l'état courant évolue ensuite.

## T32 — rattachement shadow

Le premier mock qualifiant du même `stateKey` dans les 30 jours est rattaché ; un mock après 30 jours ne l'est pas.

## T33 — niveau sans preuve directe : jamais 0 %

Séquence :

```text
1. CO:B1 → deux séries calibrées indépendantes 16/20 et 17/20
   → B1 SOLID, directQualification = true
2. CO:A2 n'a jamais reçu la moindre LearningEvidence
```

Attendu à l'étape 2 :

```text
sumWeightEpoch(CO:A2) = 0
masteryScore(CO:A2) = null
visibleProgress(CO:A2) = null
prerequisiteSatisfied(CO:A2) = true
prerequisiteSatisfiedByLevel = B1
UI : « A2 — Validé via B1 », aucun pourcentage affiché
activeLearningLevel(CO) = B2 si objectif = B2
```

Puis :

```text
3. CO:B1 reçoit deux contradictions fortes indépendantes
   → B1 passe SOLID → WATCH
```

Attendu :

```text
prerequisiteSatisfied(CO:A2) = false
visibleProgress(CO:A2) = null          // toujours null, jamais 0
status(CO:A2) = NOT_EVALUATED
UI : « A2 — À évaluer », aucun pourcentage
prescriptionLevel(CO) = B1             // vérification WATCH prioritaire
Le Plan ne contient jamais CO A2 + CO B1 le même jour
```

## T34 — recouvrement de contenu : pas de deuxième preuve qualifiante

Banque restreinte, `independenceOverlapThreshold = 0.50`.

```text
Série 1 : questions Q1..Q20, 16/20, CALIBRATED
Série 2 : questions Q1..Q14 + Q21..Q26, 17/20, CALIBRATED
          overlap = 14/20 = 0.70
```

Attendu :

```text
contentId(S1) != contentId(S2)
independenceClass(S2) = NEW_CONTENT_SAME_BLUEPRINT
independenceFactor(S2) = 0.90
qualificationGate(CO:A2) = false
status != SOLID
```

Puis une troisième série sans recouvrement :

```text
Série 3 : questions Q31..Q50, 16/20, CALIBRATED
          overlap max = 0.00
```

Attendu :

```text
independenceClass(S3) = NEW_CONTENT
qualificationGate(CO:A2) = true     // S1 et S3 sont indépendantes
status = SOLID
```

## T35 — série strictement identique relancée

```text
Série 1 : Q1..Q20, 16/20
Série 2 : Q1..Q20 exactement, 20/20
```

Attendu :

```text
contentId(S1) == contentId(S2)
independenceClass(S2) = REPEATED_EXACT_CONTENT
independenceFactor(S2) = 0.50
qualificationGate = false
```

Trois relances de la même série ne verrouillent jamais un palier.

## T36 — conformité front

Test statique sur le code web et mobile.

Échoue si le code contient :

```text
- une fonction retournant "A1"|"A2"|"B1"|"B2" à partir d'un nombre ;
- une comparaison d'un pourcentage à 40 / 45 / 60 / 65 / 80 / 85
  suivie d'un libellé d'état pédagogique ;
- un libellé d'état absent du mapping de §25 bis.3 ;
- un pourcentage et un libellé de niveau CECRL dans le même composant.
```

Réussit si les six états de §13 sont tous rendus, `WATCH` et `READY_FOR_REASSESSMENT` compris.

---

# 49. Ordre d'implémentation recommandé

## Phase 0 — tests, config et nettoyage front, avant le moteur

1. figer `progression-config-v1.json` (avec les blocs `independence` et `maintenance`) ;
2. écrire T01–T36 ;
3. calculer à la main T01–T06 ;
4. créer feature flag `SHADOW/ACTIVE` ;
5. **supprimer du front `cefr()`, `masteryLabel()`, `masteryTone()` et tous leurs appels** (§25 bis.4), et remplacer les vocabulaires d'états concurrents par le mapping unique de §25 bis.3 ;
6. mettre en place le test statique de conformité front (T36) ;
7. ne commencer l'implémentation du moteur qu'une fois ces contrats présents.

**Hard stop.** Claude Code présente le livrable de Phase 0 et attend validation explicite avant d'écrire la moindre ligne de moteur.

## Phase 1 — registre + moteur CO/CE en SHADOW

1. `learning_evidence` unifié ;
2. adaptateurs des sources CO/CE existantes ;
3. correction du hasard ;
4. politique incomplete/submitted/time-expired ;
5. `contentId` + calcul serveur de `independenceClass` (§12 bis) ;
6. agrégat epoch, colonnes `double precision` (§27.2.1) ;
7. idempotence ;
8. `progression_state` ;
9. state machine CO/CE ;
10. `directQualification` ;
11. `prerequisiteSatisfied` et §18.6 (`visibleProgress = null`) ;
12. `activeLearningLevel/prescriptionLevel` ;
13. `progression_prediction_log` ;
14. shadow mode.

## Phase 2 — activation Plan CO/CE après validation

1. analyser les métriques shadow ;
2. corriger uniquement via `engineVersion` suivante si nécessaire ;
3. passer le feature flag en ACTIVE ;
4. brancher le Plan sur `prescriptionLevel` ;
5. surveiller les reason codes et les transitions.

## Phase 3 — EE / EO

1. observations IA normalisées ;
2. scoringConfidence ;
3. micro cap ;
4. READY_FOR_REASSESSMENT ;
5. transferGate ;
6. contradictions/WATCH ;
7. corpus de stabilité IA ;
8. shadow validation productive.

## Phase 4 — calibration contenu

1. `difficultyBand` CO/CE ;
2. séries fixes 6/10/4 ;
3. migration des anciennes séries ;
4. difficulté empirique par item ;
5. traitement des événements `CONTENT_BANK_TOO_SMALL` (§12 bis.5) pour prioriser la production de questions ;
6. `engineVersion` suivante si les données montrent qu'un seuil doit changer.

---

# 50. Ce que Claude Code ne doit pas inventer

Claude Code ne modifie pas sans décision produit explicite :

- `progression-config-v1.json` ;
- la correction du hasard ;
- l'epoch ;
- le half-life ;
- les sourceWeights ;
- les profils de seuils ;
- les strongEvidence thresholds ;
- les K de confiance ;
- les qualification gates ;
- le cap micro ;
- le blueprint 6/10/4 ;
- la règle `totalQuestions` ;
- la politique des tentatives interrompues ;
- la règle d'un seul niveau CO/CE prescrit à la fois ;
- `directQualification` ;
- `prerequisiteSatisfied` ;
- sa transitivité et sa révocabilité ;
- les règles WATCH ;
- la séparation `visibleProgress/masteryScore` ;
- le contrat UI « Progression du parcours » ;
- le contrat de rendu front §25 bis (aucun calcul d'état ni de niveau côté client) ;
- la définition de `eligibleEvidenceMassNow` par `stateType` (§11.0) ;
- les règles de `contentId` / `independenceClass` et le seuil de recouvrement (§12 bis) ;
- les types SQL `double precision` des accumulateurs epoch (§27.2.1) ;
- la règle `visibleProgress = null` pour un niveau sans preuve directe (§18.6) ;
- le shadow mode et sa table de prédictions.

Si une contrainte technique empêche l'implémentation exacte :

```text
1. signaler la contrainte ;
2. conserver le contrat métier ;
3. proposer une migration/alternative ;
4. ne pas modifier silencieusement une formule.
```

---

# 51. Invariants finaux

```text
I1  Toute activité valide peut alimenter la progression quel que soit son point d'entrée.
I2  Le Plan est une projection ; il n'est jamais la source de vérité.
I3  LearningEvidence contient uniquement des observations réellement produites par le candidat.
I4  Aucune preuve synthétique de niveau inférieur n'est créée.
I5  CO/CE utilisent un result corrigé du hasard avant toute agrégation.
I6  Toute LearningEvidence CO/CE émise utilise totalQuestions comme dénominateur.
I7  Une pratique incomplète n'émet aucune preuve de maîtrise.
I8  Un mock SUBMITTED/TIME_EXPIRED compte les non-réponses comme fausses.
I9  L'agrégat est commutatif et indépendant de l'ordre d'ingestion.
I10 Même multiensemble de preuves + même config + même now = même projection.
I11 Score et confiance sont deux variables différentes.
I12 La confiance dépend de la masse de preuves et décroît avec le temps.
I13 La simple décroissance temporelle de confiance ne constitue pas une contradiction.
I14 RECEPTIVE_LEVEL et PRODUCTIVE_SKILL utilisent des profils de seuils distincts.
I15 CO/CE ont un seul niveau prescrit à la fois par domaine.
I16 Un WATCH prioritaire ne doit jamais être mélangé au niveau inférieur dans la même séance.
I17 A2 doit être cleared avant de prescrire normalement B1.
I18 B1 doit être cleared avant de prescrire normalement B2.
I19 Un niveau supérieur directement SOLID peut satisfaire les prérequis inférieurs.
I20 prerequisiteSatisfied est transitif vers le bas à partir d'une vraie qualification directe supérieure.
I21 prerequisiteSatisfied est dérivé et révocable.
I22 Un niveau seulement prerequisiteSatisfied ne crée aucune chaîne de preuves artificielle.
I23 Une mauvaise preuve supérieure ne crée jamais de mauvaise preuve inférieure synthétique.
I24 Un examen blanc ne réinitialise jamais l'historique.
I25 Une première contradiction forte sur SOLID produit WATCH.
I26 La sortie de SOLID utilise une hystérésis distincte de l'entrée.
I27 Les micro-sujets seuls ne prouvent pas le transfert EE/EO.
I28 Les micro-sujets ne sont pas obligatoires si le transfert est déjà prouvé.
I29 visibleProgress est un indicateur de parcours, jamais un score TCF.
I30 visibleProgress ne baisse pas dans le même cycle et reste <=95 avant confirmation directe.
I31 learning_evidence est immuable, idempotent et rejouable.
I32 Tous les seuils viennent d'une config versionnée unique.
I33 progression-config-v1.json ne doit jamais être auto-ajusté par le code.
I34 Une nouvelle calibration produit une nouvelle engineVersion et un replay.
I35 Le shadow mode persiste la prédiction au moment où elle est faite.
I36 Les métriques shadow sont calculées sur des outcomes ultérieurs, pas sur l'état courant recalculé.
I37 eligibleEvidenceMassNow a une définition explicite par stateType ; aucune n'est déduite par analogie.
I38 independenceClass est toujours calculé serveur, jamais fourni par le client.
I39 Deux séries dont le recouvrement d'items atteint le seuil ne comptent jamais comme deux preuves qualifiantes.
I40 Les accumulateurs epoch sont stockés en virgule flottante double précision, jamais en décimal à précision fixe.
I41 Un niveau sans aucune preuve directe a visibleProgress = null, jamais 0.
I42 Le front ne calcule aucun état pédagogique, aucun niveau CECRL, aucun seuil.
I43 Un niveau CECRL n'est affiché que s'il est envoyé explicitement par le serveur, et jamais sur une compétence, un drill ou une série isolée.
I44 Un pourcentage de progression et un libellé de niveau CECRL n'apparaissent jamais dans le même bloc visuel.
```

---

# 52. Contrat de livraison Claude Code

Avant de considérer la Phase 1 terminée, Claude Code doit livrer :

```text
[ ] progression-config-v1.json figé
[ ] migrations DB
[ ] learning_evidence + contrainte d'idempotence
[ ] colonnes epoch en double precision (§27.2.1)
[ ] normalisation chance-adjusted CO/CE
[ ] contentId + independenceClass calculés serveur (§12 bis)
[ ] gestion INCOMPLETE / ABANDONED / TIME_EXPIRED / SUBMITTED
[ ] agrégation epoch commutative
[ ] progression_state
[ ] qualificationGate direct
[ ] prerequisiteSatisfied dérivé
[ ] visibleProgress = null sans preuve directe (§18.6)
[ ] activeLearningLevel
[ ] prescriptionLevel avec WATCH
[ ] progression_prediction_log
[ ] mode SHADOW
[ ] contrat de rendu front §25 bis appliqué (cefr/masteryLabel/masteryTone supprimés)
[ ] T01–T36 verts
[ ] valeurs T01–T06 conformes à 1e-6
[ ] test des 6 permutations d'ingestion
[ ] test statique de conformité front (T36)
[ ] logs recommendationReasonCode
[ ] logs CONTENT_BANK_TOO_SMALL
```

Claude Code doit signaler explicitement tout élément non implémenté ; aucun `TODO` silencieux ne vaut conformité.

---

# 53. Phrase de référence

> **La progression est l'accumulation de preuves réelles. La maîtrise est une estimation stricte, chance-adjusted, indépendante du contenu déjà vu et versionnée de ces preuves. Les prérequis peuvent être déduits sans falsifier l'historique. Le Plan est uniquement la meilleure prochaine action calculée à partir de cet état. Et le front n'en est que l'affichage : il ne le recalcule jamais.**
