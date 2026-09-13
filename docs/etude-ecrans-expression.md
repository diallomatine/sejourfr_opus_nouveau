# Étude — les 3 écrans d'expression (EE/EO)

**Étude close. Les décisions sont prises — §0 fait foi.**
Ce qui suit (§1 à §4) est l'analyse qui a servi à les prendre ; elle est
conservée telle quelle, y compris les options écartées, parce que c'est elle qui
explique *pourquoi* on a tranché ainsi. Le §5 récapitule.

---

## 0. Décisions finales (arbitrage du propriétaire, 2026-09-12)

🛑 **Ces neuf décisions font foi.** Là où elles contredisent une option de
l'étude, ce sont elles qui l'emportent.

1. **« Acquis » et « Série terminée » sont deux choses distinctes, et on dit les
   deux.** (Option C du §3.3.)
   - 5 petits sujets validés ⇒ « **Série terminée · 5/5** ».
   - Une compétence n'est « **Acquise** » **que si `masteryState == SOLID`** —
     donc jamais sans production complète.
   - Une compétence acquise affiche **son palier** : « Acquis · A2 » / « · B1 » /
     « · B2 », lu sur **`skills.target_level`**.
2. **Option D écartée pour ce chantier.** Aucune migration pour agréger un
   `level_reached` par compétence. Le palier affiché est celui **du
   référentiel**, jamais un palier démontré.
3. **La carte « Recommandé pour vous » est pilotée par le PLAN**, jamais par
   l'ordre du catalogue. On cherche la compétence la plus prioritaire **de
   l'épreuve affichée**, dans cet ordre : `plan.seance.items` → `currentPriority`
   → `nextPriorities`. **Aucun repli artificiel** sur la première compétence
   disponible : si le Plan ne désigne rien sur cette épreuve, **pas de carte**.
   Les compteurs (« 2/5 exercices réussis ») sont ceux **déjà servis** par le
   Plan.
4. **« Examens blancs » reste en bas**, comme aujourd'hui.
5. **« X/8 compétences acquises » ne compte que les `SOLID`.** Ni une compétence
   simplement observée, ni une série 5/5 ne comptent. Le badge d'une tâche reste
   cohérent avec ce compteur : pas de « Acquis » à 3/8.
6. **Le badge d'une tâche porte le palier RÉEL de la tâche** — « PALIER A2 » /
   « PALIER B1 » / « PALIER B2 ». L'objectif personnel du candidat (B2) peut
   rester sur l'écran **global** Expression, mais ne doit jamais être présenté
   comme le niveau de la Tâche 1.
7. **`learning_points` est validé** : nouvelle donnée éditoriale sur `skills`,
   3 points courts par compétence (« Choisir tu ou vous »…), migration
   **additive**, DTO / mappers / admin / web / mobile + tests de forme et de
   complétude. 🛑 **Jamais dérivés** de `general_criterion` ni des `checklist`
   des sujets.
   - Production du contenu : **principe B2 validé** (génération assistée par
     LLM, contenu **figé dans les seeds**). 🛑 **Aucun appel payant sans un
     coût estimé présenté et un feu vert explicite.** L'infrastructure et le
     générateur se préparent dès maintenant.
8. **Durée : « 5 petits sujets · ≈ X min chacun »**, calculée par
   `ExerciseDuration`. **Ne jamais présenter « ≈ 5 min » comme la durée totale**
   de la séance.
9. **Le périmètre des sujets garde ses DEUX comportements**, et ce n'est pas un
   défaut :
   - arrivée depuis le Plan / « Recommandé » ⇒ **vue de l'étape**, 5 sujets ;
   - arrivée libre depuis le catalogue ⇒ **vue complète**, 15 sujets.
   Ne pas transformer toutes les compétences en groupes de 5 par défaut.

**Deux consignes de rédaction qui accompagnent l'arbitrage :**

- **Les textes suivent l'état réel.** Les 5 sujets terminés ⇒ pas de
  « Continuer la séance ». Le libellé dit ce qui va réellement se passer, **sans
  inventer de logique métier nouvelle**.
- **« Sujets d'examen » devient « Sujets complets »**, partout, web et mobile
  dans la même passe.

**Hors périmètre de ce chantier, explicitement :** le moteur de progression
V4.2 (`progression/`) et le modèle de niveau démontré. On n'y touche pas.

---

Maquettes : `~/Desktop/sejourfr_ecrans/expression_ecran.png`,
`detail_tache.png`, `detail_competence.png`.

