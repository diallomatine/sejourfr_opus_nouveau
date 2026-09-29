# SejourFR — Brief Claude Code
## Moteur de suivi des compétences, progression, réévaluation et adaptation du Plan

> **But de ce document**
>
> Faire évoluer le suivi des compétences de SejourFR afin qu'il ne repose plus uniquement sur le diagnostic initial.
>
> Chaque nouvelle production pertinente — micro-entraînement ciblé, tâche EE/EO complète, simulation, réévaluation ou examen blanc — doit produire des **observations de compétences** exploitables pour mettre à jour le niveau de maîtrise du candidat et adapter automatiquement son Plan.
>
> Ce document décrit surtout le **comportement fonctionnel et pédagogique attendu**.  
> **Ne pas imposer une architecture ou une modélisation si le projet possède déjà les concepts nécessaires.**
>
> Claude Code doit d'abord auditer le projet, comprendre les structures existantes, proposer l'intégration la plus simple et la plus cohérente, puis poser au développeur uniquement les questions qui nécessitent réellement une décision produit/architecture.

---

# 1. Vision produit

SejourFR doit fonctionner comme une boucle d'apprentissage continue :

```text
Diagnostic initial
      ↓
Faiblesses / priorités
      ↓
Entraînements ciblés
      ↓
Nouvelles observations
      ↓
Mise à jour de la maîtrise
      ↓
Réévaluation en situation réelle
      ↓
Plan automatiquement adapté
      ↓
Nouvelle priorité
```

Le produit ne doit pas seulement répondre :

> « Quel est votre niveau ? »

Il doit surtout être capable de répondre en permanence :

> **« Qu'est-ce qui vous freine actuellement, qu'est-ce qui progresse, qu'est-ce qui est réellement maîtrisé, et que devez-vous faire maintenant ? »**

---

# 2. Contexte actuel à vérifier dans le projet

Le projet possède normalement déjà :

- un référentiel de compétences ;
- des compétences attachées aux tâches EE1, EE2, EE3, EO1, EO2, EO3 ;
- un diagnostic initial qui identifie les faiblesses ;
- des micro-entraînements ciblés par compétence ;
- des sujets complets EE / EO ;
- un pipeline de soumission de production ;
- un pipeline LLM de correction des productions ;
- un historique / système de progression ;
- un module Plan ;
- des examens / simulations ;
- des évaluations IA structurées.

Cependant, il semble qu'actuellement :

> **le diagnostic analyse les compétences, mais les soumissions classiques de tâches EE/EO ne retournent pas encore systématiquement une évaluation structurée des compétences attachées à la tâche.**

C'est probablement le premier trou à combler.

Claude Code doit le confirmer en auditant le code.

---

# 3. Règle fondamentale

## Une compétence ne doit jamais être un simple champ statique

Pour chaque candidat et chaque compétence, SejourFR doit pouvoir reconstruire une histoire du type :

```text
Diagnostic        → fragile
Micro-exercice 1  → encore fragile
Micro-exercice 2  → réussi
Micro-exercice 3  → réussi
Tâche complète    → correctement réutilisé
Réévaluation      → confirmé
```

Le système peut ensuite conclure :

> **Compétence solide**

À l'inverse :

```text
Diagnostic        → solide
Tâche complète    → fragile
Nouvelle tâche    → fragile
```

doit pouvoir faire redescendre progressivement la confiance dans cette compétence.

---

# 4. Principe pédagogique le plus important

Toutes les réussites n'ont **pas la même valeur**.

Il faut distinguer au minimum :

## A. Apprentissage ciblé

Exemple :

Le candidat travaille :

> **Développer un argument**

On lui donne un exercice qui ne teste quasiment que cette compétence.

S'il réussit :

> cela prouve qu'il **commence à comprendre et appliquer** la compétence.

Mais cela ne prouve pas encore qu'il sait l'utiliser spontanément pendant une vraie tâche TCF.

---

## B. Transfert en situation

Quelques productions plus tard, le candidat réalise une vraie EE3.

Il doit en même temps :

- comprendre la consigne ;
- gérer la longueur ;
- donner son opinion ;
- développer ses arguments ;
- utiliser son vocabulaire ;
- gérer sa grammaire ;
- structurer son texte ;
- écrire dans un temps limité.

S'il utilise correctement la compétence dans ce contexte :

> cette observation a beaucoup plus de valeur pour confirmer la maîtrise.

---

## Conclusion

### Règle à respecter dans le moteur

> **Un micro-entraînement peut faire progresser une compétence, mais il ne doit pas pouvoir, à lui seul, déclarer une compétence définitivement maîtrisée.**

La maîtrise doit être confirmée dans une production suffisamment indépendante et contextualisée.

---

# 5. Ce que Claude Code doit auditer AVANT de coder

Avant toute modification, analyser au minimum :

## Référentiel de compétences

- Où sont stockées les compétences ?
- Quel est leur identifiant stable ?
- Comment sont-elles attachées à EE1 / EE2 / EE3 / EO1 / EO2 / EO3 ?
- Une compétence peut-elle être partagée entre plusieurs tâches ?
- Y a-t-il déjà un niveau cible, des critères ou une rubrique d'évaluation ?
- Les micro-exercices ont-ils déjà un `skillId`, `competencyId` ou équivalent ?

## Productions

- structure des `production_tasks` ou équivalent ;
- structure des `production_submissions` ;
- distinction entraînement / examen / simulation / diagnostic ;
- lien entre une soumission et la tâche correspondante ;
- possibilité d'identifier un sujet précis pour éviter de compter deux fois une reprise du même sujet comme deux contextes indépendants.

## IA

