# Plan personnalisé et Plan adaptatif

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Contenu verbatim, aucune réécriture.**
> Origine : lignes 814-1195, 1406-1901 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier porte la loi de ce sous-système : on l'ouvre **quand on travaille dedans**.
> Journal du Plan : il n'a **pas** de fichier `docs/decisions/` séparé — les révocations et
> arbitrages datés sont restés **en place**, dans le corps des règles, parce qu'ils y sont
> inséparables de la règle qu'ils fondent. Voir aussi `docs/decisions/diagnostic.md`
> (V040/V041/V042) et `docs/decisions/contradictions-ouvertes.md` (#3, coût du Plan).
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

- **Une étape du Plan = les 5 premiers sujets actifs de sa compétence**, par
  `display_order` croissant (`LearningPlanStep.PROMPTS_PAR_ETAPE`, arbitré le
  2026-08-11). **Dérivé, jamais persisté** : aucune table, aucune migration, le
  périmètre se relit du rang d'affichage — mêmes 5 sujets pour tout le monde,
  ils ne bougent jamais. Avant, une étape exigeait les **15** sujets (« 2/15 »),
  que personne n'allait finir. Une compétence publiant moins de 5 sujets a une
  étape plus courte : le périmètre vaut ce qui existe, **aucun dénominateur
  n'est inventé**. « Tous distincts » est **acquis par construction**
  (`latestObservedBySkill` ne garde qu'une observation par compétence) : **ne
  jamais construire de mécanisme d'unicité inter-étapes**, il serait mort-né.
- **Compteurs d'étape À CÔTÉ des compteurs de compétence, jamais à leur place.**
  `LearningPlanPriorityDto` porte les deux : `promptCount`/`attemptedCount`/
  `validatedCount` = la **compétence** (15 sujets, sémantique de `SkillDto`,
  inchangée) ; `stepPromptCount`/`stepAttemptedCount`/`stepValidatedCount`/
  `stepCompleted` = l'**étape** (5 sujets). C'est le second jeu que les fronts
  affichent sur l'anneau d'une étape. Détourner le premier à 5 ferait dire
  « /5 » au Plan et « /15 » à la fiche de compétence pour une même compétence.
  `LearningPlanSkillDto` (compétences observées) **n'est pas une étape** et ne
  porte que les compteurs de compétence. Un seul calcul dans
  `SkillProgressCounter` (+ `SkillProgressTally`, `SkillStatusResolver`), **2
  requêtes** quel que soit le nombre de compétences.
- **Le PÉRIMÈTRE de l'étape est publié, pas redécoupé par les fronts** :
  `LearningPlanPriorityDto.stepPromptIds` (liste ordonnée d'UUID, **jamais
  `null`**, éventuellement vide, `display_order` croissant sur les sujets
  actifs), dérivée de `LearningPlanStep.scope`. Invariant garanti :
  `stepPromptIds.size() == stepPromptCount` — le compteur en est **dérivé**, ils
  ne peuvent plus diverger. **Zéro requête ajoutée** : les sujets étaient déjà
  chargés pour les compteurs. Motif : ouvrir une compétence **depuis le Plan**
  affichait « 1/15 » (la fiche générique), l'étape se perdait à la navigation.
  Les fronts servent désormais un écran **scopé aux 5 sujets** quand on vient du
  Plan, et la fiche complète (« x/15 ») par le chemin Réviser → Compétences —
  deux vues assumées pour une même compétence. Ils **ne réimplémentent pas**
  « les 5 premiers par ordre d'affichage » : deux copies désigneraient deux
  étapes différentes.
- **UNE SEULE définition de « transfert prouvé », et elle vit chez le moteur**
  (2026-08-16, `SkillMastery.transferProven()`) : l'état agrégé vaut `SOLID`,
  **ou** une réussite en situation (`SOLID` issu de `PRODUCTION_EE/EO` ou
  `MOCK_EXAM_EE/EO` — jamais un micro-entraînement, jamais le diagnostic qui est
  la baseline) est encore dans `transfer-proof-days` **et** les fragilités
  contextualisées récentes restent sous `fragility-tolerance`. Une compétence
  dont le transfert est prouvé cesse d'être *actionable* : elle sort des
  priorités et la suivante devient l'étape n°1.
  `LearningPlanPriorityResolver.transfertProuve` ne fait que **lire** ce
  booléen — il ne relit plus l'historique.
  ⚠️ **Cette règle RÉVOQUE celle du 2026-08-15** (« la **dernière** observation
  contextualisée fait foi »), qui avait une tolérance **nulle** et enfermait le
  candidat : une seule production moins bonne révoquait trois `SOLID`
  antérieurs, la compétence restait priorité **à vie**, et le moteur — qui la
  jugeait déjà `SOLID` — refusait en même temps d'ouvrir la vérification
  (`readyForReassessment` court-circuite sur `state == SOLID`). Impasse mesurée
  en base sur `user@sejourfr.fr`/`EE1-C8`, plus 4 autres compétences du même
  compte. Ne pas la réintroduire.
  ⚠️ **Aligner sur le seul `state == SOLID` NE MARCHE PAS non plus** — piège
  arithmétique, vérifié : dans le parcours normal (5 micro-sujets validés + 1
  vérification réussie) le score plafonne à **0,679** pour un `solid-score` de
  **0,75**, les 5 `TO_REINFORCE` ciblés à 0,5 diluant la moyenne. Les 5
  conditions structurelles de `SOLID` sont pourtant réunies : c'est le **seuil de
  score** qui manque. Exiger `SOLID` déplacerait donc l'impasse d'un cran et
  imposerait une **seconde** preuve en situation, contre la décision « une
  réussite suffit ». D'où la seconde branche. Verrou :
  `SkillMasteryEngineTest.cinqSujetsPuisUneVerificationProuventLeTransfert`
  (assert `transferProven()` **et** `state != SOLID`).
  **Corollaire** : une étape franchie n'est **pas** forcément `SOLID` — sur le
  compte réel, 1 l'est et 4 sont `CONSOLIDATING`. `PlanMilestoneSelector`
  (≥ 2 compétences `SOLID`) est donc **inchangé**, et les fronts ne doivent
  **jamais** conditionner la coche verte à `masteryState == SOLID` :
  l'appartenance à `completedSteps` **est** la coche.
  🛑 **`recentContextualProof` ne se pose que sur une contextualisée `SOLID`**
  (corrigé le 2026-08-16) : il l'était sur tout `valeur >= 0.5`, donc une
  production jugée **fragile** comptait comme preuve de transfert et **éteignait**
  le signal de vérification. Ne change rien au cas ci-dessus (de vrais `SOLID`
  existaient) ; débloque les candidats dont la seule trace en situation était une
  fragilité.
  ⚠️ **Le déclencheur de la vérification est INCHANGÉ** : toujours
  `readyForReassessment` **et** `step.completed()`.
  Conséquence sur le freemium : `SkillAccessService` ouvrant la compétence de la
  priorité n°1, celle-ci **se déplace** avec l'enchaînement. Sans effet réel pour
  un compte gratuit, qui plafonne à 2 sujets sur 5, ne termine jamais une étape
  et n'obtient donc jamais cette preuve par cette voie.
- **Une étape franchie RESTE dans le parcours, cochée** —
  `LearningPlanDto.completedSteps` (`LearningPlanCompletedStepDto`, **jamais
  `null`**, vide = cas normal, **bornée à 5** les plus récentes, ordre du plus
  ancien au plus récent). Elle se lit **avant** `currentPriority` puis
  `nextPriorities`, dans le **même parcours numéroté**. Sans elle, une compétence
  prouvée **disparaissait** et le candidat perdait la trace de ce qu'il avait
  franchi. Elle ne porte **ni `recommendedExercise` ni `locked`** : il n'y a rien
  à y faire, et ce n'est pas une porte commerciale. L'historique complet reste
  l'affaire de l'écran Progression.
- **Achèvement d'une étape, dérivé serveur** (`LearningPlanStep.Progress
  .completed()`, jamais persisté, jamais recalculé par un front — philosophie
  `SkillStatusResolver` / `SituationDansNiveau`) : terminée quand ses 5 sujets
  ont été **traités** (`status.isAttempted()`, tout sauf `TODO`). **Terminée ≠
  tout validé** — `stepValidatedCount` reste l'information distincte. Une étape
  sans sujet actif n'est jamais terminée. ⚠️ **Une étape terminée ne disparaît
  pas du Plan** : les priorités ne changent qu'à l'arrivée d'une nouvelle
  observation (`LearningPlanObservationService`), donc à la prochaine
  production. C'est le comportement correct — aux fronts de le dire clairement.
- **L'exercice recommandé doit faire avancer** — règle unique partagée par le
  Plan et l'écran de résultat du diagnostic (`RecommendedExerciseSelector`, seul
  endroit) : (1) premier sujet **jamais tenté** par `display_order` croissant,
  (2) sinon le sujet `TO_REINFORCE` dont la dernière tentative est la plus
  ancienne, (3) sinon le sujet tenté le plus anciennement, (4) sinon rien. Statut
  dérivé par `SkillStatusResolver`, chargement en lot (2 requêtes quel que soit
  le nombre de compétences). Avant, les deux appelants prenaient le sujet de rang
  1 et le resservaient indéfiniment. **Le périmètre est celui de l'ÉTAPE** : le
  choix se fait parmi les 5 premiers sujets actifs (`LearningPlanStep.scope`),
  jamais sur les 15 — sinon « Continuer cette étape » enverrait hors étape et
  l'anneau « x/5 » ne bougerait pas. Les **4 branches sont intactes**, seul
  l'ensemble sur lequel elles s'appliquent est réduit, et la borne vaut pour les
  **deux** appelants : le diagnostic désigne la compétence de la priorité n°1,
  il doit pointer dans les mêmes 5. `estimatedMinutes` est **dérivé du sujet**
  (EO : temps de parole conseillé × 3 pour lecture/préparation ; EE : milieu de
  la fourchette de mots à 12 mots/minute ; repli 5/4 min si la donnée manque).
- **Plan source de vérité serveur** : `GET /api/me/plan` renvoie les états
  `NEEDS_DIAGNOSTIC`, `DIAGNOSTIC_IN_PROGRESS` ou `ACTIVE`, les priorités déjà
  ordonnées, l'exercice recommandé et, sur chaque priorité comme sur chaque
  compétence observée, `promptCount`/`attemptedCount`/`validatedCount` — mêmes
  compteurs, même calcul (`SkillProgressCounter` + `SkillProgressTally`) que
  `SkillDto` du module Compétences, jamais un second calcul parallèle (les
  compteurs d'**étape** s'ajoutent à côté, cf. ci-dessus). `learning_plan_observations` conserve
  `skill_id`, source typée + `source_id`, preuve, explication, confiance, date et
  indicateur de baseline. Les fronts affichent cet ordre sans le recalculer ;
  `NOT_OBSERVED` est conservé dans l'historique mais n'annule jamais la dernière
  observation probante d'une compétence ;
  l'écran historique/Progression reste secondaire et séparé.
  **L'ordre des priorités vit dans `LearningPlanPriorityResolver`**, extrait de
  `LearningPlanService` le 2026-08-10 parce qu'un second lecteur en dépend :
  `SkillAccessService` ouvre la compétence de la priorité n°1 à un compte
  gratuit. Deux copies auraient fini par désigner deux « étapes n°1 »
  différentes.
- **On floute l'ACTION pas encore accessible, jamais le RÉSULTAT mesuré**
  (arbitrage du propriétaire, 2026-08-21). ⚠️ Cette règle **révoque** la
  formulation précédente — « le Plan reste intégralement visible sans
  abonnement, aucune priorité, aucune compétence observée, aucun compteur n'est
  masqué ». Ne pas la réintroduire au motif qu'elle est encore écrite quelque
  part : ce qui suit fait foi, et trois commits en dépendent.
  - **Floutés** pour un compte gratuit, sur le Plan : les **items de la séance**
    et les **lignes de priorité** qui sont verrouillés, plus la liste que
    reprend la modale « Pourquoi cette séance ? ». Sur le **rapport de
    diagnostic** : au-delà de 2 priorités, au-delà de 2 points forts, et
    au-delà du 1er entraînement de l'aperçu de séance.
  - **Jamais floutés, pour tout le monde** : la carte de priorité actuelle, le
    profil TCF et ses 4 domaines, « Compléter mon profil », le chemin vers
    l'objectif, « ce qui a changé », les compétences observées, les étapes
    franchies ; et sur le diagnostic, les niveaux estimés EE/EO, l'objectif, le
    rail, le résumé, l'`exempleCible` et le détail des deux productions.
    **Ce sont ses productions et ses mesures.** Masquer là priverait le
    candidat du résultat de son propre travail.
  - 🛑 **Le contenu flouté est le VRAI, jamais un décor fabriqué**, et le bloc
    est retiré de l'arbre d'accessibilité **et** du parcours clavier/tactile
    (`aria-hidden` + `inert` côté web, `ExcludeSemantics` + `IgnorePointer`
    côté mobile). Un flou qu'un lecteur d'écran traverse est un contournement
    et un mensonge d'accessibilité. L'information nette (compteur, CTA) vit
    **hors** du bloc flouté.
  - 🛑 **Les compteurs « + N autres » sont VRAIS**, calculés sur ce que le
    serveur a réellement renvoyé — jamais une constante recopiée de la
    maquette. `N == 0` ⇒ **le bloc n'existe pas**. Corollaire découvert en
    livrant : les listes ne doivent plus être **tronquées à la source**
    (`slice(0,3)` / `.take(4)`), sinon le compteur est faux par construction
    *et* un abonné perd en silence ce qui dépasse. Le seul plafond d'affichage
    vit au point d'appel, à côté du compteur qu'il alimente.
  - **Le floutage suit le `locked` servi par le serveur, jamais le rang de la
    ligne.** La maquette bloque « à partir du 2ᵉ » parce que son bouchon n'a pas
    de serveur ; or une compétence de rang 2 peut être réellement ouverte
    (celle de la priorité n°1 l'est). Flouter par l'index cacherait du contenu
    accessible.
  - ⚠️ **Vérifier qu'aucune AUTRE surface de l'écran ne montre en clair ce qui
    est flouté.** Piège rencontré trois fois : la carte de tête du rapport
    listait les priorités en entier, la modale « Pourquoi cette séance ? » et
    la feuille mobile équivalente réénuméraient les items de séance.
  - L'exercice recommandé reste **désigné** même verrouillé : savoir quoi
    travailler est ce que le Plan apporte, on ne le détourne pas vers un sujet
    ouvert qui ne serait plus la priorité mesurée. `locked` est porté par
    `LearningPlanPriorityDto`, `LearningPlanSkillDto`, `PlanSeanceItemDto` et
    `PlanRecommendedExerciseDto`.
  - **Visible ≠ finissable** : les compteurs d'étape sont servis en entier, mais
    un compte gratuit plafonne à 2/5 (cf. § Freemium).
- **Boucle de réévaluation — l'étape CHANGE DE NATURE, elle ne se dédouble pas.**
  Quand la maîtrise pose `readyForReassessment` (moteur inchangé), la carte « À
  faire maintenant » cesse de proposer un micro-sujet et propose une
  **vérification en situation** : même carte, même emplacement, action
  différente. Le sujet est une **tâche de production déjà publiée** de la
  `SkillTaskCode` de la compétence (jamais de génération, jamais de nouvelle
  banque, jamais d'appel LLM) ; le **diagnostic initial n'est jamais rejoué**
  (filtre `diagnostic_code IS NULL` des deux côtés — mémorisation, biais,
  lassitude). Autorité unique : **`ReassessmentExerciseSelector`**, jumelle de
  `RecommendedExerciseSelector`. Règle : (1) premier sujet **jamais rendu**, (2)
  tous rendus ⇒ le premier du même ordre en écartant la copie la plus récente,
  (3) aucun sujet publié ⇒ rien, et l'étape retombe sur son micro-exercice —
  cas **normal**, jamais une erreur. L'ordre est une **permutation semée** par
  (candidat, compétence, sujet) via splitmix64 : reproductible d'un appel, d'un
  process et d'un serveur à l'autre — jamais `Random` non semé, jamais
  `hashCode` d'objet. Elle porte sur le pool **entier**, donc jouer un autre
  sujet de la même tâche ne redistribue rien. Le DTO dit **quoi et où** :
  `PlanRecommendedExerciseDto.kind` (`MICRO_TRAINING|REASSESSMENT`),
  `skillPromptId` **xor** `productionTaskId` + `tacheNumero`, construits par
  `microTraining(...)` / `reassessment(...)`. `estimatedMinutes` reste **dérivé
  du sujet** (`util/ExerciseDuration`, formule partagée par les deux
  sélecteurs). **Le verrou freemium continue de s'appliquer et ne détourne
  rien** : un sujet verrouillé est **désigné quand même** avec son `locked`, lu
  par `ProductionAccessService.isTrainingLocked` — même règle que
  `enforceQuota`, en lecture (une copie aurait fini par ouvrir ce que le serveur
  refuse). Une réévaluation est une **production standard** : elle produit ses
  observations `PRODUCTION_EE/EO` par le pipeline existant, aucun type de source
  dédié.
- **La bascule vers la vérification exige DEUX conditions, pas une** (2026-08-14) :
  le signal du moteur (`SkillMastery.readyForReassessment`) **et**
  `LearningPlanStep.Progress.completed()` — l'**étape terminée**, ses **5** sujets
  traités. `LearningPlanService` combine les deux **une seule fois** et sert ce
  booléen à la fois à `LearningPlanPriorityDto.readyForReassessment` et au choix
  de l'exercice : le DTO ne peut pas dire « prêt » pendant que la carte propose
  un micro-sujet. Motif mesuré en base : un candidat ayant validé 2 des 5 sujets
  se voyait proposer « Vérifier ma progression » sous un anneau à **2/5** — le
  moteur avait raison sur le fond, l'étape n'était pas finie.
  🛑 **Le périmètre est l'étape ENTIÈRE, pas ce que l'accès du candidat lui
  ouvre — c'est un ARBITRAGE PRODUIT du propriétaire, pas une propriété du
  moteur de maîtrise : la vérification de progression est PREMIUM.** Un compte
  gratuit plafonne à 2 sujets sur 5 (`FREE_PROMPTS_PER_SKILL`), donc il ne
  bascule **jamais** ; aucune de ses compétences n'atteint `SOLID` (qui réclame
  la preuve contextualisée que seule cette vérification apporte) ; et il ne voit
  donc pas non plus les **jalons** de `PlanMilestoneSelector`, dont le
  déclencheur d'épreuve exige ≥ 2 compétences `SOLID`. **Ces trois conséquences
  sont voulues** : ne pas les « réparer » en comptant les sujets ouverts. Une
  première version (livrée puis révoquée le jour même) le faisait, via un
  `exhausted()` / `openCount` dérivé de `SkillAccess` — supprimés, ne pas les
  réintroduire. Le seuil `readiness-targeted-subjects: 2` n'y change rien : il
  n'a jamais gardé cette porte.
  ⚠️ **Le seuil `readiness-targeted-score` ne se monte pas.** Une observation
  ciblée vaut **au mieux 0,5** — `recordSkillAttempt` écrit `TO_REINFORCE` quand
  le critère est **VALIDATED**, et **jamais `SOLID`**. Donc : `0.30` est le seul
  réglage qui sépare « un échec ancien puis deux réussites » (0,351, à laisser
  passer) de « deux réussites noyées dans trois échecs récents » (0,20, à
  refuser) ; `0.50` interdit d'échouer une première fois ; au-delà le signal
  s'**éteint** — et avec lui `SOLID`, qui réclame la preuve contextualisée que
  seule cette vérification apporte. Même piège pour les **réussites ciblées**
  (`SkillMasteryEngine.estReussiteCiblee`, désormais découplé du `valeur >= 0.5`
  du score) : **ne pas la restreindre à `SOLID`**, aucune ligne ne le produit.
  Verrou : `SkillMasteryEngineTest.leSeuilCibleResteAtteignable`.
- **JALONS — on ESCALADE, on ne reporte pas** (`PlanMilestoneSelector`, 3ᵉ et
  dernier sélecteur d'exercice, jumeau de `RecommendedExerciseSelector` /
  `ReassessmentExerciseSelector` — **autorité unique**, deux copies auraient fini
  par désigner deux jalons). Échelle : étape (5 sujets) → **vérification ciblée**
  (débloque `SOLID`) → **examen blanc d'épreuve** (EE ou EO, 3 tâches) → **examen
  blanc TCF complet**. Attendre « les 3 étapes finies » était inatteignable (un
  gratuit plafonne à 2/5) et aurait figé tout le monde en `CONSOLIDATING`.
  L'échelle est déjà **tarifée** par les poids du moteur (0,45 / 0,80 / 1,00 /
  1,20) ; il ne manquait que le déclencheur.
  - **Déclencheurs, dérivés serveur et jamais persistés** : jalon d'épreuve quand
    les compétences **observées** de l'épreuve sont majoritairement **`SOLID`**
    (`epreuve-min-solid-skills: 2` **et** `epreuve-solid-ratio: 0.5`, les deux
    ensemble) et qu'aucun examen blanc de cette épreuve n'a été observé depuis
    `proof-days: 45` ; jalon complet quand **les deux** épreuves ont franchi le
    leur **et l'ont prouvé**, sauf si un `TCF_COMPLET` a démarré dans la fenêtre.
    `SOLID` et pas le score : c'est le seul état qui exige une preuve **en
    situation**. Tous les nombres vivent sous
    `sejourfr.learning-plan.milestone` (+ POJO `LearningPlanProperties.Milestone`
    aux mêmes défauts). À égalité, l'**écrit** passe devant l'oral.
  - **Aucun contenu créé, aucune route nouvelle** : un jalon désigne un examen
    blanc **déjà existant** par `epreuve` + `slotNumber` (le premier slot non
    joué, plafonné à la grille). `PlanExerciseKind` gagne `EPREUVE_MOCK_EXAM` et
    `FULL_TCF_MOCK_EXAM` ; `PlanRecommendedExerciseDto` gagne `epreuve` +
    `slotNumber`, **mutuellement exclusifs** avec `skillPromptId` et avec
    `productionTaskId`+`tacheNumero`. Un jalon ne porte **ni titre ni
    compétence** : le serveur expose des faits, la phrase appartient aux fronts.
    Servi sur `LearningPlanDto.milestone`, **à côté** des priorités (chaque étape
    garde son propre exercice) ; `null` est le **cas normal**.
  - **Verrou reporté, jamais appliqué à la désignation** : un jalon verrouillé
    est **désigné quand même** avec son `locked`, lu chez l'autorité que le
    serveur oppose au démarrage — `ProductionAccessService.isProductionExamLocked`
    (jumelle en lecture de `assertCanStartProductionExam`, que
    `AttemptService.startProductionAttempt` appelle désormais) et
    `.isFullExamProductionLocked` (jumelle du calcul que `FullTcfExamService
    .start` faisait en propre). **Jamais une copie de la règle.**
  - **Coût** : **zéro requête** tant qu'aucun jalon n'est atteint — tout se
    décide sur l'historique déjà chargé et les états de maîtrise déjà calculés
    (`fromObservations` porte désormais sur **toutes** les compétences observées,
    pas seulement celles des cartes : une compétence `SOLID` n'est jamais une
    priorité). Quand un jalon est atteint : 2 à 3 requêtes bornées, jamais une
    par compétence.
- **« Le Plan a changé » après une production** : `ProductionSubmissionDto
  .planChange` (`PlanChangeDto` = `confirmedSkill` + `newPriority`, deux
  `PlanSkillRefDto` **indépendamment nullables**, bloc entier `null` si rien n'a
  bougé). Une **ligne**, jamais la liste des compétences observées. « Confirmée »
  = observation `SOLID` **contextuelle** issue de cette soumission (le diagnostic
  est la baseline, il ne confirme jamais) ; « nouvelle priorité » = la priorité
  n°1 courante **si c'est cette production qui l'a désignée**. Calculé
  **serveur, à la lecture** (`LearningPlanService.changeAfterProduction`,
  branché sur `getOwnDetail` seulement — ni liste d'historique, ni sujet de
  diagnostic, ni avant `EVALUATED`). ⚠️ **Course assumée** : les observations
  s'écrivent **après** la correction, best-effort et hors transaction
  (`ProductionPipelineAsyncRunner`) — rien n'est figé à l'écriture, donc
  l'absence du bloc est un **état normal** et la lecture suivante le rend, sans
  erreur ni rejeu (même sursis côté fronts que le plan d'action).
  **Aucun libellé serveur** : le bloc expose des faits, la phrase appartient aux
  fronts — et un transfert manqué ne se dit **jamais** « vous avez perdu votre
  progression », mais « réussi en exercice ciblé, pas encore automatique en
  production complète ».
- **Plan vivant** : après une correction v14/v8 réussie d'une future production
  complète standard, une observation structurée séparée utilise les skill IDs de
  sa tâche ; son échec best-effort ne dégrade jamais la correction. Les
  micro-exercices alimentent aussi le Plan une fois évalués, mais une réussite
  isolée devient au mieux `TO_REINFORCE`, jamais `SOLID`. **Les productions
  d'examen blanc EE/EO alimentent le même moteur** (V031) : elles passaient déjà
  par le même pipeline mais étaient enregistrées comme de l'entraînement, donc
  sous-pondérées. Une session d'examen productive porte un `slotNumber`, une
  épreuve d'examen **complet** est un sous-attempt d'un parent `TCF_COMPLET` —
  les deux sont sur la ligne `attempts` déjà chargée, aucune requête de plus
  (`LearningPlanObservationService.isMockExam`, sources `MOCK_EXAM_EE/EO`).
- **Aucun diagnostic n'est exigé pour OBSERVER** (2026-08-12). `hasActivePlan` a
  été **supprimé** des deux producteurs (`recordSkillAttempt`,
  `observeStandardProduction`) : un candidat qui travaillait sans passer le
  diagnostic n'accumulait rien, et tout son travail était perdu le jour où il le
  passait. C'est le **Plan** qui continue de réclamer un diagnostic `COMPLETED`
  pour passer `ACTIVE` — `NEEDS_DIAGNOSTIC` / `DIAGNOSTIC_IN_PROGRESS` sont
  inchangés. ⚠️ Conséquence de coût assumée : la voie d'observation d'une
  production standard **appelle le LLM**, elle tourne désormais pour tout le
  monde, plus seulement pour les comptes diagnostiqués.
- **Moteur de maîtrise — `SkillMasteryEngine` + `SkillMasteryResolver`**, dérivé
  à la lecture et **jamais persisté** (même philosophie que `SkillStatusResolver`
  et `SituationDansNiveau`) : recalibrer une pondération relit tout l'historique
  au prochain appel, sans migration ni job.
  - **4 états agrégés, enum `SkillMasteryState`** : `PRIORITY` / `TO_REINFORCE` /
    `CONSOLIDATING` / `SOLID` (« Priorité » / « À renforcer » / « En
    consolidation » / « Solide », gelés par `SkillLabelsTest`, à mirrorer sur les
    3 fronts). ⚠️ **Distinct de `LearningPlanSkillStatus`**, qui est le verdict
    d'**une production** et reste persisté sur chaque observation : la contrainte
    `chk_learning_plan_observation_status` n'admet toujours que
    `NOT_OBSERVED|PRIORITY|TO_REINFORCE|SOLID`. `null` quand rien n'a été observé
    — on n'invente pas un état. `CONSOLIDATING` existe parce que « réussi en
    exercice ciblé » n'est ni « à renforcer » ni « maîtrisé » : c'est lui qui rend
    la vérification en situation compréhensible.
  - **Score interne** `poidsSource × confiance × récence`, moyenne pondérée dans
    `[0,1]` sur une fenêtre glissante et un nombre plafonné d'observations. Il
    **n'est exposé à aucun front** : pas de « 73 % maîtrisé ». `NOT_OBSERVED`
    ignoré (« je n'ai pas pu observer » ≠ « le candidat est mauvais »).
  - **L'état ne se déduit jamais du seul score.** `SOLID` exige **cinq**
    conditions : score ≥ seuil, ≥ 2 observations positives, **≥ 1 venue d'une
    production contextualisée** (production complète ou examen blanc — jamais un
    micro-entraînement, ni le diagnostic qui est la baseline), sujets
    **différents** (`learning_plan_observations.subject_id`, V031 — le sujet, pas
    la tentative), et pas de série de fragilités récentes.
  - **Stabilité** : une seule production moins bonne ne casse pas une compétence
    solide — le moteur rejoue le calcul sans les fragilités récentes tant que
    celles issues d'une production contextualisée restent sous
    `fragility-tolerance` (2). Une fragilité en micro-exercice ne révoque jamais
    un transfert déjà prouvé.
  - **`readyForReassessment`** : signal **interne** (exposé sur
    `LearningPlanPriorityDto` pour la suite du chantier) — assez de réussites
    ciblées, sur des **sujets différents**, performance **ciblée** suffisante, et
    pas de preuve de transfert récente. ⚠️ Le seuil porte sur la performance
    **des seuls micro-entraînements**, pas sur le score global : la baseline du
    diagnostic est une fragilité et un micro-exercice réussi ne vaut qu'une
    demi-preuve, donc un seuil global serait mécaniquement hors d'atteinte et le
    Plan proposerait des micro-exercices à l'infini.
  - **Tous les nombres vivent dans `application.yaml`** sous
    `sejourfr.learning-plan.mastery`, POJO `LearningPlanProperties` **aux mêmes
    valeurs par défaut** : sources `0.45 / 0.80 / 1.00 / 1.20`
    (micro-entraînement / diagnostic / production / examen blanc), confiances
    `1.00 / 0.80 / 0.55`, récence `1.00` (≤ 14 j) / `0.85` (≤ 30 j) / `0.70`,
    fenêtre 180 j, 12 observations max, seuils `0.75 / 0.50 / 0.30`. Aucune
    constante de pondération dans le Java.
  - **Chargement en lot obligatoire** : `SkillMasteryResolver.bySkillIds` fait
    **une** requête pour 24 compétences (index `idx_learning_plan_user_skill_recent`,
    posé en V029 et jusqu'ici jamais emprunté, verrouillé par
    `SkillMasteryResolverIT` qui compte les statements) ; le Plan, lui, se branche
    sur l'historique **déjà chargé** par `LearningPlanPriorityResolver`
    (`fromObservations`, zéro requête de plus).
  - **Exposition** : `masteryState` sur `SkillDto` (**c'est ce que la carte de
    compétence affiche à la place de « 2/15 traités »** — les compteurs restent,
    ils servent l'anneau d'étape), `LearningPlanSkillDto` et
    `LearningPlanPriorityDto`. ⚠️ **La `trajectory` de `SkillDetailDto` a été
    SUPPRIMÉE** le 2026-08-16 (DTO, `SkillObservationPointDto`,
    `SkillMasteryResolver.trajectory` et les deux miroirs front) : la section
    « Ton parcours sur cette compétence » n'apportait rien au candidat, et la
    servir coûtait **une requête à chaque ouverture** d'une compétence. Ne pas
    la réintroduire sans un écran qui la lise vraiment.
  - **`LearningPlanPriorityResolver` reste l'unique autorité sur l'ordre des
    priorités** : le moteur ne le réordonne pas, `SkillAccessService` continue
    d'en dépendre pour ouvrir la compétence de la priorité n°1.
  - **Aucun rattrapage** : le suivi démarre à la mise en service, le diagnostic
    reste la baseline. V031 ne renseigne `subject_id` que par jointure SQL
    déterministe sur des lignes existantes — aucun rejeu, aucun appel LLM.
## Plan adaptatif — profil par domaine, cycle de palier, séance (2026-08-21)

Chantier `feature/plan-adaptatif-ui`, d'après `docs/plan/BRIEF_CLAUDE_CODE_PLAN_ADAPTATIF_TCF_V2.md`
et ses trois maquettes, versionnées au même endroit. Ce qui suit complète la section
« Diagnostic initial TCF et Plan personnalisé » ci-dessus, il ne la remplace pas.

### Le niveau par DOMAINE existe enfin côté front
`TcfProfileService.levelProfile` calculait déjà `TcfLevelProfile{co, ce, ee, eo}` avec la
bonne règle ; `UserDashboardService` n'en gardait que le **plancher** et **jetait les
quatre**. `DashboardSummaryResponse.tcfDomainProfile` les publie désormais
(`TcfDomainProfileDto{domaines[4], globalLevel, evaluated, expected, partial}` +
`TcfDomainDto{epreuve, evaluated, niveau}`), **ordre figé serveur, aucun front ne retrie**.
Un domaine non passé est **présent** avec `evaluated:false` / `niveau:null` — *null =
inconnu, jamais mauvais*. Les 3 scalaires historiques (`estimatedTcfLevel*`) restent servis.

🔴 **Trou corrigé au passage** : la bifurcation `production_submissions.is_diagnostic` écrit
dans `diagnostic_production_analyses` et **jamais** dans `ai_evaluations`, seule table lue par
le calcul. Mesuré sur la base : 16 productions de diagnostic, **0** `ai_evaluation`, et
**8 comptes au diagnostic terminé affichaient « 0 domaine évalué sur 4 »** au sortir d'une
évaluation portant sur deux d'entre eux. Le diagnostic est désormais un **repli** : il ne
renseigne un domaine que si **aucune** production réelle ne l'a fait — une vraie production
prime **toujours**, quelle que soit sa date. Même hiérarchie que les poids du moteur
(diagnostic 0,80 · production 1,00).

### Compétences de COMPRÉHENSION — 6, une par palier et par domaine
`SkillSection` vaut maintenant `EE|EO|**CO**|**CE**` ; `skills.task_code` est **nullable**
(une compétence de compréhension n'appartient à aucune des 6 tâches) et le palier vit sur
`target_level`. 🛑 **`SkillTaskCode` reste les 6 tâches officielles d'expression — ne jamais y
ajouter de valeur CO/CE.** Codes : `CO-A2`, `CO-B1`, `CO-B2`, `CE-A2`, `CE-B1`, `CE-B2`
(V039 schéma + V318 contenu, UUID uuid5 déterministes). Trois contraintes DB rendent
l'invariant opposable, dont un **index unique partiel** sur (section, display_order) sans
lequel deux compétences de compréhension partageraient le même rang (Postgres tient deux
`NULL` pour distincts).
🛑 **Une compétence CO/CE n'a AUCUN `skill_prompt`** — le brief l'interdit, son entraînement
est une série de 20 QCM. Les compteurs rendent 0 **sans jamais inventer de dénominateur**, et
la console admin masque la création de sujet dessus.
`SkillDto.taskCode` / `AdminSkillDto.taskCode` / `AdminSkillStatsDto.taskCode` sont devenus
**nullables** ; `SkillPromptDto.taskCode` reste non-null. Le domaine se lit sur `section`, le
palier sur `targetLevel`, **jamais** déduits de la tâche.
⚠️ `GET /api/skills/progress?section=CO|CE` répond **422** volontairement (pas d'écran
« choix de la tâche » en compréhension) ; le typage web l'interdit désormais en amont.
Freemium : le **palier le plus bas encore actif** de chaque domaine est ouvert (`CO-A2`,
`CE-A2`), B1/B2 verrouillés, plus l'exception « compétence de la priorité n°1 du Plan ».
Autorité unique `SkillAccessService`, opposable serveur (`assertCanTrain`, 403).

### Les QCM alimentent le profil — `ComprehensionObservationService`
`LearningPlanSourceType` **déclarait** `TCF_CO`/`TCF_CE` et `SkillMasteryEngine` savait les
pondérer, mais **aucun code ne les écrivait jamais**. Le producteur existe : un attempt TCF
CO/CE terminé ventile ses réponses **par niveau de question** et observe la compétence
correspondante. `CO_IMAGE` compte avec `CO` ; **STRUCTURE est hors périmètre** (aucune
compétence, ne pas en inventer).
Seuils **neufs et séparés** sous `sejourfr.learning-plan.comprehension` (POJO aux mêmes
défauts que le YAML) : `solid-ratio 0.80`, `reinforce-ratio 0.65`, `min-questions 6`,
`high-confidence-questions 12`. 🛑 **Aucun seuil de `SkillMasteryEngine` n'a bougé** (cf. le
piège arithmétique documenté plus haut).
Le plancher à **6** n'est pas arbitraire : avec `n` questions le taux ne prend que `n+1`
valeurs espacées de `1/n`, et la bande intermédiaire fait 15 points — à `n=5` le pas vaut 20,
donc l'échantillon le plus mince ne rendrait **que** les deux verdicts les plus tranchés.
Sous le plancher : `NOT_OBSERVED`, jamais une fausse fragilité.
- **`subject_id` = `attemptId`**, et `TCF_CO`/`TCF_CE` sont **`isContextual()`** : en
  compréhension le QCM **est** le format réel de l'épreuve, il n'existe pas de version guidée
  à lui opposer. Sans ça aucune compétence CO/CE ne pourrait jamais devenir `SOLID`. Elles ne
  sont **pas** `isTargeted()` (ce drapeau pilote `readyForReassessment`, dont la sortie est
  une *production*). Zéro effet sur EE/EO, verrouillé par test.
- ⚠️ **Une seule série à 16/20 ne rend PAS `SOLID`** — `min-positive-observations = 2` et
  `min-distinct-subjects = 2` exigent **deux sessions**. Le brief §16 dit littéralement
  l'inverse ; **arbitrage du propriétaire (2026-08-21) : on garde deux sessions**, une série
  se réussit par chance, deux non. Verrouillé par `deuxSeriesReussiesRendentSolide` /
  `uneSeuleSerieNeConclutPas`.
- **Prérequis de palier** (`ComprehensionLevelResolver`, dérivé, jamais persisté) : le niveau
  d'un domaine est la longueur du **préfixe ininterrompu de `SOLID` en partant du bas**. Des
  réussites en B2 ne rachètent **pas** un B1 fragile. Rien de consolidé ⇒ `Optional.empty()`,
  jamais « A1 ».
- Best-effort en `REQUIRES_NEW`, exception avalée : une violation d'intégrité dans la
  transaction de correction du QCM l'aurait marquée rollback-only et fait échouer la
  correction elle-même.

### Série ciblée de 20 questions — le `skillId` suffit
`POST /api/attempts {type:"TRAINING", module:"TCF", skillId:"<uuid CO/CE>"}`. **Le client
n'envoie que la compétence** : `questionType`, `difficulty` et `size` sont dérivés serveur du
référentiel — un couple reçu du client aurait pu contredire la compétence affichée et faire
progresser une **autre** compétence. Aucune colonne « compétence visée » n'est persistée : le
producteur rattache par le **contenu réel** des questions. Refus : 403 verrouillé, 422
compétence d'expression, 404 inconnue. Tirage `findLeastRecentlySeen` (jamais vues d'abord,
puis les plus anciennes) ; manque de contenu logué, jamais masqué.
🔴 **Bug de justesse corrigé** : un compte gratuit **connecté** basculait sur
`findDemoPool`, qui **ignore `questionType` ET `difficulty`**. Depuis que les QCM nourrissent
le Plan, cette série hors sujet écrivait ses observations vers **d'autres compétences**. Elle
reste **déterministe** (on n'ouvre pas la banque sans abonnement) mais porte enfin sur ce qui
a été demandé. `findDemoPool` reste pour les **invités**, inchangé.
⚠️ **Une série ciblée est un `TRAINING` : elle ne rend JAMAIS un domaine « évalué ».** Seul un
**examen blanc de module** le fait. C'est `domainesAEvaluer` qui dit par quoi mesurer.

### Ce que `GET /api/me/plan` sert en plus
Quatre blocs ajoutés en fin de `LearningPlanDto`, plus un cinquième :
`domaines` · `cycle` · `domainesAEvaluer` · `seance` · `recentChanges`.
- **`domaines`** (`PlanDomainDto`) : les 4, **triés serveur par urgence**, avec `priority`
  (`PlanDomainPriority`, **libellés FR gelés** par `SkillLabelsTest` : « Priorité forte » /
  « À travailler » / « Entretien » / « Pas encore prioritaire » / « À évaluer », **l'ordre de
  déclaration EST l'ordre d'urgence**), `consolidatedLevel`, `blockingLevel`, les 3 `paliers`
  en CO/CE, les `taches` observées/total en EE/EO. **Depuis le 2026-08-22** il porte aussi
  `skills` (les compétences de l'épreuve, uniforme sur les 4) et les 3 compteurs
  `fragileSkillCount`/`solidSkillCount`/`notObservedSkillCount` — cf. la section
  *« Mon diagnostic » se lit PAR ÉPREUVE* plus bas.
- **`cycle`** (`PlanCycleDto`) : vise **le cran au-dessus du niveau consolidé**, jamais
  l'objectif directement. 🛑 **L'objectif vient de `TargetProcedure.niveauVise`, jamais d'une
  constante** — la maquette l'affiche en dur à `B2`, ce qui retirerait son A2 à un dossier
  CSP ; `objectiveLevel` est **nullable** et aucun front n'invente « B2 » à sa place.
  **Rien n'est persisté** : le cycle se relit de l'historique. 4 états retenus
  (`BUILDING_BASELINE|TRAINING|READY_FOR_GATE_MOCK|TARGET_STABILIZATION`) ; 4 écartés du brief
  avec motif — `WAITING_REASSESSMENT` doublerait le signal **par compétence** et finirait par
  le contredire, `GATE_MOCK_IN_PROGRESS` obligerait à persister, et `LEVEL_CONFIRMED` /
  `NOT_CONFIRMED` sont des **transitions** observables zéro seconde.
- **Gate de palier** : un **cas de plus** de `PlanMilestoneSelector`, pas une notion
  parallèle — même examen désigné, même verrou reporté, même garde-fou d'ancienneté. **Aucune
  clé de configuration ajoutée** : « aucune compétence bloquante » et « toutes les priorités
  solides » sont la **même phrase** sur notre modèle, celle que rend déjà
  `LearningPlanPriorityResolver.actionable`. Une compétence de palier **jamais observée** ne
  bloque **pas** le gate (la refuser enfermerait le candidat ; l'examen est précisément ce qui
  viendrait l'observer).
- **`domainesAEvaluer`** (`PlanDomainAssessmentDto`) : par quoi mesurer chaque domaine
  manquant. **Vide = profil complet**, l'état visé et non une anomalie. `slotNumber` vaut
  toujours **1** (seul slot offert et rejouable, donc mesurer un domaine ne bute jamais sur le
  paywall).
- **`seance`** (`PlanSeanceDto`) : ≤ **3** items, **1 compétence = 1 slot**, minutes
  **recalculées**. `PlanExerciseKind` gagne `TARGETED_QCM_SERIES` (+ `questionCount` sur
  `PlanRecommendedExerciseDto`).
  🛑 **La règle « sticky » n'a demandé AUCUN mécanisme** : les priorités ne trient que sur des
  faits d'observation, une compétence n'en sort que lorsqu'elle est **réussie**, et
  `PlanSeanceBuilder` ne reçoit ni `Clock` ni `LocalDate`. Ne pas créer de table « items du
  jour » : elle serait une seconde source de vérité à réconcilier à chaque observation. Un
  test **vieillit l'historique de 40 jours en base** et exige la même séance.
  **Ce qui est COCHÉ vient pourtant du compte** (2026-08-21) : chaque item porte
  `lastActivityAt` (`Instant` nullable, dernière ligne de
  `learning_plan_observations` de la compétence — **`NOT_OBSERVED` comprise**, une production
  rendue est une activité même quand le correcteur n'a rien pu observer ; autorité
  `LearningPlanPriorityResolver.lastActivityBySkill`, **zéro requête**, l'historique est déjà
  chargé). 🛑 **Le serveur sert un FAIT, jamais un booléen « fait aujourd'hui »** — il n'a pas
  d'horloge ici, et un booléen figé à la lecture serait faux le lendemain : ce sont les fronts
  qui comparent à leur journée courante en **Europe/Paris** (`planSeanceItemDone`, miroirs web
  `lib/plan-domain.ts` ⇄ mobile `plan_seance_state.dart` — étape bouclée **ou** activité du
  jour). Cela **révoque** les deux marqueurs locaux et éphémères (`planSeanceDoneProvider`
  mobile, état de composant web), **supprimés** : ils s'évaporaient au rechargement et le même
  candidat voyait deux séances différentes selon l'appareil. Ne pas les réintroduire, et ne pas
  faire entrer de `Clock` dans `PlanSeanceBuilder` pour « finir le travail ».
  ⚠️ **« Refaire ma séance » n'efface plus rien** : quand tout est fait, le bouton mobile
  **relance réellement** le premier entraînement (`openPlanSeanceItem`, extrait à la 2ᵉ
  occurrence — l'ancien chemin du bouton oubliait les **jalons** et ne faisait rien du tout
  dessus).
- **`recentChanges`** : transitions **réelles** de l'état agrégé, mesurées en rejouant
  `SkillMasteryEngine` sur l'historique arrêté au début de la fenêtre. **`null` = cas
  normal.** Une **première mesure n'est jamais une transition** (sinon le bloc serait plein le
  jour du diagnostic) ; une compétence sans observation dans la fenêtre n'est **pas examinée**.
  Ne double pas `PlanChangeDto` (verdict d'**une** soumission vs état **agrégé** récent) :
  grains différents, et le seul fait commun — la priorité n°1 — vient de la même autorité.
- 🔴 **Trou corrigé** : une priorité de compréhension ressortait avec
  `recommendedExercise == null`, donc **une carte sans action**. `RecommendedExerciseSelector`
  (autorité existante, **pas** un 4ᵉ sélecteur) désigne désormais la série ciblée.
> ✅ **CONTRADICTION #3 TRANCHÉE le 2026-08-26 : c'est 21 requêtes.** Le chiffre ci-dessous
> est l'état d'avant ; il est conservé pour la traçabilité. Voir la section
> « Progression PAR ÉPREUVE » plus bas et `docs/decisions/contradictions-ouvertes.md`.

- **Coût (état 2026-08-21, dépassé)** : le Plan complet faisait **20 requêtes, constantes** avec 2 ou 20 compétences
  observées — verrouillé par deux tests qui comptent les statements. La passe séance +
  changements a ajouté **zéro** requête ; la passe « à acquérir » en a ajouté **une** (le
  référentiel du palier, chargé en un lot — cf. la section suivante).

### Trois catégories, pas une : le Plan sait enfin ENSEIGNER (2026-08-21)

Constat mesuré sur `billodiallo@gmail.com` : 6 compétences EE solides, 2 à renforcer,
8 EO jamais observées, un oral inexploitable — et un Plan qui affichait **2 actions** à
un candidat A2 qui vise le B2, donc à qui il reste **un palier entier**. Le Plan savait
**réparer**, il ne savait pas **enseigner**.

> *`NON OBSERVÉ ≠ FAIBLE`, mais aussi `NON FRAGILE ≠ PLUS RIEN À APPRENDRE`.*

- **`PlanActionNature`** (enum, **dérivé, jamais persisté**, libellés FR gelés par
  `SkillLabelsTest`, **à mirrorer sur les 3 fronts**) : `A_EVALUER` « À évaluer » ·
  `A_RENFORCER` « À renforcer » · `A_VERIFIER` « À vérifier » · `A_ACQUERIR`
  « À acquérir ». **L'ordre de déclaration EST l'ordre de choix** d'une séance — mesurer
  ce qui manque, réparer ce qui est fragile, vérifier ce qui est prêt, apprendre ce qui
  vient. Servi sur `LearningPlanPriorityDto.nature` et `PlanSeanceItemDto.nature` ; les
  fronts lisent **cette nature**, jamais la nullité d'un autre champ.
  🛑 **`A_ACQUERIR` ne se dit JAMAIS « à renforcer »** : renforcer suppose un constat
  négatif, et sur une compétence jamais travaillée il n'y en a aucun.
- **Réconciliation des vocabulaires — trois enums, trois grains, ils ne se remplacent
  pas.** `LearningPlanSkillStatus` = le verdict d'**une production** (persisté, sans
  libellé) · `SkillMasteryState` = l'état **agrégé** d'une compétence (dérivé, affiché sur
  sa fiche) · `PlanActionNature` = **l'action à faire maintenant** (dérivée, affichée sur
  la carte du Plan). `PlanActionNature.A_RENFORCER` et `SkillMasteryState.TO_REINFORCE`
  portent **volontairement le même libellé** — quand les deux s'appliquent ils disent la
  même chose, ils ne s'affichent simplement pas au même endroit ; idem pour « À évaluer »
  partagé avec `PlanDomainPriority.A_EVALUER`. Ce n'est **pas** une collision à corriger,
  et `SkillLabelsTest` fige l'égalité pour que personne ne « répare » l'un des deux.
  `PlanDomainPriority` qualifie un **domaine**, jamais une action : « À travailler » et
  « Entretien » restent là-bas.
### Progression PAR ÉPREUVE, confirmation GLOBALE (2026-08-26)

> *`NON FRAGILE ≠ PLUS RIEN À APPRENDRE`, et **`PLAFOND UI ≠ BUDGET PÉDAGOGIQUE`**.*

Mesuré sur `billodiallo2@gmail.com` (diagnostic `fe35354d`) : **EE A2 / EO B1, objectif B2**.
Le Plan servait **2 actions**, toutes en écrit, et la carte d'expression orale affichait
« rien à travailler » — alors que 16 de ses 24 compétences n'avaient jamais été touchées.
**10 actions vraies existaient, 2 étaient servies.** Quatre causes, corrigées ensemble :

- 🛑 **Le palier d'apprentissage est celui DU DOMAINE**, plus celui du niveau **global**
  (le plancher des domaines évalués). `PlanDomainTargetLevelResolver`, **autorité unique** :
  il **appelle** `ProgressionPlanBridge.prescriptionLevel` (moteur V4.2, décrit comme « le
  seul niveau que le Plan a le droit de proposer ») et **retombe** sur « le cran au-dessus du
  niveau du domaine, plafonné par l'objectif » quand le pont rend `empty()` — ce qui est le
  cas aujourd'hui en `SHADOW` et hors compréhension. ⚠️ **Ne jamais écrire une seconde règle
  de palier ailleurs** : le pont reste la porte, son extension à EE/EO est un chantier séparé.
  Amende les **§37/§39** du brief (le palier se lisait sur le niveau global).
  🛑 **N'amende PAS le §93**, qui interdit de faire *redescendre* un domaine avancé et n'a
  jamais dit qu'il ne recevait rien — c'est l'implémentation qui avait durci « pas
  prioritaire » en « zéro action ». Un domaine `PAS_ENCORE_PRIORITAIRE` reçoit ses
  acquisitions ; il passe simplement après.
- 🛑 **Le moteur calcule TOUT, l'affichage coupe.** `LearningPlanPriorityResolver.actionable`
  n'a plus de plafond, et le sélecteur d'acquisitions **ne reçoit plus de budget** — la ligne
  `MAX_PRIORITIES - actionable.size()` faisait servir un plafond d'écran de budget de
  production aux **quatre** domaines à la fois. Ordre : pool complet → filtre de faisabilité →
  classement → composition → troncature d'affichage.
- 🆕 **Filtre de faisabilité — une action n'existe que si elle est EXÉCUTABLE**
  (`PlanContentAvailability`, **2 requêtes agrégées, jamais un compte par compétence**).
  Deux branches : expression ⇒ « ≥ 1 petit sujet actif » ; compréhension ⇒ « ≥ 1 question
  active **à ce palier** » (la série ciblée ne tire son contenu qu'au démarrage). Il **logue
  ce qu'il coupe** : aujourd'hui il ne coupe rien (48/48 compétences ont 15 sujets ; 134 à 214
  questions par palier), donc **toute ligne dans les logs signale un pourrissement du
  catalogue**. ⚠️ Le palier d'une fragilité de compréhension doit être fourni au filtre —
  sans lui, toute compétence CO/CE serait jugée inexécutable et le Plan perdrait des
  fragilités réelles.
- 🆕 **Classement et composition configurables** (`PlanActionRanker`) : score additif
  `nature + urgence du domaine + écart à l'objectif + confiance`, départages `observedAt` puis
  code. 🛑 **Aucune horloge** — la récence est un *départage*, jamais un poids, sinon la
  stickiness de la séance ne serait plus gratuite. **La première place est épinglée** :
  c'est celle que le freemium ouvre (`PlanFocusResolver`), un classement qui la déplacerait
  cadenasserait l'étape n°1. **Composition d'Aujourd'hui** : au plus
  `display.todayMaxSecondaryDomainActions` action(s) de domaine **secondaire** dans la
  fenêtre — un **maximum**, jamais un minimum : si tout le haut du classement est primaire, la
  séance reste sur un seul domaine, et c'est légitime.
- 🛑 **`plan-config-v{n}.json`, fichier DISTINCT de `progression-config`**
  (`sejourfr.plan.config-version`). Les deux ont des cycles de vie **opposés** :
  `progression-config` porte l'intégrité d'`engineVersion` et le **rejeu** de la maîtrise ;
  `plan-config` ne porte que **sélection et affichage** (`display.*`, `ranking.*`) et bougera
  souvent. **INVARIANT : `plan-config` ne peut RIEN influencer du calcul de maîtrise.**
  ⚠️ Le mapping `nextTargetLevel` **n'y est pas** : c'est de la doctrine pédagogique
  déterministe et testée, pas un réglage.
- **Coût : 21 requêtes**, fixe et assumé (19 + 2 agrégées pour la faisabilité), verrouillé par
  `LearningPlanCycleIT`. ⚠️ **Tranche la CONTRADICTION #3** (« 20, +1 ou 19 ? ») : c'est **21**.
  L'égalité « 2 compétences observées ou 20, même coût » reste le vrai garde-fou.
- **La carte d'épreuve ne dérive plus des cartes affichées** : `natures` est posé depuis le
  **pool complet**, plus depuis la liste tronquée. C'était la cause directe de l'écran vide.
- **`PlanDomainDto` sert quatre champs de plus**, tous **dérivés serveur**, mirrorés sur les
  deux fronts : `nextTargetLevel` (le palier de **ce** domaine), `acquireCount` (compétences à
  acquérir — **exécutables uniquement**, le compte ne promet jamais un contenu absent),
  `readyForValidationCount`, et `notObservedWithoutActionCount` (le vrai « pas encore assez de
  données »).
  🛑 **Deux copies front supprimées, et elles mentaient** : `diagnosticNextLevel` (mobile) /
  `nextLevel` (web) dérivaient « prochain palier » du seul niveau mesuré, **sans plafond par
  l'objectif** — un candidat B1 visant le B1 lisait « prochain palier B2 » ; et le mobile
  recomptait « pas encore assez de données » en excluant les acquisitions pendant que le
  serveur les incluait. **Deux champs nommés distinctement** plutôt qu'une soustraction faite
  par chaque front.
  ⚠️ Le palier d'une compétence se lit par `planSkillTargetLevel` (`domaines[].skills[]`),
  **jamais** par un repli sur `cycle.targetLevel` — c'est le palier **global**, et il affiche
  un palier faux dès que deux domaines divergent.
- **Le rideau est INSTRUMENTÉ avant d'être changé** : `PLAN_CURTAIN_SHOWN` /
  `PLAN_CURTAIN_EXPANDED` / `PLAN_PAYWALL_VIEWED`. Le correctif fait passer le rideau de
  « 1 sur 5 » à « 1 sur 9 ou 12 » — signal de valeur plus fort, découragement tout aussi
  plausible. → `docs/regles/mesure-audience.md`
- ⚠️ **« Aujourd'hui » peut légitimement rester sur un seul domaine.** Le plafond de domaines
  secondaires est un **maximum**, pas un minimum : si le classement place trois actions
  primaires en tête, la séance est mono-domaine, et c'est conforme. Le candidat voit ses
  actions des autres épreuves **sur leur carte**. Poser un *plancher* de diversité serait
  l'inverse de cette règle — décision produit non prise à ce jour.

- **`PlanAcquisitionSelector`, autorité unique** de « que reste-t-il à APPRENDRE ? ».
  Source : **`skills.target_level`, qui existait déjà** (EE 8 A2 / 11 B1 / 5 B2 · EO 8/8/8 ·
  CO et CE 1 par palier) — **aucune migration, aucun contenu créé, aucun appel LLM**, la
  sélection est **déterministe**. Trois conditions : (1) la compétence appartient au
  **palier que SON DOMAINE construit** en expression (`PlanDomainTargetLevelResolver`,
  2026-08-26 — c'était le palier du cycle **global** avant, cf. section ci-dessus), ou au
  **palier bloquant de son domaine** en compréhension (⚠️ **les deux ne sont pas le même
  palier, et c'est voulu** : la compréhension a une chaîne de prérequis, A2 solide avant B1) ; (2) son domaine a **déjà été mesuré** — un domaine jamais mesuré
  se mesure d'abord, et cette porte existe déjà (`domainesAEvaluer`) ; (3) le candidat n'a
  **aucune ligne d'historique** dessus, `NOT_OBSERVED` comprise. Ordre : urgence du domaine
  (celle que `PlanCycleResolver` a **déjà** décidée, jamais recalculée), puis ordre des
  épreuves, tâche, `display_order`.
- **Les deux sens de `NOT_OBSERVED`, enfin distingués** — c'est ce qui débloque le compte
  de référence. « La production était **inutilisable** » ⇒ il faut **réévaluer** :
  `PlanDomainAssessmentResolver.indispensable` (grain du **domaine** — une production ratée
  emporte toute son épreuve), servi **en tête de séance** en `A_EVALUER`, **zéro requête**.
  « Ce palier n'a **pas encore été abordé** » ⇒ il faut **acquérir** (grain de la
  compétence). Sans cette distinction, le Plan proposait de l'écrit à l'infini à un candidat
  dont c'est l'oral qui manquait.
- 🛑 **`SkillMasteryEngine` n'a pas bougé d'un octet.** Une compétence à acquérir n'est
  **pas une observation** : aucune ligne dans `learning_plan_observations`, donc ni score,
  ni moyenne, ni fragilité. Sa carte a `status`, `explanation`, `evidence`, `confidence`,
  `observedAt` et `masteryState` à **`null`** — *null = inconnu, jamais mauvais* — et
  `readyForReassessment` à `false`. `NOT_OBSERVED` ne devient toujours **jamais** une
  fragilité.
- **Plafonds : 3 dans « Aujourd'hui », 5 dans « Mes priorités »** (`MAX_PRIORITIES` 3 → 5,
  calibré pour un Plan qui ne savait que réparer). 🛑 **Ce sont des PLAFONDS, pas des
  quotas** : rien n'est fabriqué pour remplir l'écran, une compétence **solide** ou **non
  observée hors du palier visé** ne devient jamais une action, et deux actions vraies
  rendent deux cartes. Les acquisitions arrivent **après** les fragilités — on répare ce
  qui bloque avant d'apprendre ce qui vient — et n'en reçoivent que les places restantes.
- **Le jalon FERME la séance**, il ne l'ouvre plus. Un examen blanc de 30 à 60 min n'a rien
  à prouver tant qu'une mesure manque ou qu'une fragilité bloque, et à trois slots le mettre
  en tête chassait le vrai travail de la journée. Conséquence assumée : **une journée déjà
  pleine ne lui laisse pas de place** — il reste servi sur `LearningPlanDto.milestone`, il
  n'est pas perdu, il n'est simplement plus prioritaire.
- **`PlanSeanceItemDto` : `exercise` XOR `assessment`.** Un item `A_EVALUER` est le seul à
  porter le second, et il ne porte aucune compétence. Les minutes d'une mesure sans durée
  (production, diagnostic) comptent **zéro**, jamais un chiffre inventé.
- **Coût : +1 requête, constante.** Le référentiel du palier se charge en **un lot**.
  🛑 **Cette requête est INCONDITIONNELLE dès qu'un palier se construit**, y compris quand
  les fragilités remplissent déjà les 5 places : le nombre de places restantes dépend des
  **données du candidat**, et rendre un aller-retour en base conditionnel à cela ferait
  varier le coût du Plan d'un compte à l'autre — donc invérifiable. C'est ce qui permet aux
  tests de coût d'exiger une **égalité** et d'attraper vraiment un N+1. Ne pas « optimiser »
  en remettant un retour anticipé.
- **Freemium — LA PREMIÈRE PLACE DU PLAN EST TOUJOURS OUVERTE, quelle que soit sa
  nature** (2026-08-21). ⚠️ **Révoque** la règle inverse livrée le jour même (« une
  compétence à acquérir n'est pas déverrouillée par sa place n°1 »), qui était un
  **état constaté**, pas une décision : arbitrage du propriétaire — *« un candidat non
  abonné pourra travailler sa priorité 1, vu qu'elle est visible »*. Le Plan promettait
  une action que le candidat ne pouvait pas commencer.
  - **Autorité unique : `PlanFocusResolver`** (3ᵉ résolveur du trio, à côté de
    `LearningPlanPriorityResolver` — l'ordre des priorités — et de
    `PlanAcquisitionSelector`). Règle : **la première fragilité actionnable ; à défaut,
    la première acquisition** — exactement l'ordre dans lequel `LearningPlanService`
    empile ses cartes. `LearningPlanPriorityResolver.currentPrioritySkillId` est
    **supprimée** : « priorité n°1 » ne veut plus dire « première fragilité ».
  - **Deux formes, une seule règle** (patron `actionable(list)` ⇄ `actionable(list,
    mastery)`) : `focus(actionable, acquisitions)` **en mémoire** pour le Plan, qui a
    déjà ses deux listes, et `currentFocusSkillId(userId)` **autonome** pour
    `SkillAccessService`. `LearningPlanService` **passe** la première place à
    `accessService.resolve(userId, focusSkillId)` : le cycle ne tourne donc **pas deux
    fois** dans une lecture du Plan, dont le coût est **inchangé** (ses deux tests de
    cout exigent une égalité).
  - 🛑 **Le coût du verrou reste au plus bas grâce à un RETOUR ANTICIPÉ** : une
    acquisition ne peut occuper la première place que si le candidat n'a **aucune**
    fragilité (elles passent toutes devant). Cas courant : **1 requête**, comme avant.
    Sans fragilité et sans diagnostic terminé : +1, puis sortie. Sans fragilité avec
    diagnostic terminé : le cycle de palier, borné, jamais une requête par compétence.
    ⚠️ **C'est l'inverse de la règle du Plan** (`PlanAcquisitionSelector` charge
    *inconditionnellement*) et les deux se défendent : le Plan est **un** écran dont on
    veut vérifier le coût par une égalité, `SkillAccessService` est appelé par **tous**
    les écrans de compétences. Ne pas uniformiser.
  - **Rien d'autre ne s'ouvre** : c'est **une place**, pas une catégorie. Les
    acquisitions suivantes gardent leur `locked`, les 2 sujets par compétence ouverte et
    les 3 analyses IA à vie ne bougent pas, et le verrou reste **opposable serveur**
    (403). Limite assumée, sans conséquence : le Plan écarte de ses cartes une
    acquisition **sans exercice publié**, ce que la forme en mémoire ne peut pas savoir
    (l'exercice se choisit après, et `RecommendedExerciseSelector` lit l'accès — le
    calculer avant créerait un cycle). Une compétence d'expression sans aucun sujet actif
    serait donc ouverte sans être affichée : elle n'a rien à produire. Le catalogue
    publié n'en compte aucune.

### Diagnostic progressif — 0/4 → 4/4
Le socle existait aux trois quarts. Deux trous seulement ont été comblés :
- `evaluated:false` était un constat **sans porte de sortie** → `domainesAEvaluer` (ci-dessus).
- 🔴 Un candidat **EE + EO solides, compréhension jamais mesurée** — le cas que le brief §77
  nomme mot pour mot — se voyait proposer l'**examen blanc complet à 2/4**. Le cycle était
  irréprochable ; c'est l'échelle des **jalons** qui pouvait désigner cet examen sans regarder
  le profil. Un `FULL_TCF_MOCK_EXAM` est désormais retiré tant que `profileComplete()` est
  faux ; le jalon d'**une épreuve** survit (il ne prétend rien du palier).
- **La variante rapide / complet n'est PAS persistée** : la seule différence est ce que le
  front enchaîne après l'analyse, et le profil réel se lit sur les **domaines mesurés**. Une
  colonne aurait affirmé « complet » sur un candidat arrêté après l'oral — et au moment du
  choix le candidat est encore **invité**, aucune ligne ne pourrait la porter.
- 🛑 **Le parcours de l'invité ne bouge pas d'une ligne** : productions côté client → compte →
  analyse, puis **la compréhension seulement une fois connecté**. Un attempt sans compte n'a
  personne à qui attribuer un progrès (`ComprehensionObservationService` l'ignore déjà, et
  `TcfProfileService` lit par `user_id`) : un QCM d'invité serait **perdu par construction**.
  Aucune session anonyme, `diagnostic_sessions.user_id` reste `NOT NULL`, funnel intact.

### « Mon diagnostic » se lit PAR ÉPREUVE (2026-08-22)

Chantier d'après les maquettes `docs/plan/SejourFR - {Mobile,Web} Autonome.html` (écrans
`MDiagBilan` ⇄ `PlanDiagScreen`). L'écran **Plan → « Mon diagnostic »** était organisé par
**nature d'information** (niveau global → profil TCF → points forts → priorités → offre) ;
il l'est désormais **par épreuve** : une carte dépliable par épreuve, portant son niveau
estimé, les compétences qui l'expliquent, et l'action qui suit.

**Le chemin d'accès ne bouge pas** : ligne « Mon diagnostic » du groupe de liens secondaires
du Plan, `push('/diagnostic')` (mobile) ⇄ `/diagnostic` (web), sans cadenas — l'écran s'ouvre
pour tout le monde.

- **Ordre figé des sections, identique sur les deux fronts** : héros global (niveau estimé,
  objectif, `N / 4 épreuves évaluées`, rail A2→B1→B2, et **4 colonnes cliquables** qui
  déplient la carte visée) → « Mes 4 épreuves » dans l'ordre **EE · EO · CE · CO** → prochaine
  étape (abonné) ou carte d'offre (gratuit) → note d'estimation. 🛑 L'ordre des épreuves est
  **stable**, il ne reprend PAS l'ordre d'urgence de `LearningPlanDto.domaines` : le Plan se
  lit par urgence, le diagnostic se lit toujours pareil. On ne retrie rien, on lit.
- **Trois états de carte** : `ok` · **« À évaluer »** (`evaluated == false`, niveau `—`, CTA
  vers l'assessment de `domainesAEvaluer`) · **« Évaluation incomplète »**
  (`ProductionEvaluabilite.NON_EVALUABLE`). ⚠️ **Un domaine réellement mesuré affiche son
  niveau** : une production inexploitable ne produit aucun niveau, mais elle n'**efface** pas
  celui qu'une autre mesure a donné. Les deux fronts testent les états dans le **même** ordre —
  ils divergeaient à la livraison, c'est corrigé.

**Contrat serveur — `PlanDomainDto` gagne les compétences de son épreuve.**
`PlanDomainDto.taches` ne donnait que des **compteurs**, `paliers` que 3 entrées sans titre, et
`LearningPlanDto.observedSkills` est **plafonné à 8 toutes épreuves confondues** — une épreuve
pouvait donc sortir vide alors qu'elle avait des compétences. Quatre champs additifs :
`List<PlanDomainSkillDto> skills` (**jamais null**), `fragileSkillCount`, `solidSkillCount`,
`notObservedSkillCount`. `paliers` et `taches` sont **intacts**.

- **`skills` est UNIFORME sur les 4 épreuves** : les 24 compétences de l'épreuve en expression
  (3 tâches × 8, ordre tâche puis `display_order`), les **3 compétences de palier** en
  compréhension (A2→B1→B2). C'est ce qui donne aux fronts **une seule façon de lire une carte**.
  🛑 La maquette invente des sous-domaines de compréhension (« Informations implicites »,
  « Documents longs ») qui **n'existent pas** au référentiel — arbitrage du propriétaire
  (2026-08-22) : on affiche les **3 paliers réels**, jamais un contenu fabriqué.
- **Autorité unique `PlanDomainSkillResolver`, ZÉRO requête** — il ne décide rien : `status` et
  `observedAt` viennent de `latestObservedBySkill`, `masteryState` de `SkillMasteryEngine`,
  `nature` **des cartes que `LearningPlanService` vient d'empiler**, `locked` de
  `SkillAccessService`. Jamais une copie d'une règle qui a déjà une autorité.
- 🛑 **Rien n'est affirmé sans observation** : une compétence jamais observée sort
  `NOT_OBSERVED` / `masteryState` **null** / `observedAt` **null** / **aucune** `nature` —
  *null = inconnu, jamais mauvais*. Une compétence `SOLID` n'a pas de nature non plus : une
  nature est **l'action à faire**, pas un statut.
> ⚠ **CONTRADICTION #3** — voir `docs/decisions/contradictions-ouvertes.md`. Non tranchée.

- **Coût inchangé : 19 requêtes avant, 19 après.** Le `GROUP BY` `countActiveByTaskCode` est
  **remplacé** par un lot `findActiveExpression()` (48 lignes) : les compteurs par tâche s'en
  dérivent en mémoire, et le même lot sert la liste des compétences. **Une requête troquée
  contre une**, publiée par `PlanCycleResolver.Resolution.referentiel()` — la charger deux fois
  aurait fait payer au Plan une donnée qu'il avait déjà en main. Les deux tests de coût gardent
  leur **égalité**. `PlanAcquisitionSelector` n'est pas touché : le fusionner casserait le
  retour anticipé de `PlanFocusResolver.currentFocusSkillId`, qui protège **tous** les écrans
  de compétences.
- **Invariant testé** : `fragileSkillCount + solidSkillCount + notObservedSkillCount ==
  skills.size()`. C'est ce qui garantit qu'un front ne peut pas afficher un « + N » faux.
- ⚠️ **La branche `NEEDS_DIAGNOSTIC` appelle désormais `accessService.resolve(userId, null)`** :
  sans lui `locked` y valait `false` par défaut, donc **faux**. Correction, pas régression.

**Freemium — on floute l'action, jamais la mesure.** Application par épreuve de la règle du
2026-08-21 : 1 priorité + 1 compétence solide en clair, puis **un seul bloc de verrou par
carte** portant le **vrai** libellé de la compétence suivante, flouté, et le compte exact
(« + 3 compétences détectées · 2 déjà solides »). Compteurs calculés sur les
`fragileSkillCount`/`solidSkillCount` **du domaine** — jamais sur `DiagnosticResultDto
.fragileSkillCount`, qui est **global** et mentirait par épreuve. `N == 0` ⇒ **le bloc n'existe
pas**. Le rideau est hors de l'arbre d'accessibilité (`aria-hidden` + `inert` ⇄
`BlurredContent`), le compteur et le CTA vivent **hors** du rideau. Un seul chemin vers l'offre,
**aucun événement d'audience ajouté**.
⚠️ **Le compte des non observées est recalculé côté front** (`NOT_OBSERVED` **et** pas
`A_ACQUERIR`) au lieu de lire `notObservedSkillCount` : ce dernier inclut les acquisitions,
déjà affichées sous « À acquérir ». Les compter deux fois dirait qu'une compétence est à la
fois à apprendre et sans données.

**Aucune phrase ne vient du serveur.** Les résumés par (épreuve × palier) et l'encart
d'explication vivent dans les fronts — `diagnostic_report_labels.dart` ⇄ les constantes de
`DiagnosticReport.tsx`, miroirs mot pour mot — et l'explication est **composée de faits**
(compétences observées, tâches, palier bloquant), jamais d'un jugement.

**Ce que la maquette n'a pas et qu'on a gardé** : « Compléter mon profil » n'est plus une carte
séparée, son parcours vit dans le bouton de chaque carte « À évaluer » (même
`openPlanAssessment` / `usePlanAssessment`, autorité inchangée), avec un repli vers la fiche
d'épreuve quand aucun assessment n'est servi. L'accès aux fiches de domaine survit en lien
discret. **Supprimés** : `DiagnosticProfile.tsx` (web) et, des deux côtés, les blocs
« points forts » / « priorités » plats, leur teaser et la barre d'action collante.

🛑 **Piège de rendu à ne pas rejouer (mobile)** : la `Row` des 4 colonnes du résumé est
enveloppée d'**`IntrinsicHeight`**. Sans lui, `CrossAxisAlignment.stretch` dans un
`SingleChildScrollView` réclame une hauteur **infinie**, la `RenderFlex` reste `NEEDS-LAYOUT`,
et `flushSemantics` — qui ignore les nœuds non mis en page — lève
`!semantics.parentDataDirty` **à chaque frame** : écran blanc. Les asserts de sémantique
étaient le **symptôme**, l'exception racine étant noyée sous les « Another exception was
thrown ». Les 3 autres `Row + stretch` de l'app en sont déjà enveloppées — c'est la convention.
⚠️ Et **ne pas « réparer » ce genre d'assert avec `excludeSemantics: true`** : il vide
`visitChildrenForSemantics`, donc l'action `onTap` de l'`InkWell` disparaît du nœud et
VoiceOver annonce « bouton » sans pouvoir l'activer.

### L'écran Plan se lit PAR ÉPREUVE → TÂCHE (2026-08-22)

Chantier d'après les maquettes `docs/plan/SejourFR - {Mobile,Web} Autonome.html` **mises à jour**
(fichier neuf « encarts rétractables épreuve → tâche » ; l'écran Plan y **maigrit** des deux
côtés). « Aujourd'hui » et « Mes priorités » ne sont plus des listes plates : ce sont des
**encarts rétractables groupés par épreuve puis par tâche**. Fermé, un encart dit *où* je
travaille ; ouvert, il déroule ses lignes.

- **Clé de groupe** : la **tâche** en expression, le couple **(domaine, niveau)** en
  compréhension. Une mesure et un jalon font chacun leur groupe. Dérivé **front**, à partir de
  ce que `GET /api/me/plan` sert déjà — aucun champ ajouté au serveur.
- **Résumé d'un encart** : « {titre de tâche} · 1 priorité · 2 à renforcer · 3 solides »,
  **ordre figé** (priorité, à renforcer, à acquérir, à vérifier, solide, à évaluer). Il compte
  **tout le groupe**, jamais les seules lignes visibles.
- **6 statuts de ligne**, dérivés de `nature` → `masteryState` → `status` dans cet ordre. 🛑 Les
  libellés sont **empruntés** à `PlanActionNature` et `SkillMasteryState`, jamais réécrits : ce
  sont des enums gelées par `SkillLabelsTest`.
- **Le titre des 6 tâches est un MIROIR de l'enum `SkillTaskCode`** (« Raconter une
  expérience »), déclaré une fois par front et dérivé du `skillCode` servi (`EE2-C3` ⇒ `EE2`).
  L'API ne le sert pas et **n'a pas à le servir** : c'est un référentiel officiel figé, patron
  habituel des libellés d'enum. Il s'affiche aussi sur la fiche de domaine et « Toutes mes
  compétences ».
- **Pastille de tâche : bleu clair · ambre clair · bleu plein.** 🛑 **Jamais de rouge** — la
  charte le réserve aux CTA critiques, et sur une épreuve d'expression `PlanDomainTile` **et**
  le statut « Priorité » sont déjà rouges dans la même carte. La maquette utilise un violet qui
  n'existe pas dans nos tokens : **ne pas le fabriquer**. La 3ᵉ teinte se distingue par le
  **remplissage**, pas par la couleur.

**« Compétences observées » n'existe plus — elle est FONDUE dans « Mes priorités »**
(arbitrage du propriétaire, 2026-08-22 : *« il faut les combiner dans mes priorités, même si on
n'affiche pas toute la liste, mais qu'il sache qu'il a de quoi travailler »*).
- **Construction en deux passes** : les priorités servies **créent** les encarts (ordre serveur
  intact) ; les compétences de **`domaines[].skills[]`** les **complètent sans en créer**. Une
  tâche sur laquelle le Plan ne demande rien n'ouvre donc pas de carte — son contenu se relit
  par le « + N autres » et la fiche de domaine.
- 🛑 **La source est `domaines[].skills[]`, PAS `observedSkills`**, qui est **plafonné à 8
  toutes épreuves confondues** (`LearningPlanService`) : construire les groupes dessus ferait
  sortir une épreuve **vide** alors qu'elle a des compétences.
- **Éligibilité d'une ligne** : `observedAt != null` **ou** `nature != null`. Une compétence
  jamais observée et sans action n'est **ni une ligne ni un compté** — elle n'est ni un acquis
  ni quelque chose à faire.
- **6 lignes visibles au plus**, puis « + N autre(s) compétence(s) ». 🛑 **Le compteur est
  VRAI**, dérivé du contenu réel du groupe ; `N == 0` ⇒ pas de lien.
- Le bouton d'encart vise la première ligne **non solide** ; groupe entièrement solide ⇒ **pas
  de bouton** (aucun repli sur la première ligne).
- L'intertitre est **« Mes compétences »** : « Ce que je dois améliorer » est devenu faux dès
  lors que la liste porte aussi des acquis.

**Freemium — le verrou se lit, il ne se déduit pas.**
- 🛑 **Jamais « à partir du 2ᵉ »** : la maquette le dessine ainsi parce que son bouchon n'a pas
  de serveur. Le `locked` **servi** fait foi, et `PlanFocusResolver` ouvre réellement la
  première place du Plan quelle que soit sa nature.
- **Un encart est verrouillé ⇔ TOUTES ses lignes le sont** ⇒ cadenas **à la place du chevron**,
  pas de dépliage, tap → offre. `group.locked` se recalcule **après** enrichissement.
- **Une ligne `SOLID` n'est jamais verrouillée à l'affichage** : c'est un résultat mesuré, et
  *on floute l'action pas encore accessible, jamais la mesure*.
- Sur une ligne floutée, **seul le titre** passe derrière le rideau — **statut, nature et durée
  restent nets**, sinon « à acquérir » se lirait « à renforcer ».
- Le compteur « K entraînement(s) gratuit(s) sur M » est **compté sur les `locked` servis**,
  **jamais posé à 1** : un compte gratuit a réellement plusieurs compétences ouvertes.
- Rideau hors de l'arbre d'accessibilité des deux côtés, un seul chemin vers l'offre, **aucun
  événement d'audience ajouté**.

**« Toutes mes compétences » s'ouvre à TOUT LE MONDE** (arbitrage du propriétaire,
2026-08-22). ⚠️ **Révoque** le garde web `if (!canAccessModule(user, "TCF"))` qui fermait la
page entière. Il y avait **trois** verrous, tous retirés : la page, le lien du Plan côté web, la
ligne du Plan côté mobile. Motif : la page n'affiche que de la **mesure** (compteurs par tâche,
paliers, niveau du domaine) — aucun de ces DTO ne porte de `locked`, parce qu'aucun n'est une
action. Les **destinations** gardent leur verrou servi, opposable en 403 par
`SkillAccessService`.

**Nouvel écran « Ma progression vers le {objectif} »** (`/plan/progression` des deux côtés),
adossé au Plan. ⚠️ **À ne pas confondre avec l'écran de progression générique** (`/progress`
mobile, `/statistiques` web) : celui-là montre les anneaux et les parcours civique/TCF, il reste
en place avec son entrée depuis le Profil. Le nouveau détaille les **4 domaines du Plan**.
- **Titre** : `cycle.objectiveLevel`. 🛑 **Nullable, et aucun front n'invente « B2 »** — absent
  ⇒ « Ma progression » tout court. Un dossier CSP vise A2, une carte de résident B1.
