-- ============================================================================
-- V402 — TCF CE A2 — lot 02 (support : petite annonce logement)
-- ----------------------------------------------------------------------------
-- 10 items CE A2, theme 22222222-0000-0000-0000-000000000002.
-- Chaque item = une petite annonce de logement originale (SVG style « document »)
-- + 1 question sur UNE information explicite + 4 choix (1 correct).
-- UUID déterministes : questions 11111111-a002-1000-…, medias 11111111-a002-5000-…,
-- choices 11111111-a002-2100/2200/2300/2400-… (display_order 1..4).
-- ============================================================================


-- medias (IMAGE) — petites annonces logement référencées par les questions ci-dessous
INSERT INTO medias
  (id, type, url, storage_key, original_filename, content_type, size_bytes, duration_sec,
   alt_text, created_at, transcript, inline_svg)
VALUES
  ('11111111-a002-5000-0000-000000000001', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Petite annonce de location d''un studio meublé à Toulouse, quartier Saint-Cyprien : 25 m² au 2e étage, loyer 480 € charges comprises, dépôt de garantie 960 €, libre le 1er septembre ; contacter Lucia au 06 52 88 14 73.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de location d''un studio meublé à Toulouse</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">À LOUER — STUDIO</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Toulouse — quartier Saint-Cyprien</text><text x="32" y="80" font-family="Arial" font-size="11" fill="#0F1839">Studio meublé de 25 m² — 2e étage</text><text x="32" y="102" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Loyer : 480 € charges comprises</text><text x="32" y="124" font-family="Arial" font-size="11" fill="#0F1839">Dépôt de garantie : 960 €</text><text x="32" y="146" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Libre le 1er septembre</text><line x1="32" y1="158" x2="288" y2="158" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="176" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Contact : Lucia — 06 52 88 14 73</text></svg>'),

  ('11111111-a002-5000-0000-000000000002', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Petite annonce de colocation à Montpellier, proche du tramway : chambre meublée dans un T4 de 80 m², 350 € par mois charges comprises, disponible immédiatement, non-fumeur ; appeler Amadou après 18h au 07 81 45 26 90.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de colocation à Montpellier</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">COLOCATION</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Montpellier — proche du tramway</text><text x="32" y="80" font-family="Arial" font-size="11" fill="#0F1839">Chambre meublée dans un T4 de 80 m²</text><text x="32" y="102" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">350 € par mois, charges comprises</text><text x="32" y="124" font-family="Arial" font-size="11" fill="#0F1839">Disponible immédiatement</text><text x="32" y="146" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">Non-fumeur</text><line x1="32" y1="158" x2="288" y2="158" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="176" font-family="Arial" font-size="10" font-weight="700" fill="#1E3A8C" text-anchor="middle">Appeler Amadou après 18h : 07 81 45 26 90</text></svg>'),

  ('11111111-a002-5000-0000-000000000003', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Petite annonce de l''agence Brion pour un appartement T2 à louer à Angers, centre-ville : 42 m² au 3e étage avec ascenseur, loyer 620 € plus 40 € de charges, visites le mercredi de 14h à 17h ; téléphone 02 41 77 35 12.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de location d''un appartement T2 à Angers</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">À LOUER — APPARTEMENT T2</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Angers — centre-ville</text><text x="32" y="80" font-family="Arial" font-size="11" fill="#0F1839">42 m², 3e étage avec ascenseur</text><text x="32" y="102" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Loyer : 620 € + 40 € de charges</text><text x="32" y="124" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Visites le mercredi de 14h à 17h</text><line x1="32" y1="140" x2="288" y2="140" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="166" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Agence Brion : 02 41 77 35 12</text><text x="160" y="182" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Dossier complet demandé lors de la visite</text></svg>'),

  ('11111111-a002-5000-0000-000000000004', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Petite annonce de location d''une maison à Pau, quartier Trespoey : 4 pièces avec jardin et garage, 950 € par mois, animaux acceptés, libre le 1er novembre ; contacter Diego au 06 14 72 58 33.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de location d''une maison à Pau</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">À LOUER — MAISON</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Pau — quartier Trespoey</text><text x="32" y="80" font-family="Arial" font-size="11" fill="#0F1839">4 pièces, jardin et garage</text><text x="32" y="102" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">950 € par mois</text><text x="32" y="124" font-family="Arial" font-size="11" fill="#0F1839">Animaux acceptés</text><text x="32" y="146" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Libre le 1er novembre</text><line x1="32" y1="158" x2="288" y2="158" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="176" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Contact : Diego — 06 14 72 58 33</text></svg>'),

  ('11111111-a002-5000-0000-000000000005', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Petite annonce d''une chambre chez l''habitant à Grenoble, à 5 minutes de l''université : chambre calme de 12 m², 300 € par mois petit-déjeuner inclus, pour étudiant ou étudiante ; contact uniquement par e-mail à l''adresse olena.location@exemple.fr.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce d''une chambre chez l''habitant à Grenoble</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">CHAMBRE CHEZ L''HABITANT</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Grenoble — à 5 minutes de l''université</text><text x="32" y="80" font-family="Arial" font-size="11" fill="#0F1839">Chambre calme de 12 m²</text><text x="32" y="102" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">300 € par mois, petit-déjeuner inclus</text><text x="32" y="124" font-family="Arial" font-size="11" fill="#0F1839">Pour étudiant ou étudiante</text><line x1="32" y1="138" x2="288" y2="138" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="160" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">Contact uniquement par e-mail :</text><text x="160" y="178" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">olena.location@exemple.fr</text></svg>'),

  ('11111111-a002-5000-0000-000000000006', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Petite annonce de location d''un studio meublé à Reims, face à la gare : surface 30 m² au 1er étage, loyer 510 € charges comprises, libre le 15 août ; contacter Wei au 06 38 90 41 27.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de location d''un studio meublé à Reims</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">À LOUER — STUDIO MEUBLÉ</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Reims — face à la gare</text><text x="32" y="80" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Surface : 30 m² — 1er étage</text><text x="32" y="102" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Loyer : 510 € charges comprises</text><text x="32" y="124" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Libre le 15 août</text><line x1="32" y1="140" x2="288" y2="140" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="166" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Contact : Wei — 06 38 90 41 27</text><text x="160" y="182" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Visites possibles en semaine et le samedi</text></svg>'),

  ('11111111-a002-5000-0000-000000000007', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Petite annonce de recherche de logement : Priya cherche un appartement T3 à Dijon, budget maximum 750 € par mois, à partir du mois de janvier, dans un quartier calme près d''une école ; contact au 07 64 29 81 50.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de recherche d''un appartement T3 à Dijon</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#168F5B" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#168F5B"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">RECHERCHE LOGEMENT</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Priya cherche un appartement T3 à Dijon</text><text x="32" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Budget maximum : 750 € par mois</text><text x="32" y="108" font-family="Arial" font-size="11" fill="#0F1839">À partir du mois de janvier</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Quartier calme, près d''une école</text><line x1="32" y1="148" x2="288" y2="148" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="170" font-family="Arial" font-size="10" font-weight="700" fill="#1E3A8C" text-anchor="middle">Contact : 07 64 29 81 50</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Famille sérieuse avec garanties</text></svg>'),

  ('11111111-a002-5000-0000-000000000008', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Petite annonce pour un appartement T1 à louer à Mulhouse, quartier Rebberg : 28 m² avec parking inclus, loyer 410 € hors charges, charges 45 € par mois, visites uniquement sur rendez-vous ; contacter Rachid au 06 77 03 64 18.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de location d''un appartement T1 à Mulhouse</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">À LOUER — APPARTEMENT T1</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Mulhouse — quartier Rebberg</text><text x="32" y="80" font-family="Arial" font-size="11" fill="#0F1839">28 m², parking inclus</text><text x="32" y="102" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Loyer : 410 € hors charges</text><text x="32" y="124" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Charges : 45 € par mois</text><text x="32" y="146" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">Visites uniquement sur rendez-vous</text><line x1="32" y1="158" x2="288" y2="158" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="176" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Rachid : 06 77 03 64 18</text></svg>'),

  ('11111111-a002-5000-0000-000000000009', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Petite annonce de colocation étudiante à Limoges : grande maison avec jardin, 3 chambres libres à 280 € chacune, à 10 minutes du campus en bus, internet et lave-linge inclus ; contacter Fatou au 06 45 17 92 36.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de colocation étudiante à Limoges</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">COLOCATION ÉTUDIANTE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Limoges — grande maison avec jardin</text><text x="32" y="80" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">3 chambres libres : 280 € chacune</text><text x="32" y="102" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">À 10 minutes du campus en bus</text><text x="32" y="124" font-family="Arial" font-size="11" fill="#0F1839">Internet et lave-linge inclus</text><line x1="32" y1="140" x2="288" y2="140" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="166" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Contact : Fatou — 06 45 17 92 36</text><text x="160" y="182" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Ambiance calme, idéale pour réviser</text></svg>'),

  ('11111111-a002-5000-0000-00000000000a', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Petite annonce pour un appartement T3 à louer à Caen, vue sur le port : 65 m² avec grand balcon, au 5e étage sans ascenseur, loyer 690 € par mois, libre le 1er mars ; contacter Mme Lefèvre au 02 31 84 56 20.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Annonce de location d''un appartement T3 à Caen</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">À LOUER — APPARTEMENT T3</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Caen — vue sur le port</text><text x="32" y="80" font-family="Arial" font-size="11" fill="#0F1839">65 m², grand balcon</text><text x="32" y="102" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">5e étage sans ascenseur</text><text x="32" y="124" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Loyer : 690 € par mois</text><text x="32" y="146" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Libre le 1er mars</text><line x1="32" y1="158" x2="288" y2="158" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="176" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Mme Lefèvre : 02 31 84 56 20</text></svg>');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-a002-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a002-5000-0000-000000000001', 'A2', 'CE',
   'Quel est le montant du loyer mensuel du studio ?',
   'L''annonce indique « **Loyer : 480 € charges comprises** » : c''est le montant à payer chaque mois. « 960 € » est le dépôt de garantie, versé une seule fois à l''entrée dans le logement, pas le loyer. « 520 € » et « 425 € » sont des montants plausibles pour un studio à Toulouse, mais ils n''apparaissent nulle part dans l''annonce.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a002-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a002-5000-0000-000000000002', 'A2', 'CE',
   'Quand peut-on téléphoner à Amadou ?',
   'L''annonce précise « **Appeler Amadou après 18h** » : il faut donc téléphoner en fin de journée. « Le matin » et « avant 18h » désignent justement les moments exclus par l''annonce. « Le dimanche seulement » invente une restriction de jour qui n''est écrite nulle part : la contrainte donnée porte sur l''heure, pas sur le jour de la semaine.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a002-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a002-5000-0000-000000000003', 'A2', 'CE',
   'Quel jour peut-on visiter l''appartement ?',
   'L''annonce de l''agence Brion indique « **Visites le mercredi de 14h à 17h** » : le seul jour de visite annoncé est le mercredi. « Le lundi », « le samedi » et « le vendredi » sont des jours plausibles pour visiter un logement, mais aucun n''est mentionné dans l''annonce — ces trois distracteurs ne reposent sur aucune information du document.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a002-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a002-5000-0000-000000000004', 'A2', 'CE',
   'À partir de quelle date la maison est-elle disponible ?',
   'L''annonce précise « **Libre le 1er novembre** » : la maison sera disponible à cette date. « Immédiatement » contredit l''annonce, qui fixe une date précise — ce distracteur conviendrait à la colocation « disponible immédiatement » d''une autre annonce. « Le 1er octobre » et « le 15 novembre » sont des dates proches mais inventées : seul le 1er novembre figure dans le document.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a002-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a002-5000-0000-000000000005', 'A2', 'CE',
   'Comment doit-on contacter Olena ?',
   'L''annonce indique « **Contact uniquement par e-mail** », avec l''adresse olena.location@exemple.fr. « Par téléphone » est exclu : aucun numéro n''apparaît dans l''annonce. « Par courrier » et « en se présentant sur place » ne sont proposés nulle part — le mot « **uniquement** » écarte tout autre moyen de contact que l''e-mail.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a002-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a002-5000-0000-000000000006', 'A2', 'CE',
   'Quelle est la surface du studio ?',
   'L''annonce indique « **Surface : 30 m²** » : c''est la taille du studio de Reims. « 15 m² » reprend le chiffre de la date de disponibilité (« libre le **15** août »), pas la surface. « 20 m² » et « 45 m² » sont des surfaces plausibles pour un studio, mais elles n''apparaissent pas dans l''annonce.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a002-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a002-5000-0000-000000000007', 'A2', 'CE',
   'Quel est le budget maximum de Priya ?',
   'L''annonce de recherche indique « **Budget maximum : 750 € par mois** » : Priya ne peut pas payer plus que cette somme. « 650 € », « 700 € » et « 850 € » sont des montants proches et plausibles pour un T3 à Dijon, mais aucun n''apparaît dans l''annonce — le seul chiffre donné comme limite est bien 750 €.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a002-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a002-5000-0000-000000000008', 'A2', 'CE',
   'Quel est le montant des charges chaque mois ?',
   'L''annonce distingue deux montants : le loyer et les charges. La ligne « **Charges : 45 € par mois** » donne la réponse. « 410 € » est le loyer hors charges — ce distracteur répondrait à « quel est le loyer ? ». « 455 € » correspond à l''addition loyer + charges, que l''annonce ne présente pas comme « les charges ». « 35 € » est un montant plausible mais absent du document.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a002-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a002-5000-0000-000000000009', 'A2', 'CE',
   'Comment peut-on aller de la maison au campus ?',
   'L''annonce situe la maison « **à 10 minutes du campus en bus** » : le moyen de transport indiqué est le bus. « À pied », « en tramway » et « à vélo » sont des moyens de déplacement plausibles pour un trajet étudiant, mais aucun n''est mentionné dans l''annonce — seule la liaison en bus est précisée par Fatou.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a002-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a002-5000-0000-00000000000a', 'A2', 'CE',
   'À quel étage se trouve l''appartement ?',
   'L''annonce indique en rouge « **5e étage sans ascenseur** » : l''appartement de Caen se trouve au 5e étage. « Au 3e étage » et « au 1er étage » sont des valeurs plausibles mais absentes de l''annonce. « Au rez-de-chaussée » contredit directement la mention « sans ascenseur », qui n''aurait alors aucune raison d''être signalée en rouge.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('11111111-a002-2100-0000-000000000001', '11111111-a002-1000-0000-000000000001', '960 €', 'false', '1'),
  ('11111111-a002-2200-0000-000000000001', '11111111-a002-1000-0000-000000000001', '480 €', 'true', '2'),
  ('11111111-a002-2300-0000-000000000001', '11111111-a002-1000-0000-000000000001', '520 €', 'false', '3'),
  ('11111111-a002-2400-0000-000000000001', '11111111-a002-1000-0000-000000000001', '425 €', 'false', '4'),

  ('11111111-a002-2100-0000-000000000002', '11111111-a002-1000-0000-000000000002', 'Le matin', 'false', '1'),
  ('11111111-a002-2200-0000-000000000002', '11111111-a002-1000-0000-000000000002', 'Avant 18h', 'false', '2'),
  ('11111111-a002-2300-0000-000000000002', '11111111-a002-1000-0000-000000000002', 'Après 18h', 'true', '3'),
  ('11111111-a002-2400-0000-000000000002', '11111111-a002-1000-0000-000000000002', 'Le dimanche seulement', 'false', '4'),

  ('11111111-a002-2100-0000-000000000003', '11111111-a002-1000-0000-000000000003', 'Le mercredi', 'true', '1'),
  ('11111111-a002-2200-0000-000000000003', '11111111-a002-1000-0000-000000000003', 'Le lundi', 'false', '2'),
  ('11111111-a002-2300-0000-000000000003', '11111111-a002-1000-0000-000000000003', 'Le samedi', 'false', '3'),
  ('11111111-a002-2400-0000-000000000003', '11111111-a002-1000-0000-000000000003', 'Le vendredi', 'false', '4'),

  ('11111111-a002-2100-0000-000000000004', '11111111-a002-1000-0000-000000000004', 'Immédiatement', 'false', '1'),
  ('11111111-a002-2200-0000-000000000004', '11111111-a002-1000-0000-000000000004', 'Le 1er octobre', 'false', '2'),
  ('11111111-a002-2300-0000-000000000004', '11111111-a002-1000-0000-000000000004', 'Le 15 novembre', 'false', '3'),
  ('11111111-a002-2400-0000-000000000004', '11111111-a002-1000-0000-000000000004', 'Le 1er novembre', 'true', '4'),

  ('11111111-a002-2100-0000-000000000005', '11111111-a002-1000-0000-000000000005', 'Par téléphone', 'false', '1'),
  ('11111111-a002-2200-0000-000000000005', '11111111-a002-1000-0000-000000000005', 'Par e-mail', 'true', '2'),
  ('11111111-a002-2300-0000-000000000005', '11111111-a002-1000-0000-000000000005', 'Par courrier', 'false', '3'),
  ('11111111-a002-2400-0000-000000000005', '11111111-a002-1000-0000-000000000005', 'En se présentant sur place', 'false', '4'),

  ('11111111-a002-2100-0000-000000000006', '11111111-a002-1000-0000-000000000006', '20 m²', 'false', '1'),
  ('11111111-a002-2200-0000-000000000006', '11111111-a002-1000-0000-000000000006', '45 m²', 'false', '2'),
  ('11111111-a002-2300-0000-000000000006', '11111111-a002-1000-0000-000000000006', '30 m²', 'true', '3'),
  ('11111111-a002-2400-0000-000000000006', '11111111-a002-1000-0000-000000000006', '15 m²', 'false', '4'),

  ('11111111-a002-2100-0000-000000000007', '11111111-a002-1000-0000-000000000007', '650 €', 'false', '1'),
  ('11111111-a002-2200-0000-000000000007', '11111111-a002-1000-0000-000000000007', '700 €', 'false', '2'),
  ('11111111-a002-2300-0000-000000000007', '11111111-a002-1000-0000-000000000007', '850 €', 'false', '3'),
  ('11111111-a002-2400-0000-000000000007', '11111111-a002-1000-0000-000000000007', '750 €', 'true', '4'),

  ('11111111-a002-2100-0000-000000000008', '11111111-a002-1000-0000-000000000008', '45 €', 'true', '1'),
  ('11111111-a002-2200-0000-000000000008', '11111111-a002-1000-0000-000000000008', '410 €', 'false', '2'),
  ('11111111-a002-2300-0000-000000000008', '11111111-a002-1000-0000-000000000008', '455 €', 'false', '3'),
  ('11111111-a002-2400-0000-000000000008', '11111111-a002-1000-0000-000000000008', '35 €', 'false', '4'),

  ('11111111-a002-2100-0000-000000000009', '11111111-a002-1000-0000-000000000009', 'À pied', 'false', '1'),
  ('11111111-a002-2200-0000-000000000009', '11111111-a002-1000-0000-000000000009', 'En bus', 'true', '2'),
  ('11111111-a002-2300-0000-000000000009', '11111111-a002-1000-0000-000000000009', 'En tramway', 'false', '3'),
  ('11111111-a002-2400-0000-000000000009', '11111111-a002-1000-0000-000000000009', 'À vélo', 'false', '4'),

  ('11111111-a002-2100-0000-00000000000a', '11111111-a002-1000-0000-00000000000a', 'Au 3e étage', 'false', '1'),
  ('11111111-a002-2200-0000-00000000000a', '11111111-a002-1000-0000-00000000000a', 'Au rez-de-chaussée', 'false', '2'),
  ('11111111-a002-2300-0000-00000000000a', '11111111-a002-1000-0000-00000000000a', 'Au 5e étage', 'true', '3'),
  ('11111111-a002-2400-0000-00000000000a', '11111111-a002-1000-0000-00000000000a', 'Au 1er étage', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 10 items (NN=01..0a), UUID déterministes uniques (questions 1000-,
--     medias 5000-, choices 2100/2200/2300/2400-).
-- [x] Tous les supports = petites annonces logement, 10 situations différentes
--     (studio Toulouse, colocation Montpellier, T2 agence Angers, maison Pau,
--     chambre chez l'habitant Grenoble, studio Reims, recherche T3 Dijon,
--     T1 Mulhouse, colocation étudiante Limoges, T3 Caen). Aucun support
--     interdit (pas d'horaires, étiquette, SMS, affichette, menu, etc.).
-- [x] 4 choix par question, exactement 1 correct ; distribution des bonnes
--     réponses : pos1=2 (items 3,8), pos2=3 (items 1,5,9), pos3=3 (items
--     2,6,10), pos4=2 (items 4,7) — max 3 par position, 4 positions utilisées.
-- [x] Questions sur UNE information explicite (loyer, charges, surface, étage,
--     date, jour de visite, heure d'appel, mode de contact, transport, budget) ;
--     labels des choices = texte de la réponse ; distracteurs = autres valeurs
--     présentes (dépôt 960 €, loyer 410 €, total 455 €, « 15 » août) ou
--     plausibles de l'annonce.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chacun des
--     3 distracteurs, point clé en **gras**.
-- [x] SVG : viewBox="0 0 320 200", style « document » (carte blanche, bandeau,
--     Arial), palette charte, rouge réservé aux infos critiques (non-fumeur,
--     visites sur rendez-vous, 5e étage sans ascenseur) ; balises équilibrées ;
--     alt_text descriptif complet sur chaque media. Texte utile ~15-35 mots
--     par annonce.
-- [x] Apostrophes SQL doublées ('') partout (SVG, alt_text, statements,
--     explanations, labels). Pas de JSONB (choices en lignes). Contenu 100%
--     original, prénoms variés (Lucia, Amadou, Diego, Olena, Wei, Priya,
--     Rachid, Fatou, Mme Lefèvre) et villes variées (Toulouse, Montpellier,
--     Angers, Pau, Grenoble, Reims, Dijon, Mulhouse, Limoges, Caen), chiffres
--     tous différents.
-- [x] competence_code : 5× ce_reperage_explicite (items 2,3,4,5,9),
--     5× ce_detail_specifique (items 1,6,7,8,10).
-- ============================================================================
