# Spécification — Benchmark JEV pour SejourFR

## 0. Principe général

L’objectif est d’évaluer sérieusement si JEV peut devenir, à terme, le moteur principal d’estimation du niveau CECRL des productions des candidats.

Pour l’instant, il ne faut **rien remplacer dans le produit**.

La première étape est un **audit uniquement**.

Aucun code métier ne doit être modifié avant validation explicite.

---

# 1. Règle absolue : commencer par un AUDIT

**Ne code rien pour le moment.**

Commence par auditer le projet pour comprendre précisément :

- comment les productions EE sont enregistrées ;
- comment les productions EO et leurs transcriptions sont enregistrées ;
- comment le niveau CECRL actuel est calculé ;
- où sont enregistrées les évaluations IA existantes ;
- comment sont représentées les tâches, consignes et sous-types de tâches ;
- comment fonctionnent les « petits sujets » / sujets ciblés hors examen complet ;
- quelles métadonnées permettent d’identifier EE1, EE2, EE3, EO1, EO2, EO3 et les autres exercices productifs ;
- comment fonctionne actuellement l’admin ;
- s’il existe déjà un mécanisme de scripts/outils locaux permettant de lire la base de production sans écrire dedans ;
- comment sont stockés les scores actuels par critère ;
- comment sont stockées les versions de prompts et modèles ;
- comment sont représentés les tours de parole en EO si cela existe ;
- comment sont traitées les transcriptions partielles ou douteuses.

## Livrable de l’audit

Créer :

`docs/JEV/audit-integration-jev.md`

Le rapport doit contenir :

1. architecture actuelle du scoring ;
2. tables/classes/services concernés ;
3. provenance exacte du niveau CECRL actuellement affiché ;
4. inventaire des différents types de productions évaluables ;
5. spécificités EE et EO ;
6. structure des transcriptions EO ;
7. disponibilité éventuelle des tours examinateur/candidat pour EO ;
8. fonctionnement des petits sujets ;
9. règles de longueur actuellement appliquées selon le type de tâche ;
10. données nécessaires au benchmark JEV ;
11. méthode la moins intrusive pour récupérer les productions de production en lecture seule ;
12. proposition d’architecture du benchmark ;
13. fichiers qu’il faudrait créer/modifier **après mon GO** ;
14. risques identifiés ;
15. impact estimé sur le code existant ;
16. stratégie RGPD / sous-traitance JEV ;
17. stratégie d’échantillonnage ;
18. proposition de phasage V1/V2 ;
19. recommandation finale d’architecture.

**À la fin de l’audit, arrête-toi. Ne code rien. Attends mon GO.**

---

# 2. Objectif du benchmark

Nous voulons comparer :

`niveau actuel SejourFR`

vs

`niveau estimé par JEV`

et, lorsque nécessaire :

`niveau arbitre LLM`

et éventuellement :

`niveau humain`

Le but est de déterminer si JEV doit :

- remplacer le calcul actuel du niveau ;
- intervenir uniquement dans les cas douteux ;
- compléter le LLM actuel ;
- ou ne pas être utilisé.

Le benchmark ne doit jamais considérer le niveau actuel SejourFR comme une vérité absolue.

Un accord avec le système actuel signifie seulement :

> les deux systèmes ont donné le même résultat.

Cela ne veut pas dire que le résultat est nécessairement correct.

---

# 3. Contraintes absolues

Pendant toute cette expérimentation :

- **aucun déploiement** ;
- aucune modification de données en production ;
- aucune migration appliquée en production ;
- aucun changement du scoring réel des utilisateurs ;
- aucune utilisation de JEV dans le parcours candidat ;
- aucune clé API committée ;
- aucune donnée nominative récupérée ;
- aucun email, prénom, nom, téléphone, adresse IP, identifiant utilisateur ou donnée non nécessaire ;
- aucune écriture dans la base de production ;
- aucun benchmark massif sur données réelles avant validation RGPD explicite.

La clé JEV est déjà présente dans les variables d’environnement locales.

Elle doit uniquement être lue depuis l’environnement.

Ne jamais l’écrire dans :

- le repository ;
- un fichier de configuration committé ;
- les logs ;
- l’interface admin.

---

# 4. Phasage

## V1

La première implémentation doit concerner uniquement :

- EE1 ;
- EE2 ;
- EE3 ;
- petits sujets écrits / exercices ciblés.

Objectif : répondre d’abord à la question :

> JEV estime-t-il les niveaux écrits de manière plus cohérente que notre système actuel ?

## V2

L’expression orale sera traitée ensuite :

- EO1 ;
- EO2 ;
- EO3 ;
- transcriptions temps réel ;
- gestion des tours de parole ;
- transcriptions douteuses ;
- détection éventuelle de langue étrangère ;
- qualité/exploitabilité de transcription.

L’audit doit tout de même analyser EO dès maintenant, mais **l’implémentation V1 ne doit pas inclure EO**.

Les statistiques EE et EO devront toujours rester séparées.

---

# 5. Architecture privilégiée

Je veux **le moins d’impact possible sur l’application**.

Après l’audit, privilégier si techniquement raisonnable :

`Production DB READ ONLY`
→ `script local`
→ anonymisation/nettoyage
→ `JEV API`
→ stockage local
→ interface locale de benchmark

Un petit outil Python séparé est parfaitement acceptable.

Exemple :

`tools/jev-benchmark/`

avec :

- scripts Python ;
- SQLite locale ;
- JSON/CSV locaux ;
- petite interface locale ;
- exports.

Les productions réelles et résultats contenant du texte utilisateur doivent être gitignored.

Le dossier :

`docs/JEV/`

peut contenir :

- documentation ;
- architecture ;
- résultats agrégés ;
- conclusions.

Il ne doit pas contenir de dump de productions utilisateurs.

---

# 6. Accès à la production

Ne jamais utiliser les identifiants administrateur PostgreSQL de production en local.

Préférer :

- un utilisateur PostgreSQL dédié ;
- droits `SELECT` uniquement ;
- limité aux tables nécessaires ;
- idéalement limité aux colonnes nécessaires.

Alternative acceptable :

- export ciblé en lecture seule ;
- sans données nominatives.

L’audit doit proposer la solution la plus sûre.

---

# 7. RGPD / sous-traitant JEV

Avant toute utilisation de vraies productions de candidats, l’audit doit documenter :

- fournisseur réellement appelé par l’API JEV ;
- localisation du traitement ;
- localisation du stockage ;
- durée de conservation ;
- usage éventuel pour entraînement ;
- politique de rétention ;
- DPA disponible ;
- sous-traitants éventuels ;
- transferts hors UE ;
- clauses contractuelles ;
- compatibilité avec les CGU / politique de confidentialité de SejourFR.

Tant que je n’ai pas validé ce point :

**aucune vraie production utilisateur ne doit être envoyée à JEV.**

Le benchmark peut commencer avec :

- textes de tests internes ;
- productions synthétiques ;
- jeux de tests déjà utilisés manuellement.

---

# 8. Données minimales du benchmark

Pour chaque production :

```text
benchmark_sample_id
modality
task_type
exercise_type
task_instruction
task_context
required_points
candidate_production
current_cefr_level
current_scores éventuels
current_ai_model éventuel
current_prompt_version éventuelle
word_count
official_min
official_max
below_official_min
above_official_max
official_length_compliant
```

Pour V1 :

`modality = EE`

Ne pas récupérer :

```text
user_id
firstname
lastname
email
phone
address
subscription
IP
device_id
```

---

# 9. Anonymisation

Si des données personnelles apparaissent dans le texte libre :

- nom ;
- prénom ;
- email ;
- téléphone ;
- adresse ;
- identifiant facilement détectable ;

prévoir une redaction locale avant envoi.

Exemple :

```text
Jean Dupont
→ [PERSONNE]

06 12 34 56 78
→ [TELEPHONE]
```

Ne pas tenter une anonymisation complexe qui détruit le sens linguistique.

L’objectif est de retirer les informations directement identifiantes sans altérer inutilement la production.

---

# 10. Règles de longueur officielles

Le script doit calculer la longueur indépendamment de JEV.

Pour les tâches EE en conditions d’examen :

```text
EE1 : 30–60 mots
EE2 : 40–90 mots
EE3 : 40–90 mots
```

**À vérifier dans le code et les règles actuelles avant implémentation.**

Conserver :

```text
word_count
official_min
official_max
below_official_min
above_official_max
official_length_compliant
```

Ces informations servent à analyser la conformité aux règles de l’examen.

## Important

La longueur ne doit **pas** être utilisée comme raccourci pour estimer le niveau linguistique JEV.

