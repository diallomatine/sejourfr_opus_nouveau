-- ============================================================================
-- V293 — 366 TAGS POSÉS AUTOMATIQUEMENT AU SEUIL DE CONFIANCE ≥ 0,95.
-- ----------------------------------------------------------------------------
-- 🛑 CE SONT DES TAGS AUTOMATIQUES, PAS DES VALIDATIONS HUMAINES, et la base
-- doit continuer à le dire. `review_verdict` reste NULL sur ces 366 lignes :
-- personne ne les a relues, et écrire VALIDATED ferait entrer 366 succès
-- fictifs dans la mesure de qualité du modèle — celle-là même qui a servi à
-- choisir le seuil. Une métrique qui se nourrit de ses propres décisions ne
-- mesure plus rien.
--
-- 🛑 D'OÙ VIENT LE SEUIL, ET POURQUOI 0,95 ET NON 0,90. Échantillon de 100
-- suggestions stratifié sur les 5 thèmes et les 2 tranches, relu à la main le
-- 2026-09-11 :
--     ≥ 0,95      : 71 / 71   = 100 %
--     0,90 – 0,94 : 28 / 29   = 96,6 %
-- La seule erreur de l'échantillon était à 0,90. Le propriétaire a donc porté
-- le seuil d'acceptation en masse de 0,90 à 0,95 : à 0,90, les 158 questions
-- de la tranche basse auraient été posées sur la foi d'un taux mesuré sur 29
-- cas seulement.
--
-- 🛑 CE QUI EST EXCLU, ET POURQUOI CHAQUE EXCLUSION COMPTE :
--   * `notion_id IS NULL` — « aucune notion ne convient » n'est pas un tag.
--     Zéro cas ici, aucune réponse de ce type n'atteint 0,95 dans la campagne.
--   * `review_verdict IS NOT NULL` — une question déjà relue appartient à son
--     relecteur, pas à un seuil.
--   * `civic_notion_id IS NOT NULL` — une décision déjà prise ne se réécrit pas.
--   * `source_theme_code <> theme actuel` — une suggestion produite pour un
--     autre référentiel ne vaut rien ici, quelle que soit sa confiance.
--
-- ⚠️ COMMENT LES RETROUVER PLUS TARD. Leur signature est « taguée, sans
-- verdict humain ». Elle n'est pas tout à fait exclusive : les questions
-- déplacées de thème puis taguées à la main par leur relecteur la portent
-- aussi, faute de suggestion applicable à juger. La requête qui les isole
-- vraiment ajoute la confiance :
--     tag posé  ET  aucun verdict  ET  suggestion applicable >= 0,95
--     pointant vers la notion effectivement posée.
-- ============================================================================

DO $$
DECLARE
    candidates integer;
    posees integer;
    verdicts integer;
BEGIN
    CREATE TEMP TABLE tags_v293 ON COMMIT DROP AS
    WITH courante AS (
        SELECT DISTINCT ON (s.question_id)
               s.question_id, s.notion_id, s.confidence, s.review_verdict
          FROM question_notion_suggestions s
                   JOIN questions q ON q.id = s.question_id
                   JOIN themes t ON t.id = q.theme_id
         WHERE s.prompt_version = 'PROMPT_TAG_NOTION_v4'
           AND s.source_theme_code = t.code
         ORDER BY s.question_id, s.created_at DESC, s.confidence DESC, s.notion_id NULLS LAST
    )
    SELECT c.question_id, c.notion_id
      FROM courante c
               JOIN questions q ON q.id = c.question_id
     WHERE c.confidence >= 0.95
       AND c.notion_id IS NOT NULL
       AND c.review_verdict IS NULL
       AND q.civic_notion_id IS NULL;

    SELECT count(*) INTO candidates FROM tags_v293;

    -- 🛑 Le compte est VÉRIFIÉ AVANT d'écrire. Sur une base neuve la campagne
    -- n'a jamais tourné et il n'y a rien à poser ; partout ailleurs, un écart
    -- signifie que l'état a bougé depuis le contrôle du 2026-09-11, et poser
    -- un nombre de tags different de celui qui a ete annonce serait le
    -- contraire d'un audit.
    IF candidates <> 0 AND candidates <> 366 THEN
        RAISE EXCEPTION
            'V293 : % candidates au seuil 0,95, 366 attendues. Etat modifie depuis le controle.',
            candidates;
    END IF;

    UPDATE questions q
    SET civic_notion_id = t.notion_id
    FROM tags_v293 t
    WHERE q.id = t.question_id
      AND q.civic_notion_id IS NULL;

    GET DIAGNOSTICS posees = ROW_COUNT;

    IF posees <> candidates THEN
        RAISE EXCEPTION 'V293 : % tags poses pour % candidates.', posees, candidates;
    END IF;

    -- 🛑 Et APRÈS : aucune de ces questions ne doit avoir gagné un verdict au
    -- passage. C'est toute la différence entre « le modèle en était sûr » et
    -- « un humain l'a relu ».
    SELECT count(*) INTO verdicts
      FROM question_notion_suggestions s
               JOIN tags_v293 t ON t.question_id = s.question_id
     WHERE s.review_verdict IS NOT NULL;

    IF verdicts > 0 THEN
        RAISE EXCEPTION
            'V293 : % suggestions de ces questions portent un verdict humain. Ce lot doit rester automatique.',
            verdicts;
    END IF;

    RAISE NOTICE 'V293 : % tags automatiques poses au seuil 0,95.', posees;
END $$;
