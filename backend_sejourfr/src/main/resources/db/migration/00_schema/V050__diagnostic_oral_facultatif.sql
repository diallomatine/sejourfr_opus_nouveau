-- ==========================================================================
-- V050 — Le diagnostic peut n'avoir QU'UNE production (lot L3)
--
-- `10_` §3 et `50_` §3.2 : le diagnostic rapide est UNE production écrite
-- transversale de 150-220 mots. Elle remplace la paire (EE 100-120 mots +
-- EO 2 min). Conséquence acceptée et arbitrée : plus aucun signal oral à
-- l'entrée -- le diagnostic TCF complet (L4) évalue EO1+EO2+EO3.
--
-- 🛑 CETTE MIGRATION NE SUPPRIME RIEN ET NE RÉÉCRIT RIEN.
-- Les deux colonnes orales deviennent seulement FACULTATIVES. Les sessions
-- déjà passées gardent leur production orale, leur analyse et leur résultat :
-- ce sont des mesures réelles, et le dépôt ne recalcule jamais un verdict
-- rétroactivement. Un diagnostic à une production et un diagnostic à deux
-- productions coexistent, et c'est le CONTENU (le couple diagnostic_code /
-- diagnostic_version) qui dit lequel est servi -- jamais un drapeau.
--
-- C'est ce qui rend le retour arrière gratuit : reposer
-- `sejourfr.diagnostic.initial-code: INITIAL_TCF` suffit à reservir la paire.
-- Aucune migration inverse, aucune donnée à reconstruire.
-- ==========================================================================

ALTER TABLE diagnostic_sessions ALTER COLUMN oral_task_id DROP NOT NULL;
ALTER TABLE diagnostic_sessions ALTER COLUMN oral_attempt_id DROP NOT NULL;

COMMENT ON COLUMN diagnostic_sessions.oral_task_id IS
    'Sujet oral. NULL = ce diagnostic n''a pas d''étape orale (diagnostic rapide, L3). '
    'Jamais « oral perdu » : une session qui en avait un le garde.';
COMMENT ON COLUMN diagnostic_sessions.oral_attempt_id IS
    'Attempt oral. NULL = ce diagnostic n''a pas d''étape orale (diagnostic rapide, L3).';
