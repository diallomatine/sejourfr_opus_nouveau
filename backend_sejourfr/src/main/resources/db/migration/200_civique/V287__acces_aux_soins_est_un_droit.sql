-- ============================================================================
-- V287 — « L'ACCÈS AUX SOINS » EST UN DROIT, PAS UNE DÉMARCHE.
-- ----------------------------------------------------------------------------
-- Le pilote v4 (50 questions, 2026-09-11) a produit UNE SEULE erreur à haute
-- confiance, et c'est celle-ci : « Concernant l'accès aux soins, quelle
-- proposition est correcte ? » a reçu « vs_sante_soins » à 0,90 alors que sa
-- réponse — « toute personne résidant en France a droit aux soins » — énonce un
-- DROIT SOCIAL et non un parcours de soins.
--
-- 🛑 ON CORRIGE LA SOURCE, PAS LE PROMPT. Le modèle n'avait pas tort de
-- chercher dans son thème : la question ÉTAIT rangée dans « Vivre en société »,
-- où la seule notion plausible est le parcours de soins. Durcir la règle 10 du
-- prompt aurait appris au modèle à se méfier d'un rangement faux au lieu de le
-- réparer — et aurait déplacé l'erreur ailleurs. Le propriétaire a tranché le
-- 2026-09-11 : v4 est conservé tel quel, c'est la question qui bouge.
--
-- La frontière que ce déplacement applique est déjà écrite dans les deux
-- descriptions concernées : « un droit qu'on peut faire valoir devant un juge
-- reste ici ; un formulaire à déposer à un guichet part là-bas ».
--
-- ⚠️ Sa suggestion v4 REJETÉE n'est pas effacée : elle porte la trace de
-- l'erreur qui a motivé ce déplacement. On ne réécrit pas l'historique d'une
-- mesure.
-- ============================================================================

DO $$
DECLARE
    deplacees integer;
    manque text;
BEGIN
    UPDATE questions q
    SET theme_id = (SELECT id FROM themes WHERE code = 'CIV_DROITS_DEVOIRS')
    WHERE q.module = 'CIVIQUE'
      AND q.statement = 'Concernant l''accès aux soins, quelle proposition est correcte ?'
      AND q.theme_id <> (SELECT id FROM themes WHERE code = 'CIV_DROITS_DEVOIRS');

    GET DIAGNOSTICS deplacees = ROW_COUNT;

    -- L'énoncé vient du seed de production (V283) : il DOIT exister. S'il a été
    -- retouché, mieux vaut échouer que laisser croire au rangement.
    IF deplacees <> 1
        AND NOT EXISTS (
            SELECT 1 FROM questions q JOIN themes t ON t.id = q.theme_id
             WHERE q.module = 'CIVIQUE' AND t.code = 'CIV_DROITS_DEVOIRS'
               AND q.statement = 'Concernant l''accès aux soins, quelle proposition est correcte ?')
    THEN
        RAISE EXCEPTION
            'V287 : la question « acces aux soins » est introuvable. Enonce retouche depuis le pilote v4 ?';
    END IF;

    -- Même garde-fou qu'en V286 : un thème qui perd une question ne doit pas
    -- vider un vivier d'examen blanc en silence.
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
        RAISE EXCEPTION 'V287 : le deplacement vide un vivier d''examen blanc -> %', manque;
    END IF;
END $$;