- Contenu : niveau estimé → objectif + rail + couverture du profil · une carte par domaine
  (3 paliers avec leur état en compréhension, 3 tâches avec titre éditorial et compteurs en
  expression, phrase + CTA de mesure si non évalué) · « ce qui a changé » · note.
- 🛑 **Trois éléments de la maquette sont IMPOSSIBLES et ne se fabriquent pas** : les **barres
  de pourcentage par palier** (le score interne du moteur n'est exposé à aucun front — règle
  déjà écrite sur `PlanDomainLevelDto`), **« Voir mon bilan »** (l'écran n'existe ni dans l'app
  ni au serveur) et le **compte de jours** (aucune source). Les paliers portent leur
  `masteryState`, ce qui dit la même chose sans chiffre interdit.
- **Aucun verrou** : l'écran n'affiche que de la mesure.

⚠️ **Ce que les maquettes du Plan demandent et qu'on ne comblera PAS** : les **sous-compétences
de compréhension** (« Informations implicites », « Documents longs »…) **n'existent pas** — le
référentiel n'a qu'une compétence par palier (`CO-A2/B1/B2`, `CE-A2/B1/B2`). Trois blocs de
maquette reposent dessus ; le pendant réel légitime, ce sont les **3 paliers**.

### Écrans — ce qui n'a PAS été créé, et pourquoi
La maquette appelle plusieurs écrans secondaires. **Créés** : fiche d'un domaine, « votre
programme évolue », bilan d'une série ciblée (mobile). **Non créés, l'existant suffisait** :
- **aucun runner de série ciblée** — c'est un `TRAINING` ordinaire, il part dans le runner QCM
  existant (le brief interdit une seconde UX concurrente) ;
