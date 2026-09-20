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
