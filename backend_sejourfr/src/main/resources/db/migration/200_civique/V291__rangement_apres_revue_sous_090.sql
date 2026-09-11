-- ============================================================================
-- V291 — TREIZE QUESTIONS CHANGENT DE THÈME APRÈS LA REVUE DES SUGGESTIONS
--        SOUS 0,90.
-- ----------------------------------------------------------------------------
-- Relecture humaine des 133 suggestions de confiance inférieure à 0,90
-- (campagne PROMPT_TAG_NOTION_v4), le 2026-09-11. Sur 133 : 115 validations,
-- 4 corrections dans le thème, 1 orpheline, et ces 13 déplacements.
--
-- 🛑 CLÉ SUR L'IDENTIFIANT, PAS SUR L'ÉNONCÉ, contrairement à V286 et V288.
-- Deux couples de questions partagent un énoncé au mot près en ne différant
-- que par leur mention — « En quelle année la loi de séparation des Églises et
-- de l'État a-t-elle été votée ? » existe en CR et en NAT, et les deux sont
-- dans cette liste. Un UPDATE par énoncé les traiterait ensemble par accident ;
-- ici ça tombe juste, mais le jour où deux jumelles iraient à deux endroits
-- différents, la migration se tromperait sans rien dire. Ces identifiants sont
-- ceux des lots de seed (V201 à V285), stables dans tous les environnements.
--
-- 🛑 AUCUN TAG N'EST POSÉ ICI, et c'est le point du geste. La suggestion que
-- l'humain a lue a été produite dans l'ANCIEN thème : elle est inapplicable
-- dans le nouveau, et recopier la notion retenue à partir d'elle reviendrait à
-- faire confiance à une proposition faite pour un autre programme. Le tag se
-- pose après, par le flux humain normal, une fois la question dans son thème.
--
-- ⚠️ La suggestion d'origine n'est pas effacée : `source_theme_code` (V061) la
-- marque périmée toute seule, et elle reste la mesure de la campagne.
--
-- ⚠️ DEUX DE CES QUESTIONS REVIENNENT SUR UN DÉPLACEMENT DE V286. La loi de
-- 1905 avait été versée à CIV_PRINCIPES parce qu'elle suivait sa notion
-- « hg_loi_1905 », fusionnée dans « pv_laicite ». La relecture tranche
-- autrement, et la description fait autorité : datée, la loi de 1905 est
-- l'acquisition d'un droit, donc « hg_conquetes_droits ». Revenir sur une
-- décision n'est pas une incohérence quand la raison est écrite.
-- ============================================================================

DO $$
DECLARE
    deplacees integer;
    restees text;
BEGIN
    CREATE TEMP TABLE mouvements_v291 (question_id uuid PRIMARY KEY, vers varchar(64)) ON COMMIT DROP;

    INSERT INTO mouvements_v291 (question_id, vers) VALUES
    -- ---- vers CIV_DROITS_DEVOIRS (6) ------------------------------------
    ('f0000001-0000-0000-0000-00000000013b', 'CIV_DROITS_DEVOIRS'), -- école gratuite
    ('f0000001-0000-0000-0000-000000000130', 'CIV_DROITS_DEVOIRS'), -- droit de grève
    ('f0000001-0000-0000-0000-00000000012f', 'CIV_DROITS_DEVOIRS'), -- liberté syndicale
    ('f0000001-0000-0000-0000-00000000011e', 'CIV_DROITS_DEVOIRS'), -- mariage pour tous
    ('f0000001-0000-0000-0000-00000000012e', 'CIV_DROITS_DEVOIRS'), -- liberté d'aller et venir
    -- ---- vers CIV_HISTOIRE_GEO (4) ---------------------------------------
    ('f4000002-0000-0000-0000-00000000003c', 'CIV_HISTOIRE_GEO'),   -- loi de 1905 (CR)
    ('f0000001-0000-0000-0000-00000000001f', 'CIV_HISTOIRE_GEO'),   -- loi de 1905 (NAT)
    ('f2000000-0000-0000-0000-00000000002b', 'CIV_HISTOIRE_GEO'),   -- pays fondateur de l'UE
    ('f2000001-0000-0000-0000-00000000002b', 'CIV_HISTOIRE_GEO'),   -- fondateur de la CEE
    -- ---- vers CIV_PRINCIPES (4) ------------------------------------------
    ('f2000000-0000-0000-0000-000000000004', 'CIV_PRINCIPES'),      -- dirigeants élus
    ('f3000002-0000-0000-0000-000000000079', 'CIV_PRINCIPES'),      -- égalité réelle
    ('f3000002-0000-0000-0000-00000000005f', 'CIV_PRINCIPES'),      -- égalité hommes-femmes
    ('f2000002-0000-0000-0000-00000000008e', 'CIV_PRINCIPES');      -- égal accès aux mandats

    UPDATE questions q
    SET theme_id = t.id
    FROM mouvements_v291 m
             JOIN themes t ON t.code = m.vers
    WHERE q.id = m.question_id
      AND q.module = 'CIVIQUE'
      AND q.theme_id <> t.id;

    GET DIAGNOSTICS deplacees = ROW_COUNT;

    -- Même garde-fou qu'en V286 : on ne compte pas les lignes, on vérifie
    -- l'état d'arrivée. Une question absente de l'environnement ne se déplace
    -- pas, et ce n'est pas une erreur.
    SELECT string_agg(DISTINCT left(q.statement, 60), E'\n  - ') INTO restees
    FROM mouvements_v291 m
             JOIN questions q ON q.id = m.question_id
             JOIN themes t ON t.id = q.theme_id
    WHERE t.code <> m.vers;

    IF restees IS NOT NULL THEN
        RAISE EXCEPTION 'V291 : des questions sont restees dans le mauvais theme :%',
            E'\n  - ' || restees;
    END IF;

    RAISE NOTICE 'V291 : % questions civiques rangees.', deplacees;
END $$;

-- ----------------------------------------------------------------------------
-- Le vivier des examens blancs survit-il ? CIV_PRINCIPES en perd cinq et en
-- gagne quatre ; CIV_INSTITUTIONS en perd quatre.
-- ----------------------------------------------------------------------------
DO $$
DECLARE manque text;
BEGIN
    SELECT string_agg(format('%s/%s : %s demandees, %s disponibles',
                             t.code, coalesce(r.difficulty, 'toutes'),
                             r.question_count, coalesce(v.n, 0)), ' | ')
    INTO manque
    FROM exam_template_rules r
             JOIN themes t ON t.id = r.theme_id
             LEFT JOIN LATERAL (
        SELECT count(*) AS n FROM questions q
        WHERE q.theme_id = r.theme_id
          AND q.is_active = true
          AND (r.difficulty IS NULL OR q.difficulty = r.difficulty)
          AND (r.question_type IS NULL OR q.question_type = r.question_type)
        ) v ON true
    WHERE t.code LIKE 'CIV%'
      AND coalesce(v.n, 0) < r.question_count;

    IF manque IS NOT NULL THEN
        RAISE EXCEPTION 'V291 : le rangement vide un vivier d''examen blanc -> %', manque;
    END IF;
END $$;