- service(s) qui construisent les prompts ;
- DTO / JSON retourné par le LLM ;
- versionnement des prompts ;
- parsing ;
- mécanisme de retry ;
- différences entre diagnostic, entraînement classique, examen, oral, écrit ;
- système existant de score CECRL / critères.

## Progression

- existe-t-il une table de progression par compétence ?
- stocke-t-elle seulement un état courant ou aussi l'historique ?
- les résultats des micro-exercices sont-ils déjà persistés ?
- existe-t-il des événements / observations / attempts réutilisables ?

## Plan

- comment les priorités actuelles sont-elles choisies ?
- le Plan est-il statique après diagnostic ou recalculé ?
- peut-il recommander une compétence précise ?
- sait-il recommander une tâche complète ?
- sait-il recommander une réévaluation ?

## Examens / simulations

- peut-on identifier les productions réalisées dans un examen blanc ?
- les tâches d'examen utilisent-elles le même pipeline d'évaluation ?
- les simulations orales IA peuvent-elles produire les mêmes observations de compétences ?

---

# 6. Étape obligatoire après l'audit

Claude Code ne doit pas immédiatement inventer une nouvelle architecture.

Il doit d'abord produire un petit compte rendu :

```text
1. Ce qui existe déjà
2. Ce qui peut être réutilisé
3. Ce qui manque
4. Solution proposée
5. Migrations nécessaires
6. Risques / compatibilité
7. Questions nécessitant réellement une validation
```

### Important

Ne pas demander confirmation pour chaque détail mineur.

En revanche, demander au développeur de valider avant une modification structurante si, par exemple :

- il faut créer une nouvelle table centrale d'observations ;
- plusieurs modèles existants concurrents pourraient être utilisés ;
- un historique existant devrait être remplacé ;
- un backfill coûteux des anciennes productions est envisagé ;
- plusieurs stratégies de génération des réévaluations sont possibles avec des impacts importants.

---

# 7. Nouveau concept fonctionnel : une observation de compétence

À chaque fois qu'une production permet réellement d'observer une compétence, produire un événement conceptuel :

```text
SkillObservation
```

Le nom réel doit être adapté au projet.

Une observation devrait conceptuellement pouvoir retrouver :

```text
user
competence
date
source
task
subject / exercice
submission
score / niveau de réussite
observed = true / false
confidence
evidence
feedback court
version du moteur / prompt
```

Ce n'est **pas une obligation de créer exactement cette table**.

Si le projet possède déjà une structure équivalente, la réutiliser.

---

# 8. Sources possibles d'une observation

Prévoir au minimum les catégories conceptuelles suivantes :

```text
DIAGNOSTIC
TARGETED_PRACTICE
SAME_PROMPT_RETRY
FULL_TASK
LIVE_SIMULATION
REASSESSMENT
MOCK_EXAM
```

Adapter les noms aux enums / modèles existants.

Le moteur doit connaître la provenance de l'observation car sa valeur pédagogique n'est pas la même.

---

# 9. Valeur relative des différentes sources

Ne pas traiter toutes les observations comme équivalentes.

Ordre recommandé de fiabilité :

```text
Examen blanc / réévaluation contextualisée
        ↑
Tâche complète / simulation réelle
        ↑
Diagnostic
        ↑
Micro-entraînement ciblé
        ↑
Deuxième tentative immédiate du même exercice
```

Une deuxième tentative immédiatement après avoir vu la correction doit compter comme progrès, mais beaucoup moins comme preuve de maîtrise indépendante.

---

# 10. Pondérations — proposition de départ

Les valeurs exactes sont des paramètres produit et ne doivent pas devenir des constantes dispersées dans le code.

Proposition initiale :

| Source | Poids indicatif |
|---|---:|
| `SAME_PROMPT_RETRY` | 0.25 |
| `TARGETED_PRACTICE` | 0.45 |
| `DIAGNOSTIC` | 0.80 |
| `FULL_TASK` | 1.00 |
| `LIVE_SIMULATION` | 1.00 |
| `REASSESSMENT` | 1.15 |
| `MOCK_EXAM` | 1.20 |

Ces valeurs servent surtout à exprimer une règle :

> **une réussite assistée / très ciblée ne doit pas écraser une observation obtenue dans une production complète.**

Claude Code peut proposer une autre représentation plus adaptée au modèle existant.

---

# 11. Ne pas utiliser une simple moyenne naïve

Éviter :

```text
score = moyenne de toutes les notes depuis la création du compte
```

Sinon :

- les anciennes erreurs continuent à pénaliser éternellement le candidat ;
- dix micro-exercices faciles peuvent artificiellement écraser deux vraies tâches ratées ;
- une répétition du même exercice peut faire croire à une maîtrise ;
- une compétence nouvellement acquise met trop longtemps à remonter.

---

# 12. Algorithme recommandé : score récent pondéré + preuve de transfert

Pour chaque compétence :

## Étape 1 — récupérer les observations pertinentes

Utiliser principalement les observations récentes.

Par exemple :

- dernières observations indépendantes ;
- ou fenêtre glissante ;
- ou historique pondéré par récence.

Ne pas faire dépendre le système de toute l'histoire depuis le premier jour.

---

## Étape 2 — calculer un poids effectif

Conceptuellement :

```text
poidsEffectif =
    poidsSource
  × confianceObservation
  × facteurRécence
  × facteurIndépendance
```

### confianceObservation

Si le LLM indique qu'une compétence était difficile à observer dans cette production :

> le poids doit diminuer.

Si la compétence n'était pas observable :

> aucune mise à jour.

### facteurRécence

Une observation récente compte davantage qu'une observation très ancienne.

Ne pas créer une chute brutale.

Exemple simple configurable :

```text
0–14 jours  → 1.00
15–30 jours → 0.85
> 30 jours  → 0.70
```

