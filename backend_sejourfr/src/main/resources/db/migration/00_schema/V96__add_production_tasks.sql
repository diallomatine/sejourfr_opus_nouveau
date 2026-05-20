-- ============================================================================
-- V96 : Expression orale (EO) + Expression ecrite (EE) du TCF IRN
-- ============================================================================
-- Ajoute le support des epreuves productives evaluees par IA (Whisper + Claude).
-- Cf. PRODUCTION_TASKS_SPEC_V2.md a la racine du repo pour le contexte fonctionnel.
--
-- Resume :
--   1. attempts : nouvelle colonne `epreuve` (granularite : CIVIQUE | TCF_CO | TCF_CE |
--      TCF_STRUCTURE | TCF_EO | TCF_EE | TCF_COMPLET) + `parent_attempt_id` pour
--      regrouper les sous-attempts d'un examen blanc TCF complet.
--   2. production_tasks : catalogue des consignes EO/EE (independant des attempts).
--   3. production_submissions : ce que l'utilisateur a rendu (audio ou texte).
--   4. transcriptions : sortie Whisper pour les submissions EO.
--   5. ai_evaluations : note + feedback structure produit par Claude (tool_use).
--   6. human_calibration_notes : notes humaines pour calibrer l'IA.
--
-- Le pipeline d'evaluation est synchrone court-terme (cf. spec section 2.2). La
-- presence des statuts `TRANSCRIBING` / `EVALUATING` dans le CHECK n'implique pas
-- qu'ils soient utilises en MVP : ils sont la pour la migration future en async.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. attempts : `epreuve` + `parent_attempt_id`
-- ---------------------------------------------------------------------------
ALTER TABLE attempts
    ADD COLUMN epreuve           VARCHAR(20),
    ADD COLUMN parent_attempt_id UUID REFERENCES attempts(id) ON DELETE CASCADE;

-- Backfill : derive `epreuve` du `module` existant.
-- Les TCF historiques sont tous des QCM de comprehension orale (le CE et la
-- structure sont arrives plus tard dans les seeds mais reutilisent les memes
-- attempts) -> on retombe par defaut sur TCF_CO. Si un attempt etait dedie au
-- CE/STRUCTURE, l'admin pourra le repointer manuellement. La granularite fine
-- ne s'applique vraiment qu'aux attempts crees apres cette migration.
UPDATE attempts
SET epreuve = CASE
    WHEN module = 'TCF'      THEN 'TCF_CO'
    WHEN module = 'CIVIQUE'  THEN 'CIVIQUE'
    ELSE 'CIVIQUE'
END
WHERE epreuve IS NULL;

ALTER TABLE attempts
    ALTER COLUMN epreuve SET NOT NULL,
    ADD CONSTRAINT chk_attempts_epreuve CHECK (
        epreuve IN ('CIVIQUE', 'TCF_CO', 'TCF_CE', 'TCF_STRUCTURE', 'TCF_EO', 'TCF_EE', 'TCF_COMPLET')
    );

CREATE INDEX idx_attempts_parent ON attempts(parent_attempt_id) WHERE parent_attempt_id IS NOT NULL;

COMMENT ON COLUMN attempts.epreuve IS
    'Nature fine de l''epreuve (orthogonale a `mode`). Pour les examens blancs TCF complets, le parent porte TCF_COMPLET et les sous-attempts portent TCF_CO/TCF_CE/TCF_EO/TCF_EE.';
COMMENT ON COLUMN attempts.parent_attempt_id IS
    'NULL pour un attempt isole. Renseigne pour les sous-attempts d''un examen blanc TCF complet. CASCADE -> supprimer le parent supprime tous les enfants.';

