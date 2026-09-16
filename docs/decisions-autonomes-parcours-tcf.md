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
