-- ============================================================================
-- V751 — TCF EO T3 — lot 01 (10 nouveaux sujets)
-- ----------------------------------------------------------------------------
-- Tâche 3 : exprimer ses goûts / opinions (monologue oral, 3 min 30).
-- 10 sujets : 4×A2, 3×B1, 3×B2. Table production_tasks uniquement.
-- A2 = position + 2 raisons + exemple ; B1 = arguments illustrés + concession ;
-- B2 = thèse nuancée + objection anticipée et discutée.
-- UUID déterministes : 88888888-3001-1000-0000-0000000000NN (NN = 01..0a).
-- ============================================================================

INSERT INTO production_tasks
  (id, epreuve, tache_numero, niveau_cible, consigne, contexte, duree_max_sec, mots_min,
   mots_max, is_active, created_at, duree_min_sec)
VALUES
  -- 01 · A2 · votre ville préférée
  ('88888888-3001-1000-0000-000000000001', 'TCF_EO', '3', 'A2',
   'Quelle est la ville que vous préférez ? Dites où elle se trouve, donnez deux raisons pour lesquelles vous l''aimez et racontez un souvenir ou un exemple précis vécu dans cette ville.',
   NULL,
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 02 · B1 · la gratuité des transports en commun
  ('88888888-3001-1000-0000-000000000002', 'TCF_EO', '3', 'B1',
   'Certaines villes rendent les bus et les tramways gratuits pour tout le monde. Êtes-vous favorable à la gratuité des transports en commun ? Donnez votre avis avec au moins deux arguments illustrés par des exemples, puis mentionnez un inconvénient possible de cette mesure.',
   NULL,
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 03 · B2 · les écrans et les enfants
  ('88888888-3001-1000-0000-000000000003', 'TCF_EO', '3', 'B2',
   'Faut-il interdire les écrans (téléphones, tablettes, télévision) aux enfants de moins de six ans, ou plutôt apprendre aux familles à les utiliser raisonnablement ? Défendez une position nuancée et envisagez au moins une objection que pourrait formuler un parent ou un enseignant en désaccord avec vous, puis répondez-y.',
   NULL,
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 04 · A2 · ville ou campagne
  ('88888888-3001-1000-0000-000000000004', 'TCF_EO', '3', 'A2',
   'Préférez-vous vivre en ville ou à la campagne ? Donnez votre choix, expliquez deux raisons et donnez un exemple de votre vie quotidienne pour illustrer votre préférence.',
   NULL,
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 05 · A2 · l'importance du sport
  ('88888888-3001-1000-0000-000000000005', 'TCF_EO', '3', 'A2',
   'Le sport est-il important pour vous ? Dites quel sport vous pratiquez ou aimeriez pratiquer, donnez deux raisons pour lesquelles le sport est utile et racontez un exemple personnel (un match, une séance, une promenade sportive).',
   NULL,
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 06 · A2 · les voyages
  ('88888888-3001-1000-0000-000000000006', 'TCF_EO', '3', 'A2',
   'Aimez-vous voyager ? Dites quel type de voyage vous préférez (mer, montagne, grandes villes, visite de la famille), donnez deux raisons et décrivez un voyage que vous avez fait ou que vous rêvez de faire.',
   NULL,
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 07 · B1 · l'alimentation au quotidien
  ('88888888-3001-1000-0000-000000000007', 'TCF_EO', '3', 'B1',
   'De plus en plus de personnes mangent des plats préparés ou commandent des repas livrés au lieu de cuisiner. Selon vous, est-il important de cuisiner soi-même tous les jours ? Donnez au moins deux arguments illustrés par des exemples de votre quotidien, puis reconnaissez un avantage du point de vue opposé.',
   NULL,
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 08 · B2 · travailler le week-end
  ('88888888-3001-1000-0000-000000000008', 'TCF_EO', '3', 'B2',
   'Dans certains secteurs (commerce, restauration, santé), travailler le week-end est devenu habituel, et certains magasins voudraient ouvrir tous les dimanches. Pensez-vous que le travail du week-end devrait rester une exception ou se généraliser ? Présentez une position nuancée, anticipez une objection sérieuse (par exemple celle d''un salarié ou d''un commerçant qui ne partage pas votre avis) et discutez-la avant de conclure.',
   NULL,
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 09 · B2 · la voiture en ville
  ('88888888-3001-1000-0000-000000000009', 'TCF_EO', '3', 'B2',
   'Plusieurs grandes villes limitent fortement la circulation des voitures dans leur centre : zones piétonnes, stationnement très cher, rues fermées. Faut-il selon vous réduire la place de la voiture en ville, et jusqu''où ? Défendez une thèse nuancée, envisagez l''objection d''une personne qui dépend de sa voiture (famille, travail, handicap) et répondez-y de manière argumentée.',
   NULL,
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 10 · B1 · l'apprentissage des langues
  ('88888888-3001-1000-0000-00000000000a', 'TCF_EO', '3', 'B1',
   'Selon vous, quelle est la meilleure façon d''apprendre une langue étrangère : prendre des cours, utiliser des applications, ou vivre dans le pays ? Donnez votre avis avec au moins deux arguments illustrés par votre propre expérience du français, puis admettez une limite de la méthode que vous défendez.',
   NULL,
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 sujets, UUID déterministes 88888888-3001-1000-0000-0000000000NN (01..0a).
-- [x] niveau_cible : 4×A2 (01, 04, 05, 06), 3×B1 (02, 07, 10), 3×B2 (03, 08, 09).
-- [x] Calibration : A2 = position + 2 raisons + exemple ; B1 = arguments
--     illustrés + concession ; B2 = thèse nuancée + objection anticipée et
--     discutée.
-- [x] epreuve='TCF_EO', tache_numero=3, duree_max_sec=210, duree_min_sec=120,
--     mots_min/mots_max NULL, is_active=true, created_at 2026-06-07 12:00:00+02.
-- [x] Distribution des bonnes réponses : N/A (sujets de production, pas de QCM).
-- [x] SVG/SSML : N/A (aucun media dans production_tasks ; exemples-modèles
--     générés séparément).
-- [x] Thèmes tous différents, aucun doublon avec l'existant (transport préféré,
--     réseaux sociaux, télétravail) ni avec les thèmes réservés au lot 02.
-- [x] Contenu 100 % original ; apostrophes SQL doublées ; consignes autonomes.
-- ============================================================================
