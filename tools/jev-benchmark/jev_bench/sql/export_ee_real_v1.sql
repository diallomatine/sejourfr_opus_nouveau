-- Export ANONYMISÉ des productions EE réelles (EE1–EE3) pour le benchmark JEV — version 1.
-- LECTURE SEULE : uniquement des SELECT ; la session est lancée avec
-- PGOPTIONS='-c default_transaction_read_only=on'. Rien n'est écrit sur le serveur.
--
-- Variable psql obligatoire : :'salt' (sel local, jamais affiché, jamais versionné).
-- Sortie : une ligne JSON par enregistrement, deux types :
--   {"kind":"sample", ...}  les productions RETENUES (seules à porter un texte) ;
--   {"kind":"count",  ...}  les effectifs par cellule (disponible / après plafond candidat / retenu).
--
-- Ne sort JAMAIS : user_id, attempt_id, id de soumission ou d'évaluation, email, nom.
-- Identifiants projetés : md5(sel || id) uniquement. Le pseudo-candidat ne sert qu'au
-- contrôle local du plafond ; il n'est ni envoyé à JEV ni exporté.
-- scores_criteres : codes + notes SEULEMENT (commentaires et preuves citent le texte).
--
-- Échantillonnage (déterministe, reproductible avec le même sel) :
--   1. population : TCF_EE hors diagnostic, EVALUATED, comptes réels (non internes, non
--      supprimés, hors @sejourfr.fr et compte propriétaire), DERNIÈRE évaluation par
--      soumission, grille v15 / schéma v9 ;
--   2. plafond 3 productions par candidat, AVANT les quotas (ordre md5(sel || id)) ;
--   3. cellules tâche × {A1, A2, B1, B2} : tout pour A1 et B2, 11 pour A2 et B1 ; jamais de
--      complément d'une cellule insuffisante ;
--   4. strates ISOLÉES, prises en entier : A1_NON_ATTEINT, NON_EVALUABLE, PLAFOND
--      (trace feedback_json.plafond_niveau posée par AiEvaluationService.applyPlafonds).

