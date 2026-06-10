-- ============================================================================
-- V401 — TCF CE A2 — lot 01 (support : panneaux d'horaires)
-- ----------------------------------------------------------------------------
-- 10 items CE A2, theme 22222222-0000-0000-0000-000000000002.
-- Chaque item = un panneau d'horaires original (SVG style « document »)
-- + 1 question sur UNE information explicite + 4 choix (1 correct).
-- UUID déterministes : questions 11111111-a001-1000-…, medias 11111111-a001-5000-…,
-- choices 11111111-a001-2100/2200/2300/2400-… (display_order 1..4).
-- ============================================================================


-- medias (IMAGE) — panneaux d'horaires référencés par les questions ci-dessous
INSERT INTO medias
  (id, type, url, storage_key, original_filename, content_type, size_bytes, duration_sec,
   alt_text, created_at, transcript, inline_svg)
VALUES
  ('11111111-a001-5000-0000-000000000001', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''horaires du cabinet médical du Dr Fatou Ndiaye à Lyon : du lundi au vendredi, matin 8h30-12h sans rendez-vous, après-midi 14h-18h sur rendez-vous ; fermé le jeudi après-midi.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Horaires du cabinet médical du Dr Fatou Ndiaye</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">CABINET MÉDICAL</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Dr Fatou Ndiaye — Médecine générale</text><line x1="32" y1="66" x2="288" y2="66" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="88" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839">Lundi - Vendredi</text><text x="44" y="108" font-family="Arial" font-size="11" fill="#0F1839">Matin :</text><text x="96" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">8h30 - 12h</text><text x="168" y="108" font-family="Arial" font-size="10" fill="#0F1839">(sans rendez-vous)</text><text x="44" y="128" font-family="Arial" font-size="11" fill="#0F1839">Après-midi :</text><text x="116" y="128" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">14h - 18h</text><text x="182" y="128" font-family="Arial" font-size="10" fill="#0F1839">(sur rendez-vous)</text><text x="32" y="156" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F">FERMÉ le jeudi après-midi</text><text x="160" y="180" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">8 rue des Lilas, Lyon — Tél : 04 72 18 36 90</text></svg>'),

  ('11111111-a001-5000-0000-000000000002', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''horaires de la piscine municipale de Nantes : du lundi au vendredi de 12h à 20h, nocturne le jeudi jusqu''à 21h30, samedi et dimanche de 9h à 18h ; fermeture annuelle du 1er au 15 août.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Horaires de la piscine municipale de Nantes</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">PISCINE MUNICIPALE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Nantes — Horaires d''ouverture</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Lundi - Vendredi</text><text x="288" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">12h - 20h</text><text x="32" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Nocturne le jeudi</text><text x="288" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">jusqu''à 21h30</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Samedi - Dimanche</text><text x="288" y="132" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">9h - 18h</text><line x1="32" y1="148" x2="288" y2="148" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="170" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F" text-anchor="middle">Fermeture annuelle : du 1er au 15 août</text></svg>'),

  ('11111111-a001-5000-0000-000000000003', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''horaires de la médiathèque Jules-Verne de Tours : du mardi au samedi de 10h à 18h30, nocturne le mercredi jusqu''à 20h, dimanche de 14h à 18h ; fermée le lundi.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Horaires de la médiathèque Jules-Verne de Tours</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">MÉDIATHÈQUE JULES-VERNE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Tours — Horaires d''ouverture</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Mardi - Samedi</text><text x="288" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">10h - 18h30</text><text x="32" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Nocturne le mercredi</text><text x="288" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">jusqu''à 20h</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Dimanche</text><text x="288" y="132" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">14h - 18h</text><line x1="32" y1="148" x2="288" y2="148" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="170" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F" text-anchor="middle">FERMÉE le lundi</text></svg>'),

  ('11111111-a001-5000-0000-000000000004', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''horaires du service état civil de la mairie de Villeneuve-sur-Lot : du lundi au vendredi de 8h45 à 12h15 et de 13h30 à 17h, samedi de 9h à 12h uniquement sur rendez-vous ; fermé le dimanche.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Horaires du service état civil de la mairie</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">MAIRIE — SERVICE ÉTAT CIVIL</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Villeneuve-sur-Lot</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Lundi - Vendredi</text><text x="288" y="84" font-family="Arial" font-size="10" font-weight="700" fill="#168F5B" text-anchor="end">8h45 - 12h15 / 13h30 - 17h</text><text x="32" y="112" font-family="Arial" font-size="11" fill="#0F1839">Samedi</text><text x="288" y="112" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">9h - 12h</text><text x="288" y="130" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">uniquement sur rendez-vous</text><line x1="32" y1="146" x2="288" y2="146" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="168" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F">Fermé le dimanche</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Rendez-vous au 05 53 41 27 80</text></svg>'),

  ('11111111-a001-5000-0000-000000000005', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''horaires de la boulangerie Le Fournil de Rachid à Lille : ouverte lundi, mardi, jeudi, vendredi et samedi de 6h30 à 19h30, dimanche de 7h à 13h ; fermée le mercredi.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Horaires de la boulangerie Le Fournil de Rachid</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">BOULANGERIE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Le Fournil de Rachid — Lille</text><text x="32" y="88" font-family="Arial" font-size="11" fill="#0F1839">Lun, mar, jeu, ven, sam</text><text x="288" y="88" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">6h30 - 19h30</text><text x="32" y="116" font-family="Arial" font-size="11" fill="#0F1839">Dimanche</text><text x="288" y="116" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">7h - 13h</text><line x1="32" y1="134" x2="288" y2="134" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="160" font-family="Arial" font-size="13" font-weight="700" fill="#E1372F" text-anchor="middle">FERMÉE le mercredi</text><text x="160" y="182" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">14 rue de la Gare — pain frais toute la journée</text></svg>'),

  ('11111111-a001-5000-0000-000000000006', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''horaires de la déchetterie intercommunale de Combs-la-Ville : en été (avril-octobre) du lundi au samedi de 9h à 18h, en hiver (novembre-mars) du lundi au samedi de 9h à 17h, dimanche de 9h à 12h ; fermée les jours fériés.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Horaires de la déchetterie intercommunale</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">DÉCHETTERIE INTERCOMMUNALE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Combs-la-Ville — Route de Melun</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Été (avril - octobre) : lun - sam</text><text x="288" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">9h - 18h</text><text x="32" y="108" font-family="Arial" font-size="11" fill="#0F1839">Hiver (novembre - mars) : lun - sam</text><text x="288" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">9h - 17h</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Dimanche</text><text x="288" y="132" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">9h - 12h</text><line x1="32" y1="148" x2="288" y2="148" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="170" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F" text-anchor="middle">Fermée les jours fériés</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Accès réservé aux habitants — carte obligatoire</text></svg>'),

  ('11111111-a001-5000-0000-000000000007', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affichette de pharmacie de garde pour le dimanche 15 mars : la Pharmacie du Port à Marseille est ouverte de 9h à 20h sans interruption ; après 20h, appeler le 3237.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Affichette de pharmacie de garde du dimanche 15 mars</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#168F5B" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#168F5B"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">PHARMACIE DE GARDE</text><text x="160" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">Dimanche 15 mars</text><text x="160" y="86" font-family="Arial" font-size="13" font-weight="700" fill="#1E3A8C" text-anchor="middle">Pharmacie du Port</text><text x="160" y="104" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">2 quai des Pêcheurs, Marseille</text><text x="160" y="130" font-family="Arial" font-size="12" font-weight="700" fill="#168F5B" text-anchor="middle">Ouverte de 9h à 20h sans interruption</text><line x1="32" y1="146" x2="288" y2="146" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="170" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F" text-anchor="middle">Après 20h : appelez le 3237</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Service de garde des pharmacies des Bouches-du-Rhône</text></svg>'),

  ('11111111-a001-5000-0000-000000000008', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''horaires du musée d''histoire locale de Bordeaux : du mercredi au dimanche de 10h à 18h, nocturne le vendredi jusqu''à 21h, fermé lundi et mardi ; entrée gratuite le premier dimanche du mois.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Horaires du musée d''histoire locale de Bordeaux</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">MUSÉE D''HISTOIRE LOCALE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Bordeaux — Horaires des visites</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Mercredi - Dimanche</text><text x="288" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">10h - 18h</text><text x="32" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Nocturne le vendredi</text><text x="288" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">jusqu''à 21h</text><text x="32" y="134" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F">FERMÉ lundi et mardi</text><line x1="32" y1="150" x2="288" y2="150" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="172" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317" text-anchor="middle">Entrée gratuite le premier dimanche du mois</text></svg>'),

  ('11111111-a001-5000-0000-000000000009', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''horaires du bureau de poste du quartier gare à Strasbourg : du lundi au vendredi de 9h à 18h sans interruption, samedi de 9h à 12h30, fermé le dimanche ; retrait des colis avant 17h30 en semaine.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Horaires du bureau de poste du quartier gare</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">BUREAU DE POSTE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Quartier gare — Strasbourg</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Lundi - Vendredi</text><text x="288" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">9h - 18h sans interruption</text><text x="32" y="108" font-family="Arial" font-size="11" fill="#0F1839">Samedi</text><text x="288" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">9h - 12h30</text><text x="32" y="134" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Retrait des colis : avant 17h30 en semaine</text><line x1="32" y1="150" x2="288" y2="150" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="172" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F" text-anchor="middle">FERMÉ le dimanche</text></svg>'),

  ('11111111-a001-5000-0000-00000000000a', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''horaires du gymnase Léo-Lagrange à Rennes : en semaine, 9h-17h réservé aux scolaires puis 17h-22h aux associations sportives ; samedi de 10h à 18h ouvert à tous ; fermé le dimanche.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Horaires du gymnase Léo-Lagrange de Rennes</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">GYMNASE LÉO-LAGRANGE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Rennes — Planning de la semaine</text><text x="32" y="82" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Lundi - Vendredi</text><text x="44" y="102" font-family="Arial" font-size="11" fill="#0F1839">9h - 17h : réservé aux scolaires</text><text x="44" y="122" font-family="Arial" font-size="11" fill="#0F1839">17h - 22h : associations sportives</text><text x="32" y="148" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Samedi : 10h - 18h — ouvert à tous</text><line x1="32" y1="160" x2="288" y2="160" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F" text-anchor="middle">FERMÉ le dimanche</text></svg>');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-a001-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a001-5000-0000-000000000001', 'A2', 'CE',
   'Quel après-midi le cabinet du docteur Ndiaye est-il fermé ?',
   'Le panneau indique en rouge « **FERMÉ le jeudi après-midi** » : la bonne réponse est donc le jeudi. Le lundi, le mardi et le vendredi sont des jours d''ouverture normaux (8h30-12h le matin, 14h-18h l''après-midi) : ces trois distracteurs répondraient à la question « quels jours peut-on consulter ? », pas à celle de la fermeture.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a001-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a001-5000-0000-000000000002', 'A2', 'CE',
   'Jusqu''à quelle heure la piscine est-elle ouverte le jeudi ?',
   'Le panneau précise « **Nocturne le jeudi : jusqu''à 21h30** » : le jeudi, la piscine ferme donc à 21h30. « 20h » est l''heure de fermeture des autres jours de semaine, « 18h » celle du samedi et du dimanche, et « 12h » est l''heure d''ouverture en semaine — ce dernier distracteur répondrait à « à quelle heure la piscine ouvre-t-elle ? ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a001-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a001-5000-0000-000000000003', 'A2', 'CE',
   'Quel jour la médiathèque est-elle ouverte seulement l''après-midi ?',
   'La ligne « **Dimanche : 14h - 18h** » montre que la médiathèque n''ouvre que l''après-midi ce jour-là. Le lundi, elle est fermée toute la journée (ce distracteur répondrait à « quel jour est-elle fermée ? »). Le mercredi est le jour de la nocturne jusqu''à 20h, et le samedi elle ouvre dès 10h, comme les autres jours de la semaine.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a001-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a001-5000-0000-000000000004', 'A2', 'CE',
   'Que faut-il faire pour venir au service état civil le samedi matin ?',
   'Le panneau précise « Samedi : 9h - 12h, **uniquement sur rendez-vous** » : il faut donc prendre rendez-vous. « L''accueil est libre » vaut pour les jours de semaine, pas pour le samedi. Le justificatif de domicile n''est mentionné nulle part sur le panneau. « Arriver avant 8h45 » confond avec l''heure d''ouverture du lundi au vendredi, qui n''est pas une condition d''accès le samedi.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a001-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a001-5000-0000-000000000005', 'A2', 'CE',
   'Quel jour la boulangerie est-elle fermée ?',
   'La mention rouge « **FERMÉE le mercredi** » donne directement la réponse. Le lundi et le jeudi sont des jours d''ouverture normaux (6h30-19h30). Le dimanche est le distracteur le plus piégeux : beaucoup de commerces ferment ce jour-là, mais ici la boulangerie est ouverte le matin (7h-13h) — il répondrait plutôt à « quel jour ferme-t-elle plus tôt ? ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a001-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a001-5000-0000-000000000006', 'A2', 'CE',
   'À quelle heure la déchetterie ferme-t-elle en hiver, du lundi au samedi ?',
   'La ligne « **Hiver (novembre - mars) : lun - sam, 9h - 17h** » indique une fermeture à 17h. « 18h » est l''heure de fermeture en été (avril-octobre), « 12h » celle du dimanche, et « 9h » est l''heure d''ouverture — ce dernier distracteur répondrait à « à quelle heure la déchetterie ouvre-t-elle ? ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a001-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a001-5000-0000-000000000007', 'A2', 'CE',
   'Que faut-il faire pour obtenir un médicament après 20h ?',
   'L''affichette indique en rouge « **Après 20h : appelez le 3237** ». Aller à la Pharmacie du Port n''est possible que de 9h à 20h ce dimanche : ce distracteur répondrait à « où aller pendant la journée de garde ? ». « Attendre le lundi matin » n''est écrit nulle part. La mairie n''apparaît pas sur l''affichette : ce distracteur est plausible mais inventé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a001-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a001-5000-0000-000000000008', 'A2', 'CE',
   'Quand l''entrée du musée est-elle gratuite ?',
   'Le panneau annonce « **Entrée gratuite le premier dimanche du mois** ». « Le vendredi soir » correspond à la nocturne : c''est une ouverture prolongée jusqu''à 21h, pas une gratuité. « Tous les dimanches » sur-généralise : seul le premier dimanche du mois est gratuit. « Le mercredi » est un simple jour d''ouverture aux horaires normaux (10h-18h), sans gratuité annoncée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a001-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a001-5000-0000-000000000009', 'A2', 'CE',
   'Jusqu''à quelle heure peut-on retirer un colis en semaine ?',
   'Le panneau précise « **Retrait des colis : avant 17h30 en semaine** ». « 18h » est l''heure de fermeture des guichets du lundi au vendredi, pas la limite du retrait des colis. « 12h30 » est l''heure de fermeture du samedi, et « 9h » est l''heure d''ouverture du bureau — ce dernier distracteur répondrait à « à quelle heure le bureau ouvre-t-il ? ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a001-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a001-5000-0000-00000000000a', 'A2', 'CE',
   'Quel jour le gymnase est-il ouvert à tous ?',
   'La ligne verte « **Samedi : 10h - 18h — ouvert à tous** » donne la réponse. Le lundi et le vendredi, le gymnase est réservé aux scolaires (9h-17h) puis aux associations sportives (17h-22h) : le public n''y a pas accès librement. Le dimanche, il est fermé (mention en rouge) — ce distracteur répondrait à « quel jour le gymnase est-il fermé ? ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('11111111-a001-2100-0000-000000000001', '11111111-a001-1000-0000-000000000001', 'Le lundi', 'false', '1'),
  ('11111111-a001-2200-0000-000000000001', '11111111-a001-1000-0000-000000000001', 'Le jeudi', 'true', '2'),
  ('11111111-a001-2300-0000-000000000001', '11111111-a001-1000-0000-000000000001', 'Le mardi', 'false', '3'),
  ('11111111-a001-2400-0000-000000000001', '11111111-a001-1000-0000-000000000001', 'Le vendredi', 'false', '4'),

  ('11111111-a001-2100-0000-000000000002', '11111111-a001-1000-0000-000000000002', '18h', 'false', '1'),
  ('11111111-a001-2200-0000-000000000002', '11111111-a001-1000-0000-000000000002', '20h', 'false', '2'),
  ('11111111-a001-2300-0000-000000000002', '11111111-a001-1000-0000-000000000002', '21h30', 'true', '3'),
  ('11111111-a001-2400-0000-000000000002', '11111111-a001-1000-0000-000000000002', '12h', 'false', '4'),

  ('11111111-a001-2100-0000-000000000003', '11111111-a001-1000-0000-000000000003', 'Le dimanche', 'true', '1'),
  ('11111111-a001-2200-0000-000000000003', '11111111-a001-1000-0000-000000000003', 'Le lundi', 'false', '2'),
  ('11111111-a001-2300-0000-000000000003', '11111111-a001-1000-0000-000000000003', 'Le mercredi', 'false', '3'),
  ('11111111-a001-2400-0000-000000000003', '11111111-a001-1000-0000-000000000003', 'Le samedi', 'false', '4'),

  ('11111111-a001-2100-0000-000000000004', '11111111-a001-1000-0000-000000000004', 'Rien, l''accueil est libre', 'false', '1'),
  ('11111111-a001-2200-0000-000000000004', '11111111-a001-1000-0000-000000000004', 'Apporter un justificatif de domicile', 'false', '2'),
  ('11111111-a001-2300-0000-000000000004', '11111111-a001-1000-0000-000000000004', 'Arriver avant 8h45', 'false', '3'),
  ('11111111-a001-2400-0000-000000000004', '11111111-a001-1000-0000-000000000004', 'Prendre rendez-vous', 'true', '4'),

  ('11111111-a001-2100-0000-000000000005', '11111111-a001-1000-0000-000000000005', 'Le lundi', 'false', '1'),
  ('11111111-a001-2200-0000-000000000005', '11111111-a001-1000-0000-000000000005', 'Le mercredi', 'true', '2'),
  ('11111111-a001-2300-0000-000000000005', '11111111-a001-1000-0000-000000000005', 'Le dimanche', 'false', '3'),
  ('11111111-a001-2400-0000-000000000005', '11111111-a001-1000-0000-000000000005', 'Le jeudi', 'false', '4'),

  ('11111111-a001-2100-0000-000000000006', '11111111-a001-1000-0000-000000000006', '12h', 'false', '1'),
  ('11111111-a001-2200-0000-000000000006', '11111111-a001-1000-0000-000000000006', '18h', 'false', '2'),
  ('11111111-a001-2300-0000-000000000006', '11111111-a001-1000-0000-000000000006', '17h', 'true', '3'),
  ('11111111-a001-2400-0000-000000000006', '11111111-a001-1000-0000-000000000006', '9h', 'false', '4'),

  ('11111111-a001-2100-0000-000000000007', '11111111-a001-1000-0000-000000000007', 'Appeler le 3237', 'true', '1'),
  ('11111111-a001-2200-0000-000000000007', '11111111-a001-1000-0000-000000000007', 'Aller à la Pharmacie du Port', 'false', '2'),
  ('11111111-a001-2300-0000-000000000007', '11111111-a001-1000-0000-000000000007', 'Attendre le lundi matin', 'false', '3'),
  ('11111111-a001-2400-0000-000000000007', '11111111-a001-1000-0000-000000000007', 'Se présenter à la mairie', 'false', '4'),

  ('11111111-a001-2100-0000-000000000008', '11111111-a001-1000-0000-000000000008', 'Le vendredi soir', 'false', '1'),
  ('11111111-a001-2200-0000-000000000008', '11111111-a001-1000-0000-000000000008', 'Tous les dimanches', 'false', '2'),
  ('11111111-a001-2300-0000-000000000008', '11111111-a001-1000-0000-000000000008', 'Le mercredi', 'false', '3'),
  ('11111111-a001-2400-0000-000000000008', '11111111-a001-1000-0000-000000000008', 'Le premier dimanche du mois', 'true', '4'),

  ('11111111-a001-2100-0000-000000000009', '11111111-a001-1000-0000-000000000009', '12h30', 'false', '1'),
  ('11111111-a001-2200-0000-000000000009', '11111111-a001-1000-0000-000000000009', '18h', 'false', '2'),
  ('11111111-a001-2300-0000-000000000009', '11111111-a001-1000-0000-000000000009', '17h30', 'true', '3'),
  ('11111111-a001-2400-0000-000000000009', '11111111-a001-1000-0000-000000000009', '9h', 'false', '4'),

  ('11111111-a001-2100-0000-00000000000a', '11111111-a001-1000-0000-00000000000a', 'Le lundi', 'false', '1'),
  ('11111111-a001-2200-0000-00000000000a', '11111111-a001-1000-0000-00000000000a', 'Le samedi', 'true', '2'),
  ('11111111-a001-2300-0000-00000000000a', '11111111-a001-1000-0000-00000000000a', 'Le vendredi', 'false', '3'),
  ('11111111-a001-2400-0000-00000000000a', '11111111-a001-1000-0000-00000000000a', 'Le dimanche', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 10 items (NN=01..0a), UUID déterministes uniques (questions 1000-,
--     medias 5000-, choices 2100/2200/2300/2400-).
-- [x] Tous les supports = panneaux d'horaires, 10 établissements différents
--     (cabinet médical, piscine, médiathèque, mairie, boulangerie, déchetterie,
--     pharmacie de garde, musée, poste, gymnase). Aucun support interdit.
-- [x] 4 choix par question, exactement 1 correct ; distribution des bonnes
--     réponses : pos1=2 (items 3,7), pos2=3 (items 1,5,10), pos3=3 (items
--     2,6,9), pos4=2 (items 4,8) — max 3 par position, 4 positions utilisées.
-- [x] Questions sur UNE information explicite (horaire, jour, condition) ;
--     labels des choices = texte de la réponse ; distracteurs = autres valeurs
--     présentes ou plausibles du panneau.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**.
-- [x] SVG : viewBox="0 0 320 200", Arial, palette charte, rouge réservé aux
--     infos critiques (FERMÉ / après 20h) ; balises équilibrées ; alt_text
--     descriptif complet sur chaque media. Texte utile ~10-40 mots par panneau.
-- [x] Apostrophes SQL doublées ('') partout (SVG, alt_text, statements,
--     explanations, labels). Pas de JSONB (choices en lignes). Contenu 100%
--     original, prénoms/villes variés (Ndiaye, Rachid… Lyon, Nantes, Tours,
--     Villeneuve-sur-Lot, Lille, Combs-la-Ville, Marseille, Bordeaux,
--     Strasbourg, Rennes), aucun chiffre recopié d'un sujet existant.
-- [x] competence_code : 5× ce_reperage_explicite (items 1,4,5,7,10),
--     5× ce_detail_specifique (items 2,3,6,8,9).
-- ============================================================================
