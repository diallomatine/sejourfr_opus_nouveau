# Pipeline d'évaluation des productions TCF IRN (EO + EE)

Ce document décrit le branchement technique actuel de la correction des productions. La
référence pédagogique exhaustive reste [`notation-ia-eo-ee.md`](notation-ia-eo-ee.md).

## Contrat actif

- Profil : **TCF IRN uniquement**.
- Niveau de sortie maximal : **B2** ; C1 et C2 ne font pas partie du contrat actif.
- Rubriques : `prompts/production-rubrics-v14.json`.
- Tool-schema : `prompts/production-evaluation-tool-schema-v8.json`.
- ⚠️ **`version_amelioree` n'est plus produite ni affichée.** Elle a quitté le tool-schema
  en **v8** ; le serveur la retire même si une sortie récalcitrante la renvoie
  (`AiEvaluationService.postProcess`). Le texte modèle rendu au candidat est
  `version_ciblee`, produit par un appel séparé. Les mentions de ce champ plus bas
  décrivent l'historique des versions v5→v7, pas le contrat actif.
- 🆕 **`v12` / `v6` = LA PREUVE SE DÉSIGNE PAR UN NUMÉRO DE SEGMENT.** `v12` est `v9` **au bit
  près** pour tout ce qui note (échelle, 4 critères, seuils, couplage, plafonds, bandes, tests
  décisifs A1/A2 et B1/B2, les 16 ancres few-shot, les 6 rubriques de tâche — verrouillé par
  `ProductionEvaluationContractTest`) ; seules 5 sections du bloc `commun` changent, et toutes
  décrivent la **mécanique** de la preuve. `v6` est `v5` avec `scores_criteres[].preuve`
  (string) remplacé par `preuve_segment` (**integer, minimum 1**).
  - **Motif** : une citation recopiée peut être juste et refusée quand même (le modèle
    dédouble un bégaiement, normalise une graphie). Cas réel `e6f28822` : deux appels refusés
    d'affilée, deux citations exactes, puis mode dégradé. Plus généralement, `flash` voyait
    **42,9 % de ses appels ORAUX** refusés par nos contrôles. Avec un entier borné, inventer
    une preuve devient impossible **par construction** ; la seule violation possible est un
    numéro hors bornes.
  - **Aucun impact sur les 3 fronts** : le serveur résout le numéro en texte AVANT
    persistance, donc `AiEvaluation.feedback_json.scores_criteres[].preuve` reste une chaîne.
    `preuve_segment` ne franchit jamais la frontière du service. Aucun miroir de DTO à
    propager (`web_sejoufr/lib/types.ts`, `mobile_sejourfr/lib/core/models/production_models.dart`,
    `admin_sejourfr/src/types/api.ts` : inchangés).
  - ⚠️ **NON MESURÉE AU BANC** : bascule livrée sans campagne (aucun appel LLM payant
    autorisé). Défendable parce qu'elle ne touche aucune règle de notation et que le peu
    qu'elle change au prompt **retire** une contrainte. Retour arrière sans migration :
    `EVAL_RUBRICS_VERSION=v9` + `EVAL_PROMPT_VERSION=v5` (les deux ensemble — la matrice
    refuse une paire incohérente au démarrage).
  - **v12 corrige aussi une consigne contradictoire** : les bornes de mots EE étaient
    recopiées en dur dans la grille (« tâches 2 et 3 : 60 à 90 mots ») et dans la
    description de `version_amelioree`, **à côté** des bornes réellement injectées depuis
    `production_tasks`. Depuis la migration **V724** (minimum T2/T3 60 → **40**), les deux
    se contredisaient dans le même prompt. v12 et le tool-schema v6 ne redéclarent plus
    rien : ils **renvoient** au bloc `LONGUEUR ATTENDUE`. Verrou : `EvaluationBornesMotsSourceUniqueTest`
    (aucune plage de mots en dur dans la grille ni le tool-schema **actifs**).
  - ⚠️ **Le retour arrière v9/v5 réintroduit cette contradiction.** v8, v9, v10, v11 et le
    tool-schema v5 sont des versions **livrées** : elles gardent leurs bornes historiques
    60-90, qui sont la trace exacte de ce avec quoi les copies déjà notées l'ont été. En
    v9, le correcteur recevra donc de nouveau « LONGUEUR ATTENDUE : 40 à 90 » **et**
    « 60 à 90 mots », et la version améliorée rendue au candidat visera 60-90 même sur une
    copie de 45 mots parfaitement valide. Basculer en connaissance de cause.
  - `EvaluationProofMatcher` **reste en place** et sert toujours les contrats ≤ v5.
