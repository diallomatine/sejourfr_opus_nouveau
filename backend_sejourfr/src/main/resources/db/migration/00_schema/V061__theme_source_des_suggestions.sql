-- ============================================================================
-- V061 — UNE SUGGESTION MÉMORISE LE THÈME DE LA QUESTION AU MOMENT OÙ ELLE A
--        ÉTÉ PRODUITE.
-- ----------------------------------------------------------------------------
-- 🛑 LE DÉFAUT QUE CETTE MIGRATION FERME. Une suggestion n'est applicable que
-- dans le thème où elle a été faite : le modèle ne reçoit que les notions de ce
-- thème-là. Quand une question change de thème, sa suggestion devient caduque —
-- et jusqu'ici la base ne permettait pas de le dire. Pour une suggestion qui
-- NOMME une notion, on s'en sortait : la notion porte son thème. Mais pour
-- « aucune notion ne convient » (notion_id IS NULL), il n'y avait AUCUNE trace,
-- et l'applicabilité ne se reconstituait plus qu'en lisant le NOM DES FICHIERS
-- de la campagne. Un référentiel dont la cohérence dépend d'un nom de fichier
-- sur le poste d'un développeur n'est pas tracé.
--
-- Découvert le 2026-09-11 en contrôlant pourquoi 34 questions ressortaient
-- éligibles à une reproposition là où 20 étaient attendues.
--
-- 🛑 LE TRIGGER, PAS LA CONSIGNE. La colonne est remplie par la base, jamais
-- par l'appelant : c'est l'ordre de préférence du dépôt, une contrainte dure
-- bat une consigne. Trois écrivains touchent cette table — le script de
-- campagne, le script unitaire, l'écran d'administration. Demander à chacun de
-- penser au thème, c'est se garantir qu'un jour l'un d'eux l'oubliera, et le
-- trou resterait invisible jusqu'au prochain déplacement.
--
-- ⚠️ LE CONTENU HISTORIQUE N'EST PAS TOUCHÉ. Aucune confiance, aucune
-- rationale, aucun verdict n'est modifié : on ajoute une colonne et on la
-- remplit. La mesure de la campagne v4 reste comparable à elle-même.
-- ============================================================================

ALTER TABLE question_notion_suggestions
    ADD COLUMN source_theme_code varchar(64);

COMMENT ON COLUMN question_notion_suggestions.source_theme_code IS
    'Theme de la question AU MOMENT de la suggestion. Une suggestion n''est '
    'applicable que si ce code vaut encore le theme actuel de la question : le '
    'modele ne recoit que les notions d''un seul theme. Renseigne par trigger, '
    'jamais par l''appelant. Vaut aussi pour notion_id NULL, qui est '
    'precisement le cas ou rien d''autre ne permet de le deduire.';

-- ----------------------------------------------------------------------------
-- BACKFILL 1 — les suggestions qui NOMMENT une notion (886 lignes).
-- Déduction exacte, sans source externe : l'enum servi au modèle ne contenait
-- que les notions du thème de la question, donc le thème de la notion proposée
-- EST le thème qu'avait la question.
-- ----------------------------------------------------------------------------
UPDATE question_notion_suggestions s
SET source_theme_code = n.theme_code
FROM civic_notions n
WHERE n.id = s.notion_id AND s.source_theme_code IS NULL;

-- ----------------------------------------------------------------------------
-- BACKFILL 2 — les « aucune notion » qui ont une sœur nommée dans le MÊME lot
-- (43 lignes). Même déduction, par la sœur.
-- ----------------------------------------------------------------------------
UPDATE question_notion_suggestions a
SET source_theme_code = (
    SELECT n.theme_code FROM question_notion_suggestions b
             JOIN civic_notions n ON n.id = b.notion_id
     WHERE b.question_id = a.question_id
       AND b.batch_id IS NOT DISTINCT FROM a.batch_id
       AND b.notion_id IS NOT NULL
     LIMIT 1)
WHERE a.source_theme_code IS NULL
  AND EXISTS (SELECT 1 FROM question_notion_suggestions b
               WHERE b.question_id = a.question_id
                 AND b.batch_id IS NOT DISTINCT FROM a.batch_id
                 AND b.notion_id IS NOT NULL);

