-- V9 : seed des 40 examens blancs (20 CIVIQUE + 20 TCF) qui constituent la
-- vitrine commerciale. Le premier de chaque module est gratuit, les 19
-- suivants sont premium et alimentent la conversion vers l'abonnement.
--
-- Stratégie B (slots) : les ExamTemplateRule décrivent une composition par
-- thème/difficulté/type, les questions sont tirées à la volée à chaque
-- démarrage. Aucun ID de question n'est figé ici, ce qui rend les templates
-- auto-adaptatifs quand le pool de questions grandit.
--
-- Conventions :
-- - Civique : 40 questions, 2700 s (45 min), seuil 32/40.
-- - TCF     : 60 questions, 5400 s (90 min), seuil 0 (l'évaluation se fait
--             via le niveau CECRL atteint, pas via le score binaire).
-- - target_procedure NULL → template "tous parcours" (civique).
-- - target_level     NULL → template "diagnostic" (TCF).
-- - Thèmes civique (rappel V2/V5) :
--     11111111-0000-0000-0000-000000000001  CIV_PRINCIPES
--     11111111-0000-0000-0000-000000000002  CIV_INSTITUTIONS
--     11111111-0000-0000-0000-000000000003  CIV_DROITS_DEVOIRS
--     11111111-0000-0000-0000-000000000004  CIV_HISTOIRE_GEO
--     11111111-0000-0000-0000-000000000005  CIV_SOCIETE

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ===========================================================================
-- 20 templates CIVIQUE
-- ===========================================================================

INSERT INTO exam_templates
    (id, slug, module, target_level, target_procedure, name, subtitle, description,
     duration_seconds, total_questions, passing_score, is_free, is_published, position)
VALUES
-- Position 1 : examen GRATUIT, tous parcours
('50000000-cccc-0000-0000-000000000001', 'civique-decouverte',
 'CIVIQUE', NULL, NULL,
 'Examen civique — Découverte',
 '40 questions · 45 min · Tous parcours · Gratuit',
 'Premier examen blanc 100 % gratuit pour découvrir le format de l''épreuve civique sur les 5 thématiques officielles, tous parcours confondus.',
 2700, 40, 32, TRUE, TRUE, 1),

-- Positions 2-5 : CSP (titre de séjour pluriannuel)
('50000000-cccc-0000-0000-000000000002', 'civique-csp-mix-01',
 'CIVIQUE', NULL, 'CSP',
 'Examen civique CSP — Mix complet n°1',
 '40 questions · 45 min · CSP',
 'Examen blanc complet ciblé CSP : 8 questions par thématique officielle, sélectionnées dans le niveau attendu pour un titre de séjour.',
 2700, 40, 32, FALSE, TRUE, 2),

('50000000-cccc-0000-0000-000000000003', 'civique-csp-institutions',
 'CIVIQUE', NULL, 'CSP',
 'Examen civique CSP — Focus Institutions',
 '40 questions · 45 min · CSP',
 'Plongée intensive sur le système institutionnel et politique français au niveau CSP.',
 2700, 40, 32, FALSE, TRUE, 3),

('50000000-cccc-0000-0000-000000000004', 'civique-csp-histoire',
 'CIVIQUE', NULL, 'CSP',
 'Examen civique CSP — Focus Histoire & Géographie',
 '40 questions · 45 min · CSP',
 'Repères historiques, géographiques et culturels essentiels pour le titre de séjour.',
 2700, 40, 32, FALSE, TRUE, 4),

('50000000-cccc-0000-0000-000000000005', 'civique-csp-societe',
 'CIVIQUE', NULL, 'CSP',
 'Examen civique CSP — Focus Vivre en société',
 '40 questions · 45 min · CSP',
 'Vie quotidienne, services publics et vivre-ensemble au niveau CSP.',
 2700, 40, 32, FALSE, TRUE, 5),

-- Positions 6-11 : CR (résident)
('50000000-cccc-0000-0000-000000000006', 'civique-cr-mix-01',
 'CIVIQUE', NULL, 'CR',
 'Examen civique CR — Mix complet n°1',
 '40 questions · 45 min · CR',
 'Examen blanc complet ciblé CR (carte de résident) sur les 5 thématiques officielles.',
 2700, 40, 32, FALSE, TRUE, 6),

('50000000-cccc-0000-0000-000000000007', 'civique-cr-mix-02',
 'CIVIQUE', NULL, 'CR',
 'Examen civique CR — Mix complet n°2',
 '40 questions · 45 min · CR',
 'Variante du mix CR pour renforcer la révision : nouvelles questions tirées à chaque tentative.',
 2700, 40, 32, FALSE, TRUE, 7),

