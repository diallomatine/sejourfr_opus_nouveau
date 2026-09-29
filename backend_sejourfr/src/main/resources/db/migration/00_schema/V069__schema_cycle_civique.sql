-- ============================================================================
-- V069 — LE CYCLE ACCUEILLE LE MODULE CIVIQUE : son objectif, ses blocs, ses
--        unites travaillables
-- ============================================================================
-- Arbitrages : docs/decisions/plan-parcours-tcf.md D-26, D-32, D-41, D-47, D-48
-- (2026-09-19). Cadre fonctionnel : docs/progression/civique/SPEC_cycle_plan_civique.md.
-- Source de droit du referentiel : arrete du 10 octobre 2025 (JORF n° 0240 du
-- 12 octobre 2025, NOR INTV2527907A), annexe I.
--
-- V067 a ouvert le cycle au module civique par sa colonne `module` et ses index
-- partiels. Il lui manquait trois choses que rien ne permet de deduire :
--   1. L'OBJECTIF d'un cycle civique est une MENTION, pas un palier CECRL.
--   2. Le BLOC d'un cycle civique est une THEMATIQUE, pas une epreuve.
--   3. L'UNITE TRAVAILLABLE est une UNITE OFFICIELLE (V068), pas un `Skill`.
--
-- ----------------------------------------------------------------------------
-- 🛑 DES COLONNES PARALLELES ET UN CHECK D'EXCLUSIVITE, ET C'EST FORCE
-- ----------------------------------------------------------------------------
-- `journey_lot` et `journey_step` n'ont PAS de colonne `module` : il est sur
-- `journey`. Un CHECK ne peut pas traverser vers la table parente, et un trigger
-- serait disproportionne. La forme `(A IS NOT NULL) <> (B IS NOT NULL)` est donc
-- la SEULE qui tienne en base.
--
-- ⚠️ Une colonne polymorphe generique (`bloc_ref` + discriminant) aurait en plus
-- perdu les FK REELLES qu'on vient de gagner en P8.2a. Une FK vers `themes(id)`
-- et une vers `civic_official_units(id)` valent mieux qu'un uuid nu.
--
-- ----------------------------------------------------------------------------
-- 🛑 CE QUI N'EST PAS ICI, ET QUI EST REPORTE -- PAS OUBLIE
-- ----------------------------------------------------------------------------
-- **S-8** de l'audit (`learning_plan_observations` : `skill_id` NOT NULL FK vers
-- `skills`, et `chk_learning_plan_observation_source` sans aucune valeur
-- civique) est REPORTE EN P8.4, dans sa propre migration.
--
-- Motif, et il est de fond : ajouter `official_unit_id` a cette table
-- maintenant, ce serait PRE-DECIDER E-2 sous couvert de preparer le terrain.
-- E-2 est la question « qui fait foi quand l'observation civique et
-- `CivicLeitnerResolver` divergent sur "cette notion est-elle acquise ?" »,
-- arbitree par le proprietaire AVANT tout code. Si l'arbitrage conclut que le
-- Leitner reste seule autorite, cette colonne serait MORTE dans une migration
-- livree -- donc definitive.
--
-- 🛑 S-8 n'est donc pas un manque de V069 : c'est un point d'arret assume.
-- Ne pas le rouvrir comme une omission.
--
-- ⚠️ Et deux contraintes de l'audit ne sont PLUS concernees du tout :
--   * S-6 (`chk_skills_section`) : l'unite ne passe pas par `skills` (D-32 Q-F7) ;
--   * S-9 (`chk_free_entitlement_code`) : pas de ledger civique (D-33).
--
-- AUCUNE MIGRATION DE DONNEES : creation paresseuse, et les lignes deja creees
-- restent valides -- elles sont toutes TCF, avec `target_level` pose.
-- ============================================================================

-- ============================================================================
-- 1. `journey` — l'objectif d'un cycle civique est une MENTION
-- ============================================================================

