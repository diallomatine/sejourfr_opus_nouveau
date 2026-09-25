-- ============================================================================
-- V075 — CHANTIER « SUIVI » (lot 4) : la run FONDATRICE d'un parcours, en vue.
-- ----------------------------------------------------------------------------
-- Arbitrage Q8 (docs/admin/decisions-suivi.md) : plan_id = journey.id, et le
-- serveur resout journey -> diagnostic_run fondatrice lui-meme, sans jamais
-- croire un runId envoye par un client.
--
-- UNE REGLE = UNE AUTORITE. Cette resolution avait deux lecteurs :
--   - DiagnosticRunManager.findFoundingRun (un parcours : purchase_intent) ;
--   - la lecture du dashboard Suivi (etapes 5 et 6 du tunnel : les evenements
--     PLAN_OPENED / PLAN_UNLOCK_CLICKED portent un journey_id, a relier a la
--     run de reference de la cohorte, en masse).
-- Une copie SQL par lecteur aurait fini par diverger (la copie du lot 2b
-- divergeait deja sur l'ordre de departage). La regle vit donc ICI, une fois ;
-- les deux lecteurs la lisent.
--
-- Regle : pour chaque parcours, la run liee (par les FK de session) au
-- diagnostic LE PLUS ANCIEN journalise sur ce parcours
-- (journey_assessment_event), appartenant au porteur du parcours.
--   - rapide  : l'evenement porte l'id de diagnostic_sessions ;
--   - civique : l'id de civic_diagnostic_sessions ;
--   - complet : l'id d'une SECTION (attempts), dont tcf_diagnostic_id donne la
--     session.
-- Aucun parcours sans run liee n'apparait : inconnu, jamais une run devinee.
--
-- Vue simple (pas materialisee) : les deux lecteurs filtrent par journey_id,
-- que Postgres pousse sous le DISTINCT ON (colonne de partition).
-- ============================================================================
CREATE VIEW v_journey_founding_run AS
SELECT DISTINCT ON (j.id)
       j.id    AS journey_id,
       j.user_id AS user_id,
       r.id    AS diagnostic_run_id
  FROM journey j
  JOIN journey_assessment_event e ON e.journey_id = j.id
  LEFT JOIN attempts a
         ON e.assessment_kind = 'FULL_DIAGNOSTIC' AND a.id = e.source_assessment_id
  JOIN diagnostic_run r
    ON r.user_id = j.user_id
   AND (   (e.assessment_kind = 'QUICK_DIAGNOSTIC' AND r.diagnostic_session_id = e.source_assessment_id)
        OR (e.assessment_kind = 'CIVIC_DIAGNOSTIC' AND r.civic_diagnostic_session_id = e.source_assessment_id)
        OR (e.assessment_kind = 'FULL_DIAGNOSTIC' AND r.tcf_diagnostic_session_id = a.tcf_diagnostic_id))
 ORDER BY j.id, e.completed_at ASC, e.processed_at ASC, r.subject_viewed_at ASC, r.id ASC;

COMMENT ON VIEW v_journey_founding_run IS
    'Run fondatrice de chaque parcours (Q8) : run liee au diagnostic le plus ancien journalise, du porteur du parcours. Seule autorite, lue par DiagnosticRunRepository et SuiviReadRepository.';