- ⚠️ **`v10` et `v11` existent, sont chargeables, et sont ÉCARTÉES — ne pas réessayer cette
  voie sans le savoir.** Les deux ajoutaient une **consigne** demandant au correcteur de ne
  pas imputer au candidat un fragment en langue étrangère à l'oral. Mesurées le 2026-08-07
  contre un témoin v9 **du même jour**, même modèle, `calibration.retries=1` : niveaux exacts
  **81,8 % (v9)** contre 75,6 % (v10) et 76,7 % (v11) ; corrections perdues **8,33 % (v9)**
  contre 14,58 % et 10,42 % ; pièges 7/8 contre 4/8 et 5/8. v10 remontait en plus un
  hors-sujet de `A1_NON_ATTEINT` à `A1` et une transcription bruitée de A2 à B1 (le bloc
  ajouté, +4197 caractères, diluait la sévérité du reste). Rapports :
  `target/calibration/{v9-temoin,v10,v11}-20260807.json`. Le comportement visé est désormais
  tenu par un **contrôle serveur déterministe** (`EvaluationOralArtifactFilter`, volet LANGUE,
  §8 quater de `notation-ia-eo-ee.md`), qui ne touche ni à la note, ni à un seuil, ni au
  prompt. Les activer (`EVAL_RUBRICS_VERSION=v10|v11`) ferait revenir les chiffres ci-dessus.
- Correcteur par défaut : **DeepSeek `deepseek-v4-flash`**. ⚠️ **Choix en cours de
  réexamen** — cf. §12.6 de `notation-ia-eo-ee.md`.
- ⚠️ **La comparaison des 3 campagnes v9 est partiellement invalide.** Elles n'ont pas tourné
  avec le même nombre de tentatives (`calibration.retries` : 9 pour `flash`, 3 pour `pro`,
  1 pour `gpt-5.4`), alors que la production n'accorde **qu'un seul rejeu** avant `FAILED`.
  Toute métrique dépendant du nombre d'essais — au premier chef « corrections perdues » —
  est donc **non comparable entre campagnes** et ne doit pas être citée. Les métriques de
  justesse et de coût restent valides.
- Métrique honnête (`tentativesRatees / tentatives`, indépendante du nombre de vies) :
  **`flash` 27,3 %** de rejets serveur, dont **42,9 % sur l'EO seul** ; `pro` 17,9 % / 31,2 % ;
  `gpt-5.4` **0 % / 0 %**. En EE : **0 % partout**. Le rejet est donc un problème purement
  oral (preuve non rattachable dans un transcript, garde-fou oral). Chaque rejet est un appel
  facturé en double et, en production, un risque de correction non rendue.
- Reste établi et contre-intuitif : **`deepseek-v4-pro` coûte plus cher que `flash`** (1,12 $
  contre 0,91 $ la même campagne) sans mieux noter (pièges 4/8 contre 8/8, B2 3/7 contre 6/7).
  Le nom « pro » ne présume rien de l'aptitude à cette tâche ni du prix — ne pas y revenir
  sans remesurer, à nombre de rejeux égal. `gpt-5.4` fait jeu égal sur la justesse (81,3 %) et
  ne se fait jamais refuser, mais coûte 4,5× plus cher. OpenAI et Anthropic restent câblés et
  testés : **une bascule = un bloc de `.env`** (provider + modèle + ses deux tarifs), zéro
  ligne de code, zéro ligne de `.yaml`.
- **Première campagne à `retries=1` (comme la production), 2026-08-07** : `flash` sous v9
  rend **81,8 %** de niveaux exacts, **8,33 %** de corrections perdues et **22,8 %** de sorties
  refusées par nos validateurs, pour **51 centimes**. Les motifs de perte sont, dans l'ordre :
  JSON mal formé par le fournisseur, garde-fou oral, rejet de preuve. Ces chiffres-là **sont**
  comparables entre eux (mêmes réglages) — à l'inverse des trois campagnes v9 signalées
  ci-dessus.
