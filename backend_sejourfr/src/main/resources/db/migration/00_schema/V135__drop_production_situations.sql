-- ============================================================================
-- V135 : Simplification du module Expression — suppression des situations
-- ============================================================================
-- Modélisation retenue (correctif final) :
--   * production_tasks  = les SUJETS d'entraînement (plusieurs lignes par
--     (epreuve, tache_numero)). Le candidat en choisit un et produit sa réponse.
--   * production_examples = modèles illustratifs rattachés à une tâche (task_id)
--     + un champ `explications` (commentaire pédagogique).
--
-- On supprime donc production_situations + production_situation_medias et la
-- colonne production_submissions.situation_id (une tentative est rattachée au
-- sujet via production_task_id, déjà présent). Les supports visuels ne sont pas
-- gérés pour l'instant.
--
-- Numéro > 134 volontaire : les seeds V133/V134 (déjà appliqués) insèrent encore
-- dans production_situations ; cette migration doit passer APRÈS eux (y compris
-- sur une base neuve où V107 crée la table, V133/V134 la peuplent, puis V135 la
-- supprime).
-- ============================================================================

-- 1. La submission n'est plus rattachée à une situation (l'index part avec la colonne).
ALTER TABLE production_submissions DROP COLUMN IF EXISTS situation_id;

-- 2. Suppression des tables situations + supports (medias référence situations).
DROP TABLE IF EXISTS production_situation_medias;
DROP TABLE IF EXISTS production_situations;

-- 3. Commentaire pédagogique sur les modèles.
ALTER TABLE production_examples ADD COLUMN explications TEXT;

COMMENT ON COLUMN production_examples.explications IS
    'Commentaire pédagogique affiché sous le contenu du modèle, pour orienter le candidat (ce qui fait que ce modèle réussit la tâche).';
COMMENT ON TABLE production_tasks IS
    'Sujets d''entraînement EO/EE : plusieurs lignes par (epreuve, tache_numero). Le candidat en choisit un et produit sa réponse, corrigée par l''IA.';
