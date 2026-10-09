-- ============================================================================
-- V091 — Temps candidat issus de la détection LOCALE de voix (examinateur IA,
-- décision D-07 du 2026-10-09, docs/examinateur-ia/DECISIONS.md)
-- ----------------------------------------------------------------------------
-- started_at_ms / ended_at_ms (V090) restent la mesure de RÉFÉRENCE du temps
-- candidat : premier → dernier fragment de transcription, retardés d'autant
-- que la transcription. À partir du lot 2, le client mesure aussi la parole sur
-- l'énergie du micro (début et fin réels, après annulation d'écho) : deux
-- colonnes de plus, à côté, pour ne jamais casser la comparaison avec la base
-- mesurée avant le lot 2.
--
-- Additif et nullable : NULL pour un tour examinateur, pour un client antérieur
-- au lot 2, et quand le micro n'a détecté aucune parole pendant le tour.
-- Mesure seulement : rien n'entre dans une note, un niveau ou un quota.
-- ============================================================================

ALTER TABLE realtime_session_turns
    ADD COLUMN started_at_ms_vad integer,
    ADD COLUMN ended_at_ms_vad   integer;

COMMENT ON COLUMN realtime_session_turns.started_at_ms_vad IS
    'Candidat seulement : début de parole détecté sur l''énergie du micro, en ms depuis setupComplete côté client. NULL = non mesuré.';
COMMENT ON COLUMN realtime_session_turns.ended_at_ms_vad IS
    'Candidat seulement : fin de parole détectée sur l''énergie du micro (même référence). NULL = non mesuré.';
