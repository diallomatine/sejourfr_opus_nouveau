-- ============================================================================
-- V741 — TCF EO T2 — lot 01 (10 nouveaux sujets)
-- ----------------------------------------------------------------------------
-- Expression orale, Tâche 2 (exercice en interaction / jeu de rôle).
-- 10 sujets : 4×A2, 3×B1, 3×B2. Table production_tasks uniquement.
-- UUID déterministes 88888888-2001-1000-0000-0000000000NN (NN = 01..0a).
-- Situations : logement, voiture d''occasion, RDV médical, compte bancaire,
-- devis déménagement, voyage/hôtel, inscription cours, mairie, marché,
-- retour d''achat. Contenu 100% original.
-- ============================================================================

INSERT INTO production_tasks
  (id, epreuve, tache_numero, niveau_cible, consigne, contexte, duree_max_sec, mots_min,
   mots_max, is_active, created_at, duree_min_sec)
VALUES
  -- 01 — Louer un logement (B1)
  ('88888888-2001-1000-0000-000000000001', 'TCF_EO', '2', 'B1',
   'Vous cherchez un appartement de deux pièces à Nantes et vous visitez un logement qui vous plaît. Interrogez l''agent immobilier sur le loyer, les charges, les documents à fournir et la date de disponibilité. Négociez un point qui vous gêne (par exemple le montant du dépôt de garantie) et fixez une suite concrète : déposer un dossier ou convenir d''une deuxième visite.',
   'L''examinateur joue l''agent immobilier qui fait visiter l''appartement.',
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 02 — Acheter une voiture d'occasion (B2)
  ('88888888-2001-1000-0000-000000000002', 'TCF_EO', '2', 'B2',
   'Vous répondez à une annonce pour une voiture d''occasion affichée à 7 200 euros, mais vous avez remarqué un kilométrage élevé et une révision qui n''a pas été faite. Menez la discussion avec le vendeur : faites-vous préciser l''historique d''entretien, soulevez les points faibles avec diplomatie, proposez un prix argumenté en utilisant le conditionnel de politesse (« seriez-vous prêt à… »), et prenez l''initiative de proposer un essai sur route avant de conclure.',
   'L''examinateur joue le vendeur particulier, attaché à son prix.',
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 03 — Prendre un rendez-vous médical (A2)
  ('88888888-2001-1000-0000-000000000003', 'TCF_EO', '2', 'A2',
   'Vous avez mal au dos depuis trois jours et vous téléphonez à un cabinet médical pour prendre rendez-vous. Demandez à la secrétaire le jour et l''heure possibles, l''adresse du cabinet, le prix de la consultation et les papiers à apporter. Posez au moins 4 questions claires et confirmez le rendez-vous à la fin.',
   'L''examinateur joue la secrétaire du cabinet médical.',
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 04 — Ouvrir un compte bancaire (B2)
  ('88888888-2001-1000-0000-000000000004', 'TCF_EO', '2', 'B2',
   'Vous venez d''être embauché à Strasbourg et vous rencontrez un conseiller pour ouvrir un compte bancaire. Au-delà des formalités, comparez les deux formules qu''il vous propose : interrogez-le sur les frais de tenue de compte, le coût de la carte, les conditions du découvert autorisé et les services en ligne. Demandez avec courtoisie s''il serait possible d''obtenir une remise la première année, prenez l''initiative d''évoquer un futur projet d''épargne et concluez sur la formule qui vous convient le mieux.',
   'L''examinateur joue le conseiller bancaire, commercial mais prudent.',
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 05 — Demander un devis de déménagement (B1)
  ('88888888-2001-1000-0000-000000000005', 'TCF_EO', '2', 'B1',
   'Vous déménagez le mois prochain de Lille à Rouen avec un appartement de trois pièces au deuxième étage sans ascenseur. Vous appelez une entreprise de déménagement pour demander un devis. Décrivez votre situation, posez des questions variées (prix, date, durée, assurance des meubles, cartons fournis ou non), négociez le tarif ou une prestation en plus, et fixez une suite : une visite d''estimation ou l''envoi du devis par courriel.',
   'L''examinateur joue l''employé de l''entreprise de déménagement.',
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 06 — Réserver un voyage / hôtel (A2)
  ('88888888-2001-1000-0000-000000000006', 'TCF_EO', '2', 'A2',
   'Vous voulez passer un week-end à Marseille avec un ami et vous téléphonez à un hôtel pour réserver une chambre pour deux personnes. Demandez le prix de la chambre, si le petit-déjeuner est compris, l''heure d''arrivée possible et où se trouve l''hôtel dans la ville. Posez au moins 4 questions claires, puis donnez votre nom pour confirmer la réservation.',
   'L''examinateur joue le réceptionniste de l''hôtel.',
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 07 — S'inscrire à un cours (A2)
  ('88888888-2001-1000-0000-000000000007', 'TCF_EO', '2', 'A2',
   'Vous voulez vous inscrire à un cours de cuisine dans une association de votre quartier à Dijon. Vous parlez avec la personne de l''accueil. Demandez le jour et l''heure des cours, le prix pour trois mois, le lieu exact et ce qu''il faut apporter. Posez au moins 4 questions claires et dites à la fin si vous vous inscrivez.',
   'L''examinateur joue l''employée de l''accueil de l''association.',
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 08 — Faire une démarche en mairie (B2)
  ('88888888-2001-1000-0000-000000000008', 'TCF_EO', '2', 'B2',
   'Vous venez d''emménager à Clermont-Ferrand et vous vous présentez à la mairie pour plusieurs démarches liées à votre installation : signaler votre changement d''adresse, demander une place en crèche pour votre fille et vous renseigner sur l''inscription sur les listes électorales. L''agent vous répond de façon parfois incomplète : reformulez ses explications pour vérifier votre compréhension, demandez poliment s''il serait possible d''obtenir un rendez-vous prioritaire pour la crèche, et prenez l''initiative de récapituler les étapes avant de partir.',
   'L''examinateur joue l''agent d''accueil de la mairie, pressé et peu bavard.',
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 09 — Négocier au marché (A2)
  ('88888888-2001-1000-0000-000000000009', 'TCF_EO', '2', 'A2',
   'Vous êtes au marché de votre ville pour acheter des fruits et des légumes pour la semaine. Demandez au vendeur le prix des tomates, des pommes et des oranges, demandez si les produits viennent de la région, et essayez d''obtenir un petit prix si vous achetez une grande quantité. Posez au moins 3 questions claires et terminez en payant vos achats.',
   'L''examinateur joue le vendeur du marché.',
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 10 — Retourner un achat en magasin (B1)
  ('88888888-2001-1000-0000-00000000000a', 'TCF_EO', '2', 'B1',
   'Vous avez acheté il y a dix jours une veste à 89 euros dans un magasin de vêtements, mais une couture s''est défaite dès le premier jour. Vous retournez au magasin avec le ticket de caisse. Expliquez calmement le problème au responsable, demandez un remboursement ou un échange, répondez à ses objections (il propose d''abord un avoir), négociez la solution qui vous convient et fixez une suite concrète si l''article de remplacement n''est pas disponible aujourd''hui.',
   'L''examinateur joue le responsable du magasin, d''abord réticent au remboursement.',
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 sujets, UUID déterministes 88888888-2001-1000-0000-0000000000NN (01..0a).
-- [x] niveau_cible : 4×A2 (03, 06, 07, 09), 3×B1 (01, 05, 10), 3×B2 (02, 04, 08).
-- [x] Calibration : A2 = questions simples prix/lieu/horaire ; B1 = négocier +
--     fixer une suite ; B2 = conditionnel de politesse, reformulation, initiative.
-- [x] epreuve='TCF_EO', tache_numero='2', duree_max_sec='210', duree_min_sec='120',
--     mots_min=NULL, mots_max=NULL, is_active='true',
--     created_at='2026-06-07 12:00:00+02'. Pas de colonne declencheur.
-- [x] 'contexte' = rôle joué par l''examinateur, comme l''exemplaire V740.
-- [x] 10 situations toutes différentes, aucune reprise des sujets existants
--     (poste, SAV, recrutement) ni des situations réservées au lot 02.
-- [x] Contenu 100% original ; villes et chiffres variés (Nantes, Strasbourg,
--     Lille, Rouen, Marseille, Dijon, Clermont-Ferrand ; 7 200 €, 89 €…).
-- [x] Apostrophes SQL doublées ('') partout ; pas de JSONB/SVG/SSML requis
--     pour ce lot (sujets seuls, table production_tasks) — distribution des
--     bonnes réponses : N/A (pas de QCM).
-- ============================================================================
