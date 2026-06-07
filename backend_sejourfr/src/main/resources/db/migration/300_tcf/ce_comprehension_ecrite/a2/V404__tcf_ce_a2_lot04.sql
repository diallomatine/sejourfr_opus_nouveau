-- ============================================================================
-- V404 — TCF CE A2 — lot 04 (support : SMS)
-- ----------------------------------------------------------------------------
-- 10 items CE A2, theme 22222222-0000-0000-0000-000000000002.
-- Chaque item = un SMS original (SVG style « écran de messagerie »)
-- + 1 question sur UNE information explicite + 4 choix (1 correct).
-- UUID déterministes : questions 11111111-a004-1000-…, medias 11111111-a004-5000-…,
-- choices 11111111-a004-2100/2200/2300/2400-… (display_order 1..4).
-- ============================================================================


-- medias (IMAGE) — SMS référencés par les questions ci-dessous
INSERT INTO medias
  (id, type, url, storage_key, original_filename, content_type, size_bytes, duration_sec,
   alt_text, created_at, transcript, inline_svg)
VALUES
  ('11111111-a004-5000-0000-000000000001', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'SMS d''Amadou : le déménagement de samedi est avancé, on commence à 8h au lieu de 9h30 ; rendez-vous au 12 rue Pasteur, à Dijon.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>SMS d''Amadou : déménagement avancé à 8h</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="48" y="8" width="224" height="184" rx="10" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="48" y="8" width="224" height="30" rx="10" fill="#1E3A8C"/><rect x="48" y="24" width="224" height="14" fill="#1E3A8C"/><circle cx="66" cy="23" r="9" fill="#E8A317"/><text x="66" y="27" font-family="Arial" font-size="10" font-weight="700" fill="#FFFFFF" text-anchor="middle">A</text><text x="82" y="21" font-family="Arial" font-size="11" font-weight="700" fill="#FFFFFF">Amadou</text><text x="82" y="33" font-family="Arial" font-size="8" fill="#E8ECF8">SMS — jeudi 19:46</text><rect x="58" y="46" width="204" height="116" rx="10" fill="#E8ECF8"/><text x="68" y="66" font-family="Arial" font-size="10" fill="#0F1839">Salut ! C''est Amadou.</text><text x="68" y="82" font-family="Arial" font-size="10" fill="#0F1839">Le déménagement de samedi est</text><text x="68" y="98" font-family="Arial" font-size="10" font-weight="700" fill="#168F5B">avancé : on commence à 8h</text><text x="68" y="114" font-family="Arial" font-size="10" fill="#0F1839">au lieu de 9h30.</text><text x="68" y="130" font-family="Arial" font-size="10" fill="#0F1839">Rendez-vous au 12 rue Pasteur,</text><text x="68" y="146" font-family="Arial" font-size="10" fill="#0F1839">à Dijon. Merci !</text><rect x="58" y="170" width="204" height="16" rx="8" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1"/><text x="68" y="181" font-family="Arial" font-size="8" fill="#1E3A8C">Répondre…</text></svg>'),

  ('11111111-a004-5000-0000-000000000002', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'SMS du garage Morel à Limoges : la voiture est prête, à récupérer aujourd''hui avant 18h30 ; montant de la réparation 142 €, paiement par carte accepté.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>SMS du garage Morel : voiture prête, réparation 142 €</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="48" y="8" width="224" height="184" rx="10" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="48" y="8" width="224" height="30" rx="10" fill="#1E3A8C"/><rect x="48" y="24" width="224" height="14" fill="#1E3A8C"/><circle cx="66" cy="23" r="9" fill="#15296B"/><text x="66" y="27" font-family="Arial" font-size="10" font-weight="700" fill="#FFFFFF" text-anchor="middle">G</text><text x="82" y="21" font-family="Arial" font-size="11" font-weight="700" fill="#FFFFFF">Garage Morel — Limoges</text><text x="82" y="33" font-family="Arial" font-size="8" fill="#E8ECF8">SMS — mardi 11:08</text><rect x="58" y="46" width="204" height="100" rx="10" fill="#E8ECF8"/><text x="68" y="66" font-family="Arial" font-size="10" fill="#0F1839">Bonjour, votre voiture est prête.</text><text x="68" y="82" font-family="Arial" font-size="10" fill="#0F1839">Vous pouvez la récupérer</text><text x="68" y="98" font-family="Arial" font-size="10" fill="#0F1839">aujourd''hui avant 18h30.</text><text x="68" y="114" font-family="Arial" font-size="10" font-weight="700" fill="#1E3A8C">Montant de la réparation : 142 €</text><text x="68" y="130" font-family="Arial" font-size="10" fill="#0F1839">Paiement par carte accepté.</text><rect x="58" y="170" width="204" height="16" rx="8" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1"/><text x="68" y="181" font-family="Arial" font-size="8" fill="#1E3A8C">Répondre…</text></svg>'),

  ('11111111-a004-5000-0000-000000000003', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'SMS de l''Institut des Langues à Lucia : le cours de français de jeudi est déplacé en salle 204, au 2e étage (et non en salle 108) ; horaire inchangé, 18h.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>SMS de l''Institut des Langues : cours déplacé en salle 204</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="48" y="8" width="224" height="184" rx="10" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="48" y="8" width="224" height="30" rx="10" fill="#1E3A8C"/><rect x="48" y="24" width="224" height="14" fill="#1E3A8C"/><circle cx="66" cy="23" r="9" fill="#15296B"/><text x="66" y="27" font-family="Arial" font-size="10" font-weight="700" fill="#FFFFFF" text-anchor="middle">I</text><text x="82" y="21" font-family="Arial" font-size="11" font-weight="700" fill="#FFFFFF">Institut des Langues</text><text x="82" y="33" font-family="Arial" font-size="8" fill="#E8ECF8">SMS — lundi 09:30</text><rect x="58" y="46" width="204" height="116" rx="10" fill="#E8ECF8"/><text x="68" y="66" font-family="Arial" font-size="10" fill="#0F1839">Bonjour Lucia,</text><text x="68" y="82" font-family="Arial" font-size="10" fill="#0F1839">le cours de français de jeudi</text><text x="68" y="98" font-family="Arial" font-size="10" font-weight="700" fill="#168F5B">est déplacé en salle 204,</text><text x="68" y="114" font-family="Arial" font-size="10" fill="#0F1839">au 2e étage</text><text x="68" y="130" font-family="Arial" font-size="10" fill="#0F1839">(et non en salle 108).</text><text x="68" y="146" font-family="Arial" font-size="10" fill="#0F1839">Horaire inchangé : 18h.</text><rect x="58" y="170" width="204" height="16" rx="8" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1"/><text x="68" y="181" font-family="Arial" font-size="8" fill="#1E3A8C">Répondre…</text></svg>'),

  ('11111111-a004-5000-0000-000000000004', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'SMS de rappel du cabinet du Dr Wei, dentiste à Amiens : rendez-vous prévu mardi 17 juin à 14h15 ; en cas d''empêchement, appeler le 03 22 55 31 60 avant lundi.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>SMS de rappel : rendez-vous chez le dentiste mardi 17 juin à 14h15</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="48" y="8" width="224" height="184" rx="10" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="48" y="8" width="224" height="30" rx="10" fill="#1E3A8C"/><rect x="48" y="24" width="224" height="14" fill="#1E3A8C"/><circle cx="66" cy="23" r="9" fill="#15296B"/><text x="66" y="27" font-family="Arial" font-size="10" font-weight="700" fill="#FFFFFF" text-anchor="middle">C</text><text x="82" y="21" font-family="Arial" font-size="11" font-weight="700" fill="#FFFFFF">Cabinet Dr Wei — Amiens</text><text x="82" y="33" font-family="Arial" font-size="8" fill="#E8ECF8">SMS — vendredi 10:02</text><rect x="58" y="46" width="204" height="100" rx="10" fill="#E8ECF8"/><text x="68" y="66" font-family="Arial" font-size="10" fill="#0F1839">Rappel : votre rendez-vous</text><text x="68" y="82" font-family="Arial" font-size="10" fill="#0F1839">chez le Dr Wei, dentiste,</text><text x="68" y="98" font-family="Arial" font-size="10" font-weight="700" fill="#168F5B">est prévu mardi 17 juin à 14h15.</text><text x="68" y="114" font-family="Arial" font-size="10" fill="#0F1839">En cas d''empêchement, appelez</text><text x="68" y="130" font-family="Arial" font-size="10" fill="#0F1839">le 03 22 55 31 60 avant lundi.</text><rect x="58" y="170" width="204" height="16" rx="8" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1"/><text x="68" y="181" font-family="Arial" font-size="8" fill="#1E3A8C">Répondre…</text></svg>'),

  ('11111111-a004-5000-0000-000000000005', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'SMS d''Olena : son train a 25 minutes de retard, elle arrive à 17h50 et demande qu''on l''attende devant la sortie nord de la gare, près du café.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>SMS d''Olena : train en retard, attendre devant la sortie nord</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="48" y="8" width="224" height="184" rx="10" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="48" y="8" width="224" height="30" rx="10" fill="#1E3A8C"/><rect x="48" y="24" width="224" height="14" fill="#1E3A8C"/><circle cx="66" cy="23" r="9" fill="#168F5B"/><text x="66" y="27" font-family="Arial" font-size="10" font-weight="700" fill="#FFFFFF" text-anchor="middle">O</text><text x="82" y="21" font-family="Arial" font-size="11" font-weight="700" fill="#FFFFFF">Olena</text><text x="82" y="33" font-family="Arial" font-size="8" fill="#E8ECF8">SMS — 17:21</text><rect x="58" y="46" width="204" height="116" rx="10" fill="#E8ECF8"/><text x="68" y="66" font-family="Arial" font-size="10" fill="#0F1839">C''est Olena. Mon train a</text><text x="68" y="82" font-family="Arial" font-size="10" font-weight="700" fill="#E1372F">25 minutes de retard,</text><text x="68" y="98" font-family="Arial" font-size="10" fill="#0F1839">j''arrive à 17h50.</text><text x="68" y="114" font-family="Arial" font-size="10" fill="#0F1839">Attends-moi devant la</text><text x="68" y="130" font-family="Arial" font-size="10" font-weight="700" fill="#1E3A8C">sortie nord de la gare,</text><text x="68" y="146" font-family="Arial" font-size="10" fill="#0F1839">près du café. Désolée !</text><rect x="58" y="170" width="204" height="16" rx="8" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1"/><text x="68" y="181" font-family="Arial" font-size="8" fill="#1E3A8C">Répondre…</text></svg>'),

  ('11111111-a004-5000-0000-000000000006', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'SMS de Diego à Fatou : il demande de garder sa fille Léa samedi soir, de 19h à 23h, et propose 45 €.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>SMS de Diego : garde de Léa samedi soir, 45 € proposés</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="48" y="8" width="224" height="184" rx="10" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="48" y="8" width="224" height="30" rx="10" fill="#1E3A8C"/><rect x="48" y="24" width="224" height="14" fill="#1E3A8C"/><circle cx="66" cy="23" r="9" fill="#E8A317"/><text x="66" y="27" font-family="Arial" font-size="10" font-weight="700" fill="#FFFFFF" text-anchor="middle">D</text><text x="82" y="21" font-family="Arial" font-size="11" font-weight="700" fill="#FFFFFF">Diego</text><text x="82" y="33" font-family="Arial" font-size="8" fill="#E8ECF8">SMS — mercredi 18:54</text><rect x="58" y="46" width="204" height="100" rx="10" fill="#E8ECF8"/><text x="68" y="66" font-family="Arial" font-size="10" fill="#0F1839">Salut Fatou !</text><text x="68" y="82" font-family="Arial" font-size="10" fill="#0F1839">Peux-tu garder ma fille Léa</text><text x="68" y="98" font-family="Arial" font-size="10" fill="#0F1839">samedi soir, de 19h à 23h ?</text><text x="68" y="114" font-family="Arial" font-size="10" font-weight="700" fill="#168F5B">Je te propose 45 €.</text><text x="68" y="130" font-family="Arial" font-size="10" fill="#0F1839">Dis-moi vite. Merci !</text><rect x="58" y="170" width="204" height="16" rx="8" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1"/><text x="68" y="181" font-family="Arial" font-size="8" fill="#1E3A8C">Répondre…</text></svg>'),

  ('11111111-a004-5000-0000-000000000007', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'SMS de l''école Jean-Moulin : l''école sera fermée vendredi 13 mars en raison d''une grève ; les cours reprennent lundi matin. Signé : la directrice.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>SMS de l''école Jean-Moulin : fermeture vendredi 13 mars pour grève</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="48" y="8" width="224" height="184" rx="10" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="48" y="8" width="224" height="30" rx="10" fill="#1E3A8C"/><rect x="48" y="24" width="224" height="14" fill="#1E3A8C"/><circle cx="66" cy="23" r="9" fill="#15296B"/><text x="66" y="27" font-family="Arial" font-size="10" font-weight="700" fill="#FFFFFF" text-anchor="middle">E</text><text x="82" y="21" font-family="Arial" font-size="11" font-weight="700" fill="#FFFFFF">École Jean-Moulin</text><text x="82" y="33" font-family="Arial" font-size="8" fill="#E8ECF8">SMS — mercredi 16:40</text><rect x="58" y="46" width="204" height="116" rx="10" fill="#E8ECF8"/><text x="68" y="66" font-family="Arial" font-size="10" fill="#0F1839">Madame, Monsieur,</text><text x="68" y="82" font-family="Arial" font-size="10" fill="#0F1839">l''école Jean-Moulin sera</text><text x="68" y="98" font-family="Arial" font-size="10" font-weight="700" fill="#E1372F">fermée vendredi 13 mars</text><text x="68" y="114" font-family="Arial" font-size="10" fill="#0F1839">en raison d''une grève.</text><text x="68" y="130" font-family="Arial" font-size="10" fill="#0F1839">Les cours reprennent lundi matin.</text><text x="68" y="146" font-family="Arial" font-size="10" fill="#0F1839">La directrice</text><rect x="58" y="170" width="204" height="16" rx="8" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1"/><text x="68" y="181" font-family="Arial" font-size="8" fill="#1E3A8C">Répondre…</text></svg>'),

  ('11111111-a004-5000-0000-000000000008', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'SMS de Priya : elle a oublié ses clés sur la table de la cuisine et demande qu''on les lui apporte au restaurant Le Safran avant 15h.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>SMS de Priya : apporter ses clés au restaurant Le Safran</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="48" y="8" width="224" height="184" rx="10" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="48" y="8" width="224" height="30" rx="10" fill="#1E3A8C"/><rect x="48" y="24" width="224" height="14" fill="#1E3A8C"/><circle cx="66" cy="23" r="9" fill="#168F5B"/><text x="66" y="27" font-family="Arial" font-size="10" font-weight="700" fill="#FFFFFF" text-anchor="middle">P</text><text x="82" y="21" font-family="Arial" font-size="11" font-weight="700" fill="#FFFFFF">Priya</text><text x="82" y="33" font-family="Arial" font-size="8" fill="#E8ECF8">SMS — 13:35</text><rect x="58" y="46" width="204" height="116" rx="10" fill="#E8ECF8"/><text x="68" y="66" font-family="Arial" font-size="10" fill="#0F1839">C''est Priya. J''ai oublié mes</text><text x="68" y="82" font-family="Arial" font-size="10" fill="#0F1839">clés sur la table de la cuisine.</text><text x="68" y="98" font-family="Arial" font-size="10" fill="#0F1839">Peux-tu me les apporter au</text><text x="68" y="114" font-family="Arial" font-size="10" font-weight="700" fill="#1E3A8C">restaurant Le Safran</text><text x="68" y="130" font-family="Arial" font-size="10" fill="#0F1839">avant 15h ?</text><text x="68" y="146" font-family="Arial" font-size="10" fill="#0F1839">Merci beaucoup !</text><rect x="58" y="170" width="204" height="16" rx="8" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1"/><text x="68" y="181" font-family="Arial" font-size="8" fill="#1E3A8C">Répondre…</text></svg>'),

  ('11111111-a004-5000-0000-000000000009', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'SMS de Colis Express : le colis sera livré demain entre 10h et 12h au 25 avenue des Tilleuls, à Pau ; code de réception 4821, à présenter au livreur.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>SMS de Colis Express : livraison demain, code de réception 4821</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="48" y="8" width="224" height="184" rx="10" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="48" y="8" width="224" height="30" rx="10" fill="#1E3A8C"/><rect x="48" y="24" width="224" height="14" fill="#1E3A8C"/><circle cx="66" cy="23" r="9" fill="#15296B"/><text x="66" y="27" font-family="Arial" font-size="10" font-weight="700" fill="#FFFFFF" text-anchor="middle">C</text><text x="82" y="21" font-family="Arial" font-size="11" font-weight="700" fill="#FFFFFF">Colis Express</text><text x="82" y="33" font-family="Arial" font-size="8" fill="#E8ECF8">SMS — lundi 08:15</text><rect x="58" y="46" width="204" height="116" rx="10" fill="#E8ECF8"/><text x="68" y="66" font-family="Arial" font-size="10" fill="#0F1839">Bonjour, votre colis sera livré</text><text x="68" y="82" font-family="Arial" font-size="10" fill="#0F1839">demain entre 10h et 12h</text><text x="68" y="98" font-family="Arial" font-size="10" fill="#0F1839">au 25 avenue des Tilleuls,</text><text x="68" y="114" font-family="Arial" font-size="10" fill="#0F1839">à Pau.</text><text x="68" y="130" font-family="Arial" font-size="10" font-weight="700" fill="#168F5B">Code de réception : 4821</text><text x="68" y="146" font-family="Arial" font-size="10" fill="#0F1839">Présentez-le au livreur.</text><rect x="58" y="170" width="204" height="16" rx="8" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1"/><text x="68" y="181" font-family="Arial" font-size="8" fill="#1E3A8C">Répondre…</text></svg>'),

  ('11111111-a004-5000-0000-00000000000a', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'SMS de Rachid : le match de dimanche est reporté à cause de la pluie ; il aura lieu samedi prochain à 16h au stade des Acacias ; prévenir les autres joueurs.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>SMS de Rachid : match reporté à cause de la pluie</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="48" y="8" width="224" height="184" rx="10" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="48" y="8" width="224" height="30" rx="10" fill="#1E3A8C"/><rect x="48" y="24" width="224" height="14" fill="#1E3A8C"/><circle cx="66" cy="23" r="9" fill="#E8A317"/><text x="66" y="27" font-family="Arial" font-size="10" font-weight="700" fill="#FFFFFF" text-anchor="middle">R</text><text x="82" y="21" font-family="Arial" font-size="11" font-weight="700" fill="#FFFFFF">Rachid</text><text x="82" y="33" font-family="Arial" font-size="8" fill="#E8ECF8">SMS — samedi 20:05</text><rect x="58" y="46" width="204" height="116" rx="10" fill="#E8ECF8"/><text x="68" y="66" font-family="Arial" font-size="10" fill="#0F1839">Salut ! Le match de dimanche</text><text x="68" y="82" font-family="Arial" font-size="10" font-weight="700" fill="#E1372F">est reporté à cause de la pluie.</text><text x="68" y="98" font-family="Arial" font-size="10" fill="#0F1839">On jouera samedi prochain</text><text x="68" y="114" font-family="Arial" font-size="10" fill="#0F1839">à 16h, au stade des Acacias.</text><text x="68" y="130" font-family="Arial" font-size="10" fill="#0F1839">Préviens les autres.</text><text x="68" y="146" font-family="Arial" font-size="10" fill="#0F1839">Rachid</text><rect x="58" y="170" width="204" height="16" rx="8" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1"/><text x="68" y="181" font-family="Arial" font-size="8" fill="#1E3A8C">Répondre…</text></svg>');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-a004-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a004-5000-0000-000000000001', 'A2', 'CE',
   'À quelle heure commence le déménagement samedi ?',
   'Le SMS d''Amadou précise que le déménagement est avancé : « **on commence à 8h** au lieu de 9h30 ». « 9h30 » est l''ancienne heure, désormais annulée. « 12h » confond avec le numéro de la rue (12 rue Pasteur), qui n''est pas un horaire. « 10h » est une heure plausible mais qui n''apparaît nulle part dans le message.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a004-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a004-5000-0000-000000000002', 'A2', 'CE',
   'Quel est le montant de la réparation ?',
   'Le message du garage indique « **Montant de la réparation : 142 €** ». « 124 € » inverse les chiffres de la somme réelle. « 18 € » confond avec l''heure limite de récupération de la voiture (18h30), qui n''est pas un prix. « 130 € » est un montant plausible pour une réparation mais il est absent du SMS.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a004-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a004-5000-0000-000000000003', 'A2', 'CE',
   'Dans quelle salle a lieu le cours de français de jeudi ?',
   'Le SMS annonce que le cours « est déplacé **en salle 204**, au 2e étage ». La salle 108 est l''ancienne salle, explicitement remplacée (« et non en salle 108 ») : ce distracteur répondrait à « où le cours avait-il lieu avant ? ». Les salles 102 et 208 mélangent les chiffres des deux salles citées et ne figurent pas dans le message.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a004-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a004-5000-0000-000000000004', 'A2', 'CE',
   'Quel jour a lieu le rendez-vous chez le dentiste ?',
   'Le rappel indique que le rendez-vous est prévu « **mardi 17 juin à 14h15** ». « Lundi » est la date limite pour appeler le cabinet en cas d''empêchement, pas le jour du rendez-vous : ce distracteur répondrait à « avant quel jour faut-il prévenir ? ». « Mercredi » et « Jeudi » ne sont mentionnés nulle part dans le SMS.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a004-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a004-5000-0000-000000000005', 'A2', 'CE',
   'Où Olena demande-t-elle de l''attendre ?',
   'Olena écrit : « Attends-moi **devant la sortie nord** de la gare ». « Dans le café » déforme le repère donné : « près du café » sert à situer la sortie, pas à attendre à l''intérieur. « Sur le quai » et « devant la sortie sud » sont des lieux de gare plausibles, mais aucun des deux n''est indiqué dans le message.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a004-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a004-5000-0000-000000000006', 'A2', 'CE',
   'Combien Diego propose-t-il pour garder Léa ?',
   'Diego écrit : « **Je te propose 45 €** ». « 19 € » et « 23 € » confondent le prix avec les heures de garde (de 19h à 23h), qui ne sont pas des montants : ces distracteurs répondraient à « à quelle heure commence ou finit la garde ? ». « 35 € » est une somme plausible pour un baby-sitting mais elle n''apparaît pas dans le SMS.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a004-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a004-5000-0000-000000000007', 'A2', 'CE',
   'Quel jour l''école Jean-Moulin est-elle fermée ?',
   'Le message annonce en rouge que l''école « sera **fermée vendredi 13 mars** en raison d''une grève ». « Lundi » est le jour de la reprise des cours, pas celui de la fermeture : ce distracteur répondrait à « quand les cours reprennent-ils ? ». « Jeudi » et « Samedi » ne sont pas mentionnés dans le SMS, ce sont des jours plausibles mais inventés.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a004-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a004-5000-0000-000000000008', 'A2', 'CE',
   'Que demande Priya dans son message ?',
   'Priya a oublié ses clés et demande : « Peux-tu **me les apporter** au restaurant Le Safran avant 15h ? ». « Réserver une table » et « venir déjeuner » confondent le restaurant, simple lieu de remise des clés, avec une sortie au restaurant. « Fermer la porte de la cuisine » mélange avec la table de la cuisine, où les clés ont été oubliées — aucune porte n''est mentionnée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a004-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a004-5000-0000-000000000009', 'A2', 'CE',
   'Quel est le code de réception du colis ?',
   'Le SMS précise « **Code de réception : 4821** ». « 4812 » inverse les deux derniers chiffres du vrai code. « 1012 » colle les horaires de livraison (entre 10h et 12h), qui ne forment pas un code. « 2581 » mélange le numéro de l''adresse (25 avenue des Tilleuls) avec d''autres chiffres : il n''apparaît pas dans le message.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a004-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a004-5000-0000-00000000000a', 'A2', 'CE',
   'Pourquoi le match de dimanche est-il reporté ?',
   'Rachid écrit que le match « est reporté **à cause de la pluie** ». « Le froid » et « un autre match » sont des raisons d''annulation plausibles mais absentes du SMS. « Parce que le stade est fermé » confond avec le stade des Acacias, simplement cité comme lieu du prochain match samedi à 16h, sans aucune mention de fermeture.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('11111111-a004-2100-0000-000000000001', '11111111-a004-1000-0000-000000000001', 'À 9h30', 'false', '1'),
  ('11111111-a004-2200-0000-000000000001', '11111111-a004-1000-0000-000000000001', 'À 8h', 'true', '2'),
  ('11111111-a004-2300-0000-000000000001', '11111111-a004-1000-0000-000000000001', 'À 12h', 'false', '3'),
  ('11111111-a004-2400-0000-000000000001', '11111111-a004-1000-0000-000000000001', 'À 10h', 'false', '4'),

  ('11111111-a004-2100-0000-000000000002', '11111111-a004-1000-0000-000000000002', '18 €', 'false', '1'),
  ('11111111-a004-2200-0000-000000000002', '11111111-a004-1000-0000-000000000002', '124 €', 'false', '2'),
  ('11111111-a004-2300-0000-000000000002', '11111111-a004-1000-0000-000000000002', '130 €', 'false', '3'),
  ('11111111-a004-2400-0000-000000000002', '11111111-a004-1000-0000-000000000002', '142 €', 'true', '4'),

  ('11111111-a004-2100-0000-000000000003', '11111111-a004-1000-0000-000000000003', 'En salle 204', 'true', '1'),
  ('11111111-a004-2200-0000-000000000003', '11111111-a004-1000-0000-000000000003', 'En salle 108', 'false', '2'),
  ('11111111-a004-2300-0000-000000000003', '11111111-a004-1000-0000-000000000003', 'En salle 102', 'false', '3'),
  ('11111111-a004-2400-0000-000000000003', '11111111-a004-1000-0000-000000000003', 'En salle 208', 'false', '4'),

  ('11111111-a004-2100-0000-000000000004', '11111111-a004-1000-0000-000000000004', 'Lundi', 'false', '1'),
  ('11111111-a004-2200-0000-000000000004', '11111111-a004-1000-0000-000000000004', 'Mercredi', 'false', '2'),
  ('11111111-a004-2300-0000-000000000004', '11111111-a004-1000-0000-000000000004', 'Mardi', 'true', '3'),
  ('11111111-a004-2400-0000-000000000004', '11111111-a004-1000-0000-000000000004', 'Jeudi', 'false', '4'),

  ('11111111-a004-2100-0000-000000000005', '11111111-a004-1000-0000-000000000005', 'Sur le quai', 'false', '1'),
  ('11111111-a004-2200-0000-000000000005', '11111111-a004-1000-0000-000000000005', 'Devant la sortie nord de la gare', 'true', '2'),
  ('11111111-a004-2300-0000-000000000005', '11111111-a004-1000-0000-000000000005', 'Dans le café', 'false', '3'),
  ('11111111-a004-2400-0000-000000000005', '11111111-a004-1000-0000-000000000005', 'Devant la sortie sud de la gare', 'false', '4'),

  ('11111111-a004-2100-0000-000000000006', '11111111-a004-1000-0000-000000000006', '19 €', 'false', '1'),
  ('11111111-a004-2200-0000-000000000006', '11111111-a004-1000-0000-000000000006', '23 €', 'false', '2'),
  ('11111111-a004-2300-0000-000000000006', '11111111-a004-1000-0000-000000000006', '35 €', 'false', '3'),
  ('11111111-a004-2400-0000-000000000006', '11111111-a004-1000-0000-000000000006', '45 €', 'true', '4'),

  ('11111111-a004-2100-0000-000000000007', '11111111-a004-1000-0000-000000000007', 'Vendredi', 'true', '1'),
  ('11111111-a004-2200-0000-000000000007', '11111111-a004-1000-0000-000000000007', 'Lundi', 'false', '2'),
  ('11111111-a004-2300-0000-000000000007', '11111111-a004-1000-0000-000000000007', 'Jeudi', 'false', '3'),
  ('11111111-a004-2400-0000-000000000007', '11111111-a004-1000-0000-000000000007', 'Samedi', 'false', '4'),

  ('11111111-a004-2100-0000-000000000008', '11111111-a004-1000-0000-000000000008', 'De réserver une table au restaurant', 'false', '1'),
  ('11111111-a004-2200-0000-000000000008', '11111111-a004-1000-0000-000000000008', 'De fermer la porte de la cuisine', 'false', '2'),
  ('11111111-a004-2300-0000-000000000008', '11111111-a004-1000-0000-000000000008', 'De lui apporter ses clés', 'true', '3'),
  ('11111111-a004-2400-0000-000000000008', '11111111-a004-1000-0000-000000000008', 'De venir déjeuner avant 15h', 'false', '4'),

  ('11111111-a004-2100-0000-000000000009', '11111111-a004-1000-0000-000000000009', '2581', 'false', '1'),
  ('11111111-a004-2200-0000-000000000009', '11111111-a004-1000-0000-000000000009', '4821', 'true', '2'),
  ('11111111-a004-2300-0000-000000000009', '11111111-a004-1000-0000-000000000009', '1012', 'false', '3'),
  ('11111111-a004-2400-0000-000000000009', '11111111-a004-1000-0000-000000000009', '4812', 'false', '4'),

  ('11111111-a004-2100-0000-00000000000a', '11111111-a004-1000-0000-00000000000a', 'À cause du froid', 'false', '1'),
  ('11111111-a004-2200-0000-00000000000a', '11111111-a004-1000-0000-00000000000a', 'Parce que le stade est fermé', 'false', '2'),
  ('11111111-a004-2300-0000-00000000000a', '11111111-a004-1000-0000-00000000000a', 'À cause d''un autre match', 'false', '3'),
  ('11111111-a004-2400-0000-00000000000a', '11111111-a004-1000-0000-00000000000a', 'À cause de la pluie', 'true', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 10 items (NN=01..0a), UUID déterministes uniques (questions 1000-,
--     medias 5000-, choices 2100/2200/2300/2400-).
-- [x] Tous les supports = SMS, 10 situations différentes (déménagement avancé,
--     voiture prête au garage, cours déplacé de salle, rappel de rendez-vous
--     dentiste, train en retard, garde d'enfant, école fermée pour grève,
--     clés oubliées, livraison de colis avec code, match reporté). Aucun
--     support interdit (pas d'horaires, annonce, étiquette, menu, etc.).
-- [x] 4 choix par question, exactement 1 correct ; distribution des bonnes
--     réponses : pos1=2 (items 3,7), pos2=3 (items 1,5,9), pos3=2 (items 4,8),
--     pos4=3 (items 2,6,10) — max 3 par position, 4 positions utilisées.
-- [x] Questions sur UNE information explicite (heure, montant, salle, jour,
--     lieu, somme, code, raison, action demandée) ; labels des choices = texte
--     de la réponse ; distracteurs = autres valeurs présentes (ancienne heure,
--     heures de garde, numéro de rue, ancienne salle, jour limite d'appel)
--     ou plausibles mais absentes du document.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chacun des
--     3 distracteurs, point clé en **gras**.
-- [x] SVG : viewBox="0 0 320 200", style écran de messagerie (en-tête
--     expéditeur + bulle de message + barre « Répondre »), Arial, palette
--     charte ; rouge réservé aux infos critiques (retard du train, école
--     fermée, match reporté) ; balises équilibrées ; alt_text descriptif
--     complet sur chaque media. Texte utile ~15-35 mots par SMS.
-- [x] Apostrophes SQL doublées ('') partout (SVG, alt_text, statements,
--     explanations, labels). Pas de JSONB (choices en lignes). Contenu 100%
--     original, prénoms variés (Amadou, Lucia, Wei, Olena, Diego, Fatou,
--     Priya, Rachid), villes variées (Dijon, Limoges, Amiens, Pau),
--     chiffres tous différents (8h/9h30, 142 €, salle 204/108, 17 juin
--     14h15, 25 min/17h50, 45 €, 13 mars, 15h, 4821, 16h).
-- [x] competence_code : 5× ce_reperage_explicite (items 3,5,7,8,10),
--     5× ce_detail_specifique (items 1,2,4,6,9).
-- ============================================================================
