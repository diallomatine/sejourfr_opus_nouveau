-- ============================================================================
-- V289 — EFFACE 21 VERDICTS POSÉS SUR DES SUGGESTIONS PÉRIMÉES.
-- ----------------------------------------------------------------------------
-- 🛑 CE QUE CETTE MIGRATION RÉPARE. Le 2026-09-11, vingt questions ont changé
-- de thème (V288) puis ont été reproposées au modèle dans leur nouveau thème.
-- En validant ces nouvelles suggestions, le serveur a tamponné le verdict sur
-- TOUTES les suggestions de la question — y compris celles de la campagne
-- close, faites pour un autre thème.
--
-- Résultat : 21 lignes d'une campagne terminée portaient « VALIDATED », ce qui
-- se lit « le modèle a conclu qu'aucune notion ne convenait, et l'humain l'a
-- suivi ». L'humain avait fait l'inverse : déplacer la question et la taguer
-- ailleurs. Une mesure de campagne relancée après coup en ressortait faussée.
--
-- ⚠️ CE N'EST PAS UNE RÉÉCRITURE DE L'HISTORIQUE, C'EN EST LA RESTAURATION.
-- Ces verdicts n'ont jamais été rendus : aucun humain n'a relu ces lignes pour
-- le thème dans lequel elles ont été produites. Les remettre à NULL rend à la
-- campagne l'état qu'elle avait avant le défaut. Les confiances, les
-- rationales, les batch_id et les thèmes source ne sont pas touchés.
--
-- La cause est corrigée dans `QuestionNotionSuggestionRepository` : le verdict
-- ne s'inscrit plus que sur les suggestions dont `source_theme_code` vaut
-- encore le thème de la question. Cette migration ne nettoie que les lignes
-- déjà écrites.
--
-- Sur une base neuve : zéro ligne touchée, le pré-tagging n'a jamais tourné
-- ailleurs qu'en développement.
-- ============================================================================

DO $$
DECLARE effacees integer;
BEGIN
    UPDATE question_notion_suggestions s
    SET review_verdict = NULL,
        reviewed_by = NULL,
        reviewed_at = NULL
    FROM questions q
             JOIN themes t ON t.id = q.theme_id
    WHERE q.id = s.question_id
      AND s.review_verdict IS NOT NULL
      AND s.source_theme_code <> t.code;

    GET DIAGNOSTICS effacees = ROW_COUNT;
    RAISE NOTICE 'V289 : % verdicts perimes effaces.', effacees;
END $$;

-- ----------------------------------------------------------------------------
-- Le défaut est-il bien refermé ? Aucune suggestion périmée ne doit plus
-- porter de verdict. Si la migration passe et que le contrôle échoue, c'est
-- qu'une autre écriture les repose — mieux vaut le savoir ici.
-- ----------------------------------------------------------------------------
DO $$
DECLARE restantes integer;
BEGIN
    SELECT count(*) INTO restantes
    FROM question_notion_suggestions s
             JOIN questions q ON q.id = s.question_id
             JOIN themes t ON t.id = q.theme_id
    WHERE s.review_verdict IS NOT NULL AND s.source_theme_code <> t.code;

    IF restantes > 0 THEN
        RAISE EXCEPTION 'V289 : % verdicts perimes subsistent.', restantes;
    END IF;
END $$;
