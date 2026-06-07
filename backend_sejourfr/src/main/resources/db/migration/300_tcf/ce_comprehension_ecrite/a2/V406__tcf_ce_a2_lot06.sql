-- ============================================================================
-- V406 — TCF CE A2 — lot 06 (support : règlement / consigne)
-- ----------------------------------------------------------------------------
-- 10 items CE A2, theme 22222222-0000-0000-0000-000000000002.
-- Chaque item = un règlement ou une consigne originale (SVG style « document »)
-- + 1 question sur UNE information explicite + 4 choix (1 correct).
-- UUID déterministes : questions 11111111-a006-1000-…, medias 11111111-a006-5000-…,
-- choices 11111111-a006-2100/2200/2300/2400-… (display_order 1..4).
-- ============================================================================


-- medias (IMAGE) — règlements et consignes référencés par les questions ci-dessous
INSERT INTO medias
  (id, type, url, storage_key, original_filename, content_type, size_bytes, duration_sec,
   alt_text, created_at, transcript, inline_svg)
VALUES
  ('11111111-a006-5000-0000-000000000001', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Consignes d''utilisation de la laverie automatique Lav''Express à Toulouse : ne pas surcharger les machines, lessive en vente au distributeur (2 euros la dose), fermer le hublot avant de lancer le lavage ; en cas de panne, appeler le 05 61 44 92 18. Gérante : Lucia Moreno.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Consignes d''utilisation de la laverie automatique Lav''Express</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">LAVERIE — CONSIGNES</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Lav''Express — Toulouse</text><text x="32" y="82" font-family="Arial" font-size="11" fill="#0F1839">• Ne surchargez pas les machines.</text><text x="32" y="104" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">• Lessive en vente au distributeur (2 € la dose).</text><text x="32" y="126" font-family="Arial" font-size="11" fill="#0F1839">• Fermez bien le hublot avant de lancer le lavage.</text><line x1="32" y1="142" x2="288" y2="142" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="164" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">En cas de panne : appelez le 05 61 44 92 18</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Gérante : Lucia Moreno — Merci de laisser la laverie propre</text></svg>'),

  ('11111111-a006-5000-0000-000000000002', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Règlement du local à vélos de la résidence Les Tilleuls à Montpellier : accès avec le badge de 6h à 23h, attacher son vélo à un arceau, scooters et motos interdits ; pour toute question, s''adresser au gardien, M. Amadou Sow, loge A.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Règlement du local à vélos de la résidence Les Tilleuls</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="13" font-weight="700" fill="#FFFFFF" text-anchor="middle">LOCAL À VÉLOS — RÈGLEMENT</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Résidence Les Tilleuls — Montpellier</text><text x="32" y="82" font-family="Arial" font-size="11" fill="#0F1839">• Accès avec votre badge, de 6h à 23h.</text><text x="32" y="104" font-family="Arial" font-size="11" fill="#0F1839">• Attachez votre vélo à un arceau.</text><text x="32" y="126" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">• Scooters et motos INTERDITS.</text><line x1="32" y1="142" x2="288" y2="142" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="164" font-family="Arial" font-size="11" fill="#0F1839">Question ? Voir le gardien : M. Amadou Sow, loge A.</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">La résidence n''est pas responsable des vols</text></svg>'),

  ('11111111-a006-5000-0000-000000000003', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Règlement du jardin partagé des Coquelicots à Angers : arroser uniquement sa parcelle, ranger les outils dans le cabanon après usage, déposer le compost dans le bac en bois près de l''entrée, fermer le portail à clé après 19h. Présidente : Olena Kovalenko.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Règlement du jardin partagé des Coquelicots</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#168F5B" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#168F5B"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">JARDIN PARTAGÉ — RÈGLEMENT</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Les Coquelicots — Angers</text><text x="32" y="80" font-family="Arial" font-size="11" fill="#0F1839">• Arrosez uniquement votre parcelle.</text><text x="32" y="100" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">• Rangez les outils dans le cabanon après usage.</text><text x="32" y="120" font-family="Arial" font-size="11" fill="#0F1839">• Compost : bac en bois près de l''entrée.</text><text x="32" y="144" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">• Fermez le portail à clé après 19h.</text><line x1="32" y1="158" x2="288" y2="158" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="178" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Présidente de l''association : Olena Kovalenko</text></svg>'),

  ('11111111-a006-5000-0000-000000000004', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Consignes de sécurité de l''atelier de menuiserie Bois et Formes à Besançon : lunettes de protection obligatoires en zone de découpe, casque anti-bruit conseillé, interdiction de manger dans l''atelier ; en cas d''urgence, appeler le poste 312. Chef d''atelier : Wei Zhang.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Consignes de sécurité de l''atelier Bois et Formes</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#E8A317" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#E8A317"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839" text-anchor="middle">SÉCURITÉ — CONSIGNES ATELIER</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Menuiserie Bois &amp; Formes — Besançon</text><text x="32" y="82" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">• Lunettes de protection OBLIGATOIRES en zone de découpe.</text><text x="32" y="104" font-family="Arial" font-size="11" fill="#0F1839">• Casque anti-bruit conseillé.</text><text x="32" y="126" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">• Interdiction de manger dans l''atelier.</text><line x1="32" y1="142" x2="288" y2="142" stroke="#E8ECF8" stroke-width="2"/><text x="32" y="164" font-family="Arial" font-size="11" fill="#0F1839">Urgence : appelez le poste 312.</text><text x="160" y="184" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Chef d''atelier : Wei Zhang</text></svg>'),

  ('11111111-a006-5000-0000-000000000005', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Règlement de la salle d''étude de la bibliothèque universitaire de Grenoble : silence demandé, téléphones en mode silencieux, boissons interdites sauf l''eau en bouteille fermée, places limitées à 4 heures par personne.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Règlement de la salle d''étude de la bibliothèque universitaire</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">SALLE D''ÉTUDE — RÈGLEMENT</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Bibliothèque universitaire — Grenoble</text><text x="32" y="80" font-family="Arial" font-size="11" fill="#0F1839">• Silence demandé.</text><text x="32" y="100" font-family="Arial" font-size="11" fill="#0F1839">• Téléphones en mode silencieux.</text><text x="32" y="122" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">• Boissons interdites,</text><text x="160" y="122" font-family="Arial" font-size="11" font-weight="700" fill="#168F5B">sauf l''eau en bouteille fermée.</text><text x="32" y="146" font-family="Arial" font-size="11" fill="#0F1839">• Places limitées à 4 heures par personne.</text><line x1="32" y1="160" x2="288" y2="160" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Merci de respecter le travail des autres lecteurs</text></svg>'),

  ('11111111-a006-5000-0000-000000000006', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Note du syndic sur le tri des déchets de la résidence Le Belvédère à Dijon : bac jaune (emballages) collecté le mardi, verre à déposer au point d''apport du 12 rue des Acacias, encombrants sur rendez-vous au 03 80 55 17 26 ; ne laisser aucun sac sur le palier.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Consignes de tri des déchets de la résidence Le Belvédère</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#168F5B" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#168F5B"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">TRI DES DÉCHETS — CONSIGNES</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Résidence Le Belvédère — Dijon (note du syndic)</text><text x="32" y="80" font-family="Arial" font-size="11" fill="#0F1839">• Bac jaune (emballages) : collecte le mardi.</text><text x="32" y="100" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">• Verre : point d''apport, 12 rue des Acacias.</text><text x="32" y="120" font-family="Arial" font-size="11" fill="#0F1839">• Encombrants : sur rendez-vous au 03 80 55 17 26.</text><text x="32" y="144" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">• Ne laissez aucun sac sur le palier.</text><line x1="32" y1="158" x2="288" y2="158" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="178" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Merci pour la propreté de la résidence</text></svg>'),

  ('11111111-a006-5000-0000-000000000007', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Règlement du bassin de la piscine des Docks au Havre : bonnet de bain obligatoire, douche savonnée avant le bain, shorts et bermudas interdits, enfants de moins de 10 ans accompagnés d''un adulte. Maître-nageur : Diego Fuentes.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Règlement du bassin de la piscine des Docks</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">RÈGLEMENT DU BASSIN</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Piscine des Docks — Le Havre</text><text x="32" y="80" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">• Bonnet de bain OBLIGATOIRE.</text><text x="32" y="100" font-family="Arial" font-size="11" fill="#0F1839">• Douche savonnée avant le bain.</text><text x="32" y="122" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">• Shorts et bermudas interdits.</text><text x="32" y="146" font-family="Arial" font-size="11" fill="#0F1839">• Enfants de moins de 10 ans accompagnés d''un adulte.</text><line x1="32" y1="160" x2="288" y2="160" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Maître-nageur : Diego Fuentes — sifflet = sortie du bassin</text></svg>'),

  ('11111111-a006-5000-0000-000000000008', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Consignes pour les visiteurs du service pédiatrie de l''hôpital de Clermont-Ferrand : visites de 13h à 19h30, maximum 2 visiteurs par chambre, lavage des mains au gel à l''entrée, fleurs et plantes interdites. Cadre de santé : Priya Sharma.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Consignes pour les visiteurs du service pédiatrie</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#1E3A8C"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">VISITEURS — CONSIGNES</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Service pédiatrie — Hôpital de Clermont-Ferrand</text><text x="32" y="80" font-family="Arial" font-size="11" fill="#0F1839">• Visites de 13h à 19h30.</text><text x="32" y="100" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">• Maximum 2 visiteurs par chambre.</text><text x="32" y="120" font-family="Arial" font-size="11" fill="#0F1839">• Lavez-vous les mains au gel à l''entrée.</text><text x="32" y="144" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">• Fleurs et plantes interdites.</text><line x1="32" y1="158" x2="288" y2="158" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="178" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Cadre de santé : Priya Sharma — merci de votre compréhension</text></svg>'),

  ('11111111-a006-5000-0000-000000000009', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Consignes d''évacuation en cas d''incendie de l''immeuble Les Glycines à Amiens : ne pas utiliser l''ascenseur, descendre par l''escalier B, rejoindre le point de rassemblement place du Marché, appeler les pompiers au 18.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Consignes d''évacuation incendie de l''immeuble Les Glycines</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#E1372F" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#E1372F"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">EN CAS D''INCENDIE</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Immeuble Les Glycines — Amiens</text><text x="32" y="80" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">• N''utilisez PAS l''ascenseur.</text><text x="32" y="100" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">• Descendez par l''escalier B.</text><text x="32" y="120" font-family="Arial" font-size="11" fill="#0F1839">• Point de rassemblement : place du Marché.</text><text x="32" y="144" font-family="Arial" font-size="11" fill="#0F1839">• Appelez les pompiers : 18.</text><line x1="32" y1="158" x2="288" y2="158" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="178" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Gardez votre calme et aidez les personnes fragiles</text></svg>'),

  ('11111111-a006-5000-0000-00000000000a', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Règlement de l''aire de jeux du parc Beaumont à Pau, affiché par la mairie : aire réservée aux enfants de 2 à 10 ans, accompagnement par un adulte obligatoire, chiens interdits même tenus en laisse, ouverte de 8h au coucher du soleil.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Règlement de l''aire de jeux du parc Beaumont</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="16" y="10" width="288" height="180" rx="6" fill="#FFFFFF" stroke="#168F5B" stroke-width="2"/><rect x="16" y="10" width="288" height="30" fill="#168F5B"/><text x="160" y="30" font-family="Arial" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">AIRE DE JEUX — RÈGLEMENT</text><text x="160" y="56" font-family="Arial" font-size="11" fill="#0F1839" text-anchor="middle">Parc Beaumont — Ville de Pau</text><text x="32" y="80" font-family="Arial" font-size="11" font-weight="700" fill="#1E3A8C">• Réservée aux enfants de 2 à 10 ans.</text><text x="32" y="100" font-family="Arial" font-size="11" fill="#0F1839">• Accompagnement par un adulte obligatoire.</text><text x="32" y="122" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">• Chiens interdits, même tenus en laisse.</text><text x="32" y="146" font-family="Arial" font-size="11" fill="#0F1839">• Ouverte de 8h au coucher du soleil.</text><line x1="32" y1="160" x2="288" y2="160" stroke="#E8ECF8" stroke-width="2"/><text x="160" y="180" font-family="Arial" font-size="9" fill="#0F1839" text-anchor="middle">Mairie de Pau — service des espaces verts</text></svg>');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-a006-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a006-5000-0000-000000000001', 'A2', 'CE',
   'Où peut-on acheter de la lessive dans cette laverie ?',
   'Les consignes indiquent « **Lessive en vente au distributeur (2 € la dose)** » : c''est donc au distributeur. « À l''accueil » est plausible mais la laverie est automatique, aucun accueil n''est mentionné. « Au supermarché voisin » n''apparaît nulle part sur l''affiche. « Auprès du technicien » confond avec le numéro à appeler en cas de panne (05 61 44 92 18), qui ne vend pas de lessive.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a006-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a006-5000-0000-000000000002', 'A2', 'CE',
   'Qu''est-il interdit de laisser dans le local à vélos ?',
   'La ligne rouge du règlement est claire : « **Scooters et motos INTERDITS** ». Les vélos d''enfant et les vélos électriques restent des vélos : le local leur est justement destiné, à condition de les attacher à un arceau. Les remorques ne sont mentionnées nulle part dans le règlement — ce distracteur est plausible mais inventé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a006-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a006-5000-0000-000000000003', 'A2', 'CE',
   'Où faut-il ranger les outils après usage ?',
   'Le règlement précise « **Rangez les outils dans le cabanon après usage** » : la bonne réponse est le cabanon. « Près de l''entrée » est l''emplacement du bac à compost, pas des outils. « Sur sa parcelle » confond avec la règle d''arrosage (« arrosez uniquement votre parcelle »). « Au portail » mélange avec la consigne de fermer le portail à clé après 19h.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a006-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a006-5000-0000-000000000004', 'A2', 'CE',
   'Que faut-il obligatoirement porter dans la zone de découpe ?',
   'Les consignes de sécurité indiquent « **Lunettes de protection OBLIGATOIRES en zone de découpe** ». Le casque anti-bruit est seulement « conseillé », pas obligatoire — c''est le piège principal. Les gants et le gilet jaune ne figurent nulle part dans les consignes de cet atelier : ce sont des équipements plausibles mais inventés.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a006-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a006-5000-0000-000000000005', 'A2', 'CE',
   'Quelle boisson est autorisée dans la salle d''étude ?',
   'Le règlement énonce « Boissons interdites, **sauf l''eau en bouteille fermée** » : seule l''eau est donc autorisée. Le café, le jus de fruits et le thé sont tous des boissons et tombent sous l''interdiction générale — aucun n''est cité comme exception. Ces trois distracteurs testent la compréhension du mot **sauf**, qui introduit la seule exception du règlement.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a006-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a006-5000-0000-000000000006', 'A2', 'CE',
   'Où faut-il déposer le verre ?',
   'La note du syndic indique « **Verre : point d''apport, 12 rue des Acacias** ». Le bac jaune est réservé aux emballages, collectés le mardi : c''est le piège principal. Le palier est justement l''endroit où il est interdit de laisser un sac (ligne rouge). La déchetterie n''est pas mentionnée dans la note — ce distracteur est plausible mais inventé ; les encombrants, eux, partent sur rendez-vous téléphonique.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a006-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a006-5000-0000-000000000007', 'A2', 'CE',
   'Qu''est-ce qui est obligatoire pour se baigner dans cette piscine ?',
   'Le règlement du bassin affiche « **Bonnet de bain OBLIGATOIRE** » : c''est la seule obligation de tenue. Le short de bain est au contraire **interdit** (« shorts et bermudas interdits ») — c''est le piège principal. Les lunettes de natation et la serviette ne sont mentionnées nulle part dans le règlement : ce sont des objets plausibles à la piscine mais sans aucune obligation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a006-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a006-5000-0000-000000000008', 'A2', 'CE',
   'Combien de visiteurs au maximum sont autorisés par chambre ?',
   'Les consignes du service pédiatrie précisent « **Maximum 2 visiteurs par chambre** ». « Un » est plus strict que la règle affichée et « trois » comme « quatre » la dépassent : aucun de ces trois nombres n''apparaît dans les consignes. Attention à ne pas confondre avec les horaires de visite (13h à 19h30), qui sont les seuls autres chiffres du document.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a006-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a006-5000-0000-000000000009', 'A2', 'CE',
   'Que ne faut-il pas utiliser en cas d''incendie ?',
   'La première consigne, en rouge, est « **N''utilisez PAS l''ascenseur** ». L''escalier B est au contraire le chemin à emprunter pour descendre. Le téléphone sert justement à appeler les pompiers (18) : il n''est pas interdit. La sortie de l''immeuble est le but de l''évacuation, vers le point de rassemblement place du Marché — ces trois distracteurs désignent des éléments à **utiliser**, pas à éviter.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a006-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a006-5000-0000-00000000000a', 'A2', 'CE',
   'À quels enfants l''aire de jeux est-elle réservée ?',
   'Le règlement affiche « **Réservée aux enfants de 2 à 10 ans** » : c''est la tranche d''âge exacte. « Moins de 2 ans » et « plus de 10 ans » sont précisément les âges exclus par cette règle. « Tous les enfants accompagnés » mélange deux règles différentes : l''accompagnement par un adulte est obligatoire, mais il ne supprime pas la limite d''âge de 2 à 10 ans.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('11111111-a006-2100-0000-000000000001', '11111111-a006-1000-0000-000000000001', 'À l''accueil de la laverie', 'false', '1'),
  ('11111111-a006-2200-0000-000000000001', '11111111-a006-1000-0000-000000000001', 'Au supermarché voisin', 'false', '2'),
  ('11111111-a006-2300-0000-000000000001', '11111111-a006-1000-0000-000000000001', 'Au distributeur', 'true', '3'),
  ('11111111-a006-2400-0000-000000000001', '11111111-a006-1000-0000-000000000001', 'Auprès du technicien', 'false', '4'),

  ('11111111-a006-2100-0000-000000000002', '11111111-a006-1000-0000-000000000002', 'Les scooters et les motos', 'true', '1'),
  ('11111111-a006-2200-0000-000000000002', '11111111-a006-1000-0000-000000000002', 'Les vélos d''enfant', 'false', '2'),
  ('11111111-a006-2300-0000-000000000002', '11111111-a006-1000-0000-000000000002', 'Les vélos électriques', 'false', '3'),
  ('11111111-a006-2400-0000-000000000002', '11111111-a006-1000-0000-000000000002', 'Les remorques', 'false', '4'),

  ('11111111-a006-2100-0000-000000000003', '11111111-a006-1000-0000-000000000003', 'Près de l''entrée', 'false', '1'),
  ('11111111-a006-2200-0000-000000000003', '11111111-a006-1000-0000-000000000003', 'Sur sa parcelle', 'false', '2'),
  ('11111111-a006-2300-0000-000000000003', '11111111-a006-1000-0000-000000000003', 'Au portail', 'false', '3'),
  ('11111111-a006-2400-0000-000000000003', '11111111-a006-1000-0000-000000000003', 'Dans le cabanon', 'true', '4'),

  ('11111111-a006-2100-0000-000000000004', '11111111-a006-1000-0000-000000000004', 'Un casque anti-bruit', 'false', '1'),
  ('11111111-a006-2200-0000-000000000004', '11111111-a006-1000-0000-000000000004', 'Des lunettes de protection', 'true', '2'),
  ('11111111-a006-2300-0000-000000000004', '11111111-a006-1000-0000-000000000004', 'Des gants', 'false', '3'),
  ('11111111-a006-2400-0000-000000000004', '11111111-a006-1000-0000-000000000004', 'Un gilet jaune', 'false', '4'),

  ('11111111-a006-2100-0000-000000000005', '11111111-a006-1000-0000-000000000005', 'L''eau en bouteille fermée', 'true', '1'),
  ('11111111-a006-2200-0000-000000000005', '11111111-a006-1000-0000-000000000005', 'Le café', 'false', '2'),
  ('11111111-a006-2300-0000-000000000005', '11111111-a006-1000-0000-000000000005', 'Le jus de fruits', 'false', '3'),
  ('11111111-a006-2400-0000-000000000005', '11111111-a006-1000-0000-000000000005', 'Le thé', 'false', '4'),

  ('11111111-a006-2100-0000-000000000006', '11111111-a006-1000-0000-000000000006', 'Dans le bac jaune', 'false', '1'),
  ('11111111-a006-2200-0000-000000000006', '11111111-a006-1000-0000-000000000006', 'Sur le palier', 'false', '2'),
  ('11111111-a006-2300-0000-000000000006', '11111111-a006-1000-0000-000000000006', 'Au point d''apport de la rue des Acacias', 'true', '3'),
  ('11111111-a006-2400-0000-000000000006', '11111111-a006-1000-0000-000000000006', 'À la déchetterie', 'false', '4'),

  ('11111111-a006-2100-0000-000000000007', '11111111-a006-1000-0000-000000000007', 'Les lunettes de natation', 'false', '1'),
  ('11111111-a006-2200-0000-000000000007', '11111111-a006-1000-0000-000000000007', 'Le bonnet de bain', 'true', '2'),
  ('11111111-a006-2300-0000-000000000007', '11111111-a006-1000-0000-000000000007', 'Le short de bain', 'false', '3'),
  ('11111111-a006-2400-0000-000000000007', '11111111-a006-1000-0000-000000000007', 'La serviette', 'false', '4'),

  ('11111111-a006-2100-0000-000000000008', '11111111-a006-1000-0000-000000000008', 'Un', 'false', '1'),
  ('11111111-a006-2200-0000-000000000008', '11111111-a006-1000-0000-000000000008', 'Trois', 'false', '2'),
  ('11111111-a006-2300-0000-000000000008', '11111111-a006-1000-0000-000000000008', 'Quatre', 'false', '3'),
  ('11111111-a006-2400-0000-000000000008', '11111111-a006-1000-0000-000000000008', 'Deux', 'true', '4'),

  ('11111111-a006-2100-0000-000000000009', '11111111-a006-1000-0000-000000000009', 'L''ascenseur', 'true', '1'),
  ('11111111-a006-2200-0000-000000000009', '11111111-a006-1000-0000-000000000009', 'L''escalier B', 'false', '2'),
  ('11111111-a006-2300-0000-000000000009', '11111111-a006-1000-0000-000000000009', 'Le téléphone', 'false', '3'),
  ('11111111-a006-2400-0000-000000000009', '11111111-a006-1000-0000-000000000009', 'La sortie de l''immeuble', 'false', '4'),

  ('11111111-a006-2100-0000-00000000000a', '11111111-a006-1000-0000-00000000000a', 'Aux enfants de moins de 2 ans', 'false', '1'),
  ('11111111-a006-2200-0000-00000000000a', '11111111-a006-1000-0000-00000000000a', 'Aux enfants de 2 à 10 ans', 'true', '2'),
  ('11111111-a006-2300-0000-00000000000a', '11111111-a006-1000-0000-00000000000a', 'Aux enfants de plus de 10 ans', 'false', '3'),
  ('11111111-a006-2400-0000-00000000000a', '11111111-a006-1000-0000-00000000000a', 'À tous les enfants accompagnés', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 10 items (NN=01..0a), UUID déterministes uniques (questions 1000-,
--     medias 5000-, choices 2100/2200/2300/2400-).
-- [x] Tous les supports = règlement / consigne, 10 contextes différents
--     (laverie automatique, local à vélos, jardin partagé, atelier de
--     menuiserie, salle d'étude, tri des déchets, bassin de piscine, visites
--     à l'hôpital, évacuation incendie, aire de jeux). Aucun support interdit
--     (pas d'horaires, d'annonce, d'étiquette, de SMS, de menu, etc.).
-- [x] 4 choix par question, exactement 1 correct ; distribution des bonnes
--     réponses : pos1=3 (items 2,5,9), pos2=3 (items 4,7,10), pos3=2 (items
--     1,6), pos4=2 (items 3,8) — max 3 par position, 4 positions utilisées.
-- [x] Questions sur UNE information explicite (lieu, objet interdit/obligé,
--     nombre, action) ; labels des choices = texte de la réponse ;
--     distracteurs = autres valeurs présentes ou plausibles du document.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chacun des
--     3 distracteurs, point clé en **gras**.
-- [x] SVG : viewBox="0 0 320 200", Arial, palette charte, rouge réservé aux
--     interdictions / urgences (INTERDITS, panne, incendie, palier) ; balises
--     équilibrées ; alt_text descriptif complet sur chaque media. Texte utile
--     ~10-40 mots par document.
-- [x] Apostrophes SQL doublées ('') partout (SVG, alt_text, statements,
--     explanations, labels). Pas de JSONB (choices en lignes). Contenu 100%
--     original, prénoms variés (Lucia Moreno, Amadou Sow, Olena Kovalenko,
--     Wei Zhang, Diego Fuentes, Priya Sharma), villes toutes différentes
--     (Toulouse, Montpellier, Angers, Besançon, Grenoble, Dijon, Le Havre,
--     Clermont-Ferrand, Amiens, Pau), chiffres inventés.
-- [x] competence_code : 5× ce_reperage_explicite (items 2,4,5,7,9),
--     5× ce_detail_specifique (items 1,3,6,8,10).
-- ============================================================================