-- ---------------------------------------------------------------------------
-- 2. production_tasks : catalogue des consignes EO/EE
-- ---------------------------------------------------------------------------
-- Une `production_task` est une consigne rejouable a l'infini, independante des
-- attempts. Le contenu est valide manuellement avant publication (is_active).
-- ---------------------------------------------------------------------------
CREATE TABLE production_tasks (
    id                    UUID PRIMARY KEY,
    epreuve               VARCHAR(20) NOT NULL,
    tache_numero          SMALLINT NOT NULL,
    niveau_cible          VARCHAR(4) NOT NULL,
    consigne              TEXT NOT NULL,
    contexte              TEXT,
    duree_max_sec         INTEGER,
    mots_min              INTEGER,
    mots_max              INTEGER,
    criteres_evaluation   JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_active             BOOLEAN NOT NULL DEFAULT FALSE,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_prod_task_epreuve
        CHECK (epreuve IN ('TCF_EO', 'TCF_EE')),
    CONSTRAINT chk_prod_task_tache_numero
        CHECK (tache_numero BETWEEN 1 AND 3),
    CONSTRAINT chk_prod_task_niveau
        CHECK (niveau_cible IN ('A2', 'B1', 'B2')),
    -- Coherence audio/texte : EO => duree_max_sec renseignee, mots_* NULL ;
    -- EE => mots_min/mots_max renseignes, duree_max_sec NULL.
    CONSTRAINT chk_prod_task_audio_text_coherence
        CHECK (
            (epreuve = 'TCF_EO' AND duree_max_sec IS NOT NULL AND mots_min IS NULL AND mots_max IS NULL)
         OR (epreuve = 'TCF_EE' AND duree_max_sec IS NULL AND mots_min IS NOT NULL AND mots_max IS NOT NULL)
        ),
    CONSTRAINT chk_prod_task_mots_range
        CHECK (mots_min IS NULL OR mots_max IS NULL OR mots_min <= mots_max)
);

CREATE INDEX idx_prod_task_lookup ON production_tasks(epreuve, niveau_cible, is_active);

COMMENT ON TABLE production_tasks IS
    'Catalogue des consignes pour les epreuves productives (EO/EE) du TCF IRN.';
COMMENT ON COLUMN production_tasks.criteres_evaluation IS
    'Grille passee au LLM : tableau de criteres ponderes + niveau attendu + consignes correcteur. Cf. spec section 3.2.';

