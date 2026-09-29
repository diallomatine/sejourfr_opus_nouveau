# Notation IA des productions EE/EO — règles serveur

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Contenu verbatim, aucune réécriture.**
> Origine : lignes 1902-1915, 2034-2163, 2322-3038 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier porte la loi de ce sous-système : on l'ouvre **quand on travaille dedans**.
> Fichier jumeau : `docs/decisions/notation-ia.md`
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

## Notation IA des productions EE/EO — repères

Le « quoi » et le « pourquoi » vivent dans `docs/notation-ia-eo-ee.md` (référence
grand public, **à tenir exhaustive et à jour dans la même passe** — cf. la règle
dédiée plus bas). Ici, uniquement de quoi se repérer.

- **Versions actives** : rubriques `production-rubrics-v15.json`, tool-schema de
  sortie `production-evaluation-tool-schema-v9.json`, persona vocale
  `realtime-personas-v3.json`. **v14/v8, v13/v7, v12/v6, v9/v5, v8/v5, v7/v4, v6/v3, v5/v3,
  v4.2/v2, v4.1/v2, v4/v2 et v3/v2 restent chargeables et validées** : un retour arrière
  change la paire `EVAL_RUBRICS_VERSION` + `EVAL_PROMPT_VERSION`, aucune migration.
  **On versionne, on ne réécrit jamais** une rubrique livrée. **v10 et v11 sont
  chargeables mais MESURÉES MOINS BONNES que v9 — ne pas les réactiver** (détail
  dans le filet de langue étrangère, plus bas).
