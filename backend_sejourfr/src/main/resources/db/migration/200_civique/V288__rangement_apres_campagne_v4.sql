-- ============================================================================
-- V288 — VINGT QUESTIONS REJOIGNENT LEUR THÈME, D'APRÈS LA CAMPAGNE v4.
-- ----------------------------------------------------------------------------
-- La campagne complète (791 questions, PROMPT_TAG_NOTION_v4) a rendu 34
-- réponses « aucune notion de ce thème ne convient ». Relues une à une par le
-- propriétaire le 2026-09-11, elles se partagent en deux : vingt questions mal
-- rangées, que cette migration replace, et quatorze vraies orphelines, qu'on
-- laisse sans notion.
--
-- 🛑 QUATORZE DES VINGT VIENNENT DE `CIV_PRINCIPES`, soit 16 % de ce thème.
-- C'est le constat le plus lourd de la campagne, et l'audit du corpus ne
-- l'avait vu qu'à moitié : je m'étais arrêté à son arithmétique — 19 questions
-- CSP, plafond de 3 notions — sans relire ses 88 énoncés un à un. Le modèle,
-- lui, les a tous lus. Un thème qui contient la date de la Ve République, le
-- droit de vote des femmes et la sanction pénale du racisme n'est pas un thème
-- de principes : c'est ce qui reste quand on ne sait pas où ranger.
--
-- 🛑 ON NE DÉPLACE PAS TOUT CE QUE LE MODÈLE DÉSIGNE. Quatre destinations
-- proposées ont été REFUSÉES par le propriétaire, chacune pour une raison de
-- fond, et les questions restent donc orphelines :
--   * le Défenseur des droits (deux questions, plus une restée en suspens au
--     pilote) n'entre pas dans « dd_police_justice » — c'est un groupe de
--     trois questions, sous le seuil éditorial de cinq, et rien ne dit qu'il
--     porte trois faits distincts. Pas de notion créée.
--   * la HATVP est une institution de contrôle de la vie publique ; la verser
--     aux droits et devoirs serait un déplacement de commodité.
--   * les deux questions sur « le service public » restent sans notion : deux
--     questions ne justifient pas d'en créer une.
--
-- ⚠️ CE QUE DEVIENNENT LES SUGGESTIONS DE CES VINGT QUESTIONS. Rien n'est
-- effacé : leur ligne v4 « aucune notion » reste en base, c'est la mesure de la
-- campagne et elle a été payée. Elle devient simplement inapplicable dans le
-- nouveau thème, ce que la règle de sélection de `batch-v4.sh` reconnaît déjà —
-- ces questions redeviendront donc éligibles à une reproposition, dans le bon
-- thème cette fois. On ne réécrit pas l'historique d'une mesure.
--
-- 🛑 AUCUN `civic_notion_id` n'est posé ici, ni pour les vingt, ni pour les
-- orphelines. Déplacer une question la rend taguable ; ça ne la tague pas.
--
-- Numérotée dans `200_civique/` et pas dans `00_schema/` : Flyway ordonne par
-- NUMÉRO, et les questions civiques sont seedées par V201 à V285.
-- ============================================================================

DO $$
DECLARE
    deplacees integer;
    restees text;
