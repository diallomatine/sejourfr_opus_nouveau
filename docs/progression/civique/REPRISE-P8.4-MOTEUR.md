# Reprise — P8.4, le moteur du cycle civique

> **C'est un ÉTAT, pas un plan.** Chaque point dit ce qui est **déjà en place** et ce qui
> **manque**, avec le chemin du fichier et la ligne. La passe suivante doit démarrer sur le moteur,
> pas sur une relecture.
>
> Écrit le **2026-09-19**, contexte frais, après le commit `6e90faf7`.
> ⚠️ Les numéros de ligne sont ceux de ce commit — vérifier par `grep`, pas par `sed -n`.

## Où en est le chantier

| Phase | État |
|---|---|
| P8.0 → P8.3, P8.A | ✅ **livrées**, `verify` vert |
| **P8.4** | 🔶 **1, 2 et 2 bis faits** (`V071`, `getOrCreate` par module, l'objectif servi) — **3 à 9 restent** |
| P8.5 → P8.9, doc | ⬜ pas commencées |

**Autorité des règles** : `docs/decisions/plan-parcours-tcf.md` — **D-25 → D-50**, la règle
générale **D-48** (`PROGRAMME ≠ CORPUS`) qui se lit seule, et les dettes **DETTE-M1** / **DETTE-P1**.
🛑 **D-50 tranche les écrans** — et deux de ses points se préparent **dans cette passe** : l'objectif
servi (point 2 bis) et le fait que « À faire maintenant » lira le **cycle**, plus le plan dérivé.
**Mesure des écarts d'écran** : `docs/audits/AUDIT_plan_civique_ecran_et_moteur.md` (clos).
**Cadre fonctionnel** : `docs/progression/civique/SPEC_cycle_plan_civique.md`.

---

## Ce qui est DÉJÀ en place, et sur quoi s'appuyer

| Acquis | Où |
|---|---|
| Les **16 unités officielles** + le rattachement des 46 notions | `civic_official_units` (V068 / V115) · `CivicOfficialUnitManager` · `CivicOfficialUnit` |
| `journey.target_procedure`, `entry_score`, `exit_score` | V069 · `Journey` |
| `journey_lot.theme_id` · `journey_step.theme_id` · `journey_step.official_unit_id` | V069 · les 3 `CHECK` de forme réécrits |
| `learning_plan_observations.official_unit_id` + les 2 sources civiques | V070 · `LearningPlanSourceType.CIVIQUE_SERIE` / `CIVIQUE_EXAMEN` |
| 🛑 **L'axe du bloc, lu sans savoir de quel module on parle** | `JourneyStep.blocRef()` / `blocCode()` / `aUnBloc()` / `poserBloc(…)` · idem sur `JourneyLot` |
| 🛑 **L'unité travaillable, idem** | `JourneyStep.aUneUnite()` / `uniteLabel()` / `uniteId()` / `poserUnite(…)` |
| Le **bloc servi** `{kind, code, label}`, les 3 côtés | `JourneyBlocRefDto` ⇄ `types.ts` ⇄ `journey_models.dart` |
| La composition conforme (examen global **et** de thème) | `CivicExamCompositionService` |
| Le plan civique dérivé, **intouché et à conserver** | `service/plancivique/` — D-36 maintient « le plan civique reste dérivé » |

🛑 **Utiliser `blocRef()` / `poserBloc()` partout.** C'est ce qui a permis de traiter les
57 occurrences d'`EpreuveType` à la source. Un nouveau `getExamType()` dans le moteur réintroduit
le problème.

---

## Le reste de P8.4, dans l'ordre

### 1. ⛔ UNE MIGRATION EST NÉCESSAIRE — arrêt avant de l'écrire

**Manque** : `journey_assessment_event` refuse une évaluation civique.

```
chk_journey_assessment_exam_type  CHECK (exam_type IS NULL OR exam_type IN
                                        ('TCF_CO','TCF_CE','TCF_EO','TCF_EE'))
chk_journey_assessment_epreuve_mesuree  CHECK ((assessment_kind = 'QUICK_DIAGNOSTIC')
                                              = (exam_type IS NULL))
```

Un examen civique porte `EpreuveType.CIVIQUE` ou une thématique — les deux `CHECK` le rejettent.
⚠️ **Et l'échec serait SILENCIEUX** : `porterAuParcours` avale l'exception
(`AttemptInteractionService`, `catch (RuntimeException echec) { log.warn(...) }`). Le même piège a
déjà mordu une fois, avec `TCF_STRUCTURE` — le commentaire sur place le raconte. 🛑 2ᵉ occurrence,
donc **dette nommée** : `DETTE-M1` dans `docs/decisions/plan-parcours-tcf.md`, **à traiter dans cette
passe** — au minimum rendre l'échec détectable autrement que par l'absence de cycle.

**Forme probable**, à valider : `theme_id` sur `journey_assessment_event`, `exam_type` nullable, un
`CHECK` d'exclusivité — **exactement le patron de V069**. Plus l'adaptation de
`chk_journey_assessment_epreuve_mesuree`, qui lie aujourd'hui « pas d'épreuve » à « diagnostic
rapide » et vaudrait faux pour un examen civique.

🛑 **Prochain numéro libre : `V071`** (`00_schema/`). Contenu civique : `V299` (`200_civique/`).

### 2. `JourneyService.getOrCreate` — câblé `Module.TCF`, et son objectif est un `TargetLevel`

**En place** : rien de civique.
**Manque** :

```java
// JourneyService.getOrCreate, ~l.156-182
TargetLevel cible = TargetProcedure.niveauVise(
        user.getTargetProcedure(), user.getTargetLevel());
if (cible == null) return Optional.empty();                        // ← D-3, correct
journeyManager.find(userId, Module.TCF, JourneyStatus.EN_COURS)     // ← 🛑 en dur
journey.setTargetLevel(cible);                                     // ← 🛑 inutilisable tel quel
journey.setModule(Module.TCF);                                     // ← 🛑 en dur
```

⚠️ **CORRECTION du 2026-09-19** — la première écriture de cette note disait qu'un candidat
**purement civique** (CSP déclaré, aucun `target_level`) « sortait à sec ». **C'est faux**, et la
lecture exacte change ce que la passe moteur doit écrire :

- `TargetProcedure.niveauVise(CSP, null)` rend **`A2`**, pas `null` — c'est le **plancher** de la
  procédure (`TargetProcedure.java`, ~l.98-103). `cible == null` n'arrive donc que si le candidat
  n'a **ni** procédure **ni** niveau déclaré : c'est **D-3**, et c'est le bon comportement.
- Le vrai défaut est ailleurs : ce candidat obtient un cycle **`Module.TCF` à `A2`**, amorcé sur ses
  observations TCF — défendable en soi (déclarer CSP implique l'A2) — et **jamais** de cycle
  civique, puisque les deux `Module.TCF` sont en dur.

🛑 **Le piège réel, et il est de forme** : `chk_journey_objectif` (V069) exige **exactement un** de
`target_level` / `target_procedure`. Un cycle civique porte donc `target_procedure` et **laisse
`target_level` NULL** — la ligne `setTargetLevel(cible)` ne se réutilise pas, et l'objectif civique
ne se dérive **pas** de `niveauVise`, qui ne parle que de français.

**Décision à prendre** : `getOrCreate(userId)` devient `getOrCreate(userId, Module)`, ou deux
méthodes. ⚠️ Vérifier **tous les appelants** avant de choisir : `grep -rn "getOrCreate" src/main`.

### 2 bis. 🛑 L'**objectif servi** — à faire DANS cette passe (D-50)

**En place** : `journey.target_procedure` (V069) et `chk_journey_objectif`.
**Manque** : le contrat. ⟦CODE⟧ `JourneyDto.targetLevel` est un `TargetLevel` — **le dernier champ
typé TCF** du contrat de cycle, et un cycle civique ne peut pas s'y exprimer.

**La forme est arbitrée** (D-50) : un **objectif servi** `{ kind, code, label }`, **patron du bloc
servi** (D-47). Il ne dépend pas du moteur, seulement de V069 — d'où sa place ici.

⚠️ Il commande la **bande objectif** de l'écran, dont le texte est tranché : « Objectif :
naturalisation · **seuil 32/40** ». 🛑 **Jamais de score d'entrée** : `entry_score` existe en base et
ne s'affiche pas là — il se lirait comme un niveau acquis alors que c'est un résultat d'examen blanc.

### 3. `JourneyBlocResolver` — l'axe est un enum en dur

**En place** : le groupement par bloc, le statut dérivé, `cycleDeMesure`, et la construction du
bloc servi (déjà faite).
**Manque** : l'axe.

```java
// JourneyBlocResolver, ~l.72-84
for (EpreuveType epreuve : TcfDomainProfileDto.ORDRE) { ... }   // ← 4 valeurs TCF
```

L'axe civique est **les 5 thématiques**, dans l'ordre de `themes.display_order` — une **donnée**,
pas un enum. 🛑 `TcfDomainProfileDto.ORDRE` reste l'autorité **TCF** (D-9, D-20) : on ne la touche
pas, on ajoute un axe à côté.

**Forme suggérée** : `lire(...)` reçoit la **liste ordonnée des codes de bloc** au lieu d'itérer
sur l'enum. L'appelant (`JourneyReadService`) la fournit selon le module.

### 4. `JourneyLotBuilder` — les priorités civiques

**En place** : le patron « un lot + ses ≤ 3 priorités + son checkpoint », `maxPrioritiesPerLot: 3`
(D-20, inchangé).
**Manque** : d'où viennent les priorités civiques.

🛑 **Elles ne viennent pas d'un `SkillMasteryEngine`** — il **lève** sur une source civique
(décision de la passe précédente, pour ne pas inventer un poids). Elles viennent du **diagnostic
civique** : `CivicDiagnosticResultDto.priorites()` donne des thématiques faibles, et il faut en
dériver des **unités officielles** de ces thématiques.

⚠️ **Point non tranché** : quelles unités d'une thématique faible deviennent priorités ?

✅ **Tranché par avance sur l'ORDRE** (propriétaire, 2026-09-19) : **lire l'ordre existant** de
`CivicPrioriteScorer`. S'il ne convient pas, **le remonter** — ne pas en créer un second au motif
qu'il serait meilleur (D-36 : le cycle se superpose au plan dérivé).

🛑 **Et ce point doit fermer A60** : depuis le point 2, un cycle civique naît **vide**. C'est un
**état de transition**, pas un comportement. Ici, un cycle sans priorité devient **impossible** (la
création échoue tant qu'il n'y a rien à poser) **ou explicite** (le cycle dit qu'il attend son
amorce, comme `attendSonAmorce()` côté TCF). Une ligne muette qui a l'air d'un cycle et n'en est pas
un ne survit pas à cette passe.

### 5. L'écrivain d'observation civique — **le cœur de D-49**

**En place** : la table, les deux sources, l'index jumeau.
**Manque** : le service.

**À imiter** : `ComprehensionObservationService.record(...)` (`~l.162`), qui rend
`Set<UUID>` — les compétences réellement observées. Le pendant civique rend les **unités**
observées.

🛑 **Ce qu'il doit écrire, et rien de plus** :
- `official_unit_id` (jamais `skill_id`) · `source_type` = `CIVIQUE_SERIE` **ou** `CIVIQUE_EXAMEN` ;
- `status = SOLID` **dès que le ratio atteint `learning-plan.comprehension.solid-ratio` (0.80)**.
  🛑 **Lire ce seuil chez son autorité**, ne pas en déclarer un 9ᵉ (D-16, et le raisonnement de
  D-44 sur le partage 28/12) ;
- 🛑 **`NOT_OBSERVED` compte comme série TERMINÉE, jamais comme RÉUSSIE** — la règle existe côté
  TCF, elle se transpose telle quelle.

### 6. `etapesAuQuota` — R2 au grain de l'unité

**En place** : l'autorité unique de R2, partagée lecture/écriture (`JourneyReadService`, ~l.559),
et `seriesDepuisLaCreation` (~l.504) qui lit `status = SOLID`.
**Manque** : la même lecture **par unité officielle**. Aujourd'hui `quotaAtteint` branche sur
`skill.getSection().isComprehension()` — une étape civique n'a pas de `Skill`.

🛑 **Ne pas dupliquer la règle** : « 2 réussies **ou** 4 terminées » (D-16) reste une seule
formule. Seule la **clé de lecture** change.

### 7. Le point de branchement — un seul, et il existe déjà

**En place** : `AttemptInteractionService.porterAuParcours(attempt, competences)`, appelé par
`recordProgression` après l'écriture des observations.
**Manque** : le civique n'y passe **pas**.

```java
boolean epreuveDuTcfIrn = TcfDomaine.section(attempt.getEpreuve()) != null;  // false pour CIVIQUE
if (attempt.getType() == MOCK_EXAM && epreuveDuTcfIrn) { ... }
else if (!competences.isEmpty()) { ... }   // competences est VIDE pour le civique
```

⇒ **il ne se passe rien**, en silence. C'est là que tout se branche.

✅ **Bonne nouvelle : un seul point suffit côté civique.** Les 3 autres points de **D-24** sont
TCF (`sortie anticipée EE/EO`, `buildAndPersistCecrlIfReady`, et `lockProductionSubAttempts`
**exclu**) — le civique n'a ni production ni examen complet à sous-attempts. ⚠️ **À vérifier
quand même** pour l'examen de thème **et** pour l'examen global : les deux passent-ils bien par
`doFinish` ?

### 8. Les règles, qui se transposent sans réécriture

| Règle | Ce qu'il faut savoir |
|---|---|
| **R1** | un examen de thème hors plan clôt l'étape **si le bloc était débloqué**. ✅ Le thème est **déjà persisté** : `attempts.lot_theme_id` |
| **R3** | ✅ **gratuit** : `JourneyEvaluationFilter` lit déjà `CIVIQUE_SERIE → false` / `CIVIQUE_EXAMEN → true` |
| **Déblocage** | **D-15 mot pour mot** : l'examen du bloc verrouillé tant qu'une unité du bloc reste ouverte |
| **Cycle en attente** · **fin de cycle** · **historisation** | `JourneyCycleService` (232 l.) — structurel, peu couplé à l'épreuve. ⚠️ Vérifier `exit_level` → **`exit_score`** côté civique |

### 9. Ce qui NE doit PAS bouger

- 🛑 `service/plancivique/` — **D-36** : « le plan civique reste dérivé ». Le cycle **se superpose**.
- 🛑 `TcfDomainProfileDto.ORDRE` — autorité **TCF**, non configurable (D-9, D-20).
- 🛑 `CivicDiagnosticComposer` et `sejourfr.civic-diagnostic` — **D-29 exigence 5**.
- 🛑 Le filtre de mention **hors composition d'examen** — c'est **P8.2b**, pas P8.4 (D-45).
- 🛑 `SkillMasteryEngine` — il **lève** sur une source civique, et c'est voulu.

---

## Les pièges déjà payés, à ne pas repayer

1. **`NOT IN` sur collection vide** ne passe pas en JPQL. Le dépôt a l'idiome
   (`QuestionRepository.findRandomExcluding` → une méthode `default` qui dispatche).
2. **Une violation de contrainte par test** : un statement en échec **aborte** la transaction
   Postgres (`25P02`), et le second `assertThatThrownBy` échoue alors sur « transaction is
   aborted », pas sur la contrainte visée.
3. **Postgres traite les NULL comme DISTINCTS** dans un index unique. Tout index unique portant une
   colonne devenue nullable a besoin d'un **jumeau partiel** sur la colonne civique.
4. **Un `CHECK` ne peut pas agréger** (`cannot use subquery in check constraint`) ni **traverser
   vers la table parente**. D'où la forme `(A IS NOT NULL) <> (B IS NOT NULL)`.
5. **`porterAuParcours` avale ses exceptions** : une contrainte oubliée échoue **en silence**.
   Vérifier en base, pas au vert des tests. 🛑 C'est **`DETTE-M1`** (`docs/decisions/plan-parcours-tcf.md`),
   nommée parce que c'est la 2ᵉ occurrence — **à traiter dans cette passe moteur**.
6. **Les tests du plan civique supposent un corpus non tagué** : `remettreLeCorpusANonTague()`
   existe dans `CivicPlanServiceIT` et `CivicPlanNotionParcoursIT`.
7. 🛑 **Aucune fixture ne sait construire un cycle civique.** `TestData.journey(...)` pose
   **toujours** un `TargetLevel` (`TestData.java` ~l.1286-1307) et `setTargetProcedure` n'y apparaît
   **jamais** — or `chk_journey_objectif` interdit les deux à la fois. Aucun test existant ne peut
   donc voir les câblages du point 2 : **la fabrique vient avant le moteur**, sinon le premier test
   civique échouera sur la contrainte et non sur la logique visée.
8. 🛑 **Une migration ne s'applique JAMAIS à la main sur la base de dev.** V068, V069 et V115 y
   avaient été passées directement : le premier démarrage du backend a échoué sur
   `42P07 relation "civic_official_units" already exists`, Flyway ne les connaissant pas. `verify`
   restait vert — Zonky part d'une base vide, donc **seul un boot** pouvait le voir. Régularisé le
   2026-09-19 (3 lignes inscrites dans `flyway_schema_history` après vérification objet par objet,
   puis V070/V296/V297/V298 appliquées par Flyway). ⚠️ **Pour V071 : écrire le fichier, puis
   démarrer l'application.** C'est la même famille que `DETTE-T1`.

---

## Le livrable de preuve attendu à la fin de P8.5

Un **parcours civique joué de bout en bout côté serveur** : amorce, blocs, examen de thème, fin de
cycle, historisation. C'est un IT, pas une capture d'écran — les écrans se jugent à l'œil, donc en
P8.7.

**Plus** la liste des décisions prises seul, à consigner à la suite de la dernière entrée de
`docs/decisions-autonomes-parcours-tcf.md`.

✅ Les **8 des deux premières lancées y sont écrites** : **A47 → A54** (le bloc servi, le label
servi, `journeyBlocMark` vide pour une thématique, `SkillMasteryEngine` qui lève, les deux sources
civiques, les index jumeaux, une violation par test, le test de S-8 qui change de sens). La passe
moteur reprend donc la numérotation à **A55**.