---

## 1. Ce que je lis sur les trois maquettes

**Détail expression** — en-tête `TCF IRN / Expression écrite / Votre progression
vers l'objectif B2`, puis une carte **« Recommandé pour vous »** (icône,
« Développer un argument », « Tâche 3 · Point de vue argumenté », « 2/5
exercices réussis », CTA rouge « Continuer »), puis **« Les 3 tâches »** avec
« 3/8 compétences acquises » par tâche et un badge **En cours** sur la tâche 3.

**Détail de la tâche** — en-tête `Tâche 1 · Expression écrite`, badge
**OBJECTIF B2**, carte « Consigne · 60 à 80 mots », onglets **Compétences** /
**Sujets complets**, puis 8 lignes de compétence avec un sous-titre et une
pastille : *Acquis* (vert), *En cours · 2/5 réussis* (bleu), *À découvrir /
À faire* (gris).

**Détail d'une compétence** — carte à eyebrow **« Compétence acquise »**, titre,
**« Vous allez apprendre à : »** + 3 puces vertes, ligne « ☰ 5 petits sujets ·
⏱ ≈ 5 min », CTA rouge « Continuer la séance » ; puis « Compétence acquise /
0 restants » + barre pleine, puis « Les petits sujets » 01→05, tous *Acquis*.

**Deux observations de lecture, avant tout :**

- **Cet écran-là montre 5 petits sujets. Une compétence en porte 15.** 5, c'est
  le périmètre d'une **étape du Plan** (`LearningPlanStep.PROMPTS_PAR_ETAPE`).
  La maquette décrit donc la **vue scopée à l'étape**, qui existe déjà des deux
  côtés (`?etape=1` web, `planStep: true` mobile). Tout concorde : « 5 petits
  sujets », « 0 restants », la barre pleine.
