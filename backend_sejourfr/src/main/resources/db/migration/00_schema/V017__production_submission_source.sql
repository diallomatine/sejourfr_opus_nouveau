-- ============================================================================
-- V017 — Origine d'une production_submissions (ASYNC vs REALTIME)
-- ----------------------------------------------------------------------------
-- Le mode EO temps réel crée une submission dont la production est portée par
-- la `transcriptions` (le dialogue candidat), SANS audio stocké (le flux audio
-- est passé directement client <-> fournisseur, pas par R2) et sans texte EE.
--
-- Le CHECK historique `chk_prod_sub_audio_or_text` imposait media_url XOR
-- texte_soumis : on l'assouplit pour autoriser le cas REALTIME (les deux NULL),
-- tout en conservant la contrainte stricte pour les submissions ASYNC.
-- La notation réutilise le pipeline existant (Whisper sauté car la transcription
-- est pré-remplie) — aucune modification des règles de notation.
-- ============================================================================

ALTER TABLE production_submissions
    ADD COLUMN source varchar(16) DEFAULT 'ASYNC'::varchar NOT NULL;

ALTER TABLE production_submissions
    ADD CONSTRAINT chk_prod_sub_source
    CHECK (((source)::text = ANY ((ARRAY['ASYNC','REALTIME'])::text[])));

ALTER TABLE production_submissions
    DROP CONSTRAINT chk_prod_sub_audio_or_text;

ALTER TABLE production_submissions
    ADD CONSTRAINT chk_prod_sub_audio_or_text CHECK (
        -- REALTIME : ni audio ni texte (production dans transcriptions).
        (((source)::text = 'REALTIME'::text) AND (media_url IS NULL) AND (texte_soumis IS NULL))
        -- ASYNC : audio EO XOR texte EE, comme avant.
        OR (((source)::text = 'ASYNC'::text)
            AND (((media_url IS NOT NULL) AND (texte_soumis IS NULL))
              OR ((media_url IS NULL) AND (texte_soumis IS NOT NULL))))
    );

COMMENT ON COLUMN production_submissions.source IS 'ASYNC (upload audio/texte classique) ou REALTIME (session EO temps réel, production dans transcriptions, sans media).';
