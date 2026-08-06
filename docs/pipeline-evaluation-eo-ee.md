# Pipeline d'évaluation des productions TCF IRN (EO + EE)

Ce document décrit le branchement technique actuel de la correction des productions. La
référence pédagogique exhaustive reste [`notation-ia-eo-ee.md`](notation-ia-eo-ee.md).

## Contrat actif

- Profil : **TCF IRN uniquement**.
- Niveau de sortie maximal : **B2** ; C1 et C2 ne font pas partie du contrat actif.
- Rubriques : `prompts/production-rubrics-v9.json`.
- Tool-schema : `prompts/production-evaluation-tool-schema-v5.json`.
- Correcteur par défaut : **DeepSeek `deepseek-v4-flash`**.
- Examinateur vocal temps réel : **Gemini Live**. Il conduit/transcrit l'échange mais ne
  note jamais ; le transcript final revient dans le même pipeline correcteur.
- EE : T1 **30–60 mots**, T2/T3 **60–90 mots**, bornes strictes.

La v7 déclare `profile=TCF_IRN`, `niveau_max=B2` et `tool_schema_version=v4`.
`ProductionRubricsProvider` refuse au chargement une paire incompatible (par exemple v7/v3).
Les versions v6/v3 restent intactes pour rollback ; on versionne, on ne réécrit pas.

## Parcours des données

### Expression écrite

1. Le front envoie le texte à `ProductionEvaluationService`.
2. Le service vérifie le nombre de mots contre les bornes de la tâche. Il n'existe plus de
   tolérance de 20 %.
3. `ProductionValidityService` applique les contrôles déterministes : production exploitable,
   langue dominante et recopiage de consigne.
4. `AiEvaluationService` construit les prompts, appelle le correcteur choisi, valide sa sortie
   brute, post-traite et persiste `AiEvaluation`.

### Expression orale enregistrée

1. L'audio est envoyé dans le stockage R2 privé.
2. `WhisperTranscriptionService` produit une transcription littérale.
3. La transcription suit exactement le même `AiEvaluationService` que l'EE.

### Expression orale temps réel

1. Gemini Live joue l'examinateur et fournit le dialogue transcrit.
2. `ProductionEvaluationService.evaluateRealtimeTranscript` crée la submission et la
   transcription déjà finalisée ; Whisper est sauté.
3. Le même runner async et le même `EvaluationLlmClient` évaluent le transcript.

La durée de l'EO peut rester stockée comme métadonnée de session, mais elle n'est plus insérée
dans le prompt de notation et ne produit plus d'avertissement de score.

### Frontières transactionnelles du runner

`ProductionPipelineAsyncRunner` est volontairement un orchestrateur **sans transaction
englobante**. `WhisperTranscriptionService` et `AiEvaluationService` exécutent leurs écritures
dans leurs propres transactions. En cas d'exception, `ProductionPipelineFailureRecorder`
persiste `FAILED` et le message original dans une transaction `REQUIRES_NEW` indépendante.

Cette frontière évite qu'une exception d'un service interne marque une transaction externe
`rollback-only`, puis fasse sortir un `UnexpectedRollbackException` après le `catch` du runner.
Comme la submission est ensuite détachée, le runner la charge avec `findByIdWithTask` avant de
lire l'épreuve : remplacer ce chargement par un `findById` simple réintroduirait un accès lazy
hors session et pourrait marquer à tort un succès comme `FAILED`.

## Source unique du correcteur

Toute voie de notation lit `sejourfr.production-evaluation` dans `application.yaml` :

```yaml
sejourfr:
  production-evaluation:
    provider: ${EVAL_LLM_PROVIDER:deepseek}
    rubrics-version: ${EVAL_RUBRICS_VERSION:v7}
    deepseek:
      model: ${EVAL_DEEPSEEK_MODEL:deepseek-v4-flash}
      prompt-version: ${EVAL_PROMPT_VERSION:v4}
```

`EvaluationLlmConfig` expose un unique bean primaire `EvaluationLlmClient`. Il est utilisé par :

- l'évaluation asynchrone EE/EO ;
- la fin d'une session orale temps réel ;
- la réparation sémantique ;
- la seconde passe optionnelle ;
- le banc de calibration.

La seconde passe ne possède plus de propriété `provider`. `ProductionSecondePasseService`
reçoit le même bean primaire, donc le même provider et le même modèle. Le banc ne reconnaît
plus `calibration.provider` : il charge le provider/modèle du runtime et ne surcharge que les
versions de rubriques et de schéma demandées par la campagne.

Providers supportés :

- `deepseek` et `openai` via `OpenAiCompatibleEvalClient` ;
- `anthropic` via `EvaluationAnthropicClient`.

Changer `EVAL_LLM_PROVIDER` est la seule bascule globale. Les réglages Gemini sous
`sejourfr.realtime` restent indépendants car ils concernent la conversation/transcription,
pas la correction.