Claude Code peut proposer une fonction continue si le projet possède déjà ce type de logique.

### facteurIndépendance

Une répétition du même sujet après feedback ne doit pas être considérée comme une nouvelle preuve complète.

---

# 13. Score de maîtrise

Le moteur doit conserver ou calculer une mesure interne de maîtrise.

### Important

Ne pas obligatoirement afficher un faux :

> « 83,7 % maîtrisé »

à l'utilisateur.

Le score numérique peut rester interne.

L'UI peut afficher uniquement des états pédagogiques.

Si le projet possède déjà une échelle exploitable, la conserver.

Sinon Claude Code peut proposer :

- score interne normalisé ;
- enum ;
- niveaux ;
- combinaison score + confiance.

---

# 14. États pédagogiques recommandés

Pour chaque compétence :

```text
À ÉVALUER
PRIORITÉ
À RENFORCER
EN CONSOLIDATION
SOLIDE
```

Éventuellement en interne :

```text
NEEDS_ASSESSMENT
PRIORITY
IMPROVING
CONSOLIDATING
MASTERED
```

Les noms doivent rester cohérents avec l'interface existante.

---

# 15. Ne pas déduire l'état uniquement du score

Une compétence avec un score élevé mais seulement **un micro-exercice réussi** ne doit pas être `SOLIDE`.

Il faut combiner :

```text
niveau de performance
+
quantité d'évidence
+
qualité des sources
+
diversité des contextes
+
récence
```

---

# 16. Règles proposées pour devenir « Solide »

Une compétence peut être déclarée `SOLIDE` uniquement si :

1. la performance récente atteint le seuil attendu ;
2. plusieurs observations positives existent ;
3. au moins une observation positive vient d'une **production contextualisée** :
   - tâche complète ;
   - simulation réelle ;
   - réévaluation ;
   - examen blanc ;
4. les observations ne sont pas toutes issues du même sujet répété ;
5. aucune fragilité importante très récente ne contredit la conclusion.

### Exemple

```text
Micro exercice A  → réussi
Micro exercice B  → réussi
Tâche EE3         → réussi en contexte
```

=> compétence potentiellement `SOLIDE`.

Mais :

```text
Même exercice
Tentative 1 → raté
Tentative 2 → réussi
Tentative 3 → réussi
```

=> **pas suffisant** pour `SOLIDE`.

---

# 17. Ne pas casser une compétence solide sur une seule erreur

L'inverse est également important.

Si une compétence est `SOLIDE` puis qu'une seule production est moins bonne :

> ne pas la rétrograder immédiatement.

Créer plutôt un état de vigilance interne.

Par exemple :

```text
SOLIDE
↓
1 observation fragile
↓
reste SOLIDE mais confiance réduite
```

Puis :

```text
2 observations contextualisées fragiles récentes
↓
À RENFORCER
```

La progression doit sembler stable et crédible, pas aléatoire.

---

# 18. Modification indispensable du pipeline LLM des tâches complètes

Actuellement, vérifier si les productions EE / EO classiques retournent seulement :

- niveau ;
- score ;
- feedback ;
- points forts ;
- corrections ;

sans observations structurées des compétences.

Si c'est le cas, étendre le contrat existant.

---

# 19. Quelles compétences envoyer au LLM ?

Lorsqu'un candidat soumet une production correspondant à une tâche :

```text
EE1
EE2
EE3
EO1
EO2
EO3
```

le backend doit récupérer les compétences **déjà attachées à cette tâche**.

Exemple conceptuel :

```text
task = EE3

allowedSkills = [
  position_claire,
  justification,
  developpement_argument,
  exemple,
  organisation_logique,
  connecteurs_argumentation,
  lexique_opinion,
  morphosyntaxe
]
```

Puis fournir cette liste au LLM avec :

- définition ;
- critères ;
- niveau attendu si disponible ;
- règles d'observation ;
- éventuelle rubrique déjà existante.

### Règle

Le LLM ne doit pas inventer de nouveaux IDs de compétences.

Il doit évaluer uniquement les compétences autorisées fournies par le backend.

---

# 20. Ce que le LLM doit retourner pour chaque compétence

Adapter le JSON au contrat actuel.

Conceptuellement :

```json
{
  "skillId": "developpement_argument",
  "observable": true,
  "performance": "...",
  "score": "...",
  "confidence": 0.88,
  "evidence": "extrait ou constat précis",
  "shortFeedback": "L'argument est présent mais reste peu développé."
}
```

Le type de `score` doit réutiliser l'échelle déjà existante si possible.

---

# 21. Une compétence peut être « non observable »

C'est obligatoire.

Exemple :

Une production EO2 contient presque aucune question.

Pour certaines compétences :

- on peut conclure à une faiblesse ;
- pour d'autres, on n'a simplement pas assez de matière.

Le LLM doit pouvoir retourner :

```text
observable = false
```

Dans ce cas :

> **ne pas mettre à jour le niveau de maîtrise.**

Ne jamais transformer « je n'ai pas pu observer » en « le candidat est mauvais ».

---

# 22. Evidence / preuve

Pour chaque observation importante, conserver si possible une preuve concise :

### Écrit

- extrait de la production ;
- ou constat associé à une partie identifiable du texte.

### Oral

- extrait de transcription ;
- comportement d'interaction réellement observé.

Cela permet :

- d'expliquer les changements de Plan ;
- de débugger l'IA ;
- d'améliorer les prompts ;
- de montrer au candidat pourquoi une priorité existe.

---

# 23. Limites de l'analyse orale

Si le LLM reçoit uniquement la transcription :

il peut analyser :

- contenu ;
- pertinence ;
- lexique ;
- grammaire ;
- structure ;
- formulation des questions ;
- argumentation.

