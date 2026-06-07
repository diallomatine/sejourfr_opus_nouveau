-- ============================================================================
-- V813 — TCF CO A2 — lot 11 (thème : services (poste/banque/mairie))
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (A2), table audio_question_draft. 10 items, tous dans le
-- thème « services (poste/banque/mairie) », scènes toutes différentes :
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
  -- 1. [Format A] Rue : un homme glisse une enveloppe dans la boîte aux lettres
  -- ----------------------------------------------------------------------------
  ('66666666-a00b-1000-0000-000000000001', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="190" y="70" width="60" height="70" rx="6" fill="#E8A317"/><rect x="200" y="85" width="40" height="8" fill="#0F1839"/><rect x="212" y="140" width="16" height="20" fill="#0F1839"/><circle cx="120" cy="70" r="13" fill="#0F1839"/><rect x="110" y="84" width="20" height="44" rx="4" fill="#1E3A8C"/><rect x="130" y="88" width="46" height="8" fill="#1E3A8C"/><rect x="172" y="80" width="24" height="15" fill="#FFFFFF" stroke="#0F1839" stroke-width="2"/><rect x="112" y="128" width="7" height="32" fill="#0F1839"/><rect x="121" y="128" width="7" height="32" fill="#0F1839"/></svg>',
   NULL,
   'Dans la rue, un homme tend le bras et glisse une enveloppe blanche dans la fente d''une boîte aux lettres jaune.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il achète du pain à la boulangerie.
B. Il attend ses amis devant le cinéma.
C. Il poste une lettre dans la boîte aux lettres.
D. Il lave les vitres de son appartement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il achète du pain à la boulangerie.<break time="700ms"/>B.<break time="300ms"/>Il attend ses amis devant le cinéma.<break time="700ms"/>C.<break time="300ms"/>Il poste une lettre dans la boîte aux lettres.<break time="700ms"/>D.<break time="300ms"/>Il lave les vitres de son appartement.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un homme qui glisse une enveloppe dans une boîte aux lettres jaune : il **poste une lettre**. Seule C correspond à la scène. A (acheter du pain) montrerait une boulangerie et des baguettes, B (attendre des amis) une façade de cinéma sans enveloppe, D (laver les vitres) une fenêtre et une éponge — rien de tout cela n''est représenté.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 2. [Format A] Banque : une femme retire des billets au distributeur
  -- ----------------------------------------------------------------------------
  ('66666666-a00b-1000-0000-000000000002', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#0F1839"/><rect x="170" y="40" width="100" height="120" rx="6" fill="#1E3A8C"/><rect x="185" y="55" width="70" height="40" fill="#E8ECF8"/><rect x="185" y="105" width="30" height="22" fill="#0F1839"/><rect x="225" y="105" width="30" height="10" fill="#0F1839"/><rect x="200" y="138" width="40" height="10" fill="#0F1839"/><rect x="205" y="130" width="30" height="9" fill="#168F5B"/><circle cx="110" cy="70" r="13" fill="#E8A317"/><rect x="100" y="84" width="20" height="46" rx="4" fill="#0F6E45"/><rect x="120" y="92" width="48" height="8" fill="#0F6E45"/><rect x="102" y="130" width="7" height="30" fill="#0F1839"/><rect x="111" y="130" width="7" height="30" fill="#0F1839"/></svg>',
   NULL,
   'Devant le mur d''une banque, une femme tend la main vers un distributeur automatique bleu ; un billet vert sort de la machine.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle retire de l''argent au distributeur.
B. Elle choisit des fruits au supermarché.
C. Elle promène son chien dans le parc.
D. Elle prend rendez-vous chez le dentiste.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle retire de l''argent au distributeur.<break time="700ms"/>B.<break time="300ms"/>Elle choisit des fruits au supermarché.<break time="700ms"/>C.<break time="300ms"/>Elle promène son chien dans le parc.<break time="700ms"/>D.<break time="300ms"/>Elle prend rendez-vous chez le dentiste.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une femme devant un distributeur automatique d''où sort un billet : elle **retire de l''argent**. Seule A décrit cette scène. B (choisir des fruits) montrerait des rayons de supermarché, C (promener un chien) un parc avec un animal en laisse, D (prendre rendez-vous) un cabinet dentaire — aucun de ces lieux n''apparaît sur l''image.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 3. [Format A] Devant une maison : le facteur remet un colis à une habitante
  -- ----------------------------------------------------------------------------
  ('66666666-a00b-1000-0000-000000000003', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="158" width="320" height="42" fill="#168F5B"/><rect x="20" y="70" width="110" height="90" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><polygon points="15,70 75,30 135,70" fill="#15296B"/><rect x="55" y="105" width="34" height="55" fill="#1E3A8C"/><circle cx="160" cy="80" r="13" fill="#0F1839"/><rect x="150" y="93" width="20" height="42" rx="4" fill="#FDECEB"/><rect x="170" y="104" width="24" height="7" fill="#FDECEB"/><rect x="152" y="135" width="7" height="25" fill="#0F1839"/><rect x="161" y="135" width="7" height="25" fill="#0F1839"/><circle cx="240" cy="78" r="13" fill="#E8A317"/><rect x="230" y="91" width="20" height="44" rx="4" fill="#1E3A8C"/><rect x="218" y="104" width="14" height="7" fill="#1E3A8C"/><rect x="250" y="108" width="18" height="14" fill="#0F1839"/><rect x="232" y="135" width="7" height="25" fill="#0F1839"/><rect x="241" y="135" width="7" height="25" fill="#0F1839"/><rect x="192" y="98" width="30" height="22" fill="#E8A317" stroke="#0F1839" stroke-width="2"/><line x1="207" y1="98" x2="207" y2="120" stroke="#0F1839" stroke-width="2"/></svg>',
   NULL,
   'Devant une maison, un facteur avec une sacoche tend un colis en carton à une habitante qui ouvre les bras pour le prendre.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Le médecin examine un patient à l''hôpital.
B. Le boulanger sort le pain du four.
C. Le jardinier arrose les fleurs du square.
D. Le facteur apporte un colis à une habitante.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le médecin examine un patient à l''hôpital.<break time="700ms"/>B.<break time="300ms"/>Le boulanger sort le pain du four.<break time="700ms"/>C.<break time="300ms"/>Le jardinier arrose les fleurs du square.<break time="700ms"/>D.<break time="300ms"/>Le facteur apporte un colis à une habitante.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un facteur avec sa sacoche qui tend un paquet en carton à une femme devant sa maison : il **livre un colis**. Seule D correspond. A (le médecin) évoquerait une salle d''examen à l''hôpital, B (le boulanger) un fournil et du pain, C (le jardinier) un arrosoir et des fleurs — aucun de ces métiers n''est représenté sur l''image.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 4. [Format A] Mariage : un couple devant le maire, mairie au drapeau tricolore
  -- ----------------------------------------------------------------------------
  ('66666666-a00b-1000-0000-000000000004', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="60" y="55" width="200" height="105" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><polygon points="50,55 160,20 270,55" fill="#1E3A8C"/><rect x="80" y="70" width="12" height="90" fill="#E8ECF8" stroke="#1E3A8C" stroke-width="1"/><rect x="228" y="70" width="12" height="90" fill="#E8ECF8" stroke="#1E3A8C" stroke-width="1"/><rect x="158" y="0" width="4" height="26" fill="#0F1839"/><rect x="162" y="2" width="8" height="14" fill="#1E3A8C"/><rect x="170" y="2" width="8" height="14" fill="#FFFFFF"/><rect x="178" y="2" width="8" height="14" fill="#E1372F"/><circle cx="160" cy="92" r="11" fill="#0F1839"/><rect x="151" y="103" width="18" height="38" rx="4" fill="#0F1839"/><line x1="153" y1="105" x2="167" y2="139" stroke="#1E3A8C" stroke-width="4"/><line x1="157" y1="104" x2="171" y2="138" stroke="#FFFFFF" stroke-width="3"/><line x1="160" y1="103" x2="174" y2="137" stroke="#E1372F" stroke-width="3"/><circle cx="115" cy="100" r="11" fill="#E8A317"/><polygon points="115,111 98,150 132,150" fill="#FFFFFF"/><circle cx="205" cy="100" r="11" fill="#E8A317"/><rect x="196" y="111" width="18" height="39" rx="4" fill="#15296B"/></svg>',
   NULL,
   'Devant une mairie au drapeau tricolore, un couple (la mariée en robe blanche, le marié en costume) se tient face au maire qui porte son écharpe tricolore.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Ils achètent des fleurs chez le fleuriste.
B. Ils se marient à la mairie.
C. Ils écoutent un concert dans une salle.
D. Ils déjeunent sur une terrasse.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ils achètent des fleurs chez le fleuriste.<break time="700ms"/>B.<break time="300ms"/>Ils se marient à la mairie.<break time="700ms"/>C.<break time="300ms"/>Ils écoutent un concert dans une salle.<break time="700ms"/>D.<break time="300ms"/>Ils déjeunent sur une terrasse.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un couple — robe blanche et costume — devant le maire et son écharpe tricolore, à la mairie : c''est **un mariage civil**. Seule B correspond. A (acheter des fleurs) montrerait une boutique de fleuriste, C (écouter un concert) une scène et des musiciens, D (déjeuner en terrasse) une table avec des assiettes — rien de tout cela n''apparaît.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 5. [Format A] Guichet de la mairie : un usager dépose un dossier à l'employée
  -- ----------------------------------------------------------------------------
  ('66666666-a00b-1000-0000-000000000005', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#0F1839"/><rect x="100" y="14" width="120" height="26" rx="4" fill="#1E3A8C"/><text x="160" y="33" font-family="Arial" font-size="16" fill="#FFFFFF" text-anchor="middle">MAIRIE</text><rect x="140" y="50" width="100" height="68" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><circle cx="190" cy="78" r="11" fill="#E8A317"/><rect x="181" y="89" width="18" height="29" rx="4" fill="#168F5B"/><rect x="100" y="118" width="180" height="12" fill="#1E3A8C"/><rect x="112" y="130" width="10" height="30" fill="#15296B"/><rect x="258" y="130" width="10" height="30" fill="#15296B"/><circle cx="55" cy="70" r="13" fill="#0F1839"/><rect x="45" y="84" width="20" height="46" rx="4" fill="#15296B"/><rect x="65" y="95" width="40" height="7" fill="#15296B"/><rect x="105" y="98" width="28" height="18" fill="#E8A317" stroke="#0F1839" stroke-width="2"/><rect x="47" y="130" width="7" height="30" fill="#0F1839"/><rect x="56" y="130" width="7" height="30" fill="#0F1839"/></svg>',
   NULL,
   'Au guichet de la mairie, sous un panneau « MAIRIE », un usager tend un dossier jaune à une employée assise derrière la vitre du comptoir.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il commande un plat au restaurant.
B. Il emprunte un livre à la bibliothèque.
C. Il dépose un dossier au guichet de la mairie.
D. Il monte dans le bus de la ligne quatre.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il commande un plat au restaurant.<break time="700ms"/>B.<break time="300ms"/>Il emprunte un livre à la bibliothèque.<break time="700ms"/>C.<break time="300ms"/>Il dépose un dossier au guichet de la mairie.<break time="700ms"/>D.<break time="300ms"/>Il monte dans le bus de la ligne quatre.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un usager qui tend un dossier à une employée derrière le guichet, sous le panneau « MAIRIE » : il **dépose un dossier à la mairie**. Seule C correspond. A (commander un plat) se passerait à une table de restaurant, B (emprunter un livre) devant des rayonnages de bibliothèque, D (monter dans le bus) à un arrêt avec un véhicule — aucune de ces scènes n''est représentée.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 6. [Format B] « Où est-ce que je peux acheter des timbres ? » (lieu) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a00b-1000-0000-000000000006', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Où est-ce que je peux acheter des timbres ?

A. Demain matin, vers neuf heures.
B. Au bureau de poste de la rue Pasteur.
C. Avec ma carte bancaire, c''est plus simple.
D. Pour envoyer une carte postale à Lucia.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Où est-ce que je peux acheter des timbres ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Demain matin, vers neuf heures.<break time="700ms"/>B.<break time="300ms"/>Au bureau de poste de la rue Pasteur.<break time="700ms"/>C.<break time="300ms"/>Avec ma carte bancaire, c''est plus simple.<break time="700ms"/>D.<break time="300ms"/>Pour envoyer une carte postale à Lucia.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Où est-ce que je peux acheter des timbres ? » porte sur **le lieu**. Seule B « au bureau de poste de la rue Pasteur » indique un endroit. A donne un moment et répondrait à « quand y vas-tu ? », C indique un moyen de paiement et répondrait à « comment payes-tu ? », D exprime un but et répondrait à « pourquoi achètes-tu des timbres ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 7. [Format B] « À quelle heure ouvre la mairie le samedi ? » (heure) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a00b-1000-0000-000000000007', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] À quelle heure ouvre la mairie le samedi matin ?

A. Sur la place de la République.
B. Pour les passeports seulement.
C. Avec l''employée du guichet numéro trois.
D. À neuf heures, jusqu''à midi.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">À quelle heure ouvre la mairie le samedi matin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Sur la place de la République.<break time="700ms"/>B.<break time="300ms"/>Pour les passeports seulement.<break time="700ms"/>C.<break time="300ms"/>Avec l''employée du guichet numéro trois.<break time="700ms"/>D.<break time="300ms"/>À neuf heures, jusqu''à midi.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « À quelle heure ouvre la mairie ? » porte sur **l''horaire d''ouverture**. Seule D « à neuf heures, jusqu''à midi » donne une heure. A indique le lieu et répondrait à « où se trouve la mairie ? », B précise un service et répondrait à « pour quelles démarches ouvre-t-elle ? », C désigne une personne et répondrait à « avec qui as-tu rendez-vous ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 8. [Format B] « Combien coûte l'envoi de ce colis ? » (prix) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a00b-1000-0000-000000000008', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Combien coûte l''envoi de ce colis en Espagne ?

A. Douze euros quarante, madame.
B. En quatre jours environ.
C. Au guichet numéro deux.
D. Pour mon frère Diego, à Madrid.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Combien coûte l''envoi de ce colis en Espagne ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Douze euros quarante, madame.<break time="700ms"/>B.<break time="300ms"/>En quatre jours environ.<break time="700ms"/>C.<break time="300ms"/>Au guichet numéro deux.<break time="700ms"/>D.<break time="300ms"/>Pour mon frère Diego, à Madrid.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Combien coûte l''envoi ? » porte sur **le prix**. Seule A « douze euros quarante » donne un montant. B indique un délai et répondrait à « en combien de temps arrive-t-il ? », C donne un lieu et répondrait à « où dois-je le déposer ? », D désigne le destinataire et répondrait à « pour qui est ce colis ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 9. [Format B] « Quels documents pour ouvrir un compte ? » (objets) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a00b-1000-0000-000000000009', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Quels documents faut-il pour ouvrir un compte dans votre banque ?

A. À l''agence du centre-ville.
B. En quinze minutes seulement.
C. Une pièce d''identité et un justificatif de domicile.
D. Du lundi au vendredi, sans rendez-vous.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quels documents faut-il pour ouvrir un compte dans votre banque ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À l''agence du centre-ville.<break time="700ms"/>B.<break time="300ms"/>En quinze minutes seulement.<break time="700ms"/>C.<break time="300ms"/>Une pièce d''identité et un justificatif de domicile.<break time="700ms"/>D.<break time="300ms"/>Du lundi au vendredi, sans rendez-vous.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Quels documents faut-il ? » porte sur **les papiers à fournir**. Seule C « une pièce d''identité et un justificatif de domicile » nomme des documents. A indique un lieu et répondrait à « où ouvrir le compte ? », B donne une durée et répondrait à « combien de temps ça prend ? », D donne des jours et répondrait à « quand l''agence est-elle ouverte ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 10. [Format B] « Pourquoi vas-tu à la banque ce matin ? » (but) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a00b-1000-0000-00000000000a', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Pourquoi est-ce que tu vas à la banque ce matin ?

A. Juste avant le déjeuner, vers onze heures.
B. Pour commander une nouvelle carte bancaire.
C. À côté de la pharmacie, dans la grande rue.
D. Avec mon voisin Rachid, en voiture.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Pourquoi est-ce que tu vas à la banque ce matin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Juste avant le déjeuner, vers onze heures.<break time="700ms"/>B.<break time="300ms"/>Pour commander une nouvelle carte bancaire.<break time="700ms"/>C.<break time="300ms"/>À côté de la pharmacie, dans la grande rue.<break time="700ms"/>D.<break time="300ms"/>Avec mon voisin Rachid, en voiture.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Pourquoi vas-tu à la banque ? » porte sur **la raison de la visite**. Seule B « pour commander une nouvelle carte bancaire » exprime un but. A donne une heure et répondrait à « quand y vas-tu ? », C indique un lieu et répondrait à « où se trouve la banque ? », D désigne une personne et un moyen de transport, et répondrait à « avec qui et comment y vas-tu ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes '66666666-a00b-1000-0000-0000000000NN'
--     (NN = 01..09, 0a), tous uniques.
-- [x] Thème unique « services (poste/banque/mairie) », 10 scènes toutes
--     différentes : boîte aux lettres (poster une lettre), distributeur
--     (retrait), facteur (livraison colis), mariage à la mairie, guichet
--     mairie (dépôt de dossier), timbres (lieu), horaires mairie (heure),
--     envoi colis (prix), ouverture de compte (documents), visite banque
--     (but). Aucun thème interdit (repas, transports, commerces, santé,
--     école, maison, loisirs, météo, travail, famille, voyages, fêtes,
--     nature : absents).
-- [x] 5 × format A (co_image_proposition, inline_svg + image_alt_text,
--     SSML mono-voix Denise) + 5 × format B (co_question_reponse,
--     inline_svg/image_alt_text NULL, SSML Denise → Vivienne (×3 : items
--     6, 8, 10) / Henri (×2 : items 7, 9) → Denise).
-- [x] 4 propositions / exactement 1 correcte par item. Distribution des
--     bonnes réponses : A=2 (items 2,8), B=3 (items 4,6,10),
--     C=3 (items 1,5,9), D=2 (items 3,7) — 4 lettres utilisées, max 3.
-- [x] Compréhension explicite A2 : bonne réponse littérale, distracteurs
--     nettement distincts (autre lieu / action / moment / personne / but).
-- [x] explanation ≥ 80 caractères : justifie la bonne réponse ET les 3
--     distracteurs (avec la question à laquelle chacun répondrait), point
--     clé en **gras**.
-- [x] SVG : viewBox 320×200, palette charte uniquement, texte « MAIRIE »
--     seul (information de scène, police Arial), rouge #E1372F limité au
--     drapeau et à l''écharpe tricolores (élément signifiant de la scène,
--     item 4), scène lisible en < 2 s, alt_text présent sur les 5 CO_IMAGE.
-- [x] SSML : balises <voice>/<prosody> équilibrées, pauses 1500/1000/700/
--     300 ms conformes, voix Denise 0.95 / Henri & Vivienne 1.0.
-- [x] voice_recommended cohérent (Denise format A ; voix de la question
--     format B). status='TEXT_VALIDATED', colonnes audio toutes NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] SQL : apostrophes doublées partout (SSML/SVG/JSONB inclus), JSONB
--     valide. Contenu 100 % original (prénoms variés : Lucia, Diego,
--     Rachid).
-- ============================================================================
