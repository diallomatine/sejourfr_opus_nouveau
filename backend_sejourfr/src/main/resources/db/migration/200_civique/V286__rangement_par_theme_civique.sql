-- ============================================================================
-- V286 — QUARANTE QUESTIONS CIVIQUES CHANGENT DE THÈME.
-- ----------------------------------------------------------------------------
-- L'audit du corpus (V058) a trouvé une quarantaine de questions rangées dans
-- un thème qui n'est pas le leur : des symboles de la République dans
-- l'histoire, des numéros d'urgence dans les droits, le nom de la Constitution
-- dans les droits, la présomption d'innocence dans les institutions. Le
-- propriétaire a arbitré chaque flux le 2026-09-11.
--
-- 🛑 POURQUOI ÇA NE POUVAIT PAS ATTENDRE LE TAGGING.
-- Une question ne peut recevoir qu'une notion de SON thème. Laisser « Que
-- représente le drapeau français ? » dans CIV_HISTOIRE_GEO, c'est la rendre
-- définitivement intaguable : aucune notion d'histoire ne l'accepte, et
-- « pv_symboles_devise » est dans un autre thème. Ces questions auraient
-- grossi le compte des non taguées sans que personne puisse les traiter.
--
-- 🛑 LES RÈGLES DE SUBSTANCE ARBITRÉES, qui expliquent les cas limites :
--   * IMPÔTS — l'OBLIGATION DE PAYER est un devoir (CIV_DROITS_DEVOIRS) ;
--     l'ORGANISATION, la COLLECTE et le BUDGET public sont institutionnels.
--     D'où « Tout le monde paie-t-il des impôts ? » qui part vers les droits,
--     et « Comment s'appelle l'argent que l'État collecte ? » qui RESTE dans
--     les institutions.
--   * POLICE — ce que FONT les forces de l'ordre est un service
--     (CIV_SOCIETE) ; ce que je peux LEUR OPPOSER est un droit
--     (CIV_DROITS_DEVOIRS). D'où « Quel est le rôle de la police ? » qui part,
--     et « Un policier peut-il fouiller mon sac ? » qui reste.
--   * LAÏCITÉ — l'obligation de l'ÉTAT ou du SERVICE PUBLIC relève des
--     principes ; le droit INDIVIDUEL de croire ou de ne pas croire reste dans
--     les droits. 🛑 C'est pour ça que les DEUX questions « liberté de
--     conscience » de CIV_DROITS_DEVOIRS NE BOUGENT PAS : elles énoncent un
--     droit de la personne, pas une obligation de l'État.
--
-- Deux questions suivent leur notion plutôt qu'un arbitrage propre : la loi de
-- 1905 et « l'école publique est-elle laïque ? ». V058 a fusionné
-- « hg_loi_1905 » et « vs_laicite_quotidien » dans « pv_laicite » ; leurs
-- questions doivent les suivre, sinon elles deviennent intaguables.
--
-- 🛑 CE QUE CETTE MIGRATION NE CASSE PAS, et pourquoi on peut la passer.
-- Aucune table ne fige un état utilisateur PAR THÈME : le plan civique
-- recalcule tout à la lecture depuis les réponses, qui portent l'identifiant
-- de la QUESTION. Une réponse passée est donc automatiquement réattribuée au
-- nouveau thème — c'est le même choix qu'au bloc « Progression détectée », où
-- l'absence de snapshot préserve la rétroactivité. `attempts.lot_theme_id`
-- garde en revanche la trace du thème visé à l'époque, et c'est voulu :
-- l'historique d'une session ne se réécrit pas.
--
-- ⚠️ CE QUI CHANGE VRAIMENT : la taille du vivier par thème et par mention.
-- `exam_template_rules` tire N questions d'un couple (thème, difficulté). Le
-- garde-fou en fin de fichier vérifie qu'aucune règle ne devient
-- insatisfaisable ; si l'une l'était, la migration échoue au lieu de produire
-- des examens blancs tronqués en silence.
-- 🛑 POURQUOI V286 ET PAS V059, ALORS QUE C'EST LE MÊME CHANTIER QUE V058.
-- Flyway ordonne par NUMÉRO, pas par dossier. Les questions civiques sont
-- seedées par V201 à V285 (`200_civique/`) : un UPDATE numéroté dans
-- `00_schema` passerait AVANT elles et toucherait zéro ligne. Sur une base de
-- dev déjà peuplée, `out-of-order: true` le masque ; sur le Postgres embarqué
-- des tests d'intégration et sur tout environnement neuf, la migration tombe.
-- C'est le piège écrit noir sur blanc dans `backend_sejourfr/CLAUDE.md`, et le
-- garde-fou des 40 déplacements l'a attrapé. V058 reste dans `00_schema` :
-- elle ne touche que `civic_notions`, seedées par V051 au même endroit.
-- ============================================================================

