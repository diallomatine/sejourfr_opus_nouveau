# Décisions autonomes — chantier « parcours TCF piloté par les évaluations »

> **Menées en autonomie la nuit du 2026-09-17 au 2026-09-18**, sur consigne du propriétaire :
> « go, vas-y lot par lot, n'attends pas ma validation pour continuer. Quand il y a une décision à
> prendre, prends la meilleure et note les décisions dans un .md, j'y regarderai demain matin. »
>
> Ce fichier ne consigne **que** ce que la spec ne tranchait pas. Les 9 arbitrages du propriétaire
> (D-1 → D-9) vivent dans `docs/decisions/plan-parcours-tcf.md` ; la spec est
> `docs/progression/spec-plan-tcf-parcours-evaluations-v2.md`.
>
> Chaque entrée dit : **ce qui a été décidé**, **pourquoi**, et **ce qu'il faudrait changer** si le
> propriétaire tranche autrement. Niveau de confiance indiqué à chaque fois.

---

## Sommaire

| # | Sujet | Confiance |
|---|---|---|
| A01 | Emplacement des classes : arbo plate + `service/journey/` | haute |
| A02 | `journey_step` référence `skill_id` (FK), pas `skill_code` | haute |
| A03 | `task_code` n'est pas persisté sur l'étape | haute |
| A04 | `exam_type` est porté par le lot **et** par l'étape | moyenne |
| A05 | Verrou pessimiste sur `journey`, pas de file d'attente applicative | haute |
| A06 | `next_position` : compteur sur `journey`, incréments de 1 | haute |
| A07 | Suppression de compte : effacement explicite du parcours | haute |
| A08 | `JourneyAssessmentKind` reste persisté | haute |
| A09 | Une étape `DIAGNOSTIC` ne porte ni lot ni épreuve | haute |
| A10 | Le filtre R1 vit dans `JourneyEvaluationFilter`, une seule classe | haute |

---

## Lot 1 — Donnees et configuration (2026-09-17, nuit)

### A01 — Arborescence plate + `service/journey/`, pas un module autonome

**Decide.** Les 4 entites vont dans `entity/`, les enums dans `enums/`, les repositories dans
`repository/`, les managers dans `manager/`. Seule la **configuration versionnee** prend un
sous-dossier, `service/journey/`, exactement comme `service/plan/`.

**Pourquoi.** `backend_sejourfr/CLAUDE.md` enonce l'arborescence attendue et elle est **plate** :
« `entity/`, `repository/`, `manager/`, `service/`, `controller/`, `dto/`, `mapper/`,
`specification/`, `security/`, `config/`, `exception/`, `enums/` (+ `audioquestion/`) ». Le package
`progression/` est un module autonome, mais il n'est pas cite comme un modele a suivre — et le
parcours n'est pas un moteur separe, c'est une **couche d'orchestration du Plan**. Le ranger comme
le Plan est ranger le rend trouvable par quelqu'un qui cherche le Plan.

**Si arbitre autrement.** Deplacer les 4 entites, 9 enums, 4 repositories et 3 managers sous
`journey/` : purement mecanique, aucun changement de logique.

### A02 — `journey_step` reference `skill_id` (FK), pas `skill_code`

**Decide.** L'etape porte une **cle etrangere vers `skills`**. Le code, le titre, le domaine et la
tache **ne sont pas recopies** : ils se lisent sur l'entite chargee en `LEFT JOIN FETCH`.

**Pourquoi.** La spec §6 ecrivait `skill_code varchar`, mais **tous** les moteurs que la lecture
interroge sont indexes par identifiant : `SkillMasteryResolver.fromObservations`,
`SkillProgressCounter.bySkillIds`, `SkillAccessService.isSkillLocked`. Stocker le code aurait
impose une resolution code → UUID a chaque lecture, donc une requete de plus **et** une seconde
copie du referentiel dans la file. Et un titre recopie derive le jour ou la console en change un.

**Effet de bord voulu** : `ON DELETE CASCADE` sur `skills` — desactiver une competence ne supprime
rien (le seed ne supprime jamais), mais si une competence disparaissait, ses etapes partiraient avec
elle plutot que de pointer dans le vide.

### A03 — `task_code` n'est pas persiste sur l'etape

**Decide.** Colonne supprimee du modele de la spec §6.

**Pourquoi.** `skills.task_code` est deja la, sur la ligne que l'etape reference (A02), et il est
**immuable** pour une competence donnee (verrouille en base par
`chk_skills_section_matches_task`). Le recopier serait une duplication pure. C'est aussi lui qui
sert de discriminant a l'unite de progression (`PROMPT` vs `SERIES`, D-5) : une seule autorite
pour un seul fait.

### A04 — `exam_type` est porte par le lot **et** par l'etape

**Decide.** Les deux tables portent la colonne. Le lot s'en sert pour l'index unique partiel de R5 ;
l'etape s'en sert pour les filtres par epreuve.

**Pourquoi.** L'index de R5 (`(journey_id, exam_type) WHERE status = 'OPEN'`) **exige** la colonne
sur le lot. Cote etape, la lire par jointure aurait ajoute un saut a chaque filtre pour un enum
immuable, et les etapes `INITIAL_ASSESSMENT` **n'ont pas de lot** — il leur faut donc la colonne de
toute facon. Les deux valeurs s'ecrivent dans la **meme transaction depuis la meme variable**.

**Confiance : moyenne.** C'est la seule denormalisation du lot. Elle est bornee (un enum, jamais
modifie apres creation) et couverte par les contraintes de forme
(`chk_journey_step_train_skill` / `chk_journey_step_section_exam` exigent `exam_type NOT NULL`).
Une contrainte inter-tables « l'etape et son lot portent la meme epreuve » n'est pas exprimable en
CHECK Postgres ; elle est tenue par le code et verrouillee par les tests de Lot 2.

### A05 — Verrou **pessimiste** sur `journey`, pas d'optimiste, pas de file applicative

**Decide.** `JourneyRepository.findByIdForUpdate` avec `LockModeType.PESSIMISTIC_WRITE`.

**Pourquoi.** Deux evaluations peuvent se terminer en meme temps — une production EE corrigee en
asynchrone pendant que le candidat finit un QCM sur son telephone — et chacune veut ajouter des
etapes en fin de file. Un `@Version` aurait fait **echouer** la seconde, donc **perdu son lot** :
ces traitements sont declenches en best-effort, personne ne les rejoue. Le verrou les **serialise**
et les deux lots entrent. C'est aussi ce qui rend `next_position` fiable sans sequence dediee.

### A06 — `next_position` : compteur sur `journey`, increments de 1

**Decide.** Un `bigint` sur la ligne de parcours, incremente sous le verrou (`consommerPosition()`).

**Pourquoi.** Une sequence Postgres serait globale a la table, donc les positions d'un parcours
auraient des trous enormes et illisibles en debug. Un `MAX(position) + 1` relirait la table a chaque
ajout et serait faux sous concurrence. Le compteur porte par l'agregat est exact, lisible, et ne
coute rien puisque la ligne est deja verrouillee.

### A07 — Suppression de compte : effacement explicite du parcours

**Decide.** `JourneyRepository.deleteByUserId` existe et sera appelee par `AccountDeletionService`
au Lot 2, en plus du `ON DELETE CASCADE`.

**Pourquoi.** Le depot **anonymise** plutot qu'il ne supprime (`User.anonymiser()` met
`targetProcedure` et `targetLevel` a `null`) : la ligne `users` survit, donc la cascade **ne part
pas**. Or un parcours anonymise serait un parcours orphelin de tout objectif — et D-3 dit qu'il n'y
a pas de parcours sans niveau cible. L'effacement doit donc etre explicite, comme il l'est deja pour
`learning_plan_observations` (`deleteByUserId`).

### A08 — `JourneyAssessmentKind` reste persiste

**Decide.** Colonne conservee.

**Pourquoi.** Un `sourceAssessmentId` seul ne dit pas **de quelle table** il vient :
`QUICK_DIAGNOSTIC` designe une `diagnostic_sessions`, `FULL_DIAGNOSTIC` une
`tcf_diagnostic_sessions`, les deux autres un `attempts`. Sans cette colonne, tracer « qu'est-ce qui
a construit cette file ? » demanderait d'interroger trois tables a l'aveugle.

### A09 — Une etape `DIAGNOSTIC` ne porte ni lot, ni epreuve, ni competence

**Decide.** Verrouille par `chk_journey_step_diagnostic`.

**Pourquoi.** Le diagnostic rapide mesure **le candidat**, pas une epreuve (R11) — c'est exactement
ce qui le distingue de tout le reste dans la spec §2. Lui attacher une epreuve aurait laisse croire
qu'il en mesure une, et aurait ouvert la porte a ce qu'il ferme un lot.

### A10 — Le filtre R1 vivra dans **une seule** classe

**Decide (engagement pour le Lot 2).** `JourneyEvaluationFilter`, appelee par
`onAssessmentCompleted` **et** par le bootstrap R19.

**Pourquoi.** D-6 le demande explicitement (« meme filtre pour le bootstrap R19 »). Deux copies
finiraient par admettre deux ensembles de preuves differents — un candidat verrait alors une file au
bootstrap qu'aucune evaluation ulterieure ne saurait reproduire.

### A11 — `journey_assessment_event` porte l'epreuve mesuree (correction de la spec §6)

**Decide.** Ajout d'une colonne `exam_type`, nullable, avec
`CHECK ((assessment_kind = 'QUICK_DIAGNOSTIC') = (exam_type IS NULL))`.

**Pourquoi — c'est un vrai trou de la spec.** R14 exige « la derniere evaluation deja traitee **pour
la meme epreuve** ». La spec §6 ne donnait aucun moyen de repondre : l'evenement ne portait pas
d'epreuve. La premiere implementation deduisait ce repere des **lots** (« quel lot cette evaluation
a-t-elle cree ? »), ce qui est **faux** des que R9 s'applique : une epreuve mesuree **sans produire
de priorite** ne cree aucun lot, donc ne laisse aucun repere, donc une synchronisation tardive
pouvait ensuite remplacer un lot plus recent.

**Pourquoi une seule epreuve par evenement, et pas une table fille.** C'est une propriete du modele
d'`Attempt`, verifiee a l'audit : les sous-epreuves d'un examen blanc complet et les sections d'un
diagnostic complet sont des **attempts a part entiere**, avec leur propre identifiant. Une
evaluation = un attempt = au plus une epreuve. Le seul cas sans epreuve est le diagnostic rapide, et
la base le verrouille.

⚠️ **Consequence pour le Lot 2** : cote EE/EO, l'unite d'evaluation est **l'attempt d'epreuve**, pas
la soumission. Les 3 taches d'une epreuve produisent 3 `production_submissions` ; traiter chacune
comme une evaluation ferait que la tache 2 **remplacerait** (R7) le lot que la tache 1 vient de
creer. `sourceAssessmentId` doit donc etre l'`attempt.id` de l'epreuve, et le branchement doit
attendre que l'epreuve soit **complete**.

### A12 — Trois managers, pas quatre

**Decide.** `JourneyManager` (parcours **et** journal d'evaluations), `JourneyLotManager`,
`JourneyStepManager`.

**Pourquoi.** « Un manager par agregat » (convention backend). Le journal d'evaluations ne se lit
jamais sans son parcours et personne d'autre ne le lit : c'est le meme agregat. Un quatrieme manager
n'aurait ajoute qu'un fichier.

### Verification du lot 1

`./mvnw -o verify -Dtest=TcfJourneyConfigLoaderTest -Dit.test=JourneySchemaIT` — **19 tests verts**
(3 unitaires, 16 d'integration). Les 16 ITs verifient que **la base** tient R5, R13, R14, R18, D-7 et
la forme des trois types d'etape : ce sont des contraintes qu'aucun branchement best-effort ne peut
contourner.
---

## Lot 2 — Orchestration (2026-09-17, nuit)

### A13 — `plan_pinned_priorities` n'est PAS supprimee au lot 2 : elle l'est au lot 4

**Decide.** La suppression prevue par la spec §6/§11 est **reportee a la Phase 4**, celle ou les
fronts basculent reellement sur `journey.current`.

**Pourquoi — deux blocages reels, pas une prudence de principe.**
1. **Le Plan existant s'en sert encore.** L'epingle (V065) a ete posee le 2026-09-13 pour un defaut
   mesure : « EE3 a 0/5, remplacee par EO1 des la premiere production orale ». La retirer au lot 2,
   alors qu'aucun front ne lit encore le parcours, remettrait ce defaut en service pour toute la
   duree du chantier.
2. 🛑 **Le Plan fonctionne SANS objectif declare ; le parcours non** (arbitrage D-3). Or
   `SkillAccessService` ouvre d'office a un compte gratuit la competence de la premiere place
   (arbitrage du 2026-08-21). Brancher cette exemption sur le parcours priverait de leur priorite
   n&deg;1 tous les candidats sans demarche declaree — **17 sur 34** sur la base de dev.

**A resoudre en Phase 4** : soit `PlanFocusResolver` devient un lecteur du parcours **avec repli**
sur sa regle actuelle quand il n'y a pas de parcours (et l'epingle disparait), soit le Plan exige
lui aussi un objectif. Le second choix est un arbitrage produit : il n'est pas pris ici.

### A14 — Les tests du parcours ne sont pas transactionnels, et font leur menage a la main

**Decide.** `JourneyServiceIT` et `JourneyProgressionIT` portent
`@Transactional(propagation = NOT_SUPPORTED)` et suppriment leurs candidats en `@AfterEach`.

**Pourquoi.** `JourneyService` ecrit en `REQUIRES_NEW` — c'est ce qui garantit qu'un bug
d'orchestration ne fasse jamais echouer la correction d'un QCM ni la livraison d'une evaluation
payante. Une transaction de test l'enveloppant la **suspend**, et la transaction neuve ne voit
**rien** de ce que le test vient d'ecrire : le service sort silencieusement et **les assertions
passent pour de mauvaises raisons**. C'est arrive : deux tests sont passes au vert sur un service
qui n'avait rien fait. C'est l'idiome deja en place dans le depot
(`ComprehensionObservationIT`, `DiagnosticPostSignupSequenceIT`).

**Corollaire, qui a coute une passe de debug** : ces tests n'ont plus le droit de **creer** ni
competence ni petit sujet — les lignes survivraient a la classe et feraient echouer, a distance,
les tests qui comptent le referentiel (`LearningPlanDomainSkillsIT` attend 24 competences EE). Ils
empruntent donc le **referentiel seede**.

### A15 — `JourneyLotManager.save` fait `saveAndFlush`

**Decide.** Flush a chaque ecriture de lot.

**Pourquoi — un vrai bug, attrape par l'index de R5.** Hibernate range **tous les INSERT avant tous
les UPDATE** dans sa file d'actions. Fermer un lot puis en creer un autre sur la meme epreuve dans
la meme transaction envoyait donc l'INSERT du nouveau **avant** l'UPDATE qui ferme l'ancien, et
`uq_journey_lot_open_par_epreuve` refusait la ligne. Le flush retablit l'ordre reel des decisions.
Cout nul : un lot par epreuve et par evaluation, jamais un par competence.

### A16 — Cote production, l'evaluation se declenche quand les 3 taches sont evaluees

**Decide.** `DiagnosticProductionAnalysisService.observeStandardProduction` appelle le parcours
seulement si la session est un **examen** et que **toutes** les taches attendues portent une
evaluation.

**Pourquoi.** C'est la consequence directe de A11 : une evaluation = une **epreuve**. Declencher
par soumission ferait que la tache 2 **remplacerait** (R7) le lot que la tache 1 vient de creer.

⚠️ **Limite connue et acceptee** : une epreuve **abandonnee** dont la derniere evaluation atterrit
avant la cloture de la session n'ouvre pas de lot. L'epreuve reste **mesuree** (son autorite est
ailleurs), et la prochaine evaluation de cette epreuve reprend la main. La fermer proprement
demanderait un declencheur a la cloture de session, qui n'existe pas aujourd'hui cote production.

### A17 — Une etape d'expression SANS SUJET PUBLIE ne prend pas la main

**Decide.** `JourneyReadService.elire` ecarte, en plus des etapes verrouillees, les etapes
d'expression dont la competence ne publie aucun sujet.

**Pourquoi.** `LearningPlanStep.Progress.completed()` refuse — a juste titre — de declarer finie
une etape vide : « il n'y a rien a y faire, le dire fini serait un contresens ». Une telle etape ne
peut donc **jamais** se clore, et la laisser prendre la main figerait le parcours sur une carte
sans action. Le cas est rare : `PlanContentAvailability` ecarte deja du pool les competences sans
contenu au moment ou l'evaluation les designe.

### Verification du lot 2

`./mvnw -o verify` — **1296 tests, 0 echec, BUILD SUCCESS.** Dont 48 pour le parcours : 16 de
schema, 9 de construction de lots, 14 d'orchestration, 6 de progression, 3 de configuration.
---

## Lot 4 — Les fronts (2026-09-17, nuit)

### A18 — 🛑 TROU DANS LA SPEC §16 : le parcours dit QUELLE étape, jamais COMMENT la lancer

**Le constat.** `JourneyStepDto` (spec §16) porte l'identité d'une étape — `type`, `purpose`,
`examType`, `section`, `taskCode`, `skillCode`, `skillTitle`, `progress`, `locked` — mais
**aucune action à lancer**. Or §10 dit que la carte « À faire maintenant » *est* l'étape
`CURRENT`, bouton compris. Ces deux phrases ne peuvent pas être vraies en même temps : avec le
seul contrat servi, la carte sait quoi **annoncer** et pas quoi **ouvrir**.

Ce que le Plan porte et que le parcours n'a pas :
- `LearningPlanPriorityDto.recommendedExercise` — le petit sujet **précis** que
  `RecommendedExerciseSelector` a désigné (et son `locked`, et ses minutes) ;
- `LearningPlanDto.domainesAEvaluer` — par quoi mesurer une épreuve
  (`PlanDomainAssessmentKind`, `slotNumber`, `moduleExamQuestionType`,
  `estimatedMinutes`), arbitré le 2026-09-16 ;
- la nature servie (`PlanActionNature`) et la bascule vers la **vérification en situation**.

**Décidé (proposition, à valider).** **Le parcours décide QUELLE étape est courante ; le Plan
fournit COMMENT la lancer.** `planNowCard(plan, {free, journey})` reçoit le parcours :
- l'**identité** de la carte (titre, sous-titre, pastille, progression, verrou) vient de
  `journey.current` — c'est ce que §10 demande, et c'est ce qui rend les six cartes
  identiques ;
- l'**action** se résout en rapprochant l'étape des données du Plan : `TRAIN_SKILL` → la
  priorité de même `skillCode` et son `recommendedExercise` ; `SECTION_EXAM` → l'entrée de
  `domainesAEvaluer` de même épreuve ; `DIAGNOSTIC` → `/diagnostic` ;
- **sans parcours servi** (backend antérieur, parcours pas encore chargé) : comportement
  d'aujourd'hui, inchangé.

**Pourquoi pas l'inverse — enrichir le DTO d'un `action`.** Ce serait une **seconde autorité**
sur « par quoi mesurer une épreuve » et « quel sujet proposer », deux règles qui ont déjà leur
resolver et dont l'une vient d'être arbitrée. Le parcours est une couche d'**orchestration**
(spec §0.4) : lui faire porter le catalogue d'actions le transformerait en second moteur.

**✅ FAIT (lot 4d, commit `5b47748d` et suivants).** ⚠️ Le paragraphe qui disait ici « ce n'est
pas fait cette nuit » est **périmé** : `planNowCard(plan, {free, journey})` a bien été réécrite,
et les **six** sites d'appel la lui passent — `LearningPlanView.ActionMaintenant`,
`dashboard/page.tsx::ActionPlanDuJour`, `lib/reviser.ts::reviserResumeTcf` côté web ;
`plan_tcf_view._nowCard`, `home_screen._actionTcf`, `reviser_labels.reviserResumeTcf` côté
mobile. L'identité de la carte vient de `journey.current` ; l'action se résout dans le Plan.

**⚠️ Deux défauts de cette première version, corrigés le 2026-09-17** (revue du propriétaire) :

1. **l'action d'un point d'étape ne se résolvait pas** — voir **A24**, qui sert désormais la
   mesure sur l'étape elle-même ;
2. **le repli était silencieux et faux** — quand rien ne se résolvait, la fonction retombait sur
   `plan.currentPriority` : la carte annonçait l'étape du parcours et **ouvrait une autre
   compétence**. Voir **A25**, le garde-fou.

### A19 — La timeline sert les DEUX variantes de l'écran, abonné comme gratuit

**Décidé.** La même `JourneySection` / `_journeySection()` est rendue dans les deux branches du
Plan.

**Pourquoi.** Un parcours amputé pour un compte gratuit serait **un second parcours** — et la
contradiction #1 du dépôt (tranchée le 2026-08-21) dit que le Plan reste intégralement visible.
Le verrou est **lu par étape** (`locked` servi) et se rend par un cadenas, à la place de
l'étape, sans en déplacer aucune. C'est ce qui remplace l'ancienne liste `SfLockRow` /
`LockRow`, qui montrait les compétences de la tâche **sans leur état**.

### A20 — Le parcours est chargé en parallèle du Plan, et son échec est silencieux

**Décidé.** Web : `journeyApi.getCached()` lancé dans le même effet que le Plan, erreur avalée.
Mobile : `journeyProvider`, observé par `ref.watch(...).valueOrNull`.

**Pourquoi.** Les deux alimentent le **même écran** : les enchaîner ferait clignoter la carte
entre deux autorités. Et un backend antérieur à l'endpoint doit laisser un Plan **entier** —
la section disparaît, elle n'affiche jamais de squelette.

🛑 **Corollaire non négociable** : le parcours partage les **points de fraîcheur** du Plan —
préfixe de cache commun côté web (donc purgé par `invalidateDiagnosticAndPlan()`), mêmes
`ref.watch` côté mobile. Sans ça, une évaluation rechargerait l'un et laisserait l'autre sur son
état d'avant : deux lectures du même candidat, au même instant, qui se contrediraient à l'écran.

### A21 — L'aperçu de l'Accueil n'affiche **aucun compteur d'étape**

**Décidé.** Le bloc « Votre Plan » de l'Accueil montre l'étape courante et sa voisine, **sans**
« Étape 2 / 5 ». Le parcours **civique**, lui, garde le sien (`civicPathCounter`).

**Pourquoi.** Le parcours TCF ne sert **aucune position d'étape**, et `steps` est **déjà
filtrée** par le serveur (§14) : un compteur dérivé de cette liste compterait la **fenêtre**,
pas la file. On n'affiche pas un nombre qu'on ne sait pas.

**Ce qui est conservé du bloc d'avant** : la fenêtre de **deux** étapes (plafond d'affichage
arbitré le 2026-09-12) et la règle qui la rend utile — **elle contient toujours l'étape
courante**, elle et sa suivante, ou la précédente et elle quand elle ferme la file. Montrer
« les deux premières » aurait caché exactement ce qu'il y a à faire maintenant.

