# Module « Compétences TCF » (micro-entraînement EE/EO)

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Contenu verbatim, aucune réécriture.**
> Origine : lignes 3238-3282, 3395-3422, 3479-3486, 3642-3853 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier porte la loi de ce sous-système : on l'ouvre **quand on travaille dedans**.
> Fichier jumeau : `docs/decisions/competences.md`
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

## Module « Compétences TCF » (micro-entraînement EE/EO)

Voie **parallèle** aux productions complètes, pas une réutilisation : le candidat
travaille **une micro-compétence à la fois** sur un « petit sujet » de quelques
phrases. Schéma en `V025`, contenu seedé en `V300..V305` (lot 1) puis
`V312..V317` (lot 2).

⚠️ **RÈGLE RÉVOQUÉE À MOITIÉ le 2026-08-11 : niveau OUI, note /20 NON.**
L'ancienne formule « cette voie ne rend ni note /20 ni niveau CECRL » **ne vaut
plus pour le niveau**. Elle laissait le candidat sans réponse à « où j'en suis »,
alors que c'est exactement ce qu'il vient chercher : sa démarche exige un palier
(CSP→A2, CR→B1, NAT→B2) et l'écran ne le situait nulle part. Depuis le contrat
**v3**, le correcteur attribue un `level_reached` (`A1_NON_ATTEINT|A1|A2|B1|B2`,
profil TCF IRN, **jamais C1/C2**). **La note /20 reste interdite et le restera** :
aucun champ du tool-schema ne peut la loger, et c'est le schéma qui tient la
règle, pas une consigne. Ne pas réintroduire l'ancienne formule au motif qu'elle
est encore écrite quelque part — ce qui suit fait foi.

**Où ça vit** — tables `skills`, `skill_prompts`, `skill_references`,
`user_skill_attempts` (DDL `00_schema/V025__schema_competences_tcf.sql`, seed
`300_tcf/competences/V300..V317`). Backend : `service/competence/` (analyse IA) +
`SkillService` / `SkillAttemptService` / `SkillStatusResolver` /
`SkillAnalysisAccessService` / `AdminSkillService`. **12 endpoints utilisateur**
(`/api/skills*`, `/api/skill-attempts*`, `/api/skill-prompts*`) et **11 endpoints
admin** (`/api/admin/skills*`, `/api/admin/skill-prompts*`) — détail dans
`docs/api-endpoints.md`. Fronts : web `app/_components/competences/` + routes
`…/entrainement/tcf/{ee,eo}/tache/[n]/competences/…`, mobile
`lib/screens/tcf_production/competences/` + `core/models/skill_models.dart` ;
point d'entrée = 3ᵉ onglet « Compétences » à côté de « Sujets » et « Exemples »,
qui **pousse** vers le nouvel écran au lieu d'ouvrir un onglet local.

- **DEUX APPELS LLM SÉPARÉS, invariant à ne pas casser.** L'**appel 1** juge et
  **ne connaît jamais le palier visé par le candidat** ; l'**appel 2** (« pour
  viser X ») reçoit niveau constaté + niveau visé et produit le plan d'action.
  Motif **mesuré** côté productions : donner l'objectif au correcteur fait tomber
  l'accord exact de **81,8 % à 75,6 %** (campagnes v10/v11). Montage calqué sur
  `service/versionciblee/`. **Ne pas fusionner.** ⚠️ **Depuis v5, l'appel 1 ne
  reçoit PLUS AUCUN niveau cible** — même pas celui de la **compétence** (donnée
  éditoriale du sujet, comme `production_tasks.niveau_cible`), qui y était jusqu'à
  v4 sans que la grille le nomme nulle part : une étiquette de palier posée dans
  le même objet JSON que le texte à niveler. Autorité unique :
  `CompetenceRubricsProvider.envoieLeNiveauCibleDeLaCompetence()`, allowlist des
  versions v1..v4 (un retour arrière doit reproduire le prompt d'avant, une
  version future ne doit pas hériter du défaut). Verrous :
  `CompetenceAnalysisServiceTest`, `CompetenceRubricsProviderTest`.