('50000000-cccc-0000-0000-000000000008', 'civique-cr-institutions',
 'CIVIQUE', NULL, 'CR',
 'Examen civique CR — Focus Institutions',
 '40 questions · 45 min · CR',
 'Approfondissement du système institutionnel français pour la carte de résident.',
 2700, 40, 32, FALSE, TRUE, 8),

('50000000-cccc-0000-0000-000000000009', 'civique-cr-droits',
 'CIVIQUE', NULL, 'CR',
 'Examen civique CR — Focus Droits et devoirs',
 '40 questions · 45 min · CR',
 'Charte des droits et devoirs du citoyen français, au niveau attendu pour la CR.',
 2700, 40, 32, FALSE, TRUE, 9),

('50000000-cccc-0000-0000-000000000010', 'civique-cr-histoire',
 'CIVIQUE', NULL, 'CR',
 'Examen civique CR — Focus Histoire & Géographie',
 '40 questions · 45 min · CR',
 'Histoire, géographie et patrimoine culturel français pour la carte de résident.',
 2700, 40, 32, FALSE, TRUE, 10),

('50000000-cccc-0000-0000-000000000011', 'civique-cr-societe',
 'CIVIQUE', NULL, 'CR',
 'Examen civique CR — Focus Vivre en société',
 '40 questions · 45 min · CR',
 'Vie quotidienne et services publics au niveau CR.',
 2700, 40, 32, FALSE, TRUE, 11),

-- Positions 12-16 : NAT (naturalisation)
('50000000-cccc-0000-0000-000000000012', 'civique-nat-mix-01',
 'CIVIQUE', NULL, 'NAT',
 'Examen civique NAT — Mix complet n°1',
 '40 questions · 45 min · Naturalisation',
 'Examen blanc complet niveau naturalisation, le plus exigeant des trois parcours civiques.',
 2700, 40, 32, FALSE, TRUE, 12),

('50000000-cccc-0000-0000-000000000013', 'civique-nat-mix-02',
 'CIVIQUE', NULL, 'NAT',
 'Examen civique NAT — Mix complet n°2',
 '40 questions · 45 min · Naturalisation',
 'Variante du mix naturalisation pour préparer l''entretien d''assimilation.',
 2700, 40, 32, FALSE, TRUE, 13),

('50000000-cccc-0000-0000-000000000014', 'civique-nat-institutions',
 'CIVIQUE', NULL, 'NAT',
 'Examen civique NAT — Focus Institutions',
 '40 questions · 45 min · Naturalisation',
 'Maîtrise du système institutionnel attendue pour devenir Français.',
 2700, 40, 32, FALSE, TRUE, 14),

('50000000-cccc-0000-0000-000000000015', 'civique-nat-droits',
 'CIVIQUE', NULL, 'NAT',
 'Examen civique NAT — Focus Droits et devoirs',
 '40 questions · 45 min · Naturalisation',
 'Droits et devoirs du citoyen, exigés pour la naturalisation.',
 2700, 40, 32, FALSE, TRUE, 15),

('50000000-cccc-0000-0000-000000000016', 'civique-nat-histoire',
 'CIVIQUE', NULL, 'NAT',
 'Examen civique NAT — Focus Histoire & Géographie',
 '40 questions · 45 min · Naturalisation',
 'Histoire et géographie de France au niveau naturalisation.',
 2700, 40, 32, FALSE, TRUE, 16),

-- Positions 17-20 : tous parcours (mixant CSP/CR/NAT)
('50000000-cccc-0000-0000-000000000017', 'civique-tous-mix-01',
 'CIVIQUE', NULL, NULL,
 'Examen civique tous parcours — Mix n°1',
 '40 questions · 45 min · Tous parcours',
 'Pour les indécis ou pour s''entraîner large : un mix sur les 3 parcours.',
 2700, 40, 32, FALSE, TRUE, 17),

('50000000-cccc-0000-0000-000000000018', 'civique-tous-mix-02',
 'CIVIQUE', NULL, NULL,
 'Examen civique tous parcours — Mix n°2',
 '40 questions · 45 min · Tous parcours',
 'Deuxième mix multi-parcours pour varier les sessions de révision.',
 2700, 40, 32, FALSE, TRUE, 18),

