-- ============================================================================
-- V070 — L'OBSERVATION D'APPRENTISSAGE ACCUEILLE L'UNITE OFFICIELLE CIVIQUE
-- ============================================================================
-- Arbitrage : docs/decisions/plan-parcours-tcf.md D-49 (E-2, 2026-09-19).
-- Leve S-8 de docs/audits/AUDIT_cycle_plan_civique.md, REPORTE par V069.
--
-- ----------------------------------------------------------------------------
-- 🛑 DEUX AUTORITES, DEUX QUESTIONS, ET AUCUN ARBITRAGE ENTRE ELLES
-- ----------------------------------------------------------------------------
-- L'audit designait ceci comme « le defaut le plus cher du depot » : ecrire une
-- observation civique cree une SECONDE autorite sur « cette notion est-elle
-- acquise ? », face a `CivicLeitnerResolver`. La reponse n'est pas de choisir une
-- gagnante, c'est de SEPARER LES QUESTIONS pour qu'elles ne puissent plus se
-- contredire :
--
--   * « Cette ETAPE DU CYCLE est-elle CLOTUREE ? »  -> L'OBSERVATION.
--     2 series reussies, ou 4 terminees (D-16). Une cloture NE SE ROUVRE JAMAIS.
--   * « Ou le candidat EN EST-IL sur cette notion ? » -> LE LEITNER.
--     La boite, l'echeance, les 5 crans. Il peut RECULER sans rien rouvrir.
--
-- Pourquoi le Leitner ne peut pas porter R2 : il ne garde que la BOITE COURANTE,
-- un etat agrege. Trois series reussies puis une ratee donnent boite 1,
-- indistinguable de « jamais vu ». R2 compte des SERIES -- des evenements dates --
-- et `etapesAuQuota` les lit sur `status = SOLID`. Le Leitner n'a pas cette trace.
--
-- ⚠️ CE QU'UN CANDIDAT VOIT QUAND ELLES DIVERGENT, et c'est assume (lecture 1) :
-- l'etape du cycle reste TERMINEE, et « Ou vous en etes » redescend la notion a
-- « a travailler ». Les deux sont vraies -- le cycle mesure un parcours accompli,
-- le plan un etat present -- et une PHRASE SERVIE l'explique sur l'ecran ou elles
-- se croisent (P8.7). 🛑 On ne masque PAS la mesure du Leitner : « on floute
-- l'action, jamais le resultat mesure » (contradiction #1 du depot).
--
-- ----------------------------------------------------------------------------
-- 🛑 LA GRANULARITE EST L'UNITE OFFICIELLE (16), PAS LA NOTION INTERNE (46)
-- ----------------------------------------------------------------------------
-- Consequence assumee de D-47 : une unite regroupe jusqu'a 8 notions internes,
-- donc une unite peut etre CLOTUREE alors qu'une de ses notions est en boite 1.
-- C'est coherent -- ce sont les deux questions ci-dessus -- et c'est pourquoi
-- cette table recoit `official_unit_id` et AUCUNE colonne de notion.
--
-- AUCUNE MIGRATION DE DONNEES : toutes les lignes existantes sont TCF, avec
-- `skill_id` pose.
-- ============================================================================

ALTER TABLE learning_plan_observations
    ADD COLUMN official_unit_id uuid REFERENCES civic_official_units (id);

-- `skill_id` cesse d'etre obligatoire : une observation civique n'a pas de `Skill`.
ALTER TABLE learning_plan_observations ALTER COLUMN skill_id DROP NOT NULL;

ALTER TABLE learning_plan_observations
    -- 🛑 EXACTEMENT UNE unite observee. Meme forme que `chk_journey_step_train_skill`
    -- (V069), et pour la meme raison : cette table n'a pas de colonne `module`.
    ADD CONSTRAINT chk_learning_plan_observation_unite CHECK (
        (skill_id IS NOT NULL) <> (official_unit_id IS NOT NULL)
    );

-- 🛑 LA SOURCE : deux valeurs civiques s'ajoutent aux neuf existantes.
-- `CIVIQUE_SERIE` est une serie ciblee du Plan -- c'est elle qui alimente R2.
-- `CIVIQUE_EXAMEN` est un examen de theme ou l'examen global : il MESURE, donc il
-- peut cloturer une etape et reinjecter une regression dans le cycle en attente.
-- ⚠️ La distinction n'est pas decorative : R3 dit que l'entrainement n'alimente
-- JAMAIS le cycle en attente, seuls les examens le font. Sans deux sources, la
-- regle serait indistinguable a la lecture.
ALTER TABLE learning_plan_observations DROP CONSTRAINT chk_learning_plan_observation_source;
ALTER TABLE learning_plan_observations
    ADD CONSTRAINT chk_learning_plan_observation_source CHECK (
        source_type IN (
            'DIAGNOSTIC_EE', 'DIAGNOSTIC_EO',
            'PRODUCTION_EE', 'PRODUCTION_EO',
            'MOCK_EXAM_EE', 'MOCK_EXAM_EO',
            'SKILL_TRAINING', 'TCF_CO', 'TCF_CE',
            'CIVIQUE_SERIE', 'CIVIQUE_EXAMEN'
        )
    );

-- ⚠️ `uq_learning_plan_observation_source (user_id, skill_id, source_type, source_id)`
-- N'EST PAS TOUCHEE, et c'est mesure : Postgres traite les NULL comme DISTINCTS
-- dans un index unique, donc deux observations civiques du meme `source_id`
-- passeraient. D'ou l'index JUMEAU ci-dessous, sur la colonne civique.
CREATE UNIQUE INDEX uq_learning_plan_observation_source_unite
    ON learning_plan_observations (user_id, official_unit_id, source_type, source_id)
    WHERE official_unit_id IS NOT NULL;

CREATE INDEX idx_learning_plan_user_unite_recent
    ON learning_plan_observations (user_id, official_unit_id, observed_at DESC)
    WHERE official_unit_id IS NOT NULL;

COMMENT ON COLUMN learning_plan_observations.official_unit_id IS
    'L''unite du programme officiel civique observee (V068). 🛑 Exclusive de '
    '`skill_id`. La granularite est l''UNITE (16), jamais la notion interne (46) : '
    'une unite peut etre cloturee avec une de ses notions en boite 1 -- consequence '
    'assumee de D-47, et c''est le Leitner qui dit l''etat present (D-49).';
