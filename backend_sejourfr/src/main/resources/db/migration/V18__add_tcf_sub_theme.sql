-- V18 : sous-theme TCF pour les questions audio CO generees
-- Les questions audio CO sont toutes attachees au theme generique TCF_CO.
-- Cette colonne stocke le sous-theme suggere par Claude (sante, transports,
-- environnement, ...) : utile pour la prevue admin, les stats et le filtrage.

ALTER TABLE questions
    ADD COLUMN IF NOT EXISTS tcf_sub_theme VARCHAR(64);

CREATE INDEX IF NOT EXISTS idx_questions_tcf_sub_theme
    ON questions(tcf_sub_theme)
    WHERE tcf_sub_theme IS NOT NULL;

COMMENT ON COLUMN questions.tcf_sub_theme IS
    'Sous-theme TCF CO (sante, transports, ...), null pour les questions civique ou non audio.';
