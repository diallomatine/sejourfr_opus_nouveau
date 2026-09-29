-- ============================================================================
-- V011 — Schéma : production EO/EE (sujets, soumissions, éval IA)
-- ----------------------------------------------------------------------------
-- Tables : production_tasks, production_submissions, transcriptions,
--          ai_evaluations, human_calibration_notes, production_examples
-- Relations :
--   production_submissions -> attempts (CASCADE) + production_tasks + users (CASCADE)
--   transcriptions / ai_evaluations / human_calibration_notes -> production_submissions (CASCADE)
--   production_examples -> production_tasks (CASCADE)
--
-- NB : pas de table production_situations / *_medias (décision actée : les sujets
--      vivent dans production_tasks, les exemples dans production_examples).
--      La colonne production_tasks.criteres_evaluation est définitivement
--      supprimée — la notation vit dans prompts/production-rubrics-<version>.json.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- production_tasks (sujets EO/EE)
-- ---------------------------------------------------------------------------
CREATE TABLE production_tasks (
    id            uuid NOT NULL PRIMARY KEY,
    epreuve       varchar(20) NOT NULL,
    tache_numero  smallint NOT NULL,
    niveau_cible  varchar(4) NOT NULL,
    consigne      text NOT NULL,
    contexte      text,
    duree_min_sec integer,
    duree_max_sec integer,
    mots_min      integer,
    mots_max      integer,
    is_active     boolean DEFAULT false NOT NULL,
    created_at    timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT chk_prod_task_epreuve CHECK (((epreuve)::text = ANY ((ARRAY['TCF_EO','TCF_EE'])::text[]))),
    CONSTRAINT chk_prod_task_niveau CHECK (((niveau_cible)::text = ANY ((ARRAY['A2','B1','B2'])::text[]))),
    CONSTRAINT chk_prod_task_tache_numero CHECK (((tache_numero >= 1) AND (tache_numero <= 3))),
    CONSTRAINT chk_prod_task_mots_range CHECK (((mots_min IS NULL) OR (mots_max IS NULL) OR (mots_min <= mots_max))),
    CONSTRAINT chk_prod_task_audio_text_coherence CHECK (
        (((epreuve)::text = 'TCF_EO'::text) AND (duree_max_sec IS NOT NULL) AND (mots_min IS NULL) AND (mots_max IS NULL))
        OR (((epreuve)::text = 'TCF_EE'::text) AND (duree_max_sec IS NULL) AND (mots_min IS NOT NULL) AND (mots_max IS NOT NULL))
    )
);
CREATE INDEX idx_prod_task_lookup ON production_tasks (epreuve, niveau_cible, is_active);

COMMENT ON TABLE production_tasks IS 'Sujets d''entraînement EO/EE : plusieurs lignes par (epreuve, tache_numero). Le candidat en choisit un et produit sa réponse, corrigée par l''IA.';

-- ---------------------------------------------------------------------------
-- production_submissions (réponse utilisateur : audio EO ou texte EE)
-- ---------------------------------------------------------------------------
CREATE TABLE production_submissions (
    id                 uuid NOT NULL PRIMARY KEY,
    attempt_id         uuid NOT NULL REFERENCES attempts(id) ON DELETE CASCADE,
    production_task_id uuid NOT NULL REFERENCES production_tasks(id),
    user_id            uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    submitted_at       timestamptz DEFAULT now() NOT NULL,
    media_url          varchar(500),
    media_duration_sec integer,
    texte_soumis       text,
    mots_count         integer,
    statut             varchar(20) DEFAULT 'SUBMITTED'::varchar NOT NULL,
    retry_count        smallint DEFAULT 0 NOT NULL,
    erreur_message     text,
    created_at         timestamptz DEFAULT now() NOT NULL,
    updated_at         timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT chk_prod_sub_statut CHECK (((statut)::text = ANY ((ARRAY['SUBMITTED','TRANSCRIBING','EVALUATING','EVALUATED','FAILED'])::text[]))),
    CONSTRAINT chk_prod_sub_retry_count CHECK (((retry_count >= 0) AND (retry_count <= 3))),
    CONSTRAINT chk_prod_sub_audio_or_text CHECK ((((media_url IS NOT NULL) AND (texte_soumis IS NULL)) OR ((media_url IS NULL) AND (texte_soumis IS NOT NULL))))
);
CREATE INDEX idx_prod_sub_attempt ON production_submissions (attempt_id);
CREATE INDEX idx_prod_sub_user_submitted ON production_submissions (user_id, submitted_at DESC);
CREATE INDEX idx_prod_sub_statut_pending ON production_submissions (statut) WHERE ((statut)::text <> 'EVALUATED'::text);

