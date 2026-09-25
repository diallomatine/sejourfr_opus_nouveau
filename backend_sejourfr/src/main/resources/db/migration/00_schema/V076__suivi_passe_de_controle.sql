-- ============================================================================
-- V076 — CHANTIER « SUIVI », passe de controle (docs/admin/controle-suivi.md)
-- ----------------------------------------------------------------------------
-- Additif. Aucune donnee n'est rattrapee : NULL = inconnu (Q16).
-- ============================================================================


-- ---------------------------------------------------------------------------
-- 1. Controle C — « soumis » du diagnostic civique.
--
-- Le diagnostic civique n'a pas d'echeance ; « Quitter » confirme passe par la
-- meme fin d'attempt qu'une fin explicite. Le modele ne distingue donc pas un
-- abandon a 0/40 d'une copie rendue. On FIGE ici une mesure au moment de la
-- soumission (combien de questions posees, combien repondues), et la REGLE
-- (« soumis » = au moins X % de reponses) vit a la lecture, dans la config
-- versionnee (analytics-config-vN.json, civicSubmittedMinAnsweredRatio) :
-- changer le seuil ne demande aucune migration.
--
-- Ecrites par DiagnosticRunRepository.markSubmittedByCivicSession, dans le
-- meme UPDATE que submitted_at, pour les runs CIVIQUE seulement. NULL pour les
-- autres types, et pour les runs civiques soumises avant V076 : inconnu — la
-- lecture ne les compte PAS soumises, et ne les lit jamais comme 0 reponse.
-- ---------------------------------------------------------------------------
ALTER TABLE diagnostic_run
    ADD COLUMN submitted_answered_count integer,
    ADD COLUMN submitted_question_count integer,
    ADD CONSTRAINT chk_diagnostic_run_submitted_counts CHECK (
        (submitted_answered_count IS NULL) = (submitted_question_count IS NULL)
        AND (submitted_answered_count IS NULL
             OR (submitted_at IS NOT NULL
                 AND submitted_answered_count >= 0
                 AND submitted_answered_count <= submitted_question_count))
        );

COMMENT ON COLUMN diagnostic_run.submitted_answered_count IS
    'Civique : questions repondues a la soumission. NULL = autre type, ou run anterieure a V076 (inconnu).';
COMMENT ON COLUMN diagnostic_run.submitted_question_count IS
    'Civique : questions posees a la soumission. NULL = autre type, ou run anterieure a V076 (inconnu).';
