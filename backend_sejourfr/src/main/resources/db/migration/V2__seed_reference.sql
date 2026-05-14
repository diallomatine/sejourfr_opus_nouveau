-- ============================================================================
-- Données de reference (toujours chargées, en dev comme en prod)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Thèmes Civique (5 thématiques officielles)
-- ---------------------------------------------------------------------------
INSERT INTO themes (id, module, code, name, description, display_order)
VALUES ('11111111-0000-0000-0000-000000000001', 'CIVIQUE', 'CIV_PRINCIPES',
        'Principes et valeurs de la République',
        'Devise, symboles, laïcité, liberté, égalité, fraternité', 1),
       ('11111111-0000-0000-0000-000000000002', 'CIVIQUE', 'CIV_INSTITUTIONS',
        'Système institutionnel et politique',
        'Constitution, président, parlement, separation des pouvoirs', 2),
       ('11111111-0000-0000-0000-000000000003', 'CIVIQUE', 'CIV_DROITS_DEVOIRS',
        'Droits et devoirs',
        'Charte des droits et devoirs du citoyen français', 3),
       ('11111111-0000-0000-0000-000000000004', 'CIVIQUE', 'CIV_HISTOIRE_GEO',
        'Histoire, géographie et culture',
        'Reperes historiques, géographie, patrimoine culturel', 4),
       ('11111111-0000-0000-0000-000000000005', 'CIVIQUE', 'CIV_SOCIETE',
        'Vivre dans la société française',
        'Vie quotidienne, services publics, vivre-ensemble', 5);

-- ---------------------------------------------------------------------------
-- Thèmes TCF (3 catégories officielles)
-- ---------------------------------------------------------------------------
INSERT INTO themes (id, module, code, name, description, display_order)
VALUES ('22222222-0000-0000-0000-000000000001', 'TCF', 'TCF_CO',
        'Comprehension orale',
        'Audios courts, dialogues, annonces, extraits radio', 1),
       ('22222222-0000-0000-0000-000000000002', 'TCF', 'TCF_CE',
        'Comprehension ecrite',
        'SMS, e-mails, panneaux, articles, formulaires', 2),
       ('22222222-0000-0000-0000-000000000003', 'TCF', 'TCF_STRUCTURE',
        'Structure de la langue',
        'Grammaire, lexique, conjugaison', 3);

-- ---------------------------------------------------------------------------
-- Plans
-- ---------------------------------------------------------------------------
INSERT INTO plans (id, code, name, billing_cycle, price, is_active)
VALUES ('33333333-0000-0000-0000-000000000001', 'FREE',
        'Gratuit', 'NONE', 0.00, TRUE),
       ('33333333-0000-0000-0000-000000000002', 'PREMIUM_MONTHLY',
        'Premium mensuel', 'MONTHLY', 9.99, TRUE),
       ('33333333-0000-0000-0000-000000000003', 'PREMIUM_YEARLY',
        'Premium annuel', 'YEARLY', 89.00, TRUE);

-- ---------------------------------------------------------------------------
-- Exam templates officiels
-- ---------------------------------------------------------------------------
-- Civique : 40 questions, 45 min (2700 s), seuil 32/40
INSERT INTO exam_templates (id, module, target_level, name, duration_seconds, total_questions, passing_score)
VALUES ('44444444-0000-0000-0000-000000000001', 'CIVIQUE', NULL,
        'Examen civique - 40 questions', 2700, 40, 32);

-- TCF : 3 niveaux indicatifs
INSERT INTO exam_templates (id, module, target_level, name, duration_seconds, total_questions, passing_score)
VALUES ('44444444-0000-0000-0000-000000000002', 'TCF', 'A2',
        'TCF blanc - A2', 1800, 30, 18),
       ('44444444-0000-0000-0000-000000000003', 'TCF', 'B1',
        'TCF blanc - B1', 1800, 30, 21),
       ('44444444-0000-0000-0000-000000000004', 'TCF', 'B2',
        'TCF blanc - B2', 1800, 30, 24);