## Construction des prompts

`ProductionRubricsProvider` charge la rubrique versionnée et expose :

- `commun.sections` + `commun.few_shot` pour le system prompt ;
- `rubrics.EE_T1..3` / `EO_T1..3` pour le message de tâche ;
- `commun.niveau`, `couplage`, `plafonds` et `bandes_criteres` pour les calculs serveur.

`EvaluationPromptBuilder` assemble ces données avec la consigne, le contexte, le niveau cible,
les bornes de mots et la production. Pour l'EO, il n'ajoute **aucun bloc durée**. Les niveaux
présentés au modèle s'arrêtent à B2.

Les quatre critères v7, équipondérés, sont toujours :

1. `communiquer` ;
2. `interagir` ;
3. `lexique` ;
4. `morphosyntaxe`.

## Validation brute et retry sémantique

Le function calling ne suffit pas à garantir qu'un fournisseur respecte le contrat.
`EvaluationOutputValidator` intervient donc **avant toute normalisation** et avant tout calcul.

Pour v4, il exige notamment :

- tous les champs racine requis et aucun champ imprévu ;
- un niveau parmi `A1_NON_ATTEINT`, `A1`, `A2`, `B1`, `B2` ;
- une note globale numérique finie dans `[0,20]` ;
- exactement quatre scores, ensemble de codes exactement égal à la rubrique ;
- aucun doublon, manque ou code supplémentaire ;
- chaque note de critère finie dans `[0,20]` ;
- chaque preuve non vide et rattachée à un passage réel par `EvaluationProofMatcher` :
  recherche contiguë exacte après normalisation Unicode NFKC/NFD (`œ`/`oe`, `æ`/`ae`,
  casse, accents, apostrophes, tirets et espaces neutralisés), puis seulement pour une
  citation d'au moins 4 tokens un fallback sur une fenêtre de taille `n-1`, `n` ou `n+1` ;
  ce fallback autorise au maximum une insertion ou suppression prise dans une courte liste
  fermée de mots-outils. La seule substitution admise est la flexion
  `telle/tels/telles`, explicitement reconnue ; toute autre substitution de caractère est
  refusée. Il exige au moins 3 tokens significatifs identiques et un match unique, et
  refuse tout écart de nombre/négation — tout token contenant un chiffre est immuable —,
  tout remplacement de mot porteur, synonymie recherchée ou réordonnancement ; en EO
  dialoguee, seules les fenêtres des tours `Candidat :` sont indexées ;
- la canonicalisation de toute preuve acceptée vers la sous-chaîne originale exacte avant
  construction du `feedbackJson` persisté ;
- les structures complètes de confiance, accomplissement, priorités et exemples corrigés ;
- des objets fermés, cohérents avec `additionalProperties:false` du schéma v4.

Si la première sortie est invalide, `AiEvaluationService.evaluateValidated` effectue **une
seule** seconde requête auprès du même client en ajoutant la liste précise des violations. Si
la sortie réparée est valide, les tokens d'entrée, tokens de sortie et coûts des **deux**
appels sont additionnés dans l'`Outcome` persisté.

Un seul repli dégradé est permis après ce second appel : si l'unique violation restante est
une citation non vide mais impossible à rattacher pour **un seul** des quatre critères, alors
que les trois autres preuves et toute la structure sont valides, cette citation est retirée.
Elle n'est jamais persistée ni affichée, la confiance est plafonnée à `MOYENNE` (une confiance
`FAIBLE` reste `FAIBLE`) et un avertissement serveur l'explique au candidat. Le tool-schema
v4 continue d'exiger quatre preuves : ce repli n'est pas une permission donnée au LLM.

Deux preuves non rattachables, une preuve vide, ou la présence de n'importe quelle autre
violation lèvent toujours une `AiEvaluationException` ; aucune note partielle n'est alors
enregistrée et le pipeline rend la submission `FAILED`.

Limite de traçage actuelle : quand les deux sorties sont invalides, il n'existe pas
d'`AiEvaluation` réussie où persister leurs coûts. Les appels apparaissent dans les logs du
fournisseur, mais pas comme une ligne de coût applicative.

La même limite vaut si la seconde passe optionnelle échoue après une première passe valide :
la première passe reste exploitable, mais l'usage du ou des appels échoués de la seconde passe
n'est pas disponible dans son `Outcome` et ne peut donc pas être ajouté à la ligne applicative.
Il reste consultable dans les métriques ou logs du fournisseur.

## Garde-fou EO testable

Une sortie EO est rejetée si un champ évaluatif fonde la note, les commentaires, les points
forts/faibles, les suggestions, les avertissements, l'accomplissement ou l'explication d'une
correction sur :

- hésitations, répétitions ou faux départs ;
- fluidité, aisance, débit, prononciation, accent ou intonation ;
- orthographe ou ponctuation de la transcription ;
- durée de l'enregistrement ou temps de parole (jamais une durée qui fait partie du contenu,
  par exemple la durée de résidence en France).

