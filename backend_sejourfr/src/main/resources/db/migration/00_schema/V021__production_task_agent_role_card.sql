-- ============================================================================
-- V021 — production_tasks.agent_role_card : fiche de scénario de l'examinateur
-- ----------------------------------------------------------------------------
-- Sans fiche, l'examinateur vocal de l'EO tâche 2 ne reçoit qu'une phrase de
-- contexte et INVENTE tous les faits (prix, délais, horaires) : il peut se
-- contredire en cours d'échange, et on n'a aucune vérité de référence sur ce
-- que le candidat pouvait obtenir.
--
-- La colonne est NULLABLE et réservée à l'EO tâche 2 : les sujets EE et les
-- tâches 1/3 continuent de fonctionner sans, et une tâche EO T2 sans fiche
-- retombe exactement sur le comportement historique de l'examinateur.
--
-- Structure (cf. entity/AgentRoleCard) :
--   { roleAgent, relation, objectifCandidat, phraseOuverture,
--     informationsEssentielles: [{id, valeur, importance}],
--     informationsSecondaires:  [{id, valeur, importance}],
--     contraintesAgent: [".."] }
-- ⚠️ Les `valeur` sont les réponses que le candidat doit obtenir en posant ses
--    questions : elles ne sortent JAMAIS vers un client (aucun champ DTO).
-- ============================================================================

ALTER TABLE production_tasks
    ADD COLUMN agent_role_card jsonb;

ALTER TABLE production_tasks
    ADD CONSTRAINT chk_prod_task_agent_role_card CHECK (
        agent_role_card IS NULL
        OR (
            jsonb_typeof(agent_role_card) = 'object'
            AND (epreuve)::text = 'TCF_EO'
            AND tache_numero = 2
        )
    );

COMMENT ON COLUMN production_tasks.agent_role_card IS
    'EO tâche 2 seulement : fiche de scénario de l''examinateur-personnage (rôle, registre, réplique d''ouverture, faits qu''il détient, contraintes de jeu). Rend l''agent cohérent et donne une vérité de référence. N''est PAS une check-list de notation et n''est jamais exposée au client.';
