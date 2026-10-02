-- ============================================================================
-- V083 — Accès admin : décisions GRANT / REVOKE et journal des opérations
-- ----------------------------------------------------------------------------
-- Chantier « Admin / Gestion des utilisateurs » (spec V2 + GO du 2026-10-02,
-- décisions : docs/admin/decisions-gestion-utilisateurs.md).
--
-- 🛑 Strictement ADDITIF : aucune table existante n'est modifiée, aucune
-- donnée n'est écrite. `user_subscriptions` (les ACHATS) reste intacte : une
-- décision admin vit ICI, à part, et l'accès effectif se CALCULE à la lecture
-- (SubscriptionService → AccesEffectifResolver), il n'est jamais stocké.
--
-- Invariant du GO §18 : les fenêtres [starts_at, ends_at) des overrides
-- COURANTS (superseded_at IS NULL) d'un même (user_id, product) ne se
-- chevauchent jamais. Tenu par une contrainte d'EXCLUSION (btree_gist), pas
-- par du Java : deux admins concurrents ne peuvent pas la contourner.
-- btree_gist est une extension contrib standard (« trusted » depuis PG 13 :
-- le propriétaire de la base peut la créer sans superutilisateur).
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- ----------------------------------------------------------------------------
-- Le journal : UNE ligne par action admin (une correction de produit = une
-- ligne, plusieurs overrides). Son id EST l'operation_id.
-- before_state / after_state : photo de l'accès par produit À L'INSTANT de
-- l'action, pour l'affichage de l'historique seulement — jamais relue pour
-- calculer un accès.
-- ----------------------------------------------------------------------------
CREATE TABLE admin_access_operations (
    id             UUID          PRIMARY KEY,
    user_id        UUID          NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    admin_user_id  UUID          NOT NULL REFERENCES users (id),
    operation      VARCHAR(24)   NOT NULL
        CONSTRAINT ck_admin_access_operations_operation
            CHECK (operation IN ('GRANT', 'EXTEND', 'SHORTEN', 'END', 'REACTIVATE', 'CORRECT_PRODUCT')),
    product        VARCHAR(16)   NOT NULL
        CONSTRAINT ck_admin_access_operations_product
            CHECK (product IN ('CIVIQUE', 'INTEGRAL')),
    from_product   VARCHAR(16)   NULL
        CONSTRAINT ck_admin_access_operations_from_product
            CHECK (from_product IS NULL OR from_product IN ('CIVIQUE', 'INTEGRAL')),
    starts_at      TIMESTAMPTZ   NULL,
    ends_at        TIMESTAMPTZ   NULL,
    reason         VARCHAR(500)  NOT NULL
        CONSTRAINT ck_admin_access_operations_reason
            CHECK (char_length(btrim(reason)) BETWEEN 3 AND 500),
    before_state   JSONB         NOT NULL,
    after_state    JSONB         NOT NULL,
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT ck_admin_access_operations_correction
        CHECK ((operation = 'CORRECT_PRODUCT') = (from_product IS NOT NULL)),
    CONSTRAINT ck_admin_access_operations_produits_distincts
        CHECK (from_product IS NULL OR from_product <> product)
);

CREATE INDEX idx_admin_access_operations_user
    ON admin_access_operations (user_id, created_at DESC);

COMMENT ON TABLE admin_access_operations IS
    'Journal des actions admin sur les accès (qui, quand, avant/après, motif). Une ligne = un operation_id.';

-- ----------------------------------------------------------------------------
-- Les décisions. Jamais supprimées (hors purge de compte), toujours remplacées :
-- une décision qui en recouvre une autre la SUPERSEDE et, si une partie de
-- l'ancienne reste hors de sa fenêtre, la RÉINSÈRE tronquée (même
-- operation_id que la nouvelle décision, replaces_override_id = l'ancienne,
-- decided_at = celui de l'ancienne).
--
-- decided_at = l'instant de la DÉCISION d'origine. C'est lui, et non
-- created_at, que lit la règle « un achat postérieur au REVOKE rouvre l'accès »
-- (spec §2.3) : une copie tronquée ne doit pas rendre « antérieur » un rachat
-- légitime fait entre la décision et sa troncature.
-- ----------------------------------------------------------------------------
CREATE TABLE access_overrides (
    id                          UUID          PRIMARY KEY,
    user_id                     UUID          NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    product                     VARCHAR(16)   NOT NULL
        CONSTRAINT ck_access_overrides_product
            CHECK (product IN ('CIVIQUE', 'INTEGRAL')),
    type                        VARCHAR(8)    NOT NULL
        CONSTRAINT ck_access_overrides_type
            CHECK (type IN ('GRANT', 'REVOKE')),
    starts_at                   TIMESTAMPTZ   NOT NULL,
    ends_at                     TIMESTAMPTZ   NULL,
    decided_at                  TIMESTAMPTZ   NOT NULL,
    reason                      VARCHAR(500)  NOT NULL
        CONSTRAINT ck_access_overrides_reason
            CHECK (char_length(btrim(reason)) BETWEEN 3 AND 500),
    created_by                  UUID          NOT NULL REFERENCES users (id),
    created_at                  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    operation_id                UUID          NOT NULL REFERENCES admin_access_operations (id),
    replaces_override_id        UUID          NULL REFERENCES access_overrides (id),
    superseded_at               TIMESTAMPTZ   NULL,
    superseded_by_operation_id  UUID          NULL REFERENCES admin_access_operations (id),
    CONSTRAINT ck_access_overrides_grant_borne
        CHECK (type <> 'GRANT' OR ends_at IS NOT NULL),
    CONSTRAINT ck_access_overrides_fenetre
        CHECK (ends_at IS NULL OR ends_at > starts_at),
    CONSTRAINT ck_access_overrides_supersession
        CHECK ((superseded_at IS NULL) = (superseded_by_operation_id IS NULL)),
    CONSTRAINT excl_access_overrides_courants_sans_chevauchement
        EXCLUDE USING gist (
            user_id WITH =,
            product WITH =,
            tstzrange(starts_at, ends_at, '[)') WITH &&
        ) WHERE (superseded_at IS NULL)
);

CREATE INDEX idx_access_overrides_user_courants
    ON access_overrides (user_id) WHERE superseded_at IS NULL;

CREATE INDEX idx_access_overrides_operation
    ON access_overrides (operation_id);

COMMENT ON TABLE access_overrides IS
    'Décisions admin GRANT/REVOKE par (compte, produit) sur une fenêtre [starts_at, ends_at). Les achats restent dans user_subscriptions.';
COMMENT ON COLUMN access_overrides.decided_at IS
    'Instant de la décision d''origine (copié sur une copie tronquée) : un achat postérieur rouvre un REVOKE.';