- **Contrat de l'analyse (appel 1)** : rubriques
  `prompts/competence-analysis-rubrics-v5.json` + tool-schema
  `prompts/competence-analysis-tool-schema-v4.json` (`profile: TCF_IRN`, paire
  `rubrics-version` ⇄ `tool_schema_version` validée au boot — **aucune consigne de
  notation en dur dans le Java**). **v3 = v2 au bit près pour tout ce qui JUGE**
  (rôle et périmètre, les 3 verdicts et leur règle de décision, la brièveté qui
  n'est pas un défaut, le garde-fou oral, `commun.statuts`) — verrouillé par
  `CompetenceAnalysisContractTest`, qui compare les blocs et **reconstruit** la
  section d'accentuation de v2 depuis celle de v3 (2 éditions inversées, technique
  de `ProductionEvaluationContractTest`). Sortie stricte à **5 champs** (6 sous
  v4), `additionalProperties: false` : `status` (`VALIDATED|PARTIAL|NOT_VALIDATED`),
  **`level_reached`** (`A1_NON_ATTEINT|A1|A2|B1|B2`), `verdict` (20 mots),
  **`strength_tag`** et **`focus_tag`** (**3 mots** chacun — des étiquettes, pas
  des phrases). **Retirés du contrat** : `success_point`,
  `improvement_priority`, `improved_version` — même mouvement que v14/v8 côté
  productions (retirer un champ du schéma est la façon la plus fiable de le faire
  disparaître) ; les leviers de l'appel 2 les remplacent.
  ⚠️ **Legacy non migré** : les `analysis_json` déjà persistés portent les 5
  anciennes clés. `SkillAnalysisDto` les expose encore, **tous nullables**, et le
  jeu de clés attendu d'une NOUVELLE sortie suit la version du contrat
  (`CompetenceAnalysisFields.cles(toolSchemaVersion)`) — c'est ce qui garde
  `COMPETENCE_RUBRICS_VERSION=v2` + `COMPETENCE_TOOL_SCHEMA_VERSION=v2` (ou v1)
  réellement jouable. `LearningPlanObservationService` replie
  `improvement_priority` → `focus_tag` → `verdict`.
  Contraintes de longueur **en mots** déclarées par la grille (20 / 3 / 3),
  doublées de `maxLength` en caractères dans le schéma ; le validateur tolère
  ×1,2 avant de rejeter. Sortie invalide → **un seul rejeu** avec les violations,
  puis **échec net** (`FAILED`) — jamais d'analyse partielle.
- **Contrat du plan d'action (appel 2)** : `service/competence/niveauvise/` +
  `prompts/competence-niveau-vise-{rubrics,tool-schema}-v3.json`. Sortie stricte à
  **3 champs**, `additionalProperties: false` : `leviers[2..3]`
  `{action ≤6 mots impératif, exemple ≤5 mots, procede}`, `exemple_cible`
  `{texte, segments[2..3] {extrait, apport ≤3 mots}, marqueurs_du_palier[2..3]
  {extrait, type}}`, `a_retenir` `{formule ≤8 mots, explication ≤14 mots}`.
  **Aucun champ de note, de verdict ni de niveau** : le serveur pose lui-même
  `niveau_vise` / `niveau_constate`.
- **Dérivé serveur `SkillLevelProgressResolver`** (jamais un front, jamais le
  LLM) : compare `level_reached` au palier visé et rend `SituationNiveauVise` +
  son libellé, l'**échelle de 3 crans** se terminant sur l'objectif (B2 →
  A2·B1·B2) et l'**index du curseur** (ramené dans l'échelle s'il est en dessous
  du premier cran). Exposé par `SkillLevelProgressDto`. Le palier visé est
  **recalculé à la lecture**, jamais figé dans l'analyse : un candidat qui passe
  de CR à NAT vise soudain le B2, et ses tentatives passées doivent l'afficher.
  Libellés gelés par `SkillLabelsTest`, **à mirrorer sur web et mobile**.
