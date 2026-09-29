-- ============================================================================
-- V294 — TRENTE-SEPT DOUBLONS SORTENT DU CORPUS, ET UNE QUESTION CHANGE DE THÈME.
-- ----------------------------------------------------------------------------
-- Passe de clôture du chantier de rattachement aux notions, le 2026-09-11.
--
-- 🛑 CE QUI EST RETIRÉ, ET CE QUI NE L'EST PAS. Un doublon, ici, c'est une
-- question qui n'apporte AUCUN FAIT DISTINCT à ce qu'un candidat doit
-- apprendre. Deux critères, et un seul suffit :
--   * énoncé strictement identique ;
--   * énoncés proches (trigrammes >= 0,60) ET bonne réponse identique au mot
--     près après normalisation.
--
-- 🛑 CE QUI A ÉTÉ EXPRESSÉMENT ÉPARGNÉ, parce que la ressemblance de surface
-- ment :
--   * « Où siègent les députés ? » / « Où siègent les sénateurs ? » — une
--     lettre d'écart, deux palais. Le propriétaire l'avait signalé nommément.
--   * « Que signifie CDI ? » / « Que signifie CDD ? » — réponses opposées.
--   * « droit du sol » / « droit du sang » — idem.
--   * « durée du mandat des conseillers MUNICIPAUX » / « RÉGIONAUX » — même
--     réponse, six ans, mais deux collectivités différentes. Seul cas où une
--     réponse identique ne fait pas un doublon : exclu à la main.
--
-- ⚠️ Trois des quarante viennent du jeu de démonstration et sont traitées à
-- part, hors garde-fou : voir le commentaire dans le corps de la migration.
--
-- Dans chaque grappe, la question CONSERVÉE est choisie dans cet ordre : celle
-- qui porte déjà une notion, puis celle dont la bonne réponse est la plus
-- complète, puis la plus ancienne. Les 37 retirées portaient toutes une notion
-- — c'est normal, le tagging est terminé — et leur retrait ne perd donc aucun
-- travail humain : leur jumelle porte la même.
--
-- ⚠️ La mesure d'origine annonçait QUARANTE. Trois d'entre elles venaient du
-- seed de démonstration `db/migration-dev/V900__seed_dev.sql`, que seul le
-- profil `dev` charge : elles ne sont donc pas du corpus, et elles se retirent
-- plus bas SANS entrer dans le compte. Voir le bloc dédié.
--
-- ⚠️ `is_active = false`, PAS DE DELETE. Une question désactivée n'est plus
-- tirée mais reste lisible, et les réponses déjà données par des candidats
-- gardent une cible. Le dépôt ne supprime pas de la donnée réelle.
--
-- ============================================================================
-- Et un dernier arbitrage de taxonomie, issu de la relecture des 158 :
-- « Que peut-on dire de l'accès aux soins en France ? » — réponse : « garanti
-- à tous les résidents réguliers ». C'est le DROIT à la santé, pas le parcours
-- de soins, et la frontière de « vs_sante_soins » l'envoie explicitement vers
-- « dd_droits_sociaux ». Sa jumelle avait déjà été déplacée pour cette raison
-- (V287) ; celle-ci suit.
-- ============================================================================

DO $$
DECLARE
    retirees integer;
    manque text;
