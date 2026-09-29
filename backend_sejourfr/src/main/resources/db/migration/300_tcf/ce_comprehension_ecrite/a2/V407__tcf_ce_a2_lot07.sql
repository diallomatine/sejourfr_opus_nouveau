-- ============================================================================
-- V407 — TCF CE A2 — lot 07 (support : menu)
-- ----------------------------------------------------------------------------
-- 10 items CE A2, theme 22222222-0000-0000-0000-000000000002.
-- Chaque item = un menu original (restaurant, cantine, crêperie, food truck,
-- pizzeria, cafétéria, salon de thé, menu enfant, brasserie) en SVG style
-- « document » + 1 question sur UNE information explicite + 4 choix (1 correct).
-- UUID déterministes : questions 11111111-a007-1000-…, medias 11111111-a007-5000-…,
-- choices 11111111-a007-2100/2200/2300/2400-… (display_order 1..4).
-- ============================================================================


-- medias (IMAGE) — menus référencés par les questions ci-dessous
INSERT INTO medias
  (id, type, url, storage_key, original_filename, content_type, size_bytes, duration_sec,
   alt_text, created_at, transcript, inline_svg)
VALUES
  ('11111111-a007-5000-0000-000000000001', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Menu du jour du restaurant La Table d''Olena à Dijon : entrée + plat 14,50 € ; plat + dessert 13,50 € ; entrée + plat + dessert 17 € ; plat du jour : bœuf bourguignon ; menu du jour servi uniquement le midi.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Menu du jour du restaurant La Table d''Olena</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">LA TABLE D''OLENA</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Dijon — Menu du jour</text><text x="32" y="82" font-family="Arial" font-size="11" fill="#0F1839">Entrée + plat</text><text x="288" y="82" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">14,50 €</text><text x="32" y="104" font-family="Arial" font-size="11" fill="#0F1839">Plat + dessert</text><text x="288" y="104" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">13,50 €</text><text x="32" y="126" font-family="Arial" font-size="11" fill="#0F1839">Entrée + plat + dessert</text><text x="288" y="126" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">17 €</text><text x="32" y="150" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Plat du jour : bœuf bourguignon</text><line x1="32" y1="162" x2="288" y2="162" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F" text-anchor="middle">Menu du jour servi uniquement le midi</text></svg>'),

  ('11111111-a007-5000-0000-000000000002', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Menu de la cantine de l''école Jean-Moulin à Angers pour le mardi 12 mai : entrée salade de tomates, plat poisson pané et riz, produit laitier fromage blanc, dessert compote de pommes ; mention : présence de gluten.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Menu de la cantine de l''école Jean-Moulin</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">CANTINE SCOLAIRE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">École Jean-Moulin, Angers — Mardi 12 mai</text><text x="32" y="82" font-family="Arial" font-size="11" fill="#0F1839">Entrée :</text><text x="288" y="82" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839" text-anchor="end">salade de tomates</text><text x="32" y="104" font-family="Arial" font-size="11" fill="#0F1839">Plat :</text><text x="288" y="104" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839" text-anchor="end">poisson pané et riz</text><text x="32" y="126" font-family="Arial" font-size="11" fill="#0F1839">Produit laitier :</text><text x="288" y="126" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839" text-anchor="end">fromage blanc</text><text x="32" y="148" font-family="Arial" font-size="11" fill="#0F1839">Dessert :</text><text x="288" y="148" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">compote de pommes</text><line x1="32" y1="160" x2="288" y2="160" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="179" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F" text-anchor="middle">Présence de gluten</text></svg>'),

  ('11111111-a007-5000-0000-000000000003', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Carte de la crêperie Le Phare à Brest : galette complète 8,90 €, galette au saumon 11,50 €, crêpe au sucre 4 €, bolée de cidre 3,50 € ; fermée le lundi.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Carte de la crêperie Le Phare à Brest</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">CRÊPERIE LE PHARE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Brest — Notre carte</text><text x="32" y="82" font-family="Arial" font-size="11" fill="#0F1839">Galette complète</text><text x="288" y="82" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">8,90 €</text><text x="32" y="104" font-family="Arial" font-size="11" fill="#0F1839">Galette au saumon</text><text x="288" y="104" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">11,50 €</text><text x="32" y="126" font-family="Arial" font-size="11" fill="#0F1839">Crêpe au sucre</text><text x="288" y="126" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">4 €</text><text x="32" y="148" font-family="Arial" font-size="11" fill="#0F1839">Bolée de cidre</text><text x="288" y="148" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">3,50 €</text><line x1="32" y1="160" x2="288" y2="160" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="179" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F" text-anchor="middle">Fermée le lundi</text></svg>'),

  ('11111111-a007-5000-0000-000000000004', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Menu du food truck Saveurs de Dakar d''Amadou, place Saint-Aubin à Toulouse : mafé de bœuf 10 €, yassa poulet 11 €, thiéboudienne 12 €, jus de bissap 3 € ; service uniquement le midi, du mardi au samedi.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Menu du food truck Saveurs de Dakar</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">SAVEURS DE DAKAR</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Food truck d''Amadou — Toulouse, place Saint-Aubin</text><text x="32" y="82" font-family="Arial" font-size="11" fill="#0F1839">Mafé de bœuf</text><text x="288" y="82" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">10 €</text><text x="32" y="104" font-family="Arial" font-size="11" fill="#0F1839">Yassa poulet</text><text x="288" y="104" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">11 €</text><text x="32" y="126" font-family="Arial" font-size="11" fill="#0F1839">Thiéboudienne</text><text x="288" y="126" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">12 €</text><text x="32" y="148" font-family="Arial" font-size="11" fill="#0F1839">Jus de bissap</text><text x="288" y="148" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">3 €</text><line x1="32" y1="160" x2="288" y2="160" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="179" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F" text-anchor="middle">Uniquement le midi, du mardi au samedi</text></svg>'),

  ('11111111-a007-5000-0000-000000000005', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Carte de la pizzeria Da Lucia à Nice : margherita 9 €, regina 11 €, quatre fromages 12 €, boisson 2,50 € ; offre : -10 % sur les pizzas à emporter.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Carte de la pizzeria Da Lucia à Nice</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">PIZZERIA DA LUCIA</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Nice — Nos pizzas</text><text x="32" y="82" font-family="Arial" font-size="11" fill="#0F1839">Margherita</text><text x="288" y="82" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">9 €</text><text x="32" y="104" font-family="Arial" font-size="11" fill="#0F1839">Regina</text><text x="288" y="104" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">11 €</text><text x="32" y="126" font-family="Arial" font-size="11" fill="#0F1839">Quatre fromages</text><text x="288" y="126" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">12 €</text><text x="32" y="148" font-family="Arial" font-size="11" fill="#0F1839">Boisson</text><text x="288" y="148" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">2,50 €</text><line x1="32" y1="160" x2="288" y2="160" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="179" font-family="Arial" font-size="12" font-weight="700" fill="#E8A317" text-anchor="middle">-10 % sur les pizzas à emporter</text></svg>'),

  ('11111111-a007-5000-0000-000000000006', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Plats de la semaine de la cafétéria L''Atelier Gourmand à Clermont-Ferrand : lundi lasagnes de bœuf, mardi blanquette de veau, mercredi curry de légumes (végétarien), jeudi poulet basquaise, vendredi filet de colin.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Plats de la semaine de la cafétéria L''Atelier Gourmand</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">CAFÉTÉRIA L''ATELIER GOURMAND</text><text x="160" y="54" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Clermont-Ferrand — Plats de la semaine</text><text x="32" y="78" font-family="Arial" font-size="11" fill="#0F1839">Lundi :</text><text x="288" y="78" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839" text-anchor="end">lasagnes de bœuf</text><text x="32" y="100" font-family="Arial" font-size="11" fill="#0F1839">Mardi :</text><text x="288" y="100" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839" text-anchor="end">blanquette de veau</text><text x="32" y="122" font-family="Arial" font-size="11" fill="#0F1839">Mercredi :</text><text x="288" y="122" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">curry de légumes — végétarien</text><text x="32" y="144" font-family="Arial" font-size="11" fill="#0F1839">Jeudi :</text><text x="288" y="144" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839" text-anchor="end">poulet basquaise</text><text x="32" y="166" font-family="Arial" font-size="11" fill="#0F1839">Vendredi :</text><text x="288" y="166" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839" text-anchor="end">filet de colin</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Service de 11h45 à 14h — réservé au personnel</text></svg>'),

  ('11111111-a007-5000-0000-000000000007', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Carte du salon de thé Au Jardin de Wei à Pau : thé vert ou noir 3,50 €, pâtisserie du jour 4,50 €, brunch servi le dimanche de 10h à 14h pour 18 € par personne ; réservation conseillée pour le brunch.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Carte du salon de thé Au Jardin de Wei à Pau</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">AU JARDIN DE WEI</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Salon de thé — Pau</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Thé vert ou noir</text><text x="288" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">3,50 €</text><text x="32" y="108" font-family="Arial" font-size="11" fill="#0F1839">Pâtisserie du jour</text><text x="288" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">4,50 €</text><text x="32" y="134" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Brunch : le dimanche, 10h - 14h</text><text x="288" y="134" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">18 €</text><text x="32" y="152" font-family="Arial" font-size="10" fill="#0F1839">par personne, boissons comprises</text><line x1="32" y1="162" x2="288" y2="162" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317" text-anchor="middle">Réservation conseillée pour le brunch</text></svg>'),

  ('11111111-a007-5000-0000-000000000008', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Menu enfant du restaurant La Marmite de Priya à Montpellier : 8 €, réservé aux enfants jusqu''à 10 ans ; steak haché ou nuggets avec frites, glace deux boules, sirop à l''eau.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Menu enfant du restaurant La Marmite de Priya</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">LA MARMITE DE PRIYA</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Montpellier — Menu enfant</text><text x="32" y="84" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839">Menu enfant</text><text x="288" y="84" font-family="Arial" font-size="12" font-weight="700" fill="#168F5B" text-anchor="end">8 €</text><text x="32" y="104" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Réservé aux enfants jusqu''à 10 ans</text><line x1="32" y1="116" x2="288" y2="116" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="138" font-family="Arial" font-size="11" fill="#0F1839">Steak haché ou nuggets + frites</text><text x="32" y="158" font-family="Arial" font-size="11" fill="#0F1839">Glace 2 boules</text><text x="32" y="178" font-family="Arial" font-size="11" fill="#0F1839">Sirop à l''eau</text></svg>'),

  ('11111111-a007-5000-0000-000000000009', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Menu du restaurant Le Soleil de l''Atlas à Grenoble, cuisine du chef Rachid : tajine de poulet 14 €, servi tous les jours ; couscous royal 16 €, servi le vendredi et le samedi uniquement ; thé à la menthe offert le midi.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Menu du restaurant Le Soleil de l''Atlas à Grenoble</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">LE SOLEIL DE L''ATLAS</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Grenoble — Cuisine du chef Rachid</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Tajine de poulet — tous les jours</text><text x="288" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">14 €</text><text x="32" y="110" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Couscous royal — vendredi et samedi</text><text x="288" y="110" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">16 €</text><text x="44" y="128" font-family="Arial" font-size="10" font-weight="700" fill="#1E3A8C">uniquement</text><line x1="32" y1="142" x2="288" y2="142" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="164" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="middle">Thé à la menthe offert le midi</text><text x="160" y="182" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">21 rue des Alpes — Tél : 04 76 52 38 14</text></svg>'),

  ('11111111-a007-5000-0000-00000000000a', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Menu du soir de la brasserie Chez Diego à Amiens : entrée + plat + dessert 22 €, supplément fromage 3 €, café gourmand 6 € ; réservation conseillée le week-end.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Menu du soir de la brasserie Chez Diego à Amiens</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">BRASSERIE CHEZ DIEGO</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Amiens — Menu du soir</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Entrée + plat + dessert</text><text x="288" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">22 €</text><text x="32" y="110" font-family="Arial" font-size="11" fill="#0F1839">Supplément fromage</text><text x="288" y="110" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">3 €</text><text x="32" y="136" font-family="Arial" font-size="11" fill="#0F1839">Café gourmand</text><text x="288" y="136" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">6 €</text><line x1="32" y1="152" x2="288" y2="152" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="172" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317" text-anchor="middle">Réservation conseillée le week-end</text><text x="160" y="186" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">5 place du Beffroi — service de 19h à 22h30</text></svg>');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-a007-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a007-5000-0000-000000000001', 'A2', 'CE',
   'Combien coûte la formule entrée + plat + dessert ?',
   'Le menu affiche trois formules ; la ligne « **Entrée + plat + dessert : 17 €** » donne directement le prix de la formule complète. « 14,50 € » est le prix de la formule entrée + plat et « 13,50 € » celui de la formule plat + dessert : ces deux distracteurs répondent au prix des formules à deux éléments. « 19,50 € » est un montant plausible mais absent du menu.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a007-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a007-5000-0000-000000000002', 'A2', 'CE',
   'Quel est le dessert du menu de mardi ?',
   'Sur le menu du mardi, la ligne « **Dessert : compote de pommes** » donne la réponse. Le fromage blanc est le produit laitier, pas le dessert : c''est le piège principal de ce menu de cantine. La salade de tomates est l''entrée du repas — ce distracteur répondrait à « quelle est l''entrée ? ». Le yaourt est un dessert plausible de cantine, mais il n''apparaît nulle part sur ce menu.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a007-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a007-5000-0000-000000000003', 'A2', 'CE',
   'Quel est le prix de la galette au saumon ?',
   'La carte indique « **Galette au saumon : 11,50 €** ». « 8,90 € » est le prix de la galette complète, « 4 € » celui de la crêpe au sucre et « 3,50 € » celui de la bolée de cidre : chacun de ces distracteurs donne le prix d''un autre article de la carte, pas celui de la galette au saumon.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a007-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a007-5000-0000-000000000004', 'A2', 'CE',
   'Quand le food truck sert-il ses plats ?',
   'La mention en rouge « **Uniquement le midi, du mardi au samedi** » indique que le food truck ne sert qu''à midi. « Midi et soir » contredit le mot « uniquement ». « Uniquement le soir » inverse l''information du menu. « Le dimanche midi » est impossible : le service s''arrête au samedi, le dimanche le food truck ne travaille pas.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a007-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a007-5000-0000-000000000005', 'A2', 'CE',
   'Quelle offre est proposée pour les pizzas à emporter ?',
   'L''encadré « **-10 % sur les pizzas à emporter** » donne la réduction exacte. « 5 % de réduction » et « 20 % de réduction » sont des pourcentages plausibles mais absents de la carte. « Une boisson offerte » confond avec la ligne « Boisson : 2,50 € », qui est un article payant du menu, pas un cadeau accordé à l''achat d''une pizza.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a007-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a007-5000-0000-000000000006', 'A2', 'CE',
   'Quel jour la cafétéria propose-t-elle un plat végétarien ?',
   'La ligne « **Mercredi : curry de légumes — végétarien** » est la seule du menu qui porte la mention végétarien. Le lundi (lasagnes de bœuf), le mardi (blanquette de veau) et le jeudi (poulet basquaise) proposent tous un plat avec de la viande : ces trois distracteurs répondraient plutôt à la question « quels jours sert-on de la viande ? ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a007-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a007-5000-0000-000000000007', 'A2', 'CE',
   'Quel jour le brunch est-il servi ?',
   'La carte précise « **Brunch : le dimanche, 10h - 14h — 18 €** ». « Le samedi » et « Le vendredi » sont des jours plausibles pour un brunch, mais ils ne figurent pas sur la carte. « Tous les jours » sur-généralise : seuls le thé et la pâtisserie sont proposés en continu, le brunch n''existe que le dimanche.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a007-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a007-5000-0000-000000000008', 'A2', 'CE',
   'Jusqu''à quel âge peut-on commander le menu enfant ?',
   'Le menu indique « **Réservé aux enfants jusqu''à 10 ans** » : la limite est donc 10 ans. « 8 ans » confond l''âge avec le prix du menu (8 €) : c''est le piège principal. « 12 ans » et « 6 ans » sont des limites d''âge plausibles dans d''autres restaurants, mais elles ne correspondent pas à ce qui est écrit sur ce menu.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a007-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a007-5000-0000-000000000009', 'A2', 'CE',
   'Quels jours le couscous royal est-il servi ?',
   'Le menu précise « **Couscous royal — vendredi et samedi uniquement** ». « Tous les jours » correspond au tajine de poulet, pas au couscous : c''est le piège principal. « Le samedi et le dimanche » remplace le vendredi par un jour où le plat n''est pas proposé. « Uniquement le midi » confond avec le thé à la menthe, qui est offert le midi.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a007-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a007-5000-0000-00000000000a', 'A2', 'CE',
   'Combien coûte le supplément fromage ?',
   'La ligne « **Supplément fromage : 3 €** » donne directement le prix. « 22 € » est le prix du menu complet du soir et « 6 € » celui du café gourmand : ces deux distracteurs répondent au prix d''autres éléments de la carte. « 4,50 € » est un montant plausible pour un supplément, mais il n''apparaît nulle part sur ce menu.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('11111111-a007-2100-0000-000000000001', '11111111-a007-1000-0000-000000000001', '13,50 €', 'false', '1'),
  ('11111111-a007-2200-0000-000000000001', '11111111-a007-1000-0000-000000000001', '14,50 €', 'false', '2'),
  ('11111111-a007-2300-0000-000000000001', '11111111-a007-1000-0000-000000000001', '17 €', 'true', '3'),
  ('11111111-a007-2400-0000-000000000001', '11111111-a007-1000-0000-000000000001', '19,50 €', 'false', '4'),

  ('11111111-a007-2100-0000-000000000002', '11111111-a007-1000-0000-000000000002', 'La compote de pommes', 'true', '1'),
  ('11111111-a007-2200-0000-000000000002', '11111111-a007-1000-0000-000000000002', 'Le fromage blanc', 'false', '2'),
  ('11111111-a007-2300-0000-000000000002', '11111111-a007-1000-0000-000000000002', 'La salade de tomates', 'false', '3'),
  ('11111111-a007-2400-0000-000000000002', '11111111-a007-1000-0000-000000000002', 'Un yaourt', 'false', '4'),

  ('11111111-a007-2100-0000-000000000003', '11111111-a007-1000-0000-000000000003', '8,90 €', 'false', '1'),
  ('11111111-a007-2200-0000-000000000003', '11111111-a007-1000-0000-000000000003', '11,50 €', 'true', '2'),
  ('11111111-a007-2300-0000-000000000003', '11111111-a007-1000-0000-000000000003', '4 €', 'false', '3'),
  ('11111111-a007-2400-0000-000000000003', '11111111-a007-1000-0000-000000000003', '3,50 €', 'false', '4'),

  ('11111111-a007-2100-0000-000000000004', '11111111-a007-1000-0000-000000000004', 'Midi et soir', 'false', '1'),
  ('11111111-a007-2200-0000-000000000004', '11111111-a007-1000-0000-000000000004', 'Uniquement le soir', 'false', '2'),
  ('11111111-a007-2300-0000-000000000004', '11111111-a007-1000-0000-000000000004', 'Le dimanche midi', 'false', '3'),
  ('11111111-a007-2400-0000-000000000004', '11111111-a007-1000-0000-000000000004', 'Uniquement le midi', 'true', '4'),

  ('11111111-a007-2100-0000-000000000005', '11111111-a007-1000-0000-000000000005', '5 % de réduction', 'false', '1'),
  ('11111111-a007-2200-0000-000000000005', '11111111-a007-1000-0000-000000000005', '10 % de réduction', 'true', '2'),
  ('11111111-a007-2300-0000-000000000005', '11111111-a007-1000-0000-000000000005', '20 % de réduction', 'false', '3'),
  ('11111111-a007-2400-0000-000000000005', '11111111-a007-1000-0000-000000000005', 'Une boisson offerte', 'false', '4'),

  ('11111111-a007-2100-0000-000000000006', '11111111-a007-1000-0000-000000000006', 'Le lundi', 'false', '1'),
  ('11111111-a007-2200-0000-000000000006', '11111111-a007-1000-0000-000000000006', 'Le mardi', 'false', '2'),
  ('11111111-a007-2300-0000-000000000006', '11111111-a007-1000-0000-000000000006', 'Le mercredi', 'true', '3'),
  ('11111111-a007-2400-0000-000000000006', '11111111-a007-1000-0000-000000000006', 'Le jeudi', 'false', '4'),

  ('11111111-a007-2100-0000-000000000007', '11111111-a007-1000-0000-000000000007', 'Le dimanche', 'true', '1'),
  ('11111111-a007-2200-0000-000000000007', '11111111-a007-1000-0000-000000000007', 'Le samedi', 'false', '2'),
  ('11111111-a007-2300-0000-000000000007', '11111111-a007-1000-0000-000000000007', 'Tous les jours', 'false', '3'),
  ('11111111-a007-2400-0000-000000000007', '11111111-a007-1000-0000-000000000007', 'Le vendredi', 'false', '4'),

  ('11111111-a007-2100-0000-000000000008', '11111111-a007-1000-0000-000000000008', '6 ans', 'false', '1'),
  ('11111111-a007-2200-0000-000000000008', '11111111-a007-1000-0000-000000000008', '8 ans', 'false', '2'),
  ('11111111-a007-2300-0000-000000000008', '11111111-a007-1000-0000-000000000008', '12 ans', 'false', '3'),
  ('11111111-a007-2400-0000-000000000008', '11111111-a007-1000-0000-000000000008', '10 ans', 'true', '4'),

  ('11111111-a007-2100-0000-000000000009', '11111111-a007-1000-0000-000000000009', 'Tous les jours', 'false', '1'),
  ('11111111-a007-2200-0000-000000000009', '11111111-a007-1000-0000-000000000009', 'Le vendredi et le samedi', 'true', '2'),
  ('11111111-a007-2300-0000-000000000009', '11111111-a007-1000-0000-000000000009', 'Le samedi et le dimanche', 'false', '3'),
  ('11111111-a007-2400-0000-000000000009', '11111111-a007-1000-0000-000000000009', 'Uniquement le midi', 'false', '4'),

  ('11111111-a007-2100-0000-00000000000a', '11111111-a007-1000-0000-00000000000a', '6 €', 'false', '1'),
  ('11111111-a007-2200-0000-00000000000a', '11111111-a007-1000-0000-00000000000a', '22 €', 'false', '2'),
  ('11111111-a007-2300-0000-00000000000a', '11111111-a007-1000-0000-00000000000a', '3 €', 'true', '3'),
  ('11111111-a007-2400-0000-00000000000a', '11111111-a007-1000-0000-00000000000a', '4,50 €', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 10 items (NN=01..0a), UUID déterministes uniques (questions 1000-,
--     medias 5000-, choices 2100/2200/2300/2400-).
-- [x] Tous les supports = menus, 10 contextes différents (menu du jour de
--     restaurant, cantine scolaire, crêperie, food truck sénégalais, pizzeria,
--     cafétéria d'entreprise, brunch de salon de thé, menu enfant, restaurant
--     marocain, menu du soir de brasserie). Aucun support interdit (pas
--     d'horaires seuls, pas d'annonce, pas d'étiquette, pas de SMS, etc.).
-- [x] 4 choix par question, exactement 1 correct ; distribution des bonnes
--     réponses : pos1=2 (items 2,7), pos2=3 (items 3,5,9), pos3=3 (items
--     1,6,10), pos4=2 (items 4,8) — max 3 par position, 4 positions utilisées.
-- [x] Questions sur UNE information explicite (prix, plat, jour, condition,
--     âge limite, offre) ; labels des choices = texte de la réponse ;
--     distracteurs = autres valeurs présentes ou plausibles du menu.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chacun des
--     3 distracteurs, point clé en **gras**.
-- [x] SVG : viewBox="0 0 320 200", Arial, palette charte, rouge réservé aux
--     infos critiques (service uniquement le midi, présence de gluten,
--     fermée le lundi) ; ambre pour les offres/notes ; balises équilibrées ;
--     alt_text descriptif complet sur chaque media. Texte utile ~10-40 mots.
-- [x] Apostrophes SQL doublées ('') partout (SVG, alt_text, statements,
--     explanations, labels). Pas de JSONB (choices en lignes). Contenu 100%
--     original, prénoms variés (Olena, Amadou, Lucia, Wei, Priya, Rachid,
--     Diego), villes variées (Dijon, Angers, Brest, Toulouse, Nice,
--     Clermont-Ferrand, Pau, Montpellier, Grenoble, Amiens), chiffres tous
--     différents.
-- [x] competence_code : 5× ce_reperage_explicite (items 1,3,4,7,10),
--     5× ce_detail_specifique (items 2,5,6,8,9).
-- ============================================================================
