-- ============================================================================
-- V808 — TCF CO A2 — lot 06 (thème : maison & logement)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (A2), table audio_question_draft. 10 items, tous dans le
-- thème « maison & logement », scènes toutes différentes :
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
  -- 1. [Format A] Emménagement : camion devant la maison, personne avec un carton
  -- ----------------------------------------------------------------------------
  ('66666666-a006-1000-0000-000000000001', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="210" y="80" width="90" height="80" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><polygon points="205,80 255,45 305,80" fill="#1E3A8C"/><rect x="240" y="115" width="26" height="45" fill="#0F1839"/><rect x="218" y="95" width="18" height="14" fill="#E8ECF8" stroke="#1E3A8C" stroke-width="2"/><rect x="20" y="95" width="90" height="50" fill="#1E3A8C"/><rect x="110" y="110" width="35" height="35" fill="#15296B"/><rect x="116" y="116" width="16" height="12" fill="#E8ECF8"/><circle cx="45" cy="150" r="12" fill="#0F1839"/><circle cx="125" cy="150" r="12" fill="#0F1839"/><rect x="152" y="138" width="24" height="22" fill="#E8A317"/><circle cx="188" cy="98" r="12" fill="#0F1839"/><rect x="180" y="110" width="16" height="40" fill="#168F5B"/><rect x="174" y="116" width="28" height="20" fill="#E8A317"/></svg>',
   NULL,
   'Devant une maison, un camion de déménagement est garé ; une personne porte un carton vers la porte d''entrée, un autre carton est posé au sol.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Ils lavent leur voiture dans la rue.
B. Ils emménagent dans leur nouvelle maison.
C. Ils plantent un arbre devant la porte.
D. Ils réparent le toit de la maison.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ils lavent leur voiture dans la rue.<break time="700ms"/>B.<break time="300ms"/>Ils emménagent dans leur nouvelle maison.<break time="700ms"/>C.<break time="300ms"/>Ils plantent un arbre devant la porte.<break time="700ms"/>D.<break time="300ms"/>Ils réparent le toit de la maison.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un camion de déménagement devant une maison et une personne qui porte un carton : c''est **un emménagement**. Seule B correspond. A (laver une voiture) montrerait un seau et une éponge, C (planter un arbre) une pelle et un jeune arbre, D (réparer le toit) une échelle posée contre la maison et quelqu''un sur le toit.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 2. [Format A] Travaux : un homme peint le mur du salon en bleu (rouleau, pot)
  -- ----------------------------------------------------------------------------
  ('66666666-a006-1000-0000-000000000002', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="170" width="320" height="30" fill="#0F1839"/><rect x="20" y="20" width="120" height="150" fill="#1E3A8C"/><rect x="140" y="20" width="160" height="150" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="148" y="58" width="28" height="14" rx="6" fill="#E8A317"/><line x1="176" y1="72" x2="196" y2="100" stroke="#0F1839" stroke-width="4"/><circle cx="206" cy="110" r="13" fill="#E8A317"/><rect x="197" y="123" width="18" height="44" fill="#0F6E45"/><rect x="245" y="140" width="30" height="28" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><ellipse cx="260" cy="140" rx="15" ry="4" fill="#1E3A8C"/></svg>',
   NULL,
   'Dans un salon, un homme tient un rouleau et peint le mur en bleu ; la moitié du mur est déjà peinte, un pot de peinture est posé au sol.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il accroche des rideaux à la fenêtre.
B. Il nettoie les vitres du salon.
C. Il monte une étagère avec des outils.
D. Il peint le mur du salon en bleu.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il accroche des rideaux à la fenêtre.<break time="700ms"/>B.<break time="300ms"/>Il nettoie les vitres du salon.<break time="700ms"/>C.<break time="300ms"/>Il monte une étagère avec des outils.<break time="700ms"/>D.<break time="300ms"/>Il peint le mur du salon en bleu.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un homme avec un rouleau, un mur à moitié peint en bleu et un pot de peinture : il **peint le mur**. Seule D correspond. A (accrocher des rideaux) montrerait une fenêtre et du tissu, B (nettoyer les vitres) un chiffon et une vitre, C (monter une étagère) des planches, des vis et un tournevis — rien de tout cela n''apparaît.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 3. [Format A] Balcon : une femme arrose ses plantes en pot avec un arrosoir
  -- ----------------------------------------------------------------------------
  ('66666666-a006-1000-0000-000000000003', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><circle cx="282" cy="38" r="18" fill="#E8A317"/><rect x="0" y="150" width="320" height="50" fill="#15296B"/><rect x="20" y="110" width="280" height="8" fill="#1E3A8C"/><rect x="32" y="118" width="6" height="32" fill="#1E3A8C"/><rect x="86" y="118" width="6" height="32" fill="#1E3A8C"/><rect x="140" y="118" width="6" height="32" fill="#1E3A8C"/><rect x="194" y="118" width="6" height="32" fill="#1E3A8C"/><rect x="248" y="118" width="6" height="32" fill="#1E3A8C"/><rect x="200" y="126" width="24" height="24" fill="#E8A317"/><circle cx="212" cy="116" r="12" fill="#168F5B"/><rect x="252" y="126" width="24" height="24" fill="#E8A317"/><circle cx="264" cy="114" r="13" fill="#0F6E45"/><circle cx="100" cy="76" r="13" fill="#0F1839"/><rect x="92" y="89" width="17" height="48" fill="#1E3A8C"/><rect x="118" y="100" width="26" height="18" rx="3" fill="#0F6E45"/><line x1="144" y1="104" x2="162" y2="96" stroke="#0F6E45" stroke-width="5"/><circle cx="170" cy="104" r="3" fill="#1E3A8C"/><circle cx="174" cy="113" r="3" fill="#1E3A8C"/></svg>',
   NULL,
   'Sur un balcon avec une balustrade bleue, une femme arrose deux plantes en pot avec un arrosoir vert ; le soleil brille.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle arrose les plantes de son balcon.
B. Elle étend son linge sur un fil.
C. Elle balaie l''entrée de l''immeuble.
D. Elle lit un magazine dans sa chambre.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle arrose les plantes de son balcon.<break time="700ms"/>B.<break time="300ms"/>Elle étend son linge sur un fil.<break time="700ms"/>C.<break time="300ms"/>Elle balaie l''entrée de l''immeuble.<break time="700ms"/>D.<break time="300ms"/>Elle lit un magazine dans sa chambre.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une femme sur un balcon, un arrosoir à la main, devant des plantes en pot : elle **arrose ses plantes**. Seule A correspond. B (étendre le linge) montrerait un fil et des vêtements suspendus, C (balayer l''entrée) un balai dans un hall d''immeuble, D (lire un magazine) une personne assise à l''intérieur avec un magazine.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 4. [Format A] Ménage : un homme passe l'aspirateur dans le salon (canapé, tapis)
  -- ----------------------------------------------------------------------------
  ('66666666-a006-1000-0000-000000000004', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#FDECEB"/><rect x="0" y="155" width="320" height="45" fill="#15296B"/><rect x="30" y="25" width="60" height="45" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="200" y="80" width="100" height="26" rx="8" fill="#15296B"/><rect x="200" y="100" width="100" height="40" rx="8" fill="#1E3A8C"/><rect x="206" y="140" width="10" height="15" fill="#0F1839"/><rect x="284" y="140" width="10" height="15" fill="#0F1839"/><ellipse cx="110" cy="160" rx="70" ry="12" fill="#E8A317"/><circle cx="80" cy="78" r="13" fill="#E8A317"/><rect x="72" y="91" width="17" height="48" fill="#0F6E45"/><line x1="92" y1="112" x2="130" y2="150" stroke="#0F1839" stroke-width="5"/><circle cx="116" cy="148" r="9" fill="#1E3A8C"/><ellipse cx="138" cy="154" rx="16" ry="7" fill="#0F1839"/></svg>',
   NULL,
   'Dans un salon avec un canapé bleu et un tapis, un homme passe l''aspirateur sur le sol.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il range la vaisselle dans le placard.
B. Il déplace le canapé du salon.
C. Il passe l''aspirateur dans le salon.
D. Il dort sur le canapé du salon.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il range la vaisselle dans le placard.<break time="700ms"/>B.<break time="300ms"/>Il déplace le canapé du salon.<break time="700ms"/>C.<break time="300ms"/>Il passe l''aspirateur dans le salon.<break time="700ms"/>D.<break time="300ms"/>Il dort sur le canapé du salon.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un homme debout qui tient le tube d''un aspirateur posé sur le sol du salon : il **fait le ménage avec l''aspirateur**. Seule C correspond. A (ranger la vaisselle) montrerait des assiettes et un placard de cuisine, B (déplacer le canapé) un homme qui pousse ou soulève le meuble, D (dormir) une personne allongée sur le canapé — ici il est debout.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 5. [Format A] Plomberie : un plombier répare le lavabo qui fuit (salle de bains)
  -- ----------------------------------------------------------------------------
  ('66666666-a006-1000-0000-000000000005', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="165" width="320" height="35" fill="#15296B"/><rect x="190" y="25" width="60" height="45" rx="4" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="186" y="98" width="68" height="22" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="210" y="120" width="20" height="45" fill="#E8ECF8" stroke="#1E3A8C" stroke-width="2"/><rect x="216" y="84" width="8" height="14" fill="#0F1839"/><rect x="216" y="80" width="18" height="6" fill="#0F1839"/><circle cx="244" cy="134" r="3" fill="#1E3A8C"/><circle cx="248" cy="147" r="3" fill="#1E3A8C"/><circle cx="244" cy="159" r="3" fill="#1E3A8C"/><circle cx="120" cy="105" r="13" fill="#0F1839"/><rect x="110" y="118" width="20" height="36" fill="#1E3A8C"/><line x1="132" y1="130" x2="170" y2="140" stroke="#0F1839" stroke-width="5"/><circle cx="174" cy="141" r="6" fill="#0F1839"/><rect x="56" y="142" width="36" height="22" rx="3" fill="#E8A317"/><path d="M 56 142 Q 74 130 92 142" stroke="#0F1839" stroke-width="3" fill="none"/></svg>',
   NULL,
   'Dans une salle de bains, un plombier accroupi avec une clé répare un lavabo qui fuit ; des gouttes d''eau tombent, une boîte à outils est posée au sol.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il prend une douche bien chaude.
B. Il répare le lavabo de la salle de bains.
C. Il se brosse les dents devant le miroir.
D. Il peint la porte de la salle de bains.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il prend une douche bien chaude.<break time="700ms"/>B.<break time="300ms"/>Il répare le lavabo de la salle de bains.<break time="700ms"/>C.<break time="300ms"/>Il se brosse les dents devant le miroir.<break time="700ms"/>D.<break time="300ms"/>Il peint la porte de la salle de bains.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un homme accroupi sous un lavabo qui fuit, une clé à la main et une boîte à outils au sol : il **répare le lavabo**. Seule B correspond. A (prendre une douche) montrerait une cabine de douche et de l''eau qui coule d''en haut, C (se brosser les dents) une personne debout face au miroir avec une brosse, D (peindre la porte) un pinceau et un pot de peinture.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 6. [Format B] « À quel étage est-ce que tu habites ? » (étage) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a006-1000-0000-000000000006', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] À quel étage est-ce que tu habites ?

A. Au quatrième étage, sans ascenseur.
B. Six cent vingt euros par mois.
C. Depuis le mois de janvier.
D. Avec mon frère Amadou.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">À quel étage est-ce que tu habites ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au quatrième étage, sans ascenseur.<break time="700ms"/>B.<break time="300ms"/>Six cent vingt euros par mois.<break time="700ms"/>C.<break time="300ms"/>Depuis le mois de janvier.<break time="700ms"/>D.<break time="300ms"/>Avec mon frère Amadou.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « À quel étage est-ce que tu habites ? » porte sur **l''étage du logement**. Seule A « au quatrième étage » donne un étage. B donne un montant et répondrait à « combien coûte ton loyer ? », C donne une date et répondrait à « depuis quand habites-tu ici ? », D désigne une personne et répondrait à « avec qui habites-tu ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 7. [Format B] « Combien de pièces a ton nouvel appartement ? » (pièces) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a006-1000-0000-000000000007', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Combien de pièces a ton nouvel appartement ?

A. Dans un quartier calme, près du centre.
B. Huit cents euros, charges comprises.
C. Trois pièces et une petite cuisine.
D. Le mois prochain, après les travaux.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Combien de pièces a ton nouvel appartement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dans un quartier calme, près du centre.<break time="700ms"/>B.<break time="300ms"/>Huit cents euros, charges comprises.<break time="700ms"/>C.<break time="300ms"/>Trois pièces et une petite cuisine.<break time="700ms"/>D.<break time="300ms"/>Le mois prochain, après les travaux.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Combien de pièces ? » porte sur **le nombre de pièces du logement**. Seule C « trois pièces et une petite cuisine » donne ce nombre. A indique le lieu et répondrait à « où se trouve ton appartement ? », B donne le prix et répondrait à « combien coûte le loyer ? », D donne un moment et répondrait à « quand est-ce que tu déménages ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 8. [Format B] « Quand est-ce que je peux visiter le studio ? » (moment) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a006-1000-0000-000000000008', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Quand est-ce que je peux visiter le studio ?

A. Au deuxième étage de l''immeuble.
B. Vingt-cinq mètres carrés environ.
C. Avec madame Lucia, la propriétaire.
D. Samedi matin, à dix heures.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Quand est-ce que je peux visiter le studio ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au deuxième étage de l''immeuble.<break time="700ms"/>B.<break time="300ms"/>Vingt-cinq mètres carrés environ.<break time="700ms"/>C.<break time="300ms"/>Avec madame Lucia, la propriétaire.<break time="700ms"/>D.<break time="300ms"/>Samedi matin, à dix heures.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Quand est-ce que je peux visiter ? » porte sur **le moment de la visite**. Seule D « samedi matin, à dix heures » donne un jour et une heure. A indique un étage et répondrait à « où se trouve le studio ? », B donne la surface et répondrait à « quelle est sa taille ? », C désigne une personne et répondrait à « avec qui se fait la visite ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 9. [Format B] « Combien coûte le loyer de cette maison ? » (prix) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a006-1000-0000-000000000009', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Combien coûte le loyer de cette maison ?

A. Quatre chambres et un grand garage.
B. Neuf cent cinquante euros par mois.
C. Dans une petite rue très calme.
D. À partir du premier septembre.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Combien coûte le loyer de cette maison ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Quatre chambres et un grand garage.<break time="700ms"/>B.<break time="300ms"/>Neuf cent cinquante euros par mois.<break time="700ms"/>C.<break time="300ms"/>Dans une petite rue très calme.<break time="700ms"/>D.<break time="300ms"/>À partir du premier septembre.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Combien coûte le loyer ? » porte sur **le prix du logement**. Seule B « neuf cent cinquante euros par mois » donne un montant. A décrit la composition de la maison et répondrait à « comment est-elle ? », C indique le lieu et répondrait à « où se trouve-t-elle ? », D donne une date et répondrait à « quand est-elle disponible ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 10. [Format B] « Pourquoi cherches-tu un nouveau logement ? » (cause) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a006-1000-0000-00000000000a', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Pourquoi est-ce que tu cherches un nouveau logement ?

A. Parce que mon appartement est trop petit.
B. Dans le sud de la ville, je pense.
C. Avec mon cousin Rachid, peut-être.
D. Avant la fin de l''été, j''espère.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Pourquoi est-ce que tu cherches un nouveau logement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce que mon appartement est trop petit.<break time="700ms"/>B.<break time="300ms"/>Dans le sud de la ville, je pense.<break time="700ms"/>C.<break time="300ms"/>Avec mon cousin Rachid, peut-être.<break time="700ms"/>D.<break time="300ms"/>Avant la fin de l''été, j''espère.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Pourquoi est-ce que tu cherches un nouveau logement ? » demande **une cause**. Seule A, introduite par « parce que », donne une raison : l''appartement est trop petit. B indique un lieu et répondrait à « où veux-tu habiter ? », C désigne une personne et répondrait à « avec qui veux-tu habiter ? », D donne un moment et répondrait à « quand veux-tu déménager ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes '66666666-a006-1000-0000-0000000000NN'
--     (NN = 01..09, 0a), tous uniques.
-- [x] Thème unique « maison & logement », 10 scènes toutes différentes :
--     emménagement (camion + cartons), peinture du salon, plantes du balcon,
--     aspirateur au salon, réparation du lavabo, étage habité, nombre de
--     pièces, visite d'un studio (moment), loyer (prix), recherche de
--     logement (cause). Aucun thème interdit (pas de repas, transports,
--     commerces, santé, école, loisirs, météo, travail, famille, services,
--     voyages, fêtes, nature).
-- [x] 5 × format A (co_image_proposition, inline_svg + image_alt_text,
--     SSML mono-voix Denise) + 5 × format B (co_question_reponse,
--     inline_svg/image_alt_text NULL, SSML Denise → Vivienne (×3) /
--     Henri (×2) → Denise).
-- [x] 4 propositions / exactement 1 correcte par item. Distribution des
--     bonnes réponses : A=3 (items 3,6,10), B=3 (items 1,5,9),
--     C=2 (items 4,7), D=2 (items 2,8) — 4 lettres utilisées, max 3.
-- [x] Compréhension explicite A2 : bonne réponse littérale, distracteurs
--     nettement distincts (autre lieu / action / moment / personne / prix).
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
--     valide. Contenu 100 % original (prénoms variés : Amadou, Lucia,
--     Rachid).
-- ============================================================================
