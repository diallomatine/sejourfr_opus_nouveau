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

---

## 2026-09-18 — Le parcours devient un **cycle borné**, **13 arbitrages** (D-12 → D-24)

**Contexte.** Le propriétaire a écrit un cadre fonctionnel neuf
(`docs/progression/SPEC_cycle_plan.md`) : le parcours doit se lire comme un **cycle** — un bloc par
épreuve, un examen en fin de bloc, un état « terminé », une transition de fin de cycle, et un cycle
**en attente** invisible qui se remplit pendant qu'on travaille. L'audit de Phase 0
(`docs/audits/AUDIT_cycle_plan.md`) a conclu que le moteur existait déjà à ~80 % sous les noms
`journey` / `journey_lot` / `journey_step` (V066, livré la veille), que le vrai trou du modèle
n'était pas celui que la spec annonçait, et que **quatre exigences de la spec révoquaient des
arbitrages datés**. Les réponses du propriétaire sont dans
`docs/audits/REPONSES_AUDIT_cycle_plan.md`.

🛑 **La doctrine de cette passe, verbatim** :

> « Le comportement décrit dans la spec est la cible et ne se négocie pas. Là où l'existant diverge,
> c'est l'existant qui est révoqué, avec une décision datée. Les arbitrages ci-dessous ne sont pas
> des compromis techniques : ce sont les règles du produit. »

Deux constats de l'audit actés d'emblée : **`Competence` existe** — c'est `Skill` (48 compétences
d'expression + 6 de compréhension), la spec §10.1 était fausse et a été corrigée ; et le
**vocabulaire `journey` / `lot` / `étape` est conservé** — **D-8 est maintenu**, « cycle » n'était
qu'un mot de commodité du cadre fonctionnel.

---

### D-12 — Le cycle borné **se superpose** aux lots, il ne les remplace pas

- **La décision.** `journey_lot` reste ce qu'il est (les ≤ 3 priorités qu'**une** évaluation a
  retenues pour **une** épreuve). Au-dessus, le **cycle** borne : un **bloc par épreuve**, chaque
  bloc contenant les étapes de ses lots ouverts **plus** son `SECTION_EXAM`, un état « bloc
  terminé » quand toutes ses étapes sont clôturées, et un état « cycle terminé » quand les quatre
  blocs le sont.
- **Ce que ça n'est pas** : une renumérotation. `journey_step.position` reste monotone et
  globale — « une renumérotation ferait bouger un parcours que le candidat a sous les yeux » (V066).
  Le **groupement par épreuve est une lecture**, il ne réécrit pas la file.
- **Schéma** (détail en D-13) : `journey` reçoit `module` et `status`.
- **Le niveau de sortie d'un cycle est PERSISTÉ** à l'historisation, et il n'est jamais recalculé
  rétroactivement. Motif : c'est un **fait daté** — « voilà où en était le candidat quand ce cycle
  s'est fermé » —, que le recalibrage d'un moteur ne doit pas réinterpréter. Même argument que
  `resolution` en D-7. Le niveau **d'entrée** d'un cycle est le niveau de sortie du précédent, ou
  le niveau du diagnostic pour le premier.

### D-13 — Le cycle EN ATTENTE est persisté et invisible — **révocation de R2**

- **La phrase révoquée**, `docs/progression/spec-plan-tcf-parcours-evaluations-v2.md` (R2, 2026-09-17) :

  > « **Les autres ne sont pas stockées ni mises en attente.** Si elles persistent, le prochain
  > examen de l'épreuve les fera remonter. »

  Et son miroir dans `docs/regles/plan.md` (« R2 — trois priorités par lot ») :

  > « `maxPrioritiesPerLot: 3` **en est un** — les priorités au-delà ne sont ni stockées ni mises en
  > attente. »

- **La décision.** Un `journey` de statut **`EN_ATTENTE`** existe par `(user, module)`, **invisible
  du candidat**. Chaque évaluation passée pendant le cycle en cours y écrit les priorités
  nouvellement détectées. Une priorité déjà clôturée dans le cycle en cours n'y est **pas**
  recréée, sauf régression mesurée au dernier examen.
- **Ce qui n'est PAS révoqué** : `maxPrioritiesPerLot` reste à **3** (D-20), et le plafond reste un
  **budget par épreuve** au sens de B-5. Ce qui change, c'est la **destination** de ce qui dépasse :
  la mise en attente, au lieu de l'oubli.
- **Unicité** : un seul `EN_COURS` et un seul `EN_ATTENTE` par `(user_id, module)`, par **index
  uniques partiels** sur le patron déjà validé `uq_journey_lot_open_par_epreuve`.
  `uq_journey_user_target UNIQUE (user_id, target_level)` est adaptée en conséquence : elle
  interdisait deux parcours du même niveau cible, donc exactement ce que cette décision exige.

### D-14 — Le statut de l'ÉTAPE reste dérivé ; seul le statut du CYCLE est persisté

- **D-7 est maintenu en entier** : `JourneyStepStatus` (`UPCOMING` / `CURRENT` / `COMPLETED` /
  `SKIPPED` / `OBSOLETE`) reste **dérivé à la lecture**, `locked` aussi, la maîtrise n'est jamais
  persistée, et une clôture ne se réouvre jamais. La spec demandait `A_FAIRE` / `EN_COURS` /
  `REUSSI` **en base** : **refusé**.
- **Ce qui est persisté, et pourquoi** : `journey.status` ∈ `EN_COURS` / `EN_ATTENTE` /
  `HISTORISE`. Ce n'est pas un dérivé : c'est une **mémoire d'ordonnancement**, comme
  `resolution` — rien ne permet de reconstituer « ce cycle-ci a été historisé à cette date parce
  que le candidat a demandé une actualisation », parce que cela dépend d'un **événement**, pas d'un
  état. Même argument que D-7, et que `plan_pinned_priorities` avant lui.

### D-15 — L'examen d'un bloc est **verrouillé par son bloc**, et `SUPERSEDED` disparaît de ce cas

