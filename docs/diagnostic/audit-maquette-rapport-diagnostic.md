# Audit — la maquette « rapport du diagnostic » (Expression écrite) face aux données servies

> Date : 2026-09-25 · branche `feature/refonte-l1-socle` · **audit seul, aucun code modifié,
> aucun appel LLM**. Base locale lue en `SELECT` uniquement.
> Maquette auditée : `docs/diagnostic/maquette-rapport-diagnostic-ee.html` (490 lignes, lue en entier).
>
> ⏸️ **Statut : EN ATTENTE** (décision du propriétaire, 2026-09-25). Aucun lot lancé, aucun
> arbitrage A1 → A9 tranché. Les bugs relevés pendant l'audit sont consignés au **§10** et
> restent ouverts jusqu'à la reprise du sujet.

Légende de classement, pour chaque élément affiché :

| Code | Sens |
|---|---|
| ✅ | disponible **et servi** tel quel par un DTO existant |
| 🟡 | la donnée **existe en base** mais n'est pas servie (ou pas par le DTO de l'écran) — DTO à enrichir |
| 🟠 | **dérivable serveur** sans nouvelle donnée — il faut une règle, et lui donner une autorité unique |
| 🔴 | **absent** — il faut produire la donnée (champ de tool-schema, migration, contenu éditorial) |
| ⚠️ | conflit avec un invariant ou une décision déjà tranchée — arbitrage requis |

---

## 0. Verdict en une page

1. **La maquette décrit le rapport du diagnostic RAPIDE (`QUICK_TCF`)**, pas celui du complet.
   Preuve en base : les trois compétences affichées (« Utiliser les temps du passé… »,
   « Relier les informations dans une description cohérente », « Développer un argument ») sont
   **exactement** `EE2-C3`, `EE1-C8`, `EE3-C3`, dans cet ordre, soit le lot de parcours réel
   `journey_lot a79f302f…` créé le 2026-09-21 par une session `QUICK_TCF` close
   (`journey_step.source_assessment_id = diagnostic_sessions.id`). La maquette a été bâtie sur
   une vraie donnée.