- **aucun écran de vérification en situation** — un exercice `REASSESSMENT` porte déjà sa
  `productionTaskId` + `tacheNumero` et réutilise le démarrage de production ;
- les jalons ouvrent les examens blancs existants.
⚠️ **Les écrans de résultat `AIFeedbackCard` / `MAIFeedback` de la maquette sont des
VESTIGES** : note **/100 par critère**, critères « Prononciation » et « Fluidité ». Les
reproduire contredirait deux règles écrites (note retirée d'une tâche isolée le 2026-08-08 ;
interdiction de juger la prononciation depuis une transcription). La bonne référence est
`WResultat.jsx`.


---

## Plan CIVIQUE — répétition espacée et grain mesuré (L10, 2026-09-10)

🛑 **À ne pas confondre avec le Plan TCF.** Deux plans, deux moteurs, aucun effet
croisé (`20_` §12) : le civique ne porte **aucune** métrique CECRL, et le TCF
ignore les notions civiques. L'onglet du Plan choisit lequel s'affiche.

Source : `GET /api/me/civic-plan`. Écrans : `CivicPlanPanel.tsx` ⇄
`civic_plan_view.dart`, libellés `lib/civic-plan.ts` ⇄ `civic_plan_labels.dart`.

### Ce qui n'existe pas, et pourquoi

