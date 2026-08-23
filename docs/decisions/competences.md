# Journal — contrats du module Compétences (v2 → v6)

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Journal daté, verbatim et intégral.**
> Origine : lignes 3283-3394, 3423-3478, 3487-3641 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier consigne les arbitrages et révocations : on l'ouvre **avant de changer une règle**, pas pour l'appliquer.
> Fichier jumeau : `docs/regles/competences.md`
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

- **v6 = LE COÛT DE NOMMER UN PALIER DEVIENT LE MÊME PARTOUT** (2026-08-16,
  rubriques v6 / tool-schema **v5**). v6 est **v5 au bit près pour tout ce qui
  JUGE** (rôle, périmètre, les 3 verdicts et leur règle de décision,
  `commun.statuts`, `commun.niveaux`, `commun.contraintes_longueur`, la brièveté
  qui n'est pas un défaut, le garde-fou oral, et **les 10 ancres dans leur
  substance**) — verrou `CompetenceAnalysisContractTest`, qui **reconstruit v5
  depuis v6** par une liste **énumérée** de 6 éditions et exige l'égalité. Le
  tool-schema v5 est **v4 avec `level_evidence` dans son `required`**, verrou :
  **égalité stricte** de tout le reste (types, bornes,
  `additionalProperties:false`, les 5 autres propriétés au caractère près) ; les
  2 descriptions éditées se **reconstruisent** elles aussi en celles de v4.
  - **Le défaut corrigé est dans le MÉCANISME, pas dans une consigne.** Sous v4,
    annoncer un B1/B2 obligeait à fournir un numéro de segment, et un numéro
    absent/faux faisait **abaisser le verdict d'un palier** ; annoncer un A2 ne
    coûtait **rien** et ne risquait **rien**. Le mécanisme lui-même rendait le
    palier bas confortable et le haut risqué — et **aucune ancre ne pouvait le
    corriger**, d'où les 3 ancres de v5 restées sans effet sur la cause. Mesure
    en base : **0 B2 sur 18 tentatives**.
  - **L'EFFORT devient symétrique, la SANCTION reste où elle protège.** Le
    correcteur désigne **toujours** le segment sur lequel il fonde son verdict,
    `A1_NON_ATTEINT` compris. Mais `CompetenceLevelEvidenceGuard` **n'abaisse que
    sur un B1/B2 mal étayé** : abaisser un A2 punirait la prudence, exactement
    l'inverse du but. Un défaut sous le B1 est **compté**
    (`CompetenceLevelDowngradeMetrics.enregistrerSansSanction`, clés
    `MOTIF/SANS_SANCTION/<palier>`, **même famille** — c'est la seule façon de
    comparer les deux moitiés de l'échelle) et **ne vaut aucune réparation
    payée** : le correcteur ne l'anticipe pas au moment de produire, donc l'appel
    n'achèterait rien. Coût d'exploitation **inchangé**.
  - 🛑 **Une preuve manquante ne fait toujours JAMAIS échouer l'analyse.**
    `level_evidence` reste **hors de `CompetenceAnalysisValidator`**, seul
    habilité à rendre `FAILED`, **y compris sous v5 où le schéma la rend
    requise** : c'est le fournisseur qui l'exige, jamais nous. La méthode
    s'appelle désormais **`estExclueDuValidateur`** (et non plus
    `estOptionnelle`) parce que le nom invitait à recopier le `required` du JSON
    dans le jeu de clés vérifié — ce qui aurait fait **rejeter 100 % des
    sorties** qui l'omettent : le piège exact de
    `EvaluationOutputValidator.CHAMPS_V4`.
  - **Le numéro reste résolu en TEXTE avant persistance**, aux paliers bas comme
    aux hauts : `analysis_json.level_evidence` porte le passage, jamais l'entier
    — **aucun miroir DTO à propager sur les 3 fronts**, aucun écran modifié.
  - **Les 6 ancres qui n'avaient pas de preuve en portent une**, dont celle
    d'`A1_NON_ATTEINT` : elle désigne le passage qui **MONTRE** que le palier
    n'est pas atteint (la phrase en langue étrangère). Une ancre qui omettrait la
    preuve apprendrait au correcteur à s'en passer, précisément là où v6 veut
    qu'il ne s'en passe plus.
  - **Rang lu par ALLOWLIST explicite** (`CompetenceAnalysisFields
    .exigeLaPreuveSurTousLesPaliers`), jamais un `!= v6` — patron
    `CompetenceRubricsProvider.envoieLeNiveauCibleDeLaCompetence` : une version
    future ne doit pas hériter du comportement par accident. Retour arrière :
    `COMPETENCE_RUBRICS_VERSION=v5` + `COMPETENCE_TOOL_SCHEMA_VERSION=v4`
    reproduit le comportement d'avant **au bit près** (champ facultatif, aucune
    anomalie comptée sous le B1, rappel du prompt reformulé à l'identique).
    Aucune migration, `analysis_json` legacy intact.
  - ✅ **MESURÉ le 2026-08-16** — trois campagnes de 90 cas sur
    `golden-set-competences-v1.json`, le **même jour**, `retries=1`, même
    provider/modèle (`deepseek-v4-flash`), rapports dans `target/calibration/` :

    | | **v4/v4** | **v5/v4** | **v6/v5** |
    |---|---|---|---|
    | accord exact niveau | 71,1 % | 82,2 % | **85,6 %** |
    | accord statut critère | 88,9 % | 87,8 % | **90,0 %** |
    | B2 · A2 · B1 justes (/18) | 8 · 13 · 13 | 13 · 16 · 15 | **14 · 17 · 16** |
    | écart de palier moyen | 0,0 | +0,02 | −0,01 |
    | échec de production | 0 % | 0 % | 0 % |
    | paires confondues (tâche, /540) | 74 | 43 | **39** |

    **+14,5 points** d'accord exact, 0 échec sur 270 appels, **0,33 $** au total
    (tarifs alors configurés). 🛑 **Les deux moitiés de l'échelle montent
    ENSEMBLE** — c'était la condition de réfutation : les A2 justes passent de 13
    à 17 *pendant que* les B2 passent de 8 à 14, et l'écart moyen reste à zéro.
    Le correcteur ne note pas plus haut, il note plus juste.
  - ⚠️ **Le diagnostic initial était PLUS GROSSIER que la réalité, et la campagne
    l'a corrigé.** On croyait à un **plafonnement au A2** (« 0 B2 sur 18 » en
    base). Faux : v4 rend déjà 10 B2 sur 90 cas. Le vrai défaut est une
    **compression vers le MILIEU** — v4 rendait 27 B1 là où le corpus en attend
    18, en absorbant par le bas les B2 (9 des 18 attendus B2 sortaient B1) et par
    le haut les A2 (5 des 18 attendus A2 sortaient B1). v5+v6 décompressent les
    deux extrêmes. Corollaire : le « 0 B2 » de la base ne prouvait pas que le
    correcteur en soit incapable — il disait peut-être seulement que ces 18
    productions réelles n'étaient pas B2. **Ne pas rejouer ce raisonnement sur un
    échantillon de production sans référence.**
  - ⚠️ **Un point de la prédiction reste INVÉRIFIÉ** :
    `PREUVE_ABSENTE/SANS_SANCTION/*` vit en mémoire (`LongAdder`) et n'est pas
    exporté dans le rapport de banc, donc rien ne prouve encore que l'effort est
    devenu symétrique **dans les faits** (le modèle pourrait omettre le champ en
    bas d'échelle malgré le `required`). À exporter avant d'en tirer une
    conclusion sur le mécanisme lui-même.
- **v5 = LE NIVEAU CESSE D'ÊTRE PLAFONNÉ AU A2** (2026-08-16). Mesuré par SQL sur
  la base locale : **0 B2 sur 18 tentatives**, jamais ; une production fautive et
  une production propre avec subordonnée et conditionnel recevaient **le même
  A2** ; **aucun sujet rejoué n'a jamais rendu deux niveaux différents**. Trois
  causes, toutes **lisibles dans le prompt lui-même**, trois éditions et rien
  d'autre : **(a)** les 7 ancres v4 étaient A2×4, B1×2, A1×1 — **zéro B2, zéro
  `A1_NON_ATTEINT`** ⇒ 3 ancres ajoutées (2 B2, 1 `A1_NON_ATTEINT`), le A2 restant
  majoritaire (on ouvre le haut de l'échelle, on ne bascule pas le prior) ;
  **(b)** retrait de « *c'est même le cas le plus fréquent, et c'est normal* », une
  **consigne de répartition** — l'idée légitime (verdict et niveau indépendants,
  un critère peut être validé à un palier modeste) est conservée ; **(c)** le
  `targetLevel` de la compétence quitte le prompt (ci-dessus). v5 est **v4 au bit
  près pour tout ce qui JUGE** (rôle, les 3 verdicts et leur règle de décision,
  `commun.statuts/niveaux/contraintes_longueur`, la brièveté, le garde-fou oral,
  la preuve du niveau par numéro) — verrou `CompetenceAnalysisContractTest`, qui
  **reconstruit v4 depuis v5** par l'unique édition énumérée et exige l'égalité des
  11 sections et des 7 premières ancres. **Le CONTRAT DE SORTIE NE BOUGE PAS** :
  v5 déclare `tool_schema_version: v4`, aucun champ ajouté ni retiré, aucun miroir
  front — première version de ce module à réutiliser le schéma de la précédente
  (`TOOL_SCHEMA_BY_RUBRICS_VERSION` : `v5 -> v4` ; demander un « v5 » échoue au
  boot). ⚠️ **Bascule NON mesurée, et il n'existe AUCUN corpus de
  micro-productions avec niveau attendu** (le golden-set des 48 cas est celui des
  productions complètes) : ce qui la justifie, c'est qu'on retire des **biais
  visibles dans le prompt**, pas qu'on règle un curseur. Retour arrière :
  `COMPETENCE_RUBRICS_VERSION=v4` + `COMPETENCE_TOOL_SCHEMA_VERSION=v4`.
- **v4 = LE NIVEAU DEVIENT OPPOSABLE, il ne se nomme plus à vue** (2026-08-11).
  Sous v3 le correcteur écrivait `level_reached` d'après cinq lignes de
  descripteurs, **sans note, sans seuil, sans ancre chiffrée et sans aucun
  contrôle serveur en aval**, alors qu'une production complète **dérive** le sien
  d'une note contrainte par `applyCouplage`/`applyPlafonds` : deux grandeurs
  portaient le nom de la même échelle CECRL sans être commensurables. v4 est
  **v3 au bit près pour tout ce qui juge** (`commun.statuts`, `commun.niveaux`,
  `commun.contraintes_longueur`, et toutes les sections sauf deux) — verrou
  `CompetenceAnalysisContractTest`, qui **reconstruit v3 depuis v4** en inversant
  les 2 seules éditions (« Les cinq champs à produire » → « six » + un paragraphe
  ajouté **en fin** de section ; « des cinq prévus » → « des six prévus » dans les
  interdictions) et vérifie que les 6 ancres de v3 sont reprises **au numéro de
  preuve près**.
  - **Preuve par NUMÉRO, jamais par citation** — même technique que le contrat
    **v12** des productions, pour la même raison mesurée (`PREUVE_NON_RATTACHEE`
    = 42,9 % des appels sur les productions orales). La production part au
    correcteur **découpée en segments numérotés** par
    **`EvaluationProductionSegments`** — la classe des productions complètes,
    **appelée, jamais recopiée** (EE = une phrase, EO = un tour `Candidat :`, les
    tours examinateur montrés **sans numéro**). Nouveau champ **`level_evidence`**
    = **entier ≥ 1**, **optionnel dans le schéma** : seuls B1 et B2 se démontrent,
    et l'exiger partout pousserait à désigner un segment « par défaut ».
  - **`CompetenceLevelEvidenceGuard` est la seule autorité.** Numéro absent sur un
    B1/B2, hors bornes, ou non entier ⇒ **une** réparation actionnable
    (`CompetenceEvidenceRepairPrompt` : nomme le numéro refusé, rappelle les
    bornes **réelles**, redonne les deux sorties sûres — technique
    `EvaluationRepairPrompt`, motif mesuré : un libellé brut répare **0 preuve
    sur 8**). Cette réparation est **partagée** avec celle du validateur : une
    sortie malformée et une preuve manquante partent dans le **même** message, on
    ne double pas les appels. Après elle, le serveur **abaisse d'un palier, une
    seule fois, et ne relève JAMAIS** (philosophie `applyCouplage` /
    `applyPlafonds` / `applyConfiance`).
  - 🛑 **Une preuve manquante ne fait JAMAIS échouer l'analyse** — c'est pourquoi
    `level_evidence` est **volontairement hors du `CompetenceAnalysisValidator`**,
    qui a le pouvoir de rendre `FAILED`. Une analyse perdue coûte au candidat sa
    production et son quota ; un niveau prudent ne lui coûte qu'un affichage.
  - **Le numéro est résolu en TEXTE avant persistance** (comme
    `resolvePreuveSegments`) : `analysis_json.level_evidence` porte le passage,
    jamais l'entier, donc **aucun miroir DTO à propager sur les 3 fronts**. Le
    passage **n'est exposé à aucun front** (rien ne l'affiche — pas d'API morte),
    mais il est **persisté** : c'est ce qui permettra de répondre en une requête
    SQL à « sur quoi ce B2 était-il fondé ? ».
  - Abaissements comptés par **`CompetenceLevelDowngradeMetrics`** (motif +
    `avant->après`), **distinct** de `EvaluationRefusalMetrics` (un refus coûte la
    tâche) et de `EvaluationPurgeMetrics` (une purge retire une phrase) : les
    mélanger rendrait la mesure illisible.
  - ⚠️ **AUCUNE campagne ne l'appuie**, et ce qui tient la règle reste la
    contrainte dure (schéma `integer`/`minimum:1` + contrôle serveur), pas une
    mesure a posteriori. ⚠️ En revanche, la phrase « il n'existe aucun corpus
    pour la voie Compétences » est **révoquée** : il en existe un depuis le
    2026-08-16 (cf. le banc ci-dessous). L'instrument existe, la mesure reste à
    payer.
  - Retour arrière : `COMPETENCE_RUBRICS_VERSION=v3` +
    `COMPETENCE_TOOL_SCHEMA_VERSION=v3` — sous v3 le découpage n'est même pas
    calculé et le prompt repart **inchangé d'un octet**
    (`CompetenceAnalysisFields.porteLaPreuveDuNiveau`).
- **v3 = UN LEVIER NOMME UNE OPÉRATION DE LANGUE** (2026-08-16). Chaque levier
  gagne un **`procede` requis**, `enum` reprenant **exactement** `MarqueurPalier`
  — la même énumération, la même table de compatibilité procédé ⇄ palier
  (`MarqueurPalier.demontre`), jamais une copie. Motif, cas réel : les trois
  leviers servis vers le B2 étaient « Rends ton invitation plus chaleureuse »,
  « Propose une alternative concrète », « Termine par une formule engageante » —
  des conseils de **ton**, qu'on peut suivre à la lettre en restant A2. Le filet
  `EvaluationMarqueursA2` ne pouvait rien y voir (liste fermée de 6 mots-outils,
  égalité exacte) et **il ne faut pas l'élargir** : deux variantes plus larges ont
  déjà été mesurées et rejetées côté productions pour faux positifs.
  - 🛑 **RÈGLE ABSOLUE : un levier n'est JAMAIS purgé à cause de son procédé.**
    Ce qui tient la règle, c'est le **schéma** — le modèle ne peut plus produire
    un conseil de ton sans le rattacher à un moyen de langue réel —, pas une
    sanction à l'affichage. Les leviers portent le **bloc entier** (purgés sous
    leur minimum et non réparés, tout est abandonné) : purger sur ce motif
    viderait l'écran du candidat. Donc procédé **manquant**, **inconnu** ou qui
    **sur-vend** le palier cible ⇒ le levier est **servi tel quel**, l'anomalie est
    **comptée**, et **aucune réparation payée** n'est déclenchée.
    `CompetenceNiveauViseProcedeAudit` est la seule autorité ; il ne retire
    jamais un levier, seulement le procédé fautif de l'objet persisté.
  - **Le procédé fautif n'est PAS persisté** (arbitrage). Le champ n'est exposé à
    **aucun front** (doctrine `level_evidence` — pas d'API morte) : il existe pour
    répondre en **une requête SQL** à « ce levier nommait-il un vrai moyen de
    langue ? ». Une colonne pouvant contenir n'importe quelle chaîne du modèle ne
    répond à rien ; un procédé **absent** dit exactement « ce levier n'était pas
    vérifiable », et le compteur porte le motif.
  - **Le validateur ADMET le procédé, il ne le juge pas** : une violation de la
    section `LEVIERS` est **fatale**, l'y ranger reviendrait à purger. Il n'ajoute
    donc que la clé à l'allowlist du levier.
  - Compteurs : `CompetenceNiveauViseMetrics.procedeAnormal` →
    `PROCEDE_ANORMAL/{ABSENT,INCONNU,SUR_VENDU}`. Famille inchangée, jamais
    mélangée à `EvaluationRefusalMetrics` ni `EvaluationPurgeMetrics`.
  - Le filet **`CompetenceNiveauViseLevierFilter`** (marqueur A2 vendu pour un
    palier supérieur) est **conservé inchangé** : lui purge, c'est un motif
    différent, et il garde sa réparation. Ne pas le fusionner avec le nouveau
    contrôle, ne pas le désactiver.
  - **v3 = v2 au bit près** pour tout ce qui juge, pour `exemple_cible` et pour
    `a_retenir` : seule la section « Les leviers » est éditée, plus un `procede`
    ajouté à chaque levier des 2 ancres. Verrou :
    `CompetenceNiveauViseContractTest` **reconstruit v2 depuis v3** (rubriques et
    tool-schema) par une liste **énumérée** d'éditions.
  - **Retour arrière réel** : `COMPETENCE_NIVEAU_VISE_{RUBRICS,TOOL_SCHEMA}_VERSION=v2`
    (ou `v1`) — sous v2 le champ n'est ni demandé dans le prompt, ni admis par le
    validateur (il redevient une clé hors contrat), ni compté. Conditionné par une
    **allowlist explicite** (`CompetenceNiveauViseFields.porteLeProcedeDesLeviers`,
    patron `CompetenceRubricsProvider.envoieLeNiveauCibleDeLaCompetence`), jamais
    par un test `!= v3`. Aucune migration.
  - ⚠️ **Non mesuré, et il faut le dire** : il n'existe **aucun corpus** de
    micro-productions avec un niveau attendu (le banc porte sur les productions
    complètes). Défendable sans mesure parce qu'on **ajoute une contrainte de
    schéma** — la façon la plus fiable de rendre un comportement impossible — et
    qu'on ne déplace **aucun seuil, aucune note, aucun niveau**.
- **v2 = LE PALIER DEVIENT EXIGIBLE** (2026-08-16). Trois changements, un seul
  motif — mesuré en base : un candidat a copié-collé le `exemple_cible.texte`
  servi comme « version pour viser B2 », l'a resoumis, et l'appel 1 l'a réévalué
  **A2** (`written_production = analysis_json->'pour_viser'->'exemple_cible'->>'texte'`
  vaut `true`). Rien n'obligeait ce texte à être au niveau annoncé, et la consigne
  tirait dans l'autre sens (« longueur PROCHE de la sienne »).
  - **Le texte modèle vise la MARCHE SUIVANTE** : `palierCible = min(constaté + 1,
    visé)`, ramené dans `[A2, B2]`. **Autorité unique**
    `CompetenceNiveauViseService.palierCible`, à côté de la garde « constaté ≥ visé
    ⇒ aucun appel » (inchangée). Effet voulu : les 2 ancres few-shot (A2→B1,
    B1→B2) couvrent désormais 100 % des cas — le cas réel était un saut A2→B2
    **sans aucune ancre**. Le palier VISÉ du candidat reste calculé comme avant
    (`TargetProcedure.niveauVise`, plancher de la démarche) mais devient le
    **plafond** de l'ambition. `SkillLevelProgressResolver` / `SituationNiveauVise`
    **inchangés** : c'est là que le candidat se situe par rapport à son objectif
    réel. ⚠️ `analysis_json.pour_viser.niveau_vise` et donc
    `SkillNiveauViseDto.niveauVise` portent le **palier cible**, pas l'objectif —
    aucun changement de type, seuls les libellés fronts bougent.
  - **`marqueurs_du_palier` requis** : 2 à 3 passages **recopiés du texte modèle**
    + un `type` d'une énumération fermée (`MarqueurPalier` : `REGISTRE_AJUSTE` /
    `ARTICULATION_LOGIQUE` A2, `SUBORDINATION` / `LEXIQUE_PRECIS` B1, `NUANCE` /
    `OBJECTION_TRAITEE` B2). Doctrine du dépôt : un champ **requis et vérifiable**
    force le contenu, une consigne ne serait qu'un vœu. Extraits résolus par
    `util/SegmentsSurlignage` (mécanique partagée, jamais recopiée) ; un type qui
    **sur-vend** le palier cible est retiré (`objection_traitee` pour viser A2). La
    table `MarqueurPalier` est **opposée à `commun.marqueurs_palier` au BOOT**
    (divergence ⇒ échec du démarrage). **Persistés, exposés à aucun front** (même
    arbitrage que `level_evidence`) : ils répondront en SQL à « sur quoi ce B1
    était-il fondé ? ».
  - **Longueur du texte modèle bornée** par `skill_prompts.recommended_min/max_words`
    (**plafond seul, au mot près, sans tolérance** — patron `ProductionTextBounds`
    + `ProductionPayloadSupport.countWords`), bornes **injectées dans le prompt**
    (`mots_min`/`mots_max`). `null` sur un sujet **oral** (il porte une durée, pas
    une fourchette) : on n'invente pas de borne.
  - 🛑 **Rien ne disparaît de l'écran.** Les violations sont désormais rangées
    **par section** (`CompetenceNiveauViseValidator.Section`, patron
    `VersionCibleeValidator`) : `exemple_cible` et `a_retenir` tombent **seules**,
    seuls la racine et les **leviers** emportent le bloc. Un marqueur retiré, comme
    un segment, ne coûte que sa propre mise en évidence et **n'ouvre aucun appel
    payé**. **Une seule réparation par bloc, tous motifs confondus**
    (`CompetenceNiveauViseRepairPrompt.pour`) : leviers purgés **et/ou** texte hors
    bornes partent dans le **même** message actionnable.
  - Compteurs : `CompetenceNiveauViseMetrics` gagne `Motif.TEXTE_HORS_BORNES`,
    `sectionAbandonnee(section, motif)` et `marqueurRetire(motif)` — même famille,
    jamais mélangée à `EvaluationRefusalMetrics` ni `EvaluationPurgeMetrics`.
  - Retour arrière sans migration : `COMPETENCE_NIVEAU_VISE_RUBRICS_VERSION=v1` +
    `COMPETENCE_NIVEAU_VISE_TOOL_SCHEMA_VERSION=v1` — sous v1 **tout** ce chantier
    est inerte (ni marqueurs, ni bornes de longueur). Verrou :
    `CompetenceNiveauViseContractTest` reconstruit le tool-schema v1 depuis v2 par
    une liste **énumérée** d'éditions.
  - **Fronts** : l'intertitre nomme le palier cible — « Pour passer au niveau B1 »
    (`pourPasserAuTitle`, web `skill-ui/ActionPlan.tsx` ⇄ mobile
    `widgets/action_plan.dart`), déclaré une fois par front. `pourViserTitle`
    **reste** pour les productions complètes, dont le `niveauVise` est toujours
    l'objectif. ⚠️ **Aucune campagne** : le corpus de calibration est celui des
    productions complètes, il n'existe aucun corpus pour cette voie.
  Persisté dans `user_skill_attempts.analysis_json.pour_viser` — **aucune
  migration**.
  - **Best-effort, jamais bloquant** : lancé par `SkillAnalysisAsyncRunner`
    **après** que l'analyse est persistée et `EVALUATED`, **hors transaction**
    (même invariant que `ProductionPipelineAsyncRunner`), toute exception avalée,
    **aucun rejeu**. Si le bloc manque, l'écran reste utile. ⚠️ Conséquence
    assumée : la tentative passe `EVALUATED` **avant** l'arrivée du bloc — les
    fronts doivent traiter `niveauVise == null` comme un cas NORMAL, pas une
    erreur (même course que `version_ciblee` côté productions).
  - **Aucun appel émis** si le visé n'est pas **strictement au-dessus** du
    constaté, si l'analyse ne porte aucun niveau (contrat v1/v2), si le palier
    visé est introuvable, ou si `niveau-vise.enabled=false`. Économie réelle, pas
    seulement un bloc absent.
  - **Deux contrôles serveur.** (1) **les `segments` sont un confort de lecture,
    le texte est la pièce centrale** (aligné sur `version_ciblee` le
    **2026-08-12**) : un segment introuvable dans `exemple_cible.texte`, mal
    formé ou au-delà du 3ᵉ est **retiré**, `exemple_cible` survit dès que son
    `texte` est valide (présent, non vide), et la section ne tombe que si le
    **texte** est fautif. Un extrait introuvable **n'ouvre plus droit à
    réparation payée** — il ne coûte que son surlignage. La comparaison neutralise
    la **typographie** (`util/TexteNormalise`) et l'extrait servi est la
    **sous-chaîne originale exacte** du texte, le front surlignant par simple
    recherche de chaîne : rien d'inventé n'est jamais affiché. **Mécanique
    partagée** avec les productions — `util/SegmentsSurlignage`, câblé sur les
    noms de champs de chaque contrat — précisément parce que deux copies avaient
    divergé (l'ancienne règle « un extrait introuvable emporte tout le bloc »
    était restée dure ici après avoir été assouplie là-bas). Le tool-schema v1
    continue d'exiger 2 à 3 segments : **aucune version de contrat n'a bougé**,
    seul le serveur a cessé de punir.
    (2) filet marqueurs A2 sur les leviers, **3ᵉ occurrence** du même défaut :
    `EvaluationMarqueursA2.designe` est réutilisé tel quel (le levier est inspecté
    comme `action + « exemple »`, ce qu'il est sémantiquement), et
    `EvaluationMarqueursA2.sousLeNiveauVise` a été **extrait** à cette occasion,
    `VersionCibleeLevierFilter` l'utilisant désormais aussi. Reste < 2 leviers ⇒
    une réparation, puis abandon. **Une seule réparation par bloc, tous motifs
    confondus** — et c'est désormais le **seul** motif qui en vaut une. Compté
    `EvaluationPurgeMetrics.MARQUEUR_PALIER_LEVIER_COMPETENCE`.
  - **Compteurs `CompetenceNiveauViseMetrics`** (bloc abandonné par motif,
    réparation payée, segment retiré) : famille **distincte** de
    `VersionCibleeMetrics` (même mesure, mais sur l'écran des productions), de
    `EvaluationRefusalMetrics` (un refus coûte la tâche) et de
    `EvaluationPurgeMetrics` (une purge retire une phrase). Pas de compteur « par
    section » ici : les 3 champs du contrat sont requis ensemble, le bloc tombe
    d'un bloc — seul un **segment** peut disparaître seul.
  - **Niveau visé = `TargetProcedure.niveauVise(procedure, targetLevel)`**, la
    démarche fait **plancher** ; repli sur `skills.target_level`. Ne jamais
    réécrire cette table.
