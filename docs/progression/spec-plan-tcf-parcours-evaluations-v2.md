# Spécification v2 — Parcours TCF piloté par les évaluations

> Périmètre : module TCF uniquement (CO, CE, EE, EO). Le module civique n'est pas concerné.
>
> Règle produit : **Évaluation → max 3 priorités par épreuve → entraînement du lot → examen → fermeture du lot → nouvelles priorités en fin de file.**
> Un examen lancé hors du Plan reste une évaluation qui fait autorité et resynchronise le lot concerné.
> La file est **persistée, calculée côté serveur, idempotente et configurable**.
>
> **Révision du 2026-09-17** — cette spec intègre les **9 arbitrages du propriétaire** pris après
> l'audit de Phase 0. Journal verbatim : `docs/decisions/plan-parcours-tcf.md`.
> Audit : `docs/progression/audit-plan-tcf-parcours-evaluations-v2.md`.

---

## 0. Mode d'exécution (brief Claude Code)

1. ✅ **Phase 0 — Audit** : fait, rendu, **validé le 2026-09-17**
   (`docs/progression/audit-plan-tcf-parcours-evaluations-v2.md`).
2. Respecter les **points STOP** : attendre une validation explicite avant de passer à la phase
   suivante.
3. Aucune valeur métier en dur : tout passe par le fichier de config (§17).
4. Aucun second moteur de scoring, de maîtrise ou d'Attempt : le parcours est une **couche
   d'orchestration**.
5. 🛑 **Aucune règle existante n'est recopiée.** Priorités, ordre de gravité, maîtrise, niveau par
   épreuve, ordre des épreuves, quota d'étape, `locked` : tout est **lu** chez son autorité
   actuelle, nommée en §0 bis. Une seconde interprétation ici serait le défaut le plus cher du
   dépôt.

---

## 0 bis. Les arbitrages du 2026-09-17, et les autorités qu'ils désignent

| # | Sujet | Décision | Où elle s'applique |
|---|---|---|---|
| **D-1** | Étape non finissable par un compte gratuit | `CURRENT` = **première étape non résolue ET exécutable**. Les étapes verrouillées restent **affichées** (cadenas, CTA paywall). La carte « À faire maintenant » = `CURRENT` ; si **aucune** étape n'est exécutable, la carte montre la **première étape verrouillée** + paywall. | R8, R16, §5, §10 |
| **D-2** | Niveau par épreuve pour l'écart au niveau cible | **Lecture Plan** : `TcfProfileService.levelProfile(userId)` (meilleur résultat par épreuve). **Pas** `NiveauActuelEpreuveResolver` (moyenne d'affichage, qui peut redescendre). | R10 bis |
| **D-3** | Niveau cible absent | **Pas de parcours sans niveau cible.** État servi `NEEDS_OBJECTIVE`, carte « **Choisir mon objectif** ». | R18, §8, §10, §16 |
| **D-4** | Deux timelines | La **timeline du parcours remplace** le « chemin vers l'objectif » dans le Plan. Le palier reste dans l'**en-tête** niveau actuel / objectif. **Suppression de l'ancien dans la même passe.** | §9, §11, §12 |
| **D-5** | `TRAIN_SKILL` en compréhension | Quota en **séries ciblées terminées**, clé de configuration **distincte**, valeur **2**. | R8, §17 |
| **D-6** | R1 en compréhension | **Seules les évaluations alimentent la file.** Les entraînements et révisions continuent d'écrire leurs observations **pour le profil**, mais ne créent **jamais** d'étape ; ils peuvent seulement **faire avancer ou terminer** une étape existante. **Même filtre pour le bootstrap R19.** | R1, R19, §7 |
| **D-7** | Périmètre de persistance | Persister **la structure** + la **date de clôture** d'une étape (écrite **une seule fois**, jamais réouverte). **Ne jamais persister l'état de maîtrise.** `CURRENT` et `locked` sont **calculés à la lecture**. | §5, §6 |
| **D-8** | Collision de vocabulaire | `journey_cycle` → **`journey_lot`**. DTO servi : **`JourneyStepDto`**. | §2, §6, §16 |
| **D-9** | Ordre des épreuves | L'ordre **existant** : `TcfDomainProfileDto.ORDRE` = **`CO, CE, EO, EE`**. | R10 bis, R12, §17 |

**Autorités réutilisées telles quelles** — aucune ne se réécrit :

| Ce dont le parcours a besoin | Autorité unique | Fichier |
|---|---|---|
| Priorités d'une évaluation | `learning_plan_observations` | `entity/LearningPlanObservation.java` |
| Ordre de gravité | `LearningPlanPriorityResolver.actionable(...)` | `service/LearningPlanPriorityResolver.java` |
| « Transfert prouvé » (`MASTERED`) | `SkillMasteryEngine.SkillMastery.transferProven()` | `service/SkillMasteryEngine.java:86` |
| Quota d'étape d'expression | `LearningPlanStep.PROMPTS_PAR_ETAPE` (5) et `Progress.completed()` | `service/LearningPlanStep.java:37` |
| Niveau par épreuve | `TcfProfileService.levelProfile` | `service/TcfProfileService.java:149` |
| Niveau cible | `TargetProcedure.niveauVise(...)` / `getRequiredTcfLevel()` | `enums/TargetProcedure.java` |
| Ordre des épreuves | `TcfDomainProfileDto.ORDRE` | `dto/TcfDomainProfileDto.java:45` |
| « Par quoi mesurer une épreuve » | `PlanDomainAssessmentResolver` + `PlanDomainAssessmentKind` | `service/PlanDomainAssessmentResolver.java:92` |
| Verrous | `SkillAccessService`, `AttemptService.enforceMockExamSlotAccess`, `ProductionAccessService` | — |

---

## 1. Objectif

Faire de l'onglet **Plan** un parcours lisible en un regard :

- ce que le candidat doit faire maintenant ;
- ce qu'il fera ensuite ;
- quand arrive un examen ;
- ce qu'il a déjà terminé.

Le parcours vise le **niveau cible** du candidat : A2 (CSP), B1 (CR), B2 (naturalisation).

---

## 2. Vocabulaire

| Terme | Définition |
|---|---|
| **Évaluation** | Résultat pouvant modifier la structure du Plan : diagnostic rapide, diagnostic complet, examen CO/CE/EE/EO isolé, examen blanc complet (via ses sous-épreuves). 🛑 **Un entraînement ou une révision n'est jamais une évaluation** (R1, D-6). |
| **Épreuve mesurée** | Épreuve ayant **au moins un résultat exploitable issu d'une épreuve complète** : examen isolé, diagnostic complet, ou sous-épreuve d'un examen blanc complet. **Le diagnostic rapide ne mesure pas une épreuve.** |
| **Priorité** | Compétence identifiée comme faible par une évaluation, avec un rang de gravité fourni par le scoring existant. |
| **Lot** | Les priorités retenues pour une épreuve lors d'une évaluation (**3 max**, configurable), **et l'examen de réévaluation qui les clôture**. ⚠️ **D-8** : ce mot remplace « cycle » partout dans cette spec et en base (`journey_lot`) — « cycle » désigne déjà le **cycle de palier CECRL** (`PlanCycleDto`, `PlanCycleState`), affiché aux candidats. |
| **Checkpoint** | L'étape `SECTION_EXAM` de réévaluation qui clôture un lot. |
| **Écart au niveau cible** | Rang du niveau cible − rang du niveau **de la lecture Plan** de l'épreuve (D-2). |
| **Étape exécutable** | Étape que le candidat peut **mener à son terme** avec son accès actuel (D-1). Voir §5 bis. |

---

## 3. Règles métier fondamentales

### R1 — Seules les évaluations modifient la structure du Plan (D-6)

| Peuvent **ajouter** des étapes | Ne peuvent **jamais** ajouter d'étapes |
|---|---|
| Diagnostic rapide | Micro-entraînement (petit sujet de compétence) |
| Diagnostic complet | Série ciblée de QCM CO/CE |
| Examen CO / CE / EE / EO | Exercice de révision |
| Sous-épreuves d'un examen blanc complet | Feedback IA d'entraînement |
| | Répétition d'une tâche |

**Ce que fait un entraînement, et c'est tout** : il continue d'**écrire ses observations** — elles
nourrissent le profil, le niveau, la maîtrise, tout le reste du produit — et il peut **faire avancer
ou terminer une étape déjà présente** dans la file (R8, §7.3). Il n'en crée jamais.

🛑 **Le filtre est explicite, parce que l'existant écrit des observations sur TOUT.**
`AttemptInteractionService.doFinish` appelle `ComprehensionObservationService.record` pour **toute**
session TCF terminée — `TRAINING`, `REVIEW`, `MOCK_EXAM`, section de diagnostic confondues. Une
série ciblée de 20 questions CO-B1 écrit donc de vraies observations `TCF_CO`. **Ce comportement ne
change pas** (arbitrage du 2026-08-21 : « en compréhension, une bonne réponse est une bonne
réponse »). C'est **la file** qui filtre, à un seul endroit :

```text
uneEvaluation(observation) :
    source_type ∈ { DIAGNOSTIC_EE, DIAGNOSTIC_EO, MOCK_EXAM_EE, MOCK_EXAM_EO }
 OU (source_type ∈ { TCF_CO, TCF_CE } ET l'attempt source est un MOCK_EXAM)
```

