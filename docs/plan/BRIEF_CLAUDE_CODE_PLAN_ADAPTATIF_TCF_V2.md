# SejourFR — Brief Claude Code
## Implémentation complète du Plan adaptatif TCF : diagnostic progressif, compétences, entraînement, validation et évolution A2 → B1 → B2

> **Document de référence pour l’implémentation**
>
> Ce document complète les spécifications existantes de SejourFR et fixe les décisions produit à appliquer au module **Plan**.
>
> Claude Code recevra également le **HTML final produit par Claude Design**.  
> **Ce HTML est la référence visuelle obligatoire.**
>
> L’objectif n’est pas de redessiner le Plan, mais de connecter cette interface au vrai backend, aux vraies données, aux exercices existants, aux analyses IA, aux examens blancs et au moteur de progression.

---

# 0. Règle absolue : respecter le HTML Claude Design

Le fichier HTML fourni avec ce brief doit être considéré comme la **source de vérité visuelle et UX** du menu Plan.

Claude Code doit :

- reproduire la même hiérarchie visuelle ;
- conserver la même sensation premium ;
- conserver l’ordre général des blocs ;
- conserver les cards, espacements, densité d’information et logique mobile-first ;
- conserver le principe d’une priorité principale très visible ;
- conserver la séance du jour ;
- conserver « Mes priorités » ;
- conserver « Ce qui a changé » ;
- conserver « Mon profil TCF » ;
- conserver « Compléter mon profil » lorsqu’il manque des domaines ;
- conserver « Mon chemin vers le B2 » ou vers l’objectif du candidat ;
- conserver l’accès aux détails sans transformer l’écran principal en tableau de bord.

Ne pas refaire un autre design « inspiré » du HTML.

Si le HTML doit être traduit dans les composants/frameworks existants de l’application, le résultat visuel doit rester **fidèle à la maquette**.

Les modifications de texte et d’état prévues dans ce document sont autorisées, mais pas une refonte graphique arbitraire.

---

# 1. Vision produit

Le Plan doit fonctionner comme un véritable **coach adaptatif**.

Il doit toujours répondre à cinq questions :

1. Où en suis-je ?
2. Qu’est-ce qui me bloque actuellement ?
3. Qu’est-ce que je dois travailler aujourd’hui ?
4. Comment SejourFR sait-il que j’ai progressé ?
5. Quand est-ce que mon niveau est réellement réévalué ?

La boucle produit cible est :

```text
Diagnostic / première mesure
        ↓
Profil de compétences
        ↓
Priorités
        ↓
Entraînements ciblés
        ↓
Validation locale des compétences
        ↓
Toutes les priorités du palier deviennent solides
        ↓
Examen blanc complet de contrôle
        ↓
Palier confirmé ou non
        ↓
Nouveau Plan
        ↓
Palier suivant
```

Exemple :

```text
A2 estimé
↓
Plan vers B1
↓
Compétences B1 à travailler
↓
Toutes deviennent solides
↓
Examen blanc complet
↓
B1 confirmé sur les 4 domaines
↓
Nouveau Plan vers B2
```

---

# 2. Deux niveaux de validation à ne jamais confondre

C’est le principe central de l’algorithme.

## Niveau 1 — Validation d’une compétence

Une compétence précise peut devenir :

```text
SOLIDE
```

après suffisamment d’entraînement et une preuve adaptée.

Exemple :

```text
Raconter les actions dans l’ordre
```

peut devenir solide après :

```text
5 petits sujets
+
une vraie tâche EE2 de validation
```

---

## Niveau 2 — Validation d’un palier CECRL

Le fait que toutes les compétences prioritaires deviennent solides ne suffit **pas** à déclarer automatiquement :

```text
B1 acquis
```

ou :

```text
B2 acquis
```

Lorsque le moteur pense que le candidat a terminé le travail nécessaire pour le palier courant, le Plan doit demander :

```text
EXAMEN BLANC COMPLET
```

Ce nouvel examen blanc réévalue les quatre domaines :

```text
CO
CE
EO
EE
```

et devient le **gate de passage de niveau**.

Donc :

```text
Compétences solides
≠
Niveau supérieur confirmé
```

mais :

```text
Compétences solides
→ prêt pour examen blanc
→ examen blanc complet
→ niveau supérieur confirmé ou non
```

---

# 3. Diagnostic : il devient progressif

Ne pas considérer le diagnostic comme un bloc unique « fait / pas fait ».

Le profil peut être incomplet et se compléter progressivement.

Un utilisateur peut avoir :

```text
1 / 4 domaines évalués
2 / 4 domaines évalués
3 / 4 domaines évalués
4 / 4 domaines évalués
```

Le Plan doit fonctionner dans chacun de ces états.

---

# 4. Diagnostic rapide

Le diagnostic rapide doit rester volontairement court afin de limiter l’abandon.

Il contient :

```text
1 production EE
+
1 production EO
```

Il permet :

- une première estimation de niveau en production ;
- l’observation de compétences EE ;
- l’observation de compétences EO ;
- la création immédiate d’un premier Plan utile.

Après ce diagnostic :

```text
EE = évaluée
EO = évaluée
CE = à évaluer
CO = à évaluer
```

Ne jamais interpréter :

```text
À évaluer
```

comme :

```text
faible
```

---

# 5. Diagnostic complet

L’utilisateur peut aussi choisir de construire immédiatement un profil plus complet.

Le diagnostic complet correspond conceptuellement à :

```text
EE
+
EO
+
CO
+
CE
```

Pour CO et CE, **ne pas recréer un nouveau moteur d’examen**.

Réutiliser les examens blancs / modules de compréhension déjà existants dans l’application.

Le Plan doit également permettre une progression modulaire :

```text
EE + EO
puis plus tard CO
puis plus tard CE
```

ou par exemple :

```text
CO uniquement
```

si c’est le premier domaine que l’utilisateur décide d’évaluer.

---

# 6. Utilisateur ayant créé son compte sans diagnostic

Le Plan ne doit pas être vide.

Afficher un état d’onboarding du Plan conforme au design Claude Design.

L’utilisateur doit pouvoir choisir :

## Option principale

### Diagnostic rapide

```text
Expression écrite + Expression orale
```

Texte possible :

> Obtenez rapidement une première estimation de votre niveau et un Plan personnalisé.

---

## Évaluations complémentaires

Permettre également :

### Compréhension orale

CTA :

```text
Évaluer ma compréhension orale
```

→ ouvre un examen blanc CO existant.

### Compréhension écrite

CTA :

```text
Évaluer ma compréhension écrite
```

→ ouvre un examen blanc CE existant.

---

## Option diagnostic complet

Si cela s’intègre proprement dans l’UX :

```text
Faire le diagnostic complet
```

peut simplement orchestrer :

```text
EE
→ EO
→ CO
→ CE
```

sans dupliquer les écrans existants.

---

# 7. Compléter son profil depuis le Plan

Après un diagnostic rapide, conserver dans le Plan le bloc :

```text
Compléter mon profil
```

Exemple :

### Compréhension orale

```text
Pas encore évaluée
```

CTA :

```text
Commencer l’évaluation
```

### Compréhension écrite

```text
Pas encore évaluée
```

CTA :

```text
Commencer l’évaluation
```

Ne pas écrire :

> Une première série suffit pour l’évaluer.

Préférer :

> Faites une première série pour commencer à évaluer ce domaine.

ou :

> Complétez votre profil avec une épreuve de compréhension.

---

# 8. Structure des compétences CO / CE pour cette version

Pour l’instant, ne pas créer un grand référentiel de sous-compétences CO / CE.

Le catalogue de questions actuel est déjà organisé par niveau.

On utilise donc **une compétence par niveau**.

Chaque question CO/CE doit être reliée à la compétence correspondant à son niveau.

---

# 9. Compétences de Compréhension orale

## CO-A2 — Repérer une information explicite à l’oral

Description :

> Retrouver une information directement donnée dans un message, une annonce ou un échange simple.

Question type :