-- ---------------------------------------------------------------------------
-- 3. production_submissions : la trace de ce que l'utilisateur a rendu
-- ---------------------------------------------------------------------------
CREATE TABLE production_submissions (
    id                  UUID PRIMARY KEY,
    attempt_id          UUID NOT NULL REFERENCES attempts(id) ON DELETE CASCADE,
    production_task_id  UUID NOT NULL REFERENCES production_tasks(id),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    submitted_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    media_url           VARCHAR(500),
    media_duration_sec  INTEGER,
    texte_soumis        TEXT,
    mots_count          INTEGER,
    statut              VARCHAR(20) NOT NULL DEFAULT 'SUBMITTED',
    retry_count         SMALLINT NOT NULL DEFAULT 0,
    erreur_message      TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_prod_sub_statut
        CHECK (statut IN ('SUBMITTED', 'TRANSCRIBING', 'EVALUATING', 'EVALUATED', 'FAILED')),
    CONSTRAINT chk_prod_sub_retry_count
        CHECK (retry_count BETWEEN 0 AND 3),
    -- Exactement une des deux colonnes media_url / texte_soumis est renseignee.
    -- (Les deux peuvent etre vides pendant le tres bref instant entre l'INSERT
    -- et l'upload S3, mais en sortie de transaction on doit avoir l'une ou l'autre.)
    CONSTRAINT chk_prod_sub_audio_or_text
        CHECK (
            (media_url IS NOT NULL AND texte_soumis IS NULL)
         OR (media_url IS NULL AND texte_soumis IS NOT NULL)
        )
);

CREATE INDEX idx_prod_sub_attempt ON production_submissions(attempt_id);
CREATE INDEX idx_prod_sub_user_submitted ON production_submissions(user_id, submitted_at DESC);
CREATE INDEX idx_prod_sub_statut_pending ON production_submissions(statut)
    WHERE statut <> 'EVALUATED';

COMMENT ON TABLE production_submissions IS
    'Une soumission utilisateur (audio ou texte) rattachee a un attempt et a une production_task.';
COMMENT ON COLUMN production_submissions.media_url IS
    'URL R2 signee ou cle de stockage de l''audio (EO uniquement).';
COMMENT ON COLUMN production_submissions.retry_count IS
    'Nombre de relances manuelles via POST /api/production-submissions/{id}/retry. Plafonne a 3 (anti-abus).';

-- ---------------------------------------------------------------------------
-- 4. transcriptions : sortie Whisper (EO uniquement)
-- ---------------------------------------------------------------------------
-- Table separee pour permettre la re-transcription et le versioning sans
-- toucher a la submission. En MVP on garde la derniere transcription par
-- submission, mais le modele autorise N transcriptions.
-- ---------------------------------------------------------------------------
CREATE TABLE transcriptions (
    id                    UUID PRIMARY KEY,
    submission_id         UUID NOT NULL REFERENCES production_submissions(id) ON DELETE CASCADE,
    texte                 TEXT NOT NULL,
    langue_detectee       VARCHAR(8),
    modele_utilise        VARCHAR(40) NOT NULL,
    prompt_utilise        TEXT,
    audio_duration_sec    INTEGER,
    cout_estime_centimes  INTEGER,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_transcription_submission ON transcriptions(submission_id);

COMMENT ON TABLE transcriptions IS
    'Resultat brut de la transcription Whisper pour une submission EO.';
COMMENT ON COLUMN transcriptions.prompt_utilise IS
    'Prompt Whisper utilise (mode litteral). Conserve pour debug et A/B test futur.';

-- ---------------------------------------------------------------------------
-- 5. ai_evaluations : note + feedback structure produit par Claude
-- ---------------------------------------------------------------------------
-- Une submission peut avoir plusieurs evaluations (re-evaluation, A/B test
-- de prompts). On recupere la derniere via (submission_id, evaluated_at DESC).
-- ---------------------------------------------------------------------------
CREATE TABLE ai_evaluations (
    id                    UUID PRIMARY KEY,
    submission_id         UUID NOT NULL REFERENCES production_submissions(id) ON DELETE CASCADE,
    modele_utilise        VARCHAR(40) NOT NULL,
    prompt_version        VARCHAR(20) NOT NULL,
    note_sur_20           NUMERIC(4, 1),
    niveau_cecrl          VARCHAR(20),
    feedback_json         JSONB NOT NULL,
    tokens_input          INTEGER,
    tokens_output         INTEGER,
    cout_estime_centimes  INTEGER,
    nb_retries            SMALLINT NOT NULL DEFAULT 0,
    evaluated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_ai_eval_note
        CHECK (note_sur_20 IS NULL OR (note_sur_20 >= 0 AND note_sur_20 <= 20)),
    CONSTRAINT chk_ai_eval_niveau
        CHECK (niveau_cecrl IS NULL OR niveau_cecrl IN
            ('A1_NON_ATTEINT', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'))
);

CREATE INDEX idx_ai_eval_submission_latest ON ai_evaluations(submission_id, evaluated_at DESC);

COMMENT ON TABLE ai_evaluations IS
    'Evaluation IA d''une submission (Claude via tool_use). Une submission peut etre re-evaluee plusieurs fois.';
COMMENT ON COLUMN ai_evaluations.feedback_json IS
    'Detail structure : note_globale, niveau_cecrl, scores_criteres[], points_forts[], points_a_ameliorer[], suggestions[], exemples_corriges[]. Cf. spec section 3.2.';
COMMENT ON COLUMN ai_evaluations.prompt_version IS
    'Versioning du prompt LLM (ex: v1.0). Toute modification du prompt = nouvelle version.';

-- ---------------------------------------------------------------------------
-- 6. human_calibration_notes : reference humaine pour calibrer l'IA
-- ---------------------------------------------------------------------------
-- Permet a un admin (ou prof partenaire) de noter manuellement une submission
-- et de comparer son score a celui de l'IA. Sert au dashboard de calibration.
-- ---------------------------------------------------------------------------
CREATE TABLE human_calibration_notes (
    id                    UUID PRIMARY KEY,
    submission_id         UUID NOT NULL REFERENCES production_submissions(id) ON DELETE CASCADE,
    evaluator_user_id     UUID NOT NULL REFERENCES users(id),
    note_humaine_sur_20   NUMERIC(4, 1) NOT NULL,
    niveau_cecrl_humain   VARCHAR(20) NOT NULL,
    commentaires          TEXT,
    -- Calcule a l'insertion par l'application : note_humaine - note_ia (derniere eval).
    -- Stocke pour eviter une jointure systematique dans le dashboard.
    ecart_note            NUMERIC(4, 1),
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_human_cal_note
        CHECK (note_humaine_sur_20 >= 0 AND note_humaine_sur_20 <= 20),
    CONSTRAINT chk_human_cal_niveau
        CHECK (niveau_cecrl_humain IN
            ('A1_NON_ATTEINT', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'))
);

CREATE INDEX idx_human_cal_submission ON human_calibration_notes(submission_id);
CREATE INDEX idx_human_cal_evaluator ON human_calibration_notes(evaluator_user_id, created_at DESC);

COMMENT ON TABLE human_calibration_notes IS
    'Notes humaines de reference pour calibrer l''evaluation IA. Cf. spec section 3.2 (calibration progressive).';
COMMENT ON COLUMN human_calibration_notes.ecart_note IS
    'Calcule a l''insertion : note_humaine - note_ia (derniere ai_evaluation). NULL si pas encore d''eval IA.';