### A22 — `PlanPathStep` survit, mais ne décrit plus que le parcours **civique**

**Décidé.** Le type reste ; sa documentation dit désormais ce qu'il est.

**Pourquoi.** Le parcours de **tâche** a disparu avec le bloc « Votre parcours — Tâche X »
(spec §11), mais `civicPath` rend toujours des `PlanPathStep` — et le parcours civique n'a
**pas** de file d'évaluations : ses cinq étapes viennent de la boîte Leitner. Deux objets
différents, deux types différents. ⚠️ Le confondre avec `JourneyStepDto` ferait cocher une
étape civique avec la sémantique du parcours TCF.

⚠️ **Reste à faire, cosmétique** : `mobile_sejourfr/lib/screens/plan/plan_task_path.dart` ne
contient plus de « task path » (seulement `planTaskDto` et les tables d'état d'étape). Son nom
ment. Renommage volontairement **non fait** cette nuit : il touche quatre imports pour zéro
changement de comportement, et l'entête du fichier dit maintenant ce qu'il porte.

### A23 — 🛑 `plan_pinned_priorities` n'est PAS supprimée : elle devient le **repli**

**Décidé.** `PlanFocusResolver` lit d'abord le **parcours** — la première étape d'entraînement
encore ouverte — et **ne retombe sur l'épingle que lorsqu'il n'y a pas de parcours**. La table
reste, son rôle se réduit.

**Pourquoi la suppression prévue par la spec §6 n'a pas lieu.** Sa prémisse — « la position
d'une étape EST l'épingle » — n'est vraie **que lorsqu'un parcours existe**, et D-3 en fait une
conséquence de la démarche déclarée. Or le Plan, lui, fonctionne **sans objectif** : supprimer
l'épingle priverait de leur priorité n°1 tous les candidats sans démarche — **17 sur 34** sur la
base de dev — et leur rendrait l'instabilité que V065 avait corrigée (cas réel mesuré : « EE3 à
0/5, remplacée par EO1 dès la première production orale »).

**✅ ARBITRÉ le 2026-09-17** — verbatim du propriétaire : « **le Plan n'exige PAS d'objectif
déclaré. L'épingle reste en repli, notée comme dette de transition.** » La question ouverte est
donc close : `plan_pinned_priorities` **reste**, et la suppression prévue par la spec §6
**n'aura pas lieu** tant que le Plan fonctionnera sans démarche déclarée.

⚠️ **Dette de transition**, à relire le jour où la démarche deviendra obligatoire : l'épingle
n'aura alors plus aucun lecteur, et `PlanFocusResolver` se réduira à
`premiereDuParcours`. Le contre-pied de cette dette est **l'invitation** ajoutée le même jour —
la carte « Choisir mon objectif » se lit désormais **partout où une carte « À faire
maintenant » se lit** (Plan, Accueil et Réviser, web et mobile), et non plus sur le seul Plan.
Elle **n'enlève rien** : le Plan reste entier sans objectif, c'est une porte ouverte, pas une
porte fermée.

**Ce que ce changement corrige quand même, et c'est le vrai motif.** Le freemium ouvrait
d'office la compétence de la première place **du Plan**, pendant que la carte « À faire
maintenant » annonçait celle du **parcours** : le candidat gratuit lisait une étape et pouvait
en travailler une autre. Les deux disent désormais la même chose.

**Coût assumé, et mesuré.** Le budget de requêtes du Plan passe de **23 à 24**
(`LearningPlanCycleIT.leCoutDuPlanNeGrandiPasAvecLHistorique`, qui a attrapé le dépassement
avant moi — c'est exactement l'usage prévu de cette égalité). **Une** requête, jointure
comprise : lire le parcours puis ses étapes en aurait coûté deux.

**Ce qui n'a pas changé** : l'exemption reçoit une étape **verrous ignorés** (arbitrage du
2026-08-21), et le **pool** reste la condition — une compétence sans contenu publié n'est pas
une première place, et le freemium n'ouvre jamais du vide.


---

## Corrections de la revue du propriétaire (2026-09-17, seconde passe)

### A24 — 🛑 L'action d'une étape d'examen est SERVIE (`JourneyStepDto.assessment`)

**Le constat, et il est structurel.** Un point d'étape (`SECTION_EXAM` / `REASSESS`) porte
**toujours** sur une épreuve **déjà mesurée** — c'est elle qui a créé le lot. Or les deux
sources où les fronts allaient chercher l'action ne contiennent que le contraire :

- `LearningPlanDto.domainesAEvaluer` ne liste que les épreuves **jamais mesurées** (c'est sa
  définition : `PlanDomainAssessmentResolver.resolve` saute tout `domaine.evaluated()`) ;
- la séance ne porte qu'une mesure, l'**indispensable** (`resolver.indispensable`), réservée
  au cas « la production a été rendue et le correcteur n'a rien pu observer ».

Le checkpoint de **chaque lot** — le cas le plus courant du parcours — n'avait donc **aucune
action résoluble**, et les deux fronts retombaient sur `plan.currentPriority`.

**Décidé.** `JourneyReadService` appelle `PlanDomainAssessmentResolver.pour(examType)` et sert
le `PlanDomainAssessmentDto` sur l'étape. Les fronts lisent `etape.assessment` au lieu de
fouiller `domainesAEvaluer`, et cessent de reconstituer une enveloppe de séance à la main.

**Pourquoi ça ne contredit pas A18.** A18 interdit au parcours de **composer** une action ; ici
il en **relaie** une, depuis l'autorité qui la porte déjà. `pour(EpreuveType)` est publique
depuis le 2026-09-16 précisément pour ça — « Cinq appelants, pas cinq règles », dit son
javadoc ; le parcours devient le sixième. **Zéro requête** : c'est une table de natures.

**Vérifié par** `JourneyServiceIT.leCheckpointDUnLotPorteSaMesure` (EE déjà mesurée ⇒
`PRODUCTION_MOCK_EXAM`, slot 1) et `…seulesLesEtapesDExamenPortentUneMesure` (CO non mesurée ⇒
`MODULE_MOCK_EXAM` + `QuestionType.CO` ; toute étape d'entraînement ⇒ `null`), plus
`JourneyReadServiceTest`.

### A25 — 🛑 GARDE-FOU : une carte ne lance JAMAIS autre chose que l'étape qu'elle annonce

**Le constat.** `planNowCard` faisait `journeyPriorityDe(...) ?? plan.currentPriority`. Quand le
parcours désignait une étape dont l'action ne se résolvait pas, la carte gardait le titre de
l'étape **et lançait la priorité du Plan** — une autre compétence. Le commentaire l'assumait
(« repli assumé… l'écart est transitoire »), mais c'est exactement la contradiction que le
parcours a été écrit pour fermer.

**Décidé.** Une **quatrième nature**, `INDISPONIBLE` / `PlanNowNature.indisponible` : la carte
nomme **l'étape du parcours** (titre et sous-titre venant de `journey.ts` ⇄
`journey_labels.dart`, la même autorité que la timeline), sans bouton, avec une ligne qui dit
que la prochaine évaluation la remettra à jour. `PlanNowVue.priority` / `PlanNowCard.priority`
deviennent **nullables** — c'est le seul cas.

**Les deux causes connues, toutes deux transitoires** : une compétence que le Plan ne priorise
plus (son transfert vient d'être prouvé, le parcours clôturera l'étape au prochain
entraînement), et une compétence **hors de la fenêtre d'affichage** des priorités
(`plan.display.prioritiesMaxActions`). ⚠️ La seconde est rendue rare par A23 — la première place
est celle du parcours —, mais **pas impossible** : le parcours peut désigner un examen, et
l'épingle gouverner alors le classement.

**Rendu par écran, et ce n'est pas la même chose partout** : le Plan affiche la carte
indisponible (sans CTA) ; l'**Accueil** la nomme mais n'offre aucun raccourci ; **Réviser** ne
propose pas de reprise (règle déjà en place : « rien à lancer ⇒ pas de bouton mort »).

**Corollaire** : `planNowCta` accepte désormais une priorité `null` et rend le libellé de mesure
en premier. Une étape d'examen se nomme sans aucune priorité — c'est même le cas quand tout a
été travaillé, et l'exiger faisait disparaître la carte.

### A26 — L'exemption freemium et le Plan élisent la MÊME étape que `CURRENT`

**Le constat.** Trois lectures de « la première étape d'entraînement ouverte » coexistaient et
pouvaient diverger :

| lecteur | ce qu'il prenait |
|---|---|
| `JourneyReadService.elire` (⇒ `CURRENT`) | la première **ouverte, non verrouillée et avec du contenu** |
| `JourneyReadService.focusSkillId` (⇒ exemption freemium) | la première ouverte, **quelle qu'elle soit** |
| `PlanFocusResolver.premiereDuParcours` (⇒ première place du Plan) | la première ouverte, **et seulement elle**, abandonnée si hors du pool |

Le verrou, lui, ne les sépare pas : l'exemption **déverrouille** l'étape qu'elle reçoit, donc
`elire` l'élit ensuite. C'est le **contenu** qui les séparait — une compétence d'expression sans
aucun sujet publié : `elire` la saute, les deux autres s'y arrêtaient. Résultat : l'exemption
tombait sur une compétence qui n'a rien à ouvrir, `PlanFocusResolver` retombait sur l'épingle,
et le compte gratuit lisait une étape sans y avoir accès.

**Décidé.** Les trois sautent désormais les mêmes étapes, dans le même ordre.
`focusSkillId` applique `sansContenu` (le filtre d'`elire`, la progression étant calculée avant
l'accès — elle n'en dépend pas) ; `premiereDuParcours` **parcourt** les étapes ouvertes et garde
la première dont la compétence est **dans le pool** (le pool écarte déjà les compétences sans
contenu publié), au lieu de s'arrêter à la première ligne. `findPremiereCompetenceOuverte`
devient `findCompetencesOuvertes` et rend jusqu'à 12 lignes — **toujours une seule requête**,
donc le budget du Plan ne bouge pas.

**Ce qui reste volontairement différent** : le parcours peut désigner un **examen** comme étape
courante ; l'exemption ouvre alors la première compétence d'entraînement de la file, celle que
le candidat atteindra ensuite. Aucune contradiction à l'écran — la carte annonce l'examen.

**Vérifié par** `JourneyReadServiceTest.lExemptionTombeSurLEtapeQuiPrendLaMain` et
`PlanFocusResolverTest.lEtapeSansContenuEstSauteeCommeDansElire`.

### A16 bis — DETTE TECHNIQUE : déclencher le parcours à la clôture définitive d'un Attempt

**Inscrit comme dette** (décision du propriétaire, 2026-09-17).

**Ce qui manque.** `DiagnosticProductionAnalysisService.porterAuParcours` déclenche le parcours
quand la session est un examen **et** que les 3 tâches sont évaluées (A16). Une épreuve EE/EO
**abandonnée** dont la dernière évaluation atterrit **avant** la clôture de session n'ouvre donc
aucun lot : l'épreuve reste mesurée, et c'est la **prochaine** évaluation qui reprend la main.

**Ce qu'il faudrait.** Un point de déclenchement à la **clôture définitive** d'un `Attempt` de
production — là où `finishSubAttemptIfFullExam` et les chemins d'abandon posent `finishedAt` —,
qui appelle `onAssessmentCompleted` avec ce qui a été réellement évalué. Il couvrirait aussi
l'examen suspendu puis expiré, que rien ne couvre aujourd'hui.

**Pourquoi ce n'est pas fait dans cette passe.** Il y a **quatre** chemins de clôture (fin
normale, abandon, expiration du chrono, suspension d'examen complet) et l'idempotence par
évaluation ne suffit pas à elle seule : il faut décider ce qu'une épreuve partiellement évaluée
doit produire — un lot sur ce qui a été mesuré, ou rien. C'est un arbitrage produit, pas un
branchement.

---

# 2026-09-18 — Chantier du CYCLE BORNÉ : décisions prises en autonomie (A27 → A40)

> Arbitrages du propriétaire : `docs/decisions/plan-parcours-tcf.md` **D-12 → D-24 et D-17 bis**.
> Ce qui suit est ce que **personne n'a tranché** et qu'il a fallu décider pour livrer. Chaque
> entrée dit le geste, le motif, et ce qu'il faudrait changer si l'arbitrage était autre.

### A27 — Changer d'objectif ne détruit pas le cycle : son niveau cible est mis à jour

**Le problème.** D-13 impose **un seul cycle `EN_COURS` par (candidat, module)**. Or la clé de
V066 était `(user_id, target_level)` et le javadoc disait : « changer d'objectif ne détruit rien,
on bascule vers le parcours de ce niveau, l'ancien est conservé tel quel ». Avec l'index partiel,
cette bascule crée un **second `EN_COURS`** et échoue.

**La décision.** Le cycle `EN_COURS` **survit avec le même id** et son `target_level` est mis à
jour. On ne l'historise pas, on ne le recrée pas.

**Motif.** Historiser jetterait le plan que le candidat a sous les yeux, et un ping-pong
d'objectif remplirait la page Progression de cycles fantômes. Les priorités d'une compétence ne
deviennent pas fausses parce que la cible a bougé — seul l'**ordre** des lots s'en trouve
recalculé, et il est déjà dérivé à la lecture.

**Si l'arbitrage était autre** (« changer d'objectif ouvre un nouveau cycle ») : historiser
l'`EN_COURS` avec son `exit_level`, et laisser le bootstrap R19 reconstruire — le code est en
place, c'est un `if` dans `JourneyService.getOrCreate`. Verrouillé par un test qui assert
**l'égalité de l'id** (`JourneyServiceIT` §18-22).

### A28 — La migration réconcilie **avant** de créer l'index unique

**Le problème.** V066 autorisait plusieurs `journey` par candidat (un par niveau cible). V067 leur
donne tous `status = 'EN_COURS'` par DEFAULT, donc `CREATE UNIQUE INDEX uq_journey_en_cours`
**échouerait** pour un candidat qui a changé d'objectif entre les deux — et casserait le
déploiement.

**La décision.** Une requête de réconciliation **déterministe, bornée et idempotente** juste avant
l'index : on garde le cycle le plus récemment **touché** (`updated_at DESC, created_at DESC, id`)
et on historise les autres (`historise_at = now()`).

**Motif.** Le parcours vivant d'un candidat est celui sur lequel il travaillait. Un cycle historisé
n'est pas perdu : il part dans la page Progression. Et c'est l'exception déjà admise dans
`00_schema` (précédents V023, V024, V042) : aucune logique applicative n'est embarquée — ni niveau,
ni maîtrise, ni priorité n'est relu. Rejouée, la requête ne trouve plus qu'un `EN_COURS` par
`(candidat, module)` et ne touche rien.

**Mesure** (SQL sur la base de dev, aucun LLM) : **2 `journey`, 2 candidats, 0 doublon**. La garde
est donc écrite pour la **prod**, dont le volume n'était pas consultable.

### A29 — `free_entitlement_usage.code` est verrouillé par un CHECK, l'enum Java n'est qu'un miroir

**La décision.** CHECK fermé sur les deux valeurs (`EXAM_BLANC_EE`, `EXAM_BLANC_EO`) ;
`FreeEntitlementCode` est le miroir, pas l'autorité.

**Motif.** Ordre de préférence du dépôt : une contrainte dure avant une consigne. Avec un code
libre, une faute de frappe rendrait **gratuite une gratuité déjà consommée**, sans aucun signal.
**Coût assumé** : ajouter une gratuité demande une migration.

### A30 — `consommer(...)` avale la violation d'unicité et rend un booléen

**La décision.** Le manager rend « cet appel a-t-il consommé ? » et ne propage pas le doublon
(patron `ProcessedExternalEventManager.tryMarkProcessed`).

**Motif.** L'appelant est une **remise d'analyse déjà payée**. La faire échouer pour un doublon que
la base vient justement d'empêcher ferait perdre au candidat une analyse qu'il a reçue.

### A31 — L'idempotence d'une évaluation se lit au **candidat**, et chaque cycle qui écrit journalise

**Le problème.** `journey_assessment_event` est unique sur `(journey_id, source_assessment_id)`.
Avec deux cycles vivants (`EN_COURS` + `EN_ATTENTE`) et une promotion qui change le cycle courant,
une lecture bornée au cycle courant **retraiterait** une évaluation déjà honorée.

**La décision.** La **lecture** d'idempotence est portée au candidat
(`dejaTraiteeParUnCycle(user, module, source)`) ; l'écriture reste par cycle : un event pour
**chaque cycle qui a réellement écrit** (l'`EN_COURS` toujours, l'`EN_ATTENTE` seulement s'il
reçoit des priorités). Jamais de ligne « pour mémoire ». `derniereMesure` (chronologie R14) est
portée au candidat pour la même raison.

### A32 — Un cycle ne reçoit une **amorce** que s'il n'a ni lot ni examen

**La décision.** Une évaluation construit le cycle `EN_COURS` seulement quand celui-ci « attend son
amorce » : **aucun lot et aucune étape `SECTION_EXAM`**. Sinon, ses priorités vont en attente.

**Motif.** Ça fait entrer l'amorce C (diagnostic seul) et le cycle **vide** après actualisation,
et ça exclut le **cycle de mesure** — dont le premier examen aurait sinon créé un lot et détruit
sa nature — ainsi que tout cycle mûr, qui est borné par définition.

### A33 — « Cycle de mesure » : aucune `TRAIN_SKILL` **et au moins un** `SECTION_EXAM`

**La décision.** La dérivation exige les deux conditions, pas seulement l'absence d'entraînement.

**Motif.** « Aucune `TRAIN_SKILL` » seul qualifierait aussi le cycle vide et le cycle
diagnostic-seul — à qui on n'a aucune raison de **refuser** l'examen blanc complet en fin de cycle.
Rappel : `cycleDeMesure` n'est **pas une colonne** (D-12), et `examenCompletPossible` en découle
(A36).

### A34 — `CYCLE_COMPLETED` vs `UP_TO_DATE` : la question est « y a-t-il des étapes ? »

**La décision.** Aucune étape ouverte **et aucune étape du tout** ⇒ `UP_TO_DATE` (le « cas vide »
de la spec §6, suggestion inchangée). Des étapes, toutes closes ⇒ `CYCLE_COMPLETED`, donc l'écran
« Prochaine étape ».

**Motif.** Un seul état neuf, aucune requête de plus, et « Objectif atteint » reste un **libellé de
front** — pas un second état serveur qui dirait la même chose que `UP_TO_DATE`.

### A35 — `exit_level` se lit sur la **lecture Plan**, et reste `null` sous l'A2

