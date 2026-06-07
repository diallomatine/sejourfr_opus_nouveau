-- ============================================================================
-- V403 — TCF CE A2 — lot 03 (support : étiquette / prix)
-- ----------------------------------------------------------------------------
-- 10 items CE A2, theme 22222222-0000-0000-0000-000000000002.
-- Chaque item = une étiquette de prix originale (SVG style « document »)
-- + 1 question sur UNE information explicite + 4 choix (1 correct).
-- UUID déterministes : questions 11111111-a003-1000-…, medias 11111111-a003-5000-…,
-- choices 11111111-a003-2100/2200/2300/2400-… (display_order 1..4).
-- ============================================================================


-- medias (IMAGE) — étiquettes de prix référencées par les questions ci-dessous
INSERT INTO medias
  (id, type, url, storage_key, original_filename, content_type, size_bytes, duration_sec,
   alt_text, created_at, transcript, inline_svg)
VALUES
  ('11111111-a003-5000-0000-000000000001', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Étiquette de prix du primeur Chez Amadou à Toulouse : pommes golden bio, origine France, prix normal 2,80 € le kilo ; promotion jusqu''au 12 mars : 2,20 € le kilo.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Étiquette de prix des pommes du primeur Chez Amadou</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">CHEZ AMADOU — PRIMEUR</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Toulouse — Fruits et légumes</text><text x="32" y="84" font-family="Arial" font-size="13" font-weight="700" fill="#0F1839">Pommes golden bio</text><text x="32" y="106" font-family="Arial" font-size="11" fill="#0F1839">Origine : France</text><text x="32" y="128" font-family="Arial" font-size="11" fill="#0F1839">Prix normal :</text><text x="288" y="128" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">2,80 €/kg</text><line x1="32" y1="144" x2="288" y2="144" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="166" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F" text-anchor="middle">PROMO jusqu''au 12 mars : 2,20 €/kg</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Servez-vous, sachets papier à disposition</text></svg>'),

  ('11111111-a003-5000-0000-000000000002', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Étiquette de soldes de la boutique Lucia Mode à Grenoble : manteau en laine, taille M, prix initial 89,00 € barré, réduction de 30 %, prix soldé 62,30 €.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Étiquette de soldes du manteau de la boutique Lucia Mode</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">LUCIA MODE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Grenoble — Prêt-à-porter</text><text x="32" y="84" font-family="Arial" font-size="13" font-weight="700" fill="#0F1839">Manteau en laine — Taille M</text><text x="32" y="110" font-family="Arial" font-size="11" fill="#0F1839">Prix initial : 89,00 €</text><line x1="32" y1="106" x2="155" y2="106" stroke="#0F1839" stroke-width="1.5"/><text x="288" y="110" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317" text-anchor="end">SOLDES : -30 %</text><line x1="32" y1="128" x2="288" y2="128" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="156" font-family="Arial" font-size="15" font-weight="700" fill="#E1372F" text-anchor="middle">Prix soldé : 62,30 €</text><text x="160" y="182" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Ni repris, ni échangé pendant les soldes</text></svg>'),

  ('11111111-a003-5000-0000-000000000003', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Étiquette de la fromagerie de Rachid à Annecy : comté affiné 18 mois, prix au kilo 18,50 €, part préemballée de 250 g à 4,63 € ; lait cru des Alpes.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Étiquette de prix du comté de la fromagerie de Rachid</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">FROMAGERIE DE RACHID</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Annecy — Vente à la coupe</text><text x="32" y="84" font-family="Arial" font-size="13" font-weight="700" fill="#0F1839">Comté affiné 18 mois</text><text x="32" y="112" font-family="Arial" font-size="11" fill="#0F1839">Prix au kilo :</text><text x="288" y="112" font-family="Arial" font-size="13" font-weight="700" fill="#168F5B" text-anchor="end">18,50 €</text><text x="32" y="138" font-family="Arial" font-size="11" fill="#0F1839">Part préemballée 250 g :</text><text x="288" y="138" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">4,63 €</text><line x1="32" y1="154" x2="288" y2="154" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="176" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Lait cru des Alpes — dégustation sur demande</text></svg>'),

  ('11111111-a003-5000-0000-000000000004', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Étiquette du magasin Électro Wei à Mulhouse : lave-linge 8 kg, ancien prix 429 € barré, nouveau prix 349 €, garantie 2 ans, livraison offerte.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Étiquette de prix du lave-linge du magasin Électro Wei</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">ÉLECTRO WEI</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Mulhouse — Électroménager</text><text x="32" y="84" font-family="Arial" font-size="13" font-weight="700" fill="#0F1839">Lave-linge 8 kg</text><text x="32" y="108" font-family="Arial" font-size="11" fill="#0F1839">Ancien prix : 429 €</text><line x1="32" y1="104" x2="148" y2="104" stroke="#0F1839" stroke-width="1.5"/><text x="288" y="110" font-family="Arial" font-size="15" font-weight="700" fill="#168F5B" text-anchor="end">349 €</text><text x="32" y="134" font-family="Arial" font-size="11" fill="#0F1839">Garantie : 2 ans</text><line x1="32" y1="150" x2="288" y2="150" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="172" font-family="Arial" font-size="12" font-weight="700" fill="#E8A317" text-anchor="middle">LIVRAISON OFFERTE</text><text x="160" y="186" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Renseignements au comptoir du rayon lavage</text></svg>'),

  ('11111111-a003-5000-0000-000000000005', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Étiquette du fleuriste Atelier d''Olena à Dijon : bouquet de 10 tulipes à 12,90 €, offre en cours : deuxième bouquet à moitié prix jusqu''à samedi.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Étiquette de prix du bouquet de tulipes de l''Atelier d''Olena</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">ATELIER D''OLENA</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Dijon — Fleuriste</text><text x="32" y="86" font-family="Arial" font-size="13" font-weight="700" fill="#0F1839">Bouquet de 10 tulipes</text><text x="288" y="86" font-family="Arial" font-size="14" font-weight="700" fill="#168F5B" text-anchor="end">12,90 €</text><line x1="32" y1="106" x2="288" y2="106" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="132" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C">Offre : 2e bouquet à -50 %</text><text x="32" y="154" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317">Valable jusqu''à samedi</text><text x="160" y="182" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Fleurs coupées du jour — emballage cadeau gratuit</text></svg>'),

  ('11111111-a003-5000-0000-000000000006', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Étiquette de la librairie Le Marque-Page à Nancy : roman « Les Jardins de la Moselle », exemplaire d''occasion en très bon état à 5,50 €, prix neuf 21,00 €.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Étiquette de prix du roman d''occasion de la librairie Le Marque-Page</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">LIBRAIRIE LE MARQUE-PAGE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Nancy — Livres neufs et d''occasion</text><text x="160" y="86" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">Roman « Les Jardins de la Moselle »</text><line x1="32" y1="104" x2="288" y2="104" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="130" font-family="Arial" font-size="12" font-weight="700" fill="#168F5B">Occasion — très bon état :</text><text x="288" y="130" font-family="Arial" font-size="14" font-weight="700" fill="#168F5B" text-anchor="end">5,50 €</text><text x="32" y="156" font-family="Arial" font-size="11" fill="#0F1839">Prix neuf : 21,00 €</text><text x="160" y="182" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Reprise de vos livres le mercredi après-midi</text></svg>'),

  ('11111111-a003-5000-0000-000000000007', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Étiquette du magasin Cycles Diego à Bayonne : vélo de ville à 289 €, antivol offert, garantie 1 an, révision gratuite à 6 mois.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Étiquette de prix du vélo de ville du magasin Cycles Diego</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">CYCLES DIEGO</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Bayonne — Vélos et accessoires</text><text x="32" y="86" font-family="Arial" font-size="13" font-weight="700" fill="#0F1839">Vélo de ville</text><text x="288" y="86" font-family="Arial" font-size="15" font-weight="700" fill="#168F5B" text-anchor="end">289 €</text><line x1="32" y1="104" x2="288" y2="104" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="128" font-family="Arial" font-size="12" font-weight="700" fill="#E8A317">Antivol offert</text><text x="32" y="150" font-family="Arial" font-size="11" fill="#0F1839">Garantie : 1 an</text><text x="32" y="170" font-family="Arial" font-size="11" fill="#0F1839">Révision gratuite à 6 mois</text><text x="160" y="186" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Essai possible devant le magasin</text></svg>'),

  ('11111111-a003-5000-0000-000000000008', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Étiquette de l''étal de Priya au marché de Perpignan : tomates rondes, origine Provence, 3,40 € le kilo, barquette de 500 g à 1,90 €.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Étiquette de prix des tomates de l''étal de Priya</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">ÉTAL DE PRIYA</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Marché de Perpignan</text><text x="32" y="86" font-family="Arial" font-size="13" font-weight="700" fill="#0F1839">Tomates rondes</text><text x="32" y="110" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C">Origine : Provence</text><text x="32" y="136" font-family="Arial" font-size="11" fill="#0F1839">Prix au kilo :</text><text x="288" y="136" font-family="Arial" font-size="13" font-weight="700" fill="#168F5B" text-anchor="end">3,40 €</text><text x="32" y="158" font-family="Arial" font-size="11" fill="#0F1839">Barquette de 500 g :</text><text x="288" y="158" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">1,90 €</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Cueillies de la veille — goûtez avant d''acheter</text></svg>'),

  ('11111111-a003-5000-0000-000000000009', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Étiquette du magasin Fatou Sport à Amiens : baskets de running, pointure 42, 54,00 € ; offre : deuxième paire à moitié prix jusqu''au 30 juin.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Étiquette de prix des baskets du magasin Fatou Sport</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">FATOU SPORT</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Amiens — Chaussures de sport</text><text x="32" y="86" font-family="Arial" font-size="13" font-weight="700" fill="#0F1839">Baskets de running — Pointure 42</text><text x="288" y="112" font-family="Arial" font-size="15" font-weight="700" fill="#168F5B" text-anchor="end">54,00 €</text><line x1="32" y1="128" x2="288" y2="128" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="152" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C">Offre : 2e paire à -50 %</text><text x="32" y="172" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F">jusqu''au 30 juin</text><text x="160" y="188" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Autres pointures disponibles en réserve</text></svg>'),

  ('11111111-a003-5000-0000-00000000000a', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Étiquette de la Supérette des Arènes à Limoges, rayon entretien : lessive liquide, bidon de 3 litres à 8,70 €, soit 2,90 € le litre.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Étiquette de prix de la lessive de la Supérette des Arènes</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">SUPÉRETTE DES ARÈNES</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Limoges — Rayon entretien</text><text x="32" y="88" font-family="Arial" font-size="13" font-weight="700" fill="#0F1839">Lessive liquide — bidon 3 litres</text><text x="288" y="118" font-family="Arial" font-size="15" font-weight="700" fill="#168F5B" text-anchor="end">8,70 €</text><text x="32" y="118" font-family="Arial" font-size="11" fill="#0F1839">Prix du bidon :</text><line x1="32" y1="136" x2="288" y2="136" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="160" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C" text-anchor="middle">soit 2,90 € le litre</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Parfum savon de Marseille — 60 lavages</text></svg>');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-a003-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a003-5000-0000-000000000001', 'A2', 'CE',
   'Combien coûte un kilo de pommes pendant la promotion ?',
   'L''étiquette affiche en rouge « **PROMO jusqu''au 12 mars : 2,20 €/kg** » : c''est le prix du kilo pendant la promotion. « 2,80 € » est le prix normal hors promotion, indiqué juste au-dessus — il répondrait à « quel est le prix habituel ? ». « 3,20 € » et « 1,80 € » sont des prix plausibles pour des pommes, mais ils n''apparaissent nulle part sur l''étiquette.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a003-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a003-5000-0000-000000000002', 'A2', 'CE',
   'Quel est le prix du manteau pendant les soldes ?',
   'La ligne rouge « **Prix soldé : 62,30 €** » donne directement la réponse. « 89,00 € » est le prix initial, barré sur l''étiquette — il répondrait à « combien coûtait le manteau avant les soldes ? ». « 30,00 € » confond le **pourcentage de réduction** (-30 %) avec un prix en euros. « 26,70 € » correspond au montant économisé (89 − 62,30), pas au prix à payer en caisse.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a003-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a003-5000-0000-000000000003', 'A2', 'CE',
   'Quel est le prix d''un kilo de comté ?',
   'L''étiquette indique « **Prix au kilo : 18,50 €** » : c''est la réponse. « 4,63 € » est le prix de la part préemballée de 250 g — il répondrait à « combien coûte la part ? ». « 14,90 € » et « 8,50 € » sont des prix au kilo plausibles dans une fromagerie, mais ils ne figurent pas sur cette étiquette. Attention à ne pas confondre le prix au kilo et le prix d''une portion.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a003-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a003-5000-0000-000000000004', 'A2', 'CE',
   'Qu''est-ce qui est offert avec le lave-linge ?',
   'La mention « **LIVRAISON OFFERTE** » est la seule gratuité annoncée sur l''étiquette. « L''installation à domicile » et « la reprise de l''ancien appareil » sont des services courants en magasin d''électroménager, donc plausibles, mais ils ne sont écrits nulle part. « Un paquet de lessive » n''est pas mentionné non plus : seul le transport de l''appareil est gratuit.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a003-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a003-5000-0000-000000000005', 'A2', 'CE',
   'Combien y a-t-il de tulipes dans le bouquet ?',
   'L''étiquette précise « **Bouquet de 10 tulipes** » : le bouquet contient donc 10 fleurs. « 12 » vient d''une confusion avec le prix (12,90 €) — ce nombre répondrait à « combien coûte le bouquet ? ». « 15 » et « 20 » sont des tailles de bouquet plausibles chez un fleuriste, mais elles ne correspondent pas à ce qui est écrit sur l''étiquette.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a003-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a003-5000-0000-000000000006', 'A2', 'CE',
   'Combien coûte ce livre d''occasion ?',
   'L''étiquette indique « **Occasion — très bon état : 5,50 €** » : c''est le prix demandé pour cet exemplaire. « 21,00 € » est le prix du livre neuf, donné à titre de comparaison — il répondrait à « combien coûte ce roman neuf ? ». « 15,50 € » correspondrait à l''économie réalisée (21 − 5,50), pas à un prix affiché. « 2,50 € » est un prix d''occasion plausible mais absent de l''étiquette.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a003-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a003-5000-0000-000000000007', 'A2', 'CE',
   'Quel accessoire est offert avec le vélo ?',
   'La ligne « **Antivol offert** » désigne le seul accessoire inclus dans le prix. « Un casque », « un panier » et « des lumières » sont des équipements de vélo très courants, donc tentants, mais aucun n''apparaît sur l''étiquette : celle-ci ne mentionne que l''antivol offert, la garantie d''un an et la révision gratuite à 6 mois.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a003-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a003-5000-0000-000000000008', 'A2', 'CE',
   'D''où viennent les tomates ?',
   'L''étiquette précise « **Origine : Provence** » : les tomates viennent donc de Provence. « D''Espagne » et « D''Italie » sont des provenances fréquentes pour les tomates en magasin, mais elles sont contredites par l''étiquette. « De Bretagne » est une autre région française plausible, qui n''a aucun rapport avec l''origine affichée sur l''étal.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a003-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a003-5000-0000-000000000009', 'A2', 'CE',
   'Jusqu''à quand peut-on profiter de l''offre sur la deuxième paire ?',
   'La mention en rouge indique que l''offre est valable « **jusqu''au 30 juin** ». « Jusqu''au 13 juin » inverse les chiffres de la date, « jusqu''au 30 juillet » confond le mois, et « jusqu''à la fin de l''année » n''est écrit nulle part sur l''étiquette : ces trois distracteurs jouent sur des dates proches ou vagues, mais une seule date limite est affichée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a003-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a003-5000-0000-00000000000a', 'A2', 'CE',
   'Quel est le prix d''un litre de lessive ?',
   'L''étiquette précise « **soit 2,90 € le litre** » : c''est le prix au litre. « 8,70 € » est le prix du bidon entier de 3 litres — il répondrait à « combien coûte le bidon ? ». « 3,00 € » vient d''une confusion avec la contenance (3 litres), qui n''est pas un prix. « 5,80 € » est un montant plausible mais absent de l''étiquette.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('11111111-a003-2100-0000-000000000001', '11111111-a003-1000-0000-000000000001', '2,80 €', 'false', '1'),
  ('11111111-a003-2200-0000-000000000001', '11111111-a003-1000-0000-000000000001', '2,20 €', 'true', '2'),
  ('11111111-a003-2300-0000-000000000001', '11111111-a003-1000-0000-000000000001', '3,20 €', 'false', '3'),
  ('11111111-a003-2400-0000-000000000001', '11111111-a003-1000-0000-000000000001', '1,80 €', 'false', '4'),

  ('11111111-a003-2100-0000-000000000002', '11111111-a003-1000-0000-000000000002', '89,00 €', 'false', '1'),
  ('11111111-a003-2200-0000-000000000002', '11111111-a003-1000-0000-000000000002', '30,00 €', 'false', '2'),
  ('11111111-a003-2300-0000-000000000002', '11111111-a003-1000-0000-000000000002', '62,30 €', 'true', '3'),
  ('11111111-a003-2400-0000-000000000002', '11111111-a003-1000-0000-000000000002', '26,70 €', 'false', '4'),

  ('11111111-a003-2100-0000-000000000003', '11111111-a003-1000-0000-000000000003', '18,50 €', 'true', '1'),
  ('11111111-a003-2200-0000-000000000003', '11111111-a003-1000-0000-000000000003', '4,63 €', 'false', '2'),
  ('11111111-a003-2300-0000-000000000003', '11111111-a003-1000-0000-000000000003', '14,90 €', 'false', '3'),
  ('11111111-a003-2400-0000-000000000003', '11111111-a003-1000-0000-000000000003', '8,50 €', 'false', '4'),

  ('11111111-a003-2100-0000-000000000004', '11111111-a003-1000-0000-000000000004', 'L''installation à domicile', 'false', '1'),
  ('11111111-a003-2200-0000-000000000004', '11111111-a003-1000-0000-000000000004', 'Un paquet de lessive', 'false', '2'),
  ('11111111-a003-2300-0000-000000000004', '11111111-a003-1000-0000-000000000004', 'La reprise de l''ancien appareil', 'false', '3'),
  ('11111111-a003-2400-0000-000000000004', '11111111-a003-1000-0000-000000000004', 'La livraison', 'true', '4'),

  ('11111111-a003-2100-0000-000000000005', '11111111-a003-1000-0000-000000000005', '12', 'false', '1'),
  ('11111111-a003-2200-0000-000000000005', '11111111-a003-1000-0000-000000000005', '10', 'true', '2'),
  ('11111111-a003-2300-0000-000000000005', '11111111-a003-1000-0000-000000000005', '15', 'false', '3'),
  ('11111111-a003-2400-0000-000000000005', '11111111-a003-1000-0000-000000000005', '20', 'false', '4'),

  ('11111111-a003-2100-0000-000000000006', '11111111-a003-1000-0000-000000000006', '21,00 €', 'false', '1'),
  ('11111111-a003-2200-0000-000000000006', '11111111-a003-1000-0000-000000000006', '15,50 €', 'false', '2'),
  ('11111111-a003-2300-0000-000000000006', '11111111-a003-1000-0000-000000000006', '5,50 €', 'true', '3'),
  ('11111111-a003-2400-0000-000000000006', '11111111-a003-1000-0000-000000000006', '2,50 €', 'false', '4'),

  ('11111111-a003-2100-0000-000000000007', '11111111-a003-1000-0000-000000000007', 'Un antivol', 'true', '1'),
  ('11111111-a003-2200-0000-000000000007', '11111111-a003-1000-0000-000000000007', 'Un casque', 'false', '2'),
  ('11111111-a003-2300-0000-000000000007', '11111111-a003-1000-0000-000000000007', 'Un panier', 'false', '3'),
  ('11111111-a003-2400-0000-000000000007', '11111111-a003-1000-0000-000000000007', 'Des lumières', 'false', '4'),

  ('11111111-a003-2100-0000-000000000008', '11111111-a003-1000-0000-000000000008', 'D''Espagne', 'false', '1'),
  ('11111111-a003-2200-0000-000000000008', '11111111-a003-1000-0000-000000000008', 'D''Italie', 'false', '2'),
  ('11111111-a003-2300-0000-000000000008', '11111111-a003-1000-0000-000000000008', 'De Bretagne', 'false', '3'),
  ('11111111-a003-2400-0000-000000000008', '11111111-a003-1000-0000-000000000008', 'De Provence', 'true', '4'),

  ('11111111-a003-2100-0000-000000000009', '11111111-a003-1000-0000-000000000009', 'Jusqu''au 13 juin', 'false', '1'),
  ('11111111-a003-2200-0000-000000000009', '11111111-a003-1000-0000-000000000009', 'Jusqu''au 30 juillet', 'false', '2'),
  ('11111111-a003-2300-0000-000000000009', '11111111-a003-1000-0000-000000000009', 'Jusqu''au 30 juin', 'true', '3'),
  ('11111111-a003-2400-0000-000000000009', '11111111-a003-1000-0000-000000000009', 'Jusqu''à la fin de l''année', 'false', '4'),

  ('11111111-a003-2100-0000-00000000000a', '11111111-a003-1000-0000-00000000000a', '8,70 €', 'false', '1'),
  ('11111111-a003-2200-0000-00000000000a', '11111111-a003-1000-0000-00000000000a', '2,90 €', 'true', '2'),
  ('11111111-a003-2300-0000-00000000000a', '11111111-a003-1000-0000-00000000000a', '3,00 €', 'false', '3'),
  ('11111111-a003-2400-0000-00000000000a', '11111111-a003-1000-0000-00000000000a', '5,80 €', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 10 items (NN=01..0a), UUID déterministes uniques (questions 1000-,
--     medias 5000-, choices 2100/2200/2300/2400-, plage a003).
-- [x] Tous les supports = étiquettes / prix, 10 commerces différents
--     (primeur, boutique de vêtements, fromagerie, électroménager, fleuriste,
--     librairie occasion, magasin de vélos, étal de marché, magasin de sport,
--     supérette). Aucun support interdit (pas d'horaires, de menu, d'annonce…).
-- [x] 4 choix par question, exactement 1 correct ; distribution des bonnes
--     réponses : pos1=2 (items 3,7), pos2=3 (items 1,5,10), pos3=3 (items
--     2,6,9), pos4=2 (items 4,8) — max 3 par position, 4 positions utilisées.
-- [x] Questions sur UNE information explicite (prix promo, prix soldé, prix au
--     kilo/litre, service offert, quantité, origine, date limite) ; labels des
--     choices = texte de la réponse ; distracteurs = autres valeurs présentes
--     sur l'étiquette ou plausibles (prix barré, % de réduction, contenance…).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chacun des
--     3 distracteurs, point clé en **gras**.
-- [x] SVG : viewBox="0 0 320 200", Arial, palette charte, rouge réservé aux
--     infos critiques (prix promo, prix soldé, date limite d'offre) ; balises
--     équilibrées ; alt_text descriptif complet sur chaque media. Texte utile
--     ~10-40 mots par étiquette.
-- [x] Apostrophes SQL doublées ('') partout (SVG, alt_text, statements,
--     explanations, labels). Pas de JSONB (choices en lignes). Contenu 100%
--     original, prénoms/villes variés (Amadou, Lucia, Rachid, Wei, Olena,
--     Diego, Priya, Fatou — Toulouse, Grenoble, Annecy, Mulhouse, Dijon,
--     Nancy, Bayonne, Perpignan, Amiens, Limoges), chiffres tous différents.
-- [x] competence_code : 5× ce_reperage_explicite (items 3,4,6,7,8),
--     5× ce_detail_specifique (items 1,2,5,9,10).
-- ============================================================================
