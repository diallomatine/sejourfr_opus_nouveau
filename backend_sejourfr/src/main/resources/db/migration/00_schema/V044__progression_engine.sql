-- ============================================================================
-- V044 — MOTEUR DE PROGRESSION V4.2 : le registre des preuves et ses agregats.
-- ----------------------------------------------------------------------------
-- Spec : docs/plan/SEJOURFR_PROGRESSION_ENGINE_V4_2.md — regles :
-- docs/regles/progression.md.
--
-- CE QUE CE SCHEMA POSE, ET POURQUOI IL EST FAIT COMME CA.
--
-- 1. `learning_evidence` est un REGISTRE IMMUABLE. On n'y corrige jamais une
--    ligne : une evaluation invalidee produit un evenement d'invalidation et
--    une NOUVELLE preuve (§43). C'est ce qui rend le replay possible — et le
--    replay est la seule facon honnete de changer un seuil (§29).
--
-- 2. Les accumulateurs sont en DOUBLE PRECISION, jamais en NUMERIC(p,s). Ce
--    n'est pas une preference de style. Le poids stocke vaut
--    `baseW * exp(lambda * joursDepuisEpoch)` avec lambda = ln(2)/45 : il
--    croit exponentiellement par construction.
--        J+365  ~ 2.8e2      J+1000 ~ 1.1e5
--        J+2000 ~ 1.2e10     J+3650 ~ 2.6e24
--    Un decimal a precision fixe deborde donc en quelques annees, EN SILENCE,
--    sur une donnee materialisee que rien ne recalcule dans le chemin nominal
--    (§27.2.1, invariant I40). Cote Java : `double`, jamais `BigDecimal`.
--    Le garde-fou complementaire est le re-basage de l'epoch tous les
--    `maxEpochAgeDays` = 1095 jours (§27.2.2).
--
-- 3. `progression_state` est une PROJECTION, pas une verite. Elle est
--    entierement reconstructible depuis `learning_evidence`, et elle porte
--    `engine_version` : deux versions du moteur coexistent le temps d'un replay
--    compare (§29), puis on bascule le flag.
--
-- 4. Ce que ce schema ne contient PAS, volontairement :
--      * aucune colonne `prerequisite_satisfied`. C'est un DERIVE revocable
--        (§18.4, invariant I21) : le persister, c'est promettre a un candidat
--        un acquis qu'on devra lui retirer. Il se recalcule a la lecture.
--      * aucune preuve synthetique de niveau inferieur (§5, invariant I4).
--      * aucun `last_aggregated_at` servant a appliquer un decay a l'ecriture :
--        c'est exactement ce que §10 interdit.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- learning_evidence — ce que le candidat a REELLEMENT fait.
-- ----------------------------------------------------------------------------
CREATE TABLE learning_evidence
(
    id                         uuid PRIMARY KEY,
    user_id                    uuid             NOT NULL
        REFERENCES users (id) ON DELETE CASCADE,

    -- La tentative d'ou sort la preuve. Pas de FK : une preuve survit a la
    -- purge d'une tentative invitee, et le registre doit rester rejouable.
    attempt_id                 uuid             NOT NULL,

    -- occurred_at = heure PEDAGOGIQUE de fin d'activite.
    -- ingested_at = heure d'arrivee serveur.
    -- Une preuve hors-ligne arrivee trois jours plus tard garde son
    -- occurred_at : c'est lui, et lui seul, qui entre dans le poids (§5).
    occurred_at                timestamptz      NOT NULL,
    ingested_at                timestamptz      NOT NULL DEFAULT now(),

    -- D'ou l'utilisateur est parti. TRACE PRODUIT, aucun calcul : une activite
    -- lancee depuis « Reviser » vaut autant que depuis le Plan (§1, T24).
    entry_point                varchar(24)      NOT NULL,
    -- Ce qu'il a reellement fait. C'est CA qui porte le poids pedagogique.
    source_type                varchar(32)      NOT NULL,

    section                    varchar(2)       NOT NULL,
    level                      varchar(2),
    skill_id                   varchar(64),

    result                     double precision NOT NULL,
    scoring_confidence         double precision NOT NULL,
    assistance_level           varchar(40)      NOT NULL,

    -- Identite du contenu traite. Pour une serie : sha256 des questionIds
    -- TRIES — deux series des memes questions dans un autre ordre ont donc le
    -- meme content_id (§12 bis.1).
    content_id                 varchar(128)     NOT NULL,
    blueprint_id               varchar(64),
    calibration_status         varchar(16)      NOT NULL,
    -- TOUJOURS calcule serveur, jamais fourni par le client (invariant I38).
    independence_class         varchar(32)      NOT NULL,

    engine_version_at_creation integer          NOT NULL,
    metadata                   jsonb            NOT NULL DEFAULT '{}'::jsonb,

    -- La cle naturelle d'idempotence (§42) : un retry reseau ne double jamais
    -- la progression. C'est l'unicite EN BASE qui fait foi, pas un controle
    -- applicatif — celui-la perd toujours la course.
    natural_key                varchar(320)     NOT NULL,

    CONSTRAINT learning_evidence_natural_key_unique UNIQUE (user_id, natural_key),
    CONSTRAINT learning_evidence_result_borne CHECK (result >= 0 AND result <= 1),
    CONSTRAINT learning_evidence_confiance_borne
        CHECK (scoring_confidence >= 0 AND scoring_confidence <= 1),
    -- Un palier receptif porte un niveau et pas de competence ; une competence
    -- productive l'inverse. Un enregistrement a cheval ne veut rien dire.
    CONSTRAINT learning_evidence_cle_coherente CHECK (
        (level IS NOT NULL AND skill_id IS NULL AND section IN ('CO', 'CE'))
        OR (skill_id IS NOT NULL AND level IS NULL AND section IN ('EE', 'EO'))
    )
);

