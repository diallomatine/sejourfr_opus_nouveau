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

**Pourquoi ce n'est pas fait cette nuit.** `planNowCard` est la surface la plus sensible du
dépôt : **six** sites d'appel, et la contradiction qu'elle a corrigée le 2026-09-16 (l'Accueil
annonçant une action, le Plan une autre, au même instant) est exactement ce qu'une réécriture
inachevée rouvrirait. Elle demande une passe entière, pas un quart d'heure.

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

**La supprimer pour de bon suppose un arbitrage produit** que le propriétaire n'a pas rendu :
*le Plan exige-t-il lui aussi un objectif déclaré ?* Si oui, l'épingle part le jour même.

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
