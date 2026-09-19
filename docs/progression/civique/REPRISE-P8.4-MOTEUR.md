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
| **P8.4** | 🔶 **le contrat servi est fait** (`6e90faf7`), **le moteur ne l'est pas** |
| P8.5 → P8.9, doc | ⬜ pas commencées |

**Autorité des règles** : `docs/decisions/plan-parcours-tcf.md` — **D-25 → D-49**, et la règle
générale **D-48** (`PROGRAMME ≠ CORPUS`), qui se lit seule.
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
déjà mordu une fois, avec `TCF_STRUCTURE` — le commentaire sur place le raconte.

**Forme probable**, à valider : `theme_id` sur `journey_assessment_event`, `exam_type` nullable, un
`CHECK` d'exclusivité — **exactement le patron de V069**. Plus l'adaptation de
`chk_journey_assessment_epreuve_mesuree`, qui lie aujourd'hui « pas d'épreuve » à « diagnostic
rapide » et vaudrait faux pour un examen civique.

🛑 **Prochain numéro libre : `V071`** (`00_schema/`). Contenu civique : `V299` (`200_civique/`).

### 2. `JourneyService.getOrCreate` — câblé `Module.TCF`

**En place** : rien de civique.
**Manque** :

```java
// JourneyService, ~l.156-182
journeyManager.find(userId, Module.TCF, JourneyStatus.EN_COURS)   // ← en dur
journey.setModule(Module.TCF);                                     // ← en dur
TargetLevel cible = TargetProcedure.niveauVise(...);
if (cible == null) return Optional.empty();                        // ← sort à sec
```

🛑 **Le troisième point est le piège** : un candidat **purement civique** (CSP déclaré, aucun
`target_level`) n'obtient **jamais** de cycle. C'est le cas d'usage majoritaire du module.
L'objectif civique est `target_procedure`, et `chk_journey_objectif` (V069) exige **exactement un**
des deux.

**Décision à prendre** : `getOrCreate(userId)` devient `getOrCreate(userId, Module)`, ou deux
méthodes. ⚠️ Vérifier **tous les appelants** avant de choisir : `grep -rn "getOrCreate" src/main`.

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

⚠️ **Point non tranché** : quelles unités d'une thématique faible deviennent priorités, et dans
quel ordre ? Le plan dérivé a déjà un ordre (`CivicPrioriteScorer`) — **le lire** plutôt que d'en
créer un second (D-36 : le cycle se superpose).

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
   Vérifier en base, pas au vert des tests.
6. **Les tests du plan civique supposent un corpus non tagué** : `remettreLeCorpusANonTague()`
   existe dans `CivicPlanServiceIT` et `CivicPlanNotionParcoursIT`.

---

## Le livrable de preuve attendu à la fin de P8.5

Un **parcours civique joué de bout en bout côté serveur** : amorce, blocs, examen de thème, fin de
cycle, historisation. C'est un IT, pas une capture d'écran — les écrans se jugent à l'œil, donc en
P8.7.

**Plus** la liste des décisions prises seul, à consigner à la suite de **A46** dans
`docs/decisions-autonomes-parcours-tcf.md`. ⚠️ Les **8 de la passe précédente** y sont encore à
écrire : le bloc servi, le label servi, `journeyBlocMark` vide pour une thématique,
`SkillMasteryEngine` qui lève, les deux sources civiques, l'index jumeau, une violation par test,
et le test de S-8 qui change de sens.
