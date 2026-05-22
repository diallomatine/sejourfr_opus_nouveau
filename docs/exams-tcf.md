# Examens TCF — module et blanc complet

Deux variantes coexistent : **examen module** (CO ou CE seul, sous-set de `MOCK_EXAM`) et
**examen blanc complet** (les 4 épreuves enchaînées sous un parent `TCF_COMPLET`).

---

## Examens module TCF (CO ou CE, sous-set de MOCK_EXAM)

Permet de simuler la passation d'une épreuve TCF QCM unique.

Migration `V098__attempts_module_exam_columns.sql` ajoute :

- `module_exam_question_type` (varchar 24) : `CO` ou `CE` quand scopé, NULL sinon
- `weighted_score` + `max_weighted_score` (int) : score pondéré persisté à la finalisation
  pour éviter de re-joindre `attempt_questions` à chaque lecture
- Index partiel `idx_attempts_module_exam` sur
  `(user_id, module, module_exam_question_type, finished_at DESC)`

### Composition (`AttemptService.composeModuleExam`)

- 8 A2 + 9 B1 + 8 B2 = 25 questions progressives, tirage aléatoire dans chaque strate
  (`module=TCF`, `questionType=CO|CE`)
- Fallback si une strate est sous-dotée : on complète sans contrainte de niveau

### Chrono

20 min CO / 35 min CE (constantes `MODULE_EXAM_CO_SECONDS` / `MODULE_EXAM_CE_SECONDS`).

### Score pondéré

A2=1, B1=2, B2=3 → max 50 pts pour la répartition 8/9/8. Calculé à la finalisation par
`computeWeightedScore`.

### Endpoints

- `POST /api/attempts {type:MOCK_EXAM, module:TCF, moduleExamQuestionType:CO|CE}` →
  `AttemptService.startModuleExam` (premium TCF requis)
- `GET /api/me/attempts?type=MOCK_EXAM&module=TCF&moduleExamQuestionType=CO|CE` →
  historique des examens passés/en cours du user
- `GET /api/me/questions/wrong?module=TCF&questionType=CO|CE` → questions ratées filtrées
  par épreuve (utilisé par l'onglet Erreurs)

`AttemptSummaryResponse` (et son miroir Dart `AttemptSummary`) exposent
`moduleExamQuestionType`, `weightedScore`, `maxWeightedScore` (null pour les autres
attempts). Côté mobile : `_ExamsTab` dans `TcfQcmDetailScreen` affiche l'intro + l'historique
avec badge score coloré, `_ErrorsTab` liste les questions ratées avec leur niveau.

---

## Examen blanc TCF complet (les 4 épreuves enchaînées)

Enchaîne **CO + CE + EE + EO** sous un seul parent `epreuve = TCF_COMPLET`. Chrono global
90 min (CO 20 + CE 30 + EE 30 + EO 10). Le niveau final est le **plancher CECRL des 4
sous-épreuves** (règle officielle TCF IRN).

### Modèle de données

- Parent `attempts` avec `epreuve = TCF_COMPLET`, sans questions propres,
  `time_limit_seconds = 5400` (90 min), `final_cecrl_level` rempli à la finalisation quand
  toutes les évaluations IA EE/EO sont prêtes.
- 4 sous-attempts liés via `attempts.parent_attempt_id` (cf. migration V96) :
    - `TCF_CO` : 25 QCM (8 A2 + 9 B1 + 8 B2), chrono 20 min, score pondéré /50
    - `TCF_CE` : idem CE, chrono **30 min** (raccourci du 35 min standalone via constante
      `FULL_EXAM_CE_SECONDS`)
    - `TCF_EE` : attempt vide, 3 submissions liées via `production_submissions.attempt_id`
    - `TCF_EO` : idem EO
- Migration `V099__attempts_final_cecrl_level.sql` : colonne
  `final_cecrl_level VARCHAR(24)` nullable sur `attempts`.

### Création atomique (`FullTcfExamService.start`)

Un seul POST crée parent + 4 sous-attempts en transaction. Réservé aux abonnés TCF
(`hasTcf(userId)`). Réutilise `AttemptService.startModuleExamSubAttempt` pour CO/CE (skip le
check premium puisque le parent porte l'accès) et `AttemptService.startProductionAttempt`
pour EE/EO (déjà capable de gérer `parentAttemptId` avec validation `TCF_COMPLET`).

### Statut global (`FullTcfExamResponse.FullTcfExamStatus`)

- `IN_PROGRESS` : ≥1 sous-attempt n'a pas `finished_at`
- `PENDING_EVALUATIONS` : tous finis mais ≥1 eval IA EE/EO pas EVALUATED
- `COMPLETED` : tout fini + tout évalué + `final_cecrl_level` posé

### Calcul du CECRL plancher

`FullTcfExamService.weightedScoreToCecrl` + `floorOfCecrls` :

- CO/CE : ratio = weightedScore/maxWeightedScore → ≥80% B2 · ≥60% B1 · ≥40% A2 · ≥20% A1 ·
  sinon A1_NON_ATTEINT
- EE/EO : plancher des `niveauCecrl` des 3 `AiEvaluation` liées aux 3 submissions
- Final = min ordinal des 4 (A1_NON_ATTEINT(0) < A1 < A2 < B1 < B2 < C1 < C2)

### Endpoints

- `POST /api/full-tcf-exams` → `start(userId)` (premium TCF requis)
- `GET /api/full-tcf-exams/{id}` → état complet (parent + 4 sous-attempts + calcul CECRL
  lazy si non encore persisté)
- `POST /api/full-tcf-exams/{id}/finish` → marque finished_at + persiste
  `final_cecrl_level` quand prêt
- `GET /api/me/full-tcf-exams?limit=N` → historique compact (sans détail des sous-attempts)

### Côté backend

`backend_sejourfr/src/main/java/com/sejourfr/app/` :

- `service/FullTcfExamService.java` — orchestration
- `controller/FullTcfExamController.java` — REST
- `dto/FullTcfExamResponse.java` + `FullTcfExamSummaryResponse.java`
- `service/AttemptService.startModuleExamSubAttempt(...)` — variante sans check premium pour
  sous-attempts
- `manager/AttemptManager.findSubAttempts(...)` + `findByUserAndEpreuve(...)`
- `manager/ProductionSubmissionManager.findByAttemptId(...)` — submissions d'un sous-attempt
  EE/EO

### Côté mobile (à brancher dans un lot suivant)

Riverpod orchestrator qui enchaîne CO → CE → EE 3T → EO 3T, écran progression "Étape X/4",
écran bilan final agrégé CECRL plancher. L'UI des 20 slots (`TcfFullExamsScreen`) + briefing
modal sont déjà en place.

### Gotchas

- `FullTcfExamService.start` n'a PAS de quota anti-spam : un user premium peut créer autant
  d'examens blancs qu'il veut. Si besoin, ajouter un filter Bucket4j sur le controller.
- Pour l'orchestration mobile, **chaque sous-attempt vit indépendamment** : le runner QCM
  existant (avec `_isModuleExam` strict) fonctionne sans modification sur les sous-attempts
  CO/CE, et le flow production aussi pour EE/EO (juste passer `attemptId` du sous-attempt
  aux 3 submissions).
- L'agrégation CECRL est **idempotente** : tant que `final_cecrl_level` est NULL et que
  `status == COMPLETED`, un appel `get` ou `finish` la persiste.