JEV doit répondre :

> Quel niveau linguistique cette production démontre-t-elle ?

Le moteur métier pourra ensuite appliquer séparément les règles officielles liées à la longueur.

Pour les petits sujets :

- aucun minimum officiel par défaut ;
- ne jamais appliquer automatiquement les seuils EE1/EE2/EE3 ;
- l’audit doit identifier les règles propres à ces exercices.

---

# 11. Principe fondamental du scoring JEV

Ne pas demander seulement :

> Quel est le niveau de cette production ?

JEV doit recevoir :

1. la consigne ;
2. le type de tâche ;
3. les objectifs ;
4. les points demandés ;
5. la production ;
6. une grille CECRL stable ;
7. plusieurs décisions séparées.

Ne pas mélanger :

- niveau linguistique ;
- hors sujet ;
- réalisation de la tâche ;
- quantité de preuve linguistique.

Exemple :

```text
Niveau linguistique : B1
Pertinence : PARTIELLEMENT_DANS_LE_SUJET
Réalisation : PARTIEL
Preuve linguistique : SUFFISANTE
```

Un hors-sujet écrit dans un bon français peut rester B1 ou B2 linguistiquement.

---

# 12. Questions JEV à poser

Utiliser plusieurs questions dans la même requête lorsque l’API le permet.

## Question 1 — niveau global

Type :

`choice`

Choix :

```text
A1
A2
B1
B2
INSUFFICIENT
```

`INSUFFICIENT` signifie :

> pas assez de matière linguistique exploitable pour estimer raisonnablement le niveau.

Cela ne signifie pas :

> niveau faible.

Une production faible mais exploitable peut être A1.

---

# 13. Questions JEV par compétence

Ajouter également :

## Morphosyntaxe

```text
A1
A2
B1
B2
```

Évaluer :

- construction des phrases ;
- maîtrise des structures ;
- temps verbaux ;
- accords ;
- subordination ;
- variété syntaxique ;
- contrôle grammatical.

## Lexique

```text
A1
A2
B1
B2
```

Évaluer :

- étendue ;
- précision ;
- variété ;
- adéquation ;
- répétitions ;
- capacité à exprimer des nuances.

## Cohérence

```text
A1
A2
B1
B2
```

Évaluer :

- enchaînement ;
- organisation ;
- liens logiques ;
- cohésion ;
- progression du message.

Ces sorties doivent conserver leurs probabilités complètes.

---

# 14. Réalisation de la tâche

Ne pas utiliser A1/A2/B1/B2 pour cette dimension.

Utiliser :

```text
COMPLET
PARTIEL
INSUFFISANT
```

JEV doit utiliser :

- la consigne ;
- les points demandés ;
- les contraintes fonctionnelles de la tâche.

Exemple :

si le sujet demande 4 points, vérifier séparément que ces 4 points sont effectivement traités.

---

# 15. Pertinence / hors sujet

Décision séparée :

```text
DANS_LE_SUJET
PARTIELLEMENT_DANS_LE_SUJET
HORS_SUJET
```

Ne jamais utiliser le hors-sujet pour modifier artificiellement le niveau linguistique.

---

# 16. Quantité de preuve linguistique

Décision :

```text
SUFFISANTE
LIMITEE
INSUFFISANTE
```

La question n’est pas :

> Y a-t-il assez de mots ?

mais :

> Cette production fournit-elle suffisamment d’indices linguistiques pour soutenir raisonnablement l’estimation CECRL proposée ?

---

# 17. Nombre de questions V1

Pour V1 EE, viser :

1. niveau global ;
2. morphosyntaxe ;
3. lexique ;
4. cohérence ;
5. réalisation ;
6. pertinence ;
7. preuve linguistique.

Cela permet d’obtenir un diagnostic interprétable sans mélanger les dimensions.

---

# 18. Prompt CECRL commun

Base commune :

```text
Déterminer le niveau CECRL réellement démontré dans cette production.

Évaluer uniquement les capacités effectivement observables.

Ne jamais déduire le niveau :
- du niveau cible supposé de la tâche ;
- du numéro de la tâche ;
- de la longueur seule ;
- de quelques mots sophistiqués isolés ;
- de quelques expressions mémorisées ;
- du simple nombre de temps verbaux employés.

Évaluer notamment :
- efficacité de la communication ;
- construction syntaxique ;
- maîtrise grammaticale ;
- richesse et précision lexicale ;
- cohérence ;
- capacité à relier les idées ;
- développement approprié à la tâche ;
- capacité à raconter, expliquer, justifier, comparer, nuancer ou argumenter lorsque la tâche le permet.

Les erreurs sont compatibles avec tous les niveaux CECRL.

Ce qui compte est leur fréquence, leur nature, leur caractère systématique et leur impact sur la communication.

Une production concise peut démontrer un niveau élevé.

Une production longue ne démontre pas automatiquement un niveau élevé.

Évaluer le niveau démontré par CETTE production et non le niveau général supposé du candidat.
```

---

# 19. Critères A1

Le candidat :

- transmet quelques informations très simples ;
- utilise des structures très simples ;
- possède un lexique élémentaire ;
- juxtapose souvent les idées ;
- peut produire des phrases incomplètes ;
- montre une maîtrise grammaticale très limitée.

Une production A1 reste évaluable.

Ne pas la classer automatiquement `INSUFFICIENT`.

---

# 20. Critères A2

Le candidat :

- communique sur des situations familières ;
- utilise principalement des phrases simples ;
- possède un vocabulaire courant ;
- utilise des connecteurs élémentaires ;
- peut raconter ou expliquer simplement ;
- commet des erreurs régulières ;
- reste généralement compréhensible.

---

# 21. Critères B1

Le candidat :

- produit un texte suivi ;
- raconte ;
- explique ;
- justifie ;
- donne des raisons ;
- exprime un avis ;
- développe plusieurs idées ;
- utilise des structures plus variées ;
- possède un lexique suffisant pour développer ;
- commet encore des erreurs sans bloquer la communication.

---

# 22. Critères B2

Le candidat :

- produit un texte clair relativement à la tâche ;
- développe ;
- justifie ;
- compare ;
- nuance ;
- émet des hypothèses ;
- défend un point de vue ;
- utilise une syntaxe variée ;
- possède un lexique suffisamment précis ;
- maîtrise globalement la grammaire.

Ne pas exiger :

- dissertation ;
- style académique ;
- connecteurs artificiels ;
- vocabulaire excessivement recherché.

Un B2 peut être naturel et simple dans la forme.

---

# 23. INSUFFICIENT

Utiliser uniquement lorsque la matière est réellement insuffisante.

Exemples :

- quelques mots seulement ;
- texte presque vide ;
- production techniquement inexploitable ;
- contenu ne permettant pas d’observer suffisamment de français.

Ne pas utiliser simplement parce que le candidat est A1.

---

# 24. EE1 — Message fonctionnel

Adapter le prompt pour observer particulièrement :

- compréhension de la situation ;
- transmission des informations demandées ;
- réalisation des points ;
- clarté ;
- registre ;
- organisation ;
- précision lexicale ;
- contrôle grammatical.

Ne pas exiger d’argumentation longue.

Un B2 peut parfaitement produire une réponse courte et simple si la tâche le demande.

Le niveau doit être observé dans :

- la précision ;
- le naturel ;
- la souplesse ;
- les structures ;
- le contrôle de langue.

---

# 25. EE2 — Récit / expérience

Observer :

- chronologie ;
- capacité à raconter ;
- emploi des temps ;
- maîtrise réelle des temps ;
- description ;
- ressenti ;
- causes ;
- conséquences ;
- explications ;
- cohérence.

Ne pas surévaluer un candidat parce qu’il utilise plusieurs temps verbaux.

Ce qui compte est leur maîtrise.

---

# 26. EE3 — Opinion / argumentation

Observer :

- position ;
- arguments ;
- justification ;
- comparaison ;
- exemples ;
- causes / conséquences ;
- nuance ;
- opposition ;
- hypothèses ;
- organisation du raisonnement.

Ne pas exiger :

- premièrement ;
- cependant ;
- en conclusion ;
- style de dissertation.

Quelques expressions mémorisées ne suffisent pas pour démontrer B2.

---

# 27. Petits sujets

Faire l’inventaire exact dans l’audit.

Chaque famille de petits sujets doit avoir un `evaluation_profile`.

Exemple :

```json
{
  "objective": "développer un avis",
  "required_points": [
    "prendre position",
    "donner une raison",
    "donner un exemple",
    "proposer une conséquence ou solution"
  ]
}
```