- Le « pic à 5 min 44 s » du banc est un **cumul de 9 appels** sur un même cas, pas un appel
  lent : un appel isolé de `flash` tient en 16,3 s de médiane et 36,2 s au pire (mesuré sur
  les 41 cas réglés en un seul appel). C'est ce chiffre qui dimensionne `timeout-sec`.
- Examinateur vocal temps réel : **Gemini Live**. Il conduit/transcrit l'échange mais ne
  note jamais ; le transcript final revient dans le même pipeline correcteur.
- EE : T1 **30–60 mots**, T2/T3 **40–90 mots**, bornes strictes.

La grille active déclare `profile=TCF_IRN`, `niveau_max=B2` et `tool_schema_version=v8`.
`ProductionRubricsProvider` refuse au chargement une paire incompatible (par exemple v14/v6).
Les paires antérieures restent intactes pour rollback ; on versionne, on ne réécrit pas.

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

**Langue imposée.** `WhisperTranscriptionClient` envoie systématiquement
`language` (`sejourfr.openai.whisper.language: fr`) **et** `prompt`
(`literal-mode-prompt`, transcription verbatim). Whisper n'a donc rien à deviner.
C'est vérifié en base : **0 transcription sur 36** issue de cette voie porte une
écriture non latine, et `langue_detectee` vaut toujours `fr`/`french`. Le module
« Compétences » réutilise **le même client** (`SkillTranscriptionService`) et
hérite du réglage — aucune divergence possible entre les deux voies.

### Expression orale temps réel

1. Gemini Live joue l'examinateur et fournit le dialogue transcrit.
2. `ProductionEvaluationService.evaluateRealtimeTranscript` crée la submission et la
   transcription déjà finalisée ; Whisper est sauté.
3. Le même runner async et le même `EvaluationLlmClient` évaluent le transcript.

⚠️ **La langue de la transcription temps réel NE PEUT PAS être imposée.** Deux
limites de l'API Live, toutes les deux vérifiées :

- `inputAudioTranscription` prend un `AudioTranscriptionConfig`, et ce message
  **n'a aucun champ** — il n'existe pas de paramètre de langue pour l'entrée.
  `GeminiTokenBroker.buildRequestBody` l'envoie donc en objet vide, et c'est le
  seul envoi possible ;
- `speechConfig.languageCode` existe, mais les modèles **native-audio**
  (`gemini-live-2.5-flash-native-audio`, celui en service) le **refusent**
  (`Unsupported language code`). Le poser ferait échouer l'émission du token
  éphémère, et `RealtimeSessionService` basculerait silencieusement tout le temps
  réel en async. **Ne pas l'ajouter.**

Conséquence mesurée : **6 transcriptions temps réel sur 39** portent une écriture
non latine (arabe, cyrillique…), et le modèle produit aussi des passages en
langue étrangère en alphabet latin (anglais, néerlandais) que ce comptage ne voit
pas. Le modèle native-audio est documenté comme changeant « de langue
naturellement en cours de conversation » : c'est le mécanisme exact du défaut.

Deux réponses, aucune des deux n'étant un réglage d'API :

1. **`prompts/realtime-personas-v3.json`** (défaut `REALTIME_PERSONA_VERSION`) —
   verrou de langue dans la system instruction verrouillée dans le token : trois
   règles qui déclarent l'échange intégralement francophone et interdisent
   d'interpréter un passage mal capté comme une autre langue. v3 = v2 + ces trois
   règles, tout le reste au caractère près (`RealtimePersonaV3Test`). **Biais, pas
   garantie** : non mesurable au banc, qui n'appelle jamais Gemini Live.