Autrement dit : `PRODUCTION_EE`, `PRODUCTION_EO` (entraînement libre de production),
`SKILL_TRAINING` (petits sujets) et toute observation CO/CE issue d'un attempt `TRAINING`/`REVIEW`
**n'entrent pas** dans la production de lots.

⚠️ **Conséquence assumée** : un candidat qui ne passerait **que** des séries ciblées n'aurait jamais
de file. C'est voulu — R12 lui propose alors « {Épreuve} — Évaluer mon niveau », et c'est
précisément le sens du produit : *le Plan apprend des évaluations*.

🛑 **Ce filtre vit dans UNE seule fonction**, partagée par `onAssessmentCompleted` (§7.2) et le
bootstrap (§7.1, R19). Deux copies finiraient par admettre deux ensembles de preuves différents.

### R2 — Un lot contient au maximum 3 priorités par épreuve

- Les priorités sont triées par gravité décroissante, puis par `skillCode` (ordre déterministe en
  cas d'égalité). L'ordre de gravité est **lu** chez `LearningPlanPriorityResolver.actionable(...)`
  (`PRIORITY` avant `TO_REINFORCE`, puis confiance décroissante, puis récence) — il ne se réécrit
  pas ici. `severity_rank` est le **rang dans le lot** (0, 1, 2) dérivé de cet ordre au moment de la
  création.
- Seules les `maxPrioritiesPerLot` premières sont retenues.
- **Les autres ne sont pas stockées ni mises en attente.** Si elles persistent, le prochain examen
  de l'épreuve les fera remonter.
- La stratégie de sélection est configurable (`lotSelectionStrategy`). V1 : `TOP_SEVERITY`
  uniquement.

> 🛑 **C'est un BUDGET PÉDAGOGIQUE, et c'est un choix conscient** (B-5 de l'audit, accepté le
> 2026-09-17). Le `CLAUDE.md` racine porte l'invariant inverse — « un plafond d'AFFICHAGE n'est
> jamais un budget PÉDAGOGIQUE » — né de l'incident du 2026-08-25, où un plafond de 5 actions
> **partagé entre 4 domaines** avait privé trois domaines sur quatre de toute action (10 actions
> existaient, 2 étaient servies). Ici le plafond est **par épreuve** (donc jusqu'à 12 priorités
> vivantes), il ne prive aucune épreuve, et le moteur continue de calculer **tout** : c'est la
> **file** qui borne ce qu'elle met en attente, pas l'écran qui borne ce que le moteur produit.
> Cette distinction doit être écrite dans `docs/regles/plan.md` **avec sa raison** lors de la
> Phase 2, sinon la prochaine lecture du `CLAUDE.md` la prendra pour une régression.

> **Limite connue** : avec `TOP_SEVERITY`, les mêmes compétences très faibles peuvent revenir à
> chaque lot et empêcher une 4ᵉ d'apparaître. Une stratégie de rotation pourra être ajoutée plus
> tard **sans changer le modèle** (nouvelle valeur de `lotSelectionStrategy`). Hors périmètre V1.

### R3 — Un lot est clôturé par un examen

```text
○ EO1-C3
○ EO1-C5
○ EO2-C2
◎ Examen EO — Vérifier mes progrès   (checkpoint du lot)
```

### R4 — Ajout en fin de file uniquement

Toute nouvelle étape est ajoutée **après toutes les étapes déjà planifiées**. Elle ne remplace
jamais l'étape courante, ne passe jamais devant un examen prévu, n'interrompt jamais un autre lot.

### R5 — Un seul lot ouvert par épreuve

Invariant : pour un parcours donné, **au plus un lot `OPEN` par épreuve**. Toute nouvelle évaluation
d'une épreuve ferme ou remplace le lot ouvert de cette épreuve avant d'en créer un nouveau (R7).

### R6 — Anti-blocage

Un examen est un **checkpoint**, pas une barrière. Les nouvelles priorités qu'il produit passent en
fin de file, derrière les autres épreuves déjà planifiées. Aucune épreuve ne monopolise le Plan.

### R7 — Un examen fait toujours autorité, même passé hors du Plan

Quand un examen de l'épreuve X est terminé (depuis le Plan ou ailleurs) :

| Situation du lot ouvert de X | Effet |
|---|---|
| Aucun lot ouvert | Rien à fermer. |
| Toutes les étapes `TRAIN_SKILL` du lot sont résolues | Le checkpoint est **clôturé** (`resolution = SATISFIED_BY_ASSESSMENT`), même s'il n'était pas encore `CURRENT`. Lot → `CLOSED`. |
| Des étapes `TRAIN_SKILL` du lot sont encore en attente | L'examen devient la nouvelle référence : les étapes non clôturées du lot **et son checkpoint** sont clôturées avec `resolution = SUPERSEDED` (donc rendues `OBSOLETE`, non affichées). Lot → `SUPERSEDED`. |

Dans tous les cas :

- l'étape « X — Évaluer mon niveau » éventuellement en attente est clôturée
  (`SATISFIED_BY_ASSESSMENT`) ;
- les priorités de l'examen créent un nouveau lot en fin de file (R2, R3, R4) ;
- on ne demande jamais au candidat de refaire un examen qu'il vient de passer.

### R8 — Fin d'une étape `TRAIN_SKILL` (D-5, D-7)

🛑 **Les deux familles de compétences n'ont pas le même grain d'entraînement, et la règle le dit.**
Les compétences de compréhension **n'ont ni tâche ni petit sujet** (`skills.task_code` nullable
depuis V039) : leur entraînement est une **série ciblée de 20 QCM**
(`AttemptService.startComprehensionSeries`), pas une page de 5 sujets.

| Famille | Condition | Autorité **lue** | `resolution` |
|---|---|---|---|
| EE / EO | Compétence maîtrisée | `SkillMastery.transferProven()` | `MASTERED` |
| EE / EO | Les **5 sujets de l'étape** sont traités | `LearningPlanStep.Progress.completed()` (`PROMPTS_PAR_ETAPE = 5`) | `QUOTA_REACHED` |
| CO / CE | Compétence maîtrisée | `SkillMastery.transferProven()` | `MASTERED` |
| CO / CE | **`trainSeriesQuota` séries ciblées terminées** sur cette compétence depuis la création de l'étape (**valeur : 2**) | comptage des attempts `TRAINING` CO/CE terminés rattachés à la compétence par le contenu de leurs questions | `QUOTA_REACHED` |

🛑 **Aucune nouvelle valeur pour l'expression.** Le quota d'expression **est**
`LearningPlanStep.PROMPTS_PAR_ETAPE`, et il reste là où il vit. La configuration §17 ne le
redéclare **pas** : deux copies du chiffre 5 finiraient par annoncer « 2/5 » d'un côté et exiger 6
de l'autre. Seul `trainSeriesQuota` (CO/CE) est une valeur neuve, donc configurable.

**Clôture et rendu** (D-7) :

- Une étape clôturée porte `closed_at` + `resolution`, **écrits une seule fois**. Une étape
  clôturée ne se réouvre **jamais**.
- Elle est rendue **`COMPLETED`**, ou **`SKIPPED`** (« Déjà maîtrisée » / « Déjà travaillée ») quand
  elle a été clôturée **hors de son tour** — c'est-à-dire lorsqu'une étape de position **inférieure**
  du même parcours a été clôturée **après** elle, ou ne l'est toujours pas. 🛑 `SKIPPED` est une
  **nuance de rendu dérivée à la lecture**, jamais une valeur persistée : sinon l'ordre de clôture
  vivrait en deux endroits.
- Si toutes les étapes d'un lot sont clôturées, le checkpoint devient `CURRENT` quand son tour
  arrive **et s'il est exécutable** (D-1).

On ne bloque jamais le candidat sur une compétence non maîtrisée : l'examen décidera si elle revient.

### R9 — Examen sans priorité

Si une évaluation ne détecte **aucune priorité** pour une épreuve :

- aucun lot n'est créé pour cette épreuve ;
- l'épreuve est considérée comme mesurée ;
- le libellé affiché est « **Aucune priorité détectée lors de cette évaluation** ».

Ce n'est **pas** une déclaration de maîtrise : le niveau atteint reste déterminé par le scoring
réel.

### R10 — Évaluation multi-épreuves (examen blanc complet, diagnostic complet)

- Chaque sous-épreuve est traitée comme un examen de son épreuve (R7).
- Elle satisfait toutes les étapes « Évaluer mon niveau » correspondantes.
- Elle peut produire jusqu'à 4 lots, ordonnés selon R10 bis.

⚠️ **Les EE/EO du diagnostic complet sont des productions d'EXAMEN**, pas un diagnostic : leurs
attempts sont des sous-attempts d'un parent `TCF_COMPLET`, donc `isMockExam` est vrai et leur
`source_type` vaut `MOCK_EXAM_EE` / `MOCK_EXAM_EO`. Elles **mesurent** leur épreuve. Fait de
l'existant, pas une règle à créer.

### R10 bis — Ordre des lots (règle générale) (D-2, D-9)

**Toute évaluation qui produit plusieurs lots** (diagnostic rapide, diagnostic complet, examen blanc
complet, bootstrap R19) les ajoute dans cet ordre stable :