Il ne doit pas prétendre mesurer précisément :

- prononciation phonétique ;
- débit exact ;
- intonation ;
- hésitations audio fines ;

sauf si le pipeline fournit réellement des signaux fiables correspondants.

---

# 24. Micro-entraînements ciblés

Un micro-entraînement est généralement attaché à une compétence précise.

Le feedback doit d'abord évaluer **cette compétence**.

Il peut éventuellement détecter une autre faiblesse flagrante, mais ne doit pas transformer chaque micro-exercice en diagnostic complet de 8 compétences.

### Résultat attendu

```text
compétence ciblée
→ observation
→ progression
→ éventuelle recommandation suivante
```

---

# 25. Deuxième tentative

Après un feedback, l'utilisateur peut refaire le même exercice.

Cette tentative est utile pour mesurer :

> « A-t-il compris la correction ? »

Mais elle ne doit pas être considérée comme totalement indépendante.

Donc :

```text
source = SAME_PROMPT_RETRY
```

ou mécanisme équivalent.

Elle peut faire monter la progression.

Elle ne peut pas seule valider la maîtrise.

---

# 26. Quand arrêter les micro-exercices ?

Le Plan ne doit pas faire pratiquer éternellement une compétence.

Après suffisamment de réussite ciblée, le système doit passer de :

> **APPRENDRE**

à :

> **VÉRIFIER EN SITUATION**

---

# 27. État interne « prêt à être réévalué »

Il est utile d'avoir conceptuellement un signal :

```text
READY_FOR_REASSESSMENT
```

Il ne doit pas forcément être un statut public.

Déclencheur recommandé :

- plusieurs exercices ciblés réalisés ;
- au moins 2 réussites récentes sur des sujets différents ;
- performance ciblée devenue suffisante ;
- pas encore de preuve de transfert récente.

Dans ce cas, le Plan ne recommande plus :

> « encore 5 exercices sur les connecteurs »

mais plutôt :

> **« Vérifions maintenant si vous savez les utiliser dans une vraie tâche. »**

---

# 28. Réévaluation : ne pas refaire le diagnostic initial

Le diagnostic initial sert de baseline.

La boucle normale ne doit pas être :

```text
refaire le même diagnostic
refaire le même diagnostic
refaire le même diagnostic
```

Cela introduirait :

- mémorisation ;
- biais ;
- lassitude ;
- faux progrès.

---

# 29. Mini-réévaluation contextualisée

Après avoir travaillé quelques compétences, proposer une production courte mais naturelle.

Exemple :

## EE3

Le candidat a travaillé :

- développer un argument ;
- utiliser des connecteurs ;
- ajouter un exemple.

Au lieu de 3 nouveaux micro-exercices, proposer :

> une mini production d'opinion sur un **nouveau sujet**.

Le LLM réévalue naturellement les compétences concernées en même temps.

---

# 30. Réévaluation groupée

Pour réduire :

- friction ;
- coût LLM ;
- durée ;

une mini-réévaluation peut tester **2 ou 3 compétences compatibles appartenant à la même tâche**.

Exemple :

```text
EE3
- position claire
- développement argument
- connecteurs
```

=> un seul mini-sujet d'opinion peut confirmer les trois.

Ne pas créer un mini-examen artificiel de 20 minutes après chaque compétence.

---

# 31. Choix du sujet de réévaluation

Ordre recommandé :

1. réutiliser un sujet existant non encore fait ;
2. utiliser une banque dédiée de sujets de réévaluation ;
3. générer un sujet dynamiquement uniquement si le projet possède déjà un moteur fiable adapté.

### Contrainte majeure

Le sujet doit être différent des exercices ciblés récemment réalisés.

Le moteur doit chercher le **transfert**, pas la mémorisation.

---

# 32. Réévaluation et Plan

Lorsqu'une ou plusieurs priorités sont prêtes :

afficher dans le Plan quelque chose du type :

```text
À vérifier maintenant

Vous avez bien travaillé « Développer un argument ».

Faites une courte tâche pour vérifier que vous savez
l'utiliser naturellement dans une vraie production.

[ Vérifier ma progression · 5 min ]
```

---

# 33. Résultat d'une réévaluation

## Si réussite

```text
Vous utilisez maintenant cette compétence
dans une production complète.
```

Le moteur peut :

- augmenter fortement la confiance ;
- passer la compétence en `SOLIDE` si les autres conditions sont réunies ;
- retirer la compétence des priorités ;
- sélectionner la prochaine faiblesse.

## Si réussite partielle

```text
Vous avez progressé, mais la compétence
reste irrégulière en situation.
```

=> `EN CONSOLIDATION` / `À RENFORCER`.

## Si échec

Ne pas afficher :

> « Vous avez perdu votre progression. »

Afficher plutôt :

> « Vous réussissez cette compétence dans les exercices ciblés, mais elle n'est pas encore automatique dans une production complète. »

Puis proposer un entraînement ciblé différent.

---

# 34. Réévaluation globale / mini examen

En plus des réévaluations de compétences, le Plan peut ponctuellement proposer un contrôle plus large.

Exemple :

Après plusieurs compétences travaillées sur EE :

> **Mini bilan écrit**

avec une tâche adaptée au niveau / objectif du candidat.

Ou après plusieurs compétences EO :

> **Mini bilan oral**

L'objectif :

> vérifier que les progrès coexistent dans une production moins guidée.

---

# 35. Quand proposer un mini bilan ?

Ne pas le déclencher uniquement au temps écoulé.

Déclencheurs possibles :

- 2 ou 3 compétences prioritaires sont `READY_FOR_REASSESSMENT` ;
- plusieurs séances ciblées ont été terminées ;
- le Plan commence à considérer les priorités comme presque solides ;
- l'utilisateur demande explicitement à mesurer sa progression ;
- avant un changement important de niveau / phase du Plan.