BEGIN
    CREATE TEMP TABLE doublons_v294 (question_id uuid PRIMARY KEY) ON COMMIT DROP;
    INSERT INTO doublons_v294 (question_id) VALUES
    ('f3000001-0000-0000-0000-000000000004'),
    ('f3000001-0000-0000-0000-000000000006'),
    ('f4000001-0000-0000-0000-00000000002d'),
    ('f4000000-0000-0000-0000-00000000002c'),
    ('f4000001-0000-0000-0000-000000000026'),
    ('f4000001-0000-0000-0000-00000000001f'),
    ('f4000001-0000-0000-0000-00000000001d'),
    ('f4000001-0000-0000-0000-00000000001b'),
    ('f4000001-0000-0000-0000-000000000010'),
    ('f4000001-0000-0000-0000-000000000022'),
    ('f4000002-0000-0000-0000-000000000037'),
    ('f0000001-0000-0000-0000-00000000011a'),
    ('f4000001-0000-0000-0000-000000000003'),
    ('f4000001-0000-0000-0000-000000000001'),
    ('f4000001-0000-0000-0000-000000000019'),
    ('f4000001-0000-0000-0000-000000000018'),
    ('f4000001-0000-0000-0000-00000000002f'),
    ('f4000001-0000-0000-0000-00000000001a'),
    ('f4000000-0000-0000-0000-00000000002b'),
    ('f4000000-0000-0000-0000-000000000029'),
    ('f4000001-0000-0000-0000-00000000000c'),
    ('f4000000-0000-0000-0000-000000000023'),
    ('f4000001-0000-0000-0000-000000000024'),
    ('f4000000-0000-0000-0000-000000000027'),
    ('f4000001-0000-0000-0000-000000000028'),
    ('f4000001-0000-0000-0000-000000000021'),
    ('f4000001-0000-0000-0000-000000000025'),
    ('f2000001-0000-0000-0000-000000000021'),
    ('f2000001-0000-0000-0000-00000000000f'),
    ('f4000002-0000-0000-0000-000000000026'),
    ('f4000002-0000-0000-0000-000000000009'),
    ('f5000001-0000-0000-0000-000000000010'),
    ('f3000002-0000-0000-0000-000000000003'),
    ('f5000001-0000-0000-0000-000000000002'),
    ('f3000002-0000-0000-0000-000000000004'),
    ('f5000001-0000-0000-0000-000000000001'),
    ('f3000002-0000-0000-0000-000000000005');

    UPDATE questions q SET is_active = false
    FROM doublons_v294 d
    WHERE q.id = d.question_id AND q.is_active = true;

    GET DIAGNOSTICS retirees = ROW_COUNT;

    -- Sur une base neuve toutes existent ; ailleurs, aucune n'existe. Entre les
    -- deux, quelque chose a bougé depuis la mesure et il faut le savoir.
    IF retirees <> 0 AND retirees <> 37 THEN
        RAISE EXCEPTION 'V294 : % doublons retires, 37 attendus.', retirees;
    END IF;

    -- 🛑 LES TROIS DERNIERS NE SONT PAS COMPTÉS, ET C'EST LA CORRECTION.
    -- « Quelle est la devise de la République française ? », « durée du mandat
    -- présidentiel » et « année de la Révolution française » ne viennent PAS du
    -- corpus : ce sont des questions du seed de démonstration
    -- `db/migration-dev/V900__seed_dev.sql`, que seul le profil `dev` charge
    -- (`application-dev.yaml` ajoute `classpath:db/migration-dev`).
    --
    -- Les compter dans le 40 rendait cette migration VERTE sur une seule base au
    -- monde — celle du poste où V900 avait déjà tourné — et ROUGE partout
    -- ailleurs : en test (profil `test`, où V900 n'existe pas) comme en
    -- production. Et même sur une base `dev` neuve, puisque Flyway ordonne par
    -- NUMÉRO : V294 passe avant V900, donc les trois n'y sont pas encore.
    --
    -- Elles restent désactivées quand elles sont là — ce sont bien des doublons
    -- du corpus réel — mais SANS garde : leur absence est le cas normal.
    UPDATE questions SET is_active = false
    WHERE id IN ('c0000001-0000-0000-0000-000000000001',
                 'c0000002-0000-0000-0000-000000000002',
                 'c0000004-0000-0000-0000-000000000001')
      AND is_active = true;

    UPDATE questions q
    SET theme_id = (SELECT id FROM themes WHERE code = 'CIV_DROITS_DEVOIRS'),
        civic_notion_id = (SELECT id FROM civic_notions WHERE code = 'dd_droits_sociaux')
    WHERE q.module = 'CIVIQUE'
      AND q.statement = 'Que peut-on dire de l''accès aux soins en France ?'
      AND q.theme_id <> (SELECT id FROM themes WHERE code = 'CIV_DROITS_DEVOIRS');

    -- 🛑 Le vivier des examens blancs survit-il au retrait de 40 questions ?
    SELECT string_agg(format('%s/%s : %s demandees, %s disponibles',
                             t.code, coalesce(r.difficulty, 'toutes'),
                             r.question_count, coalesce(v.n, 0)), ' | ')
    INTO manque
    FROM exam_template_rules r
             JOIN themes t ON t.id = r.theme_id
             LEFT JOIN LATERAL (
        SELECT count(*) AS n FROM questions q
        WHERE q.theme_id = r.theme_id AND q.is_active = true
          AND (r.difficulty IS NULL OR q.difficulty = r.difficulty)
          AND (r.question_type IS NULL OR q.question_type = r.question_type)
        ) v ON true
    WHERE t.code LIKE 'CIV%' AND coalesce(v.n, 0) < r.question_count;

    IF manque IS NOT NULL THEN
        RAISE EXCEPTION 'V294 : la deduplication vide un vivier d''examen blanc -> %', manque;
    END IF;

    RAISE NOTICE 'V294 : % doublons retires du corpus.', retirees;
END $$;