('50000000-cccc-0000-0000-000000000019', 'civique-principes',
 'CIVIQUE', NULL, NULL,
 'Examen civique — Focus Principes et valeurs',
 '40 questions · 45 min · Tous parcours',
 'Liberté, égalité, fraternité, laïcité : les principes fondateurs de la République.',
 2700, 40, 32, FALSE, TRUE, 19),

('50000000-cccc-0000-0000-000000000020', 'civique-marathon',
 'CIVIQUE', NULL, NULL,
 'Examen civique — Marathon Institutions + Histoire',
 '40 questions · 45 min · Tous parcours',
 'Combo des deux thématiques structurantes : système politique et repères historiques.',
 2700, 40, 32, FALSE, TRUE, 20);

-- ---------------------------------------------------------------------------
-- Règles civique : compositions des 20 templates
-- ---------------------------------------------------------------------------

-- Mix complet "tous thèmes" : 8 questions × 5 thèmes = 40
-- Décliné pour : découverte (no diff), CSP, CR×2, NAT×2, tous parcours×2 → 8 templates
DO $$
DECLARE
    t_id  UUID;
    t_diff TEXT;
    mix_templates JSONB := '[
        {"id":"50000000-cccc-0000-0000-000000000001", "diff":null},
        {"id":"50000000-cccc-0000-0000-000000000002", "diff":"CSP"},
        {"id":"50000000-cccc-0000-0000-000000000006", "diff":"CR"},
        {"id":"50000000-cccc-0000-0000-000000000007", "diff":"CR"},
        {"id":"50000000-cccc-0000-0000-000000000012", "diff":"NAT"},
        {"id":"50000000-cccc-0000-0000-000000000013", "diff":"NAT"},
        {"id":"50000000-cccc-0000-0000-000000000017", "diff":null},
        {"id":"50000000-cccc-0000-0000-000000000018", "diff":null}
    ]'::jsonb;
    item JSONB;
BEGIN
    FOR item IN SELECT * FROM jsonb_array_elements(mix_templates) LOOP
        t_id := (item->>'id')::uuid;
        t_diff := item->>'diff';
        INSERT INTO exam_template_rules (id, exam_template_id, theme_id, question_type, difficulty, question_count, position)
        VALUES
            (gen_random_uuid(), t_id, '11111111-0000-0000-0000-000000000001', NULL, t_diff, 8, 1),
            (gen_random_uuid(), t_id, '11111111-0000-0000-0000-000000000002', NULL, t_diff, 8, 2),
            (gen_random_uuid(), t_id, '11111111-0000-0000-0000-000000000003', NULL, t_diff, 8, 3),
            (gen_random_uuid(), t_id, '11111111-0000-0000-0000-000000000004', NULL, t_diff, 8, 4),
            (gen_random_uuid(), t_id, '11111111-0000-0000-0000-000000000005', NULL, t_diff, 8, 5);
    END LOOP;
END $$;

-- Focus thème unique : 1 règle, 40 questions sur un thème + une difficulté
INSERT INTO exam_template_rules (id, exam_template_id, theme_id, question_type, difficulty, question_count, position)
VALUES
-- CSP focus
(gen_random_uuid(), '50000000-cccc-0000-0000-000000000003', '11111111-0000-0000-0000-000000000002', NULL, 'CSP', 40, 1), -- Institutions
(gen_random_uuid(), '50000000-cccc-0000-0000-000000000004', '11111111-0000-0000-0000-000000000004', NULL, 'CSP', 40, 1), -- Histoire
(gen_random_uuid(), '50000000-cccc-0000-0000-000000000005', '11111111-0000-0000-0000-000000000005', NULL, 'CSP', 40, 1), -- Société
-- CR focus
(gen_random_uuid(), '50000000-cccc-0000-0000-000000000008', '11111111-0000-0000-0000-000000000002', NULL, 'CR',  40, 1), -- Institutions
(gen_random_uuid(), '50000000-cccc-0000-0000-000000000009', '11111111-0000-0000-0000-000000000003', NULL, 'CR',  40, 1), -- Droits
(gen_random_uuid(), '50000000-cccc-0000-0000-000000000010', '11111111-0000-0000-0000-000000000004', NULL, 'CR',  40, 1), -- Histoire
(gen_random_uuid(), '50000000-cccc-0000-0000-000000000011', '11111111-0000-0000-0000-000000000005', NULL, 'CR',  40, 1), -- Société
-- NAT focus
(gen_random_uuid(), '50000000-cccc-0000-0000-000000000014', '11111111-0000-0000-0000-000000000002', NULL, 'NAT', 40, 1), -- Institutions
(gen_random_uuid(), '50000000-cccc-0000-0000-000000000015', '11111111-0000-0000-0000-000000000003', NULL, 'NAT', 40, 1), -- Droits
(gen_random_uuid(), '50000000-cccc-0000-0000-000000000016', '11111111-0000-0000-0000-000000000004', NULL, 'NAT', 40, 1), -- Histoire
-- Tous parcours focus
(gen_random_uuid(), '50000000-cccc-0000-0000-000000000019', '11111111-0000-0000-0000-000000000001', NULL, NULL,  40, 1); -- Principes