- information clairement prononcée ;
- lieu ;
- heure ;
- prix ;
- action ;
- personne ;
- détail concret.

---

## CO-B1 — Comprendre le sens global et l’intention à l’oral

Description :

> Comprendre l’idée principale d’un message et ce que le locuteur cherche à dire, demander ou faire comprendre.

Cela couvre notamment :

- idée principale ;
- situation ;
- but du message ;
- intention du locuteur ;
- lien entre plusieurs informations.

---

## CO-B2 — Comprendre l’implicite et les nuances à l’oral

Description :

> Comprendre une information qui n’est pas formulée mot pour mot, une nuance, une conclusion ou une intention plus indirecte.

Cela couvre notamment :

- inférence ;
- sous-entendu ;
- position implicite ;
- nuance ;
- distracteurs proches.

---

# 10. Compétences de Compréhension écrite

## CE-A2 — Repérer une information explicite dans un texte

Description :

> Retrouver une information clairement écrite dans un message, une annonce ou un document simple.

---

## CE-B1 — Comprendre l’idée principale et l’intention d’un texte

Description :

> Comprendre le sens global du document, son objectif et le lien entre les informations importantes.

---

## CE-B2 — Comprendre l’implicite et les nuances d’un texte

Description :

> Déduire une information, comprendre une formulation indirecte, une nuance ou distinguer des réponses très proches.

---

# 11. Mapping automatique des questions CO / CE

Pour cette version :

```text
question niveau A2
→ compétence A2 du domaine

question niveau B1
→ compétence B1 du domaine

question niveau B2
→ compétence B2 du domaine
```

Exemple :

```text
TCF_CO + B2
→ CO-B2
```

Il n’est donc pas nécessaire pour le MVP de taguer manuellement :

```text
implicite
intention
vocabulaire
etc.
```

Le niveau de la question suffit pour alimenter la compétence correspondante.

Préparer toutefois le modèle pour pouvoir ajouter plus tard des tags plus fins sans casser le système.

---

# 12. Prérequis de progression CO / CE

La progression est séquentielle.

Conceptuellement :

```text
A2 solide
→ travail B1

B1 solide
→ travail B2
```

Éviter de conclure qu’un candidat maîtrise B2 si ses résultats A2/B1 sont encore instables.

Un résultat ponctuel sur des questions B2 ne doit pas contourner les prérequis.

---

# 13. Entraînement d’une compétence CO / CE depuis le Plan

Lorsqu’un utilisateur clique sur une compétence CO ou CE :

```text
ne pas ouvrir une liste de petits sujets
```

Lancer directement une :

```text
SÉRIE CIBLÉE DE 20 QUESTIONS
```

de la compétence concernée.

Exemple :

```text
CO-B2
→ 20 questions CO niveau B2
```

ou :

```text
CE-B1
→ 20 questions CE niveau B1
```

Réutiliser les composants QCM existants.

Pour CO :

```text
lecteur audio + QCM
```

Pour CE :

```text
document / texte + QCM
```

Ne pas créer une deuxième UX concurrente.

---

# 14. Sélection des 20 questions CO / CE

Règles :

1. sélectionner uniquement le bon domaine ;
2. sélectionner uniquement le niveau correspondant à la compétence ;
3. privilégier les questions jamais vues récemment ;
4. éviter de remettre immédiatement la même question ;
5. si la banque possède moins de 20 questions uniques pour une combinaison, Claude Code doit le détecter pendant l’audit ;
6. ne pas masquer silencieusement un manque de contenu ;
7. prévoir un mécanisme permettant la répétition après épuisement de la banque, mais avec une distance temporelle raisonnable.

---

# 15. Résultat d’une série CO / CE

La série produit au minimum :

```text
correctCount
totalCount = 20
skillId
domain
level
attemptId
date
```

Le résultat met à jour la maîtrise interne de la compétence.

Proposition initiale configurable :

```text
>= 80 %  → compétence suffisamment maîtrisée pour être considérée SOLIDE localement
65–79 %  → EN PROGRESSION / À RENFORCER
< 65 %   → PRIORITÉ / À RENFORCER
```

Pour 20 questions :

```text
16 / 20 ou plus
→ candidat à SOLIDE
```

Ces seuils sont **internes à SejourFR**.

Ne pas les présenter comme une équivalence officielle de score TCF.

Les seuils doivent être centralisés et configurables, pas dispersés dans le code.

---

# 16. Pourquoi une compétence CO / CE peut devenir solide après 20 questions

Contrairement aux micro-sujets EE/EO, une série de 20 QCM apporte déjà plusieurs observations indépendantes de la même compétence.

Il est donc acceptable pour cette version de permettre :

```text
20 questions ciblées réussies
→ compétence CO/CE SOLIDE localement
```

Mais :

```text
SOLIDE localement
≠
niveau CECRL global confirmé
```

Le passage de palier reste validé par l’examen blanc complet.

---

# 17. Référentiel EE / EO existant : ne rien recréer

Pour EE et EO, utiliser impérativement le référentiel déjà défini dans SejourFR.

Il existe :

```text
EE1 : 8 compétences
EE2 : 8 compétences
EE3 : 8 compétences

EO1 : 8 compétences
EO2 : 8 compétences
EO3 : 8 compétences
```

Claude Code ne doit pas créer une deuxième liste simplifiée.

Les IDs existants doivent être la source de vérité.

Exemple existant :

```text
EE2-C5
Raconter les actions dans l’ordre
```

---

# 18. Entraînement EE / EO : conserver les petits sujets

Chaque compétence EE / EO possède pour le MVP :

```text
5 petits sujets
```

La page de compétence doit montrer :

```text
X / 5 sujets travaillés
```

et la liste :

```text
Validé
À renforcer
À faire
```

Le Plan recommande un prochain sujet, mais l’utilisateur peut ouvrir un sujet précis.

---

# 19. Décision produit sur les 5 petits sujets : conserver la tâche de validation

La meilleure option est :

```text
5 petits sujets
+
1 vraie tâche de validation
```

Ne pas considérer les 5 petits sujets comme preuve finale de maîtrise.

Pourquoi :

Un petit sujet teste volontairement un seul critère.

Une vraie tâche TCF oblige le candidat à mobiliser plusieurs éléments simultanément.

Donc :

```text
réussir les petits sujets
= apprentissage

réutiliser la compétence dans une vraie production
= transfert

transfert réussi
= compétence réellement solide
```

---

# 20. Cycle complet d’une compétence EE / EO

Exemple :

```text
EE2-C5 — Raconter les actions dans l’ordre
```

## Étape 1

Diagnostic :

```text
PRIORITÉ
```

## Étape 2

Petit sujet 1 :

```text
VALIDATED
```

## Étape 3

Petit sujet 2 :

```text
PARTIAL
```

## Étape 4

Petit sujet 3 :

```text
VALIDATED
```

etc.

## Étape 5

Les 5 sujets ont été suffisamment travaillés.

La compétence passe en état interne :

```text
READY_FOR_REASSESSMENT
```

L’UI affiche :

> Prêt à être vérifié en situation

CTA :

```text
Faire une tâche complète
```

## Étape 6

Proposer un nouveau sujet complet EE2 / EO correspondant à la tâche de la compétence.

Le sujet doit permettre réellement d’observer la compétence.

## Étape 7

Le LLM analyse la production complète et retourne une observation structurée de cette compétence.

Si validée :

```text
SOLIDE
```

Sinon :

```text
À RENFORCER
```

et elle reste dans le Plan.

---

# 21. Ne pas remettre le compteur des petits sujets à zéro après un échec de validation

Exemple :

```text
5 / 5 sujets travaillés
Tâche complète ratée
```

Ne pas faire :

```text
0 / 5
```

La personne a réellement fait le travail.

Conserver :

```text
5 / 5
```

mais afficher :

```text
À renforcer
```

Le Plan peut alors proposer :

- refaire un petit sujet fragile ;
- refaire un petit sujet avec un nouveau contexte ;
- refaire une autre tâche complète plus tard.

