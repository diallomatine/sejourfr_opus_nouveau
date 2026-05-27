-- ============================================================================
-- V107 : Situations + supports + exemples pour l'entrainement EO/EE
-- ============================================================================
-- Le module Expression (EO/EE) passe d'une simple consigne par tache a un
-- entrainement guide : chaque `production_task` (cf. V96) porte desormais N
-- `production_situations` (scenarios concrets). Pour l'EO tache 2/3, plusieurs
-- situations = les "5 sujets" parmi lesquels l'examinateur choisit. Chaque
-- situation peut avoir des supports visuels et des reponses modeles.
--
-- On NE cree PAS de table production_attempts : la production utilisateur + sa
-- correction IA vivent deja dans production_submissions / transcriptions /
-- ai_evaluations (V96). On rattache simplement une submission a la situation
-- jouee via une nouvelle colonne nullable.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. production_situations : scenarios concrets rattaches a une tache
-- ---------------------------------------------------------------------------
CREATE TABLE production_situations (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id            UUID NOT NULL REFERENCES production_tasks(id) ON DELETE CASCADE,
    titre              VARCHAR(150) NOT NULL,
    contexte           TEXT NOT NULL,
    consigne           TEXT,
    role_candidat      TEXT,
    role_examinateur   TEXT,
    objectif           TEXT,
    declencheur        JSONB,
    etapes             JSONB,
    niveau_indicatif   VARCHAR(2),
    display_order      INTEGER NOT NULL DEFAULT 0,
    is_active          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_prod_situation_niveau
        CHECK (niveau_indicatif IS NULL OR niveau_indicatif IN ('A2', 'B1', 'B2'))
);

CREATE INDEX idx_prod_situations_task ON production_situations(task_id, display_order);
CREATE INDEX idx_prod_situations_active ON production_situations(is_active);

COMMENT ON TABLE production_situations IS
    'Scenarios concrets rattaches a une production_task. Pour EO tache 2/3, plusieurs situations = les "5 sujets" de l''examen reel.';
COMMENT ON COLUMN production_situations.declencheur IS
    'EE : message declencheur affiche avant la redaction. Forme {expediteur, avatar, texte}.';
COMMENT ON COLUMN production_situations.etapes IS
    'Plan d''aide : tableau [{icon, titre, aide}] affiche en help-items.';
COMMENT ON COLUMN production_situations.niveau_indicatif IS
    'Indicatif interne pour trier la difficulte. PAS un filtre bloquant cote apprenant (l''examen TCF reel n''etiquette pas les sujets par niveau).';

-- ---------------------------------------------------------------------------
-- 2. production_situation_medias : supports visuels (EO tache 2 surtout)
-- ---------------------------------------------------------------------------
-- Flexibilite : image hebergee (R2) OU SVG inline. Une situation peut avoir
-- plusieurs supports (ex. 3 photos de logements facon sujet officiel).
-- ---------------------------------------------------------------------------
CREATE TABLE production_situation_medias (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    situation_id   UUID NOT NULL REFERENCES production_situations(id) ON DELETE CASCADE,
    type           VARCHAR(10) NOT NULL,
    image_url      TEXT,
    inline_svg     TEXT,
    legende        TEXT,
    alt_text       TEXT NOT NULL,
    display_order  INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT chk_prod_media_type
        CHECK (type IN ('IMAGE', 'SVG')),
    CONSTRAINT chk_prod_media_source
        CHECK (
            (type = 'IMAGE' AND image_url IS NOT NULL)
         OR (type = 'SVG' AND inline_svg IS NOT NULL)
        )
);

CREATE INDEX idx_prod_sit_medias_situation ON production_situation_medias(situation_id, display_order);

COMMENT ON TABLE production_situation_medias IS
    'Supports visuels d''une situation (photos de logements, etc.). type=IMAGE -> image_url (R2), type=SVG -> inline_svg.';

-- ---------------------------------------------------------------------------
-- 3. production_examples : reponses modeles d'une situation
-- ---------------------------------------------------------------------------
CREATE TABLE production_examples (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    situation_id       UUID NOT NULL REFERENCES production_situations(id) ON DELETE CASCADE,
    titre              VARCHAR(150) NOT NULL,
    resume             VARCHAR(255),
    contenu            TEXT NOT NULL,
    audio_url          TEXT,
    plan_points        JSONB,
    niveau_indicatif   VARCHAR(2),
    display_order      INTEGER NOT NULL DEFAULT 0,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_prod_example_niveau
        CHECK (niveau_indicatif IS NULL OR niveau_indicatif IN ('A2', 'B1', 'B2'))
);

CREATE INDEX idx_prod_examples_situation ON production_examples(situation_id, display_order);

COMMENT ON TABLE production_examples IS
    'Reponses modeles d''une situation. audio_url renseigne pour l''EO (genere via le pipeline audio), NULL pour l''EE.';
COMMENT ON COLUMN production_examples.plan_points IS
    'Plan rapide : tableau de chaines affichees en check-list (["Bonjour + prenom", "Ville", ...]).';

-- ---------------------------------------------------------------------------
-- 4. production_submissions.situation_id : tracer la situation jouee
-- ---------------------------------------------------------------------------
-- NULL = entrainement libre directement sur la tache (sans situation choisie),
-- ou submission anterieure a cette migration.
-- ---------------------------------------------------------------------------
ALTER TABLE production_submissions
    ADD COLUMN situation_id UUID REFERENCES production_situations(id) ON DELETE SET NULL;

CREATE INDEX idx_prod_sub_situation ON production_submissions(situation_id)
    WHERE situation_id IS NOT NULL;

COMMENT ON COLUMN production_submissions.situation_id IS
    'Situation d''entrainement jouee (NULL si entrainement libre sur la tache ou submission pre-V107).';