**La décision.** À l'historisation, `exit_level` = `TcfProfileService.levelProfile().globalLevel()`
(l'autorité de la lecture Plan, D-2), converti en `TargetLevel`. `null` si rien n'est mesuré —
**et aussi** si le niveau mesuré est sous l'A2, que la colonne ne sait pas dire.

**Motif.** `null` = inconnu, jamais mauvais : un candidat sous l'A2 ne doit pas être archivé
« A2 ». Aucun plancher n'est recalculé ici : le niveau se lit, il ne se décide pas.

### A36 — `examenCompletPossible` = `!cycleDeMesure`

**Motif.** Aucune condition « les 4 épreuves sont mesurées » : l'examen complet est justement ce
qui les mesure. La seule exclusion est un cycle de mesure, où enchaîner un second examen complet
n'aurait aucun sens (spec §6).

### A37 — L'ordre de dérivation du statut d'un bloc

**La décision.** `EN_COURS` (le bloc porte `current`) > bloc **vide** (`A_EVALUER` si l'épreuve n'a
jamais été mesurée, sinon `TERMINE`) > `TERMINE` > `A_EVALUER` > `A_VENIR`.

**Motif.** Le bloc qui porte l'action gagne toujours l'affichage, sinon deux blocs se disputeraient
« EN COURS ». `jamaisMesuree` (`NiveauActuelEpreuveResolver`) est mémoïsé et interrogé **au plus 4
fois**, seulement pour les blocs candidats : le budget de requêtes du Plan ne bouge pas.

### A38 — Trois correctifs collatéraux qu'il a fallu faire pour que le cycle tienne

1. `findCompetencesOuvertes` (la première place du Plan) est bornée au cycle **`EN_COURS`** du
   module TCF et **ne filtre plus sur `target_level`** — ce n'en est plus une clé depuis D-13.
2. `porterAuParcours` n'envoie plus au parcours un `MOCK_EXAM` de `TCF_STRUCTURE` ou
   `TCF_COMPLET` : il **échouait en silence** contre `chk_journey_assessment_exam_type`.
   Rappel : `TCF_STRUCTURE` n'est pas une cinquième épreuve.
3. `natureDeLEvaluation` existait en **deux copies** et allait passer à trois : extraite dans
   `JourneyProductionBridge`. Deuxième occurrence ⇒ on extrait.

### A39 — Le paywall d'un rejeu **EO** se présente au démarrage de la tâche

**La décision.** Quand le freebie EO est consommé, le paywall s'affiche **avant** que le candidat
parle, pas après sa soumission.

**Motif.** Un rejeu ne déclenche **aucun appel payant** (D-17 bis), donc pas de Whisper ; et l'audio
candidat n'est **jamais conservé**. Sans transcription, une soumission EO ne laisserait
**rien** — ni note, ni texte, ni trace. Faire produire un candidat dans le vide serait malhonnête.
En **EE** le texte reste relisible : le rejeu y est acceptable sans analyse, et le paywall peut
rester après la soumission.

### A40 — Trois choix de kit, assumés

1. **La barre d'avancement du cycle garde le dégradé bleu → rouge de la maquette.** Le `CLAUDE.md`
   racine réserve le rouge aux « CTAs critiques » ; ici c'est un **aplat décoratif** de la maquette
   validée par le propriétaire, pas un signal d'urgence. Si la règle doit primer, la barre passe en
   `blue → blue-mid` — un token à changer, des deux côtés.
2. **Un chevron a été ajouté** à l'en-tête de bloc, que la maquette n'a pas : elle compte sur le
   curseur `pointer`, qui n'existe pas au doigt. Il pivote comme celui de `Prio`/`SfPrio` et
   respecte `prefers-reduced-motion`.
3. **`AppColors.blueMid` a été créé** (miroir de `--color-blue-mid`) pour que le dégradé de
   `NextStepCard` ait le **même nombre d'arrêts** des deux côtés. Les deux kits sont miroirs brique
   pour brique : un dégradé à deux arrêts là où le web en a trois se voit.

### A41 — La gratuité se consomme à la **première** analyse rendue, pas à la troisième

**La décision.** La ligne du ledger s'écrit dès que la **première** analyse d'une session
d'examen est rendue, et porte `source_attempt_id` ; les deux tâches restantes du **même**
attempt restent corrigées.

**Motif.** N'écrire qu'après la 3ᵉ tâche laissait abandonner chaque examen sur la 2ᵉ et
obtenir des corrections LLM **sans borne**. Un abonné ne consomme rien ; le diagnostic
n'entre jamais dans le ledger.

### A42 — Le fenêtrage d'affichage du parcours reste **chargeable** sans lecteur

`TcfJourneyConfig.display` (`recentCompletedVisible`, `upcomingVisible`) a perdu son dernier
lecteur avec `JourneyDto.steps`. Le champ **reste** dans le record : `tcf-journey-config-v1`
et `-v2` le déclarent, et le loader refuse une clé inconnue — l'effacer rendrait
**impossible** le retour arrière par variable d'environnement, qui est la doctrine du dépôt.
Javadoc explicite sur place.

### A43 — `trainSeriesFallbackQuota` est ajouté à la config **v1** aussi

**La décision.** La v1 reçoit `trainSeriesFallbackQuota: 2`, égal à son `trainSeriesQuota`.

**Motif.** Les séries réussies étant un sous-ensemble des terminées, « 2 réussies ou 2
terminées » **est** mot pour mot l'ancienne règle de D-5. Sans cette clé, un retour arrière
en v1 aurait **fait échouer le démarrage** (le record Java est partagé par les deux
versions). Le loader refuse en plus une échappatoire **inférieure** au quota de réussite.

### A44 — L'idempotence de l'historique : le `numero` d'un cycle a **une** règle

`JourneyCycleRank` porte le rang d'un cycle (nombre d'historisés + 1) et il est **partagé**
par `JourneyDto.cycle.numero` et `JourneyHistoryCycleDto.numero`. Deux lectures du même
nombre ne peuvent donc pas diverger — c'est le défaut le plus cher du dépôt, et il se serait
vu tout de suite : l'écran d'historique affiche « Cycle 2 » à côté du Plan qui dit le même.

### A45 — Une étape `DIAGNOSTIC` n'appartient à aucun bloc, et deux tests le disent

**Le constat.** Le retrait de `JourneyDto.steps` a rendu l'étape de diagnostic invisible de
la timeline : elle ne porte **aucune épreuve**, donc aucun bloc ne peut la contenir. Deux
tests de `JourneyServiceIT` (§18-32, §18-33) l'ont attrapé en passant au rouge.

**La décision.** C'est le bon comportement, et les tests sont réécrits pour lire **la file**
(la base) au lieu du DTO : ce qu'ils prouvent — « aucune priorité inventée tant que rien
n'est mesuré » — ne dépend pas de l'écran. La carte « Faire mon diagnostic » continue d'être
servie par `current`, qui est **le** canal de cette étape. ⚠️ Corollaire à connaître : sur un
compte neuf, les quatre blocs sont servis **vides** (`A_EVALUER`) — les `SECTION_EXAM` ne
naissent qu'avec une première évaluation (R12), comportement du moteur du 2026-09-17, laissé
tel quel.

### A46 — Le geste de la carte « À faire maintenant » verrouillée est **bleu**

Sur un Plan gratuit, le seul bouton **rouge** doit rester « Débloquer mon plan », ancré sous
le cycle. Le CTA de la carte (« Débloquer cet entraînement ») prend donc la variante
**bleue**, alignée sur le jalon verrouillé qui existait déjà. ⚠️ Constaté au passage, hors
périmètre : l'**Accueil** ne nomme jamais une étape verrouillée (règle antérieure), donc un
compte gratuit y voit une carte générique **sans geste**. À rouvrir ou non — l'Accueil est
hors périmètre (D-22).

---

# 2026-09-19 — Chantier du CYCLE CIVIQUE : décisions prises en autonomie (A47 → A54)

> Arbitrages du propriétaire : `docs/decisions/plan-parcours-tcf.md` **D-25 → D-49**, plus la règle
> générale **D-48**. Ce qui suit est ce que **personne n'a tranché** et qu'il a fallu décider pour
> livrer la lancée 1 (P8.0 → P8.2a, P8.A) et la lancée 2 (P8.3, contrat servi de P8.4).
>
> ⚠️ **Le moteur du cycle civique n'est PAS livré.** État de ce qui reste :
> `docs/progression/civique/REPRISE-P8.4-MOTEUR.md`.

### A47 — Le bloc du cycle devient **servi**, plutôt qu'`examType` + un branchement par front

**Le problème.** `JourneyStepDto` et `JourneyBlocDto` portaient `examType: EpreuveType`, lu par les
deux fronts. Un bloc civique n'a pas d'`EpreuveType` : sa nature est une **thématique**, qui est une
**donnée** de `themes` et non une valeur d'enum.

**La décision.** Un objet servi `JourneyBlocRefDto { kind, code, label }` — `kind` ∈
`{EPREUVE, THEMATIQUE}` — remplace `examType` sur les deux DTO.

**Motif.** La voie écartée était `examType` **+** `themeCode`, chaque front branchant sur le module.
C'est exactement le geste que la doctrine du dépôt interdit : « aucun front ne classe », « l'état,
son libellé et son ton arrivent servis ». Deux fronts qui branchent finissent par afficher deux
choses différentes, et la parité D-21 (transposée par D-47) devient invérifiable.

**Si l'arbitrage était autre** : le champ à rétablir est un `examType` nullable **plus** un
`themeCode` nullable, et les deux fronts reprennent une table de libellés. Le changement est borné —
`JourneyBlocRefDto` a **un** producteur (`JourneyBlocResolver`) et les accesseurs d'entité.

### A48 — Le **libellé** du bloc est servi, et c'est la nouveauté

`label` arrive du serveur. Les miroirs gelés (`lib/tcf-epreuves.ts` ⇄ `core/utils/tcf_epreuves.dart`,
`EpreuveType.displayLabel`) **restent** pour leurs autres emplois : l'écran du cycle, lui, lit ce
label-ci. C'est ce qui garantit qu'une thématique civique et une épreuve TCF s'affichent par le
**même chemin** — un nom de thématique est une donnée éditable en base, qu'aucun front ne peut
connaître à la compilation.

### A49 — Une thématique **n'a pas d'initiale**, et `journeyBlocMark` rend une chaîne vide

**Le constat.** L'initiale à deux lettres (`CO`, `CE`, `EE`, `EO`) n'existe que pour une épreuve.
« Principes et valeurs de la République » ne se réduit pas à deux lettres.

**La décision.** `journeyBlocMark(bloc)` rend `""` pour un bloc `THEMATIQUE`, et c'est au **kit** de
savoir afficher un en-tête de bloc sans initiale.

**Motif.** En inventer une (« PR », « HG ») serait un libellé **fabriqué par le front**, invisible de
l'admin et impossible à corriger sans livrer les deux apps. ⚠️ **Conséquence assumée** : la brique
d'en-tête sans initiale **manque dans les deux kits** — c'est P8.6, et jusque-là aucun écran ne rend
un bloc civique.

### A50 — `SkillMasteryEngine.poidsSource` **lève** sur une source civique, il n'invente pas un poids

**Le problème.** L'ajout de `CIVIQUE_SERIE` / `CIVIQUE_EXAMEN` à `LearningPlanSourceType` a rendu le
`switch` des poids non exhaustif.

**La décision.** Il **lève** (`IllegalArgumentException`), plutôt que de rendre un poids par défaut.

**Motif.** Le moteur de maîtrise mesure des **compétences TCF** ; une observation civique porte une
**unité officielle** et aucun `skill_id`. Un poids inventé produirait une maîtrise de compétence à
partir d'une mesure qui ne la concerne pas — la famille de bugs de V040/V041/V042 (« une absence de
mesure devient un verdict »). Lever fait du passage accidentel un échec **bruyant** au premier test.

**Si l'arbitrage était autre** : ce n'est pas le poids qu'il faudrait changer, c'est le fait qu'une
observation civique n'entre pas dans ce moteur — donc `docs/regles/plan.md`, pas cette ligne.

### A51 — **Deux** sources civiques, pas une seule avec un drapeau

`LearningPlanSourceType` reçoit `CIVIQUE_SERIE` **et** `CIVIQUE_EXAMEN`.