Claude Code doit adapter cela aux données disponibles.

---

# 36. Examens blancs

Les examens blancs sont des preuves fortes.

Lorsqu'un examen blanc contient EE / EO :

> les productions doivent alimenter le même moteur de compétences.

Il ne faut pas avoir :

```text
Progression dans le Plan
```

et séparément :

```text
Résultats d'examens sans effet sur le Plan
```

Les deux doivent communiquer.

---

# 37. Simulations orales IA

Même principe.

Une simulation EO2 réelle permet par exemple d'observer de manière bien plus fiable :

- réaction à une réponse ;
- relance ;
- formulation de questions ;
- couverture des informations ;
- interaction.

Ces observations doivent alimenter le profil de compétence.

Elles peuvent aussi confirmer des compétences qui ne sont pas réellement observables dans un simple enregistrement diagnostic.

---

# 38. Calcul du Plan : priorité pédagogique

Le Plan ne doit pas simplement choisir :

> la compétence avec le plus petit score.

Construire une priorité combinant conceptuellement :

```text
écart au niveau attendu
× importance pour l'objectif
× confiance dans la faiblesse
× récence
× possibilité actuelle de progresser
```

Et intégrer un cas particulier :

```text
si compétence prête à être réévaluée
→ priorité à la vérification plutôt qu'à un nouveau micro-exercice
```

---

# 39. Maximum de priorités visibles

Même si le moteur suit beaucoup de compétences :

> ne jamais transformer l'interface en tableau de bord de 48 faiblesses.

Le Plan principal devrait conserver :

- 1 action principale ;
- 2 ou 3 priorités maximum ;
- le reste dans une vue secondaire si nécessaire.

---

# 40. Exemple de boucle complète

## Diagnostic

```text
Développer un argument
État : PRIORITÉ
Confiance : élevée
```

## Exercice ciblé 1

```text
Résultat : fragile
```

## Exercice ciblé 2

```text
Résultat : réussi
```

## Exercice ciblé 3 — autre sujet

```text
Résultat : réussi
```

Le moteur conclut :

```text
La compétence semble acquise en exercice ciblé.
READY_FOR_REASSESSMENT = true
```

## Plan

Au lieu de proposer un 4e exercice identique :

```text
Vérifier en situation
```

## Mini EE3

Résultat :

```text
Argument présent
Explication claire
Exemple pertinent
```

## Nouveau statut

```text
SOLIDE
```

La compétence sort des priorités.

Le Plan choisit la faiblesse suivante.

---

# 41. Exemple d'échec de transfert

## Micro-entraînements

```text
Connecteurs d'argumentation
✓ réussi
✓ réussi
✓ réussi
```

## Réévaluation EE3

Le candidat écrit :

```text
Je pense que le télétravail est bien.
C'est pratique.
On reste à la maison.
C'est mieux.
```

Le moteur constate :

- opinion claire ;
- presque aucun lien logique ;
- idées juxtaposées.

Résultat :

```text
Les exercices ciblés sont compris,
mais le transfert n'est pas encore automatique.
```

Le Plan peut proposer :

```text
1 exercice ciblé différent
+
nouvelle vérification plus tard
```

---

# 42. Baseline du diagnostic

Le diagnostic initial reste important.

Pour chaque compétence réellement observable pendant le diagnostic :

> créer la première observation.

Cela donne une baseline.

Mais cette baseline ne doit pas devenir une vérité permanente.

Après plusieurs productions :

> les observations récentes et contextualisées doivent progressivement devenir plus importantes.

---

# 43. Compétences non évaluées au diagnostic

Si une compétence n'a pas été observée :

```text
À ÉVALUER
```

Plus tard, si le candidat réalise naturellement une tâche qui permet de l'observer :

> le système crée sa première baseline à ce moment-là.

Il n'est pas nécessaire de forcer immédiatement une évaluation de toutes les compétences.

---

# 44. Objectif CECRL du candidat

Si le projet possède un objectif :

```text
A2
B1
B2
```

l'évaluation d'une compétence doit être interprétée par rapport à ce qui est attendu dans la tâche et l'objectif du candidat.

Attention :

> ne pas transformer artificiellement toutes les compétences en « niveau B2 ».

Une compétence doit être évaluée dans le contexte réel de la tâche TCF correspondante.

Claude Code doit analyser les rubriques actuelles avant de définir cette logique.

---

# 45. Ne pas recalculer le niveau CECRL global comme une moyenne des compétences

Le moteur de compétences sert à :

- personnaliser ;
- expliquer ;
- suivre ;
- choisir les entraînements.

Il ne doit pas automatiquement remplacer le moteur existant de niveau CECRL.

Éviter :

```text
moyenne des 8 compétences = niveau B1
```

si ce n'est pas déjà une méthodologie validée du projet.

La note / estimation globale de production et le suivi des compétences sont **deux couches liées mais distinctes**.

---

# 46. Historique et auditabilité

Pour comprendre pourquoi le Plan a changé, idéalement conserver l'historique des observations.

Cela permet :

```text
Pourquoi « Argumentation » est devenue priorité ?
→ 2 productions récentes fragiles.

Pourquoi est-elle devenue solide ?
→ 2 micro-exercices réussis + 1 EE3 réussie.
```

Très utile également pour :

- debug ;
- support ;
- amélioration de prompts ;
- comparaison de modèles IA ;
- futur analytics.

---

# 47. Versionnement IA

Si les observations proviennent du LLM, conserver si possible :

- modèle ;
- version du prompt ;
- version de la rubrique ;
- date.

Une évolution future du prompt ne doit pas rendre les données incompréhensibles.

