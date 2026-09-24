# ÉTUDE DE FAISABILITÉ — Écrans de progression (TCF IRN & examen civique)

Statut : **étude en lecture seule, 2026-09-24**, branche `feature/refonte-l1-socle`. Aucun code
modifié, aucun appel LLM. Les chiffres viennent de requêtes SQL en lecture sur la base locale
`sejourfr_db` (§2).

Maquettes du propriétaire, copiées sous `docs/progression/maquettes-progression/` :

| Fichier | Écran |
|---|---|
| `progression_global_tcf.html` | Progression **globale** TCF |
| `progression_epreuve_tcf.html` | Progression d'**une épreuve** TCF (exemple : CO) |
| `progression_global_civique.html` | Progression **globale** civique |
| `progression_theme_civique.html` | Progression d'**un thème** civique |

---

## Arbitrages du propriétaire, 2026-09-24

Les décisions D1 à D20 du §8 sont **tranchées**. Formulation du propriétaire,
reprise au plus près ; ce qui suit l'emporte sur les « recommandations » du §8.

- **D1** — La progression TCF ne se calcule que sur les **examens blancs** :
  l'épreuve passée seule + la sous-épreuve de cette épreuve dans un examen
  complet. **Aucun diagnostic.**
- **D2** — CO/CE : score de progression **/499**, **sans bandes CECRL** sur la
  courbe. Le palier est servi à part.
- **D3** — EE/EO : note **/20** avec les **bandes officielles**, servies par le
  backend.
- **D4** — Afficher le palier du **dernier examen**, et en secondaire le
  **niveau actuel estimé**.
- **D5** — **Pas d'anneau en TCF** ; l'anneau reste en **civique** (le serveur
  sert ce qu'il lui faut : taux du dernier examen face au seuil).
- **D6** — **Aucun score global TCF inventé.** Servir le palier global actuel, le
  dernier examen complet et l'évolution de palier.
- **D7** — Ne compter que les examens complets ayant **au moins une épreuve
  réellement mesurée** ; meilleur / premier seulement parmi les examens **non
  partiels**.
- **D8** — Ordinal chronologique servi par le backend. Historique **complet** sur
  les écrans épreuve / thème ; les écrans globaux servent les **3 derniers + le
  total**, et le front renvoie vers l'historique complet (servi par
  `?tous=true`).
- **D9** — Durée servie **seulement quand elle est fiable** (critère du §8), sinon
  `null` (le front affiche « — »).
- **D10** — Écran d'un thème civique : **examens de thème (20 Q) seulement**.
- **D11** — Dans un examen civique global, résultats par thème en **« x / n
  posées »** réels, jamais « / 20 ».
- **D12** — États civiques **Solide / À renforcer / Faible / Non évalué** servis
  par le backend (autorité et libellés existants, pas de doublon).
- **D13** — **Ne pas toucher au moteur de l'Accueil** ; l'endpoint de thème dit
  clairement que l'état vient du **dernier examen du thème** (champ + libellé).
- **D14** — Nouvelle famille sous **`/api/me/progression`** ; l'endpoint mort
  existant est remplacé / supprimé (« refonte = suppression immédiate »).
- **D15** — **Aucune ancienne statistique / compétence** sur ces écrans.
- **D18** — La production ne peut pas être consultée d'ici : vérifier si
  l'autorité commune traite mal les anciens attempts CO de 50/60 questions, la
  corriger si c'est clairement nécessaire et sûr (avec tests), sinon le signaler.