**Motif.** La distinction est déjà **opposable** : `JourneyEvaluationFilter` lit
`CIVIQUE_SERIE → false` / `CIVIQUE_EXAMEN → true` (R3 — une série gratuite n'évalue pas). Une seule
valeur plus un booléen ailleurs mettrait cette règle à deux endroits, et `isCivique()` / `mesure()`
la rendent lisible d'une ligne. Le coût est un `switch` de plus à compléter, et c'est **voulu** :
c'est lui qui a fait apparaître A50.

### A52 — Tout index unique portant une colonne devenue **nullable** reçoit un **jumeau partiel**

**Le problème.** Postgres traite deux `NULL` comme **distincts** dans un index unique. Rendre
`skill_id` nullable (V070) ou ajouter `theme_id` à côté d'`exam_type` (V069) désarme donc
silencieusement l'unicité sur la moitié civique : deux observations de la **même** unité, ou deux
lots ouverts sur la **même** thématique, passeraient.

**La décision.** Trois index jumeaux partiels : `uq_learning_plan_observation_source_unite` (V070),
`uq_journey_lot_open_par_theme` et `uq_journey_step_lot_unite` (V069).

**Motif.** L'alternative — un `COALESCE(skill_id, official_unit_id)` dans un index d'expression —
fusionnerait deux espaces d'identifiants distincts, et une collision d'UUID entre les deux tables
serait un bug indétectable. Deux index disent ce qu'ils gardent.

### A53 — **Une violation de contrainte par méthode de test**, jamais deux

Un statement en échec **aborte** la transaction Postgres (`25P02`) : le second `assertThatThrownBy`
d'une même méthode échoue alors sur « current transaction is aborted », **pas** sur la contrainte
visée — un test qui passe pour la mauvaise raison. Les tests de schéma civique comptent donc
**12 méthodes** là où 8 auraient suffi à couvrir les cas. ⚠️ À connaître avant de « regrouper les
assertions » dans un `*SchemaIT`.

### A54 — Le test de **S-8** change de SENS plutôt que d'être supprimé

**Le constat.** `CycleCiviqueSchemaIT` vérifiait l'**absence** de `official_unit_id` sur
`learning_plan_observations` : V069 refusait de la poser parce que ç'aurait **pré-décidé E-2**, et
qu'une colonne morte dans une migration livrée est définitive.

**La décision.** L'arbitrage a eu lieu (**D-49**), V070 a posé la colonne, et le test **inverse son
assertion** au lieu de disparaître : il fige que S-8 est **levé**, et son commentaire dit dans quel
**ordre** (arbitrage, puis migration).

**Motif.** Un test supprimé n'apprend plus rien ; celui-ci porte la seule chose qu'un relecteur
voudra vérifier ici — que la colonne n'a pas précédé la décision. C'est aussi ce que le propriétaire
a appelé « la meilleure décision de cette passe » : sortir `learning_plan_observations` du périmètre
de V069, **reporté et non oublié**, la note vivant dans l'en-tête de V069.

---

# 2026-09-19 — P8.4, points 2 et 2 bis : décisions prises en autonomie (A55 → A60)

> Arbitrages : **D-50** (les écrans, l'objectif servi) et **D-51** (V071). Ce qui suit est ce que
> personne n'a tranché et qu'il a fallu décider pour livrer `getOrCreate` par module et l'objectif
> servi.

### A55 — `getOrCreate` devient **deux chemins**, pas un `if` au milieu d'un seul

`getOrCreate(userId, module)` dispatche vers `cycleTcf(user)` ou `cycleCivique(user)`.

**Motif.** Les deux ne partagent presque rien : l'objectif n'a pas le même type, ne se lit pas au
même endroit (`niveauVise()` d'un côté, la mention déclarée de l'autre) et l'amorce n'est pas la
même. Un `if` au milieu d'une méthode unique aurait mélangé deux règles dont **aucune ligne** n'est
commune, et le `switch` sur le module **échoue à la compilation** le jour où un troisième module
apparaît.

### A56 — Le module d'une évaluation vient de **sa nature**, jamais d'un paramètre à côté

`JourneyAssessmentKind.module()` : les trois `CIVIC_*` rendent `CIVIQUE`, les quatre autres `TCF`.
`onAssessmentCompleted` s'en sert au lieu de recevoir un module.

**Motif.** Deux paramètres qui disent la même chose finissent par se contredire — et le symptôme
serait **muet** : une évaluation civique classée TCF n'alimenterait aucun cycle, sans erreur.

### A57 — Un **garde bruyant** sur le cycle de mesure d'un module non TCF

`creerCycleDeMesure` lève un `UnsupportedOperationException` explicite si le module n'est pas TCF.

**Motif.** Sa boucle pose **quatre** étapes d'examen sur les épreuves TCF ; le cycle de mesure
civique en veut **cinq**, de thématique (R1, D-51). Laisser passer fabriquerait un cycle de mesure
TCF **dans un parcours civique**. Le garde est inatteignable aujourd'hui — le contrôleur passe
`Module.TCF` —, et c'est exactement pourquoi il doit être bruyant : il ne se déclenchera que le jour
où quelqu'un câblera l'endpoint civique sans faire le travail.

### A58 — Le **libellé d'une mention** devient une autorité **serveur**, gelée par test

`TargetProcedure.getLabel()` rend « Carte de séjour pluriannuelle », « Carte de résident »,
« Naturalisation ».

**Motif.** `JourneyObjectifRefDto.label` est **servi** (D-50), comme celui du bloc (A48) : c'est ce
qui garantit qu'une mention et un palier s'affichent **par le même chemin**. Les trois chaînes sont
**mot pour mot** celles que les deux fronts affichent déjà (`MENTION_LABEL` ⇄ `mentionLabel`), et
`TargetProcedureTest` les fige — la technique de `SkillLabelsTest`.

🛑 **Le motif décisif, ajouté par le propriétaire (2026-09-19), et il prime sur le mien.** Ce
libellé n'est pas une chaîne d'interface : c'est une **notion administrative**. « Naturalisation »,
« carte de résident », « carte de séjour pluriannuelle » sont les **trois mentions de l'article 1 de
l'arrêté**. Le jour où l'administration en renomme une, **la vérité change à un endroit, pas à
trois**.

> « Ta gêne était juste — trois chaînes en quatrième copie, c'est un coût réel — mais elle se résout
> par la question habituelle : **est-ce que l'arrêté le dit ?** Ici oui. »

⇒ La question à se poser devant un libellé candidat au service n'est donc pas « est-ce que ça évite
une copie ? » mais « **est-ce que le référentiel le nomme ?** ». Si oui, il est servi ; sinon, il
reste au front.

**Si l'arbitrage était autre** (« le front garde son libellé, on ne sert que le code ») : supprimer
`getLabel()` et lire le code dans les deux miroirs existants. ⚠️ Mais ce serait laisser une **notion
de l'arrêté** vivre en deux copies front sans autorité — exactement ce que D-48 refuse pour le
programme.

### A59 — La **tournure** du titre se choisit sur la nature de l'objectif

« Votre parcours vers le **B2** » pour un palier, « Votre parcours — **Naturalisation** » pour une
mention.

**Motif.** « Votre parcours vers le Naturalisation » ne se dit pas. Le front branche donc sur
`kind` — un fait **servi** —, jamais sur le module : c'est le même geste que `journeyBlocMark`, qui
rend une chaîne vide pour une thématique (A49). ⚠️ **La phrase civique est mon choix** : D-50 a fixé
le texte de la **bande objectif** (« Objectif : naturalisation · seuil 32/40 »), pas celui du titre
de section.

### A60 — Un cycle civique naît **vide**, et c'est un manque **assumé**

`cycleCivique` crée la ligne et n'amorce rien.

**Motif.** Les priorités civiques viennent du **diagnostic civique** et se posent au grain de
l'**unité officielle** (D-48) : c'est le point suivant de P8.4, avec son ordre lu chez
`CivicPrioriteScorer` (D-36, tranché par le propriétaire : **lire** l'ordre existant, le remonter
s'il ne convient pas, ne pas en créer un second). ⚠️ Aucun écran ne montre ce vide : le Plan civique
lit toujours son plan dérivé jusqu'à P8.7.

🛑 **C'est un ÉTAT DE TRANSITION, pas un comportement** (précision du propriétaire, 2026-09-19).

> « Un cycle vide qu'aucun écran ne montre est **invisible tant qu'il n'existe qu'en test**. »

⇒ **Au point 4, un cycle civique sans priorité doit devenir impossible ou explicite** : soit la
création échoue tant qu'il n'y a rien à poser, soit le cycle porte un état qui **dit** qu'il attend
son amorce — comme `attendSonAmorce()` le fait déjà côté TCF. Ce qu'il ne doit pas rester, c'est une
ligne muette qui a l'air d'un cycle et n'en est pas un.

---

# 2026-09-19 — P8.4, point 3 : l'axe des blocs (A61 → A63)

### A61 — L'axe est **reçu**, pas déduit d'un module

`JourneyBlocResolver.lire(...)` prend la **liste ordonnée des blocs**
(`List<JourneyBlocRefDto>`) et groupe par `step.blocCode()`. Il ne reçoit **pas** le module.

**Motif.** Lui passer le module aurait mis un `if` dans le composant qui, justement, ne doit plus
savoir de quel module il parle — c'est tout l'acquis de D-47. `JourneyReadService` choisit l'axe :
`TcfDomainProfileDto.ORDRE` reste l'autorité **TCF** (D-9, D-20, **intacte**), et côté civique
l'ordre vient de `themes.display_order`, une **donnée** qu'aucun enum ne peut connaître.

**Si l'arbitrage était autre** : un second resolver civique. Ce serait deux copies de « statut d'un
bloc », et le dépôt sait ce que coûtent deux copies d'une règle.

### A62 — Côté civique, « jamais mesuré » rend **vrai**, et c'est écrit comme un état de transition

**Le problème.** Le statut d'un bloc vide se décide sur « ce bloc a-t-il déjà été mesuré ? ». Côté
TCF, l'autorité est `NiveauActuelEpreuveResolver`. Côté civique, l'autorité du cycle est
l'**observation** (D-49) — et **rien n'en écrit encore** (point 5).

**La décision.** Le prédicat civique rend **vrai** : toutes les thématiques sont `A_EVALUER`.

**Motif.** Répondre « déjà mesuré » rendrait un bloc `TERMINE` **sans que rien n'ait été mesuré** —
le plus coûteux des deux mensonges, et exactement la famille V040/V041/V042. « Jamais mesurée » est
**littéralement vrai** aujourd'hui.

⚠️ **À brancher au point 5** sur la lecture des observations civiques par unité. Le javadoc de
`jamaisMesure` le dit, et un test fige les cinq `A_EVALUER` — il passera au rouge le jour où le
comportement changera sans qu'on le veuille.

### A63 — 🛑 Le verrou de bloc (**D-15**) devient une clé de **bloc**, et il levait un NPE

**Trouvé par le premier test civique**, pas par une relecture :

```java
case SECTION_EXAM -> blocsAvecCompetenceOuverte.contains(step.getExamType())
```

Un examen de thème n'a **pas** d'`exam_type`. Or `Set.of().contains(null)` **lève un
`NullPointerException`** — dans le chemin de **lecture** du Plan.

**La décision.** `blocsAvecTravailOuvert` porte des **codes de bloc** (`step.blocCode()`), et le
verrou de production TCF garde sa clé d'épreuve avec un test de nullité explicite.

**Ce que ça donne.** **D-15 se transpose mot pour mot** — « l'examen du bloc est verrouillé tant
qu'une unité du bloc reste ouverte » — sans qu'une seule ligne ne sache de quel module il s'agit.
⚠️ C'est la **deuxième fois** dans ce chantier qu'un `EpreuveType` nul aurait produit une panne
silencieuse ou brutale ; la réponse est toujours la même : lire l'axe **à la source**.

---

# 2026-09-19 — P8.4, point 4 : les priorités civiques (A64 → A67)

### A64 — 🛑 Une **boucle de dépendances Spring**, supprimée plutôt que cachée

**Le fait.** Faire lire au cycle l'ordre du plan dérivé (D-36) a refermé une boucle, et le contexte
Spring a **refusé de démarrer** :

```
CivicPlanService → AttemptService → AttemptInteractionService → JourneyService → CivicPlanService
```

**La décision.** `CivicPlanService` n'appelle plus `attemptService.readAttempt(...)` — qui ne fait
que **déléguer** — mais le **mapper** directement, avec le manager qu'il possédait déjà.

**Motif.** Un `@Lazy` l'aurait **cachée** ; appeler le mapper la **supprime**. Et c'est aussi ce que
la convention de couches demande : *un service n'appelle pas un autre service pour mapper*. Le
correctif tient en trois lignes et **retire** une dépendance au lieu d'en ajouter une.

⚠️ **Ce que ça dit du découpage** : `CivicPlanService` **calcule** un plan **et** démarre une série.
Les deux ne relèvent pas de la même couche. Ce n'est pas urgent — la boucle est fermée —, mais si
une seconde dépendance d'action y entre, c'est le signal d'extraire un `CivicSerieService`.

### A65 — L'amorce civique : **deux cas sur trois**, et le troisième est remonté

**Livrés** (spec §2) : *diagnostic fait* ⇒ les thématiques prioritaires sont **peuplées** de leurs
unités, les autres passent en « Évaluer mon niveau » · *rien de fait* ⇒ **les cinq** en « Évaluer
mon niveau ».

🛑 **A60 est fermée** : un cycle civique n'est plus jamais vide. Le pire cas est **cinq examens à
passer**.

⚠️ **Le 3ᵉ cas est INATTEIGNABLE aujourd'hui** — « examen de thème passé sans diagnostic ⇒ ce thème
peuplé ». `CivicPlanService` ne construit **aucun plan** sans diagnostic terminé : sans plan, il
n'existe **aucune cible** à poser, donc rien avec quoi « peupler ». Ce cas retombe **volontairement**
sur « les cinq à évaluer », et R1 fermera l'étape du thème déjà passé quand son examen sera
journalisé. **À arbitrer** : soit le plan devient constructible depuis un examen seul, soit ce cas
de la spec disparaît.

### A66 — Une cible au grain **THÈME** ne devient pas une priorité

**Le problème.** Le plan dérivé travaille au grain **notion** ou **thème**, selon le tagging du
thème. Une cible au grain THÈME ne désigne **aucune notion**, donc aucune **unité officielle**.

**La décision.** Elle est **ignorée** comme priorité ; sa thématique retombe alors sur « Évaluer mon
niveau ».

**Motif.** Le cycle ne peut pas nommer une unité qu'il ne connaît pas, et **inventer** — « toutes les
unités du thème » — fabriquerait un travail que rien n'a désigné. Une absence de mesure se répond
par une **mesure**, pas par une supposition : *null = inconnu, jamais mauvais*.

### A67 — La **borne de 3 priorités par lot** est lue chez la même autorité que le TCF

`TcfJourneyConfig.maxPrioritiesPerLot` (D-20), y compris pour un lot civique — malgré le nom `Tcf`
de la classe.

**Motif.** Une seconde valeur ferait **deux règles** là où il n'y en a qu'une, et D-20 ne parle pas
d'épreuves : elle parle de ce qu'une file **met en attente**. ⚠️ Le **nom** de la classe est
trompeur maintenant qu'elle sert les deux modules — à renommer le jour où on y touchera pour une
autre raison, pas pour celle-là seule.

---

# 2026-09-19 — P8.4, point 5 : l'écrivain d'observation civique (A68 → A70)

### A68 — Le statut par ratio est **extrait** à sa 2ᵉ occurrence

`StatutObservation.selonRatio(ratio, config)` (`util/`), appelée par
`ComprehensionObservationService` **et** par `CivicObservationService`.

**Motif.** La règle — `≥ solid-ratio ⇒ SOLID`, `≥ reinforce-ratio ⇒ TO_REINFORCE`, sinon
`PRIORITY` — allait être recopiée. C'est la règle du dépôt : **2ᵉ occurrence ⇒ on extrait**. Les
seuils restent **lus** dans `learning-plan.comprehension` : aucun 9ᵉ seuil n'est déclaré, et
recalibrer relit tout l'historique sans migration.

### A69 — Une source **TCF** passée à l'écrivain civique **lève**

**Motif.** Ce n'est pas une donnée, c'est un **branchement faux**. Laisser passer écrirait une
observation civique sous une source de compréhension, et `JourneyEvaluationFilter` — qui déduit de
la source qu'une série **n'évalue pas** (R3) — dirait n'importe quoi. Même raisonnement que
`SkillMasteryEngine`, qui lève plutôt que d'inventer un poids (**A50**).

### A70 — L'unité d'une question est résolue **chez l'autorité qui la connaît déjà**

`CivicExamCompositionService.uniteOfficielle(Question)`, posée **à côté** de
`thematiqueOfficielle(Question)`.

**Motif.** La règle « de quelle unité relève cette question » existait déjà à moitié : la
composition d'examen la connaît, avec ses deux chemins — la notion pour une connaissance, **le
thème** pour une mise en situation, qui n'a jamais de notion (D-35). En écrire une seconde version
dans l'écrivain d'observation aurait fait diverger le **tirage** et la **mesure** : un examen aurait
pu tirer une question sur une unité que l'observation aurait rangée ailleurs.

⚠️ **L'écrivain ne résout rien lui-même** : il reçoit des `ReponseCivique(uniteId, …)`, des
**valeurs**, parce qu'il écrit en `REQUIRES_NEW` et que rien de détaché ne doit traverser cette
frontière. C'est l'appelant — le branchement, point 7 — qui appelle l'autorité.

---

# 2026-09-20 — P8.4, points 6 et 7 : R2 par unité, et l'examen porté au cycle (A71 → A74)

### A71 — Une seule carte de séries, **deux clés de lecture**

`seriesDepuisLaCreation` rend une `Map<UUID, Series>` dont la clé est la **compétence** TCF **ou**
l'**unité** officielle, et `auQuota(Series)` porte la formule de D-16 **une seule fois**.

**Motif.** « Seule la clé de lecture change » — R2 ne bouge pas d'un mot. Deux méthodes jumelles
auraient fait deux copies de « 2 réussies ou 4 terminées », et c'est le défaut le plus cher du
dépôt.

**Pourquoi une seule carte est sûre.** Une étape porte **exactement un** des deux identifiants
(`chk_journey_step_train_skill`), et elle relit **sa** clé. Les deux espaces d'identifiants ne se
rencontrent jamais. ⚠️ C'est l'inverse du choix d'**A52** (index jumeaux plutôt qu'un `COALESCE`) —
et pour une raison : là c'était **la base** qui devait garantir l'unicité sur deux espaces, ici
c'est une lecture en mémoire où chaque étape désigne sa propre entrée.

### A72 — `JourneyEvaluation` garde son constructeur **TCF** à quatre arguments

Le composant `themeId` s'ajoute à la fin ; un constructeur compact à 4 arguments délègue avec
`themeId = null`.

**Motif.** 13 appels TCF n'ont aucune thématique à déclarer. Leur faire écrire `null` n'aurait rien
appris à personne, et aurait rendu la revue de ce commit illisible. L'invariant, lui, est le
**miroir exact** de `chk_journey_assessment_mesure` (V071) : il échoue **à la ligne fautive**, pas
trois couches plus haut dans un `catch`.

### A73 — L'examen complet écrit ses **cinq** lignes de thématique, l'examen de thème **non**

Pour une `CIVIC_EXAM`, chaque bloc validé reçoit **en plus** une ligne `CIVIC_THEME_EXAM`. Pour une
`CIVIC_THEME_EXAM`, rien n'est réécrit : **l'évaluation elle-même est cette ligne**.

**Motif.** La réécrire violerait `uq_journey_assessment_event_par_theme` — et ce serait la même
mesure comptée deux fois. ⚠️ Effet à connaître : les cinq lignes ne sont écrites **que pour les
blocs débloqués**. Un examen complet passé alors que deux blocs ont encore des unités dues écrit
donc **quatre** lignes, pas six — le journal dit ce qui a été **validé**, pas ce qui a été passé.

### A74 — `lot_theme_id` distingue les deux examens, et rien d'autre

`attempt.getLotThemeId() != null` ⇒ examen de thème ; sinon ⇒ examen complet.

**Motif.** Il est posé **à la création de l'attempt** et **déjà persisté** — la spec §2 le notait
comme le fait qui rend R1 faisable. Relire le template d'examen ou recompter les questions par
thématique aurait fabriqué une **seconde** définition de « quel examen est-ce », qui aurait pu
diverger de la première.

---

# 2026-09-20 — P8.2b et le défaut de surface (A75 → A77)

### A75 — 🛑 `priorites` porte son plafond **dans son nom** : `prioritesVisibles`

**Le constat du propriétaire**, et il va plus loin que la règle de test :

> « Trois tests dormants en deux jours, tous dans le plan civique, tous sur le même motif. Ce n'est
> plus une règle de test, c'est un **défaut de surface** : `priorites()` est trop facile à confondre
> avec `proposables()`. »

**La décision.** Le champ **servi** est renommé sur les trois surfaces :
`priorites` → `prioritesVisibles`, `aRevoir` → `aRevoirVisibles`. La configuration s'appelait
**déjà** `prioritesVisibles` — c'est le DTO qui mentait.

**Motif.** Un appelant ne peut plus lire « la liste des priorités » et croire qu'il les a toutes :
le nom lui dit qu'il en voit une partie. La liste **complète et ordonnée** a désormais un nom à
elle, `ordrePourLeCycle(userId).cibles()`, et c'est celle que le cycle lit (D-36).

**Coût réel** : 1 champ Java, 2 miroirs front, ~50 sites d'appel — tous trouvés par le compilateur
et par `tsc` / `analyze`, aucun par relecture. ⚠️ **Aucune migration, aucun écran changé** : c'est
un nom de champ sur le fil, et les trois fronts basculent dans la même passe.

**Si l'arbitrage était autre** (« garder `priorites` sur le fil, renommer seulement côté Java ») :
un `@JsonProperty` suffirait. Écarté — le nom aurait alors menti dans deux langages sur trois, et
c'est précisément aux lecteurs des fronts qu'il faut dire qu'ils voient un extrait.

### A76 — Le stock **borne** la série, à la source

`questionsSerie = min(questionsParSerie, stock réel de la cible)` dans `CivicPlanService.cible(...)`.

**Motif.** `DETTE-C1` disait : le plan promet 10, le tirage en sert 8. Corriger le **test** aurait
figé le mensonge ; corriger le **tirage** aurait ajouté une règle. La borne se pose là où le nombre
est **fabriqué** — un seul endroit, et tout ce qui le lit devient juste.

### A77 — Le cas de **V058** disparaît, et c'est écrit

« Devenir français » : 10 questions en NAT, **zéro** en CSP. C'était le cas réel qui justifiait
`NON_APPLICABLE`. Sans filtre de mention, ces 10 questions sont **jouables par tout le monde**.

**Motif.** C'est D-27 appliqué, pas un effet de bord : **un seul programme, une seule banque**. Le
nommer maintenant évite qu'il se redécouvre plus tard comme une régression — un test l'assertait,
il a été retourné avec son motif sur place.

---

# 2026-09-20 — P8.4, point 8 : la fin de cycle civique (A78 → A80)

### A78 — 🛑 **Il n'y a pas de cycle EN ATTENTE civique**, et c'est une conséquence de D-36

**Le raisonnement.** Côté TCF, le cycle en attente existe parce que les priorités naissent
d'**évaluations datées** : celles qui arrivent pendant qu'un cycle est en cours doivent être mises
quelque part, sinon elles se perdent. Côté civique, les priorités sont **dérivées** — le plan les
recalcule à chaque lecture. **Il n'y a rien à stocker.**

**La décision.** `actualiser` civique **historise** puis **ré-amorce** : le cycle suivant se construit
sur le plan **tel qu'il est au moment où on l'ouvre**, ce qui est plus juste qu'une liste figée des
semaines plus tôt.

⚠️ **Conséquence assumée** : `JourneyStatus.EN_ATTENTE` n'existe jamais côté civique. L'index
partiel de V067 l'**autorise**, il ne l'exige pas — un test le fige.

**Si l'arbitrage était autre** : il faudrait une raison de figer des priorités dérivées, et je n'en
vois pas — sinon reproduire la structure TCF pour la symétrie, ce qui est le mauvais motif.

### A79 — Le **score de sortie** est un fait déjà vu, recopié

`exit_score` = le score du **dernier examen civique COMPLET** journalisé par ce cycle, lu sur
`attempts.score` via le journal. `null` quand il n'y en a pas.

**Motif.** Le candidat a **déjà vu ce score** à la fin de cet examen : le cycle le **recopie**, il ne
le recalcule pas, ne le pondère pas et n'en fabrique pas un second. C'est pourquoi ce n'est pas un
verdict nouveau — et donc pas un arrêt.

⚠️ **Un examen de thème ne compte pas** : 20 questions, pas les 40 de l'arrêté. Mélanger les deux
échelles ferait un chiffre qui ne veut rien dire. Et **`null` = inconnu, jamais zéro** : un cycle de
travail sans examen complet n'a pas un score de zéro.

🛑 **Le score n'est pas recopié dans le journal** : il vit sur l'attempt, on le relit là où il a été
écrit. Une seconde copie aurait pu diverger de la première.

### A80 — Le cycle de mesure civique : **cinq** blocs, tous en `REASSESS`

**Motif du `REASSESS`.** Un cycle de mesure ne s'ouvre qu'à la **fin d'un cycle entier** : tout a été
travaillé ou mesuré. Le geste est « **vérifier mes progrès** », jamais « évaluer mon niveau ».

⚠️ **Aucune unité n'y est posée**, et c'est la définition même du cycle de mesure —
`JourneyBlocResolver.cycleDeMesure` le reconnaît à l'absence de `TRAIN_SKILL`. Les cinq examens sont
donc ouverts d'emblée : **D-15 n'a rien à verrouiller**, et ils se passent thème par thème.

🛑 **Et le garde bruyant d'A57 a disparu en étant HONORÉ**, pas contourné : il disait « cinq blocs de
thématique, pas quatre épreuves ». C'est exactement ce qui est écrit maintenant.

### A81 — `nouveauCycle` **pose** l'objectif, il ne le copie pas champ par champ

`poserObjectif(procedure)` ou `poserObjectif(niveau)` selon ce que porte le précédent.

**Motif.** `setTargetLevel(precedent.getTargetLevel())` sur un cycle civique aurait posé `null` sur
les **deux** objectifs — une ligne que `chk_journey_objectif` refuse **au flush**, loin de la ligne
fautive. L'exclusivité se garantit à la source (même geste que `poserBloc`).

---

# 2026-09-20 — P8.5 : le freemium civique (A82 → A83)

### A82 — `enforceMockExamSlotAccess` quitte le chemin civique, et **la borne du slot reste**

**La règle** (D-33, Q-F9) : le diagnostic et `civique-decouverte` sont gratuits, **tout le reste est
premium**. Plus de slot, plus de ledger, plus de « première fois ».

🛑 **Mais la borne 1..20 du `slotNumber` reste appelée.** Le slot n'ouvre plus aucun droit — il
reste un **repère de grille** (V110), et une valeur hors borne reste une valeur fausse :
`slotNumber: 999` ou `-3` étaient persistés tels quels avant qu'elle existe. ⚠️ C'est le piège de ce
point : retirer le verrou emportait la **validation** avec lui, et un test l'a attrapé
(`mockExam_slotHorsBorne_refuse`).

**Ce qui reste gratuit ne passe pas par ici** : `civique-decouverte` est servi par
`startFromTemplate`, qui lit `template.isFree()` — son unique autorité, et une **promesse publique**
(D-46).

### A83 — 🛑 Les deux fronts promettaient un examen que le serveur refuse désormais

**Trouvé en vérifiant la parité**, pas en codant : les deux écrans d'examens de thème affichaient
« **examen 1 gratuit, 2+ premium** » — `freeSlots={isGuest ? 0 : 1}` côté web,
`slot > 1` côté mobile.

Sans changement, un compte gratuit aurait cliqué sur un examen annoncé **offert** et reçu un
**403**.

**La décision.** Les deux écrans passent à « tous premium », **dans la même passe**, avec le motif
écrit sur place.

**Motif.** Le verrou est **opposable serveur** ; l'écran ne fait que le **lire**. Un écran qui
promet ce que le serveur refuse n'est pas une divergence d'affichage, c'est une **promesse rompue** —
et le candidat la découvre au moment où il clique.

⚠️ **Ce n'est pas un arbitrage nouveau** : D-33 a tranché « examens de thème : premium » le
2026-09-19. Les fronts n'avaient simplement pas suivi, parce que rien ne les y forçait — le verrou
n'existait alors **que côté client**.

# 2026-09-20 — lancée 3 : les écrans du cycle civique (A84 → A90)

> Périmètre : **P8.6** (la brique de kit), **P8.7** (les deux écrans), le chantier **DETTE-P1** et
> **P8.9 côté serveur**. Mandat du propriétaire : « Tu tranches, tu consignes à la suite d'A83 ».
> ⛔ Restés fermés, comme demandé : toute migration, les 28 questions de P8.8, et l'écran
> d'historique civique.

### A84 — Le miroir `civic-plan.ts` ⇄ `civic_plan_labels.dart` porte sur le **texte**, pas sur l'inventaire

**Le fait.** La refonte de D-50 a vidé le plan civique **abonné** de cinq sections. Les helpers qui
les servaient sont morts — mais **pas des deux côtés au même moment** : l'écran **gratuit** du mobile
lit encore `civicPlanAutresLabel` (« + 3 autres thèmes à consolider »), `kCivicPlanLockedCta` et
`CivicCibleTone`, que le web n'a jamais affichés sur le sien.

**La décision.** Chaque front supprime **ce que lui ne lit plus**, et l'asymétrie est **écrite en tête
des deux fichiers**. Le contrat du miroir devient explicite : il porte sur **les chaînes partagées**,
jamais sur la liste des symboles.

**Les deux options écartées.**
- *Garder les helpers morts côté web* : le dépôt interdit la cohabitation (« refonte = suppression
  immédiate de l'ancien »), et un export sans lecteur finit par être rebranché au hasard.
- *Aligner les deux écrans gratuits dans la même passe* : c'est une **troisième** refonte d'écran,
  hors du mandat, et l'écran gratuit n'est pas ce que D-50 arbitre.

**Si l'arbitrage était autre** : il faudrait refondre l'écran **gratuit** des deux côtés, et c'est là
que les trois helpers reviendraient — sur le web, cette fois.

🛑 **Une exception, assumée dans l'autre sens** : `civicPlanGrainNote` **descend sur l'écran gratuit du
mobile** au lieu d'y mourir. Elle vivait dans la carte de contexte de l'abonné, que D-50 retire — or
c'est justement l'écran gratuit qui liste des **thèmes**, et le web portait déjà cette note en pied de
`CiviqueGratuit`. Supprimer un fait vrai d'un côté quand l'autre l'affiche aurait creusé DETTE-P1 au
lieu de la refermer.

### A85 — « Verrouillé » est un **libellé du parcours**, pas une chaîne d'écran

**Trouvé en portant la carte sur le mobile** : le badge d'une étape verrouillée était écrit **en dur**
dans `CivicPlanPanel.tsx` (`badge={etape.locked ? "Verrouillé" : undefined}`). Le porter tel quel
côté Dart en aurait fait **deux copies** d'un mot que les deux cartes disent du même fait servi.

**La décision.** `JOURNEY_LOCKED_BADGE` ⇄ `kJourneyLockedBadge`, dans `journey.ts` ⇄
`journey_labels.dart` — là où vivent déjà les phrases du parcours. Le web a été corrigé dans la même
passe.

**Motif.** C'est la règle du dépôt appliquée à la lettre : **une règle = une autorité**, et un libellé
qui décrit un `locked` **servi** appartient aux mots du parcours, pas à l'écran qui le rend. Le seuil
de la 2ᵉ occurrence était atteint à l'instant même où je l'écrivais une seconde fois.

### A86 — `PlanCycleSection` devient **commune**, et son `plan` devient nullable

**La décision technique était validée** par le propriétaire (D-50) ; ce qui restait à trancher, c'est
**comment** le module entre dans la section.

**Ce qui a été fait, des deux côtés :** un paramètre `module` (défaut TCF) et un `plan` **nullable**.
Deux points, et deux seulement, en dépendent :
1. **l'action d'une étape** — série sur l'**unité officielle** servie en civique
   (`serieSurUnite(code)`), exercice du Plan TCF sinon ;
2. **la sortie de fin de cycle** — examen civique complet (`MOCK_EXAM`, module `CIVIQUE`) ou examen
   TCF complet.

🛑 **`plan: null` n'est pas un oubli, c'est le contrat** : demander au **Plan TCF** de résoudre
l'action d'une étape civique rendait `null`, donc une ligne **sans geste** — le garde-fou du
2026-09-17 se serait déclenché sur toutes les lignes. Le type le dit maintenant.

**L'option écartée** : deux sections, une par module. C'est exactement ce que D-50 refuse — deux
écrans qui divergent au premier correctif, pour un moteur unique.

### A87 — Un lanceur **par grain**, jamais un lanceur par écran

**Le fait.** Le civique a maintenant **deux** grains d'action : la **cible** du plan dérivé (une
notion) et l'**unité officielle** du cycle (D-48). Deux routes serveur, déjà livrées.

**La décision.** Deux lanceurs, **un par grain**, chacun unique pour tous ses écrans :
`useCivicSerie` / `startCivicSerie` (cible) et `useCivicUniteSerie` / `startCivicUniteSerie` (unité).
Les deux routent le **403** vers l'offre, les deux signalent l'écriture de mesure.

**Motif.** La règle du dépôt dit « une même cible ne peut pas s'ouvrir de deux façons selon l'écran » :
elle est respectée **par grain**. Un lanceur unique qui aurait accepté « soit un id de cible, soit un
code d'unité » aurait porté un aiguillage à l'intérieur, donc la règle des deux routes dans un seul
endroit — c'est le motif qui a déjà coûté `estimateCostCents` en 11 copies, dans l'autre sens.

### A88 — Un provider de cycle **par module** côté mobile, pas un `family`

**Le fait.** Le web a des clés de cache par module (`journeyApi.cacheKeyFor`). Le mobile n'avait qu'un
`journeyProvider`, TCF en dur.

**La décision.** `journeyCiviqueProvider`, à côté de `journeyProvider` — mêmes points de fraîcheur
exactement (`compteIdProvider`, `learningPlanRevisionProvider`, `keepAlive` + `link.close()` sur
l'erreur), et **les deux observés en permanence** par `PlanScreen`.

**Motif.** Un `family` sur le module aurait été plus court, mais les deux réponses sont des **objets
différents** : les servir sous une clé paramétrée ouvrait la porte au défaut déjà payé le 2026-09-12 —
un provider `autoDispose` jeté à la bascule, donc un appel par changement d'onglet, et surtout le
**risque de voir le cycle TCF sur l'onglet civique** le temps d'une résolution.

⚠️ **Coût assumé** : un appel de plus à l'ouverture du Plan. C'est le même compromis que
`civicPlanProvider`, déjà chargé pour que la bascule soit gratuite.

### A89 — L'écran **gratuit** civique n'est pas touché, et `_nowCard` perd son drapeau `free`

**Ce que D-50 arbitre**, mot pour mot, c'est « le Plan civique **abonné** ». L'écran gratuit garde donc
ses sections — résultat du diagnostic, thèmes à travailler, priorités, première étape, offre.

**Mais une fonction en sort changée** : `_nowCard(cible, {required bool free})` servait **les deux**
écrans ; elle n'a plus qu'un appelant, gratuit. Le drapeau est **supprimé**, avec la branche qui
portait la pastille « Priorité n°1 » et le bouton d'un abonné.

**Motif.** C'est le défaut corrigé le 2026-09-12 côté TCF, à l'identique : une carte d'abonné servie à
un compte sans accès par un drapeau qu'on oublie de poser. Le retirer, c'est retirer la possibilité de
l'oublier. Même geste sur `_prioritiesSection` / `_priorityCard`.

### A90 — P8.9 : le module est servi jusqu'à `/history`, et **rien n'est conçu au-dessus**

**Ce qui est livré** : `GET /api/me/plan/journey/history?module=` rend les cycles historisés du module
demandé, blocs groupés par **bloc servi** (une épreuve en TCF, une thématique en civique), et les
quatre méthodes du repository mobile portent le paramètre.

**Ce qui n'est PAS livré, volontairement** : aucun écran, aucune ligne de rendu, aucun libellé
d'historique civique. Le propriétaire n'a pas fourni le gabarit, et la consigne était explicite —
« tu peux étendre l'endpoint, tu ne conçois rien sur l'écran d'historique ».

🛑 **Le défaut reste TCF sur les quatre routes** : un client antérieur à P8.9 garde exactement le
comportement d'avant. C'est ce qui permet de servir le fait maintenant et de dessiner l'écran plus
tard, sans rien casser entre les deux.

⚠️ **Un test existant a été mis à jour, pas contourné** :
`mobile/test/learning_plan_revision_test.dart` implémente `LearningPlanRepository` et ses quatre
signatures ont changé. Il compile à nouveau et reste vert — c'est la règle du dépôt (« un test rendu
rouge par un changement voulu se met à jour »), pas un test neuf sur un front.

# 2026-09-20 — P8.9 : l'historique des cycles civiques (A91 → A94)

> **Blocage levé par le propriétaire** : « Le gabarit n'est plus à fournir : l'écran existe côté TCF
> et il fait référence. » Consigne : mesurer la route **réellement livrée** côté TCF, puis transposer
> **brique pour brique** avec le vocabulaire civique — et **remonter** tout écart plutôt que de
> l'arbitrer.

### A91 — Un seul écran, scopé par le parcours — jamais une seconde route

**Mesuré d'abord, comme demandé.** Ce qui existe côté TCF : route `/plan/progression` (web
`app/(app)/plan/progression/page.tsx` → `PlanHistoryView` · mobile `AppRoutes.planProgress` →
`PlanHistoryScreen`), atteinte depuis le Plan par la section **« Aller plus loin »** (web) /
`_links` (mobile), ligne **« Ma progression »**. L'écran : `Top` + `HeroBanner` à 3 compteurs →
`PanelHead` « Cycles terminés » → un `BlocAccordion` par cycle (un seul déplié, le plus récent) →
dedans une `JourneyRow` `done` par bloc + un `ExamStepBox` `locked` → `InfoNote` de pied.

**La décision.** Le civique prend **cet écran-là**, scopé : `?module=CIVIQUE` côté web,
`parcoursCiviqueProvider` côté mobile (le pendant Dart déjà employé par l'Accueil, le Plan et
Réviser). **Le TCF reste le défaut**, donc un lien déjà partagé vers `/plan/progression` aboutit
exactement où il aboutissait.

**L'option écartée** : une seconde route (`/plan/progression-civique`) et un second écran. C'est
précisément ce que ce chantier a passé son temps à supprimer — et le dépôt pose déjà « **un seul
mécanisme de sélection de module, et c'est `?module=`** ».

⚠️ **Un détail qui n'en est pas un** : la variable ne peut pas s'appeler `module` côté web (Next
l'interdit, collision avec le `module` de CommonJS au bundling). Elle s'appelle `parcours`.

### A92 — `entry_score` / `exit_score` s'affichent **ici, et nulle part ailleurs**

**Ce que le propriétaire a tranché** en levant le blocage : « le niveau d'entrée et de sortie est un
score sur 40 rapporté au seuil de 32, pas un niveau CECRL. C'est ici — et seulement ici — que
`entry_score` et `exit_score` s'affichent : D-50 l'interdit sur la bande objectif du Plan, pas dans
l'historique, où un résultat d'examen blanc est à sa place. »

**Ce que j'en ai fait.** Une fonction `_mesure(cycle, module)` — l'**unique** endroit qui choisit
l'axe — et trois lectures qui s'appuient dessus : le **titre** de l'encart (« Niveau mesuré » ⇄
« **Score mesuré** »), sa **pastille** (`B1 → B2` ⇄ `28/40 → 34/40`) et sa **note**.

🛑 **Les deux champs sont servis ensemble et un seul est rempli** : un cycle TCF porte des paliers,
un cycle civique des scores. `null` = inconnu **de ce module**, jamais zéro — un front qui aurait
déduit le module de la nullité se serait trompé sur un cycle civique sans examen, où les deux sont
nuls. D'où le module **passé explicitement** à chaque fonction, plutôt que deviné.

🛑 **Le seuil accompagne toute mesure civique** (`Seuil de réussite : 32/40.`), et ses deux nombres
viennent de `CivicExamFormat` — l'autorité du format (arrêté du 10 octobre 2025), jamais un 32 écrit
dans une phrase.

### A93 — Le ton de l'encart ne juge pas un score, et le civique **compte** ses examens au lieu de les nommer

**Deux points où la transposition littérale ne marchait pas. Ni l'un ni l'autre n'est un écart de
forme : les deux viennent de ce que le civique n'a pas d'équivalent à quelque chose du TCF.**

**1. Le ton.** L'encart TCF est `ok` dès qu'une mesure existe. Un score civique, lui, se compare à un
seuil : la tentation était de le peindre en rouge sous 32. **Je ne l'ai pas fait**, et le ton reste
`ok`. Motif : cet encart **constate un résultat daté**, il ne le juge pas — c'est déjà la règle de
l'écran TCF, et un rouge dans une **archive** reprocherait au candidat un examen qu'il a passé il y a
deux mois et qui l'a fait progresser depuis. Le seuil est **dit** dans la note ; le candidat compare
lui-même.

**2. La note.** Elle nomme les épreuves qui ont reçu un examen, **par leur initiale** — « CO · CE — … ».
Une thématique n'a **pas d'initiale** (A49 : « Principes et valeurs de la République » ne se réduit
pas à deux lettres). Transposée telle quelle, la note civique serait tombée dans la branche « aucun
examen n'a été enregistré » alors que des examens avaient bien eu lieu : **un mensonge**, pas un
trou d'affichage.

**La décision** : le civique les **compte** — « 3 examens de thème enregistrés ». Les nommer aurait
répété, en cinq noms complets, ce que le corps du cycle liste déjà trois lignes plus haut. Le compte,
lui, est un fait servi (`bloc.examens`).

### A94 — Une ligne d'accès sur le Plan civique, là où le TCF en a deux

**Ce que j'ai fait** : la section « Aller plus loin » est transposée **à l'identique** (même brique,
même icône, même libellé, même écran d'arrivée), avec **une seule** ligne — « Ma progression », celle
que le propriétaire a nommée.

**Ce que je REMONTE au lieu de l'arbitrer** : le TCF en a une **seconde**, « Mon diagnostic »
(`/diagnostic`). Le civique a bien la sienne (`/diagnostic-civique`), et « brique pour brique »
plaiderait pour la transposer aussi. Je ne l'ai pas ajoutée — une entrée de navigation que personne
n'a demandée est une décision produit, pas une transposition. **Une ligne à ajouter si le
propriétaire la veut** ; le commentaire est posé sur place des deux côtés.

### Et une duplication refermée au passage

`PLAN_PROGRESS_HREF` (`lib/plan-domain.ts`) et `JOURNEY_HISTORY_HREF` (`lib/journey.ts`) portaient le
**même chemin**, et la première n'avait plus qu'un lecteur. Elle est **supprimée** : l'adresse est
désormais scopée au parcours (`journeyHistoryHref(module)`), et une seconde copie n'aurait pas pu le
savoir. C'est « une règle = une autorité », appliquée à l'endroit exact où elle allait se payer.

# 2026-09-20 — Le join évaluation ⇄ observations (A95 → A98)

> **Déclencheur** : un candidat passe le diagnostic rapide TCF, ses fragilités EE sont bien
> observées, et le bloc « Expression écrite » du cycle affiche « Aucune compétence à travailler
> avant ». Mesuré avant d'affirmer, jamais déduit d'une lecture de code.

**Le fait, ⟦SQL⟧ sur la base de dev.** `JourneyLotBuilder.depuisEvaluation` retenait les
observations d'une évaluation par **égalité brute** :
`evaluation.sourceAssessmentId().equals(observation.getSourceId())`. Or côté **production** les
deux viennent de tables différentes — l'évaluation est un `attempts.id` (ou un
`diagnostic_sessions.id`), l'observation un `production_submissions.id`. **240** observations
`DIAGNOSTIC_EE`/`DIAGNOSTIC_EO` sont clavetées sur une soumission, **zéro** sur une session :
l'égalité ne matchait donc **jamais**, et un diagnostic rapide ne créait **aucun lot** EE/EO.

🛑 **Pourquoi ça ne s'était jamais vu** : le **bootstrap R19** se cale sur
`observation.getSourceId()`, donc il fonctionnait. Tous les lots EE/EO présents en base venaient
de lui. Le défaut ne frappait que le chemin **live** — donc les comptes neufs, ceux qui ouvrent
leur Plan avant de passer le diagnostic.

⚠️ **Et la correction n'était PAS de changer l'identité.** Passer `submission.id` au parcours
rouvrait **A11** / **A16** mot pour mot, et la base le montre : le 2026-08-17, trois événements
`SECTION_EXAM`/`TCF_EE` successifs pour une seule épreuve, dont deux ont vu leur lot remplacé
par la tâche suivante (R7). C'est la **jointure** qui était fausse.

### A95 — L'identité d'évaluation fait toujours partie de ses `source_id` d'observation

`JourneyObservationSources.pour()` rend `{identité} ∪ {soumissions couvertes}` plutôt
qu'un aiguillage « production → soumissions / compréhension → attempt ».

**Motif.** En compréhension, l'observation **est** clavetée sur l'attempt
(`LearningPlanObservationService` pose `source_id = attempt.id`) : une seule règle couvre donc
les quatre épreuves, au lieu d'un second aiguillage par épreuve à maintenir chez chaque
appelant. Sans risque de faux positif — les `source_id` viennent de tables distinctes, une
collision d'UUID est impossible.

**Si l'arbitrage était autre** (un ensemble strictement disjoint de l'identité) : il faudrait un
`switch` sur `examType` dans `pour()` **et** dans tous les tests qui fabriquent des observations
en réutilisant l'id d'évaluation.

