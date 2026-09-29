# AUDIT — Plan civique : **le même moteur et le même écran** que le TCF

> **Demande du propriétaire, 2026-09-19** : « pour le menu plan, civique ça ne ressemble pas du tout
> au TCF, on doit avoir les mêmes écrans des 2 côtés ; la partie TCF ne touche pas, c'est bon. Il
> faut juste adapter l'écran plan de l'examen civique. » Puis, après arbitrage : **attendre le
> moteur**, et « je veux le même mode de fonctionnement, **moteur et écran**, tout pareil si
> possible ».
>
> 🛑 **Ce n'est pas une nouvelle demande** : `SPEC_cycle_plan_civique.md` §4 s'intitule déjà
> « Écrans — **strictement identiques au TCF** ». Cet audit dit ce qui **manque** pour y arriver,
> ce qui est **déjà fait**, et les **6 décisions** que « tout pareil » force à prendre.
>
> Marqueurs de chiffre : ⟦CODE⟧ = lu dans le dépôt, avec le fichier. Les numéros de ligne sont ceux
> du commit `7497a513` — vérifier par `grep`, pas par `sed -n`.

---

## 1. Le constat mesuré — pourquoi les deux écrans ne se ressemblent pas

⟦CODE⟧ Ils ne lisent pas les mêmes choses, et ils n'ont pas le même nombre de sections.

| | **Plan TCF** | **Plan civique** |
|---|---|---|
| Endpoints servis | **deux** : `GET /api/me/plan` (`LearningPlanDto`) **+** `GET /api/me/plan/journey` (`JourneyDto`) | **un** : `GET /api/me/civic-plan` (`CivicPlanDto`) |
| Vue mobile | `widgets/plan_tcf_view.dart` (441 l.) + `widgets/plan_cycle_section.dart` (413 l.) | `civic_plan_view.dart` (536 l.) |
| Vue web | `LearningPlanView.tsx` (502 l.) + `PlanCycleSection.tsx` (455 l.) | `CivicPlanPanel.tsx` (497 l.) |
| Sections (abonné) | **6** | **8** |
| Le cycle en blocs | ✅ `BlocAccordion` + lignes d'étape + encart d'examen | ❌ **absent** |
| La bande objectif | ✅ `GoalStrip` (niveau actuel → objectif) | ❌ absente |

**Les 6 sections du TCF**, dans l'ordre (`plan_tcf_view.dart:93`) : `Top` · bande objectif ·
**À faire maintenant** · **le cycle en blocs** · le jalon · les liens (« Ma progression », « Mon
diagnostic »).

**Les 8 du civique** (`civic_plan_view.dart:144`) : `Top` · carte de contexte (2 pastilles) ·
**À faire maintenant** · **Votre parcours — *notion*** (les 5 étapes Leitner de la notion en cours)
· **Vos priorités** · **Déjà travaillé et validé** · **À revoir bientôt** · **Progression détectée**.

### 🛑 Quatre de ces sections ont été RETIRÉES du TCF par le propriétaire

Elles ne sont pas « en plus » côté civique : elles sont **en retard**. ⟦CODE⟧
`plan_tcf_view.dart:30-41` porte les deux arbitrages, datés :

- **2026-09-19** — « Déjà travaillé et validé », « Progression détectée », la carte du diagnostic
  complet en cours, « Toutes mes compétences », « Mes examens blancs » et « Revoir mon diagnostic
  rapide » : **supprimés**. Sous le cycle il ne reste que « Ma progression » et « Mon diagnostic ».
- **2026-09-18** — « Vos priorités pour atteindre … » : **supprimé**, parce qu'il *« disait la même
  chose que les blocs d'épreuve du cycle, en moins précis — mêmes compétences, sans leur position
  dans le cycle, sans leur examen, et plafonné à trois groupes »*.

⚠️ **Le second motif vaut mot pour mot côté civique** : « Vos priorités » y est plafonné à 3 et
laisse « + 14 autres notions à consolider » — exactement le symptôme visible sur la capture.

### ⚠️ Une rupture de parité web ⇄ mobile mesurée au passage, aujourd'hui

⟦CODE⟧ La **même carte de contexte** n'affiche pas les mêmes faits :

| | Pastille 1 | Pastille 2 |
|---|---|---|
| Mobile (`civic_plan_view.dart:231`) | « **4 thèmes à renforcer** » | « 17 notions à consolider » |
| Web (`CivicPlanPanel.tsx:166`) | « 17 **à consolider** » | « 3 **à revoir bientôt** » |

