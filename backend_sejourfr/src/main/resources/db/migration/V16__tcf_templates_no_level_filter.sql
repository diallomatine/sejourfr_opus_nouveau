-- V16 : retire le filtre par niveau A2/B1/B2 sur les règles des examens
-- blancs TCF.
--
-- Le test TCF IRN est unique pour tous les candidats : le niveau CECRL
-- est restitué à la fin, calculé à partir des bonnes réponses par strate
-- présentes dans le tirage. On ne filtre donc plus à la composition.
--
-- Migration destructive sur exam_template_rules des templates TCF : on
-- remplace les 3 règles "20 A2 + 20 B1 + 20 B2" par UNE seule règle
-- "60 questions tous niveaux, tous thèmes".

-- Étape 1 : on efface les règles actuelles des templates TCF seedés.
DELETE FROM exam_template_rules
WHERE exam_template_id IN (
    SELECT id FROM exam_templates
    WHERE module = 'TCF' AND slug LIKE 'tcf-%'
);

-- Étape 2 : une règle unique par template TCF, neutre en niveau et thème.
-- Les admins peuvent ensuite raffiner (par exemple "60 questions sur la
-- compréhension écrite uniquement") via la page d'édition.
INSERT INTO exam_template_rules
    (id, exam_template_id, theme_id, question_type, difficulty, question_count, position)
SELECT
    gen_random_uuid(),
    t.id,
    NULL,
    NULL,
    NULL,
    t.total_questions,
    1
FROM exam_templates t
WHERE t.module = 'TCF' AND t.slug LIKE 'tcf-%';