`confiance_raisons` est la seule exception : une transcription incertaine peut y expliquer
une confiance moindre sans modifier la note. Après validation, le filtre historique
`stripOrthographicCorrections` retire encore les corrections EO purement orthographiques.

## Calcul serveur

Après validation et post-traitement :

1. le couplage plafonne `communiquer` et `interagir` à la moyenne de langue + 1 ;
2. les bandes qualitatives sont dérivées des scores couplés ;
3. `weightedNote` exige les quatre codes exacts, une seule fois chacun, puis calcule la
   moyenne pondérée à une décimale ;
4. tout score manquant, dupliqué, inconnu ou hors bornes est bloquant : aucun fallback vers
   `note_globale` du LLM ;
5. le niveau serveur est lu sur l'échelle `0 / 1 / 2–5 / 6–9 / 10–20`, plafonnée à B2 ;
6. les plafonds ciblés de tâche s'appliquent ensuite.

Le niveau brut du LLM reste advisory pour la calibration. Le niveau affiché vient du serveur.

## Bornes et contenu EE

`V723__tcf_irn_ee_bounds_and_contexts.sql` :

- normalise toutes les tâches EE à 30–60 / 60–90 / 60–90 ;
- ajoute un destinataire/contexte aux trois T2 historiques qui n'en avaient pas ;
- ajoute un contexte de forum aux T3 qui en étaient dépourvues ;
- pose des contraintes SQL sur les bornes et le contexte T2/T3.

`V762__tcf_irn_ee_examples_word_bounds.sql` réécrit les neuf exemples EE dans les bornes :

- T1 : 54, 56 et 59 mots ;
- T2 : 70, 83 et 83 mots ;
- T3 : 70, 82 et 88 mots.

Les migrations ne modifient aucune `production_submissions` ni le golden set. Les anciennes
productions hors nouvelles bornes restent lisibles et évaluables comme historique.

Web et mobile comptent les mots par séparation sur les espaces, comme le backend. Le bouton de
soumission et l'auto-soumission à expiration utilisent les bornes exactes ; un brouillon peut
continuer à dépasser, mais il n'est pas recevable tant qu'il n'est pas corrigé.

## Tables et stockage

- `production_tasks` : sujets, contexte et bornes ;
- `production_examples` : modèles pédagogiques ;
- `production_submissions` : rendus et statuts ;
- `transcriptions` : texte Whisper ou transcript temps réel ;
- `ai_evaluations` : résultat structuré, modèle, version, tokens et coût ;
- `human_calibration_notes` : annotations humaines.

Les audios utilisateur restent dans R2 privé avec URL signée. Les audios de compréhension
orale utilisent un stockage public distinct.

## Calibration opt-in

Le banc reste payant et n'est jamais lancé par `./mvnw verify` :

```bash
./mvnw -q test \
  -Dtest=CalibrationBenchTest \
  -DfailIfNoTests=false \
  -Dcalibration.enabled=true \
  -Dcalibration.rubrics=v7 \
  -Dcalibration.prompt=v4 \
  -Dcalibration.label=<nom>
```

Le provider et le modèle viennent de la même configuration que la production. Le corpus
`golden-set-v1.json` n'est pas modifié pour faire passer une version ; les cas désormais hors
bornes restent des références historiques explicites.

## Rollback

Une rubrique et son schéma forment une paire :

- actif : v7 / v4 ;
- rollback immédiat : v6 / v3 ;
- versions plus anciennes : utiliser la paire documentée dans l'historique du projet.

Exemple :

```bash
EVAL_RUBRICS_VERSION=v6 EVAL_PROMPT_VERSION=v3 ./mvnw spring-boot:run
```

Aucune migration de données n'est nécessaire pour changer de paire. Ne jamais modifier v6 ou
v3 pour corriger v7/v4.

## Vérifications automatiques

- `ProductionRubricsValidator` : couverture, poids, codes, bornes EE et contextes T2/T3 ;
- `ProductionEvaluationContractTest` : métadonnées v7, échelle, quatre critères, bornes et
  fermeture récursive du schéma v4 ;
- `EvaluationOutputValidatorTest` et `EvaluationProofMatcherTest` : sorties
  partielles/dupliquées/non finies/C1, feedback EO interdit, variantes typographiques,
  unicité, éditions de token et exclusion des tours examinateur ;
- `AiEvaluationServiceV6Test` : retry sémantique, absence de persistance partielle et agrégation
  tokens/coût ;
- `ProductionPipelineAsyncRunnerIT` : vrai proxy transactionnel et vrai PostgreSQL ; un échec
  d'évaluation persiste `FAILED` sans `UnexpectedRollbackException` asynchrone ;
- tests d’intégration : contraintes tâches, préservation des submissions historiques et neuf
  exemples dans les bornes.
