-- ============================================================================
-- V742 — TCF EO T2 — lot 02 (7 nouveaux sujets)
-- ----------------------------------------------------------------------------
-- Expression orale, Tâche 2 (exercice en interaction / jeu de rôle).
-- 7 sujets : 3×A2, 2×B1, 2×B2. Table production_tasks uniquement.
-- UUID déterministes 88888888-2002-1000-0000-0000000000NN (NN = 01..07).
-- Situations : assurance habitation, abonnement (sport/transport/médiathèque),
-- formation, organisation de fête, location de voiture, problème au
-- propriétaire, délai de paiement d''une facture. Contenu 100% original.
-- ============================================================================

INSERT INTO production_tasks
  (id, epreuve, tache_numero, niveau_cible, consigne, contexte, duree_max_sec, mots_min,
   mots_max, is_active, created_at, duree_min_sec)
VALUES
  -- 01 — Souscrire une assurance habitation (B2)
  ('88888888-2002-1000-0000-000000000001', 'TCF_EO', '2', 'B2',
   'Vous emménagez dans un appartement de trois pièces à Grenoble et vous rencontrez un conseiller pour souscrire une assurance habitation. Il vous présente deux formules, une à 14 euros et une à 22 euros par mois. Faites-vous expliquer précisément ce que couvre chacune (dégât des eaux, vol, bris de glace, responsabilité civile), reformulez ses explications pour vérifier votre compréhension des franchises, demandez avec courtoisie s''il serait envisageable d''ajuster le tarif si vous assurez aussi votre vélo électrique, et prenez l''initiative de récapituler les garanties retenues avant de donner votre décision.',
   'L''examinateur joue le conseiller en assurance, persuasif mais précis.',
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 02 — Prendre un abonnement à la médiathèque (A2)
  ('88888888-2002-1000-0000-000000000002', 'TCF_EO', '2', 'A2',
   'Vous habitez à Angers depuis deux mois et vous voulez prendre un abonnement à la médiathèque de votre quartier pour emprunter des livres et des films. Vous parlez avec l''employé de l''accueil. Demandez le prix de l''abonnement pour un an, les horaires d''ouverture, le nombre de livres que vous pouvez emprunter et les papiers nécessaires pour l''inscription. Posez au moins 4 questions claires et dites à la fin si vous prenez l''abonnement.',
   'L''examinateur joue l''employé de l''accueil de la médiathèque.',
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 03 — Se renseigner sur une formation (B1)
  ('88888888-2002-1000-0000-000000000003', 'TCF_EO', '2', 'B1',
   'Vous travaillez comme aide-cuisinier à Tours et vous souhaitez devenir pâtissier. Vous rencontrez la responsable d''un centre de formation pour adultes. Expliquez votre parcours et votre projet, posez des questions variées (durée de la formation, emploi du temps, coût, possibilités de financement, stage en entreprise, diplôme obtenu), réagissez à ses réponses en expliquant ce qui est important pour vous (par exemple garder votre travail le soir), et fixez une suite concrète : déposer un dossier ou assister à une réunion d''information.',
   'L''examinateur joue la responsable du centre de formation.',
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 04 — Organiser une fête (traiteur et salle) (B1)
  ('88888888-2002-1000-0000-000000000004', 'TCF_EO', '2', 'B1',
   'Vous organisez les 60 ans de votre tante Fatou et vous téléphonez à un traiteur qui loue aussi une petite salle de réception à Bayonne. Décrivez votre projet (environ 35 invités, un samedi soir du mois prochain), posez des questions variées (prix du menu par personne, plats proposés, boissons comprises ou non, location de la salle, heure de fin autorisée), négociez un point qui vous gêne (par exemple le supplément pour le service) et fixez une suite concrète : recevoir un devis ou visiter la salle.',
   'L''examinateur joue le traiteur, propriétaire de la salle de réception.',
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 05 — Louer une voiture (A2)
  ('88888888-2002-1000-0000-000000000005', 'TCF_EO', '2', 'A2',
   'Vous voulez louer une voiture pour aller voir votre ami Diego à Perpignan le week-end prochain. Vous allez dans une agence de location. Demandez à l''employé le prix pour deux jours, les papiers à présenter, si l''essence est comprise et à quelle heure il faut rendre la voiture. Posez au moins 4 questions claires et dites à la fin si vous réservez la voiture.',
   'L''examinateur joue l''employé de l''agence de location de voitures.',
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 06 — Signaler un problème à son propriétaire (B2)
  ('88888888-2002-1000-0000-000000000006', 'TCF_EO', '2', 'B2',
   'Depuis trois semaines, le chauffage de votre appartement de Mulhouse fonctionne mal et de l''humidité est apparue sur le mur de la chambre de votre fils. Vous téléphonez à votre propriétaire, qui minimise le problème et tarde à agir. Exposez la situation avec fermeté mais diplomatie, rappelez-lui ses obligations sans le braquer, reformulez ses réponses pour l''amener à s''engager (« si je comprends bien, vous enverriez un artisan… »), demandez s''il serait possible de convenir d''une date précise d''intervention, et prenez l''initiative de proposer un envoi de photos par courriel pour appuyer votre demande.',
   'L''examinateur joue le propriétaire, évasif et peu pressé d''engager des travaux.',
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120'),

  -- 07 — Demander un délai de paiement pour une facture (A2)
  ('88888888-2002-1000-0000-000000000007', 'TCF_EO', '2', 'A2',
   'Vous avez reçu une facture d''électricité de 180 euros, mais ce mois-ci vous ne pouvez pas tout payer. Vous téléphonez au service clients pour demander un délai de paiement. Expliquez simplement votre situation, demandez si vous pouvez payer en deux ou trois fois, demandez la date du prochain paiement et s''il y a des frais en plus. Posez au moins 3 questions claires et remerciez la personne à la fin.',
   'L''examinateur joue l''employée du service clients du fournisseur d''électricité.',
   '210', NULL, NULL, 'true', '2026-06-07 12:00:00+02', '120');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 sujets, UUID déterministes 88888888-2002-1000-0000-0000000000NN (01..07).
-- [x] niveau_cible : 3×A2 (02, 05, 07), 2×B1 (03, 04), 2×B2 (01, 06).
-- [x] Calibration : A2 = questions simples prix/horaire/papiers + conclusion ;
--     B1 = questions variées + réagir au contenu + négocier + fixer une suite ;
--     B2 = conditionnel de politesse, reformulation, initiative, registre adapté.
-- [x] epreuve='TCF_EO', tache_numero='2', duree_max_sec='210', duree_min_sec='120',
--     mots_min=NULL, mots_max=NULL, is_active='true',
--     created_at='2026-06-07 12:00:00+02'. Pas de colonne declencheur.
-- [x] 'contexte' = rôle joué par l''examinateur, comme l''exemplaire V741.
-- [x] 7 situations toutes différentes : assurance habitation, abonnement
--     médiathèque, formation pâtisserie, fête (traiteur + salle), location de
--     voiture, problème au propriétaire, délai de paiement. Aucune reprise des
--     sujets existants (poste, SAV, recrutement) ni des 10 situations du lot 01.
-- [x] Contenu 100% original ; villes variées (Grenoble, Angers, Tours, Bayonne,
--     Perpignan, Mulhouse), prénoms variés (Fatou, Diego), chiffres originaux
--     (14 €/22 €, 35 invités, 180 €).
-- [x] Apostrophes SQL doublées ('') partout ; pas de JSONB/SVG/SSML requis
--     pour ce lot (sujets seuls, table production_tasks) — distribution des
--     bonnes réponses : N/A (pas de QCM).
-- ============================================================================
