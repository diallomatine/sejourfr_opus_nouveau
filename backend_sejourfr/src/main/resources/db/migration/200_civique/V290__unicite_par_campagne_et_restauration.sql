-- ============================================================================
-- V290 — UNE SUGGESTION APPARTIENT À SA CAMPAGNE, ET DEUX CAMPAGNES COEXISTENT.
-- ----------------------------------------------------------------------------
-- 🛑 LE DÉFAUT. L'unicité portait sur (question_id, notion_id) NULLS NOT
-- DISTINCT. Elle empêchait donc une même question de garder la MÊME
-- proposition faite par DEUX campagnes différentes — et le cas le plus courant
-- est aussi le plus invisible : « aucune notion ne convient », qui n'a pas de
-- notion et entre en collision avec elle-même.
--
-- Mesuré le 2026-09-11 : après le déplacement de 20 questions et leur
-- reproposition, deux lignes de la campagne close ont été ÉCRASÉES par le
-- ON CONFLICT DO UPDATE du script de persistance. La campagne est passée de
-- 791 à 789 questions mesurées, sans que rien ne le signale. Une mesure qui
-- rétrécit en silence n'est plus une mesure.
--
-- La clé devient (question_id, batch_id, notion_id). Deux campagnes peuvent
-- désormais proposer la même chose sur la même question, y compris « aucune
-- notion », et chacune garde sa trace.
--
-- ⚠️ CE QUE ÇA CHANGE POUR LA LECTURE. Une question peut maintenant porter
-- plusieurs suggestions applicables issues de campagnes différentes. Les
-- requêtes qui servent l'écran de relecture et qui déduisent
-- VALIDATED/CORRECTED ne raisonnent donc plus « toutes les suggestions de la
-- question » mais « celles de la campagne COURANTE » — la plus récente parmi
-- les applicables. C'est fait côté Java, dans
-- QuestionNotionSuggestionRepository.
-- ============================================================================

ALTER TABLE question_notion_suggestions
    DROP CONSTRAINT uq_question_notion_suggestion;

ALTER TABLE question_notion_suggestions
    ADD CONSTRAINT uq_question_notion_suggestion
        UNIQUE NULLS NOT DISTINCT (question_id, batch_id, notion_id);

COMMENT ON CONSTRAINT uq_question_notion_suggestion ON question_notion_suggestions IS
    'Une proposition par (question, campagne, notion). NULLS NOT DISTINCT rend '
    'la cle effective sur notion_id NULL — « aucune notion ne convient » — qui '
    'sans cela se dupliquerait au sein d''une meme campagne. Le batch_id est '
    'dans la cle depuis V290 : sans lui, une campagne ecrasait la precedente.';

-- ============================================================================
-- RESTAURATION DES DEUX LIGNES ÉCRASÉES.
--
-- 🛑 Reconstruites à l'identique depuis les réponses brutes de la campagne
-- (`campagne-v4/CIV_PRINCIPES__1.reponse.json` et `__2`), archivées avant tout
-- traitement précisément pour ce genre de cas. AUCUN appel au modèle : ces
-- deux propositions ont déjà été payées le 2026-09-11, et les redemander
-- aurait produit un autre texte sous la même étiquette de campagne.
--
-- Les valeurs ci-dessous sont celles des fichiers, au centième près :
--   « Que permet le principe de laïcité ? »         AUCUNE 0,75 · CIV_PRINCIPES
--   « Quel est l'un des rôles des associations ? »  AUCUNE 0,60 · CIV_PRINCIPES
--   « Quelle école prestigieuse … hauts fonctionnaires ? » AUCUNE 0,80 · CIV_HISTOIRE_GEO
--
-- ⚠️ LA TROISIÈME N'AVAIT PAS ÉTÉ VUE au premier constat, et elle explique
-- pourquoi il faut un contrôle chiffré plutôt qu'une inspection à l'œil. Les
-- deux premières se sont écrasées « AUCUNE contre AUCUNE ». La troisième s'est
-- fait écraser par une ALTERNATIVE : la reproposition proposait
-- « inst_gouvernement » à 0,55 avec « aucune notion » en second choix à 0,50,
-- et c'est ce second choix qui est entré en collision avec la proposition
-- principale de la campagne. Une ligne perdue par un champ que personne ne
-- regarde.
--
-- ⚠️ `source_theme_code` est réécrit APRÈS l'insertion. Le trigger de V061 le
-- calcule depuis le thème ACTUEL de la question, qui n'est plus celui de la
-- campagne : ces deux questions ont depuis quitté CIV_PRINCIPES. Comme le
-- trigger ne recalcule sur UPDATE que si le batch_id change, un UPDATE à
-- batch_id constant repose la valeur d'époque sans le réveiller.
--
-- ⚠️ `created_at` est daté de la campagne, pas de maintenant. La « campagne
-- courante » d'une question se lit sur cette date : insérer ces lignes à
-- l'heure d'aujourd'hui les ferait passer pour plus récentes que la
-- reproposition, et l'écran de relecture montrerait la mauvaise.
-- ============================================================================