WITH derniere AS (
    SELECT DISTINCT ON (s.id)
           s.id                  AS submission_id,
           s.user_id,
           s.texte_soumis,
           s.mots_count,
           s.submitted_at,
           a.slot_number,
           a.parent_attempt_id,
           t.tache_numero,
           t.consigne,
           t.contexte,
           t.mots_min,
           t.mots_max,
           e.niveau_cecrl,
           e.niveau_cecrl_ia,
           e.note_sur_20,
           e.feedback_json,
           e.evaluabilite,
           e.modele_utilise,
           e.rubrics_version,
           e.prompt_version
    FROM production_submissions s
    JOIN production_tasks t ON t.id = s.production_task_id
    JOIN users u            ON u.id = s.user_id
    JOIN ai_evaluations e   ON e.submission_id = s.id
    LEFT JOIN attempts a    ON a.id = s.attempt_id
    WHERE t.epreuve = 'TCF_EE'
      AND NOT s.is_diagnostic
      AND s.statut = 'EVALUATED'
      AND NOT u.is_internal
      AND u.deleted_at IS NULL
      AND NOT (u.email ILIKE '%@sejourfr.fr' OR u.email = 'dialloabdoulmatine@gmail.com')
    ORDER BY s.id, e.evaluated_at DESC
),
pool AS (
    SELECT d.*,
           CASE
               WHEN d.evaluabilite = 'NON_EVALUABLE'        THEN 'NON_EVALUABLE'
               WHEN d.niveau_cecrl = 'A1_NON_ATTEINT'       THEN 'A1_NON_ATTEINT'
               WHEN d.feedback_json ? 'plafond_niveau'      THEN 'PLAFOND'
               WHEN d.niveau_cecrl IN ('A1','A2','B1','B2') THEN 'CECRL'
               ELSE 'AUTRE'
           END AS strate,
           md5(:'salt' || d.submission_id::text) AS sample_key
    FROM derniere d
    WHERE d.rubrics_version = 'v15' AND d.prompt_version = 'v9'
),
plafonne AS (
    SELECT p.*,
           row_number() OVER (PARTITION BY p.user_id ORDER BY p.sample_key) AS rang_candidat
    FROM pool p
),
apres_plafond AS (
    SELECT q.*,
           row_number() OVER (PARTITION BY q.tache_numero, q.strate, q.niveau_cecrl ORDER BY q.sample_key) AS rang_cellule
    FROM plafonne q
    WHERE q.rang_candidat <= 3
),
retenu AS (
    SELECT r.*
    FROM apres_plafond r
    WHERE r.strate IN ('A1_NON_ATTEINT', 'NON_EVALUABLE', 'PLAFOND')
       OR (r.strate = 'CECRL' AND r.niveau_cecrl IN ('A1', 'B2'))
       OR (r.strate = 'CECRL' AND r.niveau_cecrl IN ('A2', 'B1') AND r.rang_cellule <= 11)
),
cellules AS (
    SELECT tache_numero, strate, coalesce(niveau_cecrl, '-') AS niveau,
           count(*)                                   AS disponible,
           count(DISTINCT user_id)                    AS candidats_disponibles,
           count(*) FILTER (WHERE rang_candidat <= 3) AS apres_plafond
    FROM plafonne
    GROUP BY 1, 2, 3
),
retenus_par_cellule AS (
    SELECT tache_numero, strate, coalesce(niveau_cecrl, '-') AS niveau, count(*) AS retenu,
           count(DISTINCT user_id) AS candidats_retenus
    FROM retenu
    GROUP BY 1, 2, 3
)
SELECT json_build_object(
           'kind', 'sample',
           'sample_key', r.sample_key,
           'candidate_key', md5(:'salt' || r.user_id::text),
           'tache_numero', r.tache_numero,
           'attempt_type', CASE WHEN r.slot_number IS NOT NULL OR r.parent_attempt_id IS NOT NULL
                                THEN 'MOCK_EXAM' ELSE 'TRAINING' END,
           'mois', to_char(r.submitted_at AT TIME ZONE 'Europe/Paris', 'YYYY-MM'),
           'strate', r.strate,
           'consigne', r.consigne,
           'contexte', r.contexte,
           'mots_min', r.mots_min,
           'mots_max', r.mots_max,
           'mots_count', r.mots_count,
           'texte_soumis', r.texte_soumis,
           'niveau_cecrl', r.niveau_cecrl,
           'niveau_cecrl_ia', r.niveau_cecrl_ia,
           'note_sur_20', r.note_sur_20,
           'scores', (SELECT json_agg(json_build_object('code', x->>'code', 'note_sur_20', x->'note_sur_20'))
                      FROM jsonb_array_elements(coalesce(r.feedback_json->'scores_criteres', '[]'::jsonb)) x),
           'confiance', r.feedback_json->>'confiance',
           'plafond_niveau', r.feedback_json->>'plafond_niveau',
           'plafond_condition_t3', (r.tache_numero = 3 AND EXISTS (
                SELECT 1 FROM jsonb_array_elements(coalesce(r.feedback_json->'scores_criteres', '[]'::jsonb)) x
                WHERE x->>'code' = 'communiquer' AND (x->>'note_sur_20')::numeric <= 1)),
           'evaluabilite', r.evaluabilite,
           'modele_utilise', r.modele_utilise,
           'rubrics_version', r.rubrics_version,
           'prompt_version', r.prompt_version
       )
FROM retenu r
UNION ALL
SELECT json_build_object(
           'kind', 'count',
           'tache_numero', c.tache_numero,
           'strate', c.strate,
           'niveau', c.niveau,
           'disponible', c.disponible,
           'candidats_disponibles', c.candidats_disponibles,
           'apres_plafond', c.apres_plafond,
           'retenu', coalesce(rc.retenu, 0),
           'candidats_retenus', coalesce(rc.candidats_retenus, 0)
       )
FROM cellules c
LEFT JOIN retenus_par_cellule rc
       ON rc.tache_numero = c.tache_numero AND rc.strate = c.strate AND rc.niveau = c.niveau;