ALTER TABLE journey
    ADD COLUMN target_procedure varchar(16),
    ADD COLUMN entry_score      smallint,
    ADD COLUMN exit_score       smallint;

-- `target_level` cesse d'etre obligatoire : un cycle civique n'a pas de palier.
ALTER TABLE journey ALTER COLUMN target_level DROP NOT NULL;

ALTER TABLE journey
    ADD CONSTRAINT chk_journey_target_procedure CHECK (
        target_procedure IS NULL
        OR target_procedure IN ('CSP', 'CR', 'NAT')
    ),
    -- 🛑 UN cycle, UN objectif, du type de son module. Ni les deux, ni aucun :
    -- « pas de parcours sans niveau cible » (D-3) vaut pour les deux modules.
    ADD CONSTRAINT chk_journey_objectif CHECK (
        (target_level IS NOT NULL) <> (target_procedure IS NOT NULL)
    ),
    -- 🛑 AUCUN PLAFOND EN BASE, ET C'EST VOULU. Le maximum d'un score civique
    -- est le format de l'epreuve -- 40 questions -- et ce nombre vit dans
    -- `CivicExamFormat.QUESTIONS`, son autorite unique. Un `BETWEEN 0 AND 40`
    -- ici en ferait une 2e copie : un changement de l'arrete demanderait alors
    -- une MIGRATION la ou il doit demander une ligne de code. Le plafond est
    -- verifie par un TEST NORMATIF, qui le lit chez `CivicExamFormat` et jamais
    -- en litteral. Meme raisonnement que la somme des quotas en D-38.
    ADD CONSTRAINT chk_journey_entry_score CHECK (entry_score IS NULL OR entry_score >= 0),
    ADD CONSTRAINT chk_journey_exit_score  CHECK (exit_score  IS NULL OR exit_score  >= 0);

COMMENT ON COLUMN journey.target_procedure IS
    'L''objectif d''un cycle CIVIQUE : la demarche visee (CSP / CR / NAT). '
    '🛑 C''est un OBJECTIF, jamais un pool de questions -- l''arrete du '
    '10 octobre 2025 pose UN programme pour toutes les mentions (D-27, D-42).';
COMMENT ON COLUMN journey.entry_score IS
    'Score civique a l''entree du cycle, sur le format de l''epreuve. Colonne '
    'NEUVE : un score n''est pas un niveau, et `entry_level` reste CECRL (D-32). '
    'Plafond verifie par test normatif contre CivicExamFormat.QUESTIONS.';
COMMENT ON COLUMN journey.exit_score IS
    'Score civique persiste a l''historisation du cycle (D-12 transpose). Meme '
    'regle de plafond qu''`entry_score`.';

-- ============================================================================
-- 2. `journey_lot` — le bloc est une EPREUVE ou une THEMATIQUE
-- ============================================================================

ALTER TABLE journey_lot
    ADD COLUMN theme_id uuid REFERENCES themes (id);

ALTER TABLE journey_lot ALTER COLUMN exam_type DROP NOT NULL;

ALTER TABLE journey_lot
    -- 🛑 EXACTEMENT UN AXE. Le CHECK a 4 valeurs TCF de `exam_type` est conserve
    -- tel quel : ce qui change est qu'il peut etre NULL, pas ses valeurs.
    ADD CONSTRAINT chk_journey_lot_bloc CHECK (
        (exam_type IS NOT NULL) <> (theme_id IS NOT NULL)
    );

-- Jumeau de `uq_journey_lot_open_par_epreuve`, meme patron d'index partiel :
-- un seul lot OUVERT par thematique et par cycle.
CREATE UNIQUE INDEX uq_journey_lot_open_par_theme
    ON journey_lot (journey_id, theme_id)
    WHERE status = 'OPEN' AND theme_id IS NOT NULL;

