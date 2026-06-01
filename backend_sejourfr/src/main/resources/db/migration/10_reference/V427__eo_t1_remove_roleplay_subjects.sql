-- ============================================================================
-- V427 : EO Tâche 1 — suppression des sujets « profil imposé » (role-play)
-- ============================================================================
-- La tâche 1 du TCF EO est un ENTRETIEN DIRIGÉ : le candidat se présente
-- LUI-MÊME. Les sujets ajoutés en V136 (« Vous êtes mécanicien… », « Vous êtes
-- infirmier(ère)… », « Vous êtes réfugié(e)… », etc.) demandaient au candidat
-- de se glisser dans la peau d'un personnage fictif — incohérent avec l'épreuve
-- réelle. On ne conserve que les vraies consignes « Présentez-vous… » (V130,
-- A2/B1/B2).
--
-- Effets de bord gérés :
--   * Les exemples-modèles de la tâche 1 avaient été rattachés (LIMIT 1
--     arbitraire) à un sujet role-play → on les re-rattache à la tâche
--     « Présentez-vous » B1 AVANT suppression, sinon ils seraient perdus par
--     le ON DELETE CASCADE de production_examples.task_id.
--   * Les soumissions éventuelles sur ces sujets sont supprimées (leur prompt
--     disparaît) ; transcriptions / ai_evaluations / human_calibration_notes
--     suivent en CASCADE.
-- ============================================================================

DO $$
DECLARE
    genuine_b1 UUID;
BEGIN
    SELECT id INTO genuine_b1 FROM production_tasks
    WHERE epreuve = 'TCF_EO' AND tache_numero = 1 AND niveau_cible = 'B1'
      AND consigne LIKE 'Présentez-vous%'
    LIMIT 1;

    -- 1. Sauver les exemples rattachés aux sujets role-play.
    UPDATE production_examples
    SET task_id = genuine_b1
    WHERE task_id IN (
        SELECT id FROM production_tasks
        WHERE epreuve = 'TCF_EO' AND tache_numero = 1 AND consigne LIKE 'Vous êtes%'
    );

    -- 2. Purger les soumissions sur les sujets supprimés (cascade vers
    --    transcriptions / ai_evaluations / human_calibration_notes).
    DELETE FROM production_submissions
    WHERE production_task_id IN (
        SELECT id FROM production_tasks
        WHERE epreuve = 'TCF_EO' AND tache_numero = 1 AND consigne LIKE 'Vous êtes%'
    );

    -- 3. Supprimer les sujets « profil imposé » de la tâche 1.
    DELETE FROM production_tasks
    WHERE epreuve = 'TCF_EO' AND tache_numero = 1 AND consigne LIKE 'Vous êtes%';
END $$;