### A96 — `depuisHistorique` filtre épreuve par épreuve, plus globalement

**Le problème.** Le bootstrap retenait l'union des `source_id` de référence puis regroupait par
épreuve. Une même identité — un diagnostic rapide — couvre désormais des observations EE **et**
EO ; un filtre global verserait donc les observations EO du diagnostic dans le lot EO même quand
l'EO a pour référence un examen **plus récent**.

**La décision.** Le filtre est appliqué par épreuve, avec un contrôle de section.

**Si l'arbitrage était autre** : le lot d'une épreuve pourrait mélanger deux évaluations de dates
différentes tout en étant étiqueté d'une seule — exactement ce que R19.2 interdit.

### A97 — Le bootstrap journalise l'identité d'évaluation, et les 11 lignes existantes ne sont pas reprises

**Le second défaut, de la même racine.** Le bootstrap écrivait dans
`journey_assessment_event.source_assessment_id` des **ids de soumission**, là où le chemin live y
écrit des ids d'attempt ou de session. La colonne portait **deux espaces d'identifiants**, et la
conséquence était réelle : sur `onAssessmentCompleted`, `getOrCreate` amorce d'abord (le bootstrap
enregistre sous l'id de soumission), puis `dejaTraitee` interroge l'**id d'attempt** — absent — et
**la même évaluation est traitée une seconde fois**.

**La décision.** Le bootstrap traduit chaque `source_id` d'observation en identité d'évaluation
avant d'écrire. La colonne ne porte plus qu'**un** espace d'identifiants. Aucune migration.

⚠️ **Les 11 lignes déjà écrites en base gardent leurs ids de soumission** — non reprises, comme
le veut la règle « arrêt avant toute migration ». Conséquence résiduelle, bornée : si l'une de ces
évaluations refaisait surface sur `onAssessmentCompleted`, elle serait traitée une seconde fois —
R14 (`estTropAncienne`) et R11 bornent les dégâts.

**Si l'arbitrage était autre** : une migration de données numérotée après V071, avec sentinelle
`@@…@@` et un test qui **relit le fichier** (patron `RejugementProductionsInexploitablesIT`).

### A98 — La déduplication du journal se fait par identité : une épreuve = une ligne

Avant, les 3 tâches d'une épreuve et les 2 productions d'un diagnostic produisaient jusqu'à
**5 lignes** de journal à l'amorce. Elles se replient sur **2** — une par évaluation. C'est ce que
`uq (journey_id, source_assessment_id)` voulait dire depuis le début.

**Si l'arbitrage était autre** : il faudrait une seconde colonne pour distinguer « l'évaluation »
de « la trace de chaque soumission », et le journal cesserait d'être la clé d'idempotence.

### ⚠️ Le motif, parce que c'en est un — **DETTE-A1 s'étend**

C'est la **troisième** panne silencieuse du moteur de cycle causée par *un identifiant lu hors de
son espace* — après `chk_journey_assessment_exam_type` (V071) et le NPE d'`estVerrouillee` (A63).
Les trois ont le même symptôme : **rien n'échoue**, le cycle ne se remplit simplement jamais.

🛑 **Et celle-ci est pire que les deux premières** : il n'y a même pas de `catch` qui avale
(`DETTE-M1`). Le join a rendu zéro ligne, ce qui est un résultat **légitime** (R9 : « zéro
fragilité observée donne zéro priorité »). Aucun log, aucune trace, aucun test rouge — et un écran
qui se contredit tout seul, puisque le Plan dérivé, lui, voyait bien les fragilités.

**Le garde-fou posé** : `JourneyObservationSources` est la **seule** autorité de la correspondance
évaluation ⇄ observations, dans les deux sens, et `JourneyObservationSourcesIT` fige les quatre
cas. **Le signal à surveiller** : une comparaison d'identifiants entre deux objets du moteur de
cycle qui ne passe pas par cette classe.

### A99 — Le garde mesure les OBSERVATIONS rattachées, jamais les priorités produites

**Décidé.** `JourneyObservationSources.joinVide(sources, evaluations)` rend `true` quand le
candidat a des observations d'évaluation et qu'**aucune** n'a été rattachée à l'évaluation en
cours. C'est ce prédicat, et lui seul, qui déclenche le `warn` de **D-54**.

**Motif.** « Zéro priorité » est un résultat **légitime** — R9 : « zéro fragilité observée donne
zéro priorité », et `JourneyLotBuilder` le dit déjà. Un garde posé sur le nombre de priorités
crierait donc sur des cas normaux, deviendrait du bruit, et on cesserait de le lire. « Zéro
observation rattachée » n'a, lui, aucune lecture légitime : le branchement est appelé **après**
l'écriture des observations (contrat documenté d'`onAssessmentCompleted`), donc à cet instant une
évaluation en a.

**Les deux faux positifs écartés explicitement**, et figés par test : un candidat **sans aucune
observation** (cas réel de R19.8 — le parcours demande alors un diagnostic) et une évaluation
**civique**, qui sort de `onAssessmentCompleted` avant ce point.

**Si l'arbitrage était autre** (« signaler aussi zéro priorité ») : le garde passerait au niveau
`debug`, ou il faudrait lui donner la nature de l'évaluation pour ne crier que là où une priorité
est attendue — et ce serait une seconde règle sur « qu'est-ce qu'une évaluation doit produire »,
là où R9 est déjà l'autorité.

### A100 — La table d'origine d'un identifiant est épelée dans le message, pas portée par un type

**Décidé.** `origineAttendue(JourneyAssessmentKind)` traduit la nature en nom de table
(`diagnostic_sessions.id`, `attempts.id`…) **dans le garde seulement**, pour le message.

**Motif.** L'information existe déjà depuis **A08** — « `QUICK_DIAGNOSTIC` désigne une
`diagnostic_sessions` » — mais uniquement en **javadoc**, donc illisible à l'exécution, au moment
précis où on en a besoin. La porter dans un type ou une colonne est exactement le geste que
**D-54** range dans le chantier à venir : ce n'est pas à une passe de correction de bug de le
décider.

⚠️ **Le commentaire sur place le dit** : le jour où une colonne portera la nature de son
identifiant, ce `switch` disparaîtra — il n'aura plus à épeler ce que le schéma saura.

**Si l'arbitrage était autre** (trancher le chantier maintenant) : `JourneyAssessmentKind`
gagnerait la table en attribut d'enum, et le garde la lirait. Ce serait le bon geste **après**
l'inventaire de D-54, pas avant — l'inventaire peut conclure à une contrainte plutôt qu'à une
colonne.

# 2026-09-20 — L'ordre des blocs et le geste d'une étape verrouillée (A101 → A108)

> **Demande du propriétaire, verbatim** : « afficher expression écrite en premier ici, car il a
> des choses à faire, comme les autres n'ont que examen à faire. Et au lieu de verrouiller les
> actions, à la place du bouton faire cette action etape, mettre débloquer mon plan. Donc la
> règle d'affichage de l'ordre, si pas de diagnostic fait, alors on fait cet ordre actuel, mais
> si le diagnostic il est fait EE est en tête au premier cycle vu que c'est lui qui contient des
> choses à travailler »

⚠️ **Ceci révoque partiellement D-20**, et le motif de la révocation est mesuré : D-20 refusait
un ordre où EE passe devant au motif que « le besoin est déjà satisfait **par construction** : le
diagnostic rapide crée les lots EE et EO, qui sont donc en tête ». Cette prémisse est fausse deux
fois. Le diagnostic ne créait **aucun lot** — c'est le défaut de jointure corrigé au commit
`06012016` (**A95**). Et même corrigé, « en tête » y désignait la position dans la **file**
(`journey_step.position`), pas l'ordre des **blocs** à l'écran, qui était figé par
`TcfDomainProfileDto.ORDRE` et que la file n'influence pas.

🛑 **Ce qui n'est PAS révoqué** : le refus de la clé `ordre_blocs_cycle_initial`. L'ordre se
**dérive**, il ne se règle pas. Et **D-9 est intégralement maintenue** : `ORDRE` reste l'unique
autorité de l'ordre des épreuves.

### A101 — L'ordre d'**affichage** des blocs TCF se dérive du travail porté ; `ORDRE` n'est pas touchée

**Décidé.** `JourneyReadService.axeAffiche` place devant les blocs qui portent au moins une étape
`TRAIN_SKILL`, et conserve `TcfDomainProfileDto.ORDRE` **tel quel** à l'intérieur de chaque
groupe. C'est une **partition stable**, pas un tri : aucun comparateur, aucun poids, aucun rang
servi aux fronts.

**Motif.** Le critère énoncé par le propriétaire est « porter du travail », pas « être EE » :
coder EE en dur aurait figé un cas particulier du **premier** cycle et serait devenu faux au
deuxième. `axeAffiche` **lit** `ORDRE`, exactement comme le groupement par bloc **lit** la file
sans la réécrire (D-12). « Compléter mon profil » et `JourneyLotBuilder.ordreEpreuve` (R10 bis)
sont inchangés.

