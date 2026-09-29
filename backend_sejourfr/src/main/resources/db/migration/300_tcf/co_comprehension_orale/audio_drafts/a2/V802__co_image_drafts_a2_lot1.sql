-- ============================================================================
-- V802 — TCF CO : drafts CO_IMAGE A2 (lot 1)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO de type CO_IMAGE (A2). Table audio_question_draft.
-- Format officiel TCF (cf. exemples 1 & 2 du livret) : une IMAGE est affichée,
-- l'audio lit UNIQUEMENT les 4 propositions. Pas de réplique parlée : l'image
-- remplace le document. Le candidat choisit la proposition qui correspond à
-- l'image.
--
-- Colonnes image ajoutées (schéma CO_IMAGE) :
--   inline_svg     : SVG du support visuel (offline-first ; remplaçable en admin)
--   image_url      : NULL ici (l'admin pourra uploader une image réaliste -> R2)
--   image_alt_text : description accessible de l'image
--
-- competence_code = 'co_image_proposition'. statut TEXT_VALIDATED : l'audio sera
-- généré par le batch admin (intro + propositions). audio_url NULL pour l'instant.
--
-- Données déterministes, rejouables (dev + recette).
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id,
   inline_svg, image_url, image_alt_text,
   transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES

  -- ----------------------------------------------------------------------------
  -- 1. Une mère appelle sa famille à table (scène cuisine + table dressée)
  -- ----------------------------------------------------------------------------
  ('66666666-0023-1000-0000-000000000001', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="150" width="320" height="50" fill="#15296B"/><rect x="30" y="95" width="120" height="55" rx="4" fill="#FDECEB"/><rect x="30" y="88" width="120" height="10" fill="#E1372F"/><circle cx="60" cy="120" r="9" fill="#1E3A8C"/><circle cx="90" cy="120" r="9" fill="#1E3A8C"/><circle cx="120" cy="120" r="9" fill="#1E3A8C"/><rect x="200" y="60" width="90" height="90" rx="4" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><circle cx="245" cy="95" r="18" fill="#E8A317"/><rect x="225" y="120" width="40" height="25" fill="#168F5B"/><circle cx="175" cy="70" r="14" fill="#0F1839"/><rect x="168" y="82" width="14" height="30" fill="#1E3A8C"/></svg>',
   NULL,
   'Une femme dans une cuisine appelle sa famille ; la table est dressée et le repas est prêt.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Allez vous coucher rapidement.
B. Finissez vos exercices de français.
C. Regardez la télévision maintenant.
D. Venez manger tout de suite.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Allez vous coucher rapidement.<break time="700ms"/>B.<break time="300ms"/>Finissez vos exercices de français.<break time="700ms"/>C.<break time="300ms"/>Regardez la télévision maintenant.<break time="700ms"/>D.<break time="300ms"/>Venez manger tout de suite.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une femme qui appelle sa famille pour le repas, avec une table dressée. Seule D « Venez manger tout de suite » correspond à cette scène. A (aller se coucher), B (finir des exercices) et C (regarder la télévision) ne correspondent pas à l''action représentée.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-05-31 18:00:00.000000+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 2. Un couple arrive dans une salle de cinéma (écran + rangées de sièges)
  -- ----------------------------------------------------------------------------
  ('66666666-0023-1000-0000-000000000002', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#0F1839"/><rect x="40" y="20" width="240" height="90" rx="4" fill="#FFFFFF"/><rect x="48" y="28" width="224" height="74" fill="#E8ECF8"/><rect x="0" y="130" width="320" height="70" fill="#15296B"/><rect x="30" y="140" width="40" height="30" rx="4" fill="#1E3A8C"/><rect x="90" y="140" width="40" height="30" rx="4" fill="#1E3A8C"/><rect x="150" y="140" width="40" height="30" rx="4" fill="#1E3A8C"/><rect x="210" y="140" width="40" height="30" rx="4" fill="#1E3A8C"/><circle cx="270" cy="125" r="12" fill="#E8A317"/><rect x="263" y="135" width="14" height="28" fill="#E1372F"/><circle cx="295" cy="125" r="12" fill="#FDECEB"/><rect x="288" y="135" width="14" height="28" fill="#168F5B"/></svg>',
   NULL,
   'Un couple entre dans une salle de cinéma et cherche des places ; le grand écran est allumé.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. C''est un acteur formidable.
B. Je déteste la publicité.
C. Viens, on va s''asseoir là.
D. Tu vas payer nos billets.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>C''est un acteur formidable.<break time="700ms"/>B.<break time="300ms"/>Je déteste la publicité.<break time="700ms"/>C.<break time="300ms"/>Viens, on va s''asseoir là.<break time="700ms"/>D.<break time="300ms"/>Tu vas payer nos billets.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un couple qui entre dans la salle et cherche des places. Seule C « Viens, on va s''asseoir là » correspond à ce moment. A (commenter un acteur) suppose le film commencé, B (la publicité) et D (payer les billets) renvoient à d''autres moments que celui représenté.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-05-31 18:00:00.000000+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 3. Une personne attend le bus à un arrêt (panneau + abribus)
  -- ----------------------------------------------------------------------------
  ('66666666-0023-1000-0000-000000000003', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#0F1839"/><rect x="40" y="70" width="120" height="90" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="40" y="60" width="120" height="14" fill="#1E3A8C"/><rect x="200" y="40" width="14" height="120" fill="#15296B"/><rect x="190" y="40" width="60" height="34" rx="3" fill="#E1372F"/><text x="220" y="62" font-family="Arial" font-size="20" fill="#FFFFFF" text-anchor="middle">BUS</text><circle cx="100" cy="120" r="14" fill="#E8A317"/><rect x="92" y="132" width="16" height="28" fill="#168F5B"/></svg>',
   NULL,
   'Une personne attend à un arrêt de bus, sous un abribus, à côté d''un panneau marqué BUS.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. J''attends le bus pour aller en ville.
B. Je fais la queue à la boulangerie.
C. Je cherche un livre à la bibliothèque.
D. Je prends un café en terrasse.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>J''attends le bus pour aller en ville.<break time="700ms"/>B.<break time="300ms"/>Je fais la queue à la boulangerie.<break time="700ms"/>C.<break time="300ms"/>Je cherche un livre à la bibliothèque.<break time="700ms"/>D.<break time="300ms"/>Je prends un café en terrasse.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une personne à un arrêt de bus, avec un panneau BUS et un abribus. Seule A « J''attends le bus » correspond. B (boulangerie), C (bibliothèque) et D (café en terrasse) décrivent d''autres lieux non représentés.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-05-31 18:00:00.000000+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 4. Un médecin ausculte un patient (cabinet médical)
  -- ----------------------------------------------------------------------------
  ('66666666-0023-1000-0000-000000000004', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#FDECEB"/><rect x="0" y="160" width="320" height="40" fill="#E8ECF8"/><rect x="180" y="80" width="120" height="80" rx="4" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="180" y="80" width="120" height="80" rx="4" fill="none" stroke="#1E3A8C" stroke-width="2"/><rect x="232" y="60" width="16" height="40" fill="#E1372F"/><rect x="220" y="72" width="40" height="16" fill="#E1372F"/><circle cx="70" cy="70" r="16" fill="#0F1839"/><rect x="58" y="84" width="24" height="46" fill="#1E3A8C"/><circle cx="120" cy="80" r="14" fill="#E8A317"/><rect x="110" y="92" width="20" height="40" fill="#168F5B"/><circle cx="78" cy="100" r="4" fill="#FFFFFF"/></svg>',
   NULL,
   'Un médecin en blouse ausculte un patient dans un cabinet médical avec une croix de santé.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Je vais vous couper les cheveux.
B. Voici votre billet de train.
C. Respirez fort, je vous écoute.
D. Quelle pizza voulez-vous ?',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Je vais vous couper les cheveux.<break time="700ms"/>B.<break time="300ms"/>Voici votre billet de train.<break time="700ms"/>C.<break time="300ms"/>Respirez fort, je vous écoute.<break time="700ms"/>D.<break time="300ms"/>Quelle pizza voulez-vous ?</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un médecin qui ausculte un patient. Seule C « Respirez fort, je vous écoute » correspond à la consultation médicale. A (coiffeur), B (gare) et D (pizzeria) renvoient à d''autres métiers et lieux.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-05-31 18:00:00.000000+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 5. Il pleut : une personne ouvre un parapluie (nuages + gouttes)
  -- ----------------------------------------------------------------------------
  ('66666666-0023-1000-0000-000000000005', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="165" width="320" height="35" fill="#15296B"/><ellipse cx="120" cy="45" rx="70" ry="26" fill="#1E3A8C"/><ellipse cx="200" cy="55" rx="55" ry="22" fill="#15296B"/><line x1="90" y1="80" x2="84" y2="100" stroke="#1E3A8C" stroke-width="3"/><line x1="130" y1="80" x2="124" y2="100" stroke="#1E3A8C" stroke-width="3"/><line x1="170" y1="85" x2="164" y2="105" stroke="#1E3A8C" stroke-width="3"/><path d="M 200 120 A 35 35 0 0 1 270 120 Z" fill="#E1372F"/><line x1="235" y1="120" x2="235" y2="160" stroke="#0F1839" stroke-width="3"/><circle cx="235" cy="150" r="10" fill="#E8A317"/></svg>',
   NULL,
   'Il pleut : des nuages, des gouttes, et une personne ouvre un parapluie rouge.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Quel beau soleil aujourd''hui !
B. Prends ton parapluie, il pleut.
C. La neige tombe sur les montagnes.
D. Mettons-nous à l''ombre, il fait chaud.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Quel beau soleil aujourd''hui !<break time="700ms"/>B.<break time="300ms"/>Prends ton parapluie, il pleut.<break time="700ms"/>C.<break time="300ms"/>La neige tombe sur les montagnes.<break time="700ms"/>D.<break time="300ms"/>Mettons-nous à l''ombre, il fait chaud.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre la pluie et un parapluie ouvert. Seule B « Prends ton parapluie, il pleut » correspond à la météo représentée. A (soleil), C (neige) et D (chaleur) décrivent d''autres conditions météo.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-05-31 18:00:00.000000+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 6. Une cliente paie à la caisse d'un supermarché (caddie + caisse)
  -- ----------------------------------------------------------------------------
  ('66666666-0023-1000-0000-000000000006', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="170" y="100" width="120" height="60" rx="3" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="170" y="92" width="120" height="12" fill="#1E3A8C"/><rect x="185" y="112" width="40" height="22" fill="#168F5B"/><rect x="235" y="112" width="40" height="22" fill="#E8A317"/><path d="M 40 110 L 50 110 L 60 150 L 110 150 L 118 120 L 56 120" fill="none" stroke="#0F1839" stroke-width="3"/><circle cx="70" cy="160" r="7" fill="#0F1839"/><circle cx="105" cy="160" r="7" fill="#0F1839"/><circle cx="140" cy="70" r="14" fill="#E1372F"/><rect x="130" y="82" width="20" height="40" fill="#1E3A8C"/></svg>',
   NULL,
   'Une cliente avec un caddie paie à la caisse d''un supermarché.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Je voudrais réserver une chambre.
B. Bonjour, je règle mes courses.
C. Un aller-retour pour Lyon, merci.
D. Je viens récupérer mon courrier.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Je voudrais réserver une chambre.<break time="700ms"/>B.<break time="300ms"/>Bonjour, je règle mes courses.<break time="700ms"/>C.<break time="300ms"/>Un aller-retour pour Lyon, merci.<break time="700ms"/>D.<break time="300ms"/>Je viens récupérer mon courrier.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une cliente avec un caddie à la caisse d''un supermarché. Seule B « je règle mes courses » correspond. A (hôtel), C (gare) et D (poste) renvoient à d''autres lieux.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-05-31 18:00:00.000000+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 7. Des enfants jouent au ballon dans un parc (arbres + ballon)
  -- ----------------------------------------------------------------------------
  ('66666666-0023-1000-0000-000000000007', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="150" width="320" height="50" fill="#168F5B"/><circle cx="60" cy="70" r="30" fill="#0F6E45"/><rect x="55" y="90" width="10" height="60" fill="#15296B"/><circle cx="260" cy="60" r="34" fill="#0F6E45"/><rect x="255" y="85" width="10" height="65" fill="#15296B"/><circle cx="160" cy="135" r="16" fill="#FFFFFF" stroke="#0F1839" stroke-width="2"/><path d="M 160 119 L 167 130 L 153 130 Z" fill="#0F1839"/><circle cx="120" cy="100" r="12" fill="#E1372F"/><rect x="112" y="112" width="16" height="34" fill="#1E3A8C"/><circle cx="205" cy="100" r="12" fill="#E8A317"/><rect x="197" y="112" width="16" height="34" fill="#E1372F"/></svg>',
   NULL,
   'Des enfants jouent au ballon dans un parc avec des arbres et de la pelouse.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Les enfants jouent au ballon dans le parc.
B. Les élèves passent un examen en classe.
C. La famille dîne au restaurant.
D. Les voyageurs attendent à l''aéroport.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Les enfants jouent au ballon dans le parc.<break time="700ms"/>B.<break time="300ms"/>Les élèves passent un examen en classe.<break time="700ms"/>C.<break time="300ms"/>La famille dîne au restaurant.<break time="700ms"/>D.<break time="300ms"/>Les voyageurs attendent à l''aéroport.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre des enfants qui jouent au ballon dans un parc. Seule A correspond à la scène. B (classe), C (restaurant) et D (aéroport) décrivent d''autres lieux et activités.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-05-31 18:00:00.000000+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 8. Une personne dort dans un lit, la nuit (lune + lit)
  -- ----------------------------------------------------------------------------
  ('66666666-0023-1000-0000-000000000008', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#15296B"/><circle cx="260" cy="50" r="24" fill="#E8ECF8"/><circle cx="270" cy="44" r="24" fill="#15296B"/><circle cx="60" cy="40" r="2" fill="#FFFFFF"/><circle cx="100" cy="60" r="2" fill="#FFFFFF"/><circle cx="150" cy="35" r="2" fill="#FFFFFF"/><rect x="40" y="120" width="200" height="60" rx="6" fill="#E8ECF8"/><rect x="40" y="110" width="60" height="40" rx="6" fill="#FDECEB"/><circle cx="80" cy="125" r="14" fill="#E8A317"/><rect x="30" y="160" width="220" height="20" fill="#1E3A8C"/></svg>',
   NULL,
   'Il fait nuit, la lune brille, une personne dort dans un lit.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il travaille à son bureau le matin.
B. Il court sur la plage au soleil.
C. Il cuisine le déjeuner à midi.
D. Il dort dans son lit, c''est la nuit.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il travaille à son bureau le matin.<break time="700ms"/>B.<break time="300ms"/>Il court sur la plage au soleil.<break time="700ms"/>C.<break time="300ms"/>Il cuisine le déjeuner à midi.<break time="700ms"/>D.<break time="300ms"/>Il dort dans son lit, c''est la nuit.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une personne qui dort la nuit, avec la lune et les étoiles. Seule D correspond. A (bureau le matin), B (plage au soleil) et C (cuisine à midi) évoquent d''autres moments de la journée.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-05-31 18:00:00.000000+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 9. Une voiture s'arrête à un feu rouge (feu tricolore)
  -- ----------------------------------------------------------------------------
  ('66666666-0023-1000-0000-000000000009', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="150" width="320" height="50" fill="#0F1839"/><rect x="60" y="40" width="40" height="110" rx="6" fill="#15296B"/><circle cx="80" cy="62" r="12" fill="#E1372F"/><circle cx="80" cy="95" r="12" fill="#1E3A8C" opacity="0.3"/><circle cx="80" cy="128" r="12" fill="#168F5B" opacity="0.3"/><rect x="160" y="110" width="110" height="40" rx="8" fill="#1E3A8C"/><rect x="180" y="90" width="60" height="30" rx="6" fill="#1E3A8C"/><circle cx="180" cy="155" r="13" fill="#0F1839"/><circle cx="180" cy="155" r="6" fill="#E8ECF8"/><circle cx="250" cy="155" r="13" fill="#0F1839"/><circle cx="250" cy="155" r="6" fill="#E8ECF8"/></svg>',
   NULL,
   'Une voiture est arrêtée devant un feu tricolore qui est au rouge.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. L''avion décolle de la piste.
B. Le bateau traverse la rivière.
C. La voiture s''arrête au feu rouge.
D. Le vélo monte la côte.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>L''avion décolle de la piste.<break time="700ms"/>B.<break time="300ms"/>Le bateau traverse la rivière.<break time="700ms"/>C.<break time="300ms"/>La voiture s''arrête au feu rouge.<break time="700ms"/>D.<break time="300ms"/>Le vélo monte la côte.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une voiture arrêtée à un feu rouge. Seule C correspond. A (avion), B (bateau) et D (vélo) sont d''autres moyens de transport non représentés.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-05-31 18:00:00.000000+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 10. Une femme lit un livre dans un fauteuil (lampe + bibliothèque)
  -- ----------------------------------------------------------------------------
  ('66666666-0023-1000-0000-00000000000a', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#FDECEB"/><rect x="0" y="160" width="320" height="40" fill="#B5251E"/><rect x="210" y="40" width="90" height="120" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="218" y="50" width="74" height="20" fill="#1E3A8C"/><rect x="218" y="76" width="74" height="20" fill="#168F5B"/><rect x="218" y="102" width="74" height="20" fill="#E8A317"/><rect x="218" y="128" width="74" height="20" fill="#E1372F"/><rect x="60" y="100" width="80" height="60" rx="10" fill="#1E3A8C"/><circle cx="100" cy="80" r="18" fill="#E8A317"/><rect x="92" y="96" width="16" height="20" fill="#0F1839"/><rect x="88" y="110" width="40" height="26" rx="3" fill="#FFFFFF"/></svg>',
   NULL,
   'Une femme est assise dans un fauteuil et lit un livre, près d''une bibliothèque.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle nage dans la piscine.
B. Elle lit un livre dans son fauteuil.
C. Elle fait ses courses au marché.
D. Elle conduit sa voiture en ville.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle nage dans la piscine.<break time="700ms"/>B.<break time="300ms"/>Elle lit un livre dans son fauteuil.<break time="700ms"/>C.<break time="300ms"/>Elle fait ses courses au marché.<break time="700ms"/>D.<break time="300ms"/>Elle conduit sa voiture en ville.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une femme qui lit un livre dans un fauteuil près d''une bibliothèque. Seule B correspond. A (piscine), C (marché) et D (voiture) décrivent d''autres activités.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-05-31 18:00:00.000000+02', NULL, NULL, NULL);