- **La décision.** `SECTION_EXAM` est verrouillé tant qu'une étape `TRAIN_SKILL` du **même bloc**
  n'est pas clôturée. Un bloc sans compétence a donc son examen ouvert immédiatement. Corollaire
  R1 : un examen passé **hors du plan** (Réviser, Examens, sous-épreuve d'un examen complet) valide
  l'étape `SECTION_EXAM` **si et seulement si** cette étape était débloquée au moment du passage ;
  sinon il **ne valide rien** et compte comme entraînement.
- **La règle révoquée**, spec v2 §7.2 (2026-09-17) :

  > « Des étapes `TRAIN_SKILL` du lot sont encore en attente → L'examen devient la nouvelle
  > référence : les étapes non clôturées du lot **et son checkpoint** sont clôturées avec
  > `resolution = SUPERSEDED` (donc rendues `OBSOLETE`, non affichées). Lot → `SUPERSEDED`. »

- **Portée exacte de la révocation** : `SUPERSEDED` disparaît **de ce cas précis** (examen passé
  alors que le bloc n'est pas fini). La valeur reste dans l'enum et garde ses autres emplois
  (remplacement d'un lot par une évaluation plus récente **quand le lot est fini**).
- **Ce que ça change dans le produit** : passer un examen ne « saute » plus le travail restant. Le
  travail prévu reste dû ; l'examen, lui, reste évidemment jouable — il ne fait simplement plus
  avancer le cycle.

### D-16 — Le quota d'une étape de compréhension : **2 séries réussies, ou 4 terminées**

- **La règle révoquée**, `docs/regles/plan.md` (R8, 2026-09-17) et D-5 :

  > « CO / CE — **2 séries ciblées** terminées depuis la création de l'étape. »

  et le javadoc de `JourneyReadService.seriesTermineesDepuisLaCreation` :

  > « 🛑 **Les `NOT_OBSERVED` comptent**, et c'est voulu : le quota mesure le **travail fourni**, pas
  > la réussite — même doctrine que `Progress.completed()`. »

- **La décision.** Une étape de compréhension se clôt par **2 séries réussies**, **ou** par
  **4 séries terminées** quelle que soit leur réussite. L'échappatoire est là pour une raison
  nommée : **un candidat faible ne doit jamais rester bloqué** sur une étape.
- 🛑 **Le seuil de réussite ne crée pas de 8ᵉ déclaration de 0.80** : il est **lu** chez l'autorité
  qui l'a déjà, `learning-plan.comprehension.solid-ratio: 0.80` (`LearningPlanProperties`) — celle
  qui rend déjà le verdict d'**une** série de compréhension.
- **Configuration** : `trainSeriesQuota: 2` garde son nom et devient le nombre de séries
  **réussies** ; l'échappatoire prend une **clé distincte** dans
  `plan/tcf-journey-config-v*.json`. Deux nombres, deux clés : un seul nombre pour deux sens est
  exactement ce que le dépôt paie cher ailleurs.
- **Inchangé** : l'unité reste **servie** (`progress.unit`), et le quota d'expression reste
  `LearningPlanStep.PROMPTS_PAR_ETAPE`, hors configuration (D-5).

### D-17 — Freemium refondu : **un examen blanc gratuit par épreuve de production, à vie**

- **Ce qui est gratuit**, et rien d'autre : le **diagnostic rapide** (priorités et analyse
  comprises) ; **un examen blanc EE**, une fois à vie, analyse IA complète incluse ; **un examen
  blanc EO**, une fois à vie, analyse IA complète incluse ; les examens QCM CO/CE **inchangés**
  (slot 1 offert et rejouable, `AttemptService.enforceMockExamSlotAccess`).
- **Ce qui devient premium sans exception** : tout travail de compétence depuis le Plan, tous les
  sujets d'expression au-delà du freebie, **toute** analyse IA EE/EO au-delà du freebie.
- **Les phrases révoquées.** `docs/regles/freemium.md` :

  > « **Compte gratuit, EE/EO** : 1 essai d'entraînement par épreuve à vie + 1 examen blanc
  > production offert. […] Refaire l'examen 1 = toléré une fois mais consomme les essais
  > d'entraînement restants. »

  `docs/regles/competences.md` (freemium du module Compétences, 2026-08-10) :

  > « **plus la compétence de la priorité n°1 de son Plan**, si elle n'y est pas déjà. »

  > « **les 3 analyses IA offertes à vie ne bougent pas** : un sujet ouvert reste analysable dans la
  > limite du quota existant (`free-analyses`, décompte inchangé). »

  `docs/regles/plan.md` (2026-08-21), révoquée par D-18 ci-dessous :

  > « **Freemium — LA PREMIÈRE PLACE DU PLAN EST TOUJOURS OUVERTE, quelle que soit sa nature** […]
  > *« un candidat non abonné pourra travailler sa priorité 1, vu qu'elle est visible »*. »

- **Conséquences précises** : `sejourfr.competences.analysis.free-analyses: 3` est **supprimé** et
  n'est **pas** remplacé par un quota journalier — la spec parlait de « 1 analyse IA / jour »,
  l'arbitrage est **plus simple** : pas de fenêtre journalière du tout, `dailyQuota` reste
  inexistant. Le seuil « 2 sessions EE+EO confondues » de `ProductionAccessService` devient
  **1 par épreuve, nominatif**. `FREE_TRAINING_PER_EPREUVE = 1` est **supprimé** (il contredisait
  « travailler EE/EO est premium »). Dans `SkillAccessService`, l'ouverture de la compétence du
  focus Plan et celle du premier rang EE/EO sont **supprimées**, et les rangs CO/CE sont traités
  dans la même passe, cohérents avec D-18.
- 🛑 **La consommation du freebie se persiste, et se déclenche à la REMISE DE L'ANALYSE.** Ni au
  démarrage de l'examen, ni sur `doFinish` seul : un abandon, une expiration, un échec technique ou
  un échec du correcteur laissent le freebie **intact**, et le candidat le retrouve. C'est la seule
  lecture honnête de « offert une fois ».
- 🛑 **Un ledger unique**, du type
  `free_entitlement_usage (user_id, code, consumed_at, source_attempt_id)` avec
  `UNIQUE (user_id, code)`, et **les quatre implémentations ad hoc de « première fois gratuite » y
  sont ramenées** (`ProductionAccessService`, `ProductionSubmissionManager.hasFullExamProductionSubmission`,
  `attempts.production_locked`, la convention « slot ≤ 1 »). L'audit a relevé qu'il n'existait
  aucune table de quota et quatre manières différentes de dire la même chose.
### D-17 bis — **Deux** freebies nominatifs, et le **rejeu** est payant par l'ANALYSE

**Arbitrage du propriétaire, 2026-09-18, verbatim :**

> « Le candidat peut faire un examen blanc EE et EO, 1e fois à vie. les tâches sont bien corrigé et
> le llm est appélé. mais, s'il retente le même examen, alors EE ou EO, il doit être premium pour
> l'analyse IA. »

- **Deux freebies, nominatifs** : un pour **EE**, un pour **EO**. Ce n'est pas « un au choix ». Le
  ledger porte donc **deux codes distincts** (`UNIQUE (user_id, code)` de D-17 suffit).
- **Le freebie est complet** : les 3 tâches de l'épreuve sont **réellement corrigées**, le LLM **est
  appelé**, le candidat reçoit son analyse entière. C'est la vitrine du produit, pas un aperçu.
- **Le rejeu est ouvert, c'est l'ANALYSE qui est premium.** Repasser l'examen d'une épreuve dont le
  freebie est consommé n'est pas interdit ; ce qui est fermé, c'est l'**analyse IA** de ce second
  passage. 🛑 **Et aucun quota journalier n'est introduit** : le premier jet de la spec proposait
  « 1 analyse IA / jour », l'arbitrage est **premium, point** (D-17).
- 🛑 **Un rejeu ne déclenche AUCUN appel payant.** Ni correcteur, ni **Whisper**. Le refus se pose
  **avant** le pipeline, comme le fait déjà l'idempotence de V046 (« le rejeu est intercepté avant
  Whisper »). Un rejeu ne consomme rien et ne coûte rien.
- 🛑 **Conséquence à trancher avant P4, côté EO** : sans Whisper, un rejeu EO ne laisse **rien** à
  lire — l'audio candidat n'est jamais conservé (décision consentement), donc il n'y a ni
  transcription, ni note, ni trace. Faire produire un candidat dans le vide est un mauvais geste.
  **Recommandation** : pour EO, présenter le paywall **au démarrage de la tâche**, pas après la
  soumission. Pour EE le texte reste, lui, relisible — le rejeu y est donc honnête même sans
  analyse.
- **Ce que ça ne change pas** : la consommation du freebie reste écrite **à la remise de l'analyse**
  (D-17). Un premier passage interrompu, expiré ou dont le correcteur a échoué **ne consomme rien**,
  et le candidat le retrouve — sinon « offert une fois » voudrait dire « perdu une fois ».

### D-18 — Le Plan d'un compte gratuit est **lisible mais inexécutable**

- **La décision.** Travailler une compétence depuis le Plan est **premium, sans exception**.
  L'exemption du 2026-08-21 est **révoquée** (phrase citée en D-17). `JourneyState.LOCKED`
  permanent pour un compte gratuit est l'effet **voulu** : la carte « À faire maintenant » nomme la
  première étape verrouillée et ouvre le paywall, et le cycle reste affiché en entier avec ses
  cadenas.
- 🛑 **La contradiction #1 du dépôt n'est PAS rouverte.** « On floute l'ACTION pas encore
  accessible, jamais le RÉSULTAT mesuré » reste la règle : le cycle, les priorités, les niveaux
  mesurés et les compteurs **restent lisibles**. Ce qui se ferme, c'est l'**exécution**, pas
  l'affichage. Le cycle visible est l'argument de vente.
- **La circularité que D-1 avait résolue disparaît avec l'exemption** : `SkillAccessService` ne
  reçoit plus la première étape non clôturée pour la déverrouiller. L'ordre de promotion de D-1
  (« `CURRENT` = première étape non clôturée **et exécutable** ») reste valable tel quel ; pour un
  compte gratuit il ne désignera plus rien, et c'est l'intention.

### D-19 — La compétence de compréhension reste le **palier** : pas de `question_skills`

- **Le trou réel, mesuré par l'audit** : il n'existe aucune liaison question ↔ compétence. En
  compréhension, la compétence est **dérivée du contenu** par `ComprehensionObservationService`
  (couple `QuestionType` × `Difficulty`) vers **six** compétences (`CO-A2/B1/B2`, `CE-A2/B1/B2`), et
  `learning_evidence_cle_coherente` **interdit** à une preuve CO/CE de porter un `skill_id`.
- **La décision** : on **ne crée pas** `question_skills`. La compétence de compréhension **est** le
  palier, et R2 se lit « 2 séries réussies **sur le palier** ». La phrase de V318 tient : « les tags
  plus fins viendront plus tard **sans casser ce modèle** — ils se poseront sur les questions,
  jamais en multipliant les compétences ».
- **Conséquence à assumer à l'écran** : un bloc CO ne contient pas « Comprendre l'implicite à
  l'oral » mais la compétence du palier visé. Les libellés de la maquette qui nomment une
  micro-compétence de compréhension sont **illustratifs**, pas contractuels.

### D-20 — Ce qui ne change pas, et qu'il est interdit de rouvrir au passage

- **L'ordre des épreuves reste `CO, CE, EO, EE`** (`TcfDomainProfileDto.ORDRE`), **non
  configurable** — D-9 maintenu. La spec proposait `EE, CO, EO, CE` et une clé de configuration :
  refusé. Le besoin (« EE d'abord, parce que le diagnostic rapide est un écrit ») est déjà satisfait
  **par construction** : le diagnostic rapide crée les lots EE et EO, qui sont donc en tête.
  `ordre_blocs_cycle_initial` **n'existe pas**.
- **`maxPrioritiesPerLot` reste à 3.** La spec demandait 4 : refusé. Aucune clé
  `nb_max_competences_par_bloc` n'est créée — ce serait la 2ᵉ copie d'un nombre déjà servi.
- **`SkillMasteryEngine` est la seule autorité de maîtrise** lue par le cycle. Le moteur
  `progression/` V4.2 reste en **SHADOW** et n'est **pas** consulté. Aucune troisième autorité n'est
  créée. Motif : les deux moteurs portent des seuils volontairement séparés, et laisser le cycle
  choisir « selon le cas » ferait dépendre l'avancement d'un candidat du moteur qui l'a regardé.
- **`CivicExamFormat` n'est pas externalisé** : « c'est du code, pas un réglage. 40 questions et un
  seuil de 32 ne sont pas des paramètres produit. » Le bloc `civique` de la spec §9 est supprimé.

### D-21 — L'ÉPREUVE est visible partout ; le vocabulaire interne n'est jamais à l'écran

- **La décision, et c'est une exigence produit** : chaque étape du plan est rattachée à une épreuve,
  et cette épreuve est **lisible en permanence** — dans « À faire maintenant », dans l'en-tête du
  bloc, sur la ligne d'étape, et sur l'écran de résultat. Le candidat doit savoir à tout moment sur
  quelle épreuve il travaille.
- 🛑 **« lot », « step », « journey », « cycle » ne s'affichent jamais.** Le vocabulaire à l'écran est
  celui des épreuves : *compréhension orale*, *compréhension écrite*, *expression orale*,
  *expression écrite*. Le vocabulaire interne reste interne — c'est précisément ce que D-8
  protégeait.

### D-22 — L'Accueil ne change pas ; le Plan change **à partir de « Votre parcours »**

⚠️ **Amendement du 2026-09-18 (même jour), qui révoque la réponse Q16.** La réponse initiale disait
« `GoalBanner` et les 4 CTA par épreuve sont supprimés de l'Accueil ». Le propriétaire l'a **retirée**
dans la même passe, verbatim :

> « l'accueil, c'est bon, on touche pas. dans le menu plan, on ajoute le parcours à partir de la
> section votre parcours pour le B2, le reste en haut ne change pas, donc tu prends son équivalent de
> la maquette et tu le pointes ici. »

- **L'Accueil est hors périmètre.** Aucune section n'est retirée, ni `GoalBanner`, ni les 4 CTA par
  épreuve, ni « Votre Plan », ni « Votre progression », ni « Vos parcours ». Les suppressions décrites
  par la spec §8 pour l'Accueil sont **annulées**. ⚠️ Le seul changement que l'Accueil subira est
  **indirect et non visuel** : sa carte « À faire maintenant » lit le parcours et le freemium de
  D-17/D-18, elle affichera donc un cadenas pour un compte gratuit. Ce n'est pas une refonte d'écran.
- **Le Plan change à partir de la section « Votre parcours vers le B2 » — et seulement à partir de
  là.** Restent **inchangés** : l'en-tête (`Top`, kicker et titre), le `ModuleToggle`, le bloc
  objectif (`CycleGoal` / `GoalStrip`) et la section « À faire maintenant ».
- **Les maquettes de référence sont les deux `.html` neufs**, et c'est leur **équivalent** qui vient
  se brancher à cet endroit :

  | Maquette | Ce qu'elle fournit, à partir du `sectionHead` « Votre parcours vers le B2 » |
  |---|---|
  | `docs/progression/plan_cycle.html` | l'encart de cycle (barre d'avancement continue, « 3 étapes sur 8 terminées », repère de cycle) ; les **blocs d'épreuve dépliables** (initiale CO/CE/EE/EO + titre + méta + pastille d'état, corps replié sauf le bloc courant) ; les **lignes d'étape** avec leur état ; l'**encart d'examen** imbriqué (`VERROUILLÉ` / `DISPONIBLE`) ; la note « vous pouvez travailler dans l'ordre que vous voulez » ; le bouton « Voir ma progression » |
  | `docs/progression/cycle_termine.html` | l'état **cycle terminé** : encart à 100 %, les quatre blocs repliés en `TERMINÉ`, le séparateur « Prochaine étape », et la **carte finale à deux actions** (« Passer l'examen blanc complet » + « Actualiser mon plan sans examen complet ») |

