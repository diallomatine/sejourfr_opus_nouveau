-- ============================================================================
-- V754 — Titres editoriaux des sujets EO/EE (103 sujets)
-- ----------------------------------------------------------------------------
-- Colonne posee par V028 (NULLABLE). Ici, le CONTENU : un intitule court,
-- nominal et fidele a la consigne pour chacun des sujets publies.
--
-- Pourquoi : les cartes de sujet affichaient « Sujet 01 » + le debut de la
-- consigne. Or les consignes d'une meme tache commencent toutes de la meme
-- facon (« Ecrivez un message a… », « Racontez… », « Donnez votre avis… ») :
-- dans une liste de vingt sujets, rien ne les distinguait.
--
-- Regles de redaction, verifiees par le generateur : 2 a 5 mots, forme
-- nominale, aucun chiffre, aucun jargon (« Tache 2 », palier CECRL, nombre
-- de mots — tout cela est deja affiche ailleurs sur la carte), et deux
-- sujets d'une meme tache ne se confondent jamais.
--
-- Deterministe et idempotent : un UPDATE par sujet, borne par son id.
-- Aucune ligne creee, aucune supprimee, aucune consigne touchee.
--
-- FICHIER GENERE — NE PAS EDITER A LA MAIN.
--
--   cd backend_sejourfr && python3 tools/production-titres/generer_seed.py
--
-- On edite la fiche tools/production-titres/contenu/<TACHE>.json, puis on
-- regenere. Une correction faite ici serait ecrasee a la prochaine
-- generation, et les deux sources auraient diverge entre-temps.
--
-- (Le contenu vivant, lui, s'edite depuis la console d'administration une
-- fois la migration appliquee : c'est la base qui fait foi, pas ce JSON.)
-- ============================================================================

-- EE1 — Message court (20 sujets)
UPDATE production_tasks SET titre = 'Réclamation à un prestataire' WHERE id = '26b5d842-04c6-46b6-92e2-c324a9c39490';
UPDATE production_tasks SET titre = 'Emménagement dans un nouveau quartier' WHERE id = '48b8be40-994f-4afb-b03c-b9a56b670cd1';
UPDATE production_tasks SET titre = 'Événement du quartier' WHERE id = '84941b89-6ec6-4ae6-91b9-0cc26a83e5df';
UPDATE production_tasks SET titre = 'Invitation à un pique-nique' WHERE id = '77777777-e101-1000-0000-000000000001';
UPDATE production_tasks SET titre = 'Refus d''une invitation' WHERE id = '77777777-e101-1000-0000-000000000002';
UPDATE production_tasks SET titre = 'Annonce d''un nouvel emploi' WHERE id = '77777777-e101-1000-0000-000000000003';
UPDATE production_tasks SET titre = 'Portrait d''une collègue' WHERE id = '77777777-e101-1000-0000-000000000004';
UPDATE production_tasks SET titre = 'Service demandé à un voisin' WHERE id = '77777777-e101-1000-0000-000000000005';
UPDATE production_tasks SET titre = 'Félicitations pour un diplôme' WHERE id = '77777777-e101-1000-0000-000000000006';
UPDATE production_tasks SET titre = 'Remerciements pour un vélo prêté' WHERE id = '77777777-e101-1000-0000-000000000007';
UPDATE production_tasks SET titre = 'Des nouvelles à une cousine' WHERE id = '77777777-e101-1000-0000-000000000008';
UPDATE production_tasks SET titre = 'Rendez-vous difficile à fixer' WHERE id = '77777777-e101-1000-0000-000000000009';
UPDATE production_tasks SET titre = 'Cours de théâtre conseillé' WHERE id = '77777777-e101-1000-0000-00000000000a';
UPDATE production_tasks SET titre = 'Excuses après un rendez-vous manqué' WHERE id = '77777777-e102-1000-0000-000000000001';
UPDATE production_tasks SET titre = 'Garde du chat confirmée' WHERE id = '77777777-e102-1000-0000-000000000002';
UPDATE production_tasks SET titre = 'Conseils avant un entretien' WHERE id = '77777777-e102-1000-0000-000000000003';
UPDATE production_tasks SET titre = 'Invitation à un tournoi' WHERE id = '77777777-e102-1000-0000-000000000004';
UPDATE production_tasks SET titre = 'Relecture d''une lettre de motivation' WHERE id = '77777777-e102-1000-0000-000000000005';
UPDATE production_tasks SET titre = 'Projet de traiteur présenté' WHERE id = '77777777-e102-1000-0000-000000000006';
UPDATE production_tasks SET titre = 'Réponse à une amie déçue' WHERE id = '77777777-e102-1000-0000-000000000007';

-- EE2 — Récit d'expérience (20 sujets)
UPDATE production_tasks SET titre = 'Une décision difficile' WHERE id = '08e3acd5-c88e-4ba3-8166-520862865128';
UPDATE production_tasks SET titre = 'Dernière sortie au restaurant' WHERE id = '85ae18b5-b014-426f-a15a-059cae856f8d';
UPDATE production_tasks SET titre = 'Une expérience révélatrice' WHERE id = '89436b56-7ebb-4ee9-8504-7677fe1164fe';
UPDATE production_tasks SET titre = 'Le mariage d''une cousine' WHERE id = '77777777-e201-1000-0000-000000000001';
UPDATE production_tasks SET titre = 'Un voyage à Marseille' WHERE id = '77777777-e201-1000-0000-000000000002';
UPDATE production_tasks SET titre = 'Premier jour de travail' WHERE id = '77777777-e201-1000-0000-000000000003';
UPDATE production_tasks SET titre = 'Une rencontre marquante' WHERE id = '77777777-e201-1000-0000-000000000004';
UPDATE production_tasks SET titre = 'Un week-end raconté' WHERE id = '77777777-e201-1000-0000-000000000005';
UPDATE production_tasks SET titre = 'Un déménagement à Lille' WHERE id = '77777777-e201-1000-0000-000000000006';
UPDATE production_tasks SET titre = 'Un imprévu au supermarché' WHERE id = '77777777-e201-1000-0000-000000000007';
UPDATE production_tasks SET titre = 'Une sortie culturelle' WHERE id = '77777777-e201-1000-0000-000000000008';
UPDATE production_tasks SET titre = 'Une réussite personnelle' WHERE id = '77777777-e201-1000-0000-000000000009';
UPDATE production_tasks SET titre = 'Une journée importante' WHERE id = '77777777-e201-1000-0000-00000000000a';
UPDATE production_tasks SET titre = 'Une découverte culinaire' WHERE id = '77777777-e202-1000-0000-000000000001';
UPDATE production_tasks SET titre = 'Une fête de famille' WHERE id = '77777777-e202-1000-0000-000000000002';
UPDATE production_tasks SET titre = 'Un objet perdu et retrouvé' WHERE id = '77777777-e202-1000-0000-000000000003';
UPDATE production_tasks SET titre = 'Une panne sur la route' WHERE id = '77777777-e202-1000-0000-000000000004';
UPDATE production_tasks SET titre = 'Une voisine aidée' WHERE id = '77777777-e202-1000-0000-000000000005';
UPDATE production_tasks SET titre = 'Un souvenir d''enfance' WHERE id = '77777777-e202-1000-0000-000000000006';
UPDATE production_tasks SET titre = 'Une première démarche administrative' WHERE id = '77777777-e202-1000-0000-000000000007';

-- EE3 — Avis argumenté (20 sujets)
UPDATE production_tasks SET titre = 'Intelligence artificielle et éducation' WHERE id = '525cc021-4103-4260-8c7b-695f152eea8b';
UPDATE production_tasks SET titre = 'Le temps d''écran des enfants' WHERE id = '67837e55-303b-437a-a513-e8f33125de06';
UPDATE production_tasks SET titre = 'Ville ou campagne' WHERE id = '7c323ad8-639f-4122-be5c-44badb65b010';
UPDATE production_tasks SET titre = 'Supermarché ou commerces de quartier' WHERE id = '77777777-e301-1000-0000-000000000001';
UPDATE production_tasks SET titre = 'Les effets du télétravail' WHERE id = '77777777-e301-1000-0000-000000000002';
UPDATE production_tasks SET titre = 'Transports en commun ou voiture' WHERE id = '77777777-e301-1000-0000-000000000003';
UPDATE production_tasks SET titre = 'Un animal à la maison' WHERE id = '77777777-e301-1000-0000-000000000004';
UPDATE production_tasks SET titre = 'Voyager seul ou accompagné' WHERE id = '77777777-e301-1000-0000-000000000005';
UPDATE production_tasks SET titre = 'Cuisiner chez soi ou sortir' WHERE id = '77777777-e301-1000-0000-000000000006';
UPDATE production_tasks SET titre = 'Les réseaux sociaux au quotidien' WHERE id = '77777777-e301-1000-0000-000000000007';
UPDATE production_tasks SET titre = 'Travailler le week-end' WHERE id = '77777777-e301-1000-0000-000000000008';
UPDATE production_tasks SET titre = 'Le vélo en ville' WHERE id = '77777777-e301-1000-0000-000000000009';
UPDATE production_tasks SET titre = 'Achats en ligne et magasins' WHERE id = '77777777-e301-1000-0000-00000000000a';
UPDATE production_tasks SET titre = 'Vivre en colocation ou seul' WHERE id = '77777777-e302-1000-0000-000000000001';
UPDATE production_tasks SET titre = 'Apprendre une langue à l''étranger' WHERE id = '77777777-e302-1000-0000-000000000002';
UPDATE production_tasks SET titre = 'Le tourisme de masse' WHERE id = '77777777-e302-1000-0000-000000000003';
UPDATE production_tasks SET titre = 'Le prix des produits bio' WHERE id = '77777777-e302-1000-0000-000000000004';
UPDATE production_tasks SET titre = 'Sport en salle ou dehors' WHERE id = '77777777-e302-1000-0000-000000000005';
UPDATE production_tasks SET titre = 'Acheter neuf ou d''occasion' WHERE id = '77777777-e302-1000-0000-000000000006';
UPDATE production_tasks SET titre = 'Connaître ses voisins' WHERE id = '77777777-e302-1000-0000-000000000007';

-- EO1 — Entretien dirigé (3 sujets)
UPDATE production_tasks SET titre = 'Présentation et famille' WHERE id = '1e31fd83-af31-4d93-b103-c38856b254a4';
UPDATE production_tasks SET titre = 'Parcours et centres d''intérêt' WHERE id = '2d1bea33-2ba8-4524-948c-89595c55fea6';
UPDATE production_tasks SET titre = 'Un projet qui compte' WHERE id = '6bf79a5c-7fe1-45c5-bc93-c638e33f86e4';

-- EO2 — Jeu de rôle (20 sujets)
UPDATE production_tasks SET titre = 'Envoi d''un colis' WHERE id = '21b1b1d9-5411-49a8-99b7-9c18b1abd8b6';
UPDATE production_tasks SET titre = 'Entretien téléphonique d''embauche' WHERE id = '67b1bc04-5275-4cc6-b6f3-df4f28c2a0aa';
UPDATE production_tasks SET titre = 'Appel au service après-vente' WHERE id = 'aafce71c-0b12-4945-8a28-02f5d0f2299f';
UPDATE production_tasks SET titre = 'Visite d''un appartement' WHERE id = '88888888-2001-1000-0000-000000000001';
UPDATE production_tasks SET titre = 'Achat d''une voiture d''occasion' WHERE id = '88888888-2001-1000-0000-000000000002';
UPDATE production_tasks SET titre = 'Rendez-vous chez le médecin' WHERE id = '88888888-2001-1000-0000-000000000003';
UPDATE production_tasks SET titre = 'Ouverture d''un compte bancaire' WHERE id = '88888888-2001-1000-0000-000000000004';
UPDATE production_tasks SET titre = 'Devis de déménagement' WHERE id = '88888888-2001-1000-0000-000000000005';
UPDATE production_tasks SET titre = 'Réservation d''une chambre d''hôtel' WHERE id = '88888888-2001-1000-0000-000000000006';
UPDATE production_tasks SET titre = 'Inscription au cours de cuisine' WHERE id = '88888888-2001-1000-0000-000000000007';
UPDATE production_tasks SET titre = 'Démarches à la mairie' WHERE id = '88888888-2001-1000-0000-000000000008';
UPDATE production_tasks SET titre = 'Achats au marché' WHERE id = '88888888-2001-1000-0000-000000000009';
UPDATE production_tasks SET titre = 'Échange d''une veste défectueuse' WHERE id = '88888888-2001-1000-0000-00000000000a';
UPDATE production_tasks SET titre = 'Souscription d''une assurance habitation' WHERE id = '88888888-2002-1000-0000-000000000001';
UPDATE production_tasks SET titre = 'Abonnement à la médiathèque' WHERE id = '88888888-2002-1000-0000-000000000002';
UPDATE production_tasks SET titre = 'Projet de formation en pâtisserie' WHERE id = '88888888-2002-1000-0000-000000000003';
UPDATE production_tasks SET titre = 'Traiteur pour un anniversaire' WHERE id = '88888888-2002-1000-0000-000000000004';
UPDATE production_tasks SET titre = 'Location d''une voiture' WHERE id = '88888888-2002-1000-0000-000000000005';
UPDATE production_tasks SET titre = 'Panne de chauffage et humidité' WHERE id = '88888888-2002-1000-0000-000000000006';
UPDATE production_tasks SET titre = 'Délai pour une facture d''électricité' WHERE id = '88888888-2002-1000-0000-000000000007';

-- EO3 — Point de vue (20 sujets)
UPDATE production_tasks SET titre = 'Avantages et inconvénients des réseaux' WHERE id = '5e739a88-a418-49ad-a7f2-8266c899ad2a';
UPDATE production_tasks SET titre = 'Se déplacer en grande ville' WHERE id = '91d0f63c-3127-40ef-af9f-8e677910e59b';
UPDATE production_tasks SET titre = 'L''organisation du travail' WHERE id = 'f0fe3fcd-93b2-4f33-aa49-7ac040f04626';
UPDATE production_tasks SET titre = 'Sa ville d''enfance' WHERE id = '88888888-3001-1000-0000-000000000001';
UPDATE production_tasks SET titre = 'La gratuité des transports' WHERE id = '88888888-3001-1000-0000-000000000002';
UPDATE production_tasks SET titre = 'Les écrans avant six ans' WHERE id = '88888888-3001-1000-0000-000000000003';
UPDATE production_tasks SET titre = 'Vivre en ville ou ailleurs' WHERE id = '88888888-3001-1000-0000-000000000004';
UPDATE production_tasks SET titre = 'Le sport et la santé' WHERE id = '88888888-3001-1000-0000-000000000005';
UPDATE production_tasks SET titre = 'Voyager loin ou près' WHERE id = '88888888-3001-1000-0000-000000000006';
UPDATE production_tasks SET titre = 'Cuisiner soi-même chaque jour' WHERE id = '88888888-3001-1000-0000-000000000007';
UPDATE production_tasks SET titre = 'Le travail du week-end' WHERE id = '88888888-3001-1000-0000-000000000008';
UPDATE production_tasks SET titre = 'La voiture en centre-ville' WHERE id = '88888888-3001-1000-0000-000000000009';
UPDATE production_tasks SET titre = 'Apprendre une langue étrangère' WHERE id = '88888888-3001-1000-0000-00000000000a';
UPDATE production_tasks SET titre = 'Le tourisme dans les villes' WHERE id = '88888888-3002-1000-0000-000000000001';
UPDATE production_tasks SET titre = 'L''aide de l''intelligence artificielle' WHERE id = '88888888-3002-1000-0000-000000000002';
UPDATE production_tasks SET titre = 'Les gestes pour l''environnement' WHERE id = '88888888-3002-1000-0000-000000000003';
UPDATE production_tasks SET titre = 'L''engagement associatif' WHERE id = '88888888-3002-1000-0000-000000000004';
UPDATE production_tasks SET titre = 'Vie professionnelle et vie privée' WHERE id = '88888888-3002-1000-0000-000000000005';
UPDATE production_tasks SET titre = 'Habiter seul ou en famille' WHERE id = '88888888-3002-1000-0000-000000000006';
UPDATE production_tasks SET titre = 'Cuisine d''origine ou d''ici' WHERE id = '88888888-3002-1000-0000-000000000007';