1. écart au niveau cible **décroissant** — le niveau de l'épreuve est celui de la **lecture Plan**,
   `TcfProfileService.levelProfile(userId)` (**D-2**) ;
2. puis `examTypeOrder` en cas d'égalité, qui est **`TcfDomainProfileDto.ORDRE` = `CO, CE, EO, EE`**
   (**D-9**).

🛑 **Pourquoi la lecture Plan et pas la lecture d'affichage.** `NiveauActuelEpreuveResolver` rend la
**moyenne des 3 derniers examens qualifiants**, qui **peut redescendre** (arbitrage du 2026-09-16 :
« un niveau affiché est une estimation d'aujourd'hui, pas un trophée »). La brancher ici ferait
**réordonner la file** parce qu'un examen récent a été moins bon — sans qu'aucune priorité n'ait
bougé. L'ordre d'un parcours ne doit pas dépendre d'une moyenne glissante.

Si l'écart n'est pas calculable pour une épreuve (ex. diagnostic rapide sans niveau estimé), elle
est placée après celles dont l'écart est connu, puis ordonnée par `examTypeOrder`.

### R11 — Diagnostic rapide

- Il peut produire des priorités (R2), sur une ou plusieurs épreuves, ordonnées selon R10 bis, mais
  **ne mesure aucune épreuve**.
- Il ne remplace jamais un lot ouvert : il crée un lot uniquement pour les épreuves **sans lot
  ouvert**.
- Il n'est proposé comme étape que si **aucune évaluation exploitable n'existe**, y compris dans
  l'historique (R19).

⚠️ **R11 s'applique tel quel même après des examens** (B-13 de l'audit, arbitré le 2026-09-17) : la
page `/diagnostic` reste accessible en permanence, un candidat peut donc lancer un diagnostic rapide
alors qu'il a déjà trois examens derrière lui. Le traitement est alors **exactement** celui décrit
ci-dessus — priorités sur les épreuves sans lot ouvert, aucune mesure, aucune étape `DIAGNOSTIC`
créée. Rien de spécial n'est prévu pour ce cas parce que rien de spécial n'est nécessaire.

### R12 — Épreuves non mesurées