DO $$
DECLARE
    deplacees integer;
    introuvables text;
BEGIN
    CREATE TEMP TABLE mouvements_v286 (enonce text PRIMARY KEY, vers varchar(64)) ON COMMIT DROP;

    INSERT INTO mouvements_v286 (enonce, vers) VALUES
    -- ---- Symboles nationaux : histoire → principes (7) -----------------------
    ('Que représente le drapeau français ?', 'CIV_PRINCIPES'),
    ('Quel coq est un emblème animal de la France ?', 'CIV_PRINCIPES'),
    ('Quel hymne national est chanté en France ?', 'CIV_PRINCIPES'),
    ('Quelle est la devise de la République française ?', 'CIV_PRINCIPES'),
    ('Quelle est la langue officielle de la France ?', 'CIV_PRINCIPES'),
    ('Quel symbole féminin représente la République française ?', 'CIV_PRINCIPES'),
    ('Quel slogan symbolise la Révolution de 1789 ?', 'CIV_PRINCIPES'),
    -- ---- Laïcité : les deux questions qui suivent leur notion (2) ------------
    ('En quelle année la loi de séparation des Églises et de l''État a-t-elle été votée ?', 'CIV_PRINCIPES'),
    ('L''école publique en France est-elle laïque ?', 'CIV_PRINCIPES'),
    -- ---- Urgences et forces de l'ordre : droits → société (9) ----------------
    ('Quel numéro d''urgence permet d''appeler le SAMU (urgences médicales) ?', 'CIV_SOCIETE'),
    ('Quel numéro d''urgence permet d''appeler les pompiers en France ?', 'CIV_SOCIETE'),
    ('Quel numéro européen permet de joindre toutes les urgences en Europe ?', 'CIV_SOCIETE'),
    ('Quels sont les numéros d''urgence essentiels en France ?', 'CIV_SOCIETE'),
    ('Quel est le numéro national d''aide aux femmes victimes de violences ?', 'CIV_SOCIETE'),
    ('Quel est le rôle de la police ?', 'CIV_SOCIETE'),
    ('Quel est le rôle de la police nationale en France ?', 'CIV_SOCIETE'),
    ('Quel est le rôle de la gendarmerie ?', 'CIV_SOCIETE'),
    ('Quel est le rôle de la gendarmerie en France ?', 'CIV_SOCIETE'),
    -- ---- Urgences et police : institutions → société (3) ---------------------
    ('Que fait la police nationale ?', 'CIV_SOCIETE'),
    ('Quel numéro permet de joindre la police en France (hors numéro européen) ?', 'CIV_SOCIETE'),
    ('Quel numéro d''urgence européen permet de joindre la police partout en Europe ?', 'CIV_SOCIETE'),
    -- ---- Conduire : droits → société (1) ------------------------------------
    ('Quel est l''âge minimum pour conduire une voiture en France ?', 'CIV_SOCIETE'),
    -- ---- Droits et devoirs mal rangés dans les institutions (7) --------------
    ('Toute personne accusée est-elle considérée comme coupable avant son jugement ?', 'CIV_DROITS_DEVOIRS'),
    ('Une personne accusée d''un délit a-t-elle le droit à un avocat ?', 'CIV_DROITS_DEVOIRS'),
    ('En France, qui est tenu de respecter la loi ?', 'CIV_DROITS_DEVOIRS'),
    ('Qui doit respecter la loi ?', 'CIV_DROITS_DEVOIRS'),
    ('Tout le monde paie-t-il des impôts en France ?', 'CIV_DROITS_DEVOIRS'),
    ('Que peut faire un citoyen face à un mauvais fonctionnement d''un service public ?', 'CIV_DROITS_DEVOIRS'),
    ('Le médiateur entre l''administration et les citoyens existe-t-il sous une forme officielle en France ?', 'CIV_DROITS_DEVOIRS'),
    -- ---- Institutions mal rangées dans les droits (7) ------------------------
    ('Comment s''appelle la Constitution actuelle de la France ?', 'CIV_INSTITUTIONS'),
    ('Quel est le nom de la Constitution actuellement en vigueur en France ?', 'CIV_INSTITUTIONS'),
    ('Que désigne la notion de ''service public'' en droit administratif français ?', 'CIV_INSTITUTIONS'),
    ('Quels principes régissent le service public en France ?', 'CIV_INSTITUTIONS'),
    ('Que prévoit le principe de subsidiarité dans l''Union européenne ?', 'CIV_INSTITUTIONS'),
    ('Quel article de la DDHC consacre le principe de la souveraineté nationale ?', 'CIV_INSTITUTIONS'),
    ('Quel impôt finance les services publics locaux ?', 'CIV_INSTITUTIONS'),
    -- ---- Institutions mal rangées dans la société (3) ------------------------
    ('Que désigne l''INSEE ?', 'CIV_INSTITUTIONS'),
    ('Quel âge permet d''être électeur en France ?', 'CIV_INSTITUTIONS'),
    ('Quelle institution européenne assure les politiques migratoires communes ?', 'CIV_INSTITUTIONS'),
    -- ---- Histoire mal rangée dans les institutions (1) -----------------------
    ('Pourquoi la IVe République a-t-elle pris fin en 1958 ?', 'CIV_HISTOIRE_GEO');

    UPDATE questions q
    SET theme_id = t.id
    FROM mouvements_v286 m
             JOIN themes t ON t.code = m.vers
    WHERE q.statement = m.enonce
      AND q.module = 'CIVIQUE'
      AND q.theme_id <> t.id;

    GET DIAGNOSTICS deplacees = ROW_COUNT;

    -- 🛑 LE GARDE-FOU NE COMPTE PAS LES LIGNES, IL VÉRIFIE L'ÉTAT D'ARRIVÉE.
    -- Un compte fixe paraissait plus strict ; il était surtout faux. Sur une
    -- base neuve, « Quel impôt finance les services publics locaux ? »
    -- n'existe pas : elle vient de `db/migration-dev/V900__seed_dev.sql`,
    -- c'est-à-dire du jeu de démonstration, pas du corpus de production. Un
    -- `IF deplacees <> 40` faisait donc tomber la migration partout sauf sur
    -- le poste du développeur — le pire des deux mondes.
    --
    -- Ce qu'on veut vraiment garantir tient en une phrase : AUCUN de ces
    -- énoncés ne doit rester dans un thème qui n'est pas le sien. Une question
    -- absente de la base ne se déplace pas, et c'est normal.
    SELECT string_agg(DISTINCT m.enonce, E'\n  - ') INTO introuvables
    FROM mouvements_v286 m
             JOIN questions q ON q.statement = m.enonce AND q.module = 'CIVIQUE'
             JOIN themes t ON t.id = q.theme_id
    WHERE t.code <> m.vers;

    IF introuvables IS NOT NULL THEN
        RAISE EXCEPTION 'V286 : des questions sont restees dans le mauvais theme :%',
            E'\n  - ' || introuvables;
    END IF;

    -- Et la dérive dans l'autre sens : un énoncé retouché depuis l'audit du
    -- 2026-09-11 ne matcherait plus rien, donc ne bougerait pas, donc
    -- passerait le contrôle ci-dessus sans être rangé. On exige que tout ce
    -- qui manque soit une question de démonstration connue.
    SELECT string_agg(m.enonce, E'\n  - ') INTO introuvables
    FROM mouvements_v286 m
    WHERE NOT EXISTS (SELECT 1 FROM questions q
                       WHERE q.statement = m.enonce AND q.module = 'CIVIQUE')
      AND m.enonce <> 'Quel impôt finance les services publics locaux ?';

    IF introuvables IS NOT NULL THEN
        RAISE EXCEPTION
            'V286 : enonces introuvables, donc non ranges. Ils ont ete retouches depuis l''audit :%',
            E'\n  - ' || introuvables;
    END IF;

    RAISE NOTICE 'V286 : % questions civiques rangees.', deplacees;
END $$;

-- ----------------------------------------------------------------------------
-- Le vivier reste-t-il suffisant pour les examens blancs ?
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
        RAISE EXCEPTION 'V286 : le rangement par theme vide un vivier d''examen blanc -> %', manque;
    END IF;
END $$;