Puis JEV évalue :

```text
niveau
morphosyntaxe
lexique
coherence
realisation
pertinence
preuve_linguistique
```

Une production courte peut être :

```text
B2
COMPLET
DANS_LE_SUJET
SUFFISANTE
```

La longueur seule ne doit jamais l’empêcher.

---

# 28. Construction du state JEV

Exemple :

```json
{
  "exam": "TCF IRN",
  "modality": "EE",
  "task_type": "EE_TASK_3",
  "task_instruction": "...",
  "task_objective": "...",
  "required_points": [
    "...",
    "..."
  ],
  "production": "..."
}
```

Ne jamais envoyer :

```text
niveau actuel SejourFR
score actuel
résultat du LLM actuel
niveau cible supposé
```

Cela biaiserait le benchmark.

Le résultat actuel SejourFR doit être joint uniquement après l’appel JEV.

---

# 29. Appels JEV

Utiliser la clé :

`JEVMODEL_API_KEY`

Uniquement côté script/backend local.

Prévoir :

- timeout ;
- retry limité ;
- gestion 429 ;
- erreurs réseau ;
- idempotence si pertinente ;
- sauvegarde du modèle ;
- sauvegarde réponse brute ;
- probabilités ;
- confidence ;
- token usage si disponible ;
- prompt version.

Exemple :

`jev-cefr-benchmark-v1`

---

# 30. Stabilité JEV

Ajouter une option :

```bash
--repeat N
```

Exemple :

```bash
--repeat 2
```

À utiliser sur un sous-ensemble.

Stocker chaque run séparément.

Mesurer :

```text
taux de stabilité du label
variation des probabilités
variation de confidence
```

Exemple :

```text
B1 → B1
B1 → B2
```

doit être visible comme instabilité.

Ne pas écraser les résultats précédents.

---

# 31. Troisième avis optionnel

Ajouter une option :

```bash
--arbitre
```

Désactivée par défaut.

Elle doit s’appliquer uniquement aux cas sélectionnés, par exemple :

- SejourFR ≠ JEV ;
- différence importante ;
- faible confidence ;
- cas frontière.

L’arbitre utilise un autre LLM avec :

- le même state ;
- la même grille ;
- aucune connaissance du résultat SejourFR ;
- aucune connaissance du résultat JEV.

Stocker :

```text
arbiter_level
arbiter_scores
arbiter_model
arbiter_prompt_version
```

## Important

Un accord de 2 moteurs sur 3 n’est **pas une vérité**.

C’est uniquement un signal supplémentaire.

La référence la plus forte reste une validation humaine lorsqu’elle existe.

---

# 32. Validation humaine optionnelle

Si simple à ajouter :

```text
human_level
human_note
```

Valeurs :

```text
A1
A2
B1
B2
INSUFFICIENT
INCERTAIN
```

L’écran doit alors permettre de comparer :

```text
SejourFR
JEV
Arbitre
Humain
```

Ne pas construire un gros système d’annotation si cela alourdit fortement le MVP.

---

# 33. Stockage local

Préférer SQLite.

Structure logique :

```text
sample
benchmark_run
jev_result
arbiter_result
human_review
```

Pour chaque résultat :

```text
sample_id
modality
task_type
current_level
jev_level
jev_confidence

probability_a1
probability_a2
probability_b1
probability_b2
probability_insufficient

morphosyntax_level
morphosyntax_probabilities

lexicon_level
lexicon_probabilities

coherence_level
coherence_probabilities

relevance
relevance_probabilities

task_completion
task_completion_probabilities

evidence_sufficiency
evidence_probabilities

word_count
official_min
official_max
below_official_min
above_official_max
official_length_compliant

model
prompt_version
repeat_index
created_at
error
```

---

# 34. Échantillonnage

Ne pas prendre uniquement les dernières productions.

Construire un échantillon réparti entre :

```text
EE1
EE2
EE3
petits sujets
```

et autant que possible entre :

```text
A1
A2
B1
B2
```

Ajouter des paramètres :

```bash
--limit
--task
--current-level
--repeat
--arbitre
```

Éviter les appels répétés inutiles.

---

# 35. Interface admin / benchmark

Créer un écran simple et lisible.

En haut :

```text
Productions analysées
Accord exact
Désaccord
Désaccord adjacent
Désaccord majeur
Cas frontières JEV
Faible confidence
Hors sujet
Insuffisants
Non conformes longueur officielle
```

---

# 36. Tableau principal

Colonnes :

```text
Type
Tâche
Mots
Conformité longueur
Niveau actuel
Niveau JEV
Confidence
2e niveau probable
Écart
Pertinence
Réalisation
Preuve
Arbitre éventuel
Humain éventuel
Détail
```

Code visuel :

```text
✓ accord
~ écart adjacent
! écart majeur
? faible confiance
```

---

# 37. Vue détail

Afficher :

## Consigne

Consigne exacte.

## Production

Production anonymisée.

## Longueur

```text
Nombre de mots
Minimum officiel
Maximum officiel
Conforme / non conforme
```

## SejourFR

```text
niveau actuel
scores existants
modèle
version prompt
```

## JEV global

```text
A1
A2
B1
B2
INSUFFICIENT
confidence
```

## JEV par compétence

```text
Morphosyntaxe
Lexique
Cohérence
```

## Tâche

```text
Pertinence
Réalisation
Preuve linguistique
```

## Arbitre

Si utilisé.

## Avis humain

Si utilisé.

---

# 38. Filtres importants

Ajouter :

```text
JEV ≠ SejourFR
JEV très confiant mais différent
JEV faible confiance
A1 ↔ A2
A2 ↔ B1
B1 ↔ B2
écart de 2 niveaux ou plus
hors sujet
réalisation partielle
preuve limitée
sous minimum
au-dessus maximum
arbitre ≠ JEV
humain ≠ JEV
```

---

# 39. Matrice de confusion

Afficher si raisonnablement simple :

```text
             JEV
           A1 A2 B1 B2
Actuel A1
       A2
       B1
       B2
```

Filtrable par :

```text
EE1
EE2
EE3
petits sujets
```

---

# 40. Analyse des divergences par compétence

Ajouter des statistiques permettant de voir :

```text
désaccords principalement liés à la morphosyntaxe
désaccords principalement liés au lexique
désaccords principalement liés à la cohérence
désaccords principalement liés à la réalisation
```

Objectif :

comprendre **pourquoi** JEV et SejourFR divergent.

---

# 41. Export

Prévoir :

`CSV`

et idéalement :

`JSON`

Colonnes minimales :

```text
sample_id
modality
task_type

word_count
official_min
official_max
below_official_min
above_official_max
official_length_compliant

current_level

jev_level
jev_confidence
jev_a1
jev_a2
jev_b1
jev_b2
jev_insufficient

morphosyntax_level
lexicon_level
coherence_level

relevance
task_completion
evidence_sufficiency

arbiter_level
human_level

prompt_version
model
repeat_index
```

Ne pas inclure d’informations personnelles.

---

# 42. Mesures globales

Calculer au minimum :

```text
nombre total
taux accord exact
taux désaccord
taux écart adjacent
taux écart majeur
accord par tâche
accord par niveau actuel
accord par conformité longueur
stabilité JEV
```

Distinguer :

```text
A1 ↔ A2
A2 ↔ B1
B1 ↔ B2
```

de :

```text
A1 ↔ B1
A1 ↔ B2
A2 ↔ B2
```

---

# 43. Probabilités JEV

Ne jamais stocker seulement :

```text
jev_level = B1
```

Conserver toute la distribution.

Exemple :

```text
A1 0.01
A2 0.20
B1 0.55
B2 0.24
INSUFFICIENT 0
```

et :

```text
confidence
```

Même règle pour :

- morphosyntaxe ;
- lexique ;
- cohérence ;
- pertinence ;
- réalisation ;
- preuve.

---

# 44. Aucun seuil métier pour le moment

Ne pas décider maintenant :

```text
confidence < 50 % = arbitrage automatique
```

ou :

```text
JEV > 80 % = remplacer le niveau actuel
```

Le benchmark doit observer avant de décider.

Les seuils définitifs seront établis après analyse des vraies données.

---

# 45. Versionnement des prompts

Chaque résultat doit contenir :

```text
prompt_version
```

Organisation possible :

```text
jev/
  common
  ee_task_1
  ee_task_2
  ee_task_3
  targeted_exercises
```

Éviter les prompts assemblés de manière non déterministe.

---

# 46. Tests internes avant données réelles

Réutiliser les cas déjà testés manuellement :

