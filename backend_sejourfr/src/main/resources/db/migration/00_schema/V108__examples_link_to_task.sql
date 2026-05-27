-- ============================================================================
-- V108 : production_examples se rattache à la TÂCHE, plus à la situation
-- ============================================================================
-- Clarification sémantique (cf. correctif spec) :
--   * production_situations = les SUJETS que le candidat traite (ex. "Vous êtes
--     mécanicien, présentez-vous"). Il en choisit un et produit sa réponse.
--   * production_examples   = des MODÈLES illustratifs de la TÂCHE (ex. "un
--     boulanger qui se présente"). Indépendants du sujet choisi ; le candidat
--     les consulte pour s'inspirer.
--
-- On migre donc le lien examples → situation vers examples → task, en backfillant
-- les exemples déjà seedés (V133) depuis la situation à laquelle ils étaient
-- rattachés.
-- ============================================================================

ALTER TABLE production_examples
    ADD COLUMN task_id UUID REFERENCES production_tasks(id) ON DELETE CASCADE;

-- Backfill : chaque exemple hérite de la tâche de sa situation d'origine.
UPDATE production_examples e
SET task_id = s.task_id
FROM production_situations s
WHERE e.situation_id = s.id;

-- Filet de sécurité : si un exemple orphelin subsistait (situation supprimée),
-- on ne peut pas deviner sa tâche -> on le supprime (contenu de seed only).
DELETE FROM production_examples WHERE task_id IS NULL;

ALTER TABLE production_examples
    ALTER COLUMN task_id SET NOT NULL;

-- Drop de l'ancien lien situation (la colonne emporte sa FK + son index).
DROP INDEX IF EXISTS idx_prod_examples_situation;
ALTER TABLE production_examples
    DROP COLUMN situation_id;

CREATE INDEX idx_prod_examples_task ON production_examples(task_id, display_order);

COMMENT ON TABLE production_situations IS
    'Sujets d''entrainement concrets pour une tache (ex: "Vous etes mecanicien, presentez-vous"). Le candidat en choisit un et produit sa reponse.';
COMMENT ON TABLE production_examples IS
    'Reponses modeles illustrant une tache (ex: "un boulanger qui se presente"). Rattachees a la tache, pas a une situation. Le candidat les consulte pour s''inspirer.';
