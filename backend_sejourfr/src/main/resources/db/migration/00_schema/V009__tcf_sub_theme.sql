-- V18 : sous-thème TCF pour les questions audio CO générées
-- Les questions audio CO sont toutes attachées au thème générique TCF_CO.
-- Cette colonne stocke le sous-thème suggéré par Claude (santé, transports,
-- environnement, ...) : utile pour la preview admin, les stats et le filtrage.

ALTER TABLE questions
    ADD COLUMN IF NOT EXISTS tcf_sub_theme VARCHAR(64);

CREATE INDEX IF NOT EXISTS idx_questions_tcf_sub_theme
    ON questions(tcf_sub_theme)
    WHERE tcf_sub_theme IS NOT NULL;

COMMENT ON COLUMN questions.tcf_sub_theme IS
    'Sous-thème TCF CO (santé, transports, ...), null pour les questions civique ou non audio.';