- ⚠️ **Ce que la maquette montre au-dessus de cette section ne s'applique pas** : `plan_cycle.html`
  place sa propre carte « À faire maintenant » dans son en-tête — c'est l'**existant** qui est
  conservé à cette place, pas celui de la maquette.
- **Conséquence sur les primitives de kit** : les cinq briques manquantes relevées par l'audit
  (accordéon de bloc, carte de fin de cycle à deux actions, barre d'avancement continue, encart
  d'examen, liste d'historique) restent toutes à créer **dans les deux kits, dans la même passe** —
  elles vivent précisément dans la zone qui change.
- **Ce qui devient sans objet** : le risque relevé en C9 par l'audit (retirer les CTA de l'Accueil
  supprimerait un chemin de lancement d'examen). Les CTA restent, le chemin reste.

### D-23 — Périmètre : ce qui sort du chantier

| Sujet | Décision |
|---|---|
| **Civique** | **Sort du chantier.** Le moteur est livré **TCF d'abord**. Le plan civique reste dérivé (Leitner). La spec §10.3 est sans objet pour cette livraison. |
| **Mode module global persisté** | Chantier **à part** (P9). L'audit a relevé 7 mécaniques concurrentes et zéro persistance : ça ne se règle pas dans un écran. |
| **Offline mobile N1** | Sort du chantier. ⚠️ **Sauf un bug, à corriger immédiatement en ticket séparé** : `mobile_sejourfr/lib/core/auth/auth_controller.dart:81-124` — un `GET /me` en échec **réseau** efface les tokens et déconnecte l'utilisateur. |
| **Page Progression (P7)** | **Bloquée.** Le propriétaire fournira le **template de l'écran historique des cycles**. Ne rien concevoir ni implémenter avant réception ; le seul travail autorisé en amont est l'**endpoint d'agrégation**, et seulement après P6. |
| **Documents périmés** | Les 5 relevés par l'audit (C10) sont corrigés en **P2**. |

### D-24 — Le branchement post-évaluation a **quatre** points, et c'est normatif

- L'audit a établi qu'il n'existe **aucun événement Spring** dans le backend, et que le pattern en
  place est l'appel direct best-effort (`REQUIRES_NEW`, exception avalée).
- **La décision** : le moteur de cycle se branche sur les **quatre** points, et
  🛑 **un branchement sur `doFinish` seul est un échec de la phase** :
  1. `AttemptInteractionService.doFinish`, après `recordProgression` — tous les chemins de clôture
     QCM, après le point d'idempotence ;
  2. la **sortie anticipée EE/EO** de `doFinish` (l. 300-306), qui ne passe pas par la suite ;
  3. `FullTcfExamService.buildAndPersistCecrlIfReady` — le parent `TCF_COMPLET` ne passe **jamais**
     par `doFinish` ;
  4. `FullTcfExamService.lockProductionSubAttempts` → **exclu explicitement** : il pose `TERMINE`
     sans qu'aucun examen ait été passé. L'oublier inventerait des mesures.