🛑 **Aucun `if (diagnosticFait)`.** « Si pas de diagnostic fait, alors l'ordre actuel » sort de la
règle elle-même : pas de diagnostic ⇒ pas de lot ⇒ aucune `TRAIN_SKILL` ⇒ retour anticipé, axe
intact. Tester « le diagnostic a-t-il eu lieu ? » aurait créé une **seconde autorité** sur cette
question. Vérifié en base par deux tests restés verts **sans retouche**
(`JourneyCycleServiceIT.leCycleDeMesurePorteQuatreExamensTousDebloques`).

**Si l'arbitrage était autre** : pour que l'ordre suive la **file** (l'ordre d'arrivée des lots),
remplacer la partition par un tri sur la position minimale des étapes du bloc. Pour que la règle
tombe, supprimer `axeAffiche` et rendre `axe()` à l'appel — une méthode, zéro trace ailleurs.

### A102 — Le critère est « ce bloc **porte** une `TRAIN_SKILL` », ouverte **ou clôturée**

**Décidé.** Le critère se lit sur l'**existence** de l'étape, jamais sur `etapesRestantes`.

**Motif.** Un candidat qui finit ses compétences ne doit pas voir son écran se réordonner sous ses
yeux. C'est le principe de la position monotone de V066 — « une renumérotation ferait bouger un
parcours que le candidat a sous les yeux » — appliqué à l'affichage : une clôture ne se réouvre
jamais et n'efface pas l'étape (D-7), donc un bloc qui a porté du travail en porte toujours.

Le test lit le parcours **des deux côtés de la clôture** et compare la liste entière des blocs,
puis montre `etapesRestantes() == 0` sur ce même bloc : l'état pédagogique a changé, **le rang
n'a pas bougé**. C'est exactement la paire qu'une implémentation en `etapesRestantes > 0` aurait
confondue.

**Si l'arbitrage était autre** (« les blocs terminés redescendent ») : le critère devient
`etapesRestantes > 0` — une ligne — et le test de stabilité s'inverse. Il faut alors assumer que
l'ordre bouge en cours de cycle.

### A103 — La règle ne s'applique **qu'au TCF**, et le choix se fait dans `JourneyReadService`

**Motif (le civique).** L'axe civique est l'ordre des thématiques (`themes.display_order`, A61) :
une donnée **éditoriale** qui dit dans quel ordre le programme s'apprend, pas une liste d'épreuves
interchangeables. La réordonner ferait varier un **sommaire de cours** selon l'avancement du
candidat.

**Motif (le placement).** Passer le module à `JourneyBlocResolver` aurait remis dans ce composant
le `if` que D-47 et A61 en ont retiré. Le résolveur reçoit toujours un axe **déjà ordonné** et ne
sait toujours pas de quel module il parle.

**Si l'arbitrage était autre** : retirer le retour anticipé `if (module == CIVIQUE)` — la suite du
code est déjà agnostique, elle travaille sur `blocCode()`. Un test civique qui indexe
`blocs().get(1)` passerait au rouge et devrait être réécrit sur le code de bloc.

### A104 — Le classement se fait sur `affichables`, la liste même dont les blocs sont bâtis

**Motif.** Un bloc ne doit jamais être classé sur une étape que son propre contenu n'affiche pas.
La différence est nulle dans le cycle en cours — `SUPERSEDED` ne concerne que le cycle
**EN_ATTENTE** — mais faire dépendre le rang d'une liste différente de celle du contenu est le
genre d'écart qui se découvre six mois plus tard.

⚠️ **L'historique n'est pas concerné** : `JourneyHistoryService.axe()` lit `ORDRE` pour son propre
compte et reste en `CO, CE, EO, EE`. Un cycle historisé n'a plus rien « à faire ».

---

### A105 — Le geste d'une étape verrouillée est le **lien de la ligne**, pas une primitive nouvelle

`JourneyRow` ⇄ `SfJourneyRow` portaient déjà `actionLabel` + `onClick`/`onTap` dans la variante
`cycle`, et ce lien est **bleu** des deux côtés. Un compte gratuit reçoit donc **le même
emplacement** que « Faire cette étape → », avec un autre mot —
`JOURNEY_STEP_UNLOCK_LINK` ⇄ `kJourneyStepUnlockLink`, déclarés **une fois par front** dans les
mots du parcours (geste A85), miroirs au caractère près.

🛑 **Le bleu satisfait A46 sans y toucher** : le seul bouton **rouge** du Plan gratuit reste
« Débloquer mon plan {objectif} », ancré sous le cycle.

**Si l'arbitrage était autre** (un bouton plein, une pastille distincte) : il faudrait une
primitive **neuve dans les deux kits** — c'est précisément ce qu'on évite quand une primitive
existante suffit.

### A106 — Le cadenas reste ; c'est son **silence** qui part

**Décidé.** L'icône n'est pas retirée : elle **code l'état**, elle est partagée par la variante
`default` du kit et par l'encart d'examen. La ligne se lit désormais « 🔒 · Débloquer mon plan → ».

**Motif.** Le propriétaire demandait un geste là où il n'y en avait pas, pas la disparition du
repère d'état. Et retirer l'icône dans la seule variante `cycle` demanderait une prop de plus
**aux deux kits**, pour perdre un repère sur une ligne qui n'a plus de badge.

### A107 — Le geste s'arrête aux étapes d'**entraînement**

**Décidé.** L'encart d'examen garde sa phrase servie et **reste sans bouton**.

**Motif.** Sur une étape `TRAIN_SKILL`, `locked` est **toujours commercial**
(`SkillAccessService`), et `JourneyBlocDto.steps` ne porte que des étapes d'entraînement —
l'examen est servi à part dans `bloc.exam`. Sur un `SECTION_EXAM`, le verrou peut être
**pédagogique** (D-15 : « finis les compétences du bloc »). Proposer un pass pour lever un verrou
pédagogique serait un **mensonge commercial**.

🛑 **L'écart remonté et NON corrigé** : `journeyExamNote` écrit « Disponible dès que les
compétences sont terminées » **même quand le verrou est celui de D-17 bis** (gratuité d'examen
blanc EE/EO consommée) — donc une condition pédagogique annoncée pour un verrou commercial. Le
corriger suppose que le serveur serve la **nature** du verrou d'examen, ce qu'il ne fait pas ; le
déduire côté client est interdit. **À arbitrer, non ouvert.**

### A108 — La porte d'achat suit le parcours

`passOffre = module === "CIVIQUE" ? "CIVIQUE" : "INTEGRAL"` côté web, `openCivicOffer` vs
`showTcfLockPaywall` côté mobile — décidé **une seule fois par section**. Le `PaywallSheet` de
`PlanCycleSection` était codé en dur sur `INTEGRAL` : sans effet jusqu'ici, faux dès qu'une étape
civique porte un geste d'offre.

**Si l'arbitrage était autre** (un seul pass pour les deux cycles) : la ligne `passOffre` /
`_ouvrirOffre` est le seul endroit à changer.

#### ⚠️ Un écart de parité trouvé en vérifiant, et corrigé dans la même passe

`useCivicUniteSerie` expose `paywall` **et** `erreur` ; le mobile lisait les deux
(`showPaywallOrError`), le **web ni l'un ni l'autre**. Un 403 sur une série d'unité civique
n'ouvrait rien et ne disait rien côté web. Les deux sont désormais branchés.

⚠️ **Ce n'est pas le motif de `DETTE-P1`** — aucun fait n'est écrit deux fois à la main ici, c'est
un côté qui a **oublié de brancher** ce que l'autre branchait. Mais c'est la même famille, et il a
été trouvé en **mesurant**, jamais par une relecture. **Le signal à surveiller** : un lanceur
partagé dont un seul front lit les états de sortie.

#### Point laissé tel quel, et nommé

`JOURNEY_LOCKED_CAPTION` (le pied de cycle en état `LOCKED`) dit « abonnement Intégral » en dur :
correct en TCF, faux pour un cycle civique s'il passait un jour en `LOCKED`. Sans effet
aujourd'hui — le cycle civique n'est rendu que sur l'écran abonné (A89) — donc **laissé tel
quel** plutôt que de créer une seconde chaîne sans lecteur.

### A109 — Le bloc déplié par défaut est le **premier servi**, plus celui qui porte `current`

**Demande du propriétaire, verbatim** : « Actuellement c'est CO qui est ouvert par défaut, fais
en sorte que le premier élément affiché soit ouvert par défaut. »

**Décidé.** `ouvert = choix ?? premier.bloc.code` — l'accordéon suit l'**ordre servi**, il ne
cherche plus le bloc de statut `EN_COURS`.

**Motif.** Le dépli suivait `status === "EN_COURS"`, ce qui était juste **tant que l'ordre était
figé**. Depuis **D-56**, les blocs porteurs de travail passent devant : le bloc courant peut donc
être en 2ᵈ position, et le candidat arrivait sur un cycle dont la **tête était repliée** et le
**milieu ouvert**. L'ordre servi dit déjà ce qui compte d'abord ; le dépli le suit, il ne le
contredit pas.

⚠️ **Sauf sur un cycle TERMINÉ** : les quatre blocs restent **repliés**, comme dans
`cycle_termine.html` — la maquette de référence de **D-22**. Il n'y a alors plus rien à faire
dedans, et c'est la carte de fin de cycle qui porte le geste. C'est la **seule** condition
ajoutée, et elle est lue sur `state`, jamais déduite d'une liste vide.

**Ce qui ne change pas** : le **choix du candidat** l'emporte toujours dès qu'il touche un
en-tête, « tout replié » compris. C'est une préférence d'affichage, et elle reste la seule chose
que l'écran décide lui-même.

**Si l'arbitrage était autre** (« le bloc courant reste le déplié ») : rétablir la recherche par
`status`, en acceptant qu'un cycle puisse s'ouvrir sur sa deuxième ligne.

# 2026-09-20 — Le badge « EN COURS » et la carte d'un compte gratuit (A110 → A114)

### A110 — Le bloc meneur se désigne dans `JourneyBlocResolver.lire`, pas dans `JourneyReadService`

`lire(...)` reçoit l'axe **déjà ordonné** (A61) **et** a déjà groupé les étapes par bloc. Décider
ailleurs aurait exigé une **seconde passe de groupement** — donc une deuxième copie de « quelle
étape appartient à quel bloc », exactement ce que D-47 a extrait.

🛑 **Le module n'est toujours pas passé au résolveur** : `meneur(...)` ne lit que `getType()` et
`estOuverte()`, et vaut pour le civique sans le savoir.

**Si l'arbitrage était autre** : calculer le code du meneur dans `JourneyReadService.axeAffiche`
(qui parcourt déjà `affichables`) et le passer en paramètre — une signature de plus, et la règle
quitte le seul endroit qui connaît à la fois l'ordre et le groupement.

### A111 — Le meneur est un `boolean` par bloc, jamais un rang servi

Aucun champ n'est ajouté à `JourneyBlocDto` : le **statut** reste le seul fait servi, et aucun
front ne classe.

### A112 — Le critère est « `TRAIN_SKILL` **ouverte** », jamais « ouverte et exécutable »

**Motif.** Lire l'exécutabilité aurait réintroduit la dépendance D-1 ⇄ D-18 qui a **produit** le
défaut : le badge d'un compte gratuit aurait de nouveau fui vers l'examen. C'est aussi ce qui rend
la règle indépendante de l'abonnement — le même cycle donne le même écran, seul le cadenas diffère.

### A113 — ⚠️ Avec PLUSIEURS blocs porteurs, le badge et `CURRENT` peuvent désigner deux blocs différents

**Le fait.** L'ordre **servi** range les porteurs entre eux selon `ORDRE` (CO, CE, EO, EE — D-56,
A101), tandis que `CURRENT` sort de l'ordre de la **file**, qui trie les lots par **écart au niveau
cible décroissant** (R10 bis, `JourneyLotBuilder.ordonner`). Dès que les écarts EE et EO diffèrent,
les deux ordres divergent — et le diagnostic rapide crée les **deux** lots, donc le cas est
atteignable **dès le cycle 1**, y compris pour un abonné.

**Arbitrage du propriétaire, 2026-09-20** : la règle livrée est conservée — **le premier bloc servi
gagne**. Figé par `unSeulBlocEstEnCoursQuandDeuxEnPortent`.

🛑 **Mais sa note va plus loin, et elle ouvre D-57** :

> « Pour moi, l'épreuve en cours doit toujours avoir sa tâche suivante à faire dans "à faire
> maintenant", il n'y a pas de raison que ça soit différent. Une épreuve en cours, c'est forcément
> une de ses étapes à faire maintenant. Une fois cette épreuve finie, validée, on passe à la
> suivante qui devient en cours avec sa tâche 1 non faite déjà à faire maintenant. »

⇒ Ce n'est **pas** le badge qui doit suivre la carte, c'est **la carte qui doit suivre le badge** :
`CURRENT` doit s'élire **dans le bloc meneur**. Voir **D-57**.

### A114 — La carte « À faire maintenant » d'un compte gratuit est celle d'un abonné ; seul le geste change

**Demande du propriétaire, verbatim** : « Faire en sorte qu'un non abonné, vois egalement le à
faire maintenant d'un abonné, seulement au lieu du bouton commencer, mettre débloquer mon plan ?
Ou un autre nom mieux adapter pour le bouton »

**Décidé.** `free` ne décide plus que le **geste**. Un compte sans accès reçoit le titre, la
pastille « Priorité n°1 », les métas, l'explication du correcteur, la progression et la mesure —
**identiques**. L'anatomie gratuite est **supprimée des deux fronts** (`_freeStepCard`,
`kPlanFreeStepLocks`, `kPlanFreeFirstStepTitle`, le `<LockList>` du Plan TCF).

⚠️ **Ceci révoque la FORME de l'arbitrage du 2026-09-12** — « un compte sans accès ne voit pas la
carte d'un abonné », « aucun geste ne part de cette carte ».

🛑 **Ce qui TIENT, et qui est garanti par UNE ligne dans la seule autorité** : « dans le plan, on
ne travaille rien si on n'est pas abonné ». `free || locked ⇒ DEBLOQUER` dans `planNowCard`
(`plan-domain.ts` ⇄ `plan_now_card.dart`), et les deux écrans ne branchent **que** sur `geste` :
les lanceurs sont attachés à la seule branche `LANCER`, inatteignable quand `free`.

🛑 **La contradiction #1 est ici SATISFAITE, pas rouverte** (D-18) : l'explication du correcteur, la
progression et les compteurs sont des **résultats mesurés**. Les taire était le défaut, pas la règle.

**Le libellé reste « Débloquer cet entraînement »** (`PLAN_NOW_CTA_LOCKED` ⇄ `kPlanNowLockedCta`) :
la carte nomme **un** exercice, pas le plan entier ; le CTA rouge ancré dit déjà « Débloquer mon
plan {objectif} » ; et le libellé **existait déjà**, donc aucune chaîne neuve n'est gelée. Bouton
**bleu** — A46 inchangé. **A25** (`INDISPONIBLE`) intacte.

#### Trois décisions d'implémentation

- **`free` ne masque plus la MESURE** : `mesureCard = free ? null : mesure` faisait qu'un compte
  gratuit dont l'étape courante est une mesure voyait une carte d'étape au lieu de la carte de
  mesure. Une mesure est un **fait mesuré**.
- **Le `<LockList>` part aussi pour un ABONNÉ verrouillé** : le web le rendait sur
  `free || actionLocked`, le mobile ne l'a **jamais** rendu. Le supprimer referme l'écart au lieu
  de l'ajouter en Dart.
- ⚠️ **La garantie structurelle mobile n'existait déjà plus** : `_free(context, ref)` recevait le
  `WidgetRef` **avant** cette passe — son commentaire « il ne prend plus de `WidgetRef` » était
  **périmé**. Un commentaire faux est remplacé par une garantie vérifiable en un `grep` sur `geste`.

#### 🛑 Deux écarts REMONTÉS et non corrigés

1. **`PlanDomainView.DomainPriorityRow`** (web, `/plan/domaine/*`) floute encore `priority.title`
   quand la priorité est verrouillée, **au nom d'une surface disparue** : son commentaire invoque
   « la MÊME liste que *Mes priorités* », supprimée par D-22 / D-50. Or le cycle nomme la même
   chaîne **en clair** depuis A105. ⚠️ **Ce n'est pas cette passe qui l'ouvre** — la contradiction
   existe déjà. Et c'est **aussi** un écart `DETTE-P1` : le `PlanDomainScreen` mobile n'a aucune
   liste de priorités. Deux issues : retirer le flou, ou retirer la section.
2. **L'Accueil** est désormais la **dernière** surface qui tait le nom d'une priorité TCF
   verrouillée, alors que le Plan la nomme en titre, en sous-titre **et** dans son cycle. Une ligne
   de chaque côté. A46 l'avait déjà relevé comme « à rouvrir ou non ». **Non décidé.**

#### Une divergence pré-existante, remontée

La ligne web « Cet entraînement fait partie du pass Intégral. Votre plan, lui, reste entier. »
(`LearningPlanView`) **n'a aucun miroir mobile**, et ne l'a jamais eu. Soit on l'ajoute à
`plan_labels.dart`, soit on la retire du web — une ligne dans les deux cas. **Non décidé.**

# 2026-09-20 — D-57, seconde moitié : `CURRENT` s'élit dans le bloc meneur (A115 → A118)

### A115 — L'extraction va dans `JourneyBlocResolver`, en `public static`

`meneurParLeTravail(axe, étapes)` est sortie de `meneur(...)`, qui la **délègue** désormais au lieu
de la recopier. C'est le seul endroit qui sait déjà grouper les étapes par bloc (D-47) ; la mettre
ailleurs aurait créé une **2ᵉ copie** de « quelle étape appartient à quel bloc ».

**Si l'arbitrage était autre** : un `JourneyMeneurResolver` dédié — une classe de plus, et A110 à
réécrire.

### A116 — 🛑 L'absence de circularité est garantie par la SIGNATURE, pas par la discipline

`meneurParLeTravail` **ne reçoit pas** `courante` : elle ne **peut pas** en dépendre. Le graphe est
un DAG — `travail → meneur → CURRENT → (seulement si meneur est null) repli du badge sur le porteur
de CURRENT` — et les deux branches sont **exclusives** : quand le meneur par le travail existe,
`meneur(...)` retourne **avant** de lire `courante`.

⚠️ C'est la garantie qu'il faut préserver telle quelle. Passer `courante` à cette fonction « pour
simplifier » refermerait la boucle, et le symptôme serait muet.

### A117 — Une étape `DIAGNOSTIC` n'est éligible que s'il n'y a **pas** de meneur

Lecture stricte de « parmi les étapes du bloc meneur, **et d'elles seules** » : une étape
`DIAGNOSTIC` n'appartient à aucun bloc (R11, **A45**).

**Inatteignable par construction**, et c'est ce qui rend la décision sûre : un cycle qui attend son
amorce ne porte **ni lot ni examen** (`attendSonAmorce`), donc aucun meneur ; et la première
évaluation qui crée des lots **clôt** l'étape de diagnostic dans la même passe.

**Si l'arbitrage était autre** : ajouter `|| step.blocCode() == null` au filtre — mais le badge
dirait alors « EE en cours » pendant que la carte dirait « passe le diagnostic ».

### A118 — `blocsAvecTravailOuvert` (D-15) n'est **pas** fusionné avec `meneurParLeTravail`

Même prédicat, **deux questions différentes** — verrouiller *chaque* examen (D-15) contre désigner
*un* bloc (D-57) — et **deux listes d'entrée** (`ouvertes` contre `affichables`). Les fusionner
aurait couplé le verrou d'examen à l'ordre d'affichage.

---

### 🛑 Deux écarts REMONTÉS, non corrigés

**1. Un compte gratuit perd une porte d'entrée gratuite.** Il ne peut plus lancer l'examen de CO/CE
depuis « À faire maintenant » : la carte nomme sa priorité EE verrouillée et ouvre l'offre. Le geste
n'a pas disparu — l'examen reste `locked = false` dans son bloc du cycle, et **deux ITs l'assertent
explicitement** — mais il **recule d'un écran**. Conséquence directe de D-57, assumée, et nommée
parce qu'elle touche ce qu'un compte sans accès peut faire gratuitement.

**2. 🛑 A26 devient partiellement caduque — même famille que le défaut qu'on vient de fermer.**
Sa jambe « exemption freemium » avait déjà disparu avec **D-18** ; il restait `elire` ⇄
`PlanFocusResolver.premiereDuParcours`, qui élisaient la même étape. **Ce n'est plus vrai** :
`premiereDuParcours` lit la **file** (`ORDER BY position`), `elire` lit le **bloc meneur**. Sur le
montage d'**A113** (deux blocs porteurs, ordres divergents), un **abonné** peut donc voir « À faire
maintenant » nommer EO pendant que la **première place du Plan** nomme EE.

⚠️ **Le correctif tiendrait en une ligne** — faire lire à `premiereDuParcours` la compétence servie
par le parcours — **mais il touche l'autorité de la première place du Plan, l'épingle
`plan_pinned_priorities` (V065) et A23**. Ça demande un arbitrage, pas une passe silencieuse.

---

### ⚠️ Une règle de méthode, née de deux occurrences

**Deux fois dans la même journée**, un agent a annoncé un total de tests surefire **inférieur** au
build réel (2 995 puis 2 998, pour 3 058 puis 3 068 réels) — en recopiant le total d'une exécution
**filtrée** au lieu de celui du build complet. Aucune des deux fois le code n'était en cause.

🛑 **Un chiffre de build se relit dans `target/*-reports/`, ou dans la ligne `Results:` d'un
`./mvnw verify` complet — jamais dans la sortie d'une exécution ciblée.** Deux occurrences : ce
n'est plus un accident.

# 2026-09-20 — Le Plan civique gratuit, et le verrou enfin SERVI (A119 → A126)

> **Demande du propriétaire, verbatim** : « pour la partie Examen civique du plan, pour un non
> abonné, il faut aussi la même chose qu'un abonné, sauf qu'il peut pas travailler dessus. comme
> ce qu'on fait actuellement sur le TCF. il voit le plan, mais il peut pas travailler dessus, il
> doit débloquer son plan. »

