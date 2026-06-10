-- ============================================================================
-- V412 — TCF CE A2 — lot 12 (support : horaires de transport)
-- ----------------------------------------------------------------------------
-- 10 items CE A2, theme 22222222-0000-0000-0000-000000000002.
-- Chaque item = un document d'horaires de transport original (SVG style
-- « document ») + 1 question sur UNE information explicite + 4 choix (1 correct).
-- UUID déterministes : questions 11111111-a00c-1000-…, medias 11111111-a00c-5000-…,
-- choices 11111111-a00c-2100/2200/2300/2400-… (display_order 1..4).
-- ============================================================================


-- medias (IMAGE) — documents d'horaires de transport référencés par les questions
INSERT INTO medias
  (id, type, url, storage_key, original_filename, content_type, size_bytes, duration_sec,
   alt_text, created_at, transcript, inline_svg)
VALUES
  ('11111111-a00c-5000-0000-000000000001', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Fiche horaire du bus ligne 14 à l''arrêt Place des Carmes à Clermont-Ferrand : premier bus à 6h15, un passage toutes les 12 minutes en journée, dernier bus à 21h40 ; la ligne ne circule pas le 1er mai.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Horaires du bus ligne 14, arrêt Place des Carmes</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">BUS — LIGNE 14</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Arrêt Place des Carmes — Clermont-Ferrand</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Premier bus</text><text x="288" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">6h15</text><text x="32" y="108" font-family="Arial" font-size="11" fill="#0F1839">En journée</text><text x="288" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">un bus toutes les 12 minutes</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Dernier bus</text><text x="288" y="132" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">21h40</text><line x1="32" y1="148" x2="288" y2="148" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="170" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F" text-anchor="middle">Ne circule pas le 1er mai</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Direction : centre commercial des Pistes</text></svg>'),

  ('11111111-a00c-5000-0000-000000000002', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Écran des départs de la gare de Poitiers : 9h47 TER La Rochelle voie 3, 9h58 TGV Paris-Montparnasse voie 1, 10h12 TER Limoges voie 5 ; le TER de 10h31 pour Niort est supprimé.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Écran des départs de la gare de Poitiers</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#0F1839" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">GARE DE POITIERS — DÉPARTS</text><text x="32" y="66" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317">9h47</text><text x="78" y="66" font-family="Arial" font-size="11" fill="#FFFFFF">TER La Rochelle</text><text x="288" y="66" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">Voie 3</text><text x="32" y="94" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317">9h58</text><text x="78" y="94" font-family="Arial" font-size="11" fill="#FFFFFF">TGV Paris-Montparnasse</text><text x="288" y="94" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">Voie 1</text><text x="32" y="122" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317">10h12</text><text x="78" y="122" font-family="Arial" font-size="11" fill="#FFFFFF">TER Limoges</text><text x="288" y="122" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">Voie 5</text><text x="32" y="150" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317">10h31</text><text x="78" y="150" font-family="Arial" font-size="11" fill="#FFFFFF">TER Niort</text><text x="288" y="150" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F" text-anchor="end">Supprimé</text><line x1="32" y1="164" x2="288" y2="164" stroke="#15296B" stroke-width="2"/><text x="160" y="182" font-family="Arial" font-size="9" fill="#E8ECF8" text-anchor="middle">Merci de vérifier la voie avant l''embarquement</text></svg>'),

  ('11111111-a00c-5000-0000-000000000003', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affiche des fréquences du tramway ligne B à Grenoble : du lundi au vendredi toutes les 8 minutes de 5h à 0h30, le samedi toutes les 10 minutes, le dimanche et les jours fériés toutes les 15 minutes.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Fréquences du tramway ligne B à Grenoble</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">TRAMWAY — LIGNE B</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Grenoble — Fréquences de passage</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Lundi - Vendredi (5h - 0h30)</text><text x="288" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">toutes les 8 minutes</text><text x="32" y="108" font-family="Arial" font-size="11" fill="#0F1839">Samedi</text><text x="288" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">toutes les 10 minutes</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Dimanche et jours fériés</text><text x="288" y="132" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">toutes les 15 minutes</text><line x1="32" y1="148" x2="288" y2="148" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="172" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Réseau des transports de l''agglomération — ligne B : Presqu''île - Campus</text></svg>'),

  ('11111111-a00c-5000-0000-000000000004', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affiche de la navette aéroport de Nice : départ toutes les 20 minutes entre l''aéroport et la gare du centre-ville, de 4h30 à 23h, durée du trajet 35 minutes, ticket à 5 euros vendu à bord.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Horaires de la navette aéroport de Nice</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">NAVETTE AÉROPORT</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Nice — Aéroport / Gare du centre-ville</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Départs</text><text x="288" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">toutes les 20 minutes</text><text x="32" y="108" font-family="Arial" font-size="11" fill="#0F1839">Service</text><text x="288" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">de 4h30 à 23h</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Durée du trajet</text><text x="288" y="132" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">35 minutes</text><line x1="32" y1="148" x2="288" y2="148" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="170" font-family="Arial" font-size="11" font-weight="700" fill="#E8A317" text-anchor="middle">Ticket : 5 € — vente à bord</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Arrêts : Aéroport T1, Promenade, Gare centre-ville</text></svg>'),

  ('11111111-a00c-5000-0000-000000000005', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Tableau des horaires du bateau entre Lorient et l''île de Groix : départs de Lorient à 7h45, 11h30, 16h05 et 18h50, traversée de 45 minutes ; embarquement obligatoire 15 minutes avant le départ.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Horaires du bateau pour l''île de Groix</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">BATEAU — ÎLE DE GROIX</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Départs du port de Lorient</text><text x="160" y="88" font-family="Arial" font-size="13" font-weight="700" fill="#168F5B" text-anchor="middle">7h45 — 11h30 — 16h05 — 18h50</text><text x="32" y="120" font-family="Arial" font-size="11" fill="#0F1839">Traversée</text><text x="288" y="120" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">45 minutes</text><line x1="32" y1="138" x2="288" y2="138" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="162" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F" text-anchor="middle">Embarquement 15 minutes avant le départ</text><text x="160" y="182" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Compagnie des Courants — billets au guichet du port</text></svg>'),

  ('11111111-a00c-5000-0000-000000000006', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Fiche horaire du car régional ligne 302 entre Auch et Toulouse : départ d''Auch gare routière à 6h50, arrivée à Toulouse Matabiau à 8h05, retour au départ de Toulouse à 17h35 ; ne circule ni le dimanche ni les jours fériés.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Horaires du car régional ligne 302 Auch - Toulouse</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">CAR RÉGIONAL — LIGNE 302</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Auch - Toulouse</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Départ Auch (gare routière)</text><text x="288" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">6h50</text><text x="32" y="108" font-family="Arial" font-size="11" fill="#0F1839">Arrivée Toulouse (Matabiau)</text><text x="288" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">8h05</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Retour : départ de Toulouse</text><text x="288" y="132" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">17h35</text><line x1="32" y1="148" x2="288" y2="148" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="170" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F" text-anchor="middle">Ne circule ni le dimanche ni les jours fériés</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Tarif unique : 2 € — paiement auprès du conducteur</text></svg>'),

  ('11111111-a00c-5000-0000-000000000007', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affiche des horaires du métro ligne A à Rennes : premier départ à 5h15 tous les jours ; du dimanche au jeudi, dernier départ à minuit ; le vendredi et le samedi, dernier départ à 1h du matin.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Premiers et derniers départs du métro ligne A à Rennes</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">MÉTRO — LIGNE A</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Rennes — Premiers et derniers départs</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Premier départ (tous les jours)</text><text x="288" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">5h15</text><text x="32" y="108" font-family="Arial" font-size="11" fill="#0F1839">Dernier départ (dimanche - jeudi)</text><text x="288" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">minuit</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Dernier départ (vendredi et samedi)</text><text x="288" y="132" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">1h du matin</text><line x1="32" y1="148" x2="288" y2="148" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="172" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Une rame toutes les 3 minutes aux heures de pointe</text></svg>'),

  ('11111111-a00c-5000-0000-000000000008', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affiche de la navette fluviale sur la Saône à Lyon, entre Bellecour et Confluence : départs toutes les 30 minutes, de 10h à 19h, tous les jours de l''année ; service interrompu en cas de crue de la Saône.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Horaires de la navette fluviale Bellecour - Confluence</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">NAVETTE FLUVIALE — SAÔNE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Lyon : Bellecour - Confluence</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Départs</text><text x="288" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">toutes les 30 minutes</text><text x="32" y="108" font-family="Arial" font-size="11" fill="#0F1839">Horaires</text><text x="288" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">10h - 19h</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Service</text><text x="288" y="132" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">tous les jours de l''année</text><line x1="32" y1="148" x2="288" y2="148" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="170" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F" text-anchor="middle">Service interrompu en cas de crue de la Saône</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Ticket : 2 € — gratuit pour les moins de 6 ans</text></svg>'),

  ('11111111-a00c-5000-0000-000000000009', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affiche des horaires du téléphérique de Brest : ouvert tous les jours de 7h30 à 0h30, traversée de 3 minutes, accès avec un ticket de bus ; fermé pour entretien le premier lundi du mois, de 9h à 12h.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Horaires du téléphérique de Brest</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">TÉLÉPHÉRIQUE DE BREST</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Liaison entre les deux rives</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Tous les jours</text><text x="288" y="84" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B" text-anchor="end">7h30 - 0h30</text><text x="32" y="108" font-family="Arial" font-size="11" fill="#0F1839">Traversée</text><text x="288" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">3 minutes</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Accès</text><text x="288" y="132" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">avec un ticket de bus</text><line x1="32" y1="148" x2="288" y2="148" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="170" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F" text-anchor="middle">Entretien : fermé le 1er lundi du mois, 9h - 12h</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Cabines accessibles aux fauteuils roulants et aux vélos</text></svg>'),

  ('11111111-a00c-5000-0000-00000000000a', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affiche de la ligne de bus de nuit N7 à Montpellier, entre la gare Saint-Roch et le quartier des Hôpitaux : circule uniquement les nuits de vendredi et de samedi, de 0h30 à 5h, un départ toutes les heures.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Horaires de la ligne de bus de nuit N7 à Montpellier</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">LIGNE DE NUIT N7</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Montpellier : Gare Saint-Roch - Hôpitaux</text><text x="160" y="86" font-family="Arial" font-size="12" font-weight="700" fill="#168F5B" text-anchor="middle">Circule uniquement les nuits</text><text x="160" y="102" font-family="Arial" font-size="12" font-weight="700" fill="#168F5B" text-anchor="middle">de vendredi et de samedi</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Horaires</text><text x="288" y="132" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">0h30 - 5h</text><text x="32" y="156" font-family="Arial" font-size="11" fill="#0F1839">Fréquence</text><text x="288" y="156" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="end">un départ toutes les heures</text><line x1="32" y1="168" x2="288" y2="168" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Ticket habituel du réseau valable à bord</text></svg>');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-a00c-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00c-5000-0000-000000000001', 'A2', 'CE',
   'À quelle heure passe le dernier bus de la ligne 14 ?',
   'La fiche horaire indique « **Dernier bus : 21h40** ». « 6h15 » est l''heure du premier bus — ce distracteur répondrait à la question « à quelle heure passe le premier bus ? ». « 20h40 » et « 22h30 » sont des horaires plausibles mais absents du document : aucun passage n''est annoncé à ces heures-là.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00c-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00c-5000-0000-000000000002', 'A2', 'CE',
   'De quelle voie part le train pour La Rochelle ?',
   'L''écran des départs affiche « 9h47 — TER La Rochelle — **Voie 3** ». La voie 1 est celle du TGV pour Paris-Montparnasse et la voie 5 celle du TER pour Limoges : ces deux distracteurs confondent les lignes de l''écran. La voie 7 n''apparaît nulle part — elle est plausible dans une gare, mais inventée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00c-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00c-5000-0000-000000000003', 'A2', 'CE',
   'Le dimanche, à quelle fréquence le tram de la ligne B passe-t-il ?',
   'L''affiche précise « **Dimanche et jours fériés : toutes les 15 minutes** ». « Toutes les 8 minutes » correspond à la fréquence du lundi au vendredi et « toutes les 10 minutes » à celle du samedi : ces distracteurs répondraient à la question pour un autre jour. « Toutes les 20 minutes » n''est mentionné nulle part sur l''affiche.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00c-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00c-5000-0000-000000000004', 'A2', 'CE',
   'Combien de temps dure le trajet de la navette entre l''aéroport et la gare ?',
   'L''affiche indique « **Durée du trajet : 35 minutes** ». « 20 minutes » est la fréquence des départs (un départ toutes les 20 minutes), pas la durée du voyage — c''est le piège principal et il répondrait à « tous les combien la navette part-elle ? ». « 25 minutes » et « 45 minutes » sont des durées plausibles mais qui ne figurent pas sur l''affiche.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00c-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00c-5000-0000-000000000005', 'A2', 'CE',
   'À quelle heure part le dernier bateau pour l''île de Groix ?',
   'Parmi les quatre départs affichés (7h45, 11h30, 16h05, 18h50), le dernier de la journée est « **18h50** ». « 7h45 » est le premier départ — il répondrait à la question inverse. « 11h30 » et « 16h05 » sont des départs intermédiaires : ces trois distracteurs sont bien des horaires du document, mais aucun n''est le dernier bateau.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00c-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00c-5000-0000-000000000006', 'A2', 'CE',
   'À quelle heure le car de la ligne 302 arrive-t-il à Toulouse ?',
   'La fiche indique « **Arrivée Toulouse (Matabiau) : 8h05** ». « 6h50 » est l''heure de départ d''Auch — ce distracteur répondrait à « à quelle heure le car part-il ? ». « 17h35 » est l''heure du départ du trajet retour depuis Toulouse, pas une arrivée. « 7h45 » est un horaire plausible mais qui ne figure pas sur la fiche.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00c-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00c-5000-0000-000000000007', 'A2', 'CE',
   'Le samedi, à quelle heure part le dernier métro ?',
   'L''affiche précise « **Dernier départ (vendredi et samedi) : 1h du matin** ». « Minuit » est l''heure du dernier métro du dimanche au jeudi — c''est le piège principal, qui confond les deux lignes du tableau. « 5h15 » est l''heure du premier départ, pas du dernier. « 23h30 » n''apparaît nulle part sur l''affiche.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00c-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00c-5000-0000-000000000008', 'A2', 'CE',
   'Quand le service de la navette fluviale est-il interrompu ?',
   'La mention rouge indique « **Service interrompu en cas de crue de la Saône** ». La navette circule « tous les jours de l''année » : « le dimanche » est donc faux. « Quand il pleut » et « quand il fait froid » sont des situations plausibles pour un bateau, mais elles ne sont mentionnées nulle part — seule la crue interrompt le service.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00c-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00c-5000-0000-000000000009', 'A2', 'CE',
   'Quand le téléphérique est-il fermé pour entretien ?',
   'La ligne rouge précise « **Entretien : fermé le 1er lundi du mois, 9h - 12h** », donc le matin. « Tous les lundis matin » sur-généralise : seul le premier lundi du mois est concerné. « Le dimanche de 9h à 12h » se trompe de jour. « Chaque soir après 0h30 » correspond à la fermeture quotidienne normale du service, pas à l''entretien.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00c-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00c-5000-0000-00000000000a', 'A2', 'CE',
   'Quelles nuits le bus N7 circule-t-il ?',
   'L''affiche indique « **Circule uniquement les nuits de vendredi et de samedi** ». « Toutes les nuits » contredit le mot « uniquement ». « Les nuits de dimanche » est précisément un moment où la ligne ne circule pas. « Seulement en été » est plausible pour une ligne de nuit, mais aucune mention de saison ne figure sur l''affiche.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('11111111-a00c-2100-0000-000000000001', '11111111-a00c-1000-0000-000000000001', '6h15', 'false', '1'),
  ('11111111-a00c-2200-0000-000000000001', '11111111-a00c-1000-0000-000000000001', '21h40', 'true', '2'),
  ('11111111-a00c-2300-0000-000000000001', '11111111-a00c-1000-0000-000000000001', '20h40', 'false', '3'),
  ('11111111-a00c-2400-0000-000000000001', '11111111-a00c-1000-0000-000000000001', '22h30', 'false', '4'),

  ('11111111-a00c-2100-0000-000000000002', '11111111-a00c-1000-0000-000000000002', 'Voie 3', 'true', '1'),
  ('11111111-a00c-2200-0000-000000000002', '11111111-a00c-1000-0000-000000000002', 'Voie 1', 'false', '2'),
  ('11111111-a00c-2300-0000-000000000002', '11111111-a00c-1000-0000-000000000002', 'Voie 5', 'false', '3'),
  ('11111111-a00c-2400-0000-000000000002', '11111111-a00c-1000-0000-000000000002', 'Voie 7', 'false', '4'),

  ('11111111-a00c-2100-0000-000000000003', '11111111-a00c-1000-0000-000000000003', 'Toutes les 8 minutes', 'false', '1'),
  ('11111111-a00c-2200-0000-000000000003', '11111111-a00c-1000-0000-000000000003', 'Toutes les 10 minutes', 'false', '2'),
  ('11111111-a00c-2300-0000-000000000003', '11111111-a00c-1000-0000-000000000003', 'Toutes les 15 minutes', 'true', '3'),
  ('11111111-a00c-2400-0000-000000000003', '11111111-a00c-1000-0000-000000000003', 'Toutes les 20 minutes', 'false', '4'),

  ('11111111-a00c-2100-0000-000000000004', '11111111-a00c-1000-0000-000000000004', '20 minutes', 'false', '1'),
  ('11111111-a00c-2200-0000-000000000004', '11111111-a00c-1000-0000-000000000004', '35 minutes', 'true', '2'),
  ('11111111-a00c-2300-0000-000000000004', '11111111-a00c-1000-0000-000000000004', '45 minutes', 'false', '3'),
  ('11111111-a00c-2400-0000-000000000004', '11111111-a00c-1000-0000-000000000004', '25 minutes', 'false', '4'),

  ('11111111-a00c-2100-0000-000000000005', '11111111-a00c-1000-0000-000000000005', '7h45', 'false', '1'),
  ('11111111-a00c-2200-0000-000000000005', '11111111-a00c-1000-0000-000000000005', '11h30', 'false', '2'),
  ('11111111-a00c-2300-0000-000000000005', '11111111-a00c-1000-0000-000000000005', '16h05', 'false', '3'),
  ('11111111-a00c-2400-0000-000000000005', '11111111-a00c-1000-0000-000000000005', '18h50', 'true', '4'),

  ('11111111-a00c-2100-0000-000000000006', '11111111-a00c-1000-0000-000000000006', '8h05', 'true', '1'),
  ('11111111-a00c-2200-0000-000000000006', '11111111-a00c-1000-0000-000000000006', '6h50', 'false', '2'),
  ('11111111-a00c-2300-0000-000000000006', '11111111-a00c-1000-0000-000000000006', '17h35', 'false', '3'),
  ('11111111-a00c-2400-0000-000000000006', '11111111-a00c-1000-0000-000000000006', '7h45', 'false', '4'),

  ('11111111-a00c-2100-0000-000000000007', '11111111-a00c-1000-0000-000000000007', 'À minuit', 'false', '1'),
  ('11111111-a00c-2200-0000-000000000007', '11111111-a00c-1000-0000-000000000007', 'À 5h15', 'false', '2'),
  ('11111111-a00c-2300-0000-000000000007', '11111111-a00c-1000-0000-000000000007', 'À 1h du matin', 'true', '3'),
  ('11111111-a00c-2400-0000-000000000007', '11111111-a00c-1000-0000-000000000007', 'À 23h30', 'false', '4'),

  ('11111111-a00c-2100-0000-000000000008', '11111111-a00c-1000-0000-000000000008', 'Quand il pleut', 'false', '1'),
  ('11111111-a00c-2200-0000-000000000008', '11111111-a00c-1000-0000-000000000008', 'Le dimanche', 'false', '2'),
  ('11111111-a00c-2300-0000-000000000008', '11111111-a00c-1000-0000-000000000008', 'Quand il fait froid', 'false', '3'),
  ('11111111-a00c-2400-0000-000000000008', '11111111-a00c-1000-0000-000000000008', 'En cas de crue de la Saône', 'true', '4'),

  ('11111111-a00c-2100-0000-000000000009', '11111111-a00c-1000-0000-000000000009', 'Tous les lundis matin', 'false', '1'),
  ('11111111-a00c-2200-0000-000000000009', '11111111-a00c-1000-0000-000000000009', 'Le premier lundi du mois, le matin', 'true', '2'),
  ('11111111-a00c-2300-0000-000000000009', '11111111-a00c-1000-0000-000000000009', 'Le dimanche de 9h à 12h', 'false', '3'),
  ('11111111-a00c-2400-0000-000000000009', '11111111-a00c-1000-0000-000000000009', 'Chaque soir après 0h30', 'false', '4'),

  ('11111111-a00c-2100-0000-00000000000a', '11111111-a00c-1000-0000-00000000000a', 'Toutes les nuits', 'false', '1'),
  ('11111111-a00c-2200-0000-00000000000a', '11111111-a00c-1000-0000-00000000000a', 'Les nuits de dimanche', 'false', '2'),
  ('11111111-a00c-2300-0000-00000000000a', '11111111-a00c-1000-0000-00000000000a', 'Les nuits de vendredi et de samedi', 'true', '3'),
  ('11111111-a00c-2400-0000-00000000000a', '11111111-a00c-1000-0000-00000000000a', 'Seulement en été', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 10 items (NN=01..0a), UUID déterministes uniques (questions a00c-1000-,
--     medias a00c-5000-, choices a00c-2100/2200/2300/2400-).
-- [x] Tous les supports = horaires de transport, 10 modes/lieux différents
--     (bus urbain Clermont-Ferrand, écran des départs gare de Poitiers, tram
--     Grenoble, navette aéroport Nice, bateau Lorient-Groix, car régional
--     Auch-Toulouse, métro Rennes, navette fluviale Lyon, téléphérique Brest,
--     bus de nuit Montpellier). Aucun support interdit (pas de panneau
--     d'horaires d'établissement, pas d'alerte météo, pas de plan, etc.).
-- [x] 4 choix par question, exactement 1 correct ; distribution des bonnes
--     réponses : pos1=2 (items 2,6), pos2=3 (items 1,4,9), pos3=3 (items
--     3,7,10), pos4=2 (items 5,8) — max 3 par position, 4 positions utilisées.
-- [x] Questions sur UNE information explicite (horaire, voie, fréquence,
--     durée, condition d'interruption, jours de circulation) ; labels des
--     choices = texte de la réponse ; distracteurs = autres valeurs présentes
--     ou plausibles du document.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chacun des
--     3 distracteurs, point clé en **gras**.
-- [x] SVG : viewBox="0 0 320 200", Arial, palette charte, rouge réservé aux
--     infos critiques (ne circule pas le 1er mai, train supprimé, embarquement
--     obligatoire, pas de circulation dimanche/fériés, crue, entretien) ;
--     balises équilibrées ; alt_text descriptif complet sur chaque media.
--     Texte utile ~10-40 mots par document.
-- [x] Apostrophes SQL doublées ('') partout (SVG, alt_text, statements,
--     explanations, labels). Pas de JSONB (choices en lignes). Contenu 100%
--     original, lieux et chiffres variés (Clermont-Ferrand, Poitiers,
--     Grenoble, Nice, Lorient, Auch, Toulouse, Rennes, Lyon, Brest,
--     Montpellier), aucun chiffre recopié d'un sujet existant.
-- [x] competence_code : 5× ce_reperage_explicite (items 1,4,6,8,10),
--     5× ce_detail_specifique (items 2,3,5,7,9).
-- ============================================================================
