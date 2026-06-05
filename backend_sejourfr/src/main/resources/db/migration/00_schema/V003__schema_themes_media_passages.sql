-- ============================================================================
-- V003 — Schéma : thèmes, médias, passages
-- ----------------------------------------------------------------------------
-- Tables : themes, medias, passages
-- Relations : passages -> medias (AUDIO/IMAGE associé) + themes.
-- Socle de contenu : questions (V004) référence themes, passages et medias.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- themes (CIVIQUE : 5 thématiques ; TCF : CO / CE / STRUCTURE)
-- ---------------------------------------------------------------------------
CREATE TABLE themes (
    id            uuid NOT NULL PRIMARY KEY,
    module        varchar(16) NOT NULL,
    code          varchar(64) NOT NULL,
    name          varchar(200) NOT NULL,
    description   text,
    display_order integer DEFAULT 0 NOT NULL,
    CONSTRAINT uk_theme_code UNIQUE (code)
);
CREATE INDEX idx_theme_module ON themes (module);

-- ---------------------------------------------------------------------------
-- medias (AUDIO synthétisé R2, IMAGE inline SVG)
-- ---------------------------------------------------------------------------
CREATE TABLE medias (
    id                uuid NOT NULL PRIMARY KEY,
    type              varchar(16) NOT NULL,
    url               varchar(500),
    storage_key       varchar(500),
    original_filename varchar(255),
    content_type      varchar(120),
    size_bytes        bigint,
    duration_sec      integer,
    alt_text          varchar(500),
    created_at        timestamptz DEFAULT now() NOT NULL,
    transcript        text,
    inline_svg        text
);
CREATE INDEX idx_medias_has_inline_svg ON medias (((inline_svg IS NOT NULL)));

-- ---------------------------------------------------------------------------
-- passages (supports de lecture TCF CE : textes, e-mails, articles…)
-- ---------------------------------------------------------------------------
CREATE TABLE passages (
    id       uuid NOT NULL PRIMARY KEY,
    type     varchar(16) NOT NULL,
    content  text,
    media_id uuid REFERENCES medias(id),
    theme_id uuid REFERENCES themes(id)
);
