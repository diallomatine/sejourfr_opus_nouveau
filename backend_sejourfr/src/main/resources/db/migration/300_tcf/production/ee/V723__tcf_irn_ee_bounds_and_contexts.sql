-- ============================================================================
-- V723 — TCF IRN Expression écrite : bornes officielles et destinataires
-- ----------------------------------------------------------------------------
-- Le projet couvre exclusivement le TCF IRN :
--   - tâche 1 : 30 à 60 mots ;
--   - tâches 2 et 3 : 60 à 90 mots.
-- Le contexte des tâches 2 et 3 explicite également le destinataire afin que
-- l'évaluation de l'adaptation et de l'interaction ne repose pas sur une
-- supposition du correcteur.
-- ============================================================================

UPDATE production_tasks
SET mots_min = CASE WHEN tache_numero = 1 THEN 30 ELSE 60 END,
    mots_max = CASE WHEN tache_numero = 1 THEN 60 ELSE 90 END
WHERE epreuve = 'TCF_EE';

UPDATE production_tasks
SET contexte = CASE id
    WHEN '85ae18b5-b014-426f-a15a-059cae856f8d'::uuid THEN
        'Votre ami Samir vous écrit : « Tu m''as dit que tu étais sorti au restaurant ou à une fête récemment. Raconte-moi comment ça s''est passé ! »'
    WHEN '89436b56-7ebb-4ee9-8504-7677fe1164fe'::uuid THEN
        'Sur le forum de votre cours de français, les participants partagent une expérience qui leur a appris quelque chose d''important sur eux-mêmes.'
    WHEN '08e3acd5-c88e-4ba3-8166-520862865128'::uuid THEN
        'Un proche qui doit faire un choix important vous demande de raconter une décision difficile et le regard que vous portez aujourd''hui sur ses conséquences.'
    ELSE
        'Vous publiez ce récit sur un forum francophone afin de partager votre expérience avec les autres participants.'
    END
WHERE epreuve = 'TCF_EE'
  AND tache_numero = 2
  AND NULLIF(BTRIM(contexte), '') IS NULL;

UPDATE production_tasks
SET contexte = 'Vous participez à une discussion sur un forum francophone. Vous répondez aux autres participants, qui peuvent ne pas partager votre opinion.'
WHERE epreuve = 'TCF_EE'
  AND tache_numero = 3
  AND NULLIF(BTRIM(contexte), '') IS NULL;

ALTER TABLE production_tasks
    ADD CONSTRAINT chk_prod_task_tcf_irn_ee_word_bounds CHECK (
        epreuve <> 'TCF_EE'
        OR (tache_numero = 1 AND mots_min = 30 AND mots_max = 60)
        OR (tache_numero IN (2, 3) AND mots_min = 60 AND mots_max = 90)
    );

ALTER TABLE production_tasks
    ADD CONSTRAINT chk_prod_task_tcf_irn_ee_context CHECK (
        epreuve <> 'TCF_EE'
        OR tache_numero = 1
        OR NULLIF(BTRIM(contexte), '') IS NOT NULL
    );
