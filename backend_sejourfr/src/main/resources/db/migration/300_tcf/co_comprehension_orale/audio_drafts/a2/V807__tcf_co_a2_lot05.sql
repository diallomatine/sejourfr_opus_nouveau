-- ============================================================================
-- V807 — TCF CO A2 — lot 05 (thème : école & études)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (A2), table audio_question_draft. 10 items, tous dans le
-- thème « école & études », scènes toutes différentes :
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
  -- 1. [Format A] Salle de classe : la professeure écrit au tableau vert
  -- ----------------------------------------------------------------------------
  ('66666666-a005-1000-0000-000000000001', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="35" y="25" width="160" height="90" fill="#0F6E45" stroke="#FFFFFF" stroke-width="4"/><rect x="50" y="42" width="80" height="5" fill="#FFFFFF"/><rect x="50" y="58" width="105" height="5" fill="#FFFFFF"/><rect x="50" y="74" width="60" height="5" fill="#FFFFFF"/><circle cx="215" cy="65" r="13" fill="#0F1839"/><rect x="207" y="77" width="16" height="48" fill="#1E3A8C"/><rect x="196" y="82" width="14" height="6" fill="#1E3A8C"/><rect x="245" y="115" width="60" height="10" fill="#1E3A8C"/><rect x="252" y="125" width="8" height="35" fill="#0F1839"/><rect x="290" y="125" width="8" height="35" fill="#0F1839"/><rect x="255" y="105" width="28" height="8" fill="#FFFFFF"/><circle cx="275" cy="92" r="10" fill="#E8A317"/><rect x="268" y="101" width="14" height="14" fill="#168F5B"/></svg>',
   NULL,
   'Dans une salle de classe, une professeure écrit des lignes blanches sur un grand tableau vert ; un élève est assis à son bureau avec un cahier.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Les élèves nagent à la piscine.
B. La professeure écrit au tableau.
C. Les clients attendent à la caisse.
D. Le jardinier coupe l''herbe du jardin.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Les élèves nagent à la piscine.<break time="700ms"/>B.<break time="300ms"/>La professeure écrit au tableau.<break time="700ms"/>C.<break time="300ms"/>Les clients attendent à la caisse.<break time="700ms"/>D.<break time="300ms"/>Le jardinier coupe l''herbe du jardin.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une salle de classe avec un grand tableau vert couvert de lignes d''écriture et une enseignante debout devant : **la professeure écrit au tableau**. Seule B correspond. A (nager) se passerait dans une piscine avec de l''eau, C (attendre à la caisse) montrerait un magasin et une file de clients, D (couper l''herbe) un jardin avec une tondeuse — rien de tout cela n''est représenté.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 2. [Format A] Bibliothèque : une étudiante lit un livre devant les étagères
  -- ----------------------------------------------------------------------------
  ('66666666-a005-1000-0000-000000000002', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="20" y="25" width="110" height="120" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="28" y="35" width="94" height="6" fill="#1E3A8C"/><rect x="30" y="45" width="10" height="22" fill="#168F5B"/><rect x="44" y="45" width="10" height="22" fill="#E8A317"/><rect x="58" y="45" width="10" height="22" fill="#1E3A8C"/><rect x="72" y="45" width="10" height="22" fill="#0F6E45"/><rect x="86" y="45" width="10" height="22" fill="#E8A317"/><rect x="100" y="45" width="10" height="22" fill="#1E3A8C"/><rect x="28" y="75" width="94" height="6" fill="#1E3A8C"/><rect x="30" y="85" width="10" height="22" fill="#E8A317"/><rect x="44" y="85" width="10" height="22" fill="#1E3A8C"/><rect x="58" y="85" width="10" height="22" fill="#168F5B"/><rect x="72" y="85" width="10" height="22" fill="#E8A317"/><rect x="86" y="85" width="10" height="22" fill="#0F6E45"/><rect x="100" y="85" width="10" height="22" fill="#1E3A8C"/><rect x="28" y="115" width="94" height="6" fill="#1E3A8C"/><rect x="170" y="120" width="120" height="10" fill="#1E3A8C"/><rect x="178" y="130" width="9" height="30" fill="#0F1839"/><rect x="273" y="130" width="9" height="30" fill="#0F1839"/><circle cx="228" cy="78" r="13" fill="#0F1839"/><rect x="219" y="90" width="18" height="30" fill="#168F5B"/><polygon points="206,118 228,110 250,118 250,106 228,98 206,106" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/></svg>',
   NULL,
   'Dans une bibliothèque, une étudiante assise à une table lit un livre ouvert ; derrière elle, une grande étagère pleine de livres colorés.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle achète du pain à la boulangerie.
B. Elle court dans la forêt.
C. Elle lit un livre à la bibliothèque.
D. Elle lave les fenêtres de la maison.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle achète du pain à la boulangerie.<break time="700ms"/>B.<break time="300ms"/>Elle court dans la forêt.<break time="700ms"/>C.<break time="300ms"/>Elle lit un livre à la bibliothèque.<break time="700ms"/>D.<break time="300ms"/>Elle lave les fenêtres de la maison.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une jeune femme assise à une table, un livre ouvert devant elle, avec une étagère remplie de livres : elle **lit à la bibliothèque**. Seule C correspond. A (acheter du pain) montrerait une boulangerie et des baguettes, B (courir) une personne en mouvement dehors, D (laver les fenêtres) une éponge et des vitres — aucune de ces scènes n''apparaît.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 3. [Format A] Cour de récréation : deux enfants jouent au ballon devant l'école
  -- ----------------------------------------------------------------------------
  ('66666666-a005-1000-0000-000000000003', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="150" width="320" height="50" fill="#168F5B"/><rect x="90" y="40" width="140" height="110" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="3"/><polygon points="85,40 160,15 235,40" fill="#1E3A8C"/><rect x="105" y="55" width="22" height="22" fill="#E8ECF8" stroke="#1E3A8C" stroke-width="2"/><rect x="149" y="55" width="22" height="22" fill="#E8ECF8" stroke="#1E3A8C" stroke-width="2"/><rect x="193" y="55" width="22" height="22" fill="#E8ECF8" stroke="#1E3A8C" stroke-width="2"/><rect x="145" y="105" width="30" height="45" fill="#15296B"/><circle cx="48" cy="125" r="11" fill="#0F1839"/><rect x="40" y="135" width="16" height="26" fill="#E8A317"/><circle cx="272" cy="125" r="11" fill="#E8A317"/><rect x="264" y="135" width="16" height="26" fill="#1E3A8C"/><circle cx="160" cy="172" r="12" fill="#E8A317"/><path d="M 148 172 A 12 12 0 0 1 172 172" fill="#1E3A8C"/></svg>',
   NULL,
   'Devant un bâtiment d''école avec un toit bleu et trois fenêtres, deux enfants jouent avec un ballon dans la cour de récréation.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Les enfants jouent au ballon dans la cour de l''école.
B. Les enfants dorment dans leur chambre.
C. Les enfants mangent une glace à la plage.
D. Les enfants peignent un tableau dans le salon.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Les enfants jouent au ballon dans la cour de l''école.<break time="700ms"/>B.<break time="300ms"/>Les enfants dorment dans leur chambre.<break time="700ms"/>C.<break time="300ms"/>Les enfants mangent une glace à la plage.<break time="700ms"/>D.<break time="300ms"/>Les enfants peignent un tableau dans le salon.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre deux enfants et un ballon devant un bâtiment d''école : ils **jouent dans la cour de récréation**. Seule A correspond. B (dormir) se passerait dans une chambre avec un lit, C (manger une glace) à la plage avec la mer, D (peindre) à l''intérieur avec un pinceau et un chevalet — aucun de ces lieux n''est visible.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 4. [Format A] Un garçon prépare son cartable : cahiers, trousse, sac à dos
  -- ----------------------------------------------------------------------------
  ('66666666-a005-1000-0000-000000000004', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#FDECEB"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="60" y="115" width="200" height="12" fill="#1E3A8C"/><rect x="72" y="127" width="10" height="33" fill="#0F1839"/><rect x="238" y="127" width="10" height="33" fill="#0F1839"/><rect x="80" y="95" width="44" height="20" fill="#168F5B"/><rect x="84" y="88" width="44" height="20" fill="#E8A317"/><rect x="140" y="100" width="40" height="12" rx="5" fill="#1E3A8C"/><rect x="195" y="70" width="48" height="45" rx="8" fill="#1E3A8C"/><rect x="205" y="80" width="28" height="20" rx="4" fill="#E8A317"/><path d="M 203 70 Q 219 56 235 70" stroke="#0F1839" stroke-width="4" fill="none"/><circle cx="148" cy="48" r="13" fill="#0F1839"/><rect x="139" y="60" width="18" height="40" fill="#0F6E45"/><rect x="156" y="68" width="34" height="7" fill="#0F6E45"/></svg>',
   NULL,
   'Un garçon debout devant une table pose des cahiers verts et jaunes et une trousse à côté d''un sac à dos bleu ouvert.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il joue de la guitare dans sa chambre.
B. Il promène son chien dans la rue.
C. Il regarde un dessin animé à la télévision.
D. Il prépare son cartable pour l''école.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il joue de la guitare dans sa chambre.<break time="700ms"/>B.<break time="300ms"/>Il promène son chien dans la rue.<break time="700ms"/>C.<break time="300ms"/>Il regarde un dessin animé à la télévision.<break time="700ms"/>D.<break time="300ms"/>Il prépare son cartable pour l''école.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un garçon devant une table avec des cahiers, une trousse et un sac à dos ouvert : il **prépare son cartable**. Seule D décrit cette scène. A (jouer de la guitare) montrerait un instrument de musique, B (promener un chien) une rue et une laisse, C (regarder la télévision) un écran et un canapé — rien de tout cela n''est dessiné.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 5. [Format A] Salle d'examen : deux étudiants écrivent, horloge au mur
  -- ----------------------------------------------------------------------------
  ('66666666-a005-1000-0000-000000000005', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#0F1839"/><circle cx="160" cy="42" r="22" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="3"/><line x1="160" y1="42" x2="160" y2="28" stroke="#0F1839" stroke-width="3"/><line x1="160" y1="42" x2="171" y2="46" stroke="#0F1839" stroke-width="3"/><rect x="35" y="120" width="90" height="10" fill="#1E3A8C"/><rect x="45" y="130" width="8" height="30" fill="#0F1839"/><rect x="107" y="130" width="8" height="30" fill="#0F1839"/><rect x="55" y="110" width="40" height="10" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1"/><circle cx="78" cy="85" r="12" fill="#0F1839"/><rect x="70" y="96" width="16" height="24" fill="#1E3A8C"/><rect x="86" y="106" width="14" height="5" fill="#E8A317"/><rect x="195" y="120" width="90" height="10" fill="#1E3A8C"/><rect x="205" y="130" width="8" height="30" fill="#0F1839"/><rect x="267" y="130" width="8" height="30" fill="#0F1839"/><rect x="215" y="110" width="40" height="10" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1"/><circle cx="238" cy="85" r="12" fill="#E8A317"/><rect x="230" y="96" width="16" height="24" fill="#168F5B"/><rect x="246" y="106" width="14" height="5" fill="#E8A317"/></svg>',
   NULL,
   'Dans une salle silencieuse, deux étudiants assis à des tables séparées écrivent sur des feuilles blanches ; une grande horloge est accrochée au mur.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Ils chantent dans une chorale.
B. Ils passent un examen écrit.
C. Ils plantent des fleurs au jardin.
D. Ils réparent un vélo dans le garage.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ils chantent dans une chorale.<break time="700ms"/>B.<break time="300ms"/>Ils passent un examen écrit.<break time="700ms"/>C.<break time="300ms"/>Ils plantent des fleurs au jardin.<break time="700ms"/>D.<break time="300ms"/>Ils réparent un vélo dans le garage.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre deux étudiants à des tables séparées, qui écrivent sur des feuilles sous une grande horloge : ils **passent un examen écrit**. Seule B correspond. A (chanter) montrerait un groupe debout avec des partitions, C (planter des fleurs) un jardin et de la terre, D (réparer un vélo) des outils et une roue — aucune de ces situations n''est représentée.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 6. [Format B] « Quelle matière est-ce que tu préfères à l'école ? » — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a005-1000-0000-000000000006', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Quelle matière est-ce que tu préfères à l''école ?

A. Dans la salle douze, au premier étage.
B. Avec mon ami Amadou.
C. Les mathématiques, surtout la géométrie.
D. Le mardi et le jeudi après-midi.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle matière est-ce que tu préfères à l''école ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dans la salle douze, au premier étage.<break time="700ms"/>B.<break time="300ms"/>Avec mon ami Amadou.<break time="700ms"/>C.<break time="300ms"/>Les mathématiques, surtout la géométrie.<break time="700ms"/>D.<break time="300ms"/>Le mardi et le jeudi après-midi.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Quelle matière préfères-tu ? » porte sur **la matière scolaire**. Seule C « les mathématiques » nomme une matière. A indique un lieu et répondrait à « où as-tu cours ? », B désigne une personne et répondrait à « avec qui travailles-tu ? », D donne des jours et répondrait à « quand as-tu ce cours ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 7. [Format B] « À quelle heure commencent les cours le matin ? » — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a005-1000-0000-000000000007', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] À quelle heure commencent les cours le matin ?

A. À huit heures et demie.
B. Dans la salle de sciences.
C. Quatre fois par semaine.
D. Avec le professeur Wei.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">À quelle heure commencent les cours le matin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À huit heures et demie.<break time="700ms"/>B.<break time="300ms"/>Dans la salle de sciences.<break time="700ms"/>C.<break time="300ms"/>Quatre fois par semaine.<break time="700ms"/>D.<break time="300ms"/>Avec le professeur Wei.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « À quelle heure commencent les cours ? » porte sur **l''heure**. Seule A « à huit heures et demie » donne un horaire. B indique un lieu et répondrait à « où a lieu le cours ? », C exprime une fréquence et répondrait à « combien de fois par semaine ? », D désigne une personne et répondrait à « avec qui as-tu cours ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 8. [Format B] « Où se trouve la salle d'informatique ? » — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a005-1000-0000-000000000008', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Où se trouve la salle d''informatique, s''il vous plaît ?

A. Pendant une heure et demie.
B. Pour préparer l''exposé de demain.
C. Il y a vingt ordinateurs neufs.
D. Au deuxième étage, à droite de l''escalier.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Où se trouve la salle d''informatique, s''il vous plaît ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant une heure et demie.<break time="700ms"/>B.<break time="300ms"/>Pour préparer l''exposé de demain.<break time="700ms"/>C.<break time="300ms"/>Il y a vingt ordinateurs neufs.<break time="700ms"/>D.<break time="300ms"/>Au deuxième étage, à droite de l''escalier.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Où se trouve la salle d''informatique ? » porte sur **le lieu**. Seule D « au deuxième étage, à droite » donne une localisation. A indique une durée et répondrait à « combien de temps dure la séance ? », B exprime un but et répondrait à « pourquoi y vas-tu ? », C donne une quantité et répondrait à « combien d''ordinateurs y a-t-il ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 9. [Format B] « Combien d'élèves y a-t-il dans ta classe ? » — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a005-1000-0000-000000000009', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Combien d''élèves y a-t-il dans ta classe cette année ?

A. Depuis le mois de septembre.
B. À côté du gymnase de Bordeaux.
C. Vingt-quatre élèves en tout.
D. Ma maîtresse s''appelle Olena.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Combien d''élèves y a-t-il dans ta classe cette année ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis le mois de septembre.<break time="700ms"/>B.<break time="300ms"/>À côté du gymnase de Bordeaux.<break time="700ms"/>C.<break time="300ms"/>Vingt-quatre élèves en tout.<break time="700ms"/>D.<break time="300ms"/>Ma maîtresse s''appelle Olena.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Combien d''élèves y a-t-il ? » porte sur **le nombre**. Seule C « vingt-quatre élèves » donne une quantité. A indique un moment et répondrait à « depuis quand es-tu dans cette classe ? », B donne un lieu et répondrait à « où est ta classe ? », D nomme une personne et répondrait à « comment s''appelle ta maîtresse ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 10. [Format B] « Qui est ton professeur de français ? » — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a005-1000-0000-00000000000a', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Qui est ton professeur de français cette année ?

A. C''est madame Keita, elle est très gentille.
B. Le lundi matin, de neuf heures à onze heures.
C. Dans la salle huit, près de la bibliothèque.
D. Un roman et un dictionnaire de poche.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qui est ton professeur de français cette année ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>C''est madame Keita, elle est très gentille.<break time="700ms"/>B.<break time="300ms"/>Le lundi matin, de neuf heures à onze heures.<break time="700ms"/>C.<break time="300ms"/>Dans la salle huit, près de la bibliothèque.<break time="700ms"/>D.<break time="300ms"/>Un roman et un dictionnaire de poche.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Qui est ton professeur ? » porte sur **la personne**. Seule A « madame Keita » désigne quelqu''un. B donne un horaire et répondrait à « quand as-tu cours de français ? », C indique un lieu et répondrait à « où a lieu le cours ? », D nomme des objets et répondrait à « qu''est-ce que tu dois apporter ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes '66666666-a005-1000-0000-0000000000NN'
--     (NN = 01..09, 0a), tous uniques.
-- [x] Thème unique « école & études », 10 scènes toutes différentes :
--     classe (tableau), bibliothèque (lecture), cour de récréation (ballon),
--     cartable (préparation), examen écrit, matière préférée, horaire des
--     cours, salle d'informatique (lieu), effectif de la classe (nombre),
--     professeur de français (personne). Aucun thème interdit utilisé.
-- [x] 5 × format A (co_image_proposition, inline_svg + image_alt_text,
--     SSML mono-voix Denise) + 5 × format B (co_question_reponse,
--     inline_svg/image_alt_text NULL, SSML Denise → Henri (×3 : items
--     6, 8, 10) / Vivienne (×2 : items 7, 9) → Denise).
-- [x] 4 propositions / exactement 1 correcte par item. Distribution des
--     bonnes réponses : A=3 (items 3,7,10), B=2 (items 1,5),
--     C=3 (items 2,6,9), D=2 (items 4,8) — 4 lettres utilisées, max 3.
-- [x] Compréhension explicite A2 : bonne réponse littérale, distracteurs
--     nettement distincts (autre lieu / action / moment / personne / nombre).
-- [x] explanation ≥ 80 caractères : justifie la bonne réponse ET les 3
--     distracteurs (avec la question à laquelle chacun répondrait), point
--     clé en **gras**.
-- [x] SVG : viewBox 320×200, palette charte uniquement, scène lisible en
--     < 2 s, rouge #E1372F absent de tout rendu (aucun élément critique
--     requis), alt_text présent sur les 5 CO_IMAGE.
-- [x] SSML : balises <voice>/<prosody> équilibrées, pauses 1500/1000/700/
--     300 ms conformes, voix Denise 0.95 / Henri & Vivienne 1.0.
-- [x] voice_recommended cohérent (Denise format A ; voix de la question
--     format B). status='TEXT_VALIDATED', colonnes audio toutes NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] SQL : apostrophes doublées partout (SSML/SVG/JSONB inclus), JSONB
--     valide. Contenu 100 % original (prénoms variés : Amadou, Wei,
--     Olena, Keita).
-- ============================================================================
