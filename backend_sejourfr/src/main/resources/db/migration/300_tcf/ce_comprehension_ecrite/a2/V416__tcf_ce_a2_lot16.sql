-- ============================================================================
-- V416 — TCF CE A2 — lot 16 (support : plan / indication)
-- ----------------------------------------------------------------------------
-- 10 items CE A2, theme 22222222-0000-0000-0000-000000000002.
-- Chaque item = un plan d'orientation ou un panneau d'indications original
-- (SVG style « document ») + 1 question sur UNE information explicite
-- + 4 choix (1 correct).
-- UUID déterministes : questions 11111111-a010-1000-…, medias 11111111-a010-5000-…,
-- choices 11111111-a010-2100/2200/2300/2400-… (display_order 1..4).
-- ============================================================================


-- medias (IMAGE) — plans et panneaux d'indications référencés par les questions ci-dessous
INSERT INTO medias
  (id, type, url, storage_key, original_filename, content_type, size_bytes, duration_sec,
   alt_text, created_at, transcript, inline_svg)
VALUES
  ('11111111-a010-5000-0000-000000000001', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Plan des étages d''une maison de santé à Aubervilliers : 2e étage, dentiste (Dr Olena Kovach) ; 1er étage, médecine générale (Dr Wei Zhang) ; rez-de-chaussée, accueil et pharmacie ; sous-sol, laboratoire d''analyses. Avertissement en rouge : ascenseur en panne, prendre l''escalier.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Plan des étages de la maison de santé d''Aubervilliers</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">MAISON DE SANTÉ</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Aubervilliers — Plan des étages</text><text x="32" y="82" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">2e étage</text><text x="288" y="82" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">Dentiste — Dr Olena Kovach</text><text x="32" y="104" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">1er étage</text><text x="288" y="104" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="end">Médecine générale — Dr Wei Zhang</text><text x="32" y="126" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Rez-de-chaussée</text><text x="288" y="126" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="end">Accueil — Pharmacie</text><text x="32" y="148" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Sous-sol</text><text x="288" y="148" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="end">Laboratoire d''analyses</text><line x1="32" y1="160" x2="288" y2="160" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F" text-anchor="middle">Ascenseur en panne : prenez l''escalier</text></svg>'),

  ('11111111-a010-5000-0000-000000000002', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''indications au rez-de-chaussée de la mairie de Pau : état civil, couloir de droite, porte 4 ; aide sociale (CCAS), couloir de gauche, porte 2 ; salle des mariages, 1er étage ; urbanisme, bâtiment annexe dans la cour intérieure.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Panneau d''indications de la mairie de Pau</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">MAIRIE DE PAU</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Indications — Rez-de-chaussée</text><text x="32" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">État civil</text><text x="288" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">couloir de droite, porte 4</text><text x="32" y="108" font-family="Arial" font-size="11" fill="#0F1839">Aide sociale (CCAS)</text><text x="288" y="108" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="end">couloir de gauche, porte 2</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Salle des mariages</text><text x="288" y="132" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="end">1er étage</text><text x="32" y="156" font-family="Arial" font-size="11" fill="#0F1839">Urbanisme</text><text x="288" y="156" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="end">bâtiment annexe, cour intérieure</text><line x1="32" y1="166" x2="288" y2="166" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="182" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Accueil général : hall d''entrée</text></svg>'),

  ('11111111-a010-5000-0000-000000000003', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Plan des niveaux du centre commercial Les Arcades à Mulhouse : niveau 2, restaurants ; niveau 1, pharmacie et salon de coiffure Lucia ; niveau 0, supermarché et boulangerie ; niveaux -1 et -2, parking. Les ascenseurs sont au centre de la galerie.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Plan des niveaux du centre commercial Les Arcades</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">CENTRE COMMERCIAL LES ARCADES</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Mulhouse — Plan des niveaux</text><text x="32" y="82" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Niveau 2</text><text x="288" y="82" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="end">Restaurants</text><text x="32" y="104" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Niveau 1</text><text x="288" y="104" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">Pharmacie — Salon de coiffure Lucia</text><text x="32" y="126" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Niveau 0</text><text x="288" y="126" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="end">Supermarché — Boulangerie</text><text x="32" y="148" font-family="Arial" font-size="11" font-weight="700" fill="#0F1839">Niveaux -1 et -2</text><text x="288" y="148" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="end">Parking</text><line x1="32" y1="160" x2="288" y2="160" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317" text-anchor="middle">Ascenseurs au centre de la galerie</text></svg>'),

  ('11111111-a010-5000-0000-000000000004', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Plan d''orientation des visiteurs de l''hôpital Nord de Saint-Étienne : urgences, bâtiment A, rez-de-chaussée (en rouge) ; consultations, bâtiment B, 1er étage ; radiologie, bâtiment B, sous-sol ; maternité, bâtiment C. Accueil général dans le hall du bâtiment A.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Plan d''orientation de l''hôpital Nord de Saint-Étienne</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">HÔPITAL NORD — SAINT-ÉTIENNE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Plan d''orientation des visiteurs</text><text x="32" y="82" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F">Urgences : bâtiment A, rez-de-chaussée</text><text x="32" y="106" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Consultations : bâtiment B, 1er étage</text><text x="32" y="128" font-family="Arial" font-size="11" fill="#0F1839">Radiologie : bâtiment B, sous-sol</text><text x="32" y="150" font-family="Arial" font-size="11" fill="#0F1839">Maternité : bâtiment C</text><line x1="32" y1="162" x2="288" y2="162" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Accueil général : hall du bâtiment A</text></svg>'),

  ('11111111-a010-5000-0000-000000000005', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Plan du campus universitaire de Besançon : bâtiment A, amphithéâtres ; bâtiment B, secrétariat des inscriptions au bureau 12 ; bâtiment C, bibliothèque universitaire ; restaurant universitaire derrière le bâtiment C.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Plan du campus universitaire de Besançon</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">UNIVERSITÉ — CAMPUS DE BESANÇON</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Plan du campus</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Bâtiment A : amphithéâtres</text><text x="32" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Bâtiment B : secrétariat des inscriptions — bureau 12</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Bâtiment C : bibliothèque universitaire</text><text x="32" y="156" font-family="Arial" font-size="11" fill="#0F1839">Restaurant universitaire : derrière le bâtiment C</text><line x1="32" y1="166" x2="288" y2="166" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="182" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Entrée principale : avenue de l''Observatoire</text></svg>'),

  ('11111111-a010-5000-0000-000000000006', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Plan du parc de la Roseraie à Angers : aire de jeux à l''entrée nord ; lac et location de barques au centre du parc ; tables de pique-nique à l''entrée sud. Mention en rouge : pelouse centrale interdite aux chiens.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Plan du parc de la Roseraie à Angers</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#168F5B" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#168F5B"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">PARC DE LA ROSERAIE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Angers — Plan du parc</text><text x="32" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Aire de jeux : entrée nord</text><text x="32" y="108" font-family="Arial" font-size="11" fill="#0F1839">Lac et location de barques : centre du parc</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Tables de pique-nique : entrée sud</text><line x1="32" y1="146" x2="288" y2="146" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="168" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F" text-anchor="middle">Pelouse centrale interdite aux chiens</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Parc ouvert tous les jours — ville d''Angers</text></svg>'),

  ('11111111-a010-5000-0000-000000000007', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''indications pour les voyageurs de la gare de Perpignan : guichets et informations dans le hall principal ; quais 1 à 4 par le passage souterrain ; toilettes au niveau -1 ; taxis à la sortie ouest.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Panneau d''indications de la gare de Perpignan</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">GARE DE PERPIGNAN</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Indications voyageurs</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Guichets et informations : hall principal</text><text x="32" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Quais 1 à 4 : par le passage souterrain</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Toilettes : niveau -1</text><text x="32" y="156" font-family="Arial" font-size="11" fill="#0F1839">Taxis : sortie ouest</text><line x1="32" y1="166" x2="288" y2="166" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="182" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Objets trouvés : guichet 3 du hall principal</text></svg>'),

  ('11111111-a010-5000-0000-000000000008', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Plan de la résidence Les Tilleuls à Créteil : bâtiment A, appartements 1 à 24, avec la loge du gardien (M. Sow) au rez-de-chaussée ; bâtiment B, appartements 25 à 48 ; local à vélos derrière le bâtiment B. Mention en rouge : ne pas stationner devant le portail, accès pompiers.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Plan de la résidence Les Tilleuls à Créteil</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">RÉSIDENCE LES TILLEULS</text><text x="160" y="54" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Créteil — Plan de la résidence</text><text x="32" y="80" font-family="Arial" font-size="11" fill="#0F1839">Bâtiment A : appartements 1 à 24</text><text x="32" y="102" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Loge du gardien (M. Sow) : bâtiment A, rez-de-chaussée</text><text x="32" y="124" font-family="Arial" font-size="11" fill="#0F1839">Bâtiment B : appartements 25 à 48</text><text x="32" y="146" font-family="Arial" font-size="11" fill="#0F1839">Local à vélos : derrière le bâtiment B</text><line x1="32" y1="158" x2="288" y2="158" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="178" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F" text-anchor="middle">Ne pas stationner devant le portail — accès pompiers</text></svg>'),

  ('11111111-a010-5000-0000-000000000009', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''orientation des usagers de la préfecture du Gard à Nîmes : titres de séjour, salle 2 au rez-de-chaussée ; permis de conduire, salle 5 au 1er étage ; naturalisations, bureau 8 au 2e étage. Mention en rouge : accès uniquement sur convocation.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Panneau d''orientation de la préfecture du Gard</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">PRÉFECTURE DU GARD</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Nîmes — Orientation des usagers</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Titres de séjour : salle 2, rez-de-chaussée</text><text x="32" y="108" font-family="Arial" font-size="11" fill="#0F1839">Permis de conduire : salle 5, 1er étage</text><text x="32" y="132" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Naturalisations : bureau 8, 2e étage</text><line x1="32" y1="146" x2="288" y2="146" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="168" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F" text-anchor="middle">Accès uniquement sur convocation</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Présentez votre convocation et une pièce d''identité</text></svg>'),

  ('11111111-a010-5000-0000-00000000000a', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Plan des allées des halles du centre à Toulon : allée 1, fruits et légumes (stand de Diego) ; allée 2, poissonnerie ; allée 3, fromages (stand de Priya). Mention en rouge : sortie de secours au fond de la halle.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Plan des allées des halles du centre à Toulon</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">HALLES DU CENTRE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Toulon — Plan des allées</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Allée 1 : fruits et légumes — stand de Diego</text><text x="32" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Allée 2 : poissonnerie</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Allée 3 : fromages — stand de Priya</text><line x1="32" y1="146" x2="288" y2="146" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="168" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F" text-anchor="middle">Sortie de secours : au fond de la halle</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Entrée principale : place du Marché</text></svg>');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-a010-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a010-5000-0000-000000000001', 'A2', 'CE',
   'À quel étage se trouve le dentiste ?',
   'Le plan indique « **2e étage : Dentiste — Dr Olena Kovach** » : c''est la bonne réponse. Le rez-de-chaussée accueille l''accueil et la pharmacie, le 1er étage la médecine générale du Dr Wei Zhang, et le sous-sol le laboratoire d''analyses : chacun de ces trois distracteurs correspond à un autre service du plan, pas au cabinet dentaire.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a010-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a010-5000-0000-000000000002', 'A2', 'CE',
   'Où se trouve le service état civil ?',
   'Le panneau indique « **État civil : couloir de droite, porte 4** » : c''est la bonne réponse. Le couloir de gauche, porte 2, mène à l''aide sociale (CCAS) — ce distracteur répondrait à « où se trouve le CCAS ? ». Le 1er étage abrite la salle des mariages, et le bâtiment annexe de la cour intérieure correspond au service urbanisme : deux autres lieux du panneau, sans rapport avec l''état civil.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a010-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a010-5000-0000-000000000003', 'A2', 'CE',
   'À quel niveau du centre commercial se trouve la pharmacie ?',
   'Le plan indique « **Niveau 1 : Pharmacie — Salon de coiffure Lucia** » : la pharmacie est donc au niveau 1. Le niveau 0 regroupe le supermarché et la boulangerie, le niveau 2 les restaurants, et le niveau -1 fait partie du parking : ces trois distracteurs reprennent d''autres niveaux du plan, qui correspondent à d''autres commerces ou services.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a010-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a010-5000-0000-000000000004', 'A2', 'CE',
   'Où se trouvent les consultations ?',
   'Le plan d''orientation indique « **Consultations : bâtiment B, 1er étage** » : c''est la bonne réponse. Le bâtiment A, rez-de-chaussée, abrite les urgences (mention en rouge) — ce distracteur répondrait à « où sont les urgences ? ». Le sous-sol du bâtiment B correspond à la radiologie, et le bâtiment C à la maternité : deux autres services du plan, distincts des consultations.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a010-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a010-5000-0000-000000000005', 'A2', 'CE',
   'Où faut-il aller pour déposer un dossier d''inscription ?',
   'Le plan précise « **Bâtiment B : secrétariat des inscriptions — bureau 12** » : c''est donc là qu''on dépose un dossier. Le bâtiment A ne contient que des amphithéâtres, le bâtiment C la bibliothèque universitaire, et derrière le bâtiment C se trouve le restaurant universitaire : ces trois distracteurs désignent d''autres lieux du campus, sans lien avec les inscriptions.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a010-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a010-5000-0000-000000000006', 'A2', 'CE',
   'Où se trouve l''aire de jeux du parc ?',
   'Le plan indique « **Aire de jeux : entrée nord** » : c''est la bonne réponse. Le centre du parc accueille le lac et la location de barques, et l''entrée sud les tables de pique-nique — ces deux distracteurs répondraient à d''autres questions de localisation. La pelouse centrale n''abrite aucun équipement : elle est seulement mentionnée en rouge comme interdite aux chiens.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a010-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a010-5000-0000-000000000007', 'A2', 'CE',
   'Comment accède-t-on aux quais 1 à 4 ?',
   'Le panneau indique « **Quais 1 à 4 : par le passage souterrain** » : c''est la bonne réponse. Le hall principal abrite les guichets et les informations, pas l''accès aux quais. La sortie ouest mène aux taxis — ce distracteur répondrait à « où prend-on un taxi ? ». Le niveau -1 correspond aux toilettes : un autre lieu du panneau, sans rapport avec les quais.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a010-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a010-5000-0000-000000000008', 'A2', 'CE',
   'Où se trouve la loge du gardien de la résidence ?',
   'Le plan précise « **Loge du gardien (M. Sow) : bâtiment A, rez-de-chaussée** » : c''est la bonne réponse. Le bâtiment B ne contient que les appartements 25 à 48, et derrière le bâtiment B se trouve le local à vélos — deux distracteurs qui répondraient à d''autres questions de localisation. « Devant le portail » est l''endroit où il est interdit de stationner (accès pompiers), pas la loge.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a010-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a010-5000-0000-000000000009', 'A2', 'CE',
   'Où se trouve le service des naturalisations ?',
   'Le panneau d''orientation indique « **Naturalisations : bureau 8, 2e étage** » : c''est la bonne réponse. La salle 2 du rez-de-chaussée est réservée aux titres de séjour, et la salle 5 du 1er étage aux permis de conduire : ces deux distracteurs reprennent d''autres services du panneau. « L''accueil du hall » est plausible dans une préfecture, mais il n''apparaît nulle part comme lieu des naturalisations.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a010-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a010-5000-0000-00000000000a', 'A2', 'CE',
   'Dans quelle allée se trouve la poissonnerie ?',
   'Le plan des halles indique « **Allée 2 : poissonnerie** » : c''est la bonne réponse. L''allée 1 est celle des fruits et légumes (stand de Diego) et l''allée 3 celle des fromages (stand de Priya) : ces deux distracteurs correspondent à d''autres stands du plan. « Au fond de la halle » désigne la sortie de secours mentionnée en rouge, pas un emplacement de vente.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('11111111-a010-2100-0000-000000000001', '11111111-a010-1000-0000-000000000001', 'Au rez-de-chaussée', 'false', '1'),
  ('11111111-a010-2200-0000-000000000001', '11111111-a010-1000-0000-000000000001', 'Au 1er étage', 'false', '2'),
  ('11111111-a010-2300-0000-000000000001', '11111111-a010-1000-0000-000000000001', 'Au 2e étage', 'true', '3'),
  ('11111111-a010-2400-0000-000000000001', '11111111-a010-1000-0000-000000000001', 'Au sous-sol', 'false', '4'),

  ('11111111-a010-2100-0000-000000000002', '11111111-a010-1000-0000-000000000002', 'Dans le couloir de droite, porte 4', 'true', '1'),
  ('11111111-a010-2200-0000-000000000002', '11111111-a010-1000-0000-000000000002', 'Dans le couloir de gauche, porte 2', 'false', '2'),
  ('11111111-a010-2300-0000-000000000002', '11111111-a010-1000-0000-000000000002', 'Au 1er étage', 'false', '3'),
  ('11111111-a010-2400-0000-000000000002', '11111111-a010-1000-0000-000000000002', 'Dans le bâtiment annexe', 'false', '4'),

  ('11111111-a010-2100-0000-000000000003', '11111111-a010-1000-0000-000000000003', 'Au niveau 0', 'false', '1'),
  ('11111111-a010-2200-0000-000000000003', '11111111-a010-1000-0000-000000000003', 'Au niveau 1', 'true', '2'),
  ('11111111-a010-2300-0000-000000000003', '11111111-a010-1000-0000-000000000003', 'Au niveau 2', 'false', '3'),
  ('11111111-a010-2400-0000-000000000003', '11111111-a010-1000-0000-000000000003', 'Au niveau -1', 'false', '4'),

  ('11111111-a010-2100-0000-000000000004', '11111111-a010-1000-0000-000000000004', 'Au bâtiment A, au rez-de-chaussée', 'false', '1'),
  ('11111111-a010-2200-0000-000000000004', '11111111-a010-1000-0000-000000000004', 'Au bâtiment C', 'false', '2'),
  ('11111111-a010-2300-0000-000000000004', '11111111-a010-1000-0000-000000000004', 'Au bâtiment B, au sous-sol', 'false', '3'),
  ('11111111-a010-2400-0000-000000000004', '11111111-a010-1000-0000-000000000004', 'Au bâtiment B, au 1er étage', 'true', '4'),

  ('11111111-a010-2100-0000-000000000005', '11111111-a010-1000-0000-000000000005', 'Au bâtiment A', 'false', '1'),
  ('11111111-a010-2200-0000-000000000005', '11111111-a010-1000-0000-000000000005', 'Au bâtiment B, bureau 12', 'true', '2'),
  ('11111111-a010-2300-0000-000000000005', '11111111-a010-1000-0000-000000000005', 'Au bâtiment C', 'false', '3'),
  ('11111111-a010-2400-0000-000000000005', '11111111-a010-1000-0000-000000000005', 'Derrière le bâtiment C', 'false', '4'),

  ('11111111-a010-2100-0000-000000000006', '11111111-a010-1000-0000-000000000006', 'À l''entrée nord', 'true', '1'),
  ('11111111-a010-2200-0000-000000000006', '11111111-a010-1000-0000-000000000006', 'Au centre du parc', 'false', '2'),
  ('11111111-a010-2300-0000-000000000006', '11111111-a010-1000-0000-000000000006', 'À l''entrée sud', 'false', '3'),
  ('11111111-a010-2400-0000-000000000006', '11111111-a010-1000-0000-000000000006', 'Sur la pelouse centrale', 'false', '4'),

  ('11111111-a010-2100-0000-000000000007', '11111111-a010-1000-0000-000000000007', 'Par le hall principal', 'false', '1'),
  ('11111111-a010-2200-0000-000000000007', '11111111-a010-1000-0000-000000000007', 'Par la sortie ouest', 'false', '2'),
  ('11111111-a010-2300-0000-000000000007', '11111111-a010-1000-0000-000000000007', 'Par le passage souterrain', 'true', '3'),
  ('11111111-a010-2400-0000-000000000007', '11111111-a010-1000-0000-000000000007', 'Par le niveau -1', 'false', '4'),

  ('11111111-a010-2100-0000-000000000008', '11111111-a010-1000-0000-000000000008', 'Au bâtiment B', 'false', '1'),
  ('11111111-a010-2200-0000-000000000008', '11111111-a010-1000-0000-000000000008', 'Derrière le bâtiment B', 'false', '2'),
  ('11111111-a010-2300-0000-000000000008', '11111111-a010-1000-0000-000000000008', 'Devant le portail', 'false', '3'),
  ('11111111-a010-2400-0000-000000000008', '11111111-a010-1000-0000-000000000008', 'Au rez-de-chaussée du bâtiment A', 'true', '4'),

  ('11111111-a010-2100-0000-000000000009', '11111111-a010-1000-0000-000000000009', 'Salle 2, au rez-de-chaussée', 'false', '1'),
  ('11111111-a010-2200-0000-000000000009', '11111111-a010-1000-0000-000000000009', 'Bureau 8, au 2e étage', 'true', '2'),
  ('11111111-a010-2300-0000-000000000009', '11111111-a010-1000-0000-000000000009', 'Salle 5, au 1er étage', 'false', '3'),
  ('11111111-a010-2400-0000-000000000009', '11111111-a010-1000-0000-000000000009', 'À l''accueil du hall', 'false', '4'),

  ('11111111-a010-2100-0000-00000000000a', '11111111-a010-1000-0000-00000000000a', 'Dans l''allée 1', 'false', '1'),
  ('11111111-a010-2200-0000-00000000000a', '11111111-a010-1000-0000-00000000000a', 'Au fond de la halle', 'false', '2'),
  ('11111111-a010-2300-0000-00000000000a', '11111111-a010-1000-0000-00000000000a', 'Dans l''allée 2', 'true', '3'),
  ('11111111-a010-2400-0000-00000000000a', '11111111-a010-1000-0000-00000000000a', 'Dans l''allée 3', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 10 items (NN=01..0a), UUID déterministes uniques (questions a010-1000-,
--     medias a010-5000-, choices a010-2100/2200/2300/2400-).
-- [x] Tous les supports = plan / indication, 10 lieux différents (maison de
--     santé, mairie, centre commercial, hôpital, campus universitaire, parc,
--     gare — indications directionnelles uniquement, sans horaires —,
--     résidence, préfecture, halles). Aucun support interdit (pas d'horaires,
--     pas d'annonce, pas de menu, pas de règlement…).
-- [x] 4 choix par question, exactement 1 correct ; distribution des bonnes
--     réponses : pos1=2 (items 2,6), pos2=3 (items 3,5,9), pos3=3 (items
--     1,7,10), pos4=2 (items 4,8) — max 3 par position, 4 positions utilisées.
-- [x] Questions sur UNE information explicite (étage, niveau, bâtiment,
--     allée, accès) ; labels des choices = texte de la réponse ; distracteurs
--     = autres lieux présents sur le plan ou plausibles.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chacun des
--     3 distracteurs, point clé en **gras**.
-- [x] SVG : viewBox="0 0 320 200", Arial, palette charte, rouge réservé aux
--     infos critiques (ascenseur en panne, urgences, interdiction chiens,
--     accès pompiers, convocation obligatoire, sortie de secours) ; balises
--     équilibrées ; alt_text descriptif complet sur chaque media. Texte utile
--     ~10-40 mots par plan.
-- [x] Apostrophes SQL doublées ('') partout (SVG, alt_text, statements,
--     explanations, labels). Pas de JSONB (choices en lignes). Contenu 100%
--     original, prénoms variés (Olena Kovach, Wei Zhang, Lucia, M. Sow,
--     Diego, Priya), villes toutes différentes (Aubervilliers, Pau, Mulhouse,
--     Saint-Étienne, Besançon, Angers, Perpignan, Créteil, Nîmes, Toulon),
--     chiffres variés (portes 2/4, bureau 8/12, salles 2/5, allées 1-3,
--     appartements 1-24/25-48, niveaux -2 à 2).
-- [x] competence_code : 5× ce_reperage_explicite (items 1,2,4,8,9),
--     5× ce_detail_specifique (items 3,5,6,7,10).
-- ============================================================================
