-- ============================================================================
-- V812 — TCF CO A2 — lot 10 (thème : famille & quotidien)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (A2), table audio_question_draft. 10 items, tous dans le
-- thème « famille & quotidien », scènes toutes différentes :
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
  -- 1. [Format A] Histoire du soir : un père lit un livre à sa fille couchée
  -- ----------------------------------------------------------------------------
  ('66666666-a00a-1000-0000-000000000001', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="158" width="320" height="42" fill="#15296B"/><rect x="20" y="22" width="66" height="58" fill="#0F1839" stroke="#1E3A8C" stroke-width="2"/><circle cx="53" cy="48" r="11" fill="#E8A317"/><rect x="252" y="90" width="14" height="68" fill="#1E3A8C"/><rect x="120" y="118" width="146" height="26" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="122" y="124" width="98" height="20" fill="#1E3A8C"/><ellipse cx="238" cy="116" rx="18" ry="8" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1"/><circle cx="238" cy="104" r="10" fill="#E8A317"/><rect x="126" y="144" width="8" height="14" fill="#0F1839"/><rect x="250" y="144" width="8" height="14" fill="#0F1839"/><circle cx="85" cy="80" r="13" fill="#0F1839"/><rect x="76" y="93" width="18" height="44" fill="#168F5B"/><path d="M 96 112 Q 108 104 120 112 L 120 126 Q 108 118 96 126 Z" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/></svg>',
   NULL,
   'Le soir, un père assis près du lit lit un livre ouvert à sa fille couchée sous la couverture ; la lune brille par la fenêtre.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Ils regardent la télévision ensemble.
B. Le père lit une histoire à sa fille.
C. Ils jouent au ballon dans le jardin.
D. La fille prend son bain.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ils regardent la télévision ensemble.<break time="700ms"/>B.<break time="300ms"/>Le père lit une histoire à sa fille.<break time="700ms"/>C.<break time="300ms"/>Ils jouent au ballon dans le jardin.<break time="700ms"/>D.<break time="300ms"/>La fille prend son bain.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un père assis près du lit de sa fille, un livre ouvert à la main, la lune visible par la fenêtre : il **lit une histoire avant de dormir**. Seule B correspond. A (regarder la télévision) montrerait un écran dans le salon, C (jouer au ballon) se passerait dehors dans un jardin, D (prendre le bain) montrerait une baignoire dans la salle de bains.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 2. [Format A] Une mère donne le biberon à un bébé dans un fauteuil
  -- ----------------------------------------------------------------------------
  ('66666666-a00a-1000-0000-000000000002', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#FDECEB"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="100" y="90" width="120" height="70" rx="10" fill="#1E3A8C"/><rect x="86" y="103" width="22" height="57" rx="8" fill="#15296B"/><rect x="212" y="103" width="22" height="57" rx="8" fill="#15296B"/><circle cx="155" cy="68" r="14" fill="#0F1839"/><rect x="141" y="82" width="28" height="48" rx="6" fill="#E8A317"/><rect x="165" y="102" width="36" height="14" rx="7" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><circle cx="206" cy="109" r="9" fill="#E8A317"/><rect x="201" y="82" width="10" height="20" rx="3" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="203" y="100" width="6" height="5" fill="#E8A317"/></svg>',
   NULL,
   'Une mère assise dans un grand fauteuil bleu tient un bébé dans ses bras et lui donne le biberon.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle étend le linge sur le balcon.
B. Elle écrit une lettre à sa cousine.
C. Elle promène le chien dans la rue.
D. Elle donne le biberon au bébé.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle étend le linge sur le balcon.<break time="700ms"/>B.<break time="300ms"/>Elle écrit une lettre à sa cousine.<break time="700ms"/>C.<break time="300ms"/>Elle promène le chien dans la rue.<break time="700ms"/>D.<break time="300ms"/>Elle donne le biberon au bébé.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une femme assise dans un fauteuil, un bébé dans les bras et un biberon à la main : elle **donne le biberon**. Seule D correspond. A (étendre le linge) montrerait un fil et des pinces sur un balcon, B (écrire une lettre) du papier et un stylo sur une table, C (promener le chien) une laisse et une rue — rien de tout cela n''est représenté.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 3. [Format A] Appel vidéo : la famille salue la grand-mère sur la tablette
  -- ----------------------------------------------------------------------------
  ('66666666-a00a-1000-0000-000000000003', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="162" width="320" height="38" fill="#15296B"/><rect x="150" y="132" width="150" height="10" fill="#0F1839"/><rect x="160" y="142" width="8" height="20" fill="#0F1839"/><rect x="282" y="142" width="8" height="20" fill="#0F1839"/><rect x="170" y="42" width="116" height="88" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="3"/><rect x="178" y="50" width="100" height="72" fill="#E8ECF8"/><circle cx="228" cy="92" r="18" fill="#E8A317"/><path d="M 210 92 A 18 18 0 0 1 246 92 Z" fill="#FFFFFF"/><rect x="212" y="108" width="32" height="14" fill="#168F5B"/><circle cx="70" cy="78" r="13" fill="#0F1839"/><rect x="61" y="91" width="18" height="52" fill="#1E3A8C"/><rect x="82" y="60" width="7" height="30" fill="#1E3A8C"/><circle cx="115" cy="98" r="10" fill="#E8A317"/><rect x="107" y="108" width="16" height="36" fill="#0F6E45"/></svg>',
   NULL,
   'Deux personnes, un adulte qui lève la main et un enfant, saluent une grand-mère aux cheveux blancs dont le visage apparaît sur l''écran d''une tablette posée sur la table.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Ils écoutent la radio dans la cuisine.
B. Ils peignent les murs du salon.
C. Ils parlent à leur grand-mère en visio.
D. Ils cherchent un livre à la bibliothèque.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ils écoutent la radio dans la cuisine.<break time="700ms"/>B.<break time="300ms"/>Ils peignent les murs du salon.<break time="700ms"/>C.<break time="300ms"/>Ils parlent à leur grand-mère en visio.<break time="700ms"/>D.<break time="300ms"/>Ils cherchent un livre à la bibliothèque.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre deux personnes qui saluent une grand-mère dont le visage apparaît sur l''écran d''une tablette : ils **parlent en visio avec leur grand-mère**. Seule C correspond. A (écouter la radio) ne montrerait pas de visage à l''écran, B (peindre les murs) montrerait des pinceaux et des pots de peinture, D (chercher un livre) des rayonnages de bibliothèque.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 4. [Format A] Routine du soir : deux enfants se brossent les dents au lavabo
  -- ----------------------------------------------------------------------------
  ('66666666-a00a-1000-0000-000000000004', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="162" width="320" height="38" fill="#15296B"/><rect x="115" y="18" width="90" height="56" rx="4" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="3"/><rect x="125" y="112" width="70" height="16" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="152" y="128" width="16" height="34" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="156" y="100" width="8" height="12" fill="#0F1839"/><circle cx="75" cy="88" r="13" fill="#0F1839"/><rect x="66" y="101" width="18" height="50" fill="#168F5B"/><rect x="84" y="88" width="16" height="6" fill="#168F5B"/><rect x="100" y="80" width="4" height="14" fill="#E8A317"/><rect x="98" y="76" width="8" height="5" fill="#FFFFFF"/><circle cx="245" cy="88" r="13" fill="#E8A317"/><rect x="236" y="101" width="18" height="50" fill="#1E3A8C"/><rect x="220" y="88" width="16" height="6" fill="#1E3A8C"/><rect x="216" y="80" width="4" height="14" fill="#0F6E45"/><rect x="214" y="76" width="8" height="5" fill="#FFFFFF"/></svg>',
   NULL,
   'Dans la salle de bains, deux enfants se brossent les dents devant le miroir, de chaque côté du lavabo.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Ils font une bataille d''oreillers.
B. Ils se brossent les dents.
C. Ils plantent des fleurs.
D. Ils écrivent une carte postale.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ils font une bataille d''oreillers.<break time="700ms"/>B.<break time="300ms"/>Ils se brossent les dents.<break time="700ms"/>C.<break time="300ms"/>Ils plantent des fleurs.<break time="700ms"/>D.<break time="300ms"/>Ils écrivent une carte postale.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre deux enfants devant le miroir et le lavabo, une brosse à dents à la main : ils **se brossent les dents**. Seule B correspond. A (une bataille d''oreillers) se passerait dans une chambre avec des oreillers, C (planter des fleurs) dehors avec de la terre et des outils, D (écrire une carte postale) avec du papier et un stylo sur une table.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 5. [Format A] Un père et sa fille plient le linge (drap, panier, pile pliée)
  -- ----------------------------------------------------------------------------
  ('66666666-a00a-1000-0000-000000000005', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#FDECEB"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="112" y="78" width="96" height="40" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><circle cx="88" cy="70" r="13" fill="#0F1839"/><rect x="79" y="83" width="18" height="58" fill="#1E3A8C"/><rect x="97" y="82" width="16" height="6" fill="#1E3A8C"/><circle cx="232" cy="78" r="11" fill="#E8A317"/><rect x="224" y="89" width="16" height="50" fill="#168F5B"/><rect x="208" y="86" width="16" height="6" fill="#168F5B"/><rect x="138" y="130" width="52" height="28" rx="4" fill="#E8A317"/><line x1="152" y1="130" x2="152" y2="158" stroke="#0F1839" stroke-width="2"/><line x1="166" y1="130" x2="166" y2="158" stroke="#0F1839" stroke-width="2"/><line x1="180" y1="130" x2="180" y2="158" stroke="#0F1839" stroke-width="2"/><rect x="258" y="148" width="42" height="10" fill="#168F5B"/><rect x="258" y="138" width="42" height="10" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1"/><rect x="258" y="128" width="42" height="10" fill="#1E3A8C"/></svg>',
   NULL,
   'Un adulte et un enfant tiennent un grand drap blanc au-dessus d''un panier à linge ; à côté, une pile de vêtements pliés.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Ils réparent un vélo.
B. Ils choisissent un cadeau.
C. Ils dessinent ensemble.
D. Ils plient le linge ensemble.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ils réparent un vélo.<break time="700ms"/>B.<break time="300ms"/>Ils choisissent un cadeau.<break time="700ms"/>C.<break time="300ms"/>Ils dessinent ensemble.<break time="700ms"/>D.<break time="300ms"/>Ils plient le linge ensemble.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un adulte et un enfant qui tiennent un drap au-dessus d''un panier à linge, près d''une pile de vêtements pliés : ils **plient le linge**. Seule D correspond. A (réparer un vélo) montrerait un vélo et des outils, B (choisir un cadeau) un paquet ou une vitrine, C (dessiner) des feuilles et des crayons sur une table.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 6. [Format B] « Qui garde les enfants samedi soir ? » (personne) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a00a-1000-0000-000000000006', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Qui garde les enfants samedi soir ?

A. Leur grand-père Rachid, comme d''habitude.
B. Jusqu''à minuit, peut-être.
C. Dans leur chambre, à l''étage.
D. Parce que nous allons au cinéma.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Qui garde les enfants samedi soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Leur grand-père Rachid, comme d''habitude.<break time="700ms"/>B.<break time="300ms"/>Jusqu''à minuit, peut-être.<break time="700ms"/>C.<break time="300ms"/>Dans leur chambre, à l''étage.<break time="700ms"/>D.<break time="300ms"/>Parce que nous allons au cinéma.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Qui garde les enfants ? » porte sur **la personne**. Seule A « leur grand-père Rachid » désigne quelqu''un. B donne une heure et répondrait à « jusqu''à quand sortez-vous ? », C indique un lieu et répondrait à « où dorment-ils ? », D exprime une cause et répondrait à « pourquoi cherchez-vous une garde ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 7. [Format B] « À quelle heure tu réveilles les enfants ? » (heure) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a00a-1000-0000-000000000007', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] À quelle heure est-ce que tu réveilles les enfants, le matin ?

A. En ouvrant doucement les volets.
B. À sept heures moins le quart.
C. Mon mari Diego, le plus souvent.
D. Dans la petite chambre du fond.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">À quelle heure est-ce que tu réveilles les enfants, le matin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En ouvrant doucement les volets.<break time="700ms"/>B.<break time="300ms"/>À sept heures moins le quart.<break time="700ms"/>C.<break time="300ms"/>Mon mari Diego, le plus souvent.<break time="700ms"/>D.<break time="300ms"/>Dans la petite chambre du fond.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « À quelle heure ? » porte sur **l''heure du réveil**. Seule B « à sept heures moins le quart » donne une heure. A décrit la manière et répondrait à « comment les réveilles-tu ? », C désigne une personne et répondrait à « qui les réveille ? », D indique un lieu et répondrait à « où dorment-ils ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 8. [Format B] « Combien de frères et sœurs as-tu ? » (nombre) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a00a-1000-0000-000000000008', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Combien de frères et sœurs est-ce que tu as ?

A. Ils habitent à Marseille.
B. Mon frère aîné s''appelle Amadou.
C. Deux frères et une sœur.
D. On se téléphone une fois par semaine.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Combien de frères et sœurs est-ce que tu as ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ils habitent à Marseille.<break time="700ms"/>B.<break time="300ms"/>Mon frère aîné s''appelle Amadou.<break time="700ms"/>C.<break time="300ms"/>Deux frères et une sœur.<break time="700ms"/>D.<break time="300ms"/>On se téléphone une fois par semaine.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Combien de frères et sœurs ? » demande **un nombre**. Seule C « deux frères et une sœur » donne une quantité. A indique un lieu et répondrait à « où habitent-ils ? », B donne un prénom et répondrait à « comment s''appelle ton frère ? », D exprime une fréquence et répondrait à « vous parlez-vous souvent ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 9. [Format B] « Pourquoi ta sœur ne vient pas dimanche ? » (cause) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a00a-1000-0000-000000000009', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Pourquoi ta sœur Olena ne vient pas dimanche ?

A. Elle arrive d''habitude vers midi.
B. Chez nos parents, à Nantes.
C. Avec son mari et ses deux filles.
D. Parce que son fils est un peu malade.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pourquoi ta sœur Olena ne vient pas dimanche ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle arrive d''habitude vers midi.<break time="700ms"/>B.<break time="300ms"/>Chez nos parents, à Nantes.<break time="700ms"/>C.<break time="300ms"/>Avec son mari et ses deux filles.<break time="700ms"/>D.<break time="300ms"/>Parce que son fils est un peu malade.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Pourquoi ne vient-elle pas ? » demande **une cause**. Seule D « parce que son fils est un peu malade » donne une raison. A indique une heure et répondrait à « quand arrive-t-elle d''habitude ? », B donne un lieu et répondrait à « où la famille se retrouve-t-elle ? », C précise l''accompagnement et répondrait à « avec qui vient-elle ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 10. [Format B] « Que fait ton grand-père tous les matins ? » (action) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a00a-1000-0000-00000000000a', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Qu''est-ce que ton grand-père fait tous les matins ?

A. Il lit son journal dans son fauteuil.
B. Avec ma grand-mère Fatou.
C. Depuis presque dix ans.
D. Au premier étage de l''immeuble.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Qu''est-ce que ton grand-père fait tous les matins ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il lit son journal dans son fauteuil.<break time="700ms"/>B.<break time="300ms"/>Avec ma grand-mère Fatou.<break time="700ms"/>C.<break time="300ms"/>Depuis presque dix ans.<break time="700ms"/>D.<break time="300ms"/>Au premier étage de l''immeuble.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Qu''est-ce qu''il fait ? » porte sur **l''activité**. Seule A « il lit son journal » décrit une action. B désigne une personne et répondrait à « avec qui passe-t-il ses matinées ? », C donne une durée et répondrait à « depuis combien de temps ? », D indique un lieu et répondrait à « où habite-t-il ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes '66666666-a00a-1000-0000-0000000000NN'
--     (NN = 01..09, 0a), tous uniques.
-- [x] Thème unique « famille & quotidien », 10 scènes toutes différentes :
--     histoire du soir, biberon, visio grand-mère, brossage de dents,
--     pliage du linge, garde d'enfants (personne), réveil (heure),
--     fratrie (nombre), absence de la sœur (cause), routine du grand-père
--     (action). Aucun thème interdit (pas de repas, transport, commerce,
--     santé, école, logement, loisirs, météo, travail, services, voyages,
--     fêtes, nature).
-- [x] 5 × format A (co_image_proposition, inline_svg + image_alt_text,
--     SSML mono-voix Denise) + 5 × format B (co_question_reponse,
--     inline_svg/image_alt_text NULL, SSML Denise → Vivienne (×3) /
--     Henri (×2) → Denise).
-- [x] 4 propositions / exactement 1 correcte par item. Distribution des
--     bonnes réponses : A=2 (items 6,10), B=3 (items 1,4,7),
--     C=2 (items 3,8), D=3 (items 2,5,9) — 4 lettres utilisées, max 3.
-- [x] Compréhension explicite A2 : bonne réponse littérale, distracteurs
--     nettement distincts (autre lieu / action / moment / personne / cause).
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
--     valide. Contenu 100 % original (prénoms variés : Rachid, Diego,
--     Amadou, Olena, Fatou).
-- ============================================================================