Réutiliser le mécanisme existant d'`ai_evaluations` / prompt versioning s'il existe.

---

# 48. Gestion des erreurs LLM

Si le JSON retourné est incomplet :

- ne jamais enregistrer silencieusement des scores faux ;
- valider les IDs ;
- refuser un skill inconnu ;
- permettre une compétence non observable ;
- conserver le comportement de retry / fallback déjà présent.

### Règle

Une correction globale réussie mais une sous-partie `skills` invalide ne doit pas forcément faire échouer toute l'expérience si l'architecture permet de dégrader proprement.

Claude Code doit proposer la stratégie la plus sûre avec le pipeline existant.

---

# 49. Performance et coût IA

Éviter un deuxième appel LLM uniquement pour suivre les compétences si le premier appel analyse déjà la production.

Préférer :

```text
1 production
→ 1 analyse LLM structurée
→ niveau + feedback + observations compétences
```

plutôt que :

```text
appel 1 = correction
appel 2 = compétences
appel 3 = plan
```

Le Plan devrait autant que possible être calculé de manière déterministe à partir des observations enregistrées.

---

# 50. Calcul côté backend, pas par le LLM

Le LLM doit répondre :

> « Voici ce que j'ai observé dans cette production. »

Le backend doit décider :

- évolution du score de maîtrise ;
- statut ;
- priorité ;
- besoin de réévaluation ;
- compétence suivante.

Éviter de demander au LLM :

> « Décide si cette compétence est définitivement maîtrisée. »

Cette décision doit être stable, explicable et testable.

---

# 51. Proposition de pseudo-code

À adapter au projet.

```text
onProductionEvaluated(submission, evaluation):

    source = detectSource(submission)

    allowedSkills = skillsForTask(submission.task)

    for result in evaluation.skillResults:

        if result.skillId not in allowedSkills:
            reject / ignore safely

        if result.observable == false:
            continue

        observation = createSkillObservation(
            user = submission.user,
            skill = result.skillId,
            source = source,
            subject = submission.subject,
            submission = submission,
            performance = result.performance,
            confidence = result.confidence,
            evidence = result.evidence
        )

        save(observation)

        recomputeSkillMastery(user, result.skillId)

    recomputePlan(user)
```

---

# 52. Pseudo-code du recalcul d'une compétence

```text
recomputeSkillMastery(user, skill):

    observations = recentRelevantObservations(user, skill)

    weightedScore = weightedAggregation(
        sourceWeight,
        observationConfidence,
        recency,
        independence
    )

    contextualEvidence =
        countIndependentPositiveContextualObservations(observations)

    targetedEvidence =
        countIndependentPositiveTargetedObservations(observations)

    readiness =
        targetedEvidence sufficient
        AND contextualEvidence not recent enough
        AND weightedScore >= readinessThreshold

    state =
        derivePedagogicalState(
            weightedScore,
            contextualEvidence,
            targetedEvidence,
            recentNegativeSignals
        )

    persistCurrentSnapshot(
        weightedScore,
        state,
        readiness,
        confidence
    )
```

---

# 53. Ne pas sur-modéliser inutilement

Si le système actuel peut atteindre ces objectifs avec :

- une table existante ;
- quelques colonnes ;
- un historique déjà présent ;

ne pas créer :

- 8 nouvelles tables ;
- event sourcing complet ;
- moteur de règles abstrait disproportionné.

L'objectif est :

> **une progression crédible, maintenable et explicable.**

---

# 54. Données historiques déjà existantes

Claude Code doit vérifier si les anciennes productions peuvent déjà fournir des observations.

### Par défaut

Ne pas relancer automatiquement des centaines d'anciennes productions au LLM.

Cela coûterait de l'argent et introduirait potentiellement des résultats utilisant plusieurs versions de prompts.

Options possibles :

1. démarrer le suivi continu à partir du déploiement ;
2. conserver le diagnostic existant comme baseline ;
3. éventuellement backfiller uniquement des données déjà structurées ;
4. rendre un recalcul LLM historique optionnel plus tard.

Si un vrai backfill LLM est envisagé :

> demander validation avant.

---

# 55. Questions que Claude Code peut poser après audit

Poser uniquement celles qui restent nécessaires.

Exemples :

### Données

> Le projet ne conserve actuellement qu'un snapshot par compétence.  
> Je recommande une table d'observations afin de distinguer micro-exercice, tâche complète et réévaluation.  
> Voulez-vous valider cette migration ?

### Réévaluation

> Le projet possède une banque importante de sujets non joués.  
> Je recommande de les utiliser pour les mini-réévaluations plutôt que de générer de nouveaux sujets par LLM.  
> Validez-vous ce choix ?

### Historique

> Les anciennes productions n'ont aucune observation de compétence.  
> Je recommande de ne pas les retraiter automatiquement et de commencer le suivi continu à partir de cette version.  
> Voulez-vous malgré tout prévoir un backfill ?

### Statuts

> Le frontend possède déjà `PRIORITY / TO_REINFORCE / SOLID`.  
> Je peux conserver ces trois statuts et garder `READY_FOR_REASSESSMENT` comme flag interne plutôt que créer un nouvel état visible.  
> Validez-vous ?

---

# 56. Ce que Claude Code ne doit PAS demander

Ne pas bloquer pour des détails comme :

- nom exact d'une méthode ;
- package Java ;
- nom d'une migration Flyway ;
- mapping trivial ;
- choix entre deux implémentations équivalentes internes.

Il doit utiliser les conventions du projet.

---

# 57. Tests indispensables — backend

Prévoir des tests couvrant au minimum :

## Observation

- compétence autorisée enregistrée ;
- compétence inconnue rejetée ;
- compétence `observable=false` ignorée ;
- mauvaise réponse JSON gérée.

