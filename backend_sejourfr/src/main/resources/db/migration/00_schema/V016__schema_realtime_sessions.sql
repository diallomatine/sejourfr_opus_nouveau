-- ============================================================================
-- V016 — Sessions d'expression orale en temps réel (examinateur IA, T1/T2)
-- ----------------------------------------------------------------------------
-- Mode conversationnel temps réel qui S'AJOUTE au pipeline async (il ne
-- remplace rien). Un agent vocal joue l'examinateur sur les Tâches 1 et 2 de
-- l'EO ; le dialogue est noté après coup par le pipeline d'évaluation existant.
--
-- Cette table sert deux rôles :
--   1. LEDGER DE QUOTA — une ligne = une session ; le quota par pass est dérivé
--      par comptage (ACTIVE + COMPLETED) scopé sur `subscription_id`, comme le
--      reste du freemium. Cap configurable côté backend (sejourfr.realtime.quota),
--      jamais en dur. Le débit a lieu à la connexion réelle (status -> ACTIVE),
--      pas à l'émission du token : un échec de connexion ne pénalise pas.
--   2. CAPTURE DU TRANSCRIPT — schéma de connexion (A) : le client parle
--      directement à Gemini (token éphémère) ; il relaie les fragments de
--      transcription que l'on accumule ici (artefact de notation, lot 2).
-- ============================================================================

CREATE TABLE realtime_sessions (
    id                 uuid NOT NULL PRIMARY KEY,
    user_id            uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- Pass couvrant au démarrage : porte le scope du quota (reset par pass).
    -- SET NULL si la souscription est purgée — la session reste un historique.
    subscription_id    uuid REFERENCES user_subscriptions(id) ON DELETE SET NULL,
    -- Rattachement optionnel : entraînement isolé (NULL) ou sous-attempt EO
    -- d'un examen complet.
    attempt_id         uuid REFERENCES attempts(id) ON DELETE SET NULL,
    -- Consigne T1/T2 jouée (rôle examinateur + situation candidat).
    production_task_id uuid REFERENCES production_tasks(id) ON DELETE SET NULL,
    epreuve            varchar(20) NOT NULL,
    tache_numero       smallint NOT NULL,
    provider           varchar(32) NOT NULL,
    model              varchar(128) NOT NULL,
    status             varchar(20) DEFAULT 'PENDING'::varchar NOT NULL,
    -- Transcript dialogué accumulé (examinateur + candidat). Source de notation.
    transcript         text DEFAULT '' NOT NULL,
    started_at         timestamptz DEFAULT now() NOT NULL,
    connected_at       timestamptz,
    ended_at           timestamptz,
    created_at         timestamptz DEFAULT now() NOT NULL,
    updated_at         timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT chk_rt_session_epreuve CHECK (((epreuve)::text = 'TCF_EO'::text)),
    CONSTRAINT chk_rt_session_tache CHECK ((tache_numero = ANY (ARRAY[1, 2]))),
    CONSTRAINT chk_rt_session_status CHECK (((status)::text = ANY ((ARRAY['PENDING','ACTIVE','COMPLETED','FAILED'])::text[])))
);

-- Historique utilisateur (timeline descendante).
CREATE INDEX idx_rt_session_user ON realtime_sessions (user_id, started_at DESC);
-- Décompte de quota par pass : COUNT scopé (subscription_id, status).
CREATE INDEX idx_rt_session_quota ON realtime_sessions (subscription_id, status);
-- Sessions d'un attempt (assemblage examen / reprise).
CREATE INDEX idx_rt_session_attempt ON realtime_sessions (attempt_id);

COMMENT ON TABLE realtime_sessions IS 'Sessions EO temps réel (examinateur IA, T1/T2). Ledger de quota par pass + capture du transcript dialogué pour la notation.';
COMMENT ON COLUMN realtime_sessions.subscription_id IS 'Pass couvrant au démarrage : scope du quota (reset par pass).';
COMMENT ON COLUMN realtime_sessions.connected_at IS 'Première activité reçue = connexion établie = débit du quota.';
COMMENT ON COLUMN realtime_sessions.transcript IS 'Dialogue accumulé (examinateur + candidat), artefact de notation (lot 2).';
