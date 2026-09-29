# SPEC — Moteur de cycle (Plan) — SejourFR

Statut : **spécification fonctionnelle, mise en conformité le 2026-09-18** (phase P1).
Périmètre de cette livraison : **TCF IRN seulement**, écrans **Plan** et **Progression**.

> **Ce document est la cible fonctionnelle.** Les arbitrages qui l'ont mis en conformité sont
> consignés verbatim dans `docs/decisions/plan-parcours-tcf.md` (**D-12 → D-24**, 2026-09-18), à
> partir de `docs/audits/AUDIT_cycle_plan.md` et de `docs/audits/REPONSES_AUDIT_cycle_plan.md`.
> Chaque règle ci-dessous porte la référence de la décision qui la tient.

## Vocabulaire — ce document parle le langage du dépôt

🛑 Le mot « cycle » du premier jet était un **nom de commodité**. Le vocabulaire en vigueur est
celui livré le 2026-09-17 (**D-8 maintenu**), et il est **interne** :

| Ce document dit | En base / en code | À l'écran, le candidat lit |
|---|---|---|
| **cycle** | `journey` (une ligne par `(user, module, status)`) | « votre parcours » |
| **bloc** | l'ensemble des étapes d'une **épreuve** dans le cycle (les lots ouverts de cette épreuve + son examen) | « Compréhension orale », « Expression écrite »… |
| **lot** | `journey_lot` — les ≤ 3 priorités qu'**une** évaluation a retenues pour une épreuve | *jamais affiché* |
| **étape** | `journey_step` | « étape » |
| **compétence** | **`Skill`** (table `skills`) | le titre de la compétence |

🛑 **`lot`, `step`, `journey`, `cycle` ne s'affichent jamais** (D-21). Le vocabulaire d'écran est
celui des **épreuves**.

---

## 1. Objets