## Pondération

- micro-exercice influence la progression ;
- retry identique influence moins ;
- tâche complète influence davantage ;
- vieille observation influence moins.

## Maîtrise

- un seul micro-exercice ne produit jamais `SOLIDE` ;
- plusieurs exercices ciblés peuvent produire `READY_FOR_REASSESSMENT` ;
- réussite contextualisée peut confirmer `SOLIDE` ;
- une seule erreur ne détruit pas une maîtrise ;
- plusieurs échecs récents peuvent rétrograder.

## Plan

- priorité faible réellement remontée ;
- compétence solide retirée des priorités ;
- compétence prête à être réévaluée génère une action de vérification ;
- après réussite de réévaluation, le Plan sélectionne la priorité suivante.

---

# 58. Tests indispensables — IA

Créer des cas de référence pour chaque type de tâche.

Exemple :

## EE3

Production :

```text
Je pense que le télétravail est bien.
C'est pratique parce qu'on reste à la maison.
```

Le moteur doit pouvoir distinguer :

- position claire : observable ;
- justification : observable ;
- développement argument : fragile ;
- exemple concret : fragile / absent selon rubrique ;
- autres compétences : selon contenu.

### Important

Tester la stabilité des `skillId`.

---

# 59. Tests indispensables — parcours utilisateur

Scénario complet :

```text
1. diagnostic terminé
2. priorité créée
3. micro-exercice 1
4. micro-exercice 2
5. compétence prête à être vérifiée
6. Plan recommande une mini-réévaluation
7. nouvelle production
8. LLM retourne les compétences
9. compétence confirmée
10. Plan change automatiquement
```

Ce scénario doit fonctionner au minimum sur le backend et être visible correctement dans les interfaces concernées.

---

# 60. UX du rapport après une tâche complète

Le LLM peut analyser toutes les compétences de la tâche.

Mais l'UI ne doit pas afficher 8 cartes massives.

Afficher :

- niveau estimé ;
- points forts ;
- 2 ou 3 priorités ;
- exemple concret ;
- action suivante.

Les autres observations servent surtout au moteur de progression.

Une vue détaillée peut éventuellement montrer davantage.

---

# 61. UX : montrer la progression de façon compréhensible

Exemple :

```text
Développer un argument

Diagnostic        Priorité
Entraînement      En progrès
Nouvelle tâche    À renforcer
Réévaluation      Solide ✓
```

Plus utile qu'un simple :

```text
73 %
```

---

# 62. UX : expliquer pourquoi le Plan change

Quand une compétence sort des priorités :

```text
✓ Argumentation confirmée

Vous avez réussi à développer vos arguments
dans votre dernière production EE3.

Nouvelle priorité :
Nuancer votre opinion.
```

Cela renforce fortement la perception :

> « L'application voit réellement mes progrès. »

---

# 63. Notifications / déclencheurs UI

Il n'est pas nécessaire de notifier à chaque variation interne.

Afficher un événement positif quand il est significatif :

- compétence confirmée ;
- nouvelle priorité ;
- mini-bilan disponible ;
- passage d'une phase d'entraînement à une phase de vérification.

---

# 64. Cas d'un candidat qui fait uniquement des tâches complètes

Le système doit fonctionner sans micro-exercices.

Exemple :

```text
EE3 #1 → argumentation fragile
EE3 #2 → meilleure
EE3 #3 → solide
```

Les tâches complètes peuvent directement faire évoluer la maîtrise.

Les micro-exercices sont un accélérateur pédagogique, pas une obligation technique.

---

# 65. Cas d'un candidat qui fait uniquement des micro-exercices

Il peut progresser jusqu'à :

```text
EN CONSOLIDATION
READY_FOR_REASSESSMENT
```

mais le système devrait chercher une preuve contextualisée avant `SOLIDE`.

Le Plan doit alors pousser naturellement vers une tâche de vérification.

---

# 66. Cas d'un utilisateur très actif

Éviter qu'un candidat qui fait 30 micro-exercices le même jour obtienne artificiellement un score énorme.

Solutions possibles :

- plafonner la contribution de répétitions très similaires ;
- ne compter que les N observations indépendantes les plus pertinentes ;
- appliquer un facteur d'indépendance ;
- reconnaître les retries / même sujet.

Claude Code doit choisir la solution la plus simple compatible avec le modèle existant.

---

# 67. Cas d'une compétence partagée entre plusieurs tâches

Si le référentiel possède des compétences conceptuellement proches ou identiques entre tâches :

> ne pas fusionner automatiquement leurs historiques sans vérifier le modèle actuel.

Exemple :

`connecteurs` en EE2 et `connecteurs d'argumentation` en EE3 peuvent avoir des attentes différentes.

Suivre les IDs existants.

Une consolidation transversale pourra être pensée plus tard si nécessaire.

---

# 68. Préparer l'extension future à CO / CE

Le moteur devrait être suffisamment générique pour accepter plus tard des observations déterministes provenant de :

- compréhension orale ;
- compréhension écrite.

Par exemple :

```text
source = QUESTION_RESULT
skill = implicite
result = failed
```

Mais ne pas implémenter maintenant une fausse analyse si les questions ne possèdent pas les métadonnées nécessaires.

Ne pas coder le moteur comme :

> `SkillProgress = uniquement LLM + EE/EO`.

---

# 69. Métriques utiles pour vérifier que l'algorithme fonctionne

Préparer si l'analytics existe déjà :

- nombre de compétences détectées par production ;
- taux `observable=false` ;
- passage `PRIORITÉ → SOLIDE` ;
- nombre moyen de micro-exercices avant réévaluation ;
- taux de réussite des réévaluations ;
- fréquence de régression après `SOLIDE` ;
- nombre de Plans qui changent après une production ;
- coût LLM moyen par production.