🛑 **Aucune table.** `20_` §10 prévoyait `civic_plan`, `civic_plan_item`,
`user_civic_notion_progress` et un **job quotidien** pour les échéances. Rien de
tout cela n'a été construit : l'état Leitner se **replie sur l'historique des
réponses** à chaque lecture (`CivicLeitnerResolver`). Trois raisons, dans
l'ordre de leur poids :

1. 🛑 **le tagging est rétroactif.** Au lancement du lot, **0 question sur
   1 016** est taguée. Une table de progression serait née vide et le serait
   restée pour tout l'historique déjà produit ; avec un dérivé, le jour où une
   question reçoit sa notion, les réponses déjà données comptent pour elle ;
2. **recalibrer ne demande aucune migration** — changer un intervalle relit tout
   l'historique au prochain appel (doctrine du dépôt : « un dérivé se relit, il
   ne se persiste pas ») ;
3. **aucun job** : une échéance calculée à la lecture se franchit toute seule.

Corollaire : il n'y a **pas** de route `/recompute`. Recalculer, c'est relire.

🛑 **Aucun `reason_text` servi.** `20_` §10 en prévoyait un ; les phrases vivent
dans les deux fronts, en miroir mot pour mot. Le serveur n'expose que des faits.

### Leitner (`20_` §5.1)

