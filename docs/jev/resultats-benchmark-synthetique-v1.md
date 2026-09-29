# Benchmark JEV — résultats synthétiques v1 (2026-09-29)

> Résultats **agrégés** du premier benchmark réel de JEV (TypeSafe, modèle renvoyé `jev-1.13.0`) sur
> **59 productions EE synthétiques actives** (aucune donnée de production). Outil : `tools/jev-benchmark/`
> (`python -m jev_bench report` régénère ces tableaux). Aucun texte de production n'est reproduit ici.
> Les deux versions de prompt ne sont **jamais mélangées** : une section chacune.

## Protocole

- **Cas** : 35 cas `synthetic_ee_v1` (conversation Playground, tous EE2, dont 31 hors bornes de mots) +
  24 cas `synthetic_ee_v2` conçus pour démontrer un niveau (2 par case EE1/EE2/EE3 × A1/A2/B1/B2, dans les
  bornes). `SYN2-EE1-B1-1` (noté B2 par SejourFR, marqueurs B2 involontaires) est **retiré** (conservé pour
  trace) et remplacé par `SYN2-EE1-B1-1b` (noté B1 7,5 par SejourFR).
- **Niveau visé** : intention de l'auteur du texte (annoncée dans la conversation, ou « conçu »), pas un avis
  d'examinateur. Visé double (ex. A2/B1) : lecture **stricte** (principal seul) et **souple** (l'un des deux).
  `null` (SYN-EE-014) = non comparable ; INSUFFICIENT hors de l'échelle ordinale.