- L'idempotence reste celle de V066 : `journey_assessment_event UNIQUE (journey_id,
  source_assessment_id)`, chronologie par `completed_at`.

---

## Revue de livraison — P4, 2026-09-18 (quota d'étape + freemium, backend seul)

D-16, D-17, D-17 bis et D-18 sont **appliqués**. Ce qui suit n'ajoute aucun arbitrage : ce sont
les **décisions d'implémentation prises seul** pour les exécuter, consignées ici parce qu'elles
touchent des règles du produit.

### Le chemin retenu pour « série réussie » — on la LIT, on ne la recalcule pas

Le verdict d'une série de compréhension était **déjà écrit** :
`ComprehensionObservationService` pose `learning_plan_observations.status = SOLID` dès que le
ratio de bonnes réponses du palier atteint `learning-plan.comprehension.solid-ratio` (0.80).
`JourneyReadService` relit donc ce statut — **aucune 8ᵉ déclaration du seuil**, aucun second
ratio, une règle une autorité. Conséquence assumée : un `NOT_OBSERVED` compte comme série
**terminée** (elle a été jouée, elle alimente l'échappatoire) et **jamais** comme réussie.

`seuil_reussite_competence` **n'entre donc pas en configuration** (question laissée ouverte par
la spec §9) : le calcul ne lit pas un seuil du tout. Et comme il ne restait plus rien d'autre à
y mettre, **`cycle-config-v1.json` et `CycleConfigLoader` n'ont pas été créés** — l'échappatoire
a rejoint le fichier qui a déjà son loader validant, `plan/tcf-journey-config-v2.json`.

### v1 reste chargeable, et un retour arrière reste une variable d'environnement

`plan/tcf-journey-config-v1.json` a reçu `trainSeriesFallbackQuota: 2`, **égal à son
`trainSeriesQuota`**. Comme les séries réussies sont toujours un sous-ensemble des terminées,
« 2 réussies **ou** 2 terminées » **est** mot pour mot l'ancienne règle de D-5 (« 2 séries
terminées »). Ce n'est pas une réécriture de la version livrée : c'est la même règle exprimée
dans le vocabulaire de v2. Sans cela, revenir à v1 aurait fait échouer le démarrage — le record
Java est partagé par les deux versions.

### Le `progress` servi ne montre pas l'échappatoire

`done` = séries **réussies**, `quota` = `trainSeriesQuota`. Trois motifs : afficher « 2 séries
ratées sur 4 » invite à **échouer vite** pour se débarrasser d'une étape ; un filet annoncé n'en
est plus un ; un seul champ `done`/`quota` ne peut porter qu'**une** échelle, et servir la plus
exigeante ne **survend jamais** l'avancement. **Le DTO ne change pas**, donc rien à propager aux
fronts sur ce point. Corollaire : les deux lecteurs du quota (l'écran et la clôture) partagent
désormais la **fonction** `JourneyReadService.etapesAuQuota`, faute de pouvoir partager le
nombre — `JourneyService.onTrainingProgress` ne relit plus `progress.done >= progress.quota`.

### La gratuité s'écrit à la PREMIÈRE analyse rendue, et elle porte son attempt

Un examen, c'est 3 tâches. La ligne `free_entitlement_usage` est écrite dès que la
**première** analyse est rendue, avec `source_attempt_id` ; les **2 tâches restantes du même
attempt** restent corrigées au titre de la même gratuité.

⚠️ **L'alternative a été écartée pour une raison d'argent** : n'écrire qu'après la 3ᵈ tâche
laissait un candidat abandonner chaque examen sur la 2ᵈ tâche et obtenir ainsi des corrections
LLM **sans aucune borne**. « Offert une fois » ne peut pas signifier « offert autant de fois
qu'on abandonne ». La règle de D-17 est respectée telle quelle : un abandon, une expiration, un
échec technique ou un échec du correcteur ne produisent **aucune** analyse, donc ne consomment
rien.

**Un abonné ne consomme rien** : le ledger dit « ceci lui a été *offert* ». Lui écrire une ligne
lui confisquerait sa gratuité pour le jour où il se désabonnerait.

### Le verrou de production devient PAR ÉPREUVE, jusque dans l'examen complet

Deux gratuités nominatives ne se ferment pas ensemble. `FullTcfExamService` pré-termine donc
**la** sous-épreuve concernée et pose `attempts.production_locked` **sur ce sous-attempt** (la
colonne existe sur `attempts`, donc sur les sous-attempts aussi : rien à migrer). Le drapeau du
**parent** ne vaut plus que pour les **deux** épreuves fermées, et `FullTcfExamResponseBuilder`
lit le **OU** des deux — l'ancienne donnée, où seul le parent le portait, reste lue telle quelle.

`ProductionAccessService.isFullExamProductionLocked(userId)` (sans épreuve) ne rend `true` que
quand **les deux** gratuités sont consommées : le jalon « examen blanc complet » du Plan n'a
qu'un booléen à servir, et annoncer un cadenas alors qu'une épreuve reste offerte serait faux.

### Ce qui a été supprimé, et où

| Supprimé | Où il vivait |
|---|---|
| `FREE_TRAINING_PER_EPREUVE = 1` | `ProductionAccessService` |
| « 2 sessions d'examen, EE+EO confondues » | `ProductionAccessService` + `AttemptManager.countProductionExamSessions(userId)` (variante globale) |
| `ProductionSubmissionManager.hasFullExamProductionSubmission` | + sa requête `countByUserAndParentEpreuve` |
| `sejourfr.competences.analysis.free-analyses: 3` | `application.yaml` + `CompetenceProperties.Analysis.freeAnalyses` |
| `SkillAccessService.FREE_PROMPTS_PER_SKILL = 2` | `SkillAccessService` |
| les 4 ouvertures d'office du freemium | `SkillAccessService.ouvert(...)`, méthode entière |
| `SkillAccessService.resolve(userId, focusSkillId)` | sa dépendance à `PlanFocusResolver` avec elle |

`PlanFocusResolver` **survit** : il reste l'autorité de la première place du Plan, qui continue
d'être épinglée, servie et affichée. Ce qui disparaît, c'est son effet sur l'**accès**.
`AttemptManager.countProductionExamSessions(userId, epreuve)` survit aussi : il ne sert plus
qu'à désigner le prochain slot de la grille, plus de budget freemium.

### Ce qui n'a PAS été rouvert

- La **contradiction #1** : tout ce qui est mesuré reste servi. Les tests le vérifient
  explicitement (Plan entier + `locked: true`, cycle entier + `state: LOCKED`).
- Le **slot 1 QCM CO/CE**, « offert **ET** rejouable à volonté » : inchangé, et
  `ProductionAccessService.isProductionExamLocked` rend `false` pour CO/CE sans même lire le
  ledger.
- L'**EE et l'EO du diagnostic**, totalement offertes : elles n'atteignent jamais le ledger
  (garde `isDiagnostic` dans `FreeExamEntitlementService`).
- Aucun **quota journalier** n'a été introduit ; `dailyQuota` n'existe toujours pas.

---

## 2026-09-19 — Module CIVIQUE : **13 arbitrages** (D-25 → D-37), l'arrêté contre le produit

**Contexte.** L'audit `docs/audits/AUDIT_cycle_plan_civique.md` (v1) concluait que R2 était
inapplicable au civique faute de contenu : **1 couple (notion × mention) sur 138** portait les
~20 questions qu'exige « 2 séries réussies », et combler le déficit demandait **≈ 1 480 questions**.
Le propriétaire a produit un **contre-audit** (`docs/progression/civique/BRIEF_contre_audit_civique.md`)
opposant à ce raisonnement le **texte officiel** : l'arrêté du 10 octobre 2025 relatif au programme,
aux épreuves et aux modalités d'organisation de l'examen civique (JORF n° 0240 du 12 octobre 2025,
NOR **INTV2527907A**).

`docs/audits/AUDIT_cycle_plan_civique_v2.md` a vérifié le texte sur Légifrance et repris les mesures.
Trois résultats commandent les arbitrages ci-dessous :

1. **Au grain des notions officielles, sans filtre de mention, R2 est applicable** : 13 unités sur 14
   portent ≥ 20 questions. Il en manque **11**, toutes sur « Laïcité ».
2. 🛑 **L'examen blanc global n'est conforme à l'arrêté sur aucun axe.** **0 examen sur 33** déjà
   passés respecte la répartition officielle ; les mises en situation sortent à **7,7 par examen au
   lieu de 12**, et **58 %** de celles tirées l'étaient dans une thématique où l'examen réel n'en pose
   aucune.
3. 🛑 **Avec le filtre de mention, un examen conforme est IMPOSSIBLE** pour CSP (Laïcité : 1 question
   pour 2 exigées ; mises en situation Principes : 1 pour 6) et pour NAT (mises en situation
   Principes : 5 pour 6). Seul CR y parvient.

Réponses du propriétaire : `docs/audits/REPONSES_AUDIT_civique_v2.md`, 2026-09-19.

---

### D-25 — **L'arrêté du 10 octobre 2025 est la source de vérité du module civique**

**La décision, verbatim** :

> L'arrêté du 10 octobre 2025 est la source de vérité du module civique. Là où le produit diverge du
> texte, c'est le produit qui a tort, y compris quand la divergence est ancienne, documentée et
> testée.

**Ce que le texte fixe, et qui n'est donc ni configurable ni négociable** (art. 1 à 3 + annexe I) :

| Thématique | Total | Unités officielles et quotas |
|---|---|---|
| Principes et valeurs de la République | **11** | Devise et symboles **3** · Laïcité **2** · *Mises en situation* **6** |
| Système institutionnel et politique | **6** | Démocratie et droit de vote **3** · Organisation de la République **2** · Institutions européennes **1** |
| Droits et devoirs | **11** | Droits fondamentaux **2** · Obligations et devoirs **3** · *Mises en situation* **6** |
| Histoire, géographie et culture | **8** | Périodes et personnages **3** · Territoires et géographie **3** · Patrimoine **2** |
| Vivre dans la société française | **4** | S'installer **1** · Accès aux soins **1** · Travailler **1** · Autorité parentale et système éducatif **1** |

**40 questions** = 28 connaissances + 12 mises en situation. **Pour toutes les mentions**, et sur
**une seule** annexe I. Durée 45 min, seuil 80 %. Art. 3 : « Chaque candidat devra répondre à un
**nombre équivalent de questions par thématique et notion**. »

#### 🛑 Révocation — la phrase de V058

**Phrase révoquée, citée verbatim.** Origine :
`backend_sejourfr/src/main/resources/db/migration/00_schema/V058__referentiel_civique_valide.sql`,
en-tête, section « CE QUE LE CORPUS IMPOSE, ET QUI N'EST PAS NÉGOCIABLE PAR LA TAXONOMIE » :

> « CSP, CR et NAT ne sont pas trois niveaux du même programme : ce sont trois programmes
> différents. Le CR ne contient AUCUNE question sur le gouvernement, le NAT AUCUNE sur l'école ni
> sur la santé, le CSP AUCUNE sur Napoléon, l'Europe, les écrivains ou la DDHC. Sur ces 46 notions,
> 12 seulement portent 5 questions dans les trois mentions. Ce n'est pas un défaut de découpage. »

**Pourquoi elle est fausse** : le raisonnement est **circulaire**. Le corpus a été **écrit** par
mention, puis on a déduit du corpus que le programme l'était. V058 le dit lui-même quelques lignes
plus haut — « le référentiel a été reconstruit **à partir du corpus réel** plutôt que déduit ». Et la
mesure le confirme : sur **976** questions actives, **15** seulement (1,5 %) citent une démarche dans
leur énoncé, et **aucune n'est exclusive d'une démarche** — « S'installer et résider en France »,
qui couvre les démarches d'accès à la nationalité, est au programme **pour toutes les mentions**.

**Ce qui est révoqué avec elle** :

> « D'où l'état NON_APPLICABLE, servi par le plan […] : « zéro question dans cette mention » n'est
> pas « notion mal faite », c'est « pas pour ce candidat ». »

**Ce que V058 conserve** : les 46 notions, leurs descriptions et leurs frontières restent **valides
et utiles**. Ce n'est pas un mauvais référentiel, c'est un référentiel d'une **autre nature** : une
taxonomie **éditoriale**, faite pour écrire et relire des questions. Voir D-26.

⚠️ **Une migration livrée ne se réécrit pas** : V058 reste en base telle quelle. La révocation vit
ici et dans `docs/regles/domaine.md`, **jamais** en `UPDATE` de son commentaire.

**Ce qui est à nommer partout désormais** : l'arrêté du 10 octobre 2025 (NOR INTV2527907A) est cité
comme **source du référentiel** dans `docs/regles/domaine.md` et dans la migration qui créera la
table des unités officielles. L'audit v2 a relevé qu'il **n'était cité nulle part dans le dépôt**.

---

### D-26 — Le cycle civique compte au grain des **16 unités officielles**

- **L'unité travaillable du cycle est l'unité officielle de l'annexe I**, pas la notion interne.
- 🛑 **16 lignes, pas 14.** Dans la répartition officielle, « Mises en situation » figure **au même
  niveau qu'une notion**, avec son propre quota, dans deux thématiques : Principes (6) et Droits et
  devoirs (6). Le cycle en fait donc une unité travaillable à part entière, **dans ces deux blocs
  seulement**. 14 notions de connaissance + 2 unités de mises en situation = **16**.
- **Les 46 notions internes restent la granularité du plan dérivé** — choisir *quoi* faire
  travailler. Le **cycle** compte au grain officiel. Deux rôles distincts et nommés : l'officielle
  **mesure**, l'interne **écrit**.
- **Une table de référence**, pas une colonne (Q-F24) : libellé, thématique, ordre, **quota officiel
  par examen**. Le tirage conforme (D-29), le cycle et l'écran lisent **le même objet**. Le
  rattachement des 46 notions internes s'y fait par **FK**.
- **Conséquence sur R2** : 13 unités sur 14 portent ≥ 20 questions ; « 2 séries réussies de 10 »
  s'applique **sans réécriture**. Le déficit de la v1 était l'effet cumulé de deux découpages dont
  **aucun n'est officiel** — une taxonomie de travail à 46 entrées et un filtre de mention.
- **Conséquence sur le moteur** : 🛑 **D-15 s'applique mot pour mot** (« l'examen d'un bloc est
  verrouillé tant qu'une unité du même bloc n'est pas clôturée »). R1, R2, R3, le cycle en attente,
  la fin de cycle et l'historisation se transposent **tels quels**. Le cycle civique est le **même
  moteur** que le TCF, à l'axe des blocs près : la **thématique** au lieu de l'épreuve.

#### Ce que ça rend caduc

- **L'option α de l'audit v1** (« le bloc de thème se clôt sur son seul examen, faute de contenu »).
  Elle était un **repli subi** et la v1 la signalait elle-même comme un écart à « le moteur civique
  ne réinvente aucune règle ». Il n'y a plus d'écart à signaler.
- **Les deux options de Q1 de la v1** — généraliser `skills` ou rendre l'observation polymorphe — sont
  caduques **dans leur motif** : voir D-32.
- **Phrase révoquée, citée verbatim.** Origine : `docs/progression/civique/SPEC_cycle_plan_civique.md`
  §1, ligne « `Skill` (compétence) » :
  > « **Notion civique** (`civic_notions`) | 40 notions. »

  Ni 40, ni les 46 réellement actives : l'unité du cycle est une des **16** unités officielles.

---

### D-27 — La mention ne filtre plus le contenu ; `difficulty` devient une métadonnée éditoriale

- **Le filtre `q.difficulty = :mention` est retiré de la lecture** côté civique (option **B** du §4.4
  de l'audit v2) : l'entraînement, le diagnostic et le cycle ne filtrent plus.
- **La colonne reste en base**, intacte, comme **métadonnée éditoriale** : elle dit de quelle campagne
  vient une question, et l'admin continue de la voir. 🛑 Aucune migration de données, aucun `DROP` :
  le retour arrière est **un changement de variable de code**, pas une migration.
- **Le civique s'aligne sur le régime TCF**, où `AttemptService.resolveDifficulty` dit déjà « le TCF
  n'est jamais filtré par niveau : le test est unique pour tous ». C'est exactement ce que l'arrêté
  prescrit : un programme, une épreuve, pour toutes les mentions.
- ⚠️ **Le filtre n'était déjà pas une règle du module** : `LotService` (l. 139, 173) passe `null` en
  `difficulty` — les **lots d'entraînement civiques ignorent la mention depuis toujours**. Le filtre
  ne vivait que sur trois chemins sur quatre.
- **La mention reste l'objectif d'un cycle**, jamais son pool : la démarche visée et le seuil. Voir
  D-32.

#### 🛑 Ce qui est supprimé avec le filtre, et pas laissé vide

« Refonte = suppression immédiate de l'ancien. » Sans filtre de mention, ces deux règles ne
discriminent plus rien : **0 couple** tombe sous le seuil, et `NON_APPLICABLE` devient **impossible**.
Une règle morte qui donne l'illusion d'un garde-fou est pire que pas de garde-fou.

| Supprimé | Où il vit |
|---|---|
| `CivicDotation` (enum entier, 68 l., + `CivicDotationTest`) | `service/plancivique/CivicDotation.java` |
| `questions-min-par-notion: 5` | `application.yaml` + `CivicPlanProperties.questionsMinParNotion` |
| `estServable()` et ses appels | `CivicPlanService` (5 filtres), `CivicPlanDto.Cible.dotation` |

**Phrase révoquée, citée verbatim.** Origine : javadoc de `CivicDotation` :

> « **Trois états, pas deux — et la différence est ÉDITORIALE.** Le référentiel validé (V058) l'a
> mesurée question par question : CSP, CR et NAT ne sont pas trois niveaux du même programme, ce sont
> **trois programmes différents**. »

**Phrase révoquée, citée verbatim.** Origine : javadoc de
`CivicPlanProperties.questionsMinParNotion` :

> « 🛑 **Compte PAR MENTION.** Une notion peut être pleinement dotée pour un candidat NAT et vide pour
> un CSP : rendre un verdict global effacerait exactement cette nuance. »

**Ce qui est conservé** : `questions-par-serie: 10` (tenable sur les 16 unités, minimum 9) et
`seuil-tagging: 0.80` (franchi partout, 97–98,6 % ; garde-fou du **plan dérivé**, dont le cycle ne
dépend pas). ⚠️ Défaut à corriger avec : `tirageSerieCiblee` a un `LIMIT` et **ne complète pas** —
une unité à 9 questions rend une série de 9, en silence.

---

### D-28 — Le **contrôle de couverture** précède P8.A, et il tranche une question

- **Q-F30 est lancé avant P8.A.** Zéro appel LLM : extraction des listes publiques du ministère et
  rattachement aux 16 unités officielles.
- **Ce qu'il doit établir, en une question** : les trois listes publiques (CSP ≈ 212, CR ≈ 205, NAT en
  PDF) se recouvrent-elles largement, ou portent-elles des contenus réellement distincts ?

| Résultat | Conséquence |
|---|---|
| **Recouvrement large** | Le retrait du filtre (D-27) est confirmé **définitivement**, y compris pour la composition des examens blancs. |
| **Divergence réelle** | Le filtre revient **pour la seule composition de l'examen blanc**, jamais pour l'entraînement ni pour le cycle, et le rapport dit exactement quelles questions écrire par mention. |

🛑 **Dans les deux cas, l'entraînement et le cycle restent sans filtre.** R2 en dépend, et rien dans
l'arrêté ne justifie de restreindre ce qu'un candidat peut **travailler**.

- **Ce qui a motivé cette prudence** : l'audit v2 a établi que le ministère publie **trois listes
  distinctes par mention**. Le **programme** est unique — une seule annexe I, 40 questions pour toutes
  les mentions — mais la **banque publiée** ne l'est pas. C'est le seul argument sérieux contre D-27,
  et il se mesure au lieu de se supposer.
- **Livrable** : couverture du stock SejourFR par unité officielle **et** par liste publique, taux de
  recouvrement entre les trois listes, et la liste des unités où le stock ne couvre pas le programme.
  Plan détaillé : annexe P8.0 de `AUDIT_cycle_plan_civique_v2.md`.
- ⛔ **Aucun import.** Les énoncés publics n'ont pas leurs réponses ; un import serait du travail
  éditorial déguisé en migration.

---

### D-29 — **L'examen blanc doit simuler l'examen réel** : chantier séparé et prioritaire (P8.A)

**La décision, verbatim** :

> L'examen blanc doit simuler l'examen réel. Un examen blanc qui tire 8/8/8/8/8 au lieu de
> 11/6/11/8/4 ne prépare pas au bon examen, quelle que soit la qualité de ses questions. C'est la
> promesse centrale du produit, et elle n'est aujourd'hui pas tenue sur un seul des 33 examens passés.

**P8.A passe AVANT le cycle.** Le tirage devient une **contrainte dure** sur **trois axes** :

1. **11 / 6 / 11 / 8 / 4** par thématique ;
2. le **quota par unité officielle** à l'intérieur de chaque thématique (3/2, 3/2/1, 2/3, 3/3/2,
   1/1/1/1) ;
3. **12 mises en situation, placées uniquement en Principes (6) et Droits et devoirs (6)**.

**Les cinq exigences de la phase** :

1. **Une autorité unique de la répartition officielle, en code**, au même titre que
   `CivicExamFormat` : les 5 thématiques, leurs unités, leurs quotas, le placement des 12 mises en
   situation. 🛑 **Aucune de ces valeurs n'est un réglage.**
2. **Le quota par unité devient une contrainte du tirage**, pas une consigne — le rattachement à
   l'unité officielle entre dans la requête de composition. (Ordre de préférence du dépôt : le schéma
   avant la consigne.)
3. 🛑 **Le fallback de `pickQuestionsForTemplate` est encadré.** Un examen officiel ne doit **jamais**
   pouvoir compléter hors règles en silence : si les règles ne peuvent pas être satisfaites, l'examen
   **échoue bruyamment**, il ne se dégrade pas. **C'est le défaut le plus grave de l'audit**, parce
   qu'il rend toute règle future inopérante sans le dire.
4. **Le format de l'examen de thème** (20 Q / seuil 16 / 20 min) applique les **proportions
   officielles internes** à la thématique. Il ne peut pas être conforme à l'examen réel — ce n'est pas
   son objet — mais il doit en respecter la **structure**. Voir D-31.
5. 🛑 **Le diagnostic civique est préservé tel quel.** Sa configuration `connaissances: 28` +
   `mises-en-situation: 12` est le **seul** endroit du dépôt qui tient le partage officiel, et il le
   tient parce qu'il est **déclaré**, pas déduit d'un tirage. **Ne pas y toucher.**

**Ce que P8.A ne coûte pas** : **aucune question à produire**. L'audit v2 a mesuré qu'un examen
parfaitement conforme est tirable du stock actuel, les 14 quotas et les 12 mises en situation
couverts — **à condition** que le filtre de mention soit retiré (D-27).

---

### D-30 — Les 11 templates « Focus » mono-thème sont **dépubliés**

- Un template qui tire **40 questions d'une seule thématique** est **structurellement non conforme** :
  il ne peut pas s'appeler « examen blanc ».
- **Ce qu'ils offraient — travailler un thème — est exactement ce que le cycle fournit.** Il n'y a
  rien à remplacer.
- Les 11 : `civique-csp-institutions`, `civique-csp-histoire`, `civique-csp-societe`,
  `civique-cr-institutions`, `civique-cr-droits`, `civique-cr-histoire`, `civique-cr-societe`,
  `civique-nat-institutions`, `civique-nat-droits`, `civique-nat-histoire`, `civique-principes`.
- ⚠️ Leur matrice était de toute façon **incomplète** : 5 cases manquantes sur 15 (CSP sans Droits ni
  Principes, CR sans Principes, NAT sans Société ni Principes).
- **Q-F20 devient sans objet** : ils ne sont pas laissés en dette, ils partent.

---

### D-31 — L'examen de thème respecte la **structure** officielle, pas le format officiel

- **20 questions / seuil 16 / 20 min** est un **format SejourFR**, jamais un format officiel.
  Confirmé en base (11 attempts) et en code.
- Il applique les **proportions officielles internes** à sa thématique. Conséquence directe (Q-F21) :
  🛑 **un examen de thème ne contient de mises en situation que dans les thématiques où l'examen réel
  en pose** — Principes et Droits et devoirs. Aucune ailleurs.
- **Le format déménage en P8.1** (Q-F17) : 20 / 16 / 20 min rejoignent `CivicExamFormat`, et
  `AttemptService` perd ses **6** constantes privées (`CIVIQUE_EXAM_SIZE`, `CIVIQUE_EXAM_TIME`,
  `CIVIQUE_EXAM_THRESHOLD`, `CIVIQUE_THEME_EXAM_SIZE`, `CIVIQUE_THEME_EXAM_TIME`,
  `CIVIQUE_THEME_EXAM_THRESHOLD`).
- ⚠️ **Motif** : `CivicExamFormat` dit de lui-même « c'est du code, pas un réglage […] même traitement
  que `DureeEpreuve` et `TargetProcedure` », mais 40 et 32 y vivaient **en double** de
  `AttemptService` (l. 63, 65) — et `exam_templates` en portait une **3ᵉ** copie. Le cycle en aurait
  fait une 4ᵉ.

---

### D-32 — Le schéma du cycle civique

| # | Décision |
|---|---|
| **Q-F4** | `journey` reçoit **`target_procedure`**. La mention ne filtre plus le contenu, mais elle reste l'**objectif** d'un cycle civique : la démarche visée et le seuil. |
| **Q-F5** | **`entry_score` / `exit_score`**, colonnes neuves. 🛑 **Aucune réinterprétation des colonnes CECRL** : un score n'est pas un niveau. `entry_level` / `exit_level` restent TCF. |
| **Q-F6** | Le bloc désigne sa thématique par une **FK `theme_id`**. Un thème est une donnée de `themes`, pas une valeur d'enum. |
| **Q-F7** | **Résolue par D-26.** `journey_step` et `learning_plan_observations` pointent l'**unité officielle**, dans sa table de référence de 16 lignes. **Ni `skills` généralisée, ni `civic_notions` polymorphe.** |

**Pourquoi Q-F7 se résout ainsi** : les deux options de l'audit v1 cherchaient où loger **46 notions
mouvantes**. L'unité est désormais une **table de 16 lignes stables, adossées à un arrêté**. Elle n'a
ni à envahir `skills` (dont `chk_skills_section` et les 4 colonnes `NOT NULL` n'ont aucun sens
civique), ni à rendre `civic_notions` polymorphe.

**Les contraintes à lever, telles que l'audit v1 les a inventoriées** : **S-1** et **S-2**
(`chk_journey_target_level`, `chk_journey_entry_level`, `chk_journey_exit_level` — bornés CECRL),
**S-3** et **S-4** (`chk_journey_lot_exam_type`, `chk_journey_step_exam_type` — 4 valeurs TCF),
**S-5** et **S-10** (`journey_step.skill_id` FK + `chk_journey_step_train_skill` +
`uq_journey_step_lot_skill`), **S-8** (`chk_learning_plan_observation_source` — 9 valeurs, aucune
civique). **S-6** (`chk_skills_section`) et **S-9** (`chk_free_entitlement_code`) **ne sont plus
concernées** : la première par D-32-Q-F7, la seconde par D-33.

**Ce qui est déjà acquis et ne bouge pas** : `journey.module` admet déjà `CIVIQUE`
(`chk_journey_module`), `journey.status` et ses deux index **partiels** `uq_journey_en_cours` /
`uq_journey_en_attente` sont sur `(user_id, module)` — rien à migrer.

⚠️ **`E-4` s'aggrave et doit être traité** : `JourneyService.getOrCreate` est câblé `Module.TCF`
(l. 164, 177) **et** sort à sec si `TargetProcedure.niveauVise(...)` rend `null`. Un candidat
purement civique — CSP déclaré, aucun `target_level` CECRL — n'obtiendrait **jamais** de cycle. C'est
le cas d'usage majoritaire du module.

---

### D-33 — Freemium civique : **pas de ledger**, règle simplifiée

Le ledger « 1 examen de thème offert à vie » est **abandonné**. Il transposait au QCM une règle écrite
pour les **productions IA**, qui n'a pas lieu d'être ici : **un QCM ne coûte aucun appel LLM.**

| Élément | Régime |
|---|---|
| Diagnostic civique | **Gratuit** |
| `civique-decouverte` (40 Q, seuil 32) | **Gratuit**, comme aujourd'hui — promesse déjà publiée et affichée, elle est tenue. ⚠️ **À rendre conforme en P8.A** comme les autres. |
| Examens de thème | **Premium** |
| Autres examens blancs globaux | **Premium** |
| Travailler une unité depuis le Plan | **Premium** |

- **Q-F9 : oui.** `enforceMockExamSlotAccess` est **retiré du chemin civique** — il est remplacé par la
  règle ci-dessus, et **deux verrous sur le même bouton** sont exactement le patron qu'on cherche à
  éviter (c'est ce qui a produit les 4 implémentations ad hoc de « première fois gratuite » que D-17 a
  dû rassembler).
- **Q-F8 et Q-F11 : sans objet.** Aucun code de gratuité civique n'est créé ;
  `chk_free_entitlement_code` n'est **pas** touché, et `FreeExamEntitlementService` reste ce qu'il
  est — le service des deux gratuités **de production**.
- ✅ **Le Plan civique est déjà conforme à D-18** : `CivicPlanService.demarrerSerie` oppose un **403**
  sans `hasCivique`. Rien à révoquer de ce côté, contrairement au TCF où il a fallu fermer
  `SkillAccessService`.

#### 🛑 Révocation — la spec civique §3.3

**Phrases révoquées, citées verbatim.** Origine :
`docs/progression/civique/SPEC_cycle_plan_civique.md` §3.3 « Freemium civique » :

> « 1 examen blanc de thème, **une fois à vie**, au choix du candidat | ✅ »
>
> « Même règle de consommation que le TCF : le droit n'est consommé qu'à l'**examen terminé et
> corrigé**. Abandon ou expiration ne consomment rien. Même ledger `free_entitlement_usage`. »

**Motif** : « la même règle que le TCF » désignait la règle des **productions** (D-17 / D-17 bis), pas
celle des QCM. Le TCF laisse ses examens QCM CO/CE sous `enforceMockExamSlotAccess` — « slot 1 offert
**et rejouable** ». La spec civique croyait reprendre une règle QCM et appliquait une règle LLM.

⚠️ **À surveiller, sans agir maintenant** : un examen complet gratuit et rejouable sans limite peut
cannibaliser l'abonnement. On ne le restreint pas — la promesse est **publique** — mais l'usage réel
doit être **mesuré** avant d'ouvrir le sujet.

---

### D-34 — Un changement de mention **ne détruit pas** le cycle : **A27 s'applique**

- **A27 s'applique tel quel** : « Changer d'objectif ne détruit pas le cycle : son niveau cible est
  mis à jour. » Ici, c'est la **mention** qui est mise à jour.
- **Pourquoi** : la mention ne filtrant plus le contenu (D-27), **le travail fourni reste valide**.
  Historiser détruirait un cycle que rien n'invalide.
- ⚠️ **Mais le changement reste sans trace** : `users.target_procedure` est **écrasé**, sans table
  d'audit, sans colonne, sans trigger. **Consigner la bascule d'objectif sur le cycle** — c'est
  désormais la **seule** occasion de l'écrire.

#### 🛑 Révocation — la spec civique §5.6

**Phrase révoquée, citée verbatim.** Origine :
`docs/progression/civique/SPEC_cycle_plan_civique.md` §5 point 6 :

> « **Mention** — un changement de mention (CSP → NAT) en cours de cycle : on historise et on repart
> sur un cycle neuf, ou on conserve le cycle et on change seulement le pool ? Recommandation :
> **historiser**. »

**Motif** : la recommandation d'historisation reposait sur « changer de mention, c'est changer de
programme » — la conclusion de V058, révoquée par D-25. Le conflit **C-4** que l'audit v1 relevait
entre cette recommandation et A27 **disparaît** : il n'y a plus deux règles, il n'y en a qu'une.

---

### D-35 — Le contenu : ce qui est produit, et ce qui ne l'est pas

| # | Décision |
|---|---|
| **Q-F27** | **Les 11 questions de « Laïcité » manquantes sont produites** (9 → 20). C'est le **seul** contenu que l'audit identifie comme nécessaire, et il débloque la **dernière** unité où R2 échoue. |
| **Q-F28** | `vs_urgences_secours` (15 q.) → **S2 Accès aux soins**. 🛑 **Ce n'est pas un arbitrage** : l'annexe I range explicitement « les numéros d'urgence » sous « L'accès aux soins ». |
| **Q-F26** | **Les 108 mises en situation hors Principes et Droits restent du contenu d'entraînement**, simplement **exclues des examens blancs**. Ni retypage, ni reclassement. |
| **Q-F12** | **Révisée.** Les mises en situation restent **sans notion de connaissance**, mais elles **deviennent une unité travaillable à part entière** dans les blocs Principes et Droits et devoirs — l'arrêté leur donne un quota au même niveau qu'une notion. Elles clôturent **leur propre étape**, et uniquement celle-là. |
| **Q-F14** | **Les 17 questions de connaissance non taguées sont taguées à la main.** Aucun appel LLM. |

**Pourquoi pas de retypage (Q-F26)** : une mise en situation **n'est pas** une question de
connaissance — elle décrit une situation et demande la bonne conduite. Les retyper fausserait le
diagnostic (`connaissances: 28` / `mises-en-situation: 12`) et dégraderait le stock. Et les reclasser
vers Principes ou Droits serait une **trace fausse** : une mise en situation « vous arrivez aux
urgences sans carte Vitale » ne devient pas un cas de laïcité parce qu'on change son `theme_id`.
**Ce qui est faux, c'est qu'un examen blanc puisse les tirer** — la correction est dans le tirage
(D-29), pas dans les données.

#### 🛑 Révocation — la spec civique §3.1

**Phrase révoquée, citée verbatim.** Origine :
`docs/progression/civique/SPEC_cycle_plan_civique.md` §3.1 « Les mises en situation » :

> « 12 des 40 questions de l'examen sont des mises en situation, **réparties sur les thèmes** — ce
> n'est **pas** une thématique. »

**Motif** : l'arrêté les place **6 en Principes et 6 en Droits et devoirs, zéro ailleurs**. Et les
deux options que la spec proposait tombent toutes les deux : l'**option A** (« un type de question
présent dans **chaque** bloc ») est fausse — il n'y en a pas dans 3 blocs sur 5 ; l'**option B** (« un
6ᵉ bloc transversal ») est fausse aussi — elles appartiennent à **deux** blocs nommés. La bonne
réponse n'était dans aucune des deux : ce sont **deux unités de deux blocs**, et c'est D-26.

---

### D-36 — **D-23 est levée** sur le périmètre civique ; « le plan civique reste dérivé » est maintenu

**Phrase partiellement révoquée, citée verbatim.** Origine : **D-23** de ce fichier, 2026-09-18,
tableau « Périmètre : ce qui sort du chantier », ligne « Civique » :

> « **Sort du chantier.** Le moteur est livré **TCF d'abord**. Le plan civique reste dérivé (Leitner).
> La spec §10.3 est sans objet pour cette livraison. »

| Fragment | Statut |
|---|---|
| « Sort du chantier » | 🛑 **Levé.** La condition « TCF d'abord » est **remplie** : le chantier TCF est livré le 2026-09-19 (7 commits, `./mvnw verify` 3 048 + 1 345, 0 échec). P8 s'ouvre. |
| « Le moteur est livré TCF d'abord » | ✅ **Tenu**, et c'est ce qui autorise la levée. |
| « **Le plan civique reste dérivé (Leitner)** » | ✅ **MAINTENU, et c'est normatif.** Le cycle **se superpose** au plan dérivé (D-12 transposé), il ne le remplace pas. |

**Ce que le maintien implique, et qui n'est pas négociable** : `CivicLeitner`,
`CivicLeitnerResolver`, `CivicMaitrise`, `CivicPrioriteScorer`, `CivicChangementsResolver`,
`CivicEtapeEtat` **restent**. Ils produisent six choses que rien d'autre ne produit — l'état de
maîtrise servi (dont les deux fronts tiennent un miroir de libellés **gelés**), l'échéance de revue,
les 5 crans de parcours, l'ordre servi du plan, le **tagging rétroactif** (toute réponse déjà donnée
compte le jour où sa question reçoit sa notion) et l'**absence de job quotidien**.

⚠️ **Seul `CivicDotation` part** (D-27), parce que c'est le seul dont la raison d'être était le filtre
de mention.

---

### D-37 — Ce qui n'est **pas** rouvert au passage

- **Le diagnostic civique** : préservé tel quel, configuration comprise (D-29, exigence 5).
- **Les 46 notions internes et leurs descriptions** : valides, utiles, conservées (D-25, D-26).
- **V058 en base** : une migration livrée ne se réécrit pas. La révocation vit dans ce journal et dans
  `docs/regles/domaine.md`.
- **La contradiction #1 du dépôt** : on floute l'**action**, jamais le **résultat mesuré**. Scores,
  états et compteurs civiques restent lisibles pour un compte gratuit.
- **`FreeExamEntitlementService` et `chk_free_entitlement_code`** : intouchés (D-33).
- **`seuil-tagging: 0.80`** et **`questions-par-serie: 10`** : conservés (D-27).
- **Les plafonds d'affichage** `priorites-visibles: 3` / `revisions-visibles: 3` : inchangés, et
  jamais lus comme un budget de calcul.
- **La page « historique des cycles »** : ⛔ **toujours bloquée**, template non fourni. Ne rien
  concevoir. Travail autorisé en amont, et seulement après les écrans : étendre
  `GET /api/me/plan/journey/history` au module civique — le contrat est arrêté et les deux fronts
  codent déjà dessus.
- **Aucun nouveau test sur les fronts** : l'invariant du `CLAUDE.md` racine s'applique.

---

### Ordre des phases arrêté

**P8.0** (cette passe) → **Q-F30** (contrôle de couverture, D-28) → **P8.A** (conformité de l'examen
blanc, D-29) → **P8.1** (rangement) → **P8.2** (référentiel officiel) → **P8.3** (schéma du cycle) →
**P8.4** (moteur) → **P8.5** (freemium) → **P8.6** (kits) → **P8.7** (écrans) → **P8.8** (les
11 questions de Laïcité). **P8.9** (historique des cycles) : ⛔ bloquée.

---

### Compléments d'arbitrage — P8.0 validée, 3 points tranchés (D-38 → D-40), 2026-09-19

La livraison de P8.0 laissait trois points en suspens. Le propriétaire les a tranchés dans la même
journée. Consignés ici plutôt qu'en amendement de D-26 / D-29 / D-30 / D-28 : **ce journal
s'ajoute, il ne se réécrit pas**.

#### D-38 — Le quota par unité vit dans la **table des 16**, pas dans `CivicExamFormat`

**La décision, verbatim** :

> Le quota par unité vit dans la table des 16, pas dans `CivicExamFormat`. Une seule autorité, comme
> convenu en Q-F24 : le tirage, le cycle et l'écran lisent le même objet. `CivicExamFormat` ne garde
> que ce qui n'est pas par unité — 40 questions, seuil 32, 45 min, le partage 28/12.
>
> Les totaux par thématique (11/6/11/8/4) sont dérivés par **somme des quotas d'unité**, jamais
> déclarés une seconde fois.

**Ce que ça tranche** : l'annexe P8.0 §B.1 signalait que `CivicExamFormat` **et** la table étaient
tous deux candidats, et qu'**une seule** devait porter le quota. C'est la table.

| Porte le quota par unité | Ne le porte pas |
|---|---|
| **La table des 16 unités officielles** (`quota_examen`) | `CivicExamFormat` : 40 questions, seuil 32, 45 min, partage 28 / 12 |

🛑 **Les totaux par thématique ne sont déclarés nulle part.** 11 / 6 / 11 / 8 / 4 se **dérivent** par
somme des quotas d'unité. Les déclarer aussi en ferait une 2ᵉ copie — et un jour, l'une des deux
aurait tort.

**Les trois garde-fous, parce qu'on met de la loi dans une table** :

1. 🛑 **La table est seedée par migration et n'est PAS éditable en admin.** Aucun endpoint, aucun
   écran, aucun `AdminCivicUniteController`. Une valeur d'arrêté ne se modifie pas depuis une
   interface.
2. 🛑 **Un `CHECK` ou un test normatif vérifie que la somme des 16 quotas vaut 40**, et que les
   quotas de mises en situation totalisent **12**.
3. 🛑 **Un test verrouille les 16 lignes et leurs quotas**, avec **l'arrêté cité en commentaire**.

> **Clause de repli, verbatim** : « Si ces trois garde-fous ne tiennent pas, reviens vers moi **avant
> d'écrire la migration** — on remettra le quota en code. »

⚠️ **Conséquence pour P8.A** : la phase **dépend** de la table, donc de **P8.2**. Si l'ordre des
phases doit bouger pour ça, c'est un point à remonter, pas à arbitrer seul.

#### D-39 — Ne jamais supprimer une ligne référencée par un `attempt` — **règle générale**

**La décision, verbatim** :

> Dépublication des Focus confirmée. Ne jamais supprimer une ligne référencée par un attempt. C'est
> la **règle générale**, pas une exception pour ce cas.

- **D-30 est confirmée** : les 11 templates « Focus » passent `is_published = false`, leurs lignes
  restent.
- 🛑 **Et la portée est élargie** : ce n'est pas un contournement de FK sur ce cas précis, c'est un
  **invariant du dépôt**. Un `attempt` est l'historique d'un candidat et la source de vérité du
  freemium ; ce qu'il référence ne peut pas disparaître sous lui. Vaut pour `exam_templates`,
  `questions`, `themes`, `civic_notions` et la table des 16.
- **Ce qui est déjà cohérent avec cette règle** : `civic_notions.merged_into_id` (« une notion qui
  fusionne n'est jamais SUPPRIMÉE », V051) et `questions.is_active` (jamais de `DELETE`).
  `GuestAttemptPurgeJob` fait exception dans l'autre sens et le dit : « un attempt rattaché à un
  compte est l'historique du candidat […] il ne doit pouvoir être emporté par aucune passe de purge,
  même sur une liste d'ids fausse ».
- 🛑 **La bonne mécanique est donc toujours la désactivation**, jamais le `DELETE` : `is_published`,
  `is_active`, ou une colonne de retrait dédiée.

#### D-40 — Q-F30 : le **recouvrement d'abord**, le rattachement seulement s'il sert

**La décision, verbatim** :

> Pas d'appel LLM, et l'étape 3 n'est probablement pas nécessaire. La question décisive de Q-F30
> est : les trois listes publiques se recouvrent-elles, ou portent-elles des contenus distincts ?
> Elle se répond par comparaison des énoncés entre les trois listes, **sans rattacher quoi que ce
> soit aux 16 unités**. Inverse donc l'ordre :
>
> - d'abord le **recouvrement** entre CSP, CR et NAT — c'est ce qui décide si l'examen blanc se
>   compose par mention ;
> - ensuite seulement, **et seulement si c'est utile**, la couverture du stock SejourFR par unité.
>
> Le rattachement fin au grain de l'unité est le poste coûteux que tu as identifié ; il ne doit pas
> être payé pour répondre à une question qui n'en a pas besoin. Si le recouvrement se mesure mal par
> comparaison directe, **remonte le problème avec un chiffre** avant de proposer un LLM.

**Le nouvel ordre de Q-F30** :

| # | Étape | Conditionnelle ? |
|---|---|---|
| 1 | Extraire les 3 listes (énoncé, thématique de publication, liste d'origine) | non |
| 2 | **Mesurer le recouvrement** entre CSP, CR et NAT par comparaison directe des énoncés | non — **c'est le livrable décisif** |
| **STOP** | Le résultat décide si l'examen blanc se compose par mention (D-28) | — |
| 3 | Couverture du stock SejourFR par unité officielle | ⚠️ **seulement si elle sert encore** |

🛑 **Ce qui est interdit** : payer le rattachement fin aux 16 unités pour répondre à une question qui
n'en a pas besoin. Et 🛑 **aucun appel LLM**, ni à l'étape 2, ni à l'étape 3 : si la comparaison
directe échoue, on **remonte le problème avec un chiffre** — combien d'énoncés ne s'apparient pas, et
pourquoi — avant de proposer quoi que ce soit de payant.

**Ce que ça préserve de D-28** : dans les deux cas, l'entraînement et le cycle restent **sans
filtre**. Seule la composition de l'**examen blanc** dépend du résultat.

#### D-41 — **Précision de D-29** : P8.2 est scindée, et P8.A garde sa place

⚠️ **Ce n'est pas une révocation de D-29.** « Avant le cycle » est **tenu** : P8.2a n'est pas le
cycle, c'est le **référentiel que la conformité consomme**.

**L'ordre arrêté** :

**P8.1** (rangement) → **P8.2a** (la table des 16 **seule** : schéma, seed, garde-fous, rattachement
des 46) → **P8.A** (conformité du tirage) → **P8.2b** (retrait du filtre de mention, suppression de
`CivicDotation` et de `questions-min-par-notion`) → **P8.3** et la suite.

**Le motif, verbatim** :

> Le motif n'est pas une préférence d'ordonnancement, c'est une **dépendance à sens unique** : P8.A
> doit être écrit et testé **avant** que le retrait du filtre change les résultats de tirage. Si les
> deux passent ensemble, un examen qui devient conforme **et** un pool qui double d'un coup, on ne
> sait plus attribuer un écart de mesure à l'un ou à l'autre. P8.2a fournit à P8.A la seule chose
> dont il a besoin — **la table et ses quotas** — et rien de plus.

🛑 **Deux conséquences à vérifier en ouvrant P8.2a** :

1. **La table doit pouvoir être seedée et testée sans que le filtre de mention bouge.** Si l'un des
   **trois garde-fous de D-38** exige le retrait du filtre pour tenir, **le dire avant d'écrire la
   migration** — ce serait le signe que la séparation ne tient pas, et on reviendrait au **quota en
   code**.
2. **Le rattachement des 46 notions internes aux 16 unités se fait en P8.2a**, pas plus tard. P8.A en
   a besoin pour contraindre le tirage.

**Ce que P8.2b garde, et elle seule** : les 4 points de lecture du filtre
(`CivicPlanRepository` × 3, `CivicDiagnosticComposer`, `AttemptService.resolveDifficulty`), la
suppression de `CivicDotation` + `CivicDotationTest`, le retrait de `questions-min-par-notion`, le
champ `dotation` du DTO et ses **2 miroirs front**.

#### D-42 — **Résolution de D-28** : Q-F30 est close, le retrait du filtre est **confirmé**

**Le résultat mesuré** (annexe Q-F30 partie 1 de `AUDIT_cycle_plan_civique_v2.md`) : les listes
publiques CSP et CR ne se recouvrent qu'à **9,0 %** en appariement strict (33 énoncés communs sur
190 et 209), **24,2 %** en incluant les quasi-appariements. T4 Histoire est à **zéro** commun sur
47 et 49. NAT est resté inaccessible (403 Cloudflare, Ray ID `a3d80c56ef04063a`).

**La décision, verbatim** :

> Q-F30 est close. **Le retrait du filtre est confirmé.**
>
> Le 9 % ne décide rien […]. Ce qui décide, c'est ce que l'appariement a mis au jour : **les
> 14 notions officielles sont présentes dans les deux listes, aucune absente**. La divergence est
> **rédactionnelle, pas programmatique**. Deux façons de demander la même chose ne font pas deux
> programmes.

**Les trois motifs, dans l'ordre, verbatim** :

> 1. Le filtre **ne filtrerait pas les listes du ministère** — il filtrerait **notre** corpus, par une
>    étiquette assignée à l'écriture. Et la mesure de l'audit v2 §4.2 est sans appel : **aucune des
>    976 questions n'est exclusive d'une démarche**. L'étiquette ne porte pas de programme, elle porte
>    une **campagne de rédaction**.
> 2. Garder le filtre **rend un examen conforme impossible pour CSP et pour NAT**. Entre une fidélité
>    cosmétique à un artefact de publication et un examen blanc qui simule l'examen réel, le choix est
>    fait — c'est le principe posé en **D-25**.
> 3. La voie « un candidat CSP doit retrouver ses questions révisées » **ne tient pas** : nos énoncés
>    ne sont pas ceux du ministère. Un candidat qui a révisé la liste CSP ne les retrouvera chez nous
>    **dans aucun scénario**.

#### Ce que ça clôt dans D-28

**Phrase résolue, citée verbatim.** Origine : **D-28** de ce journal, tableau des deux issues :

> « **Divergence réelle** | Le filtre revient **pour la seule composition de l'examen blanc**, jamais
> pour l'entraînement ni pour le cycle, et le rapport dit exactement quelles questions écrire par
> mention. »

🛑 **Cette branche ne s'ouvre pas.** La divergence mesurée est **d'énoncé**, pas de programme ; la
condition qui l'aurait déclenchée n'est pas remplie. **D-27 s'applique sans réserve et sans
exception** : le filtre part de l'entraînement, du cycle **et** de la composition de l'examen blanc.

#### NAT n'est plus une condition

> « **N'attends pas NAT.** Si CSP et CR montrent déjà un programme identique sous des énoncés
> réécrits, NAT ne renversera pas le raisonnement — et même s'il divergeait, **l'arrêté a déjà tranché
> avec son annexe I unique**. Récupère quand même le PDF à la main quand tu pourras : il sert comme
> **entrée de contenu, pas comme condition**. Non bloquant. »

#### La partie 2 de Q-F30 reste fermée

> « Le rattachement fin aux 16 unités **ne sert plus la décision**. On la rouvrira si un besoin de
> **couverture éditoriale** apparaît, pas avant. »

⚠️ **À ne pas confondre** : le **rattachement des 46 notions internes aux 16 unités** reste dû, et il
se fait en **P8.2a** (**D-41**) — c'est une autre chose que le rattachement des **énoncés publics du
ministère**, qui est la partie 2 fermée ici.

#### Une exigence de forme, née du 191 / 209

> « Un point sur le 191/209 contre le « ≈ 212 / ≈ 205 » de l'audit v2. Merci de l'avoir signalé plutôt
> que de l'absorber. Fais une passe de relecture du v2 pour **marquer explicitement tout chiffre qui
> ne vient pas d'un `SELECT` ou d'une mesure reproductible**. Les chiffres SQL sont solides, mais un
> rapport où les deux natures se ressemblent **invite à fonder une décision sur une estimation**. Ce
> n'est pas une phase, c'est une **annotation**. »

🛑 **Règle générale qui en découle, pour tout rapport à venir** : un chiffre annoncé porte la **nature
de sa provenance**. Un comptage produit par un modèle de lecture n'est **pas** une mesure et ne doit
jamais se présenter comme telle. Appliqué au v2 par une légende et des marques en ligne.

#### D-43 — **E-19 est une décision, pas une dette** : aucune fabrique de création de notion

**Ce que l'audit v1 demandait** (E-19) : « Pas de fabrique de test `civicNotion(...)` ; les IT les
créent à la main (≥ 2 occurrences). **Extraire dans `TestData`.** »

🛑 **Non implémentée, et la prémisse était fausse.** Mesure faite en ouvrant P8.1 : **aucun test ne
crée de notion**. `grep -rn "new CivicNotion()" src/test/` ne rend **rien**. Les IT civiques
**lisent le référentiel seedé** par V051 / V058 en JDBC — ce qui est exactement ce qu'un module
piloté par un référentiel doit faire.

**Pourquoi la fabrique demandée serait NUISIBLE, et pas seulement inutile.** Une
`TestData.civicNotion(theme, code, label)` laisserait un test **inventer une notion hors arrêté**,
donc hors des 16 unités officielles. Avec `chk_civic_notion_rattachee` (V115), elle échouerait de
toute façon si elle ne déclarait pas son unité — et si elle en déclarait une, elle ferait passer
pour du programme quelque chose que le texte ne contient pas. C'est contre le garde-fou 1 de
**D-38** (« une valeur d'arrêté ne se modifie pas depuis une interface »), transposé aux tests.

**Ce qui est réellement dupliqué, et qui reste à extraire le jour où ça sert** : un helper de
**LECTURE** sur le référentiel seedé. `SELECT id FROM civic_notions WHERE code = ?` vit dans
**3 fichiers** (`CivicTaggingVerdictIT`, `SuggestionParCampagneIT`, `CivicNotionServiceIT`), et le
motif « prendre N notions d'un thème puis désactiver le reste » dans **2** (`CivicPlanServiceIT`
×2, `CivicPlanNotionParcoursIT`). ⚠️ Il n'a **pas** été extrait en P8.2a : la table des 16 n'en a
pas eu besoin, et un helper sans appelant est du code mort (règle du dépôt). Il s'extraira au
**premier appelant réel**, probablement en P8.4.

🛑 **E-19 ne doit plus remonter comme une dette à combler.** C'est une décision, avec son motif.

---

#### D-44 — **Précision de D-29** : le partage 28 / 12 est de la loi **partout**, y compris dans le diagnostic

**La décision, verbatim** :

> Les deux 28/12 : **fusionne-les.** Ta distinction se défend sur le papier, mais elle ne tient pas
> à l'épreuve : le jour où quelqu'un change le YAML, le diagnostic **cessera de simuler l'examen
> légal et rien ne l'en empêchera**. Le partage 28/12 est de la loi partout où il apparaît, y
> compris dans le diagnostic.
>
> D-29 protégeait le **comportement** du diagnostic — il est le seul endroit du dépôt qui tienne le
> ratio officiel — **pas l'endroit où le nombre est écrit**. Le faire lire `CivicExamFormat`
> **renforce** cette protection au lieu de l'affaiblir.
>
> Si la clé YAML doit rester pour une raison que je ne vois pas — un `config-version` qui la pilote
> réellement, un test qui la fait varier — dis-le et on la garde. Sinon **elle disparaît, elle ne
> devient pas un alias**.

**L'échappatoire a été vérifiée, et elle n'existe pas.** Quatre mesures avant de trancher :

| Question | Mesure |
|---|---|
| `config_version` pilote-t-il ce partage ? | ❌ **Non.** Il est **écrit** sur `civic_diagnostic_sessions` (`CivicDiagnosticService:156`) et **jamais relu** pour réinterpréter un résultat civique. Le seul `getConfigVersion()` qui branche quelque chose est du côté TCF (`TcfJourneyConfigProvider`, `PlanConfigProvider`), et il charge un **fichier**, pas ce bloc. |
| Un test fait-il varier les deux valeurs ? | ❌ **Non.** Aucun. |
| Un profil surcharge-t-il le bloc `civic-diagnostic` ? | ❌ **Non.** Une seule déclaration, dans `application.yaml`. Ni `application-dev`, ni les ressources de test. |
| Qui les lisait ? | **Un seul appelant** : `CivicDiagnosticComposer`, au moment de la composition. |

🛑 **Elles ne pilotaient rien.** Elles offraient seulement à quelqu'un la possibilité de faire
cesser le diagnostic de simuler l'examen légal, sans que rien ne l'en empêche. **Supprimées, pas
aliasées.**

**Ce que la fusion change, exactement** :

| Avant | Après |
|---|---|
| `sejourfr.civic-diagnostic.connaissances: 28` · `mises-en-situation: 12` | **supprimées** de `application.yaml` **et** de `CivicDiagnosticProperties` |
| `props.getConnaissances()` / `props.getMisesEnSituation()` | `CivicExamFormat.CONNAISSANCES` / `MISES_EN_SITUATION` |
| `props.getConnaissances() + props.getMisesEnSituation()` | `CivicExamFormat.QUESTIONS` — 🛑 **la somme est la loi, pas une addition à refaire** : `assertionsDeFormat()` verrouille déjà `CONNAISSANCES + MISES_EN_SITUATION == QUESTIONS` |

**Ce que D-29 protégeait, et qui est maintenu — renforcé, même** : le **comportement** du
diagnostic est inchangé, à la question près. Il tire toujours 28 connaissances et 12 mises en
situation, avec son plancher `min-par-theme: 4` et son mode dégradé tracé. Il reste « le seul
endroit du dépôt qui tient le partage officiel » — et désormais il ne peut plus cesser de le tenir
par un changement de YAML.

**Ce que `configVersion` justifie encore, et qui ne bouge pas** : `seuils.solide: 0.80`,
`seuils.faible: 0.55` et `min-par-theme: 4`. Ceux-là changent le **sens d'un résultat** à la
relecture ; ce sont des conventions de mesure, pas la loi. La distinction que D-44 refuse pour le
partage, elle la garde pour les seuils — et c'est la même règle, appliquée correctement : est-ce
que l'arrêté le dit ?

---

#### Une exigence de forme sur le garde-fou 2 de D-38

> « Une seule exigence : que ce test **échoue bruyamment et explicitement** si la somme s'écarte de
> 40 ou les mises en situation de 12 — **message nommant l'arrêté**, pas un `assertEquals` nu.
> C'est le seul rempart restant. »

**Appliqué, et vérifié en cassant le seed exprès.** `CivicOfficialUnitSeedIT` porte une constante
`ARRETE` qui nomme le texte, dit que ce n'est pas un réglage, indique quoi faire avant de toucher
au seed, et rappelle pourquoi aucun `CHECK` ne peut tenir la règle. Le message réel, sur un quota
de Laïcité porté de 2 à 3 :

> *La somme des 16 quotas de `civic_official_units` doit valoir 40 questions, elle vaut 41. Arrêté
> du 10 octobre 2025 […] NOR INTV2527907A, annexe I. 🛑 Ce n'est pas un réglage produit : c'est la
> loi. Si un quota doit changer, c'est que l'arrêté a changé — vérifier le texte sur Légifrance
> AVANT de toucher au seed de V115, et consigner la décision. 🛑 Aucun `CHECK` ne peut tenir cette
> règle […]. CE TEST EST LE SEUL REMPART.*

Les quatre assertions du lot le portent : le compte des 16, la somme, les mises en situation, et
les totaux par thématique.

---

#### Les trois rattachements qui traversent leur thème sont **documentés comme légitimes**

> « Ajoute en commentaire du test pourquoi ces trois traversent leur thème, sinon un futur
> relecteur les prendra pour un bug à corriger. »

**Appliqué.** `CivicOfficialUnitSeedIT.rattachementCoherentAvecLeTheme` ouvre sur un avis au
relecteur : l'annexe I ne donne à « Principes et valeurs » que **deux** notions de connaissance
(Devise et symboles, Laïcité), là où la taxonomie interne en a rangé **cinq** — parce qu'elle a été
construite à partir du corpus, pas de l'arrêté. Les trois en trop sont des **droits** (égalité,
libertés de la DDHC) et de la **démocratie** (la République comme régime), que le texte range
ailleurs.

Et le commentaire dit ce que « corriger » coûterait : rattacher de force l'égalité à P1 mettrait
des questions sur la discrimination dans le quota « Devise et symboles », et le tirage conforme
tirerait 3 questions de symboles dans ce pool. C'est l'erreur que ce test existe pour rendre
impossible.