COMMENT ON TABLE production_submissions IS 'Une soumission utilisateur (audio ou texte) rattachee a un attempt et a une production_task.';
COMMENT ON COLUMN production_submissions.media_url IS 'URL R2 signee ou cle de stockage de l''audio (EO uniquement).';
COMMENT ON COLUMN production_submissions.retry_count IS 'Nombre de relances manuelles via POST /api/production-submissions/{id}/retry. Plafonne a 3 (anti-abus).';

-- ---------------------------------------------------------------------------
-- transcriptions (Whisper, EO)
-- ---------------------------------------------------------------------------
CREATE TABLE transcriptions (
    id                  uuid NOT NULL PRIMARY KEY,
    submission_id       uuid NOT NULL REFERENCES production_submissions(id) ON DELETE CASCADE,
    texte               text NOT NULL,
    langue_detectee     varchar(8),
    modele_utilise      varchar(40) NOT NULL,
    prompt_utilise      text,
    audio_duration_sec  integer,
    cout_estime_centimes integer,
    created_at          timestamptz DEFAULT now() NOT NULL
);
CREATE INDEX idx_transcription_submission ON transcriptions (submission_id);

COMMENT ON TABLE transcriptions IS 'Resultat brut de la transcription Whisper pour une submission EO.';
COMMENT ON COLUMN transcriptions.prompt_utilise IS 'Prompt Whisper utilise (mode litteral). Conserve pour debug et A/B test futur.';

-- ---------------------------------------------------------------------------
-- ai_evaluations (Claude/OpenAI via tool_use)
-- ---------------------------------------------------------------------------
CREATE TABLE ai_evaluations (
    id                   uuid NOT NULL PRIMARY KEY,
    submission_id        uuid NOT NULL REFERENCES production_submissions(id) ON DELETE CASCADE,
    modele_utilise       varchar(40) NOT NULL,
    prompt_version       varchar(20) NOT NULL,
    note_sur_20          numeric(4,1),
    niveau_cecrl_ia      varchar(20),
    feedback_json        jsonb NOT NULL,
    tokens_input         integer,
    tokens_output        integer,
    cout_estime_centimes integer,
    nb_retries           smallint DEFAULT 0 NOT NULL,
    evaluated_at         timestamptz DEFAULT now() NOT NULL,
    niveau_cecrl         varchar(20),
    CONSTRAINT chk_ai_eval_note CHECK (((note_sur_20 IS NULL) OR ((note_sur_20 >= (0)::numeric) AND (note_sur_20 <= (20)::numeric)))),
    CONSTRAINT chk_ai_eval_niveau_ia CHECK (((niveau_cecrl_ia IS NULL) OR ((niveau_cecrl_ia)::text = ANY ((ARRAY['A1_NON_ATTEINT','A1','A2','B1','B2','C1','C2'])::text[])))),
    CONSTRAINT chk_ai_eval_niveau CHECK (((niveau_cecrl IS NULL) OR ((niveau_cecrl)::text = ANY ((ARRAY['A1_NON_ATTEINT','A1','A2','B1','B2','C1','C2'])::text[]))))
);
CREATE INDEX idx_ai_eval_submission_latest ON ai_evaluations (submission_id, evaluated_at DESC);

COMMENT ON TABLE ai_evaluations IS 'Evaluation IA d''une submission (Claude via tool_use). Une submission peut etre re-evaluee plusieurs fois.';
COMMENT ON COLUMN ai_evaluations.prompt_version IS 'Versioning du prompt LLM (ex: v1.0). Toute modification du prompt = nouvelle version.';
COMMENT ON COLUMN ai_evaluations.niveau_cecrl_ia IS 'Niveau CECRL brut renvoyé par le LLM (interne, calibration). Jamais exposé au mobile.';
COMMENT ON COLUMN ai_evaluations.feedback_json IS 'Detail structure : note_globale, niveau_cecrl, scores_criteres[], points_forts[], points_a_ameliorer[], suggestions[], exemples_corriges[]. Cf. spec section 3.2.';
COMMENT ON COLUMN ai_evaluations.niveau_cecrl IS 'Niveau CECRL calculé serveur (lexique + morphosyntaxe, seuils config). Valeur affichée à l''utilisateur.';