⚠️ **Ceci révoque A89** (« ce que D-50 arbitre, c'est le Plan civique **abonné** ; l'écran gratuit
garde ses sections ») et **ferme A84** : les deux anatomies gratuites disparaissent avec les
écrans, donc la divergence nommée entre elles n'a plus de surface où exister.

### A119 — 🛑 Le verrou des étapes civiques est SERVI (4ᵉ occurrence de `DETTE-P1`, fermée)

**Le fait, mesuré avant d'écrire** ⟦SQL⟧ : **13** étapes `TRAIN_SKILL` civiques en base, **0** avec
`skill_id`, 13 avec `official_unit_id` — l'exclusivité est verrouillée par
`chk_journey_step_train_skill`, et `poserUnite(...)` annule `skill`. Or
`JourneyReadService.estVerrouillee` sortait sur `if (skill == null) yield false` : **toutes** les
unités civiques rendaient `locked: false`, abonné ou pas.

Le verrou **existait** pourtant côté serveur — D-33, le **403** de
`CivicPlanService.demarrerSerieSurUnite`. Il n'était simplement **pas servi**. C'est mot pour mot
la 3ᵉ occurrence de `DETTE-P1` : « un front ne peut pas lire ce qu'on ne lui dit pas. »

**Décidé.** `estVerrouillee` rend `!accesCivique` pour toute `TRAIN_SKILL` d'un parcours civique.

🛑 **Le dispatch se fait sur le MODULE, jamais sur la nullité de `skill`.** Tester `skill == null`
marcherait aujourd'hui, mais dirait « je ne sais pas de quoi je parle » — et une étape TCF sans
compétence, que rien n'interdit d'écrire demain, sortirait verrouillée **par accident**.

⚠️ **L'accès est résolu UNE fois par lecture**, jamais par étape : c'est une requête d'abonnement,
et un parcours civique porte jusqu'à 16 unités.

**Ce qui n'est PAS touché** : `SECTION_EXAM` civique, dont le verrou est **pédagogique** (D-15) —
y ajouter un verrou commercial ferait dire à `journeyExamNote` une condition fausse (A107) et
proposerait un pass pour lever un verrou qui n'en relève pas. `SkillAccessService` non plus : il
ne parle que du travail de compétence TCF, lui ajouter `hasCivique` lui donnerait deux règles.

**Trois tests**, dont un non demandé et qui compte : 🛑 **le verrou civique ne déborde pas sur le
TCF** — un candidat sans pass Civique ne doit voir se fermer aucune étape d'un parcours TCF.

### A120 — L'écran civique devient UN seul écran, `free` en paramètre

`CiviquePremium` + `CiviqueGratuit` ⇒ `CiviquePlan({plan, journey, free})` ⇄ `_ecran(plan, free:)`.
Anatomie unique : `Top` → bande objectif → « À faire maintenant » → section de cycle → « À revoir
bientôt » → pied (offre pour un gratuit, « Aller plus loin » pour un abonné).

**La forme est celle d'A114, transposée** : `free || locked ⇒ DEBLOQUER`, **court-circuité avant**
le verrou servi, et les deux écrans ne branchent que sur `geste`. Les lanceurs — **un par grain**
(A87) — sont attachés à la seule branche `LANCER`, inatteignable quand `free`.

### A121 — `civicNowCard` retombe sur `plan.prochaine` quand `journey.current` est `null`

**Motif.** Forme exacte de `planNowCard`. Et **sans ce repli, la carte disparaîtrait** le jour où
le verrou est servi : `elire` saute les étapes verrouillées, donc un compte civique gratuit a
`current == null` et `state == LOCKED`. C'est-à-dire qu'elle disparaîtrait exactement sur l'écran
que le propriétaire demande à voir.

**Si l'arbitrage était autre** : supprimer le second `return` des deux côtés, et accepter la
disparition.

### A122 — `kCivicPlanLockedCta` est PROMU, pas supprimé

« Débloquer cette série » devient le libellé du geste, et gagne son miroir web. Même raisonnement
qu'A114 sur `PLAN_NOW_CTA_LOCKED` : la carte nomme **une** série, pas le plan entier — et les
lignes du **cycle**, elles, gardent « Débloquer mon plan → » (A105), qui parle bien du plan.

### A123 — `CivicCibleTone` est CONSERVÉ, contrairement à ce qu'A84 laissait entendre

A84 le nommait parmi les trois helpers « côté Dart seulement ». Mesuré : il a **5 lecteurs hors du
Plan** (`progres_mouvement.dart`, `home_screen.dart`). 🛑 **Un symbole se supprime sur un `grep`,
jamais sur la foi d'une note de journal** — même écrite par soi.

### A124 — `civicPlanGrainNote` descend dans « À revoir bientôt »

Elle décrit le **grain du plan dérivé** ; or la seule surface qui montre encore des cibles du plan
dérivé est cette section. Elle accompagne désormais ce qu'elle décrit, sur les deux écrans et des
deux côtés — l'asymétrie d'A84 se **referme** au lieu de se déplacer.

### A125 — La carte de résultat du diagnostic quitte le Plan civique

**Motif.** C'est un **score d'entrée**, que D-50 §1 interdit sur la bande objectif et qu'A92
réserve à « Ma progression ». 🛑 **Le résultat n'est pas perdu** — il se lit sur le rapport de
diagnostic civique et sur « Où vous en êtes ». La contradiction #1 n'est pas rouverte : on retire
un **doublon**, on ne floute rien.

### A126 — 🛑 « Cette étape fait partie de l'abonnement Intégral » devient une FONCTION du parcours

`JOURNEY_LOCKED_CAPTION` ⇒ `journeyLockedCaption(module)` ⇄ son miroir Dart. La constante nommait
l'**Intégral** en dur : sans effet tant que le cycle civique n'était rendu qu'à un abonné (A89),
**faux** à l'instant où l'écran gratuit civique le rend — et `state` y passe à `LOCKED` dès A119.

⚠️ **Laissé au FRONT, pas servi**, et la règle qui tranche est **A58** : la question n'est pas
« est-ce que ça évite une copie ? » mais « **est-ce que le référentiel le nomme ?** ». Un palier
CECRL ou une mention de l'arrêté se servent ; le **nom commercial d'un pass**, non.

---

### Deux correctifs de parité trouvés en mesurant

- `use-civic-unite-serie.ts` routait vers `/examen-blanc?attempt=` — la route **publique** héritée
  de la démo — alors que le mobile jouait déjà la série dans le runner. Aligné sur `/sessions/{id}`.
- Le `PaywallSheet` de la carte de fin de cycle était figé sur `INTEGRAL` : sans effet tant que la
  fin de cycle n'existait qu'en TCF, **faux** dès qu'un cycle civique s'achève. Il suit `module`
  (A108).

### ⚠️ Ce qui reste ouvert, et qui n'est pas de cette passe

1. **`journeyExamNote`** annonce une condition **pédagogique** quel que soit le motif du verrou
   (A107). Inchangé.
2. **`PlanDomainView.DomainPriorityRow`** (web) floute encore le titre d'une priorité verrouillée
   au nom d'une surface supprimée (A114). Toujours ouvert.
3. **A26** reste partiellement caduque (A118 bis) : `premiereDuParcours` lit la file, `elire` lit
   le bloc meneur.
4. **L'Accueil** reste la dernière surface qui tait le nom d'une priorité TCF verrouillée.

# 2026-09-20 — Le diagnostic civique peuple (A127 → A131)

> Arbitrage : **D-59**. Ce qui suit est ce que personne n'avait tranché.

### A127 — 🛑 Le cycle lit le diagnostic que l'ÉVALUATION NOMME, jamais « le dernier terminé »

**C'est la décision structurante de la passe, et elle vient d'une mesure que le brief
n'anticipait pas.**

⟦SQL⟧ : pour les 6 sessions civiques de la base de dev, `civic_diagnostic_sessions.completed_at`
est **égal à la microseconde** à `attempts.finished_at` — donc recopié par la clôture paresseuse,
pas posé par un `Instant.now()` propre. Et `journey_assessment_event.processed_at` est
**postérieur** à `finished_at`.

**La séquence réelle** : `POST /attempts/{id}/finish` → le parcours ; **puis**
`POST /civic-diagnostics/{id}/result` → `COMPLETED`.

⇒ **Au moment où le cycle traite le diagnostic, la session est encore `IN_PROGRESS` en base** — et
le traitement tourne en `REQUIRES_NEW`, donc il ne verrait pas davantage un `finishedAt` non
commité. `ordrePourLeCycle`, qui filtre sur `COMPLETED`, aurait rendu **vide** : la correction
aurait supprimé les cinq « TERMINÉ » **sans poser une seule unité**. Symptôme 1 réglé, 2 et 3
intacts, et rien pour le signaler.

**Décidé.** `CivicPlanService.ordreDuDiagnostic(userId, sessionId)` — l'ordre du diagnostic
**nommé par l'évaluation**. Le statut n'est pas relu : une `JourneyEvaluation` n'existe que pour
une évaluation terminée, et le résultat se calcule sur ce qui a été posé et répondu, exactement
comme l'écran de résultat. Garde : la session doit appartenir au candidat.

**Motif de fond, pas seulement pratique** : l'évaluation **dit** de quel diagnostic elle parle
(**A08**) ; « le dernier terminé » est une **seconde définition** de la même chose, qui peut
désigner une autre session. Coût : `findById` remplace `findLatest`, **1 requête pour 1**.

**Si l'arbitrage était autre** (« le cycle lit le plan courant ») : il faudrait déplacer le
branchement dans le `/result`, donc dans `CivicDiagnosticService` — que D-29 exigence 5 protège.

### A128 — Un bloc qui porte déjà un examen ouvert n'en reçoit pas un second

Sans ça, un bloc peuplé aurait porté son « Évaluer mon niveau » (A65) **et** le checkpoint du
nouveau lot : **deux** étapes dans l'avancement du cycle pour **une** seule montrée
(`examenDuBloc`). R3 reste honorée — le bloc a bien un examen ouvert.

⚠️ L'étape existante n'est **ni rouverte ni mutée** : la rattacher au lot l'aurait placée en
position 1, **devant ses propres unités**, et `elire` en aurait fait l'étape courante.

**Si l'arbitrage était autre** (« le lot a toujours son checkpoint ») : il faudrait marquer
l'ancien `SUPERSEDED` — une clôture structurelle que D-59 n'autorise pas.

### A129 — Le filtre R11 vit dans `creerLotsCiviques`, donc vaut aussi pour l'amorce

Il y est sans effet (aucun lot n'existe encore) et **évite une seconde règle « pour le
diagnostic »**. Miroir exact de `filtrerLeDiagnostic` côté TCF.

### A130 — `attendSonAmorce` n'est PAS consulté sur le chemin civique, et c'est délibéré

Un cycle civique n'est **jamais vide** (A65) : il rendrait donc toujours `false`, et les priorités
partiraient « en attente », c'est-à-dire **nulle part** (A78). **R11 ne parle pas d'amorce mais de
blocs** — c'est elle qui décide, bloc par bloc. Motif écrit sur place.

### A131 — L'amorce et le diagnostic partagent UNE autorité

`peuplerLeCycleCivique` est appelée par `amorcerCivique` **et** par `peuplerDepuisLeDiagnostic` :
deux copies auraient fini par peupler différemment selon la porte d'entrée.

---

### ⚠️ La règle de méthode a sa TROISIÈME occurrence

Un agent a de nouveau annoncé un total surefire **inférieur** au build réel — **3 001** pour
**3 071**. Trois fois dans la journée, jamais avec le code en cause.

🛑 **Un chiffre de build se relit dans `target/*-reports/` ou dans la ligne `Results:` d'un
`./mvnw verify` complet.** À la troisième occurrence, ce n'est plus une consigne : c'est une
vérification que le relecteur fait lui-même, systématiquement.

# 2026-09-20 — L'écran de transition avant le paiement (A132 → A140)

> Demande du propriétaire : retirer « Passez du diagnostic à la progression » des deux Plans et le
> sélecteur de pass du Plan civique ; ajouter **deux écrans intermédiaires** entre « Débloquer mon
> plan » et le choix du pass ; retirer « Votre plan B2 est prêt » de l'écran de paiement ; et
> **toujours afficher les deux pass**, en rendant évident que le Civique n'ouvre pas le TCF.
> Précision de mi-parcours : « **Et ces priorités viennent du diagnostic** ».

### A132 — Un seul composant, deux modules

`PlanUnlockScreen` ⇄ `plan_unlock_screen.dart`, paramétré par le module ; seule la **matière**
diffère. Deux écrans auraient divergé au premier correctif — c'est ce que **D-50 / A86** ont
refusé pour `PlanCycleSection`.

**Aucune primitive de kit nouvelle pour le corps** : héros, liste numérotée, encart, puces et barre
ancrée existaient déjà. Deux seulement ont été ajoutées, **des deux côtés** : `SheetHead` ⇄
`SfSheetHead` (croix + œil-de-bœuf) et la variante `lead` du CTA.

### A133 — 🛑 Tout vient du DIAGNOSTIC, héros compris

Le héros (`A2 → B2`, `11/40 → 32/40`), la liste et les pastilles se lisent sur le **résultat du
diagnostic**. **Aucune lecture** du Plan, du `journey` ni de `currentPriority` sur cet écran.

**Motif.** L'écran dit de lui-même « DIAGNOSTIC TERMINÉ » et « **vos réponses** font ressortir » :
il raconte ce que le diagnostic a trouvé, pas où en est le plan aujourd'hui. Deux sources sur le
même écran finiraient par se contredire — c'est le défaut que **D-57** et **D-60** ont passé la
journée à fermer.

### A134 — Sans diagnostic terminé, l'écran ne s'affiche pas : on passe au pass

Session absente, non close, en erreur, ou close sans priorité ⇒ **on passe la main au choix du
pass**. Ni écran vide, ni liste inventée, et **jamais un achat retardé**.

⚠️ **Cas fréquent** : un candidat qui n'a fait que le diagnostic **rapide** n'a pas de résultat
4 épreuves — il ira droit au pass.

### A135 — 🛑 Le prix vient du CATALOGUE, et le 4,99 € n'existe pas

⟦SQL⟧ `plans`, `is_active` et `purchase_type = ONE_TIME` : **CIVIQUE** → 9,99 / 29,99 ;
**INTEGRAL** → 9,99 / 19,99 / 29,99. Les deux écrans affichent donc « à partir de **9,99 €** ».

⚠️ Le **4,99 €** annoncé par le propriétaire vit sur `CIVIQUE_MONTHLY` — un plan `SUBSCRIPTION`
**et** `is_active = false`, donc **jamais servi**. 🛑 **Rien à changer côté front** : c'est le
catalogue qu'il faut trancher, et le chiffre suivra. Catalogue injoignable ⇒ **pas de ligne de
prix**, jamais un montant de repli.

### A136 — 🛑 Les pastilles de ton : servies en civique, DÉRIVÉES en TCF — écart remonté

**Civique** : `CivicPrioriteTheme.etat` est **servi** et dit exactement les mots de la maquette.

🛑 **TCF** : `TcfDiagnosticPriorityDto` ne porte **aucun état pédagogique** — seulement un rang et
des niveaux. Rien n'a été inventé : l'écran réutilise `prioritePastille(rang)`, **l'autorité que
le rapport de diagnostic emploie déjà pour cette même liste**, donc « Prioritaire / À renforcer »
au lieu de « CRITIQUE / À RENFORCER / FAIBLE ».

⚠️ **Et cette dérivation classe un RANG en état pédagogique** — ce que le `CLAUDE.md` racine
interdit. Elle est **antérieure**, elle n'a été ni étendue ni dupliquée. Obtenir les mots de la
maquette demande un **champ servi**. **À arbitrer, non fait.**

### A137 — Les conditions de masquage des pass sont retirées, les trois

| # | Condition | Ce qu'elle cachait |
|---|---|---|
| 1 | compte déjà Intégral ⇒ Civique masqué | la preuve que son pass le couvre |
| 2 | `?module=INTEGRAL` ⇒ Civique masqué | le seul écran où les deux périmètres se comparent |
| 3 | mobile : ouvert depuis une fonction TCF ⇒ Civique masqué | ce que le Civique **n'ouvre pas**, précisément quand il fallait le montrer |

`?module=` reste un **ordre d'affichage** : le module visé passe devant, aucun ne disparaît.

🛑 **Le « NON INCLUS » n'existait PAS côté web** — seulement sur mobile. Ajouté, **même texte**,
rendu par les deux cartes.

### A138 — `PaywallOrigin` est supprimé des deux fronts

Son seul lecteur était l'en-tête personnalisé, que le propriétaire retire (la promesse déménage
sur l'écran de transition). ~20 sites d'appel. Le garder imposait de garder un champ que plus rien
ne lit.

### A139 — Le CTA du Plan civique passe du bleu au ROUGE

Il aligne le code sur **son propre commentaire A46** (« le seul bouton rouge de l'écran reste
*Débloquer mon plan* »), que `variant="blue"` démentait.

### A140 — Deux écarts assumés avec la maquette, et un calcul front

- **Le rail TCF reste l'échelle existante** (A2 · B1 · B2), pas les cinq crans A1 → C1 du mockup :
  une seconde échelle ferait deux positions pour le même palier.
- **L'encart « Mises en situation » est ambre**, pas rouge : le rouge reste au CTA critique.
- ⚠️ **« X points à combler » est une soustraction faite au front** (`seuil − score`), isolée dans
  une fonction, `null` si le seuil est atteint. Ce n'est pas un classement en état pédagogique,
  mais c'est un calcul — **à faire remonter serveur** si le propriétaire préfère.

---

# 2026-09-20 — Le repli servi (A141 → A144)

> Arbitrage : **D-60**.

### A141 — 🛑 `executable` et `courante` sont DEUX lectures, et c'est ce qui sauve D-18

`etat(...)` finissait par `courante == null ? LOCKED : IN_PROGRESS`. Servir un `current` verrouillé
aurait basculé **tout compte sans accès** en `IN_PROGRESS`.

⇒ `etat(...)` prend désormais l'étape **exécutable** ; `current` porte l'étape **annonçable**.
**Mesuré avant d'écrire**, et c'est la seule raison pour laquelle D-18 tient encore.

### A142 — Le repli parcourt le MÊME ensemble qu'`elire`

Le bloc meneur — ou toute la file **quand il n'y a pas de meneur** (cycle de mesure), où `elire`
parcourt déjà la file et où le badge suit `current` : aucune divergence n'y est possible.
Restreindre autrement aurait créé un **second périmètre**.

### A143 — ⚠️ Le repli peut nommer l'EXAMEN du bloc, et c'est figé par un test

Si toutes les `TRAIN_SKILL` du bloc meneur sont sans sujet publié (A17), le repli nomme le
`SECTION_EXAM` — dont le verrou est **pédagogique** (D-15, A107). La carte proposerait alors
« Débloquer » pour un verrou qu'aucun pass ne lève.

Comportement **figé par un test** plutôt que laissé muet : la règle est « la première étape ouverte
du bloc meneur », et ajouter une exclusion serait une règle nouvelle. **Cas dégradé et rare.**
*Si l'arbitrage était autre* : exclure du repli les `SECTION_EXAM` verrouillées par
`blocsAvecTravailOuvert`, et ce montage rendrait `current == null`.

### A144 — Aucun champ ajouté au DTO

Ni `currentLocked`, ni `currentIsFallback` : `locked` et `state` disent déjà tout. Un troisième
fait aurait été une **seconde autorité** sur la même question.

#### ⚠️ Un test qui protégeait autre chose que ce qu'il disait

`…LeBlocMeneurNOffreRienEtCurrentEstNull` (écrit le matin même par D-57) figeait `current == null`,
mais ce qu'il protégeait réellement était « **aucun repli sur la file** ». Il a été **remonté en
assertion explicite** (`current.bloc() == TCF_EE`, jamais l'examen de CO) au lieu d'être effacé.

🛑 **La leçon** : avant de réécrire un test rendu rouge par un changement voulu, demander ce qu'il
protège **vraiment** — ce n'est pas toujours ce qu'il assertionne.

### A145 — 🛑 **Depuis le Plan, TOUT chemin vers le paywall passe par l'écran de transition**

**Demande du propriétaire, 2026-09-20, en deux temps :**

> « Dans les étapes quand on clique sur débloquer mon plan, ça ouvre le paywall directement sans
> l'écran intermédiaire, le bouton fixe en bas est okay, mais faire la même chose pour les boutons
> dans le cycle aussi. »
>
> « De même pour à faire maintenant, il faut passer par l'écran intermédiaire pour **tout** passage
> vers le paywall depuis le plan. » — « **tcf et examen civique** »

**Le défaut.** Le CTA ancré menait à l'écran de transition ; les **lignes d'étape du cycle**, la
carte **« À faire maintenant »**, les cibles d'**« À revoir bientôt »** et le **jalon** ouvraient
le paywall **d'un coup**. Deux chemins vers le même achat, dont un qui **saute l'écran qui dit au
candidat ce qu'il achète** — ses priorités, son écart à l'objectif, le prix d'entrée.

**Décidé.** Les **six** gestes d'achat du Plan (trois par front) poussent
`/plan/debloquer?module=…`. Une seule porte, sur les deux modules.

#### ⚠️ La distinction qui décide, et qu'il ne faut pas perdre

| | Passe par l'écran de transition | Reste tel quel |
|---|---|---|
| Nature | un **geste d'achat** — le candidat demande à débloquer | un **refus** — il a essayé de lancer, le serveur a rendu **403** |
| Source | `locked` / `free` **servis**, avant tout appel | `handleStartFailure` / `showPaywallOrError` |

Router un **403** vers une page de vente transformerait un refus en tunnel d'achat, et
`handleStartFailure` est une autorité **de toute l'app**, pas du seul Plan.

#### Ce qui a été supprimé avec, et qui ne se voyait plus

Les trois états `unlockOpen` / `offreOuverte` n'étaient **plus jamais mis à `true`** : leurs
`|| …` dans le `open` du paywall étaient morts. Retirés des trois composants web, avec
`_ouvrirOffre` côté cycle mobile et **trois imports devenus morts**. 🛑 Les `PaywallSheet`
**restent** — ils servent encore les 403 —, avec une ligne qui dit désormais qu'ils ne répondent
plus qu'à ça.

**Si l'arbitrage était autre** (« le 403 aussi passe par l'écran ») : ce serait une ligne par site
d'appel, mais il faudrait accepter qu'un refus technique ouvre une page de vente.

---

## A146 — Le verrou de l'EXERCICE n'est pas celui de l'ÉTAPE (2026-09-20)

> Constat du propriétaire, à l'écran, après A145 : « côté examen civique c'est bon, on passe bien
> par l'écran intermédiaire mais **côté tcf, c'est pas bon, direct le paywall**. »

**Mesuré.** A145 avait fermé les portes qui lisent `etape.locked` / `free`. Il restait une
porte que ce test ne voit pas : **une étape servie OUVERTE peut porter un exercice FERMÉ**.
Le geste part alors dans la branche `LANCER`, atteint le lanceur partagé
(`openRecommendedExercise` / `actionDe`), qui lit `exercise.locked` **lui-même** et ouvrait le
paywall d'un coup.

**Pourquoi le civique passait et pas le TCF.** Le module civique est verrouillé **en entier**
(A119) : son geste vaut toujours `DEBLOQUER`, il n'atteint jamais le lanceur. Le TCF, lui,
ouvre la priorité n°1 à un compte gratuit — donc des étapes ouvertes, des exercices fermés, et
le seul front qui tombait dedans.

**Décidé.** Les lanceurs prennent un `onVerrou` **optionnel** — la porte de déblocage de
l'appelant. Le Plan la passe, les autres surfaces gardent le paywall direct.

| front | fichiers |
|---|---|
| mobile | `recommended_exercise_launcher.dart` (`openRecommendedExercise`), `plan_actions.dart` (`openPlanExercise`, `openPlanSeanceItem`, `startPlanSeanceItem`), `civic_serie_launcher.dart` (`startCivicSerie`) |
| web | `PlanCycleSection.tsx` (`actionDe` ne résout plus une action sur un exercice fermé, `gesteDe` lui rend son geste d'achat), `useCivicSerie.ts` (`onVerrou`) |

🛑 **La distinction d'A145 tient toujours** : `onVerrou` ne couvre qu'un `locked` **servi**,
lu avant tout appel. Un **403** reste un refus et garde son paywall.

⚠️ **Le civique était déjà correct** — la ligne `cible.locked` de `startCivicSerie` /
`useCivicSerie` n'est atteignable que si la carte a dit `LANCER` sur une cible fermée. Elle a
été alignée quand même : c'est le **même défaut**, et le laisser d'un seul côté le rouvrirait à
la première évolution du verrou civique.

**Le motif, 3ᵉ occurrence — DETTE-V1.** Trois fois dans cette session, un front a lu **un**
verrou là où il y en a **deux** (l'étape et son exercice, le module et sa cible). La vraie
correction serait que le serveur serve **un seul `locked` résolu par geste** ; en attendant,
le lanceur est l'unique endroit qui les compose.

**Si l'arbitrage était autre** (« un exercice fermé sous une étape ouverte est un bug serveur,
à corriger là-bas ») : il faudrait que `JourneyReadService` propage le verrou de l'exercice sur
l'étape — mais une étape ainsi fermée cesserait d'être `CURRENT` (D-18/D-60), et le parcours
d'un compte gratuit se figerait. C'est pourquoi la composition reste côté front.

---

## A147 — L'écran de transition TCF lisait le MAUVAIS diagnostic (2026-09-20)

> Constat du propriétaire, à l'écran : « côté tcf **aucun bouton** ne redirige vers l'écran
> intermédiaire, toujours direct sur le paywall, mais côté examen civique c'est bon » —
> puis « même souci, sur **web** ».

**Mesuré, pas déduit.** A146 avait bien câblé les six gestes ; ils poussaient l'écran, qui
**se retirait aussitôt**. La cause est dans l'écran lui-même : sa branche TCF lit
`tcfDiagnosticRepository.current()`, c'est-à-dire le **diagnostic 4 ÉPREUVES** — un geste à
part, que la plupart des candidats n'ont jamais fait. `null` ⇒ `_rienARaconter()` ⇒ paywall
direct + auto-retrait de la pile. Le civique passait parce que son diagnostic est
**celui que le candidat a réellement passé**.

```
 email                | diag 4 épreuves | diagnostic rapide clos
 oumoubillo@gmail.com |        0        |           1
 user@sejourfr.fr     |        1        |           1
```

C'est pourquoi le défaut était **invisible sur le compte de dev** — le seul qui ait les deux.

**Décidé — une chaîne de sources, du plus riche au plus ordinaire.**

1. diagnostic **4 épreuves** clos **avec** priorités → inchangé (un palier par épreuve, la
   tâche officielle nommée) ;
2. **sinon le PLAN** (`learningPlanProvider` / `learningPlanApi.getCached()`) : palier de
   départ face à l'objectif **déclaré**, et les priorités servies ;
3. sinon seulement → `_rienARaconter()`, **inchangé** : on ne bloque jamais un achat.

🛑 **Le repli est le chemin ORDINAIRE, pas un cas limite** — le Plan existe dès que le
diagnostic **rapide** est clos (`prep.planDisponible`). Et il ne coûte **aucun appel** : le
Plan est déjà chargé par l'écran qui a poussé celui-ci.

⚠️ **Ce qu'on montre ne change pas**, seule la **source** change — et c'est celle que le Plan
affiche déjà, donc l'écran de vente ne peut pas nommer autre chose que le Plan qu'on vend.

**Deux règles tenues au passage.**
- La pastille d'une priorité dit la **nature servie** (`PLAN_ACTION_NATURE_LABEL`), jamais un
  rang. Son ton vit **une fois par front** (`PLAN_UNLOCK_NATURE_TONE` ⇄
  `planUnlockNatureTone`) : *à acquérir* reste `muted` — rien n'a été observé, donc jamais le
  rouge de fragilité, qui est réservé à ce qui a été **vu** fragile.
- **L'objectif affiché est le DÉCLARÉ** (`cycle.objectiveLevel`), jamais `targetLevel`, qui
  est le palier que le cycle **bâtit** : l'annoncer « Objectif B2 » à un candidat sans
  démarche déclarée lui promettrait une cible qu'il n'a pas choisie. `null` ⇒ ni pastille,
  ni rail ; le palier de départ se lit quand même.

**Si l'arbitrage était autre** (« le repli montre le diagnostic RAPIDE, pas le Plan ») :
`DiagnosticResultDto.priorities` ferait des lignes équivalentes, mais il ne porte **aucun
palier** — le hero retomberait sur le Plan de toute façon, donc deux sources au lieu d'une.

---

## A148 — Deux commentaires JSX nus s'affichaient à l'écran (2026-09-20)

> Constat du propriétaire : « dans l'écran plan → TCF, **ça s'affiche bien dans l'écran**,
> pas dans les logs » — suivi du texte d'un commentaire de code.

**La cause.** Ma passe A145 a posé, dans `LearningPlanView.tsx` et `CivicPlanPanel.tsx`, un
commentaire `/* … */` **en position d'enfant JSX**. React n'y voit pas un commentaire : il y
voit du **texte**, et il le rend. Un commentaire n'est un commentaire dans un `return` JSX
que sous la forme `{/* … */}`.

**Corrigé** aux deux endroits. Un balayage de tout `app/**/*.tsx` (commentaire nu **entre**
deux nœuds JSX, hors `<style jsx>`) n'en trouve **aucun autre**.

⚠️ **Ni `tsc` ni le build ne l'attrapent** — c'est du JSX parfaitement valide. Seul l'écran
le dit, et c'est le propriétaire qui l'a vu. Vérifier à l'œil après avoir commenté du JSX.

---

## A149 — Réviser montre la reprise d'un compte SANS accès, avec son geste d'achat (2026-09-20)

> Propriétaire : « normalement dans le menu réviser, on doit avoir ici la prochaine tâche
> recommandée dans le plan ; si non abonné pareil, mais le bouton **débloquer mon plan**
> s'affiche au lieu de **commencer**. »

**Le défaut.** `reviserResumeTcf` rendait `null` dès que `carte.locked` : l'écran ouvrait
directement sur « Les 4 épreuves », sans jamais nommer ce que le candidat allait débloquer.
⚠️ Cela **révoque** « une action verrouillée n'est pas proposée en reprise, la carte
disparaît, la liste reste » (2026-09-12) — c'est la **même** règle que le Plan a reçue le
2026-09-19 (« un non-abonné voit le *à faire maintenant* d'un abonné, seul le bouton
change »), étendue au troisième écran qui porte cette carte.

**Décidé.** Les deux helpers ne filtrent plus sur `locked` : ils **portent le `geste` et le
`cta` servis** par l'autorité du Plan, et l'écran exécute.

| | avant | après |
|---|---|---|
| TCF | `planNowCard(plan, journey)`, `null` si `locked` | `planNowCard(plan, journey, free)`, `null` seulement sur `AUCUN` |
| civique | `reviserResumeCivique(prochaine)` — un libellé écrit à la main | **`civicNowCard(plan, journey, free)`**, la même autorité que le Plan |

🛑 **Le geste d'achat passe par l'écran de transition** (A145), jamais par le paywall d'un
coup. 🛑 **`AUCUN` reste `null`** : on ne pose pas un bouton mort.

#### Ce que ça corrige en plus, et qui n'avait pas été demandé

Le civique de Réviser lisait **`plan.prochaine`** — la cible du plan **dérivé** — pendant que
le Plan civique lit **`journey.current`**, l'étape du **cycle**, depuis D-50 §2. Les deux
écrans annonçaient donc, au même instant, deux reprises différentes au même candidat. Réviser
lit maintenant le cycle, des deux côtés. C'est exactement le défaut que
« Réviser vient du PLAN, jamais un second chemin » existe pour empêcher — il s'était rouvert
par la bande, quand le civique est passé sur le cycle.

Corollaire : la source peut être une **unité officielle** ou une **cible**, donc Réviser
gagne le lanceur par grain qu'a déjà le Plan (`useCivicUniteSerie` ⇄ `startCivicUniteSerie`,
A87). Le pictogramme suit : le thème quand la reprise en a un, la boussole du parcours pour
une unité, qui n'en porte pas.

**Si l'arbitrage était autre** (« un compte gratuit n'a rien à reprendre, il entre par la
liste ») : il suffirait de remettre le filtre sur `geste == DEBLOQUER` dans les deux helpers
— mais l'écran redeviendrait le seul des trois à taire ce qui est à débloquer.