- A1 clair ;
- A2 clair ;
- B1 clair ;
- B2 clair ;
- frontière A1/A2 ;
- frontière A2/B1 ;
- frontière B1/B2 ;
- texte long mais faible ;
- texte court mais fort ;
- beaucoup de fautes ;
- orthographe faible mais bon niveau ;
- vocabulaire riche mais structure faible ;
- phrases apprises par cœur ;
- hors sujet ;
- matière insuffisante ;
- B2 naturel ;
- bon raisonnement mais lexique répétitif ;
- plusieurs temps verbaux maîtrisés ;
- plusieurs temps verbaux mal maîtrisés.

Ces cas doivent servir à valider le payload et les prompts.

---

# 47. Critère de réussite V1

À terme, je dois pouvoir lancer quelque chose comme :

```bash
run benchmark --limit 200
```

puis ouvrir une interface et voir :

```text
200 productions analysées

Accord exact
Désaccord
Désaccord majeur
Faible confiance
Stabilité
```

Je dois pouvoir demander :

> montre-moi les B1 actuels que JEV considère B2 avec plus de 80 %.

et examiner facilement chaque production.

---

# 48. Ce que le benchmark ne doit PAS faire

Ne pas :

- modifier le résultat candidat ;
- modifier le Plan ;
- recalculer les anciens niveaux en prod ;
- écrire les résultats JEV dans les tables métier de prod ;
- appeler JEV lors d’une nouvelle soumission réelle ;
- remplacer l’IA actuelle ;
- déclencher automatiquement l’arbitre ;
- déployer quoi que ce soit.

---

# 49. EO — audit uniquement pour l’instant

Même si V1 est EE uniquement, l’audit doit préparer V2.

Analyser :

- EO1 ;
- EO2 ;
- EO3 ;
- oral temps réel ;
- oral après enregistrement ;
- transcription ;
- segments ;
- tours examinateur/candidat ;
- informations de langue détectée ;
- erreurs de transcription ;
- limites actuelles.

Ne rien implémenter côté EO avant validation V1.

---

# 50. Préparation V2 EO

Pour la future V2, prévoir conceptuellement une décision supplémentaire :

```text
EXPLOITABLE
INCERTAINE
INEXPLOITABLE
```

pour la qualité de transcription.

Ne jamais confondre :

```text
français très faible
```

avec :

```text
transcription corrompue
```

JEV ne pourra pas évaluer correctement :

- prononciation réelle ;
- prosodie ;
- accent ;
- intelligibilité acoustique ;

à partir d’un simple transcript.

Ces dimensions devront rester hors périmètre JEV ou être traitées avec une source audio adaptée.

---

# 51. Comparaison à 3 ou 4 sources

À terme, l’écran doit pouvoir présenter :

```text
SejourFR actuel
JEV
Arbitre LLM
Humain
```

Mais aucun de ces systèmes ne doit être présenté automatiquement comme vérité absolue.

La validation humaine, lorsqu’elle existe, doit être clairement distinguée.

---

# 52. Décision attendue après audit

Dans :

`docs/JEV/audit-integration-jev.md`

terminer par une recommandation entre :

## Option A

Outil benchmark Python/local séparé.

À privilégier si cela permet de ne presque pas toucher à l’application.

## Option B

Petit module benchmark dans l’admin existante.

À choisir uniquement si cela reste simple et sans risque pour la production.

## Option C

Autre solution.

Seulement si le code existant rend A ou B inadapté.

Recommander l’approche la moins intrusive.

---

# 53. STOP obligatoire

Après avoir produit :

`docs/JEV/audit-integration-jev.md`

**STOP.**

Ne pas :

- coder l’intégration ;
- lancer de migration ;
- lancer un benchmark massif ;
- envoyer des productions réelles à JEV ;
- créer l’écran ;
- modifier le backend ;
- modifier le scoring ;
- déployer.

Je lirai le rapport et je donnerai explicitement le GO pour la suite.

---
---

# AUDIT — Intégration d'un benchmark JEV (2026-09-29)

> Audit **en lecture seule**, branche `jev`. Aucun code, aucune migration, aucun appel JEV ni
> LLM. Seules requêtes lancées : `SELECT` sur la base **locale** (`sejourfr_db`, session
> `default_transaction_read_only`). Chemins abrégés : `BE/` = `backend_sejourfr/src/main/java/com/sejourfr/app/`,
> `MIG/` = `backend_sejourfr/src/main/resources/db/migration/`, `YAML` = `backend_sejourfr/src/main/resources/application.yaml`.
>
> Livrable écrit ici à la demande du propriétaire (et non dans `docs/JEV/audit-integration-jev.md`
> comme le prévoit la §1). NB : `docs/JEV/` et `docs/jev/` sont le **même dossier** sur macOS
> (FS insensible à la casse) — garder `docs/jev/`.

## A.0 Synthèse en 10 lignes

1. Il existe **trois familles** de productions écrites notées par IA, dans **trois circuits distincts** :
   tâches EE1–EE3 (`production_submissions` → `ai_evaluations`), petits sujets EE (`user_skill_attempts`),
   et productions du **diagnostic** (`diagnostic_production_analyses`).
2. Le niveau affiché d'une tâche EE est `ai_evaluations.niveau_cecrl`, **calculé par le serveur** à partir
   de 4 notes de critères produites par le LLM (DeepSeek `deepseek-v4-flash`, grille v15 / schéma v9).
   Le niveau brut du LLM est gardé à part (`niveau_cecrl_ia`).
3. Le niveau d'un petit sujet est `user_skill_attempts.analysis_json->>'level_reached'`, émis **directement
   par le LLM** (contrat v3+), jugé sur **un seul critère**, sans colonne dédiée.
4. Les longueurs EE1 30–60 / EE2 40–90 / EE3 40–90 sont **confirmées** (contrainte SQL) et **bloquantes à
   la soumission** : aucune production EE hors bornes n'existe en base (hors données anciennes et diagnostic).
5. Aucune colonne « points requis » : la consigne est un texte libre. Les petits sujets ont un
   `unique_criterion` et une `checklist` réutilisables comme `evaluation_profile`.
6. L'audio EO n'est jamais conservé ; seules les transcriptions existent. Les tours examinateur/candidat
   du temps réel ne sont séparables **que par préfixe texte** (`Examinateur : ` / `Candidat : `).
7. Aucun accès lecture seule à la prod n'est outillé (pas de rôle dédié, pas de tunnel). Le seul précédent
   est un relevé SSH avec `default_transaction_read_only`.
8. 🛑 **RGPD** : la politique de confidentialité ne liste **aucun** fournisseur IA, alors que les
   productions partent déjà chez DeepSeek (par défaut), OpenAI (Whisper), Google (Gemini Live). Ajouter
   JEV sans corriger ce socle aggraverait un écart **déjà existant**.
9. La clé `JEVMODEL_API_KEY` **n'est pas visible** dans l'environnement shell non interactif utilisé par
   Claude Code (à vérifier : `~/.zshrc` vs `~/.zprofile`).
10. **Recommandation : Option A** — outil Python local séparé (`tools/jev-benchmark/`), SQLite gitignorée,
    export prod en lecture seule par un `SELECT` figé exécuté via SSH, **zéro modification du backend,
    des fronts et de l'admin**.

---

## A.1 Architecture actuelle du scoring

### Tâches EE1/EE2/EE3 (examen blanc et entraînement)

```text
POST /api/production-submissions (JSON)            ProductionSubmissionController.java:52
 → ProductionSubmissionService.submitText           idempotence (clientSubmissionId), rate-limit, quota
 → ProductionEvaluationService.submitAndEvaluate    sanitize NFC, countWords (split \s+), BORNES → 422
 → production_submissions (INSERT)                  + clôture auto du sous-attempt (3 tâches)
 → ProductionPipelineAsyncRunner (@Async)
    → ProductionValidityService.evaluer             juge déterministe AVANT LLM (INVALIDE ⇒ pas d'appel)
    → EvaluationPromptBuilder                       grille v15 + consigne + LONGUEUR ATTENDUE + segments numérotés
    → LLM tool-call submit_evaluation (schéma v9)   deepseek-v4-flash, T=0, 1 réparation max
    → postProcess                                   couplage, note serveur, niveau serveur, plafonds
    → ai_evaluations (INSERT)
    → versionCibleeService.enrichir                 2ᵉ appel (« version ciblée »)
```

Post-traitement serveur (`BE/service/AiEvaluationService.java:472-647`) :