2. **`EvaluationOralArtifactFilter`, volet LANGUE** (livré **ACTIF**) — contrôle
   serveur déterministe, appliqué **après** la correction, uniquement en EO. Il
   retire du rapport les phrases qui reprochent au candidat d'avoir employé une
   autre langue (`scores_criteres[].commentaire`, `points_a_ameliorer`,
   `suggestions`, `points_forts`, `accomplissement.objectif_resume`,
   `exemples_corriges`), pose un avertissement candidat dédié, et **ne touche ni à
   la note, ni au niveau, ni à un seuil**. Jamais `confiance_raisons` (c'est là
   que la langue étrangère doit vivre : limite d'observation, pas faute), jamais
   en EE. Garde-fou contre la neutralisation d'une **vraie** bascule de langue :
   deux mesures sur les seuls tours `Candidat :` — part de lettres non latines
   ≤ 15 % **et** part de mots-outils étrangers ≤ 6 %, avec un minimum de 40 mots
   exploitables ; au-dessus, on ne purge rien. Seuils calibrés sur les données
   réelles, cf. le javadoc de la classe.

   ⚠️ La voie « écrire une consigne de plus » (rubriques v10 puis v11) a été
   tentée **et mesurée moins bonne que v9** — cf. « Contrat actif » ci-dessus.

**Aucun filtrage a posteriori du transcript n'a été ajouté.** Le point de lecture
unique (`TranscriptionManager.findLatestTexteBySubmissionId` +
`TranscriptTurnStitcher`) ne retire que des **frontières** de tours, jamais du
contenu. Y supprimer un tour halluciné violerait cette philosophie, détruirait de
la parole réelle en cas de faux positif, et resterait de toute façon aveugle aux
passages étrangers en alphabet latin — qui sont la majorité des cas observés.

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
    rubrics-version: ${EVAL_RUBRICS_VERSION:v12}
    deepseek:
      model: ${EVAL_DEEPSEEK_MODEL:deepseek-v4-flash}
      prompt-version: ${EVAL_PROMPT_VERSION:v6}
      # Forme de requête négociée avec le fournisseur ; `auto` = négociation.
      max-tokens-param: ${EVAL_DEEPSEEK_MAX_TOKENS_PARAM:auto}
      send-temperature: ${EVAL_DEEPSEEK_SEND_TEMPERATURE:auto}
      # Budget d'UN appel HTTP (read timeout), pas d'une correction : 2,5× le
      # pire appel `flash` mesuré (36,2 s), et déjà au-dessus du pire appel
      # `pro` (66,7 s) — un retour arrière reste 3 lignes de `.env`.
      timeout-sec: ${EVAL_DEEPSEEK_TIMEOUT_SEC:90}
      # Vont AVEC `model`, dans la même source que lui (cf. EvaluationPricingTest).
      cost-per-million-input-tokens: ${EVAL_DEEPSEEK_COST_INPUT:0.14}
      cost-per-million-output-tokens: ${EVAL_DEEPSEEK_COST_OUTPUT:0.28}
    openai:
      model: ${EVAL_OPENAI_MODEL:gpt-5.4}
      prompt-version: ${EVAL_PROMPT_VERSION:v5}
      max-tokens-param: ${EVAL_OPENAI_MAX_TOKENS_PARAM:auto}
      send-temperature: ${EVAL_OPENAI_SEND_TEMPERATURE:auto}
      cost-per-million-input-tokens: ${EVAL_OPENAI_COST_INPUT:2.50}
      cost-per-million-output-tokens: ${EVAL_OPENAI_COST_OUTPUT:15.00}
```

### Changer de LLM ou de modèle : configuration seule, jamais de code

Exigence explicite du propriétaire, formulée deux fois : **une ligne de `.env`, un
redémarrage, ça marche**. Trois mécanismes la tiennent, aucun ne doit être défait.

1. **La forme de la requête est négociée** avec le fournisseur (section suivante), jamais
   codée en dur.
2. **Le modèle de chaque bloc est un `${EVAL_*_MODEL:…}`** ; aucun défaut métier n'existe
   dans les POJO (`ProductionEvaluationProperties` livre `model = null`), donc `application.yaml`
   reste la seule source des défauts.
3. **Le tarif voyage avec le modèle.** Le coût estimé est **persisté** dans
   `ai_evaluations.cout_centimes` et n'est pas recalculable a posteriori : les deux tarifs sont
   donc eux aussi des `${EVAL_*_COST_INPUT/OUTPUT:…}`, et `EvaluationPricingTest` **fait échouer
   le build** si un modèle est choisi hors du `.yaml` sans ses deux tarifs dans la même source.

Ce que ces tests **ne font plus** : nommer le provider ou le modèle attendu. `CalibrationEnvTest`
vérifiait `provider == "openai"` et une table fermée de tarifs listait les modèles connus —
revenir à DeepSeek passait le build au rouge alors que rien n'était cassé. Ils vérifient
désormais une **cohérence** (provider connu, modèle nommé, clé présente, paire rubriques ⇄
tool-schema valide, tarif présent/positif/plausible), et `EvaluationProviderSwapTest` prouve
qu'un modèle *inédit* se branche sur les trois providers par quatre variables, sans toucher
un `.java` ni un `.yaml`.

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

### Négociation de la forme de requête (aucun code à toucher pour changer de modèle)

`OpenAiCompatibleEvalClient` sert **deux** providers dont les corps de requête diffèrent, et
les modèles évoluent : `max_tokens` (gpt-4.x, DeepSeek) contre `max_completion_tokens`
(gpt-5.x, o-series), et des modèles qui refusent toute `temperature` explicite. Ces
différences ne sont **pas** décidées par une liste de modèles dans le code — cette approche
rouvre le code à chaque nouveau modèle.

`ChatCompletionDialectNegotiator` (`util/`) tient la **forme courante** et la corrige à partir
du 400 renvoyé par le fournisseur :

- sur `Unsupported parameter: 'max_tokens' … Use 'max_completion_tokens' instead`, le nom de
  remplacement est **lu dans le message** (`Use 'X' instead`) — un futur renommage est donc
  absorbé sans commit ; à défaut de suggestion, bascule sur l'autre nom connu ;
- sur `Unsupported value: 'temperature' does not support 0 …`, le champ est **omis** (jamais
  envoyé à 1 : ce serait accepter en douce une notation non déterministe), avec un `WARN` ;
- l'appel est rejoué **une fois** par correction de forme (3 renégociations au maximum) et la
  forme retenue est **mémorisée pour le processus** — un client = un couple provider+modèle,
  donc le surcoût est payé une fois par démarrage, jamais par correction. Rien n'est persisté.

Un **400 métier** (tool-schema refusé, contenu invalide, modèle inexistant) ne déclenche
**jamais** de renégociation : il faut à la fois un marqueur « paramètre/valeur non supporté »
et l'un de nos champs, et un `error.param` désignant autre chose suffit à refuser. Sinon on
masquerait une vraie erreur derrière une boucle de réessais.

Les heuristiques par famille de modèle (`ChatCompletionDialect.premiereForme`) ne sont qu'un
**raccourci** évitant un aller-retour raté sur les familles déjà connues ; leur absence de
correspondance ne casse rien. `EVAL_OPENAI_MAX_TOKENS_PARAM` et `EVAL_OPENAI_SEND_TEMPERATURE`
permettent de reprendre la main sans code (et **désactivent** la négociation du champ imposé).

Tests : `ChatCompletionDialectNegotiatorTest` (unitaire) et
`OpenAiCompatibleEvalClientNegotiationTest` (serveur HTTP local, corps 400 réels d'OpenAI,
modèles volontairement inconnus du code).

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

Les quatre critères, équipondérés depuis v5, sont toujours :

1. `communiquer` ;
2. `interagir` ;
3. `lexique` ;
4. `morphosyntaxe`.

## Validation brute et retry sémantique

Le function calling ne suffit pas à garantir qu'un fournisseur respecte le contrat.
`EvaluationOutputValidator` intervient donc **avant toute normalisation** et avant tout calcul.

Sous le contrat **v6**, la preuve n'est plus une chaîne mais un **numéro de segment**. Le
matériau part découpé par `EvaluationProductionSegments` (EO dialogué : un segment par tour
`Candidat :`, les tours `Examinateur :` sont rendus SANS numéro donc non désignables ; EE et
EO monologue : une phrase par segment), et `EvaluationOutputValidator` recalcule le même
découpage — il est déterministe — pour vérifier que `preuve_segment` est un entier de
`1..n`. Deux violations possibles, et deux seulement :

| Violation | Sens | Après le réessai |
|---|---|---|
| `preuve_segment[<code>] doit etre un numero de segment entier` | champ absent ou non entier | **bloquant** (miroir de « preuve vide ») |
| `preuve_segment[<code>] doit designer un segment numerote de la production` | entier hors bornes | **dégradable** (miroir de « citation non rattachable ») |

`AiEvaluationService.resolvePreuveSegments` remplace ensuite le numéro par le texte exact du
segment sous la clé `preuve`, et `EvaluationProofMatcher` n'est **pas** appelé : réappliquer un
rapprochement littéral sur un texte que le serveur a lui-même extrait rendrait ambiguë toute
production contenant deux tours identiques. `EvaluationRepairPrompt` bascule sur un rappel
« numéro », la règle de recopie n'ayant plus d'objet. `EvaluationRefusalMetrics` classe ces
violations dans les **mêmes familles** (`PREUVE_NON_RATTACHEE` / `PREUVE_ABSENTE`) pour rester
comparable d'une version de contrat à l'autre. Le garde-fou oral, le filet d'artefacts et le
filet de langue portent sur d'autres champs : **inchangés**.

Pour v4 et v5, il exige notamment :

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

## Filet oral, volet FORME (2026-08-09)

`EvaluationOralArtifactFilter` gagne un troisième volet, à côté de MOT et LANGUE. **Il ne
s'applique qu'à l'oral, qu'au critère `morphosyntaxe` et aux priorités qui le relisent** —
jamais au lexique, jamais aux points forts, jamais à `confiance_raisons`, jamais à l'écrit.

Règle : à l'oral, une faute de grammaire est une **structure**. Elle se cite soit sur au
moins **3 mots porteurs de sens**, soit sur des **mots-outils seuls** (`« pour ne pas que »`,
0 mot porteur — conservé, c'est une structure pure). Un reproche ancré qui ne nomme qu'**un
ou deux** mots pleins nomme une *forme*, pas une structure : la phrase est purgée.

- Motif mesuré sur les 142 évaluations en base : passages cités, présents verbatim dans la
  production et absents d'un dictionnaire français de 475 000 formes → **9 évaluations EO
  sur 75, 0 EE sur 67**. Zéro à l'écrit : la cause est la machine, pas le niveau.
- Sur une transcription mesurée **dégradée** (voir ci-dessous), la condition de longueur
  tombe : aucun reproche de grammaire ancré n'est opposable si le texte lu n'est pas celui
  qui a été dit.
- **Ni la note, ni le niveau, ni un seuil ne bougent** — comme les deux autres volets. Le
  candidat reçoit un avertissement dédié, et le compteur `ARTEFACT_ORAL_FORME`
  (`EvaluationPurgeMetrics`) dit combien de remarques ce volet retire.
- **Coût assumé, mesuré** : sur les 75 commentaires de morphosyntaxe EO en base, **11
  phrases** tomberaient, dont environ sept portaient *aussi* une vraie faute — la phrase
  entière part, parce qu'ôter une citation au milieu d'une énumération rendrait un texte
  mutilé. On perd du conseil, jamais un point.

## Indicateur de qualité de transcription (2026-08-09)

`TranscriptionQualityAudit` mesure, sur les seuls tours `Candidat :`, deux taux
déterministes et gratuits :

1. **formes suspectes** — part des mots de 1 à 3 lettres absents d'un inventaire fermé
   (~290 entrées, dont `ProductionValidityService.MOTS_OUTILS_FR`). Seuil **10 %** ;
2. **collages** — part des positions où deux formes suspectes se suivent (`ves te`,
   `com me commer cial`), signature du mot coupé. Seuil **2 %**.

Plancher de 40 mots exploitables, sinon « non mesurable » et aucune conséquence.

**Pas de dictionnaire français embarqué** : il aurait pesé 2 à 4 Mo dans le jar, des dizaines
de Mo en mémoire et une licence tierce. Mesure sur les 123 productions mesurables de la base
(63 EE, 28 EO Whisper, 32 EO temps réel) : l'inventaire fermé sépare mieux qu'un taux de mots
hors-vocabulaire brut, parce que les mots *longs* hors-vocabulaire sont surtout des noms
propres, des sigles et des néologismes d'apprenant. La séparation colle exactement à la
fenêtre du bug « mot coupé » : les 8 sessions mesurables du 28 juin au 4 juillet 2026 sont
entre **18,29 % et 26,94 %**, les 24 suivantes toutes **sous 4,84 %**, et il n'existe aucune
observation entre les deux.

Ce que l'indicateur déclenche, et rien de plus :

- le volet FORME passe en mode large ;
- la **confiance** est plafonnée à `FAIBLE`, avec sa raison — une transcription abîmée est un
  obstacle à l'**observation**, pas un défaut du candidat.

**La note, le niveau et les seuils ne bougent jamais.** Verrouillé par
`AiEvaluationServiceTranscriptionQualiteTest`.

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

`V724__tcf_irn_ee_t2_t3_mots_min_40.sql` corrige le **minimum** des tâches 2 et 3 :
le volume officiel du TCF IRN est **40–90**, pas 60–90. Comme les bornes sont
strictes, une copie de 40 à 59 mots — recevable à l'examen — était refusée à la
soumission. La migration retire la contrainte de V723, passe `mots_min` à 40 sur
T2/T3, puis repose la contrainte sur `30–60 / 40–90 / 40–90`. Ni la tâche 1 ni
aucun maximum ne bougent, aucun sujet n'est réécrit.

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
- `transcriptions` : texte Whisper ou transcript temps réel, **plus les indicateurs de
  qualité** (migration `V027`) :
  - `avg_logprob`, `no_speech_prob`, `compression_ratio`, `segments_count` — renvoyés par
    Whisper dans `verbose_json`, donc **payés depuis toujours et jetés jusqu'ici** ;
    `NULL` en temps réel, qui n'expose rien ;
  - `taux_formes_suspectes`, `taux_collages`, `qualite_degradee` — indicateur maison,
    calculé sur le texte final, donc renseigné pour **les deux** sources. C'est ce qui rend
    la question « nos transcriptions se dégradent-elles ? » répondable en une requête SQL
    (index partiel `idx_transcription_degradee`) ;
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
  -Dcalibration.rubrics=v14 \
  -Dcalibration.prompt=v8 \
  -Dcalibration.label=<nom>
```

Le provider et le modèle viennent de la même configuration que la production. Le corpus
`golden-set-v1.json` n'est pas modifié pour faire passer une version ; les cas désormais hors
bornes restent des références historiques explicites.

## Rollback

Une rubrique et son schéma forment une paire :

- actif : **v14 / v8** ;
- rollback immédiat : v13 / v7 ;
- versions plus anciennes : utiliser la paire documentée dans l'historique du projet.
  ⚠️ v10 et v11 sont chargeables mais **mesurées moins bonnes que v9** — ne pas les
  réactiver.

Exemple :

```bash
EVAL_RUBRICS_VERSION=v13 EVAL_PROMPT_VERSION=v7 ./mvnw spring-boot:run
```

Aucune migration de données n'est nécessaire pour changer de paire. Ne jamais modifier une
grille livrée pour corriger la grille active.

## Vérifications automatiques

- `ProductionRubricsValidator` : couverture, poids, codes, bornes EE et contextes T2/T3 ;
- `ProductionEvaluationContractTest` : métadonnées de la grille active, échelle, quatre
  critères, bornes et fermeture récursive du tool-schema ;
- `EvaluationOutputValidatorTest` et `EvaluationProofMatcherTest` : sorties
  partielles/dupliquées/non finies/C1, feedback EO interdit, variantes typographiques,
  unicité, éditions de token et exclusion des tours examinateur ;
- `AiEvaluationServiceV6Test` : retry sémantique, absence de persistance partielle et agrégation
  tokens/coût ;
- `ProductionPipelineAsyncRunnerIT` : vrai proxy transactionnel et vrai PostgreSQL ; un échec
  d'évaluation persiste `FAILED` sans `UnexpectedRollbackException` asynchrone ;
- tests d’intégration : contraintes tâches, préservation des submissions historiques et neuf
  exemples dans les bornes.