Le compteur mesure l’activité, pas la maîtrise.

---

# 22. Critères minimaux pour READY_FOR_REASSESSMENT en EE / EO

Ne pas baser cette transition uniquement sur :

```text
5 sujets ouverts
```

Proposition :

La compétence devient prête à être vérifiée si :

```text
les 5 sujets ont été tentés
ET
au moins 4 / 5 sont actuellement VALIDATED
```

ou une logique équivalente basée sur les statuts existants.

Ce seuil doit être configurable.

Si plusieurs sujets restent `TO_REINFORCE`, la compétence reste dans l’entraînement ciblé.

---

# 23. SOLIDE en EE / EO

Une compétence EE / EO devient `SOLIDE` uniquement si :

1. elle a suffisamment progressé dans les petits sujets ;
2. elle a atteint `READY_FOR_REASSESSMENT` ;
3. elle a été observée positivement dans une production contextualisée :
   - tâche complète ;
   - réévaluation ;
   - simulation pertinente ;
   - examen blanc ;
4. la production de validation est suffisamment indépendante des petits sujets ;
5. aucune preuve forte très récente ne contredit le résultat.

---

# 24. Une seule erreur ne doit pas casser SOLIDE

Si une compétence solide est moins bien utilisée une fois :

```text
ne pas la rétrograder immédiatement
```

Le moteur doit réduire sa confiance interne.

Une rétrogradation visible doit demander une preuve forte ou plusieurs observations récentes.

Exception :

Un examen blanc complet est une preuve forte.

S’il montre clairement que la compétence n’est plus suffisamment maîtrisée, elle peut revenir dans le Plan.

---

# 25. Analyse IA des petits sujets : la version améliorée doit viser le niveau suivant

Décision importante.

Actuellement l’IA produit une :

```text
improvedVersion
```

La version améliorée ne doit plus être simplement :

> une version un peu meilleure.

Elle doit montrer concrètement :

```text
à quoi ressemble la production au niveau suivant de la progression du candidat
```

---

# 26. Règle de niveau de improvedVersion

Si le candidat est actuellement estimé :

```text
A2
```

et son objectif demande de progresser :

```text
improvedVersion = modèle B1
```

Si le candidat est :

```text
B1
```

alors :

```text
improvedVersion = modèle B2
```

Si le candidat est déjà au niveau objectif :

```text
improvedVersion = niveau objectif bien maîtrisé
```

Ne pas pousser arbitrairement vers C1 si l’objectif est B2.

---

# 27. Le LLM doit recevoir explicitement le niveau de progression

Pour un petit sujet, fournir conceptuellement :

```json
{
  "candidateCurrentLevel": "A2",
  "objectiveLevel": "B2",
  "nextProgressionLevel": "B1",
  "improvedVersionTargetLevel": "B1"
}
```

Adapter les noms aux DTO existants.

Le prompt doit dire clairement :

- conserver l’idée du candidat ;
- conserver la situation ;
- ne pas écrire une réponse artificiellement parfaite ;
- améliorer seulement jusqu’au prochain palier ;
- employer une complexité réaliste pour ce niveau ;
- rester naturel ;
- rester conforme au TCF IRN.

---

# 28. Micro-exercice : pas de niveau global affiché

Même si `improvedVersion` cible B1 ou B2 :

ne pas afficher au candidat :

```text
Votre niveau sur cet exercice = B1
```

Le micro-sujet évalue un critère précis.

Il peut afficher :

```text
Validé
À renforcer
```

et :

> Exemple de réponse au niveau suivant

si souhaité dans l’UX.

---

# 29. Analyse IA d’une tâche complète EE / EO

Les tâches complètes doivent alimenter le même moteur de compétences.

Lorsqu’une production EE1 / EE2 / EE3 / EO1 / EO2 / EO3 est soumise :

1. récupérer les compétences existantes attachées à cette tâche ;
2. envoyer uniquement ces compétences autorisées au LLM ;
3. demander une observation structurée par compétence ;
4. ne jamais laisser le LLM inventer un nouvel ID ;
5. persister la provenance de l’observation ;
6. mettre à jour le profil.

---

# 30. Sources de preuve

Le moteur doit connaître la provenance d’une observation.

Prévoir conceptuellement :

```text
DIAGNOSTIC
TARGETED_PRACTICE
SAME_PROMPT_RETRY
FULL_TASK
REASSESSMENT
LIVE_SIMULATION
MOCK_EXAM
CO_CE_TARGETED_SERIES
```

Réutiliser les enums/structures existantes si possible.

---

# 31. Valeur relative des preuves

Ordre conceptuel :

```text
MOCK_EXAM
        ↑
REASSESSMENT / FULL_TASK / LIVE_SIMULATION
        ↑
DIAGNOSTIC
        ↑
CO_CE_TARGETED_SERIES
        ↑
TARGETED_PRACTICE
        ↑
SAME_PROMPT_RETRY
```

Important :

Pour CO/CE, la série ciblée contient 20 observations déterministes ; elle peut donc valider localement la compétence même si sa pondération unitaire est plus faible qu’un examen complet.

---

# 32. Ne pas faire une moyenne naïve de tout l’historique

Éviter :

```text
mastery = moyenne de toutes les tentatives depuis toujours
```

Le moteur doit favoriser :

- la récence ;
- la qualité de la source ;
- la diversité des contextes ;
- l’indépendance ;
- les preuves contextualisées.

Une tentative récente pertinente doit avoir plus de valeur qu’une erreur datant de plusieurs mois.

---

# 33. Score interne de maîtrise

Claude Code peut réutiliser le modèle actuel s’il existe.

Sinon, conceptuellement :

```text
effectiveWeight =
    sourceWeight
  × confidence
  × recencyFactor
  × independenceFactor
```

Puis calculer un score interne récent.

Ce score peut rester invisible.

L’UI utilise principalement :

```text
À évaluer
Priorité
À renforcer
En progression
Prêt à vérifier
Solide
```

`READY_FOR_REASSESSMENT` peut rester un flag interne si le design actuel préfère ne pas ajouter un statut permanent.

---

# 34. Récence recommandée

Point de départ configurable :

```text
0–14 jours  → 1.00
15–30 jours → 0.85
> 30 jours  → 0.70
```

Ne pas créer une chute brutale.

---

# 35. Algorithme de sélection des priorités

Ne pas choisir seulement :

```text
le score le plus bas
```

Conceptuellement :

```text
priorityScore =
    levelGap
  × pedagogicalImportance
  × weaknessConfidence
  × recencyNeed
  × readinessToImprove
```

Ajouter des règles de priorité absolue.

Ordre recommandé :

```text
1. compétence du jour non encore réussie / non solide
2. compétence READY_FOR_REASSESSMENT
3. compétence bloquante du palier courant
4. compétence faible mais secondaire
5. entretien
```

---

# 36. Le Plan doit suivre un « cycle de palier »

Créer un concept explicite ou reconstruisible :

```text
PlanCycle
```

Le nom technique peut être différent.

Un cycle contient conceptuellement :

```text
startingLevel
targetLevel
objectiveLevel
startedAt
sourceAssessment
activeSkills
status
gateMockAttempt
completedAt
```

États conceptuels possibles :

```text
BUILDING_BASELINE
TRAINING
WAITING_REASSESSMENT
READY_FOR_GATE_MOCK
GATE_MOCK_IN_PROGRESS
LEVEL_CONFIRMED
LEVEL_NOT_CONFIRMED
TARGET_STABILIZATION
```

Ne pas créer nécessairement une nouvelle table si l’architecture permet de reconstruire ce concept proprement.

---

# 37. Déterminer le palier à travailler

Exemple :

```text
niveau actuel A2
objectif B2
```

Le premier cycle cible :

```text
B1
```

Pas directement B2.

Puis :

```text
B1 confirmé
→ nouveau cycle B2
```

La progression doit être :

```text
A2
→ B1
→ B2
```

---

# 38. Profil incomplet : niveau global provisoire

Si seulement EE et EO sont évalués :