---

## A150 — Chaque écran d'épreuve ouvre sur ce que le CYCLE y propose (2026-09-20)

> Propriétaire : « supprime la section historique des examens pour toutes les épreuves […]
> mettre en haut une section équivalente à *recommandé par votre plan*. Mais mettre ce que le
> cycle actuel propose en premier pour CO […] donc ça aura le même impact comme si on avait
> cliqué depuis le plan CO-étape. Donc même comportement CO, CE, Structure et même expression
> orale et écrite. »

**Arbitré en cours de route — « Structure de la langue » n'a pas de carte.** Elle n'a **jamais**
de bloc dans le cycle : le backend l'exclut du Plan, du diagnostic et de l'examen blanc, parce
que ce n'est pas une 5ᵉ épreuve du TCF IRN. Le propriétaire a tranché : « t'as raison, on fait
rien pour lui, change pas l'existant ». 🛑 **Aucun `if` n'est écrit pour elle** : `planEpreuveCarte`
ne trouve pas son bloc et rend `null`, donc la carte ne s'affiche pas — la règle reste au moteur.

#### L'autorité nouvelle, et pourquoi ce n'est pas un second moteur

`planEpreuveCarte(plan, journey, blocCode, {free})` ⇄ `planEpreuveCarte(...)` (Dart).

Elle **ne décide rien** : elle choisit un **bloc** dans la file servie, y prend la première
étape encore ouverte (les étapes d'entraînement d'abord, l'examen du bloc ensuite — l'ordre de
la file, pas une règle inventée), et délègue tout le reste — `planStepAction` pour l'action,
`journeyStepTitle` / `journeyNowCta` pour les mots. **Le tap fait donc exactement ce que ferait
la même étape tapée depuis le Plan**, ce que le propriétaire demandait mot pour mot.

`null` est un cas **normal** : pas de compte, pas de bloc, bloc terminé, ou rien qui se résout.
Aucun squelette, aucun bouton mort (garde-fou A25, transposé).

#### Deux autorités concurrentes fermées au passage

L'écran EE/EO portait **déjà** une carte « Recommandé pour vous », bâtie sur
`recommandationDuPlan` — les **priorités** du Plan, pas le cycle. Deux autorités pour la même
question, donc deux réponses possibles selon l'écran ; et son geste d'achat **ouvrait le paywall
d'un coup**, sans passer par l'écran de transition (A145). Elle est **supprimée**, avec
`recommandationDuPlan`, `ExpressionRecommendation`, `exercicesReussisLabel`,
`EXPRESSION_RECOMMENDED_*` et leurs classes CSS — refonte = suppression immédiate.

#### Ce qui a été extrait, et ce qui a été retiré

| | |
|---|---|
| **Extrait** (2ᵉ surface) | `PlanRecoCard` ⇄ `plan_reco_card.dart` — la carte vivait en privé dans Réviser ; Réviser, les 2 écrans QCM et les 2 écrans d'expression la partagent |
| **Nouveau** | `PlanEpreuveReco` ⇄ `plan_epreuve_reco.dart` — autonome : il lit le Plan et le parcours **en cache**, donc aucun appel de plus |
| **Supprimé** | l'historique des examens du détail QCM (web **et** mobile), `QcmHistorySection`, `_showExamSheet` / `_resumeExam` / `_isPremium` qui ne servaient que lui |

⚠️ **`qcmExamsHistoryProvider` reste** : la page « Examens blancs » le lit toujours. C'est
l'affichage qui part de l'écran de détail, pas la donnée.

#### Un piège laissé en place, volontairement

`skill.module.css` déclare **deux fois** `.recoTitle`, avec des valeurs différentes ; c'est la
seconde qui l'emporte, et c'est elle que lit `CompetenceDetail`. Les autres règles du bloc
« Recommandé » sont parties ; celle-là **reste**, avec un commentaire qui le dit. La fusionner
changerait un écran sans rapport — c'est une passe à part.

**Si l'arbitrage était autre** (« l'écran d'épreuve garde son historique ») : il suffirait de
remettre la section, mais elle redirait ce que la page « Examens blancs » liste déjà, une
tuile plus loin.

---

## A151 — Une étape d'expression s'ouvre sur ses 5 sujets, et nomme la suivante (2026-09-20)

> Propriétaire : « depuis le plan, quand on clique sur une étape d'expression écrite ou orale,
> et même dans à faire maintenant, on doit ouvrir cette page avec les 5 sujets à travailler,
> comme ça la personne voit les sujets qu'elle travaille, et une fois fini on le redirige vers
> l'étape suivante du plan. »

### Ce que ça a révélé : deux lanceurs, deux destinations

La règle existait **déjà**, mais dans un seul des deux lanceurs. `openPlanSeanceItem` /
`startItem` — la **ligne** de séance — ouvrait la fiche scopée à l'étape ; `openPlanExercise` /
`start` — le **bouton**, donc les lignes du cycle et « À faire maintenant » — sautait au sujet.
La même compétence menait à deux écrans selon l'endroit où on la touchait, et c'était écrit
noir sur blanc dans les deux docstrings, chacune décrivant sa moitié comme voulue.

⚠️ **Révoque** « le bouton principal démarre l'entraînement, il n'ouvre pas une fiche ».

🛑 **La VÉRIFICATION garde son lancement direct** : son sujet est une tâche de production qui
ne fait pas partie des cinq — l'y envoyer laisserait le candidat sans aucun moyen de la faire.

### La fin d'étape : un bouton, pas une redirection

**Arbitré par le propriétaire** parmi trois formes. La carte « Étape terminée » reste, et son
bouton **nomme et ouvre la suivante** (« Continuer : Parler de son quotidien »).

🛑 **Le point qui décide de tout** : le serveur ne clôt une étape qu'à l'arrivée des
**évaluations**, qui sont asynchrones. Entre le 5ᵉ sujet rendu et la clôture, `journey.current`
désigne **encore celle-ci**. `journeyEtapeSuivante(journey, skillCodeCourant)` compare donc sur
`skillCode` et rend `null` tant que rien n'a bougé — la carte retombe alors sur « Revenir à mon
plan ». **On ne promet jamais une étape qui n'existe pas encore.**

C'est aussi ce qui écartait la **redirection automatique** : elle aurait arraché le candidat à
son rapport de correction, et n'aurait eu nulle part où aller dans le cas le plus fréquent.

🛑 **L'action de la suivante vient de `planStepAction`**, et part par les **mêmes lanceurs** que
le Plan : le tap fait exactement ce que ferait la même étape tapée depuis le Plan. Aucun second
chemin n'est écrit dans l'écran de compétence.

**Si l'arbitrage était autre** (« redirection automatique ») : il faudrait attendre la clôture
serveur avant de naviguer, donc un état d'attente sur un écran que le candidat est en train de
lire — c'est ce qu'on a écarté.

---

## A152 — L'Accueil annonce exactement ce qu'annonce le Plan (2026-09-20)

> Propriétaire : « synchronise toujours “à faire maintenant” plan et accueil. C'est la même
> chose. » Puis, sur les trois divergences mesurées : « les 3 points, une seule carte partout ».

**Mesuré avant d'agir.** La **donnée** était déjà partagée : les six surfaces lisent
`planNowCard` / `civicNowCard`. Ce qui divergeait, c'est ce que l'Accueil **acceptait d'en
montrer** — trois écarts, tous du même côté :

| | Plan / Réviser | Accueil (avant) |
|---|---|---|
| le drapeau d'accès | `planNowCard(plan, journey, **free**)` | `free` **jamais passé** |
| une priorité verrouillée | nommée, bouton « Débloquer cet entraînement » | **pas nommée** → « Continuez votre plan personnalisé » |
| le civique | `civicNowCard(…, journey)` — le **cycle** | `plan.prochaine` — le **plan dérivé** |

⚠️ **Révoque « une priorité verrouillée n'est jamais nommée sur l'Accueil ».** La règle
protégeait le **rideau de « Mes priorités »** — qui n'existe plus. Le Plan nomme l'étape
depuis le 2026-09-19, Réviser depuis le 20 ; l'Accueil était le dernier écran à se taire, et
il disait donc autre chose que le Plan au même instant, pour le même candidat.

🛑 **Le geste d'achat part vers l'écran de transition** (A145), des deux côtés, TCF et civique.

🛑 **La carte civique ne DÉMARRE toujours rien** : elle mène au Plan, seul porteur du lanceur
de série — un second point de départ dupliquerait la gestion du 403. Seul l'achat part d'ici.

#### Le motif, 3ᵉ occurrence — DETTE-C1

« Un écran lit le plan dérivé pendant qu'un autre lit le cycle » s'est rouvert **trois fois**
depuis D-50 : sur le Plan civique lui-même, sur Réviser (A149), sur l'Accueil (ici). La cause
est toujours la même — `CivicPlanDto.prochaine` **reste servi** et reste tentant, alors que
l'autorité est `civicNowCard`. Tant qu'il est servi, un quatrième écran le relira.
**À arbitrer** : le retirer du DTO, ou le documenter comme réservé au plan dérivé.

**Si l'arbitrage était autre** (« l'Accueil reste muet sur une priorité fermée ») : il suffirait
de remettre le filtre `nommable`, mais l'écart que le propriétaire a constaté reviendrait tel
quel.

---

## A153 — « Ma progression » et « Mon diagnostic » : deux lignes, quatre écrans (2026-09-20)

> Propriétaire : « ajoute Mon diagnostic et Ma progression aussi dans civique […] et aussi
> rendre ces 2 boutons visibles aux non abonnés au TCF et civique. »

Deux manques, tous deux notés en attente et tranchés ici.

**1. Le civique n'avait qu'une ligne.** A94 l'avait signalé sans le corriger (« une entrée de
navigation que personne n'a demandée »). Elle est demandée. 🛑 **Le diagnostic civique a sa
propre porte** (`/diagnostic-civique`) : pointer sur celle du TCF n'aurait rien raconté du
civique.

**2. Un compte sans accès ne les voyait pas.** ⚠️ **Révoque** « absentes sur un compte sans
accès, la seule action dominante de cet écran est *Débloquer mon plan* ».

Le raisonnement qui tranche : **ce sont deux CONSTATS, pas des actions.** « Ma progression »
montre ses cycles terminés, « Mon diagnostic » son résultat de départ — **rien ne s'y
travaille**, et rien n'y est verrouillé. Les en priver n'ouvrait donc aucun droit : ça
retirait au candidat la lecture de **son propre parcours**, à celui qui en a le plus besoin.
La barre « Débloquer mon plan » reste la seule **action** dominante de l'écran, et ces deux
liens n'en sont pas une.

C'est la même famille que « le Plan d'un compte sans accès est un constat » (2026-09-12) et
que la carte « À faire maintenant » servie au gratuit (2026-09-19) : **on retire un chemin de
travail, jamais une information mesurée.**

**Si l'arbitrage était autre** (« un écran gratuit ne porte qu'un seul geste ») : il suffirait
de remettre le `free ?` autour des deux rendus — mais un candidat sans accès ne pourrait plus
relire le diagnostic qu'il vient de passer.