- **Config** : `sejourfr.competences.analysis` (`max-tokens: 600`,
  `temperature: 0`, `free-analyses: 3`, `max-text-words: 400`,
  `max-audio-duration-seconds: 180`) et `sejourfr.competences.niveau-vise`
  (`enabled: true`, `max-tokens: 900`, `temperature: 0`, `max-leviers: 3`), POJO
  `CompetenceProperties` **aux mêmes valeurs par défaut que le YAML**. Le
  **fournisseur LLM n'a de réglage propre ni pour l'un ni pour l'autre** :
  `CompetenceLlmConfig` et `CompetenceNiveauViseLlmConfig` lisent
  `sejourfr.production-evaluation.provider`, comme tout le reste (règle « un seul
  correcteur configurable »). Ne pas leur en donner un second.
  Retours arrière, sans migration : `COMPETENCE_RUBRICS_VERSION=v4` +
  `COMPETENCE_TOOL_SCHEMA_VERSION=v4` pour l'analyse (⚠️ **le rang des deux
  n'est plus le même** : v5 tourne sur le tool-schema **v4**, demander « v5 »
  échoue au boot),
  `COMPETENCE_NIVEAU_VISE_ENABLED=false` pour le plan d'action (ou ses contrats
  antérieurs par `COMPETENCE_NIVEAU_VISE_{RUBRICS,TOOL_SCHEMA}_VERSION=v2`, ou
  `=v1`).
  ⚠️ **Bascules v3, v4 et v5 de l'analyse, et v2/v3 du plan d'action, NON
  mesurées au banc** (cf. `docs/notation-ia-eo-ee.md` §11 bis, qui le dit
  franchement au lecteur). Le motif — « il n'existe aucun corpus » — a **cessé
  d'être vrai le 2026-08-16**, cf. le banc ci-dessous : elles restent non
  mesurées, mais plus faute d'instrument.
