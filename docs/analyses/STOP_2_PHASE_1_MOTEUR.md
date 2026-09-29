# STOP 2 — Phase 1 (moteur) terminée

> Répond au **§24 / STOP 2** du brief. **Backend uniquement. Aucun DTO modifié, aucun front touché.**
> Tests : **2767 unitaires + 1040 intégration, 0 échec** (`./mvnw verify`).
> 🛑 J'attends un GO avant la Phase 2 (DTO / API).

---

## 1. Le résultat sur le compte de test

Compte `1a55f230-…` (diagnostic `fe35354d`), objectif **NAT → B2**, tel que la base le porte :
**EE = A2** (3 fragilités), **EO = B1** (0 fragilité, 8 compétences solides), CO/CE non évaluées.

| | Avant | Après |
|---|---|---|
| Palier construit par l'**EE** | B1 *(cran au-dessus du plancher global A2)* | **B1** *(cran au-dessus de son propre A2)* |
| Palier construit par l'**EO** | B1 *(le plancher global, alors qu'il est déjà B1)* | **B2** ✅ |
| Actions dans le **pool** | 5 (3 fragilités + 2 acquisitions) | **15** (3 + 6 EE B1 + 6 EO B2) |
| Carte d'épreuve **EO** | **0 action**, « rien à travailler » | **6 « À acquérir » au palier B2** ✅ |
| Carte d'épreuve **EE** | 5 | **9** |
| Acquisitions réelles servies / disponibles | 2 / 10 | **12 / 12** |

Les compétences que l'EO reçoit désormais, nommées : `EO3-C2`, `EO3-C4`, `EO3-C5`, `EO3-C6`,
`EO3-C7`, `EO3-C8` — les six compétences B2 de la tâche 3 jamais travaillées. Côté EE :
`EE2-C1`, `EE2-C4`, `EE2-C6`, `EE2-C8`, `EE3-C2`, `EE3-C4`.

**Verrouillé par un test d'intégration** qui rejoue ce compte ligne pour ligne :
`LearningPlanAcquisitionIT.unOralPlusAvanceQueLEcritRecoitQuandMemeSesAcquisitions` —
il vérifie les trois maillons : la carte d'oral n'est plus vide, ses acquisitions sont **au
palier B2** (le sien, pas celui du plancher), et l'écrit garde ses fragilités **plus** ses
propres acquisitions B1.

### ⚠️ Un point à arbitrer, visible seulement maintenant

« Mes priorités » (5 lignes) et « Aujourd'hui » (3) restent **entièrement écrits** sur ce
compte. C'est le classement qui le veut : une fragilité pèse plus qu'une acquisition, et l'EE
est `FORTE` quand l'EO est `PAS_ENCORE_PRIORITAIRE`. Le §12 est un **maximum** d'un domaine
secondaire, pas un minimum — donc trois actions écrites en tête est conforme.

**Conséquence** : le candidat voit ses actions d'oral **sur la carte d'épreuve**, pas dans sa
séance du jour. C'est déjà l'essentiel du correctif, mais si vous vouliez que l'oral entre
aussi dans « Aujourd'hui », il faut un **plancher de diversité** (« au moins 1 secondaire
quand il en existe »), qui est l'inverse du §12. Un mot et je l'ajoute — c'est un
`display.todayMinSecondaryDomainActions` dans la même config.

---

## 2. Ce qui a été construit

### Nouveaux composants

| Fichier | Rôle |
|---|---|
| `service/PlanDomainTargetLevelResolver.java` | **LE palier d'un domaine.** Appelle `ProgressionPlanBridge.prescriptionLevel`, retombe sur « cran au-dessus du niveau **du domaine**, plafonné par l'objectif ». |
| `service/PlanContentAvailability.java` | **Filtre de faisabilité §8**, 2 requêtes agrégées, 2 branches (sujets / stock de questions). Logue chaque coupe. |
| `service/PlanActionRanker.java` | **Classement + composition §11/§12.** Aucun poids en dur, aucune horloge, première place épinglée. |
| `service/plan/PlanConfig{,Loader,Provider}.java` + `resources/plan/plan-config-v1.json` | La config **distincte** de `progression-config`. |
| `config/PlanProperties.java` | `sejourfr.plan.config-version` — la seule clé YAML. |
| `service/diagnostic/DiagnosticStatusDistributionMetrics.java` | Le compteur EE/EO × statut demandé pour §28. |

### Ce qui a changé dans l'existant

