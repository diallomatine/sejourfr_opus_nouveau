# Journal — parcours TCF piloté par les évaluations (file persistée)

> **Journal daté, verbatim et intégral.**
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier consigne les arbitrages et révocations : on l'ouvre **avant de changer une règle**, pas
> pour l'appliquer.
> Fichiers jumeaux : `docs/progression/spec-plan-tcf-parcours-evaluations-v2.md` (la spec),
> `docs/progression/audit-plan-tcf-parcours-evaluations-v2.md` (l'audit de Phase 0),
> `docs/regles/plan.md` (la règle, à mettre à jour en Phase 2).

---

## 2026-09-17 — Rapport d'audit validé, **9 arbitrages** sur la file de parcours TCF

**Contexte.** La spec v2 demandait de remplacer le Plan TCF dérivé à la lecture par une **file
persistée** (`journey` / `journey_cycle` / `journey_step`) pilotée par les seules évaluations. L'audit
de Phase 0 a conclu que **le moteur pédagogique supposé par la spec existe déjà en entier**
(priorités sourcées, ordre de gravité déterministe, quota d'étape à 5, maîtrise, niveau par épreuve,
« Évaluer mon niveau », freemium opposable, ordre des épreuves), que le travail réel est la file
elle-même, et que **quatre points de la spec étaient inapplicables en l'état**. Le propriétaire a
validé le rapport et tranché les 9 questions ouvertes.

### Les arbitrages, verbatim

> **Rapport d'audit validé. Arbitrages :**
>
> **D-6 (R1) : option (a).** Seules les évaluations alimentent la file. Les entraînements/révisions
> continuent d'écrire leurs observations pour le profil, mais ne créent jamais d'étape ; ils peuvent
> seulement faire avancer ou terminer une étape existante. Même filtre pour le bootstrap R19.
>
> **D-1 : option (b).** CURRENT = première étape non résolue ET exécutable. Les étapes verrouillées
> restent affichées (cadenas, CTA paywall). La carte « À faire maintenant » = CURRENT. Si aucune
> étape n'est exécutable : carte = première étape verrouillée + paywall.
>
> **D-2 :** lecture Plan (TcfProfileService).
>
> **D-3 :** pas de parcours sans niveau cible. Carte « Choisir mon objectif ».
>
> **D-4 :** la timeline journey remplace le « chemin vers l'objectif » dans le Plan. Le palier reste
> dans l'en-tête niveau actuel / objectif. Supprimer l'ancien dans la même passe.
>
> **D-5 :** quota CO/CE en séries terminées, clé de config distincte (valeur : 2).
>
> **D-7 :** persister la structure + la date de clôture d'une étape (écrite une seule fois, jamais
> réouverte). Ne jamais persister l'état de maîtrise. CURRENT et locked sont calculés à la lecture.
>
> **D-8 :** journey_cycle → journey_lot. DTO : JourneyStepDto.
>
> **D-9 :** ordre existant TcfDomainProfileDto.ORDRE (CO, CE, EO, EE).
>
> Remarques B-5, B-9 à B-14 : acceptées telles que proposées.
> **B-13 :** R11 s'applique tel quel ; branchement après écriture des observations.
>
> Création paresseuse, pas de migration de données.
>
> Avant la Phase 1 : mets à jour la spec et docs/decisions/ avec ces arbitrages, puis STOP pour
> relecture.

---

### D-6 — Seules les évaluations alimentent la file

