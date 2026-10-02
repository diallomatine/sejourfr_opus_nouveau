-- ============================================================================
-- V084 — Sessions EO temps réel offertes par un GRANT INTEGRAL admin (B-1 modifié,
-- arbitrages n°3 et n°4 du propriétaire, 2026-10-02).
-- 🛑 Strictement ADDITIF : deux colonnes à défaut constant sur access_overrides
-- (métadonnée seule depuis PG 11, aucune réécriture), une colonne nullable sur
-- realtime_sessions, des CHECK, une FK et un index. Aucun UPDATE, aucun INSERT.
-- user_subscriptions n'est pas touchée.
-- La règle de calcul (quel porteur, quel solde) vit dans RealtimeQuotaService,
-- jamais ici.
-- ============================================================================

ALTER TABLE access_overrides
    ADD COLUMN realtime_eo_sessions_granted   INT NOT NULL DEFAULT 0,
    ADD COLUMN realtime_eo_sessions_remaining INT NOT NULL DEFAULT 0,
    ADD CONSTRAINT ck_access_overrides_rt_positifs
        CHECK (realtime_eo_sessions_granted >= 0 AND realtime_eo_sessions_remaining >= 0),
    ADD CONSTRAINT ck_access_overrides_rt_solde_borne
        CHECK (realtime_eo_sessions_remaining <= realtime_eo_sessions_granted),
    -- Seul un GRANT INTEGRAL porte des sessions. CIVIQUE et REVOKE : toujours 0.
    ADD CONSTRAINT ck_access_overrides_rt_grant_integral
        CHECK (realtime_eo_sessions_granted = 0 OR (type = 'GRANT' AND product = 'INTEGRAL')),
    -- Une décision remplacée ne garde jamais de solde débitable : le solde
    -- n'existe qu'une fois, sur une ligne courante.
    ADD CONSTRAINT ck_access_overrides_rt_remplacee_vide
        CHECK (superseded_at IS NULL OR realtime_eo_sessions_remaining = 0);

COMMENT ON COLUMN access_overrides.realtime_eo_sessions_granted IS
    'Sessions EO temps réel offertes par ce GRANT INTEGRAL (allocation, sert au cap). Copié sur la lignée.';
COMMENT ON COLUMN access_overrides.realtime_eo_sessions_remaining IS
    'Solde débitable. Seule une ligne COURANTE porte un solde. Lu et débité par RealtimeQuotaService seulement.';

ALTER TABLE realtime_sessions
    ADD COLUMN access_override_id UUID NULL
        CONSTRAINT fk_rt_session_access_override
            REFERENCES access_overrides (id) ON DELETE SET NULL,
    -- Une session a au plus UN porteur : un achat OU une décision admin.
    ADD CONSTRAINT ck_rt_session_un_seul_porteur
        CHECK (subscription_id IS NULL OR access_override_id IS NULL);

CREATE INDEX idx_rt_session_access_override
    ON realtime_sessions (access_override_id) WHERE access_override_id IS NOT NULL;

COMMENT ON COLUMN realtime_sessions.access_override_id IS
    'GRANT INTEGRAL réservé au démarrage, puis réécrit au débit (PENDING -> ACTIVE) avec la ligne réellement débitée, ou NULL si aucun débit n''a pu se faire.';
