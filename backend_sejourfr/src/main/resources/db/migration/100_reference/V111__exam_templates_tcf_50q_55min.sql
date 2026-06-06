-- Les examens TCF mixtes (tcf-diagnostic + tcf-mix-*) ne couvrent que les
-- QCM : compréhension orale puis écrite (EE/EO sont des épreuves dédiées).
-- L'enveloppe 60 Q / 90 min (calquée sur le TCF IRN complet) devient
-- 50 Q / 55 min : 25 CO en 20 min + 25 CE en 35 min, chaque épreuve
-- stratifiée 8 A2 + 9 B1 + 8 B2 (cf. AttemptService.drawTcfEpreuveStrata).

UPDATE exam_templates
SET total_questions  = 50,
    duration_seconds = 3300,
    subtitle         = REPLACE(subtitle, '60 questions · 90 min', '50 questions · 55 min'),
    description      = REPLACE(description, '60 questions', '50 questions')
WHERE module = 'TCF'
  AND (slug = 'tcf-diagnostic' OR slug LIKE 'tcf-mix-%');

UPDATE exam_template_rules r
SET question_count = 50
FROM exam_templates t
WHERE r.exam_template_id = t.id
  AND t.module = 'TCF'
  AND (t.slug = 'tcf-diagnostic' OR t.slug LIKE 'tcf-mix-%')
  AND r.question_count = 60;
