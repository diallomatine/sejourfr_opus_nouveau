-- ============================================================================
-- 097 : Lien attempt ↔ lot d'entraînement TCF QCM
-- ============================================================================
-- Un attempt peut être issu d'un "lot" (chunk déterministe de 15/20/25 questions
-- selon le niveau) — cf. backend_sejourfr `LotService`. On stocke ici les 3
-- valeurs qui identifient le lot d'origine (toutes NULL pour les attempts
-- libres / examens blancs / productions).
--
-- Objectif : permettre à `GET /api/lots` d'enrichir chaque LotDto avec le
-- dernier score de l'utilisateur sur ce lot précis (différenciation visuelle
-- côté mobile : un lot déjà fait affiche son score).
-- ============================================================================

ALTER TABLE attempts
    ADD COLUMN lot_numero INTEGER,
    ADD COLUMN lot_question_type VARCHAR(24),
    ADD COLUMN lot_difficulty VARCHAR(8);

-- Index composite pour la query "dernier attempt fini par lot d'un user".
-- Couvre les filtres (user_id, module, lot_question_type, lot_difficulty)
-- + tri par finished_at — cf. `AttemptManager.findLastFinishedByLots`.
CREATE INDEX idx_attempts_user_lot
    ON attempts (user_id, module, lot_question_type, lot_difficulty, lot_numero, finished_at DESC)
    WHERE lot_numero IS NOT NULL;
