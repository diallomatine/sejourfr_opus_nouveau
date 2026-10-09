-- ============================================================================
-- V090 — Mesure de l'examinateur IA temps réel (chantier examinateur IA, lot M)
-- ----------------------------------------------------------------------------
-- Problème : l'audit du 2026-10-09 (docs/examinateur-ia/AUDIT_examinateur_IA.md,
-- F11/F19/F20) n'a pu mesurer la conduite qu'en MOTS : aucun horodatage par
-- tour, aucune cause de fin de session, ni la version de persona, ni la
-- plateforme, ni le repli asynchrone n'étaient tracés.
--
-- Tout est ADDITIF : le transcript texte (realtime_sessions.transcript), seule
-- source de la notation, ne change pas. Rien ici n'entre dans une note, un
-- niveau ou un quota.
--
--   * realtime_sessions : cause de fin, version de persona, plateforme, version
--     du JSON de conduite et fenêtre de silence VAD réellement verrouillée dans
--     le token. Toutes nullables : NULL = inconnu (sessions antérieures, client
--     qui ne déclare rien).
--   * realtime_session_turns : un SEGMENT relayé par le client, avec ses temps
--     de début et de fin en ms, relatifs à l'établissement de la connexion côté
--     client (setupComplete). Temps nullables : un client ancien n'en envoie pas.
--   * realtime_session_events : événements de conduite (relance sur silence,
--     grâce de fin de temps, reprise avec ou sans handle).
--   * realtime_fallbacks : chaque bascule vers l'enregistrement classique, qui
--     n'avait jusqu'ici laissé aucune trace en base.
-- ============================================================================

ALTER TABLE realtime_sessions
    ADD COLUMN end_cause              varchar(20),
    ADD COLUMN persona_version        varchar(16),
    ADD COLUMN client_platform        varchar(16),
    ADD COLUMN conduct_config_version varchar(16),
    ADD COLUMN vad_silence_ms         integer,
    ADD CONSTRAINT chk_rt_session_end_cause
        CHECK (end_cause IS NULL OR end_cause IN ('TIME_UP', 'USER_FINISH', 'CONNECTION_LOST', 'ERROR'));

COMMENT ON COLUMN realtime_sessions.end_cause IS
    'Qui a clos la session : TIME_UP, USER_FINISH, CONNECTION_LOST, ERROR. NULL = client qui ne le déclare pas, ou session jamais close.';
COMMENT ON COLUMN realtime_sessions.persona_version IS
    'Version de persona (prompts/realtime-personas-<v>.json) verrouillée dans le token.';
COMMENT ON COLUMN realtime_sessions.client_platform IS
    'Plateforme déclarée par X-Sejourfr-Client à l''ouverture (WEB, IOS, ANDROID, MOBILE, UNKNOWN).';
COMMENT ON COLUMN realtime_sessions.conduct_config_version IS
    'Version du JSON de conduite servi au client (prompts/realtime-conduct-<v>.json). NULL avant le lot 1.';
COMMENT ON COLUMN realtime_sessions.vad_silence_ms IS
    'silenceDurationMs effectivement verrouillé dans le token à l''ouverture.';

CREATE TABLE realtime_session_turns
(
    id            uuid        NOT NULL PRIMARY KEY,
    session_id    uuid        NOT NULL REFERENCES realtime_sessions (id) ON DELETE CASCADE,
    seq           integer     NOT NULL,
    turn_index    integer,
    speaker       varchar(16) NOT NULL,
    text          text        NOT NULL,
    word_count    integer     NOT NULL,
    started_at_ms integer,
    ended_at_ms   integer,
    created_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_rt_turn_session_seq UNIQUE (session_id, seq),
    CONSTRAINT chk_rt_turn_speaker CHECK (speaker IN ('CANDIDATE', 'EXAMINER'))
);

COMMENT ON TABLE realtime_session_turns IS
    'Segments relayés d''une session EO temps réel, horodatés côté client. Mesure seulement : la notation lit realtime_sessions.transcript.';
COMMENT ON COLUMN realtime_session_turns.started_at_ms IS
    'Début du segment en ms depuis setupComplete côté client. Examinateur : début de LECTURE audio. Candidat : premier fragment de transcription (approximation, cf. DECISIONS D-07).';

CREATE TABLE realtime_session_events
(
    id         uuid        NOT NULL PRIMARY KEY,
    session_id uuid        NOT NULL REFERENCES realtime_sessions (id) ON DELETE CASCADE,
    type       varchar(32) NOT NULL,
    at_ms      integer,
    value_ms   integer,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT chk_rt_event_type CHECK (type IN
        ('SILENCE_RELANCE', 'TIMEUP_GRACE', 'RESUME_WITH_HANDLE', 'RESUME_WITHOUT_HANDLE'))
);

CREATE INDEX idx_rt_event_session ON realtime_session_events (session_id);

COMMENT ON TABLE realtime_session_events IS
    'Événements de conduite d''une session EO temps réel. at_ms : ms depuis setupComplete (NULL pour les événements tracés par le serveur). value_ms : durée associée (grâce de fin de temps).';

CREATE TABLE realtime_fallbacks
(
    id                 uuid        NOT NULL PRIMARY KEY,
    user_id            uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    production_task_id uuid REFERENCES production_tasks (id) ON DELETE SET NULL,
    session_id         uuid REFERENCES realtime_sessions (id) ON DELETE CASCADE,
    tache_numero       smallint,
    reason             varchar(32) NOT NULL,
    created_at         timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT chk_rt_fallback_reason CHECK (reason IN
        ('QUOTA', 'NOT_CONFIGURED', 'MINT_FAILED', 'RESUME_MINT_FAILED'))
);

CREATE INDEX idx_rt_fallback_created ON realtime_fallbacks (created_at);

COMMENT ON TABLE realtime_fallbacks IS
    'Chaque bascule ASYNC_FALLBACK (le candidat demandait l''examinateur et s''enregistre seul). session_id renseigné seulement pour une reprise impossible.';