- `LearningPlanPriorityResolver.actionable` — **plus aucun plafond** (`MAX_PRIORITIES` supprimé).
- `PlanAcquisitionSelector.select` — **plus de budget**, palier **par domaine**, filtre §8.
- `LearningPlanService` — pool complet → faisabilité → classement → composition → troncature ;
  `natures` posé depuis le **pool**, plus depuis la liste tronquée (c'était la cause directe de
  l'écran vide) ; exercices résolus **seulement pour les cartes affichées**.
- `PlanSeanceBuilder` — `MAX_ITEMS` remplacé par `display.todayMaxActions`.
- `PlanFocusResolver` — applique le même filtre §8 que le Plan (sinon le freemium ouvrirait
  une compétence sans contenu).

---

## 3. Les arbitrages, appliqués tels quels

| Décision | Ce qui a été fait |
|---|---|
| **C.1 — une seule autorité : le pont** | `PlanDomainTargetLevelResolver` appelle le pont **avant** tout repli, et un test le vérifie (`leMoteurALaMainQuandIlRepond`). Le pont **reste SHADOW**, son extension à EE/EO n'est pas dans ce lot. Aucun `nextTargetLevel` dans `PlanCycleResolver`. |
| **C.2 — `plan-config` distinct** | Fichier séparé, clé `planConfigVersion`, invariant écrit dans les deux javadocs : *`plan-config` ne peut RIEN influencer du calcul de maîtrise*. Le mapping `nextTargetLevel` **n'y est pas** — doctrine, pas réglage. |
| **Filtre §8 avec métrique** | `log.warn` nommant les compétences coupées à chaque coupe. |
| **Contradiction #3** | **Tranchée : 21 requêtes**, fixe et assumé, `isEqualTo(21)` dans `LearningPlanCycleIT`. L'égalité petit/grand jeu de données reste le garde-fou anti-N+1. |
| **Sticky Today** | Rien ajouté. Le classement n'a **aucune horloge** (test `leClassementEstDeterministe`). |
| **Freemium** | Aucun code. Déjà conforme. |

---

## 4. §28 — la vérification que vous aviez demandée

**Ce n'est pas structurel.** Le `tool-schema` du diagnostic est un **fichier unique** pour les
deux modalités, et il autorise les quatre statuts (`NOT_OBSERVED`, `PRIORITY`, `TO_REINFORCE`,
`SOLID`) sans distinction. Les rubriques demandent explicitement « au plus **deux compétences
prioritaires** sur cette production ». La seule consigne propre à l'oral porte sur ce que le
correcteur **ne peut pas entendre** (prononciation, débit, intonation), jamais sur les verdicts.

Donc **0 `PRIORITY` sur 57 observations orales est comportemental**, pas empêché par le
contrat. Compteur posé (`DiagnosticStatusDistributionMetrics`, clés `TCF_EO:SOLID`…), à relire
vers **N ≈ 100**. Il ne décide de rien et n'entre dans aucun calcul.

---

## 5. Tests

| Fichier | Ce qu'il verrouille |
|---|---|
| `PlanDomainTargetLevelResolverTest` (8) | palier par domaine, pas de saut, plafond objectif, **priorité du pont** |
| `PlanActionRankerTest` (7) | réparer avant apprendre, urgence, **cap de domaine secondaire**, pas de diversité forcée, **première place épinglée**, déterminisme |
| `PlanContentAvailabilityTest` (4) | les 2 branches, et le piège « palier manquant en compréhension » |
| `plan/PlanConfigLoaderTest` (5) | exhaustivité des tables, ordre de la doctrine, échec bruyant |
| `PlanAcquisitionSelectorTest` (13) | **chaque domaine son palier**, domaine secondaire servi, domaine avancé qui ne redescend pas, un seul lot de requêtes |
| `LearningPlanAcquisitionIT` | **le compte réel du 2026-08-25** |
| `LearningPlanServiceTest` | le budget supprimé ; ce qui dépasse le plafond garde sa nature sur la carte |
| `LearningPlanCycleIT` | **21 requêtes**, et l'égalité anti-N+1 |

---

## 6. Documentation déjà mise à jour

- `docs/regles/plan.md` — nouvelle section « Progression PAR ÉPREUVE, confirmation GLOBALE »,
  et la règle du palier corrigée là où elle disait « palier du cycle ».
- `docs/decisions/contradictions-ouvertes.md` — **#3 tranchée**.

`CLAUDE.md` (les trois invariants du §3) reste pour la **Phase 6**, avec le front.

---

## 🛑 STOP 2

Le moteur est fait, mesuré et verrouillé. **Rien n'est commité.**

Il me faut un GO pour la Phase 2 (DTO / API : `acquireCount`, `readyForValidationCount`,
autorité serveur sur `notObservedSkillCount`) — et, si vous le voulez, une réponse sur le
**plancher de diversité** du §1.