INSERT INTO question_notion_suggestions
    (question_id, notion_id, confidence, model, prompt_version, rationale, batch_id, created_at)
SELECT q.id, NULL, v.confiance, 'claude-sonnet-5', 'PROMPT_TAG_NOTION_v4', v.rationale,
       '2091c608-ffd1-43f3-8baa-6e8a044cb6d3'::uuid,
       (SELECT min(created_at) FROM question_notion_suggestions
         WHERE batch_id = '2091c608-ffd1-43f3-8baa-6e8a044cb6d3')
FROM (VALUES
    ('Que permet le principe de laïcité ?', 0.750,
     'Droit individuel de croire ou non → dd_libertes_limites, hors référentiel selon frontière laïcité.'),
    ('Quel est l''un des rôles des associations ?', 0.600,
     'Rôle des associations, relève plutôt de CIV_SOCIETE.'),
    ('Quelle école prestigieuse française forme les hauts fonctionnaires de l''État ?', 0.800,
     'L''ENA/INSP est une institution administrative actuelle, hors référentiel histoire-géo (relève d''un thème institutions).')
) AS v(enonce, confiance, rationale)
         JOIN questions q ON q.statement = v.enonce AND q.module = 'CIVIQUE'
WHERE EXISTS (SELECT 1 FROM question_notion_suggestions
               WHERE batch_id = '2091c608-ffd1-43f3-8baa-6e8a044cb6d3')
ON CONFLICT DO NOTHING;

UPDATE question_notion_suggestions s
SET source_theme_code = v.theme
FROM (VALUES
    ('Que permet le principe de laïcité ?', 'CIV_PRINCIPES'),
    ('Quel est l''un des rôles des associations ?', 'CIV_PRINCIPES'),
    ('Quelle école prestigieuse française forme les hauts fonctionnaires de l''État ?',
     'CIV_HISTOIRE_GEO')
) AS v(enonce, theme)
         JOIN questions q ON q.statement = v.enonce AND q.module = 'CIVIQUE'
WHERE s.question_id = q.id
  AND s.batch_id = '2091c608-ffd1-43f3-8baa-6e8a044cb6d3'
  AND s.notion_id IS NULL
  AND s.source_theme_code <> v.theme;

-- ----------------------------------------------------------------------------
-- La campagne retrouve-t-elle ses 791 questions ? Ce contrôle ne vaut que là
-- où la campagne a tourné ; ailleurs il n'y a rien à vérifier.
-- ----------------------------------------------------------------------------
DO $$
DECLARE couvertes integer;
BEGIN
    SELECT count(DISTINCT question_id) INTO couvertes
      FROM question_notion_suggestions
     WHERE batch_id = '2091c608-ffd1-43f3-8baa-6e8a044cb6d3';

    IF couvertes <> 0 AND couvertes <> 791 THEN
        RAISE EXCEPTION
            'V290 : la campagne couvre % questions, 791 attendues apres restauration.', couvertes;
    END IF;
END $$;
