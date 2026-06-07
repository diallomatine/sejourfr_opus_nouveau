-- ============================================================================
-- V809 — TCF CO A2 — lot 07 (thème : loisirs & sport)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (A2), table audio_question_draft. 10 items, tous dans le
-- thème « loisirs & sport », scènes toutes différentes :
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
  -- 1. [Format A] Piscine : une nageuse traverse le bassin entre les lignes d'eau
  -- ----------------------------------------------------------------------------
  ('66666666-a007-1000-0000-000000000001', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="80" width="320" height="120" fill="#1E3A8C"/><rect x="0" y="118" width="320" height="3" fill="#FFFFFF"/><rect x="0" y="158" width="320" height="3" fill="#FFFFFF"/><circle cx="150" cy="103" r="12" fill="#E8A317"/><path d="M 162 106 Q 180 86 198 104" stroke="#E8A317" stroke-width="7" fill="none"/><ellipse cx="124" cy="110" rx="16" ry="5" fill="#FFFFFF"/><ellipse cx="206" cy="110" rx="12" ry="4" fill="#FFFFFF"/><rect x="284" y="58" width="6" height="62" fill="#0F1839"/><rect x="302" y="58" width="6" height="62" fill="#0F1839"/><rect x="284" y="70" width="24" height="5" fill="#0F1839"/><rect x="284" y="90" width="24" height="5" fill="#0F1839"/></svg>',
   NULL,
   'Une nageuse traverse une piscine entre deux lignes d''eau ; sa tête et son bras sortent de l''eau, une échelle est fixée au bord.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle fait ses courses au supermarché.
B. Elle conduit un bus en ville.
C. Elle nage à la piscine.
D. Elle peint le mur de sa chambre.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle fait ses courses au supermarché.<break time="700ms"/>B.<break time="300ms"/>Elle conduit un bus en ville.<break time="700ms"/>C.<break time="300ms"/>Elle nage à la piscine.<break time="700ms"/>D.<break time="300ms"/>Elle peint le mur de sa chambre.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une nageuse dans l''eau, entre des lignes de bassin, avec une échelle au bord : elle **nage à la piscine**. Seule C correspond à la scène. A (faire les courses) montrerait un chariot et des rayons de magasin, B (conduire un bus) un volant et des passagers, D (peindre un mur) un rouleau et un pot de peinture dans une chambre.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 2. [Format A] Football : un joueur tire le ballon vers le but sur la pelouse
  -- ----------------------------------------------------------------------------
  ('66666666-a007-1000-0000-000000000002', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="125" width="320" height="75" fill="#168F5B"/><rect x="225" y="55" width="6" height="80" fill="#FFFFFF"/><rect x="304" y="55" width="6" height="80" fill="#FFFFFF"/><rect x="225" y="55" width="85" height="6" fill="#FFFFFF"/><circle cx="85" cy="75" r="13" fill="#0F1839"/><rect x="74" y="89" width="22" height="34" rx="4" fill="#1E3A8C"/><rect x="74" y="123" width="9" height="26" fill="#0F1839"/><path d="M 92 123 L 118 138" stroke="#0F1839" stroke-width="9" fill="none"/><circle cx="152" cy="142" r="11" fill="#FFFFFF"/><polygon points="152,136 158,141 155,148 149,148 146,141" fill="#0F1839"/><line x1="168" y1="140" x2="194" y2="137" stroke="#FFFFFF" stroke-width="3"/></svg>',
   NULL,
   'Sur une pelouse, un footballeur en maillot bleu tire un ballon blanc et noir vers un but blanc.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il joue au football sur le terrain.
B. Il promène son chien.
C. Il répare son vélo.
D. Il achète du pain à la boulangerie.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il joue au football sur le terrain.<break time="700ms"/>B.<break time="300ms"/>Il promène son chien.<break time="700ms"/>C.<break time="300ms"/>Il répare son vélo.<break time="700ms"/>D.<break time="300ms"/>Il achète du pain à la boulangerie.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un joueur qui frappe un ballon en direction d''un but, sur une pelouse : il **joue au football**. Seule A décrit cette scène. B (promener un chien) montrerait un animal en laisse, C (réparer un vélo) des outils et une roue, D (acheter du pain) le comptoir d''une boulangerie — rien de tout cela n''apparaît.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 3. [Format A] Tennis : deux joueuses échangent une balle au-dessus du filet
  -- ----------------------------------------------------------------------------
  ('66666666-a007-1000-0000-000000000003', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="125" width="320" height="75" fill="#0F6E45"/><rect x="154" y="88" width="12" height="72" fill="#FFFFFF" stroke="#0F1839" stroke-width="2"/><circle cx="60" cy="80" r="12" fill="#E8A317"/><rect x="50" y="93" width="20" height="34" fill="#1E3A8C"/><line x1="70" y1="100" x2="92" y2="82" stroke="#0F1839" stroke-width="5"/><ellipse cx="98" cy="76" rx="11" ry="14" fill="#FFFFFF" stroke="#0F1839" stroke-width="3"/><circle cx="255" cy="82" r="12" fill="#0F1839"/><rect x="245" y="95" width="20" height="32" fill="#168F5B"/><line x1="245" y1="102" x2="224" y2="86" stroke="#0F1839" stroke-width="5"/><ellipse cx="218" cy="80" rx="11" ry="14" fill="#FFFFFF" stroke="#0F1839" stroke-width="3"/><circle cx="160" cy="55" r="7" fill="#E8A317"/></svg>',
   NULL,
   'Sur un court vert, deux joueuses avec des raquettes échangent une balle jaune au-dessus d''un filet blanc.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elles dansent dans un studio.
B. Elles font de la couture ensemble.
C. Elles chantent dans une chorale.
D. Elles jouent au tennis.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elles dansent dans un studio.<break time="700ms"/>B.<break time="300ms"/>Elles font de la couture ensemble.<break time="700ms"/>C.<break time="300ms"/>Elles chantent dans une chorale.<break time="700ms"/>D.<break time="300ms"/>Elles jouent au tennis.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre deux joueuses de part et d''autre d''un filet, raquettes en main, avec une balle en l''air : elles **jouent au tennis**. Seule D correspond. A (danser) montrerait un studio sans raquettes ni filet, B (coudre) du tissu et une machine à coudre, C (chanter) des partitions et un groupe de choristes.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 4. [Format A] Musique : un homme assis sur un tabouret joue de la guitare
  -- ----------------------------------------------------------------------------
  ('66666666-a007-1000-0000-000000000004', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#FDECEB"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="118" y="122" width="64" height="9" fill="#0F1839"/><rect x="126" y="131" width="8" height="29" fill="#0F1839"/><rect x="166" y="131" width="8" height="29" fill="#0F1839"/><circle cx="148" cy="56" r="14" fill="#0F1839"/><rect x="135" y="71" width="26" height="52" rx="6" fill="#168F5B"/><ellipse cx="172" cy="104" rx="24" ry="19" fill="#E8A317"/><circle cx="172" cy="104" r="6" fill="#0F1839"/><line x1="190" y1="94" x2="242" y2="62" stroke="#0F1839" stroke-width="7"/><rect x="238" y="50" width="16" height="14" rx="2" fill="#0F1839"/><circle cx="262" cy="38" r="5" fill="#1E3A8C"/><rect x="265" y="20" width="3" height="18" fill="#1E3A8C"/><circle cx="285" cy="30" r="5" fill="#1E3A8C"/><rect x="288" y="12" width="3" height="18" fill="#1E3A8C"/></svg>',
   NULL,
   'Un homme assis sur un tabouret joue de la guitare ; des notes de musique flottent au-dessus de l''instrument.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il écrit une lettre à sa sœur.
B. Il joue de la guitare.
C. Il coupe du bois dans la cour.
D. Il téléphone à un ami.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il écrit une lettre à sa sœur.<break time="700ms"/>B.<break time="300ms"/>Il joue de la guitare.<break time="700ms"/>C.<break time="300ms"/>Il coupe du bois dans la cour.<break time="700ms"/>D.<break time="300ms"/>Il téléphone à un ami.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un homme assis avec une guitare dans les bras et des notes de musique au-dessus : il **joue de la guitare**. Seule B correspond. A (écrire une lettre) montrerait un stylo et du papier sur un bureau, C (couper du bois) une hache et des bûches dehors, D (téléphoner) un téléphone contre l''oreille.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 5. [Format A] Loisir créatif : une femme peint un tableau sur un chevalet
  -- ----------------------------------------------------------------------------
  ('66666666-a007-1000-0000-000000000005', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="162" width="320" height="38" fill="#15296B"/><line x1="180" y1="62" x2="162" y2="162" stroke="#0F1839" stroke-width="5"/><line x1="250" y1="62" x2="268" y2="162" stroke="#0F1839" stroke-width="5"/><rect x="170" y="55" width="90" height="66" fill="#FFFFFF" stroke="#0F1839" stroke-width="3"/><circle cx="240" cy="74" r="10" fill="#E8A317"/><path d="M 173 112 Q 200 88 228 112 L 257 112 L 257 118 L 173 118 Z" fill="#168F5B"/><circle cx="85" cy="68" r="13" fill="#0F1839"/><rect x="73" y="82" width="24" height="50" rx="5" fill="#1E3A8C"/><line x1="97" y1="95" x2="150" y2="84" stroke="#E8A317" stroke-width="6"/><rect x="148" y="78" width="6" height="12" fill="#168F5B"/><ellipse cx="58" cy="112" rx="16" ry="10" fill="#FFFFFF" stroke="#0F1839" stroke-width="2"/><circle cx="52" cy="110" r="3" fill="#168F5B"/><circle cx="62" cy="108" r="3" fill="#E8A317"/><circle cx="58" cy="116" r="3" fill="#1E3A8C"/></svg>',
   NULL,
   'Une femme, palette de couleurs à la main, peint un paysage avec un soleil et une colline sur une toile posée sur un chevalet.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle recoud un bouton de manteau.
B. Elle photographie des oiseaux.
C. Elle peint un tableau.
D. Elle joue du piano.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle recoud un bouton de manteau.<break time="700ms"/>B.<break time="300ms"/>Elle photographie des oiseaux.<break time="700ms"/>C.<break time="300ms"/>Elle peint un tableau.<break time="700ms"/>D.<break time="300ms"/>Elle joue du piano.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une femme avec un pinceau et une palette devant une toile posée sur un chevalet : elle **peint un tableau**. Seule C correspond. A (recoudre un bouton) montrerait une aiguille et du fil, B (photographier) un appareil photo dirigé vers le ciel, D (jouer du piano) un clavier avec des touches — aucun de ces objets n''est visible.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 6. [Format B] « Quel sport est-ce que tu pratiques le week-end ? » (sport) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a007-1000-0000-000000000006', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Quel sport est-ce que tu pratiques le week-end ?

A. Je joue au basket avec mes amis.
B. Au gymnase, près de chez moi.
C. Le dimanche matin, en général.
D. Depuis trois ans environ.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Quel sport est-ce que tu pratiques le week-end ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Je joue au basket avec mes amis.<break time="700ms"/>B.<break time="300ms"/>Au gymnase, près de chez moi.<break time="700ms"/>C.<break time="300ms"/>Le dimanche matin, en général.<break time="700ms"/>D.<break time="300ms"/>Depuis trois ans environ.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Quel sport est-ce que tu pratiques ? » porte sur **le nom du sport**. Seule A « je joue au basket » nomme une activité sportive. B indique un endroit et répondrait à « où fais-tu du sport ? », C donne un moment et répondrait à « quand t''entraînes-tu ? », D donne une durée et répondrait à « depuis combien de temps en fais-tu ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 7. [Format B] « Où est-ce que tu suis ton cours de judo ? » (lieu) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a007-1000-0000-000000000007', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Où est-ce que tu suis ton cours de judo ?

A. Tous les mercredis soir.
B. Avec mon ami Diego.
C. Une ceinture et un kimono.
D. Au dojo de la rue Pasteur.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Où est-ce que tu suis ton cours de judo ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Tous les mercredis soir.<break time="700ms"/>B.<break time="300ms"/>Avec mon ami Diego.<break time="700ms"/>C.<break time="300ms"/>Une ceinture et un kimono.<break time="700ms"/>D.<break time="300ms"/>Au dojo de la rue Pasteur.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Où est-ce que tu suis ton cours ? » porte sur **le lieu de l''entraînement**. Seule D « au dojo de la rue Pasteur » indique un endroit. A donne une fréquence et répondrait à « quand as-tu cours ? », B désigne une personne et répondrait à « avec qui t''entraînes-tu ? », C nomme l''équipement et répondrait à « que faut-il apporter ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 8. [Format B] « Combien coûte l'entrée de la patinoire ? » (prix) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a007-1000-0000-000000000008', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Combien coûte l''entrée de la patinoire ?

A. Jusqu''à vingt-deux heures le samedi.
B. Six euros cinquante pour les adultes.
C. À dix minutes du centre-ville.
D. Avec mes cousines Priya et Lucia.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Combien coûte l''entrée de la patinoire ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Jusqu''à vingt-deux heures le samedi.<break time="700ms"/>B.<break time="300ms"/>Six euros cinquante pour les adultes.<break time="700ms"/>C.<break time="300ms"/>À dix minutes du centre-ville.<break time="700ms"/>D.<break time="300ms"/>Avec mes cousines Priya et Lucia.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Combien coûte l''entrée ? » porte sur **le prix**. Seule B « six euros cinquante » donne un montant. A donne un horaire et répondrait à « jusqu''à quelle heure est-ce ouvert ? », C indique une distance et répondrait à « où se trouve la patinoire ? », D désigne des personnes et répondrait à « avec qui y vas-tu ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 9. [Format B] « Quand commence le cours de danse ? » (moment) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a007-1000-0000-000000000009', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Quand est-ce que le cours de danse commence ?

A. Mardi prochain, à dix-huit heures.
B. Dans la grande salle du premier étage.
C. Quarante euros par trimestre.
D. Parce que j''adore la musique.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quand est-ce que le cours de danse commence ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Mardi prochain, à dix-huit heures.<break time="700ms"/>B.<break time="300ms"/>Dans la grande salle du premier étage.<break time="700ms"/>C.<break time="300ms"/>Quarante euros par trimestre.<break time="700ms"/>D.<break time="300ms"/>Parce que j''adore la musique.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Quand est-ce que le cours commence ? » porte sur **le moment**. Seule A « mardi prochain, à dix-huit heures » donne une date et une heure. B indique le lieu et répondrait à « où a lieu le cours ? », C donne un prix et répondrait à « combien coûte l''inscription ? », D exprime une cause et répondrait à « pourquoi t''es-tu inscrit ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 10. [Format B] « Avec qui est-ce que tu joues aux échecs ? » (personne) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a007-1000-0000-00000000000a', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Avec qui est-ce que tu joues aux échecs ?

A. Deux fois par semaine.
B. Au café du quartier.
C. Des parties d''une heure environ.
D. Avec mon voisin Amadou.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Avec qui est-ce que tu joues aux échecs ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Deux fois par semaine.<break time="700ms"/>B.<break time="300ms"/>Au café du quartier.<break time="700ms"/>C.<break time="300ms"/>Des parties d''une heure environ.<break time="700ms"/>D.<break time="300ms"/>Avec mon voisin Amadou.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Avec qui est-ce que tu joues ? » porte sur **la personne**. Seule D « avec mon voisin Amadou » désigne quelqu''un. A donne une fréquence et répondrait à « combien de fois joues-tu ? », B indique un lieu et répondrait à « où jouez-vous ? », C donne une durée et répondrait à « combien de temps durent vos parties ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes '66666666-a007-1000-0000-0000000000NN'
--     (NN = 01..09, 0a), tous uniques.
-- [x] Thème unique « loisirs & sport », 10 scènes toutes différentes :
--     natation (piscine), football (terrain), tennis (court), guitare
--     (musique), peinture (chevalet), basket (sport pratiqué), judo (lieu),
--     patinoire (prix), cours de danse (moment), échecs (personne).
--     Aucun thème interdit (pas de repas, transports, commerces, santé,
--     école, maison, météo, travail, famille, services, voyages, fêtes,
--     nature & parc).
-- [x] 5 × format A (co_image_proposition, inline_svg + image_alt_text,
--     SSML mono-voix Denise) + 5 × format B (co_question_reponse,
--     inline_svg/image_alt_text NULL, SSML Denise → Vivienne (×3) /
--     Henri (×2) → Denise).
-- [x] 4 propositions / exactement 1 correcte par item. Distribution des
--     bonnes réponses : A=3 (items 2,6,9), B=2 (items 4,8),
--     C=2 (items 1,5), D=3 (items 3,7,10) — 4 positions utilisées, max 3.
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
--     valide. Contenu 100 % original (prénoms variés : Diego, Priya,
--     Lucia, Amadou).
-- ============================================================================