Cinq boîtes, intervalles **0 / 1 / 3 / 7 / 21 jours**. Réponse juste ⇒ boîte + 1
(max 5) ; 🛑 **réponse fausse ⇒ retour boîte 1, toujours**, quelle que soit la
hauteur atteinte. L'échéance se compte depuis la **dernière** présentation.

🛑 **L'ORDRE fait la boîte** : le repli rejoue les réponses triées par instant.
Un `ORDER BY` oublié se verrait comme un plan qui change sans raison.

🛑 **Toutes les sources comptent** — diagnostic, série ciblée, examen blanc
(`20_` §8.2). Écarter une source rendrait le plan sourd à la moitié de ce que le
candidat produit.

### Le parcours d'une cible — l'effet Leitner rendu visible (2026-09-11)

`30_` §510 demande deux choses en une phrase : « **l'effet Leitner doit être
visible** — c'est ce qui rend la valeur Premium tangible » et « **ne jamais
afficher le numéro de boîte**, seulement l'état et la prochaine échéance ».
Longtemps, seule la seconde moitié était tenue : le plan se réordonnait en
silence, donc il ne se distinguait pas d'une liste de thèmes.

`CivicPlanDto.Cible.parcours` sert désormais **exactement 5 `CivicEtapeEtat`**
(`FRANCHIE` / `EN_COURS` / `A_VENIR`), calculés par `CivicLeitner.parcours` :