- **couplage** (`:1170`) : `communiquer` et `interagir` ≤ moyenne(`lexique`, `morphosyntaxe`) + 1 ;
- **note serveur** (`:1437`) : moyenne pondérée des 4 critères à 0,25 ; elle écrase la note du LLM ;
- **niveau serveur** (`:1462` → `ProductionBilanService.computeNiveau` `:525-576`) : note 0 ⇒
  `A1_NON_ATTEINT` ; sinon seuils **B2 ≥ 10, B1 ≥ 6, A2 ≥ 2, > 0 ⇒ A1** (grille v15, `commun.niveau`) ;
- **plafonds** (`:1221`) : T3, `communiquer` ≤ 1 ⇒ niveau plafonné A2 (trace `feedback_json.plafond_niveau`).

### Petits sujets (module Compétences)

```text
SkillAttemptService.submitText (EE) / submitAudio (EO, Whisper synchrone)
 → CompetenceAnalysisServiceImpl                   DeepSeek par défaut, T=0, max 600 tokens
    grille COMPETENCE_RUBRICS_VERSION = v6, schéma COMPETENCE_TOOL_SCHEMA_VERSION = v5
    outil submit_competence_analysis → status, level_reached, level_evidence, verdict, strength_tag, focus_tag
 → CompetenceLevelEvidenceGuard                   preuve absente sur B1/B2 ⇒ −1 palier
 → user_skill_attempts.analysis_json (+ criterion_status en colonne)
 → CompetenceNiveauViseService                    2ᵉ appel « pour viser X » → analysis_json.pour_viser
```

### Diagnostic (troisième circuit)

Productions du diagnostic (`production_submissions.is_diagnostic = true`, sujets `diagnostic_code`
`INITIAL_TCF` / `QUICK_TCF`) : verdict dans `diagnostic_production_analyses` (`level_estimate`,
`task_completion`, `communication_status`, `schema_version`, `model_used`, `evaluabilite`).
Ce circuit sépare **déjà** niveau et réalisation de la tâche, comme le veut la §11.

### Banc de calibration existant

`backend_sejourfr/src/test/java/com/sejourfr/app/calibration/` (`CalibrationBenchTest`,
`CalibrationRunner`) : opt-in `-Dcalibration.enabled=true`, **payant**, 48 cas synthétiques
(`src/test/resources/calibration/golden-set-v1.json`), aucun accès base (managers mockés), rapports
dans `target/calibration/`. Pas de banc sur de vraies productions.

---

## A.2 Tables, classes et services concernés

| Objet | Rôle pour le benchmark | Réf. |
|---|---|---|
| `production_tasks` | consigne, contexte, `tache_numero`, `niveau_cible`, `mots_min/max`, `diagnostic_code` | `MIG/00_schema/V011:20-41`, V028, V029 |
| `production_submissions` | `texte_soumis`, `mots_count`, `source` (ASYNC/REALTIME), `is_diagnostic`, `statut`, `user_id`, `attempt_id` | V011:49-67, V017, V029, V046 |
| `ai_evaluations` | `niveau_cecrl` (affiché), `niveau_cecrl_ia`, `note_sur_20`, `feedback_json`, `modele_utilise`, `prompt_version`, `rubrics_version`, `evaluabilite` | V011:98-115, V022, V041 |
| `transcriptions` | texte EO + qualité Whisper | V011:79-89, V027, V035 |
| `realtime_sessions` | dialogue temps réel brut | V016, V032 |
| `diagnostic_production_analyses` | verdicts du diagnostic | V029, V040 |
| `skills` / `skill_prompts` / `skill_references` | catalogue des petits sujets | `MIG/00_schema/V025`, V026, V063 |
| `user_skill_attempts` | production + `analysis_json` des petits sujets | V025:190-255, V033, V034, V046 |
| `human_calibration_notes` | notes humaines déjà saisies via l'admin `/calibration` | V011:127-130 |
| `attempts` | `epreuve`, `type`, `parent_attempt_id`, `slot_number` (examen vs entraînement) | V006 |

Services : `AiEvaluationService`, `ProductionValidityService`, `ProductionBilanService`,
`EvaluationPromptBuilder`, `ProductionRubricsProvider`, `CompetenceAnalysisServiceImpl`,
`CompetenceAnalysisPromptBuilder`, `WhisperTranscriptionClient`, `RealtimeSessionService`,
`TranscriptionManager` (+ `TranscriptTurnStitcher`).

---

## A.3 Provenance exacte du niveau CECRL actuellement affiché

| Production | Colonne affichée | Qui décide | À joindre au benchmark |
|---|---|---|---|
| Tâche EE isolée | `ai_evaluations.niveau_cecrl` | **serveur** (note des 4 critères → seuils → plafonds) | + `niveau_cecrl_ia` (brut LLM), 4 notes de critères, `rubrics_version`, `prompt_version`, `modele_utilise` |
| Épreuve TCF_EE (examen) | aucune colonne : **dérivé à la lecture** par `ProductionBilanService.niveauEpreuve` (`:254-276`) | serveur (moyenne des 3 tâches, garde-fou T3 < B1 ⇒ ≤ B1) | hors V1 : le benchmark compare **par production** |
| Petit sujet EE | `user_skill_attempts.analysis_json->>'level_reached'` | **LLM** (seul le garde-preuve peut l'abaisser) | + `criterion_status`, `prompt_version` (= schéma), `rubrics_version`, `ai_model` |
| Diagnostic | `diagnostic_production_analyses.level_estimate` | LLM + règles V040 | à traiter comme **strate séparée** |

Pièges d'interprétation :

- `ai_evaluations.niveau_cecrl` n'est servi au front que si une `confiance` est présente
  (`BE/mapper/ProductionSubmissionMapper.java:86-114`) : « niveau en base » ≠ « niveau vu par le candidat »
  dans quelques cas.
- 🛑 **`A1_NON_ATTEINT` n'est pas `INSUFFICIENT`.** C'est un verdict (note 0, dont hors-sujet). Les
  productions **inexploitables** sont `evaluabilite = 'NON_EVALUABLE'` avec `niveau_cecrl = NULL`
  (`modele_utilise = 'validation-serveur'`). Mapping benchmark proposé :
  `NULL` ⇒ `current_level = NULL` (inconnu, **jamais** un désaccord) ; `A1_NON_ATTEINT` ⇒ gardé tel quel,
  comparé à part (ni A1 ni INSUFFICIENT).
- Le commentaire SQL de `ai_evaluations.niveau_cecrl` (V011:122, V041) parle encore de
  « lexique + morphosyntaxe » : faux sous v15 (4 critères). La `docs/pipeline-evaluation-eo-ee.md`
  annonce v14/v8 : **en retard** sur le runtime v15/v9.
- **Les versions sont hétérogènes en base.** En local, les EE notées couvrent grilles v4.2 → v15, des
  lignes sans `rubrics_version` (`prompt_version` `v1.5`/`v2`) et 3 modèles (`deepseek-v4-flash`,
  `deepseek-v4-pro`, `gpt-4o-mini`). Comparer JEV à une ligne v6 revient à benchmarker un système qui
  n'existe plus : **filtrer par défaut sur la version active (v15/v9)** et stratifier le reste.

---

## A.4 Inventaire des productions évaluables

| Famille | Identification | Circuit | V1 ? |
|---|---|---|---|
| EE1 / EE2 / EE3 (entraînement ou examen) | `production_tasks.epreuve='TCF_EE'` + `tache_numero` ; examen si `attempts.slot_number` ou `parent_attempt_id` non NULL | `ai_evaluations` | **oui** |
| Petits sujets EE (48 compétences dont 24 EE actives, 360 sujets EE) | `skills.section='EE'`, `skills.task_code` EE1..EE3 | `user_skill_attempts` | **oui** |
| Diagnostic écrit (`INITIAL_TCF` 100–120 mots, `QUICK_TCF` 80–300 mots) | `production_submissions.is_diagnostic`, `production_tasks.diagnostic_code` | `diagnostic_production_analyses` | strate optionnelle (voir A.18) |
| EO1 / EO2 / EO3 enregistré (Whisper) | `epreuve='TCF_EO'`, `source='ASYNC'` | `ai_evaluations` + `transcriptions` | V2 |
| EO1 / EO2 temps réel (Gemini Live) | `source='REALTIME'` | idem + `realtime_sessions` | V2 |
| Petits sujets EO | `skills.section='EO'` | `user_skill_attempts.transcript` | V2 |

⚠️ `SkillTaskCode` (EE1…EO3) ne sert **qu'au module Compétences**. Pour les tâches d'examen, EE1 se lit
`epreuve='TCF_EE' AND tache_numero=1`. Le `task_type` du benchmark doit être construit par l'outil.

---

## A.5 Spécificités EE et EO

| | EE | EO |
|---|---|---|
| Texte évalué | `texte_soumis` (NFC, trim) | transcription Whisper **ou** dialogue temps réel |
| Bornes | **bloquantes** 30–60 / 40–90 / 40–90 mots | aucune durée minimale imposée |
| Critères (v15) | `communiquer`, `interagir`, `lexique`, `morphosyntaxe` (0,25 chacun) | idem, mais le correcteur ne juge **ni** prononciation, **ni** fluidité, **ni** orthographe |
| Plafonds | T3 : prise de position faible ⇒ ≤ A2 | T3 idem ; **EO T2** : conduite de l'échange faible ⇒ ≤ A2 |
| Confiance | LLM | plafonnée MOYENNE (temps réel) ou FAIBLE (`qualite_degradee`) |
| Segments de preuve | une phrase = un segment | temps réel : un segment par tour **candidat** ; l'examinateur est visible mais non citable |

Pour la §11 (ne pas mélanger niveau et tâche) : le système actuel **mélange** en partie — `communiquer`
porte la réalisation de la tâche et pèse 25 % du niveau, et un hors-sujet donne une note 0 ⇒
`A1_NON_ATTEINT`. C'est une **différence de construction attendue** avec JEV (qui sépare pertinence et
niveau) : un désaccord « hors-sujet bien écrit » (actuel `A1_NON_ATTEINT`, JEV B1) sera **structurel**,
pas une erreur de l'un ou l'autre. Il faut l'isoler dans les statistiques.

