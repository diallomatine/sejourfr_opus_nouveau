-- ============================================================================
-- V429 : niveau CECRL calculé côté serveur + niveau IA brut conservé
-- ============================================================================
-- Le niveau AFFICHÉ à l'utilisateur n'est plus celui du LLM : il est calculé
-- serveur à partir des critères porteurs du niveau (lexique + morphosyntaxe),
-- comme `note_globale` l'est déjà. Le niveau du LLM reste en base (jamais
-- affiché) pour mesurer l'écart IA vs calcul (dashboard de calibration).
--
-- - `niveau_cecrl_ia` (ex-`niveau_cecrl`) : niveau brut du LLM. Interne.
-- - `niveau_cecrl` (nouveau) : niveau calculé serveur. Exposé au mobile.
--
-- Rétro-compat : les évaluations antérieures avaient le niveau LLM dans
-- `niveau_cecrl` ; on le recopie dans `niveau_cecrl_ia` (via le rename) ET on
-- réalimente `niveau_cecrl` avec cette même valeur pour ne pas casser
-- l'historique (recalcul possible plus tard si besoin).
-- ============================================================================

ALTER TABLE ai_evaluations RENAME COLUMN niveau_cecrl TO niveau_cecrl_ia;
ALTER TABLE ai_evaluations RENAME CONSTRAINT chk_ai_eval_niveau TO chk_ai_eval_niveau_ia;

ALTER TABLE ai_evaluations ADD COLUMN niveau_cecrl VARCHAR(20);
ALTER TABLE ai_evaluations ADD CONSTRAINT chk_ai_eval_niveau
    CHECK (niveau_cecrl IS NULL OR niveau_cecrl IN
        ('A1_NON_ATTEINT', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'));

UPDATE ai_evaluations SET niveau_cecrl = niveau_cecrl_ia;

COMMENT ON COLUMN ai_evaluations.niveau_cecrl_ia IS
    'Niveau CECRL brut renvoyé par le LLM (interne, calibration). Jamais exposé au mobile.';
COMMENT ON COLUMN ai_evaluations.niveau_cecrl IS
    'Niveau CECRL calculé serveur (lexique + morphosyntaxe, seuils config). Valeur affichée à l''utilisateur.';