-- ---------------------------------------------------------------------------
-- human_calibration_notes (référence humaine pour calibrer l'IA)
-- ---------------------------------------------------------------------------
CREATE TABLE human_calibration_notes (
    id                  uuid NOT NULL PRIMARY KEY,
    submission_id       uuid NOT NULL REFERENCES production_submissions(id) ON DELETE CASCADE,
    evaluator_user_id   uuid NOT NULL REFERENCES users(id),
    note_humaine_sur_20 numeric(4,1) NOT NULL,
    niveau_cecrl_humain varchar(20) NOT NULL,
    commentaires        text,
    ecart_note          numeric(4,1),
    created_at          timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT chk_human_cal_note CHECK (((note_humaine_sur_20 >= (0)::numeric) AND (note_humaine_sur_20 <= (20)::numeric))),
    CONSTRAINT chk_human_cal_niveau CHECK (((niveau_cecrl_humain)::text = ANY ((ARRAY['A1_NON_ATTEINT','A1','A2','B1','B2','C1','C2'])::text[])))
);
CREATE INDEX idx_human_cal_submission ON human_calibration_notes (submission_id);
CREATE INDEX idx_human_cal_evaluator ON human_calibration_notes (evaluator_user_id, created_at DESC);

COMMENT ON TABLE human_calibration_notes IS 'Notes humaines de reference pour calibrer l''evaluation IA. Cf. spec section 3.2 (calibration progressive).';
COMMENT ON COLUMN human_calibration_notes.ecart_note IS 'Calcule a l''insertion : note_humaine - note_ia (derniere ai_evaluation). NULL si pas encore d''eval IA.';

-- ---------------------------------------------------------------------------
-- production_examples (réponses modèles rattachées à une tâche)
-- ---------------------------------------------------------------------------
CREATE TABLE production_examples (
    id                 uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    task_id            uuid NOT NULL REFERENCES production_tasks(id) ON DELETE CASCADE,
    titre              varchar(150) NOT NULL,
    resume             varchar(255),
    contenu            text NOT NULL,
    explications       text,
    ssml_text          text,
    audio_url          text,
    audio_status       varchar(20) DEFAULT 'NONE'::varchar NOT NULL,
    audio_voice        varchar(50),
    audio_duration_sec integer,
    audio_generated_at timestamptz,
    audio_batch_id     uuid,
    audio_error        text,
    plan_points        jsonb,
    niveau_indicatif   varchar(2),
    display_order      integer DEFAULT 0 NOT NULL,
    created_at         timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT chk_prod_example_niveau CHECK (((niveau_indicatif IS NULL) OR ((niveau_indicatif)::text = ANY ((ARRAY['A2','B1','B2'])::text[])))),
    CONSTRAINT chk_prod_example_audio_status CHECK (((audio_status)::text = ANY ((ARRAY['NONE','PENDING','GENERATING','GENERATED','PUBLISHED','ERROR'])::text[])))
);
CREATE INDEX idx_prod_examples_task ON production_examples (task_id, display_order);
CREATE INDEX idx_prod_examples_audio_status ON production_examples (audio_status);

COMMENT ON TABLE production_examples IS 'Reponses modeles illustrant une tache (ex: "un boulanger qui se presente"). Rattachees a la tache, pas a une situation. Le candidat les consulte pour s''inspirer.';
COMMENT ON COLUMN production_examples.plan_points IS 'Plan rapide : tableau de chaines affichees en check-list (["Bonjour + prenom", "Ville", ...]).';
COMMENT ON COLUMN production_examples.audio_status IS 'Cycle de génération audio (EO) : NONE -> PENDING -> GENERATING -> GENERATED -> PUBLISHED / ERROR. Le candidat n''entend l''audio que PUBLISHED.';
COMMENT ON COLUMN production_examples.audio_batch_id IS 'Identifiant du lot de génération (POST /api/admin/production/examples/audio/batch-generate).';
COMMENT ON COLUMN production_examples.explications IS 'Commentaire pédagogique affiché sous le contenu du modèle, pour orienter le candidat (ce qui fait que ce modèle réussit la tâche).';
