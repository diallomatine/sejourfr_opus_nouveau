# Lots d'entraînement TCF + Civique (calcul dynamique, sans schéma)

Un **lot** est un sous-ensemble déterministe de questions filtrées par critères propres au
module, trié par `created_at ASC, id ASC`. **Aucune table dédiée** : la composition est dérivée
de la position dans le pool. Tant que le pool ne change pas, Lot 1 renvoie toujours les mêmes
questions.

- **TCF** : (`module=TCF`, `questionType=CO|CE`, `difficulty=A2|B1|B2`).
  Endpoint : `GET /api/lots?module=TCF&questionType=CO&difficulty=A2`.
- **Civique** : (`module=CIVIQUE`, `themeId=<uuid>`).
  Endpoint : `GET /api/lots?module=CIVIQUE&themeId=...`.

**Tailles fixes** (constantes dans `LotService.LOT_SIZE_*`) :

- TCF A2 = 15 · B1 = 20 · B2 = 25
- Civique = 15 (constant, indépendant du thème)

## Règle de découpage

- Pool == 0 → aucun lot exposé.
- Pool < lotSize standard → **1 lot partiel** avec tout le pool. Utile quand le pool CO se
  remplit progressivement (admin génère des audio questions par lot de 5-10 via le pipeline
  IA). Évite d'afficher "0 lot" alors que des questions sont prêtes côté admin.
- Pool ≥ lotSize → N lots complets de taille standard. Les questions au-delà du dernier
  multiple sont ignorées (elles seront exposées quand un nouveau multiple sera atteint).
  Exemple A2 avec 47 questions : Lot 1 (1-15), Lot 2 (16-30), Lot 3 (31-45), les 2 restantes
  en attente.

`AttemptService.startFromLot` utilise `LotService.resolveLotSize(...)` (TCF) ou
`resolveLotSizeCivique(...)` (Civique) pour résoudre la taille effective du lot demandé —
même source de vérité que `GET /api/lots`, donc impossible que les deux endpoints divergent.

## Trace lot ↔ attempt

La migration `V088__attempts_lot_columns.sql` ajoute trois colonnes TCF (`lot_numero`,
`lot_question_type`, `lot_difficulty`), et `V089__attempts_lot_theme_id.sql` ajoute
`lot_theme_id` pour les lots Civique. `startFromLot` remplit les colonnes correspondantes
selon le module. Index partiels `idx_attempts_user_lot` (TCF) et
`idx_attempts_user_lot_civique` (CIVIQUE) couvrent les queries `findFinishedByUserAndLot` /
`findFinishedByUserAndLotCivique`. Les deux chemins (TCF et Civique) enrichissent les
`LotDto` avec `lastScore` + `lastAttemptedAt` du user pour que le mobile différencie
visuellement les lots déjà faits (carte teintée + badge score `X/Y`).

## Côté backend

`backend_sejourfr/src/main/java/com/sejourfr/app/` :

- `dto/LotDto.java` (record `numero / difficulty / totalQuestions`)
- `service/LotService.java` (calcul dynamique + helpers statiques `lotSizeFor`)
- `controller/LotController.java` (`GET /api/lots`)
- `manager/QuestionManager.findLotQuestions(...)` (fenêtre paginée par lotNumero)
- `dto/StartAttemptRequest.java` accepte un champ `lotNumero` ; quand présent,
  `AttemptService.startFromLot` construit l'attempt avec la fenêtre exacte (réservé premium
  TCF, retourne 403 sinon).
- `repository/QuestionRepository.countActiveMatching` étendu avec un filtre `questionType`
  (callers `AdminExamTemplateService` passent `null`).

## Côté mobile

`mobile_sejourfr/lib/` :

- `core/models/lot_models.dart` (LotDto Dart)
- `core/api/lots_repository.dart` (`GET /api/lots`)
- `core/models/attempt_models.dart` : `StartAttemptRequest.lotNumero` ajouté
- `screens/module_detail/tcf_qcm_detail_screen.dart` : onglet Séries affiche 3 sections par
  niveau, lots chargés via `_lotsProvider` family.

Pour ajouter un 4ᵉ niveau (jamais prévu vu que TCF s'arrête à B2) ou changer la taille d'un
lot : modifier les constantes dans `LotService` + ajouter le niveau dans `_seriesLevels` côté
mobile. Pas de migration.
