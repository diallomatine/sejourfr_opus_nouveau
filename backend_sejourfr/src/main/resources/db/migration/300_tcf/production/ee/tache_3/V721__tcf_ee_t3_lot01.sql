-- ============================================================================
-- V721 — TCF EE T3 — lot 01 (10 nouveaux sujets)
-- ----------------------------------------------------------------------------
-- Expression écrite, Tâche 3 : avis argumenté façon forum (40-90 mots).
-- 10 sujets : 4×A2 / 3×B1 / 3×B2. Table production_tasks uniquement.
-- A2 = position + 2 raisons simples ; B1 = + exemples et concession ;
-- B2 = + objection anticipée et discutée.
-- UUID déterministes 77777777-e301-1000-0000-0000000000NN (NN = 01..0a).
-- ============================================================================

INSERT INTO production_tasks
  (id, epreuve, tache_numero, niveau_cible, consigne, contexte, duree_max_sec, mots_min,
   mots_max, is_active, created_at, duree_min_sec)
VALUES
  -- 01 · A2 · supermarché vs petits commerces
  ('77777777-e301-1000-0000-000000000001', 'TCF_EE', '3', 'A2',
   'Préférez-vous faire vos courses au supermarché ou dans les petits commerces de quartier ? Donnez votre opinion et expliquez deux raisons simples.',
   NULL,
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 02 · B2 · le télétravail
  ('77777777-e301-1000-0000-000000000002', 'TCF_EE', '3', 'B2',
   'Le télétravail rend-il la vie professionnelle meilleure ou plus difficile ? Défendez une position nuancée : exposez votre thèse, appuyez-la sur au moins deux arguments, puis envisagez explicitement une objection que vous discutez avant de conclure.',
   NULL,
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 03 · A2 · les transports en commun
  ('77777777-e301-1000-0000-000000000003', 'TCF_EE', '3', 'A2',
   'Préférez-vous vous déplacer en transports en commun ou en voiture ? Donnez votre opinion et expliquez deux raisons simples.',
   NULL,
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 04 · A2 · les animaux à la maison
  ('77777777-e301-1000-0000-000000000004', 'TCF_EE', '3', 'A2',
   'Est-ce une bonne idée d''avoir un animal à la maison ? Donnez votre opinion et expliquez deux raisons simples.',
   NULL,
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 05 · B1 · voyager seul ou accompagné
  ('77777777-e301-1000-0000-000000000005', 'TCF_EE', '3', 'B1',
   'Vaut-il mieux voyager seul ou accompagné ? Donnez votre avis en le défendant avec deux arguments illustrés d''exemples (vécus ou observés) et en reconnaissant au moins un avantage du choix opposé.',
   NULL,
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 06 · A2 · cuisiner vs manger dehors
  ('77777777-e301-1000-0000-000000000006', 'TCF_EE', '3', 'A2',
   'Préférez-vous cuisiner chez vous ou manger au restaurant ? Donnez votre opinion et expliquez deux raisons simples.',
   NULL,
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 07 · B1 · les réseaux sociaux au quotidien
  ('77777777-e301-1000-0000-000000000007', 'TCF_EE', '3', 'B1',
   'Les réseaux sociaux améliorent-ils notre vie quotidienne ? Donnez votre avis en l''appuyant sur deux arguments concrets avec des exemples de votre quotidien, et faites une concession à l''opinion contraire (« c''est vrai que… mais »).',
   NULL,
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 08 · B2 · travailler le week-end
  ('77777777-e301-1000-0000-000000000008', 'TCF_EE', '3', 'B2',
   'Faut-il accepter de travailler le week-end ? Défendez une position nuancée : formulez votre thèse, développez au moins deux arguments, puis anticipez une objection sérieuse que vous discutez avant de proposer une conclusion ouverte.',
   NULL,
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 09 · B1 · le vélo en ville
  ('77777777-e301-1000-0000-000000000009', 'TCF_EE', '3', 'B1',
   'Le vélo est-il une bonne solution pour se déplacer en ville ? Donnez votre avis avec deux arguments illustrés d''exemples précis (trajets, météo, budget…) et reconnaissez au moins une limite de votre position.',
   NULL,
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 0a · B2 · les achats en ligne
  ('77777777-e301-1000-0000-00000000000a', 'TCF_EE', '3', 'B2',
   'Les achats en ligne vont-ils faire disparaître les magasins traditionnels, et serait-ce une bonne chose ? Défendez une position nuancée : exposez votre thèse, soutenez-la par au moins deux arguments, et discutez explicitement une objection qu''on pourrait vous opposer.',
   NULL,
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- - 10 sujets, UUID déterministes 77777777-e301-1000-0000-0000000000NN (01..0a),
--   tous uniques.
-- - epreuve='TCF_EE', tache_numero=3, mots_min=40, mots_max=90,
--   duree_max_sec=NULL, duree_min_sec=NULL, is_active=true,
--   created_at='2026-06-07 12:00:00+02', contexte=NULL (format exemplaire V720).
-- - niveau_cible : 4×A2 (01, 03, 04, 06), 3×B1 (05, 07, 09), 3×B2 (02, 08, 0a).
-- - Exigence graduée : A2 = position + 2 raisons simples ; B1 = + exemples et
--   concession ; B2 = + objection anticipée et discutée.
-- - 10 thèmes tous différents, conformes au bon de commande ; aucun recoupement
--   avec les sujets existants (ville/campagne, écrans des enfants, IA et
--   éducation) ni avec les thèmes réservés au lot 02.
-- - Pas de colonne declencheur (schéma réel production_tasks respecté).
-- - Distribution des bonnes réponses : N/A (sujets de production, pas de QCM).
-- - SVG/SSML : N/A (épreuve écrite, pas de média).
-- - Apostrophes SQL doublées ('') partout ; contenu 100 % original.
-- ============================================================================
