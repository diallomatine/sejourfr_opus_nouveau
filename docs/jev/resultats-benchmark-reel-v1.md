# Benchmark JEV — productions RÉELLES anonymisées, v1 (2026-09-30)

> Agrégats uniquement : **aucun texte ni extrait de production**. Les cas sont désignés par les 12 premiers
> caractères de leur clé hachée (`md5(sel local ∥ id)`, sel jamais versionné). Régénérable :
> `python -m jev_bench report-real`. Ne se mélange jamais avec le benchmark synthétique
> (`resultats-benchmark-synthetique-v1.md`), rappelé en §9 à titre de comparaison seulement.

## ⚠️ Garde-fous d'interprétation

- **SejourFR n'est pas une vérité terrain.** Il sert ici de référence de comparaison, pas d'étalon : un
  désaccord JEV / SejourFR ne dit pas lequel des deux se trompe.
- **L'accord ne prouve pas la justesse** : deux correcteurs peuvent se tromper dans le même sens. Seule une
  évaluation humaine experte (examinateur TCF) permettrait de trancher.
- **B2 n'est pas mesurable** : 1 seul cas B2 SejourFR dans l'échantillon (EE1 B2 perdu au plafond par candidat,
  EE2 B2 inexistant en prod). Aucune conclusion sur le haut de l'échelle.
- Échantillon stratifié (quotas par cellule, plafond 3 productions par candidat) : les pourcentages
  décrivent **cet échantillon**, pas la distribution de la prod.
- SejourFR voit le niveau cible et la longueur attendue de la tâche ; JEV ne voit ni niveau ni longueur.

## Protocole

- **Population** : productions EE1–EE3 réelles, prod, `EVALUATED`, hors diagnostic, comptes réels (internes,
  supprimés, `@sejourfr.fr` et compte propriétaire exclus côté serveur), dernière évaluation par soumission,
  grille v15 / schéma v9. 328 productions, 104 candidats.
- **Échantillon** : extraction en lecture seule (`jev_bench/sql/export_ee_real_v1.sql`), plafond 3 productions
  par candidat avant quotas, A1/B2 en entier, 11 par cellule A2/B1, strates isolées A1_NON_ATTEINT et
  NON_EVALUABLE ; rédaction locale des données personnelles (11 [PERSONNE], 1 [ADRESSE]) ; 1 cas retiré sur
  décision du propriétaire (prénoms en capitales non rédigeables) → **99 productions** (84 CECRL, 12
  A1_NON_ATTEINT, 3 NON_EVALUABLE). 88 en examen blanc, 11 en entraînement.
