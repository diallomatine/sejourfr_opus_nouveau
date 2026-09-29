-- ============================================================================
-- V413 — TCF CE A2 — lot 13 (support : annonce de vente d'objet)
-- ----------------------------------------------------------------------------
-- 10 items CE A2, theme 22222222-0000-0000-0000-000000000002.
-- Chaque item = une annonce de vente d'objet originale (SVG style « document »)
-- + 1 question sur UNE information explicite + 4 choix (1 correct).
-- UUID déterministes : questions 11111111-a00d-1000-…, medias 11111111-a00d-5000-…,
-- choices 11111111-a00d-2100/2200/2300/2400-… (display_order 1..4).
-- ============================================================================


-- medias (IMAGE) — annonces de vente référencées par les questions ci-dessous
INSERT INTO medias
  (id, type, url, storage_key, original_filename, content_type, size_bytes, duration_sec,
   alt_text, created_at, transcript, inline_svg)
VALUES
  ('11111111-a00d-5000-0000-000000000001', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Annonce de vente d''un vélo d''enfant 6-8 ans bleu, très bon état, 45 euros, à venir chercher le samedi matin, quartier Saint-Cyprien à Toulouse ; contact Amadou au 06 52 18 47 93.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de vente d''un vélo d''enfant à Toulouse</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">À VENDRE</text><text x="160" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">Vélo d''enfant 6-8 ans — bleu</text><text x="160" y="78" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Très bon état, peu servi</text><text x="160" y="108" font-family="Arial" font-size="18" font-weight="700" fill="#168F5B" text-anchor="middle">45 €</text><text x="160" y="134" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">À venir chercher le samedi matin</text><text x="160" y="154" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Quartier Saint-Cyprien — Toulouse</text><line x1="32" y1="164" x2="288" y2="164" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Amadou — 06 52 18 47 93</text></svg>'),

  ('11111111-a00d-5000-0000-000000000002', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Annonce de vente d''un canapé 3 places en tissu gris, acheté il y a 2 ans, très bon état, 120 euros à débattre, pas de livraison, à venir chercher sur place ; Lucia, Dijon centre.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de vente d''un canapé 3 places à Dijon</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">À VENDRE</text><text x="160" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">Canapé 3 places — tissu gris</text><text x="160" y="78" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Acheté il y a 2 ans, très bon état</text><text x="160" y="108" font-family="Arial" font-size="18" font-weight="700" fill="#168F5B" text-anchor="middle">120 €</text><text x="160" y="126" font-family="Arial" font-size="10" fill="#E8A317" text-anchor="middle">prix à débattre</text><text x="160" y="150" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">Pas de livraison : à venir chercher sur place</text><line x1="32" y1="164" x2="288" y2="164" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Lucia — Dijon centre</text></svg>'),

  ('11111111-a00d-5000-0000-000000000003', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Annonce de vente d''une machine à laver 7 kg achetée en 2024, sous garantie jusqu''en décembre, 90 euros, téléphoner le soir après 18h ; Wei, quartier Berriat à Grenoble, 06 44 09 31 87.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de vente d''une machine à laver à Grenoble</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">À VENDRE</text><text x="160" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">Machine à laver 7 kg</text><text x="160" y="78" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Achetée en 2024 — garantie jusqu''en décembre</text><text x="160" y="108" font-family="Arial" font-size="18" font-weight="700" fill="#168F5B" text-anchor="middle">90 €</text><text x="160" y="138" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">Téléphoner le soir, après 18h</text><line x1="32" y1="156" x2="288" y2="156" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="176" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Wei — Grenoble, quartier Berriat — 06 44 09 31 87</text></svg>'),

  ('11111111-a00d-5000-0000-000000000004', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Annonce de vente d''une table en bois avec 4 chaises, bon état, 75 euros, cause déménagement, à retirer avant le 30 juin ; Rachid, quartier Doutre à Angers.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de vente d''une table et de 4 chaises à Angers</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">À VENDRE</text><text x="160" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">Table en bois + 4 chaises</text><text x="160" y="78" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Bon état — cause déménagement</text><text x="160" y="108" font-family="Arial" font-size="18" font-weight="700" fill="#168F5B" text-anchor="middle">75 €</text><text x="160" y="138" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F" text-anchor="middle">À retirer avant le 30 juin</text><line x1="32" y1="156" x2="288" y2="156" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="176" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Rachid — Angers, quartier Doutre</text></svg>'),

  ('11111111-a00d-5000-0000-000000000005', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Annonce de vente d''une poussette double état neuf, servie 6 mois seulement, 60 euros, contact par SMS uniquement au 07 81 26 54 39 ; Olena, Metz-Sablon.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de vente d''une poussette double à Metz</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">À VENDRE</text><text x="160" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">Poussette double — état neuf</text><text x="160" y="78" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Servie 6 mois seulement</text><text x="160" y="108" font-family="Arial" font-size="18" font-weight="700" fill="#168F5B" text-anchor="middle">60 €</text><text x="160" y="138" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">Contact par SMS uniquement</text><line x1="32" y1="156" x2="288" y2="156" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="176" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">07 81 26 54 39 — Olena, Metz-Sablon</text></svg>'),

  ('11111111-a00d-5000-0000-000000000006', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Annonce de vente d''un ordinateur portable 15 pouces de 2023, chargeur et housse inclus, 250 euros, remise en main propre place de la Gare à Nîmes ; contact Diego au 07 63 20 95 41.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de vente d''un ordinateur portable à Nîmes</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">À VENDRE</text><text x="160" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">Ordinateur portable 15 pouces (2023)</text><text x="160" y="78" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Chargeur et housse inclus</text><text x="160" y="108" font-family="Arial" font-size="18" font-weight="700" fill="#168F5B" text-anchor="middle">250 €</text><text x="160" y="138" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">Remise en main propre : place de la Gare</text><line x1="32" y1="156" x2="288" y2="156" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="176" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Diego — Nîmes — 07 63 20 95 41</text></svg>'),

  ('11111111-a00d-5000-0000-000000000007', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Annonce de vente d''un réfrigérateur de 140 cm classe A qui fonctionne très bien, 110 euros, à venir chercher le dimanche entre 10h et 12h ; Priya, rue des Vignes à Clermont-Ferrand.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de vente d''un réfrigérateur à Clermont-Ferrand</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">À VENDRE</text><text x="160" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">Réfrigérateur 140 cm — classe A</text><text x="160" y="78" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Fonctionne très bien</text><text x="160" y="108" font-family="Arial" font-size="18" font-weight="700" fill="#168F5B" text-anchor="middle">110 €</text><text x="160" y="138" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">À venir chercher le dimanche, entre 10h et 12h</text><line x1="32" y1="156" x2="288" y2="156" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="176" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Priya — Clermont-Ferrand, rue des Vignes</text></svg>'),

  ('11111111-a00d-5000-0000-000000000008', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Annonce de vente d''une guitare classique adulte, très bon état, housse offerte, 85 euros, appeler après 17h au 02 98 41 76 25 ; Fatou, Brest.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de vente d''une guitare classique à Brest</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">À VENDRE</text><text x="160" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">Guitare classique adulte</text><text x="160" y="78" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Très bon état — housse offerte</text><text x="160" y="108" font-family="Arial" font-size="18" font-weight="700" fill="#168F5B" text-anchor="middle">85 €</text><text x="160" y="138" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">Appeler après 17h</text><line x1="32" y1="156" x2="288" y2="156" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="176" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Fatou — Brest — 02 98 41 76 25</text></svg>'),

  ('11111111-a00d-5000-0000-000000000009', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Annonce de vente d''un bureau d''enfant blanc avec tiroir, 40 euros, disponible mercredi toute la journée, premier arrivé premier servi ; Mariam, quartier Saint-Jacques à Perpignan.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de vente d''un bureau d''enfant à Perpignan</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">À VENDRE</text><text x="160" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">Bureau d''enfant blanc, avec tiroir</text><text x="160" y="78" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">Disponible mercredi toute la journée</text><text x="160" y="108" font-family="Arial" font-size="18" font-weight="700" fill="#168F5B" text-anchor="middle">40 €</text><text x="160" y="138" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317" text-anchor="middle">Premier arrivé, premier servi !</text><line x1="32" y1="156" x2="288" y2="156" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="176" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Mariam — Perpignan, quartier Saint-Jacques</text></svg>'),

  ('11111111-a00d-5000-0000-00000000000a', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Annonce de vente d''un téléviseur écran 102 cm, image parfaite, télécommande fournie, 130 euros, paiement en espèces uniquement ; Tomas, Mulhouse, 06 17 58 02 46.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de vente d''un téléviseur à Mulhouse</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">À VENDRE</text><text x="160" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">Téléviseur écran 102 cm</text><text x="160" y="78" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Image parfaite — télécommande fournie</text><text x="160" y="108" font-family="Arial" font-size="18" font-weight="700" fill="#168F5B" text-anchor="middle">130 €</text><text x="160" y="138" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F" text-anchor="middle">Paiement en espèces uniquement</text><line x1="32" y1="156" x2="288" y2="156" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="176" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Tomas — Mulhouse — 06 17 58 02 46</text></svg>');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-a00d-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00d-5000-0000-000000000001', 'A2', 'CE',
   'Quand faut-il venir chercher le vélo ?',
   'L''annonce précise « **à venir chercher le samedi matin** ». « Le samedi après-midi » garde le bon jour mais pas le bon moment de la journée. « Le dimanche matin » garde le bon moment mais pas le bon jour. « En semaine » ne correspond à rien dans l''annonce d''Amadou, qui ne propose qu''un seul créneau.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00d-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00d-5000-0000-000000000002', 'A2', 'CE',
   'Quel est le prix demandé pour le canapé ?',
   'Le prix affiché est « **120 € à débattre** » : la somme demandée est donc 120 €. « 220 € », « 110 € » et « 100 € » n''apparaissent nulle part dans l''annonce de Lucia : ce sont des montants proches mais inventés. « À débattre » signifie seulement que le prix peut être négocié — le prix de départ écrit reste 120 €.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00d-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00d-5000-0000-000000000003', 'A2', 'CE',
   'Quand peut-on téléphoner à Wei ?',
   'L''annonce demande de « **téléphoner le soir, après 18h** ». « Le matin, avant 9h » et « à l''heure du déjeuner » sont des créneaux plausibles mais jamais mentionnés dans l''annonce. « À tout moment » contredit directement la consigne : Wei limite les appels à un seul créneau, le soir après 18h.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00d-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00d-5000-0000-000000000004', 'A2', 'CE',
   'Pourquoi Rachid vend-il sa table ?',
   'L''annonce indique « **cause déménagement** » : Rachid vend sa table parce qu''il déménage. « La table est cassée » contredit la mention « bon état » écrite juste avant. « Il achète une table neuve » et « il part en vacances » sont des raisons plausibles mais qui ne figurent nulle part dans l''annonce.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00d-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00d-5000-0000-000000000005', 'A2', 'CE',
   'Comment faut-il contacter Olena ?',
   'L''annonce précise « **contact par SMS uniquement** » au 07 81 26 54 39. « En téléphonant » est le piège principal : un numéro est bien donné, mais le mot « uniquement » exclut les appels — il sert seulement à recevoir des SMS. « Par e-mail » et « en passant chez elle » ne sont mentionnés nulle part dans l''annonce.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00d-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00d-5000-0000-000000000006', 'A2', 'CE',
   'Où a lieu la remise de l''ordinateur ?',
   'L''annonce indique « **remise en main propre : place de la Gare** », à Nîmes. « Au domicile de Diego » et « devant la mairie » sont des lieux plausibles pour ce type de vente, mais absents de l''annonce. « Par envoi postal » contredit la formule « remise en main propre », qui signifie que la vente se fait face à face.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00d-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00d-5000-0000-000000000007', 'A2', 'CE',
   'À quelle heure peut-on venir chercher le réfrigérateur le dimanche ?',
   'L''annonce fixe le créneau du dimanche : « à venir chercher le dimanche, **entre 10h et 12h** ». « Entre 14h et 16h » et « avant 9h » sont des horaires inventés, absents du document. « Toute la journée » est contredit par l''annonce de Priya, qui limite la venue à deux heures précises du matin.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00d-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00d-5000-0000-000000000008', 'A2', 'CE',
   'Qu''est-ce qui est offert avec la guitare ?',
   'L''annonce précise « très bon état — **housse offerte** » : la housse est donnée avec la guitare. « Des cordes neuves », « un support » et « des partitions » sont des accessoires plausibles pour une guitare, mais aucun des trois n''est mentionné dans l''annonce de Fatou — seul le mot « housse » apparaît.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00d-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00d-5000-0000-000000000009', 'A2', 'CE',
   'Quel jour le bureau est-il disponible ?',
   'L''annonce indique « **disponible mercredi toute la journée** ». « Le mardi » et « le jeudi » sont les jours voisins du mercredi : c''est le piège classique du jour proche, mais ils ne figurent pas dans l''annonce. « Le week-end » n''est pas mentionné non plus : Mariam ne propose qu''un seul jour, le mercredi.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00d-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00d-5000-0000-00000000000a', 'A2', 'CE',
   'Comment faut-il payer le téléviseur ?',
   'L''annonce précise en rouge « **paiement en espèces uniquement** » : Tomas n''accepte que l''argent liquide. « Par chèque », « par carte bancaire » et « par virement » sont des moyens de paiement courants et plausibles, mais tous les trois sont exclus par le mot « uniquement » — aucun n''apparaît dans l''annonce.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('11111111-a00d-2100-0000-000000000001', '11111111-a00d-1000-0000-000000000001', 'Le samedi après-midi', 'false', '1'),
  ('11111111-a00d-2200-0000-000000000001', '11111111-a00d-1000-0000-000000000001', 'Le dimanche matin', 'false', '2'),
  ('11111111-a00d-2300-0000-000000000001', '11111111-a00d-1000-0000-000000000001', 'Le samedi matin', 'true', '3'),
  ('11111111-a00d-2400-0000-000000000001', '11111111-a00d-1000-0000-000000000001', 'En semaine', 'false', '4'),

  ('11111111-a00d-2100-0000-000000000002', '11111111-a00d-1000-0000-000000000002', '120 €', 'true', '1'),
  ('11111111-a00d-2200-0000-000000000002', '11111111-a00d-1000-0000-000000000002', '220 €', 'false', '2'),
  ('11111111-a00d-2300-0000-000000000002', '11111111-a00d-1000-0000-000000000002', '110 €', 'false', '3'),
  ('11111111-a00d-2400-0000-000000000002', '11111111-a00d-1000-0000-000000000002', '100 €', 'false', '4'),

  ('11111111-a00d-2100-0000-000000000003', '11111111-a00d-1000-0000-000000000003', 'Le matin, avant 9h', 'false', '1'),
  ('11111111-a00d-2200-0000-000000000003', '11111111-a00d-1000-0000-000000000003', 'À l''heure du déjeuner', 'false', '2'),
  ('11111111-a00d-2300-0000-000000000003', '11111111-a00d-1000-0000-000000000003', 'À tout moment', 'false', '3'),
  ('11111111-a00d-2400-0000-000000000003', '11111111-a00d-1000-0000-000000000003', 'Le soir, après 18h', 'true', '4'),

  ('11111111-a00d-2100-0000-000000000004', '11111111-a00d-1000-0000-000000000004', 'La table est cassée', 'false', '1'),
  ('11111111-a00d-2200-0000-000000000004', '11111111-a00d-1000-0000-000000000004', 'Il déménage', 'true', '2'),
  ('11111111-a00d-2300-0000-000000000004', '11111111-a00d-1000-0000-000000000004', 'Il achète une table neuve', 'false', '3'),
  ('11111111-a00d-2400-0000-000000000004', '11111111-a00d-1000-0000-000000000004', 'Il part en vacances', 'false', '4'),

  ('11111111-a00d-2100-0000-000000000005', '11111111-a00d-1000-0000-000000000005', 'En téléphonant', 'false', '1'),
  ('11111111-a00d-2200-0000-000000000005', '11111111-a00d-1000-0000-000000000005', 'Par e-mail', 'false', '2'),
  ('11111111-a00d-2300-0000-000000000005', '11111111-a00d-1000-0000-000000000005', 'Par SMS', 'true', '3'),
  ('11111111-a00d-2400-0000-000000000005', '11111111-a00d-1000-0000-000000000005', 'En passant chez elle', 'false', '4'),

  ('11111111-a00d-2100-0000-000000000006', '11111111-a00d-1000-0000-000000000006', 'Place de la Gare', 'true', '1'),
  ('11111111-a00d-2200-0000-000000000006', '11111111-a00d-1000-0000-000000000006', 'Au domicile de Diego', 'false', '2'),
  ('11111111-a00d-2300-0000-000000000006', '11111111-a00d-1000-0000-000000000006', 'Devant la mairie', 'false', '3'),
  ('11111111-a00d-2400-0000-000000000006', '11111111-a00d-1000-0000-000000000006', 'Par envoi postal', 'false', '4'),

  ('11111111-a00d-2100-0000-000000000007', '11111111-a00d-1000-0000-000000000007', 'Entre 14h et 16h', 'false', '1'),
  ('11111111-a00d-2200-0000-000000000007', '11111111-a00d-1000-0000-000000000007', 'Avant 9h', 'false', '2'),
  ('11111111-a00d-2300-0000-000000000007', '11111111-a00d-1000-0000-000000000007', 'Toute la journée', 'false', '3'),
  ('11111111-a00d-2400-0000-000000000007', '11111111-a00d-1000-0000-000000000007', 'Entre 10h et 12h', 'true', '4'),

  ('11111111-a00d-2100-0000-000000000008', '11111111-a00d-1000-0000-000000000008', 'Des cordes neuves', 'false', '1'),
  ('11111111-a00d-2200-0000-000000000008', '11111111-a00d-1000-0000-000000000008', 'La housse', 'true', '2'),
  ('11111111-a00d-2300-0000-000000000008', '11111111-a00d-1000-0000-000000000008', 'Un support', 'false', '3'),
  ('11111111-a00d-2400-0000-000000000008', '11111111-a00d-1000-0000-000000000008', 'Des partitions', 'false', '4'),

  ('11111111-a00d-2100-0000-000000000009', '11111111-a00d-1000-0000-000000000009', 'Le mercredi', 'true', '1'),
  ('11111111-a00d-2200-0000-000000000009', '11111111-a00d-1000-0000-000000000009', 'Le mardi', 'false', '2'),
  ('11111111-a00d-2300-0000-000000000009', '11111111-a00d-1000-0000-000000000009', 'Le jeudi', 'false', '3'),
  ('11111111-a00d-2400-0000-000000000009', '11111111-a00d-1000-0000-000000000009', 'Le week-end', 'false', '4'),

  ('11111111-a00d-2100-0000-00000000000a', '11111111-a00d-1000-0000-00000000000a', 'Par chèque', 'false', '1'),
  ('11111111-a00d-2200-0000-00000000000a', '11111111-a00d-1000-0000-00000000000a', 'Par carte bancaire', 'false', '2'),
  ('11111111-a00d-2300-0000-00000000000a', '11111111-a00d-1000-0000-00000000000a', 'En espèces', 'true', '3'),
  ('11111111-a00d-2400-0000-00000000000a', '11111111-a00d-1000-0000-00000000000a', 'Par virement', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 10 items (NN=01..0a), UUID déterministes uniques (questions a00d-1000-,
--     medias a00d-5000-, choices a00d-2100/2200/2300/2400-).
-- [x] Tous les supports = annonces de vente d'objet, 10 objets différents
--     (vélo d'enfant, canapé, machine à laver, table + chaises, poussette,
--     ordinateur portable, réfrigérateur, guitare, bureau d'enfant,
--     téléviseur). Aucun support interdit (pas d'horaires, logement,
--     étiquette, SMS, affichette d'événement, menu, etc.).
-- [x] 4 choix par question, exactement 1 correct ; distribution des bonnes
--     réponses : pos1=3 (items 2,6,9), pos2=2 (items 4,8), pos3=3 (items
--     1,5,10), pos4=2 (items 3,7) — max 3 par position, 4 positions utilisées.
-- [x] Questions sur UNE information explicite (créneau de retrait, prix,
--     horaire d'appel, motif de vente, mode de contact, lieu de remise,
--     accessoire offert, jour de disponibilité, moyen de paiement) ; labels
--     des choices = texte de la réponse ; distracteurs = autres valeurs
--     présentes ou plausibles du document.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chacun des
--     3 distracteurs, point clé en **gras**.
-- [x] SVG : viewBox="0 0 320 200", Arial, palette charte, rouge réservé aux
--     infos critiques (« à retirer avant le 30 juin », « paiement en espèces
--     uniquement ») ; balises équilibrées ; alt_text descriptif complet sur
--     chaque media. Texte utile ~10-40 mots par annonce.
-- [x] Apostrophes SQL doublées ('') partout (SVG, alt_text, statements,
--     explanations, labels). Pas de JSONB (choices en lignes). Contenu 100%
--     original, prénoms/villes variés (Amadou, Lucia, Wei, Rachid, Olena,
--     Diego, Priya, Fatou, Mariam, Tomas — Toulouse, Dijon, Grenoble, Angers,
--     Metz, Nîmes, Clermont-Ferrand, Brest, Perpignan, Mulhouse), chiffres
--     tous différents, aucun texte recopié d'un sujet existant.
-- [x] competence_code : 5× ce_reperage_explicite (items 2,4,5,6,10),
--     5× ce_detail_specifique (items 1,3,7,8,9).
-- ============================================================================
