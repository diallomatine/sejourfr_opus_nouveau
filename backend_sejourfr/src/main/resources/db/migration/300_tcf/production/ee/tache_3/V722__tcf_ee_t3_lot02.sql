-- ============================================================================
-- V722 — TCF EE T3 — lot 02 (7 nouveaux sujets)
-- ----------------------------------------------------------------------------
-- Expression écrite, Tâche 3 : avis argumenté façon forum (40-90 mots).
-- 7 sujets : 3×A2 / 2×B1 / 2×B2. Table production_tasks uniquement.
-- A2 = position + 2 raisons simples ; B1 = + exemples et concession ;
-- B2 = + objection anticipée et discutée.
-- UUID déterministes 77777777-e302-1000-0000-0000000000NN (NN = 01..07).
-- ============================================================================

INSERT INTO production_tasks
  (id, epreuve, tache_numero, niveau_cible, consigne, contexte, duree_max_sec, mots_min,
   mots_max, is_active, created_at, duree_min_sec)
VALUES
  -- 01 · A2 · la colocation
  ('77777777-e302-1000-0000-000000000001', 'TCF_EE', '3', 'A2',
   'Aimeriez-vous vivre en colocation ou préférez-vous habiter seul(e) ? Donnez votre opinion et expliquez deux raisons simples.',
   NULL,
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 02 · B1 · apprendre une langue à l'étranger
  ('77777777-e302-1000-0000-000000000002', 'TCF_EE', '3', 'B1',
   'Pour apprendre une langue, faut-il absolument partir vivre dans le pays où on la parle ? Donnez votre avis en l''appuyant sur deux arguments illustrés d''exemples (votre expérience ou celle de personnes que vous connaissez), et reconnaissez au moins un avantage de l''opinion contraire.',
   NULL,
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 03 · B2 · le tourisme de masse
  ('77777777-e302-1000-0000-000000000003', 'TCF_EE', '3', 'B2',
   'Le tourisme de masse est-il une chance ou une menace pour les villes et les sites très visités ? Défendez une position nuancée : exposez votre thèse, appuyez-la sur au moins deux arguments, puis anticipez une objection sérieuse que vous discutez avant de conclure.',
   NULL,
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 04 · B2 · l'alimentation bio
  ('77777777-e302-1000-0000-000000000004', 'TCF_EE', '3', 'B2',
   'Faut-il privilégier les produits bio malgré leur prix plus élevé ? Défendez une position nuancée : formulez votre thèse, développez au moins deux arguments, puis envisagez explicitement une objection qu''on pourrait vous opposer et discutez-la avant de proposer une conclusion ouverte.',
   NULL,
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 05 · A2 · sport en salle vs sport en plein air
  ('77777777-e302-1000-0000-000000000005', 'TCF_EE', '3', 'A2',
   'Préférez-vous faire du sport dans une salle ou en plein air ? Donnez votre opinion et expliquez deux raisons simples.',
   NULL,
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 06 · A2 · acheter neuf ou d'occasion
  ('77777777-e302-1000-0000-000000000006', 'TCF_EE', '3', 'A2',
   'Préférez-vous acheter des objets neufs ou d''occasion (vêtements, meubles, téléphones…) ? Donnez votre opinion et expliquez deux raisons simples.',
   NULL,
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 07 · B1 · faut-il connaître ses voisins ?
  ('77777777-e302-1000-0000-000000000007', 'TCF_EE', '3', 'B1',
   'Est-il important de connaître ses voisins ? Donnez votre avis en le défendant avec deux arguments concrets illustrés d''exemples de la vie quotidienne (services rendus, fêtes, tranquillité…), et faites une concession à l''opinion contraire (« c''est vrai que… mais »).',
   NULL,
   NULL, '40', '90', 'true', '2026-06-07 12:00:00+02', NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- - 7 sujets, UUID déterministes 77777777-e302-1000-0000-0000000000NN (01..07),
--   tous uniques.
-- - epreuve='TCF_EE', tache_numero=3, mots_min=40, mots_max=90,
--   duree_max_sec=NULL, duree_min_sec=NULL, is_active=true,
--   created_at='2026-06-07 12:00:00+02', contexte=NULL (format exemplaire V721).
-- - niveau_cible : 3×A2 (01, 05, 06), 2×B1 (02, 07), 2×B2 (03, 04).
-- - Exigence graduée : A2 = position + 2 raisons simples ; B1 = + exemples et
--   concession ; B2 = + objection anticipée et discutée.
-- - 7 thèmes du bon de commande, tous différents ; aucun recoupement avec les
--   sujets existants (ville/campagne, écrans des enfants, IA et éducation) ni
--   avec les 10 thèmes du lot 01.
-- - Pas de colonne declencheur (schéma réel production_tasks respecté).
-- - Distribution des bonnes réponses : N/A (sujets de production, pas de QCM).
-- - SVG/SSML : N/A (épreuve écrite, pas de média).
-- - Apostrophes SQL doublées ('') partout ; contenu 100 % original.
-- ============================================================================