---

## A.6 Structure des transcriptions EO

Table `transcriptions` (`MIG/00_schema/V011:79-89` + V027 + V035), écrite par
`WhisperTranscriptionService.persist` (`BE/service/WhisperTranscriptionService.java:66-87`) :

- `texte`, `langue_detectee`, `modele_utilise` (`whisper-1`), `prompt_utilise`, `audio_duration_sec`, `cout_micro_usd` ;
- agrégats de qualité : `avg_logprob` (moyenne pondérée), `no_speech_prob` et `compression_ratio`
  (pire segment), `segments_count`, `taux_formes_suspectes`, `taux_collages`, `qualite_degradee`.

Limites :

- **Segments Whisper non stockés** (ni horodatage, ni texte par segment, ni logprob par mot).
- Whisper est appelé avec **`language=fr` forcé** (`WhisperTranscriptionClient.java:70`, `YAML:434`) :
  une parole étrangère peut être « francisée » et devenir indétectable. `langue_detectee` n'est donc pas
  une mesure fiable.
- Temps réel : `langue_detectee='fr'` **codé en dur**, métriques Whisper à NULL.
- Audio **jamais conservé** (`BE/util/AudioEphemere.java:36-49`, V033) : impossible de re-transcrire.

---

## A.7 Tours examinateur / candidat en EO

- Temps réel (EO T1/T2 seulement, `RealtimeSessionService.java:79-81`) : chaque tour est ajouté à
  `realtime_sessions.transcript` avec un préfixe `Examinateur : ` ou `Candidat : ` et un saut de ligne
  (`:178-215, 392-396`), puis recopié dans `transcriptions.texte` à la fin de la session.
- **Pas** de JSON de tours, **pas** de table de tours, **pas** d'horodatage par tour.
- Le mobile fusionne les fragments consécutifs d'un même locuteur avant l'envoi ; le serveur les recolle
  aussi **à la lecture** (`TranscriptTurnStitcher`, sans réécriture en base). Le texte « vu » par le
  correcteur ≠ le texte brut en base : choisir le texte recollé pour la V2.
- `media_duration_sec` en temps réel **inclut** le temps de parole de l'examinateur.
- Mode enregistré : monologue, pas d'examinateur. Le comportement d'un EO T2 en ASYNC reste **à vérifier**.

---

## A.8 Fonctionnement des petits sujets

- **Catalogue actif** : 6 tâches × 8 compétences × 15 sujets × 3 références = 48 compétences,
  720 sujets, 2 160 références (verrouillé par `SkillSeedIT`). Seeds `MIG/300_tcf/competences/V300…V320`
  (taxonomie V3 : V319, V320). Les compétences CO/CE de V318 n'ont aucun sujet.
- **Représentation** (`skill_prompts`) : `context`, `instruction` (consigne), `unique_criterion`
  (**le seul critère jugé**), `recommended_min_words`/`max_words` (EE) ou `recommended_duration_seconds`
  (EO), `difficulty_level`, `checklist jsonb`, `constraint_tags jsonb`, `answer_starter`, `tip`.
- **Aucun champ « points requis »** ; `checklist` et `unique_criterion` sont les meilleurs candidats
  pour construire l'`evaluation_profile` de la §27 — à relire sur un échantillon, car la checklist est
  un guidage pour le candidat, pas une grille.
- `skill_references.level` (`INSUFFICIENT`/`EXPECTED`/`EXCELLENT`) est **éditorial**, pas CECRL.
- `skills.target_level` n'est pas toujours celui de la tâche (`EE3-C1/C2/C4` sont B1). Palier
  pédagogique interne, **jamais** envoyé à JEV (§28).
- **Données envoyées au LLM actuel** : épreuve, section, tâche, compétence, contexte, consigne,
  critère unique, production segmentée. **Jamais** la longueur.
- **Sortie** : `status`, `level_reached` (A1_NON_ATTEINT…B2), `level_evidence`, `verdict`, tags. Pas de
  notes par critère. Les tentatives en contrat v1/v2 **n'ont pas** de `level_reached` ⇒ exclues.
- ⚠️ Comparabilité : le niveau actuel d'un petit sujet est jugé **à travers un critère unique** ; JEV
  jugera la production entière. Un écart ici n'a pas le même sens qu'un écart sur EE1–EE3 : strate à part.
- ⚠️ Doc en retard : `docs/regles/competences.md:117-119` annonce v5+v4, le YAML sert v6+v5. Les
  commentaires de V025 et la javadoc de `UserSkillAttempt` disent encore « aucun niveau » (périmé).

---

## A.9 Règles de longueur appliquées

### Tâches EE (vérifié dans le code et la base locale)

| Tâche | Bornes | Source |
|---|---|---|
| EE1 | **30–60** | contrainte `chk_prod_task_tcf_irn_ee_word_bounds` (`MIG/300_tcf/production/V756…:55-61`) |
| EE2 | **40–90** | idem (minimum passé de 60 à 40 en V724) |
| EE3 | **40–90** | idem |
| Diagnostic `INITIAL_TCF` (T3) | 100–120 | exempté (V758) |
| Diagnostic `QUICK_TCF` (T3) | 80–300 | exempté (V758) |

- Comptage : `split(\s+)` après NFC/trim (`BE/util/ProductionPayloadSupport.java:111-114`). **Le script
  devra reproduire exactement ce comptage**, sinon `word_count` divergera du `mots_count` stocké.
- Hors bornes ⇒ **refus 422 avant toute ligne en base** (`ProductionEvaluationService.java:436-462`,
  `ProductionTextBounds`). Aucune pénalité, aucun plafond ; la grille v15 interdit de pénaliser la longueur.
- **Conséquence pour la §10** : sur les données actuelles, `below_official_min` / `above_official_max`
  seront **presque toujours faux** pour EE1–EE3. Seules exceptions : données antérieures à V724 (T2/T3 à
  60 minimum) et productions du diagnostic. Les colonnes restent utiles, mais l'analyse « accord par
  conformité longueur » sera quasi vide en V1. Elle prendra son sens sur les petits sujets.

### Petits sujets

- Fourchettes **recommandées, jamais bloquantes** (V025:115-120). En local : EE1 30–60, EE2 15–90,
  EE3 40–90 mots (min et max par sujet varient) ; EO 20–60 s.
- Seules limites dures : `max-text-words: 400` (422) et `max-audio-duration-seconds: 180`.
- Conformément à la §10 : stocker `recommended_min` / `recommended_max` dans des colonnes **distinctes**
  de `official_min/max` (qui restent NULL pour les petits sujets).

---

## A.10 Données nécessaires au benchmark (mapping §8)