```
boîte 1 → EN_COURS  A_VENIR  A_VENIR  A_VENIR  A_VENIR
boîte 3 → FRANCHIE FRANCHIE  EN_COURS A_VENIR  A_VENIR
MAITRISEE → tout FRANCHIE, aucune étape en cours
```

🛑 **Le numéro de boîte n'est jamais publié à l'écran.** Il reste sur le DTO pour
l'admin et les tests ; le candidat voit une **position dans un parcours nommé**
(« Étape 3 / 5 »). C'est la forme validée par la maquette du propriétaire, et
elle honore les deux moitiés de la règle.

🛑 **Les libellés des 5 étapes sont GELÉS côté front**, en miroir mot pour mot
(`CIVIC_PATH_LABELS` dans `web_sejoufr/lib/civic-plan.ts` ⇄ `kCivicPathLabels`
dans `mobile_sejourfr/lib/screens/plan/civic_plan_labels.dart`). Le DTO civique
sert des **faits, jamais des phrases** — c'est la règle de tout ce module.

🛑 **Aucun front ne situe le candidat.** Une première version dérivait les trois
états depuis `boite` dans les deux fronts : c'était un front qui classe un nombre
en état pédagogique, et deux implémentations vouées à diverger. Ne pas y revenir.
`CivicLeitnerParcoursTest` verrouille le contrat.