- **JEV** : 6 questions `choice` par requête (niveau global A1…B2 + INSUFFICIENT, pertinence, 4 critères de la
  grille v15), state = consigne + contexte + production, **sans aucun niveau**. `--repeat 2`.
  - `jev-independent-v1` (**principal**) : options des critères = descripteurs CECRL de la spec (§19–22).
  - `jev-v15-aligned-v1` (**sensibilité**) : options des critères = échelle CECRL commune + descripteurs de tâche
    de la grille v15 (la v15 n'a aucun descripteur par critère). ⚠️ La question `niveau_global` est identique
    dans les deux versions.
- **SejourFR** : correcteur actuel (grille v15 / schéma v9, `deepseek-v4-flash`) via le backend local ; 28 cas
  comparables (notés, hors A1_NON_ATTEINT, hors HORS_SUJET JEV) ; les 31 cas hors bornes ne sont pas notables.
- Exclusions des taux : JEV pertinence HORS_SUJET (`SYN-EE-015`, conçu presque hors sujet) et SejourFR
  A1_NON_ATTEINT (aucun cas).

## Ce qu'il faut retenir

1. **JEV vs visé : 72 % exact strict, 82 % souple, 0 écart majeur**, identique sur les deux répétitions.
   Tous les désaccords sont **adjacents**.
2. **JEV resserre l'échelle vers le centre** : les textes conçus A1 sortent A2 dans 10 observations sur 16 (5 textes sur 8, cas × répétition),
   les B2 sortent B1 dans 10 observations sur 28 (5 textes sur 14) ; en sens inverse, 3 textes visés A2
   montent en B1. Les B1 sont presque toujours reconnus (36 observations sur 38).
3. **INSUFFICIENT** : reconnu seulement sur le cas quasi vide (`SYN-EE-019`) ; les cas « trop courts »
   (`SYN-EE-012`, `SYN-EE-018`) sortent A2 / A1, avec INSUFFICIENT à 0,44–0,48 sur le second.
4. **Stabilité excellente** : 59/59 labels identiques entre répétitions, variation moyenne des probabilités
   < 0,01, variation moyenne de confiance ≈ 0,02.
5. **SejourFR vs JEV : 21/28 exact (75 %), 7 adjacents, 0 majeur.** Sur ces 28 cas, SejourFR retrouve le niveau
   visé 28/28 : les 7 écarts sont les 5 A1 conçus (JEV A2), un B2 et un A2 (JEV B1). Biais possible : les
   textes v2 ont été écrits par l'auteur des niveaux visés et le cas B1 réécrit a été ajusté sur SejourFR.
6. **Sensibilité (v15-aligned)** : niveau global inchangé (contrôle), mais les critères deviennent plus
   **sévères** (morphosyntaxe ↓ 28 fois sur 118, jamais ↑). En secondaire, la formule SejourFR appliquée aux
   critères v15-aligned rejoint SejourFR sur **28/28** (variante argmax) et le visé à 81 %, contre 68 % et 65 %
   avec les critères indépendants.
7. **Coût réel : 0,0535 $** pour 237 requêtes (1 test + 2 × 118), 1 273 104 tokens d'entrée.

## `jev-independent-v1` — benchmark PRINCIPAL

Run `real-2026-09-29T214833Z-0e6179` · hash des questions `da11bd86ffc1…` · modèle(s) renvoyé(s) `jev-1.13.0` · 118 requêtes, 0 erreur(s) · 521512 tokens d'entrée, 37272 de sortie · **0.0219 $**

**Pertinence JEV** : r1 {'DANS_LE_SUJET': 55, 'PARTIEL': 3, 'HORS_SUJET': 1} ; r2 {'DANS_LE_SUJET': 55, 'PARTIEL': 3, 'HORS_SUJET': 1} — HORS_SUJET exclus des taux : SYN-EE-015

**JEV vs niveau visé**

| | strict (niveau principal) | souple (principal ou alternatif) |
|---|---|---|
| répétition 1 | exact 41/57 (72 %) · adjacent 14 · majeur 0 · INSUFFICIENT manqué 2 · non comparables 1 | exact 47/57 (82 %) · adjacent 10 · majeur 0 · non comparables 1 |
| répétition 2 | exact 41/57 (72 %) · adjacent 14 · majeur 0 · INSUFFICIENT manqué 2 · non comparables 1 | exact 47/57 (82 %) · adjacent 10 · majeur 0 · non comparables 1 |

| Tâche | strict r1 | souple r1 | strict r2 | souple r2 |
|---|---|---|---|---|
| EE1 | 6/8 (75 %) | 6/8 (75 %) | 6/8 (75 %) | 6/8 (75 %) |
| EE2 | 30/41 (73 %) | 36/41 (88 %) | 30/41 (73 %) | 36/41 (88 %) |
| EE3 | 5/8 (62 %) | 5/8 (62 %) | 5/8 (62 %) | 5/8 (62 %) |

**Matrice de confusion** (visé principal en ligne × JEV en colonne, 2 répétitions cumulées)

| visé \ JEV | A1 | A2 | B1 | B2 | INSUFFICIENT |
|---|---|---|---|---|---|
| **A1** | 6 | 10 | · | · | · |
| **A2** | · | 22 | 6 | · | · |
| **B1** | · | 2 | 36 | · | · |
| **B2** | · | · | 10 | 18 | · |
| **INSUFFICIENT** | 2 | 2 | · | · | 2 |

**Stabilité r1 / r2** : label identique 59/59 (100 %) · variation moyenne des probabilités 0.0072 (max 0.032) · variation moyenne de confiance 0.0195 (max 0.11)

**SejourFR vs JEV** (notés SejourFR, hors A1_NON_ATTEINT et HORS_SUJET)

- r1 : exact 21/28 (75 %) · adjacent 7 · majeur 0 — EE1 6/8 (75 %) ; EE2 10/12 (83 %) ; EE3 5/8 (62 %)
- r2 : exact 21/28 (75 %) · adjacent 7 · majeur 0 — EE1 6/8 (75 %) ; EE2 10/12 (83 %) ; EE3 5/8 (62 %)
- rappel SejourFR vs visé : strict exact 28/28 (100 %) · adjacent 0 · majeur 0 ; souple exact 28/28 (100 %) · adjacent 0 · majeur 0

**Désaccords JEV / visé** (strict, au moins une répétition ; distributions complètes du niveau global)

| cas | tâche | visé | SejourFR | JEV r1 (conf.) — probas | JEV r2 (conf.) — probas | pertinence r1/r2 |
|---|---|---|---|---|---|---|
| SYN-EE-008 Test 5 — frontière A2 / B1 | EE2 | A2/B1 | — | **B1** (0.46) — B1 0.58 A2 0.42 | **B1** (0.47) — B1 0.59 A2 0.41 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN-EE-011 Test 8 — B2 dans le raisonnement, avec plusieurs erreurs | EE2 | B2/B1 | — | **B1** (0.57) — B1 0.66 B2 0.34 | **B1** (0.57) — B1 0.66 B2 0.34 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN-EE-012 Test 9 — production trop courte pour juger | EE2 | INSUFFICIENT/A2 | — | **A2** (0.47) — A2 0.58 A1 0.42 | **A2** (0.46) — A2 0.57 A1 0.42 B1 0.01 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN-EE-018 Vrai INSUFFICIENT | EE2 | INSUFFICIENT/A1 | — | **A1** (0.4) — A1 0.52 INSUFFICIENT 0.48 | **A1** (0.45) — A1 0.56 INSUFFICIENT 0.44 | PARTIEL/PARTIEL |
| SYN-EE-020 B2 avec fautes assez nombreuses | EE2 | B2/B1 | — | **B1** (0.73) — B1 0.78 B2 0.21 A2 0.01 | **B1** (0.74) — B1 0.79 B2 0.20 A2 0.01 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN-EE-022 B2 avec vocabulaire très simple | EE2 | B2 | — | **B1** (0.65) — B1 0.73 B2 0.27 | **B1** (0.62) — B1 0.70 B2 0.30 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN-EE-026 Phrases « apprises par cœur » | EE2 | B1 | — | **A2** (0.38) — A2 0.50 B1 0.47 B2 0.02 A1 0.01 | **A2** (0.38) — A2 0.50 B1 0.47 B2 0.02 A1 0.01 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN-EE-031 Temps verbaux variés, mais niveau réel encore limité | EE2 | A2/B1 | — | **B1** (0.59) — B1 0.67 A2 0.30 B2 0.03 | **B1** (0.59) — B1 0.68 A2 0.30 B2 0.02 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN-EE-033 B2 naturel, sans style « dissertation » | EE2 | B2 | — | **B1** (0.49) — B1 0.59 B2 0.41 | **B1** (0.38) — B1 0.51 B2 0.49 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN2-EE1-A1-1 Invitation à un repas (A1) | EE1 | A1 | A1 | **A2** (0.67) — A2 0.74 A1 0.25 B1 0.01 | **A2** (0.67) — A2 0.73 A1 0.26 B1 0.01 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN2-EE1-A1-2 Annonce d'un nouveau travail (A1) | EE1 | A1 | A1 | **A2** (0.44) — A2 0.55 A1 0.45 | **A2** (0.46) — A2 0.57 A1 0.43 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN2-EE2-A1-1 Premier week-end dans une nouvelle ville (A1) | EE2 | A1 | A1 | **A2** (0.53) — A2 0.62 A1 0.37 B1 0.01 | **A2** (0.55) — A2 0.64 A1 0.36 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN2-EE2-B2-1 Reprise d'études à quarante ans (B2) | EE2 | B2 | B2 | **B1** (0.39) — B1 0.52 B2 0.48 | **B1** (0.41) — B1 0.54 B2 0.46 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN2-EE3-A1-1 Voitures en centre-ville (A1) | EE3 | A1 | A1 | **A2** (0.63) — A2 0.70 A1 0.23 B1 0.07 | **A2** (0.63) — A2 0.71 A1 0.23 B1 0.06 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN2-EE3-A1-2 Téléphone avant 12 ans (A1) | EE3 | A1 | A1 | **A2** (0.76) — A2 0.81 B1 0.14 A1 0.05 | **A2** (0.74) — A2 0.79 B1 0.17 A1 0.04 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN2-EE3-A2-1 Magasins ouverts le dimanche (A2) | EE3 | A2 | A2 | **B1** (0.65) — B1 0.72 A2 0.25 B2 0.03 | **B1** (0.65) — B1 0.72 A2 0.26 B2 0.02 | DANS_LE_SUJET/DANS_LE_SUJET |

**Secondaire : niveau via formule SejourFR** (r1, A1=1 · A2=4 · B1=8 · B2=15)

- argmax_milieu : vs JEV natif exact 54/57 (95 %) · adjacent 3 · majeur 0 · non comparables 1 ; vs visé exact 37/57 (65 %) · adjacent 17 · majeur 0 · INSUFFICIENT manqué 3 · non comparables 1 ; vs SejourFR exact 19/28 (68 %) · adjacent 9 · majeur 0
- esperance : vs JEV natif exact 45/57 (79 %) · adjacent 12 · majeur 0 · non comparables 1 ; vs visé exact 39/57 (68 %) · adjacent 15 · majeur 0 · INSUFFICIENT manqué 3 · non comparables 1 ; vs SejourFR exact 18/28 (64 %) · adjacent 10 · majeur 0

## `jev-v15-aligned-v1` — benchmark SECONDAIRE de sensibilité

Run `real-2026-09-29T214932Z-619a63` · hash des questions `df56ddcc4c9b…` · modèle(s) renvoyé(s) `jev-1.13.0` · 118 requêtes, 0 erreur(s) · 747232 tokens d'entrée, 37272 de sortie · **0.0314 $**

**Pertinence JEV** : r1 {'DANS_LE_SUJET': 55, 'PARTIEL': 3, 'HORS_SUJET': 1} ; r2 {'DANS_LE_SUJET': 55, 'PARTIEL': 3, 'HORS_SUJET': 1} — HORS_SUJET exclus des taux : SYN-EE-015

**JEV vs niveau visé**

| | strict (niveau principal) | souple (principal ou alternatif) |
|---|---|---|
| répétition 1 | exact 41/57 (72 %) · adjacent 14 · majeur 0 · INSUFFICIENT manqué 2 · non comparables 1 | exact 47/57 (82 %) · adjacent 10 · majeur 0 · non comparables 1 |
| répétition 2 | exact 41/57 (72 %) · adjacent 14 · majeur 0 · INSUFFICIENT manqué 2 · non comparables 1 | exact 47/57 (82 %) · adjacent 10 · majeur 0 · non comparables 1 |

| Tâche | strict r1 | souple r1 | strict r2 | souple r2 |
|---|---|---|---|---|
| EE1 | 6/8 (75 %) | 6/8 (75 %) | 6/8 (75 %) | 6/8 (75 %) |
| EE2 | 30/41 (73 %) | 36/41 (88 %) | 30/41 (73 %) | 36/41 (88 %) |
| EE3 | 5/8 (62 %) | 5/8 (62 %) | 5/8 (62 %) | 5/8 (62 %) |

**Matrice de confusion** (visé principal en ligne × JEV en colonne, 2 répétitions cumulées)

| visé \ JEV | A1 | A2 | B1 | B2 | INSUFFICIENT |
|---|---|---|---|---|---|
| **A1** | 6 | 10 | · | · | · |
| **A2** | · | 22 | 6 | · | · |
| **B1** | · | 2 | 36 | · | · |
| **B2** | · | · | 10 | 18 | · |
| **INSUFFICIENT** | 2 | 2 | · | · | 2 |

**Stabilité r1 / r2** : label identique 59/59 (100 %) · variation moyenne des probabilités 0.0056 (max 0.02) · variation moyenne de confiance 0.0153 (max 0.06)

**SejourFR vs JEV** (notés SejourFR, hors A1_NON_ATTEINT et HORS_SUJET)

- r1 : exact 21/28 (75 %) · adjacent 7 · majeur 0 — EE1 6/8 (75 %) ; EE2 10/12 (83 %) ; EE3 5/8 (62 %)
- r2 : exact 21/28 (75 %) · adjacent 7 · majeur 0 — EE1 6/8 (75 %) ; EE2 10/12 (83 %) ; EE3 5/8 (62 %)
- rappel SejourFR vs visé : strict exact 28/28 (100 %) · adjacent 0 · majeur 0 ; souple exact 28/28 (100 %) · adjacent 0 · majeur 0

**Désaccords JEV / visé** (strict, au moins une répétition ; distributions complètes du niveau global)

| cas | tâche | visé | SejourFR | JEV r1 (conf.) — probas | JEV r2 (conf.) — probas | pertinence r1/r2 |
|---|---|---|---|---|---|---|
| SYN-EE-008 Test 5 — frontière A2 / B1 | EE2 | A2/B1 | — | **B1** (0.46) — B1 0.57 A2 0.42 B2 0.01 | **B1** (0.42) — B1 0.53 A2 0.46 B2 0.01 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN-EE-011 Test 8 — B2 dans le raisonnement, avec plusieurs erreurs | EE2 | B2/B1 | — | **B1** (0.62) — B1 0.70 B2 0.30 | **B1** (0.6) — B1 0.69 B2 0.31 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN-EE-012 Test 9 — production trop courte pour juger | EE2 | INSUFFICIENT/A2 | — | **A2** (0.49) — A2 0.59 A1 0.40 B1 0.01 | **A2** (0.47) — A2 0.58 A1 0.41 B1 0.01 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN-EE-018 Vrai INSUFFICIENT | EE2 | INSUFFICIENT/A1 | — | **A1** (0.42) — A1 0.54 INSUFFICIENT 0.46 | **A1** (0.41) — A1 0.53 INSUFFICIENT 0.47 | PARTIEL/PARTIEL |
| SYN-EE-020 B2 avec fautes assez nombreuses | EE2 | B2/B1 | — | **B1** (0.71) — B1 0.77 B2 0.22 A2 0.01 | **B1** (0.72) — B1 0.77 B2 0.22 A2 0.01 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN-EE-022 B2 avec vocabulaire très simple | EE2 | B2 | — | **B1** (0.61) — B1 0.69 B2 0.31 | **B1** (0.61) — B1 0.70 B2 0.30 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN-EE-026 Phrases « apprises par cœur » | EE2 | B1 | — | **A2** (0.4) — A2 0.51 B1 0.46 B2 0.02 A1 0.01 | **A2** (0.37) — A2 0.50 B1 0.47 B2 0.02 A1 0.01 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN-EE-031 Temps verbaux variés, mais niveau réel encore limité | EE2 | A2/B1 | — | **B1** (0.61) — B1 0.69 A2 0.29 B2 0.02 | **B1** (0.59) — B1 0.68 A2 0.31 B2 0.01 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN-EE-033 B2 naturel, sans style « dissertation » | EE2 | B2 | — | **B1** (0.45) — B1 0.56 B2 0.44 | **B1** (0.47) — B1 0.58 B2 0.42 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN2-EE1-A1-1 Invitation à un repas (A1) | EE1 | A1 | A1 | **A2** (0.61) — A2 0.69 A1 0.30 B1 0.01 | **A2** (0.61) — A2 0.69 A1 0.30 B1 0.01 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN2-EE1-A1-2 Annonce d'un nouveau travail (A1) | EE1 | A1 | A1 | **A2** (0.47) — A2 0.58 A1 0.42 | **A2** (0.48) — A2 0.59 A1 0.41 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN2-EE2-A1-1 Premier week-end dans une nouvelle ville (A1) | EE2 | A1 | A1 | **A2** (0.49) — A2 0.60 A1 0.40 | **A2** (0.48) — A2 0.58 A1 0.41 B1 0.01 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN2-EE2-B2-1 Reprise d'études à quarante ans (B2) | EE2 | B2 | B2 | **B1** (0.4) — B1 0.52 B2 0.48 | **B1** (0.39) — B1 0.52 B2 0.48 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN2-EE3-A1-1 Voitures en centre-ville (A1) | EE3 | A1 | A1 | **A2** (0.67) — A2 0.74 A1 0.19 B1 0.07 | **A2** (0.62) — A2 0.69 A1 0.24 B1 0.07 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN2-EE3-A1-2 Téléphone avant 12 ans (A1) | EE3 | A1 | A1 | **A2** (0.74) — A2 0.80 B1 0.15 A1 0.05 | **A2** (0.76) — A2 0.81 B1 0.15 A1 0.04 | DANS_LE_SUJET/DANS_LE_SUJET |
| SYN2-EE3-A2-1 Magasins ouverts le dimanche (A2) | EE3 | A2 | A2 | **B1** (0.68) — B1 0.75 A2 0.22 B2 0.03 | **B1** (0.67) — B1 0.74 A2 0.24 B2 0.02 | DANS_LE_SUJET/DANS_LE_SUJET |

**Secondaire : niveau via formule SejourFR** (r1, A1=1 · A2=4 · B1=8 · B2=15)

- argmax_milieu : vs JEV natif exact 45/57 (79 %) · adjacent 12 · majeur 0 · non comparables 1 ; vs visé exact 46/57 (81 %) · adjacent 8 · majeur 0 · INSUFFICIENT manqué 3 · non comparables 1 ; vs SejourFR exact 28/28 (100 %) · adjacent 0 · majeur 0
- esperance : vs JEV natif exact 49/57 (86 %) · adjacent 8 · majeur 0 · non comparables 1 ; vs visé exact 44/57 (77 %) · adjacent 10 · majeur 0 · INSUFFICIENT manqué 3 · non comparables 1 ; vs SejourFR exact 24/28 (86 %) · adjacent 4 · majeur 0

## Comparaison `jev-independent-v1` → `jev-v15-aligned-v1`

- Paires ordinales comparées (cas × répétition) : 116 ; v15-aligned plus haut 0, plus bas 0, identique 116 ; écart moyen 0.0 palier.
- ⚠️ La question `niveau_global` est IDENTIQUE dans les deux versions (seules les options des questions critère diffèrent) : l'identité des niveaux globaux est un contrôle de reproductibilité, pas un résultat de sensibilité.
- Questions critère (cas × répétition), v15-aligned par rapport à independent : communiquer 19/118 différents (↑7 ↓12) ; interagir 24/118 différents (↑11 ↓13) ; lexique 30/118 différents (↑11 ↓19) ; morphosyntaxe 28/118 différents (↑0 ↓28).
- Cas qui changent de niveau global (r1) : aucun

## Coût réel total (tous appels, test compris)

237 requêtes · 1273104 tokens d'entrée · 74860 tokens de sortie · **0.0535 $**

## Limites

- Productions **synthétiques** ; niveau visé = intention de l'auteur, non validé par un examinateur humain.
- 35 cas sur 59 partagent la même consigne (fête de quartier) ; EE1 et EE3 n'ont que 8 cas chacun.
- JEV ne voit ni la longueur attendue ni le niveau cible ; SejourFR voit les deux (prompt v15).
- Les conclusions sur données réelles demandent l'étape V1-b (export anonymisé, décision RGPD préalable).