ne pas prétendre avoir un niveau global définitif sur les 4 domaines.

On peut afficher :

```text
Niveau estimé à partir des productions : A2
```

ou la formulation déjà prévue dans le design.

Mais le moteur doit savoir :

```text
profileCompleteness = 2 / 4
```

Le passage officiel interne de palier ne peut être confirmé qu’une fois les quatre domaines mesurés.

---

# 39. Niveau global interne après profil complet

Lorsque les quatre domaines sont évalués, le moteur peut déterminer un niveau global de travail à partir du domaine le plus bas.

Conceptuellement :

```text
globalLevel = min(
    CO level,
    CE level,
    EO level,
    EE level
)
```

Cette règle sert au Plan.

Exemple :

```text
CO B1
CE B2
EO B1
EE B2
```

→ niveau de travail global :

```text
B1
```

Le Plan doit consolider les domaines qui empêchent d’atteindre B2.

Ne pas afficher cette formule comme un score officiel du TCF.

---

# 40. Construction du Plan après diagnostic

Le moteur :

1. récupère tous les domaines évalués ;
2. récupère les compétences observées ;
3. détecte les compétences fragiles ;
4. détermine le prochain palier ;
5. classe les priorités ;
6. sélectionne maximum 3 compétences visibles ;
7. définit une priorité principale ;
8. construit « Aujourd’hui ».

---

# 41. Maximum de priorités visibles

Sur l’écran principal :

```text
1 priorité principale
+
2 ou 3 priorités secondaires maximum
```

Même si le moteur suit 48 compétences EE/EO + les compétences CO/CE.

Le reste est accessible via :

```text
Toutes mes compétences
```

---

# 42. La séance du jour

Utiliser le terme :

```text
entraînements
```

plutôt que :

```text
petits exercices
```

car la séance peut contenir :

- petit sujet EE ;
- petit sujet EO ;
- série CO de 20 questions ;
- série CE de 20 questions ;
- tâche complète de validation ;
- examen blanc lorsque le cycle l’exige.

Exemple :

```text
Aujourd’hui
3 entraînements · environ 25 min
```

---

# 43. Règle « sticky » : une compétence reste dans Aujourd’hui jusqu’à réussite

Décision produit forte.

Une compétence sélectionnée dans :

```text
Aujourd’hui
```

ne doit pas disparaître simplement parce que la date change.

Elle reste dans la séance du jour jusqu’à ce que son objectif actuel soit réussi.

---

# 44. Cas : aucun entraînement effectué

Jour 1 :

```text
Compétence A
Compétence B
Compétence C
```

Le candidat ne fait rien.

Jour 2 :

```text
Compétence A
Compétence B
Compétence C
```

On reprend les mêmes.

---

# 45. Cas : seulement une compétence réussie

Jour 1 :

```text
A
B
C
```

A devient solide.

Jour 2 :

```text
B
C
D
```

La compétence suivante entre seulement lorsqu’une place se libère.

---

# 46. Cas : entraînement tenté mais non réussi

Exemple :

```text
Raconter les actions dans l’ordre
```

est travaillé mais reste fragile.

Le lendemain :

```text
la compétence reste dans Aujourd’hui
```

Le moteur peut toutefois changer le **sujet précis** recommandé.

Donc :

```text
stickiness au niveau de la compétence
```

et non obligatoirement :

```text
stickiness du même prompt exact
```

Cela évite la monotonie.

---

# 47. Quand considère-t-on la compétence « réussie » pour la retirer de Aujourd’hui ?

## EE / EO

Elle quitte définitivement les priorités lorsque :

```text
SOLIDE
```

donc après validation en situation.

Pendant les 5 petits sujets, elle peut rester une priorité du Plan.

---

## CO / CE

Elle peut quitter la priorité lorsque la série ciblée fournit le seuil de maîtrise locale requis.

Exemple :

```text
>= 16 / 20
→ SOLIDE
```

sous réserve des règles de confiance et historique.

---

# 48. Ne pas mettre 3 fois la même compétence dans Aujourd’hui

Même si une compétence nécessite plusieurs étapes :

```text
1 compétence = 1 slot
```

La card indique l’action actuelle :

```text
Petit sujet 3 / 5
```

ou :

```text
Prêt à vérifier en situation
```

ou :

```text
Série ciblée de 20 questions
```

---

# 49. Quand toutes les compétences prioritaires du cycle deviennent solides

Ne pas générer immédiatement de nouvelles compétences du niveau suivant.

Le cycle passe en :

```text
READY_FOR_GATE_MOCK
```

Le Plan change son action principale.

Afficher par exemple :

> Vous avez consolidé les compétences prioritaires de ce palier.

> Vérifions maintenant vos progrès dans les conditions du TCF.

CTA :

```text
Faire un examen blanc complet
```

---

# 50. Examen blanc de validation de palier

Réutiliser l’architecture d’examen complet existante.

Le projet possède normalement :

```text
1 Attempt parent
+
TCF_CO
+
TCF_CE
+
TCF_EO
+
TCF_EE
```

Ne pas recréer un moteur parallèle.

Le gate mock doit contenir les quatre domaines.

---

# 51. Ce que l’examen blanc réanalyse

## CO

Résultats QCM, ventilés par niveau :

```text
A2
B1
B2
```

→ met à jour les 3 compétences CO.

## CE

Même logique.

## EE

Les 3 tâches complètes sont évaluées par le pipeline IA.

Les observations de compétences attachées aux tâches doivent être retournées.

## EO

Même logique.

---

# 52. L’examen blanc est une preuve forte

Les observations provenant du gate mock doivent peser fortement dans le profil.

Il peut :

- confirmer une compétence solide ;
- maintenir une compétence ;
- faire réapparaître une fragilité ;
- invalider une hypothèse trop optimiste issue des micro-entraînements.

Ne pas protéger artificiellement le Plan contre les nouvelles données.

---

# 53. Règle de passage de palier

Supposons :

```text
cycle actuel : A2 → B1
```

Le niveau B1 est confirmé uniquement si le gate mock montre que le candidat atteint au moins le niveau B1 dans **les quatre domaines** selon les règles internes de SejourFR.

Conceptuellement :

```text
CO >= B1
AND
CE >= B1
AND
EO >= B1
AND
EE >= B1
```

→ :

```text
B1 CONFIRMÉ
```

Puis :

```text
nouveau cycle B1 → B2
```

Même logique pour B2.

Important :

Cette règle est une règle de progression du produit.

Ne pas l’exposer comme une formule officielle de calcul d’un score TCF.

---

# 54. Si l’examen blanc confirme le nouveau palier

Exemple :

```text
ancien niveau confirmé : A2
gate mock : B1 partout
```

Alors :

1. enregistrer `B1` comme nouveau niveau confirmé du Plan ;
2. clôturer le cycle A2 → B1 ;
3. recalculer toutes les observations ;
4. créer un nouveau cycle B1 → B2 si objectif B2 ;
5. afficher :

```text
Ton programme évolue
```

avec les vraies nouvelles priorités ;
6. la `improvedVersion` des prochains micro-sujets cible désormais B2.

---

# 55. Si l’examen blanc ne confirme pas le palier

Exemple :

```text
CO B1
CE B1
EO A2
EE B1
```

Ne pas faire :

```text
retour à zéro
```

Le Plan doit analyser ce qui a réellement bloqué.

Il :

1. conserve les acquis crédibles ;
2. réouvre les compétences fragiles observées dans le mock ;
3. replace ces compétences dans les priorités ;
4. crée une nouvelle boucle ciblée ;
5. proposera un autre gate mock lorsqu’elles seront de nouveau solides.

Exemple :

```text
EO reste A2
→ priorité EO
→ entraînements ciblés
→ validation
→ nouveau gate mock
```

---

# 56. Un examen blanc peut faire revenir une ancienne compétence

Exemple :

```text
Développer un argument = SOLIDE
```

puis lors du gate mock :

```text
argument peu développé dans EE3
```

Si la preuve est suffisamment forte :

