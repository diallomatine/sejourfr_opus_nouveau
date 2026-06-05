-- ============================================================================
-- V101 — Référence : thèmes
-- ----------------------------------------------------------------------------
-- Table themes. CIVIQUE (5) + TCF (CO/CE/STRUCTURE).
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

INSERT INTO themes
  (id, module, code, name, description, display_order)
VALUES
  ('11111111-0000-0000-0000-000000000001', 'CIVIQUE', 'CIV_PRINCIPES', 'Principes et valeurs de la République',
   'Devise, symboles, laïcité, liberté, égalité, fraternité',
   '1'),

  ('11111111-0000-0000-0000-000000000002', 'CIVIQUE', 'CIV_INSTITUTIONS', 'Système institutionnel et politique',
   'Constitution, président, parlement, séparation des pouvoirs',
   '2'),

  ('11111111-0000-0000-0000-000000000003', 'CIVIQUE', 'CIV_DROITS_DEVOIRS', 'Droits et devoirs',
   'Charte des droits et devoirs du citoyen français',
   '3'),

  ('11111111-0000-0000-0000-000000000004', 'CIVIQUE', 'CIV_HISTOIRE_GEO', 'Histoire, géographie et culture',
   'Repères historiques, géographie, patrimoine culturel',
   '4'),

  ('11111111-0000-0000-0000-000000000005', 'CIVIQUE', 'CIV_SOCIETE', 'Vivre dans la société française',
   'Vie quotidienne, services publics, vivre-ensemble',
   '5'),

  ('22222222-0000-0000-0000-000000000001', 'TCF', 'TCF_CO', 'Compréhension orale',
   'Audios courts, dialogues, annonces, extraits radio',
   '1'),

  ('22222222-0000-0000-0000-000000000002', 'TCF', 'TCF_CE', 'Compréhension écrite',
   'SMS, e-mails, panneaux, articles, formulaires',
   '2'),

  ('22222222-0000-0000-0000-000000000003', 'TCF', 'TCF_STRUCTURE', 'Structure de la langue',
   'Grammaire, lexique, conjugaison',
   '3');