Elle disparaît si la carte est remplacée par la bande objectif du TCF (§5, décision **C**) — mais
elle est réelle, et c'est le genre d'écart que la parité doit attraper.

---

## 2. Pourquoi l'écran civique ne PEUT PAS afficher les blocs aujourd'hui

Le cycle n'est pas une mise en page : c'est une **donnée servie**. ⟦CODE⟧ `PlanCycleSection` sort
en `SizedBox.shrink()` dès que `journey == null` (`plan_cycle_section.dart:84`), et un candidat
civique n'a **jamais** de `journey` :

1. `JourneyService.getOrCreate` est câblé `Module.TCF` en deux endroits (~l.156-182) ;
2. `journey_assessment_event` **refuse** une évaluation civique par deux `CHECK`, et l'échec serait
   **silencieux** (`DETTE-M1`) ;
3. le point de branchement `porterAuParcours` ne voit pas passer le civique.

C'est **P8.4**, et son état exact — ce qui est en place, ce qui manque, fichier et ligne — vit dans
`docs/progression/civique/REPRISE-P8.4-MOTEUR.md`. **Cet audit ne le redit pas.**

---

## 3. Ce qui est DÉJÀ générique — ne pas le refaire

✅ Beaucoup du travail « tout pareil » est **fait**, et c'était l'objet de la passe du bloc servi.

| Acquis | Où | Ce que ça donne |
|---|---|---|
| **Le bloc servi** `{kind, code, label}` (**D-47**, A47-A48) | `JourneyBlocRefDto` ⇄ `types.ts` ⇄ `journey_models.dart` | un front affiche un bloc **sans savoir de quel module il parle** |
| Les accesseurs d'entité `blocRef()` / `poserBloc()` / `uniteLabel()` / `poserUnite()` | `JourneyStep`, `JourneyLot` | les 57 occurrences d'`EpreuveType` du moteur traitées **à la source** |
| `JourneyBlocDto` · `JourneyCycleDto` · `JourneyNextStepDto` | `dto/` | **déjà neutres** (sauf un nom, §4.4) |
| **Les 4 primitives de cycle, des deux côtés** | `CycleProgress` · `BlocAccordion` · `ExamStepBox` · `NextStepCard` (+ `JourneyRow`, `NowCard`, `GoalStrip`) | le kit n'est pas à écrire, il est à **étendre** |
| Le filtre d'évaluation civique (R3) | `JourneyEvaluationFilter` : `CIVIQUE_SERIE → false`, `CIVIQUE_EXAMEN → true` | la gratuité ne fausse pas le cycle |
| L'observation civique en base | V070 : `official_unit_id`, 2 sources, index jumeau | **D-49** peut s'écrire |

🛑 **Corollaire** : l'écran civique ne se code pas « à côté » du TCF. Il consomme **le même
contrat**, ou l'exercice n'a servi à rien.

---

## 4. Ce qu'il reste à rendre générique — **4 contrats**, et c'est tout

### 4.1 🛑 L'objectif du cycle — le dernier champ typé TCF du `JourneyDto`

⟦CODE⟧ `JourneyDto.targetLevel` est un **`TargetLevel`** (`JourneyDto.java:33`). L'objectif civique
est une **`TargetProcedure`**, et `chk_journey_objectif` (V069) exige **exactement un** des deux en
base. Le DTO ne peut donc pas servir un cycle civique.

**Le geste est déjà connu** : c'est celui du bloc. Un **objectif servi**
`{ kind: NIVEAU | PROCEDURE, code, label }`, que les deux fronts affichent sans brancher.
`targetLevel` reste servi pour le TCF tant que d'autres écrans le lisent — additif d'abord,
suppression de l'ancien **dans la même passe** dès que le dernier appelant est converti.

### 4.2 L'unité travaillable d'une étape

⟦CODE⟧ `JourneyStepDto` porte **6 champs TCF** : `section`, `taskCode`, `skillCode`, `skillTitle`,
`assessment`, `exercise` (`JourneyStepDto.java:44-128`). Une étape civique porte une **unité
officielle** et aucun `Skill`.

Même geste : une **unité servie** `{ label, code }` — les entités l'exposent déjà
(`uniteLabel()` / `uniteId()`), il ne reste qu'à la faire remonter au DTO. Les champs TCF **restent**
pour ce qu'ils servent ailleurs (la séance, l'exercice recommandé, le correcteur).