-- La lecture nominale : toutes les preuves d'un candidat sur un domaine, dans
-- l'ordre pedagogique.
CREATE INDEX idx_learning_evidence_user_section
    ON learning_evidence (user_id, section, level, occurred_at);
CREATE INDEX idx_learning_evidence_user_skill
    ON learning_evidence (user_id, skill_id, occurred_at)
    WHERE skill_id IS NOT NULL;
-- Le calcul du recouvrement (§12 bis.2) cherche les series recentes du meme
-- couple user + domaine + niveau.
CREATE INDEX idx_learning_evidence_content
    ON learning_evidence (user_id, section, level, content_id);

COMMENT ON TABLE learning_evidence IS
    'Registre immuable des observations reellement produites par le candidat '
    '(V4.2 §5). Aucune preuve synthetique : l''inference de prerequis passe par '
    'prerequisiteSatisfied, derive a la lecture.';

-- ----------------------------------------------------------------------------
-- learning_evidence_invalidation — §43.
-- On ne modifie JAMAIS une preuve en place. Une reevaluation IA invalidee
-- laisse sa ligne d'origine intacte et pose ici la trace de sa revocation ;
-- l'agregat du stateKey concerne est rejoue.
-- ----------------------------------------------------------------------------
CREATE TABLE learning_evidence_invalidation
(
    id           uuid PRIMARY KEY,
    evidence_id  uuid        NOT NULL
        REFERENCES learning_evidence (id) ON DELETE CASCADE,
    reason       varchar(64) NOT NULL,
    invalidated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT learning_evidence_invalidation_unique UNIQUE (evidence_id)
);

-- ----------------------------------------------------------------------------
-- progression_state — la projection materialisee, une ligne par
-- user + state_key + engine_version.
-- ----------------------------------------------------------------------------
CREATE TABLE progression_state
(
    id                         uuid PRIMARY KEY,
    user_id                    uuid             NOT NULL
        REFERENCES users (id) ON DELETE CASCADE,
    state_key                  varchar(80)      NOT NULL,
    state_type                 varchar(20)      NOT NULL,
    engine_version             integer          NOT NULL,

    -- INTERNES AU MOTEUR. Ces deux-la ne sortent jamais vers un front
    -- (§25 bis.2) : la console admin et le journal de predictions, rien
    -- d'autre. mastery_score est NULL quand rien n'a ete mesure — NULL veut
    -- dire inconnu, jamais mauvais.
    mastery_score              double precision,
    confidence                 double precision NOT NULL DEFAULT 0,

    status                     varchar(24)      NOT NULL,

    -- §27.2.1 : double precision obligatoire, cf. l'en-tete de ce fichier.
    sum_weight_epoch           double precision NOT NULL DEFAULT 0,
    sum_weighted_result_epoch  double precision NOT NULL DEFAULT 0,
    micro_sum_weight_epoch     double precision NOT NULL DEFAULT 0,
    non_micro_sum_weight_epoch double precision NOT NULL DEFAULT 0,

    qualifying_evidence_count  integer          NOT NULL DEFAULT 0,
    recent_strong_negative_count integer        NOT NULL DEFAULT 0,
    qualification_gate         boolean          NOT NULL DEFAULT false,
    transfer_gate              boolean          NOT NULL DEFAULT false,
    direct_qualification       boolean          NOT NULL DEFAULT false,

    -- NULL = jamais mesure directement, et le front n'affiche alors AUCUN
    -- pourcentage (§18.6, invariant I41). Surtout pas 0 : le candidat n'a pas
    -- regresse, il n'a jamais ete mesure. C'est la meme confusion qui avait
    -- produit les faux A1_NON_ATTEINT de V040-V042.
    visible_progress           integer,
    practice_points            double precision NOT NULL DEFAULT 0,
    level_cycle_id             varchar(96)      NOT NULL,

    last_evidence_at           timestamptz,
    updated_at                 timestamptz      NOT NULL DEFAULT now(),

    CONSTRAINT progression_state_unique UNIQUE (user_id, state_key, engine_version),
    CONSTRAINT progression_state_visible_borne
        CHECK (visible_progress IS NULL OR (visible_progress >= 0 AND visible_progress <= 100)),
    CONSTRAINT progression_state_mastery_borne
        CHECK (mastery_score IS NULL OR (mastery_score >= 0 AND mastery_score <= 1))
);