-- Marathon Institutions + Histoire (template 20) : 2 règles
INSERT INTO exam_template_rules (id, exam_template_id, theme_id, question_type, difficulty, question_count, position)
VALUES
(gen_random_uuid(), '50000000-cccc-0000-0000-000000000020', '11111111-0000-0000-0000-000000000002', NULL, NULL, 20, 1),
(gen_random_uuid(), '50000000-cccc-0000-0000-000000000020', '11111111-0000-0000-0000-000000000004', NULL, NULL, 20, 2);

-- ===========================================================================
-- 20 templates TCF
-- ===========================================================================
-- Stratégie : 1 examen unique « diagnostic » qui mixe 20 questions A2 + 20 B1
-- + 20 B2 = 60 questions, sans contrainte de thème (le pool TCF actuel ne
-- contient que de la compréhension écrite, mais le tirage s'auto-adaptera
-- quand on ajoutera de la CO et de la structure).
--
-- Les 20 templates ont des règles identiques en mode dev (stock = 96 questions,
-- chevauchements assumés). L'admin pourra plus tard différencier la
-- composition de chaque template au fur et à mesure que le pool grandit.

INSERT INTO exam_templates
    (id, slug, module, target_level, target_procedure, name, subtitle, description,
     duration_seconds, total_questions, passing_score, is_free, is_published, position)
VALUES
('50000000-aaaa-0000-0000-000000000001', 'tcf-diagnostic',
 'TCF', NULL, NULL,
 'TCF IRN — Diagnostic gratuit',
 '60 questions · 90 min · Gratuit',
 'Découvrez le format du TCF IRN en conditions réelles : 60 questions tirées sur les niveaux A2, B1 et B2. Votre score détermine votre niveau CECRL estimé.',
 5400, 60, 0, TRUE, TRUE, 1);

INSERT INTO exam_templates
    (id, slug, module, target_level, target_procedure, name, subtitle, description,
     duration_seconds, total_questions, passing_score, is_free, is_published, position)
SELECT
    ('50000000-aaaa-0000-0000-' || LPAD(pos::text, 12, '0'))::uuid,
    'tcf-mix-' || LPAD((pos - 1)::text, 2, '0'),
    'TCF',
    NULL,
    NULL,
    'TCF IRN — Diagnostic complet n°' || (pos - 1),
    '60 questions · 90 min · Diagnostic CECRL',
    'Diagnostic complet du niveau CECRL : 60 questions réparties sur A2, B1, B2. Tirage différent à chaque tentative.',
    5400, 60, 0, FALSE, TRUE, pos
FROM generate_series(2, 20) AS pos;

-- Règles TCF : 3 règles identiques par template (20 A2 + 20 B1 + 20 B2)
-- pour tous les 20 templates. Pas de contrainte de thème → le tirage prend
-- dans tout le module TCF (CO/CE/Structure, dès que le stock s'enrichit).
INSERT INTO exam_template_rules (id, exam_template_id, theme_id, question_type, difficulty, question_count, position)
SELECT gen_random_uuid(), t.id, NULL, NULL, 'A2', 20, 1
FROM exam_templates t
WHERE t.module = 'TCF' AND t.slug LIKE 'tcf-%';

INSERT INTO exam_template_rules (id, exam_template_id, theme_id, question_type, difficulty, question_count, position)
SELECT gen_random_uuid(), t.id, NULL, NULL, 'B1', 20, 2
FROM exam_templates t
WHERE t.module = 'TCF' AND t.slug LIKE 'tcf-%';

INSERT INTO exam_template_rules (id, exam_template_id, theme_id, question_type, difficulty, question_count, position)
SELECT gen_random_uuid(), t.id, NULL, NULL, 'B2', 20, 3
FROM exam_templates t
WHERE t.module = 'TCF' AND t.slug LIKE 'tcf-%';