⚠️ **Le parcours peut RECULER** — une erreur renvoie en première étape, comme la
boîte. C'est voulu : c'est exactement ce que le candidat doit voir. Un
`parcours` vide (client servi par un backend antérieur au champ) n'affiche
**aucune carte**, jamais des étapes fabriquées.

### État de maîtrise (`20_` §5.2)

`NON_EVALUEE` (< 2 réponses) · `A_TRAVAILLER` (boîte 1-2) · `EN_PROGRESSION`
(boîte 3) · `MAITRISEE` (boîte 4-5 **et** dernière réponse juste).

🛑 **`NON_EVALUEE` n'est pas un mauvais verdict** : moins de deux réponses ne
conclut rien. C'est l'invariant `null = inconnu`, dont la confusion inverse a
produit les faux `A1_NON_ATTEINT` du TCF (V040/V041/V042).

🛑 **Un THÈME n'est JAMAIS `MAITRISEE`.** Une notion se tient sur quelques
questions ; un thème en porte deux cents. Quatre bonnes réponses de suite sur un
thème ne prouvent rien, et l'annoncer acquis reproduirait « NON FRAGILE ≠ PLUS
RIEN À APPRENDRE ». Le garde-fou **rabat** `MAITRISEE` sur `EN_PROGRESSION` au
grain thème — il ne peut qu'abaisser, jamais relever.