| Objet | Description |
|---|---|
| **Cycle** (`journey`) | Un parcours borné. Statut **persisté** : `EN_COURS`, `EN_ATTENTE` (invisible du candidat), `HISTORISE`. **Un seul `EN_COURS` et un seul `EN_ATTENTE` par (utilisateur, module)**, par index uniques partiels (D-13). Le cycle porte aussi son **niveau d'entrée** et, à l'historisation, son **niveau de sortie**, persisté (D-12). |
| **Bloc** | Une **épreuve** : CO, CE, EO, EE. Le bloc n'est pas une table : c'est la **lecture par épreuve** des étapes du cycle (D-12). Le cycle borné **se superpose** aux lots, il ne les remplace pas. |
| **Étape** (`journey_step`) | Type : `TRAIN_SKILL` (travailler une compétence) ou `SECTION_EXAM` (l'examen du bloc), plus `DIAGNOSTIC`. 🛑 **Son statut n'est PAS persisté** : `UPCOMING` / `CURRENT` / `COMPLETED` / `SKIPPED` / `OBSOLETE` et `locked` sont **dérivés à la lecture** (D-14, D-7). Ce qui est persisté : la structure, `closed_at` et `resolution`. |
| **Compétence** | ⚠️ **Elle existe déjà : c'est `Skill`** — 48 compétences d'expression (taxonomie V3) + 6 de compréhension. *Le premier jet de cette spec affirmait le contraire ; c'était faux.* Une `Question` **n'est pas taguée** par compétence, et ne le sera pas dans ce chantier (D-19). |
| **Examen de bloc** (`SECTION_EXAM`) | L'examen blanc d'**une** épreuve. C'est **toujours la dernière étape** de son bloc. |
| **Examen complet** | L'examen blanc des 4 épreuves. Déjà passable **épreuve par épreuve** : c'est le modèle en place (`attempts.parent_attempt_id` + 4 sous-attempts). Chaque partie terminée vaut examen de bloc de son épreuve. |

**Nommage à l'écran** : `SECTION_EXAM` s'affiche « **Évaluer mon niveau** » tant que l'épreuve n'a
jamais été mesurée, « **Vérifier mes progrès** » ensuite. C'est le **même objet** — c'est déjà
`JourneyStepPurpose.INITIAL_ASSESSMENT` / `REASSESS`, et l'autorité de « mesurée » est
`NiveauActuelEpreuveResolver`.

### La compétence de compréhension **est le palier** (D-19)

Il n'existe aucune liaison question ↔ compétence, et on n'en crée pas. En CO/CE la compétence est
**dérivée du contenu** vers six unités : `CO-A2/B1/B2`, `CE-A2/B1/B2`. ⚠️ Les libellés de
micro-compétences de compréhension des maquettes (« Comprendre l'implicite à l'oral ») sont
**illustratifs, pas contractuels**.

---

## 2. Création d'un cycle — 3 amorces

| Amorce | Cycle créé |
|---|---|
| **A. Diagnostic rapide fait** | Les blocs **EE et EO** portent les compétences prioritaires détectées + leur examen. Les blocs **CO et CE** ne portent que leur examen (« Évaluer mon niveau »). ⚠️ Le diagnostic rapide produit **deux** productions (écrit **et** oral) : les deux blocs d'expression sont donc peuplés, pas seulement EE. |
| **B. Aucun diagnostic, mais un examen passé sur une épreuve X** | Bloc X = les priorités détectées dans cet examen + son examen **déjà clôturé**. Autres blocs = leur examen seul. |
| **C. Aucun diagnostic, aucun examen** | Les 4 blocs ne portent que leur examen. En tête du Plan, « À faire maintenant » affiche **« Faire le diagnostic rapide »** tant qu'il n'a pas été fait. |

**Ordre des blocs : `CO, CE, EO, EE`** — `TcfDomainProfileDto.ORDRE`, autorité unique, **non
configurable** (D-20, D-9). Le besoin « l'expression d'abord » est satisfait **par construction** :
le diagnostic rapide crée les lots EE/EO, qui sont donc en tête de file.

**Un cycle n'existe pas sans niveau cible** (D-3) : sans démarche déclarée, l'état est
`NEEDS_OBJECTIVE` et les écrans invitent à « Choisir mon objectif » — **sans rien retirer**.

---

## 3. Progression et déblocage

- La progression se **lit par bloc** : les compétences d'une épreuve, puis son examen, puis
  l'épreuve suivante.
- Le candidat **n'est pas obligé de suivre l'ordre** : toute étape `TRAIN_SKILL` est ouvrable, dans
  n'importe quel bloc, à tout moment (sous réserve du freemium, §7).
- **Seule exception : l'examen d'un bloc est verrouillé tant qu'une compétence du même bloc n'est
  pas clôturée** (D-15). Un bloc sans compétence a son examen ouvert immédiatement.
- Le **bloc** est terminé quand toutes ses étapes sont clôturées ; le **cycle** est terminé quand
  ses quatre blocs le sont.
- `CURRENT` reste la première étape **non clôturée et exécutable** (D-1).

---

## 4. Validation automatique des étapes

### R1 — Examen passé hors du plan
Un examen passé depuis **Réviser**, depuis **Examens**, ou comme partie d'un **examen complet**,
clôture l'étape `SECTION_EXAM` de l'épreuve **si et seulement si cette étape était débloquée au
moment du passage** (aucune compétence restante dans le bloc).

| Situation | Examen passé | Résultat |
|---|---|---|
| Bloc CO = son examen seul | Examen CO via Réviser | ✅ étape CO clôturée |
| Bloc EE = 3 compétences non faites + son examen | Examen EE via Réviser | ❌ rien n'est validé — l'examen compte comme entraînement |
| Bloc EE = 3 compétences clôturées + son examen | Examen complet | ✅ étape EE clôturée |

🛑 **Ce que ça révoque** (D-15) : un examen passé alors que le bloc n'est pas fini **ne clôture plus
les étapes restantes** en `SUPERSEDED`. Le travail prévu reste dû. `SUPERSEDED` garde ses autres
emplois.

### R2 — Une compétence se clôt par l'entraînement
Une étape `TRAIN_SKILL` de compréhension se clôt après **2 séries réussies**, **ou** après
**4 séries terminées** quelle que soit leur réussite — l'échappatoire existe pour qu'un **candidat
faible ne reste jamais bloqué** (D-16).

- Le **seuil de réussite est lu** chez l'autorité qui l'a déjà : `learning-plan.comprehension.solid-ratio`
  (0.80). 🛑 Aucune nouvelle déclaration de ce seuil.
- En **expression**, le quota reste les **5 sujets de l'étape** (`LearningPlanStep.PROMPTS_PAR_ETAPE`),
  hors configuration (D-5). L'unité est **servie** (`progress.unit`).
- Une clôture **ne se réouvre jamais** : une compétence redevenue fragile revient par un **examen**.
- L'autorité de maîtrise lue par le cycle est **`SkillMasteryEngine`, et elle seule** (D-20). Le
  moteur `progression/` V4.2 reste en shadow.

### R3 — L'entraînement n'alimente jamais le cycle
Seules les **évaluations** (diagnostic, examen de bloc, sous-épreuve d'examen complet) créent des
étapes. Un entraînement peut **faire avancer ou clôturer** une étape existante, jamais en créer.
Déjà codé : `JourneyEvaluationFilter` (D-6).

---

## 5. Cycle en attente

- À chaque évaluation passée pendant le cycle en cours, les priorités nouvellement détectées sont
  écrites dans le cycle **`EN_ATTENTE`** du module. **Invisible du candidat.**
- Une priorité déjà clôturée dans le cycle en cours n'y est **pas** recréée, sauf **régression
  mesurée** au dernier examen.
- 🛑 **Ceci révoque une règle du 2026-09-17** — « les autres [priorités] ne sont pas stockées ni
  mises en attente » (D-13). Ce qui change est la **destination** de ce qui dépasse le plafond, pas
  le plafond : `maxPrioritiesPerLot` reste à **3** (D-20).

---

## 6. Fin de cycle — transitions

Quand le cycle est terminé, le Plan affiche « **Prochaine étape** » avec deux issues :

| Action | Effet |
|---|---|
| **Passer l'examen blanc complet** | Le cycle `EN_ATTENTE` est laissé de côté. Un **cycle de mesure** devient `EN_COURS` : 4 blocs, chacun ne portant que son examen, tous débloqués. Passable épreuve par épreuve ou d'un trait. Le cycle courant est **historisé** avec son niveau de sortie. Les résultats alimentent le cycle `EN_ATTENTE`. |
| **Actualiser mon plan sans examen complet** | Le cycle `EN_ATTENTE` devient `EN_COURS`, le cycle courant est **historisé** avec son niveau de sortie, un nouveau `EN_ATTENTE` vide est créé. |

**Cas particulier** : à la fin d'un **cycle de mesure**, la seule issue proposée est « Actualiser mon
plan ».
**Cas vide** : si le cycle `EN_ATTENTE` est vide au moment d'actualiser (aucune priorité, niveau
cible atteint partout), le Plan bascule sur « **Objectif atteint** » — maintien par un examen
complet par mois, au lieu d'un nouveau cycle.

---

## 7. Freemium (réécrit — D-17, D-18)

### Gratuit

| Élément | Détail |
|---|---|
| Diagnostic rapide | Gratuit, priorités et analyse comprises. |
| **1 examen blanc EE** | Gratuit, **une fois à vie** : les 3 tâches sont réellement corrigées, le LLM est appelé, l'analyse est complète. |
| **1 examen blanc EO** | Gratuit, **une fois à vie**, aux mêmes conditions. ⚠️ **Deux freebies nominatifs**, un par épreuve — pas « un au choix ». |
| Examens QCM CO / CE | **Inchangé** : slot 1 offert et rejouable (`enforceMockExamSlotAccess`). |

### Premium, sans exception
Tout travail de compétence depuis le Plan, tous les sujets d'expression au-delà du freebie,
**toute** analyse IA EE/EO au-delà du freebie.

### Comportement d'un compte gratuit
- Le cycle reste **entièrement lisible** — c'est l'argument de vente — mais **aucune étape n'est
  exécutable**. `LOCKED` permanent est l'effet **voulu** (D-18).
- « À faire maintenant » nomme la première étape verrouillée, avec son cadenas ; le tap ouvre la
  popup « **Débloquer mon plan** » → paywall. Un bouton « Débloquer mon plan » est ancré en bas du
  cycle.
- 🛑 **La contradiction #1 du dépôt n'est pas rouverte** : on floute l'**action**, jamais le
  **résultat mesuré**. Niveaux, priorités et compteurs restent lisibles.

### Rejeu d'un examen dont le freebie est consommé (D-17 bis)
- Le rejeu **est ouvert** ; c'est l'**analyse IA** qui est premium. Aucun quota journalier.
- 🛑 **Aucun appel payant n'est déclenché** : ni correcteur, ni **Whisper**. Le refus se pose **avant**
  le pipeline, comme l'idempotence de V046.
- 🛑 **À trancher avant P4, côté EO** : sans Whisper il ne reste **rien** à lire (l'audio candidat
  n'est jamais conservé). Recommandation : pour EO, le paywall se présente **au démarrage de la
  tâche**, pour ne pas faire produire dans le vide. En EE le texte reste relisible.

### Consommation du freebie — règle stricte
- Le freebie est consommé **uniquement** quand l'examen est **terminé et l'analyse rendue**. Abandon,
  expiration, échec technique, échec du correcteur ⇒ **non consommé**, le candidat le retrouve.
- La consommation est **persistée**, pas calculée à la lecture : **un ledger unique**, du type
  `free_entitlement_usage (user_id, code, consumed_at, source_attempt_id)`, `UNIQUE (user_id, code)`,
  auquel les **quatre** implémentations ad hoc de « première fois gratuite » sont ramenées.
- Le point d'écriture est la **remise de l'analyse**, ni le démarrage de l'examen, ni `doFinish` seul.

### Ce que ça révoque
`free-analyses: 3` (« 3 analyses IA à vie ») — **supprimé**, sans quota journalier de remplacement
(⚠️ le premier jet demandait « 1 analyse IA / jour » : **refusé**, plus simple sans). Le seuil
« 2 sessions EE+EO confondues » ⇒ **1 par épreuve, nominatif**. `FREE_TRAINING_PER_EPREUVE = 1` ⇒
**supprimé**. Dans `SkillAccessService`, l'ouverture de la compétence du focus Plan et du premier
rang EE/EO ⇒ **supprimées**. L'exemption du 2026-08-21 ⇒ **révoquée**.


---

## 8. Écrans (périmètre corrigé — D-22)

### Accueil — **hors périmètre, on ne touche pas**
Aucune section n'est retirée. ⚠️ Le seul changement est **indirect** : la carte « À faire
maintenant » lit le parcours et le freemium, elle affichera donc un cadenas pour un compte gratuit.
*Le premier jet demandait de réduire l'Accueil à deux sections et de retirer le rappel d'objectif et
les CTA par épreuve : **annulé**.*

### Plan — le changement commence à « Votre parcours vers le B2 »
**Inchangés** : l'en-tête, le toggle de module, le bloc objectif, et la section « À faire
maintenant ».
**Remplacé, à partir du titre « Votre parcours vers le B2 »**, par l'équivalent des maquettes
`docs/progression/plan_cycle.html` et `docs/progression/cycle_termine.html` :

1. l'**encart de cycle** : barre d'avancement **continue** + « X étapes sur Y terminées » + repère de
   cycle ;
2. les **blocs d'épreuve dépliables** : initiale (CO/CE/EE/EO) + titre d'épreuve + méta
   (« 1 compétence restante · puis examen ») + pastille d'état ; **le bloc courant est déplié, les
   autres repliés** ;
3. les **lignes d'étape** avec leur état, et l'**encart d'examen** imbriqué en fin de bloc
   (`VERROUILLÉ` / `DISPONIBLE` + la phrase de condition) ;
4. la note « vous pouvez travailler les compétences dans l'ordre que vous voulez » ;
5. le bouton « **Voir ma progression** » ;
6. l'état **cycle terminé** : encart à 100 %, quatre blocs repliés en `TERMINÉ`, séparateur
   « Prochaine étape », **carte finale à deux actions** (§6).

⚠️ Ce que la maquette montre **au-dessus** de cette section ne s'applique pas : elle place sa propre
carte « À faire maintenant » dans son en-tête ; c'est l'**existant** qui reste à cette place.

🛑 **L'épreuve est lisible partout** (D-21) : dans « À faire maintenant », dans l'en-tête du bloc,
sur la ligne d'étape et sur l'écran de résultat. Le candidat doit savoir en permanence sur quelle
épreuve il travaille.

Les deux fronts assemblent les **mêmes primitives**, miroirs brique pour brique
(`web_sejoufr/app/_components/sejour/SejourKit.tsx` ⇄
`mobile_sejourfr/lib/core/widgets/sejour/sejour_kit.dart`). Cinq briques manquent **des deux
côtés** : accordéon de bloc, carte finale à deux actions, barre d'avancement continue, encart
d'examen, liste d'historique — elles se créent **dans les deux kits dans la même passe**.

### Progression — 🛑 **écran bloqué**
Le contenu visé est la liste des cycles historisés, du plus récent au plus ancien : dates,
compétences travaillées, examens passés et scores, niveau mesuré **en entrée et en sortie** (persisté
à l'historisation, D-12).
⚠️ **Le propriétaire fournira le template de cet écran.** Ne rien concevoir ni implémenter avant
réception ; le seul travail autorisé en amont est l'**endpoint d'agrégation**, et seulement après la
phase des écrans (D-23). La refonte portera sur `/plan/progression`, avec suppression de
`/plan/evolution` dans la même passe.

### Toggle de module
Présent sur les deux écrans, **inchangé**. ⚠️ Le « mode global **persisté** » est un **chantier à
part** (D-23) : aujourd'hui il n'est persisté nulle part et 7 mécaniques concurrentes coexistent.

---

## 9. Configuration versionnée

Fichier : `backend_sejourfr/src/main/resources/plan/cycle-config-v1.json`, **distinct** de
`plan-config` (qui s'interdit d'influencer le calcul de maîtrise), avec son **propre loader
validant** sur le patron `TcfJourneyConfigLoader` (refus sur clé inconnue, version discordante,
plafond ≤ 0 ; **aucun défaut en Java**, aucun rechargement à chaud).

```json
{
  "cycleConfigVersion": 1,
  "seuil_reussite_competence": 0.80,
  "exam_bloc_gratuit": { "epreuves": ["EE", "EO"], "quantite": 1 }
}
```

🛑 **Ce qui n'entre PAS en configuration**, et pourquoi :

| Clé du premier jet | Pourquoi elle est supprimée |
|---|---|
| `nb_series_reussies_pour_valider_competence` | **existe déjà** : `trainSeriesQuota` dans `plan/tcf-journey-config-v2.json` — l'échappatoire des 4 séries terminées y a pris une **clé distincte**, `trainSeriesFallbackQuota` (D-16, livré en P4). |
| `nb_max_competences_par_bloc` | **existe déjà** : `maxPrioritiesPerLot: 3`, valeur inchangée (D-20). |
| `ordre_blocs_cycle_initial` | l'ordre est `TcfDomainProfileDto.ORDRE`, autorité unique **non configurable** (D-9, D-20). |
| `analyses_ia_par_jour_gratuit` | **aucun quota journalier n'est introduit** (D-17). |
| `civique.{seuil_examen, nb_questions_examen}` | `CivicExamFormat` : « c'est du code, pas un réglage » — et le civique sort du chantier (D-23). |

⚠️ `seuil_reussite_competence` figurait ci-dessus comme **valeur de référence du cadre**.
🛑 **Tranché en P4 (2026-09-18) : elle N'ENTRE PAS en configuration.** Le calcul ne lit pas un
seuil du tout — il relit le **verdict déjà posé**,
`learning_plan_observations.status = SOLID`, écrit par `ComprehensionObservationService` à
partir de `learning-plan.comprehension.solid-ratio`. La servir dans un second fichier en aurait
fait une seconde déclaration ; la lire depuis ce fichier-là pour recalculer un ratio en aurait
fait un second calcul. Une règle, une autorité, et le seuil ne bouge pas d'endroit.

🛑 **`cycle-config-v1.json` n'a donc pas été créé, et `CycleConfigLoader` non plus** : après le
retrait de `seuil_reussite_competence` (ici), de
`nb_series_reussies_pour_valider_competence`, de `nb_max_competences_par_bloc`, de
`ordre_blocs_cycle_initial`, de `analyses_ia_par_jour_gratuit` et du bloc `civique`, il ne
restait que `exam_bloc_gratuit` — dont la valeur est **portée par l'enum**
`FreeEntitlementCode` (`EXAM_BLANC_EE`, `EXAM_BLANC_EO`), miroir d'un `CHECK` de la base : ce
sont **deux gratuités nommées**, pas un réglage. L'échappatoire de D-16, elle, a rejoint le
fichier qui a déjà son loader validant : `plan/tcf-journey-config-v2.json`
(`trainSeriesFallbackQuota: 4`), v1 restant chargeable à l'identique.

---

## 10. Ce qui a été tranché, et ce qui reste ouvert

**Tranché** (détail : `docs/decisions/plan-parcours-tcf.md` D-12 → D-24)

1. **`Competence` existe** : c'est `Skill`. *Le premier jet affirmait l'inverse.* Aucune seconde
   entité n'est créée, et **pas** de `question_skills` : la compétence de compréhension est le
   **palier** (D-19).
2. Le **diagnostic rapide n'est pas** l'examen de bloc EE. Deux gestes distincts, tous deux
   gratuits ; le double coût LLM au démarrage est **assumé** (D-17).
3. **Civique hors chantier** : le moteur est livré TCF d'abord (D-23).
4. **Régression** : une compétence déjà clôturée n'est **pas** décochée dans le cycle en cours ; elle
   est réinjectée dans le cycle `EN_ATTENTE` (D-13, D-16).
5. **Expiration** : pas d'expiration temporelle. Un cycle abandonné reste en cours (R17).

**Ouvert**

- ~~Le **paywall d'un rejeu EO**~~ : **tranché et livré en P4** (2026-09-18). Le refus se pose
  **au démarrage de l'épreuve** (`ProductionAccessService.assertCanStartProductionExam`), pas
  après la soumission : sans Whisper il ne resterait rien à lire, et l'audio d'un candidat n'est
  jamais conservé. À l'écrit le démarrage reste ouvert, et c'est `enforceQuota` qui refuse
  l'analyse — avant tout appel payé.
- Le template de l'écran **Progression**, à fournir par le propriétaire — §8.