COMMENT ON COLUMN journey_lot.theme_id IS
    'La thematique du bloc, pour un cycle CIVIQUE -- l''equivalent de '
    '`exam_type` cote TCF. FK reelle vers `themes` : un bloc range sous une '
    'thematique inexistante serait une trace fausse (D-32 Q-F6).';

-- ============================================================================
-- 3. `journey_step` — deux axes de bloc, et DEUX unites travaillables
-- ============================================================================

ALTER TABLE journey_step
    ADD COLUMN theme_id         uuid REFERENCES themes (id),
    ADD COLUMN official_unit_id uuid REFERENCES civic_official_units (id);

ALTER TABLE journey_step
    ADD CONSTRAINT chk_journey_step_bloc CHECK (
        -- Une etape DIAGNOSTIC n'appartient a aucun bloc (A45) : les deux nuls.
        -- Partout ailleurs, exactement un axe.
        (exam_type IS NULL AND theme_id IS NULL)
        OR ((exam_type IS NOT NULL) <> (theme_id IS NOT NULL))
    );

-- 🛑 Les trois CHECK de FORME sont reecrits : ils nommaient `skill_id` et
-- `exam_type` en dur, donc ils interdisaient le civique par construction.
ALTER TABLE journey_step DROP CONSTRAINT chk_journey_step_diagnostic;
ALTER TABLE journey_step DROP CONSTRAINT chk_journey_step_section_exam;
ALTER TABLE journey_step DROP CONSTRAINT chk_journey_step_train_skill;

ALTER TABLE journey_step
    -- Une etape DIAGNOSTIC mesure le CANDIDAT, pas une epreuve ni une
    -- thematique (R11, A45) : aucun bloc, aucune unite, aucun purpose.
    ADD CONSTRAINT chk_journey_step_diagnostic CHECK (
        type <> 'DIAGNOSTIC'
        OR (lot_id IS NULL AND exam_type IS NULL AND theme_id IS NULL
            AND skill_id IS NULL AND official_unit_id IS NULL AND purpose IS NULL)
    ),
    -- Un EXAMEN de bloc : aucune unite travaillable, un axe de bloc, un purpose.
    ADD CONSTRAINT chk_journey_step_section_exam CHECK (
        type <> 'SECTION_EXAM'
        OR (skill_id IS NULL AND official_unit_id IS NULL
            AND (exam_type IS NOT NULL OR theme_id IS NOT NULL)
            AND purpose IS NOT NULL)
    ),
    -- Un ENTRAINEMENT : EXACTEMENT UNE unite travaillable -- une competence TCF
    -- ou une unite officielle civique --, son lot, son axe de bloc, pas de purpose.
    ADD CONSTRAINT chk_journey_step_train_skill CHECK (
        type <> 'TRAIN_SKILL'
        OR ((skill_id IS NOT NULL) <> (official_unit_id IS NOT NULL)
            AND lot_id IS NOT NULL
            AND (exam_type IS NOT NULL OR theme_id IS NOT NULL)
            AND purpose IS NULL)
    );

-- Jumeau de `uq_journey_step_lot_skill` : une unite officielle n'apparait
-- qu'une fois par lot.
CREATE UNIQUE INDEX uq_journey_step_lot_unite
    ON journey_step (lot_id, official_unit_id)
    WHERE official_unit_id IS NOT NULL;

COMMENT ON COLUMN journey_step.theme_id IS
    'La thematique du bloc de cette etape, pour un cycle CIVIQUE.';
COMMENT ON COLUMN journey_step.official_unit_id IS
    'L''UNITE TRAVAILLABLE d''une etape civique : une des 16 unites du programme '
    'officiel (V068). 🛑 C''est l''obligation de D-47 en base -- le bloc du cycle '
    'se rattache a l''UNITE, jamais a `questions.theme_id` (D-48, cote PROGRAMME). '
    'L''equivalent de `skill_id` cote TCF, et les deux s''excluent.';