- **Banc de mesure du module — `CompetenceCalibrationBenchTest`** (2026-08-16),
  **jumeau** de `CalibrationBenchTest` et **jamais son remplaçant** : corpus
  séparé `src/test/resources/calibration/golden-set-competences-v1.json`
  (**90 micro-productions annotées**, 6 tâches × 5 paliers × 3, plus 33
  productions **réelles hors score**), grandeurs séparées (**palier** +
  **verdict de critère**, jamais une note /20 — le contrat n'a aucun champ où la
  loger). Mêmes garde-fous que l'autre banc : **opt-in strict** (jamais dans
  `./mvnw verify`), provider et modèle **non surchargeables**,
  `calibration.retries` figé dans le rapport, `sorties_refusees_pct` et
  `echec_production_pct` **distincts**. Détail d'usage :
  `docs/plan-tests-backend.md`.
  - **La vérité terrain se déduit de traits STRUCTURELS**, listés par cas dans
    `traits_structurels` et lus dans `commun.niveaux` de la grille active — pas
    d'un jugement esthétique. C'est la parade à la circularité : une IA écrit les
    productions, une IA les note. Un cas se conteste en montrant que le trait
    annoncé n'est pas dans la production.
  - **Le verdict de critère est INDÉPENDANT du palier**, et le corpus le teste :
    les cas `HORS_SUJET_RICHE` sont en langue B2 avec un critère `NOT_VALIDATED`.
    Un correcteur qui aligne l'un sur l'autre y échoue.
  - **Métrique de SENSIBILITÉ**, propre à ce banc : 6 **échelles** de 5
    productions du **même sujet** à des paliers différents, et le rapport compte
    les paires *ordonnées / inversées / confondues*. C'est la question du
    dossier — mesuré en base : **0 B2 sur 18 tentatives**, deux productions
    manifestement inégales notées toutes deux A2. Le rapport publie aussi la
    **répartition des paliers rendus** et `paliers_jamais_rendus` : un bon taux
    d'accord peut coexister avec un palier entier jamais produit.
  - **Pilote du 2026-08-16, 10 cas, consignes v6 / contrat v5, `retries=1`** :
    0 sortie refusée, 0 cas perdu, accord exact **60 %** — **100 % sur
    A1_NON_ATTEINT, A1 et A2, 0 % sur B1 et B2**, tous les cas hauts retombant en
    A2 (un seul B1 rendu, **aucun B2**). Coût réel **0,0129 $** (88 980 tokens
    d'entrée, 1 562 de sortie). Le défaut mesuré en base est donc **reproduit par
    l'instrument**, sur un échantillon trop petit pour conclure.
  - ⚠️ **Le coût persisté ment sur ce module** : chaque appel est arrondi au cent
    **supérieur** (`Math.ceil`), donc une campagne de micro-analyses s'affiche
    ~10× trop cher. Le rapport publie `cout_reel_usd`, recalculé depuis les tokens
    et les tarifs du provider actif — c'est ce chiffre qu'on cite.
  - **Les 33 productions réelles sont HORS SCORE** : tableau `temoins_reels`
    séparé, `hors_score: true`, exclues de tous les agrégats par
    `CompetenceCaseRun.exploitable()`. Elles n'ont aucune vérité terrain et ne
    servent qu'à vérifier le réalisme des cas synthétiques. **Ne jamais les faire
    entrer dans un taux d'accord.**
  - `CompetenceGoldenSetTest` fige le corpus (couverture, pièges, échelles,
    séparation des témoins) **sans aucun appel LLM** : lui tourne dans `verify`.
- **Volume figé** : 6 tâches (`EE1..EE3`, `EO1..EO3`) × **8 compétences** × **15
  sujets** × **3 références** (`INSUFFICIENT`/`EXPECTED`/`EXCELLENT`) = 48 / 720 /
  2160. Les 6 tâches sont un référentiel officiel (**enum `SkillTaskCode`, pas de
  table**). Ce compte est verrouillé par **`SkillSeedIT`**, pas par le DDL : la
  contrainte `display_order BETWEEN 1 AND 8` gelait le catalogue (les 8 rangs
  légaux étant tous seedés, l'admin ne pouvait plus rien créer) — elle est passée
  à **50**, et la règle produit vit désormais dans le test. Ne pas la remettre.
- **Les seeds sont GÉNÉRÉS**, jamais écrits à la main. Le générateur est
  **versionné** dans `backend_sejourfr/tools/competences/` (`generer_seed.py` +
  `contenu/*.json`, une fiche par tâche) et se rejoue par
  `cd backend_sejourfr && python3 tools/competences/generer_seed.py` (Python 3
  seul, aucune dépendance). **On édite le JSON puis on régénère, jamais le SQL** :
  modifier un `V300..V317` à la main désynchronise les deux et la régénération
  suivante écrase le correctif. Le script valide le contenu (8×15×3, cohérence
  EE mots / EO durée, unicité des codes **et unicité éditoriale** — pas deux fois
  le même titre ni la même situation dans une tâche, quasi-doublons de contexte
  détectés par trigrammes) et **refuse de générer** sur du contenu non conforme ;
  les UUID sont déterministes (uuid5 sur le code métier), donc stables d'un
  environnement à l'autre.
  - **Deux lots, parce que le lot 1 est déjà appliqué.** Les sujets de
    `display_order` 1-5 sortent en `V300..V305` (+ guidage `V306..V311`), ceux de
    6-15 en `V312..V317`. Régénérer doit rendre `V300..V311` **au bit près** —
    toute autre sortie invaliderait leur somme de contrôle Flyway sur les bases
    qui les ont jouées. Un nouveau lot de contenu = de nouvelles migrations,
    jamais une réécriture des précédentes.
  - Il ne sert qu'à **republier depuis une base propre**. Une fois les migrations
    appliquées, le **contenu vivant s'édite depuis la console d'administration**
    (`admin/features/skills/`) — c'est la base qui fait foi, pas le JSON.
  - Le générateur a vécu hors dépôt jusqu'au 2026-08-06 : les six migrations
    portaient « ne pas éditer à la main » sans que le seul outil autorisé à les
    produire soit trouvable.
- **Deux textes distincts sur une compétence**, à ne jamais rendre au même
  endroit : `skills.description` = la courte explication (encart « Pourquoi cet
  exercice ? »), `skills.general_criterion` = le critère général travaillé (encart
  « Critère travaillé »). Et **ni l'un ni l'autre** n'est
  `skill_prompts.unique_criterion`, qui est le critère précis d'**un** sujet.
- **Freemium — règle en vigueur depuis le 2026-08-10.** ⚠️ **L'ancienne règle
  (« aucun sujet n'est verrouillé, seule l'analyse IA est premium ») est
  RÉVOQUÉE** : elle ouvrait les 720 sujets à un compte gratuit, si bien que le
  module entier — le cœur de l'entraînement quotidien — ne donnait aucune raison
  de payer, et les 3 analyses offertes étaient la seule friction. Ne pas la
  réintroduire au motif qu'elle est encore écrite quelque part : ce qui suit
  fait foi. Pour un compte **sans accès TCF** (`hasTcf == false`) :
  - **une seule compétence ouverte par tâche**, celle de `display_order` le plus
    bas encore actif (= rang 1 sur le contenu publié) → **6 compétences** pour
    les 6 tâches ;
  - **plus la compétence de la priorité n°1 de son Plan**, si elle n'y est pas
    déjà. Sans cette exception, un diagnostic désignant une compétence de rang 5
    cadenasserait l'**étape 1** du Plan et rendrait le Plan entier inutilisable —
    or c'est la colonne vertébrale du produit ;
  - dans une compétence ouverte, **les 2 premiers sujets actifs** seulement
    (`SkillAccessService.FREE_PROMPTS_PER_SKILL`). ⚠️ **Ne pas l'aligner sur les
    5 sujets d'une étape du Plan** (`LearningPlanStep.PROMPTS_PAR_ETAPE`) : les
    deux constantes disent des choses différentes, et le plafond à **2/5** sur
    l'étape n°1 est la conséquence voulue — aucune étape n'est finissable sans
    abonnement (arbitré le 2026-08-11) ;
  - **les 3 analyses IA offertes à vie ne bougent pas** : un sujet ouvert reste
    analysable dans la limite du quota existant (`free-analyses`, décompte
    inchangé). Sur un sujet ouvert, produire, s'auto-évaluer, se relire et lire
    les 3 références restent gratuits et illimités ; la garde des références
    (« au moins une tentative ») est inchangée.
  - Un **abonné TCF** n'a aucun verrou.
  **Une seule autorité : `SkillAccessService`** (`SkillAccess.isSkillLocked` /
  `isPromptLocked`), qui s'appuie sur `LearningPlanPriorityResolver` — extrait
  exprès pour que l'ordre des priorités du Plan et le verrou ne puissent pas
  diverger. Aucun mapper, aucun controller, aucun front ne réimplémente la
  règle : les DTO portent un `locked` (`SkillDto`, `SkillPromptDto`,
  `SkillPromptSummaryDto`, `LearningPlanPriorityDto`, `LearningPlanSkillDto`,
  `PlanRecommendedExerciseDto`), et le verrou est **opposable serveur** —
  `SkillAccessService.assertCanProduce` rend **403** à la création d'une
  tentative comme sur `analyse` et `retry`, même philosophie que
  `AttemptService.enforceMockExamSlotAccess`. Résolution **groupée** (4 requêtes
  au plus, 1 seule pour un abonné) : un écran, c'est 24 compétences × 5 sujets.
  Le quota d'analyses, lui, se consomme toujours à l'**acceptation**
  (`analysis_requested = true`), pas au succès : sinon un retry après échec
  fournisseur en offrirait davantage.
- **Statut d'un sujet dérivé serveur**, jamais recalculé par un front
  (`SkillStatusResolver`) : `TODO` / **`TREATED`** / `VALIDATED` / `TO_REINFORCE`.
  `TREATED` (« Fait ») est le 4ᵉ statut qu'impose le freemium — une production
  sans analyse n'a pas de verdict, l'afficher « Validé » ou « À renforcer » serait
  faux.
> ⚠ **CONTRADICTION #2** — voir `docs/decisions/contradictions-ouvertes.md`. Non tranchée.

- **Libellés FR = contrat gelé sur les 4 couches.** Ces chaînes ne transitent pas
  par le réseau : le backend, le web, le mobile et l'admin en tiennent chacun une
  copie écrite à la main, donc rien n'empêche une couche de dériver — et c'est
  arrivé (`NOT_VALIDATED` affiché en trois formulations différentes). Elles sont
  figées par un test **par couche**, sur exactement les mêmes chaînes :
  `SkillLabelsTest` (backend), `lib/skill-labels.test.ts` (web),
  `test/skill_models_test.dart` (mobile). Un libellé qui bouge, ce sont **quatre**
  fichiers à changer dans la même passe.
  ⚠️ **Les tests front cités ici sont un héritage** : depuis le 2026-08-09 on
  n'écrit plus de test sur les fronts (cf. § Tests). Le gel de libellé n'y est donc
  plus reproduit pour un nouveau contrat — seul `SkillLabelsTest` continue de
  l'assurer côté backend, et la concordance des copies front se vérifie **à la
  lecture**. Ne pas créer de nouveau `*.test.ts` / `*_test.dart` pour ça.
  Côté fronts, on lit toujours la constante
  partagée (`SKILL_*_LABEL` en TS, le `label` de l'enum en Dart) — jamais une
  chaîne recopiée dans un composant, qui est exactement la façon dont le web avait
  décroché.
- **Garde des références** : `GET /api/skill-prompts/{id}/references` exige **au
  moins une tentative**, jamais « une tentative réussie » — l'écran de résultat
  d'une tentative `FAILED` est précisément le moment où le candidat en a besoin.
- **`POST /api/skill-attempts/{id}/analyse`** : demande l'analyse d'une production
  déjà `RECORDED` (rendue sans IA), pour le candidat qui produit gratuitement puis
  s'abonne — sans elle, il devait refaire le sujet et **perdait sa production**.
  Refusé (422) sur tout autre statut, sinon le quota serait contournable.
- **`POST .../retry`** ne re-consomme pas le quota (l'échec n'est pas du fait du
  candidat) : c'est ce qui **impose** le plafond persisté `retry_count` ≤ 3,
  appliqué dans le service (422) **et** en base.
- **Transcription SYSTÉMATIQUE, audio JAMAIS conservé** (cf. la section
  transverse « L'audio d'une production de candidat n'est pas conservé »).
  ⚠️ **Révoque** l'ancienne règle « Whisper seulement si une analyse est
  demandée » et « l'audio est conservé dans tous les cas, les deux fronts
  permettent de se réécouter » : sans audio gardé, ne pas transcrire ne
  laisserait **rien** de la production. Elle est donc écrite dès la soumission,
  analyse demandée ou non, et l'écran de résultat n'a plus de lecteur. Pipeline
  async **sans transaction englobante**, même invariant que
  `ProductionPipelineAsyncRunner` (+ `SkillAnalysisFailureRecorder` en
  `REQUIRES_NEW` pour rendre `FAILED` durable).
- **Garde-fou EO, identique à celui des productions complètes** : la **durée n'est
  jamais envoyée** au correcteur, et la grille lui interdit de fonder verdict ou
  conseils sur la prononciation, l'accent, l'intonation, le débit, la fluidité,
  l'aisance, les pauses, les hésitations transcrites, l'orthographe ou la
  ponctuation d'une transcription automatique. Ne pas relâcher d'un côté ce qui
  est verrouillé de l'autre.
- **Rate-limit dédié** `RateLimitGuard.checkSkillAttempt` (`skill-attempt:burst`
  40 / 10 min, `skill-attempt:daily` 400 / jour) : borne le coût LLM **et**
  l'inflation de `user_skill_attempts`. Bornes anti-abus (≠ règles pédagogiques,
  les `recommendedMin/MaxWords` restent **indicatifs et jamais bloquants**) :
  400 mots en EE, 180 s en EO, taille audio max partagée avec
  `production-evaluation`.
- **Libellés gelés du bandeau « Sujet déjà traité »**, une seule action par
  section : EE « Reprendre ma réponse » (préremplit), EO « **Relire** ma dernière
  réponse » (ouvre le résultat). ⚠️ L'EO disait « Écouter » jusqu'au 2026-08-16 :
  il n'y a plus rien à réécouter, l'enregistrement n'étant pas conservé — c'est
  la transcription qu'on relit.
- `SkillPromptDto` porte `skillPromptCount` / `skillDescription` /
  `skillGeneralCriterion` / `skillTargetLevel` **exprès** : l'écran de production
  affiche le fil d'Ariane « Sujet i/5 », l'encart d'explication et le palier
  **sans second appel** à `GET /api/skills/{skillId}`.