| Champ §8 | Source EE1–EE3 | Source petit sujet EE |
|---|---|---|
| `benchmark_sample_id` | HMAC(`submission.id`, sel local) | HMAC(`user_skill_attempts.id`, sel local) |
| `modality` | `EE` | `EE` |
| `task_type` | `EE_TASK_{tache_numero}` | `EE_TARGETED` |
| `exercise_type` | `TRAINING` / `MOCK_EXAM` / `DIAGNOSTIC` (dérivé d'`attempts`) | `skills.code` (ex. `EE3-C9`) |
| `task_instruction` | `production_tasks.consigne` | `skill_prompts.instruction` |
| `task_context` | `production_tasks.contexte` | `skill_prompts.context` |
| `required_points` | **absent** ⇒ vide en V1 (voir A.14) | `checklist` + `unique_criterion` |
| `candidate_production` | `texte_soumis` (après rédaction) | `written_production` (après rédaction) |
| `current_cefr_level` | `ai_evaluations.niveau_cecrl` | `analysis_json->>'level_reached'` |
| `current_scores` | `feedback_json->'scores_criteres'` + `note_sur_20` + `niveau_cecrl_ia` | `criterion_status`, `analysis_json->>'status'` |
| `current_ai_model` | `modele_utilise` | `ai_model` |
| `current_prompt_version` | `rubrics_version` + `prompt_version` | `rubrics_version` + `prompt_version` |
| `word_count` | recalculé (même règle) ; contrôle croisé avec `mots_count` | recalculé |
| `official_min/max` | `production_tasks.mots_min/max` | NULL |

Champs à ajouter : `current_evaluabilite`, `current_confiance` (`feedback_json`), `plafond_applique`
(`feedback_json.plafond_niveau`), `submitted_month` (mois seulement, pour stratifier sans horodatage fin).

🛑 Aucun `user_id` exporté. **Mais** le lien à l'identité n'est pas seulement `user_id` : `attempt_id`
(→ `attempts.user_id`) et l'UUID de la soumission sont aussi des clés de ré-identification ⇒ ils ne
sortent jamais de la prod en clair (d'où le HMAC salé localement).

---

## A.11 Méthode la moins intrusive pour lire la production

État des lieux : aucun rôle Postgres en lecture seule, aucun tunnel documenté ; accès actuel =
`ssh root@VPS` + `psql` (`backend_sejourfr/DEPLOIEMENT_BACKEND.md:59, 294-297`). Précédent :
`docs/admin/audit-suivi-prod-2026-09-29.md` (session `default_transaction_read_only`).

Options, de la moins à la plus intrusive :

| Option | Écrit en prod ? | Mérite | Limite |
|---|---|---|---|
| **1. Export figé via SSH** : une requête `SELECT` versionnée (`export_ee_v1.sql`), lancée par `psql -X --set=ON_ERROR_STOP=1 -c "SET default_transaction_read_only=on" -f -` sur le VPS, sortie `COPY … TO STDOUT` (JSONL) **redirigée localement** dans un dossier gitignoré | **non** | zéro changement serveur ; colonnes contrôlées par la requête ; `user_id` utilisé **dans** la requête (plafond par candidat) mais jamais projeté | connexion avec le compte `sejourfr` applicatif (lecture seule seulement par session) |
| 2. Rôle dédié `jev_reader` : `SELECT` sur les 6 tables utiles, ou mieux sur **une vue** sans colonnes identifiantes, via tunnel `ssh -L` | oui (1 `CREATE ROLE` + `GRANT`, manuel, hors Flyway) | isolation par droits, réutilisable | c'est une modif prod ⇒ décision du propriétaire |
| 3. `pg_dump` complet puis travail local | non | simple | ❌ rapatrie **toute** la base (emails, noms) en local : contraire à la §3 |

**Recommandation : option 1 pour V1** (aucune écriture en prod, aucun compte admin Postgres exposé en
local, colonnes limitées par construction). Option 2 si le benchmark devient récurrent.
La rédaction des données personnelles (§9) se fait **localement, avant tout stockage SQLite**, et le
JSONL brut est supprimé après import.

---

## A.12 Proposition d'architecture du benchmark

```text
prod (VPS) ──ssh psql READ ONLY──▶ export_*.jsonl (gitignoré, éphémère)
                                        │
fixtures synthétiques (versionnées) ────┤
                                        ▼
                    import → rédaction PII → longueur → SQLite (gitignorée)
                                        │
                  state_builder (prompt versionné, SANS niveau actuel)
                                        ▼
                  JEV API (JEVMODEL_API_KEY, env seulement) ──▶ jev_result (+ réponse brute)
                                        │   (--repeat N : 1 ligne par run, jamais écrasée)
                  --arbitre (opt-in, cas filtrés) ──▶ arbiter_result
                                        ▼
                  report / export CSV-JSON / interface locale (lecture SQLite)
```

- **Python** : l'environnement système est Python 3.9.6, sans `requirements.txt` dans le dépôt. Proposer un
  `pyproject.toml` isolé dans `tools/jev-benchmark/` (Python ≥ 3.11 via `uv` ou `venv`), dépendances
  minimales : `httpx` (timeouts, retries), `sqlite3` (stdlib). Pour l'interface : **Streamlit** (tableau
  filtrable + matrice de confusion en ~200 lignes) ; alternative zéro dépendance : page HTML statique
  générée depuis SQLite.
- **Schéma SQLite** : `sample`, `benchmark_run`, `jev_result`, `arbiter_result`, `human_review`, colonnes
  de la §33, **distributions complètes stockées en JSON**, plus la réponse brute JEV.
- **Prompts** : fichiers texte versionnés `prompts/{common,ee_task_1,ee_task_2,ee_task_3,targeted}.txt`,
  assemblage déterministe, `prompt_version = jev-cefr-benchmark-v1` + hash du contenu assemblé.
- **Référence humaine existante** : `human_calibration_notes` (saisie via l'admin `/calibration`) peut
  alimenter `human_level` sans rien construire — à vérifier : volume et échelle des notes en prod.

---

## A.13 Fichiers à créer / modifier après ton GO

**Créer** (tous sous `tools/jev-benchmark/`, hors des 4 applications) :

```text
tools/jev-benchmark/
  pyproject.toml
  jev_bench/
    config.py          lecture env (JEVMODEL_API_KEY, clé arbitre), chemins
    sql/export_ee_v1.sql        SELECT figé tâches EE (version active par défaut)
    sql/export_targeted_ee_v1.sql  SELECT figé petits sujets EE
    importer.py        JSONL → SQLite ; HMAC des identifiants ; suppression du brut
    redact.py          emails, téléphones, noms évidents → [EMAIL] [TELEPHONE] [PERSONNE]
    length.py          comptage identique à ProductionPayloadSupport + bornes
    prompts/           common.txt, ee_task_1.txt, ee_task_2.txt, ee_task_3.txt, targeted.txt
    state_builder.py   state JEV (jamais de niveau actuel / cible)
    jev_client.py      timeout, retry borné, 429, sauvegarde brute
    arbiter.py         opt-in --arbitre
    store.py           schéma SQLite
    run.py             CLI --source synthetic|export --limit --task --current-level --repeat --arbitre --dry-run
    report.py          métriques §42, stabilité §30, export CSV/JSON §41
    app.py             interface locale §35-40
  fixtures/synthetic_ee_v1.jsonl   les ~30 cas de docs/jev/conversation_jev_tests_cecrl.md (§46)
  data/               (gitignoré) SQLite, exports, JSONL
```

**Modifier** : `.gitignore` racine (`tools/jev-benchmark/data/`, `*.sqlite`, `*.jsonl` du dossier).
**Documentation** : `docs/jev/` (architecture, résultats **agrégés** uniquement).
**Pas touché** : backend, admin, web, mobile, migrations Flyway.
**Plus tard, hors V1 et sur décision RGPD** : `web_sejoufr/content/legal/legal-info.ts` (liste des
sous-traitants) et `app/confidentialite/page.tsx` — voir A.16.

---

## A.14 Risques identifiés

| # | Risque | Mitigation |
|---|---|---|
| R1 | **Biais de construction** : l'actuel mêle réalisation de la tâche et niveau (`communiquer` à 25 %, hors-sujet ⇒ note 0) | analyser à part les lignes `A1_NON_ATTEINT`, `plafond_applique` et les lignes JEV `HORS_SUJET` |
| R2 | **Versions hétérogènes** en base (v4.2 → v15, 3 modèles) | filtre par défaut `rubrics_version='v15' AND prompt_version='v9'`, et stratification |
| R3 | **`required_points` absent** pour EE1–EE3 ; les extraire de `feedback_json.accomplissement` reviendrait à injecter la lecture du LLM actuel dans le state JEV (fuite de biais, §28) | V1 : consigne seule ; si besoin, points rédigés **à la main** pour les ~60 sujets EE (20 par tâche), versionnés dans `prompts/` |
| R4 | **Volume réel inconnu** (en local : ~90 évaluations EE toutes versions) ; ce volume n'a pas été mesuré en prod | premier pas après GO : une requête **COUNT seule** en prod (tâche × version × niveau) |
| R5 | Données personnelles dans le texte libre (courriels EE1/EE2 : prénoms, adresses, téléphones fictifs **ou réels**) | rédaction locale ; vérification manuelle d'un échantillon avant tout envoi |
| R6 | Surreprésentation d'un même candidat | plafond `row_number() OVER (PARTITION BY user_id) ≤ 3` **dans** la requête prod, `user_id` jamais projeté |
| R7 | Petits sujets jugés sur **un critère** : comparaison non homogène | strate séparée, jamais agrégée avec EE1–EE3 |
| R8 | Clé JEV non visible dans l'environnement shell de Claude Code | à vérifier avant toute exécution (`~/.zprofile` vs `~/.zshrc`) ; ne jamais la placer dans `backend_sejourfr/.env` ni `mobile_sejourfr/.env` (**ce dernier est embarqué dans l'app**) |
| R9 | API JEV non documentée ici (questions multiples par requête, usage de tokens, nom du modèle, rate limits) | vérifier la doc JEV avant d'écrire `jev_client.py` ; les tests §46 ont été faits dans le **Playground**, pas via l'API |
| R10 | Coût JEV et arbitre (payant) | `--dry-run` qui compte les appels et estime le coût ; l'arbitre n'est lancé que sur ta décision (règle « aucun LLM payant sans demande ») |
| R11 | `docs/jev/conversation_jev_tests_cecrl.md` est **versionné** | contient des textes synthétiques, pas des productions réelles : OK. À garder ainsi |
| R12 | `backend_sejourfr/src/test/resources/calibration/golden-set-competences-v1.json` (versionné) contient **33 productions réelles** d'après `docs/regles/competences.md` | hors périmètre JEV, mais à vérifier (anonymisation) dans le cadre du chantier RGPD |

---

## A.15 Impact estimé sur le code existant

**Nul sur l'application** avec l'option A : aucun fichier des 4 sous-projets modifié, aucune migration,
aucune route, aucun déploiement. Seuls ajouts : `tools/jev-benchmark/`, une ligne `.gitignore`, des docs.
Côté prod : zéro écriture (option 1 de A.11) ; une connexion SSH en lecture par export.

---

## A.16 Stratégie RGPD / sous-traitance JEV

### Constat sur l'existant (à traiter indépendamment de JEV)

- `web_sejoufr/content/legal/legal-info.ts:132-146` ne liste qu'**IONOS** (FR) et **Stripe** (IE).
- **Aucun** fournisseur IA n'est déclaré, alors que les productions sont déjà envoyées à **DeepSeek**
  (correcteur par défaut, `YAML:461`), **OpenAI** (Whisper), **Google** (Gemini Live), et selon la config
  Anthropic ou Azure Speech.
- `app/confidentialite/page.tsx:46-48, 391-420` affiche « Vos données sont traitées exclusivement au sein
  de l'Union européenne. Aucun transfert hors UE n'est effectué ». Ce texte est **calculé depuis la liste
  des sous-traitants** : il est faux dès aujourd'hui.
- Aucune durée de conservation propre aux productions ni aux transcriptions.

### Informations JEV à obtenir (aucune n'est dans le dépôt : **à fournir par toi / par JEV**)

| Point §7 | Statut |
|---|---|
| Fournisseur de modèle réellement appelé derrière l'API JEV | inconnu |
| Localisation du traitement et du stockage | inconnue |
| Durée de conservation, rétention des requêtes, logs | inconnue |
| Usage des données pour l'entraînement (et opt-out) | inconnu |
| DPA disponible, liste des sous-traitants ultérieurs | inconnu |
| Transferts hors UE et garanties (CCT, DPF) | inconnus |
| Compatibilité CGU / confidentialité SejourFR | **non compatible en l'état** (voir constat) |

### Stratégie proposée

1. **Phase 0 (sans RGPD bloquant)** : uniquement des fixtures synthétiques (§46), rien de réel.
2. **Avant toute production réelle** : obtenir de JEV les 7 réponses ci-dessus (idéalement DPA +
   zéro rétention + pas d'entraînement), puis décider.
3. Le benchmark sur données réelles relève de l'**amélioration du service** : c'est une finalité à
   mentionner dans la politique de confidentialité (base : intérêt légitime, à confirmer par toi).
4. Minimisation : rédaction PII, aucun identifiant, échantillon borné (≤ 200), `data/` supprimé en fin
   d'étude.
5. Mise à jour de `legal-info.ts` (fournisseurs IA existants + JEV si retenu) : chantier web séparé.

---

## A.17 Stratégie d'échantillonnage

1. **Mesurer d'abord** (COUNT seul en prod) : volumes par tâche × `rubrics_version` × `niveau_cecrl`, et
   petits sujets par `task_code` × `level_reached` × contrat.
2. Population V1 : tâches EE `statut='EVALUATED'`, `evaluabilite='EVALUABLE'`, version active v15/v9,
   **hors diagnostic** ; petits sujets EE contrat ≥ v3 (`level_reached` présent).
3. Tirage **stratifié** tâche (EE1/EE2/EE3/petits sujets) × niveau actuel (A1/A2/B1/B2), avec plafond par
   cellule (ex. 200 / 16 ≈ 12) et au plus 3 productions par candidat. Tirage aléatoire **à graine fixe**
   (reproductible), pas « les dernières ».
4. Strates « piège » ajoutées volontairement : `A1_NON_ATTEINT`, plafond T3 appliqué, `NON_EVALUABLE`
   (JEV doit répondre `INSUFFICIENT`), versions antérieures (en option).
5. `--repeat 2` sur un sous-ensemble fixe d'environ 30 productions pour la stabilité.
6. Si une cellule est vide (probable pour B2 ou A1 en EE1), on le dit dans le rapport, sans compléter
   artificiellement.

---

## A.18 Phasage V1 / V2

- **V1-a (sans données réelles)** : outil complet, fixtures synthétiques de la §46, validation du
  payload, des prompts et du format de réponse JEV. Appels JEV peu nombreux (~30 × 7 questions).
- **V1-b (après validation RGPD)** : export réel EE1–EE3 + petits sujets EE, ≤ 200 productions,
  rapports, interface.
- **V1-c (optionnel)** : strate diagnostic écrit. Intérêt : `diagnostic_production_analyses` sépare
  déjà niveau et `task_completion`, directement comparable aux questions « réalisation » de JEV.
- **V2 (EO)** : ajouter la décision `EXPLOITABLE / INCERTAINE / INEXPLOITABLE`, alimentée d'abord par les
  signaux serveur existants (`qualite_degradee`, `avg_logprob`, `no_speech_prob`, verdict
  `ProductionValidityService`) avant de la demander à JEV. Stratifier par `source` (ASYNC Whisper vs
  REALTIME Gemini), car les biais de transcription diffèrent (dans la doc, 6 transcriptions temps réel sur 39
  contiennent de l'écriture non latine, contre 0 sur 36 avec Whisper). En temps réel, n'envoyer que les
  tours `Candidat :` comme production et les tours `Examinateur :` comme contexte. Prononciation et
  prosodie restent hors périmètre.

---

## A.19 Recommandation finale

**Option A — outil Python local séparé**, pour trois raisons tirées du code :

1. L'admin a déjà un écran `/calibration` (`AdminCalibrationController`), mais l'option B imposerait des
   appels JEV **depuis le backend de prod**, de nouvelles tables (migrations) et un déploiement : trois
   interdits de la §3/§48.
2. Toutes les données utiles sont lisibles par un `SELECT` figé : aucune logique Java n'a besoin
   d'être réexécutée, puisque le niveau actuel est déjà persisté.
3. Le banc Java existant est conçu pour des corpus synthétiques avec managers mockés : il n'est pas
   adapté à des productions réelles et à une interface de revue.

**Préalables à lever avant le premier appel JEV :**

- (a) clé `JEVMODEL_API_KEY` accessible au shell ;
- (b) documentation de l'API JEV (plusieurs questions par requête, format des probabilités, usage) ;
- (c) décision RGPD pour la phase V1-b.

**Ordre proposé après ton GO :**

1. Squelette de l'outil et fixtures synthétiques.
2. Premier `--dry-run`, sans appel.
3. ~30 appels JEV sur les fixtures ; le coût t'est annoncé avant l'envoi.
4. Revue.
5. COUNT en prod.
6. Décision RGPD.
7. Export réel.

**STOP.** Aucun code n'a été écrit. J'attends ton GO.
