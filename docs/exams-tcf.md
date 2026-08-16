# Examens TCF — module et blanc complet

Deux variantes coexistent : **examen module** (CO, CE ou STRUCTURE seul, sous-set de
`MOCK_EXAM`) et **examen blanc complet** (les 4 épreuves IRN enchaînées sous un parent
`TCF_COMPLET`).

> **STRUCTURE** est un module bonus exposé côté mobile (hors TCF IRN officiel). Les
> examens module sur STRUCTURE fonctionnent comme CO/CE (25 Q, 20 min, score pondéré
> A2/B1/B2 sur /50) mais ne sont jamais inclus comme sous-attempt d'un examen blanc
> complet — la validation de `startModuleExamSubAttempt` reste restreinte à CO/CE.

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

20 min CO / 35 min CE / 20 min STRUCTURE. **Source unique : l'enum `DureeEpreuve`**
(données d'examen, pas de config YAML) — les anciennes constantes `MODULE_EXAM_*` ont
disparu. Une épreuve a la **même durée où qu'elle soit jouée**, standalone comme en
examen complet. Le chrono est **opposable serveur** : une réponse postée après
l'échéance (+ 60 s de grâce, `DureeEpreuve.GRACE_SOUMISSION_SECONDS`) est refusée en 422,
et la session est **clôturée automatiquement à la lecture suivante** avec les réponses
déjà enregistrées (pas de job planifié — expiration paresseuse, comme les abonnements).

### Score pondéré

A2=1, B1=2, B2=3 → max 50 pts pour la répartition 8/9/8. Calculé à la finalisation par
`computeWeightedScore`.

### Le niveau affiché après une épreuve CO, CE ou STRUCTURE

Après chaque épreuve à questions à choix multiples, deux informations sont
rendues : un **score sur 499**, l'échelle du relevé officiel du TCF, et un
**niveau** (A1 non atteint, A1, A2, B1, B2).

Le score est calculé « au-dessus du hasard » : dans un QCM à quatre propositions,
on obtient déjà environ un quart de bonnes réponses en cochant au petit bonheur.
Ce quart-là ne compte donc pas, et un résultat qui reste en dessous retombe à la
note plancher de 100 sur 499.

Une conséquence était injuste, et elle est corrigée depuis le 17 août 2026 :
**« A1 non atteint » est désormais réservé au candidat qui n'a obtenu aucune
bonne réponse.** Dès qu'il en a **au moins une**, le niveau affiché est au
minimum **A1**. Avant, une personne ayant six bonnes réponses sur vingt-cinq
recevait exactement le même verdict que celle qui n'en avait aucune — le score
étant identique dans les deux cas, le niveau l'était aussi. Ce n'était pas faux
au sens du calcul, mais c'était faux au sens de ce que la personne avait montré.

Deux précisions, pour être exact :

- **Le score, lui, ne change pas.** Une seule bonne réponse vaut toujours
  100 sur 499 : on ne relève pas la note, on cesse seulement de dire « A1 non
  atteint » à quelqu'un qui a réussi quelque chose. Le barème du TCF n'est pas
  retouché, cette règle est une décision de SejourFR posée par-dessus.
- **Ne pas répondre du tout, c'est n'avoir aucune bonne réponse** : le niveau
  reste « A1 non atteint ». En revanche, une épreuve qu'on n'a **jamais ouverte**
  — parce qu'on a quitté l'examen avant, ou parce qu'elle est réservée à
  l'abonnement — n'a pas de niveau du tout, et n'est comptée nulle part. Ne rien
  savoir n'est pas la même chose que mal faire.

### Endpoints

- `POST /api/attempts {type:MOCK_EXAM, module:TCF, moduleExamQuestionType:CO|CE|STRUCTURE}`
  → `AttemptService.startModuleExam` (premium TCF requis)
- `GET /api/me/attempts?type=MOCK_EXAM&module=TCF&moduleExamQuestionType=CO|CE|STRUCTURE`
  → historique des examens passés/en cours du user
- `GET /api/me/questions/wrong?module=TCF&questionType=CO|CE|STRUCTURE` → questions ratées
  filtrées par épreuve (utilisé par l'onglet Erreurs)

`AttemptSummaryResponse` (et son miroir Dart `AttemptSummary`) exposent
`moduleExamQuestionType`, `weightedScore`, `maxWeightedScore` (null pour les autres
attempts). Côté mobile : `_ExamsTab` dans `TcfQcmDetailScreen` affiche l'intro + l'historique
avec badge score coloré, `_ErrorsTab` liste les questions ratées avec leur niveau.

---

## Examen blanc TCF complet (les 4 épreuves enchaînées)

Enchaîne **CO + CE + EE + EO** sous un seul parent `epreuve = TCF_COMPLET`. Le niveau
final est le **plancher CECRL des 4 sous-épreuves** (règle officielle TCF IRN).

⚠️ **Il n'y a plus de chrono global.** L'enveloppe de 90 min a été supprimée : le total
réel fait ~95 min (CO 20 + CE 35 + EE 30 + EO ~10 de parole), le temps restant d'une
épreuve ne se transfère **jamais** à la suivante, et l'abandon-reprise entre deux épreuves
est officiellement supporté — un compte à rebours d'ensemble expirerait au nez du candidat
qui reprend le lendemain. Chaque sous-épreuve porte sa propre durée, servie aux fronts sur
`FullTcfExamResponse.SubAttempt.timeLimitSeconds` / `timerStartedAt` / `deadlineAt` (ils ne
recopient plus les minutes en dur).

### Modèle de données

- Parent `attempts` avec `epreuve = TCF_COMPLET`, sans questions propres,
  **`time_limit_seconds` NULL** (plus d'enveloppe globale), `final_cecrl_level` rempli à la
  finalisation quand toutes les évaluations IA EE/EO sont prêtes. `timer_started_at` y
  reste, mais comme **trace du début réel** de l'examen — plus comme ancre d'un décompte.
- 4 sous-attempts liés via `attempts.parent_attempt_id` (cf. migration V96) :
    - `TCF_CO` : 25 QCM (8 A2 + 9 B1 + 8 B2), chrono 20 min, score pondéré /50
    - `TCF_CE` : idem CE, chrono **35 min** — comme en standalone. Il valait 30 min ici
      pour tenir dans l'enveloppe de 90 min, désormais supprimée.
    - `TCF_EE` : attempt vide, chrono **30 min**, 3 submissions liées via
      `production_submissions.attempt_id`
    - `TCF_EO` : idem, mais **sans chrono d'épreuve** (`time_limit_seconds` NULL) : le
      temps se compte **par tâche**, au lancement de chaque tâche
      (`production_tasks.duree_max_sec` = 180 / 210 / 210 s)

Le chrono d'une sous-épreuve **ne démarre qu'au lancement réel** de l'épreuve
(`POST /api/full-tcf-exams/{id}/begin` → `timer_started_at`) : les 4 sous-attempts étant
créés d'un bloc, leur `started_at` ne dit rien du moment où le candidat les ouvre. Tant que
`timer_started_at` est NULL, l'épreuve n'a **pas** d'échéance. Autorité unique :
`AttemptChrono`.

### Statut de continuité (dérivé serveur, jamais persisté)

`FullTcfExamResponse.continuite` (`ContinuiteSimulation`, NULL tant que l'examen n'est pas
terminé) : `SESSION_UNIQUE` (« Simulation complète — conditions examen ») si aucune pause
entre deux épreuves ne dépasse 15 min, `PLUSIEURS_SESSIONS` (« Simulation complétée en
plusieurs sessions ») sinon. À ne pas confondre avec `finalLevelPartial`, qui répond à une
autre question : sur combien d'épreuves porte le niveau.
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
- EE/EO : **moyenne pondérée des compétences des 3 tâches** (poids **égaux** depuis les
  rubriques v5, `poids-taches`, cf. `ProductionBilanService.bilanEpreuve`) → seuils →
  niveau d'épreuve, plafonné B2. (Avant : plancher `min()` des 3 niveaux — abandonné, une
  seule éval IA basse sur une tâche courte plafonnait l'épreuve.) Puis **garde-fou de
  cohérence**, désormais **actif** : pas de B2 d'épreuve si la tâche 3 est sous B1
  (`coherence-bilan`, n'abaisse jamais l'inverse — cf. `docs/notation-ia-eo-ee.md` §6.5 bis).
- EE/EO **verrouillée** (freemium, `attempts.production_locked` sur le parent) : **aucun
  niveau** (`cecrlLevel = null`, `locked = true`). Une épreuve verrouillée n'a pas été
  passée — la compter `A1_NON_ATTEINT` restituait un verrou commercial comme un verdict de
  langue. Le verrou lui-même est inchangé.
- Final = min ordinal des épreuves **réellement passées** (A1_NON_ATTEINT(0) < A1 < A2 <
  B1 < B2 < C1 < C2). Hors périmètre : épreuve `locked`, et épreuve sans niveau (évals IA
  en échec ou en vol) — `min()` ignore l'inconnu. Le périmètre effectif est publié :
  `epreuvesCountedInFinalLevel` (0..4), `epreuvesExpected` (4), `finalLevelPartial`
  (= `counted < expected`). **Les fronts doivent lire ces champs** au lieu d'écrire « le
  plus bas de tes 4 épreuves » en dur. Le résumé d'historique
  (`FullTcfExamSummaryResponse`) porte `finalLevelPartial` pour que les stats « meilleur
  niveau » / « dernier examen » n'agrègent pas un bilan partiel comme un examen complet.
  Migration `V024` : les `final_cecrl_level` déjà persistés sur des examens verrouillés
  sont remis à NULL pour forcer la re-dérivation.

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