2. **Environ 60 % de l'écran est servi aujourd'hui** (niveau estimé, synthèse, les 3 compétences
   du lot, leurs titres, l'état des autres épreuves, topbar, CTA). Ce qui manque est concentré
   dans **un seul bloc** : « Ce qui a été évalué ».
3. **Le point dur : le diagnostic rapide n'a PAS d'axe de critères.** Son contrat IA
   (`diagnostic-analysis-*-v1`) produit des **compétences**, un `task_completion` et un
   `communication_status` — rien sur le vocabulaire ni la grammaire
   (`docs/regles/diagnostic.md:199-201` : « Le diagnostic n'a PAS d'axe de critères »).
   Sur les 4 critères de la maquette, **2 ont un équivalent servi** (« Votre message » ⇄
   `communicationStatus`, « Votre réponse » ⇄ `taskCompletion`), **2 sont 🔴** (Vocabulaire,
   Grammaire).
4. **À l'inverse, le diagnostic COMPLET (et tout examen EE/EO) a déjà les 4 critères** —
   `communiquer` / `interagir` / `lexique` / `morphosyntaxe`, avec une **bande qualitative
   calculée serveur** et persistée (`ai_evaluations.feedback_json.scores_criteres[].bande`) —
   mais **par tâche**, jamais agrégée par épreuve, et absente de `TcfDiagnosticResultDto`
   (🟠). Et le rendu « critère + bande + jauge » **existe déjà** hors kit
   (`CriteriaOverview.tsx` ⇄ `criterion_row.dart`).
5. **Quatre conflits d'invariants à trancher avant tout code** : les mini-barres en % continus,
   le titre « Votre niveau estimé : B1 » (wording imposé « sur cet exercice »), le mélange
   diagnostic + Plan sur un même écran (doctrine A133), et le CTA « Commencer mon Plan » sur le
   rapport rapide (révoque D-M-1 : « le paywall ne se joue plus sur le rapport rapide »).

---

## 1. Ce qui existe aujourd'hui

### 1.1 Les deux diagnostics TCF, leurs contrats et leurs écrans

| | Diagnostic **rapide** (`QUICK_TCF`, v1) | Diagnostic **complet** (4 épreuves) |
|---|---|---|
| Ce qui est produit | **une** production écrite (tirée dans une allowlist de 8 compétences EE) | CO + CE (25 items) + EE (3 tâches) + EO (3 tâches) |
| Correcteur | `DiagnosticProductionAnalysisService`, contrat **`diagnostic-analysis-tool-schema-v1.json`** — bifurqué avant `ai_evaluations` | notation standard, **rubriques v15 / tool-schema v9** (`application.yaml:680`, matrice `v15 -> schema v9`) |
| Stockage | `diagnostic_production_analyses.analysis_json` + colonnes `level_estimate`, `task_completion`, `communication_status` | `ai_evaluations.feedback_json` (par tâche) ; niveaux CO/CE recalculés à la lecture |
| Endpoint du rapport | `GET /api/diagnostics/{id}` · `GET /api/diagnostics/current` → `DiagnosticResponse.result` | `GET /api/tcf-diagnostics/{id}/result` → `TcfDiagnosticResultDto` |
| DTO | `DiagnosticResultDto` / `DiagnosticProductionResultDto` / `DiagnosticSkillObservationDto` | `TcfDiagnosticResultDto` / `TcfDiagnosticSectionDto` / `TcfDiagnosticPriorityDto` |
| Écran web | `web_sejoufr/app/_components/diagnostic/DiagnosticReport.tsx` (page `/diagnostic`, **et encastré** dans `plan/PlanGate.tsx:76`) | `web_sejoufr/app/_components/diagnostic-tcf/TcfDiagnosticResult.tsx` (`/diagnostic-tcf/[sessionId]/resultat`) |
| Écran mobile | `mobile_sejourfr/lib/screens/diagnostic/widgets/diagnostic_result.dart` (`DiagnosticResultView`, **et encastré** dans `screens/plan/plan_screen.dart:498`) | `mobile_sejourfr/lib/screens/diagnostic_tcf/tcf_diagnostic_result_screen.dart` |
| Libellés | `diagnostic/report-labels.ts` ⇄ `diagnostic/widgets/diagnostic_report_labels.dart` | `lib/tcf-diagnostic.ts` ⇄ `diagnostic_tcf/tcf_diagnostic_labels.dart` |

Base locale : 8 sessions `QUICK_TCF` `COMPLETED`, 32 analyses toutes en `schema_version = v1/v1` ;
2 sessions complètes `COMPLETED` ; 170 `ai_evaluations` dont 73 portent `bande`.

### 1.2 Ce que l'écran du rapport RAPIDE affiche aujourd'hui (web ⇄ mobile, parité vérifiée)

Ordre figé (`DiagnosticReport.tsx:106-190` ⇄ `diagnostic_result.dart:84-139`), conforme à la
spec `docs/review_all/10_SEJOURFR_TCF.md:172-205` et à D-M-1 (`60_DECISIONS_IMPLEMENTATION.md:519`) :

1. **Hero** (`Card hero` ⇄ `SfCard(hero)`) : eyebrow **« Niveau estimé sur cet exercice »**,
   palier en Fraunces, « Votre objectif : B2 », `LevelTrack`, puis `written.summary` (≤ 280 c.).
2. **« Ce que nous avons observé »** : 1 ligne positive (compétence `SOLID`) + 2 « à améliorer »
   (les `priorities` servies), avec `explanation` (`report-labels.ts:76-105`).
3. **« Ce n'est qu'une première estimation »** (note d'honnêteté).
4. **« Découvrez où vous en êtes vraiment au TCF »** : les 4 épreuves en `ExamRow` **sans
   statut**, promesse en 3 coches, CTA **« Faire le diagnostic complet »** vers le hub.

Header : `Top` kicker « Diagnostic rapide terminé », titre « Votre estimation ». Aucun paywall.

### 1.3 Écarts maquette ⇄ écran actuel

| Maquette | Écran actuel | Nature de l'écart |
|---|---|---|
| « Votre niveau estimé : B1 » (h1) + tuile B1 | « Niveau estimé sur cet exercice » + palier | ⚠️ wording imposé |
| Titre qualitatif « Vous vous faites bien comprendre. » | aucun | nouveau (donnée servie, non affichée) |
| Bandeau de confiance ✓ | aucun | copie statique |
| **« Ce qui a été évalué » — 4 critères + bande + barre** | aucun | 2 🟡/✅, 2 🔴 |
| Pont « L'analyse devient votre entraînement » | aucun | kit |
| **« Votre Plan a choisi 3 priorités »** (lot du parcours) | « Ce que nous avons observé » (priorités **du diagnostic**, 2 max) | ⚠️ source différente (cf. §4.4) |
| « Pour… » + « Pourquoi : … » | `explanation` LLM | 🟡 / 🔴 |
| « Les autres épreuves — Non évalué » | 4 `ExamRow` muettes dans le bloc « diagnostic complet » | proche ; ⚠️ D-M-1 |
| Note d'honnêteté « Ce n'est qu'une première estimation » | présente | **absente de la maquette** |
| Bloc « diagnostic complet » + promesse | présent | **absent de la maquette** |
| CTA « Commencer mon Plan → » | « Faire le diagnostic complet » | ⚠️ D-M-1 |
| Bottom nav (Plan actif) | aucune : `/diagnostic` est **hors shell** des deux côtés | ⚠️ navigation |

---

## 2. Décomposition bloc par bloc — tableau de correspondance

### 2.1 Topbar

| Élément | Source | Classe | Référence |
|---|---|---|---|
| Bouton retour | `Top backTo` ⇄ `SfTop` | ✅ | `SejourKit.tsx:184` ⇄ `sejour_kit.dart:2260` |
| « Diagnostic écrit » | libellé front (aujourd'hui « Votre estimation », imposé par `10_` §3.6) | ✅ (arbitrage de wording) | `report-labels.ts:26` |
| « Terminé » | `Top badge` existe ; le fait = `DiagnosticResponse.status == COMPLETED` | ✅ | `DiagnosticResponse.java:14`, `TcfDiagnosticResult.tsx:201` (précédent `badge`) |

### 2.2 Hero

| Élément | Donnée | Classe | Remarque |
|---|---|---|---|
| Eyebrow « Expression écrite » | le rapide n'a que l'EE : `written != null`, `format.exerciseCount` | ✅ | `DiagnosticResponse.java:16,26` |
| « Votre niveau estimé : B1 » | `written.levelEstimate` (niveau **rendu par le LLM** du diagnostic, `A1_NON_ATTEINT`…`B2`) | ✅ donnée / ⚠️ wording | `DiagnosticProductionResultDto.java:32` ; schéma `diagnostic-analysis-tool-schema-v1.json:14-18` (« jamais un niveau officiel TCF ») |
| Phrase de synthèse | `written.summary` (≤ 280 c., tronqué serveur) — ou phrase front indexée sur `communicationStatus` | ✅ | `DiagnosticService.java:425-429` ; `diagnostic.md:111-124` |

⚠️ **Wording** : « Niveau estimé **sur cet exercice** », « jamais votre niveau TCF » est imposé par
`10_SEJOURFR_TCF.md:104`, `00_SEJOURFR_SPEC_MAITRE.md:458` et gelé dans
`report-labels.ts:30-34` ⇄ `diagnostic_report_labels.dart:33`. « Votre niveau estimé : B1 » en h1,
après **une seule** production écrite, le contredit. Pire en `null` : production
`NON_EVALUABLE` ⇒ `levelEstimate == null` ⇒ le h1 doit dire l'état, jamais « A1 »
(V040/V041/V042). Proposition : h1 « Niveau estimé sur cet exercice : B1 ».

### 2.3 Carte résultat

| Élément | Donnée | Classe | Remarque |
|---|---|---|---|
| Tuile « B1 » (80 px, dégradé) | `levelEstimate` | ✅ donnée · 🔴 **primitive de kit** | aucune tuile carrée dans le kit ; `SfLevel`/`styles.level` sont du texte Fraunces |
| « Niveau estimé » (small) | libellé | ✅ | |
| Titre qualitatif « Vous vous faites bien comprendre. » | **`communicationStatus`** (`EFFECTIVE` / `PARTIAL` / `INEFFECTIVE`) : c'est **exactement** ce fait-là. Servi, mirroré, **jamais affiché** | ✅ (servi, non rendu) | `DiagnosticProductionResultDto.java:34` ; miroirs `web_sejoufr/lib/types.ts:1264` ⇄ `diagnostic_models.dart:639` |
| Phrase « Votre message est clair dans l'ensemble… » | `summary`, ou 2ᵉ phrase indexée sur le couple `communicationStatus × taskCompletion` | ✅ | phrase = front (le serveur sert des faits) |
| Bandeau « Ce résultat nous aide à préparer… » | copie statique | ✅ | primitive existante `InfoNote variant="check"` ⇄ `SfInfoNote(check)` (`SejourKit.tsx:1717`, `sejour_kit.dart:3501`) |

🛑 Un titre qualitatif ne se déduit **pas** du palier (ce serait une table palier → phrase, donc un
front qui classe) : il se lit sur l'enum servi `communicationStatus`. Le table enum → phrase est
une table de **libellés**, légitime, à déclarer une fois par front (miroirs).

### 2.4 « Ce qui a été évalué » — les 4 critères (le cœur de l'audit)

#### 2.4.a Les critères réels de la notation EE/EO

Rubriques **v15** (active), tool-schema **v9** : **4 critères, identiques pour les 6 tâches EE/EO**,
poids 0,25 chacun (`production-rubrics-v15.json`, `rubrics.EE_T1…EO_T3.criteres`) ; enum du
tool-schema `production-evaluation-tool-schema-v9.json:124-148`.

| Code | Libellé servi (`label`) | Critère de la maquette le plus proche | Écart |
|---|---|---|---|
| `communiquer` | « Communiquer : accomplir la tâche et enchaîner les idées » | **« Votre message »** *et* **« Votre réponse »** | ⚠️ la maquette **coupe en deux** ce que la grille réunit (clarté/enchaînement + accomplissement de la consigne) |
| `interagir` | « Interagir : adaptation à la situation et au destinataire » | **aucun** | ⚠️ la maquette n'a pas de ligne « ton / destinataire » |
| `lexique` | « Lexique : vocabulaire approprié » | « Vocabulaire » | ✅ |
| `morphosyntaxe` | « Morphosyntaxe : correction grammaticale » | « Grammaire » | ✅ |

⇒ Les 4 cartes de la maquette **ne sont pas** les 4 critères de la grille. Pour un rendu fidèle à
la notation, il faudrait : « Votre message » (communiquer), « Ton et destinataire »
(interagir), « Vocabulaire », « Grammaire ». Arbitrage **A3**.

Legacy : la base porte encore des codes de grilles antérieures (`coherence`,
`adequation_destinataire`, `realisation_consigne`, `argumentation`…, cf. requête §6) — tout
lecteur doit les couvrir, comme le font déjà `CriteriaOverview.tsx` et `criterion_row.dart`.

#### 2.4.b Score par critère : existe-t-il, où, dans quel DTO ?

| Diagnostic | Score par critère ? | Persisté où | Servi où | Classe |
|---|---|---|---|---|
| **Rapide** | **Non.** Le contrat v1 ne produit que `level_estimate`, `task_completion`, `communication_status`, `summary`, `strengths[≤3]`, `weaknesses[≤3]`, `skills[]` (`diagnostic-analysis-tool-schema-v1.json:4-12`) | — | — | voir tableau suivant |
| **Complet** (EE/EO) | **Oui, par tâche** : `note_sur_20` + `bande` (+ `commentaire`, `preuve`) | `ai_evaluations.feedback_json.scores_criteres[]` ; `bande` ajoutée serveur par `AiEvaluationService.applyBandesCriteres` (`AiEvaluationService.java:1142-1151`) | `EvaluationResultDto.feedback` (JSONB passé tel quel, `EvaluationResultDto.java:36-45`), par soumission. **Pas** dans `TcfDiagnosticResultDto` (`TcfDiagnosticResultDto.java:20-58`) ni dans `ProductionBilanResponse` (`ProductionBilanResponse.java:23-45`) | 🟡 par tâche · 🟠 par épreuve |

Pour le **rapide**, critère par critère :

| Critère maquette | Donnée | Classe | Référence |
|---|---|---|---|
| Votre message (clair, compréhensible ?) | `communicationStatus` : `EFFECTIVE` / `PARTIAL` / `INEFFECTIVE` | ✅ servi, non affiché | `DiagnosticProductionResultDto.java:34` ; CHECK `chk_diagnostic_analysis_communication` |
| Votre réponse (répond à la demande ?) | `taskCompletion` : `COMPLETED` / `PARTIAL` / `NOT_COMPLETED` | ✅ servi, non affiché | `DiagnosticProductionResultDto.java:33` |
| Vocabulaire | **rien de structuré** — au mieux une phrase de `weaknesses[]` (« Le lexique et les structures restent élémentaires… », texte libre LLM) | 🔴 | il faudrait un champ de contrat |
| Grammaire | idem ; **proxy partiel** : la compétence `EE2-C3` « temps du passé » est observée, mais c'est une compétence, pas le critère | 🔴 | allowlist `QUICK_TCF` : `EE1-C7, EE2-C5, EE2-C3, EE2-C7, EE3-C1, EE3-C2, EE3-C3, EE1-C8` — **aucune** compétence de lexique |

Produire Vocabulaire/Grammaire pour le rapide = **`diagnostic-analysis-tool-schema-v2`** +
**`diagnostic-analysis-rubrics-v2`** (on versionne, on ne réécrit jamais la v1), deux champs
enum (`lexique_status`, `morphosyntaxe_status`, mêmes 3 valeurs que `communication_status`),
validateur + réconciliateur, variable d'environnement pour le retour arrière.
**Coût LLM marginal** (~20 tokens de sortie par diagnostic), **mais** : v10/v11 ont mesuré qu'un
bloc ajouté à une grille qui juge fait baisser l'accord exact (81,8 % → 75,6 %,
`diagnostic.md:291-293`). Une mesure au banc serait donc nécessaire — **payante, décision du
propriétaire**. Et les 32 analyses existantes resteraient sans ces deux lignes (`null` = inconnu,
jamais mauvais : la ligne s'afficherait « Non évalué »).

#### 2.4.c La bande qualitative est-elle déjà dérivée serveur ?

- **Complet : oui.** `BandeCritere` (`enums/BandeCritere.java:25-46`) — `TRES_BONNE_MAITRISE`
  / `SATISFAISANT` / `EN_COURS_ACQUISITION` / `FRAGILE` / `NON_EVALUABLE`, bornes lues dans la
  grille active (10 / 6 / 2, qui **coïncident avec les seuils B2 / B1 / A2**,
  `production-rubrics-v15.json → commun.bandes_criteres`). La sévérité des priorités du
  diagnostic complet en dépend déjà (`TcfDiagnosticReadService.java:248-262, 336-358`).
- **Rapide : oui pour les deux critères qui existent** — `communicationStatus` et
  `taskCompletion` **sont** des états servis, 3 valeurs chacun.
- **Mapping 5 → 3 de la maquette** (Solide / À renforcer / Prioritaire) : 🟠, **à servir**, pas à
  écrire dans les fronts. Proposition : `TRES_BONNE_MAITRISE|SATISFAISANT → SOLIDE`,
  `EN_COURS_ACQUISITION → A_RENFORCER`, `FRAGILE → A_TRAVAILLER`, `NON_EVALUABLE|absent →
  NON_EVALUE` (neutre, jamais rouge). ⚠️ Question de fond (**A4**) : **absolu ou relatif à
  l'objectif ?** `SATISFAISANT` = critère au niveau B1. Pour un candidat NAT (objectif B2),
  « Solide » serait faux ; `TcfDiagnosticPriorityResolver` raisonne pourtant par écart à la
  cible (`diagnostic-tcf-4-epreuves.md:364-389`). Si relatif, l'autorité doit recevoir
  `TargetProcedure.niveauVise(...)` — jamais une table recopiée.
- ⚠️ **Vocabulaire à harmoniser** : aujourd'hui la bande s'affiche « Niveau B2 / B1 / A2 / A1 »
  (`bandeCritereLabel`, `web_sejoufr/lib/types.ts:3593-3605` ⇄ `BandeCritere.displayName`,
  **gelés par test des deux côtés**). « Prioritaire » entre en collision avec la notion de
  **priorité du Plan** (`LearningPlanSkillStatus.PRIORITY`) : une carte « Grammaire —
  Prioritaire » sans aucune compétence de grammaire dans les 3 priorités se lirait comme une
  contradiction. Préférer « À travailler ».

#### 2.4.d La mini-barre en % — ⚠️ incompatible telle quelle

La maquette remplit ses barres à **78 / 64 / 58 / 45 %** : des nombres continus.

- Le rapide **n'a aucun nombre** à mettre dedans (🔴 absolu).
- Le complet a `note_sur_20`, mais le dépôt a décidé de ne **pas** l'afficher par critère :
  « une IA ne distingue pas honnêtement un 13 d'un 14 » (`BandeCritere.java:5-13`), « aucun
  pourcentage » sur ce rapport (`10_SEJOURFR_TCF.md:182`), « aucun pourcentage de progression
  vers un palier » (`docs/regles/progression.md:404-405`), et `ProgressMini` (jauge continue) a
  été **supprimée** le 2026-09-19 (`SejourKit.tsx:917`).
- **Ce qui est admis** (`progression.md:1115-1124`) : une jauge qui est le **codage visuel d'un
  enum servi, à positions fixes, sans chiffre**. C'est déjà ce que fait `.critBar`
  (`production.module.css:1107-1111` : 100 / 75 / 50 / 25 / 0 % selon la bande) ⇄
  `BandeCritere.fillRatio` (`mobile_sejourfr/lib/core/models/enums.dart:459`).

⇒ Recommandation : **barre à crans fixes pilotée par l'état servi**, jamais par une note.

#### 2.4.e Dette découverte au passage

`critereBandeFromNote` (`web_sejoufr/lib/production-feedback.ts:161-178`) ⇄
`TcfNoteScale.bandeFor` (`mobile_sejourfr/lib/screens/tcf_production/widgets/tcf_note_scale.dart:77`)
**classent une note en bande côté front** pour les évaluations antérieures à la `bande`
(`criterion_row.dart:46-47`). C'est la lettre de l'invariant « aucun front ne classe un nombre ».
Correctif naturel (🟠, dans le lot backend) : le serveur sert la bande **à la lecture** pour le
legacy (`BandeCritere.of` existe déjà), les deux fronts suppriment leur copie.

### 2.5 Pont et « Votre Plan a choisi N priorités »

| Élément | Donnée | Classe | Référence / remarque |
|---|---|---|---|
| Séparateur « L'analyse devient votre entraînement » | copie | 🔴 **primitive** | aucun séparateur à libellé dans les kits |
| « Votre Plan a choisi **3** priorités » | le **lot** du parcours créé par ce diagnostic : `journey_step` `TRAIN_SKILL` de `lot_id`, `source_assessment_id = session.id`, triés par `severity_rank` ; **3 par lot** par construction (`maxPrioritiesPerLot`, `plan.md:2002-2023`) | ✅ via `GET /api/me/plan/journey` (`JourneyStepDto.lotId`, `.sourceAssessmentId`, `JourneyStepDto.java:69-70`) · 🟡 si on veut le servir **sur le DTO du rapport** | ⚠️ cf. §4.4 (deux sources) et §4.5 (sans objectif ⇒ pas de parcours) |
| « Cycle actuel » | `JourneyDto` / `JourneyCycleDto` | ✅ | |
| Badge « EE » + « Expression écrite » | `JourneyStepDto.section` / `taskCode` | ✅ | libellés : `lib/tcf-epreuves.ts` ⇄ `tcf_epreuves.dart` |
| Numéro 1 / 2 / 3 | `position` / `severity_rank` | ✅ | |
| Titre de compétence | `JourneyStepDto.skillTitle` (= `skills.title`) — **seule chaîne servie** par le parcours | ✅ | `JourneyStepDto.java:21-26, 67-68` |
| Sous-titre « Pour rendre vos récits plus précis… » | `skills.description` existe (2 phrases, ton « Vous apprenez à… », ex. `EE2-C3` : « Un récit se tient au passé… »), `skills.general_criterion`, `skills.learning_points[3]` | 🟡 (non servis par `JourneyStepDto`) · 🔴 si l'on veut une **ligne « Pour… » courte** : contenu éditorial à écrire pour les 48 compétences (migration de contenu, **aucun LLM**) | table `skills` |
| « Pourquoi : difficulté observée en grammaire » | voir ci-dessous | 🟡 / 🔴 | |

**Le lien critère → compétence n'existe nulle part.** Vérifié : aucune colonne, aucune table,
aucun code Java ne relie une compétence (`skills`) à un critère de grille
(`communiquer`/`interagir`/`lexique`/`morphosyntaxe`) ; `morphosyntaxe` n'apparaît que dans la
notation (`AiEvaluationService`, `ProductionBilanService`, filtres) ; la taxonomie v3
(`docs/taxonomie-competences-v3.md`) ne porte qu'un « Critère général » **textuel** par
compétence. Le moteur du Plan ne raisonne **pas** par critère : il trie des **observations de
compétence** (`LearningPlanPriorityResolver`), et le diagnostic complet par **tâche**
(`TcfDiagnosticPriorityResolver`), la sévérité n'étant qu'un **compte** de bandes, sans nom de
critère (`TcfDiagnosticReadService.Severite`, l. 261).

Trois façons d'écrire le « Pourquoi », de la moins chère à la plus chère :

| Option | Donnée | Classe | Coût |
|---|---|---|---|
| **P1** — citer l'observation | `explanation` de l'observation qui a fondé l'étape (≤ 220 c., LLM ; ex. `EE2-C3` : « Le passé composé et l'imparfait sont utilisés, mais des formes fautives apparaissent… »). Servi par `DiagnosticSkillObservationDto.explanation` pour les 8 compétences du rapide, et par `LearningPlanPriorityDto.explanation` (`LearningPlanPriorityDto.java:55`) — **mais** la vue est bornée à 5 priorités et **`JourneyStepDto` ne la porte pas** | 🟡 | 0 LLM ; enrichir `JourneyStepDto` ou joindre côté DTO du rapport |
| **P2** — famille de critère éditoriale | table **compétence → critère** (48 lignes, fait éditorial du référentiel, ex. `EE2-C3 → morphosyntaxe`, `EE1-C8 → communiquer`, `EE3-C3 → communiquer`) + libellé front « difficulté observée en grammaire » indexé sur l'enum | 🔴 (migration additive `skills.criterion_code` ou référentiel en code) | 0 LLM ; ~0,5 j + validation éditoriale ; `SkillLabelsTest` |
| **P3** — le correcteur désigne le critère | champ de contrat par compétence | 🔴 | contrat v2, banc payant — **déconseillé** (contrainte dure < consigne ; P2 suffit) |

⚠️ Avec P2, la phrase « Pourquoi : difficulté observée en grammaire » n'est vraie que si
l'observation est **fragile** (`PRIORITY`/`TO_REINFORCE`). Toutes les étapes d'un lot le sont
par construction (R1/R2), mais le front ne doit pas l'écrire sans que le statut soit servi.

### 2.6 « Les autres épreuves — Non évalué »

| Élément | Donnée | Classe | Remarque |
|---|---|---|---|
| Liste CO / CE / EO | liste fixe par front (`DIAGNOSTIC_COMPLET_EPREUVES`, `report-labels.ts:127-132` ⇄ `kDiagnosticCompletEpreuves`) ; **4 épreuves, jamais `TCF_STRUCTURE`** | ✅ | ordre maquette : CO, CE, EO (EE retirée car hero) |
| « Non évalué » **par ce diagnostic** | vrai par construction (le rapide ne mesure que l'EE) | ✅ | statique |
| « Aucun résultat disponible **pour le moment** » (sens **produit**) | ⚠️ faux si l'épreuve a été mesurée ailleurs (examen blanc, complet). Le fait produit existe : `NiveauActuelEpreuveResolver`, servi par `TcfDiagnosticReadService.sectionsMesurees` (`PreparationService`), `PlanDomainDto.evaluated/niveau`, `/api/me/progression` | 🟡 (pas sur le DTO du rapport) | doctrine 2026-09-16 : « une épreuve mesurée est une section **faite** » (`diagnostic-tcf-4-epreuves.md:104-162`) |
| Pastille « Non évalué » grise | `ExamRow status` + ton neutre | ✅ | 🛑 neutre, jamais ambre ni rouge (`null` = inconnu) |

⚠️ D-M-1 a **retiré** du rapport rapide les 4 épreuves à « — » (« trois épreuves sur quatre
s'affichaient en « — », juste sous une carte qui venait de dire *ce n'est qu'une première
estimation* »). La maquette les réintroduit avec un meilleur mot (« Non évalué ») : c'est un
retour sur décision → **A6**.

Pour le **complet**, la même liste est ✅ servie : `TcfDiagnosticResultDto.epreuves[]` (niveau
`null` = non évaluée) + `dejaAuNiveau` + `priorites` ; l'écran actuel la rend déjà
(`TcfDiagnosticResult.tsx:237-259`).

### 2.7 CTA, liens, navigation

| Élément | État | Classe | Remarque |
|---|---|---|---|
| « Commencer mon Plan → » (rouge) | `Cta` ⇄ `SfButton` ✅ ; `PreparationDto.ModulePreparation.planDisponible` dit si le Plan existe (vrai dès le rapide clos) | ✅ technique · ⚠️ produit | D-M-1 : « le paywall ne se joue plus sur le rapport rapide ». Pour un compte gratuit, « Commencer mon Plan » mène au **paywall** (`JourneyState.LOCKED` permanent, D-18). Rouge = CTA critique (charte) : conforme si c'est le geste de conversion |
| Lien secondaire (CSS `.secondary`, **absent du HTML**) | — | — | la maquette a supprimé le lien « Faire le diagnostic complet » ; or `affinerPlan()` est l'autorité de cette invitation (`diagnostic.md:574-589`) |
| Bottom nav 5 onglets, Plan actif | mobile : `MainShell` (`main_shell.dart:10-22, 113-119`) ✅ **mais** `/diagnostic` et `/diagnostic-tcf/:id/resultat` sont **hors** `ShellRoute` (`app_router.dart:637, 655` < `669`). Web : **aucune bottom nav** — barre latérale ≥ 901 px, `AppTopBar` + tiroir en dessous ; `/diagnostic` est même hors du groupe `(app)` | ⚠️ | écart de parité **assumé et documenté** (web ⇄ mobile) ; « Plan » actif sur un écran de diagnostic est un choix de navigation → **A8** |

---

## 3. Le KIT — primitives existantes et manquantes

Règle : ces écrans passent par `SejourKit.tsx` ⇄ `sejour_kit.dart`, **brique pour brique** ; un
motif manquant s'ajoute **dans les deux kits dans la même passe** (CLAUDE.md racine).

| Bloc maquette | Primitive existante (web ⇄ mobile) | Manque |
|---|---|---|
| Topbar + « Terminé » | `Top` (`backTo`, `kicker`, `title`, `badge`) ⇄ `SfTop` | — |
| Eyebrow rouge + h1 + phrase | `Top`/`HeroBanner` (`SejourKit.tsx:2170`) ⇄ `SfHeroBanner` ; ou `Card hero` + `styles.label/level/insight` | variante « hero de rapport » éventuelle ; le h1 doit rester **Fraunces** |
| Tuile niveau 80 px + copie | — (`SfLevel` = texte) | 🔴 **`ResultHead` / `LevelTile`** (tuile + small + titre + phrase), les deux kits |
| Bandeau de confiance | `InfoNote variant="check"` ⇄ `SfInfoNote(check)` | — |
| Tête de section + méta à droite (« Vue rapide », « Cycle actuel ») | `Section title` ⇄ `SfSection` ; `action` = **lien** seulement (`SejourKit.tsx:292-330`) | 🔴 variante **`meta`** (texte non cliquable) |
| Ligne de critère (icône, nom, description, pastille, jauge) | existe **hors kit** : `production/CriteriaOverview.tsx` + `.critBar` ⇄ `tcf_production/widgets/criterion_row.dart` | 🔴 **promouvoir** en `CriterionRow` + `CriterionList` dans les deux kits (et faire migrer le rapport express dessus : refonte = suppression de l'ancien) |
| Pastille Solide / À renforcer / … | `Pill` (`SejourKit.tsx:1778`) ⇄ `SfPill` | — (tons `ok`/`warn`/`hot`/`muted`) |
| Note centrée « Ces points servent simplement… » | `MicroNote` ⇄ `SfMicroNote` | — |
| Séparateur « L'analyse devient votre entraînement » | — | 🔴 **`Bridge`** (filet + libellé) |
| Carte Plan : tête EE + liste numérotée | `PanelHead` ⇄ `SfPanelHead` ; `Prio` (`rank`, `tag`, `title`, `text`, `children`) ⇄ `SfPrio` ; `JourneyRow` ⇄ `SfJourneyRow` | ligne « **Pourquoi** » : se glisse dans `Prio children` (via `MicroNote`) — sinon variante `origin` ; `Prio` impose un `tag` (« Priorité 1 ») absent de la maquette |
| Autres épreuves | `ExamRow` (`icon`, `title`, `subtitle`, `status`, `tone`) ⇄ `SfExamRow` | — (`subtitle` = « Aucun résultat… ») |
| CTA | `Cta` ⇄ `SfButton` | — |
| Deux colonnes ≥ 700 px | palier desktop du kit (`SejourApp report`, `deskPair`) | web seulement — **une media query n'est pas une primitive**, aucun miroir Flutter |
| Bottom nav | `MainShell` (mobile) | web : aucune (barre latérale) |

### Identité visuelle (maquette ⇄ charte)

| Maquette | Charte (`docs/identite-visuelle.md`, `web_sejoufr/CLAUDE.md:244-268`) |
|---|---|
| `font-family: Inter` | **Plus Jakarta Sans** (UI), **Fraunces** (titres, niveau), **JetBrains Mono** (eyebrows) — Inter est réservé à l'admin |
| `--navy #1b2f73`, `--navy2 #324a9a` | `--color-blue #1E3A8C`, `--color-blue-mid #2A4BB0` ⇄ `AppColors.blue*` |
| `--red #d84b3e` | `--color-red #E1372F` (CTA critiques seulement) |
| `--green #34795f`, `--amber #bd842e` + fonds `Soft` | `--color-green #168F5B` / `-light`, `--color-amber #E8A317` / `-light` / `-dark` |
| `#f7f9ff`, `#e2e7f7`, `#8a92ad`, `#edf0f5`… en dur | `--color-blue-soft`, `--color-line*`, `--color-muted*` ; **jamais un hex** dans un écran |
| Emojis/symboles (`◎ ↔ Aa ⌘ ▱ ▦`) | icônes Lucide (web `lucide-react` ⇄ `lucide_icons_flutter`) |

Tous les rôles de couleur de la maquette ont un token : **aucun token à créer**. La classe
`.summary-grid` de la maquette n'est utilisée par aucun élément HTML (vestige).

---

## 4. Conflits avec les invariants et décisions en vigueur

| # | Élément | Règle heurtée | Où elle vit | Gravité |
|---|---|---|---|---|
| C1 | Mini-barres 78 / 64 / 58 / 45 % | « aucun pourcentage », fausse précision du critère, jauge = enum servi à crans fixes | `10_SEJOURFR_TCF.md:182` ; `BandeCritere.java:5-13` ; `progression.md:1115-1124` ; `SejourKit.tsx:917` | 🛑 bloquant tel quel — **soluble** (crans fixes) |
| C2 | « Votre niveau estimé : B1 » | wording imposé « Niveau estimé sur cet exercice » ; un seul écrit ≠ niveau TCF | `10_` §3.1 l. 104 ; `report-labels.ts:30-34` | ⚠️ |
| C3 | Plan + diagnostic sur un écran « Terminé » | **A133** : un écran qui dit « diagnostic terminé » lit **le diagnostic**, jamais le Plan/parcours (« deux sources sur le même écran finiraient par se contredire ») | `decisions-autonomes-parcours-tcf.md:2211-2216` | ⚠️ — **mesuré**, cf. §4.4 |
| C4 | CTA « Commencer mon Plan » sur le rapport rapide, bloc « diagnostic complet » supprimé | D-M-1 : le paywall ne se joue plus sur le rapport rapide ; il mène au complet | `60_DECISIONS_IMPLEMENTATION.md:519-545` | ⚠️ décision produit |
| C5 | « Les autres épreuves » réintroduites | D-M-1 les a retirées du rapport rapide | idem | ⚠️ (mineur si « Non évalué » neutre) |
| C6 | « Prioritaire » comme bande de critère | collision avec les priorités du Plan ; bande relative ou absolue ? | `LearningPlanSkillStatus` ; `diagnostic-tcf-4-epreuves.md:364-389` | ⚠️ |
| C7 | Libellés de critères | les 4 cartes ≠ les 4 critères de la grille (« Votre réponse » ≠ `interagir`) | rubriques v15 | ⚠️ |
| C8 | Inter + hex en dur + emojis | charte : Plus Jakarta Sans / Fraunces / tokens | `CLAUDE.md` racine, `identite-visuelle.md` | 🛑 (portage) |
| C9 | Bottom nav sur le web | le web n'a pas de bottom nav (barre latérale) ; écran hors shell des deux côtés | `main_shell.dart:18-22` ; `app_router.dart:637-669` | ⚠️ |
| C10 | Palier interne | ne **jamais** afficher `skills.target_level` / `SkillTaskCode.targetLevel` (« EE3-C3 = B2 ») comme une règle du TCF | CLAUDE.md racine | ✅ la maquette ne le fait pas — à préserver |
| C11 | `null` = inconnu | `levelEstimate == null` (`NON_EVALUABLE`), critère absent, épreuve non mesurée ⇒ nommer l'état, jamais A1 ni rouge | V040/V041/V042 | à tenir dans chaque bloc |
| C12 | Parité | l'écran existe **deux fois** par front (page + encastré dans la porte du Plan) : `PlanGate.tsx:76` ⇄ `plan_screen.dart:498` | `DiagnosticReport.tsx:20-26` | à tenir |

### 4.4 Mesure en base : diagnostic ≠ parcours (C3)

`diagnostic_sessions.summary_json.priority_skill_codes` (ce que sert `DiagnosticResultDto.priorities`,
**2 max** pour une seule production, `diagnostic.md:100-110`) comparé au lot de parcours créé par la
même session :

| Session `QUICK_TCF` | Priorités du diagnostic | Lot du parcours |
|---|---|---|
| `c6a79fa6…` (celle de la maquette) | `EE2-C3, EE1-C7` | `EE2-C3, EE1-C8, EE3-C3` |
| `f241e217…` | `EE2-C3, EE3-C3` | `EE3-C3, EE2-C3, EE3-C2` |
| `6474e75a…` | `EE3-C3, EE2-C3` | `EE3-C3, EE2-C3, EE3-C2` |
| `f14e39f6…` | `EE3-C2, EE3-C3` | `EE3-C3, EE3-C2` (ordre inversé) |
| 4 autres sessions | 2 codes | **aucun lot** (compte sans objectif déclaré ⇒ pas de parcours, D-3/D-10) |

Donc : (1) le rapide ne peut **jamais** afficher « 3 priorités » depuis son propre DTO ; (2) les
deux sources **divergent déjà** (compétence, nombre, ordre) ; (3) sans objectif déclaré, il n'y
a pas de lot du tout. « Votre Plan a choisi 3 priorités » **doit** lire le parcours, et l'écran
actuel « Ce que nous avons observé » ne peut pas coexister avec lui sans montrer deux listes
différentes → **A5**.

### 4.5 Sans objectif déclaré

Pas de parcours ⇒ pas de lot ⇒ le bloc Plan de la maquette est vide. Repli possible : les
priorités de `LearningPlanDto` (épingle `plan_pinned_priorities`, repli officiel D-10) —
troisième source. À trancher avec A5 ; à défaut, le bloc s'efface et la carte « Choisir mon
objectif » s'affiche (règle « on invite, on ne ferme rien », `plan.md:2158-2166`).

---

## 5. Les 4 épreuves — ce que donnerait le même gabarit ailleurs

La maquette est un gabarit **par épreuve**. Pour le diagnostic complet (et, par construction,
tout examen blanc d'épreuve), voici ce qui alimenterait chaque bloc :

| Bloc | EE | EO | CE | CO |
|---|---|---|---|---|
| Niveau de l'épreuve | ✅ `TcfDiagnosticSectionDto.niveau` (min des 3 tâches) | ✅ idem | ✅ (taux par palier) + `scoreCalibre` /499 | ✅ idem |
| « Ce qui a été évalué » | 🟠 4 critères, **agrégés** sur les 3 tâches (règle à écrire : la **pire** bande des tâches évaluées, cohérente avec « une tâche ratée plafonne l'épreuve ») | 🟠 idem ; ⚠️ lexique/grammaire lus sur une **transcription** (filtres d'artefacts oraux, prononciation non notée — `docs/notation-ia-eo-ee.md`) : le libellé doit le dire | 🟡 3 **paliers** A2/B1/B2, pas des critères. Taux calculés (`TcfDiagnosticLevelResolver.java:70-81`) mais non servis ; états par palier servis par `PlanDomainDto.paliers` (produit, pas session). 🛑 **jamais** « A2 : 80 % » (pourcentage + palier dans le même bloc, `progression.md:90-92`) | 🟡 idem |
| Priorités | ✅ par **tâche** (`TcfDiagnosticPriorityDto`, « EE · Tâche 2 », score jamais exposé) ; ✅ compétences via le lot du parcours de l'examen | ✅ idem | ✅ priorité d'**épreuve** (`taskCode = null`) ; compétences CO/CE-A2/B1/B2 via le parcours | ✅ idem |
| Autres épreuves | ✅ `epreuves[]` + `dejaAuNiveau` + `priorites` (mentions déjà rendues, `epreuveMention`) | ✅ | ✅ | ✅ |

Le rapport **global** du complet (`TcfDiagnosticResult.tsx` ⇄ `tcf_diagnostic_result_screen.dart`)
reste le moment de conversion (plancher des quatre, priorités, plan) ; un rapport par épreuve
n'y ajouterait que le bloc « Ce qui a été évalué ». Aujourd'hui « Voir le rapport » d'une
section mène au bilan d'examen existant (`rapportAttemptId`), qui affiche **déjà** les critères
par tâche (`CriteriaOverview`).

---

## 6. Requêtes SQL exécutées (lecture seule, reproductibles)

```sql
-- allowlist du rapide : les 8 compétences observables
SELECT pt.diagnostic_code, dts.display_order, s.code, s.title
FROM diagnostic_task_skills dts JOIN production_tasks pt ON pt.id = dts.production_task_id
JOIN skills s ON s.id = dts.skill_id ORDER BY 1, 2;

-- ce que stocke une analyse du rapide
SELECT jsonb_pretty(analysis_json - 'exemple_cible') FROM diagnostic_production_analyses LIMIT 1;

-- bandes de critères réellement en base (grilles courantes et legacy)
SELECT s->>'code', s->>'bande', count(*)
FROM ai_evaluations, jsonb_array_elements(feedback_json->'scores_criteres') s
WHERE s ? 'bande' GROUP BY 1, 2;

-- priorités du diagnostic vs lot du parcours
SELECT ds.id, ds.summary_json->'priority_skill_codes',
       (SELECT string_agg(s.code, ',' ORDER BY js.position) FROM journey_step js
        JOIN skills s ON s.id = js.skill_id WHERE js.source_assessment_id = ds.id)
FROM diagnostic_sessions ds WHERE ds.diagnostic_code = 'QUICK_TCF' AND ds.status = 'COMPLETED';
```

---

## 7. Plan de mise en œuvre proposé (après arbitrages)

Hypothèse de travail retenue ci-dessous : **A1 = option b** (pas de nouveau contrat IA), **A3 =
libellés alignés sur la grille**, **A4 = bande absolue**, **A5 = le parcours fait foi**. Chaque
lot vérifie web **et** mobile dans la même passe ; aucun nouveau test front
(`npx tsc --noEmit`, `npm run build`, `flutter analyze`) ; tests backend dans la même passe.

### Lot 1 — Backend (DTO), ~2,5 j

1. **Enum servi `CritereEtat`** (`SOLIDE` / `A_RENFORCER` / `A_TRAVAILLER` / `NON_EVALUE`) et
   **une** autorité de mapping (`BandeCritere → CritereEtat`, `DiagnosticCommunicationStatus →
   CritereEtat`, `DiagnosticTaskCompletion → CritereEtat`). Libellés FR gelés par
   `SkillLabelsTest`.
2. **Rapide** : `DiagnosticProductionResultDto` gagne `criteres: List<CritereDto{code, etat}>`
   — les deux lignes réelles (message, réponse). Vocabulaire/Grammaire **absents** (et non
   « Non évalué » inventé) tant que A1 ne dit pas le contraire.
3. **Complet** : `TcfDiagnosticResultDto.EpreuveNiveau` gagne `criteres` agrégés sur les tâches
   évaluées de l'attempt qui a mesuré l'épreuve (même lecture que `tachesMesurees`, **zéro
   requête** de plus : les évaluations sont déjà chargées pour la sévérité). Règle d'agrégat
   écrite une fois, testée (IT sur Zonky).
4. **Legacy** : bande servie à la lecture pour les évaluations sans `bande` → suppression de
   `critereBandeFromNote` ⇄ `TcfNoteScale.bandeFor` côté fronts (§2.4.e).
5. **Lien diagnostic → lot** : `DiagnosticResultDto.planLot` (étapes `TRAIN_SKILL` dont
   `source_assessment_id = session.id` : `skillCode`, `skillTitle`, `position`, statut et
   `explanation` de l'observation fondatrice) — `null` sans parcours. Une lecture indexée ;
   coût verrouillé par égalité.
6. **Famille de critère** (si A7 = P2) : migration additive `skills.criterion_code` (4 valeurs,
   `CHECK`), backfill éditorial des 48 compétences numéroté **après** leurs lots de seed,
   servi sur `planLot[]` et `JourneyStepDto`. ~0,5 j + relecture du propriétaire.
7. Miroirs : `web_sejoufr/lib/types.ts` ⇄ `mobile_sejourfr/lib/core/models/diagnostic_models.dart`
   / `tcf_diagnostic_models.dart` (l'admin ne mirroir pas ces DTO). Doc : `docs/regles/diagnostic.md`,
   `docs/api-endpoints.md`.

### Lot 2 — Kits web + mobile, ~2 j

`ResultHead` (tuile niveau + titre + phrase), `CriterionRow`/`CriterionList` (promus depuis
`CriteriaOverview` ⇄ `criterion_row`, jauge à **crans fixes** pilotée par `CritereEtat`, le
rapport express migré dessus et l'ancien supprimé), `Bridge`, `Section meta`, variante
« pourquoi » de `Prio` (ou `children` + `MicroNote`). Tokens uniquement, Lucide, Fraunces pour
le niveau. Mise à jour des deux `CLAUDE.md` de front (section kit).

### Lot 3 — Écrans, ~1,5 j

`DiagnosticReport.tsx` ⇄ `DiagnosticResultView` refaits sur la maquette, **dans leurs deux
emplacements** (page + porte du Plan, `embedded`/`leading`), en conservant : état `NON_EVALUABLE`,
objectif `null`, note d'honnêteté (si A2), invitation au complet via `affinerPlan()`.
Optionnel : bloc « Ce qui a été évalué » dans `TcfDiagnosticResult` ⇄
`tcf_diagnostic_result_screen` (par épreuve), ~0,5 j.

### Lot 4 (optionnel, conditionné à A1 = a) — contrat IA v2 du rapide

`diagnostic-analysis-rubrics-v2` + `tool-schema-v2` (+ `lexique_status`, `morphosyntaxe_status`),
validateur/réconciliateur, bascule par variable d'environnement, `docs/notation-ia-eo-ee.md`
mis à jour dans la même passe. ~1,5 j **+ mesure au banc payante** (à chiffrer et à décider
par le propriétaire).

**Total** : ~6 j sans le lot 4 ; ~7,5 j + banc avec.

---

## 8. Arbitrages à demander au propriétaire

| # | Question | Options | Recommandation |
|---|---|---|---|
| **A1** | Vocabulaire et Grammaire sur le rapport **rapide** ? | (a) contrat IA v2 + banc payant ; (b) n'afficher que les 2 critères que le rapide mesure (message, réponse) + les compétences observées ; (c) ne montrer le bloc « Ce qui a été évalué » que pour le complet | **(b)** — aucune donnée inventée, aucun coût, aucun risque d'accord |
| **A2** | Wording du hero | « Votre niveau estimé : B1 » (maquette) vs « Niveau estimé sur cet exercice : B1 » (spec 10_ §3.1) ; garder ou non la note « Ce n'est qu'une première estimation » | garder « sur cet exercice » **et** une note d'honnêteté courte |
| **A3** | Quels 4 critères ? | maquette (message / réponse / vocabulaire / grammaire) vs grille (communiquer / interagir / lexique / morphosyntaxe) | aligner sur la **grille** pour le complet ; pour le rapide, n'afficher que ce qui est mesuré |
| **A4** | Bande **absolue** (niveau du critère) ou **relative à l'objectif** ? Et quels mots ? | « Solide / À renforcer / Prioritaire » vs « Niveau B1… » (actuel, gelé par test) | absolue ; « Solide / À renforcer / À travailler / Non évalué » ; « Prioritaire » réservé au Plan |
| **A5** | Quelle source pour « N priorités » sur un écran « Diagnostic terminé » ? | parcours (3, par sévérité) — **révoque A133 pour cet écran** ; ou diagnostic (≤ 2) | parcours, **en remplaçant** « Ce que nous avons observé » (jamais deux listes) ; repli sans objectif à trancher (§4.5) |
| **A6** | Réintroduire « Les autres épreuves » sur le rapport rapide (révoque en partie D-M-1) ? Sens de « Non évalué » : **par ce diagnostic** ou **par le produit** ? | | oui, neutre ; sens **produit** (une épreuve mesurée ailleurs affiche son niveau, cohérent avec la doctrine du 2026-09-16) |
| **A7** | Le « Pourquoi » | P1 (explication observée, LLM, existante) · P2 (famille de critère éditoriale, migration) · P3 (contrat IA) | P2 pour la ligne courte, P1 en dépliant |
| **A8** | CTA et navigation | « Commencer mon Plan » (conversion sur le rapide — révoque D-M-1) vs « Faire le diagnostic complet » ; bottom nav sur ces écrans (mobile), rien côté web | CTA Plan si `planDisponible`, lien « Affiner » secondaire conservé ; bottom nav : non (écran de fin de parcours, poussé) |
| **A9** | Sous-titre « Pour… » | réutiliser `skills.description` (long) ou écrire 48 lignes courtes | 48 lignes courtes (contenu, pas LLM) si le bloc est retenu |

---

## 9. Fichiers de référence

- Maquette : `docs/diagnostic/maquette-rapport-diagnostic-ee.html`
- Contrats IA : `backend_sejourfr/src/main/resources/prompts/diagnostic-analysis-tool-schema-v1.json`,
  `production-evaluation-tool-schema-v9.json`, `production-rubrics-v15.json`
- Backend : `enums/BandeCritere.java`, `service/AiEvaluationService.java:1136-1151`,
  `service/diagnostic/DiagnosticService.java:235-261, 406-429`,
  `service/diagnostictcf/TcfDiagnosticReadService.java:248-358`,
  `service/diagnostictcf/TcfDiagnosticViewService.java:107-124`,
  `dto/DiagnosticResultDto.java`, `dto/DiagnosticProductionResultDto.java`,
  `dto/DiagnosticSkillObservationDto.java`, `dto/TcfDiagnosticResultDto.java`,
  `dto/TcfDiagnosticSectionDto.java`, `dto/JourneyStepDto.java`, `dto/LearningPlanPriorityDto.java`,
  `dto/EvaluationResultDto.java`, `dto/ProductionBilanResponse.java`
- Web : `app/_components/diagnostic/DiagnosticReport.tsx`, `diagnostic/report-labels.ts`,
  `diagnostic-tcf/TcfDiagnosticResult.tsx`, `production/CriteriaOverview.tsx`,
  `production/production.module.css:1100-1111`, `lib/production-feedback.ts:150-178`,
  `lib/types.ts:3585-3605`, `sejour/SejourKit.tsx`, `plan/PlanGate.tsx:76`
- Mobile : `screens/diagnostic/widgets/diagnostic_result.dart`,
  `screens/diagnostic/widgets/diagnostic_report_labels.dart`,
  `screens/diagnostic_tcf/tcf_diagnostic_result_screen.dart`,
  `screens/tcf_production/widgets/criterion_row.dart`, `core/widgets/sejour/sejour_kit.dart`,
  `screens/shell/main_shell.dart`, `core/router/app_router.dart:637-669`,
  `screens/plan/plan_screen.dart:498`
- Règles et décisions : `docs/regles/diagnostic.md`, `docs/regles/diagnostic-tcf-4-epreuves.md`,
  `docs/regles/plan.md` (R2, D-10), `docs/regles/progression.md:70-92, 404-405, 1115-1124`,
  `docs/review_all/10_SEJOURFR_TCF.md` §3, `docs/review_all/60_DECISIONS_IMPLEMENTATION.md` D-M-1…3,
  `docs/decisions-autonomes-parcours-tcf.md` A133

---

## 10. Bugs et dette relevés pendant l'audit — ouverts, sujet en attente

Relevés en marge de l'étude, **non corrigés**. À traiter à la reprise (idéalement dans le lot 1
backend) ou à sortir en correctif isolé si l'un d'eux gêne avant.

| # | Constat | Où | Invariant / règle violé | Correctif proposé | Statut |
|---|---|---|---|---|---|
| B1 | Les deux fronts **reclassent une note en bande** pour les évaluations antérieures à la `bande` servie | `web_sejoufr/lib/production-feedback.ts:161-178` (`critereBandeFromNote`) ⇄ `mobile_sejourfr/lib/screens/tcf_production/widgets/tcf_note_scale.dart:77` (`TcfNoteScale.bandeFor`), consommé par `criterion_row.dart:46-47` | « Aucun front ne classe un nombre en état » ; « une règle = une autorité » (2 copies front + `BandeCritere.of` serveur) | Le serveur sert la bande **à la lecture** pour le legacy via `BandeCritere.of`, les deux fronts suppriment leur copie (§2.4.e) | ⏸️ ouvert |
| B2 | **Priorités du diagnostic ≠ lot du parcours** pour une même session : compétence, nombre et ordre divergent (4 sessions sur 4 ayant un lot) | `diagnostic_sessions.summary_json.priority_skill_codes` (servi par `DiagnosticResultDto.priorities`) vs lot du parcours TCF — mesure §4.4 | A133 (un écran « diagnostic terminé » lit une seule source) ; risque « deux sources finissent par se contredire » | Choisir une source unique par écran (arbitrage **A5**) ; ne jamais afficher les deux listes | ⏸️ ouvert — arbitrage |
| B3 | **4 sessions rapides sur 8 n'ont aucun lot de Plan** : compte sans objectif déclaré ⇒ pas de parcours | Base locale, §4.4 / §4.5 (D-3 / D-10) | Pas une violation en soi, mais tout écran qui promet « Votre Plan a choisi N priorités » serait **vide** pour la moitié des utilisateurs | Repli à trancher avec A5 : épingle `plan_pinned_priorities` (D-10) ou carte « Choisir mon objectif » (`plan.md:2158-2166`) | ⏸️ ouvert — arbitrage |
| B4 | `communicationStatus` et `taskCompletion` sont **servis mais affichés nulle part** sur le rapport du diagnostic rapide | `DiagnosticResultDto` — §2.4.b | — (donnée mesurée, payée, perdue à l'écran) | Les afficher dès le lot 3 (couvre « Votre message » / « Votre réponse » de la maquette sans coût LLM) | ⏸️ ouvert |