- **D19** — **En premier** : un `final_cecrl_level` historique persisté (figé
  sous d'anciennes règles, ex. « A1 non atteint ») ne doit plus l'emporter sur la
  re-dérivation. Invariants : un garde-fou ne peut qu'abaisser, `null` =
  inconnu, on versionne sans réécrire. Tests requis.
- **D20** — **Tous les résultats visibles** d'un compte gratuit ; seuls les CTA
  vers de nouveaux examens peuvent être verrouillés — le backend sert l'état
  (`locked`) pour que les fronts ne le déduisent pas.
- **Ajout du même jour** — À la fin du chantier, l'espace Progression ne contient
  **que ce que montrent les 4 maquettes** : tout ce que les écrans de
  progression actuels étaient seuls à lire disparaît (backend compris), sauf ce
  que l'Accueil et l'historique des cycles du Plan (« Mes cycles ») utilisent.

D16 et D17 relèvent de la phase front (libellés, entrées de navigation).
Implémentation backend (phase 1) : `docs/regles/progression.md` § « Écrans de
progression ».

---

## 0. Règle directrice — le visuel vient des maquettes, les données viennent du backend

🛑 **Principe du propriétaire, qui gouverne toute la suite de ce document.**

1. **Les 4 maquettes donnent la direction VISUELLE, et seulement elle.** L'implémentation doit en
   être aussi proche que possible, idéalement identique : mise en page, hiérarchie, cartes, style
   de la courbe, espacements, ordre des blocs.
2. **Toutes les données viennent de NOTRE backend, qui reste le maître.** Échelles, seuils, bandes,
   libellés, états, compteurs : servis. **Toute valeur ou tout libellé de maquette qui n'existe pas
   dans notre modèle, ou qui y est différent, est remplacé par le nôtre** : la vraie échelle TCF,
   les 5 thématiques civiques officielles, les états servis. Rien n'est inventé ni recalculé par un
   front.
3. Pour chaque bloc de chaque maquette, le §4.6 dit soit **« visuel repris tel quel — donnée
   servie par X »**, soit **« bloc adapté, parce que la donnée n'existe pas : … »**.

Ce principe n'est pas une nouveauté. Il redit des invariants déjà en vigueur : « Aucun front ne
classe un nombre en état pédagogique ni en niveau CECRL », « Dérivé serveur ⇒ jamais recalculé par
un front », « Une règle = une autorité » (`CLAUDE.md` racine), plus la règle du kit (« un motif qui
manque s'ajoute dans les deux kits dans la même passe »).

---

## 1. Verdict

**Faisable, sur les deux fronts, en parité et à travers le kit.** Il y a quatre réserves, et
aucune ne bloque :

1. **Les chiffres des maquettes sont faux pour notre produit, presque partout.** Tout est affiché
   « / 499 » avec des bandes A1 100–199 … B2 400–499. **C'est exactement la table score → palier
   révoquée le 2026-09-20** (`docs/regles/qcm.md` § « Le score 100-499 est un SCORE DE
   PROGRESSION »). Côté civique, tout est affiché « / 20 » avec 4 thèmes et un vocabulaire
   inventé (« Très bon », « Bonne maîtrise »). Le visuel se reprend, les chiffres se remplacent
   (§4).
2. **Un seul endpoint neuf par écran**, dans `service/progres/`. Tout ce qu'il sert existe déjà
   chez une autorité (niveaux QCM par strates, niveau EE/EO, note /20, état d'un thème civique,
   plancher d'examen complet). Il y a **un seul calcul réellement nouveau**, et il est trivial :
   ordinal chronologique, meilleur, premier, écart entre premier et dernier. Il doit vivre côté
   serveur.
3. **Il y a peu de données réelles** : 4 examens TCF complets exploitables sur les 4 épreuves,
   4 examens de thème civique terminés sur toute la base (§2). Les écrans doivent être pensés
   **d'abord pour l'état vide et l'état à 1 point**.
4. **Deux défauts existants remontent à la surface** et se traitent à part : un
   `final_cecrl_level` persisté qui l'emporte sur la re-dérivation (§5.6), et l'état d'un thème
   civique sur l'Accueil, qui vient du **diagnostic** et non des examens (§4.2).

Effort estimé : **≈ 15 jours-développeur**, répartis en 6 lots (§7).

---

## 2. Ce que la base contient réellement (SQL, 2026-09-24)

Base locale, **38 comptes** (37 `USER`). Ce sont des données de dev : elles disent ce qui **peut**
exister et ce qui est persisté, pas un volume de production.

### 2.1 Attempts par origine (`user_id IS NOT NULL`)

| module · épreuve | origine | créés | terminés | score | `weighted_score` |
|---|---|---|---|---|---|
| TCF · CO | examen de module (slot) | 30 | 14 | 14 | 14 |
| TCF · CO | sous-épreuve d'examen complet | 29 | 20 | 20 | 20 |
| TCF · CO | section de diagnostic complet | 7 | 3 | 3 | 3 |
| TCF · CO | MOCK_EXAM sans slot ni parent (héritage) | 23 | 7 | 7 | 7 |
| TCF · CE | examen de module (slot) | 10 | 5 | 5 | 5 |
| TCF · CE | sous-épreuve d'examen complet | 29 | 20 | 20 | 20 |
| TCF · CE | section de diagnostic complet | 7 | 2 | 2 | 2 |
| TCF · COMPLET | examen blanc complet (slot) | 29 | 20 | — | — |
| TCF · EE / EO | examen de production (slot) | 13 / 14 | 7 / 14 | — | — |
| TCF · EE / EO | sous-épreuve d'examen complet | 29 / 29 | 23 / 22 | — | — |
| CIVIQUE | examen global 40 Q | 23 | 9 | 9 | — |
| CIVIQUE | examen de thème 20 Q (`lot_theme_id`) | 10 | **4** | 4 | — |
| CIVIQUE | diagnostic civique (40 Q) | 6 | 6 | 6 | — |

✅ **`weighted_score` est posé sur 100 % des examens CO/CE terminés** : le score de progression
100–499 se calcule donc pour chacun (`TcfLevelEstimatorService.calibratedScore(weighted, max)`).

### 2.2 Épreuves réellement exploitables

- **CO/CE avec au moins une réponse** (le prédicat de `AttemptRepository.findQcmEpreuvesPassees`) :
  CO 11/12 en module (examens de 25 Q ; les 2 autres terminés sont des héritages de 50/60 Q, §7),
  **9/20** en sous-épreuve d'examen complet ; CE 4/5 en module, 9/20 en sous-épreuve. **Un examen complet « terminé » sur deux a des QCM vides** (abandon, puis clôture
  paresseuse).
- **EE/EO qualifiantes** (`findProductionEpreuvesPassees`) : EE 3 en module et 7 en complet
  portent des soumissions, dont 2 et 7 ont les 3 tâches évaluées ; EO 11 et 7, dont 6 et 5.
- **Examens TCF complets** : 29 créés, 20 terminés, 2 verrouillés (freemium), 9 avec CO **et** CE
  répondues, **4 exploitables sur les 4 épreuves**. `final_cecrl_level` est persisté sur 6
  d'entre eux, et vaut `A1_NON_ATTEINT` sur les 6 (§5.6).
- **Candidat le plus actif** (`user@sejourfr.fr`) : 12 CO, 7 CE, 4 EE, 7 EO qualifiantes. C'est
  le seul profil où une courbe à 7 points, comme sur la maquette, existe réellement.

### 2.3 Temps d'un examen

| population | terminés | `timer_started_at` absent | au-delà de la limite + 60 s |
|---|---|---|---|
| CO/CE, examen de module | 26 | **26/26** (jamais posé : on lit `started_at`) | 0 |
| CO/CE, sous-épreuve de complet | 45 | 25 | **12** (clôture paresseuse) |
| civique | 19 | — | 0 |

⚠️ **« Temps » n'est pas une donnée fiable telle quelle.** Une sous-épreuve est clôturée « à la
lecture suivante » après son échéance (`docs/regles/examens-temps.md`) : son `finished_at` est
alors l'heure de **retour** du candidat, pas celle où il a fini. Et l'EO n'a pas de chrono
d'épreuve (`timeLimitSeconds = null`). → décision **D9**.

### 2.4 Civique — un examen GLOBAL se découpe-t-il par thème ?

**Oui, intégralement.** Sur les 15 examens globaux de 40 Q terminés (diagnostics compris), les
**600 questions sur 600** ont un `questions.theme_id`, et les 5 thèmes sont présents dans chaque
examen. Le découpage existe déjà côté serveur : `AttemptQuestionRepository.aggregateByThemeAndType`
(`backend_sejourfr/src/main/java/com/sejourfr/app/repository/AttemptQuestionRepository.java:93`),
lu par `CivicDiagnosticViewService.resultat`.

Mais **la part d'un thème n'est jamais « / 20 »** :

- dans les examens historiques, antérieurs à la conformité P8.A, un thème a reçu **de 3 à
  13 questions** (mesuré). Exemple : `da01f614…` a posé T1 = 3, T2 = 11, T4 = 11 ;
- dans un examen **conforme** (arrêté du 10/10/2025, `SPEC_cycle_plan_civique.md` §0), la part est
  fixe : **T1 11 · T2 6 · T3 11 · T4 8 · T5 4**, sur 40.

Un « 16 / 20 » par thème, dans un examen global, n'a donc aucun sens : on sert « x / n posées ».
→ **D11**.

---

## 3. (A) Le paysage existant — ce qui recouvre, ce qui part, ce qui reste

### 3.1 Écrans qui recouvrent la demande

| Écran | Web | Mobile | Donnée | Maquette d'origine |
|---|---|---|---|---|
| **« Votre progression » globale**, ouverte depuis le Profil | `/statistiques` (`web_sejoufr/app/(app)/statistiques/page.tsx`, 755 l.) | `/progress` → `ProgresScreen` (`mobile_sejourfr/lib/screens/progres/progres_screen.dart`, 823 l.) | `GET /api/me/progress` + `GET /api/me/progress/tcf/{epreuve}/historique` + `GET /api/me/dashboard` | `docs/progression/ecran_progression_normal.html` (1ʳᵉ partie) |
| **« Vos résultats » d'une épreuve** | `/historique/epreuve/[domaine]` → `EpreuveHistoriqueView` (397 l.) | `/historiques/epreuve/:domainKey` → `EpreuveHistoriqueScreen` (442 l.) | `GET /api/me/progress/tcf/{epreuve}/historique` | `ou_en_vous.html` |
| **« Vos résultats » d'un thème** | `/historique/theme/[theme]` → `ThemeHistoriqueView` (354 l.) | `/historiques/theme/:themeId` → `ThemeHistoriqueScreen` (342 l.) | `GET /api/me/progress` + `GET /api/me/attempts?type=MOCK_EXAM&module=CIVIQUE&themeId=` | — |
| **« Ma progression » = historique des cycles** | `/plan/progression` → `PlanHistoryView` | `/plan/progression` → `PlanHistoryScreen` | `GET /api/me/plan/journey/history?module=` | `docs/progression/histo_cycle.html` |
| Historique de toutes les sessions | `/historique` (804 l.) | `/historiques`, `/history` (civique complets), `/historiques/tcf` (TCF complets) | `/api/me/attempts`, `/api/me/full-tcf-exams` | — |
| `/plan/evolution` | **déjà supprimé** (cf. `PlanHistoryView.tsx:68`) | — | — | — |

✅ **Les entrées depuis l'Accueil existent déjà, des deux côtés.** « Voir mes résultats » d'une
carte d'épreuve ouvre bien « Vos résultats » : `web_sejoufr/app/(app)/dashboard/page.tsx:846` ⇄
`mobile_sejourfr/lib/screens/home/home_screen.dart:730`. Pour un thème : `dashboard/page.tsx:979`
(`themeHistoriqueHref`) ⇄ `home_screen.dart:680`.
⚠️ **Mais seulement dans l'issue 3.** Une carte d'épreuve a trois issues
(`docs/regles/progression.md` § « Faire un exercice LANCE la mesure ») : 1) épreuve jamais mesurée
⇒ **lancer la mesure** ; 2) `EN_PROGRESSION` ⇒ **fiche du domaine du Plan** ; 3) sinon ⇒ résultats.
Seule l'issue 3 change de destination (**D17**).

