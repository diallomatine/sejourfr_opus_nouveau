-- ============================================================================
-- V724 — TCF IRN Expression écrite : minimum de mots des tâches 2 et 3 = 40
-- ----------------------------------------------------------------------------
-- V723 avait figé les tâches 2 et 3 à 60-90 mots. Le volume officiel du TCF IRN
-- est 40-90 : une copie de 40 à 59 mots est parfaitement recevable. Comme les
-- bornes sont STRICTES depuis V723 (aucune tolérance, serveur + fronts +
-- auto-soumission), ces copies étaient refusées à la soumission — un candidat
-- bloqué sans raison.
--
-- Seul le MINIMUM des tâches 2 et 3 bouge. La tâche 1 (30-60) et tous les
-- maximums sont inchangés. Aucun sujet n'est réécrit, aucun contenu supprimé :
-- c'est un UPDATE de deux colonnes numériques. Les 9 exemples-modèles livrés
-- (V761/V762) comptent 54-59 mots en T1 et 70-88 mots en T2/T3 : ils restent
-- tous dans leur fourchette, qui ne fait que s'élargir vers le bas.
--
-- La contrainte de V723 impose encore mots_min = 60 : elle est retirée avant
-- l'UPDATE puis reposée sur les bornes corrigées. Rejouable sans effet.
-- ============================================================================

ALTER TABLE production_tasks
    DROP CONSTRAINT IF EXISTS chk_prod_task_tcf_irn_ee_word_bounds;

UPDATE production_tasks
SET mots_min = 40
WHERE epreuve = 'TCF_EE'
  AND tache_numero IN (2, 3)
  AND mots_min IS DISTINCT FROM 40;

ALTER TABLE production_tasks
    ADD CONSTRAINT chk_prod_task_tcf_irn_ee_word_bounds CHECK (
        epreuve <> 'TCF_EE'
        OR (tache_numero = 1 AND mots_min = 30 AND mots_max = 60)
        OR (tache_numero IN (2, 3) AND mots_min = 40 AND mots_max = 90)
    );