Après chaque évaluation, pour chaque épreuve (dans l'ordre `examTypeOrder`, **D-9**) :

```text
si l'épreuve n'est pas mesurée
et qu'aucune étape SECTION_EXAM de cette épreuve n'est ouverte :
    ajouter « {Épreuve} — Évaluer mon niveau »
```

Ces étapes sont ajoutées **après** les nouveaux lots.

🛑 **Cette règle existe déjà et ne se réécrit pas.** « Quelles épreuves ne sont pas mesurées, et par
quoi les mesurer » **est** `PlanDomainAssessmentResolver.resolve(domaines)`, servi aujourd'hui sur
`LearningPlanDto.domainesAEvaluer`. Le parcours **consomme** ce resolver :

- nature de l'action : `PlanDomainAssessmentKind` — `MODULE_MOCK_EXAM` (CO/CE) ou
  `PRODUCTION_MOCK_EXAM` (EE/EO). ⚠️ Les natures `DIAGNOSTIC` et `PRODUCTION` ont été **supprimées**
  le 2026-09-16 (« mesurer un domaine, c'est passer un EXAMEN BLANC — les quatre épreuves, sans
  exception ») : ne pas les réintroduire ;
- slot : `PlanDomainAssessmentResolver.SLOT_OFFERT = 1`, offert et rejouable à tout compte inscrit ;
- nombre de questions et durée : lus sur le format d'examen existant et `DureeEpreuve`, jamais en
  dur.

### R13 — Déduplication

- Pas deux fois la même compétence dans un même lot.
- Grâce à R5, une compétence ne peut pas être active dans deux lots de la même épreuve.
- Une compétence résolue dans un ancien lot peut revenir dans un nouveau lot : c'est une nouvelle
  occurrence légitime.

### R14 — Idempotence et ordre des événements

- Un `sourceAssessmentId` n'est **traité qu'une seule fois** (table `journey_assessment_event`).
- Une évaluation dont la date de fin est **antérieure** à la dernière évaluation déjà traitée pour
  la même épreuve est enregistrée mais **ne modifie pas** la structure pour cette épreuve (cas des
  synchronisations mobiles tardives).
- Le traitement d'un parcours est sérialisé (verrou sur la ligne `journey`).

### R15 — Calcul côté serveur uniquement

- Le serveur est la seule source de vérité de la file.
- Web et mobile lisent un instantané. En hors-ligne, le mobile affiche le dernier instantané reçu et
  ne réordonne rien localement.

### R16 — Freemium (D-1)

- Le Plan affiche **toujours** les étapes verrouillées, **à leur place dans la file**, avec un
  cadenas et un CTA qui ouvre le paywall. Le parcours n'est **jamais** modifié pour contourner le
  Premium, et une étape verrouillée ne disparaît **jamais** (contradiction #1 du dépôt, tranchée le
  2026-08-21 : « le Plan reste intégralement visible »).
- 🛑 **Une étape verrouillée ne devient pas `CURRENT`** : `CURRENT` est la première étape non
  résolue **et exécutable** (§5 bis). C'est ce qui empêche qu'un compte gratuit voie son parcours se
  figer définitivement sur une étape qu'il ne peut pas terminer.
- Si **aucune** étape n'est exécutable, `current` vaut `null` et la carte « À faire maintenant »
  montre la **première étape non résolue**, verrouillée, avec le paywall.
- L'état `locked` est **calculé à la lecture**, jamais persisté (D-7).

### R17 — Pas d'expiration temporelle en V1

Aucune priorité n'expire avec le temps. Une nouvelle évaluation remplace progressivement les
informations anciennes (R7). Une notion de fraîcheur pourra être ajoutée plus tard si l'usage le
justifie.

### R18 — Un parcours par niveau cible, et **pas de parcours sans objectif** (D-3)

- Le parcours est identifié par `(userId, targetLevel)`.
- 🛑 **Aucun parcours n'est créé tant que le niveau cible est inconnu.** L'endpoint rend
  `state = NEEDS_OBJECTIVE`, `current = null`, `steps = []`, et les fronts affichent la carte
  « **Choisir mon objectif** » qui ouvre le choix de démarche : `/parcours` (web) /
  `target_path_screen` (mobile) → `PUT /api/me/target-path`.
- **En pratique, « niveau cible inconnu » = démarche non déclarée.**
  `MeService.updateTargetProcedure` pose `target_level = procedure.getRequiredTcfLevel()` : les deux
  colonnes sont nulles ou renseignées ensemble. Le niveau visé se lit **toujours** chez
  `TargetProcedure.niveauVise(procedure, declare)` — jamais recopié.
- Si le candidat change d'objectif, il bascule vers le parcours de ce niveau. L'ancien est conservé
  tel quel.
- Si le parcours du nouveau niveau n'existe pas, il est **initialisé par le bootstrap (R19)** à
  partir des évaluations déjà passées.
- **Un changement d'objectif ne force jamais un nouveau diagnostic.**

⚠️ **Asymétrie à tester** : en **compréhension**, la compétence **est** le palier (`CO-A2`, `CO-B1`,
`CO-B2`), donc un changement B1 → B2 change littéralement l'ensemble des compétences candidates. En
**expression**, les 6 tâches existent à tous les paliers et les fragilités se transposent. Les deux
familles ne se comportent pas pareil au changement d'objectif (test §18-23).

### R19 — Bootstrap à la création d'un parcours (D-6)

S'applique à toute création de parcours : utilisateur existant avant la fonctionnalité, nouvel
utilisateur, changement de niveau cible. **Création paresseuse à la première ouverture du Plan ;
aucune migration de données** (arbitrage du 2026-09-17).

1. Charger l'historique des évaluations exploitables de l'utilisateur — **avec le filtre R1**
   (D-6) : une observation d'entraînement ou de révision n'entre pas, quelle que soit son
   ancienneté.
2. Pour chaque épreuve, retenir **une seule évaluation de référence** :
   - la plus récente évaluation qui **mesure** l'épreuve (examen isolé, diagnostic complet,
     sous-épreuve d'examen blanc) ;
   - à défaut, le plus récent diagnostic rapide ayant produit des priorités pour cette épreuve.
3. Extraire les priorités de chaque évaluation de référence **pour le niveau cible du parcours**.
   🛑 **Aucun appel LLM, aucun recalcul d'évaluation** : les observations ne dépendent pas du niveau
   cible, seule la **sélection** en dépend (`skills.target_level`,
   `PlanDomainTargetLevelResolver.parSection`, `PlanAcquisitionSelector`).
4. Exclure les compétences **déjà maîtrisées aujourd'hui** selon le moteur de maîtrise.
5. Appliquer R2 (top N), créer un lot par épreuve ayant des priorités, ordonner selon R10 bis.
6. Appliquer R12 pour les épreuves non mesurées.
7. Enregistrer **toutes** les évaluations historiques dans `journey_assessment_event` (elles ne
   seront jamais retraitées ; R14 garantit qu'aucune évaluation plus ancienne ne modifie ensuite la
   structure).
8. Seulement si **aucune** évaluation exploitable n'existe : ajouter l'étape `DIAGNOSTIC`.

**Évaluations inexploitables à écarter** (relevé par l'audit) :
`ai_evaluations.evaluabilite = NON_EVALUABLE` (V041/V042) · sessions QCM terminées sans aucune
réponse (déjà exclues par l'`EXISTS(answers)` des requêtes existantes) · observations
`NOT_OBSERVED` — 🛑 `null = inconnu, jamais mauvais`, on n'en fait **jamais** une priorité ·
attempts invités (`user_id IS NULL`) · le **parent** d'un diagnostic complet `IN_PROGRESS` (ses
sections terminées, elles, comptent).

**Requêtes d'historique existantes** — à réutiliser, pas à réécrire :
`AttemptRepository.findQcmEpreuvesPassees` (CO/CE, sous-épreuves de diagnostic complet **incluses**
depuis la révocation de l'exclusion V049 le 2026-09-16) ·
`AttemptRepository.findProductionEpreuvesPassees` (EE/EO, entraînement libre **exclu**) ·
`DiagnosticProductionAnalysisRepository` (diagnostic rapide).

Le bootstrap ne rejoue pas l'historique étape par étape : il reconstruit directement l'état à partir
des évaluations de référence. Aucune étape clôturée n'est fabriquée à partir de l'historique.

---

## 4. Types d'étapes

| Type | `purpose` | Exemple de libellé (composé par les fronts) | Lot |
|---|---|---|---|
| `DIAGNOSTIC` | — | Faire mon diagnostic rapide | aucun |
| `TRAIN_SKILL` | — | EE · Tâche 1 — Identifier clairement le destinataire | oui |
| `SECTION_EXAM` | `INITIAL_ASSESSMENT` | Compréhension orale — Évaluer mon niveau | aucun |
| `SECTION_EXAM` | `REASSESS` | Expression écrite — Vérifier mes progrès | oui (checkpoint) |

⚠️ **`TRAIN_SKILL` n'a pas le même grain selon la famille** (R8, D-5) : en expression c'est une
compétence d'une **tâche** (`task_code` non nul) travaillée par **5 petits sujets** ; en
compréhension c'est une compétence de **palier** (`task_code` nul) travaillée par **2 séries ciblées
de 20 QCM**. Les fronts doivent composer deux sous-titres différents et deux compteurs différents —
`taskCode == null` est le discriminant, et il est servi.

---

## 5. Statuts d'une étape

| Statut | Sens | Persisté ? (D-7) | Affiché dans la timeline |
|---|---|---|---|
| `UPCOMING` | À venir | **non** — dérivé (`closed_at IS NULL`) | Oui |
| `CURRENT` | À faire maintenant (**une seule par parcours**) | 🛑 **non** — dérivé à la lecture (§5 bis) | Oui, mis en avant |
| `COMPLETED` | Clôturée dans son tour | **non** — dérivé de `closed_at` + ordre de clôture | Oui |
| `SKIPPED` | Clôturée hors de son tour | **non** — nuance de rendu de `COMPLETED` (R8) | Oui, comme terminée |
| `OBSOLETE` | Remplacée par une évaluation plus récente | **non** — dérivé de `resolution = SUPERSEDED` | Non |

**Persisté, et rien d'autre** : `closed_at` (écrit **une seule fois**, jamais réouvert) et
`resolution` ∈ `MASTERED`, `QUOTA_REACHED`, `SATISFIED_BY_ASSESSMENT`, `SUPERSEDED`.

🛑 **L'état de maîtrise n'est JAMAIS persisté** (D-7). `MASTERED` sur une étape dit « cette étape a
été clôturée **parce que** le moteur avait conclu au transfert, à cette date » — c'est un fait
historique daté. Il ne fait pas autorité sur « cette compétence est-elle acquise aujourd'hui ? » :
cette question a une seule autorité, `SkillMasteryEngine`, et elle se relit.

## 5 bis. Étape exécutable, et promotion (D-1)

**`locked` d'une étape** = « cette étape ne peut pas être menée à son terme avec l'accès actuel du
candidat ». Décidé **à la lecture**, par les autorités existantes, jamais par une règle écrite ici :

| Étape | Verrouillée quand | Autorité |
|---|---|---|
| `TRAIN_SKILL` expression | le nombre de sujets **ouverts** de la compétence est inférieur au nombre de sujets de l'étape (un compte gratuit : 2 < 5 ⇒ **verrouillée**) | `SkillAccessService` (`FREE_PROMPTS_PER_SKILL = 2`) + `LearningPlanStep.PROMPTS_PAR_ETAPE` |
| `TRAIN_SKILL` compréhension | la compétence est verrouillée (gratuit : seuls `CO-A2` / `CE-A2` sont ouverts) — une série n'a pas de plafond interne | `SkillAccessService` |
| `SECTION_EXAM` CO / CE | **jamais** — slot 1 offert **et rejouable à volonté**, tirage aléatoire pour tout compte inscrit | `AttemptService.enforceMockExamSlotAccess` |
| `SECTION_EXAM` EE / EO | le quota d'examen blanc de production est consommé (gratuit : 1 offert par épreuve) | `ProductionAccessService` |
| `DIAGNOSTIC` | **jamais** | — |

**Promotion, dans cet ordre exact** (l'ordre importe : il casse une circularité) :

```text
promoteCurrent(journey):
    premiere = première étape non clôturée par position        // ignore les verrous
    acces    = SkillAccessService.resolve(userId, premiere.skillId)   // l'exemption freemium
    locked   = calculé pour chaque étape avec `acces`
    CURRENT  = première étape non clôturée dont locked == false
    si aucune : CURRENT = null   (la carte montre `premiere`, verrouillée, + paywall)
```

🛑 **Pourquoi `premiere` et pas `CURRENT` alimente `SkillAccessService`.** Le service ouvre d'office
à un compte gratuit la compétence de la **première place du Plan**, quelle que soit sa nature
(arbitrage du 2026-08-21 : « un candidat non abonné pourra travailler sa priorité 1, vu qu'elle est
visible »). Lui passer `CURRENT` serait circulaire — `CURRENT` dépend de `locked`, qui dépend de
l'accès. Et lui passer une étape déjà déverrouillée rendrait l'exemption inutile : le candidat
gratuit perdrait l'accès à sa **vraie** priorité n°1. Il reçoit donc la **première étape non
clôturée**, verrous ignorés.

⚠️ **Conséquence à lire attentivement en relecture.** Pour un compte gratuit, les étapes
`TRAIN_SKILL` d'expression sont **verrouillées** (2 sujets ouverts sur 5) tout en étant
**travaillables** (l'exemption ouvre 2 sujets sur la première). Son `CURRENT` sera donc typiquement
une étape de compréhension (série `CO-A2`) ou un checkpoint CO/CE, pendant que sa vraie priorité
n°1 d'expression reste **affichée en tête, avec son cadenas et son CTA paywall**. C'est ce que D-1
demande : le parcours avance au lieu de mourir, et la porte commerciale reste au bon endroit.

---

## 6. Modèle de données

Nouvelles tables uniquement pour l'orchestration. Aucune donnée de maîtrise, de score ou d'Attempt
n'est dupliquée. **Migration Flyway : `V066__schema_journey_tcf.sql` dans `00_schema/`** (dernier
numéro utilisé : V065 — ⚠️ `100_reference/` est à V114, les plages sont thématiques).
**DDL seulement : aucune migration de données** (création paresseuse, R19).

### `journey`

| Colonne | Type | Note |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | |
| `target_level` | varchar | `A2` / `B1` / `B2` — **jamais null** (D-3) |
| `next_position` | bigint | compteur monotone |
| `created_at`, `updated_at` | timestamptz | |

Unique : `(user_id, target_level)`.

### `journey_lot` (D-8)

| Colonne | Type | Note |
|---|---|---|
| `id` | uuid | PK |
| `journey_id` | uuid | FK |
| `exam_type` | varchar | `TCF_CO` / `TCF_CE` / `TCF_EO` / `TCF_EE` |
| `status` | varchar | `OPEN` / `CLOSED` / `SUPERSEDED` — persisté : c'est un **fait historique**, pas un dérivé |
| `source_assessment_id` | uuid | évaluation qui a créé le lot |
| `closed_by_assessment_id` | uuid | nullable |
| `created_at`, `closed_at` | timestamptz | |

Index unique partiel : `(journey_id, exam_type) WHERE status = 'OPEN'` (R5).

### `journey_step`

| Colonne | Type | Note |
|---|---|---|
| `id` | uuid | PK |
| `journey_id` | uuid | FK |
| `lot_id` | uuid | nullable (D-8) |
| `type` | varchar | `DIAGNOSTIC` / `TRAIN_SKILL` / `SECTION_EXAM` |
| `purpose` | varchar | nullable (`INITIAL_ASSESSMENT` / `REASSESS`) |
| `exam_type` | varchar | nullable pour `DIAGNOSTIC` |
| `task_code` | varchar | nullable — 🛑 **null = compétence de compréhension** (R8, §4) |
| `skill_code` | varchar | nullable |
| `severity_rank` | int | nullable, rang dans le lot |
| `source_assessment_id` | uuid | nullable |
| `closed_at` | timestamptz | nullable. 🛑 **Écrite une seule fois, jamais réouverte** (D-7) |
| `resolution` | varchar | nullable, posée avec `closed_at` |
| `resolved_by_assessment_id` | uuid | nullable |
| `position` | bigint | jamais renumérotée |
| `created_at` | timestamptz | |

Index :
- unique `(lot_id, skill_code) WHERE skill_code IS NOT NULL` (R13) ;
- `(journey_id, position)`.

🛑 **Ce qui a DISPARU du modèle par rapport à la première rédaction, et pourquoi** (D-7) :
- **`status`** : `UPCOMING` / `CURRENT` / `COMPLETED` / `SKIPPED` / `OBSOLETE` sont **tous dérivés**
  de `closed_at`, `resolution`, `lot.status` et l'ordre de clôture (§5). Persister `CURRENT` en
  créerait une seconde autorité, et `locked` ne peut de toute façon pas se figer.
- **L'index unique partiel `(journey_id) WHERE status = 'CURRENT'`** : sans colonne `status`, il
  n'existe plus. L'unicité de `CURRENT` est garantie **par construction** — la promotion rend une
  seule étape (§5 bis).
- `resolution` **reste** parce qu'une résolution est un **fait daté** que rien ne permet de
  reconstituer : `SUPERSEDED` et `SATISFIED_BY_ASSESSMENT` dépendent d'un événement, pas d'un état.

`title` et `subtitle` ne sont **pas persistés** : voir §16 — le serveur sert des **faits**, la
phrase appartient aux fronts.

### `journey_assessment_event`

| Colonne | Type | Note |
|---|---|---|
| `id` | uuid | PK |
| `journey_id` | uuid | FK |
| `source_assessment_id` | uuid | |
| `assessment_kind` | varchar | `QUICK_DIAGNOSTIC` / `FULL_DIAGNOSTIC` / `SECTION_EXAM` / `MOCK_EXAM` |
| `completed_at` | timestamptz | date de fin de l'évaluation |
| `processed_at` | timestamptz | |

Unique : `(journey_id, source_assessment_id)`.

### Ce qui est SUPPRIMÉ dans la même passe

🛑 **`plan_pinned_priorities`** (entité `PlanPinnedPriority`, son manager, son repository, et
`PlanFocusResolver.epingler`). L'épingle a été introduite le 2026-09-13 pour empêcher la première
place de sauter au milieu d'un cycle ; avec la file, **la position d'une étape EST l'épingle**. Règle
du dépôt : refonte = suppression immédiate de l'ancien, fichier + imports + routes + CTA.

⚠️ **Ne pas oublier `SkillAccessService`** : sa dépendance à `PlanFocusResolver` doit être remplacée
par la **première étape non clôturée** du parcours (§5 bis). L'oublier recadenasserait l'étape 1
d'un compte gratuit — exactement le bug corrigé le 2026-08-21.

---

## 7. Algorithmes

### 7.1 Initialisation et bootstrap (R18, R19, D-3, D-6)

```text
getOrCreateJourney(user):
    targetLevel = TargetProcedure.niveauVise(user.targetProcedure, user.targetLevel)
    si targetLevel == null : return NEEDS_OBJECTIVE          // D-3, aucun parcours créé

    journey = find(user, targetLevel)
    si journey existe : return journey

    journey = create(user, targetLevel)
    lock(journey)
    history = evaluationsExploitables(user)      // 🛑 filtre R1 (D-6), fonction PARTAGÉE avec 7.2

    si history est vide :
        append DIAGNOSTIC
        return journey

    lots = []
    pour chaque épreuve X dans examTypeOrder :                // CO, CE, EO, EE (D-9)
        ref = latestMeasuring(history, X) ?? latestQuickDiagnosticWithPriorities(history, X)
        si ref :
            p = priorities(ref, X, targetLevel)
            p = p sans les compétences maîtrisées aujourd'hui   // SkillMasteryEngine, lu
            si p non vide : lots += top(p, maxPrioritiesPerLot)

    trier lots selon R10 bis                                   // écart via TcfProfileService (D-2)
    pour chaque lot : créer lot OPEN, append TRAIN_SKILL…, append SECTION_EXAM(REASSESS)

    pour chaque X dans examTypeOrder :
        si non mesurée(X) et aucune SECTION_EXAM(X) ouverte :
            append SECTION_EXAM(X, INITIAL_ASSESSMENT)         // via PlanDomainAssessmentResolver

    enregistrer tous les éléments de history dans journey_assessment_event
    return journey
```

Le bootstrap et `onAssessmentCompleted` partagent les mêmes fonctions : `evaluationsExploitables`
(filtre R1), `top`, tri R10 bis, R12. Pas de logique dupliquée.

⚠️ `promoteCurrent()` **n'apparaît plus dans les algorithmes d'écriture** : `CURRENT` est calculé à
la lecture (§5 bis, D-7).

### 7.2 Évaluation terminée

```text
onAssessmentCompleted(journey, a):
    si a n'est pas une ÉVALUATION (filtre R1, D-6) : return    // entraînement, révision
    lock(journey)
    si event(journey, a.id) existe : return                    // R14
    enregistrer event

    // Étape diagnostic
    si étape DIAGNOSTIC non clôturée :
        clôturer (SATISFIED_BY_ASSESSMENT)

    // Fermeture / remplacement des lots (R7, R10)
    pour chaque épreuve X mesurée par a :
        si a.completedAt < lastCompletedAt(journey, X) : ignorer X   // R14
        clôturer étape « X — Évaluer mon niveau » ouverte → SATISFIED_BY_ASSESSMENT
        lot = openLot(X)
        si lot :
            si toutes ses TRAIN_SKILL sont clôturées :
                checkpoint → clôturé (SATISFIED_BY_ASSESSMENT)
                lot → CLOSED
            sinon :
                étapes non clôturées du lot (checkpoint inclus) → clôturées (SUPERSEDED)
                lot → SUPERSEDED

    // Nouveaux lots (R2, R11)
    lots = []
    pour chaque épreuve X ayant des priorités dans a :
        si a est un diagnostic rapide et openLot(X) existe : ignorer X       // R11
        si X a été ignorée pour ancienneté : ignorer X
        lots += top(priorities(X), maxPrioritiesPerLot)

    trier lots selon R10 bis

    pour chaque lot :
        lot = créer lot OPEN
        pour chaque priorité : append TRAIN_SKILL
        append SECTION_EXAM(REASSESS)

    // Épreuves non mesurées (R12)
    pour chaque X dans examTypeOrder :
        si non mesurée(X) et aucune SECTION_EXAM(X) ouverte :
            append SECTION_EXAM(X, INITIAL_ASSESSMENT)
```

**Où brancher** (B-13, arbitré : *branchement après écriture des observations*) :

| Évaluation | Point de branchement | Note |
|---|---|---|
| Examen CO/CE, section de diagnostic complet | `AttemptInteractionService.doFinish`, **après** `recordComprehension` | 🛑 la compétence CO/CE est **dérivée du contenu des questions** par `ComprehensionObservationService` : l'appelant ne la connaît pas avant. Le parcours lit donc les observations **réellement écrites**. |
| Production EE/EO (examen, diagnostic complet) | après `LearningPlanObservationService.recordProduction` | même raison |
| Diagnostic rapide | à la clôture de `DiagnosticSession` | |
| Examen blanc complet | à la finalisation du parent, une passe par sous-épreuve (R10) | |

🛑 **Best-effort, jamais bloquant, propre transaction.** Même doctrine que
`ComprehensionObservationService` (`REQUIRES_NEW`, exception avalée, log `warn`) et que
`ProductionPipelineFailureRecorder` : un bug d'orchestration du parcours ne doit **jamais** faire
échouer la correction d'un QCM, la livraison d'une évaluation payante, ni la réponse HTTP. La
lecture suivante rattrape.

### 7.3 Progression d'entraînement (R1, R8, D-5, D-6)

```text
onTrainingProgress(journey, skillCodes):      // les compétences RÉELLEMENT observées
    lock(journey)
    pour chaque skillCode :
        step = étape TRAIN_SKILL non clôturée avec ce skillCode
        si aucune : continue                              // 🛑 R1 : jamais de création
        si maîtrisée (SkillMasteryEngine, lu)  : résolution = MASTERED
        sinon si quotaAtteint(step)             : résolution = QUOTA_REACHED
        sinon : continue
        step.closed_at = now ; step.resolution = résolution
```

`quotaAtteint(step)` — la seule différence entre les deux familles (R8, D-5) :
- **expression** : `LearningPlanStep.Progress.completed()` — les 5 sujets de l'étape traités ;
- **compréhension** : au moins `trainSeriesQuota` (**2**) séries ciblées terminées sur cette
  compétence **depuis `step.created_at`**.

Aucun réordonnancement, aucun ajout, aucune réouverture.

### 7.4 Lecture

```text
readJourney(user):
    si pas de niveau cible : NEEDS_OBJECTIVE                  // D-3
    charger les étapes non OBSOLETE, par position
    calculer `locked` de chaque étape et `CURRENT`            // §5 bis, D-1
    dériver le statut de rendu de chaque étape                // §5
    filtrer selon §14
```

---

## 8. État final

Quand aucune étape n'est ouverte :

- carte « À faire maintenant » : **« Votre parcours est à jour »** ;
- si les 4 épreuves sont mesurées : **suggestion** (hors file, pas une étape) de passer un examen
  blanc complet pour confirmer le niveau global ;
- sinon : proposer l'épreuve non mesurée (cas normalement impossible grâce à R12).

**Deux états servis en plus** :
- `NEEDS_OBJECTIVE` (D-3) — carte « Choisir mon objectif », aucune étape, aucun parcours en base ;
- `LOCKED` — des étapes restent ouvertes mais **aucune n'est exécutable** (R16, D-1) : `current`
  vaut `null`, la carte montre la première étape verrouillée + paywall.

---

# ÉCRAN PLAN

## 9. Hiérarchie (D-4)

1. **En-tête** : niveau actuel / objectif. 🛑 **Le palier CECRL reste ici** — c'est la seule chose
   que le « chemin vers l'objectif » supprimé continuera de dire.
2. **À faire maintenant**.
3. **Votre parcours vers le {niveau cible}** (la timeline du parcours).
4. Autres sections existantes utiles.

## 10. Carte « À faire maintenant » (D-1, D-3)

Règle absolue : **la carte est la représentation exacte de l'étape `CURRENT`**, sans logique propre.

**`TRAIN_SKILL` expression**

```text
À faire maintenant
Identifier clairement le destinataire
Expression écrite · Tâche 1
PRIORITÉ
5 petits sujets · ~2 min chacun
Progression : 2/5
[Continuer]
```

**`TRAIN_SKILL` compréhension** (`taskCode == null`)

```text
À faire maintenant
Compréhension orale · Niveau B1
COMPRÉHENSION ORALE
PRIORITÉ
Série ciblée de 20 questions
Progression : 1 série sur 2
[Continuer]
```

**`SECTION_EXAM`**

```text
À faire maintenant
Évaluer votre compréhension orale
Compréhension orale
ÉVALUATION
{nbQuestions} questions · ~{durée} min
Cette épreuve complète votre niveau et identifie vos prochaines priorités.
[Passer l'épreuve]
```

Nombre de questions et durée : lus depuis le format d'examen existant et `DureeEpreuve`, jamais en
dur.

**`DIAGNOSTIC`**

```text
À faire maintenant
Faire votre diagnostic rapide
Quelques minutes pour identifier vos premières priorités.
[Commencer]
```

**Aucun niveau cible** (`state = NEEDS_OBJECTIVE`, D-3)

```text
À faire maintenant
Choisir mon objectif
Votre parcours dépend de la démarche que vous visez.
[Choisir ma démarche]        → /parcours (web) · target_path_screen (mobile)
```

**Aucune étape exécutable** (`state = LOCKED`, R16 / D-1) : la carte montre la **première étape non
résolue**, verrouillée, avec son badge Premium et un CTA qui ouvre le paywall. Elle ne saute pas
l'étape, elle ne la masque pas, elle ne la remplace pas par autre chose.

🛑 **SIX sites d'appel, migrés dans la même passe.** La carte a aujourd'hui une autorité unique
**côté front**, `planNowCard(plan)` — `web_sejoufr/lib/plan-domain.ts:639` ⇄
`mobile_sejourfr/lib/screens/plan/plan_now_card.dart:129` — consommée par :

| Écran | Web | Mobile |
|---|---|---|
| Plan | `LearningPlanView.tsx:505` | `plan_tcf_view.dart:292` |
| Accueil | `app/(app)/dashboard/page.tsx:549` | `home_screen.dart:328` |
| Réviser | `lib/reviser.ts:135` | `reviser_labels.dart:118` |

N'en migrer que quelques-uns rouvrirait la contradiction corrigée le 2026-09-16 : l'Accueil
annonçant une action et le Plan une autre, au même instant, pour le même candidat. `planNowCard`
devient une **projection de `current`**, pas un décideur.

## 11. Suppressions (D-4)

**À supprimer dans la même passe** — fichier + imports + routes + CTA, pas de cohabitation :

1. Le bloc **« Votre parcours — Tâche X »** et la carte listant toutes les compétences de la tâche :
   `parcoursDeLaTache` (`LearningPlanView.tsx:288` et `:395`), `plan_task_path.dart`,
   `plan_task_row.dart`.
2. Le **« chemin vers l'objectif »** (D-4), remplacé par la timeline §12 :
   - backend : `PlanCycleDto.path`, `PlanCycleResolver.chemin(...)` (l.235),
     `dto/PlanPathStepDto.java`, `enums/PlanPathStepKind.java`, `enums/PlanPathStepStatus.java` ;
   - web : `PLAN_PATH_*`, `planPathStepTitle` / `planPathStepMeta` / `planPathStepNote`
     (`lib/plan-domain.ts`), le type `PlanPathStepDto` (`lib/types.ts`), son rendu dans
     `dashboard/page.tsx` ;
   - mobile : `widgets/plan_path_section.dart`, `PlanPathStep*` dans
     `core/models/diagnostic_models.dart` et `plan_labels.dart` ;
   - tests backend concernés (`LearningPlanCycleIT`, `PlanCycleResolverTest`) : **mis à jour**, pas
     contournés.
   🛑 **`PlanCycleDto` SURVIT** : `startingLevel`, `targetLevel`, `objectiveLevel`, `state`,
   `domainsEvaluated`, `domainsExpected`, `profileComplete` alimentent l'en-tête §9 et le gate
   d'examen blanc complet. Seul `path` disparaît.
3. `plan_pinned_priorities` et `PlanFocusResolver.epingler` (§6).

## 12. Timeline « Votre parcours vers le {niveau cible} »

```text
Votre parcours vers le B2

✓ Diagnostic rapide
✓ EE · Tâche 1
  Identifier clairement le destinataire
→ EE · Tâche 2                         MAINTENANT
  Situer clairement le récit
✓ EE · Tâche 3                         DÉJÀ MAÎTRISÉE
  Développer un argument
🔒 EE · Tâche 1                        PREMIUM
  Annoncer clairement l'objet du message
◎ Expression écrite                    EXAMEN
  Vérifier mes progrès
◎ Compréhension orale                  EXAMEN
  Évaluer mon niveau
[Voir les étapes suivantes]
```

🛑 **Elle passe par le KIT, pas par du CSS d'écran.** `SejourKit.tsx` ⇄ `sejour_kit.dart`, miroirs
brique pour brique. Les primitives manquantes (rail vertical, marqueur double-cercle, badge
`EXAMEN`, cadenas d'étape) s'ajoutent **dans les deux kits dans la même passe**. Maquettes de
référence : `~/Desktop/sejourfr_ecrans`, `~/Desktop/grok_ecran`.

## 13. Rendu des statuts

| Statut / type | Rendu |
|---|---|
| `COMPLETED` | Coche verte (`#168F5B`), texte atténué |
| `SKIPPED` | Coche verte + mention « Déjà maîtrisée » / « Déjà travaillée » |
| `CURRENT` | Marqueur bleu (`#1E3A8C`), fond `#E8ECF8`, badge **MAINTENANT** |
| `UPCOMING` + `TRAIN_SKILL` | Cercle vide |
| `UPCOMING` + `SECTION_EXAM` | Double cercle + badge **EXAMEN** |
| `OBSOLETE` | Non affiché |
| Étape `locked` | Cadenas + badge Premium, **sans changer l'ordre**, CTA → paywall (R16) |

🛑 **Jamais de couleur ni de font en dur** : tokens locaux (`var(--color-*)`, `AppColors.*`,
`AppFonts.*`). Les valeurs ci-dessus nomment les tokens existants, elles ne s'écrivent pas dans le
markup.

## 14. Étapes affichées

- Les `recentCompletedVisible` dernières étapes clôturées.
- L'étape `CURRENT`.
- **Toute étape `locked` non résolue de position inférieure à `CURRENT`** — c'est elle que le
  freemium doit montrer (R16) ; elle ne disparaît jamais.
- Toutes les étapes du lot courant, **checkpoint inclus (jamais masqué)**.
- Les `upcomingVisible` étapes suivantes.
- Le reste replié derrière **« Voir les étapes suivantes »**.

## 15. Synchronisation

```text
CURRENT dans la timeline = contenu de la carte « À faire maintenant »
```

Les deux sont alimentés par la **même réponse API**, sur les **six** sites d'appel (§10). Aucune
divergence possible.

---

# API

## 16. Lecture du parcours (B-10, B-11, D-8)

`GET /api/me/plan/journey`

🛑 **Aucun query param.** Le serveur connaît le niveau visé du candidat
(`TargetProcedure.niveauVise`) ; accepter un `?targetLevel=` ouvrirait la porte à un front qui
demande un parcours qui n'est pas le sien. Le chemin suit la convention du dépôt (`/api/me/plan`,
`/api/me/progress`), pas `/api/tcf/*`.

```json
{
  "targetLevel": "B2",
  "state": "IN_PROGRESS",
  "current": {
    "id": "b2f1…",
    "type": "TRAIN_SKILL",
    "status": "CURRENT",
    "examType": "TCF_EE",
    "section": "EE",
    "taskCode": "EE1",
    "skillCode": "EE1-C3",
    "skillTitle": "Identifier clairement le destinataire",
    "lotId": "c9a0…",
    "sourceAssessmentId": "d41e…",
    "position": 4,
    "progress": { "done": 2, "quota": 5, "unit": "PROMPT" },
    "locked": false
  },
  "steps": [
    {
      "id": "7c2d…",
      "type": "SECTION_EXAM",
      "purpose": "REASSESS",
      "status": "UPCOMING",
      "examType": "TCF_EE",
      "section": "EE",
      "lotId": "c9a0…",
      "position": 7,
      "locked": true
    }
  ],
  "hiddenUpcomingCount": 3,
  "suggestion": null
}
```

- `state` : `NEEDS_OBJECTIVE` / `IN_PROGRESS` / `LOCKED` / `UP_TO_DATE` (§8).
- `suggestion` : `null` ou `{ "type": "MOCK_EXAM" }` (§8).
- `steps` : déjà filtrées selon §14 ; `GET …?expand=all` renvoie toutes les étapes non obsolètes.
- `progress.unit` : `PROMPT` (expression, 5 petits sujets) ou `SERIES` (compréhension, 2 séries) —
  **D-5**. Le front n'en déduit rien : l'unité est servie.
- DTO Java : **`JourneyStepDto`** (D-8). Miroirs à maintenir à la main :
  `web_sejoufr/lib/types.ts`, `mobile_sejourfr/lib/core/models/*.dart`.

🛑 **Le serveur sert des FAITS, la phrase appartient aux fronts** (B-11). C'est la doctrine de tout
l'existant — `PlanPathStepKind`, `PlanDomainAssessmentKind`, `PlanChangeDto`, `PreparationEtape` le
disent tous explicitement.

- **Servis** : `type`, `purpose`, `examType`, `section`, `taskCode`, `skillCode`, `skillTitle`
  (= `skills.title`, un fait éditorial du référentiel), `progress`, `locked`, `position`.
- **Composés par les fronts, dans leurs libellés miroirs** (`plan-domain.ts` ⇄ `plan_labels.dart`) :
  « Expression écrite · Tâche 1 », « Vérifier mes progrès », « Évaluer mon niveau »,
  « Déjà maîtrisée », « Choisir mon objectif ». Les servir ouvrirait une 7ᵉ copie de libellés.

---

## 17. Configuration (B-9, D-5)

Fichier versionné **`backend_sejourfr/src/main/resources/plan/tcf-journey-config-v1.json`**, chargé
et **validé au démarrage** par son propre loader, sur le modèle exact de `PlanConfigLoader` :
refus sur clé inconnue, entrée d'enum manquante, plafond ≤ 0, version discordante.
🛑 **Aucune valeur de repli en Java, aucun `?:`** : une clé absente est une erreur de démarrage.

```json
{
  "journeyConfigVersion": 1,
  "maxPrioritiesPerLot": 3,
  "lotSelectionStrategy": "TOP_SEVERITY",
  "trainSeriesQuota": 2,
  "display": {
    "recentCompletedVisible": 3,
    "upcomingVisible": 5
  }
}
```

- `lotSelectionStrategy` : seule valeur supportée en V1 = `TOP_SEVERITY`. Toute autre valeur fait
  échouer le démarrage.
- `trainSeriesQuota` : **compréhension uniquement** (D-5).
- 🛑 **`trainSkillQuota` n'existe pas dans ce fichier.** Le quota d'expression **est**
  `LearningPlanStep.PROMPTS_PAR_ETAPE`, et il reste son unique autorité (R8). Le déclarer ici
  créerait la 2ᵉ copie d'un chiffre déjà servi aux deux fronts dans `progress.quota`.
- 🛑 **`examTypeOrder` n'existe pas dans ce fichier.** L'ordre **est** `TcfDomainProfileDto.ORDRE`
  (**D-9**, `CO, CE, EO, EE`), déjà à l'écran. Un second ordre configurable ferait diverger la file
  et « Compléter mon profil ».

**Pourquoi un fichier séparé et pas une section de `plan-config-v2.json`** : `PlanConfig` porte
l'interdiction explicite de « rien pouvoir influencer du calcul de maîtrise » (arbitrage du
2026-08-26, pour que le rejeu de `progression-config` reste intact). `trainSeriesQuota` décide de la
**clôture d'une étape** : il n'a pas sa place sous cette interdiction.

---

# TESTS

## 18. Tests métier backend — obligatoires, dans la même passe

Conventions : `*Test` (unitaire, surefire) / `*IT` (intégration, failsafe, **Postgres embarqué
Zonky**, vraies migrations Flyway) — `docs/plan-tests-backend.md`. Gabarits : les 28 tests Plan
existants (`LearningPlanServiceTest`, `LearningPlanCycleIT`, `PlanActionRankerTest`, …).

| # | Cas | Attendu |
|---|---|---|
| 1 | Aucune évaluation | `CURRENT = DIAGNOSTIC`, aucune priorité inventée |
| 2 | Diagnostic rapide → 3 priorités EE | 3 `TRAIN_SKILL` EE, puis examen EE `REASSESS`, puis `INITIAL_ASSESSMENT` CO, CE, EO |
| 3 | Diagnostic rapide → 6 priorités EE | Seules les 3 plus graves sont ajoutées |
| 4 | **Entraînement détecte une nouvelle faiblesse** | **Aucune étape ajoutée**, et l'observation **est bien écrite** (le profil apprend, la file non) — **D-6** |
| 5 | Compétence `CURRENT` maîtrisée | clôturée `MASTERED`, suivante devient `CURRENT` |
| 6 | Quota atteint sans maîtrise (expression, 5 sujets) | clôturée `QUOTA_REACHED`, le parcours avance |
| 7 | Compétence non courante maîtrisée en entraînement libre | clôturée `MASTERED`, rendue `SKIPPED`, ordre inchangé |
| 8 | Examen EE du Plan → 2 priorités | Lot `CLOSED`, étapes déjà planifiées devant, nouveau lot EE en fin |
| 9 | Examen CO → priorités alors que CE/EO sont planifiés | CE/EO gardent leur position, lot CO ajouté après |
| 10 | Examen EE hors Plan, entraînements du lot terminés | Checkpoint clôturé `SATISFIED_BY_ASSESSMENT`, pas de réexamen demandé |
| 11 | Examen EE hors Plan, entraînements du lot en cours | Étapes restantes + checkpoint clôturés `SUPERSEDED` (rendus `OBSOLETE`), lot `SUPERSEDED`, nouveau lot EE en fin |
| 12 | Examen CO hors Plan alors que « CO — Évaluer mon niveau » est prévu | Étape clôturée, non redemandée |
| 13 | Examen sans priorité | Aucun lot créé, épreuve mesurée, aucun réexamen ajouté |
| 14 | Examen blanc complet → 4 lots | 4 lots ordonnés par écart au niveau cible **(lecture Plan)** puis `CO, CE, EO, EE` ; 4 `INITIAL_ASSESSMENT` satisfaites |
| 15 | Diagnostic rapide alors qu'un lot EE est ouvert | Aucune modification du lot EE |
| 16 | Même `sourceAssessmentId` reçu deux fois | Second traitement sans effet |
| 17 | Évaluation EE plus ancienne reçue après une plus récente | Enregistrée, sans effet sur EE |
| 18 | Deux traitements simultanés | Sérialisés, un seul `CURRENT`, positions uniques |
| 19 | Même compétence dans un nouveau lot | Nouvelle occurrence créée |
| 20 | Prochaine étape Premium, utilisateur gratuit | Étape **inchangée et affichée**, `locked = true` |
| 21 | Toutes les étapes clôturées, 4 épreuves mesurées | `state = UP_TO_DATE`, suggestion examen blanc |
| 22 | Changement de niveau cible | Bascule vers le parcours du nouveau niveau, l'ancien est conservé |
| 23 | Changement B1 → B2 avec examens déjà passés | Parcours B2 initialisé depuis l'historique, **pas** d'étape `DIAGNOSTIC` ; **les compétences CO/CE changent de palier, les fragilités EE/EO se transposent** (R18) |
| 24 | Utilisateur existant avec 10 examens, première ouverture du Plan | Bootstrap depuis les évaluations de référence les plus récentes, pas de diagnostic |
| 25 | Utilisateur existant sans aucune évaluation | `CURRENT = DIAGNOSTIC` |
| 26 | Bootstrap : priorité déjà maîtrisée aujourd'hui | Non ajoutée |
| 27 | Bootstrap : examen CO ancien + diagnostic rapide plus récent sur CO | L'examen CO fait référence pour CO |
| 28 | Bootstrap : aucune étape clôturée créée depuis l'historique | Timeline commence par les étapes à venir |
| 29 | Après bootstrap, une évaluation historique est rejouée | Sans effet (idempotence) |
| 30 | Diagnostic rapide → priorités EE et CO | Lots ordonnés selon R10 bis, puis `INITIAL_ASSESSMENT` des épreuves non mesurées |

**Tests ajoutés par les arbitrages du 2026-09-17** :

| # | Cas | Attendu |
|---|---|---|
| 31 | **D-6** — série ciblée CO-B1 terminée (20 QCM, `TRAINING`) sans lot CO ouvert | Observations `TCF_CO` écrites, **aucune étape créée** |
| 32 | **D-6** — même série, avec une étape `TRAIN_SKILL` CO-B1 ouverte | L'étape **avance** ; 2ᵉ série ⇒ clôturée `QUOTA_REACHED` (`trainSeriesQuota = 2`) |
| 33 | **D-6** — bootstrap d'un candidat n'ayant **que** des entraînements | Aucun lot, `CURRENT = DIAGNOSTIC` |
| 34 | **D-1** — compte gratuit, première étape `TRAIN_SKILL` EE (2 sujets ouverts sur 5) | Étape `locked = true`, **affichée en tête** ; `CURRENT` = première étape exécutable suivante |
| 35 | **D-1** — compte gratuit dont **aucune** étape n'est exécutable | `state = LOCKED`, `current = null`, la carte montre la 1ʳᵉ étape verrouillée |
| 36 | **D-1** — la compétence de la 1ʳᵉ étape non clôturée est ouverte d'office à un compte gratuit | `SkillAccessService` reçoit bien cette compétence (et non `CURRENT`) |
| 37 | **D-1** — abonnement souscrit | `CURRENT` redevient la 1ʳᵉ étape non clôturée, sans aucune écriture en base |
| 38 | **D-2** — moyenne d'affichage qui redescend après un mauvais examen | L'ordre des lots **ne bouge pas** |
| 39 | **D-3** — aucune démarche déclarée | `state = NEEDS_OBJECTIVE`, **aucune ligne `journey` créée** |
| 40 | **D-3** — démarche déclarée ensuite | Parcours créé et bootstrappé, pas de diagnostic si historique |
| 41 | **D-5** — `TRAIN_SKILL` CO/CE | `progress.unit = SERIES`, `quota = 2` ; jamais `PROMPT` |
| 42 | **D-7** — étape clôturée puis compétence redevenue fragile | `closed_at` **inchangée**, l'étape n'est **pas** réouverte ; la fragilité reviendra par un examen (R7) |
| 43 | **D-7** — recalibrage du moteur de maîtrise | Aucune étape clôturée n'est réinterprétée ; les étapes ouvertes se relisent |
| 44 | **B-14** — `plan_pinned_priorities` supprimée | Aucun code ne la lit ; l'étape 1 d'un compte gratuit reste ouverte |
| 45 | **§7.2** — l'orchestration lève une exception | La correction du QCM et la réponse HTTP **aboutissent** ; la lecture suivante rattrape |

## 19. Vérification d'interface — **checklist manuelle, PAS des tests** (B-12)

> 🛑 **Aucun NOUVEAU test sur les fronts.** La règle du `CLAUDE.md` racine **prime** sur toute
> consigne de test écrite ailleurs, y compris dans cette spec. Les points ci-dessous sont une
> **checklist de relecture**, pas des fichiers de test.
> Vérification d'un changement front : `npx tsc --noEmit` · `npm run build` · `flutter analyze`.
> Les **16 tests TS et 24 tests Dart existants** doivent rester verts ; ceux que ce chantier rend
> rouges se **mettent à jour ou se suppriment**, un par un, jamais en masse.

- Ancien bloc « Votre parcours — Tâche X » absent ; « chemin vers l'objectif » absent (D-4).
- En-tête niveau actuel / objectif toujours présent (D-4).
- Titre « Votre parcours vers le {niveau cible} » correct pour A2, B1, B2.
- `CURRENT` mis en avant ; carte « À faire maintenant » identique **sur les 6 sites** (§10).
- Badge **EXAMEN** sur les étapes `SECTION_EXAM`.
- Étapes terminées et sautées cochées ; étapes obsolètes absentes.
- Étapes verrouillées **visibles à leur place**, cadenas + CTA paywall (R16).
- Compte gratuit : carte = première étape exécutable ; si aucune, première étape verrouillée (D-1).
- Sans démarche déclarée : carte « Choisir mon objectif » (D-3).
- `TRAIN_SKILL` compréhension : « série ciblée », compteur en séries, pas en petits sujets (D-5).
- Checkpoint du lot courant toujours visible, liste longue repliable.
- Responsive 360 / 768 / 1280 ; mobile hors-ligne affiche le dernier instantané.

---

# PLAN D'IMPLÉMENTATION

## 20. Phase 0 — Audit ✅ validé le 2026-09-17

`docs/progression/audit-plan-tcf-parcours-evaluations-v2.md`. Les 9 arbitrages sont en §0 bis, leur
journal verbatim dans `docs/decisions/plan-parcours-tcf.md`.

**STOP — relecture de cette spec révisée et du journal de décisions.** ⬅️ *nous sommes ici*

## 21. Phase 1 — Données et config

`V066__schema_journey_tcf.sql` (`00_schema/`, **DDL seulement**), entités, managers, repositories,
`tcf-journey-config-v1.json` + son loader validant.

**STOP — validation du schéma.**

## 22. Phase 2 — Orchestration

Service de parcours (§7), fonction de filtre R1 **partagée** (D-6), bootstrap R19, branchements
après écriture des observations (§7.2), **suppression de `plan_pinned_priorities`** et report de son
rôle sur la première étape non clôturée, tests §18 (45 cas).
Mise à jour de `docs/regles/plan.md` : R1, R2 (le budget pédagogique **et sa raison**, B-5), R8, la
notion d'étape exécutable.

**STOP — validation des tests métier.**

## 23. Phase 3 — API

`GET /api/me/plan/journey` (B-10), `JourneyStepDto` (D-8), `locked` et `CURRENT` calculés à la
lecture (D-1, D-7), `progress.unit` (D-5), filtrage §14, **faits servis / phrases aux fronts**
(B-11). Miroirs `lib/types.ts` et `core/models/*.dart` mis à jour à la main.
Mise à jour de `docs/api-endpoints.md`.

**STOP — validation du contrat.**

## 24. Phase 4 — Web puis mobile

**Trois écrans × deux fronts** : les 6 cartes « À faire maintenant » branchées sur `current` (§10),
la timeline §12-14 dans **les deux kits**, les suppressions §11.
Vérification : `npx tsc --noEmit`, `npm run build`, `flutter analyze` — **et rien d'autre** (B-12).
Mise à jour du `CLAUDE.md` local de chaque front si une convention change.

**STOP — validation visuelle.**

---

# CRITÈRES D'ACCEPTATION

1. Sans niveau cible, le Plan propose « Choisir mon objectif » et **aucun parcours n'est créé**.
2. Sans évaluation, le Plan propose le diagnostic rapide.
3. Les étapes proviennent **uniquement d'évaluations** ; un entraînement n'en crée jamais, mais
   continue d'écrire ses observations.
4. Un entraînement peut **faire avancer ou terminer** une étape existante, jamais en créer une.
5. Un lot contient au plus `maxPrioritiesPerLot` priorités par épreuve.
6. Chaque lot est suivi d'un examen de réévaluation de son épreuve.
7. Les nouveaux lots sont ajoutés après les étapes en attente, dans un ordre déterministe
   (écart au niveau cible **lecture Plan**, puis `CO, CE, EO, EE`).
8. Au plus un lot ouvert par épreuve.
9. Un examen passé hors Plan est toujours pris en compte (validation ou remplacement du lot).
10. Une étape `TRAIN_SKILL` se termine par maîtrise ou quota — **5 petits sujets en expression,
    2 séries en compréhension** ; aucune ne bloque le parcours.
11. Un examen sans priorité n'est pas présenté comme une maîtrise.
12. Le traitement est idempotent, sérialisé, calculé côté serveur, et **jamais bloquant** pour la
    correction d'une session ni la livraison d'une évaluation.
13. Le Premium ne modifie **jamais** l'ordre du parcours ; une étape verrouillée reste **affichée à
    sa place** et ne devient jamais `CURRENT`.
14. Un compte gratuit voit son parcours **avancer** : `CURRENT` est la première étape exécutable, ou
    `null` avec la première étape verrouillée en carte.
15. La carte « À faire maintenant » et la timeline sont toujours synchronisées, **sur les six sites
    d'appel**.
16. Le titre reflète le niveau cible ; le palier CECRL reste dans l'en-tête.
17. Les moteurs de score, de maîtrise, de niveau et d'Attempt existants sont réutilisés **sans
    duplication** ; aucune valeur métier n'est recopiée.
18. `CURRENT`, `locked` et tous les statuts de rendu sont **calculés à la lecture** ; seule la
    structure et la date de clôture sont persistées, et une clôture ne se réouvre jamais.
19. Un utilisateur ayant déjà des évaluations ne voit jamais de diagnostic initial, ni à la première
    ouverture du Plan, ni après un changement d'objectif.
20. L'ancien « chemin vers l'objectif », l'ancien bloc « Votre parcours — Tâche X » et
    `plan_pinned_priorities` ont **disparu du dépôt**.

---

## 25. Résumé produit

> **Le Plan n'apprend rien des entraînements. Il apprend des évaluations.**
>
> Une évaluation dit : « Voici les 3 choses les plus importantes à travailler. »
> Le candidat les travaille — et son travail fait avancer l'étape, sans jamais en créer une nouvelle.
> Un examen dit : « Voici ce qu'il reste maintenant. »
> Ces nouvelles priorités passent en fin de parcours, pour que toutes les épreuves continuent
> d'avancer.
>
> Et le parcours d'un candidat gratuit **avance** : ce qu'il ne peut pas finir reste visible,
> cadenassé, à sa place.