Ne pas créer une usine analytics si rien n'existe.

---

# 70. Calibration future

Les poids et seuils proposés dans ce document ne sont pas des vérités scientifiques.

Ils doivent être :

- centralisés ;
- configurables ;
- testables ;
- documentés.

Lorsque SejourFR aura suffisamment de données anonymisées, il sera possible de vérifier :

- combien de micro-exercices sont réellement nécessaires ;
- quel score prédit la réussite d'une tâche complète ;
- si les pondérations doivent changer ;
- si certaines compétences sont trop faciles / trop sévèrement évaluées.

---

# 71. Critères d'acceptation fonctionnels

L'intégration est considérée correcte lorsque :

- [ ] le diagnostic reste une baseline initiale ;
- [ ] les tâches EE/EO classiques retournent également des observations de compétences ;
- [ ] seules les compétences attachées à la tâche sont évaluées ;
- [ ] une compétence peut être `non observable` ;
- [ ] les observations sont persistées ou reconstruisibles ;
- [ ] la source de l'observation est connue ;
- [ ] un micro-exercice influence la progression ;
- [ ] un retry du même exercice pèse moins ;
- [ ] une tâche complète fournit une preuve plus forte ;
- [ ] un micro-exercice seul ne peut pas valider définitivement une compétence ;
- [ ] le Plan évolue après les nouvelles productions ;
- [ ] après plusieurs réussites ciblées, le Plan peut proposer une réévaluation ;
- [ ] la réévaluation utilise un autre contexte ;
- [ ] plusieurs compétences compatibles peuvent être réévaluées dans une seule production ;
- [ ] une réussite contextualisée peut confirmer une compétence ;
- [ ] une erreur isolée ne détruit pas une compétence solide ;
- [ ] plusieurs fragilités contextualisées récentes peuvent faire redescendre la compétence ;
- [ ] examens blancs et simulations pertinentes alimentent le même moteur ;
- [ ] le backend, et non le LLM, décide de la maîtrise et du Plan ;
- [ ] le système n'affiche pas de fausse précision au candidat ;
- [ ] le moteur reste compatible avec l'extension future CO / CE.

---

# 72. Plan d'implémentation souhaité pour Claude Code

## Phase 1 — Audit

Analyser :

- référentiel ;
- productions ;
- micro-exercices ;
- diagnostic ;
- IA ;
- progression ;
- Plan ;
- examens ;
- simulations ;
- persistence ;
- web ;
- mobile si concerné.

### Livrable intermédiaire obligatoire

Avant modification structurante :

```text
État actuel
→ gaps
→ architecture proposée
→ migrations
→ questions bloquantes
```

---

## Phase 2 — Contrat IA

Étendre le pipeline de production afin d'obtenir :

```text
production evaluation
+
skill observations
```

sans deuxième appel IA si possible.

---

## Phase 3 — Persistence / historique

Réutiliser les structures existantes.

Si elles ne suffisent pas :

> proposer la plus petite extension permettant de conserver l'historique et la provenance.

---

## Phase 4 — Moteur de maîtrise

Implémenter :

- pondération par source ;
- récence ;
- indépendance ;
- confiance ;
- statut ;
- règle de preuve contextualisée ;
- protection contre les fluctuations.

---

## Phase 5 — Réévaluation

Implémenter :

```text
READY_FOR_REASSESSMENT
→ sélection d'une production contextualisée
→ nouvelle observation
→ confirmation ou consolidation
```

---

## Phase 6 — Plan

Faire du Plan une projection dynamique du profil actuel :

```text
priorité
ou
entraînement
ou
réévaluation
ou
prochaine compétence
```

---

## Phase 7 — Examens / simulations

Faire en sorte que leurs productions alimentent le même historique lorsque techniquement pertinent.

---

## Phase 8 — UI

Afficher uniquement les informations utiles :

- priorité ;
- progression ;
- compétence confirmée ;
- action suivante ;
- réévaluation.

---

## Phase 9 — Tests

Tester l'algorithme et le parcours complet.

---

# 73. Décisions à NE PAS prendre arbitrairement

Après audit, demander validation si nécessaire pour :

1. nouvelle table d'observations vs réutilisation d'une structure existante ;
2. changement du modèle de progression actuel ;
3. backfill des anciennes productions ;
4. génération dynamique des sujets de réévaluation vs banque existante ;
5. modification visible des statuts de compétences ;
6. migration incompatible avec des clients web/mobile existants.

Pour le reste :

> choisir la solution la plus simple conforme aux conventions du projet.

---

# 74. Résultat produit recherché

À terme, un utilisateur doit pouvoir vivre ceci :

> « Au diagnostic, SejourFR a vu que j'avais du mal à développer mes arguments. »

Puis :

> « L'application m'a donné quelques petits exercices précisément sur ça. »

Puis :

> « Quand je les ai réussis, elle ne m'a pas simplement mis 100 %. Elle m'a demandé de refaire une vraie petite production. »

Puis :

> « J'ai réussi à utiliser ce que j'avais appris dans un nouveau sujet. »

Puis :

> « La compétence est passée en solide et mon Plan a automatiquement changé de priorité. »

C'est cette boucle qui doit créer la sensation :

> **SejourFR ne me donne pas seulement des exercices. Il comprend ce que je maîtrise réellement et sait ce que je dois travailler ensuite.**

---

# 75. Principe final

Le moteur doit toujours distinguer trois choses :

```text
J'ai vu la compétence
≠
Je l'ai réussie dans un exercice ciblé
≠
Je la maîtrise dans une vraie production
```

C'est la base de tout le système de progression.