CREATE INDEX idx_progression_state_user
    ON progression_state (user_id, engine_version);

COMMENT ON COLUMN progression_state.visible_progress IS
    'NULL = aucune preuve directe, jamais 0 (§18.6). Le front n''affiche alors '
    'que l''etat textuel.';

-- ----------------------------------------------------------------------------
-- progression_state_family_aggregate — §27.3.
-- Suit separement la masse MICRO et NON_MICRO, pour le seul cap existant :
-- celui des micro-sujets en production (§11.1). 50 micro-sujets ne peuvent
-- jamais, a eux seuls, fournir toute la confiance necessaire a SOLID.
-- ----------------------------------------------------------------------------
CREATE TABLE progression_state_family_aggregate
(
    id                        uuid PRIMARY KEY,
    user_id                   uuid             NOT NULL
        REFERENCES users (id) ON DELETE CASCADE,
    state_key                 varchar(80)      NOT NULL,
    source_family             varchar(16)      NOT NULL,
    engine_version            integer          NOT NULL,
    sum_weight_epoch          double precision NOT NULL DEFAULT 0,
    sum_weighted_result_epoch double precision NOT NULL DEFAULT 0,
    updated_at                timestamptz      NOT NULL DEFAULT now(),

    CONSTRAINT progression_family_unique
        UNIQUE (user_id, state_key, source_family, engine_version)
);

-- ----------------------------------------------------------------------------
-- progression_prediction_log — §47.
-- Le shadow mode ecrit ici ce que le moteur AURAIT dit, au moment ou il le dit,
-- puis on regarde ce qui s'est reellement passe ensuite.
--
-- Les valeurs sont FIGEES a predicted_at (invariant I35). Une prediction qu'on
-- recalculerait a posteriori ne mesurerait plus rien : elle aurait toujours
-- raison.
-- ----------------------------------------------------------------------------
CREATE TABLE progression_prediction_log
(
    id                    uuid PRIMARY KEY,
    user_id               uuid             NOT NULL
        REFERENCES users (id) ON DELETE CASCADE,
    state_key             varchar(80)      NOT NULL,
    state_type            varchar(20)      NOT NULL,
    engine_version        integer          NOT NULL,
    predicted_at          timestamptz      NOT NULL,
    level_cycle_id        varchar(96),

    mastery_score         double precision,
    confidence            double precision NOT NULL,
    status                varchar(24)      NOT NULL,
    ready_for_mock        boolean          NOT NULL DEFAULT false,
    direct_qualification  boolean          NOT NULL DEFAULT false,
    prerequisite_satisfied boolean         NOT NULL DEFAULT false,
    prediction_reason     varchar(48)      NOT NULL,

    -- Rattaches plus tard, quand un examen qualifiant du meme state_key
    -- survient dans les 30 jours (§47.3).
    outcome_attempt_id    uuid,
    outcome_result        double precision,
    outcome_at            timestamptz,

    created_at            timestamptz      NOT NULL DEFAULT now(),
    updated_at            timestamptz      NOT NULL DEFAULT now()
);

-- La metrique primaire (§47.4) lit les predictions SOLID d'un cycle en attente
-- de resultat.
CREATE INDEX idx_progression_prediction_pending
    ON progression_prediction_log (user_id, state_key, predicted_at)
    WHERE outcome_at IS NULL;
CREATE INDEX idx_progression_prediction_status
    ON progression_prediction_log (status, engine_version, predicted_at);

COMMENT ON TABLE progression_prediction_log IS
    'Journal shadow (§47). Les valeurs sont figees a predicted_at : une '
    'prediction recalculee aurait toujours raison et ne mesurerait rien.';

-- ----------------------------------------------------------------------------
-- progression_content_signal — §12 bis.5.
-- Quand la banque d'un couple domaine+niveau est trop petite pour produire une
-- seconde serie sous le seuil de recouvrement, le moteur NE S'ASSOUPLIT PAS :
-- il le dit ici, et la production de contenu se priorise dessus.
-- ----------------------------------------------------------------------------
CREATE TABLE progression_content_signal
(
    id          uuid PRIMARY KEY,
    user_id     uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    signal      varchar(32) NOT NULL,
    section     varchar(2)  NOT NULL,
    level       varchar(2)  NOT NULL,
    detail      varchar(255),
    occurred_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_progression_content_signal_scope
    ON progression_content_signal (signal, section, level, occurred_at);