- **Les maquettes introduisent un quatrième vocabulaire.** L'app dit aujourd'hui
  *Priorité · À renforcer · En consolidation · Solide* (état d'une compétence),
  *À faire · Fait · Validé · À renforcer* (statut d'un sujet), *À évaluer · À
  renforcer · À vérifier · À acquérir* (nature d'action du Plan). La maquette
  ajoute *Acquis · En cours · À faire*. C'est ce que la question du §3 doit
  ranger.

---

## 2. Détail expression — ce qui est prêt, ce qui attend

| Ta demande | État |
|---|---|
| Garder « Examens blancs » en bas | ✅ déjà le cas des deux côtés. Rien à changer. |
| « Recommandé » = une compétence **du Plan**, la plus prioritaire | ⚠️ à faire |

### Ce que la carte fait aujourd'hui

Elle s'appelle « Prochain entraînement » et prend la **première compétence non
terminée dans l'ordre du référentiel** :

```ts
// web_sejoufr/app/_components/production/parcours.ts
export function nextSkill(skills) {
  return skills?.find((k) => !k.locked && k.attemptedCount < k.promptCount) ?? null;
}
```

C'est un choix **de catalogue**, pas **pédagogique** : il ne lit pas le Plan, il
prend la première case libre. Côté mobile il n'y a même pas de carte (retirée à
la refonte du 2026-08-21).

### Ce qu'il faut mettre à la place

La compétence désignée par le Plan, dans cet ordre :

1. **`plan.seance.items[0]`** — la première ligne de la séance du jour. C'est
   déjà l'autorité qu'a adoptée l'écran Réviser (commit `7fb6f17d`).
2. **`plan.currentPriority`**, si la séance est vide.

Les deux portent `skillId`, `title`, `section` et
`stepAttemptedCount / stepValidatedCount / stepPromptCount` — donc « 2/5
exercices réussis » s'écrit **sans rien compter côté front**.

⚠️ **La compétence du Plan n'est pas forcément de cette épreuve.** Le Plan
classe les **quatre** domaines par urgence : un candidat dont la priorité n°1
est en CO n'a aucune compétence EE à recommander ici. Il faut donc filtrer sur
la section de l'écran, et se rabattre sur la **première compétence de cette
section dans l'ordre des priorités** (`currentPriority` puis `nextPriorities`).
Si le Plan ne désigne rien sur cette épreuve : **pas de carte** — plutôt que de
retomber en silence sur « la première case libre », qui recommanderait autre
chose que le Plan.

### Pourquoi je n'ai pas codé

Les cartes de tâche affichent **« 3/8 compétences acquises »**. Ce compteur
n'est servi par rien (§3.2) et sa définition est exactement ta question. Coder
le reste en laissant ce nombre faux serait pire qu'attendre. **Tranche le §3 et
je fais les trois écrans d'un coup.**

---

## 3. QUESTION A — « Acquis », et à quel palier

> *« Comment marquer une compétence comme acquise ? Une personne qui vise un B2
> peut très bien acquérir une tâche mais en A2, ou B1, mais pas encore de niveau
> B2. »*

### 3.1 Ce que le serveur SAIT déjà

**Le palier est déjà en base, compétence par compétence.**
`skills.target_level`, `varchar(4) NOT NULL`, avec un CHECK
`IN ('A1','A2','B1','B2')`. Le seed réel :

| Tâche | Palier de la tâche | Paliers de ses 8 compétences |
|---|---|---|
| EE1 « Écrire un message court » | A2 | **8 × A2** |
| EE2 « Raconter une expérience » | B1 | **8 × B1** |
| EE3 « Donner son opinion » | B2 | **3 × B1 + 5 × B2** |
| EO1 « Parler de soi » | A2 | **8 × A2** |
| EO2 « Jeu de rôle » | B1 | **8 × B1** |
| EO3 « Point de vue » | B2 | **8 × B2** |

Ton intuition est donc **déjà vraie dans le contenu** : acquérir les 8
compétences de la Tâche 1, c'est acquérir du **A2**, et ça ne dit rien du B2. Un
candidat qui vise le B2 doit aller chercher EE3/EO3.

Et ce palier **pilote déjà une décision** : `PlanAcquisitionSelector` ne propose
« à acquérir » que des compétences **du palier que le domaine construit**
(`PlanDomainTargetLevelResolver`, autorité unique). C'est le seul endroit du
système où le palier commande, côté expression.

Le serveur sait aussi, **par tentative**, le palier démontré : `level_reached`
(`A1_NON_ATTEINT…B2`), produit par l'appel 1 du correcteur, resitué face à
l'objectif du candidat par `SkillLevelProgressResolver` (situation + jauge à 3
crans). Depuis le contrat v5, une preuve manquante **abaisse** le palier d'un
cran — le garde-fou est déjà là.

Enfin, « acquis **jusqu'au** palier X » existe déjà… **mais seulement en CO/CE** :
`ComprehensionLevelResolver.niveauConsolide()` (A2→B1→B2 séquentiel), exposé en
`PlanDomainDto.consolidatedLevel` / `blockingLevel`. **Aucun équivalent EE/EO.**

### 3.2 Ce que le serveur NE sait PAS dire

**(a) « Acquise au A2 mais pas au B2 » est impossible à formuler.**
Une compétence n'a **qu'un** palier dans le référentiel. Il n'existe nulle part
de couple (compétence × palier) mesurable :

- `learning_plan_observations` — la table qui alimente l'état de maîtrise — a
  `skill_id`, `source_type`, `source_id`, `subject_id`, `observed`, `status`,
  `evidence`, `explanation`, `confidence`, `baseline`, `observed_at`. **Aucune
  colonne de niveau.**
- le moteur V4.2 (`progression/`), le seul capable de modéliser un palier,
  **l'interdit explicitement** sur une compétence : `ProgressionStateKey` exige
  un `level` sur `RECEPTIVE_LEVEL` (`CO:A2`) et **le refuse** sur
  `PRODUCTIVE_SKILL` (`EE:EE2-C3`). Et il est en SHADOW, son pont refusant
  EE/EO.

Le palier est un attribut du **contenu**, jamais une dimension de la **mesure**.

**(b) Aucun agrégat « meilleur niveau atteint » sur une compétence.**
`level_reached` vit dans `user_skill_attempts.analysis_json` (jsonb non indexé),
une valeur par tentative. Aucun service ne l'agrège, aucun DTO ne l'expose hors
du résultat immédiat, et il n'entre dans **aucun** calcul d'état.

**(c) « Acquis » n'existe pas, et `SOLID` ne peut pas en tenir lieu.**
C'est le nœud. `SOLID` exige **quatre conditions simultanées** — score ≥ 0,75,
≥ 2 observations positives, ≥ 2 sujets distincts, et surtout :

> au moins une observation venue d'une **production contextualisée**, jamais
> d'un micro-entraînement seul

Autrement dit : **on ne devient pas `SOLID` en faisant des petits sujets.** Il
faut avoir rendu une production complète sur laquelle le correcteur a vu cette
compétence. Or la maquette marque la compétence « acquise » avec ses 5 petits
sujets faits, **sans** production complète. Les deux lectures se contredisent
frontalement.

**(d) Deux compteurs de la maquette sont trompeurs tels quels.**
`PlanDomainTaskDto.observedSkills` compte les compétences ayant **au moins une
observation, échec compris** — c'est une couverture, pas une réussite. Et sur
EE3 il **mélange les paliers** (3 B1 + 5 B2) : « 4/8 » ne dit pas lesquels.

**(e) Valider les sujets ne prouve pas un palier.**
`SkillCriterionStatus` (`VALIDATED / PARTIAL / NOT_VALIDATED`) est **hors CECRL
par conception** : les rubriques disent qu'un critère est validé « en A2 comme
en B2 ». Valider les 15 sujets d'une compétence B1 ne démontre pas le B1.

### 3.3 Quatre façons de trancher

#### Option A — « Acquis » = l'étape est réussie (lecture littérale de la maquette)

« Acquise » = les 5 sujets de l'étape sont `VALIDATED`.

- **Coût : nul.** `stepValidatedCount / stepPromptCount` est déjà servi.
- **Le palier** vient de `skills.target_level` : « acquise » sur EE1 = « au A2 ».
- **Le risque, réel** : c'est le défaut que le dépôt nomme *« NON FRAGILE ≠ PLUS
  RIEN À APPRENDRE »*. Cinq micro-exercices de 15 à 35 mots ne prouvent pas
  qu'on sait le faire en production. Le moteur dit non, l'écran dirait oui.
- **Atténuation** : dire « **Série terminée** » ou « **Travaillée** » plutôt
  qu'« Acquis ». Même information, sans la promesse.

#### Option B — « Acquis » = `SOLID`

- **Coût : nul** — `masteryState` est déjà servi sur `SkillDto`.
- **C'est honnête**, et c'est déjà la règle qui sort une compétence des
  priorités du Plan.
- **Le risque** : presque aucune compétence ne sera « acquise » avant plusieurs
  productions complètes. Un écran où les 8 restent « En cours » pendant des
  semaines ne reflète pas le travail fourni et décourage.

#### Option C — dire les deux (ma recommandation)

Ce sont deux faits différents, et le candidat a besoin des deux :

```
Adapter le message au destinataire
Série terminée · 5/5        ← ce qu'il a fait    (étape, déjà servi)
[Acquis · A2]               ← ce qui est prouvé  (SOLID + skills.target_level)
```

- 5 sujets faits sans production complète → **« Série terminée »**, pas de
  pastille verte ;
- `SOLID` → **« Acquis · A2 »**, le palier venant de la compétence ;
- compteur de tâche : « **3/8 acquises · 5/8 travaillées** », ou « 3/8
  compétences acquises » en ne comptant que les `SOLID`.

**Coût : nul en base.** Tout est déjà servi — c'est une question de libellés et
de ce qu'on compte.

#### Option D — le palier réellement démontré (plus cher, plus juste)

Pour dire « acquise **au B1** » sur une compétence étiquetée A2 (le candidat
écrit mieux que le sujet ne demande), il faut agréger `level_reached` :

1. colonne `user_skill_attempts.level_reached` (aujourd'hui noyée dans
   `analysis_json`) — migration **additive** + backfill lisible depuis le JSON ;
2. dérivé `SkillDto.levelReached` = meilleur palier démontré, calculé à la
   lecture (jamais persisté, comme le reste) ;
3. ou, plus solide : `level_reached` sur `learning_plan_observations`, pour que
   le **moteur** conclue « SOLID au B1 » et non « SOLID ».

**Coût : 1 à 2 migrations + un resolver + les miroirs de DTO — 1 à 2 jours,
aucun appel LLM** (le palier est déjà produit et persisté, juste enfermé dans un
JSON).

### 3.4 Recommandation

**C maintenant, D plus tard si tu veux le palier démontré.** C ne coûte aucune
migration, ne fait pas mentir l'écran et ne décourage pas. D ne contredit pas C,
il l'enrichit.

### 3.5 Un détail à trancher en même temps

Le badge **« OBJECTIF B2 »** de `detail_tache.png` est posé sur la **Tâche 1**,
qui est une tâche **A2**. C'est l'objectif du *candidat*, pas le palier de la
tâche — mais posé là, il laisse croire que réussir cette tâche vaut B2. Soit
« **Palier A2** » (ce que la tâche enseigne), soit « **Votre objectif : B2** »
en toutes lettres.

---

## 4. QUESTION B — « Vous allez apprendre à : »

> *« Je pense qu'on n'a pas les infos sur cette partie. »*

**Confirmé : la donnée n'existe pas.** L'expression n'apparaît nulle part dans
le dépôt, et aucune colonne ne s'en approche.

### 4.1 Ce qu'une compétence porte aujourd'hui

`skills` a **douze colonnes**, pas une de plus : `id`, `section`, `task_code`,
`code`, `title`, `description`, `general_criterion`, `target_level`,
`display_order`, `is_active`, `created_at`, `updated_at`. Aucun `ALTER TABLE
skills ADD COLUMN` n'existe dans le dépôt, aucune table fille éditoriale.

Pour la compétence exacte de ta maquette (`EE1-C1`) :

- **`description`** — un **paragraphe** : « On n'écrit pas de la même façon à un
  ami, à un voisin, à un employeur ou à une administration. […] » → déjà affiché
  derrière la pastille ⓘ.
- **`general_criterion`** — une **phrase** : « Savoir choisir une formule, un ton
  et un niveau de politesse adaptés : ami, voisin, collègue, administration,
  responsable. » → déjà affiché dans « Critère travaillé ».

### 4.2 Pourquoi on ne peut pas les fabriquer à partir de l'existant

**Découper `general_criterion` sur les virgules** donne « ami », « voisin »,
« collègue », « administration », « responsable » : des **destinataires**, pas
des gestes. Rien à voir avec « Choisir tu ou vous ».

**Réutiliser les `unique_criterion` des sujets** donne, pour EE1-C1 :

- S1 : « Employer une salutation et un vouvoiement adaptés à une voisine que
  l'on connaît peu. »
- S2 : « Employer un ton amical et le tutoiement du début à la fin du message. »
- S3 : « S'adresser au propriétaire avec une formule d'appel formelle et le
  vouvoiement. »

14 mots, **collés au contexte du sujet** (la voisine, le propriétaire), et
redondants entre eux. Inutilisables comme puces de fiche.

**En revanche le bon format existe déjà en base**, un cran plus bas :
`skill_prompts.checklist` (jsonb, ajouté en V026) est **exactement** le registre
de la maquette — 2 à 4 items, 1 à 6 mots, impératif :

```json
EE1-C1-S1 : ["Saluez votre voisine", "Dites qui vous êtes", "Écrivez deux phrases"]
```

Mais elle est **attachée au sujet, pas à la compétence**, et **située** (« votre
voisine »). Agréger les 15 checklists d'une compétence donnerait ~45 items
redondants et contextualisés, pas 3 puces propres.

**Conclusion : c'est une nouvelle donnée éditoriale.** Le style cible est
démontrable (on a 720 exemples de checklists), le contenu ne l'est pas.

### 4.3 Ce que ça coûte

**Volume : 54 compétences** (48 EE/EO + 6 CO/CE) **× 3 puces = ~162 chaînes.**

Le chemin est entièrement balisé — **V026 est le précédent exact** (ajout d'une
colonne jsonb nullable sur cette famille de tables, avec sa doctrine : nullable,
dégradation propre côté fronts, complétude verrouillée par **test de seed**, pas
par le DDL).

1. **Deux migrations, pas une de plus** :
   `00_schema/Vxxx__skills_learning_points.sql` (`ADD COLUMN learning_points
   jsonb` nullable) et `300_tcf/competences/Vyyy__…` (`UPDATE … FROM (VALUES …)`
   par `code`, sur le modèle de V306).
   🛑 **Ne jamais réécrire `V300..V318`** : leur somme de contrôle Flyway est
   déjà jouée.
2. **Générateur** — `tools/competences/generer_seed.py` : clé `learningPoints`
   dans les 6 fiches `contenu/*.json`, assertion `len == 3` et `1 ≤ mots ≤ 6`
   (symétrie exacte avec la règle checklist déjà en place), émission SQL.
   ~30 lignes.
3. **Backend** — `Skill`, `SkillDto`, `SkillDetailDto`, `AdminSkill*`, mappers,
   validation.
4. **Admin** — le patron existe déjà : `SkillPromptFormModal.tsx` a un
   `useFieldArray` avec monter/descendre/supprimer et compteur de mots. C'est un
   copier-adapter dans `SkillFormModal.tsx`.
5. **Fronts** — carte de résumé mobile + web, avec dégradation si `null`
   (doctrine V026 : « jamais de carte vide »).
6. **Test** — étendre `SkillSeedIT` : 54 compétences, exactement 3 items, ≤ 6
   mots. C'est ainsi que ce dépôt verrouille la complétude éditoriale.

**≈ 2 jours d'ingénierie + 0,5 jour de relecture.** Le risque n'est pas
technique, il est éditorial.

⚠️ **Et la spec est à amender** : `docs/skills/SEJOURFR_SPEC_COMPETENCES_EE_EO.md`
§3 « Niveau 4 — Une compétence » énumère **exhaustivement** ce que l'écran
affiche (titre, courte explication, critère général, progression, liste des
sujets, statut de chaque sujet). Ce bloc est **hors spec**.

### 4.4 Trois façons de produire les 162 puces

| | Comment | Coût | Qualité |
|---|---|---|---|
| **B1** | Tu les écris dans les 6 JSON | 1–2 j | La meilleure |
| **B2** | Script LLM **hors production**, 1 appel par compétence, sortie relue puis figée dans le JSON | 54 appels, quelques centimes | Bonne si relue |
| **B3** | On n'affiche pas le bloc tant qu'il est vide | 0 | La carte perd sa moitié haute |

**Recommandation : B2 relu par toi.** Le prompt disposerait d'un contexte
inhabituellement riche et déjà structuré — `title` + `description` +
`general_criterion` + les 15 `unique_criterion` + les ~45 items de `checklist`
de la compétence. Le modèle a donc à **généraliser**, pas à inventer, et le
style cible se démontre par quelques exemples tirés des checklists existantes.

🛑 **Je ne lance rien sans ton feu vert explicite**, et je te donnerai le coût
estimé avant (règle du dépôt : aucun appel LLM payant sans demande).

### 4.5 La ligne « ☰ 5 petits sujets · ⏱ ≈ 5 min »

- **« 5 petits sujets »** : servi, aucune question — `stepPromptCount` en vue
  étape (5), `promptCount` en fiche complète (15).
- **« ≈ 5 min » : aucune durée n'est servie sur une compétence ni sur un sujet.**
  Le calcul existe pourtant, centralisé dans `util/ExerciseDuration` : écrit =
  `(min+max)/2 ÷ 12 mots/min`, oral = `secondes × 3 ÷ 60`, replis **4 min**
  (écrit) et **5 min** (oral). Il n'est exposé que par
  `PlanRecommendedExerciseDto.estimatedMinutes`.

  ⚠️ **Et le chiffre de la maquette ne colle pas.** Les 5 sujets de l'étape
  EE1-C1 (15-35, 15-35, 25-45, 30-55, 40-70 mots) font **3+3+3+4+5 = 18 min**
  calculées. « ≈ 5 min » est le **repli oral** d'`ExerciseDuration` — donc le
  temps d'**un** sujet, pas des cinq.

  Trois options : **(1)** exposer `estimatedMinutes` sur `SkillDto` (le calcul
  existe, zéro requête de plus) et écrire la vraie somme — « ≈ 18 min » ;
  **(2)** afficher le temps d'**un** sujet — « 5 petits sujets · ≈ 4 min
  chacun » ; **(3)** ne rien afficher.
  Je penche pour **(2)** : c'est ce que la maquette montre, et c'est le chiffre
  qui décide le candidat à commencer.

---

## 5. Décisions attendues

| # | Question | Bloque | Ma reco |
|---|---|---|---|
| 1 | « Acquis » = `SOLID`, = 5/5 validés, ou les deux affichés ? (§3.3) | les 3 écrans | **Option C** |
| 2 | Palier à côté d'« Acquis » : celui de la compétence, ou rien ? | tâche + compétence | celui de la compétence |
| 3 | Badge Tâche 1 : « OBJECTIF B2 » ou « PALIER A2 » ? (§3.5) | détail tâche | « Palier A2 » |
| 4 | « Vous allez apprendre à » : B1 / B2 / B3 ? (§4.4) | détail compétence | **B2**, relu par toi |
| 5 | « ≈ 5 min » : somme réelle, temps d'un sujet, ou rien ? (§4.5) | détail compétence | temps d'un sujet |

Dès que **1–3** sont tranchés, je livre les deux premiers écrans. Le troisième
suit avec **4–5**.

**Ce que je ferai dans tous les cas, sans attendre** : renommer l'onglet
« Sujets d'examen » en « **Sujets complets** » (maquette) — libellé gelé, donc
web + mobile dans la même passe.
