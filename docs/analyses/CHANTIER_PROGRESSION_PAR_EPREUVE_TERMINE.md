# Chantier « progression par épreuve » — terminé

> Les **six phases** du brief `BRIEF_CLAUDE_CODE_PROGRESSION_PAR_DOMAINE_v2.md` sont faites.
> `./mvnw verify` : **2771 tests unitaires + 1040 tests d'intégration, 0 échec**.
> `flutter analyze` : *No issues found*. `tsc --noEmit` + `next build` : OK.
> `verifier-contrat-front-progression.mjs` : conforme.
> **4 commits, poussés** sur `feature/progression-engine-v4-2`.

---

## Ce que le candidat voit maintenant

Compte `1a55f230-…`, objectif **B2**, **EE = A2** (3 fragilités) / **EO = B1** (0 fragilité) :

| | Avant | Après |
|---|---|---|
| Palier construit par l'EO | B1 *(le plancher global, alors qu'il est déjà B1)* | **B2** |
| Carte d'épreuve EO | **0 action**, « rien à travailler » | **6 « À acquérir » en B2** |
| Carte d'épreuve EE | 5 | **9** |
| Pool d'actions | 5 | **15** |
| Acquisitions servies / disponibles | 2 / 10 | **12 / 12** |
| « prochain palier » affiché | dérivé côté front, **sans plafond par l'objectif** | servi, exact |

---

## Les six phases

| Phase | Contenu | Commit |
|---|---|---|
| **0** | Audit — `AUDIT_PHASE_0_PROGRESSION_PAR_DOMAINE.md` | — |
| **1** | Moteur : palier par domaine, plus aucun plafond dans le calcul, filtre de faisabilité, classement + composition en config versionnée | `9cccbd9e` |
| **2 + 3** | DTO / API (4 champs servis) et les deux fronts, copies locales supprimées | `73ffc5b8` |
| **4** | Instrumentation du rideau freemium (3 événements) | `eed52350` |
| **5** | Audit notation §28 — **mesuré, pas corrigé** | `9cccbd9e` (compteur) |
| **6** | `CLAUDE.md` × 4 + `docs/regles/*` | `493eab10` |

---

## Definition of Done (§40)

**Moteur** — ✅ `nextTargetLevel` par domaine · acquisitions au palier du domaine · filtre de
faisabilité **avant** le ranking · tout calculé avant toute troncature · ranking et composition
pilotés par `plan-config-v1.json` · limites d'affichage appliquées **après**.

**Backend** — ✅ `PlanDomainDto` sert la vue complète et des compteurs exacts · fragilité /
acquisition / validation distinguées (`A_RENFORCER` / `A_ACQUERIR` / `A_VERIFIER`, enums
existants conservés) · tests §31-39 verts.

**Frontend** — ✅ « Mon diagnostic » affiche les vraies compétences par épreuve · contexte
épreuve · tâche déjà en place · Aujourd'hui / Mes priorités branchés sur le nouveau pool ·
mobile et web cohérents · compteurs freemium exacts et événements posés.

**Documentation** — ✅ les invariants du §3 sont dans `CLAUDE.md` racine · l'amendement §2 est
écrit et les affirmations contraires corrigées.

### Les tests du §31-39, un par un

| # | Test | Où |
|---|---|---|
| 1 | `EE=A2, EO=B1, obj=B2` → EE cible B1, EO cible B2 | `PlanAcquisitionSelectorTest`, `LearningPlanAcquisitionIT` |
| 2 | Niveau global reste `min(...)`, ne pilote plus les paliers | `PlanCycleResolver` inchangé |
| 3 | Aucune fragilité EO → acquisitions B2 quand même | `LearningPlanAcquisitionIT` |
| 4 | `NOT_OBSERVED` ne devient jamais `TO_REINFORCE` | `PlanDomainSkillResolverTest` |
| 5 | Domaine sous objectif porte ≥ 1 action **si elle existe** | `LearningPlanAcquisitionIT` |
| 6 | Domaine à l'objectif → pas d'acquisitions | `PlanDomainTargetLevelResolverTest` |
| 7 | Plafond UI : plus d'actions connues que servies, compteurs justes | `LearningPlanServiceTest` |
| 8 | Aujourd'hui ≤ 3, ≤ 1 domaine secondaire | `PlanActionRankerTest` |
| 9 | Carte d'épreuve indépendante des cartes sélectionnées | `LearningPlanServiceTest` |
| 10 | Sticky J+1 | `LearningPlanSeanceIT` (inchangé — aucune horloge n'a été ajoutée) |
| 11 | Gate mock sur la règle globale | `PlanCycleResolver` inchangé |
| 12 | Compétence sans contenu absente du pool et non comptée | `PlanAcquisitionSelectorTest`, `PlanContentAvailabilityTest` |
| 13 | Vérification non observante rejetée | **sans objet** — voir ci-dessous |
| 14 | Aucune valeur de ranking en dur | `plan/PlanConfigLoaderTest` |
| 15 | Non-abonné : même pool, masque en fin de chaîne | déjà le cas, `LearningPlanService` |

**§9 PATCH 2 (test 13) — sans objet, et c'est volontaire.** Le patch corrigeait un *fallback*
« Vérifier le niveau en situation » servi indéfiniment quand un domaine n'a plus rien. Ce
fallback **n'existe pas** ici : un domaine sans action n'en reçoit aucune, et c'est le gate
mock qui prend le relais. Le seul `A_VERIFIER` du dépôt est une **re-vérification d'une
compétence précise**, qui produit par construction une nouvelle observation sur elle. Ajouter
un garde-fou pour un cas qu'on n'a pas introduit aurait été du code sans lecteur.

---

## Deux choses à décider (aucune n'est bloquante)

### 1. « Aujourd'hui » reste mono-domaine sur ce compte

Le §12 est un **maximum** de domaines secondaires, pas un minimum. Une fragilité pèse plus
qu'une acquisition et l'EE est `FORTE` : les trois entraînements du jour sont écrits, et
l'oral vit **sur sa carte**. C'est conforme au brief.

Si vous vouliez l'oral aussi dans la séance, il faut un **plancher** de diversité
(`display.todayMinSecondaryDomainActions`), qui est l'inverse de la règle actuelle. Un mot et
c'est une ligne de config plus une condition dans `PlanActionRanker.composer`.

### 2. C.3 et C.4, laissées telles quelles

- **C.3 — noms de champs** : les enums existants (`A_RENFORCER` / `A_ACQUERIR` / `A_VERIFIER`,
  `status` / `masteryState` / `nature`) sont conservés. Renommer coûtait 3 surfaces et le test
  de libellés gelés pour zéro gain — le brief indiquait lui-même que ses noms étaient
  conceptuels.
- **C.4 — « votre plan construit d'abord votre B1 »** : la phrase du héros reste sur le
  **cycle global**, qui existe toujours ; chaque carte d'épreuve annonce désormais **son**
  palier (`nextTargetLevel`). Les deux ne se contredisent pas, mais la formulation du héros
  peut être revue si elle vous paraît ambiguë.

---

## Ce qui reste ouvert, hors chantier

- **Extension du pont V4.2 à EE/EO** — décidé « chantier séparé ». La couture est en place :
  `PlanDomainTargetLevelResolver` interroge déjà le pont, il suffira de lever le
  `!section.isComprehension()` et de passer en `ACTIVE`.
- **§28 / notation** — compteur posé, à relire vers **N ≈ 100**. Pas de garde-fou sur
  22 lignes.
- **Le rideau** — les trois événements sont posés ; la décision produit se prendra sur les
  chiffres, pas avant.