### 4.3 L'endpoint — **une** route ou **deux** ?

⟦CODE⟧ `GET /api/me/plan/journey` n'a **pas** de paramètre de module. Deux voies, et c'est la
décision **A** du §5.

### 4.4 Un nom

⟦CODE⟧ `JourneyBlocDto.competencesRestantes` : une thématique ne compte pas des *compétences*. Le
champ est juste, son nom ment côté civique. À renommer (`etapesRestantes`), les 3 miroirs dans la
même passe.

---

## 5. **Les 6 décisions** que « tout pareil » force — à trancher avant P8.7

> Trois sont techniques et je peux les recommander. **Trois engagent ce que le candidat lit** : elles
> remontent, conformément à la règle de la passe.

### A — Un seul contrat de cycle, ou deux ? *(technique)*

- **A1 — `GET /api/me/plan/journey?module=CIVIQUE`** ⭐ *recommandé.* Un contrat, un écran, une
  règle. C'est la doctrine « une règle = une autorité » appliquée au contrat lui-même, et le
  prolongement direct de D-47. Le toggle de module **existe déjà** dans l'URL et nulle part ailleurs
  (spec §4), il alimenterait aussi cet appel.
- **A2 — un endpoint civique jumeau.** Découplage total, mais **deux contrats à faire vivre** : la
  prochaine évolution du cycle se fait deux fois, et on connaît le prix des copies dans ce dépôt
  (table des paliers en 6 copies).

### B — Une seule vue de cycle, ou deux ? *(technique)*

⭐ *Recommandé* : `PlanCycleSection` (web **et** mobile) devient **commune**, parce qu'après D-47
elle ne lit plus que des faits servis. Ce qui reste propre à chaque module — la carte d'action, les
liens du bas, l'amorce, le plan dérivé civique — reste dans sa vue. ⚠️ À vérifier avant de s'engager :
`plan_cycle_section.dart` importe encore `fullExamsHistoryProvider` et `plan_now_card` — deux
dépendances TCF à isoler.

### C — 🛑 Que dit la **bande objectif** côté civique ?

Le TCF affiche « niveau actuel → objectif » (`A2 → B2`). Le civique n'a pas de palier CECRL. Trois
lectures possibles, **et elles ne promettent pas la même chose** :

1. **mention visée + seuil** (« CSP · seuil **80 %** ») — un fait du référentiel, aucune promesse ;
2. **score d'entrée → seuil** (« 29/40 → 32/40 ») — `entry_score` existe en base (V069), mais
   afficher un score **le transforme en verdict**, et l'arrêté ne dit rien d'un score d'entrée ;
3. **rien** — pas de bande, l'écran commence par « À faire maintenant ».

⚠️ Je ne tranche pas : la 2 affiche un chiffre que le candidat lira comme **son niveau**.

### D — 🛑 La carte « À faire maintenant » **change de source**

⟦CODE⟧ Aujourd'hui elle vient du plan **dérivé** (`CivicPlan.prochaine`). Côté TCF elle vient de
l'**étape servie du cycle** (`plan_now_card.dart:460`, `JourneyStep`), et `JourneyDto` porte cette
exigence noir sur blanc : *« une seule réponse alimente la carte **et** la timeline »* — c'est ce qui
a supprimé, le 2026-09-16, la contradiction où l'Accueil annonçait une action et le Plan une autre.

⇒ Le jour où le cycle civique existe, la carte **doit** passer au cycle, sinon le Plan civique
s'autorise deux autorités. **Effet visible** : la carte peut nommer **autre chose** qu'aujourd'hui
pour le même candidat au même instant. C'est un changement de ce que le candidat lit comme sa
prochaine action — **arrêt, arbitrage du propriétaire**.

### E — 🛑 Les 4 sections du plan dérivé **disparaissent-elles** comme côté TCF ?

« Vos priorités », « Déjà travaillé et validé », « À revoir bientôt », « Progression détectée ».

Le motif de leur retrait côté TCF s'applique (§1). **Mais** : côté civique, elles portent le
**Leitner** (`aRevoir`), que le cycle **ne porte pas** — D-49 a explicitement posé deux autorités,
et `CivicLeitnerResolver` « dit la condition présente » là où l'observation « clôt l'étape du
cycle ». Supprimer « À revoir bientôt » sans que le cycle le reprenne **perdrait un fait**.