```text
SOLIDE → À RENFORCER
```

La compétence revient dans le Plan.

C’est normal.

Le Plan doit refléter la performance actuelle, pas protéger artificiellement les badges gagnés.

---

# 57. Quand l’objectif final est atteint

Exemple :

```text
objectif B2
gate mock confirme B2 sur les 4 domaines
```

Ne pas afficher :

> Vous aurez forcément B2 au TCF.

Afficher :

> Votre niveau estimé atteint maintenant le B2 dans les conditions évaluées.

Puis passer en :

```text
TARGET_STABILIZATION
```

Le Plan privilégie :

- examens blancs ;
- entraînements mixtes ;
- chronométrage ;
- entretien des compétences ;
- correction des fragilités détectées.

---

# 58. Réévaluation périodique après objectif

Même après objectif atteint :

- les nouveaux examens peuvent mettre à jour le profil ;
- une fragilité peut réapparaître ;
- le Plan peut proposer un entretien ciblé.

Le produit reste dynamique.

---

# 59. Moteur de niveau CO / CE depuis les examens existants

Le backend doit auditer la façon dont les questions sont actuellement classées.

La logique minimale attendue :

```text
A2 questions → evidence CO/CE A2
B1 questions → evidence CO/CE B1
B2 questions → evidence CO/CE B2
```

Pour une épreuve mélangée :

calculer un résultat interne par niveau.

Ne pas se contenter du score total si l’objectif est d’alimenter le Plan.

---

# 60. Déterminer le niveau CO / CE

Le niveau doit respecter les prérequis.

Exemple :

```text
A2 solide
B1 solide
B2 fragile
```

→ niveau estimé :

```text
B1
```

Exemple :

```text
A2 solide
B1 fragile
quelques B2 réussies
```

→ niveau estimé :

```text
A2
```

Les réussites B2 ne contournent pas un B1 fragile.

---

# 61. Analyse du niveau EE / EO

Continuer à utiliser le LLM avec les règles TCF existantes.

Ne pas déduire le niveau uniquement d’une moyenne de compétences.

Le LLM doit juger :

1. accomplissement de la tâche ;
2. communication ;
3. compétences observables ;
4. qualité globale ;
5. niveau montré.

Mais l’algorithme de Plan doit recevoir les observations structurées, pas seulement un commentaire libre.

---

# 62. LLM : contrat structuré minimal pour tâches complètes

Adapter le JSON existant, mais le moteur doit pouvoir retrouver conceptuellement :

```json
{
  "estimatedLevel": "A2|B1|B2",
  "skillObservations": [
    {
      "skillId": "EE2-C5",
      "observable": true,
      "status": "VALIDATED|PARTIAL|NOT_VALIDATED",
      "confidence": 0.0,
      "evidence": "..."
    }
  ]
}
```

`confidence` peut utiliser l’échelle existante.

Ne pas inventer de `skillId`.

---

# 63. LLM : contrat des petits sujets

Conserver le format court existant :

```json
{
  "status": "VALIDATED|PARTIAL|NOT_VALIDATED",
  "verdict": "...",
  "successPoint": "...",
  "improvementPriority": "...",
  "improvedVersion": "..."
}
```

Ajouter / fournir au prompt le niveau cible de la version améliorée.

Si le projet le nécessite, on peut également persister :

```text
improvedVersionTargetLevel
```

pour audit et reproductibilité.

---

# 64. Conserver les règles pédagogiques des micro-sujets

L’IA :

- analyse uniquement le critère annoncé ;
- ne fait pas un cours complet ;
- accepte plusieurs formulations ;
- tolère les erreurs qui n’empêchent pas le critère ;
- ne donne pas un score TCF global ;
- ne donne pas une note /20 ;
- garde l’idée du candidat ;
- donne une seule priorité claire.

---

# 65. Architecture de persistance : principe

Claude Code doit d’abord auditer l’existant.

Ne pas créer automatiquement :

```text
10 nouvelles tables
```

si les concepts existent déjà.

Mais le système doit pouvoir reconstruire :

```text
user
skill
source
attempt
task
prompt
date
result
confidence
evidence
level
```

pour chaque observation utile.

---

# 66. Historique indispensable

Pour une compétence :

```text
Diagnostic          → fragile
Petit sujet 1       → validé
Petit sujet 2       → partiel
Petit sujet 3       → validé
Petit sujet 4       → validé
Petit sujet 5       → validé
Tâche de validation → validé
Gate mock           → confirmé
```

Ce parcours doit pouvoir être retracé.

---

# 67. Anti-double comptage

Ne pas considérer comme preuves indépendantes :

```text
même sujet
tentative 1
tentative 2 immédiatement après correction
tentative 3 immédiatement après correction
```

Les retries sont utiles pédagogiquement mais doivent avoir moins de poids.

---

# 68. Plan principal : ordre des blocs

Respecter le HTML Claude Design.

Ordre attendu, sauf variation d’état :

1. priorité actuelle ;
2. séance / Aujourd’hui ;
3. Mes priorités ;
4. Ce qui a changé lorsqu’il existe ;
5. Mon profil TCF ;
6. Compléter mon profil si nécessaire ;
7. Mon chemin vers l’objectif ;
8. accès secondaires :
   - toutes mes compétences ;
   - progression ;
   - bilan ;
   - diagnostic.

---

# 69. Mon profil TCF

Afficher les quatre **domaines**, pas les appeler « compétences ».

```text
Compréhension orale
Compréhension écrite
Expression orale
Expression écrite
```

Pour chaque domaine :

```text
À évaluer
```

ou :

```text
Niveau estimé A2
Niveau estimé B1
Niveau estimé B2
```

avec le niveau de confiance / état prévu par l’UI.

---

# 70. Toutes mes compétences

Le sous-titre :

```text
6 tâches · 8 compétences par tâche
```

devient insuffisant lorsque CO / CE sont présents.

Utiliser une formulation générique, par exemple :

```text
Expression et compréhension · toutes vos compétences
```

Dans le détail :

## EE

```text
EE1
EE2
EE3
```

→ 8 compétences par tâche.

## EO

```text
EO1
EO2
EO3
```

→ 8 compétences par tâche.

## CO

```text
A2 — Information explicite
B1 — Sens global et intention
B2 — Implicite et nuances
```

## CE

même structure adaptée.

---

# 71. Navigation selon le type de compétence

## EE / EO

```text
Plan
→ compétence
→ détail + 5 petits sujets
→ prochain sujet recommandé
→ petit sujet
→ analyse IA
→ sujet suivant
→ READY_FOR_REASSESSMENT
→ tâche complète
→ SOLIDE ou À RENFORCER
```

---

## CO / CE

```text
Plan
→ compétence
→ série ciblée 20 questions
→ résultat
→ mise à jour maîtrise
→ retour Plan
```

Ne pas créer de page « 5 petits sujets » pour CO / CE.

---

# 72. Aujourd’hui et changement de date

Le backend ne doit pas régénérer aveuglément un nouveau Plan chaque minuit.

Créer une logique idempotente.

Pseudo-code :

```text
load activePlanItems

for each item:
    if competency not mastered:
        keep item
    else:
        remove item

while slots < maxDailySlots:
    add next highest priority competency
```

Le changement de jour peut mettre à jour :

- date d’affichage ;
- durée estimée ;
- contenu précis recommandé ;

mais pas effacer les priorités non résolues.

---

# 73. Après un exercice réussi mais compétence non solide

Exemple EE :

```text
petit sujet validé
```

mais il reste :

```text
3 / 5
```

La compétence reste dans Aujourd’hui.

La prochaine action devient :

```text
Petit sujet suivant
```

---

# 74. Après 5 petits sujets réussis

La compétence reste dans Aujourd’hui.

L’action change :

```text
Vérifier en situation
```

CTA :

```text
Faire une tâche complète
```

Elle ne quitte le Plan qu’après validation contextualisée.

---

# 75. Après une série CO / CE ratée

La compétence reste dans Aujourd’hui.

Le moteur peut proposer :