⚠️ **Deux écrans portent aujourd'hui le nom « Ma progression »** : la ligne du Profil
(→ `/statistiques` ⇄ `/progress`, `web_sejoufr/app/(app)/profil/page.tsx:230` ⇄
`mobile_sejourfr/lib/screens/profile/profile_screen.dart:158`) et le bouton du Plan
(→ `/plan/progression`, l'historique des cycles). La refonte est l'occasion de lever l'homonymie
(**D16**).

### 3.2 Endpoints et DTO existants

| Endpoint | DTO | Ce qu'il sert | Ce qui manque pour les maquettes |
|---|---|---|---|
| `GET /api/me/progress` (`ProgressController.java:38`) | `ProgressDto` | palier **actuel** de chaque épreuve (moyenne des 3 derniers examens qualifiants, `levelProfileAccueil`), `niveauInitial`, `evolution`, `status`, palier global (plancher des 4), courbe des **diagnostics** ; civique : historique des **diagnostics** seulement, `themes` (`CivicPlanDto.ThemeLigne`) | aucun score par examen ; rien sur les examens civiques |
| `GET /api/me/progress/tcf/{epreuve}/historique` (`ProgressController.java:57`) | `EpreuveHistoriqueDto(epreuve, evaluations[mesureA, source, niveau])` | les évaluations qualifiantes, **plafonnées à 3** (`EpreuveHistoriqueService.java:108`, `MAX_EVALUATIONS = 3`), diagnostic rapide compris | score, identifiant d'attempt (pour « Voir → »), durée, ordinal, liste complète |
| `GET /api/me/attempts?type&module&moduleExamQuestionType&themeId` (`MeController.java:117`) | `AttemptSummaryResponse` | score, `totalQuestions`, `passThreshold`, `calibratedScore`, `cecrlLevel`, `slotNumber`, `lotThemeId`, dates | pas d'EE/EO, pas de sous-épreuves de complet, aucun état civique, aucun agrégat |
| `GET /api/me/full-tcf-exams?limit` (`FullTcfExamController.java:71`) | `FullTcfExamSummaryResponse` | `finalCecrlLevel`, `finalLevelPartial`, statut, continuité, slot | **aucun détail par épreuve** — alors que `FullTcfExamResponseBuilder.buildSummaries` le construit, puis le jette dans `toSummary` |
| `GET /api/full-tcf-exams/{id}` | `FullTcfExamResponse.SubAttempt` | par épreuve : `cecrlLevel`, `score/maxScore` (pondéré), `calibratedScore`, `locked`, chrono | pas de note /20 EE/EO (`score` est `null` en production) |
| `GET /api/attempts/{id}/production-bilan` | `ProductionBilanResponse` | `moyenneSur20` (= `ProductionBilanService.noteEpreuve`), `niveauGlobal` | forme unitaire (une session) |
| `GET /api/me/plan/journey/history` | `JourneyHistoryDto` | cycles historisés | — (autre sujet) |
| **`GET /api/me/progression?module=`** (`MeController.java:169`) | `ProgressionSummaryResponse` | un résumé ancien | 🛑 **Code mort** : son seul client, `UserContentRepository.progression` (`mobile_sejourfr/lib/core/api/user_content_repository.dart:87`), n'a **aucun appelant**, et ni le web ni l'admin ne l'appellent. **Son chemin est exactement celui qu'il faut à la nouvelle famille d'endpoints.** |

Le moteur V4.2 (`progression.*`, en SHADOW) **n'est pas concerné** : il ne sert aucun front
(`docs/regles/progression.md` § « Ce qui n'existe pas encore »). Les écrans demandés lisent des
**examens**, pas des `LearningEvidence`.

### 3.3 Ce qui est remplacé, et donc supprimé dans la même passe

*(Règle : « refonte = suppression immédiate de l'ancien ».)*

| Remplacé | Par | Supprimé avec lui |
|---|---|---|
| `/statistiques` ⇄ `/progress` (`ProgresScreen`) | écran **global** par module | page, route, `EpreuveStatRow/List`, `GoalHero`, `LevelStrip`, `ChartTitle`/`ChartNote` **si plus aucun lecteur** (à vérifier au grep au moment du lot), la section civique `ModuleProgressSection`, et les libellés `PROGRESSION_*` de `lib/progres.ts` ⇄ `progres_labels.dart` ; `AppSidebar.tsx:85`, le lien du Profil |
| `/historique/epreuve/[domaine]` ⇄ `/historiques/epreuve/:domainKey` | écran **épreuve** | vues, routes, `HISTORIQUE_*`, `progressionResultatsHref`, `AppRoutes.epreuveHistorique*` |
| `/historique/theme/[theme]` ⇄ `/historiques/theme/:themeId` | écran **thème** | vues, routes, `THEME_RESULTATS_*`, `themeHistoriqueHref`, `civiqueThemeCourbe`, `AppRoutes.themeHistorique*` |
| `GET /api/me/progress/tcf/{epreuve}/historique` | nouvel endpoint épreuve | `EpreuveHistoriqueService`, `EpreuveHistoriqueDto`, `SourceEvaluation` s'il n'a plus de lecteur, `EpreuveHistoriqueServiceIT` (réécrit, pas perdu), miroirs `EpreuveHistoriqueDto` / `EvaluationQualifianteDto` des fronts |
| `GET /api/me/progression` + `ProgressionSummaryResponse` + `MeService.progressionSummary` + `FullTcfExamService.findLatestForUser` (s'il n'a pas d'autre lecteur) | le même **chemin**, réattribué | modèle Dart `ProgressionSummary` |

⚠️ **Test front existant à mettre à jour, pas à supprimer** :
`mobile_sejourfr/test/plan_navigation_test.dart:19` gèle `AppRoutes.progress == '/progress'`.

### 3.4 Ce qui reste

- `GET /api/me/progress` et `ProgressDto` : l'Accueil en vit (« Où vous en êtes », « Votre
  progression »). **Inchangés.**
- `/plan/progression` (historique des **cycles**) : c'est un autre fait (ce qui a été
  **travaillé**), avec sa maquette validée (`histo_cycle.html`). Il reste ; seul son libellé
  d'entrée est à arbitrer (**D16**).
- `/historique`, `/history`, `/historiques/tcf` : la liste **exhaustive** des sessions, en cours
  comprises. L'écran global n'en montre que les 3 dernières, puis renvoie vers elle.
- `ProgresMouvement` (activité sur 28 jours, compétences tenues) : **hors maquettes** → **D15**.
- Les maquettes antérieures `ecran_progression_normal.html` et `histo_cycle.html` restent dans
  `docs/progression/` comme archive. La première ne décrit plus aucun écran vivant une fois
  `/statistiques` remplacé : la marquer « révoquée par `maquettes-progression/` ».

---

## 4. (B) Disponibilité des données, champ par champ

### 4.1 Les échelles TCF — ce que la maquette affiche et ce qui est vrai

| Épreuve | Maquette | Réalité du produit | Autorité |
|---|---|---|---|
| **CO / CE** | « 422 / 499 », bandes A1 100–199 · A2 200–299 · B1 300–399 · B2 400–499, titre « Score TCF IRN · /499 » | **Score de PROGRESSION 100–499** (`100 + max(0,(ratio−0,25)/0,75) × 399`). 🛑 **Aucune bande** : aucun palier ne dérive de ce nombre depuis le 2026-09-20. Le palier de l'examen vient **des strates** (60 % arrondi au supérieur, sans saut). Un candidat qui tient tout l'A2 est « **A2 avec 100 / 499** ». Titre « Score de progression », jamais « Score TCF ». | `TcfLevelEstimatorService.calibratedScore` / `.niveauxQcm` ; `docs/regles/qcm.md` ; libellé `scoreProgressionLabel` (`web_sejoufr/lib/exam-levels.ts` ⇄ `mobile_sejourfr/lib/core/models/full_tcf_exam.dart`) |
| **EE / EO** | « 367 / 499 » | **Note d'épreuve / 20, sur l'échelle OFFICIELLE du TCF** (`docs/notation-ia-eo-ee.md` §6.6). Bandes officielles : **0 = <A1 · 1 = A1 · 2–5 = A2 · 6–9 = B1 · 10–20 = B2**. Palier servi : `ProductionBilanService.niveauEpreuve` (3 tâches, poids égaux, plafond B2, garde-fou T3). | `ProductionBilanService.noteEpreuve` (la note affichée au bilan, `moyenneSur20`) ; `enums/BandeNoteTcf.java` (les bandes) |
| **Global** | « 384 / 499, Niveau B1 » | 🛑 **Il n'existe AUCUN score global**, et il ne peut pas en exister : on ne moyenne pas un score de progression /499 avec une note officielle /20. Ce qui existe est un **palier** global, le plancher des 4 épreuves (règle TCF IRN). | actuel : `ProgressDto.tcf.niveauActuel` (`TcfLevelEstimatorService.floor` sur `levelProfileAccueil`) ; par examen complet : `FullTcfExamResponse.finalCecrlLevel` + `finalLevelPartial` / `epreuvesCountedInFinalLevel` |

🛑 **Nombres de la maquette à remplacer, un par un** :

- `progression_epreuve_tcf.html` : chaque « / 499 » d'une EE/EO devient « / 20 ». Pour la CO et
  la CE, « / 499 » reste mais comme **score de progression**. Les bandes « A1 · 100–199 … B2 ·
  400–499 » (courbe **et** légende) **disparaissent en CO/CE**, et deviennent les bandes
  officielles /20 en EE/EO. « Score TCF IRN · /499 » devient « Score de progression · /499 » (ou
  « Note TCF · /20 »). Le pied de page « Barème affiché pour les épreuves QCM du TCF IRN » est
  **faux** : c'est notre barème de progression, pas celui du TCF.
- `progression_global_tcf.html` : « 384 / 499 », « 401 / 499 », « 353 / 499 » et « +31 points »
  **n'ont pas d'équivalent** et deviennent des **paliers** (§4.6.2). Dans les cartes et les lignes
  d'examen, EE et EO passent en « / 20 ».
- ⚠️ **Le palier et le score peuvent sembler se contredire, et c'est voulu** : « A2 · 100 / 499 »
  est un résultat normal. C'est précisément pourquoi une courbe /499 **à bandes CECRL** est
  interdite : elle poserait un point badgé A2 dans une bande « A1 ».

⚠️ **EE/EO — un seul écart note ⇄ palier possible, et il est assumé** : quand une tâche a été
**plafonnée** (`plafond_niveau`), la note affichée reste celle du barème alors que le palier est
abaissé (`ProductionBilanService.java:380-384`, « le plafond ne peut qu'abaisser »). Un point peut
donc tomber dans la bande B2 avec un badge B1. On l'affiche tel quel, avec une note de portée, et
on ne « corrige » rien côté front.

### 4.2 Le civique — échelles, états, thèmes

| Sujet | Maquette | Réalité | Autorité |
|---|---|---|---|
| Thèmes | 4 : « Valeurs de la République », « Institutions françaises », « Droits et devoirs », « Histoire et repères » | **5 thématiques officielles**, libellés servis : Principes et valeurs de la République · Système institutionnel et politique · Droits et devoirs · Histoire, géographie et culture · Vivre dans la société française | table `themes` (`module = CIVIQUE`), ordre `display_order` ; `ThemeLigne.label` |
| Examen de thème | « / 20 », « Examen thème n°7 » | **20 Q, seuil 16, 20 min** — format **SejourFR**, pas officiel (D-31) | `CivicExamFormat.QUESTIONS_THEME` / `SEUIL_REUSSITE_THEME` (`enums/CivicExamFormat.java:94-100`) ; servis par attempt (`totalQuestions`, `passThreshold`) |
| Examen global | « 17 / 20 » | **40 Q, seuil 32, 45 min** — format officiel | `CivicExamFormat.QUESTIONS` / `SEUIL_REUSSITE` (`:49-55`) |
| Part d'un thème dans un examen global | « Valeurs 16 / 20 » | **x / n posées**, n = 11 / 6 / 11 / 8 / 4 dans un examen conforme, de 3 à 13 dans l'historique (§2.4) | `aggregateByThemeAndType` (à grouper par lot d'attempts, §6.1) |
| États | « À renforcer 0–9 · Bonne maîtrise 10–14 · Très bon 15–20 » | **`CivicThemeState`** : `SOLIDE` (taux ≥ 0,80) · `A_RENFORCER` · `FAIBLE` (taux < 0,55) · `NON_EVALUE` (0 posée, **jamais** Faible). Sur 20 : **Faible 0–10 · À renforcer 11–15 · Solide 16–20**. Sur 40 : Faible 0–21 · À renforcer 22–31 · Solide 32–40. ✅ **La borne « Solide » tombe pile sur le seuil de réussite** (16/20, 32/40). | `CivicDiagnosticThemeResolver.etat(bonnes, posees)` (`service/diagnosticcivique/CivicDiagnosticThemeResolver.java:30-40`), seuils `application.yaml:1107-1109` ; libellés `CIVIC_THEME_STATE_LABEL` ⇄ `CivicThemeState.label` |
| Anneau « 85 % » | pourcentage | `bonnes / posées`, un nombre **servi** (taux) — pas un palier | `CivicDiagnosticThemeResolver.taux` |

🛑 **Les bandes civiques ne s'écrivent pas dans un front** : elles se **dérivent des seuils
0,55 / 0,80** et doivent être **servies** (bornes calculées serveur pour le total de l'examen).
Aujourd'hui, `themeResultatsVerdict` (`web_sejoufr/lib/progres.ts:1038`) compare déjà score et
seuil côté front. C'est toléré, puisqu'il s'agit de deux nombres servis et d'aucun état, mais la
nouvelle version doit servir le verdict.

⚠️ **Divergence à connaître : l'état d'un thème sur l'Accueil vient du DIAGNOSTIC, pas des
examens.** `CivicPlanService.etatDuTheme` (`service/plancivique/CivicPlanService.java:957`) lit le
**dernier diagnostic civique terminé**, et `ProgressDto.civique.historique` ne liste lui aussi que
des diagnostics (`ProgressService.java:299-329`). Un examen de thème réussi à 18/20 ne fait donc
**pas** bouger « À renforcer » sur l'Accueil. Si l'écran de thème sert un état tiré des
**examens** (la demande du propriétaire), les deux écrans peuvent afficher deux états différents
pour le même thème, le même jour. → **D13**.

⚠️ **Mises en situation.** Le diagnostic **exclut** les mises en situation de l'état d'un thème
(`CivicDiagnosticViewService.java:85-91`). Or l'arrêté les **place dans** T1 et T3 (6 chacune), et
les examens de thème T1/T3 en tirent. Les exclure réduirait la part de T1 dans un examen global à
5 questions. → **D11**.

### 4.3 Score par épreuve tiré d'un examen TCF complet

✅ **Disponible.** Chaque sous-attempt (`attempts.parent_attempt_id`) est une épreuve complète,
identique à l'épreuve passée seule (25 Q 10/8/7, même durée ; « une épreuve a la même durée où
qu'elle soit jouée »). La **comparer** à une épreuve isolée est donc légitime.

- CO/CE : `weighted_score` persisté (100 %) ⇒ score de progression ; palier par
  `niveauxQcm(ids)` en **une requête** pour toute la page.
- EE/EO : `EpreuvesProductionQualifiantesResolver.qualifiantes` rend déjà, **par lot**, session,
  date, palier et compétence. Il manque la **note /20 affichée** (`noteEpreuve`) : elle s'ajoute
  à `EpreuveQualifiante`, qui a déjà les évaluations sous la main.
- Épreuve **verrouillée** (freemium) ou **jamais ouverte** : aucune note, aucun palier. Elle est
  exclue de la liste de l'épreuve, et vaut « — » dans le détail d'un examen complet
  (`FullTcfExamResponseBuilder.mapSubAttempt`, `:202-230`).
- ⚠️ **N+1 à ne pas recopier** : pour EE/EO, `mapSubAttempt` appelle
  `productionSubmissionManager.findByAttemptId` **par sous-attempt**. La liste « Mes derniers
  examens blancs » ne doit pas passer par `buildResponse` examen par examen : elle passe par la
  forme par lot du résolveur de qualifiantes.

### 4.4 Temps, numérotation, meilleur, premier, écart, tendance

| Champ de maquette | Servi aujourd'hui ? | Calculable côté serveur ? | Proposition |
|---|---|---|---|
| « Examen blanc **n°7** » | non | oui | 🛑 **Pas le `slotNumber`** : c'est un créneau de grille (1..20), **réutilisé** à chaque rejeu (`AttemptSummaryResponse` : « refaire l'examen N met à jour la note du slot N »). Mesuré : le slot 1 revient 12 fois sur 29 examens complets. Servir un **ordinal chronologique** `numero` (1 = le plus ancien). → **D8** |
| « **Temps** 18 min 42 » | non | partiellement | `finished_at − coalesce(timer_started_at, started_at)`, servi **seulement** si l'épreuve s'est close dans sa limite + la grâce ; sinon `null` (« — »). **Toujours `null` en EO.** → **D9** |
| « **Meilleur** score 422 · 22 septembre » | non | oui | max du score **affiché** ; à égalité, le plus récent. Servi avec son palier et sa date. |
| « **Premier** résultat », « **Dernier** examen » | non | oui | extrémités chronologiques de la même liste |
| « ↗ **+148 points depuis le début** » | non | oui | `ecart = dernier − premier` (entier en /499 ; une décimale en /20 ; entier en civique), **servi**. Aucun écart avec un seul examen (`null`, pas « +0 »). |
| Flèche ↗ / ↘ | non | oui | un `sens` servi : `HAUSSE` / `BAISSE` / `STABLE` / `INCONNU`. 🛑 `BAISSE` se sert (« la masquer rendrait la réévaluation invendable ») ; `INCONNU` ne rend **aucun** marqueur. |
| Sparkline des cartes | non | oui | les **N derniers scores servis** (N = 7 sur la maquette), plus les bornes de l'axe. Le front **place** des points, il ne classe rien. |

⚠️ Ces écarts sont des **écarts de score**, pas des paliers. La règle « aucun pourcentage de
progression vers un palier » tient : on ne rend jamais « 68 % vers le B2 ».

### 4.5 « Niveau global estimé » TCF

**L'autorité existe déjà, et on ne l'invente pas** : `ProgressDto.tcf.niveauActuel`, c'est-à-dire
le **plancher des 4 paliers affichés** (chacun la moyenne des 3 derniers examens qualifiants), par
`TcfLevelEstimatorService.floor` (`docs/regles/progression.md` § « Le niveau AFFICHÉ = la MOYENNE
des 3 derniers examens qualifiants »). C'est le même chiffre que sur l'Accueil et le Profil.

Par examen complet : `finalCecrlLevel` (plancher des épreuves **réellement passées**), avec
`finalLevelPartial` quand moins de 4 épreuves ont compté.

🛑 **Pas de score global, pas de « 384 / 499 »** (§4.1). L'écart « +31 points » devient une
**évolution de palier** entre le premier et le dernier examen complet **non partiel**, servie par
l'autorité existante `TcfDiagnosticProgressionResolver.evolution(initial, actuel)`. Il n'y a pas
de seconde comparaison de paliers.

### 4.6 Bloc par bloc — visuel repris, donnée servie

Légende : **V** = visuel repris tel quel · **D** = donnée servie par … · **A** = bloc adapté, parce
que … · **∅** = n'existe pas aujourd'hui, à servir (§6.1).

#### 4.6.1 `progression_epreuve_tcf.html` — une épreuve

| Bloc | Verdict |
|---|---|
| Barre haute : ← + nom d'épreuve, bouton « Nouvel examen blanc » | **V.** Retour = la pile (Accueil ou écran global). Le CTA ouvre la **grille d'examens de l'épreuve**, jamais un démarrage direct (§6.5). Bouton **bleu**, comme sur la maquette : ce n'est pas un CTA critique. |
| Eyebrow « Votre progression » + titre + phrase | **V.** Nom d'épreuve : `EPREUVE_PRESENTATION` ⇄ `EpreuveType.displayLabel` (tables existantes). Phrase réécrite : « score de progression », pas « score TCF IRN ». |
| Carte « Dernier résultat » : gros score, « / max », palier, écart, anneau | **V** + **∅**. Score : CO/CE `calibratedScore` (/499), EE/EO `noteEpreuve` (/20). Palier **de cet examen**, servi (strates ⇄ bilan). Écart et sens servis. Anneau : **D5**. Secondaire : « Niveau actuel estimé », servi par `ProgressDto` (**D4**). |
| Encart « Meilleur score » | **V** + **∅** (`meilleur` servi) |
| Encart « Examens réalisés » | **V** + **∅** (`nombre` servi). ⚠️ Libellé « examens blancs terminés » : on compte les examens **qualifiants** (au moins une réponse / une soumission), pas les sessions ouvertes. |
| « Évolution de votre score » : courbe à bandes, pastilles de valeur | **V** (aire + ligne + dernier point mis en avant). **A** en CO/CE : **pas de bandes** (§4.1), des repères neutres 100 / 200 / 300 / 400 / 499. EE/EO : bandes officielles **servies** (`BandeNoteTcf`). Le dernier point est **bleu**, pas rouge (§5.4). |
| Légende de l'échelle A1 … B2 | **A.** CO/CE : remplacée par une note de portée (« Score de progression : il mesure votre avancée d'un examen à l'autre ; votre niveau se lit palier par palier »). EE/EO : légende des bandes servies, libellés « <A1 · A1 · A2 · B1 · B2 ». |
| « Mes examens blancs », du plus récent au plus ancien | **V** + **∅** : n°, date, score, badge de palier, temps, « Voir → ». Provenance servie (épreuve seule / examen complet), dite dans la ligne. |
| Pied « Barème affiché pour les épreuves QCM du TCF IRN. » | **A** : faux, remplacé par la note de portée ci-dessus. |

#### 4.6.2 `progression_global_tcf.html` — TCF global

| Bloc | Verdict |
|---|---|
| ← « Tableau de bord », « Faire un examen blanc » | **V.** Retour : Accueil. CTA : la grille des examens blancs **complets** (web `/examens-blancs` onglet TCF ⇄ mobile `AppRoutes.tcfFullExams`). Ouvert aux comptes gratuits (§6.5). |
| Carte « Dernier niveau global estimé 384 / 499 Niveau B1, +31 points, anneau » | **A** : il n'existe aucun score global. **Palier global actuel** en gros (`ProgressDto.tcf.niveauActuel`), puis « Dernier examen blanc complet : B1 (partiel : 3 épreuves sur 4) », servi. Évolution de palier servie à la place des points. Anneau : **D5**. |
| 4 encarts : Examens blancs · Meilleur · Première évaluation · Dernier examen | **V** (`StatGrid` ⇄ `SfStatGrid`, déjà dans les deux kits). **A** : Meilleur et Première sont des **paliers** (`finalCecrlLevel`), pas des « / 499 ». Compteur : **D7**. |
| « Progression par épreuve » : 4 cartes (pictogramme, nom, dernier score, palier, écart, sparkline, ›) | **V.** Pictogrammes **Lucide** existants au lieu des émojis (`SITUATION_EPREUVE_ICON` ⇄ `_situationIcon`). Données : le **résumé** de chaque épreuve, le même que l'en-tête de l'écran épreuve (une seule autorité). EE/EO en « / 20 ». Épreuve sans examen : « Pas encore d'examen » (`SUIVI_SANS_EXAMEN_LABEL` ⇄ `kSuiviSansExamenLabel`), sans sparkline ni écart. Les 4 épreuves sont **toujours** servies. |
| « Mes derniers examens blancs » : lignes avec CO / CE / EE / EO et badge global | **V** + **∅** : `FullTcfExamSummaryResponse` étendu d'un détail par épreuve (score, max, palier, `locked`). Épreuve verrouillée ou jamais ouverte : « — », jamais « 0 ». Badge global = `finalCecrlLevel`, mention « partiel » si `finalLevelPartial`. 3 derniers, puis « Tous mes examens blancs » vers l'historique existant. |
| Pied « Le détail de chaque épreuve ouvre l'écran de progression dédié. » | **V.** |

#### 4.6.3 `progression_global_civique.html` — civique global

| Bloc | Verdict |
|---|---|
| ← « Tableau de bord », « Faire un examen blanc global » | **V.** CTA : la grille des examens civiques globaux (web `/examens-blancs` onglet civique ⇄ mobile `AppRoutes.civiqueExamsBlanc`). Le créneau offert `civique-decouverte` reste gratuit (D-33). |
| Carte « Dernier résultat global 17 / 20, Très bon, +5 points, anneau 85 % » | **A** : « **/ 40** », « seuil 32 » servi, verdict « seuil atteint / il manque N points » servi (la phrase existe déjà : `SPEC_cycle_plan_civique.md` §4, « 29 / 40, il manque 3 points »). État : `CivicDiagnosticThemeResolver.etat` (**D12**). Anneau = taux servi, **vert** au seuil, **bleu** en dessous. |
| 4 encarts | **V** + **∅** (en /40). |
| « Progression par thème » : **4** cartes | **A** : **5** cartes, noms et ordre servis. « Dernier examen du thème » = dernier **examen de thème** (/20). Sans examen de thème : « Pas encore d'examen de thème », **D10/D11** pour la part issue d'un examen global. Pictogrammes Lucide existants (`SITUATION_THEME_ICON` ⇄ `_situationThemeIcon`) au lieu de 🇫🇷🏛️⚖️🗺️. |
| « Mes derniers examens globaux » : parts par thème « / 20 », « Global : 17 / 20 » | **A** : parts « x / n » (§2.4), noms courts servis, « Global : x / 40 ». 3 derniers, puis l'historique existant. |

#### 4.6.4 `progression_theme_civique.html` — un thème

| Bloc | Verdict |
|---|---|
| ← « Examen civique », « Nouvel examen blanc » | **V.** Retour : l'écran civique global (ou l'Accueil, selon la pile). CTA : la grille du thème (`civicThemeExamsHref` ⇄ `AppRoutes.civiqueThemeExams`). 🛑 **Premium** (D-33) : la grille sert son propre verrou, l'écran n'en pose aucun. |
| Titre « Thème : Valeurs de la République » | **A** : nom complet servi. |
| Carte « Dernier résultat 16 / 20 Bonne maîtrise, +6, anneau 80 % » | **V** + **∅** : score / 20 servi, seuil 16 servi, état **servi** (`SOLIDE` à 16/20), écart servi. ⚠️ C'est l'état **de l'examen**, pas celui de l'Accueil (**D13**). |
| « Meilleur score », « Examens réalisés » | **V** + **∅** |
| Courbe à 3 bandes « Très bon 15–20 / Bonne maîtrise 10–14 / À renforcer 0–9 » | **V** (même style de courbe). **A** : bandes **servies** Faible 0–10 · À renforcer 11–15 · Solide 16–20, plus le trait de seuil 16 (`ChartRung.seuil` existe déjà). |
| Légende de l'échelle | **A** : les 3 bandes servies, libellés gelés. |
| Liste « Examen thème n°7 · 16 / 20 · Très bon · Temps · Voir → » | **V** + **∅** : ordinal servi, état servi, temps servi (**D9**), lien vers le rapport d'attempt. |

### 4.7 Incohérences internes aux maquettes (signalées, pas à reproduire)

- Thème : la carte de tête dit « 16 / 20 **Bonne maîtrise** », la ligne n°7 dit « 16 / 20 **Très
  bon** », et la bande « Très bon » commence à 15. La même note porte deux états : c'est
  exactement ce qu'empêche un état **servi**.
- Thème : « Meilleur score 17 / 20 · 22 septembre », alors que l'examen du 22 septembre vaut 16.
- Global civique : « 17 / 20 » pour un examen de **40** questions.
- Épreuve CO : la courbe a 7 points pour 4 dates et 4 lignes affichées. Il faut décider si la
  liste est tronquée (« Voir tout ») : **D8**.
- Global TCF : « Meilleur résultat 401 · **B2** », alors que chaque ligne d'examen porte un badge
  global **B1**. Un meilleur **palier** ne peut pas sortir d'une liste dont aucun examen ne l'a
  atteint.

---

## 5. (C) Conflits avec les invariants

1. **« Aucun front ne classe un nombre en état ou en niveau CECRL. »** Les bandes, badges,
   verdicts (« seuil atteint »), états civiques, écarts, sens et compteurs sont **servis**. Les
   fronts **placent** des points sur un axe dont les bornes sont servies (comme `LevelChart`
   aujourd'hui) : placer n'est pas classer. `node scripts/verifier-contrat-front-progression.mjs`
   doit rester vert. ⚠️ Sa règle 3 refuse **un pourcentage et un libellé CECRL dans le même
   bloc** : l'anneau TCF de la maquette, avec « B2 » au centre d'un disque rempli à 84 %, tombe
   exactement dessus (**D5**).
2. **`null` = inconnu.** Épreuve jamais passée, épreuve verrouillée, sous-épreuve jamais ouverte,
   évaluation IA en vol, thème jamais posé : « — » ou « Pas encore d'examen », **jamais** 0,
   « A1 » ni « Faible ». Aucun écart avec un seul point. `NON_EVALUE` reste **neutre**.
3. **Freemium.** 🛑 « Ce qui se ferme est l'**exécution**, jamais l'**affichage** »
   (`docs/regles/freemium.md`). Un compte gratuit voit **tous** ses résultats sur ces écrans, et
   ces DTO ne portent **aucun** `locked` de lecture. Seuls les CTA mènent à une porte qui peut
   être fermée, et c'est la **grille** qui sert son `locked` (§6.5). ⚠️ `docs/regles/freemium.md`
   dit encore « slot 1 offert » pour les examens de **thème** civique, alors que D-33
   (`SPEC_cycle_plan_civique.md` §3.3) et le code (`AttemptService.java:168-188`) les rendent
   **premium**. Le doc est périmé sur ce point.
4. **Couleurs en dur → jetons.** Les maquettes déclarent leur palette : `--brand:#102c62`,
   `--red:#e2363a`, `--green:#26785d`, `#edf0f4`… (entre 22 et 31 littéraux par fichier). On prend
   les jetons (`var(--color-blue|red|green|amber|line|ink|muted)` ⇄ `AppColors.*`). 🛑 **Le
   rouge est réservé aux CTA critiques** (`docs/identite-visuelle.md`). Or les maquettes le
   mettent sur l'**anneau** (épreuve, thème, global civique), sur le **dernier point** de la
   courbe et dans l'eyebrow. L'eyebrow à pastille rouge existe déjà dans le kit (`.heroDot`) :
   on le garde. L'anneau et le dernier point passent au **bleu**, et au **vert** quand le seuil
   est atteint (sémantique actuelle de `Ring` ⇄ `SfRing`).
5. **Polices.** Les maquettes sont en **Inter**. Le web et le mobile sont en **Plus Jakarta
   Sans**, titres en **Fraunces**, valeurs en **JetBrains Mono** : on garde nos polices. Les
   titres « Compréhension orale » passent en Fraunces.
6. **Émojis → pictogrammes produit.** 🎧📖✍️🎙️ et 🇫🇷🏛️⚖️🗺️ deviennent les icônes Lucide déjà
   déclarées **une fois par front** (voir §4.6).
7. **Courbe : réutiliser `LevelChart` ⇄ `SfLevelChart`** (`SejourKit.tsx:1757` ⇄
   `sejour_kit.dart:3653`). Elle prend déjà `rungs` (libellé + hauteur, avec `seuil`) et `points`.
   Il lui manque des **bandes** colorées, une **aire** sous la ligne et un **dernier point
   accentué**. On les ajoute en options, dans les deux kits, dans la même passe.
8. **Dérivé ⇒ jamais persisté.** Rien de neuf n'est persisté. ⚠️ **Défaut existant révélé** :
   `FullTcfExamResponseBuilder` (`:119-121`) **préfère** `attempts.final_cecrl_level` **persisté**
   à la re-dérivation. Les 6 valeurs en base, toutes `A1_NON_ATTEINT`, ont été écrites **sous
   l'ancienne règle QCM** (juin–août). Cela contredit la doctrine de `qcm.md` (« un changement de
   règle relit tout l'historique, sans migration »). L'écran global afficherait ces paliers
   figés. → **D19** (ticket backend séparé, avec test).
9. **Duplication.** L'écran épreuve et les cartes du global montrent le **même** résumé
   d'épreuve : un seul record serveur, une seule brique de kit.
10. **Parité.** Un endpoint par écran, **le même** pour les deux fronts. Mêmes briques des deux
    côtés. Seule exception admise : une media query du palier desktop web, sans miroir Flutter.
11. **Aucun test front nouveau.** Vérification par `npx tsc --noEmit`, `npm run build`,
    `flutter analyze` et le vérificateur T36.

---

## 6. (D) Architecture proposée

### 6.1 Backend — endpoints et DTO

On **réattribue** le chemin mort `/api/me/progression` (§3.2). Ordre de lecture : un résumé par
module, puis un détail par épreuve ou par thème.

```
GET /api/me/progression/tcf                      → ProgressionTcfDto
GET /api/me/progression/tcf/{epreuve}            → ProgressionEpreuveDto   (TCF_CO|CE|EE|EO, sinon 400)
GET /api/me/progression/civique                  → ProgressionCiviqueDto
GET /api/me/progression/civique/themes/{themeId} → ProgressionThemeDto     (thème du module, sinon 404)
```

Formes (records Java, miroirs à la main : `web_sejoufr/lib/types.ts`,
`mobile_sejourfr/lib/core/models/progression_models.dart`) :

```text
Echelle        { min, max, unite: PROGRESSION_499 | NOTE_20 | QUESTIONS,
                 bandes: [ { libelle, niveau?: NiveauCecrl, etat?: CivicThemeState, min, max } ],  // [] en CO/CE
                 seuil?: int, reperes: int[] }                                                      // lignes neutres de l'axe
Mesure         { attemptId, parentAttemptId?, numero, date, score: decimal, max,
                 niveau?: NiveauCecrl, etat?: CivicThemeState, dureeSecondes?,
                 provenance: EPREUVE_SEULE | EXAMEN_COMPLET | EXAMEN_THEME | EXAMEN_GLOBAL,
                 rapport: { kind: QCM | PRODUCTION | EXAMEN_COMPLET, attemptId } }
Resume         { nombre, dernier?: Mesure, meilleur?: Mesure, premier?: Mesure,
                 ecart?: decimal, sens: HAUSSE|BAISSE|STABLE|INCONNU, jauge?: 0..1,
                 serie: decimal[] /* N derniers scores, du plus ancien au plus récent */ }

ProgressionEpreuveDto { epreuve, echelle, resume, niveauActuel?, examens: Mesure[] }
ProgressionTcfDto     { niveauActuel?, evolution, examensComplets: { nombre, meilleur?, premier?, dernierLe? },
                        epreuves: [ { epreuve, echelle, resume } ×4, toujours servies ],
                        derniers: [ { parentId, numero, date, finalLevel?, partiel, continuite?,
                                      parEpreuve: [ { epreuve, score?, max?, niveau?, locked } ×4 ] } ] }
ProgressionThemeDto   { themeId, code, label, echelle, resume, examens: Mesure[] }
ProgressionCiviqueDto { echelleGlobale, global: Resume,
                        themes: [ { themeId, code, label, echelle, resume } ×5, toujours servis ],
                        derniers: [ { attemptId, numero, date, bonnes, posees, seuil, etat,
                                      parTheme: [ { themeId, bonnes, posees, etat } ×5 ] } ] }
```

🛑 `jauge` n'est servie que si l'anneau est retenu (**D5**). `bandes` sort de `BandeNoteTcf` en
EE/EO, et des seuils de `CivicDiagnosticProperties` appliqués au total de l'examen en civique.

**Couches** (Controller → Service → Manager → Repository, strict) :

| Classe | Rôle |
|---|---|
| `ProgressionController` (nouveau, `/api/me/progression`) | ultra-fin, 4 routes |
| `service/progres/ProgressionExamensService` | orchestre. Ne touche **aucun** repository. |
| `service/progres/ResumeExamensResolver` (pur, `@Component`) | numérotation, meilleur, premier, écart, sens, série. **Le seul code neuf à règle**, testé aux bornes. |
| `AttemptManager` | `findQcmEpreuvesPassees` / `findProductionEpreuvesPassees` **réutilisées**, avec une limite plus haute (50) ; nouvelle méthode `findCivicExamsPasses(userId, themeId?)` ; `findSubAttempts(parentIds)` existe déjà |
| `AttemptQuestionManager` | nouvelle `partsParTheme(Collection<UUID>)`, forme **par lot** de `aggregateByThemeAndType` (une requête pour toute la page) |
| Autorités **appelées, jamais recopiées** | `TcfLevelEstimatorService.niveauxQcm` / `calibratedScore` / `floor` ; `EpreuvesProductionQualifiantesResolver` (+ `noteEpreuve` dans son record) ; `ProductionBilanService` ; `BandeNoteTcf` ; `CivicDiagnosticThemeResolver.etat` / `taux` ; `TcfLevelProfile` via `TcfProfileService.levelProfileAccueil` ; `TcfDiagnosticProgressionResolver.evolution` ; `FullTcfExamResponseBuilder.buildSummaries` (réutilisée pour les sous-épreuves QCM, **pas** pour EE/EO, §4.3) |

**Tests backend (même passe)** — gabarits de `docs/plan-tests-backend.md` :

- `ResumeExamensResolverTest` : 0 / 1 / 2 / N examens, égalité au meilleur, écart négatif
  (`BAISSE`), `null` partout à 0 examen, ordinal stable.
- `ProgressionExamensServiceTest` (Mockito) : EE/EO en /20 avec bandes officielles, CO/CE sans
  bande, épreuve verrouillée exclue, sous-épreuve jamais ouverte exclue, `NON_EVALUE` sur un thème
  à 0 posée.
- `ProgressionExamensServiceIT` (Zonky) : les deux provenances CO/CE (module + complet), les deux
  provenances EE/EO, un examen de thème, une part de thème dans un examen global conforme
  (11/6/11/8/4), un compte gratuit qui **voit** tout.
- `ProgressionSansNPlusUnIT` : nombre de requêtes **égal** entre 1 et 6 examens (patron de
  `NiveauQcmDeriveSansNPlusUnIT`), sur les 4 endpoints.
- Suppression de `EpreuveHistoriqueServiceIT` et des tests de `progressionSummary`, **après**
  report des cas encore pertinents.

### 6.2 Routes

| Écran | Web | Mobile |
|---|---|---|
| Global (par module) | `/progression?module=TCF\|CIVIQUE` (`?module=`, **l'unique** mécanisme de sélection du web ; TCF par défaut) | `/progression` (module lu comme sur Plan et Accueil : `parcoursCiviqueProvider`) |
| Épreuve | `/progression/tcf/[domaine]` (`co\|ce\|ee\|eo`, `planDomainSlug`) | `/progression/tcf/:domainKey` (`planDomainKey`) |
| Thème | `/progression/civique/[theme]` (slug `themeSlug(code)`, UUID accepté) | `/progression/civique/:themeId` |

Le préfixe `/progression` entre dans `APP_GROUP_PREFIXES` (`web_sejoufr/lib/chrome-routes.ts`).
Anciennes routes : **supprimées** (règle de refonte). On n'ajoute une redirection que si le
propriétaire veut préserver des liens déjà partagés (**D14**).

### 6.3 Kit — à réutiliser, à ajouter (dans les deux kits, même passe)

| Besoin | Web `SejourKit.tsx` | Mobile `sejour_kit.dart` | Action |
|---|---|---|---|
| 4 encarts de synthèse | `StatGrid` (`:2335`) | `SfStatGrid` (`:2506`) | réutiliser |
| Courbe | `LevelChart` (`:1757`) | `SfLevelChart` (`:3653`) | **étendre** : `bands`, `area`, dernier point accentué, valeur en pastille |
| Anneau de la carte de tête | `Ring` (`:678`, 40 px fixe, sans centre) | `SfRing` (`:1016`, `size`/`stroke`) | **étendre** : taille et contenu central. Aligner le web sur le `size` du mobile (rattrapage de parité). |
| Carte de tête « Dernier résultat » | — (`ResultHero` est un héros sombre à objectif) | — | **nouvelle** `ProgressHero` ⇄ `SfProgressHero` : score, « / max », pastille de palier ou d'état, ligne d'écart, anneau, ligne secondaire |
| Carte d'épreuve / de thème avec sparkline | — | — | **nouvelles** `ProgressCard` + `Sparkline` ⇄ `SfProgressCard` + `SfSparkline` ; grille : patron de `LevelCardGrid` (container query, 2 → 4 colonnes ; 3 + 2 en civique) |
| Ligne d'examen (n°, date, score, badge, temps, « Voir → ») | `HistoryRow` (`:1879`, dépliable) | `SfHistoryRow` (`:3934`) | **nouvelle** `ExamResultRow` ⇄ `SfExamResultRow`. Sa carte-alternative mobile est native : c'est la ligne elle-même. |
| Ligne d'examen complet avec détail par épreuve ou thème | — | — | **nouvelle** `FullExamRow` ⇄ `SfFullExamRow` (puces « CO 392 / 499 », « EE 12 / 20 », « — » si verrouillée) |
| Légende d'échelle | — | — | **nouvelle** `ScaleLegend` ⇄ `SfScaleLegend`, alimentée par `echelle.bandes` |
| En-tête de page + CTA | `Top` / `TopSlot` | `SfTop` / `SfTopSlot` | réutiliser |
| Note de pied | `MicroNote` / `InfoNote` | `SfMicroNote` / `SfInfoNote` | réutiliser |

Briques orphelines après suppression de `/statistiques` et des deux « Vos résultats » :
`ResultHero`, `FilterChips`, `HistoryRow`, `EpreuveStatRow/List`, `GoalHero`, `LevelStrip`,
`ChartTitle`, `ChartNote`. Chacune est **supprimée des deux kits** si un grep ne lui trouve plus
aucun lecteur.

### 6.4 Carte de navigation

```
Accueil « Où vous en êtes »
 ├─ carte d'épreuve — issue 3 « Voir mes résultats » ─→ /progression/tcf/{co|ce|ee|eo}
 │     (issues 1 « lancer la mesure » et 2 « fiche du domaine » : inchangées)
 └─ carte de thème « Voir mes résultats » ────────────→ /progression/civique/{theme}
Profil « Ma progression » ────────────────────────────→ /progression (?module du parcours actif)
Plan « Voir ma progression » ─────────────────────────→ D16 (cycles ou global)
/progression (TCF)
 ├─ carte d'épreuve ›  ─→ /progression/tcf/{x}          ← retour : /progression
 ├─ ligne d'examen complet ─→ bilan d'examen complet
 │       (web /examens-blancs/tcf/[id]/bilan ⇄ mobile /tcf/examen-blanc/:parentId/bilan)
 └─ « Faire un examen blanc » ─→ grille des examens complets
/progression (civique)
 ├─ carte de thème › ─→ /progression/civique/{theme}    ← retour : /progression?module=CIVIQUE
 ├─ ligne d'examen global ─→ rapport d'attempt (web /sessions/[id] ⇄ mobile /exam-report/:attemptId)
 └─ « Faire un examen blanc global » ─→ grille civique globale
/progression/tcf/{x}
 ├─ « Voir → » : QCM ─→ /sessions/[id] ⇄ /exam-report/:id
 │              EE/EO ─→ /entrainement/tcf/{ee|eo}/session/[id] ⇄ /tcf/{ee|eo}/sessions/:attemptId
 │              sous-épreuve de complet ─→ bilan de l'examen complet (parentAttemptId)
 └─ « Nouvel examen blanc » ─→ grille de l'épreuve
        (web /entrainement/tcf/[code]/examens, /entrainement/tcf/{ee|eo}/examens
         ⇄ mobile tcfCoExams / tcfCeExams / ProductionExamsScreen)
```

Le retour est **la pile** (`retourOuRepli` côté mobile), avec repli sur l'écran global. La
destination de « Voir → » est choisie par le **`rapport.kind` servi**, jamais déduite d'une route.
C'est le patron de `PlanDomainAssessmentDto`.

### 6.5 Les CTA et le freemium

- Les CTA mènent à la **grille**, jamais à un démarrage direct. C'est la grille qui connaît les
  créneaux et sert leurs verrous (`enforceMockExamSlotAccess` pour les QCM, gratuités nominatives
  EE/EO, D-33 pour le civique). L'écran de progression **n'ajoute aucun verrou**. Deux verrous sur
  un même bouton est le patron que D-33 a supprimé.
- Ce qu'un compte gratuit trouve derrière chaque CTA :

| CTA | Compte gratuit |
|---|---|
| CO / CE | créneau 1 **offert et rejouable**, créneaux 2+ verrouillés |
| EE / EO | 1 examen **corrigé** offert par épreuve (ledger), puis l'analyse est premium |
| Examen TCF complet | **accessible**, chaque épreuve de production y est incluse tant que sa gratuité n'est pas consommée |
| Thème civique | **premium** |
| Global civique | `civique-decouverte` gratuit, le reste premium |

---

## 7. (E) Effort et risques

| Lot | Contenu | Estimation |
|---|---|---|
| **L1 Backend** | 4 endpoints, DTO, `ResumeExamensResolver`, `partsParTheme` par lot, `noteEpreuve` dans les qualifiantes, extension de `FullTcfExamSummary` (ou record dédié), tests Test + IT + N+1, suppression de l'ancien endpoint et de `/api/me/progression` legacy | **5 j** |
| **L2 Kits** | `LevelChart` étendu, `Ring` étendu (taille + centre, parité web), `ProgressHero`, `ProgressCard`, `Sparkline`, `ExamResultRow`, `FullExamRow`, `ScaleLegend` — **×2 kits** | **3,5 j** |
| **L3 Web** | 3 routes, miroirs `types.ts`, `api.ts`, libellés dans `lib/progres.ts`, Accueil (issue 3 + thème), Profil, Plan, sidebar, responsive 360 / 768 / 1280 | **2,5 j** |
| **L4 Mobile** | 3 routes, modèles Dart, repository + providers Riverpod, `home_screen`, Profil, Plan | **3 j** |
| **L5 Nettoyage** | suppression de `/statistiques` ⇄ `ProgresScreen`, des deux « Vos résultats », des briques orphelines des deux kits, de `ProgressionSummary` ; mise à jour de `plan_navigation_test.dart:19` ; `tsc`, `build`, `flutter analyze`, T36 | **1 j** |
| **L6 Docs** | `docs/regles/progression.md` (nouvelle section, révocation de « La page Voir mes résultats »), `docs/api-endpoints.md`, les `CLAUDE.md` web/mobile, `SPEC_cycle_plan.md` §8 (« écran bloqué » → levé), correction de `freemium.md` (thème civique premium) | **0,5 j** |
| **Total** | | **≈ 15,5 j** |

**Risques**

1. **Données héritées** : 8 attempts `TCF_CO` de **50 et 60 questions** (anciens examens complets
   d'avant V96, CO et CE mêlés) répondent au prédicat de `findQcmEpreuvesPassees`. Ils
   apparaîtraient comme des « examens de CO ». Le filtrer dans la nouvelle liste **seulement**
   créerait une seconde définition de « qualifiant ». → **D18** (mesurer la production d'abord).
2. **Clôture paresseuse** : 12 sous-épreuves sur 45 ont un `finished_at` **postérieur** à leur
   échéance (§2.3). Sans la règle de **D9**, la colonne « Temps » afficherait des heures.
3. **Examens complets vides** (§2.2 : 11 sur 29 seulement ont au moins une épreuve exploitable) : le compteur global et « Meilleur / Première »
   doivent ignorer les examens sans aucune épreuve mesurée (**D7**).
4. **Paliers figés** par `final_cecrl_level` persisté (§5.8, **D19**).
5. **Divergence d'état civique** Accueil (diagnostic) ⇄ thème (examens) (**D13**).
6. **Peu de points** : la plupart des candidats auront 0 ou 1 examen par épreuve. L'état vide et
   l'état à un point doivent être conçus et soignés **avant** l'état à 7 points de la maquette.
7. **Coût de lecture** : l'écran global TCF agrège 4 épreuves, dont 2 de production, plus
   3 examens complets. À tenir en requêtes **constantes**, sous peine de retomber sur le N+1 de
   `mapSubAttempt`.

---

## 8. (F) Décisions à arbitrer

**D1 — Quels examens comptent pour une épreuve TCF.**
Options : (a) examens blancs seulement, épreuve seule + sous-épreuve d'examen complet ;
(b) (a) + sections de diagnostic complet ; (c) (b) + diagnostic rapide.
➜ **Recommandation : (a)**, conforme à la demande (« progression calculée sur les EXAMENS ») et à
la maquette (« chaque point = un examen blanc »). Les sections de diagnostic complet sont des QCM
de 15 questions, de composition différente, et le diagnostic rapide n'a pas de score. Conséquence
assumée : le **niveau actuel** servi, qui les compte, peut s'appuyer sur une mesure absente de la
liste. D4 le dit à l'écran.

**D2 — Échelle CO/CE.** ➜ **Score de progression 100–499, SANS bandes CECRL**, repères neutres
100 / 200 / 300 / 400 / 499, badge de palier **servi** par examen, titre « Score de progression ».
La maquette montre la table révoquée le 2026-09-20 ; la reprendre réintroduirait « la bande A2
inatteignable ».

**D3 — Échelle EE/EO.** ➜ **Note d'épreuve / 20** (`noteEpreuve`, celle du bilan), bandes
officielles `BandeNoteTcf` **servies** (0 · 1 · 2–5 · 6–9 · 10–20), badge = palier servi. L'écart
dû au plafonnement (§4.1) est affiché tel quel, avec une note de portée.

**D4 — Le palier de la carte de tête d'une épreuve.** Options : (a) le palier **du dernier
examen** ; (b) le **niveau actuel estimé** (moyenne des 3 derniers, le chiffre de l'Accueil) ;
(c) les deux.
➜ **Recommandation : (c)**. En gros, « Dernier résultat » avec **son** palier (la maquette) ;
dessous, « Niveau actuel estimé : B1 », servi par `ProgressDto`. Sans cette seconde ligne, le
candidat qui arrive de l'Accueil lit « B1 » sur la carte et « B2 » sur l'écran suivant.

**D5 — L'anneau.** Options : (a) le garder partout, rempli d'un taux servi ; (b) le garder en
civique seulement (taux de bonnes réponses, vert au seuil), le retirer en TCF ; (c) le retirer
partout.
➜ **Recommandation : (b)**. En TCF, un disque rempli « à 84 % » avec « B2 » au centre est un
pourcentage **et** un palier dans le même bloc (le vérificateur T36 le refuse), et 100 / 499 y
paraîtrait « 20 % » alors que c'est le hasard pur. En civique, le taux est une donnée réelle, et
le seuil de 80 % lui donne un sens. Si le propriétaire tient à l'anneau en TCF : jauge **servie**
`(score − min) / (max − min)`, score au centre, **jamais** le palier.

**D6 — Carte de tête globale TCF.** ➜ Palier global **actuel** (`niveauActuel`, plancher des 4),
plus le dernier examen complet (palier + « partiel » servi), plus une **évolution de palier**
servie. Aucun score global, aucun « +31 points ».

**D7 — Ce que compte « Examens blancs · N terminés » (TCF global).** ➜ Les examens complets **dont
au moins une épreuve est mesurée** (`epreuvesCountedInFinalLevel ≥ 1`). « Meilleur » et
« Première évaluation » ne regardent **que** les examens **non partiels**. Sinon, les coquilles vides
entrent dans le compte : seuls 11 examens complets sur 29 ont au moins une épreuve exploitable
(§2.2).

**D8 — Numérotation et longueur de liste.** ➜ **Ordinal chronologique servi** (`numero`), jamais
le `slotNumber`. Liste **entière** sur l'écran épreuve / thème (au plus 50, du plus récent au plus
ancien) : la courbe et la liste montrent alors les mêmes examens. Sur l'écran global : les 3
derniers, puis « Tous mes examens blancs » vers l'historique existant.

**D9 — « Temps ».** Options : (a) le servir quand il est fiable, « — » sinon ; (b) retirer la
colonne.
➜ **Recommandation : (a)**. `dureeSecondes` n'est servi que si l'épreuve a été close **dans sa
limite + 60 s** ; il vaut `null` en EO (pas de chrono d'épreuve), sur une clôture paresseuse, et
sur une sous-épreuve sans `timer_started_at`.

**D10 — Source de l'écran d'un thème.** Options : (a) examens de **thème** seuls ; (b) + parts de
ce thème prises dans les examens **globaux**.
➜ **Recommandation : (a)** pour la courbe, la carte de tête, le meilleur, le compteur et la liste.
Une part de 4 questions (T5) et un examen de 20 ne sont pas le même instrument ; les mêler sur une
courbe produirait des sauts qui ne mesurent rien. Les parts par thème restent visibles là où elles
ont un sens : la ligne d'examen global de l'écran civique global.

**D11 — Part d'un thème dans un examen global.** ➜ Servie en **« x / n posées »**, jamais
« / 20 ». **Mises en situation INCLUSES** : elles appartiennent à T1 et T3 par l'arrêté, et le
thème compterait sinon 5 questions sur 11. État par part : **non servi** (à 4 questions, T5
basculerait d'état sur une seule réponse). ⚠️ Cet écart avec le diagnostic, qui exclut les mises
en situation de l'état d'un thème, est à consigner. Carte de thème sans examen de thème :
« Pas encore d'examen de thème », **sans** repli sur la part globale (cohérent avec D10).

**D12 — Vocabulaire civique.** ➜ « Très bon / Bonne maîtrise / À renforcer » est remplacé par
**`CivicThemeState` servi** (Solide · À renforcer · Faible · Non évalué), calculé par
`CivicDiagnosticThemeResolver.etat` sur le score de l'examen. Bandes servies : 0–10 / 11–15 /
16–20 sur 20, 0–21 / 22–31 / 32–40 sur 40. La borne « Solide » est le seuil de réussite. Aucun
nouvel enum, aucun nouveau seuil.

**D13 — L'état civique de l'Accueil (diagnostic) contre celui de l'écran de thème (examens).**
Options : (a) laisser l'Accueil tel quel, l'écran de thème dit « d'après votre dernier examen du
thème » ; (b) faire lire à l'Accueil le plus récent entre diagnostic et examen de thème.
➜ **Recommandation : (a) dans ce chantier, (b) en arbitrage séparé.** (b) touche le moteur du Plan
civique (`CivicPlanService`, ses priorités, `PreparationService`), ce qui dépasse l'écran. Le
libellé de (a) empêche le candidat de lire une contradiction.

**D14 — Routes, et sort des anciennes.** ➜ Nouvelle famille `/progression` (§6.2). **Suppression**
de `/statistiques`, `/historique/epreuve/*`, `/historique/theme/*` ⇄ `/progress`,
`/historiques/epreuve/*`, `/historiques/theme/*`, et de
`GET /api/me/progress/tcf/{epreuve}/historique`. Pas de redirection, sauf demande (aucun lien
externe connu).

**D15 — Ce que `/statistiques` montre et que les maquettes ne montrent pas.** Il s'agit de
`ProgresMouvement` (jours travaillés sur 28 jours, compétences tenues, dernières acquises), de la
section civique `ModuleProgressSection` et du lien « Recommandations ».
➜ **Recommandation : ne pas les reprendre** (écran identique à la maquette). Les compteurs de
compétences restent sur l'Accueil (« Votre progression »). ⚠️ La frise d'**activité** n'aurait
alors plus aucun écran : la supprimer avec son service, ou la garder ailleurs, est à trancher
explicitement.

**D16 — Deux « Ma progression ».** ➜ Le Profil « **Ma progression** » ouvre le nouvel écran
global. Le bouton du Plan ouvre l'historique des **cycles**, renommé « **Mes cycles** » (ou
« Historique de mon parcours ») : c'est un autre fait, avec sa maquette validée, et il reste.
L'écran global peut porter un lien discret vers lui.

**D17 — Entrée depuis l'Accueil.** ➜ Seule l'**issue 3** (« Voir mes résultats ») change de
destination, vers l'écran épreuve. Les issues 1 (lancer la mesure) et 2 (fiche du domaine du Plan,
`EN_PROGRESSION`) restent. La carte de thème passe à l'écran thème.

**D18 — Attempts hérités de 50/60 questions.** ➜ Mesurer d'abord leur existence **en
production** (une requête SQL). Si zéro, ne rien faire. Sinon, les exclure **dans l'autorité**
`findQcmEpreuvesPassees` elle-même, avec un test, jamais dans la seule nouvelle liste.

**D19 — `final_cecrl_level` persisté prioritaire.** ➜ Ticket backend **séparé et préalable** :
toujours re-dériver le plancher à la lecture (la colonne devient une trace, ou disparaît comme
`attempts.cecrl_level`), avec un test qui relit un examen écrit sous l'ancienne règle. Sans lui,
l'écran global affichera les 6 `A1_NON_ATTEINT` figés.

**D20 — Freemium des écrans.** ➜ **Tout est visible** pour un compte gratuit (ses propres
résultats). Les CTA ouvrent la **grille**, qui sert ses verrous. Aucun `locked` de lecture dans
les nouveaux DTO.

---

*Fichiers principaux cités :*
`backend_sejourfr/src/main/java/com/sejourfr/app/controller/ProgressController.java`,
`…/service/progres/{ProgressService,EpreuveHistoriqueService}.java`,
`…/service/EpreuvesProductionQualifiantesResolver.java`, `…/service/ProductionBilanService.java`,
`…/service/FullTcfExamResponseBuilder.java`, `…/service/plancivique/CivicPlanService.java`,
`…/service/diagnosticcivique/{CivicDiagnosticThemeResolver,CivicDiagnosticViewService}.java`,
`…/repository/{AttemptRepository,AttemptQuestionRepository}.java`,
`…/enums/{BandeNoteTcf,CivicExamFormat,CivicThemeState}.java`,
`…/controller/MeController.java` ; `web_sejoufr/app/(app)/{statistiques,dashboard,profil}/page.tsx`,
`web_sejoufr/app/_components/progres/{EpreuveHistoriqueView,ThemeHistoriqueView}.tsx`,
`web_sejoufr/app/_components/sejour/SejourKit.tsx`, `web_sejoufr/lib/{progres,themes,journey}.ts` ;
`mobile_sejourfr/lib/screens/progres/*`, `mobile_sejourfr/lib/screens/home/home_screen.dart`,
`mobile_sejourfr/lib/core/router/app_router.dart`,
`mobile_sejourfr/lib/core/widgets/sejour/sejour_kit.dart`,
`mobile_sejourfr/lib/core/api/user_content_repository.dart`.