- **JEV** : `jev-independent-v1` (hash identique au synthétique : `da11bd86…`), modèle **épinglé** `jev-1.13.0`
  (renvoyé à l'identique sur les 124 appels), state = consigne + contexte + production rédigée, contrôlé
  automatiquement avant envoi (6 champs, aucun niveau / note / score / identifiant / sel). 1 répétition sur
  les 99, 2 sur un sous-ensemble stratifié de 25.
- **Comparaison** : répétition 1 ; JEV HORS_SUJET exclus des taux (compteur séparé) ; INSUFFICIENT hors échelle.

## Ce qu'il faut retenir

1. **Accord JEV / SejourFR : 54/81 exact (67 %), 27 adjacents, 0 majeur,
   κ pondéré quadratique 0.638** — nettement moins que sur le synthétique (75 %, κ 0,871).
2. **Les écarts ont une structure claire** : JEV place **plus haut** les A1 SejourFR (10/14 → A2) et **plus
   bas** près de la moitié des B1 SejourFR (14/33 → A2) ; les A2 sont presque toujours d'accord (32/33).
   JEV resserre donc vers A2, SejourFR étire l'échelle vers A1 et B1.
3. **EE1 concentre le désaccord B1→A2** (9 des 14) : SejourFR donne B1 à des messages courts que JEV lit A2.
   EE3 est la tâche la plus concordante (κ 0,797), et c'est là que JEV monte parfois (7 fois plus haut, 0 plus bas).
4. **9 désaccords à forte confiance JEV** (≥ 0,7) : tous dans le sens « JEV A2 » sauf un (A2 → B1). Ce sont les
   premiers cas à soumettre à un avis humain.
5. **Strates isolées** : les 3 NON_EVALUABLE → JEV INSUFFICIENT + HORS_SUJET (3/3, confiance ≥ 0,89). Les 12
   A1_NON_ATTEINT → HORS_SUJET pour 11/12, mais le niveau linguistique est A1/A2 dans 7 cas : JEV sépare
   bien « hors sujet » et « niveau de langue », là où SejourFR met 0/20.
6. **Pertinence** : JEV juge PARTIEL 41 productions CECRL sur 84 (contre 3/59 en synthétique) — le traitement
   partiel de la consigne est fréquent sur de vraies copies.
7. **Stabilité** : 23/25 labels identiques ; les 2 instables sont à 50/50 dans les deux répétitions.
8. **Coût réel : 0,0230 $** pour 124 requêtes (548 136 tokens d'entrée).

Run `real-2026-09-29T221622Z-e8d2b5` · prompt `jev-independent-v1` (hash `da11bd86ffc1…`) · modèle demandé `jev-1.13.0`, renvoyé `jev-1.13.0` · 124 requêtes, 0 erreur(s) · 548136 tokens d'entrée, 39033 de sortie · **0.0230 $**

## 1. JEV vs SejourFR — strate CECRL

84 productions CECRL ; JEV HORS_SUJET : 3 (3fcde63ae40d, 14d83c4dcf1d, 6d10fda93b59) ; comparables : 81.
Pertinence JEV sur la strate : {'DANS_LE_SUJET': 40, 'PARTIEL': 41, 'HORS_SUJET': 3}.

**Global** : exact 54/81 (67 %) · adjacent 27 · majeur 0 · JEV plus haut 13 / plus bas 14 · κ quadratique 0.638

## 2. Par tâche

| Tâche | Résultat |
|---|---|
| EE1 | exact 15/26 (58 %) · adjacent 11 · majeur 0 · JEV plus haut 2 / plus bas 9 · κ quadratique 0.421 |
| EE2 | exact 18/27 (67 %) · adjacent 9 · majeur 0 · JEV plus haut 4 / plus bas 5 · κ quadratique 0.567 |
| EE3 | exact 21/28 (75 %) · adjacent 7 · majeur 0 · JEV plus haut 7 / plus bas 0 · κ quadratique 0.797 |

## 3. Par niveau SejourFR et matrice de confusion

| SejourFR | Résultat |
|---|---|
| A1 | exact 4/14 (29 %) · adjacent 10 · majeur 0 · JEV plus haut 10 / plus bas 0 |
| A2 | exact 32/33 (97 %) · adjacent 1 · majeur 0 · JEV plus haut 1 / plus bas 0 |
| B1 | exact 17/33 (52 %) · adjacent 16 · majeur 0 · JEV plus haut 2 / plus bas 14 |
| B2 | exact 1/1 (100 %) · adjacent 0 · majeur 0 · JEV plus haut 0 / plus bas 0 |

(Pas de kappa par niveau : la référence n'y a qu'une seule classe.)

SejourFR en ligne × JEV en colonne (répétition 1) :

| SejourFR \ JEV | A1 | A2 | B1 | B2 | INSUFFICIENT |
|---|---|---|---|---|---|
| **A1** | 4 | 10 | · | · | · |
| **A2** | · | 32 | 1 | · | · |
| **B1** | · | 14 | 17 | 2 | · |
| **B2** | · | · | · | 1 | · |

## 4. Désaccords (27)

Critères dans l'ordre communiquer / interagir / lexique / morphosyntaxe.

| clé | tâche | type | mots | SejourFR (note ; critères) | JEV (conf.) | distribution JEV | pertinence | critères JEV |
|---|---|---|---|---|---|---|---|---|
| `012a355ce5c1` | EE1 | MOCK_EXAM | 40 | A1 (1.5 ; 2/2/1/1) | **A2** (0.38) | A1 0.49 A2 0.51 B1 0.00 B2 0.00 INSUFFICIENT 0.00 | DANS_LE_SUJET | A2/A2/A2/A1 |
| `e0fb8ea04692` | EE1 | MOCK_EXAM | 57 | A1 (1.5 ; 2/2/1/1) | **A2** (0.69) | A1 0.12 A2 0.76 B1 0.12 B2 0.00 INSUFFICIENT 0.00 | PARTIEL | A2/A2/A2/A2 |
| `0915d8dc87d6` | EE1 | TRAINING | 60 | B1 (7.5 ; 8/8/7/7) | **A2** (0.66) | A1 0.01 A2 0.73 B1 0.24 B2 0.02 INSUFFICIENT 0.00 | PARTIEL | A2/A2/A2/B1 |
| `12c748e896ed` | EE1 | TRAINING | 58 | B1 (8.5 ; 9/9/8/8) | **A2** (0.48) | A1 0.00 A2 0.59 B1 0.38 B2 0.03 INSUFFICIENT 0.00 | DANS_LE_SUJET | A2/B1/A2/A2 |
| `156c04cca83f` | EE1 | TRAINING | 43 | B1 (7.5 ; 8/8/7/7) | **A2** (0.38) | A1 0.00 A2 0.50 B1 0.33 B2 0.17 INSUFFICIENT 0.00 | DANS_LE_SUJET | A2/B1/A2/B1 |
| `1acef76c3989` | EE1 | MOCK_EXAM | 59 | B1 (7.5 ; 8/8/7/7) | **A2** (0.49) | A1 0.02 A2 0.60 B1 0.36 B2 0.02 INSUFFICIENT 0.00 | DANS_LE_SUJET | A2/A2/A2/A2 |
| `1f6371e4722c` | EE1 | MOCK_EXAM | 60 | B1 (6.5 ; 7/7/6/6) | **A2** (0.78) | A1 0.01 A2 0.83 B1 0.16 B2 0.00 INSUFFICIENT 0.00 | DANS_LE_SUJET | A2/A2/A2/A2 |
| `2484a71e386d` | EE1 | MOCK_EXAM | 52 | B1 (7.5 ; 8/8/7/7) | **A2** (0.37) | A1 0.01 A2 0.49 B1 0.45 B2 0.04 INSUFFICIENT 0.01 | PARTIEL | A2/A2/B1/B1 |
| `376b3ea1852b` | EE1 | MOCK_EXAM | 41 | B1 (7.5 ; 8/8/7/7) | **A2** (0.73) | A1 0.02 A2 0.78 B1 0.13 B2 0.07 INSUFFICIENT 0.00 | DANS_LE_SUJET | A2/A2/A2/A2 |
| `3ef5a290e71c` | EE1 | MOCK_EXAM | 60 | B1 (6.5 ; 7/7/6/6) | **A2** (0.51) | A1 0.01 A2 0.60 B1 0.38 B2 0.01 INSUFFICIENT 0.00 | PARTIEL | A2/B1/A2/A2 |
| `725d18f0839f` | EE1 | MOCK_EXAM | 46 | B1 (8.5 ; 9/9/8/8) | **A2** (0.68) | A1 0.02 A2 0.74 B1 0.23 B2 0.01 INSUFFICIENT 0.00 | PARTIEL | A2/B1/A2/A2 |
| `2a64a7df3d2f` | EE2 | MOCK_EXAM | 70 | A1 (1.5 ; 2/2/1/1) | **A2** (0.47) | A1 0.41 A2 0.58 B1 0.01 B2 0.00 INSUFFICIENT 0.00 | PARTIEL | A1/A2/A2/A1 |
| `68f6c0bcc276` | EE2 | MOCK_EXAM | 44 | A1 (1.5 ; 2/2/1/1) | **A2** (0.59) | A1 0.31 A2 0.67 B1 0.02 B2 0.00 INSUFFICIENT 0.00 | PARTIEL | A1/A2/A2/A2 |
| `9d2769a640cf` | EE2 | MOCK_EXAM | 49 | A1 (1.5 ; 2/2/1/1) | **A2** (0.78) | A1 0.12 A2 0.83 B1 0.05 B2 0.00 INSUFFICIENT 0.00 | DANS_LE_SUJET | A2/A1/A2/A2 |
| `c916b7197aa1` | EE2 | MOCK_EXAM | 42 | A1 (1.5 ; 2/2/1/1) | **A2** (0.68) | A1 0.24 A2 0.75 B1 0.00 B2 0.00 INSUFFICIENT 0.01 | PARTIEL | A1/A2/A2/A2 |
| `07a91e97d6eb` | EE2 | MOCK_EXAM | 89 | B1 (7.5 ; 8/8/7/7) | **A2** (0.71) | A1 0.03 A2 0.77 B1 0.20 B2 0.00 INSUFFICIENT 0.00 | DANS_LE_SUJET | A2/A1/A2/A2 |
| `1202599b84e6` | EE2 | TRAINING | 41 | B1 (6.5 ; 7/7/6/6) | **A2** (0.82) | A1 0.06 A2 0.86 B1 0.08 B2 0.00 INSUFFICIENT 0.00 | PARTIEL | A2/A2/A2/A2 |
| `1d174487912b` | EE2 | MOCK_EXAM | 66 | B1 (7.5 ; 8/8/7/7) | **A2** (0.73) | A1 0.13 A2 0.79 B1 0.08 B2 0.00 INSUFFICIENT 0.00 | PARTIEL | A2/A2/A2/A2 |
| `2a10aa0a30b9` | EE2 | MOCK_EXAM | 84 | B1 (8.8 ; 9/9/8/9) | **A2** (0.42) | A1 0.01 A2 0.54 B1 0.44 B2 0.01 INSUFFICIENT 0.00 | PARTIEL | A2/A1/A2/B1 |
| `2e78d61b28e1` | EE2 | MOCK_EXAM | 86 | B1 (7.5 ; 8/8/7/7) | **A2** (0.42) | A1 0.02 A2 0.54 B1 0.43 B2 0.01 INSUFFICIENT 0.00 | DANS_LE_SUJET | A2/A2/B1/A2 |
| `5b56cbfe0657` | EE3 | MOCK_EXAM | 42 | A1 (1.5 ; 2/2/1/1) | **A2** (0.78) | A1 0.10 A2 0.83 B1 0.07 B2 0.00 INSUFFICIENT 0.00 | DANS_LE_SUJET | A2/A2/A2/A2 |
| `6da92c0d8abe` | EE3 | MOCK_EXAM | 41 | A1 (1.5 ; 2/2/1/1) | **A2** (0.75) | A1 0.06 A2 0.80 B1 0.14 B2 0.00 INSUFFICIENT 0.00 | DANS_LE_SUJET | A2/A2/A2/A2 |
| `9f95dcfacd6d` | EE3 | MOCK_EXAM | 51 | A1 (1.5 ; 2/2/1/1) | **A2** (0.64) | A1 0.02 A2 0.72 B1 0.26 B2 0.00 INSUFFICIENT 0.00 | PARTIEL | A2/A2/A2/A2 |
| `a8c52b2024a6` | EE3 | MOCK_EXAM | 40 | A1 (1.5 ; 2/2/1/1) | **A2** (0.49) | A1 0.31 A2 0.60 B1 0.08 B2 0.00 INSUFFICIENT 0.01 | PARTIEL | A2/A1/A2/A1 |
| `20609f5be9f2` | EE3 | MOCK_EXAM | 78 | A2 (4.5 ; 5/5/4/4) | **B1** (0.7) | A1 0.00 A2 0.20 B1 0.76 B2 0.04 INSUFFICIENT 0.00 | DANS_LE_SUJET | B1/B1/B1/B1 |
| `085c2326f3e2` | EE3 | MOCK_EXAM | 77 | B1 (9.0 ; 9/9/9/9) | **B2** (0.38) | A1 0.00 A2 0.01 B1 0.49 B2 0.50 INSUFFICIENT 0.00 | DANS_LE_SUJET | B1/B1/B2/B2 |
| `6b7a03b89567` | EE3 | MOCK_EXAM | 84 | B1 (8.5 ; 9/9/8/8) | **B2** (0.49) | A1 0.00 A2 0.01 B1 0.40 B2 0.59 INSUFFICIENT 0.00 | PARTIEL | B2/B1/B2/B2 |

## 5. JEV très confiant contre SejourFR (confiance ≥ 0,7 ou proba du choix ≥ 0,8) : 9

- `1f6371e4722c` EE1 : SejourFR B1 (6.5) → JEV **A2** (conf. 0.78, p = 0.83)
- `376b3ea1852b` EE1 : SejourFR B1 (7.5) → JEV **A2** (conf. 0.73, p = 0.78)
- `9d2769a640cf` EE2 : SejourFR A1 (1.5) → JEV **A2** (conf. 0.78, p = 0.83)
- `07a91e97d6eb` EE2 : SejourFR B1 (7.5) → JEV **A2** (conf. 0.71, p = 0.77)
- `1202599b84e6` EE2 : SejourFR B1 (6.5) → JEV **A2** (conf. 0.82, p = 0.86)
- `1d174487912b` EE2 : SejourFR B1 (7.5) → JEV **A2** (conf. 0.73, p = 0.79)
- `5b56cbfe0657` EE3 : SejourFR A1 (1.5) → JEV **A2** (conf. 0.78, p = 0.83)
- `6da92c0d8abe` EE3 : SejourFR A1 (1.5) → JEV **A2** (conf. 0.75, p = 0.80)
- `20609f5be9f2` EE3 : SejourFR A2 (4.5) → JEV **B1** (conf. 0.7, p = 0.76)

## 6. Strates isolées (jamais mêlées aux statistiques CECRL)

**A1_NON_ATTEINT** (12) — JEV : {'INSUFFICIENT': 5, 'A1': 2, 'A2': 5} ; pertinence : {'HORS_SUJET': 11, 'PARTIEL': 1}

| clé | tâche | mots | note SejourFR | JEV (conf.) | distribution | pertinence |
|---|---|---|---|---|---|---|
| `b61847195fa3` | EE1 | 31 | 0.0 | **INSUFFICIENT** (0.99) | A1 0.01 A2 0.00 B1 0.00 B2 0.00 INSUFFICIENT 0.99 | HORS_SUJET |
| `c2b34e50d716` | EE1 | 30 | 0.0 | **A1** (0.5) | A1 0.60 A2 0.02 B1 0.00 B2 0.00 INSUFFICIENT 0.38 | HORS_SUJET |
| `d72fdfe793ad` | EE1 | 59 | 0.0 | **A2** (0.62) | A1 0.06 A2 0.69 B1 0.15 B2 0.01 INSUFFICIENT 0.09 | HORS_SUJET |
| `035fb3a131f5` | EE2 | 90 | 0.0 | **INSUFFICIENT** (0.38) | A1 0.37 A2 0.11 B1 0.01 B2 0.00 INSUFFICIENT 0.51 | HORS_SUJET |
| `71df887f231e` | EE2 | 87 | 0.0 | **A2** (0.61) | A1 0.25 A2 0.69 B1 0.01 B2 0.00 INSUFFICIENT 0.05 | HORS_SUJET |
| `8da0e0032b5b` | EE2 | 41 | 0.0 | **INSUFFICIENT** (0.99) | A1 0.01 A2 0.00 B1 0.00 B2 0.00 INSUFFICIENT 0.99 | HORS_SUJET |
| `2984144991f4` | EE3 | 90 | 0.0 | **A2** (0.7) | A1 0.08 A2 0.76 B1 0.09 B2 0.00 INSUFFICIENT 0.07 | HORS_SUJET |
| `43dd50864724` | EE3 | 41 | 0.0 | **INSUFFICIENT** (0.99) | A1 0.00 A2 0.00 B1 0.00 B2 0.00 INSUFFICIENT 1.00 | HORS_SUJET |
| `8c7e809a981e` | EE3 | 43 | 0.0 | **A2** (0.49) | A1 0.14 A2 0.59 B1 0.09 B2 0.00 INSUFFICIENT 0.18 | PARTIEL |
| `95490e31a03c` | EE3 | 41 | 0.0 | **INSUFFICIENT** (0.66) | A1 0.22 A2 0.05 B1 0.00 B2 0.00 INSUFFICIENT 0.73 | HORS_SUJET |
| `b40b2a01e9ec` | EE3 | 53 | 0.0 | **A2** (0.49) | A1 0.16 A2 0.60 B1 0.13 B2 0.00 INSUFFICIENT 0.11 | HORS_SUJET |
| `dc50bf1568e1` | EE3 | 40 | 0.0 | **A1** (0.5) | A1 0.61 A2 0.31 B1 0.01 B2 0.00 INSUFFICIENT 0.07 | HORS_SUJET |

**NON_EVALUABLE** (3) — JEV : {'INSUFFICIENT': 3} ; pertinence : {'HORS_SUJET': 3}

| clé | tâche | mots | note SejourFR | JEV (conf.) | distribution | pertinence |
|---|---|---|---|---|---|---|
| `eb2bc3f2ed58` | EE1 | 30 | None | **INSUFFICIENT** (0.89) | A1 0.09 A2 0.00 B1 0.00 B2 0.00 INSUFFICIENT 0.91 | HORS_SUJET |
| `5084714150f8` | EE2 | 47 | None | **INSUFFICIENT** (0.98) | A1 0.01 A2 0.00 B1 0.00 B2 0.00 INSUFFICIENT 0.99 | HORS_SUJET |
| `b697ae8f82f8` | EE3 | 43 | None | **INSUFFICIENT** (1.0) | A1 0.00 A2 0.00 B1 0.00 B2 0.00 INSUFFICIENT 1.00 | HORS_SUJET |

## 7. Stabilité (sous-ensemble répété)

Niveau identique 23/25 (92 %) · variation moyenne des probabilités 0.0081 (max 0.024) · variation moyenne de confiance 0.02 (max 0.06).

- instable `012a355ce5c1` (CECRL, SejourFR A1) : r1 **A2** (A2 0.51 A1 0.49) / r2 **A1** (A1 0.53 A2 0.47)
- instable `085c2326f3e2` (CECRL, SejourFR B1) : r1 **B2** (B2 0.50 B1 0.49) / r2 **B1** (B1 0.52 B2 0.47)

## 8. Coût et secondaire

Coût réel 0.0230 $ · 548136 tokens d'entrée · 39033 de sortie.

Secondaire — niveau via formule SejourFR (A1=1 · A2=4 · B1=8 · B2=15) appliquée aux 4 critères JEV, comparé au niveau SejourFR :

- argmax_milieu : exact 51/81 (63 %) · adjacent 30 · majeur 0 · JEV plus haut 15 / plus bas 15 · κ quadratique 0.578
- esperance : exact 50/81 (62 %) · adjacent 31 · majeur 0 · JEV plus haut 17 / plus bas 14 · κ quadratique 0.548

## 9. Rappel du benchmark synthétique (calculé séparément, mêmes métriques)

Run `real-2026-09-29T214833Z-0e6179` (`jev-independent-v1`, 28 comparables) : exact 21/28 (75 %) · adjacent 7 · majeur 0 · JEV plus haut 6 / plus bas 1 · κ quadratique 0.871

- EE1 : exact 6/8 (75 %) · adjacent 2 · majeur 0 · JEV plus haut 2 / plus bas 0 · κ quadratique 0.875
- EE2 : exact 10/12 (83 %) · adjacent 2 · majeur 0 · JEV plus haut 1 / plus bas 1 · κ quadratique 0.906
- EE3 : exact 5/8 (62 %) · adjacent 3 · majeur 0 · JEV plus haut 3 / plus bas 0 · κ quadratique 0.812

## Limites et suite

- Échantillon de 99 productions (81 comparables) : intervalles d'incertitude larges, surtout par tâche × niveau.
- Aucun jugement humain : la question « qui a raison ? » reste ouverte. Proposition : faire noter à l'aveugle
  par un examinateur les 27 désaccords (priorité aux 9 à forte confiance JEV) et un échantillon d'accords.
- Petits sujets non traités (strate séparée, décision en attente).
