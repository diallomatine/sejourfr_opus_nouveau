-- ============================================================================
-- V405 — TCF CE A2 — lot 05 (support : affichette d'événement)
-- ----------------------------------------------------------------------------
-- 10 items CE A2, theme 22222222-0000-0000-0000-000000000002.
-- Chaque item = une affichette d'événement originale (SVG style « document »)
-- + 1 question sur UNE information explicite + 4 choix (1 correct).
-- UUID déterministes : questions 11111111-a005-1000-…, medias 11111111-a005-5000-…,
-- choices 11111111-a005-2100/2200/2300/2400-… (display_order 1..4).
-- ============================================================================


-- medias (IMAGE) — affichettes d'événement référencées par les questions ci-dessous
INSERT INTO medias
  (id, type, url, storage_key, original_filename, content_type, size_bytes, duration_sec,
   alt_text, created_at, transcript, inline_svg)
VALUES
  ('11111111-a005-5000-0000-000000000001', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affichette du vide-grenier du quartier Saint-Michel à Toulouse : dimanche 14 juin de 8h à 17h, place des Tilleuls ; emplacement exposant 8 euros, inscription avant le 5 juin auprès de Lucia au 06 52 18 47 93 ; buvette sur place.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Affichette du vide-grenier du quartier Saint-Michel</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">VIDE-GRENIER</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Quartier Saint-Michel — Toulouse</text><text x="160" y="78" font-family="Arial" font-size="12" font-weight="700" fill="#168F5B" text-anchor="middle">Dimanche 14 juin — 8h - 17h</text><text x="160" y="98" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Place des Tilleuls</text><line x1="32" y1="110" x2="288" y2="110" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="130" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Emplacement exposant : 8 €</text><text x="32" y="152" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">Inscription avant le 5 juin</text><text x="32" y="170" font-family="Arial" font-size="10" fill="#0F1839">Lucia : 06 52 18 47 93</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Buvette sur place toute la journée</text></svg>'),

  ('11111111-a005-5000-0000-000000000002', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affichette d''un concert gratuit du groupe Diego et les Alizés à la salle des fêtes de Dijon, samedi 21 mars : ouverture des portes à 19h45, début du concert à 20h30 ; entrée gratuite, places limitées.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Affichette du concert gratuit de Diego et les Alizés</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">CONCERT GRATUIT</text><text x="160" y="56" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">Diego et les Alizés</text><text x="160" y="76" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Salle des fêtes — Dijon</text><text x="160" y="98" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C" text-anchor="middle">Samedi 21 mars</text><line x1="32" y1="112" x2="288" y2="112" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Ouverture des portes :</text><text x="288" y="132" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="end">19h45</text><text x="32" y="154" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Début du concert :</text><text x="288" y="154" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">20h30</text><text x="160" y="178" font-family="Arial" font-size="10" font-weight="700" fill="#E8A317" text-anchor="middle">Entrée gratuite — places limitées</text></svg>'),

  ('11111111-a005-5000-0000-000000000003', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affichette d''un atelier cuisine du monde animé par Priya au centre social Les Coteaux de Mulhouse, mercredi 8 avril de 14h à 16h : gratuit, ingrédients fournis, 12 places ; inscription obligatoire à l''accueil avant le 3 avril.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Affichette de l''atelier cuisine du monde animé par Priya</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#168F5B" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#168F5B"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">ATELIER CUISINE DU MONDE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Centre social Les Coteaux — Mulhouse</text><text x="160" y="78" font-family="Arial" font-size="12" font-weight="700" fill="#168F5B" text-anchor="middle">Mercredi 8 avril — 14h - 16h</text><text x="160" y="100" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Animé par Priya</text><line x1="32" y1="112" x2="288" y2="112" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Gratuit — ingrédients fournis</text><text x="32" y="152" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317">12 places seulement</text><text x="32" y="174" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">Inscription obligatoire à l''accueil avant le 3 avril</text></svg>'),

  ('11111111-a005-5000-0000-000000000004', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affichette du tournoi de pétanque du boulodrome des Remparts à Avignon, samedi 5 juillet : inscriptions sur place dès 13h, 5 euros par équipe, début des parties à 14h ; lots à gagner, buvette, contact Rachid au 06 71 24 58 36.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Affichette du tournoi de pétanque du boulodrome des Remparts</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">TOURNOI DE PÉTANQUE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Boulodrome des Remparts — Avignon</text><text x="160" y="78" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C" text-anchor="middle">Samedi 5 juillet</text><line x1="32" y1="92" x2="288" y2="92" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="112" font-family="Arial" font-size="11" fill="#0F1839">Inscriptions sur place dès 13h</text><text x="32" y="132" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">5 € par équipe</text><text x="32" y="152" font-family="Arial" font-size="11" fill="#0F1839">Début des parties : 14h</text><text x="160" y="172" font-family="Arial" font-size="10" font-weight="700" fill="#E8A317" text-anchor="middle">Lots à gagner — buvette sur place</text><text x="160" y="186" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Contact : Rachid — 06 71 24 58 36</text></svg>'),

  ('11111111-a005-5000-0000-000000000005', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affichette de la fête des voisins de la résidence des Acacias à Amiens, vendredi 29 mai à partir de 19h dans la cour intérieure : chacun apporte un plat à partager ; en cas de pluie, repli dans la salle commune ; organisée par Olena, appartement 12.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Affichette de la fête des voisins de la résidence des Acacias</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">FÊTE DES VOISINS</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Résidence des Acacias — Amiens</text><text x="160" y="78" font-family="Arial" font-size="12" font-weight="700" fill="#168F5B" text-anchor="middle">Vendredi 29 mai — à partir de 19h</text><text x="160" y="98" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">Dans la cour intérieure</text><line x1="32" y1="112" x2="288" y2="112" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Chacun apporte un plat à partager</text><text x="32" y="154" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">En cas de pluie : salle commune</text><text x="160" y="178" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Organisée par Olena — appartement 12</text></svg>'),

  ('11111111-a005-5000-0000-000000000006', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affichette d''une séance de cinéma en plein air au parc de la Roseraie à Perpignan, vendredi 18 juillet à 22h : projection du film Le Voyage de Mina, entrée libre ; apportez une couverture ou un siège pliant.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Affichette de la séance de cinéma en plein air au parc de la Roseraie</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#15296B" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#15296B"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">CINÉMA EN PLEIN AIR</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Parc de la Roseraie — Perpignan</text><text x="160" y="78" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C" text-anchor="middle">Vendredi 18 juillet — 22h</text><text x="160" y="102" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">« Le Voyage de Mina »</text><line x1="32" y1="116" x2="288" y2="116" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="140" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="middle">Entrée libre</text><text x="160" y="164" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">Apportez une couverture ou un siège pliant</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Séance organisée par la ville de Perpignan</text></svg>'),

  ('11111111-a005-5000-0000-000000000007', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affichette du marché de Noël de la place de la Révolution à Besançon, du 5 au 24 décembre, ouvert tous les jours de 10h à 19h : 40 chalets d''artisans, entrée libre.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Affichette du marché de Noël de Besançon</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#168F5B" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#168F5B"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">MARCHÉ DE NOËL</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Place de la Révolution — Besançon</text><text x="160" y="80" font-family="Arial" font-size="13" font-weight="700" fill="#1E3A8C" text-anchor="middle">Du 5 au 24 décembre</text><line x1="32" y1="96" x2="288" y2="96" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="118" font-family="Arial" font-size="11" fill="#0F1839">Tous les jours :</text><text x="288" y="118" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">10h - 19h</text><text x="32" y="142" font-family="Arial" font-size="11" fill="#0F1839">40 chalets d''artisans</text><text x="160" y="168" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317" text-anchor="middle">Entrée libre</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Artisanat local, décorations et gourmandises</text></svg>'),

  ('11111111-a005-5000-0000-000000000008', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affichette de la course solidaire Courir pour l''école au parc Beaumont de Pau, dimanche 12 octobre : retrait des dossards dès 8h30, départ à 9h30, parcours de 5 km ouvert à tous, dossard 10 euros, bénéfices reversés à l''école du quartier.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Affichette de la course solidaire Courir pour l''école</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">COURSE SOLIDAIRE</text><text x="160" y="56" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839" text-anchor="middle">« Courir pour l''école » — Parc Beaumont, Pau</text><text x="160" y="78" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C" text-anchor="middle">Dimanche 12 octobre</text><line x1="32" y1="92" x2="288" y2="92" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="112" font-family="Arial" font-size="11" fill="#0F1839">Retrait des dossards : dès 8h30</text><text x="32" y="134" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Départ : 9h30</text><text x="32" y="156" font-family="Arial" font-size="11" fill="#0F1839">Parcours de 5 km ouvert à tous</text><text x="160" y="180" font-family="Arial" font-size="10" font-weight="700" fill="#E8A317" text-anchor="middle">Dossard : 10 € — bénéfices reversés à l''école du quartier</text></svg>'),

  ('11111111-a005-5000-0000-000000000009', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affichette du spectacle de marionnettes Le Petit Nuage par la compagnie de Wei Zhang, salle Marcel-Pagnol à Metz, mercredi 11 février à 15h : durée 45 minutes, entrée 3 euros, conseillé à partir de 4 ans, réservation au 03 87 45 12 60.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Affichette du spectacle de marionnettes Le Petit Nuage</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="11" font-weight="700" fill="#FFFFFF" text-anchor="middle">SPECTACLE DE MARIONNETTES</text><text x="160" y="56" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">« Le Petit Nuage » — Compagnie Wei Zhang</text><text x="160" y="76" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Salle Marcel-Pagnol — Metz</text><text x="160" y="98" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C" text-anchor="middle">Mercredi 11 février — 15h</text><line x1="32" y1="112" x2="288" y2="112" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Durée : 45 minutes — Entrée : 3 €</text><text x="32" y="154" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317">À partir de 4 ans</text><text x="160" y="178" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Réservation conseillée : 03 87 45 12 60</text></svg>'),

  ('11111111-a005-5000-0000-00000000000a', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affichette du troc de plantes du jardin partagé des Hirondelles à Saint-Étienne, samedi 26 avril de 10h à 13h, animé par Amadou : échange de boutures, graines et plants ; entrée libre, apportez au moins une plante à échanger.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Affichette du troc de plantes du jardin partagé des Hirondelles</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#168F5B" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#168F5B"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">TROC DE PLANTES</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Jardin partagé des Hirondelles — Saint-Étienne</text><text x="160" y="78" font-family="Arial" font-size="12" font-weight="700" fill="#168F5B" text-anchor="middle">Samedi 26 avril — 10h - 13h</text><line x1="32" y1="92" x2="288" y2="92" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="114" font-family="Arial" font-size="11" fill="#0F1839">Échangez vos boutures, graines et plants</text><text x="32" y="136" font-family="Arial" font-size="11" fill="#0F1839">Entrée libre — animé par Amadou</text><text x="160" y="162" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">Apportez au moins une plante à échanger</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Conseils de jardinage offerts sur place</text></svg>');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-a005-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a005-5000-0000-000000000001', 'A2', 'CE',
   'Combien coûte un emplacement pour les exposants ?',
   'L''affichette indique « **Emplacement exposant : 8 €** » : c''est le prix demandé. « 5 € » confond avec la date limite d''inscription (avant le 5 juin), « 14 € » avec la date du vide-grenier (dimanche 14 juin) et « 17 € » avec l''heure de fin (17h) : ces trois nombres figurent bien sur l''affichette, mais aucun n''est un prix.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a005-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a005-5000-0000-000000000002', 'A2', 'CE',
   'À quelle heure le concert commence-t-il ?',
   'La ligne « **Début du concert : 20h30** » donne directement la réponse. « 19h45 » est l''heure d''ouverture des portes, pas du concert : ce distracteur répondrait à « à partir de quelle heure peut-on entrer ? ». « 21h » confond avec la date du samedi 21 mars, et « 18h » n''apparaît nulle part sur l''affichette.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a005-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a005-5000-0000-000000000003', 'A2', 'CE',
   'Que faut-il faire pour participer à l''atelier ?',
   'L''affichette précise « **Inscription obligatoire à l''accueil** avant le 3 avril » : il faut donc s''inscrire à l''accueil du centre social. « Payer 12 € » confond avec le nombre de places (12) alors que l''atelier est gratuit. « Apporter ses ingrédients » contredit la mention « ingrédients fournis ». « Réserver par téléphone » est plausible mais inventé : aucun numéro n''est indiqué, l''inscription se fait sur place.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a005-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a005-5000-0000-000000000004', 'A2', 'CE',
   'Combien coûte l''inscription d''une équipe au tournoi ?',
   'L''affichette annonce « **5 € par équipe** » : c''est le tarif d''inscription. « 13 € » confond avec l''heure d''ouverture des inscriptions (dès 13h) et « 14 € » avec l''heure de début des parties (14h) : ce sont des horaires, pas des prix. « C''est gratuit » est faux : seule la présence de lots et d''une buvette est annoncée, le tarif de 5 € est clairement affiché.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a005-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a005-5000-0000-000000000005', 'A2', 'CE',
   'Où la fête a-t-elle lieu en cas de pluie ?',
   'L''affichette indique en rouge « **En cas de pluie : salle commune** » : c''est le lieu de repli. La cour intérieure est le lieu prévu par beau temps : ce distracteur répondrait à « où la fête a-t-elle lieu normalement ? ». L''appartement 12 est celui d''Olena, l''organisatrice, pas un lieu de fête. Rien n''annonce une annulation : un repli est justement prévu.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a005-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a005-5000-0000-000000000006', 'A2', 'CE',
   'Que conseille l''affichette d''apporter pour la séance ?',
   'L''affichette demande d''« **apporter une couverture ou un siège pliant** » pour s''installer dans le parc. « Un pique-nique » et « une lampe de poche » sont plausibles pour une soirée en plein air, mais aucun des deux n''est mentionné. « Un parapluie » non plus : rien sur l''affichette ne parle de pluie ou de mauvais temps.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a005-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a005-5000-0000-000000000007', 'A2', 'CE',
   'Quel est le dernier jour du marché de Noël ?',
   'L''affichette indique « **Du 5 au 24 décembre** » : le marché se termine donc le 24 décembre. « Le 5 décembre » est le jour d''ouverture — ce distracteur répondrait à « quand le marché commence-t-il ? ». « Le 19 décembre » confond avec l''heure de fermeture quotidienne (19h) et « le 10 décembre » avec l''heure d''ouverture (10h) : ce sont des horaires, pas des dates.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a005-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a005-5000-0000-000000000008', 'A2', 'CE',
   'À quelle heure le départ de la course est-il donné ?',
   'La ligne « **Départ : 9h30** » donne la réponse. « 8h30 » est l''heure du retrait des dossards, pas du départ : ce distracteur répondrait à « à partir de quelle heure peut-on retirer son dossard ? ». « 10h » confond avec le prix du dossard (10 €) et « 12h » avec la date du dimanche 12 octobre : ces nombres figurent sur l''affichette mais ne sont pas des horaires de départ.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a005-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a005-5000-0000-000000000009', 'A2', 'CE',
   'À partir de quel âge le spectacle est-il conseillé ?',
   'L''affichette précise « **À partir de 4 ans** » : c''est l''âge conseillé. « 3 ans » confond avec le prix d''entrée (3 €), « 11 ans » avec la date du mercredi 11 février et « 15 ans » avec l''heure de la séance (15h) : ces trois nombres apparaissent sur l''affichette mais ne concernent pas l''âge du public.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a005-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a005-5000-0000-00000000000a', 'A2', 'CE',
   'Que doit-on apporter pour participer au troc ?',
   'L''affichette demande d''« **apporter au moins une plante à échanger** » : c''est le principe même du troc. « Des outils de jardinage » n''est mentionné nulle part. « De l''argent pour l''entrée » est faux : l''entrée est libre. « Rien du tout » contredit la consigne : sans plante à échanger, on ne peut pas participer au troc.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('11111111-a005-2100-0000-000000000001', '11111111-a005-1000-0000-000000000001', '5 €', 'false', '1'),
  ('11111111-a005-2200-0000-000000000001', '11111111-a005-1000-0000-000000000001', '8 €', 'true', '2'),
  ('11111111-a005-2300-0000-000000000001', '11111111-a005-1000-0000-000000000001', '14 €', 'false', '3'),
  ('11111111-a005-2400-0000-000000000001', '11111111-a005-1000-0000-000000000001', '17 €', 'false', '4'),

  ('11111111-a005-2100-0000-000000000002', '11111111-a005-1000-0000-000000000002', '19h45', 'false', '1'),
  ('11111111-a005-2200-0000-000000000002', '11111111-a005-1000-0000-000000000002', '21h', 'false', '2'),
  ('11111111-a005-2300-0000-000000000002', '11111111-a005-1000-0000-000000000002', '20h30', 'true', '3'),
  ('11111111-a005-2400-0000-000000000002', '11111111-a005-1000-0000-000000000002', '18h', 'false', '4'),

  ('11111111-a005-2100-0000-000000000003', '11111111-a005-1000-0000-000000000003', 'S''inscrire à l''accueil', 'true', '1'),
  ('11111111-a005-2200-0000-000000000003', '11111111-a005-1000-0000-000000000003', 'Payer 12 €', 'false', '2'),
  ('11111111-a005-2300-0000-000000000003', '11111111-a005-1000-0000-000000000003', 'Apporter ses ingrédients', 'false', '3'),
  ('11111111-a005-2400-0000-000000000003', '11111111-a005-1000-0000-000000000003', 'Réserver par téléphone', 'false', '4'),

  ('11111111-a005-2100-0000-000000000004', '11111111-a005-1000-0000-000000000004', '13 €', 'false', '1'),
  ('11111111-a005-2200-0000-000000000004', '11111111-a005-1000-0000-000000000004', '14 €', 'false', '2'),
  ('11111111-a005-2300-0000-000000000004', '11111111-a005-1000-0000-000000000004', 'C''est gratuit', 'false', '3'),
  ('11111111-a005-2400-0000-000000000004', '11111111-a005-1000-0000-000000000004', '5 €', 'true', '4'),

  ('11111111-a005-2100-0000-000000000005', '11111111-a005-1000-0000-000000000005', 'Dans la cour intérieure', 'false', '1'),
  ('11111111-a005-2200-0000-000000000005', '11111111-a005-1000-0000-000000000005', 'Dans la salle commune', 'true', '2'),
  ('11111111-a005-2300-0000-000000000005', '11111111-a005-1000-0000-000000000005', 'Dans l''appartement d''Olena', 'false', '3'),
  ('11111111-a005-2400-0000-000000000005', '11111111-a005-1000-0000-000000000005', 'Nulle part, la fête est annulée', 'false', '4'),

  ('11111111-a005-2100-0000-000000000006', '11111111-a005-1000-0000-000000000006', 'Un pique-nique', 'false', '1'),
  ('11111111-a005-2200-0000-000000000006', '11111111-a005-1000-0000-000000000006', 'Une lampe de poche', 'false', '2'),
  ('11111111-a005-2300-0000-000000000006', '11111111-a005-1000-0000-000000000006', 'Une couverture ou un siège pliant', 'true', '3'),
  ('11111111-a005-2400-0000-000000000006', '11111111-a005-1000-0000-000000000006', 'Un parapluie', 'false', '4'),

  ('11111111-a005-2100-0000-000000000007', '11111111-a005-1000-0000-000000000007', 'Le 24 décembre', 'true', '1'),
  ('11111111-a005-2200-0000-000000000007', '11111111-a005-1000-0000-000000000007', 'Le 5 décembre', 'false', '2'),
  ('11111111-a005-2300-0000-000000000007', '11111111-a005-1000-0000-000000000007', 'Le 19 décembre', 'false', '3'),
  ('11111111-a005-2400-0000-000000000007', '11111111-a005-1000-0000-000000000007', 'Le 10 décembre', 'false', '4'),

  ('11111111-a005-2100-0000-000000000008', '11111111-a005-1000-0000-000000000008', '8h30', 'false', '1'),
  ('11111111-a005-2200-0000-000000000008', '11111111-a005-1000-0000-000000000008', '10h', 'false', '2'),
  ('11111111-a005-2300-0000-000000000008', '11111111-a005-1000-0000-000000000008', '12h', 'false', '3'),
  ('11111111-a005-2400-0000-000000000008', '11111111-a005-1000-0000-000000000008', '9h30', 'true', '4'),

  ('11111111-a005-2100-0000-000000000009', '11111111-a005-1000-0000-000000000009', '3 ans', 'false', '1'),
  ('11111111-a005-2200-0000-000000000009', '11111111-a005-1000-0000-000000000009', '4 ans', 'true', '2'),
  ('11111111-a005-2300-0000-000000000009', '11111111-a005-1000-0000-000000000009', '11 ans', 'false', '3'),
  ('11111111-a005-2400-0000-000000000009', '11111111-a005-1000-0000-000000000009', '15 ans', 'false', '4'),

  ('11111111-a005-2100-0000-00000000000a', '11111111-a005-1000-0000-00000000000a', 'Des outils de jardinage', 'false', '1'),
  ('11111111-a005-2200-0000-00000000000a', '11111111-a005-1000-0000-00000000000a', 'De l''argent pour l''entrée', 'false', '2'),
  ('11111111-a005-2300-0000-00000000000a', '11111111-a005-1000-0000-00000000000a', 'Une plante à échanger', 'true', '3'),
  ('11111111-a005-2400-0000-00000000000a', '11111111-a005-1000-0000-00000000000a', 'Rien du tout', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 10 items (NN=01..0a), UUID déterministes uniques (questions 1000-,
--     medias 5000-, choices 2100/2200/2300/2400-).
-- [x] Tous les supports = affichettes d'événement, 10 événements différents
--     (vide-grenier, concert, atelier cuisine, tournoi de pétanque, fête des
--     voisins, cinéma en plein air, marché de Noël, course solidaire,
--     spectacle de marionnettes, troc de plantes). Aucun support interdit
--     (pas d'horaires, annonce, SMS, menu, invitation personnelle, etc.).
-- [x] 4 choix par question, exactement 1 correct ; distribution des bonnes
--     réponses : pos1=2 (items 3,7), pos2=3 (items 1,5,9), pos3=3 (items
--     2,6,10), pos4=2 (items 4,8) — max 3 par position, 4 positions utilisées.
-- [x] Questions sur UNE information explicite (prix, heure, lieu, date,
--     action demandée, âge) ; labels des choices = texte de la réponse ;
--     distracteurs = autres valeurs présentes ou plausibles de l'affichette.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**.
-- [x] SVG : viewBox="0 0 320 200", Arial, palette charte, rouge réservé aux
--     infos critiques (date limite d'inscription, repli en cas de pluie) ;
--     balises équilibrées ; alt_text descriptif complet sur chaque media.
--     Texte utile ~10-40 mots par affichette.
-- [x] Apostrophes SQL doublées ('') partout (SVG, alt_text, statements,
--     explanations, labels). Pas de JSONB (choices en lignes). Contenu 100%
--     original, prénoms/villes variés (Lucia, Diego, Priya, Rachid, Olena,
--     Wei, Amadou… Toulouse, Dijon, Mulhouse, Avignon, Amiens, Perpignan,
--     Besançon, Pau, Metz, Saint-Étienne), aucun texte recopié d'un sujet
--     existant.
-- [x] competence_code : 5× ce_reperage_explicite (items 2,3,5,6,10),
--     5× ce_detail_specifique (items 1,4,7,8,9).
-- ============================================================================