```text
Nouvelle série ciblée
```

avec 20 autres questions autant que possible.

---

# 76. Après une série CO / CE réussie

La compétence peut devenir `SOLIDE`.

Elle quitte les priorités actives et la prochaine compétence bloquante prend sa place.

---

# 77. Cas particulier : profil incomplet et toutes les compétences connues sont solides

Exemple :

```text
EE solide
EO solide
CO non évaluée
CE non évaluée
```

Ne pas lancer un gate mock complet comme si le profil était complet.

Le Plan doit d’abord mettre en avant :

```text
Compléter votre profil
```

avec CO et CE.

Une fois les quatre domaines évalués, recalculer le cycle.

---

# 78. Quand proposer le gate mock

Conditions recommandées :

```text
profileCompleteness = 4 / 4
AND
no blocking active skill for current target level
AND
all current-cycle priorities are SOLID
```

Alors :

```text
READY_FOR_GATE_MOCK
```

---

# 79. Ne pas créer un gate mock après chaque compétence

Le gate mock est un contrôle de palier.

Il intervient :

```text
après avoir traité toutes les compétences bloquantes du cycle
```

pas après chaque compétence.

La validation locale d’une compétence reste une tâche complète EE/EO ou une série 20 QCM CO/CE.

---

# 80. Exemple complet A2 → B1

## Diagnostic rapide

```text
EE = A2
EO = A2
CO = non évaluée
CE = non évaluée
```

Le Plan identifie :

```text
EE2-C5 — Raconter les actions dans l’ordre
EO2-Cx — Poser des questions pertinentes
```

## Plan

Aujourd’hui :

```text
1. Raconter les actions dans l’ordre
2. Poser des questions pertinentes
```

## Entraînement

Les compétences restent plusieurs jours jusqu’à progression.

## Validation locale

Après les petits sujets :

```text
tâches complètes
→ les deux compétences deviennent SOLIDE
```

## Profil incomplet

Le Plan affiche :

```text
Compléter votre profil
```

Le candidat fait :

```text
CO
CE
```

Les résultats détectent par exemple :

```text
CO-A2 solide
CO-B1 fragile

CE-A2 solide
CE-B1 solide
```

Nouvelle priorité :

```text
CO-B1 — Comprendre le sens global et l’intention
```

## Série ciblée

20 questions CO B1.

Réussite :

```text
17 / 20
→ SOLIDE
```

## Plus aucune priorité bloquante

Le Plan passe :

```text
READY_FOR_GATE_MOCK
```

## Examen blanc complet

Résultat :

```text
CO B1
CE B1
EO B1
EE B1
```

→ :

```text
B1 CONFIRMÉ
```

Nouveau cycle :

```text
B1 → B2
```

---

# 81. Exemple B1 → B2

Le moteur cible principalement :

```text
CO-B2 — Implicite et nuances
CE-B2 — Implicite et nuances
EE3 compétences fragiles
EO3 compétences fragiles
```

La `improvedVersion` des petits sujets EE/EO cible :

```text
B2
```

Lorsque les priorités deviennent solides :

```text
nouvel examen blanc complet
```

Si :

```text
CO B2
CE B2
EO B2
EE B2
```

→ objectif B2 estimé confirmé.

Sinon, le Plan retravaille uniquement les gaps.

---

# 82. « Ce qui a changé »

Ce bloc doit être alimenté par de vraies transitions du moteur.

Exemples :

```text
Raconter les actions dans l’ordre
À renforcer → Solide
```

```text
Compréhension orale B1
En progression → Solide
```

```text
Votre B1 est maintenant confirmé
Nouveau palier : B2
```

```text
L’examen blanc montre que l’oral reste à renforcer
Nouvelle priorité : EO
```

Ne pas générer des messages génériques sans événement réel.

---

# 83. « Pourquoi cette séance ? »

Le texte doit être produit à partir du vrai Plan.

Exemple :

> Cette compétence reste dans votre séance parce qu’elle n’est pas encore suffisamment stable.

> Vous avez déjà travaillé 3 sujets sur 5. Le prochain exercice sert à vérifier que vous pouvez reproduire la même compétence dans un autre contexte.

Pour CO/CE :

> Cette série cible le niveau B1, actuellement le principal frein dans votre compréhension orale.

Pas besoin de LLM si des templates déterministes suffisent.

---

# 84. Réutilisation des examens existants

Obligation :

- CO diagnostic / complément → réutiliser examens/séries existants ;
- CE diagnostic / complément → réutiliser examens/séries existants ;
- gate mock → réutiliser le moteur d’examen blanc complet existant ;
- ne pas dupliquer les banques ;
- ne pas dupliquer les composants QCM ;
- ne pas dupliquer la logique d’Attempt.

---

# 85. Compatibilité avec les anciens utilisateurs

Claude Code doit auditer :

- utilisateurs avec diagnostic existant ;
- utilisateurs avec compétences déjà enregistrées ;
- utilisateurs avec anciennes tentatives ;
- utilisateurs sans diagnostic ;
- utilisateurs ayant fait des examens mais sans nouveau profil de compétences.

Ne pas faire de backfill IA massif sans nécessité.

Stratégie recommandée :

- conserver les données historiques exploitables ;
- commencer le nouveau suivi structuré à partir de cette version ;
- utiliser les anciennes données seulement lorsqu’elles sont fiables et facilement mappables.

---

# 86. Cas utilisateur ayant déjà un diagnostic EE/EO ancien

Si ses résultats sont exploitables :

- ne pas forcer un nouveau diagnostic ;
- construire le Plan avec les informations disponibles ;
- afficher CO / CE comme à évaluer si nécessaire ;
- lui proposer de compléter.

---

# 87. Cas utilisateur ayant déjà fait un examen blanc complet récent

Si l’architecture permet de récupérer proprement :

- résultats CO/CE par niveau ;
- niveau EE/EO ;
- observations structurées de compétences ;

utiliser ces données.

Sinon, ne pas inventer une migration complexe sans validation.

---

# 88. API / services : responsabilités conceptuelles

Adapter aux conventions du projet.

Le backend doit avoir des responsabilités séparées conceptuellement :

## Assessment/Profile

- sait quels domaines sont évalués ;
- connaît le niveau estimé de chaque domaine ;
- connaît le niveau confirmé global du Plan.

## Skill mastery

- agrège les observations ;
- calcule les états de compétences ;
- sait si une compétence est prête à être réévaluée.

## Plan engine

- détermine le cycle ;
- sélectionne les priorités ;
- garde les compétences sticky ;
- produit la séance du jour ;
- déclenche le gate mock.

## AI evaluation

- analyse EE/EO ;
- retourne les observations structurées ;
- génère improvedVersion au bon niveau suivant.

## QCM assessment

- calcule les preuves CO/CE par niveau ;
- alimente les compétences CO/CE.

Ne pas forcément créer ces classes mot pour mot si l’architecture existante a déjà des services équivalents.

---

# 89. Idempotence et concurrence

Le Plan ne doit pas créer des doublons si :

- l’utilisateur rafraîchit ;
- l’app mobile renvoie deux fois une requête ;
- une soumission est rechargée ;
- une évaluation IA est retry ;
- le job de recalcul est relancé.

Les observations doivent être liées à une source/attempt/submission stable.

Un même résultat ne doit pas être compté deux fois.

---

# 90. Recalcul du Plan

Déclencher un recalcul au minimum après :

- fin du diagnostic EE ;
- fin du diagnostic EO ;
- fin d’un examen CO ;
- fin d’un examen CE ;
- fin d’un petit sujet ;
- fin d’une tâche de validation ;
- fin d’une série ciblée CO/CE ;
- fin d’un examen blanc complet ;
- modification de l’objectif utilisateur.

Le recalcul doit être déterministe pour les mêmes données.

---

# 91. Ne pas recalculer de manière destructrice

Quand le Plan est recalculé :

- préserver l’historique ;
- préserver les sujets faits ;
- préserver les compétences solides ;
- préserver la provenance ;
- préserver les items sticky non résolus si toujours pertinents.

