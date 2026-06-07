-- ============================================================================
-- V408 — TCF CE A2 — lot 08 (support : panneau d'information (lieu public))
-- ----------------------------------------------------------------------------
-- 10 items CE A2, theme 22222222-0000-0000-0000-000000000002.
-- Chaque item = un panneau d'information original affiché dans un lieu public
-- (SVG style « document ») + 1 question sur UNE information explicite
-- + 4 choix (1 correct).
-- UUID déterministes : questions 11111111-a008-1000-…, medias 11111111-a008-5000-…,
-- choices 11111111-a008-2100/2200/2300/2400-… (display_order 1..4).
-- ============================================================================


-- medias (IMAGE) — panneaux d'information référencés par les questions ci-dessous
INSERT INTO medias
  (id, type, url, storage_key, original_filename, content_type, size_bytes, duration_sec,
   alt_text, created_at, transcript, inline_svg)
VALUES
  ('11111111-a008-5000-0000-000000000001', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''information du parc des Cèdres à Toulouse : l''aire de jeux est fermée pour travaux de rénovation du 3 au 21 mars ; le reste du parc reste ouvert ; renseignements auprès des services techniques (Mme Olena Kovalenko).',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Panneau d''information du parc des Cèdres de Toulouse</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">PARC DES CÈDRES — INFORMATION</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Ville de Toulouse</text><text x="32" y="84" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F">Aire de jeux fermée pour travaux</text><text x="32" y="106" font-family="Arial" font-size="11" fill="#0F1839">Travaux de rénovation :</text><text x="32" y="126" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C">du 3 au 21 mars</text><text x="32" y="150" font-family="Arial" font-size="11" fill="#168F5B">Le reste du parc reste ouvert.</text><line x1="32" y1="162" x2="288" y2="162" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Renseignements : services techniques — Mme Olena Kovalenko</text></svg>'),

  ('11111111-a008-5000-0000-000000000002', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''information de la mairie annexe de Saint-Étienne : le service des cartes d''identité et des passeports est transféré au bureau 204, au 2e étage ; l''ancien bureau était le 12, au rez-de-chaussée ; ascenseur à droite de l''accueil.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Panneau d''information de la mairie annexe de Saint-Étienne</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">MAIRIE ANNEXE — INFORMATION</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Saint-Étienne — Cartes d''identité et passeports</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Le service est transféré au :</text><text x="32" y="106" font-family="Arial" font-size="13" font-weight="700" fill="#168F5B">Bureau 204 — 2e étage</text><text x="32" y="130" font-family="Arial" font-size="11" fill="#0F1839">Ancien bureau : 12, rez-de-chaussée</text><line x1="32" y1="148" x2="288" y2="148" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="170" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Ascenseur à droite de l''accueil</text></svg>'),

  ('11111111-a008-5000-0000-000000000003', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''information de la bibliothèque Georges-Sand à Clermont-Ferrand : Wi-Fi gratuit dans tout le bâtiment ; code d''accès à demander à l''accueil, valable 4 heures ; réseau BIBLIO-CF.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Panneau d''information Wi-Fi de la bibliothèque Georges-Sand</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#168F5B" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#168F5B"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">WI-FI GRATUIT</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Bibliothèque Georges-Sand — Clermont-Ferrand</text><text x="32" y="86" font-family="Arial" font-size="11" fill="#0F1839">Demandez votre code d''accès à l''accueil.</text><text x="32" y="112" font-family="Arial" font-size="13" font-weight="700" fill="#1E3A8C">Code valable 4 heures</text><line x1="32" y1="132" x2="288" y2="132" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="156" font-family="Arial" font-size="11" fill="#0F1839">Réseau : BIBLIO-CF</text><text x="160" y="180" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Connexion possible dans tout le bâtiment</text></svg>'),

  ('11111111-a008-5000-0000-000000000004', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''information de la piscine Jean-Moulin au Havre : le bassin extérieur est fermé pour entretien jusqu''au 12 mai inclus ; le bassin intérieur reste ouvert ; signé Wei Zhang, responsable de l''établissement.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Panneau d''information de la piscine Jean-Moulin du Havre</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">PISCINE JEAN-MOULIN — LE HAVRE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Information aux usagers</text><text x="32" y="84" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F">Bassin extérieur fermé pour entretien</text><text x="32" y="106" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C">jusqu''au 12 mai inclus</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#168F5B">Le bassin intérieur reste ouvert.</text><line x1="32" y1="148" x2="288" y2="148" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="170" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Merci de votre compréhension — Wei Zhang, responsable</text></svg>'),

  ('11111111-a008-5000-0000-000000000005', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''information dans le hall de la mairie de Nîmes : ascenseur en panne, merci d''utiliser l''escalier ; les personnes à mobilité réduite peuvent s''adresser à l''accueil ; réparation prévue le vendredi 14 mars.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Panneau d''information du hall de la mairie de Nîmes</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">MAIRIE DE NÎMES — HALL</text><text x="160" y="60" font-family="Arial" font-size="14" font-weight="700" fill="#E1372F" text-anchor="middle">ASCENSEUR EN PANNE</text><text x="32" y="88" font-family="Arial" font-size="11" fill="#0F1839">Merci d''utiliser l''escalier.</text><text x="32" y="110" font-family="Arial" font-size="11" fill="#0F1839">Personnes à mobilité réduite :</text><text x="32" y="128" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">adressez-vous à l''accueil.</text><line x1="32" y1="144" x2="288" y2="144" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="168" font-family="Arial" font-size="12" font-weight="700" fill="#168F5B">Réparation prévue : vendredi 14 mars</text></svg>'),

  ('11111111-a008-5000-0000-000000000006', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''information du marché couvert des Halles à Perpignan : les objets trouvés sont à retirer au bureau du gardien, allée C, près de l''entrée nord ; contact M. Diego Torres, pendant les jours de marché.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Panneau objets trouvés du marché couvert des Halles de Perpignan</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">MARCHÉ COUVERT DES HALLES</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Perpignan — Objets trouvés</text><text x="32" y="86" font-family="Arial" font-size="11" fill="#0F1839">Objets perdus à retirer au :</text><text x="32" y="110" font-family="Arial" font-size="13" font-weight="700" fill="#168F5B">Bureau du gardien — allée C</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">(près de l''entrée nord)</text><line x1="32" y1="148" x2="288" y2="148" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="172" font-family="Arial" font-size="10" fill="#1E3A8C" text-anchor="middle">Contact : M. Diego Torres — pendant les jours de marché</text></svg>'),

  ('11111111-a008-5000-0000-000000000007', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''information du jardin botanique d''Angers : la fontaine de l''entrée est hors service à cause de travaux sur les canalisations ; un point d''eau potable est disponible près du kiosque, allée des Roses.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Panneau d''information du jardin botanique d''Angers</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">JARDIN BOTANIQUE — ANGERS</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Information aux visiteurs</text><text x="32" y="84" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F">Fontaine de l''entrée hors service</text><text x="32" y="104" font-family="Arial" font-size="10" fill="#0F1839">(travaux sur les canalisations)</text><text x="32" y="130" font-family="Arial" font-size="12" font-weight="700" fill="#168F5B">Eau potable : près du kiosque</text><text x="32" y="150" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">allée des Roses</text><line x1="32" y1="164" x2="288" y2="164" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="182" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Merci de votre compréhension — Ville d''Angers</text></svg>'),

  ('11111111-a008-5000-0000-000000000008', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''information à l''accueil de la mairie de Metz : distribution gratuite de sacs de tri jaunes jusqu''au 30 juin, 2 rouleaux maximum par foyer, sur présentation d''un justificatif de domicile.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Panneau de distribution de sacs de tri de la mairie de Metz</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#168F5B" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#168F5B"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">DISTRIBUTION GRATUITE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Mairie de Metz — Sacs de tri jaunes</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">À l''accueil, jusqu''au 30 juin</text><text x="32" y="110" font-family="Arial" font-size="13" font-weight="700" fill="#1E3A8C">2 rouleaux maximum par foyer</text><line x1="32" y1="128" x2="288" y2="128" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="152" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317">Sur présentation d''un justificatif</text><text x="32" y="170" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317">de domicile</text></svg>'),

  ('11111111-a008-5000-0000-000000000009', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''information du parking des Alpes à Grenoble : à partir du 1er février, les horodateurs n''acceptent plus les pièces ; paiement par carte bancaire ou application MobiPark uniquement.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Panneau d''information du parking des Alpes de Grenoble</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">PARKING DES ALPES — GRENOBLE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Information stationnement</text><text x="32" y="84" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F">Les horodateurs n''acceptent plus</text><text x="32" y="102" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F">les pièces</text><text x="32" y="122" font-family="Arial" font-size="11" fill="#0F1839">à partir du 1er février</text><line x1="32" y1="138" x2="288" y2="138" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="160" font-family="Arial" font-size="12" font-weight="700" fill="#168F5B">Paiement : carte bancaire</text><text x="32" y="180" font-family="Arial" font-size="12" font-weight="700" fill="#168F5B">ou application MobiPark uniquement</text></svg>'),

  ('11111111-a008-5000-0000-00000000000a', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Panneau d''information de l''hôpital Sud d''Amiens : à partir du lundi 7 avril, l''entrée des visiteurs se fait par l''avenue des Tilleuls ; l''entrée principale, rue Carnot, est réservée aux urgences ; accueil Mme Priya Sharma.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Panneau d''information visiteurs de l''hôpital Sud d''Amiens</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">HÔPITAL SUD — AMIENS</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Information visiteurs</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">À partir du lundi 7 avril :</text><text x="32" y="108" font-family="Arial" font-size="12" font-weight="700" fill="#168F5B">Entrée des visiteurs :</text><text x="32" y="128" font-family="Arial" font-size="12" font-weight="700" fill="#168F5B">avenue des Tilleuls</text><text x="32" y="154" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">Entrée rue Carnot réservée aux urgences</text><line x1="32" y1="166" x2="288" y2="166" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Accueil des visiteurs : Mme Priya Sharma — bâtiment B</text></svg>');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-a008-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a008-5000-0000-000000000001', 'A2', 'CE',
   'Jusqu''à quand l''aire de jeux du parc est-elle fermée ?',
   'Le panneau indique que l''aire de jeux est fermée pour rénovation « **du 3 au 21 mars** » : elle est donc fermée jusqu''au 21 mars. « Le 3 mars » est la date de début des travaux, pas la fin — ce distracteur répondrait à « quand les travaux commencent-ils ? ». « Le 30 mars » n''apparaît nulle part sur le panneau. « La fin de l''année » contredit la période courte annoncée, d''autant que le reste du parc reste ouvert.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a008-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a008-5000-0000-000000000002', 'A2', 'CE',
   'Où se trouve maintenant le service des cartes d''identité ?',
   'Le panneau annonce le transfert du service au « **Bureau 204 — 2e étage** ». « Le bureau 12, au rez-de-chaussée » est l''ancienne adresse, explicitement signalée comme telle — c''est le piège principal. « L''accueil » n''est mentionné que pour situer l''ascenseur (« à droite de l''accueil »), ce n''est pas le nouveau lieu du service. « La mairie centrale » n''apparaît pas sur le panneau : le service reste dans la mairie annexe.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a008-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a008-5000-0000-000000000003', 'A2', 'CE',
   'Combien de temps le code Wi-Fi est-il valable ?',
   'Le panneau précise « Code **valable 4 heures** » : c''est la durée de validité exacte. « 2 heures » est une durée plausible mais absente du panneau. « 4 jours » reprend le bon chiffre mais confond l''unité : il s''agit d''heures, pas de jours. « Toute la journée » contredit la limite de 4 heures clairement indiquée sur le panneau.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a008-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a008-5000-0000-000000000004', 'A2', 'CE',
   'Jusqu''à quand le bassin extérieur de la piscine est-il fermé ?',
   'Le panneau indique « Bassin extérieur fermé pour entretien **jusqu''au 12 mai inclus** ». « Le 2 mai » et « le 12 mars » recombinent les chiffres de la vraie date (12, mai) pour fabriquer des dates proches mais fausses, absentes du panneau. « Jusqu''à demain » n''est écrit nulle part : la fermeture court jusqu''à une date précise. Pendant ce temps, seul le bassin intérieur reste ouvert.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a008-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a008-5000-0000-000000000005', 'A2', 'CE',
   'Quand la réparation de l''ascenseur est-elle prévue ?',
   'Le panneau annonce « Réparation prévue : **vendredi 14 mars** » — c''est la seule date indiquée. « Lundi 10 mars » et « mercredi 12 mars » sont des dates plausibles de la même semaine, mais elles n''apparaissent pas sur le panneau. « Samedi 15 mars » serait le lendemain de la date annoncée : lui non plus n''est écrit nulle part. En attendant, il faut utiliser l''escalier ou, pour les personnes à mobilité réduite, s''adresser à l''accueil.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a008-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a008-5000-0000-000000000006', 'A2', 'CE',
   'Où peut-on récupérer un objet perdu au marché couvert ?',
   'Le panneau indique que les objets perdus sont à retirer au « **Bureau du gardien — allée C** ». « L''entrée nord » sert seulement à situer ce bureau (« près de l''entrée nord »), ce n''est pas le lieu de retrait lui-même : c''est le piège du repère géographique. « La mairie » et « le commissariat » sont des lieux plausibles pour des objets trouvés, mais aucun des deux ne figure sur ce panneau du marché.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a008-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a008-5000-0000-000000000007', 'A2', 'CE',
   'Où peut-on trouver de l''eau potable dans le jardin ?',
   'Le panneau signale un point d''eau potable « **près du kiosque, allée des Roses** ». « La fontaine de l''entrée » est justement l''équipement hors service à cause des travaux — c''est le piège principal. « La cafétéria » n''est mentionnée nulle part sur le panneau. « Nulle part dans le jardin » est faux : le panneau indique précisément un point d''eau de remplacement.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a008-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a008-5000-0000-000000000008', 'A2', 'CE',
   'Combien de rouleaux de sacs de tri peut-on retirer par foyer ?',
   'Le panneau fixe la limite « **2 rouleaux maximum par foyer** ». « 1 rouleau » et « 3 rouleaux » sont des quantités proches mais absentes du panneau. « 30 rouleaux » confond avec le « 30 » de la date limite de la distribution (« jusqu''au 30 juin ») : c''est le piège du chiffre présent ailleurs sur le document, qui répond à « jusqu''à quand a lieu la distribution ? ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a008-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a008-5000-0000-000000000009', 'A2', 'CE',
   'Comment peut-on payer le stationnement au parking des Alpes ?',
   'Le panneau précise « Paiement : **carte bancaire ou application MobiPark uniquement** ». « En pièces de monnaie » est exactement ce qui n''est plus accepté depuis le 1er février — c''est le piège de l''information périmée. « Par chèque » n''apparaît nulle part sur le panneau. « Au bureau du parking » n''est pas proposé : le paiement se fait aux horodateurs, par carte ou via l''application.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a008-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a008-5000-0000-00000000000a', 'A2', 'CE',
   'Par où les visiteurs de l''hôpital doivent-ils entrer à partir du 7 avril ?',
   'Le panneau indique qu''à partir du lundi 7 avril, l''entrée des visiteurs se fait par « **l''avenue des Tilleuls** ». « L''entrée principale, rue Carnot » est désormais réservée aux urgences : c''est le piège principal du panneau. « Le service des urgences » désigne qui utilise la rue Carnot, pas un accès pour les visiteurs. « Le parking » n''est pas mentionné comme entrée sur le panneau.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('11111111-a008-2100-0000-000000000001', '11111111-a008-1000-0000-000000000001', 'Jusqu''au 3 mars', 'false', '1'),
  ('11111111-a008-2200-0000-000000000001', '11111111-a008-1000-0000-000000000001', 'Jusqu''au 21 mars', 'true', '2'),
  ('11111111-a008-2300-0000-000000000001', '11111111-a008-1000-0000-000000000001', 'Jusqu''au 30 mars', 'false', '3'),
  ('11111111-a008-2400-0000-000000000001', '11111111-a008-1000-0000-000000000001', 'Jusqu''à la fin de l''année', 'false', '4'),

  ('11111111-a008-2100-0000-000000000002', '11111111-a008-1000-0000-000000000002', 'Au bureau 12, au rez-de-chaussée', 'false', '1'),
  ('11111111-a008-2200-0000-000000000002', '11111111-a008-1000-0000-000000000002', 'À l''accueil', 'false', '2'),
  ('11111111-a008-2300-0000-000000000002', '11111111-a008-1000-0000-000000000002', 'Au bureau 204, au 2e étage', 'true', '3'),
  ('11111111-a008-2400-0000-000000000002', '11111111-a008-1000-0000-000000000002', 'À la mairie centrale', 'false', '4'),

  ('11111111-a008-2100-0000-000000000003', '11111111-a008-1000-0000-000000000003', '4 heures', 'true', '1'),
  ('11111111-a008-2200-0000-000000000003', '11111111-a008-1000-0000-000000000003', '2 heures', 'false', '2'),
  ('11111111-a008-2300-0000-000000000003', '11111111-a008-1000-0000-000000000003', '4 jours', 'false', '3'),
  ('11111111-a008-2400-0000-000000000003', '11111111-a008-1000-0000-000000000003', 'Toute la journée', 'false', '4'),

  ('11111111-a008-2100-0000-000000000004', '11111111-a008-1000-0000-000000000004', 'Jusqu''au 2 mai', 'false', '1'),
  ('11111111-a008-2200-0000-000000000004', '11111111-a008-1000-0000-000000000004', 'Jusqu''au 12 mars', 'false', '2'),
  ('11111111-a008-2300-0000-000000000004', '11111111-a008-1000-0000-000000000004', 'Jusqu''à demain', 'false', '3'),
  ('11111111-a008-2400-0000-000000000004', '11111111-a008-1000-0000-000000000004', 'Jusqu''au 12 mai', 'true', '4'),

  ('11111111-a008-2100-0000-000000000005', '11111111-a008-1000-0000-000000000005', 'Le lundi 10 mars', 'false', '1'),
  ('11111111-a008-2200-0000-000000000005', '11111111-a008-1000-0000-000000000005', 'Le mercredi 12 mars', 'false', '2'),
  ('11111111-a008-2300-0000-000000000005', '11111111-a008-1000-0000-000000000005', 'Le vendredi 14 mars', 'true', '3'),
  ('11111111-a008-2400-0000-000000000005', '11111111-a008-1000-0000-000000000005', 'Le samedi 15 mars', 'false', '4'),

  ('11111111-a008-2100-0000-000000000006', '11111111-a008-1000-0000-000000000006', 'À l''entrée nord', 'false', '1'),
  ('11111111-a008-2200-0000-000000000006', '11111111-a008-1000-0000-000000000006', 'Au bureau du gardien, allée C', 'true', '2'),
  ('11111111-a008-2300-0000-000000000006', '11111111-a008-1000-0000-000000000006', 'À la mairie', 'false', '3'),
  ('11111111-a008-2400-0000-000000000006', '11111111-a008-1000-0000-000000000006', 'Au commissariat', 'false', '4'),

  ('11111111-a008-2100-0000-000000000007', '11111111-a008-1000-0000-000000000007', 'À la fontaine de l''entrée', 'false', '1'),
  ('11111111-a008-2200-0000-000000000007', '11111111-a008-1000-0000-000000000007', 'À la cafétéria', 'false', '2'),
  ('11111111-a008-2300-0000-000000000007', '11111111-a008-1000-0000-000000000007', 'Nulle part dans le jardin', 'false', '3'),
  ('11111111-a008-2400-0000-000000000007', '11111111-a008-1000-0000-000000000007', 'Près du kiosque, allée des Roses', 'true', '4'),

  ('11111111-a008-2100-0000-000000000008', '11111111-a008-1000-0000-000000000008', '2 rouleaux', 'true', '1'),
  ('11111111-a008-2200-0000-000000000008', '11111111-a008-1000-0000-000000000008', '1 rouleau', 'false', '2'),
  ('11111111-a008-2300-0000-000000000008', '11111111-a008-1000-0000-000000000008', '3 rouleaux', 'false', '3'),
  ('11111111-a008-2400-0000-000000000008', '11111111-a008-1000-0000-000000000008', '30 rouleaux', 'false', '4'),

  ('11111111-a008-2100-0000-000000000009', '11111111-a008-1000-0000-000000000009', 'En pièces de monnaie', 'false', '1'),
  ('11111111-a008-2200-0000-000000000009', '11111111-a008-1000-0000-000000000009', 'Par carte bancaire ou avec l''application', 'true', '2'),
  ('11111111-a008-2300-0000-000000000009', '11111111-a008-1000-0000-000000000009', 'Par chèque', 'false', '3'),
  ('11111111-a008-2400-0000-000000000009', '11111111-a008-1000-0000-000000000009', 'Au bureau du parking', 'false', '4'),

  ('11111111-a008-2100-0000-00000000000a', '11111111-a008-1000-0000-00000000000a', 'Par l''entrée principale, rue Carnot', 'false', '1'),
  ('11111111-a008-2200-0000-00000000000a', '11111111-a008-1000-0000-00000000000a', 'Par le service des urgences', 'false', '2'),
  ('11111111-a008-2300-0000-00000000000a', '11111111-a008-1000-0000-00000000000a', 'Par l''avenue des Tilleuls', 'true', '3'),
  ('11111111-a008-2400-0000-00000000000a', '11111111-a008-1000-0000-00000000000a', 'Par le parking', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 10 items (NN=01..0a), UUID déterministes uniques (questions a008-1000-,
--     medias a008-5000-, choices a008-2100/2200/2300/2400-).
-- [x] Tous les supports = panneaux d'information de lieux publics, 10 lieux et
--     objets différents (parc/travaux aire de jeux, mairie annexe/transfert de
--     service, bibliothèque/Wi-Fi, piscine/bassin fermé, mairie/ascenseur en
--     panne, marché couvert/objets trouvés, jardin botanique/point d'eau,
--     mairie/distribution sacs de tri, parking/moyens de paiement,
--     hôpital/changement d'entrée). Aucun support interdit (pas de panneau
--     d'horaires, annonce, étiquette, SMS, affichette d'événement, règlement,
--     menu, carte postale, mémo, programme, transport, vente, météo,
--     invitation ni plan).
-- [x] 4 choix par question, exactement 1 correct ; distribution des bonnes
--     réponses : pos1=2 (items 3,8), pos2=3 (items 1,6,9), pos3=3 (items
--     2,5,10), pos4=2 (items 4,7) — max 3 par position, 4 positions utilisées.
-- [x] Questions sur UNE information explicite (date de fin, lieu, durée,
--     quantité, moyen de paiement, accès) ; labels des choices = texte de la
--     réponse ; distracteurs = autres valeurs présentes ou plausibles du
--     panneau.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chacun des
--     3 distracteurs, point clé en **gras**.
-- [x] SVG : viewBox="0 0 320 200", Arial, palette charte, rouge réservé aux
--     infos critiques (fermée, en panne, hors service, n'acceptent plus,
--     réservée aux urgences) ; balises équilibrées ; alt_text descriptif
--     complet sur chaque media. Texte utile ~10-40 mots par panneau.
-- [x] Apostrophes SQL doublées ('') partout (SVG, alt_text, statements,
--     explanations, labels). Pas de JSONB (choices en lignes). Contenu 100%
--     original, prénoms/villes variés (Olena Kovalenko, Wei Zhang, Diego
--     Torres, Priya Sharma — Toulouse, Saint-Étienne, Clermont-Ferrand,
--     Le Havre, Nîmes, Perpignan, Angers, Metz, Grenoble, Amiens), aucun
--     chiffre recopié d'un sujet existant.
-- [x] competence_code : 5× ce_reperage_explicite (items 2,6,7,9,10),
--     5× ce_detail_specifique (items 1,3,4,5,8).
-- ============================================================================