- **NOTE /20 MASQUÉE SUR UNE TÂCHE ISOLÉE** (décision produit, 2026-08-08) : le résultat d'une
  tâche n'affiche plus que le **niveau** + sa position dans le palier. Au TCF le correcteur
  attribue un niveau **par tâche**, la note /20 ne porte que sur l'**épreuve entière** ; et sur
  l'échelle officielle (10 = B2), « 3,5/20 » se lit comme un naufrage alors que c'est un A2
  normal. **Aucune règle de calcul ne bouge** : la note reste calculée, persistée et exposée
  (`EvaluationResultDto.noteSurVingt`, bilan d'épreuve, admin, banc). Changement d'**affichage**.
  Remplacement du signal de progression : **`SituationDansNiveau`** (`ENTREE_DE_PALIER` /
  `PALIER_CONFIRME` / `PALIER_SOLIDE`, libellés *Palier atteint / confirmé / solide*, composés
  en « **A2 solide** »). Dérivé **serveur** (`SituationDansNiveau.of`, appelé par
  `ProductionSubmissionMapper`), jamais recalculé par un front — même philosophie que
  `SkillStatusResolver`. Bornes de bande lues dans `commun.niveau` de la **grille active**, pas
  en dur. ⚠️ **Règle de formulation gelée** : le haut de A2 se dit « A2 solide », **jamais
  « presque B1 »** — on vient de retirer le vocabulaire de déficit, on ne le réintroduit pas.
  `null` si pas de note, `A1_NON_ATTEINT` (bande d'un seul point) ou C1/C2. Note hors bande
  (niveau **plafonné**) → ramenée dans la bande affichée. Libellés figés par
  `SituationDansNiveauTest` ; **à mirrorer sur les 3 fronts**.
- **VERSION AU NIVEAU VISÉ — SECOND APPEL LLM SÉPARÉ, EE *et* EO** (`service/versionciblee/`,
  livré **ACTIF**). Rend au candidat un **plan d'action** vers le palier qu'il VISE
  (`User.targetLevel` avec plancher `TargetProcedure.niveauVise`, repli
  `production_tasks.niveau_cible`). Distinct de `version_amelioree`, qui visait le palier
  **juste au-dessus**.
  **Contrat v2 (`VersionCibleeContrat`, registre par rang comme `EvaluationToolSchema` —
  une version inconnue échoue au BOOT, jamais de repli muet)** :
  - **commun** : `leviers[2..3]` = objets `{action ≤ 6 mots impératif, exemple ≤ 5 mots}`
    (fini la chaîne libre de 25 mots) + `a_retenir {formule ≤ 8 mots, explication ≤ 14 mots}` ;
  - **EE** : `exemple_cible {texte, segments[0..3] {extrait, apport ≤ 3 mots}}` — `texte` garde
    les bornes `production_tasks.mots_min/max` (recomptées serveur). ⚠️ **Les segments sont
    FACULTATIFS** (règle du 2026-08-11, elle **révoque** « 2 segments minimum, sinon ce n'est
    pas un chemin », qui ne vaut que pour les `reformulations` orales) : un extrait
    introuvable, un apport trop long ou un objet mal formé fait retirer **ce segment**
    (`VersionCibleeSegmentFilter`), l'`exemple_cible` survit dès que son `texte` est valide, et
    la section ne tombe que si le **texte** est fautif. Motif : le texte réécrit est ce que le
    candidat vient chercher — **afficher le texte sans surlignage vaut mieux que ne rien
    afficher**. Un extrait introuvable ne vaut **plus de réparation payée** (il ne coûte qu'un
    surlignage). Les 3 fronts étaient **déjà** prêts (web `asActionExempleCible` n'exige que
    `texte`, mobile idem) ;
  - **la comparaison extrait ⇄ texte neutralise la TYPOGRAPHIE** (`util/TexteNormalise`, NFKC,
    apostrophes courbes/droites, espaces insécables, tirets longs, ligatures, suites de blancs)
    **et rien d'autre** — ni casse, ni accents, ni appariement flou ; puis l'extrait servi est
    **remplacé par la sous-chaîne ORIGINALE exacte**, comme `resolvePreuveSegments`, pour que le
    front surligne par simple recherche de chaîne. Motif : nos textes portent des apostrophes
    courbes, le modèle rend des droites (ou l'inverse), et un extrait **juste** était déclaré
    introuvable. `EvaluationProofMatcher.normalizeToken` a été **déplacé** dans ce même fichier
    (`TexteNormalise.mot`, au bit près) : une seule normalisation, deux couches ;
  - **EO** : ⚠️ **la production orale n'est JAMAIS réécrite** (rendre un beau texte à la place
    d'une transcription est trompeur). `exemple_cible` est remplacé par
    `reformulations[2..3] {segment_numero, reformule, apport}` — **désignation par NUMÉRO**
    (technique v12 qui a fait tomber `PREUVE_NON_RATTACHEE`, 42,9 % des appels oraux), via
    `EvaluationProductionSegments` (**appelée, jamais recopiée**) ; tours `Examinateur :`
    montrés **sans numéro** ⇒ non désignables par construction. Le serveur **résout le numéro
    en texte** (`original`) avant persistance, comme `resolvePreuveSegments` : **aucun miroir
    DTO ne transporte d'entier** ;
  - **deux tool-schemas** (`…-tool-schema-v2.json` / `…-tool-schema-oral-v2.json`), chargés au
    boot par variante (`VersionCibleeTools`) ; les fondre en un seul aurait supposé des champs
    facultatifs, c'est-à-dire plus de contrat.
  **Trois garde-fous oraux, exigence du propriétaire** (« c'est la formulation des phrases
  qu'on reformule, pas les erreurs de transcription ») : (1) `TranscriptionQualityAudit
  .degradee` ⇒ **aucun appel émis**, gratuit et honnête ; (2) `VersionCibleeReformulationFilter`
  retire toute reformulation dont l'apport tient à **1 ou 2 mots pleins REMPLACÉS SUR PLACE** —
  règle du volet FORME extraite dans **`EvaluationOralForme`** (2ᵉ occurrence ⇒ extraction,
  partagée avec `EvaluationOralArtifactFilter`) ; l'alignement **positionnel** est le cœur :
  subordonner/réordonner déplace les mots, donc n'est jamais purgé ; (3) durée **jamais
  envoyée**, ni prononciation/accent/débit/fluidité/hésitations/orthographe. Moins de 2
  reformulations restantes ⇒ **1** réparation nommée puis abandon de la **section
  `reformulations` seule**. Purges comptées
  `EvaluationPurgeMetrics.REFORMULATION_ORALE_FORME` (à part de `ARTEFACT_ORAL_FORME`).
  ⚠️ **UNE SECTION QUI TOMBE N'EMPORTE PAS LE BLOC** (règle posée le 2026-08-11, elle
  **révoque** l'ancienne « moins de 2 ⇒ le bloc entier est abandonné »). `exemple_cible` /
  `reformulations` et `a_retenir` sont **facultatives** : inexploitables après l'unique
  réparation, elles tombent **seules** et le reste est servi. Seuls les **leviers** portent le
  bloc — purgés sous leur minimum et non réparés, tout est abandonné (comportement conservé).
  Motif, mesuré sur une tâche 1 d'EO en temps réel : sur une transcription hachée les
  reformulations sont **légitimement** purgées (elles ne corrigeraient qu'un artefact de notre
  machine) et le candidat perdait **aussi** ses leviers et son « à retenir », qui ne dépendent
  d'aucune citation — la fragilité des citations à l'oral ne doit pas emporter des contenus qui
  n'en dépendent pas. Le validateur range donc ses violations **par section**
  (`VersionCibleeValidator.Section`), et les trois fronts conditionnent déjà chaque section
  indépendamment.
  ⚠️ **C'est LE seul texte modèle d'un résultat EE** : les fronts ont retiré
  `version_amelioree` de l'écran, puis **v14/v8 l'a retirée du contrat de sortie** —
  elle n'est plus ni demandée ni produite (legacy persisté intact). Motif mesuré en base : elle était **au même niveau que la copie**,
  sans étiquette de palier — recopiée telle quelle et resoumise, elle rendait la
  **même note au dixième près**. `version_ciblee`, elle, **nomme son niveau**.
  ⚠️ **L'appel est séparé de la correction, c'est la raison même du montage** : le prompt de
  notation ne change pas d'un octet et le correcteur n'apprend **jamais** le niveau visé, sinon
  il aligne sa note dessus (v10/v11 ont mesuré qu'un simple bloc ajouté à la grille fait tomber
  l'accord exact de 81,8 % à 75,6 %). **Ne pas fusionner les deux appels.** Verrou :
  `VersionCibleeContractTest`.
  Prompts versionnés `production-version-ciblee-{rubrics,tool-schema[-oral]}-v2.json`, paire
  validée au boot ; **aucune consigne en dur dans le Java** ; français **accentué** (leçon
  v13/v7). `additionalProperties:false`, chaque plafond **déclaré en mots par la grille** ET
  doublé d'un `maxLength` + plafond serveur (tolérance ×1,2 sur les plafonds pédagogiques, **pas**
  sur les bornes du texte modèle) — **aucun champ où loger une note ou un niveau**. Le serveur
  ajoute `niveau_vise` / `niveau_constate` (⚠️ données de logique : ne pas en faire une étiquette
  de palier sur l'exemple, autre chantier).
  **UNE seule réparation par bloc, tous motifs confondus** (`VersionCibleeRepairPrompt`) — pas
  une par section — et seulement sur du **mécanique nommable** : longueur du texte, numéro hors
  bornes, leviers purgés, reformulations purgées. Sortie structurellement fausse ⇒ **zéro**
  second appel payé, et **leviers** structurellement faux ⇒ aucune réparation non plus (le bloc
  est condamné, payer ne rachèterait rien).
  **Tolérance des plafonds pédagogiques : `PlafondMots.tolere` = `max(plafond+1,
  floor(plafond×1,2))`** (2026-08-11). L'ancienne formule seule était **fictive sur les petits
  plafonds** : sur `apport` (3 mots) elle tolérait 3, soit **zéro marge**, exactement là où la
  tolérance avait été écrite pour servir. Effet mesuré, plafond par plafond : `apport` 3→**4**
  (avant : 3) ; `exemple` 6, `action` 7, `formule` 9, `explication` 16, `reformule` 72,
  `ce_qui_manque` 30 — **inchangés**. Même correction, même passe, sur le module Compétences
  (`CompetenceAnalysisValidator` : `strength_tag`/`focus_tag` 3→**4** ;
  `CompetenceNiveauViseValidator` : `apport` 3→**4**). Ne s'applique **pas** aux bornes du
  texte modèle (`ProductionTextBounds`), qui restent au mot près.
  **Compteurs `VersionCibleeMetrics`** (troisième famille, à ne pas mélanger avec
  `EvaluationRefusalMetrics` « un refus coûte la tâche » ni `EvaluationPurgeMetrics` « une purge
  retire une phrase ») : **section abandonnée** par section × motif, **réparation payée** par
  motif, **segment retiré** par motif. Sans eux, la disparition intermittente de la section
  n'avait que deux `log.info` pour l'expliquer et aucune de ces décisions n'était jugeable sur
  des chiffres.
  **Best-effort, jamais bloquant** : lancé par `ProductionPipelineAsyncRunner` **après** que
  l'éval est persistée et `EVALUATED`, **hors transaction** (invariant du runner), le service
  avale toute exception, **aucun rejeu** (c'est un confort, pas une correction). Rien n'est
  produit si le niveau visé est **≤** au niveau constaté (bloc `niveau_vise_atteint` à la place)
  ou si le drapeau est éteint.
  Persistance dans `feedback_json.version_ciblee` — **aucune migration**. Un front distingue
  l'écrit de l'oral à la présence de `exemple_cible` ou de `reformulations`. Tokens/coût du 2ᵉ
  appel **additionnés** à ceux de l'éval. Provider = `production-evaluation.provider` (règle
  « un seul correcteur configurable »), réglages propres sous
  `production-evaluation.version-ciblee` (`enabled`, `max-tokens: 1600`, `max-leviers: 3`).
  Retour arrière : `EVAL_VERSION_CIBLEE_ENABLED=false`, ou **v1** par
  `EVAL_VERSION_CIBLEE_RUBRICS_VERSION=v1` + `EVAL_VERSION_CIBLEE_TOOL_SCHEMA_VERSION=v1`
  (sortie `texte` + `ce_qui_manque[string]`, oral muet) — **aucune migration**, on versionne, on
  ne réécrit jamais. **Aucune campagne requise** : rien de ce qui note ne bouge, par
  construction. Le banc (`CalibrationRunner`) n'emprunte pas ce chemin.
- **Changer de LLM ou de modèle ne touche AUCUN `.java` ni `.yaml`** — exigence du
  propriétaire, verrouillée par les tests. Trois mécanismes : la **forme de requête**
  (`max_tokens` vs `max_completion_tokens`, `temperature` envoyée ou omise) est
  **négociée** (`ChatCompletionDialectNegotiator` : déduit le remplacement du 400 du
  fournisseur, rejoue **une fois**, mémorise par processus ; un **400 métier** ne
  renégocie **jamais** ; les heuristiques par famille ne sont qu'un point de départ) ;
  le **modèle et ses tarifs** sont des `${EVAL_*_MODEL/COST_INPUT/COST_OUTPUT/COST_CACHED_INPUT}` ;
  le même dialecte sert `CompetenceOpenAiCompatibleClient` — sinon une bascule casse
  le module Compétences en silence. `EvaluationPricingTest` ne fige plus une table
  « tel modèle = tel prix » (elle rendait rouge tout changement de modèle) mais une
  **cohérence** : tarif présent, positif, plausible, **posé dans la même source que le
  modèle**. `CalibrationEnvTest` vérifie un environnement **cohérent**, plus quel
  provider est choisi. `EvaluationProviderSwapTest` prouve qu'un modèle inédit se
  branche sur les 3 providers par 4 variables.
- **Correcteur actif : DeepSeek `deepseek-v4-flash`** (`.env`, défaut YAML aligné) —
  **choix mesuré, pas par défaut**. Trois campagnes v9 sur les 48 cas ont départagé
  `flash`, `deepseek-v4-pro` et `gpt-5.4` :

  | | `flash` | `pro` | `gpt-5.4` |
  |---|---|---|---|
  | **appels refusés — tous cas** | 27,3 % | 17,9 % | **0 %** |
  | **appels refusés — ORAL** | **42,9 %** | 31,2 % | **0 %** |
  | appels refusés — écrit | **0 %** | **0 %** | **0 %** |
  | accord exact | **81,3 %** | 77,1 % | **81,3 %** |
  | pièges | **8/8** | 4/8 | 5/8 |
  | B2 · A1 · A2 | 6/7 · 3/8 · 10/13 | 3/7 · **4/8** · **12/13** | 6/7 · 2/8 · 11/13 |
  | latence médiane / max **par appel** | 16,3 s / 36 s | 28,8 s / 67 s | **12,9 s / 32 s** |
  | coût 48 corrections | **0,91 $** | 1,12 $ | 4,14 $ |

  ⚠️ **La ligne « corrections perdues » de ces campagnes est NON COMPARABLE et a été
  retirée** : `calibration.retries` valait **9 / 3 / 1**. `flash` n'a pas moins perdu,
  il a eu neuf vies. En production il n'y a qu'**un** réessai — figer `retims` entre
  témoin et candidat, et le reporter dans le rapport. Ne jamais rechoisir un modèle
  sur cette colonne.
  ⚠️ **`pro` est plus cher que `flash`** — le nom ne dit rien de l'aptitude à cette
  tâche. `gpt-5.4` est le seul sans aucun appel refusé, mais 4,5× le prix (écarté sur
  le coût, 2026-08-08).
  ✅ **CHOIX CLOS le 2026-08-16 : `flash` est retenu, motif LATENCE.** 16,3 s de
  médiane et 36 s au pire appel contre 28,8 s / 66,7 s pour `pro` — c'est le seul
  écart que le candidat ressent, il attend sa correction devant l'écran. Renforcé
  par un fait mesuré le même jour : **la justesse se gagne dans les contrats et les
  contrôles serveur, pas dans le moteur** (+14,5 points d'accord exact sans changer
  de modèle). Payer 4,5× pour `gpt-5.4`, qui note **aussi juste** (81,3 % des deux
  côtés), n'achèterait pas de la précision ; et les 42,9 % d'appels refusés à l'oral
  se traitent chez **nos validateurs**, pas chez le fournisseur. Ne pas rouvrir ce
  dossier sans une mesure neuve, à réessais égaux.
  **Le rejet est un problème purement ORAL** : 0 % d'appels refusés en EE chez les
  trois moteurs. Et ce ne sont pas des JSON cassés — ce sont **nos validateurs** qui
  refusent des sorties bien formées.
  ⚠️ **Les tarifs du tableau ci-dessus datent de l'ANCIENNE grille** (relevés le
  2026-08-07 : flash 0,14 / 0,28 ; pro 0,435 / 0,87) — conservés parce que les
  campagnes ont été payées à ce prix-là. La grille **en vigueur** est celle du
  2026-08-16 16:00 UTC, à trois tarifs et deux plages horaires (cf. § *Ce que coûte
  un appel LLM* ci-dessous).
  `timeout-sec` deepseek 60 → **90** (read timeout **par appel** : pire appel `flash`
  36 s, `pro` 67 s ; les « 5 min » d'un rapport sont un **cas entier**, pas un appel).
  Bascule = un bloc de `.env`. Détail : `docs/notation-ia-eo-ee.md` §12.6.
- **Ce que coûte un appel LLM — TROIS tarifs, deux plages horaires, et un cout au
  MICRO-DOLLAR** (2026-08-16). Autorité unique : **`util/CoutAppelLlm`**, extraite à
  la **11ᵉ** occurrence — chacun des 11 clients portait sa propre copie de
  `estimateCostCents`, et passer de 2 tarifs à 3 les aurait fait diverger. Contrat
  partagé : **`config/TarifsLlm`** (implémenté par `BlocTarifs`, dont héritent les 3
  blocs provider).
  - **Grille DeepSeek en vigueur depuis le 2026-08-16 16:00 UTC** (USD / 1M tokens),
    en heures creuses : `flash` **0,007 / 0,22 / 0,66** (entrée cache hit / cache
    miss / sortie), `pro` **0,022 / 0,66 / 1,98**. **Heures pleines = ×2 sur les
    trois**, sur **01:00-04:00 et 06:00-10:00 UTC**. L'ancienne paire `0,14 / 0,28`
    était fausse **dans les deux sens** : sortie sous-estimée ×2,4 à ×4,7, entrée
    cache miss ×1,6 à ×3,1, et entrée cache **hit SUR**estimée ×20.
  - **Un multiplicateur, pas six chiffres** : la grille est exactement
    proportionnelle (×2 sur les 3 tarifs et les 2 gammes), donc
    `peak-multiplier` + `peak-utc-ranges` disent la même chose sans tripler la
    surface d'env. Si un fournisseur cessait d'être proportionnel, **alors** on
    scinde. Les bornes horaires vivent **en configuration**, jamais en dur.
    L'heure est résolue **à l'instant de l'appel**, en UTC, depuis un `Clock`
    paramètre du calcul (`CoutAppelLlm(tarifs, horloge)`) — testable, jamais un
    `Instant.now()` enfoui dans 11 clients.
  - **Le découpage cache hit / miss est LU, jamais deviné** : DeepSeek renvoie
    `usage.prompt_cache_hit_tokens`, OpenAI `usage.prompt_tokens_details.cached_tokens`,
    les deux dialectes sont acceptés (`CoutAppelLlm.lireCacheHitTokens`). **Absent ⇒
    tout en cache miss**, l'hypothèse **prudente** : on surestime, jamais l'inverse.
    Même repli quand un provider ne déclare pas de tarif de cache (`0` ⇒ plein tarif).
    🛑 **L'invariant « changer de LLM ne touche aucun `.java` ni `.yaml` » survit** :
    tarif de cache et heures pleines sont **facultatifs**, avec des neutres (`0`, `1`,
    `""`), verrouillé par `EvaluationProviderSwapTest`.
  - **Fin de l'arrondi au centime supérieur.** `Math.ceil(usd * 100)` multipliait par
    ~8 la facture d'une micro-analyse (~0,0013 $) : la campagne de 90 cas du
    2026-08-16 a persisté **90 centimes pour 9,9 centimes réels**, et
    `CompetenceCalibrationReport` avait dû republier un `cout_reel_usd` recalculé pour
    le contourner (supprimé, il n'a plus lieu d'être). Le coût est désormais un
    **entier de micro-dollars** — additionnable sans erreur flottante quand un second
    appel s'ajoute au premier, et arrondi au **micro-dollar supérieur** (même prudence,
    granularité 10 000× plus fine).
  - **V034, additive** : `cout_micro_usd` (+ `cost_micro_usd` côté diagnostic) et
    `tokens_input_cache_hit` sur `ai_evaluations`, `user_skill_attempts`,
    `diagnostic_production_analyses`. Le cache **miss** n'a pas de colonne, il se
    déduit. 🛑 `cout_estime_centimes` / `cost_estimate_cents` deviennent **LEGACY,
    plus jamais écrites, plus mappées** — les valeurs restent, **aucun recalcul
    rétroactif** : le prix du jour n'a jamais été stocké à côté des tokens, le
    recalculer serait une invention.
  - **V035, additive : la TRANSCRIPTION suit** (2026-08-16). V034 avait laissé
    `transcriptions.cout_estime_centimes` active au motif que Whisper facture **à la
    minute d'audio, pas au token** — exact sur la **formule**, faux sur l'**unité** :
    `Math.ceil` au centime facturait **1 centime** un audio de 95 s (la médiane du
    dépôt) qui en vaut 0,95, soit **~5 % de trop**, et c'était le dernier endroit du
    dépôt à arrondir une facture au centime. Nouvelle colonne
    `transcriptions.cout_micro_usd` ; l'ancienne devient **LEGACY, plus jamais
    écrite, plus mappée, valeurs intactes** — même doctrine, **aucun recalcul
    rétroactif**.
    🛑 **Les deux formules restent distinctes, seule l'unité est partagée** :
    `util/MicroDollars` (conversion + arrondi au supérieur) est appelé par
    `CoutAppelLlm` (au token) **comme** par `CoutTranscription` (à la minute). Ne pas
    tordre `CoutAppelLlm` pour y faire entrer Whisper, ni recopier la règle d'arrondi
    — c'est le motif qui a fait supprimer les 11 `estimateCostCents`.
    Le tarif à la minute vit désormais **en configuration**
    (`sejourfr.openai.whisper.cost-per-minute-usd`, `OPENAI_WHISPER_COST_PER_MINUTE`,
    défaut YAML **et** POJO `0.006`), jamais en constante Java : il **voyage avec le
    modèle**, dans la même source, comme les tarifs des correcteurs. `0` ⇒ rien n'est
    facturé (colonne `NULL`) plutôt qu'un montant inventé.
  - **Le cache PEUT mordre chez nous, et l'ordre des prompts est déjà bon** (vérifié
    le 2026-08-16, aucun réordonnancement nécessaire — en faire un aurait changé ce
    que le correcteur lit, donc la version du contrat). La grille invariante est le
    **message système**, envoyé en tête : **~80 ko sur 120** pour les productions
    (`commun.sections` 58 ko + few-shot 22 ko), **~94 %** pour Compétences,
    `versionciblee` et `niveauvise`. Rien de variable ne la précède, et la production
    du candidat est **le dernier élément** du message utilisateur. Verrou :
    `EvaluationPromptBuilderTest.le_prefixe_envoye_au_correcteur_est_invariant_donc_le_cache_peut_mordre`
    — ne jamais glisser d'horodatage, d'identifiant ni de compteur en tête d'un
    prompt, c'est invisible fonctionnellement et ça éteint la remise de 31×.
    ⚠️ Le **taux de cache réel** n'est pas mesuré : c'est précisément ce que la
    nouvelle colonne servira à répondre, en une requête SQL.
- **Une sortie LLM malformée est TRANSITOIRE, donc rejouée** (`@Retryable` des deux
  clients) : absence de `tool_calls`, `finish_reason=length`, arguments vides,
  JSON illisible, réponse vide. Seuls la configuration absente et les 4xx sont
  terminaux. Motif : un unique échantillon corrompu (mesuré : du texte arabe
  glissé au milieu de `scores_criteres`) détruisait la tâche sans recours. Le
  `@Recover` **conserve la cause** dans le message, sinon la ventilation
  `MotifPerte` du banc reclasse une troncature en « fournisseur indisponible ».
- **Un message de réessai ne vaut que s'il est actionnable** — vrai pour les
  preuves (cf. `EvaluationRepairPrompt`) **comme pour le garde-fou oral** :
  une violation orale nomme désormais la notion interdite et cite le passage
  rejeté, et le prompt de réparation donne la sortie sûre. Renvoyer le seul
  libellé brut de la violation ne répare rien (mesuré : 0/8 sur les preuves).
- **Preuves opposables (schémas v4 et v5)** : chaque critère porte une citation non vide. Le
  serveur privilégie le passage contigu exact, puis ne tolère, à partir de 4
  tokens, qu'une seule édition de token : insertion/suppression réservée à une liste
  fermée de mots-outils ; la seule substitution admise est la flexion
  `telle/tels/telles`, explicitement reconnue. Toute autre substitution est refusée.
  Elle exige au moins 3 tokens significatifs identiques, un match unique et aucun écart de
  nombre/négation ; tout token contenant un chiffre est immuable. Les variantes
  Unicode, ligatures, apostrophes, tirets et espaces sont neutralisées. En
  dialogue EO, seuls les tours `Candidat :` sont cherchés. Toute preuve acceptée
  est remplacée avant persistance par la sous-chaîne originale exacte ; une
  preuve inventée ou ambiguë déclenche le retry sémantique. Si une unique preuve
  demeure non rattachable après ce retry, elle n'est jamais persistée : le mode
  dégradé documenté ci-dessus conserve seulement les trois preuves sûres.
  **Élision des disfluences, sens production → citation uniquement**
  (`EvaluationProofMatcher.DISFLUENCES`, liste fermée `euh|heu|hum`, tirée de
  `NON_SIGNIFICANT`) : la production peut porter ces tokens en nombre quelconque
  sans que la citation ait à les recopier. **Aucun token porteur de sens n'est
  dispensé** — une citation contenant un mot absent de la production reste
  refusée, la contiguïté et la tolérance d'une seule édition sont inchangées, une
  disfluence ne peut ni ouvrir ni fermer le passage restitué (qui reste la
  sous-chaîne originale exacte, disfluences comprises). Motif : la transcription
  Whisper est littérale, et le prompt interdit par ailleurs d'évaluer les
  hésitations — sans cette élision, le correcteur ne pouvait pas satisfaire les
  deux consignes.
- **Élision des répétitions immédiates** (`EvaluationProofMatcher`, contrats ≤ v5) :
  même famille que l'élision des disfluences, **sens production → citation
  uniquement**. Un bloc de 1 à 3 tokens **immédiatement répété** dans la production
  peut n'apparaître qu'une fois dans la citation. Motif : le correcteur dédouble les
  bégaiements — ce que la grille lui ordonne par ailleurs de ne pas évaluer — et deux
  citations JUSTES ont été refusées d'affilée sur une même production réelle
  (`une sœur qui se trouve tous tous chez moi`, `j'aime bien les les films les films
  comédies`), soit 2 et 3 suppressions, hors de la tolérance d'**une seule** édition.
  **Deux lectures, jamais mélangées** : la lecture stricte garde le comportement
  historique au bit près et **gagne toujours** ; l'élision n'est tentée que si la
  première ne trouve **rien**. L'élision se fait **avant** l'appariement et ne
  consomme donc pas le budget d'édition. Aucun bloc contenant un nombre, un chiffre
  ou une négation n'est élidable ; ambiguïté = refus ; le passage restitué reste la
  **sous-chaîne originale exacte**, bégaiements compris. Limite assumée : une
  répétition légitime (`très très bien`) est élidable — sans conséquence, le texte
  affiché reste celui du candidat.
- **Message de réessai** (`EvaluationRepairPrompt`) : le retry ne renvoie plus la
  seule liste brute des violations (mesuré : **0 preuve réparée sur 8**, le
  modèle resoumettait la même citation). Il rappelle **la citation refusée,
  critère par critère**, énonce la règle (passage contigu, recopié tel qu'il
  apparaît, pas d'ellipse, pas de recomposition, un seul tour `Candidat :` en EO)
  et suggère de re-citer plus court. **Aucun contrôle serveur n'est relâché** :
  on aide le correcteur à respecter la vérification.
- **Mot coupé par la transcription** (`EvaluationProofMatcher`, 2026-08-07) : un token
  de la citation peut recoller **plusieurs tokens consécutifs de la production** dont
  la concaténation est identique — **sens unique production → citation**, exactement
  comme l'élision des disfluences. Motif : sur une transcription hachée
  (« j'ai ach eté cette ves te »), presque aucun passage n'était citable, et la grille
  ordonne pourtant de « changer de passage » — on demandait l'impossible. Quatre
  garde-fous, tous dans le sens « en cas de doute, on ne fusionne pas » : ≤ 3
  fragments ; **blancs horizontaux seuls** entre fragments (ni apostrophe, ni trait
  d'union, ni ponctuation, ni saut de ligne — donc jamais à travers un tour
  `Examinateur :`) ; aucun fragment négation / nombre / chiffre / disfluence ; le mot
  recollé n'est jamais une négation ni un token chiffré. Contiguïté, match unique,
  écart de nombre/négation, tolérance d'une seule édition, tours `Candidat :` :
  **inchangés** ; le passage restitué reste la **sous-chaîne originale exacte**,
  coupures comprises. La voie *fuzzy* (une édition) n'en bénéficie **pas** :
  mot coupé **plus** édition = cas doublement dégradé. Limite assumée et testée : deux
  mots voisins soudés par la citation passent — sans conséquence, rien n'est inventé
  et le passage affiché reste le texte réel.
- **Garde-fou oral : deux faux positifs corrigés** — `repetition` n'est plus interdit
  que dans ses emplois de **diction** (consigne d'évitement portant sur « les
  répétitions » en bloc, ou voisinage d'un marqueur oral dans la même phrase) : il
  détruisait des évaluations pour des remarques de **morphosyntaxe** et levait une
  **contradiction interne** du dépôt, la rubrique v9 §19 *ordonnant* de peser « a-t-il
  dû faire répéter ? ». `accent` n'est refusé que hors de l'idiome « mettre l'accent
  **sur** ». `fluidite`, `prononciation`, `debit`, `intonation`, `pauses`,
  `hesitation`, `orthographe` : **inchangés** — l'acquis « on ne note jamais sur la
  prononciation » est entier. Aucune campagne requise : rien de ce qui note ne bouge.
- **`EvaluationRefusalMetrics`** : ce que nos contrôles refusent est **compté par
  (phase, motif)**, plus seulement logué, et le refus **après réessai** est logué lui
  aussi (il ne l'était pas). Le banc en tire, par tentative, les violations **et la
  citation refusée** — y compris celles du premier appel, que l'exception ne porte pas.
  Sans ça, 98 % des refus étaient sans motif traçable et toute action sur les contrôles
  était un pari.
- **Banc — deux métriques à ne plus confondre** : `sorties_refusees_pct` (÷ appels LLM,
  ce que refusent nos contrôles) ≠ `echec_production_pct` (`tentativesRatees /
  tentatives`, **la seule qui décrit ce que vit un candidat**, puisqu'en production il
  n'y a qu'**un** réessai). `appels_rates_pct` est supprimé : il comptait les
  tentatives de la boucle externe en se présentant comme un taux par appel, et
  sous-estimait les refus d'un facteur ~2. **`calibration.retries` est figé dans le
  rapport** et `-Dcalibration.temoin=<rapport.json>` fait **échouer** une campagne dont
  le témoin n'a pas tourné au même nombre de réessais.
- **Plafond de tokens de SORTIE = 4000**, identique sur les trois providers
  (`sejourfr.production-evaluation.{openai,anthropic,deepseek}.max-tokens`,
  figé par `EvaluationTokenBudgetTest`). À 2000 — valeur d'avant les quatre
  citations littérales du tool-schema — les corrections EO (1800-2000 tokens)
  arrivaient en `finish_reason=length`, JSON tronqué, submission perdue. C'est un
  plafond, pas une consommation : le relever ne coûte rien sur les sorties
  courtes. Ne pas redescendre sans retirer des champs de la sortie.
- **Transaction du pipeline async** : `ProductionPipelineAsyncRunner` reste
  volontairement **sans transaction englobante**. Whisper et l'évaluation ont
  leurs propres transactions ; `ProductionPipelineFailureRecorder` conserve
  `REQUIRES_NEW` pour rendre `FAILED` durable. Le runner charge la task par
  `findByIdWithTask` avant détachement. Ne pas réintroduire de transaction
  externe : une exception d'un service `REQUIRED` la marquerait rollback-only et
  provoquerait un `UnexpectedRollbackException` après le `catch`.
- **Garde-fou EO opposable** : le correcteur ne reçoit plus la durée et sa sortie
  est rejetée si un champ évaluatif fonde la note ou les conseils sur les
  hésitations, répétitions, faux départs, aisance, fluidité, débit,
  prononciation, accent, intonation, orthographe/ponctuation de la transcription
  ou durée. Seules les `confiance_raisons` peuvent expliquer une transcription
  incertaine.
- **Bornes EE strictes TCF IRN** : T1 `30–60`, **T2/T3 `40–90`**. La tolérance
  historique de 20 % est supprimée : serveur, web, mobile et auto-soumission
  appliquent exactement les bornes DB. Les tâches T2/T3 ont un contexte/destinataire et les neuf exemples
  livrés restent dans la fourchette. Les anciennes submissions sont préservées.
  ⚠️ **Le minimum de T2/T3 a valu 60 par erreur** jusqu'à `V724` (2026-08-08) : une
  copie de **40 à 59 mots**, pourtant recevable à l'examen, était **refusée sur les
  trois surfaces**. `V723` figeait même `mots_min = 60` par contrainte SQL.
  **Source de vérité unique : `production_tasks.mots_min/mots_max`**, injectée dans
  le prompt par `EvaluationPromptBuilder`. Ne jamais réécrire ces bornes en dur —
  ni dans une rubrique, ni dans un tool-schema, ni dans un texte de front : c'est
  exactement ce qui a produit une consigne contradictoire au correcteur.
- **Un seul correcteur configurable** : `sejourfr.production-evaluation.provider`
  dans `application.yaml` (défaut `deepseek`, modèle `deepseek-v4-flash`) pilote
  l'async, la fin de session temps réel, la seconde passe et le banc. La seconde
  passe réutilise obligatoirement le même bean provider/modèle. Gemini reste
  uniquement l'examinateur vocal et le transcripteur temps réel ; il ne note pas.
- **Banc de mesure** (`src/test/java/.../calibration/`, corpus
  `src/test/resources/calibration/golden-set-v1.json`, 48 cas synthétiques) :
  **opt-in strict**, jamais dans `./mvnw verify` (appelle un LLM payant).
  `./mvnw -q test -Dtest=CalibrationBenchTest -DfailIfNoTests=false
  -Dcalibration.enabled=true -Dcalibration.rubrics=v8 -Dcalibration.prompt=v5
  -Dcalibration.label=<nom>` → rapport JSON dans `target/calibration/`. Le banc
  lit obligatoirement le provider et le modèle du runtime dans
  `application.yaml`/`.env` : il n'existe plus de surcharge
  `calibration.provider`, afin d'éviter de mesurer un autre correcteur par erreur.
  Parallélisme ≤ 3 : au-delà le fournisseur renvoie des 429 et des cas se
  perdent (mesuré : 5 cas perdus à 4 en vol, 2 à 2 en vol avec `retries=10`).
  **Ne jamais ajuster le corpus** pour faire passer une version : on corrige le
  système, jamais la référence. Une campagne ≈ 0,45 € ; comparer une nouvelle
  version à un **rerun de l'ancienne le même jour** (le bruit inter-campagnes
  vaut ~1 pt de note / ~2 pts de pourcentage, et un seul cas qui bascule sur 12
  ne prouve rien).
  🛑 **INTERDIT DE LANCER UNE CAMPAGNE SANS DEMANDE EXPLICITE DE L'UTILISATEUR**
  (règle posée le 2026-08-07, elle prime sur tout le reste de ce fichier). Le banc
  appelle un LLM payant, c'est **l'argent de l'utilisateur**. Aucun agent ne le
  déclenche « pour vérifier », « pour mesurer avant/après » ou « parce que la règle
  du dépôt l'exige » : il faut une phrase de l'utilisateur qui le demande. En
  l'absence de campagne, on **livre quand même** — en disant franchement ce qui est
  mesuré et ce qui est estimé. La règle « toute modif d'une consigne de notation se
  mesure avant/après » devient donc : *on propose la mesure, on ne la lance pas.*
  Corollaire : **une bascule de LLM ou de modèle ne demande AUCUNE campagne** — le
  contrat de sortie (tool-schema strict, `additionalProperties:false`, longueurs
  plafonnées) et les **contrôles serveur déterministes** sont ce qui tient la
  qualité, pas la mesure a posteriori.
- **Ce qui tient la qualité, ce sont les CONTRAINTES DURES, pas les consignes.**
  Ordre de préférence, du plus fiable au moins fiable, à respecter quand on veut
  corriger un comportement du correcteur : (1) **le tool-schema** — un champ absent
  du schéma ne peut pas être produit ; (2) **une longueur plafonnée** (`maxLength`,
  budget en mots déclaré par la grille, comme le module Compétences : 20 / 30 /
  35 mots) ; (3) **un contrôle serveur déterministe** qui refuse ou purge
  (`EvaluationOutputValidator`, `EvaluationOralArtifactFilter`, `capListe`) ; (4) en
  **dernier** recours, une consigne dans la rubrique. Une consigne est un vœu : v9
  §17 interdisait déjà d'imputer un artefact de transcription au candidat, et le
  correcteur l'a fait dans 5 évaluations EO sur 72. Ne jamais répondre à un
  comportement indésirable par « on va mieux lui expliquer » quand un plafond ou un
  filtre serveur peut le rendre **impossible**.
  Convention de signe partout : **écart = référence − IA** (négatif = IA trop
  indulgente). **Toute modif d'une consigne de notation ou d'un seuil se mesure
  avant/après** — sinon c'est un pari. La contrainte de preuve littérale a été la
  seule exception à cette règle (livrée sans campagne, sans témoin rejoué) : son
  coût en soumissions perdues est resté invisible des mois. Consigné dans
  `docs/notation-ia-eo-ee.md` §12.3 bis, à ne pas effacer.
  **Motif de perte ventilé** (`CalibrationMetrics.MotifPerte` : troncature JSON /
  rejet de preuve / garde-fou oral / fournisseur indisponible / sortie incomplète
  / autre) : le rapport affiche le **taux de cas perdus à côté du taux de sortie
  invalide**. Avant, un rejet de preuve tombait dans `erreurAppel` et la doc
  affichait « 0 % de sortie invalide » pendant qu'un tiers des cas se perdait.
- **Une seule échelle depuis v6** (0 → A1 non atteint, 1 → A1, 2-5 → A2,
  6-9 → B1, **10-20 → B2**) : notre note **s'exprime sur l'échelle** du TCF — elle
  n'est pas la note officielle, qui est produite par plusieurs correcteurs humains.
  La table
  officielle vit toujours dans l'enum `BandeNoteTcf` (code, pas config — donnée
  officielle, pas réglage) ; la grille active la reprend telle quelle dans
  `commun.niveau`. On ne **convertit** toujours rien : `correspondanceTcf`
  (`{niveau, scoreTcfMin, scoreTcfMax}`, `ProductionBilanResponse`) part du
  **niveau** et n'est affichée qu'au **bilan d'une épreuve entière**. **Jamais
  sur une tâche isolée** — au TCF la note /20 porte sur les 3 tâches ; ce qui
  diffère là n'est plus l'échelle mais le **périmètre**. Détail grand public :
  `docs/notation-ia-eo-ee.md` §6.6.
- **Console de calibration admin** (`features/calibration/` +
  `AdminCalibrationService`) : annotation humaine de vraies productions, biais et
  dispersion vs IA. C'est elle qui doit faire grossir le corpus réel.
- **Fiche de scénario EO T2** : `production_tasks.agent_role_card` (migration
  V743, les 20 sujets couverts), rendue par `RealtimePersonaBuilder` via le
  gabarit `t2Fiche` de la persona v2. Jamais exposée à un client, jamais envoyée
  à l'IA correctrice — **ce n'est pas une check-list de notation**.
> ⚠ **CONTRADICTION #2** — voir `docs/decisions/contradictions-ouvertes.md`. Non tranchée.

- **Titre éditorial d'un sujet** : `production_tasks.titre` (colonne V028,
  **nullable** ; contenu V754 — les **103** sujets publiés). Les cartes de sujet
  affichaient « Sujet 01 » + le début de la consigne, or les consignes d'une même
  tâche commencent toutes pareil. Contenu **généré**, jamais écrit à la main dans
  le SQL (`backend_sejourfr/tools/production-titres/`, même convention que
  `tools/competences/`), et **éditable en console** une fois les migrations
  appliquées (`/api/admin/production-tasks`, feature admin `productionTasks/`) :
  c'est la base qui fait foi. **Repli obligatoire quand le titre manque** :
  « Sujet N » + consigne, déclaré une seule fois par front
  (`productionSubjectTitle`, `lib/types.ts` ⇄ `widgets/production_common.dart`,
  libellé gelé par test des deux côtés). Aucun écran ne suppose le titre présent.
- **Fluidité de la session vocale temps réel** (chantier du 2026-08-12, les 3
  surfaces). Le ressenti « l'examinateur met trop longtemps à répondre » avait une
  cause unique et symétrique : **le gate qui coupe le micro pendant que
  l'examinateur parle se levait sur une estimation arithmétique** (durée théorique
  de l'audio reçu + 900 ms), aveugle au retard réel de la file. Trop tôt, le micro
  rouvrait pendant la parole et l'écho repartait à Gemini en **faux tour
  candidat** ; trop tard, les **premiers mots du candidat étaient jetés** et tout
  le tour glissait. Le gate suit désormais la **position de lecture réelle** —
  `playHead` côté web, `remainingFrames` du moteur natif + file côté mobile, sur
  **horloge monotone** (`Stopwatch`, jamais `DateTime.now()`). Marge 900 → 100 ms,
  tenue micro 300 → 120 ms : ces deux valeurs ne compensaient que l'imprécision
  supprimée. **Ne pas les regonfler** sans remettre une estimation à la place.
  - **Le micro reste coupé pendant que l'examinateur parle** (half-duplex,
    anti-écho) — arbitrage du propriétaire, 2026-08-12. L'AEC mobile n'a pas le
    signal joué par `flutter_pcm_sound` comme référence, donc un full-duplex
    ferait s'auto-interrompre l'examinateur. Le code de flush `interrupted` reste
    en place, **inatteignable mais intact** : ne pas le supprimer.
  - **Chunk micro 20–40 ms des deux côtés** (recommandation Google). Le worklet
    web postait un render quantum brut = **un message WS toutes les 8 ms**
    (~125/s, 256 o utiles pour ~344 car. de base64) ; il accumule maintenant
    40 ms. Mobile : `streamBufferSize` explicite — ⚠️ **l'unité diffère**,
    Android compte des **octets**, iOS/macOS des **frames**.
  - **Pré-roll de lecture** (120 ms web / 150 ms mobile) : sans lui, un hoquet
    réseau donne un trou puis un clic. Amorçage forcé en fin de tour pour ne pas
    coincer une réponse courte.
  - 🛑 **VAD de fin de tour : `END_SENSITIVITY_MEDIUM` N'EXISTE PAS.** L'enum du
    fournisseur n'a que `..._UNSPECIFIED`, `..._LOW` et `..._HIGH` — sur chacune
    des deux sensibilités. Posée le 2026-08-12 (« répondre plus vite en fin de
    tour »), cette valeur a fait répondre `auth_tokens` en **400
    INVALID_ARGUMENT à CHAQUE émission de token** : `GeminiTokenBroker.mint`
    levait, `RealtimeSessionService.start` retombait en `ASYNC_FALLBACK`, et
    **plus une seule session temps réel n'a eu lieu du 2026-08-12 au 2026-08-16**
    (dernière ligne `realtime_sessions` : 2026-08-11 21:33) — sur les **deux**
    fronts, **en silence** : le candidat choisissait « Avec un examinateur » et
    atterrissait sur l'enregistreur solo, sans un mot. **La valeur retenue est
    donc `LOW`** : c'est le réglage le plus lent, mais `HIGH` couperait un
    apprenant A2 en pleine hésitation et il n'y a pas de troisième choix — le
    vrai levier de réactivité est `silence-duration-ms`, pas cette enum.
    Deux verrous posés le 2026-08-16 : allowlists
    `RealtimeProperties.Vad.{START,END}_SENSITIVITES` **opposées au BOOT**
    (`GeminiTokenBroker.assertVadSupportee` → une valeur inconnue fait échouer le
    démarrage, jamais de repli muet — philosophie des contrats de prompts), et un
    **message au candidat** quand son choix de temps réel n'aboutit pas
    (`kRealtimeUnavailableMessage` ⇄ `REALTIME_UNAVAILABLE_MESSAGE`, miroirs mot
    pour mot) : on continue de ne **jamais** le bloquer, mais on ne le dépose
    plus sur l'enregistreur solo comme s'il l'avait choisi.
    `silence-duration-ms` reste à **500** (plancher Google, en dessous les pauses
    naturelles fragmentent l'énoncé) et `prefix-padding-ms` à **300** (sinon la
    première syllabe est rognée). Les 5 valeurs sont surchargeables par env.
  - **Reprise de session** (`sessionResumption` + `contextWindowCompression`,
    V032 additive, `POST /api/realtime/eo/sessions/{id}/resume`). Le token vise
    l'endpoint **contraint** : le client ne peut poser **aucun** champ de setup,
    donc il **relaie son handle au serveur**, qui le verrouille dans le setup d'un
    nouveau token. Seul montage possible — ne pas tenter de reconnecter en
    réutilisant l'ancien token. `uses` 1 → 3 et `newSessionExpireTime` 120 → 600 s
    (120 s ne couvrent pas un tunnel de métro : le token mourait avant le retour
    du réseau, la reprise aurait été illusoire). ⚠️ **Non vérifié contre l'API
    réelle** que Gemini accepte `sessionResumption` dans un setup verrouillé —
    repli `REALTIME_SESSION_RESUMPTION_ENABLED=false`.
  - **Quota jamais débité deux fois** : `appendTranscript` lisait la session
    **sans verrou**, deux transactions concurrentes pouvaient toutes deux voir
    `PENDING` et décrémenter (`decrementRealtimeSessions` est atomique mais
    conditionné à `> 0` : il ne protège pas contre deux débits **légitimes**).
    Verrou pessimiste de ligne, `finish` restant volontairement non transactionnel.
    `turnIndex` rend `appendTranscript` **idempotent** : un réessai doit repartir
    avec le **même** index, attribué à la construction du lot et non à l'envoi.
    C'est l'invariant qui protège le quota — **aucun front ne rappelle
    `POST /sessions` après une coupure**, ce serait un second slot.
- **Écran allumé — primitives partagées, un seul point de câblage par front.**
  Mobile `core/utils/screen_wake_lock.dart` (`ScreenWakeLock`, **refcount par
  raison**, exceptions plateforme avalées, ré-application au retour au premier
  plan car Android relâche en arrière-plan) + widget déclaratif
  `core/widgets/keep_screen_awake.dart` ; web `lib/use-screen-wake-lock.ts`
  (`useScreenWakeLock(active)`, détection de capacité — absente sur Safari iOS
  < 16.4 et Firefox — et **ré-acquisition sur `visibilitychange`**, le navigateur
  relâchant le verrou dès que l'onglet passe en arrière-plan). Câblé dans
  `RecordingController` (mobile) et `EoRecordingForm` (web), qui servent **à eux
  seuls** production EO + compétences EO + diagnostic ; plus `SejourAudioPlayer`
  pour la réécoute et l'écran temps réel. ⚠️ Le câblage mobile passe par le **flux
  d'état** du service, pas par `start()/stop()` : l'auto-stop de `maxDuration`
  appelle `stop()` sur le **service**, pas sur le controller — un acquire posé
  dans `start()` fuirait à chaque enregistrement arrivé au bout. **Aucune
  permission `WAKE_LOCK`** : `wakelock_plus` pose `FLAG_KEEP_SCREEN_ON` sur la
  fenêtre, qui n'en exige pas ; la déclarer ne ferait que salir la fiche Play Store.
- **Recollage des tours EO temps réel** (`util/TranscriptTurnStitcher`, drapeau
  `sejourfr.production-evaluation.recollage-tours.enabled`, livré **ACTIF** —
  c'est une correction, pas une expérimentation). La transcription temps réel
  clôt un tour sur le signal de fin de tour **du modèle**, pas sur la fin de la
  phrase du candidat : un même énoncé ressortait scindé en tours consécutifs.
  Conséquences corrigées : `EvaluationProofMatcher.searchableSegments` construit
  un segment par tour, donc une citation à cheval sur deux tours était
  **introuvable** (et deux preuves refusées = submission en échec sous v7+) ;
  le correcteur jugeait la langue sur un texte haché et baissait sa confiance
  pour une raison venant de nous ; le candidat relisait sa phrase en deux bulles.
  - **Non destructif, un seul point d'application** : rien n'est réécrit
    (`realtime_sessions.transcript` et `transcriptions.texte` intacts), le
    recollage se fait **à la lecture** dans
    `TranscriptionManager.findLatestTexteBySubmissionId` — l'unique accesseur au
    texte, volontairement le seul (aucune méthode ne rend plus l'entité
    `Transcription`). Prompt, contrôle de preuve et DTO servi aux 3 fronts en
    héritent sans une ligne de code côté web/mobile.
  - **Invariant à ne pas casser** : le texte cité par le correcteur EST celui
    affiché au candidat. Deux points d'application = preuves inopposables.
  - **Règle — en cas de doute, on ne fusionne pas.** Le sens de l'erreur est
    assumé : une fusion **fausse** fabrique de la parole, une fusion **manquée**
    ne fait que ramener au comportement d'avant. Trois garde-fous, tous dans ce
    sens : (1) même locuteur uniquement ; (2) **jamais** à travers un tour
    `Examinateur :` ; (3) **jamais** quand une phrase paraît terminée et qu'une
    nouvelle commence — ponctuation forte à gauche **ET** majuscule à droite
    (les deux conditions ; la fragmentation qu'on corrige laisse presque toujours
    le second morceau en minuscule) ; (4) **jamais** autour d'un fragment sans
    aucun caractère alphanumérique (`. . . .`), qui reste un **tour isolé** et
    n'est jamais retiré du texte servi — le recollage n'enlève que des
    *frontières*, jamais du contenu. Jonction : un **espace simple**, aucune
    ponctuation ajoutée ni retirée (une ponctuation forte de fin de fragment est
    **conservée** — elle vient du transcripteur, et le matcher ne tokenise pas la
    ponctuation) ; pas d'espace devant `,.…)]}%` ni après une élision/trait
    d'union. Les **mots** coupés en deux (bug corrigé le 2026-07-04) ne sont
    **jamais** réparés, et les transcriptions ratées de bout en bout (`stanno
    mal.`, marqueurs contenant des lettres comme `<noise>`) ne sont **pas**
    rattrapées : notre découpage ne les a pas cassées.
  - Mesure sur les 35 sessions réelles : 749 → 398 tours (-46,9 %), tours
    candidat 461 → 183 (-60,3 %), médiane 6 → 14 tokens par tour candidat,
    tours candidat sous 4 tokens 26,9 % → 15,3 %. Sur 388 frontières « même
    locuteur », **37 sont refusées** par les garde-fous 3 et 4 (34 + 3).
- **Filet « marqueur A2 vendu comme levier d'un palier supérieur »**
  (`EvaluationPalierMarqueurFilter`, livré **ACTIF** le 2026-08-08, EE **et** EO).
  Purge les phrases de `suggestions`, `points_a_ameliorer` et
  `exemples_corriges[].gain` qui présentent un moyen classé **A2 par la grille
  active** (`et`, `mais`, `alors`, `aussi`, `après`, `parce que`) comme la clé du
  **B1/B2** — verbatims réels : « une subordonnée causale avec « parce que »,
  marqueur attendu au B1 ». Le propriétaire a suivi ce conseil, resoumis, **même
  note** : structurellement incapable de faire progresser. **Ni note, ni niveau, ni
  seuil** (appliqué après `applyPlafonds`, d'où il tire le niveau constaté) ⇒ aucune
  campagne requise. Deux conditions dans la **même phrase** : revendication d'un
  palier **> A2** (B1/B2 nommés, ou formule relative si constaté ≥ A2 — depuis A1
  « gagner un niveau » vise A2, ce que la rubrique **ordonne**) **et** marqueur
  **désigné** (cité seul, ou « parce que » précédé d'un mot de désignation à ≤ 25
  caractères). **Mesuré sur les 707 champs de restitution des 138 évaluations en
  base : 5 phrases purgées, toutes fautives, 0 faux positif** ; deux variantes plus
  larges rejetées sur ces mêmes données (« marqueur dans n'importe quelle citation »
  effaçait un conseil B2 sur l'objection traitée ; « désignation + n'importe quel
  marqueur » effaçait un conseil sur le passé composé). Jamais touchés :
  `justification_niveau`, `exemple.avant`, `exemples_corriges[].original`,
  `scores_criteres[].commentaire`. Liste fermée en Java, **miroir vérifié par
  `EvaluationPalierMarqueurRubriqueTest`** contre la rubrique active. Purges comptées
  par `EvaluationPurgeMetrics` (distinct de `EvaluationRefusalMetrics` : un refus
  coûte la tâche, une purge retire une phrase).
- **Même filet sur `version_ciblee.ce_qui_manque`** (`VersionCibleeLevierFilter`,
  livré **ACTIF** le 2026-08-08). Le défaut existait **aussi** dans le 2ᵉ appel —
  mesuré en base : **2 blocs, 6 leviers, 1 fautif** (« Relier les phrases avec des
  connecteurs simples : « et », « mais », « donc » » sous `niveau_vise: B1`).
  Devenu urgent depuis que les fronts n'affichent plus `version_amelioree` :
  `version_ciblee` est **LE** texte modèle d'un résultat EE, leviers en dessous.
  Détection **partagée** (`EvaluationMarqueursA2.designe`, extraite à la 2ᵉ
  occurrence, porte aussi `MARQUEURS_A2`) ; la condition « palier revendiqué » est
  ici **le champ structuré `niveau_vise`**, pas une devinette dans la phrase → on
  purge dès que `niveau_vise > A2`, jamais si `= A2`. Le levier tombe **en entier**
  (un demi-levier ne s'applique pas). **Nouveau garde-fou commun aux deux filets** :
  tout ce qui suit une formule de **rejet** (`au lieu de`, `plutôt que`, `à la place
  de`, `au-delà de`, `remplacer`, `éviter`) est ignoré — sans lui, notre propre ancre
  few-shot « … au lieu de poser « mais » seul » se purgeait elle-même. Reste < 2
  leviers ⇒ **une** réparation actionnable (`VersionCibleeRepairPrompt.pourLeviers`,
  nomme le levier refusé + les moyens > A2), puis **abandon du bloc** ; **une seule
  réparation par bloc, tous motifs confondus** (longueur ou leviers). Compté
  `EvaluationPurgeMetrics.MARQUEUR_PALIER_LEVIER`, à part de `MARQUEUR_PALIER`.
  Consigne ajoutée en parallèle dans `production-version-ciblee-rubrics-v1.json`
  (prompt récent, non figé par un contrat de notation) — mais c'est le contrôle qui
  tient la règle. Invariant best-effort intact, aucune campagne requise.
- **Bornes de longueur = `ProductionTextBounds`** (`util/`), source unique partagée
  par `ProductionEvaluationService.validateTextWordCount` et le second appel
  « version au niveau visé ». Motif : `version_ciblee.texte` faisait **63 et 64 mots**
  sur une tâche EE T1 à `mots_max=60` — un modèle **non soumettable** sur notre propre
  plateforme, la seule garde étant une consigne de prompt. Désormais bornes injectées
  dans le prompt **et** recomptées serveur (`ProductionPayloadSupport.countWords`,
  **sans tolérance** — celle de 20 % ne vaut que pour les leviers). Hors bornes ⇒
  **une** réparation actionnable (`VersionCibleeRepairPrompt` : compte obtenu, bornes,
  mots à retirer/ajouter, « ne coupe pas en cours de phrase »), puis **abandon du
  bloc** — on ne tronque **jamais** un texte modèle. Une violation **structurelle** ne
  vaut toujours **aucun** second appel payé. Invariant best-effort intact.
- **Filet déterministe de langue étrangère à l'oral** (`EvaluationOralArtifactFilter`,
  volet LANGUE, livré **ACTIF** le 2026-08-07). Le transcripteur temps réel (Gemini
  natif-audio) hallucine des passages en langue/écriture étrangère — **6
  transcriptions realtime sur 39**, contre **0 sur 36** côté Whisper, où la langue est
  imposée ; l'API Live ne permet **pas** de l'imposer à l'entrée, et les modèles
  natif-audio rejettent un code de langue. Le correcteur l'imputait au candidat dans
  **5 évaluations EO sur 72** (« *Éviter de passer à une autre langue pendant
  l'épreuve* »). Le serveur retire ces phrases de `scores_criteres[].commentaire`,
  `points_a_ameliorer`, `suggestions`, `points_forts`,
  `accomplissement.objectif_resume` et `exemples_corriges`, pose
  `AVERTISSEMENT_LANGUE`, et **ne touche ni la note, ni le niveau, ni un seuil**.
  - **Jamais `confiance_raisons`** : « transcription partiellement incertaine
    (passages en russe et en néerlandais) » est le **bon** comportement — là, la
    langue étrangère est une limite d'**observation**. **Jamais en EE** : à l'écrit le
    candidat tape chaque mot, une langue étrangère est une vraie non-réalisation.
    L'asymétrie vient de la **machine**, pas du niveau exigé.
  - **Garde-fou contre la neutralisation d'une VRAIE bascule de langue** (piège
    `AUTRE_LANGUE` du corpus) : deux mesures sur les seuls tours `Candidat :` —
    lettres non latines ≤ **15 %** ET mots-outils étrangers ≤ **6 %**, avec ≥ **40**
    mots exploitables. Au-dessus de l'un **ou** l'autre, ou en cas de doute, **on ne
    purge rien**. Calibré sur les données réelles : artefacts ≤ 6,8 % / ≤ 1,4 %, piège
    espagnol à 12,5 %. ⚠️ **Le ratio de mots-outils FRANÇAIS ne sépare pas** — le
    piège en affiche 36 %, plus que 8 vraies transcriptions françaises (les langues
    romanes partagent trop de petits mots) ; d'où
    `ProductionValidityService.MOTS_OUTILS_ETRANGERS`, miroir de `MOTS_OUTILS_FR`,
    verrouillé par test.
  - **Rubriques v10 et v11 : écrites, mesurées MOINS BONNES que v9, NON ACTIVÉES, ne
    pas réessayer cette voie.** Elles répondaient au même problème par une **consigne**
    — illustration directe de la règle « les contraintes dures priment sur les
    consignes ». Campagne du 2026-08-07, témoin v9 du même jour, même modèle,
    `retries=1` : accord exact 81,8 % (v9) contre 75,6 % et 76,7 % ; échec en
    production 8,33 % contre 14,58 % et 10,42 % ; pièges 7/8 contre 4/8 et 5/8. v10
    remontait en plus un hors-sujet de `A1_NON_ATTEINT` à `A1` : le bloc ajouté
    (+4197 caractères) **diluait la sévérité du reste**. Elles restent chargeables.
  - **Persona `realtime-personas-v3.json`** (défaut) = v2 + verrou de langue dans la
    system instruction. **Biais, pas garantie**, et non mesurable au banc.
  - Frontières assumées : la purge ne se déclenche que sur un marqueur d'une **liste
    fermée** (une formulation qui y échappe passe) ; `MOTS_OUTILS_ETRANGERS` couvre 6
    langues, une vraie production en turc ou polonais n'est protégée que par le
    contrôle amont `ratioMotsOutils < 0,10`.
- **Volet FORME du même filet — une faute de grammaire ORALE est une STRUCTURE, jamais
  la forme d'un mot** (`EvaluationOralArtifactFilter`, livré **ACTIF** le 2026-08-09).
  Cas réel : « « abit à Lille » (j'habite) » reproché en `morphosyntaxe` alors que le
  candidat avait dit « j'habite » — la transcription avait mangé le « j'h ». Mesure sur
  les 142 évaluations en base (passages cités, présents verbatim, absents d'un
  dictionnaire de 475 k formes) : **9 EO sur 75 (12,0 %), 0 EE sur 67**. **Zéro à
  l'écrit** ⇒ la cause est la machine, pas le niveau. Règle : un reproche ancré dont une
  citation ne nomme qu'**1 ou 2 mots porteurs** est purgé ; **0 mot porteur**
  (« pour ne pas que ») = structure pure, **conservée** ; **≥ 3** = structure, conservée.
  **EO seulement, critère `morphosyntaxe` + priorités qui le relisent seulement** —
  jamais `lexique` (deux faux positifs réels mesurés : `chronoposte`, `ESN`, ce dernier
  cité en **point fort**), jamais l'écrit. Ni note, ni niveau, ni seuil ne bougent ;
  avertissement candidat + compteur `ARTEFACT_ORAL_FORME`. **Coût assumé et mesuré** :
  11 phrases sur 75 commentaires EO tomberaient, dont ~7 portaient AUSSI une vraie faute
  — la phrase entière part (retirer une citation au milieu d'une énumération rendrait un
  texte mutilé). Corollaire honnête : **ça ne change aucune note**, donc le palier du cas
  réel (A2 → B1 si on retirait les 3 fautes) n'est **pas** corrigé.
  Au passage, `reprocheDeNiveauMot` (volet MOT) exige désormais ≥ 1 mot porteur :
  il purgeait par inadvertance les citations 100 % mots-outils, qui sont de vrais
  reproches de grammaire. Resserrement pur.
- **UN SEUL avertissement sur une production ORALE** (2026-08-17). Le bloc « À savoir sur
  cette évaluation » empilait **trois** paragraphes ; il n'en porte plus qu'un,
  `AiEvaluationService.AVERTISSEMENT_TRANSCRIPTION`, réécrit en trois phrases : « Nous
  analysons la transcription écrite de votre enregistrement, pas votre voix — et la
  transcription peut se tromper. Dans ce cas, l'erreur ne vous est jamais comptée. La
  prononciation et l'aisance ne sont donc pas évaluées ici. » Les constantes
  `AVERTISSEMENT_ARTEFACT`, `AVERTISSEMENT_FORME` et `AVERTISSEMENT_LANGUE` d'
  `EvaluationOralArtifactFilter` sont **supprimées**, ainsi que les trois `addAvertissement`
  qui les posaient. Motifs : elles racontaient au candidat la **mécanique interne** de nos
  purges, et leur seul contenu utile (« la transcription peut se tromper, on ne vous le
  compte pas ») est **exactement** ce que dit la 2ᵉ phrase du texte unique — d'où l'absorption
  de `AVERTISSEMENT_LANGUE` avec les deux autres. La mention « prononciation et aisance »
  est **conservée** (la retirer laisserait croire que l'oral a été jugé dessus et que c'est
  bon) ; le renvoi à l'examen officiel part dans `docs/notation-ia-eo-ee.md` §9.
  🛑 **Aucun filtre n'est désactivé, aucun compteur n'est retiré** : les purges des trois
  volets tournent à l'identique et restent comptées par `EvaluationPurgeMetrics` — c'est le
  **texte affiché** qui disparaît, pas le nettoyage ni sa trace. Ne pas recréer ces
  constantes. Miroirs front (le **repli** quand la liste arrive vide sur une tâche orale,
  évaluations antérieures) : `web/ProductionFeedbackView.TRANSCRIPTION_LIMIT` ⇄
  `mobile/kOralEvaluationLimitNotice`, mot pour mot. **Legacy intact** : les `feedback_json`
  déjà persistés gardent leurs anciens textes, aucune migration, et les fronts affichent la
  liste reçue quel qu'en soit le nombre. Les **commentaires de critère de remplacement**
  (`COMMENTAIRE_CRITERE_PURGE*`, `OBJECTIF_RESUME_PURGE_LANGUE`) sont **inchangés** : ce sont
  des champs obligatoires qui ne peuvent pas rester vides, pas des avertissements. Le
  **diagnostic** n'a pas d'avertissement à retirer (`DiagnosticOralArtifactFilter` remplace le
  `summary`, il n'en pose aucun) — mais son texte de remplacement a suivi le **même** arbitrage
  le 2026-08-17 : il rassure au lieu d'expliquer la purge (cf. § Diagnostic).
- **Indicateur de qualité de transcription** (`TranscriptionQualityAudit`, migration
  `V027`). Whisper renvoie `segments[].avg_logprob/no_speech_prob/compression_ratio` dans
  `verbose_json` — **payés depuis toujours, jamais lus** ; le temps réel n'expose rien.
  Deux taux **déterministes et gratuits** sur les seuls tours `Candidat :` : **formes
  suspectes** (mots de 1-3 lettres absents d'un inventaire fermé d'~290 entrées, incluant
  `MOTS_OUTILS_FR`) > **10 %**, ou **collages** (deux formes suspectes qui se suivent) >
  **2 %** ⇒ transcription **dégradée**. Plancher 40 mots. **Pas de dictionnaire français
  embarqué** (2-4 Mo de jar, licence tierce) : mesuré sur les 123 productions mesurables
  de la base, l'inventaire fermé **sépare mieux** qu'un OOV brut (les mots longs
  hors-vocabulaire sont des noms propres, sigles et néologismes d'apprenant). La coupure
  colle **exactement** à la fenêtre du bug « mot coupé » : 8 sessions du 28/06 au 04/07 à
  **18,29-26,94 %**, les 24 suivantes **< 4,84 %**, aucune observation entre les deux.
  Déclenche **deux choses et rien d'autre** : le volet FORME passe en mode large, et la
  **confiance** est plafonnée `FAIBLE` avec sa raison (obstacle à l'**observation**, pas
  défaut du candidat). **Note, niveau et seuils ne bougent jamais.** Les deux taux + les
  3 indicateurs Whisper sont **persistés** sur `transcriptions` (index partiel
  `idx_transcription_degradee`) : le bug de juillet aurait été visible **en une requête**.
> ⚠ **SUSPECTÉ PÉRIMÉ — non vérifié au 2026-08-23, ne pas appliquer sans confirmation.**
> Suspicion #6 — motif et liste complète : `docs/decisions/suspects-perimes.md`.

- **Deux drapeaux livrés ÉTEINTS** (`sejourfr.production-evaluation`) :
  `fluidite.enabled` (débit/pauses, informatif) et `seconde-passe.enabled` (2ᵉ
  lecture en zone floue, même provider/modèle). À `false`, ils ne changent
  **rien**. Les `plafonds`, eux, sont **actifs**.
- **`coherence-bilan.enabled` est ACTIF depuis le 2026-08-05** (défaut `true`
  dans `application.yaml` **et** dans le POJO, pour qu'ils ne divergent pas) :
  pas de B2 au bilan d'épreuve si T3 < B1. Motif : le niveau d'une épreuve est
  la **moyenne pondérée des compétences** des 3 tâches
  (`ProductionBilanService.compute`, qui a remplacé un ancien `min()`), or les
  tâches ne sont pas interchangeables — T3 est la seule qui demande
  d'argumenter, donc la seule qui puisse démontrer un B2. Le garde-fou ne peut
  qu'**abaisser**, jamais relever : c'est ce qui le rend sûr. Généralisable
  palier par palier (liste de couples `tache3-min`/`plafond`) sans réécrire le
  calcul — forme proposée dans le javadoc de `CoherenceBilan`, **non
  implémentée**. ⚠️ **Activé sur du raisonnement, pas sur une mesure** : le
  corpus du banc porte un niveau attendu **par tâche**, il n'a aucune référence
  de niveau d'**épreuve** — il ne peut structurellement pas arbitrer ce choix.
  Le vérifier demanderait un jeu de cas « 3 tâches + niveau d'épreuve attendu »,
  qui n'existe pas. Détail : `docs/notation-ia-eo-ee.md` §6.5 bis.
- **Niveau d'un examen blanc TCF complet** : `finalCecrlLevel` est le **plancher
  ordinal des 4 épreuves** (`FullTcfExamResponseBuilder.floorOfCecrls`), plafonné
  B2 — à ne pas confondre avec le niveau d'une **épreuve**, qui est une moyenne
  (d'où « Niveau global » au bilan d'épreuve, « plancher » au bilan d'examen
  complet ; les deux libellés sont exacts, chacun chez lui). Sont **hors
  périmètre** du plancher une épreuve `locked` (verrou freemium — elle n'a pas
  été passée, la compter `A1_NON_ATTEINT` revenait à dire à un compte gratuit
  qu'il n'atteint pas le A1 parce qu'il n'a pas payé) et une épreuve à
  `cecrlLevel` null (évals FAILED ou en vol) : **null = inconnu, jamais mauvais**.
  Une épreuve **ouverte puis abandonnée** (`timer_started_at` posé, chrono
  écoulé, rien rendu) reste, elle, comptée `A1_NON_ATTEINT` — elle a été passée
  et ratée. ⚠️ **Une épreuve JAMAIS OUVERTE en sort** (2026-08-15) :
  `timer_started_at` NULL **et** rien de rendu (aucune réponse en CO/CE, aucune
  soumission en EE/EO) ⇒ `cecrlLevel` **null**, hors plancher, donc
  `finalLevelPartial` vrai. Les **deux** critères, jamais l'un seul : tous les
  sous-attempts antérieurs au chrono par épreuve portent `timer_started_at`
  null, et s'en contenter effacerait le niveau d'épreuves réellement passées.
  Motif mesuré : un candidat ayant joué CO (A2) + CE (A1) puis quitté voyait ses
  EE/EO closes par le front, notées `A1_NON_ATTEINT`, son A2 écrasé, et un bilan
  annoncé **complet sur 4 épreuves**. Même raisonnement que la branche `locked`
  vingt lignes plus haut — une porte jamais franchie n'a pas été passée, et
  `null = inconnu, jamais mauvais`. ⚠️ **Le serveur ne refuse PAS
  `markSubAttemptDone` sur une épreuve jamais lancée** (pas de 422) : le flux
  d'abandon volontaire des fronts l'appelle avant `finish`, qui exige tous les
  sous-attempts terminés — un refus casserait le bouton « Abandonner ».
  Abandonner sans ouvrir l'EE est un geste **valide** ; c'est le **verdict**
  qu'on en tirait qui était faux. Conséquence côté fronts : une sous-épreuve
  terminée, non verrouillée, sans échec et **sans niveau** est désormais un cas
  normal, à lire « non passée » et **jamais** « évaluation en cours » (web :
  état `not_taken` de `subAttemptView` ; mobile : `SubAttempt.jamaisOuverte` —
  sans quoi un spinner tourne sans issue). Partialité
  exposée aux fronts par `epreuvesCountedInFinalLevel` / `epreuvesExpected` /
  `finalLevelPartial` (+ `finalLevelPartial` sur le résumé) : aucun front ne doit
  plus écrire « le plus bas de tes 4 épreuves » en dur, ni agréger un examen
  partiel dans un « meilleur niveau » sans l'annoter. V024 a remis à NULL les
  `final_cecrl_level` déjà persistés à tort sur les examens verrouillés.
- **Niveau TCF estimé d'un CANDIDAT** (≠ résultat d'un examen) —
  `TcfProfileService`, arbitré le 2026-08-08 : **plancher des 4 épreuves,
  chaque épreuve retenant son MEILLEUR résultat, une épreuve abandonnée sans
  rien rendre étant EXCLUE**. « Aucune preuve » n'est pas « mauvaise preuve » :
  `null = inconnu, jamais mauvais`, même principe que `finalCecrlLevel`.
  - **« Abandonnée sans rien rendre »**, écrit dans le code : CO/CE = examen
    fini avec **zéro réponse** (filtre `EXISTS` de
    `AttemptRepository.findQcmEpreuvesPassees`, verrouillé par
    `AttemptManagerIT`) ; EE/EO = **zéro soumission évaluée**.
  - **Les productions entrent enfin dans le calcul** : EE/EO sont lues dans
    `ai_evaluations` (meilleur niveau d'une **tâche** évaluée, la plus récente
    évaluation faisant foi par soumission). Avant, le niveau ne regardait que
    `attempts.cecrl_level` — un candidat qui ne travaillait qu'en EE/EO restait
    à « — » indéfiniment, et un examen complet abandonné le figeait à
    « < A1 ».
  - **Une seule surface publie ce niveau** : `DashboardSummaryResponse
    .estimatedTcfLevel` (`GET /api/me/dashboard`), lu tel quel par le web
    (dashboard, profil, statistiques, `TcfHub`, examens-blancs) et le mobile
    (accueil, profil). **Aucun front ne le recalcule.** Libellé aligné des deux
    côtés : il contient toujours le mot **« estimé »**.
  - L'endpoint `GET /api/tcf/profile/level` et son client mobile
    `tcfLevelProfile()` (zéro appelant) ont été **supprimés** : deux surfaces
    HTTP répondant différemment à la même question, c'est exactement ce qui a
    produit l'incohérence.
- **Ce qui reste ouvert** : `ProductionBilanService` (bilan d'**une épreuve**
  de production) garde sa **moyenne** pondérée des 3 tâches, et
  `FullTcfExamResponseBuilder` (niveau d'**un examen complet**) garde son
  plancher où une épreuve abandonnée compte `A1_NON_ATTEINT`. L'arbitrage
  ci-dessus ne vaut que pour le **niveau d'un candidat dans le temps** — ne pas
  le propager à ces deux calculs sans une décision explicite.