Ne pas « recréer un Plan neuf » en supprimant la mémoire du précédent.

---

# 92. Règle de priorité après gate mock

Le gate mock devient la source la plus récente et la plus forte.

Après correction :

1. détecter les domaines sous le palier visé ;
2. dans ces domaines, détecter les compétences qui expliquent les difficultés ;
3. créer les nouvelles priorités ;
4. ne pas retravailler une compétence solide non contredite ;
5. afficher le changement dans le Plan.

---

# 93. Cas où le mock montre un niveau supérieur dans un domaine

Exemple :

```text
objectif cycle B1
CE montre B2
EO montre A2
```

Ne pas forcer CE à travailler B1.

Le domaine CE peut être en :

```text
entretien / pas prioritaire
```

Le Plan cible le domaine qui bloque le palier global.

---

# 94. Algorithme synthétique

Pseudo-code conceptuel :

```text
function recalculatePlan(user):

    profile = buildAssessmentProfile(user)

    if profile.hasNoEvidence():
        return onboardingPlan()

    cycle = getOrCreateCurrentCycle(profile, user.objective)

    skillStates = masteryEngine.compute(user, profile)

    if cycle.profileIncomplete():
        activeGaps = findGapsFromEvaluatedDomains(cycle, skillStates)

        if activeGaps.notEmpty():
            return trainingPlan(
                sticky(activeGaps),
                showCompleteProfile = true
            )

        return completeProfilePlan()

    targetLevel = cycle.targetLevel

    blockingSkills = findBlockingSkillsForLevel(
        profile,
        targetLevel,
        skillStates
    )

    stickySkills = keepPreviousUnmasteredPlanItems(
        blockingSkills
    )

    if stickySkills.notEmpty():
        return trainingPlan(stickySkills)

    if allBlockingSkillsSolid():
        if noGateMockForCurrentCycle():
            return gateMockPlan()

        result = evaluateGateMock()

        if result.allDomainsAtLeast(targetLevel):
            confirmLevel(targetLevel)

            if targetLevel >= user.objective:
                return stabilizationPlan()

            return createNextLevelCycle()

        else:
            reopenSkillsFromMock(result)
            return trainingPlan()

```

---

# 95. Calcul des compétences bloquantes EE / EO

Pour le palier cible :

- utiliser les compétences réellement observées ;
- utiliser les compétences de la tâche liée au niveau à atteindre ;
- ne pas exiger de traiter artificiellement les 48 compétences si elles ne sont pas fragiles ;
- une compétence non observable n’est pas automatiquement faible.

Le diagnostic / mock décide ce qui doit être travaillé.

---

# 96. Les compétences non observées

État :

```text
À évaluer
```

Elles ne doivent pas toutes apparaître comme priorités.

Elles peuvent être observées naturellement lors de :

- tâches complètes ;
- examens blancs ;
- simulations ;
- nouvelles productions.

---

# 97. Seuils et paramètres centralisés

Créer une configuration centrale ou équivalent pour :

```text
TARGETED_QCM_SIZE = 20

QCM_SOLID_THRESHOLD = 0.80
QCM_PROGRESS_THRESHOLD = 0.65

MICRO_PROMPTS_PER_SKILL = 5
MICRO_READY_MIN_VALIDATED = 4

MAX_VISIBLE_PRIORITIES = 3
MAX_TODAY_ITEMS = 3

RECENCY_WINDOWS
SOURCE_WEIGHTS
```

Ne pas disperser des nombres magiques.

---

# 98. Analytics

Si un système existe déjà, suivre :

```text
plan_opened
plan_today_started
plan_skill_opened
plan_skill_prompt_started
plan_skill_prompt_completed
plan_skill_ready_for_reassessment
plan_reassessment_started
plan_skill_became_solid

plan_co_ce_targeted_series_started
plan_co_ce_targeted_series_completed

profile_completion_clicked
profile_co_completed
profile_ce_completed

gate_mock_offered
gate_mock_started
gate_mock_completed
level_confirmed
level_not_confirmed
plan_cycle_advanced
```

Ne pas installer un nouveau fournisseur analytics seulement pour cela.

---

# 99. Tests backend indispensables

## Diagnostic progressif

Tester :

```text
0/4
1/4
2/4
3/4
4/4 domaines
```

Le Plan doit fonctionner pour chaque cas.

---

## EE / EO

Tester :

```text
5 sujets tentés
mais seulement 3 validés
→ pas READY
```

```text
5 sujets tentés
4 validés
→ READY_FOR_REASSESSMENT
```

```text
READY + tâche complète réussie
→ SOLIDE
```

```text
READY + tâche complète ratée
→ À RENFORCER
```

---

## CO / CE

```text
20 questions
16 bonnes
→ SOLIDE local
```

```text
20 questions
12 bonnes
→ reste prioritaire
```

Tester A2/B1/B2 séparément.

---

## Sticky Today

```text
jour 1 A/B/C
aucun fait
jour 2 A/B/C
```

```text
jour 1 A/B/C
A solide
jour 2 B/C/D
```

```text
B tenté mais raté
→ B reste
```

---

## Gate mock

```text
toutes priorités solides
profile 4/4
→ gate mock
```

```text
gate mock B1 partout
→ niveau B1 confirmé
```

```text
gate mock B1 partout sauf EO A2
→ B1 non confirmé
→ EO réouvert
```

---

## Progression A2 → B1 → B2

Tester le scénario intégral.

---

# 100. Tests IA indispensables

## improvedVersion

Candidat A2 :

```text
nextProgressionLevel = B1
```

La version améliorée doit rester réaliste B1.

Candidat B1 :

```text
nextProgressionLevel = B2
```

La version améliorée doit être B2.

Candidat B2 avec objectif B2 :

```text
reste B2
```

Ne pas passer C1.

---

## IDs de compétences

Le LLM reçoit les IDs autorisés.

Toute compétence inventée doit être rejetée / ignorée.

---

## observable=false

Ne pas modifier la maîtrise si la compétence ne peut pas être observée.

---

# 101. Tests UI / parcours

Tester avec le HTML comme référence :

## État 0 — aucun diagnostic

Plan invite à construire le profil.

## État 1 — diagnostic rapide EE/EO

```text
2/4 évalués
```

Plan fonctionnel + bloc compléter profil.

## État 2 — 3/4

Un domaine manque.

## État 3 — 4/4

Plan complet.

## État 4 — compétence EE/EO en apprentissage

Afficher `2 / 5`.

## État 5 — compétence prête à vérifier

CTA tâche complète.

## État 6 — compétence CO/CE

Clic → série 20 QCM.

## État 7 — toutes priorités solides

CTA examen blanc complet.

## État 8 — niveau confirmé

« Ton programme évolue ».

## État 9 — objectif atteint

Mode stabilisation.

---

# 102. Texte UX à corriger dans le HTML

Remplacer les formulations de type :

```text
Une première série suffit pour l’évaluer
```

par :

```text
Faites une première série pour commencer à évaluer ce domaine
```

ou une version plus courte cohérente avec la maquette.

---

Remplacer :

```text
3 petits exercices
```

par :

```text
3 entraînements
```

lorsque la séance peut mélanger plusieurs formats.

---

Pour « Toutes mes compétences », éviter :

```text
6 tâches · 8 compétences par tâche
```

comme description globale.

Utiliser une formulation qui inclut aussi CO / CE.

---

# 103. Ne pas afficher de faux pourcentages officiels

Les pourcentages de maîtrise peuvent exister en interne.

Dans l’écran principal :

préférer :

```text
À renforcer
En progression
Solide
```

Dans une vue détaillée, un indicateur interne peut être affiché si le design l’exige.

Toujours éviter de laisser entendre qu’il s’agit d’un score officiel TCF.

---

# 104. Règles de wording

Éviter :

```text
Échec
Mauvais
Faible
Vous avez raté
```

Préférer :

