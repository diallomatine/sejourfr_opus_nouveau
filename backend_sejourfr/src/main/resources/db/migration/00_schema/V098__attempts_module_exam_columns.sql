-- ============================================================================
-- V098 : Examens blancs scopés à un module TCF (CO ou CE uniquement)
-- ============================================================================
-- Un attempt MOCK_EXAM peut être :
--   - un examen blanc complet (toutes épreuves)        → module_exam_question_type IS NULL
--   - un examen blanc scopé à une épreuve TCF QCM      → module_exam_question_type = 'CO' ou 'CE'
--
-- L'examen module tire 25 questions progressives (8 A2 + 9 B1 + 8 B2) en
-- 20 min (CO) ou 35 min (CE). Le score est pondéré par niveau (A2=1, B1=2,
-- B2=3) → max 50 points pour la répartition 8/9/8. Les colonnes
-- weighted_score / max_weighted_score sont remplies à la finalisation pour
-- éviter de recalculer à chaque lecture.
-- ============================================================================

ALTER TABLE attempts
    ADD COLUMN module_exam_question_type VARCHAR(24),
    ADD COLUMN weighted_score INTEGER,
    ADD COLUMN max_weighted_score INTEGER;

-- Liste des examens module passés d'un user : (user, module, type CO/CE)
-- avec tri par finished_at desc pour l'historique.
CREATE INDEX idx_attempts_module_exam
    ON attempts (user_id, module, module_exam_question_type, finished_at DESC)
    WHERE module_exam_question_type IS NOT NULL;
