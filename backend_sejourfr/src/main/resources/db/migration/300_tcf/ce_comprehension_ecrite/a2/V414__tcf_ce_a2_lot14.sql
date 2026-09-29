-- ============================================================================
-- V414 — TCF CE A2 — lot 14 (support : alerte météo)
-- ----------------------------------------------------------------------------
-- 10 items CE A2, theme 22222222-0000-0000-0000-000000000002.
-- Chaque item = une alerte météo originale (SVG style « document »)
-- + 1 question sur UNE information explicite + 4 choix (1 correct).
-- UUID déterministes : questions 11111111-a00e-1000-…, medias 11111111-a00e-5000-…,
-- choices 11111111-a00e-2100/2200/2300/2400-… (display_order 1..4).
-- ============================================================================


-- medias (IMAGE) — alertes météo référencées par les questions ci-dessous
INSERT INTO medias
  (id, type, url, storage_key, original_filename, content_type, size_bytes, duration_sec,
   alt_text, created_at, transcript, inline_svg)
VALUES
  ('11111111-a00e-5000-0000-000000000001', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Avis de vigilance orange pour vent violent émis par la préfecture de la Manche à Cherbourg : mercredi de 14h à 22h, rafales jusqu''à 110 km/h ; parcs et jardins municipaux fermés ; sorties en mer déconseillées.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Avis de vigilance orange vent violent de la préfecture de la Manche</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#E8A317" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#E8A317"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">VIGILANCE ORANGE — VENT</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Préfecture de la Manche — Cherbourg</text><text x="32" y="84" font-family="Arial" font-size="11" fill="#0F1839">Mercredi, de 14h à 22h</text><text x="32" y="108" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C">Rafales jusqu''à 110 km/h</text><text x="32" y="134" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">Parcs et jardins municipaux FERMÉS</text><line x1="32" y1="150" x2="288" y2="150" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="172" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Sorties en mer déconseillées toute la journée</text></svg>'),

  ('11111111-a00e-5000-0000-000000000002', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affiche d''alerte canicule de la ville de Montauban : jeudi et vendredi, températures jusqu''à 39 °C ; salle rafraîchie ouverte à la salle des fêtes de 10h à 19h ; consigne de boire de l''eau régulièrement ; numéro vert 0 805 11 22 33. Signée par la maire, Lucia Fernandes.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Affiche d''alerte canicule de la ville de Montauban</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">ALERTE CANICULE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Ville de Montauban</text><text x="32" y="82" font-family="Arial" font-size="11" fill="#0F1839">Jeudi et vendredi : jusqu''à</text><text x="200" y="82" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F">39 °C</text><text x="32" y="106" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Salle rafraîchie : salle des fêtes, 10h - 19h</text><text x="32" y="128" font-family="Arial" font-size="11" fill="#0F1839">Buvez de l''eau régulièrement</text><text x="32" y="150" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Numéro vert : 0 805 11 22 33</text><line x1="32" y1="162" x2="288" y2="162" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">La maire, Lucia Fernandes</text></svg>'),

  ('11111111-a00e-5000-0000-000000000003', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Avis d''alerte neige et verglas de la préfecture du Cantal à Aurillac, pour la nuit de samedi à dimanche : consigne d''éviter de circuler en voiture ; bus scolaires supprimés dimanche matin ; équipements spéciaux obligatoires au-dessus de 800 m.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Avis d''alerte neige et verglas de la préfecture du Cantal</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">ALERTE NEIGE ET VERGLAS</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Préfecture du Cantal — Aurillac</text><text x="32" y="82" font-family="Arial" font-size="11" fill="#0F1839">Nuit de samedi à dimanche</text><text x="32" y="106" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C">Évitez de circuler en voiture</text><text x="32" y="130" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">Bus scolaires SUPPRIMÉS dimanche matin</text><line x1="32" y1="146" x2="288" y2="146" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="168" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Équipements spéciaux obligatoires</text><text x="160" y="184" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">sur les routes au-dessus de 800 m</text></svg>'),

  ('11111111-a00e-5000-0000-000000000004', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Avis de vigilance orages de la mairie de Biscarrosse : lundi, orages violents attendus de 18h à 23h ; plage fermée dès 16h, réouverture mardi à 10h ; en cas de grêle, s''abriter à la salle polyvalente.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Avis de vigilance orages de la mairie de Biscarrosse</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#E8A317" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#E8A317"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">VIGILANCE ORAGES</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Mairie de Biscarrosse</text><text x="32" y="82" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C">Lundi : orages violents de 18h à 23h</text><text x="32" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">Plage FERMÉE dès 16h</text><text x="32" y="130" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Réouverture mardi à 10h</text><line x1="32" y1="146" x2="288" y2="146" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="168" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">En cas de grêle, abritez-vous</text><text x="160" y="184" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">à la salle polyvalente</text></svg>'),

  ('11111111-a00e-5000-0000-000000000005', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Avis d''alerte crue de la préfecture du Loiret à Orléans : la Loire monte, pic attendu mercredi ; parking des bords de Loire fermé ; les automobilistes doivent déplacer leur véhicule avant mardi 6h ; quais interdits aux piétons.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Avis d''alerte crue de la Loire de la préfecture du Loiret</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">ALERTE CRUE DE LA LOIRE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Préfecture du Loiret — Orléans</text><text x="32" y="82" font-family="Arial" font-size="11" fill="#0F1839">La Loire monte : pic attendu mercredi</text><text x="32" y="106" font-family="Arial" font-size="11" fill="#0F1839">Parking des bords de Loire fermé</text><text x="32" y="130" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">Déplacez votre véhicule avant mardi 6h</text><line x1="32" y1="146" x2="288" y2="146" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="170" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">Quais interdits aux piétons</text></svg>'),

  ('11111111-a00e-5000-0000-000000000006', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Affiche du plan grand froid de la ville de Mulhouse : des nuits de lundi à jeudi, températures jusqu''à -12 °C ; gymnase des Coteaux ouvert chaque nuit de 20h à 8h pour les personnes sans abri ; pour signaler une personne sans abri, appeler le 115. Contact mairie : Amadou Sissoko.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Affiche du plan grand froid de la ville de Mulhouse</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">PLAN GRAND FROID</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Ville de Mulhouse</text><text x="32" y="82" font-family="Arial" font-size="11" fill="#0F1839">Nuits de lundi à jeudi : jusqu''à -12 °C</text><text x="32" y="106" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Gymnase des Coteaux ouvert chaque nuit, 20h - 8h</text><text x="32" y="132" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F">Personne sans abri ? Appelez le 115</text><line x1="32" y1="148" x2="288" y2="148" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="170" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Contact mairie : Amadou Sissoko — 03 89 52 14 70</text></svg>'),

  ('11111111-a00e-5000-0000-000000000007', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Avis de vigilance vagues-submersion de la mairie de Saint-Gilles-Croix-de-Vie : samedi de 5h à 14h, grande marée et forte houle ; accès à la jetée et à la plage interdit ; le marché du centre-ville est maintenu. Signé par la maire, Olena Kovalenko.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Avis de vigilance vagues-submersion de Saint-Gilles-Croix-de-Vie</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#E8A317" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#E8A317"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">VIGILANCE VAGUES-SUBMERSION</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Mairie de Saint-Gilles-Croix-de-Vie</text><text x="32" y="82" font-family="Arial" font-size="11" fill="#0F1839">Samedi, de 5h à 14h :</text><text x="32" y="100" font-family="Arial" font-size="11" fill="#0F1839">grande marée et forte houle</text><text x="32" y="126" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F">Accès à la jetée et à la plage INTERDIT</text><text x="32" y="150" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Le marché du centre-ville est maintenu</text><line x1="32" y1="162" x2="288" y2="162" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">La maire, Olena Kovalenko</text></svg>'),

  ('11111111-a00e-5000-0000-000000000008', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Avis d''alerte brouillard dense de la préfecture de la Somme à Amiens : vendredi de 6h à 10h, visibilité inférieure à 50 mètres ; consigne d''allumer les feux de croisement ; vitesse limitée à 50 km/h sur les routes du département.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Avis d''alerte brouillard dense de la préfecture de la Somme</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">ALERTE BROUILLARD DENSE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Préfecture de la Somme — Amiens</text><text x="32" y="84" font-family="Arial" font-size="12" font-weight="700" fill="#1E3A8C">Vendredi, de 6h à 10h</text><text x="32" y="108" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">Visibilité inférieure à 50 mètres</text><text x="32" y="132" font-family="Arial" font-size="11" fill="#0F1839">Allumez vos feux de croisement</text><line x1="32" y1="148" x2="288" y2="148" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="170" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C" text-anchor="middle">Vitesse limitée à 50 km/h sur les routes</text></svg>'),

  ('11111111-a00e-5000-0000-000000000009', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Avis d''alerte tempête de la ville de Quimper : écoles et crèches fermées le jeudi 12 mars, réouverture vendredi 13 mars ; les repas de cantine ne seront pas facturés. Signé par le maire, Rachid Benali.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Avis d''alerte tempête de la ville de Quimper</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#E8A317" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#E8A317"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">ALERTE TEMPÊTE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Ville de Quimper</text><text x="32" y="84" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F">Écoles et crèches FERMÉES jeudi 12 mars</text><text x="32" y="110" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Réouverture vendredi 13 mars</text><text x="32" y="134" font-family="Arial" font-size="11" fill="#0F1839">Les repas de cantine ne seront pas facturés</text><line x1="32" y1="150" x2="288" y2="150" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="172" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Le maire, Rachid Benali</text></svg>'),

  ('11111111-a00e-5000-0000-00000000000a', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Avis de risque d''avalanche de niveau 4 sur 5 de la mairie de Val-Cenis : remontées mécaniques fermées au-dessus de 2 000 m ; pistes du bas du domaine ouvertes ; hors-piste strictement interdit. Signé par le maire, Diego Morales.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Avis de risque d''avalanche de la mairie de Val-Cenis</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">RISQUE D''AVALANCHE — NIVEAU 4/5</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Mairie de Val-Cenis — Domaine skiable</text><text x="32" y="84" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F">Remontées mécaniques FERMÉES</text><text x="32" y="102" font-family="Arial" font-size="12" font-weight="700" fill="#E1372F">au-dessus de 2 000 m</text><text x="32" y="128" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">Pistes du bas du domaine ouvertes</text><text x="32" y="152" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">Hors-piste strictement interdit</text><line x1="32" y1="164" x2="288" y2="164" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="182" font-family="Arial" font-size="10" fill="#0F1839" text-anchor="middle">Le maire, Diego Morales</text></svg>');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-a00e-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00e-5000-0000-000000000001', 'A2', 'CE',
   'Quelle vitesse maximale de vent est annoncée mercredi ?',
   'L''avis indique « **Rafales jusqu''à 110 km/h** » : c''est la seule vitesse de vent écrite sur le document. « 90 km/h », « 140 km/h » et « 70 km/h » sont des valeurs plausibles pour une vigilance vent, mais elles n''apparaissent nulle part : les choisir, c''est confondre avec les heures de l''alerte (14h-22h), qui ne sont pas des vitesses.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00e-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00e-5000-0000-000000000002', 'A2', 'CE',
   'Où peut-on aller pour se rafraîchir pendant la canicule ?',
   'L''affiche annonce « **Salle rafraîchie : salle des fêtes, 10h - 19h** » : c''est le seul lieu proposé pour se rafraîchir. La mairie est l''émettrice de l''affiche, pas le lieu d''accueil. La piscine municipale et la médiathèque sont des lieux frais plausibles, mais ils ne sont mentionnés nulle part sur le document.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00e-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00e-5000-0000-000000000003', 'A2', 'CE',
   'Que demande la préfecture aux habitants pendant l''alerte ?',
   'L''avis dit clairement « **Évitez de circuler en voiture** » : c''est la consigne donnée aux habitants. « Prendre le bus scolaire » est impossible : les bus scolaires sont justement supprimés dimanche matin. « Partir travailler plus tôt » et « déneiger la route » ne figurent nulle part sur l''avis — seuls les équipements spéciaux sont exigés au-dessus de 800 m.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00e-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00e-5000-0000-000000000004', 'A2', 'CE',
   'À partir de quelle heure les orages sont-ils attendus lundi ?',
   'L''avis annonce « Lundi : orages violents **de 18h à 23h** » : les orages commencent donc à 18h. « 16h » est l''heure de fermeture de la plage, prise par précaution avant les orages. « 23h » est l''heure de fin des orages, pas leur début. « 10h » est l''heure de réouverture de la plage mardi — ce distracteur répondrait à « quand la plage rouvre-t-elle ? ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00e-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00e-5000-0000-000000000005', 'A2', 'CE',
   'Que doivent faire les automobilistes garés près de la Loire ?',
   'L''avis demande en rouge : « **Déplacez votre véhicule avant mardi 6h** ». « Payer le stationnement » n''est écrit nulle part : le parking est fermé, pas payant. « Se garer sur les quais » est le contraire de la consigne : les quais sont interdits aux piétons et la zone est inondable. « Attendre mercredi » est dangereux : mercredi est le jour du pic de crue, pas une consigne.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00e-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00e-5000-0000-000000000006', 'A2', 'CE',
   'Quel numéro faut-il appeler pour signaler une personne sans abri ?',
   'L''affiche indique en rouge : « Personne sans abri ? **Appelez le 115** ». Le « 15 » (SAMU), le « 18 » (pompiers) et le « 112 » (urgences européennes) sont des numéros d''urgence réels et plausibles, mais aucun n''apparaît sur l''affiche : le seul numéro donné pour signaler une personne sans abri est le 115, le numéro d''hébergement d''urgence.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00e-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00e-5000-0000-000000000007', 'A2', 'CE',
   'Quel lieu est interdit d''accès samedi matin ?',
   'L''avis indique en rouge : « **Accès à la jetée et à la plage INTERDIT** » de 5h à 14h. Le marché du centre-ville est au contraire « maintenu » — ce distracteur répondrait à « qu''est-ce qui reste ouvert ? ». La mairie est l''émettrice de l''avis, rien n''indique sa fermeture. Le parking du port n''est mentionné nulle part sur le document.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00e-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00e-5000-0000-000000000008', 'A2', 'CE',
   'Jusqu''à quelle heure le brouillard est-il annoncé vendredi ?',
   'L''avis précise « Vendredi, **de 6h à 10h** » : le brouillard est annoncé jusqu''à 10h. « 6h » est l''heure de début de l''alerte — ce distracteur répondrait à « à quelle heure le brouillard commence-t-il ? ». « 8h » et « 12h » sont des heures matinales plausibles, mais elles ne figurent pas sur le document ; attention à ne pas les confondre avec « 50 », qui désigne la visibilité en mètres et la vitesse en km/h.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00e-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00e-5000-0000-000000000009', 'A2', 'CE',
   'Quel jour les écoles de Quimper sont-elles fermées ?',
   'L''avis annonce en rouge : « Écoles et crèches FERMÉES **jeudi 12 mars** ». « Le vendredi » est le jour de la réouverture (vendredi 13 mars), pas celui de la fermeture — c''est le piège principal. « Le mercredi » et « le samedi » sont des jours proches mais ils ne sont mentionnés nulle part sur le document : aucune fermeture n''est annoncée pour ces jours-là.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00e-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00e-5000-0000-00000000000a', 'A2', 'CE',
   'Qu''est-ce qui est fermé pendant l''alerte avalanche ?',
   'L''avis indique en rouge : « **Remontées mécaniques FERMÉES au-dessus de 2 000 m** ». « Toutes les pistes de la station » sur-généralise : les pistes du bas du domaine restent justement ouvertes. « Les pistes du bas du domaine » dit l''inverse du document (elles sont ouvertes, en vert). « L''office de tourisme » n''apparaît nulle part sur l''avis — seul le hors-piste est par ailleurs interdit.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('11111111-a00e-2100-0000-000000000001', '11111111-a00e-1000-0000-000000000001', '90 km/h', 'false', '1'),
  ('11111111-a00e-2200-0000-000000000001', '11111111-a00e-1000-0000-000000000001', '110 km/h', 'true', '2'),
  ('11111111-a00e-2300-0000-000000000001', '11111111-a00e-1000-0000-000000000001', '140 km/h', 'false', '3'),
  ('11111111-a00e-2400-0000-000000000001', '11111111-a00e-1000-0000-000000000001', '70 km/h', 'false', '4'),

  ('11111111-a00e-2100-0000-000000000002', '11111111-a00e-1000-0000-000000000002', 'À la mairie', 'false', '1'),
  ('11111111-a00e-2200-0000-000000000002', '11111111-a00e-1000-0000-000000000002', 'À la piscine municipale', 'false', '2'),
  ('11111111-a00e-2300-0000-000000000002', '11111111-a00e-1000-0000-000000000002', 'À la salle des fêtes', 'true', '3'),
  ('11111111-a00e-2400-0000-000000000002', '11111111-a00e-1000-0000-000000000002', 'À la médiathèque', 'false', '4'),

  ('11111111-a00e-2100-0000-000000000003', '11111111-a00e-1000-0000-000000000003', 'D''éviter de circuler en voiture', 'true', '1'),
  ('11111111-a00e-2200-0000-000000000003', '11111111-a00e-1000-0000-000000000003', 'De prendre le bus scolaire', 'false', '2'),
  ('11111111-a00e-2300-0000-000000000003', '11111111-a00e-1000-0000-000000000003', 'De partir travailler plus tôt', 'false', '3'),
  ('11111111-a00e-2400-0000-000000000003', '11111111-a00e-1000-0000-000000000003', 'De déneiger la route', 'false', '4'),

  ('11111111-a00e-2100-0000-000000000004', '11111111-a00e-1000-0000-000000000004', '16h', 'false', '1'),
  ('11111111-a00e-2200-0000-000000000004', '11111111-a00e-1000-0000-000000000004', '23h', 'false', '2'),
  ('11111111-a00e-2300-0000-000000000004', '11111111-a00e-1000-0000-000000000004', '10h', 'false', '3'),
  ('11111111-a00e-2400-0000-000000000004', '11111111-a00e-1000-0000-000000000004', '18h', 'true', '4'),

  ('11111111-a00e-2100-0000-000000000005', '11111111-a00e-1000-0000-000000000005', 'Payer le stationnement', 'false', '1'),
  ('11111111-a00e-2200-0000-000000000005', '11111111-a00e-1000-0000-000000000005', 'Déplacer leur véhicule avant mardi 6h', 'true', '2'),
  ('11111111-a00e-2300-0000-000000000005', '11111111-a00e-1000-0000-000000000005', 'Se garer sur les quais', 'false', '3'),
  ('11111111-a00e-2400-0000-000000000005', '11111111-a00e-1000-0000-000000000005', 'Attendre mercredi', 'false', '4'),

  ('11111111-a00e-2100-0000-000000000006', '11111111-a00e-1000-0000-000000000006', 'Le 15', 'false', '1'),
  ('11111111-a00e-2200-0000-000000000006', '11111111-a00e-1000-0000-000000000006', 'Le 18', 'false', '2'),
  ('11111111-a00e-2300-0000-000000000006', '11111111-a00e-1000-0000-000000000006', 'Le 115', 'true', '3'),
  ('11111111-a00e-2400-0000-000000000006', '11111111-a00e-1000-0000-000000000006', 'Le 112', 'false', '4'),

  ('11111111-a00e-2100-0000-000000000007', '11111111-a00e-1000-0000-000000000007', 'La jetée', 'true', '1'),
  ('11111111-a00e-2200-0000-000000000007', '11111111-a00e-1000-0000-000000000007', 'Le marché du centre-ville', 'false', '2'),
  ('11111111-a00e-2300-0000-000000000007', '11111111-a00e-1000-0000-000000000007', 'La mairie', 'false', '3'),
  ('11111111-a00e-2400-0000-000000000007', '11111111-a00e-1000-0000-000000000007', 'Le parking du port', 'false', '4'),

  ('11111111-a00e-2100-0000-000000000008', '11111111-a00e-1000-0000-000000000008', '6h', 'false', '1'),
  ('11111111-a00e-2200-0000-000000000008', '11111111-a00e-1000-0000-000000000008', '8h', 'false', '2'),
  ('11111111-a00e-2300-0000-000000000008', '11111111-a00e-1000-0000-000000000008', '12h', 'false', '3'),
  ('11111111-a00e-2400-0000-000000000008', '11111111-a00e-1000-0000-000000000008', '10h', 'true', '4'),

  ('11111111-a00e-2100-0000-000000000009', '11111111-a00e-1000-0000-000000000009', 'Le mercredi', 'false', '1'),
  ('11111111-a00e-2200-0000-000000000009', '11111111-a00e-1000-0000-000000000009', 'Le vendredi', 'false', '2'),
  ('11111111-a00e-2300-0000-000000000009', '11111111-a00e-1000-0000-000000000009', 'Le jeudi', 'true', '3'),
  ('11111111-a00e-2400-0000-000000000009', '11111111-a00e-1000-0000-000000000009', 'Le samedi', 'false', '4'),

  ('11111111-a00e-2100-0000-00000000000a', '11111111-a00e-1000-0000-00000000000a', 'Toutes les pistes de la station', 'false', '1'),
  ('11111111-a00e-2200-0000-00000000000a', '11111111-a00e-1000-0000-00000000000a', 'Les remontées mécaniques au-dessus de 2 000 m', 'true', '2'),
  ('11111111-a00e-2300-0000-00000000000a', '11111111-a00e-1000-0000-00000000000a', 'L''office de tourisme', 'false', '3'),
  ('11111111-a00e-2400-0000-00000000000a', '11111111-a00e-1000-0000-00000000000a', 'Les pistes du bas du domaine', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 10 items (NN=01..0a), UUID déterministes uniques (questions 1000-,
--     medias 5000-, choices 2100/2200/2300/2400-).
-- [x] Tous les supports = alertes météo, 10 phénomènes et émetteurs différents
--     (vent violent/préfecture Manche, canicule/Montauban, neige-verglas/
--     préfecture Cantal, orages/Biscarrosse, crue/préfecture Loiret, grand
--     froid/Mulhouse, vagues-submersion/Saint-Gilles-Croix-de-Vie, brouillard/
--     préfecture Somme, tempête/Quimper, avalanche/Val-Cenis). Aucun support
--     interdit (pas d'horaires, annonce, étiquette, SMS, affichette
--     d'événement, règlement, menu, carte postale, post-it, programme,
--     transport, vente, invitation, plan).
-- [x] 4 choix par question, exactement 1 correct ; distribution des bonnes
--     réponses : pos1=2 (items 3,7), pos2=3 (items 1,5,10), pos3=3 (items
--     2,6,9), pos4=2 (items 4,8) — max 3 par position, 4 positions utilisées.
-- [x] Questions sur UNE information explicite (vitesse, lieu, consigne, heure,
--     numéro, jour) ; labels des choices = texte de la réponse ; distracteurs
--     = autres valeurs présentes ou plausibles du document.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chacun des 3
--     distracteurs, point clé en **gras**.
-- [x] SVG : viewBox="0 0 320 200", Arial, palette charte (ambre pour les
--     vigilances orange, navy sinon), rouge réservé aux infos critiques
--     (FERMÉ / INTERDIT / 115 / déplacement de véhicule) ; balises
--     équilibrées ; alt_text descriptif complet sur chaque media. Texte utile
--     ~10-40 mots par document.
-- [x] Apostrophes SQL doublées ('') partout (SVG, alt_text, statements,
--     explanations, labels). Pas de JSONB (choices en lignes). Contenu 100%
--     original, prénoms variés (Lucia Fernandes, Amadou Sissoko, Olena
--     Kovalenko, Rachid Benali, Diego Morales), villes variées (Cherbourg,
--     Montauban, Aurillac, Biscarrosse, Orléans, Mulhouse,
--     Saint-Gilles-Croix-de-Vie, Amiens, Quimper, Val-Cenis), chiffres tous
--     différents, aucun texte recopié d'un sujet existant.
-- [x] competence_code : 5× ce_reperage_explicite (items 2,3,5,7,9),
--     5× ce_detail_specifique (items 1,4,6,8,10).
-- ============================================================================
