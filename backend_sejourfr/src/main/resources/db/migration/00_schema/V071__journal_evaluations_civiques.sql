-- ============================================================================
-- V071 — LE JOURNAL DES EVALUATIONS ACCUEILLE LE CIVIQUE : un axe, trois
--        natures, et une cle qui laisse un examen complet ecrire SIX lignes
-- ============================================================================
-- Arbitrage : docs/decisions/plan-parcours-tcf.md D-51 (2026-09-19), forme
-- validee par le proprietaire avant ecriture. Cadre fonctionnel :
-- docs/progression/civique/SPEC_cycle_plan_civique.md. Etat de la passe :
-- docs/progression/civique/REPRISE-P8.4-MOTEUR.md (point 1).
-- Source de droit du referentiel : arrete du 10 octobre 2025 (JORF n° 0240 du
-- 12 octobre 2025, NOR INTV2527907A).
--
-- `journey_assessment_event` refusait TOUTE evaluation civique, par deux CHECK
-- de V066 :
--   * `chk_journey_assessment_exam_type` borne `exam_type` aux 4 valeurs TCF ;
--   * `chk_journey_assessment_epreuve_mesuree` dit « SEUL le diagnostic rapide
--     ne mesure rien » -- donc un examen civique, qui ne mesure aucune EPREUVE,
--     etait rejete.
--
-- ⚠️ ET L'ECHEC AURAIT ETE SILENCIEUX : `porterAuParcours` avale ses exceptions
-- (`AttemptInteractionService`, catch RuntimeException -> log.warn). Le symptome
-- aurait ete « le cycle civique ne se remplit jamais », sans trace et sans test
-- rouge. C'est DETTE-M1, nommee a la 2e occurrence du meme piege.
--
-- ----------------------------------------------------------------------------
-- CE QU'UNE EVALUATION CIVIQUE MESURE -- ET POURQUOI IL EN FAUT TROIS NATURES
-- ----------------------------------------------------------------------------
--   * CIVIC_DIAGNOSTIC  -- le diagnostic civique. Aucun axe : il produit des
--     priorites sans mesurer, comme QUICK_DIAGNOSTIC cote TCF. 🛑 Une valeur A
--     PART, et non QUICK_DIAGNOSTIC, parce que `source_assessment_id` vient
--     d'une AUTRE TABLE : `civic_diagnostic_sessions`, pas
--     `diagnostic_sessions`. Le champ `assessment_kind` dit de quelle table
--     vient l'identifiant -- le confondre rendrait le journal ambigu.
--   * CIVIC_THEME_EXAM  -- un examen de theme. Son axe est SA thematique.
--   * CIVIC_EXAM        -- l'examen blanc civique complet (40 questions, les 5
--     thematiques). AUCUN AXE : c'est un fait GLOBAL, il mesure le programme
--     entier et met a jour `exit_score`.
--
-- 🛑 UN EXAMEN COMPLET ECRIT SIX LIGNES : une CIVIC_EXAM globale, plus une
-- CIVIC_THEME_EXAM par thematique dont le bloc etait debloque. Motif (R1,
-- arbitrage du proprietaire) : le CYCLE DE MESURE est fait de cinq blocs qui ne
-- contiennent QUE leur examen, tous debloques -- et c'est precisement l'examen
-- complet qui doit les cloturer. Sans ces cinq lignes, le cycle de mesure
-- n'aurait aucun moyen de se fermer.
--
-- 🛑 UNE ETAPE D'EXAMEN SE CLOTURE EN ETANT PASSEE, PAS EN ETANT REUSSIE -- ni
-- au TCF ni au civique. L'examen MESURE, il ne sanctionne pas. Aucun seuil par
-- thematique n'entre donc ici, et l'arrete n'en definit aucun : ses 80 % portent
-- sur les 40 questions, jamais theme par theme.
--
-- ----------------------------------------------------------------------------
-- 🛑 LA CLE : DEUX INDEX PARTIELS, ET SUREMENT PAS UNE CONTRAINTE A 3 COLONNES
-- ----------------------------------------------------------------------------
-- `UNIQUE (journey_id, source_assessment_id, theme_id)` ne garantirait RIEN pour
-- les evenements sans axe : Postgres traite deux NULL comme DISTINCTS, donc les
-- diagnostics -- TCF comme civiques -- pourraient se dupliquer librement, et
-- R14 tomberait LA OU IL TIENT AUJOURD'HUI.
--
-- D'ou deux index jumeaux partiels. Ce qu'il faut en retenir, et c'est la
-- formulation qui compte :
--
--   LA GARANTIE DE V066 N'EST PAS DESSERREE, ELLE EST BORNEE AU COTE SANS AXE.
--
-- Pour tout ce qui est TCF -- dont `theme_id` est toujours NULL, le CHECK ci-
-- dessous l'impose -- la cle reste EXACTEMENT `(journey_id,
-- source_assessment_id)`, bit pour bit.
--
-- ----------------------------------------------------------------------------
-- ⚠️ LE GARDE D'IDEMPOTENCE NE BOUGE PAS -- A UNE CONDITION, ET ELLE EST TESTEE
-- ----------------------------------------------------------------------------
-- `JourneyService` sort par `dejaTraitee(userId, module, sourceAssessmentId)`,
-- SANS axe. Il reste juste tant que LES SIX LIGNES S'ECRIVENT DANS LA MEME
-- PASSE : un rejeu retombe alors sur « deja traitee » et ne reecrit rien.
--
-- 🛑 Si un jour elles s'ecrivaient au fil de l'eau, ce garde deviendrait FAUX EN
-- SILENCE -- la 2e thematique serait vue comme un rejeu de la 1re, et les quatre
-- clotures suivantes seraient perdues sans une ligne de log. Une note ne suffit
-- pas a tenir ca : le couplage est fige par un test
-- (`JournalCiviqueSchemaIT.lesSixLignesDoiventSEcrireDansLaMemePasse`).
--
-- AUCUNE MIGRATION DE DONNEES : les lignes existantes sont toutes TCF, avec leur
-- `exam_type` pose et `theme_id` NULL -- elles satisfont le nouveau CHECK telles
-- quelles.
-- ============================================================================

-- ============================================================================
-- 1. L'AXE — jumeau exact du patron de V069
-- ============================================================================

ALTER TABLE journey_assessment_event
    ADD COLUMN theme_id uuid REFERENCES themes (id);

COMMENT ON COLUMN journey_assessment_event.theme_id IS
    'La THEMATIQUE que cette evaluation a mesuree, cote civique. NULL pour tout le TCF (son axe '
        'est `exam_type`), pour les deux diagnostics, et pour l''examen blanc civique COMPLET, '
        'qui est un fait global. Un examen complet ecrit une ligne globale + une ligne par '
        'thematique dont le bloc etait debloque (R1).';

-- ============================================================================
-- 2. LES NATURES — le CHECK est l'AUTORITE, l'enum Java en est le MIROIR
-- ============================================================================
-- Meme discipline que `chk_free_entitlement_code` (V067) : une valeur libre
-- ferait qu'une faute de frappe passerait sans que rien ne le signale. Ajouter
-- une nature d'evaluation est donc une MIGRATION, pas une constante Java.

ALTER TABLE journey_assessment_event
    DROP CONSTRAINT chk_journey_assessment_kind,
    ADD CONSTRAINT chk_journey_assessment_kind CHECK (
        assessment_kind IN (
            'QUICK_DIAGNOSTIC', 'FULL_DIAGNOSTIC', 'SECTION_EXAM', 'MOCK_EXAM',
            'CIVIC_DIAGNOSTIC', 'CIVIC_THEME_EXAM', 'CIVIC_EXAM'));

-- ============================================================================
-- 3. QUI MESURE QUOI — un axe EXACT par nature, jamais « au choix »
-- ============================================================================
-- Remplace `chk_journey_assessment_epreuve_mesuree`, qui liait « aucune
-- epreuve » au seul diagnostic rapide. La forme par CASE donne a CHAQUE nature
-- sa regle exacte, au lieu d'un « ou bien » qui aurait desserre le TCF pour
-- loger le civique : les 4 natures TCF portent `exam_type` et JAMAIS `theme_id`.

ALTER TABLE journey_assessment_event
    DROP CONSTRAINT chk_journey_assessment_epreuve_mesuree,
    ADD CONSTRAINT chk_journey_assessment_mesure CHECK (
        CASE assessment_kind
            -- Les deux diagnostics ne mesurent rien : ils produisent des
            -- priorites (R11). Deux natures, parce que deux tables sources.
            WHEN 'QUICK_DIAGNOSTIC' THEN exam_type IS NULL AND theme_id IS NULL
            WHEN 'CIVIC_DIAGNOSTIC' THEN exam_type IS NULL AND theme_id IS NULL
            -- L'examen de theme mesure SA thematique, et elle seule.
            WHEN 'CIVIC_THEME_EXAM' THEN exam_type IS NULL AND theme_id IS NOT NULL
            -- L'examen complet est un fait GLOBAL : il mesure le programme
            -- entier. Ses cinq clotures de bloc sont des CIVIC_THEME_EXAM.
            WHEN 'CIVIC_EXAM' THEN exam_type IS NULL AND theme_id IS NULL
            -- FULL_DIAGNOSTIC, SECTION_EXAM, MOCK_EXAM : le TCF, inchange.
            ELSE exam_type IS NOT NULL AND theme_id IS NULL
        END);

COMMENT ON CONSTRAINT chk_journey_assessment_mesure ON journey_assessment_event IS
    'Chaque nature d''evaluation porte EXACTEMENT l''axe qu''elle mesure : aucun pour les deux '
        'diagnostics et pour l''examen civique complet, la thematique pour un examen de theme, '
        'l''epreuve pour tout le TCF. Une regle par nature, jamais un « ou bien ».';

-- ============================================================================
-- 4. LA CLE D'IDEMPOTENCE (R14) — deux index jumeaux partiels
-- ============================================================================

ALTER TABLE journey_assessment_event
    DROP CONSTRAINT uq_journey_assessment_event;

-- 🛑 LE COTE SANS AXE : c'est la cle de V066, INCHANGEE. Tout le TCF y tombe
-- (son `theme_id` est toujours NULL), ainsi que les deux diagnostics et
-- l'examen civique complet. Une evaluation, une ligne, par cycle.
CREATE UNIQUE INDEX uq_journey_assessment_event_sans_axe
    ON journey_assessment_event (journey_id, source_assessment_id)
    WHERE theme_id IS NULL;

-- Le cote AVEC axe : les cinq clotures d'un examen complet partagent leur
-- `source_assessment_id` -- c'est le MEME attempt -- et se distinguent par leur
-- thematique. Deux fois la meme thematique pour le meme attempt reste refuse.
CREATE UNIQUE INDEX uq_journey_assessment_event_par_theme
    ON journey_assessment_event (journey_id, source_assessment_id, theme_id)
    WHERE theme_id IS NOT NULL;

-- ============================================================================
-- 5. LE REPERE DE R14 COTE THEMATIQUE — jumeau de idx_..._epreuve
-- ============================================================================
-- « Quelle est la derniere evaluation deja traitee de cette THEMATIQUE ? » --
-- ce qui fait ignorer une synchronisation mobile tardive mais plus ancienne.

CREATE INDEX idx_journey_assessment_event_theme
    ON journey_assessment_event (journey_id, theme_id, completed_at DESC)
    WHERE theme_id IS NOT NULL;