```text
À renforcer
Cette compétence reste fragile
Nous allons continuer à la travailler
Votre niveau n’est pas encore suffisamment stable sur ce domaine
```

---

# 105. Performance et coût IA

Ne pas appeler le LLM lorsque ce n’est pas nécessaire.

CO / CE :

```text
100 % déterministe
```

Pas d’IA pour corriger les QCM.

Le Plan / explications simples peuvent utiliser des templates.

IA nécessaire principalement pour :

- EE ;
- EO ;
- observations de compétences en production ;
- improvedVersion.

---

# 106. Aucun second appel IA inutile

Si l’évaluation existante d’une tâche complète peut retourner :

```text
feedback normal
+
skillObservations
```

dans le même appel :

préférer cette solution.

Ne pas doubler le coût pour analyser ensuite les mêmes données.

---

# 107. Audio EO

Réutiliser :

```text
audio
→ transcription
→ évaluation LLM
```

Ne pas prétendre analyser des éléments phonologiques précis si le pipeline ne dispose pas de données permettant de le faire.

---

# 108. Erreurs et reprise

Le Plan doit survivre à :

- fermeture app ;
- reprise plus tard ;
- web ↔ mobile si compte synchronisé ;
- échec réseau ;
- correction IA différée ;
- retry.

Une compétence ne doit pas perdre son état parce que l’utilisateur a quitté l’écran.

---

# 109. Pas de dépendance au jour calendaire pour la maîtrise

« Aujourd’hui » est une présentation UX.

La progression réelle dépend des actions.

Le moteur ne doit jamais faire :

```text
nouveau jour
→ compétence oubliée
```

---

# 110. Audit obligatoire avant coding

Avant les modifications structurantes, Claude Code doit inspecter :

## Backend

- Attempt parent / sub-attempts ;
- CO / CE question metadata ;
- niveaux déjà stockés ;
- moteur de scoring ;
- production_tasks ;
- production_submissions ;
- transcriptions ;
- ai_evaluations ;
- référentiel de compétences ;
- micro-sujets ;
- progression actuelle ;
- diagnostic ;
- Plan actuel ;
- examens blancs ;
- simulations.

## Front

- écran Plan existant ;
- navigation ;
- composants CO/CE existants ;
- pages compétences ;
- pages petits sujets ;
- résultat IA ;
- écran diagnostic ;
- écran progression.

## HTML Claude Design

Identifier :

- tous les écrans ;
- tous les états ;
- toutes les interactions ;
- composants visuels à reproduire.

---

# 111. Livrable d’audit avant grosse migration

Claude Code doit d’abord produire :

```text
1. Ce qui existe
2. Ce qui est directement réutilisable
3. Ce qui manque
4. Mapping de ce brief vers le code actuel
5. Migrations minimales
6. Risques de compatibilité
7. Plan d’implémentation
```

Puis coder.

Ne pas demander confirmation pour les détails techniques triviaux.

---

# 112. Migrations

Principes :

- migrations Flyway ;
- backward-compatible autant que possible ;
- pas de suppression de données historiques ;
- pas de backfill LLM coûteux sans validation ;
- ajouter seulement les structures indispensables.

---

# 113. Critères d’acceptation fonctionnels

Le travail n’est pas terminé si l’un de ces parcours ne fonctionne pas.

## Parcours A — nouvel utilisateur

```text
compte
→ Plan sans diagnostic
→ diagnostic rapide
→ Plan 2/4
→ entraînements EE/EO
→ compléter CO/CE
→ Plan 4/4
```

---

## Parcours B — compétence EE

```text
diagnostic
→ Raconter les actions dans l’ordre PRIORITÉ
→ 5 petits sujets
→ tâche complète
→ SOLIDE
→ nouvelle priorité
```

---

## Parcours C — compétence CO

```text
CO-B1 prioritaire
→ clic depuis Plan
→ 20 questions B1
→ résultat
→ état mis à jour
→ Plan mis à jour
```

---

## Parcours D — sticky

```text
compétence non résolue
→ fermeture app
→ lendemain
→ même compétence dans Aujourd’hui
```

---

## Parcours E — gate niveau

```text
toutes priorités solides
→ examen blanc complet
→ analyse 4 domaines
→ nouveau niveau confirmé ou gaps réouverts
```

---

## Parcours F — A2 → B1 → B2

```text
A2
→ improvedVersion B1
→ B1 confirmé par mock
→ nouveau Plan B2
→ improvedVersion B2
→ B2 confirmé par mock
```

---

# 114. Ce qu’il ne faut pas faire

Claude Code ne doit pas :

- inventer un nouveau design Plan ;
- remplacer le HTML par un dashboard générique ;
- créer un référentiel parallèle EE/EO ;
- créer 20 sous-compétences CO/CE maintenant ;
- utiliser de l’IA pour corriger CO/CE ;
- considérer 5/5 petits sujets comme SOLIDE automatiquement ;
- considérer toutes les compétences solides comme niveau supérieur acquis ;
- faire progresser A2 → B2 directement ;
- oublier une priorité au changement de jour ;
- remettre un compteur de petits sujets à zéro après une réévaluation ratée ;
- déclarer un niveau global si seulement 1 ou 2 domaines sont évalués ;
- créer un niveau officiel TCF à partir d’un simple pourcentage brut ;
- compter un retry identique comme une preuve totalement indépendante ;
- multiplier les appels IA ;
- casser les examens existants ;
- dupliquer les composants CO/CE ;
- supprimer l’historique.

---

# 115. Priorités d’implémentation recommandées

## Phase 1 — Audit

Cartographier l’existant.

## Phase 2 — Modèle de profil / observations

Rendre les preuves persistantes et agrégeables.

## Phase 3 — EE / EO

Brancher les petits sujets + tâches complètes + skill observations.

## Phase 4 — improvedVersion niveau suivant

Adapter les prompts.

## Phase 5 — CO / CE

Créer les 6 compétences niveau-domaine et brancher les résultats existants.

## Phase 6 — série ciblée 20 questions

Réutiliser QCM existants.

## Phase 7 — moteur Plan

Cycle, priorités, sticky, today.

## Phase 8 — diagnostic progressif

0/4 → 4/4.

## Phase 9 — gate mock

Validation de niveau et nouveau cycle.

## Phase 10 — UI

Brancher le vrai moteur sur le HTML Claude Design en restant visuellement fidèle.

## Phase 11 — tests intégrés

Tester les parcours d’acceptation.

---

# 116. Résultat produit final attendu

L’utilisateur doit pouvoir vivre une expérience comme :

> Au diagnostic, SejourFR a vu que je suis autour de A2.

Puis :

> Il m’a montré exactement les compétences qui m’empêchent de passer au B1.

Puis :

> Chaque jour, il me repropose les compétences que je n’ai pas encore réellement maîtrisées.

Puis :

> Pour l’écrit et l’oral, je travaille plusieurs petits sujets, puis SejourFR vérifie si je sais utiliser la compétence dans une vraie tâche.

Puis :

> Pour la compréhension, je fais une série de 20 questions ciblées sur le niveau qui me bloque.

Puis :

> Quand toutes mes priorités sont solides, SejourFR ne me donne pas automatiquement B1 : il me demande un vrai examen blanc complet.

Puis :

> L’examen confirme ou non mon B1 dans les quatre domaines.

Puis :

> S’il est confirmé, mon Plan passe automatiquement au B2 et les exemples améliorés de mes productions visent désormais le B2.

C’est cette boucle qui doit faire sentir :

> **SejourFR sait où je suis, ce que je dois travailler, quand une compétence est réellement acquise et quand je suis prêt à passer au palier suivant.**

---

# 117. Principe final à garder dans tout le code

```text
J’ai fait un exercice
≠
J’ai compris la compétence
≠
Je sais la réutiliser
≠
Mon niveau supérieur est confirmé
```

La hiérarchie exacte est :

```text
Micro-entraînement
→ progression

Validation contextualisée
→ compétence solide

Examen blanc complet
→ palier confirmé

Nouveau Plan
→ palier suivant
```

C’est le cœur du produit.