-- ----------------------------------------------------------------------------
-- BACKFILL 3 — les 31 « aucune notion » sans aucune trace en base.
--
-- Inscrites une par une, et c'est volontaire : elles viennent des fichiers de
-- lot de la campagne, une source EXTERNE à la base. La seule façon de rendre ce
-- report vérifiable et reproductible est de l'écrire, pas de le rejouer depuis
-- un répertoire qui n'existera nulle part ailleurs.
--
-- Vérifié avant rédaction : aucune de ces 31 questions n'apparaît dans deux
-- lots différents, la clé (question_id) est donc sans ambiguïté.
--
-- Sur une base neuve ces lignes n'existent pas — le pré-tagging n'a jamais
-- tourné ailleurs qu'en développement — et l'UPDATE touchera zéro ligne.
-- ----------------------------------------------------------------------------
UPDATE question_notion_suggestions s
SET source_theme_code = v.theme
FROM (VALUES
    ('f0000001-0000-0000-0000-000000000012', 'CIV_PRINCIPES'),
    ('f0000001-0000-0000-0000-000000000013', 'CIV_PRINCIPES'),
    ('f0000001-0000-0000-0000-000000000115', 'CIV_PRINCIPES'),
    ('f0000001-0000-0000-0000-000000000116', 'CIV_PRINCIPES'),
    ('f0000001-0000-0000-0000-000000000118', 'CIV_PRINCIPES'),
    ('f0000001-0000-0000-0000-000000000119', 'CIV_PRINCIPES'),
    ('f0000001-0000-0000-0000-00000000011a', 'CIV_PRINCIPES'),
    ('f0000001-0000-0000-0000-000000000123', 'CIV_PRINCIPES'),
    ('f0000001-0000-0000-0000-000000000124', 'CIV_PRINCIPES'),
    ('f0000001-0000-0000-0000-000000000125', 'CIV_PRINCIPES'),
    ('f0000001-0000-0000-0000-00000000013a', 'CIV_PRINCIPES'),
    ('f2000001-0000-0000-0000-000000000004', 'CIV_INSTITUTIONS'),
    ('f2000002-0000-0000-0000-000000000020', 'CIV_DROITS_DEVOIRS'),
    ('f2000002-0000-0000-0000-00000000004a', 'CIV_INSTITUTIONS'),
    ('f2000002-0000-0000-0000-00000000004b', 'CIV_INSTITUTIONS'),
    ('f2000002-0000-0000-0000-000000000051', 'CIV_DROITS_DEVOIRS'),
    ('f2000002-0000-0000-0000-000000000090', 'CIV_INSTITUTIONS'),
    ('f3000002-0000-0000-0000-00000000005d', 'CIV_INSTITUTIONS'),
    ('f3000002-0000-0000-0000-0000000000b5', 'CIV_INSTITUTIONS'),
    ('f3000002-0000-0000-0000-0000000000b6', 'CIV_INSTITUTIONS'),
    ('f4000002-0000-0000-0000-000000000027', 'CIV_HISTOIRE_GEO'),
    ('f4000002-0000-0000-0000-00000000005d', 'CIV_HISTOIRE_GEO'),
    ('f4000002-0000-0000-0000-00000000007c', 'CIV_HISTOIRE_GEO'),
    ('f4000002-0000-0000-0000-0000000000d4', 'CIV_HISTOIRE_GEO'),
    ('f4000002-0000-0000-0000-0000000000d7', 'CIV_HISTOIRE_GEO'),
    ('f5000002-0000-0000-0000-000000000012', 'CIV_SOCIETE'),
    ('f5000002-0000-0000-0000-00000000001c', 'CIV_SOCIETE'),
    ('f5000002-0000-0000-0000-00000000001e', 'CIV_INSTITUTIONS'),
    ('f5000002-0000-0000-0000-00000000001f', 'CIV_SOCIETE'),
    ('f5000002-0000-0000-0000-0000000000e2', 'CIV_SOCIETE'),
    ('f5000002-0000-0000-0000-0000000000e8', 'CIV_SOCIETE')
) AS v(question_id, theme)
WHERE s.question_id = v.question_id::uuid AND s.source_theme_code IS NULL;

-- ----------------------------------------------------------------------------
-- Le backfill est-il COMPLET ? Sinon la colonne ne peut pas devenir
-- obligatoire, et une suggestion sans thème d'origine est exactement le trou
-- qu'on vient de fermer. Mieux vaut échouer ici.
-- ----------------------------------------------------------------------------
DO $ctrl$
DECLARE restantes integer;
BEGIN
    SELECT count(*) INTO restantes
      FROM question_notion_suggestions WHERE source_theme_code IS NULL;
    IF restantes > 0 THEN
        RAISE EXCEPTION 'V061 : % suggestions sans theme source. Backfill incomplet.', restantes;
    END IF;
END $ctrl$;

ALTER TABLE question_notion_suggestions
    ALTER COLUMN source_theme_code SET NOT NULL;

-- ----------------------------------------------------------------------------
-- LE TRIGGER. Il remplit la colonne lui-même et IGNORE ce que l'appelant aurait
-- pu passer : le thème d'origine n'est pas une opinion, c'est un fait que seule
-- la base connaît au moment de l'écriture.
--
-- 🛑 IL SE REDÉCLENCHE SUR UNE REPROPOSITION, PAS SUR UNE RELECTURE. Le script
-- de persistance écrit en ON CONFLICT DO UPDATE : une question déplacée qui
-- reçoit un nouveau « aucune notion » retomberait sur sa ligne précédente
-- (contrainte NULLS NOT DISTINCT) et garderait un thème périmé sans ce test. Le
-- discriminant est le batch_id — un nouveau lot est une nouvelle proposition,
-- tandis qu'un verdict humain ne le change pas et ne doit surtout pas réécrire
-- l'histoire de la mesure.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION suggestion_theme_source() RETURNS trigger AS $fn$
BEGIN
    IF TG_OP = 'INSERT' OR NEW.batch_id IS DISTINCT FROM OLD.batch_id THEN
        SELECT t.code INTO NEW.source_theme_code
          FROM questions q JOIN themes t ON t.id = q.theme_id
         WHERE q.id = NEW.question_id;
    END IF;
    RETURN NEW;
END $fn$ LANGUAGE plpgsql;

CREATE TRIGGER trg_suggestion_theme_source
    BEFORE INSERT OR UPDATE ON question_notion_suggestions
    FOR EACH ROW EXECUTE FUNCTION suggestion_theme_source();
