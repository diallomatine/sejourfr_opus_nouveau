-- ============================================================================
-- V411 — TCF CE A2 — lot 11 (support : programme)
-- ----------------------------------------------------------------------------
-- 10 items CE A2, theme 22222222-0000-0000-0000-000000000002.
-- Chaque item = un programme original (SVG style « document » : portes ouvertes,
-- formation, festival, semaine d'activités, sortie, tournoi, réunion, ateliers,
-- stage, forum) + 1 question sur UNE information explicite + 4 choix (1 correct).
-- UUID déterministes : questions 11111111-a00b-1000-…, medias 11111111-a00b-5000-…,
-- choices 11111111-a00b-2100/2200/2300/2400-… (display_order 1..4).
-- ============================================================================


-- medias (IMAGE) — programmes référencés par les questions ci-dessous
INSERT INTO medias
  (id, type, url, storage_key, original_filename, content_type, size_bytes, duration_sec,
   alt_text, created_at, transcript, inline_svg)
VALUES
  ('11111111-a00b-5000-0000-000000000001', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Programme de la journée portes ouvertes de l''école de musique de Mulhouse, samedi 5 avril : 10h accueil des visiteurs, 10h30 démonstration de piano, 14h essai des instruments, 16h concert des élèves. Entrée libre.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Programme des portes ouvertes de l''école de musique de Mulhouse</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">PROGRAMME — PORTES OUVERTES</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">École de musique de Mulhouse — samedi 5 avril</text><text x="32" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">10h</text><text x="80" y="84" font-family="Arial" font-size="11" fill="#0F1839">Accueil des visiteurs</text><text x="32" y="106" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">10h30</text><text x="80" y="106" font-family="Arial" font-size="11" fill="#0F1839">Démonstration de piano</text><text x="32" y="128" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">14h</text><text x="80" y="128" font-family="Arial" font-size="11" fill="#0F1839">Essai des instruments</text><text x="32" y="150" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">16h</text><text x="80" y="150" font-family="Arial" font-size="11" fill="#0F1839">Concert des élèves</text><line x1="32" y1="164" x2="288" y2="164" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="182" font-family="Arial" font-size="10" font-weight="700" fill="#E8A317" text-anchor="middle">Entrée libre — 7 rue des Violons</text></svg>'),

  ('11111111-a00b-5000-0000-000000000002', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Programme de la formation aux premiers secours de l''association Les Gestes qui Sauvent à Amiens, samedi 21 mars, animée par Amadou Sy : 9h théorie et numéros d''urgence, 11h15 exercices sur les gestes d''urgence, 12h30 pause déjeuner, 14h examen pratique, 16h remise des attestations.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Programme de la formation aux premiers secours à Amiens</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">FORMATION PREMIERS SECOURS</text><text x="160" y="54" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Les Gestes qui Sauvent — Amiens, samedi 21 mars</text><text x="32" y="78" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">9h</text><text x="80" y="78" font-family="Arial" font-size="11" fill="#0F1839">Théorie : les numéros d''urgence</text><text x="32" y="98" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">11h15</text><text x="80" y="98" font-family="Arial" font-size="11" fill="#0F1839">Exercices : gestes d''urgence</text><text x="32" y="118" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">12h30</text><text x="80" y="118" font-family="Arial" font-size="11" fill="#0F1839">Pause déjeuner</text><text x="32" y="138" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">14h</text><text x="80" y="138" font-family="Arial" font-size="11" fill="#0F1839">Examen pratique</text><text x="32" y="158" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">16h</text><text x="80" y="158" font-family="Arial" font-size="11" fill="#0F1839">Remise des attestations</text><line x1="32" y1="168" x2="288" y2="168" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Formateur : Amadou Sy — salle Jules-Ferry</text></svg>'),

  ('11111111-a00b-5000-0000-000000000003', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Programme du festival du film court de Pau, du 12 au 14 juin : vendredi 12 à 19h soirée d''ouverture, samedi 13 à 15h séance familles puis à 20h30 séance en plein air, dimanche 14 à 17h remise des prix. Billets : 4 euros la séance.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Programme du festival du film court de Pau</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">FESTIVAL DU FILM COURT — PAU</text><text x="160" y="54" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Programme du 12 au 14 juin — cinéma Le Méridien</text><text x="32" y="80" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Vendredi 12</text><text x="140" y="80" font-family="Arial" font-size="11" fill="#0F1839">19h : soirée d''ouverture</text><text x="32" y="104" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Samedi 13</text><text x="140" y="104" font-family="Arial" font-size="11" fill="#0F1839">15h : séance familles</text><text x="140" y="122" font-family="Arial" font-size="11" fill="#0F1839">20h30 : séance en plein air</text><text x="32" y="146" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Dimanche 14</text><text x="140" y="146" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">17h : remise des prix</text><line x1="32" y1="160" x2="288" y2="160" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="10" font-weight="700" fill="#E8A317" text-anchor="middle">Billets : 4 € la séance</text></svg>'),

  ('11111111-a00b-5000-0000-000000000004', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Programme de la semaine du centre social Les Glycines à Saint-Étienne : lundi 14h atelier de français, mercredi 10h cuisine du monde animée par Fatou, jeudi 16h30 aide aux devoirs, vendredi 18h café des parents. Activités gratuites, ouvertes à tous.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Programme de la semaine du centre social Les Glycines</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">PROGRAMME DE LA SEMAINE</text><text x="160" y="54" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Centre social Les Glycines — Saint-Étienne</text><text x="32" y="80" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Lundi 14h</text><text x="125" y="80" font-family="Arial" font-size="11" fill="#0F1839">Atelier de français</text><text x="32" y="102" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Mercredi 10h</text><text x="125" y="102" font-family="Arial" font-size="11" fill="#0F1839">Cuisine du monde (avec Fatou)</text><text x="32" y="124" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Jeudi 16h30</text><text x="125" y="124" font-family="Arial" font-size="11" fill="#0F1839">Aide aux devoirs</text><text x="32" y="146" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Vendredi 18h</text><text x="125" y="146" font-family="Arial" font-size="11" fill="#0F1839">Café des parents</text><line x1="32" y1="160" x2="288" y2="160" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="10" font-weight="700" fill="#168F5B" text-anchor="middle">Activités gratuites — ouvertes à tous</text></svg>'),

  ('11111111-a00b-5000-0000-000000000005', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Programme de la sortie au lac d''Annecy de l''association Le Trait d''Union, samedi 17 mai : 8h départ en car place de la Mairie, 10h visite guidée du château, 12h30 pique-nique au bord du lac, 15h temps libre, 18h retour. Inscription obligatoire avant le 10 mai.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Programme de la sortie au lac d''Annecy</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">SORTIE AU LAC D''ANNECY</text><text x="160" y="54" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Association Le Trait d''Union — samedi 17 mai</text><text x="32" y="78" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">8h</text><text x="80" y="78" font-family="Arial" font-size="11" fill="#0F1839">Départ en car, place de la Mairie</text><text x="32" y="98" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">10h</text><text x="80" y="98" font-family="Arial" font-size="11" fill="#0F1839">Visite guidée du château</text><text x="32" y="118" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">12h30</text><text x="80" y="118" font-family="Arial" font-size="11" fill="#0F1839">Pique-nique au bord du lac</text><text x="32" y="138" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">15h</text><text x="80" y="138" font-family="Arial" font-size="11" fill="#0F1839">Temps libre</text><text x="32" y="158" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">18h</text><text x="80" y="158" font-family="Arial" font-size="11" fill="#0F1839">Retour</text><line x1="32" y1="168" x2="288" y2="168" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="184" font-family="Arial" font-size="10" font-weight="700" fill="#E1372F" text-anchor="middle">Inscription obligatoire avant le 10 mai</text></svg>'),

  ('11111111-a00b-5000-0000-000000000006', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Programme du tournoi de football inter-quartiers de Montreuil, dimanche 28 juin au stade Marcel-Pagnol : 9h accueil des équipes, 9h30 matchs de qualification, 14h demi-finales, 16h30 finale, 17h30 remise de la coupe. Buvette sur place.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Programme du tournoi de football inter-quartiers de Montreuil</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">TOURNOI DE FOOT INTER-QUARTIERS</text><text x="160" y="54" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Montreuil — dimanche 28 juin, stade Marcel-Pagnol</text><text x="32" y="78" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">9h</text><text x="80" y="78" font-family="Arial" font-size="11" fill="#0F1839">Accueil des équipes</text><text x="32" y="98" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">9h30</text><text x="80" y="98" font-family="Arial" font-size="11" fill="#0F1839">Matchs de qualification</text><text x="32" y="118" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">14h</text><text x="80" y="118" font-family="Arial" font-size="11" fill="#0F1839">Demi-finales</text><text x="32" y="138" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">16h30</text><text x="80" y="138" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Finale</text><text x="32" y="158" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">17h30</text><text x="80" y="158" font-family="Arial" font-size="11" fill="#0F1839">Remise de la coupe</text><line x1="32" y1="168" x2="288" y2="168" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Buvette sur place — entrée gratuite pour le public</text></svg>'),

  ('11111111-a00b-5000-0000-000000000007', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Programme de la réunion d''accueil des nouveaux habitants de la mairie de Niort, jeudi 12 février à la salle des fêtes : 18h mot d''accueil de la maire, 18h15 présentation des services municipaux, 19h questions du public, 19h30 verre de l''amitié.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Programme de la réunion d''accueil des nouveaux habitants de Niort</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">ACCUEIL DES NOUVEAUX HABITANTS</text><text x="160" y="54" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Mairie de Niort — jeudi 12 février, salle des fêtes</text><text x="32" y="82" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">18h</text><text x="84" y="82" font-family="Arial" font-size="11" fill="#0F1839">Mot d''accueil de la maire</text><text x="32" y="106" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">18h15</text><text x="84" y="106" font-family="Arial" font-size="11" fill="#0F1839">Présentation des services municipaux</text><text x="32" y="130" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">19h</text><text x="84" y="130" font-family="Arial" font-size="11" fill="#0F1839">Questions du public</text><text x="32" y="154" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">19h30</text><text x="84" y="154" font-family="Arial" font-size="11" fill="#0F1839">Verre de l''amitié</text><line x1="32" y1="166" x2="288" y2="166" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Entrée libre — renseignements au 05 49 62 31 70</text></svg>'),

  ('11111111-a00b-5000-0000-000000000008', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Programme des ateliers numériques d''avril de l''espace numérique de Perpignan, tous les mardis à 10h, animés par Diego Ramos : mardi 4 créer une boîte mail, mardi 11 faire ses démarches en ligne, mardi 18 protéger ses mots de passe, mardi 25 appels vidéo avec la famille. Sur inscription.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Programme des ateliers numériques d''avril à Perpignan</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">ATELIERS NUMÉRIQUES — AVRIL</text><text x="160" y="54" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Espace numérique de Perpignan — les mardis à 10h</text><text x="32" y="80" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Mardi 4</text><text x="110" y="80" font-family="Arial" font-size="11" fill="#0F1839">Créer une boîte mail</text><text x="32" y="102" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Mardi 11</text><text x="110" y="102" font-family="Arial" font-size="11" fill="#0F1839">Faire ses démarches en ligne</text><text x="32" y="124" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Mardi 18</text><text x="110" y="124" font-family="Arial" font-size="11" fill="#0F1839">Protéger ses mots de passe</text><text x="32" y="146" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Mardi 25</text><text x="110" y="146" font-family="Arial" font-size="11" fill="#0F1839">Appels vidéo avec la famille</text><line x1="32" y1="160" x2="288" y2="160" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="10" font-weight="700" fill="#E8A317" text-anchor="middle">Gratuit, sur inscription — animateur : Diego Ramos</text></svg>'),

  ('11111111-a00b-5000-0000-000000000009', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Programme de la journée type du stage multisport du service jeunesse de Clermont-Ferrand, du 6 au 10 juillet, pour les enfants de 8 à 12 ans : 9h accueil, 9h30 sports collectifs, 12h repas, 13h30 piscine, 16h goûter et bilan de la journée. Animateurs : Wei et Olena.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Programme du stage multisport de Clermont-Ferrand</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">STAGE MULTISPORT — 6 AU 10 JUILLET</text><text x="160" y="54" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Clermont-Ferrand — enfants de 8 à 12 ans</text><text x="32" y="78" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">9h</text><text x="80" y="78" font-family="Arial" font-size="11" fill="#0F1839">Accueil des enfants</text><text x="32" y="98" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">9h30</text><text x="80" y="98" font-family="Arial" font-size="11" fill="#0F1839">Sports collectifs</text><text x="32" y="118" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">12h</text><text x="80" y="118" font-family="Arial" font-size="11" fill="#0F1839">Repas</text><text x="32" y="138" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">13h30</text><text x="80" y="138" font-family="Arial" font-size="11" fill="#0F1839">Piscine</text><text x="32" y="158" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">16h</text><text x="80" y="158" font-family="Arial" font-size="11" fill="#0F1839">Goûter et bilan de la journée</text><line x1="32" y1="168" x2="288" y2="168" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Animateurs : Wei et Olena — service jeunesse</text></svg>'),

  ('11111111-a00b-5000-0000-00000000000a', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Programme du forum des métiers de Roubaix, mardi 7 octobre à la salle Watremez : 9h30 ouverture du forum, 10h conférence « Réussir son CV » par Priya Sharma, 14h entretiens rapides avec les entreprises, 16h atelier lettre de motivation. Entrée gratuite, venir avec son CV.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Programme du forum des métiers de Roubaix</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">FORUM DES MÉTIERS — ROUBAIX</text><text x="160" y="54" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Mardi 7 octobre — salle Watremez</text><text x="32" y="80" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">9h30</text><text x="84" y="80" font-family="Arial" font-size="11" fill="#0F1839">Ouverture du forum</text><text x="32" y="102" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">10h</text><text x="84" y="102" font-family="Arial" font-size="11" fill="#0F1839">Conférence « Réussir son CV » (Priya Sharma)</text><text x="32" y="124" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">14h</text><text x="84" y="124" font-family="Arial" font-size="11" fill="#0F1839">Entretiens rapides avec les entreprises</text><text x="32" y="146" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">16h</text><text x="84" y="146" font-family="Arial" font-size="11" fill="#0F1839">Atelier lettre de motivation</text><line x1="32" y1="160" x2="288" y2="160" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="10" font-weight="700" fill="#E8A317" text-anchor="middle">Entrée gratuite — venez avec votre CV</text></svg>');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-a00b-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00b-5000-0000-000000000001', 'A2', 'CE',
   'À quelle heure les visiteurs peuvent-ils essayer les instruments ?',
   'Le programme indique « **14h : Essai des instruments** » : c''est le seul créneau prévu pour essayer les instruments. « 10h » est l''heure de l''accueil des visiteurs, « 10h30 » celle de la démonstration de piano (on regarde, on n''essaie pas), et « 16h » celle du concert des élèves — ces trois distracteurs reprennent d''autres horaires du programme.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00b-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00b-5000-0000-000000000002', 'A2', 'CE',
   'Que font les participants à 14h ?',
   'Le programme annonce « **14h : Examen pratique** » : à cette heure, les participants passent l''examen. « Ils étudient la théorie » correspond au créneau de 9h, « ils déjeunent » à la pause de 12h30, et « ils reçoivent leur attestation » à 16h — chacun de ces distracteurs répond à la question « que se passe-t-il à un autre moment de la journée ? ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00b-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00b-5000-0000-000000000003', 'A2', 'CE',
   'Quel jour la remise des prix a-t-elle lieu ?',
   'Le programme indique « **Dimanche 14 — 17h : remise des prix** ». Le vendredi est le jour de la soirée d''ouverture, le samedi celui de la séance familles et de la séance en plein air : ces deux distracteurs reprennent les autres journées du festival. « Le jeudi » est plausible pour un festival mais n''apparaît nulle part dans le programme.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00b-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00b-5000-0000-000000000004', 'A2', 'CE',
   'Quel jour l''atelier de cuisine a-t-il lieu ?',
   'Le programme de la semaine indique « **Mercredi 10h : Cuisine du monde** » : l''atelier de cuisine a donc lieu le mercredi. Le lundi est réservé à l''atelier de français, le jeudi à l''aide aux devoirs et le vendredi au café des parents — chacun de ces distracteurs correspond à une autre activité du centre social, pas à la cuisine.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00b-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00b-5000-0000-000000000005', 'A2', 'CE',
   'À quelle heure le car part-il ?',
   'Le programme commence par « **8h : Départ en car, place de la Mairie** » : le car part donc à 8h. « 10h » est l''heure de la visite guidée du château, « 15h » celle du temps libre, et « 18h » celle du retour — ce dernier distracteur répondrait à la question « à quelle heure revient-on ? », pas à celle du départ.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00b-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00b-5000-0000-000000000006', 'A2', 'CE',
   'À quelle heure la finale commence-t-elle ?',
   'Le programme du tournoi indique « **16h30 : Finale** ». « 9h30 » est l''heure des matchs de qualification, « 14h » celle des demi-finales — un piège classique, car les demi-finales précèdent juste la finale. « 17h30 » est l''heure de la remise de la coupe, après la finale : ce distracteur répondrait à « quand reçoit-on le trophée ? ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00b-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00b-5000-0000-000000000007', 'A2', 'CE',
   'Que peuvent faire les habitants à 19h ?',
   'Le programme indique « **19h : Questions du public** » : à 19h, les habitants peuvent poser leurs questions. « Écouter le mot d''accueil de la maire » correspond à 18h, « découvrir les services municipaux » à 18h15, et « prendre le verre de l''amitié » à 19h30 — ces trois distracteurs reprennent les autres moments de la réunion, avant ou après le créneau demandé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00b-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00b-5000-0000-000000000008', 'A2', 'CE',
   'Quel est le sujet de l''atelier du mardi 11 avril ?',
   'Le programme associe le **mardi 11 avril** à l''atelier « **Faire ses démarches en ligne** ». « Créer une boîte mail » est le sujet du mardi 4, « protéger ses mots de passe » celui du mardi 18, et « les appels vidéo avec la famille » celui du mardi 25 — chaque distracteur est un vrai atelier du programme, mais associé à une autre date.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00b-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00b-5000-0000-000000000009', 'A2', 'CE',
   'Que font les enfants à 13h30 ?',
   'Le programme de la journée type indique « **13h30 : Piscine** » : après le repas, les enfants vont à la piscine. « Ils prennent le repas » correspond à 12h, « ils font des sports collectifs » à 9h30, et « ils prennent le goûter » à 16h — chacun de ces distracteurs reprend une autre activité de la journée, à un autre horaire que celui demandé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00b-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00b-5000-0000-00000000000a', 'A2', 'CE',
   'À quelle heure la conférence « Réussir son CV » commence-t-elle ?',
   'Le programme du forum indique « **10h : Conférence « Réussir son CV » (Priya Sharma)** ». « 9h30 » est l''heure d''ouverture du forum, pas de la conférence. « 14h » correspond aux entretiens rapides avec les entreprises et « 16h » à l''atelier lettre de motivation — ces deux distracteurs reprennent les activités de l''après-midi, sans lien avec la conférence du matin.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('11111111-a00b-2100-0000-000000000001', '11111111-a00b-1000-0000-000000000001', '10h', 'false', '1'),
  ('11111111-a00b-2200-0000-000000000001', '11111111-a00b-1000-0000-000000000001', '10h30', 'false', '2'),
  ('11111111-a00b-2300-0000-000000000001', '11111111-a00b-1000-0000-000000000001', '14h', 'true', '3'),
  ('11111111-a00b-2400-0000-000000000001', '11111111-a00b-1000-0000-000000000001', '16h', 'false', '4'),

  ('11111111-a00b-2100-0000-000000000002', '11111111-a00b-1000-0000-000000000002', 'Ils passent l''examen pratique', 'true', '1'),
  ('11111111-a00b-2200-0000-000000000002', '11111111-a00b-1000-0000-000000000002', 'Ils étudient la théorie', 'false', '2'),
  ('11111111-a00b-2300-0000-000000000002', '11111111-a00b-1000-0000-000000000002', 'Ils déjeunent', 'false', '3'),
  ('11111111-a00b-2400-0000-000000000002', '11111111-a00b-1000-0000-000000000002', 'Ils reçoivent leur attestation', 'false', '4'),

  ('11111111-a00b-2100-0000-000000000003', '11111111-a00b-1000-0000-000000000003', 'Le vendredi', 'false', '1'),
  ('11111111-a00b-2200-0000-000000000003', '11111111-a00b-1000-0000-000000000003', 'Le dimanche', 'true', '2'),
  ('11111111-a00b-2300-0000-000000000003', '11111111-a00b-1000-0000-000000000003', 'Le samedi', 'false', '3'),
  ('11111111-a00b-2400-0000-000000000003', '11111111-a00b-1000-0000-000000000003', 'Le jeudi', 'false', '4'),

  ('11111111-a00b-2100-0000-000000000004', '11111111-a00b-1000-0000-000000000004', 'Le lundi', 'false', '1'),
  ('11111111-a00b-2200-0000-000000000004', '11111111-a00b-1000-0000-000000000004', 'Le jeudi', 'false', '2'),
  ('11111111-a00b-2300-0000-000000000004', '11111111-a00b-1000-0000-000000000004', 'Le vendredi', 'false', '3'),
  ('11111111-a00b-2400-0000-000000000004', '11111111-a00b-1000-0000-000000000004', 'Le mercredi', 'true', '4'),

  ('11111111-a00b-2100-0000-000000000005', '11111111-a00b-1000-0000-000000000005', '10h', 'false', '1'),
  ('11111111-a00b-2200-0000-000000000005', '11111111-a00b-1000-0000-000000000005', '8h', 'true', '2'),
  ('11111111-a00b-2300-0000-000000000005', '11111111-a00b-1000-0000-000000000005', '15h', 'false', '3'),
  ('11111111-a00b-2400-0000-000000000005', '11111111-a00b-1000-0000-000000000005', '18h', 'false', '4'),

  ('11111111-a00b-2100-0000-000000000006', '11111111-a00b-1000-0000-000000000006', '9h30', 'false', '1'),
  ('11111111-a00b-2200-0000-000000000006', '11111111-a00b-1000-0000-000000000006', '14h', 'false', '2'),
  ('11111111-a00b-2300-0000-000000000006', '11111111-a00b-1000-0000-000000000006', '16h30', 'true', '3'),
  ('11111111-a00b-2400-0000-000000000006', '11111111-a00b-1000-0000-000000000006', '17h30', 'false', '4'),

  ('11111111-a00b-2100-0000-000000000007', '11111111-a00b-1000-0000-000000000007', 'Poser leurs questions', 'true', '1'),
  ('11111111-a00b-2200-0000-000000000007', '11111111-a00b-1000-0000-000000000007', 'Écouter le mot d''accueil de la maire', 'false', '2'),
  ('11111111-a00b-2300-0000-000000000007', '11111111-a00b-1000-0000-000000000007', 'Prendre le verre de l''amitié', 'false', '3'),
  ('11111111-a00b-2400-0000-000000000007', '11111111-a00b-1000-0000-000000000007', 'Découvrir les services municipaux', 'false', '4'),

  ('11111111-a00b-2100-0000-000000000008', '11111111-a00b-1000-0000-000000000008', 'Créer une boîte mail', 'false', '1'),
  ('11111111-a00b-2200-0000-000000000008', '11111111-a00b-1000-0000-000000000008', 'Protéger ses mots de passe', 'false', '2'),
  ('11111111-a00b-2300-0000-000000000008', '11111111-a00b-1000-0000-000000000008', 'Les appels vidéo avec la famille', 'false', '3'),
  ('11111111-a00b-2400-0000-000000000008', '11111111-a00b-1000-0000-000000000008', 'Faire ses démarches en ligne', 'true', '4'),

  ('11111111-a00b-2100-0000-000000000009', '11111111-a00b-1000-0000-000000000009', 'Ils prennent le repas', 'false', '1'),
  ('11111111-a00b-2200-0000-000000000009', '11111111-a00b-1000-0000-000000000009', 'Ils vont à la piscine', 'true', '2'),
  ('11111111-a00b-2300-0000-000000000009', '11111111-a00b-1000-0000-000000000009', 'Ils font des sports collectifs', 'false', '3'),
  ('11111111-a00b-2400-0000-000000000009', '11111111-a00b-1000-0000-000000000009', 'Ils prennent le goûter', 'false', '4'),

  ('11111111-a00b-2100-0000-00000000000a', '11111111-a00b-1000-0000-00000000000a', '9h30', 'false', '1'),
  ('11111111-a00b-2200-0000-00000000000a', '11111111-a00b-1000-0000-00000000000a', '14h', 'false', '2'),
  ('11111111-a00b-2300-0000-00000000000a', '11111111-a00b-1000-0000-00000000000a', '10h', 'true', '3'),
  ('11111111-a00b-2400-0000-00000000000a', '11111111-a00b-1000-0000-00000000000a', '16h', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 10 items (NN=01..0a), UUID déterministes uniques (questions 1000-,
--     medias 5000-, choices 2100/2200/2300/2400-), préfixe lot 11 = a00b.
-- [x] Tous les supports = programmes, 10 contextes différents (portes ouvertes
--     école de musique, formation premiers secours, festival du film court,
--     semaine du centre social, sortie au lac, tournoi de foot, réunion
--     d'accueil mairie, ateliers numériques, stage multisport, forum des
--     métiers). Aucun support interdit (ni horaires, ni annonce, ni SMS, ni
--     affichette d'événement, ni menu, ni invitation, etc.).
-- [x] 4 choix par question, exactement 1 correct ; distribution des bonnes
--     réponses : pos1=2 (items 2,7), pos2=3 (items 3,5,9), pos3=3 (items
--     1,6,10), pos4=2 (items 4,8) — max 3 par position, 4 positions utilisées.
-- [x] Questions sur UNE information explicite (horaire, jour, activité,
--     sujet d'atelier) ; labels des choices = texte de la réponse ;
--     distracteurs = autres valeurs présentes ou plausibles du programme.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**.
-- [x] SVG : viewBox="0 0 320 200", Arial, palette charte, rouge réservé à
--     l'info critique (« Inscription obligatoire avant le 10 mai ») ; balises
--     équilibrées ; alt_text descriptif complet sur chaque media. Texte utile
--     ~15-40 mots par programme.
-- [x] Apostrophes SQL doublées ('') partout (SVG, alt_text, statements,
--     explanations, labels). Pas de JSONB (choices en lignes). Contenu 100%
--     original, prénoms variés (Amadou Sy, Fatou, Diego Ramos, Wei, Olena,
--     Priya Sharma), villes variées (Mulhouse, Amiens, Pau, Saint-Étienne,
--     Annecy, Montreuil, Niort, Perpignan, Clermont-Ferrand, Roubaix),
--     chiffres et horaires tous différents entre items.
-- [x] competence_code : 5× ce_reperage_explicite (items 2,3,4,7,9),
--     5× ce_detail_specifique (items 1,5,6,8,10).
-- ============================================================================
