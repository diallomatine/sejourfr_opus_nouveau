-- ============================================================================
-- V803 — TCF CO A2 — lot 01 (thème : repas & cuisine)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (A2), table audio_question_draft. 10 items, tous dans le
-- thème « repas & cuisine », scènes toutes différentes :
--   - 5 items format A (CO_IMAGE, competence_code='co_image_proposition') :
--     une IMAGE est affichée (inline_svg + image_alt_text), l'audio lit
--     uniquement l'intro + les 4 propositions (mono-voix Denise).
--   - 5 items format B (competence_code='co_question_reponse') : l'audio lit
--     une question courte (Henri ou Vivienne) puis 4 réponses (Denise).
--     inline_svg / image_alt_text NULL.
-- Compréhension EXPLICITE (A2) : bonne réponse littérale, distracteurs
-- nettement distincts (autre lieu / action / moment).
-- statut TEXT_VALIDATED : l'audio sera généré par le batch admin.
-- Toutes colonnes audio NULL. Données déterministes, rejouables (dev + recette).
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
  -- 1. [Format A] Petit-déjeuner en famille (table, bols, croissant, soleil)
  -- ----------------------------------------------------------------------------
  ('66666666-a001-1000-0000-000000000001', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="155" width="320" height="45" fill="#15296B"/><rect x="230" y="25" width="70" height="60" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><circle cx="265" cy="55" r="14" fill="#E8A317"/><rect x="60" y="110" width="170" height="12" fill="#1E3A8C"/><rect x="70" y="122" width="10" height="33" fill="#0F1839"/><rect x="210" y="122" width="10" height="33" fill="#0F1839"/><ellipse cx="105" cy="105" rx="16" ry="8" fill="#FFFFFF"/><ellipse cx="185" cy="105" rx="16" ry="8" fill="#FFFFFF"/><ellipse cx="145" cy="103" rx="14" ry="6" fill="#E8A317"/><circle cx="105" cy="70" r="13" fill="#0F1839"/><rect x="97" y="82" width="16" height="28" fill="#1E3A8C"/><circle cx="185" cy="70" r="13" fill="#E8A317"/><rect x="177" y="82" width="16" height="28" fill="#168F5B"/></svg>',
   NULL,
   'Le matin, deux personnes sont assises à une table de petit-déjeuner avec des bols et un croissant ; le soleil entre par la fenêtre.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Ils regardent un film au salon.
B. Ils font leurs devoirs ensemble.
C. Ils jardinent derrière la maison.
D. Ils prennent le petit-déjeuner.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ils regardent un film au salon.<break time="700ms"/>B.<break time="300ms"/>Ils font leurs devoirs ensemble.<break time="700ms"/>C.<break time="300ms"/>Ils jardinent derrière la maison.<break time="700ms"/>D.<break time="300ms"/>Ils prennent le petit-déjeuner.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre deux personnes à table le matin, avec des bols et un croissant : c''est **le petit-déjeuner**. Seule D correspond à la scène. A (regarder un film) se passerait devant un écran au salon, B (faire les devoirs) montrerait des cahiers et des stylos, C (jardiner) se passerait dehors avec des outils de jardin.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 2. [Format A] Au marché : une cliente achète des légumes pour cuisiner
  -- ----------------------------------------------------------------------------
  ('66666666-a001-1000-0000-000000000002', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="20" y="55" width="150" height="14" fill="#168F5B"/><rect x="22" y="69" width="6" height="91" fill="#0F1839"/><rect x="162" y="69" width="6" height="91" fill="#0F1839"/><rect x="30" y="105" width="130" height="55" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="40" y="112" width="50" height="18" fill="#E8A317"/><circle cx="50" cy="110" r="7" fill="#168F5B"/><circle cx="64" cy="110" r="7" fill="#0F6E45"/><circle cx="78" cy="110" r="7" fill="#168F5B"/><rect x="100" y="112" width="50" height="18" fill="#FDECEB"/><circle cx="110" cy="110" r="7" fill="#E8A317"/><circle cx="124" cy="110" r="7" fill="#E8A317"/><circle cx="138" cy="110" r="7" fill="#E8A317"/><circle cx="95" cy="86" r="11" fill="#0F1839"/><circle cx="240" cy="92" r="13" fill="#E8A317"/><rect x="231" y="104" width="18" height="40" fill="#1E3A8C"/><rect x="255" y="125" width="28" height="20" rx="3" fill="#0F6E45"/><path d="M 255 125 Q 269 110 283 125" stroke="#0F1839" stroke-width="3" fill="none"/><ellipse cx="269" cy="122" rx="9" ry="4" fill="#E8A317"/></svg>',
   NULL,
   'Au marché, une cliente avec un panier achète des légumes et des fruits à un étal couvert d''un auvent vert.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle poste une lettre au bureau de poste.
B. Elle achète des légumes pour la soupe.
C. Elle essaie des chaussures au magasin.
D. Elle emprunte un roman à la médiathèque.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle poste une lettre au bureau de poste.<break time="700ms"/>B.<break time="300ms"/>Elle achète des légumes pour la soupe.<break time="700ms"/>C.<break time="300ms"/>Elle essaie des chaussures au magasin.<break time="700ms"/>D.<break time="300ms"/>Elle emprunte un roman à la médiathèque.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une cliente, panier à la main, devant un étal de légumes et de fruits : elle **achète de quoi cuisiner**. Seule B correspond. A (poster une lettre) décrirait un bureau de poste, C (essayer des chaussures) un magasin de chaussures, D (emprunter un roman) une médiathèque — aucun de ces lieux n''est représenté.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 3. [Format A] Recette : un homme cuisine, casserole qui fume sur la cuisinière
  -- ----------------------------------------------------------------------------
  ('66666666-a001-1000-0000-000000000003', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#FDECEB"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="180" y="95" width="110" height="65" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="195" y="120" width="80" height="32" fill="#E8ECF8" stroke="#1E3A8C" stroke-width="2"/><circle cx="205" cy="105" r="8" fill="#0F1839"/><circle cx="262" cy="105" r="8" fill="#0F1839"/><rect x="228" y="78" width="44" height="20" rx="3" fill="#1E3A8C"/><rect x="272" y="84" width="24" height="6" fill="#0F1839"/><path d="M 240 70 Q 236 60 240 50" stroke="#1E3A8C" stroke-width="3" fill="none"/><path d="M 256 70 Q 260 60 256 50" stroke="#1E3A8C" stroke-width="3" fill="none"/><circle cx="120" cy="75" r="14" fill="#0F1839"/><rect x="108" y="50" width="24" height="14" rx="4" fill="#FFFFFF"/><rect x="108" y="88" width="24" height="50" fill="#168F5B"/><rect x="130" y="95" width="50" height="8" fill="#168F5B"/><rect x="178" y="86" width="6" height="16" fill="#E8A317"/></svg>',
   NULL,
   'Un cuisinier avec une toque prépare un plat dans une cuisine ; une casserole fume sur la cuisinière.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il prépare le repas dans la cuisine.
B. Il répare sa voiture au garage.
C. Il arrose les plantes du balcon.
D. Il repasse ses chemises dans le salon.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il prépare le repas dans la cuisine.<break time="700ms"/>B.<break time="300ms"/>Il répare sa voiture au garage.<break time="700ms"/>C.<break time="300ms"/>Il arrose les plantes du balcon.<break time="700ms"/>D.<break time="300ms"/>Il repasse ses chemises dans le salon.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un homme devant une cuisinière avec une casserole qui fume : il **prépare le repas**. Seule A décrit cette scène. B (réparer une voiture) se passerait dans un garage avec des outils, C (arroser les plantes) sur un balcon avec un arrosoir, D (repasser des chemises) devant une table à repasser.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 4. [Format A] Restaurant simple : le serveur apporte les plats aux clients
  -- ----------------------------------------------------------------------------
  ('66666666-a001-1000-0000-000000000004', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#0F1839"/><rect x="40" y="110" width="110" height="10" fill="#1E3A8C"/><rect x="88" y="120" width="12" height="40" fill="#0F1839"/><ellipse cx="65" cy="107" rx="12" ry="5" fill="#FFFFFF"/><ellipse cx="125" cy="107" rx="12" ry="5" fill="#FFFFFF"/><circle cx="30" cy="85" r="12" fill="#E8A317"/><rect x="22" y="96" width="16" height="30" fill="#1E3A8C"/><circle cx="160" cy="85" r="12" fill="#0F1839"/><rect x="152" y="96" width="16" height="30" fill="#0F6E45"/><circle cx="245" cy="72" r="13" fill="#E8A317"/><rect x="236" y="84" width="18" height="56" fill="#0F1839"/><rect x="210" y="92" width="28" height="7" fill="#0F1839"/><ellipse cx="205" cy="88" rx="22" ry="5" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1"/><path d="M 188 88 A 17 17 0 0 1 222 88 Z" fill="#E8A317"/></svg>',
   NULL,
   'Dans un restaurant, un serveur apporte un plateau avec une cloche dorée à deux clients assis à une table.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Le facteur distribue le courrier.
B. Le professeur corrige des copies.
C. Le serveur apporte les plats aux clients.
D. Le coiffeur lave les cheveux d''une cliente.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le facteur distribue le courrier.<break time="700ms"/>B.<break time="300ms"/>Le professeur corrige des copies.<break time="700ms"/>C.<break time="300ms"/>Le serveur apporte les plats aux clients.<break time="700ms"/>D.<break time="300ms"/>Le coiffeur lave les cheveux d''une cliente.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un serveur qui apporte un plateau à deux clients attablés : c''est **le service au restaurant**. Seule C correspond. A (le facteur) évoquerait une rue et des lettres, B (le professeur) une salle de classe et des copies, D (le coiffeur) un salon de coiffure — aucun de ces métiers n''est représenté.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 5. [Format A] Pique-nique : couverture, panier et bouteille dans l'herbe
  -- ----------------------------------------------------------------------------
  ('66666666-a001-1000-0000-000000000005', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="110" width="320" height="90" fill="#168F5B"/><circle cx="55" cy="65" r="32" fill="#0F6E45"/><rect x="50" y="88" width="10" height="40" fill="#15296B"/><rect x="120" y="140" width="150" height="42" fill="#FDECEB"/><rect x="175" y="118" width="34" height="24" rx="3" fill="#E8A317"/><path d="M 175 118 Q 192 100 209 118" stroke="#0F1839" stroke-width="3" fill="none"/><rect x="216" y="112" width="8" height="22" fill="#0F6E45"/><circle cx="240" cy="152" r="9" fill="#FFFFFF"/><circle cx="140" cy="115" r="12" fill="#0F1839"/><rect x="132" y="126" width="16" height="26" fill="#1E3A8C"/><circle cx="255" cy="115" r="12" fill="#E8A317"/><rect x="247" y="126" width="16" height="26" fill="#15296B"/></svg>',
   NULL,
   'Deux personnes pique-niquent sur une couverture dans l''herbe, près d''un arbre, avec un panier, une bouteille et une assiette.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Ils déménagent leurs cartons.
B. Ils pique-niquent sur l''herbe.
C. Ils attendent le train sur le quai.
D. Ils visitent un musée d''art.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ils déménagent leurs cartons.<break time="700ms"/>B.<break time="300ms"/>Ils pique-niquent sur l''herbe.<break time="700ms"/>C.<break time="300ms"/>Ils attendent le train sur le quai.<break time="700ms"/>D.<break time="300ms"/>Ils visitent un musée d''art.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre deux personnes assises sur une couverture avec un panier de nourriture, dans l''herbe : c''est **un pique-nique**. Seule B correspond. A (déménager) montrerait des cartons et un camion, C (attendre le train) un quai de gare, D (visiter un musée) des tableaux dans une salle d''exposition.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 6. [Format B] « Qu'est-ce que tu prépares pour le dîner ? » (plat) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a001-1000-0000-000000000006', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Qu''est-ce que tu prépares pour le dîner ce soir ?

A. Un poulet au citron avec du riz.
B. Dans la grande casserole bleue.
C. Vers vingt heures, je pense.
D. Pour mes voisins Olena et Diego.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce que tu prépares pour le dîner ce soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un poulet au citron avec du riz.<break time="700ms"/>B.<break time="300ms"/>Dans la grande casserole bleue.<break time="700ms"/>C.<break time="300ms"/>Vers vingt heures, je pense.<break time="700ms"/>D.<break time="300ms"/>Pour mes voisins Olena et Diego.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Qu''est-ce que tu prépares ? » porte sur **le plat cuisiné**. Seule A « un poulet au citron avec du riz » nomme un plat. B indique l''ustensile et répondrait à « dans quoi le fais-tu cuire ? », C donne une heure et répondrait à « quand mange-t-on ? », D désigne les invités et répondrait à « pour qui cuisines-tu ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 7. [Format B] « Où est-ce que tu déjeunes le midi ? » (cantine) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a001-1000-0000-000000000007', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Où est-ce que tu déjeunes le midi, d''habitude ?

A. Un plat de pâtes, souvent.
B. Avec ma collègue Priya.
C. À la cantine de l''entreprise.
D. En trente minutes, pas plus.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Où est-ce que tu déjeunes le midi, d''habitude ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un plat de pâtes, souvent.<break time="700ms"/>B.<break time="300ms"/>Avec ma collègue Priya.<break time="700ms"/>C.<break time="300ms"/>À la cantine de l''entreprise.<break time="700ms"/>D.<break time="300ms"/>En trente minutes, pas plus.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Où est-ce que tu déjeunes ? » porte sur **le lieu du repas**. Seule C « à la cantine de l''entreprise » indique un endroit. A nomme un plat et répondrait à « que manges-tu ? », B désigne une personne et répondrait à « avec qui déjeunes-tu ? », D donne une durée et répondrait à « combien de temps dure ta pause ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 8. [Format B] « Combien coûte le menu du jour ? » (prix) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a001-1000-0000-000000000008', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Combien coûte le menu du jour ?

A. Avec une entrée et un dessert.
B. Treize euros cinquante, boisson comprise.
C. Jusqu''à quatorze heures trente.
D. Au petit restaurant de la place.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Combien coûte le menu du jour ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec une entrée et un dessert.<break time="700ms"/>B.<break time="300ms"/>Treize euros cinquante, boisson comprise.<break time="700ms"/>C.<break time="300ms"/>Jusqu''à quatorze heures trente.<break time="700ms"/>D.<break time="300ms"/>Au petit restaurant de la place.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Combien coûte le menu ? » porte sur **le prix**. Seule B « treize euros cinquante » donne un montant. A décrit la composition du menu et répondrait à « qu''est-ce qu''il comprend ? », C donne un horaire et répondrait à « jusqu''à quelle heure est-il servi ? », D indique le lieu et répondrait à « où le sert-on ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 9. [Format B] « Quand arrivent les invités pour le repas ? » (heure) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a001-1000-0000-000000000009', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Quand est-ce que les invités arrivent pour le repas ?

A. Avec un gâteau au chocolat.
B. Dans la salle à manger.
C. Parce qu''ils aiment ma cuisine.
D. Vers dix-neuf heures trente.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Quand est-ce que les invités arrivent pour le repas ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec un gâteau au chocolat.<break time="700ms"/>B.<break time="300ms"/>Dans la salle à manger.<break time="700ms"/>C.<break time="300ms"/>Parce qu''ils aiment ma cuisine.<break time="700ms"/>D.<break time="300ms"/>Vers dix-neuf heures trente.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Quand est-ce que les invités arrivent ? » porte sur **le moment**. Seule D « vers dix-neuf heures trente » donne une heure. A indique ce qu''ils apportent et répondrait à « avec quoi viennent-ils ? », B donne le lieu et répondrait à « où mange-t-on ? », C exprime une cause et répondrait à « pourquoi viennent-ils ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 10. [Format B] « Qui fait la cuisine chez vous ? » (personne) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a001-1000-0000-00000000000a', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Qui fait la cuisine chez vous, le soir ?

A. C''est Fatou, ma femme, le plus souvent.
B. Des légumes du jardin, en général.
C. Dans une grande poêle noire.
D. Pendant une demi-heure environ.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qui fait la cuisine chez vous, le soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>C''est Fatou, ma femme, le plus souvent.<break time="700ms"/>B.<break time="300ms"/>Des légumes du jardin, en général.<break time="700ms"/>C.<break time="300ms"/>Dans une grande poêle noire.<break time="700ms"/>D.<break time="300ms"/>Pendant une demi-heure environ.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Qui fait la cuisine ? » porte sur **la personne qui cuisine**. Seule A « Fatou, ma femme » désigne quelqu''un. B nomme des aliments et répondrait à « avec quoi cuisine-t-elle ? », C indique l''ustensile et répondrait à « dans quoi cuisine-t-elle ? », D donne une durée et répondrait à « pendant combien de temps ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes '66666666-a001-1000-0000-0000000000NN'
--     (NN = 01..09, 0a), tous uniques.
-- [x] Thème unique « repas & cuisine », 10 scènes toutes différentes :
--     petit-déjeuner, marché (légumes), recette/cuisine, restaurant (service),
--     pique-nique, dîner (plat), cantine (lieu), menu du jour (prix),
--     invités (heure), cuisine familiale (personne). Aucun thème interdit.
-- [x] 5 × format A (co_image_proposition, inline_svg + image_alt_text,
--     SSML mono-voix Denise) + 5 × format B (co_question_reponse,
--     inline_svg/image_alt_text NULL, SSML Denise → Henri (×3) / Vivienne (×2)
--     → Denise).
-- [x] 4 propositions / exactement 1 correcte par item. Distribution des
--     bonnes réponses : A=3 (items 3,6,10), B=3 (items 2,5,8),
--     C=2 (items 4,7), D=2 (items 1,9) — 4 positions utilisées, max 3.
-- [x] Compréhension explicite A2 : bonne réponse littérale, distracteurs
--     nettement distincts (autre lieu / action / moment / personne).
-- [x] explanation ≥ 80 caractères : justifie la bonne réponse ET les 3
--     distracteurs (avec la question à laquelle chacun répondrait), point
--     clé en **gras**.
-- [x] SVG : viewBox 320×200, palette charte uniquement, pas de texte,
--     rouge absent (aucun élément critique requis), scène lisible en < 2 s,
--     alt_text présent sur les 5 CO_IMAGE.
-- [x] SSML : balises <voice>/<prosody> équilibrées, pauses 1500/1000/700/
--     300 ms conformes, voix Denise 0.95 / Henri & Vivienne 1.0.
-- [x] voice_recommended cohérent (Denise format A ; voix de la question
--     format B). status='TEXT_VALIDATED', colonnes audio toutes NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] SQL : apostrophes doublées partout (SSML/SVG/JSONB inclus), JSONB
--     valide. Contenu 100 % original (prénoms variés : Olena, Diego,
--     Priya, Fatou).
-- ============================================================================
