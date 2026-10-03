-- ============================================================================
-- V085 — Signalements admin d'une évaluation IA (console « Productions IA »)
-- ----------------------------------------------------------------------------
-- Chantier « Admin · Productions & corrections IA » (audit validé :
-- docs/admin/productions_corrections/audit-admin-productions-ia.md §E.1, F-3 A ;
-- décisions d'implémentation : decisions-implementation-productions-ia.md).
--
-- 🛑 Strictement ADDITIF. Un signalement ne modifie JAMAIS ai_evaluations :
-- ni note, ni niveau, ni feedback. Il vit à part, et le résultat servi au
-- candidat est le même avant et après.
--
-- États : actif (removed_at NULL), vérifié (verified_at posé), retiré
-- (removed_at posé — retrait « soft », l'historique est conservé).
-- Au plus UN signalement vivant par évaluation ; un retrait libère la place.
-- submission_id est dénormalisé pour le filtre de la liste admin.
-- ============================================================================
CREATE TABLE ai_evaluation_flags (
    id               UUID          PRIMARY KEY,
    evaluation_id    UUID          NOT NULL REFERENCES ai_evaluations (id) ON DELETE CASCADE,
    submission_id    UUID          NOT NULL REFERENCES production_submissions (id) ON DELETE CASCADE,
    motif            VARCHAR(32)   NOT NULL
        CONSTRAINT ck_ai_evaluation_flags_motif
            CHECK (motif IN ('NIVEAU_INCOHERENT', 'SCORE_INCOHERENT', 'FEEDBACK_INCORRECT',
                             'REPONSE_MAL_COMPRISE', 'TRANSCRIPTION', 'AUTRE')),
    commentaire      VARCHAR(1000) NULL,
    created_by       UUID          NOT NULL REFERENCES users (id),
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),
    verified_by      UUID          NULL REFERENCES users (id),
    verified_at      TIMESTAMPTZ   NULL,
    removed_by       UUID          NULL REFERENCES users (id),
    removed_at       TIMESTAMPTZ   NULL,
    CONSTRAINT ck_ai_evaluation_flags_verification
        CHECK ((verified_at IS NULL) = (verified_by IS NULL)),
    CONSTRAINT ck_ai_evaluation_flags_retrait
        CHECK ((removed_at IS NULL) = (removed_by IS NULL))
);

CREATE UNIQUE INDEX uq_ai_evaluation_flags_actif
    ON ai_evaluation_flags (evaluation_id) WHERE removed_at IS NULL;

CREATE INDEX idx_ai_evaluation_flags_submission_actif
    ON ai_evaluation_flags (submission_id) WHERE removed_at IS NULL;

COMMENT ON TABLE ai_evaluation_flags IS
    'Signalements admin d''une évaluation IA. N''altère JAMAIS ai_evaluations : ni note, ni niveau, ni feedback.';