BEGIN
    CREATE TEMP TABLE mouvements_v288 (enonce text PRIMARY KEY, vers varchar(64)) ON COMMIT DROP;

    INSERT INTO mouvements_v288 (enonce, vers) VALUES
    -- ---- vers CIV_DROITS_DEVOIRS (7) ----------------------------------
    ('Quel article de la DDHC consacre le principe de la souveraineté nationale ?', 'CIV_DROITS_DEVOIRS'),
    ('L''homophobie (propos ou actes haineux envers les personnes homosexuelles) est-elle un délit ?', 'CIV_DROITS_DEVOIRS'),
    ('Le racisme est-il puni par la loi en France ?', 'CIV_DROITS_DEVOIRS'),
    ('Que permet le principe de laïcité ?', 'CIV_DROITS_DEVOIRS'),
    ('Quel droit est garanti par la laïcité ?', 'CIV_DROITS_DEVOIRS'),
    ('Quelle proposition est correcte ? La liberté d''expression :', 'CIV_DROITS_DEVOIRS'),
    ('Le tabac est-il interdit aux mineurs en France ?', 'CIV_DROITS_DEVOIRS'),
    -- ---- vers CIV_HISTOIRE_GEO (8) ------------------------------------
    ('Quel traité a créé l''Union européenne sous sa forme actuelle ?', 'CIV_HISTOIRE_GEO'),
    ('Quel traité a fondé la Communauté économique européenne en 1957 ?', 'CIV_HISTOIRE_GEO'),
    ('Combien y a-t-il eu de Républiques en France depuis 1792 ?', 'CIV_HISTOIRE_GEO'),
    ('De quand date la Constitution de la Ve République ?', 'CIV_HISTOIRE_GEO'),
    ('Depuis quand le suffrage universel masculin existe-t-il en France ?', 'CIV_HISTOIRE_GEO'),
    ('Depuis quelle année les femmes ont-elles le droit de vote en France ?', 'CIV_HISTOIRE_GEO'),
    ('En quelle année la première République française a-t-elle été proclamée ?', 'CIV_HISTOIRE_GEO'),
    ('Quel homme politique a fondé la Ve République ?', 'CIV_HISTOIRE_GEO'),
    -- ---- vers CIV_INSTITUTIONS (2) ------------------------------------
    ('Quelle école prestigieuse française forme les hauts fonctionnaires de l''État ?', 'CIV_INSTITUTIONS'),
    ('Le drapeau européen est-il aussi affiché sur les bâtiments officiels français ?', 'CIV_INSTITUTIONS'),
    -- ---- vers CIV_PRINCIPES (1) ---------------------------------------
    ('Dans quel type de régime les dirigeants sont-ils choisis par les citoyens ?', 'CIV_PRINCIPES'),
    -- ---- vers CIV_SOCIETE (2) -----------------------------------------
    ('Quel est l''un des rôles des associations ?', 'CIV_SOCIETE'),
    ('À partir de quel âge l''instruction est-elle obligatoire en France ?', 'CIV_SOCIETE');

    UPDATE questions q
    SET theme_id = t.id
    FROM mouvements_v288 m
             JOIN themes t ON t.code = m.vers
    WHERE q.statement = m.enonce
      AND q.module = 'CIVIQUE'
      AND q.theme_id <> t.id;

    GET DIAGNOSTICS deplacees = ROW_COUNT;

    -- Même garde-fou qu'en V286 : on ne compte pas les lignes, on vérifie
    -- l'état d'arrivée. Un compte fixe tombe dès qu'un énoncé n'existe pas dans
    -- l'environnement — huit questions de la base de dev viennent du seed de
    -- démonstration et n'existent pas en production.
    SELECT string_agg(DISTINCT m.enonce, E'\n  - ') INTO restees
    FROM mouvements_v288 m
             JOIN questions q ON q.statement = m.enonce AND q.module = 'CIVIQUE'
             JOIN themes t ON t.id = q.theme_id
    WHERE t.code <> m.vers;

    IF restees IS NOT NULL THEN
        RAISE EXCEPTION 'V288 : des questions sont restees dans le mauvais theme :%',
            E'\n  - ' || restees;
    END IF;

    RAISE NOTICE 'V288 : % questions civiques rangees.', deplacees;
END $$;

-- ----------------------------------------------------------------------------
-- CIV_PRINCIPES perd quatorze questions d'un coup. Le vivier des examens
-- blancs doit y survivre, sinon un examen se génère tronqué en silence.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    manque text;
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
        RAISE EXCEPTION 'V288 : le rangement vide un vivier d''examen blanc -> %', manque;
    END IF;
END $$;
