-- ============================================================================
-- V415 — TCF CE A2 — lot 15 (support : invitation)
-- ----------------------------------------------------------------------------
-- 10 items CE A2, theme 22222222-0000-0000-0000-000000000002.
-- Chaque item = une invitation originale (SVG style « document »)
-- + 1 question sur UNE information explicite + 4 choix (1 correct).
-- UUID déterministes : questions 11111111-a00f-1000-…, medias 11111111-a00f-5000-…,
-- choices 11111111-a00f-2100/2200/2300/2400-… (display_order 1..4).
-- ============================================================================


-- medias (IMAGE) — invitations référencées par les questions ci-dessous
INSERT INTO medias
  (id, type, url, storage_key, original_filename, content_type, size_bytes, duration_sec,
   alt_text, created_at, transcript, inline_svg)
VALUES
  ('11111111-a00f-5000-0000-000000000001', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Carton d''invitation à la pendaison de crémaillère d''Amadou : samedi 14 juin à 19h, 25 rue des Tilleuls à Angers ; apporter une boisson ; réponse demandée avant le 7 juin.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Invitation à la pendaison de crémaillère d''Amadou</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">INVITATION</text><text x="160" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">Pendaison de crémaillère</text><text x="160" y="80" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Amadou vous invite à fêter son nouvel appartement</text><text x="160" y="106" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C" text-anchor="middle">Samedi 14 juin à 19h</text><text x="160" y="128" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">25 rue des Tilleuls, Angers</text><text x="160" y="150" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="middle">Apportez une boisson !</text><line x1="32" y1="162" x2="288" y2="162" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F" text-anchor="middle">Réponse avant le 7 juin</text></svg>'),

  ('11111111-a00f-5000-0000-000000000002', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Faire-part de mariage de Lucia et Mateo : cérémonie à la mairie de Pau samedi 5 septembre à 15h, suivie d''un repas à la ferme du Grand Pré à 19h.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Faire-part de mariage de Lucia et Mateo</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">FAIRE-PART DE MARIAGE</text><text x="160" y="60" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Lucia et Mateo ont la joie de vous inviter</text><text x="160" y="78" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">à leur mariage</text><text x="160" y="106" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C" text-anchor="middle">Cérémonie : mairie de Pau</text><text x="160" y="126" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C" text-anchor="middle">Samedi 5 septembre à 15h</text><line x1="32" y1="144" x2="288" y2="144" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="166" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="middle">Repas à la ferme du Grand Pré, à 19h</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Route de Lescar — Pau</text></svg>'),

  ('11111111-a00f-5000-0000-000000000003', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Invitation aux 30 ans de Wei : pique-nique dimanche 22 mars à 12h30 au parc des Marronniers à Dijon ; en cas de pluie, rendez-vous à la salle des fêtes de la rue Carnot.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Invitation aux 30 ans de Wei</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">INVITATION — 30 ANS</text><text x="160" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">Wei fête ses 30 ans !</text><text x="160" y="84" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C" text-anchor="middle">Pique-nique dimanche 22 mars à 12h30</text><text x="160" y="106" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Parc des Marronniers, Dijon</text><text x="160" y="128" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Chacun vient avec sa bonne humeur</text><line x1="32" y1="144" x2="288" y2="144" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="166" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">En cas de pluie : salle des fêtes, rue Carnot</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Merci de prévenir Wei au 06 51 28 47 93</text></svg>'),

  ('11111111-a00f-5000-0000-000000000004', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Invitation au pot de départ à la retraite de Rachid : vendredi 28 novembre à 17h, salle de réunion du 2e étage, après 32 ans dans l''entreprise ; répondre avant le 20 novembre.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Invitation au pot de départ à la retraite de Rachid</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">POT DE DÉPART</text><text x="160" y="58" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Après 32 ans dans l''entreprise,</text><text x="160" y="76" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Rachid part à la retraite.</text><text x="160" y="102" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C" text-anchor="middle">Vendredi 28 novembre à 17h</text><text x="160" y="124" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Salle de réunion du 2e étage</text><line x1="32" y1="142" x2="288" y2="142" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="164" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F" text-anchor="middle">Merci de répondre avant le 20 novembre</text><text x="160" y="182" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Une cagnotte est ouverte à l''accueil</text></svg>'),

  ('11111111-a00f-5000-0000-000000000005', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Faire-part de baptême de Sofia, fille d''Olena et Pavlo : dimanche 12 avril à 11h à l''église Saint-Michel de Colmar, déjeuner ensuite au restaurant La Cigogne.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Faire-part de baptême de Sofia</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">BAPTÊME DE SOFIA</text><text x="160" y="60" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Olena et Pavlo sont heureux de vous inviter</text><text x="160" y="78" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">au baptême de leur fille</text><text x="160" y="104" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C" text-anchor="middle">Dimanche 12 avril à 11h</text><text x="160" y="126" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Église Saint-Michel, Colmar</text><line x1="32" y1="144" x2="288" y2="144" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="166" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="middle">Déjeuner ensuite au restaurant La Cigogne</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">4 place des Tanneurs — Colmar</text></svg>'),

  ('11111111-a00f-5000-0000-000000000006', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Invitation à la fête des voisins par Priya, voisine du 3e étage : jeudi 4 juin à 18h30 dans la cour de l''immeuble, 8 allée des Acacias à Mulhouse ; chacun apporte un plat à partager.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Invitation à la fête des voisins de Priya</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#168F5B" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#168F5B"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">FÊTE DES VOISINS</text><text x="160" y="58" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Priya, votre voisine du 3e étage, vous invite</text><text x="160" y="84" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C" text-anchor="middle">Jeudi 4 juin à 18h30</text><text x="160" y="106" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Dans la cour de l''immeuble</text><text x="160" y="124" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">8 allée des Acacias, Mulhouse</text><line x1="32" y1="142" x2="288" y2="142" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="164" font-family="Arial" font-size="12" font-weight="700" fill="#168F5B" text-anchor="middle">Chacun apporte un plat à partager !</text><text x="160" y="182" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Tables et boissons fournies par l''immeuble</text></svg>'),

  ('11111111-a00f-5000-0000-000000000007', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Invitation au repas annuel de l''association Les Jardins de Beaubreuil : dimanche 8 février à 12h30, salle polyvalente de Limoges ; participation 5 euros par personne, gratuit pour les enfants ; inscription auprès de Fatou.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Invitation au repas annuel de l''association Les Jardins de Beaubreuil</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">REPAS ANNUEL DE L''ASSOCIATION</text><text x="160" y="58" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Les Jardins de Beaubreuil vous invitent</text><text x="160" y="84" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C" text-anchor="middle">Dimanche 8 février à 12h30</text><text x="160" y="106" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Salle polyvalente, Limoges</text><text x="160" y="130" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="middle">Participation : 5 € par personne</text><text x="160" y="148" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="middle">Gratuit pour les enfants</text><line x1="32" y1="160" x2="288" y2="160" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Inscription auprès de Fatou, présidente de l''association</text></svg>'),

  ('11111111-a00f-5000-0000-000000000008', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Invitation à l''anniversaire des 7 ans d''Idriss, fils de Khadija : mercredi 13 mai de 15h à 18h, 12 rue des Cerisiers à Toulouse, goûter et jeux ; les parents viennent chercher les enfants à 18h.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Invitation à l''anniversaire des 7 ans d''Idriss</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">ANNIVERSAIRE — 7 ANS</text><text x="160" y="58" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Khadija invite les copains de la classe</text><text x="160" y="76" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">pour les 7 ans de son fils Idriss</text><text x="160" y="102" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C" text-anchor="middle">Mercredi 13 mai, de 15h à 18h</text><text x="160" y="124" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">12 rue des Cerisiers, Toulouse</text><text x="160" y="142" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="middle">Goûter et jeux au programme</text><line x1="32" y1="156" x2="288" y2="156" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="178" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">Les parents viennent chercher les enfants à 18h</text></svg>'),

  ('11111111-a00f-5000-0000-000000000009', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Invitation à la soirée jeux de société de Diego : vendredi 19 décembre à 20h, 3 impasse du Moulin à Besançon ; apporter son jeu préféré, pizzas offertes.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Invitation à la soirée jeux de société de Diego</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">SOIRÉE JEUX DE SOCIÉTÉ</text><text x="160" y="58" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Diego organise une soirée jeux chez lui</text><text x="160" y="84" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C" text-anchor="middle">Vendredi 19 décembre à 20h</text><text x="160" y="106" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">3 impasse du Moulin, Besançon</text><text x="160" y="130" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="middle">Apportez votre jeu préféré !</text><line x1="32" y1="146" x2="288" y2="146" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="168" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317" text-anchor="middle">Pizzas offertes</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Sonnez à l''interphone « D. Morales »</text></svg>'),

  ('11111111-a00f-5000-0000-00000000000a', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Invitation de la mairie de Niort à la cérémonie d''accueil des nouveaux habitants : samedi 7 mars à 10h30, salle du conseil de l''hôtel de ville ; inscription par téléphone au 05 49 12 34 56 avant le 27 février.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Invitation de la mairie de Niort à la cérémonie d''accueil des nouveaux habitants</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">MAIRIE DE NIORT — INVITATION</text><text x="160" y="58" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Cérémonie d''accueil des nouveaux habitants</text><text x="160" y="84" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C" text-anchor="middle">Samedi 7 mars à 10h30</text><text x="160" y="106" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Salle du conseil, hôtel de ville</text><text x="160" y="130" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">Inscription par téléphone : 05 49 12 34 56</text><line x1="32" y1="146" x2="288" y2="146" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="168" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F" text-anchor="middle">Avant le 27 février</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Verre de l''amitié offert à l''issue de la cérémonie</text></svg>');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-a00f-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00f-5000-0000-000000000001', 'A2', 'CE',
   'À quelle heure commence la pendaison de crémaillère ?',
   'L''invitation indique « **Samedi 14 juin à 19h** » : la fête commence donc à 19h. « 14h » confond l''heure avec la date du 14 juin. « 18h » et « 20h » sont des heures de soirée plausibles, mais aucune autre heure que 19h ne figure sur le carton d''invitation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00f-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00f-5000-0000-000000000002', 'A2', 'CE',
   'Où a lieu la cérémonie de mariage ?',
   'Le faire-part précise « Cérémonie : **mairie de Pau**, samedi 5 septembre à 15h ». La ferme du Grand Pré est le lieu du repas qui suit, à 19h : ce distracteur répondrait à « où a lieu le repas ? ». L''église n''est mentionnée nulle part sur le faire-part. « Au restaurant » est plausible pour un mariage mais ne correspond à aucun lieu cité.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00f-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00f-5000-0000-000000000003', 'A2', 'CE',
   'Où se retrouve-t-on en cas de pluie ?',
   'L''invitation précise « **En cas de pluie : salle des fêtes, rue Carnot** ». Le parc des Marronniers est le lieu prévu s''il fait beau : ce distracteur répondrait à « où a lieu le pique-nique ? ». « Chez Wei » et « au restaurant » ne sont mentionnés nulle part sur l''invitation — Wei est seulement la personne à prévenir par téléphone.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00f-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00f-5000-0000-000000000004', 'A2', 'CE',
   'Avant quelle date faut-il répondre à l''invitation ?',
   'La mention rouge demande de « répondre **avant le 20 novembre** ». « Le 28 novembre » est la date du pot de départ lui-même, pas la date limite de réponse. « Le 17 novembre » confond avec l''heure du pot (17h), et « le 2 novembre » avec le lieu (salle de réunion du 2e étage) : ces deux chiffres figurent sur l''invitation mais ne sont pas des dates.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00f-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00f-5000-0000-000000000005', 'A2', 'CE',
   'À quelle heure commence le baptême ?',
   'Le faire-part indique « **Dimanche 12 avril à 11h**, église Saint-Michel » : le baptême commence à 11h. « 12h » confond l''heure avec la date du 12 avril. « 10h » n''apparaît nulle part sur le faire-part. « 13h » serait une heure plausible pour le déjeuner au restaurant La Cigogne, mais elle n''est pas écrite.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00f-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00f-5000-0000-000000000006', 'A2', 'CE',
   'Que doit apporter chaque voisin ?',
   'L''invitation demande explicitement : « **Chacun apporte un plat à partager !** ». « Une boisson » est fausse : les boissons sont fournies par l''immeuble, comme les tables. « Une chaise » est plausible pour une fête en plein air mais n''est pas demandée. « Rien du tout » contredit directement la consigne écrite sur l''invitation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00f-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00f-5000-0000-000000000007', 'A2', 'CE',
   'Combien paie un adulte pour le repas ?',
   'L''invitation indique « Participation : **5 € par personne**, gratuit pour les enfants » : un adulte paie donc 5 €. « C''est gratuit » ne vaut que pour les enfants — c''est le piège principal de l''item. « 8 € » confond avec la date du repas (dimanche 8 février) et « 12 € » avec l''heure (12h30) : ces chiffres figurent sur l''invitation mais ne sont pas des prix.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00f-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00f-5000-0000-000000000008', 'A2', 'CE',
   'À quelle heure les parents viennent-ils chercher les enfants ?',
   'L''invitation précise « **Les parents viennent chercher les enfants à 18h** », ce qui correspond aussi à la fin de la fête (15h-18h). « 15h » est l''heure du début de l''anniversaire : ce distracteur répondrait à « à quelle heure les enfants arrivent-ils ? ». « 17h » n''apparaît nulle part. « 13h » confond avec la date du mercredi 13 mai.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00f-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00f-5000-0000-000000000009', 'A2', 'CE',
   'Quel jour a lieu la soirée jeux ?',
   'L''invitation annonce la soirée pour le « **Vendredi 19 décembre à 20h** ». « Samedi 20 décembre » confond le jour avec l''heure de début (20h). « Vendredi 3 décembre » confond avec le numéro de la rue (3 impasse du Moulin). « Jeudi 19 novembre » garde le bon chiffre 19 mais ni le bon jour ni le bon mois.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00f-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00f-5000-0000-00000000000a', 'A2', 'CE',
   'Comment faut-il s''inscrire à la cérémonie d''accueil ?',
   'L''invitation indique « **Inscription par téléphone : 05 49 12 34 56**, avant le 27 février » : il faut donc téléphoner à la mairie. « Par courrier » et « par e-mail » sont des moyens plausibles pour contacter une mairie mais ne figurent pas sur l''invitation. « Sur place le jour même » contredit la demande d''inscription avant le 27 février.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('11111111-a00f-2100-0000-000000000001', '11111111-a00f-1000-0000-000000000001', '18h', 'false', '1'),
  ('11111111-a00f-2200-0000-000000000001', '11111111-a00f-1000-0000-000000000001', '19h', 'true', '2'),
  ('11111111-a00f-2300-0000-000000000001', '11111111-a00f-1000-0000-000000000001', '20h', 'false', '3'),
  ('11111111-a00f-2400-0000-000000000001', '11111111-a00f-1000-0000-000000000001', '14h', 'false', '4'),

  ('11111111-a00f-2100-0000-000000000002', '11111111-a00f-1000-0000-000000000002', 'À la mairie de Pau', 'true', '1'),
  ('11111111-a00f-2200-0000-000000000002', '11111111-a00f-1000-0000-000000000002', 'À la ferme du Grand Pré', 'false', '2'),
  ('11111111-a00f-2300-0000-000000000002', '11111111-a00f-1000-0000-000000000002', 'À l''église', 'false', '3'),
  ('11111111-a00f-2400-0000-000000000002', '11111111-a00f-1000-0000-000000000002', 'Au restaurant', 'false', '4'),

  ('11111111-a00f-2100-0000-000000000003', '11111111-a00f-1000-0000-000000000003', 'Au parc des Marronniers', 'false', '1'),
  ('11111111-a00f-2200-0000-000000000003', '11111111-a00f-1000-0000-000000000003', 'Chez Wei', 'false', '2'),
  ('11111111-a00f-2300-0000-000000000003', '11111111-a00f-1000-0000-000000000003', 'À la salle des fêtes', 'true', '3'),
  ('11111111-a00f-2400-0000-000000000003', '11111111-a00f-1000-0000-000000000003', 'Au restaurant', 'false', '4'),

  ('11111111-a00f-2100-0000-000000000004', '11111111-a00f-1000-0000-000000000004', 'Le 28 novembre', 'false', '1'),
  ('11111111-a00f-2200-0000-000000000004', '11111111-a00f-1000-0000-000000000004', 'Le 17 novembre', 'false', '2'),
  ('11111111-a00f-2300-0000-000000000004', '11111111-a00f-1000-0000-000000000004', 'Le 2 novembre', 'false', '3'),
  ('11111111-a00f-2400-0000-000000000004', '11111111-a00f-1000-0000-000000000004', 'Le 20 novembre', 'true', '4'),

  ('11111111-a00f-2100-0000-000000000005', '11111111-a00f-1000-0000-000000000005', '12h', 'false', '1'),
  ('11111111-a00f-2200-0000-000000000005', '11111111-a00f-1000-0000-000000000005', '11h', 'true', '2'),
  ('11111111-a00f-2300-0000-000000000005', '11111111-a00f-1000-0000-000000000005', '10h', 'false', '3'),
  ('11111111-a00f-2400-0000-000000000005', '11111111-a00f-1000-0000-000000000005', '13h', 'false', '4'),

  ('11111111-a00f-2100-0000-000000000006', '11111111-a00f-1000-0000-000000000006', 'Un plat à partager', 'true', '1'),
  ('11111111-a00f-2200-0000-000000000006', '11111111-a00f-1000-0000-000000000006', 'Une boisson', 'false', '2'),
  ('11111111-a00f-2300-0000-000000000006', '11111111-a00f-1000-0000-000000000006', 'Une chaise', 'false', '3'),
  ('11111111-a00f-2400-0000-000000000006', '11111111-a00f-1000-0000-000000000006', 'Rien du tout', 'false', '4'),

  ('11111111-a00f-2100-0000-000000000007', '11111111-a00f-1000-0000-000000000007', '8 €', 'false', '1'),
  ('11111111-a00f-2200-0000-000000000007', '11111111-a00f-1000-0000-000000000007', 'C''est gratuit', 'false', '2'),
  ('11111111-a00f-2300-0000-000000000007', '11111111-a00f-1000-0000-000000000007', '5 €', 'true', '3'),
  ('11111111-a00f-2400-0000-000000000007', '11111111-a00f-1000-0000-000000000007', '12 €', 'false', '4'),

  ('11111111-a00f-2100-0000-000000000008', '11111111-a00f-1000-0000-000000000008', '15h', 'false', '1'),
  ('11111111-a00f-2200-0000-000000000008', '11111111-a00f-1000-0000-000000000008', '17h', 'false', '2'),
  ('11111111-a00f-2300-0000-000000000008', '11111111-a00f-1000-0000-000000000008', '13h', 'false', '3'),
  ('11111111-a00f-2400-0000-000000000008', '11111111-a00f-1000-0000-000000000008', '18h', 'true', '4'),

  ('11111111-a00f-2100-0000-000000000009', '11111111-a00f-1000-0000-000000000009', 'Vendredi 19 décembre', 'true', '1'),
  ('11111111-a00f-2200-0000-000000000009', '11111111-a00f-1000-0000-000000000009', 'Samedi 20 décembre', 'false', '2'),
  ('11111111-a00f-2300-0000-000000000009', '11111111-a00f-1000-0000-000000000009', 'Vendredi 3 décembre', 'false', '3'),
  ('11111111-a00f-2400-0000-000000000009', '11111111-a00f-1000-0000-000000000009', 'Jeudi 19 novembre', 'false', '4'),

  ('11111111-a00f-2100-0000-00000000000a', '11111111-a00f-1000-0000-00000000000a', 'Par courrier', 'false', '1'),
  ('11111111-a00f-2200-0000-00000000000a', '11111111-a00f-1000-0000-00000000000a', 'Sur place le jour même', 'false', '2'),
  ('11111111-a00f-2300-0000-00000000000a', '11111111-a00f-1000-0000-00000000000a', 'Par téléphone', 'true', '3'),
  ('11111111-a00f-2400-0000-00000000000a', '11111111-a00f-1000-0000-00000000000a', 'Par e-mail', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 10 items (NN=01..0a), UUID déterministes uniques (questions 1000-,
--     medias 5000-, choices 2100/2200/2300/2400-).
-- [x] Tous les supports = invitations, 10 occasions différentes (crémaillère,
--     mariage, anniversaire 30 ans, pot de retraite, baptême, fête des voisins,
--     repas d'association, anniversaire d'enfant, soirée jeux, cérémonie
--     d'accueil en mairie). Aucun support interdit (pas de panneau d'horaires,
--     petite annonce, étiquette, SMS, affichette, règlement, menu, carte
--     postale, post-it, programme, transport, vente d'objet, météo, plan).
-- [x] 4 choix par question, exactement 1 correct ; distribution des bonnes
--     réponses : pos1=3 (items 2,6,9), pos2=2 (items 1,5), pos3=3 (items
--     3,7,10), pos4=2 (items 4,8) — max 3 par position, 4 positions utilisées.
-- [x] Questions sur UNE information explicite (heure, lieu, date limite, prix,
--     action demandée, jour, moyen d'inscription) ; labels des choices = texte
--     de la réponse ; distracteurs = autres valeurs présentes ou plausibles de
--     l'invitation (confusions date/heure, lieu du repas vs cérémonie, etc.).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chacun des
--     3 distracteurs, point clé en **gras**.
-- [x] SVG : viewBox="0 0 320 200", Arial, palette charte, rouge réservé aux
--     infos critiques (dates limites de réponse/inscription) ; balises
--     équilibrées ; alt_text descriptif complet sur chaque media. Texte utile
--     ~10-40 mots par invitation.
-- [x] Apostrophes SQL doublées ('') partout (SVG, alt_text, statements,
--     explanations, labels). Pas de JSONB (choices en lignes). Contenu 100%
--     original, prénoms variés (Amadou, Lucia, Mateo, Wei, Rachid, Olena,
--     Pavlo, Priya, Fatou, Khadija, Diego), villes variées (Angers, Pau,
--     Dijon, Colmar, Mulhouse, Limoges, Toulouse, Besançon, Niort), chiffres
--     tous différents.
-- [x] competence_code : 5× ce_reperage_explicite (items 2,4,6,9,10),
--     5× ce_detail_specifique (items 1,3,5,7,8).
-- ============================================================================