- **Le défaut constaté.** R1 de la spec (« un micro-entraînement ne peut jamais ajouter d'étapes »)
  était **faux dans l'existant** : `AttemptInteractionService.doFinish` appelle
  `ComprehensionObservationService.record` pour **toute** session TCF terminée — `TRAINING`,
  `REVIEW`, `MOCK_EXAM`, section de diagnostic confondues. Une série ciblée de 20 questions CO-B1
  écrit donc de vraies observations `TCF_CO`, qui deviennent de vraies priorités. En expression, R1
  était en revanche déjà respecté (`SKILL_TRAINING` n'est jamais `isContextual()`).
- **Ce qui n'est PAS révoqué.** Le comportement du producteur d'observations est **inchangé**. La
  doctrine du 2026-08-21 tient : « en compréhension, une bonne réponse est une bonne réponse — il
  n'y a ni assistance ni filet dont l'absence rendrait l'examen plus probant ». Les entraînements
  continuent de nourrir le profil, le niveau et la maîtrise.
- **Ce qui change.** C'est **la file** qui filtre, dans **une seule fonction partagée** par
  `onAssessmentCompleted` et le bootstrap R19 :
  `source_type ∈ {DIAGNOSTIC_EE, DIAGNOSTIC_EO, MOCK_EXAM_EE, MOCK_EXAM_EO}` **ou**
  `source_type ∈ {TCF_CO, TCF_CE}` **et** l'attempt source est un `MOCK_EXAM`. Donc
  `PRODUCTION_EE`/`PRODUCTION_EO` (entraînement libre de production), `SKILL_TRAINING` et toute
  observation CO/CE issue d'un `TRAINING`/`REVIEW` **n'entrent pas** dans la production de lots.
- **Conséquence assumée.** Un candidat qui ne passerait **que** des séries ciblées n'aurait jamais de
  file ; R12 lui propose alors « {Épreuve} — Évaluer mon niveau ». C'est le sens du produit.
- **Ce qu'un entraînement garde le droit de faire** : faire **avancer ou terminer** une étape déjà
  présente (R8, §7.3). Il ne crée jamais.

### D-1 — `CURRENT` = première étape non résolue **et exécutable**

- **Le défaut constaté.** `LearningPlanStep.PROMPTS_PAR_ETAPE = 5` et
  `SkillAccessService.FREE_PROMPTS_PER_SKILL = 2` : un compte gratuit plafonne à **2 sujets sur 5**,
  donc `Progress.completed()` est **structurellement faux** pour lui. C'est un **arbitrage produit
  explicite** du 2026-08-14 (« la vérification de progression est PREMIUM ») dont la javadoc dit
  « ne pas le réparer ». Avec une file à un seul `CURRENT` (§5) et aucun ajout devant (R4), le Plan
  d'un compte gratuit se serait figé **définitivement** sur l'étape 1 — alors que la contradiction
  #1 du dépôt a été tranchée le 2026-08-21 en sens inverse : « le Plan reste intégralement
  visible ».
- **La décision.** `CURRENT` est la première étape non clôturée **et exécutable**. Les étapes
  verrouillées restent **affichées à leur place**, cadenas + CTA paywall. Si aucune étape n'est
  exécutable : `current = null`, `state = LOCKED`, et la carte montre la **première étape
  verrouillée** + paywall.
- **Aucune des deux règles freemium n'est touchée** : ni le plafond de 2 sujets sur 5, ni la
  visibilité intégrale du Plan.
- **L'ordre de la promotion casse une circularité, et il est normatif** (spec §5 bis) :
  `SkillAccessService` reçoit la **première étape non clôturée** (verrous ignorés), **pas**
  `CURRENT`. Lui passer `CURRENT` serait circulaire — `CURRENT` dépend de `locked`, qui dépend de
  l'accès ; et lui passer une étape déjà déverrouillée rendrait inutile l'exemption du 2026-08-21
  (« un candidat non abonné pourra travailler sa priorité 1, vu qu'elle est visible »), donc
  priverait un compte gratuit de l'accès à sa **vraie** priorité n°1.
- **Conséquence à relire** (surfacée pour la relecture de la spec) : pour un compte gratuit, les
  étapes `TRAIN_SKILL` d'expression sont **verrouillées** (non finissables : 2 < 5) tout en restant
  **travaillables** (l'exemption ouvre 2 sujets sur la première). Son `CURRENT` sera donc
  typiquement une série `CO-A2` ou un checkpoint CO/CE, pendant que sa priorité n°1 d'expression
  reste affichée **en tête**, cadenassée. Le parcours avance au lieu de mourir, et la porte
  commerciale reste au bon endroit.

### D-2 — L'écart au niveau cible se lit sur la **lecture Plan**

- Deux lectures du niveau par épreuve coexistent, volontairement :
  `TcfProfileService.levelProfile` (**meilleur** résultat de tout l'historique, lecture du Plan) et
  `NiveauActuelEpreuveResolver` (**moyenne des 3 derniers examens qualifiants**, lecture
  d'affichage, arbitrage du 2026-09-16 : « un niveau affiché est une estimation d'aujourd'hui, pas
  un trophée »).
- **R10 bis lit la lecture Plan.** Motif : brancher la moyenne d'affichage ferait **réordonner la
  file** parce qu'un examen récent a été moins bon, **sans qu'aucune priorité n'ait bougé**. L'ordre
  d'un parcours ne doit pas dépendre d'une moyenne glissante.
- Verrou : test §18-38 (« moyenne d'affichage qui redescend ⇒ l'ordre des lots ne bouge pas »).

### D-3 — Pas de parcours sans niveau cible

- **Le fait de l'existant** : `MeService.updateTargetProcedure` pose
  `target_level = procedure.getRequiredTcfLevel()`. Les deux colonnes `users.target_procedure` et
  `users.target_level` sont donc **nulles ou renseignées ensemble** : « niveau cible inconnu » =
  « démarche non déclarée ». Mesure sur la base de dev : **17 utilisateurs sur 34 sans
  `target_level`**.
- **La décision** : aucun `journey` n'est créé tant que le niveau cible est inconnu. L'endpoint rend
  `state = NEEDS_OBJECTIVE`, `current = null`, `steps = []`. Les fronts affichent la carte
  « **Choisir mon objectif** » → `/parcours` (web) / `target_path_screen` (mobile) →
  `PUT /api/me/target-path`.
- Le niveau visé continue de se lire **exclusivement** chez
  `TargetProcedure.niveauVise(procedure, declare)` — la table des paliers a déjà vécu en six copies.

### D-4 — La timeline du parcours **remplace** le « chemin vers l'objectif »

- Un chemin vers l'objectif existe déjà, servi et affiché : `PlanCycleDto.path`,
  `PlanPathStepDto`, `PlanPathStepKind` (`COMPLETE_PROFILE`/`BUILD_LEVEL`/`STABILIZE`),
  `PlanPathStepStatus` (`DONE`/`CURRENT`/`UPCOMING`), rendu par `plan_path_section.dart` et
  `planPathStepTitle`. Il décrit des **paliers CECRL**, pas des étapes.
- **La décision** : la timeline du parcours le remplace dans le Plan ; le palier reste dans
  l'**en-tête** niveau actuel / objectif. **Suppression de l'ancien dans la même passe** — règle du
  dépôt : refonte = suppression immédiate, fichier + imports + routes + CTA.
- 🛑 **`PlanCycleDto` survit** : `startingLevel`, `targetLevel`, `objectiveLevel`, `state`,
  `domainsEvaluated`, `domainsExpected`, `profileComplete` alimentent l'en-tête et le gate d'examen
  blanc complet. **Seul `path` disparaît**, avec son builder `PlanCycleResolver.chemin(...)`.
- Les tests backend qui le couvrent (`LearningPlanCycleIT`, `PlanCycleResolverTest`) sont **mis à
  jour**, pas contournés.

### D-5 — Quota de compréhension en **séries terminées**, valeur 2

- **Le défaut constaté.** Les compétences de compréhension **n'ont ni tâche ni petit sujet**
  (`skills.task_code` nullable depuis V039) : leur entraînement est une **série ciblée de 20 QCM**
  (`AttemptService.startComprehensionSeries`). Donc `task_code` est nul (pas de sous-titre
  « Tâche 1 »), il n'existe **aucun** compteur « x/5 petits sujets », et la carte de la spec
  (« {trainSkillQuota} petits sujets · ~2 min chacun ») était **littéralement fausse pour la moitié
  du référentiel**.
- **La décision** : pour CO/CE, une étape est clôturée `QUOTA_REACHED` après **2 séries ciblées
  terminées** sur cette compétence depuis la création de l'étape. Clé de configuration **distincte**
  (`trainSeriesQuota`).
- 🛑 **Aucune nouvelle valeur pour l'expression** : le quota d'expression **est**
  `LearningPlanStep.PROMPTS_PAR_ETAPE` et reste son unique autorité. `trainSkillQuota` **n'entre pas
  dans le fichier de configuration** : ce serait la 2ᵉ copie d'un chiffre déjà servi aux deux fronts
  dans `progress.quota`.
- L'unité est **servie** (`progress.unit` ∈ `PROMPT` / `SERIES`) : aucun front ne la déduit de la
  nullité de `taskCode`.

### D-7 — Persister la structure, jamais la maîtrise

- **La décision** : persister **la structure** (quelle étape, dans quel lot, à quelle position,
  issue de quelle évaluation) et la **date de clôture**, écrite **une seule fois**, **jamais
  réouverte**. **Ne jamais persister l'état de maîtrise.** `CURRENT` et `locked` sont **calculés à la
  lecture**.
- **Ce qui disparaît du modèle de la spec** :
  - la colonne **`journey_step.status`** : `UPCOMING`/`CURRENT`/`COMPLETED`/`SKIPPED`/`OBSOLETE` sont
    **tous dérivés** de `closed_at`, `resolution`, `journey_lot.status` et l'ordre de clôture ;
  - l'**index unique partiel `(journey_id) WHERE status = 'CURRENT'`** : sans colonne, il n'existe
    plus. L'unicité de `CURRENT` est garantie **par construction**, par la promotion.
  - `SKIPPED` devient une **nuance de rendu** de `COMPLETED`, dérivée à la lecture : une étape est
    rendue `SKIPPED` lorsqu'une étape de position **inférieure** a été clôturée **après** elle, ou
    ne l'est toujours pas.
- **Ce qui reste persisté, et pourquoi** : `resolution` (`MASTERED`, `QUOTA_REACHED`,
  `SATISFIED_BY_ASSESSMENT`, `SUPERSEDED`) est un **fait daté** que rien ne permet de reconstituer —
  `SUPERSEDED` et `SATISFIED_BY_ASSESSMENT` dépendent d'un **événement**, pas d'un état.
- **Le sens exact de `MASTERED` sur une étape** : « cette étape a été clôturée **parce que** le
  moteur avait conclu au transfert, **à cette date** ». Ce n'est **pas** une réponse à « cette
  compétence est-elle acquise aujourd'hui ? » — cette question a une seule autorité,
  `SkillMasteryEngine`, et elle se relit. Un recalibrage du moteur ne réinterprète donc aucune étape
  déjà clôturée (test §18-43), et une compétence redevenue fragile ne réouvre pas son étape
  (test §18-42) : elle reviendra par un examen (R7).
- **Ce que cet arbitrage désamorce** : la spec persistait `status` et `resolution`, ce qui créait une
  **seconde autorité** sur « cette compétence est-elle acquise ? » — le défaut le plus cher du
  dépôt. Et elle reste compatible avec l'invariant du `CLAUDE.md` racine (« dérivé serveur ⇒ jamais
  persisté ») : ce qui est persisté n'est pas un dérivé, c'est la **mémoire d'une décision
  d'ordonnancement**, qu'aucun recalcul ne peut reconstituer parce qu'elle dépend de l'ordre
  d'arrivée des évaluations. C'est le même argument que le dépôt avait déjà accepté pour
  `plan_pinned_priorities`.

### D-8 — `journey_cycle` → `journey_lot`, DTO `JourneyStepDto`

- **Le défaut constaté.** Trois sens de « cycle » et trois de « étape » auraient coexisté dans le
  même écran : `PlanCycleDto`/`PlanCycleResolver`/`PlanCycleState` (le **cycle de palier CECRL**,
  affiché aux candidats), `LearningPlanStep`/`PlanSkillStepState`/`completedSteps` (les **5 petits
  sujets** d'une compétence), `PlanPathStepDto` (l'**étape du chemin**). C'est exactement la
  collision qui a produit les six copies de la table des paliers.
- **La décision** : la table s'appelle **`journey_lot`** (« lot » est déjà le mot de la spec §2) et
  le DTO servi **`JourneyStepDto`**.

### D-9 — Ordre des épreuves : l'existant

- La spec proposait `["TCF_CO","TCF_CE","TCF_EE","TCF_EO"]` ; l'ordre en vigueur, déjà à l'écran,
  est `TcfDomainProfileDto.ORDRE` = **`TCF_CO, TCF_CE, TCF_EO, TCF_EE`**. **EE et EO étaient
  inversés.**
- **La décision** : l'ordre existant fait foi, et il n'est **pas** rendu configurable —
  `examTypeOrder` **n'entre pas** dans le fichier de configuration. Un second ordre ferait diverger
  la file et « Compléter mon profil ».

---

### Remarques d'audit acceptées telles que proposées

- **B-5 — Le plafond de 3 priorités par lot EST un budget pédagogique, et c'est conscient.** Le
  `CLAUDE.md` racine porte l'invariant inverse, né de l'incident du 2026-08-25 où un plafond de 5
  actions **partagé entre 4 domaines** avait privé trois domaines sur quatre de toute action (10
  actions existaient, 2 étaient servies). Ici le plafond est **par épreuve** (jusqu'à 12 priorités
  vivantes), il ne prive aucune épreuve, et le moteur continue de calculer **tout** : c'est la
  **file** qui borne ce qu'elle met en attente, pas l'écran qui borne ce que le moteur produit.
  🛑 **À écrire dans `docs/regles/plan.md` avec sa raison en Phase 2**, sinon la prochaine lecture du
  `CLAUDE.md` le prendra pour une régression. Limite connue et acceptée de `TOP_SEVERITY` : avec 3
  compétences très faibles, une 4ᵉ n'apparaîtra jamais ; une rotation pourra être ajoutée plus tard
  sans changer le modèle.
- **B-9 — Configuration**. Fichier versionné
  `backend_sejourfr/src/main/resources/plan/tcf-journey-config-v1.json` + son **propre loader
  validant** (refus sur clé inconnue, entrée d'enum manquante, plafond ≤ 0, version discordante ;
  aucune valeur de repli en Java). **Pas** une section de `plan-config-v2.json` : `PlanConfig` porte
  l'interdiction explicite du 2026-08-26 de « rien pouvoir influencer du calcul de maîtrise », et
  `trainSeriesQuota` décide de la clôture d'une étape.
- **B-10 — Endpoint** `GET /api/me/plan/journey`, **sans query param**. Le serveur connaît le niveau
  visé du candidat ; un `?targetLevel=` laisserait un front demander un parcours qui n'est pas le
  sien. Convention du dépôt : `/api/me/*`.
- **B-11 — Faits servis, phrases aux fronts.** Sont servis `type`, `purpose`, `examType`, `section`,
  `taskCode`, `skillCode`, `skillTitle` (= `skills.title`, un fait éditorial), `progress`, `locked`,
  `position`. Sont composés par les fronts dans leurs libellés miroirs (`plan-domain.ts` ⇄
  `plan_labels.dart`) : « Expression écrite · Tâche 1 », « Vérifier mes progrès », « Évaluer mon
  niveau », « Déjà maîtrisée », « Choisir mon objectif ». Les servir ouvrirait une 7ᵉ copie de
  libellés. Même doctrine que `PlanPathStepKind`, `PlanDomainAssessmentKind`, `PlanChangeDto`,
  `PreparationEtape`.
- **B-12 — §19 de la spec retiré en tant que tests.** La règle du `CLAUDE.md` racine (« aucun NOUVEAU
  test sur les fronts ») **prime sur toute consigne de test écrite ailleurs, cette spec comprise**.
  §19 devient une **checklist de relecture manuelle**. Vérification : `npx tsc --noEmit`,
  `npm run build`, `flutter analyze`. Les 16 tests TS et 24 tests Dart existants restent verts ; ceux
  que ce chantier rend rouges se mettent à jour ou se suppriment, un par un.
  §18 (tests métier backend) reste **obligatoire** et passe de 30 à **45 cas**.
- **B-13 — R11 s'applique tel quel ; branchement après écriture des observations.**
  - La page `/diagnostic` restant accessible en permanence, un candidat peut lancer un diagnostic
    rapide après trois examens : le traitement est **exactement** celui de R11 (priorités sur les
    épreuves sans lot ouvert, aucune mesure, aucune étape `DIAGNOSTIC` créée). Rien de spécial n'est
    prévu parce que rien de spécial n'est nécessaire.
  - 🛑 `onTrainingProgress` et `onAssessmentCompleted` se branchent **après** l'écriture des
    observations, et lisent **les compétences réellement écrites**. Motif : en compréhension, la
    compétence est **dérivée du contenu des questions** par `ComprehensionObservationService` —
    l'appelant ne la connaît pas avant.
- **B-14 — `plan_pinned_priorities` est supprimée** (entité, manager, repository,
  `PlanFocusResolver.epingler`). Avec la file, **la position d'une étape EST l'épingle**.
  ⚠️ La dépendance de `SkillAccessService` à la première place doit être reportée sur la **première
  étape non clôturée** du parcours (D-1) : l'oublier recadenasserait l'étape 1 d'un compte gratuit —
  exactement le bug corrigé le 2026-08-21.

### Déploiement

- **Création paresseuse à la première ouverture du Plan. Aucune migration de données.** La migration
  Flyway est **du DDL seulement** : `V066__schema_journey_tcf.sql` dans `00_schema/` (dernier numéro
  utilisé V065 — ⚠️ `100_reference/` est à V114, les plages sont thématiques).
- Motifs : une migration batch devrait rejouer `TcfProfileService` + `SkillMasteryEngine` par
  utilisateur, donc embarquer de la logique applicative dans une migration — ce que le dépôt n'a
  jamais fait ; le bootstrap est **idempotent par construction**
  (`journey_assessment_event` unique sur `(journey_id, source_assessment_id)`) ; un utilisateur qui
  n'ouvre jamais le Plan n'a pas besoin de parcours.
- Volumes mesurés **en SQL sur la base de dev** (aucun LLM, aucun coût) : 34 utilisateurs, 674
  attempts, 105 examens blancs TCF terminés, 18 diagnostics rapides, 6 diagnostics complets, 455
  observations, 18 utilisateurs avec au moins une observation. **Chiffres de dev, pas de prod** — la
  base de production n'était pas accessible depuis la session d'audit.

---

## Revue de livraison — 2026-09-17 (soir)

Le propriétaire a relu les 23 décisions autonomes (`docs/decisions-autonomes-parcours-tcf.md`)
et les a **validées**, avec cinq points de vérification. Verbatim des deux arbitrages qu'elle a
produits :

### D-10 — Le Plan n'exige PAS d'objectif déclaré

> « Le Plan n'exige PAS d'objectif déclaré. L'épingle reste en repli, notée comme dette de
> transition. Vérifier que la carte "Choisir mon objectif" est visible sur les 6 sites. »

**Ce que ça tranche.** La question laissée ouverte par **A23** est close : la suppression de
`plan_pinned_priorities` prévue par la spec §6 **n'aura pas lieu**. La table reste le **repli**
des candidats sans démarche déclarée — **17 sur 34** sur la base de dev —, qui n'ont pas de
parcours (D-3) mais ont bien un Plan.

**Ce que ça impose, et qui a été fait dans la foulée.** L'invitation « Choisir mon objectif »
vivait sur le **seul** écran Plan (web et mobile). Elle est désormais rendue sur les **six**
surfaces qui portent une carte « À faire maintenant » : Plan, Accueil et Réviser, des deux
côtés. 🛑 **Elle n'enlève rien** — elle s'ajoute au-dessus de ce que l'écran affichait déjà, et
la carte d'action reste servie. Un candidat sans objectif garde son Plan entier ; il apprend
simplement que déclarer sa démarche lui ouvre un parcours.

**Dette de transition** : le jour où la démarche deviendra obligatoire, l'épingle n'aura plus
aucun lecteur et `PlanFocusResolver` se réduira à sa lecture du parcours.

### D-11 — Déclencher le parcours à la clôture définitive d'un Attempt de production

> « A16 — inscrire en dette technique : "déclencher le parcours à la clôture définitive d'un
> Attempt de production". »

**Inscrit.** Une épreuve EE/EO **abandonnée** dont la dernière évaluation atterrit avant la
clôture de session n'ouvre aujourd'hui aucun lot. Détail du manque, des quatre chemins de
clôture concernés et de l'arbitrage produit qui reste à rendre : **A16 bis**.

### Trois corrections livrées dans la même revue

| # | Ce qui n'allait pas | Correctif |
|---|---|---|
| **A24** | Le point d'étape de **chaque lot** n'avait aucune action résoluble : `domainesAEvaluer` ne liste que les épreuves **jamais** mesurées, or un checkpoint porte toujours sur une épreuve **déjà** mesurée. | `JourneyStepDto.assessment`, relayé de `PlanDomainAssessmentResolver.pour` — son sixième appelant, pas une sixième règle. |
| **A25** | Sans action résoluble, la carte annonçait l'étape du parcours et **lançait une autre compétence** (repli sur `plan.currentPriority`). | Nature `INDISPONIBLE` : la carte nomme l'étape, sans bouton. `priority` devient nullable, et c'est le seul cas. |
| **A26** | L'exemption freemium, l'élection de `CURRENT` et la première place du Plan pouvaient désigner **trois** étapes différentes (une compétence sans sujet publié les séparait). | Les trois sautent les mêmes étapes, dans le même ordre. Toujours **une** requête : le budget du Plan ne bouge pas.