⚠️ À vérifier avant de supprimer quoi que ce soit : chaque fait retiré a-t-il un **foyer** ?
`CivicPlan.themes` alimente déjà l'écran **Réviser** ⟦CODE⟧ — c'est un bon signe, pas une preuve.

### F — 🛑 Le **grain** affiché : notion ou unité officielle ?

L'écran actuel dit « notions » (« 17 notions à consolider », « + 14 autres notions »). **D-48**
trancherait : *à l'écran, l'autorité est l'**unité officielle*** — on affiche le libellé officiel, pas
le vocabulaire interne. Or les deux ne coïncident pas : **46 notions ↔ 16 unités**, et la spec dit
déjà que `notion` ne doit **jamais** apparaître à l'écran (§4, vocabulaire).

⇒ Le passage au cycle change donc aussi **ce qu'on compte** dans les pastilles et les compteurs de
bloc. À dire explicitement, parce que le candidat verra un nombre **baisser** (17 → au plus 16, et en
pratique moins).

---

## 6. L'ordre de travail, et ce que chaque phase livre **à l'écran**

| Phase | Ce qu'elle livre côté moteur | Ce qui devient visible |
|---|---|---|
| **P8.4** — moteur | V071, `getOrCreate` par module, amorce, blocs sur `themes.display_order`, écrivain d'observation, `etapesAuQuota` par unité, branchement | rien encore : `journey` existe, l'écran ne le lit pas |
| **P8.5** — freemium | `enforceMockExamSlotAccess` hors du chemin civique | les verrous servis deviennent justes |
| **P8.6** — kits | `BlocAccordion` sans initiale (une thématique n'en a pas, **A49**), **dans les deux kits, même passe** | l'en-tête de bloc civique devient affichable |
| **P8.7** — écrans | les 4 contrats du §4, puis les deux vues | **l'écran demandé** |
| **P8.8** | les 11 questions de Laïcité | ⛔ arrêt éditorial avant écriture |
| **P8.9** | historique des cycles | ⛔ bloquée — template non fourni |

🛑 **Les décisions C, D, E, F se prennent avant P8.7, pas pendant.** Elles changent ce que l'écran
affiche, donc elles changent ce qu'il faut coder — et trois d'entre elles engagent une promesse.

**Les contrats du §4 (A, B) peuvent se préparer pendant P8.4** : ils ne dépendent pas du moteur, ils
dépendent du fait qu'un cycle civique existe en base — ce que V069/V070 ont déjà livré.

---

## 7. Ce qui ne bouge pas

- 🛑 **Le TCF n'est pas touché** (exigence explicite du propriétaire). Toute généralisation est
  **additive** côté TCF, et se vérifie par `verify` + les deux fronts verts.
- 🛑 **Le plan civique dérivé reste dérivé** (**D-36**) : `service/plancivique/` n'est pas réécrit.
  Le cycle **se superpose**.
- 🛑 **`TcfDomainProfileDto.ORDRE`** reste l'autorité TCF (D-9, D-20) : l'axe civique s'ajoute
  **à côté**, il ne la remplace pas.
- 🛑 **Aucun nouveau test sur les fronts.** Vérification : `npx tsc --noEmit`, `npm run build`,
  `flutter analyze`.
- 🛑 **Les écrans passent par le KIT**, et une brique qui manque s'ajoute **dans les deux kits dans
  la même passe**.

---

## 8. Les risques, nommés

1. **Deux autorités sur l'action du jour** (décision D) — c'est le bug déjà payé le 2026-09-16, et il
   reviendrait par la porte du civique.
2. **« Le même écran » ≠ « le même contenu ».** Le civique n'a **pas** d'analyse IA (spec §3.2), pas
   de production, pas de sous-attempts. La carte d'action n'a donc pas les mêmes gestes, et
   `JourneyStepDto.assessment` / `.exercise` resteront **nuls**. Un écran commun doit traiter ces
   nuls comme **normaux** — *null = inconnu, jamais mauvais*.
3. **Le freemium civique n'a pas de ledger** (**D-33**) : le `locked` servi ne se calcule pas de la
   même façon. L'écran lit `locked`, il ne le déduit jamais d'un rang.
4. **Réintroduire un branchement par module dans un front** annulerait la passe du bloc servi. Le
   signal à surveiller : un `if (module === ...)` dans une vue de cycle.
5. **La numérotation des décisions autonomes** reprend à **A55** (A47 → A54 sont consignées).
