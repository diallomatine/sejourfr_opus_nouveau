-- ============================================================================
-- Données de référence (toujours chargées, en dev comme en prod)
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
        'Constitution, président, parlement, séparation des pouvoirs', 2),
       ('11111111-0000-0000-0000-000000000003', 'CIVIQUE', 'CIV_DROITS_DEVOIRS',
        'Droits et devoirs',
        'Charte des droits et devoirs du citoyen français', 3),
       ('11111111-0000-0000-0000-000000000004', 'CIVIQUE', 'CIV_HISTOIRE_GEO',
        'Histoire, géographie et culture',
        'Repères historiques, géographie, patrimoine culturel', 4),
       ('11111111-0000-0000-0000-000000000005', 'CIVIQUE', 'CIV_SOCIETE',
        'Vivre dans la société française',
        'Vie quotidienne, services publics, vivre-ensemble', 5);

-- ---------------------------------------------------------------------------
-- Thèmes TCF (3 catégories officielles)
-- ---------------------------------------------------------------------------
INSERT INTO themes (id, module, code, name, description, display_order)
VALUES ('22222222-0000-0000-0000-000000000001', 'TCF', 'TCF_CO',
        'Compréhension orale',
        'Audios courts, dialogues, annonces, extraits radio', 1),
       ('22222222-0000-0000-0000-000000000002', 'TCF', 'TCF_CE',
        'Compréhension écrite',
        'SMS, e-mails, panneaux, articles, formulaires', 2),
       ('22222222-0000-0000-0000-000000000003', 'TCF', 'TCF_STRUCTURE',
        'Structure de la langue',
        'Grammaire, lexique, conjugaison', 3);

-- ---------------------------------------------------------------------------
-- Plans
-- ---------------------------------------------------------------------------
-- Paiements one-shot Stripe (pas de renouvellement automatique).
-- L'utilisateur paie sur un Stripe Payment Link et reçoit un accès limité
-- dans le temps. À l'expiration, il peut racheter manuellement.
--
-- Prix de lancement (price) affiché en grand, prix « normal » (original_price)
-- affiché barré à côté pour faire ressortir l'offre.
INSERT INTO plans (id, code, name, billing_cycle, price, original_price, module_access, duration_days, is_active)
VALUES
    ('33333333-0000-0000-0000-000000000001', 'FREE',
     'Gratuit', 'NONE', 0.00, NULL, 'NONE', 0, TRUE),
    ('33333333-0000-0000-0000-000000000002', 'CIVIQUE_3MOIS',
     'Civique — 3 mois', 'THREE_MONTHS', 5.99, 9.99, 'CIVIQUE', 90, TRUE),
    ('33333333-0000-0000-0000-000000000003', 'INTEGRAL_3MOIS',
     'Intégral (Civique + TCF) — 3 mois', 'THREE_MONTHS', 14.99, 19.99, 'INTEGRAL', 90, TRUE);

-- ---------------------------------------------------------------------------
-- Exam templates « officiels » (génériques, non publiés sur la vitrine).
-- ---------------------------------------------------------------------------
-- Les templates publics (40 examens publiés) sont créés ensuite dans
-- V110__exam_templates.sql. Ceux-ci servent de référence interne.
--
-- Le slug est requis (NOT NULL) depuis V030 → on en fournit un explicite.
-- Slugs préfixés par « officiel- » pour ne pas matcher les patterns
-- « tcf-% » et « civique-csp-% » utilisés par V110 / V120 qui injectent des
-- règles sur les templates publics. Ces 4 templates restent sans règles.
INSERT INTO exam_templates (id, module, target_level, name, duration_seconds, total_questions, passing_score, slug)
VALUES ('44444444-0000-0000-0000-000000000001', 'CIVIQUE', NULL,
        'Examen civique - 40 questions', 2700, 40, 32, 'officiel-civique-40q'),
       ('44444444-0000-0000-0000-000000000002', 'TCF', 'A2',
        'TCF blanc - A2', 1800, 30, 18, 'officiel-tcf-a2-30q'),
       ('44444444-0000-0000-0000-000000000003', 'TCF', 'B1',
        'TCF blanc - B1', 1800, 30, 21, 'officiel-tcf-b1-30q'),
       ('44444444-0000-0000-0000-000000000004', 'TCF', 'B2',
        'TCF blanc - B2', 1800, 30, 24, 'officiel-tcf-b2-30q');