### Score de priorité (`20_` §5.3)

```
score = 3 × (erreur dans les 7 derniers jours)
      + 2 × min(erreurs sur 30 jours, 3)
      + 2 × (pointé par le diagnostic)
      + 2 × (échéance Leitner franchie)
      + 1 × (poids du thème : FAIBLE 2, À_RENFORCER 1, sinon 0)
      − 3 × (maîtrisée)
      − 10 × (contenu insuffisant)
```

🛑 **`NON_EVALUE` pèse 0**, comme `SOLIDE` : un thème que le diagnostic n'a pas
touché n'est pas faible.

🛑 **Le malus de contenu insuffisant est écrasant (−10)**, et c'est voulu : une
notion qui n'a pas de quoi remplir une série ne doit **jamais** remonter en
priorité (`20_` §3.4). Un filtre en amont l'aurait rendue invisible aux mesures.

🛑 **Au grain notion, « pointé par le diagnostic » vaut toujours `false`** : le
diagnostic mesure des **thèmes**. Le compter pour chaque notion d'un thème
faible compterait le même signal deux fois, le poids du thème le portant déjà.

### Le grain se MESURE, thème par thème (`20_` §3.3)

Un thème passe au grain **notion** quand ≥ 80 % de ses questions actives sont
taguées (`sejourfr.civic-plan.seuil-tagging`). 🛑 **Par thème, jamais
globalement** : un thème tagué à 90 % n'attend pas celui qui est à 10 %. Un
thème sans question active reste au grain thème — diviser par zéro pour conclure
« 100 % tagué » basculerait un thème vide.

Le DTO sert `themesParNotion / themesTotal` et l'écran **le dit** : le plan ne se
présente jamais plus précis qu'il ne l'est. `courant = NOTION` seulement quand
**tous** les thèmes ont basculé.

### Freemium

🛑 **Le verrou porte sur la SÉRIE, jamais sur le constat** (`20_` §6, variante
non abonné). Les priorités sont servies **entières** à tout le monde — titre,
état, compteurs. `locked` porte sur l'action, et le **403** de
`POST /api/me/civic-plan/cibles/{id}/serie` est la **même règle**, cette fois
opposable : un front dont le statut premium en cache est périmé reçoit un refus
attendu, à router vers l'offre.

### La série ciblée

`POST /api/me/civic-plan/cibles/{id}/serie?grain=…` crée un **`TRAINING`
ordinaire** joué dans le runner existant — aucun écran de passation n'est créé,
aucun slot d'examen blanc n'est consommé.

🛑 **Ce n'est pas un tirage au hasard** : l'ordre porte l'intention du plan — ce
que le candidat a **raté en dernier** vient d'abord, puis ce qu'il n'a **jamais
vu**, puis le reste. Sans cet ordre, « travailler ce point » redonnerait les
questions déjà réussies. `random()` départage à l'intérieur d'un rang.

### Le bloc « objectif » sert le DIAGNOSTIC, pas une estimation courante

`20_` §6 bloc 1 parle d'un « résultat estimé aujourd'hui » dérivé des « dernières
réponses ». 🛑 **On ne le fabrique pas.** Mélanger des séries d'entraînement
(correction immédiate, questions choisies par le plan) à un examen produirait un
nombre qui ressemble à un score sans en être un. Le diagnostic, lui, pose le
format entier : son score **est** le résultat, directement comparable au seuil.
